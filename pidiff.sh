#!/usr/bin/env bash

set -euE

pushd "$(dirname "$0")" > /dev/null

. ./modules/mount.sh

popd > /dev/null

show_help() {
  cat <<EOF
Usage: ${0} [OPTIONS] BASE_IMAGE UPDATED_IMAGE

Compare two disk images and generate an rsync batch file for incremental updates.

Arguments:
  BASE_IMAGE      Path to the base image file
  UPDATED_IMAGE   Path to the updated image file

Options:
  --partition=NUM       Rootfs partition number (default: 2)
  --output=PATH         Output batch file path (default: auto-generated)
  --tar                 Create tar archive containing batch and batch.sh files
  --help                Print this help message
  
  Any other options are passed directly to rsync. For example:
  --exclude-from=FILE   Pass --exclude-from to rsync
  --verbose             Pass --verbose to rsync

Examples:
  ${0} base.img updated.img
  ${0} --tar --output=update.batch base.img updated.img
  ${0} --itemize-changes --exclude="*.pyc" base.img updated.img
EOF
}

cleanup() {
  local exit_code="${1:-0}"
  
  # Unmount rootfs partitions if mounted
  if [[ -n "${BASE_MOUNT+x}" ]] && [[ -d "${BASE_MOUNT}" ]]; then
    if mountpoint -q "${BASE_MOUNT}" 2>/dev/null; then
      umount "${BASE_MOUNT}" 2>/dev/null || true
    fi
    rmdir "${BASE_MOUNT}" 2>/dev/null || true
  fi
  
  if [[ -n "${UPDATED_MOUNT+x}" ]] && [[ -d "${UPDATED_MOUNT}" ]]; then
    if mountpoint -q "${UPDATED_MOUNT}" 2>/dev/null; then
      umount "${UPDATED_MOUNT}" 2>/dev/null || true
    fi
    rmdir "${UPDATED_MOUNT}" 2>/dev/null || true
  fi
  
  # Unmount images if mounted
  if [[ -n "${LOOP_BASE+x}" ]]; then
    umount_image "${LOOP_BASE}" 2>/dev/null || true
  fi
  
  if [[ -n "${LOOP_UPDATED+x}" ]]; then
    umount_image "${LOOP_UPDATED}" 2>/dev/null || true
  fi
  
  exit "${exit_code}"
}

trap 'cleanup $?' ERR
trap 'cleanup 130' INT TERM

# extract_os_release_variable extracts a specific variable from /etc/os-release file
# Usage: extract_os_release_variable PATH_TO_OS_RELEASE VARIABLE_NAME
extract_os_release_variable() {
  local os_release_file="$1"
  local var_name="$2"
  if [[ -f "${os_release_file}" ]]; then
    # Source the os-release file to get the variable
    local var_value=""
    if . "${os_release_file}" 2>/dev/null; then
      # Use indirect variable reference to get the value
      eval "var_value=\${${var_name}:-}"
    fi
    echo "${var_value}"
  else
    echo ""
  fi
}

# extract_os_release_timestamp gets the access timestamp of /etc/os-release in ISO 8601 UTC format
# Usage: extract_os_release_timestamp PATH_TO_OS_RELEASE
extract_os_release_timestamp() {
  local os_release_file="$1"
  if [[ -f "${os_release_file}" ]]; then
    # Get access time in seconds since epoch (GNU stat)
    local atime=$(stat -c %X "${os_release_file}" 2>/dev/null || echo "")
    if [[ -n "${atime}" ]] && [[ "${atime}" =~ ^[0-9]+$ ]]; then
      # Convert to ISO 8601 UTC format (GNU date)
      date -u -d "@${atime}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo ""
    else
      echo ""
    fi
  else
    echo ""
  fi
}

# inject_metadata injects metadata variables into the batch.sh file
# Usage: inject_metadata BATCH_SH_FILE BASE_MOUNT UPDATED_MOUNT BASE_IMAGE UPDATED_IMAGE PARTITION RSYNC_OPTIONS BATCH_FILENAME
inject_metadata() {
  local batch_sh_file="$1"
  local base_mount="$2"
  local updated_mount="$3"
  local base_image="$4"
  local updated_image="$5"
  local partition="$6"
  local rsync_options="$7"
  local batch_filename="$8"
  
  if [[ ! -f "${batch_sh_file}" ]]; then
    return 0
  fi
  
  # Extract metadata from mounted images
  local base_version=$(extract_os_release_variable "${base_mount}/etc/os-release" "PRETTY_NAME")
  local updated_version=$(extract_os_release_variable "${updated_mount}/etc/os-release" "PRETTY_NAME")
  local base_timestamp=$(extract_os_release_timestamp "${base_mount}/etc/os-release")
  local updated_timestamp=$(extract_os_release_timestamp "${updated_mount}/etc/os-release")
  local base_version_id=$(extract_os_release_variable "${base_mount}/etc/os-release" "VERSION_ID")
  local updated_version_id=$(extract_os_release_variable "${updated_mount}/etc/os-release" "VERSION_ID")
  local base_version_commit=$(extract_os_release_variable "${base_mount}/etc/os-release" "VERSION_COMMIT")
  local updated_version_commit=$(extract_os_release_variable "${updated_mount}/etc/os-release" "VERSION_COMMIT")
  
  # Get rsync version
  local rsync_version=$(rsync --version | head -n1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -n1 || echo "")
  
  # Get current timestamp in ISO 8601 UTC
  local created=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")
  
  # Build metadata header
  local metadata_header="# pidiff metadata - automatically generated
# These variables can be used in scripts to verify and apply updates

# Tool information
CREATED=\"${created}\"

# Rsync configuration
RSYNC_VERSION=\"${rsync_version}\"
RSYNC_OPTIONS=\"${rsync_options}\"

# Base image information
BASE_IMAGE=\"${base_image}\"
BASE_PRETTY_NAME=\"${base_version}\"
BASE_VERSION_ID=\"${base_version_id}\"
BASE_VERSION_COMMIT=\"${base_version_commit}\"
BASE_TIMESTAMP=\"${base_timestamp}\"

# Updated image information
UPDATED_IMAGE=\"${updated_image}\"
UPDATED_PRETTY_NAME=\"${updated_version}\"
UPDATED_VERSION_ID=\"${updated_version_id}\"
UPDATED_VERSION_COMMIT=\"${updated_version_commit}\"
UPDATED_TIMESTAMP=\"${updated_timestamp}\"

"
  
  # Extract the rsync command and heredoc from the original batch.sh file
  # Find the line starting with "rsync" and everything after it (including heredoc)
  local rsync_section=$(sed -n '/^rsync/,$p' "${batch_sh_file}")
  # Replace ${1:-default} pattern with ${TARGET_DIR} in the rsync command
  rsync_section=$(echo "${rsync_section}" | sed 's/\${1:-[^}]*}/\${TARGET_DIR}/g')
  # Replace --read-batch=/tmp/... with --read-batch using the generated batch filename
  # Assumes script is executed from the directory where batch file is located
  local batch_basename=$(basename "${batch_filename}")
  rsync_section=$(echo "${rsync_section}" | sed "s|--read-batch=[^ ]*|--read-batch=\"${batch_basename}\"|g")
  
  # Build enhanced batch.sh script
  local enhanced_script="#!/usr/bin/env bash

set -e

${metadata_header}
# Enhanced batch script with safety checks

echo \"pidiff update script\"
echo \"===================\"
echo \"Base image: \${BASE_IMAGE} (\${BASE_PRETTY_NAME})\"
echo \"Updated image: \${UPDATED_IMAGE} (\${UPDATED_PRETTY_NAME})\"
echo \"\"

# Check if running as root
if [[ \$(id -u) -ne 0 ]]; then
  echo \"Error: This script must be run as root\" >&2
  echo \"Usage: sudo \$0 <target_directory>\" >&2
  exit 1
fi

# Check if target directory is provided
if [[ -z \"\${1}\" ]]; then
  echo \"Error: Target directory must be specified\" >&2
  echo \"Usage: \$0 <target_directory>\" >&2
  exit 1
fi

TARGET_DIR=\"\${1}\"

# Validate target directory exists
if [[ ! -d \"\${TARGET_DIR}\" ]]; then
  echo \"Error: Target directory does not exist: \${TARGET_DIR}\" >&2
  exit 1
fi

# Check if target directory version matches base version
if [[ -f \"\${TARGET_DIR}/etc/os-release\" ]]; then
  # Source the os-release file to get PRETTY_NAME
  . \"\${TARGET_DIR}/etc/os-release\"
  
  if [[ -z \"\${PRETTY_NAME}\" ]]; then
    echo \"Error: PRETTY_NAME not found in \${TARGET_DIR}/etc/os-release\" >&2
    exit 1
  fi
  
  if [[ \"\${PRETTY_NAME}\" != \"\${BASE_PRETTY_NAME}\" ]]; then
    echo \"Error: Version mismatch\" >&2
    echo \"  Expected base version: \${BASE_PRETTY_NAME}\" >&2
    echo \"  Found target version: \${PRETTY_NAME}\" >&2
    echo \"  This update is designed for base version \${BASE_PRETTY_NAME}\" >&2
    exit 1
  fi
else
  echo \"Warning: /etc/os-release not found in target directory, skipping version check\" >&2
fi

echo \"Applying update to: \${TARGET_DIR}\"
echo \"This will modify files in the target directory.\"
echo \"\"

${rsync_section}

RSYNC_EXIT_CODE=\$?

echo \"\"
case \${RSYNC_EXIT_CODE} in
  0) echo \"Update completed successfully!\" ;;
  1) echo \"Error: Syntax or usage error\" >&2 ;;
  2) echo \"Error: Protocol incompatibility\" >&2 ;;
  11) echo \"Error: File I/O error\" >&2 ;;
  23) echo \"Warning: Partial transfer due to error\" >&2 ;;
  24) echo \"Warning: Partial transfer due to vanished source files\" >&2 ;;
  *) echo \"Error: Update failed with exit code \${RSYNC_EXIT_CODE}\" >&2 ;;
esac

exit \${RSYNC_EXIT_CODE}
"
  
  # Write enhanced script to batch.sh file
  echo -n "${enhanced_script}" > "${batch_sh_file}"
}

main() {
  local base_image=""
  local updated_image=""
  local partition="2"
  local output_path=""
  local create_tar=false
  local rsync_options="--recursive --links --perms --times --group --owner --devices --hard-links --delete --compress"
  local rsync_passthrough=()
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --partition=*)
        partition="${1#*=}"
        ;;
      --output=*)
        output_path="${1#*=}"
        ;;
      --tar)
        create_tar=true
        ;;
      --help)
        show_help
        exit 0
        ;;
      -*)
        # Collect unknown options to pass through to rsync
        # Options with values must use --option=value format
        rsync_passthrough+=("$1")
        ;;
      *)
        if [[ -z "${base_image}" ]]; then
          base_image="$1"
        elif [[ -z "${updated_image}" ]]; then
          updated_image="$1"
        else
          echo "Error: Too many arguments"
          show_help
          exit 1
        fi
        ;;
    esac
    shift
  done
  
  # Validate required arguments
  if [[ -z "${base_image}" ]] || [[ -z "${updated_image}" ]]; then
    echo "Error: Both BASE_IMAGE and UPDATED_IMAGE must be specified"
    show_help
    exit 1
  fi
  
  # Validate image files exist
  if [[ ! -f "${base_image}" ]] && [[ ! -b "${base_image}" ]]; then
    echo "Error: Base image file does not exist: ${base_image}"
    exit 1
  fi
  
  if [[ ! -f "${updated_image}" ]] && [[ ! -b "${updated_image}" ]]; then
    echo "Error: Updated image file does not exist: ${updated_image}"
    exit 1
  fi
  
  # Check rsync availability
  if ! command -v rsync >/dev/null 2>&1; then
    echo "Error: rsync is not installed or not in PATH"
    exit 1
  fi
  
  # Combine default rsync options with passed-through options
  if [[ ${#rsync_passthrough[@]} -gt 0 ]]; then
    rsync_options="${rsync_options} ${rsync_passthrough[*]}"
  fi
  
  # Generate output path if not specified
  if [[ -z "${output_path}" ]]; then
    local base_basename=$(basename "${base_image}" .img)
    local updated_basename=$(basename "${updated_image}" .img)
    output_path="${base_basename}_to_${updated_basename}.batch"
  fi
  
  # Ensure output directory exists
  local output_dir=$(dirname "${output_path}")
  if [[ -n "${output_dir}" ]] && [[ "${output_dir}" != "." ]]; then
    mkdir -p "${output_dir}"
  fi
  
  echo -e "\033[0;32m### Comparing images: ${base_image} -> ${updated_image}\033[0m"
  echo -e "\033[0;32m### Using partition: ${partition}\033[0m"
  echo -e "\033[0;32m### Output batch file: ${output_path}\033[0m"
  if [[ ${#rsync_passthrough[@]} -gt 0 ]]; then
    echo -e "\033[0;32m### Additional rsync options: ${rsync_passthrough[*]}\033[0m"
  fi
  
  # Mount base image
  echo -e "\033[0;32m### Mounting base image...\033[0m"
  LOOP_BASE=$(mount_image "${base_image}")
  
  # Mount updated image
  echo -e "\033[0;32m### Mounting updated image...\033[0m"
  LOOP_UPDATED=$(mount_image "${updated_image}")
  
  # Create temporary mount points
  BASE_MOUNT=$(mktemp -d)
  UPDATED_MOUNT=$(mktemp -d)
  
  # Mount rootfs partitions
  local base_rootfs="/dev/mapper/${LOOP_BASE}p${partition}"
  local updated_rootfs="/dev/mapper/${LOOP_UPDATED}p${partition}"
  
  # Validate partitions exist
  if [[ ! -b "${base_rootfs}" ]]; then
    echo "Error: Partition ${partition} does not exist in base image: ${base_rootfs}"
    cleanup 1
  fi
  
  if [[ ! -b "${updated_rootfs}" ]]; then
    echo "Error: Partition ${partition} does not exist in updated image: ${updated_rootfs}"
    cleanup 1
  fi
  
  echo -e "\033[0;32m### Mounting rootfs partitions...\033[0m"
  mount "${base_rootfs}" "${BASE_MOUNT}/"
  mount "${updated_rootfs}" "${UPDATED_MOUNT}/"
  
  # Generate rsync batch file with fixed filenames
  echo -e "\033[0;32m### Generating rsync batch file...\033[0m"


  # Use fixed filenames for batch files (in temporary directory)
  local temp_dir=$(mktemp -d)
  local batch_file="${temp_dir}/batch"
  local batch_sh_file="${batch_file}.sh"

  # rsync with default options plus any passed-through options, only write the batch file
  rsync ${rsync_options} --only-write-batch="${batch_file}" "${UPDATED_MOUNT}/" "${BASE_MOUNT}/" 
  
  # Inject metadata into batch.sh file if it exists
  if [[ -f "${batch_sh_file}" ]]; then
    echo -e "\033[0;32m### Injecting metadata into batch script...\033[0m"
    inject_metadata "${batch_sh_file}" "${BASE_MOUNT}" "${UPDATED_MOUNT}" "${base_image}" "${updated_image}" "${partition}" "${rsync_options}" "${output_path}"
  fi
  
  if [[ "${create_tar}" == true ]]; then
    # Create tar archive containing both batch files with user-specified name
    local archive_path="${output_path}.tar"
    echo -e "\033[0;32m### Creating archive: ${archive_path}\033[0m"
    
    local batch_files=()
    if [[ -f "${batch_file}" ]]; then
      batch_files+=("${batch_file}")
    fi
    if [[ -f "${batch_sh_file}" ]]; then
      batch_files+=("${batch_sh_file}")
    fi
    
    if [[ ${#batch_files[@]} -gt 0 ]]; then
      # Create tar archive (no compression) and remove original files after archiving
      # Use --remove-files to automatically remove files after adding them to archive
      # Change to temp_dir to use relative paths in archive, use absolute path for output
      local archive_abs_path=$(realpath "${archive_path}" 2>/dev/null || echo "${archive_path}")
      (cd "${temp_dir}" && tar --remove-files -cf "${archive_abs_path}" batch batch.sh 2>/dev/null || tar --remove-files -cf "${archive_abs_path}" batch)
      
      # Clean up temp directory (should be empty after --remove-files, but be safe)
      rmdir "${temp_dir}" 2>/dev/null || rm -rf "${temp_dir}"
      
      echo -e "\033[0;32m### Archive created: ${archive_path}\033[0m"
      echo -e "\033[0;32m### To apply this update, extract the archive and run: sudo ./batch.sh /path/to/target/\033[0m"
    else
      echo -e "\033[0;31m### Warning: No batch files found to archive\033[0m"
      rmdir "${temp_dir}" 2>/dev/null || rm -rf "${temp_dir}"
    fi
  else
    # Copy batch files to output location (default behavior)
    echo -e "\033[0;32m### Copying batch files to output location...\033[0m"
    
    local output_dir=$(dirname "${output_path}")
    if [[ -n "${output_dir}" ]] && [[ "${output_dir}" != "." ]]; then
      mkdir -p "${output_dir}"
    fi
    
    if [[ -f "${batch_file}" ]]; then
      cp "${batch_file}" "${output_path}"
      echo -e "\033[0;32m### Batch file created: ${output_path}\033[0m"
    fi
    
    if [[ -f "${batch_sh_file}" ]]; then
      cp "${batch_sh_file}" "${output_path}.sh"
      echo -e "\033[0;32m### Batch script created: ${output_path}.sh\033[0m"
    fi
    
    # Clean up temp directory
    rm -rf "${temp_dir}"
    
    local script_name=$(basename "${output_path}.sh")
    echo -e "\033[0;32m### To apply this update, run: sudo ./${script_name} /path/to/target/\033[0m"
  fi
  
  # Cleanup
  cleanup 0
}

main "$@"

