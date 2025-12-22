# SHRINK reduces the image file size by shrinking the filesystem and partition.
# Optionally, a size parameter can be provided to shrink to a specific size.
#
# Usage: SHRINK [SIZE]
SHRINK() {
  if [[ -b "${DEST_IMG}" ]]; then
    echo -e "\033[0;31m### Error: Block device ${DEST_IMG} cannot be shrunk.\033[0m"
    return 1
  fi

  echo -e "\033[0;32m### SHRINK${1:+ ${1}}\033[0m"

  local beforesize
  beforesize="$(ls -lh "${DEST_IMG}" | cut -d ' ' -f 5)"

  # Mount image and check filesystem integrity
  local loop
  loop=$(mount_image "${DEST_IMG}")
  local loop_device="/dev/mapper/${loop}p${IMG_ROOT}"

  if ! e2fsck -pf "${loop_device}"; then
    local err=$?
    if [ "${err}" -gt 2 ]; then
      echo -e "\033[0;31m### Error: File system check failed (${err}).\033[0m"
      umount_image "${loop}"
      return "${err}"
    fi
  fi

  # Determine minimum filesystem size and add safety buffer
  local minsize
  minsize=$(resize2fs -P "${loop_device}" 2>/dev/null | cut -d ':' -f 2 | tr -d ' ')
  
  if ! [[ "${minsize}" =~ ^[0-9]+$ ]]; then
    echo -e "\033[0;31m### Error: Could not determine minimum filesystem size.\033[0m"
    umount_image "${loop}"
    return 10
  fi

  local blocksize currentsize
  blocksize=$(tune2fs -l "${loop_device}" | grep '^Block size:' | tr -d ' ' | cut -d ':' -f 2)
  currentsize=$(tune2fs -l "${loop_device}" | grep '^Block count:' | tr -d ' ' | cut -d ':' -f 2)

  if [[ "${currentsize}" -eq "${minsize}" ]]; then
    echo "Filesystem already at minimum size"
    umount_image "${loop}"
    return 0
  fi

  # Add 5% safety buffer to prevent filesystem from being 100% full
  local buffer
  buffer=$(((currentsize - minsize) / 20))
  minsize=$((minsize + buffer))

  # Get partition start offset (includes partition table + boot partition)
  local partinfo
  partinfo=$(sfdisk -l "${DEST_IMG}" -o START 2>/dev/null | grep -E '^ *[0-9]' | sed -n "${IMG_ROOT}p")
  local partstart_sectors
  partstart_sectors=$(echo "${partinfo}" | awk '{print $1}')
  local partstart_bytes
  partstart_bytes=$((partstart_sectors * 512))

  # Determine target size based on optional SIZE parameter
  local target_blocks
  if [[ -n "${1:-}" ]]; then
    # Parse SIZE parameter with units (K, M, G suffixes supported)
    local target_bytes
    if ! target_bytes=$(units -t "${1}B" "B" 2>/dev/null); then
      echo -e "\033[0;31m### Error: Invalid size format. Use suffixes K, M, G (e.g., 2G).\033[0m"
      umount_image "${loop}"
      return 1
    fi
    
    # Convert to integer (handle scientific notation and decimals)
    target_bytes=$(printf "%.0f" "${target_bytes}" 2>/dev/null)
    
    local current_img_bytes
    current_img_bytes=$(stat -c%s "${DEST_IMG}" 2>/dev/null)
    
    if [[ ${target_bytes} -ge ${current_img_bytes} ]]; then
      # Skip shrinking, image already smaller than target
      echo "Image size (${beforesize}) already smaller than target size (${1})"
      umount_image "${loop}"
      return 0
    fi
    
    # Calculate minimum image size = minimum filesystem size + partition overhead
    local minimum_filesystem_bytes
    minimum_filesystem_bytes=$((minsize * blocksize))
    local minimum_image_bytes
    minimum_image_bytes=$((minimum_filesystem_bytes + partstart_bytes))
    
    # Compare target image size against minimum image size
    if [[ ${target_bytes} -lt ${minimum_image_bytes} ]]; then
      # Error: target image size too small
      local min_image_mb=$((minimum_image_bytes / 1048576))
      echo -e "\033[0;31m### Error: Target size (${1}) is too small. Minimum image size required: ~${min_image_mb}M.\033[0m"
      umount_image "${loop}"
      return 1
    fi
    
    # Calculate target filesystem size from target image size
    local target_filesystem_bytes
    target_filesystem_bytes=$((target_bytes - partstart_bytes))
    target_blocks=$((target_filesystem_bytes / blocksize))
    echo "Shrinking filesystem to ${target_blocks} blocks (image size: ${1})"
  else
    # No parameter: shrink to minimum + buffer
    target_blocks=${minsize}
    echo "Shrinking filesystem to ${target_blocks} blocks (minimum + 5% buffer)"
  fi

  # Shrink filesystem to target size
  if ! resize2fs -p "${loop_device}" "${target_blocks}"; then
    echo -e "\033[0;31m### Error: resize2fs failed ($?).\033[0m"
    umount_image "${loop}"
    return 12
  fi

  umount_image "${loop}"

  # Calculate new partition size in sectors
  local newsize_sectors
  newsize_sectors=$(((target_blocks * blocksize + 511) / 512))

  # Modify partition table: dump, update size field, restore
  echo "Shrinking partition to ${newsize_sectors} sectors"

  if ! sfdisk -d "${DEST_IMG}" | awk -v part="${IMG_ROOT}" -v newsize="${newsize_sectors}" '
    /^[^#]/ && /start= *[0-9]+, *size= *[0-9]+/ {
      partcount++
      if (partcount == part) gsub(/size= *[0-9]+/, "size=" newsize)
    }
    { print }
  ' | sfdisk --no-reread --force "${DEST_IMG}" 2>&1; then
    echo -e "\033[0;31m### Error: sfdisk failed ($?).\033[0m"
    return 13
  fi

  # Truncate image file to new partition end
  local last_sector
  last_sector=$(sfdisk -l "${DEST_IMG}" -o END -n 2>/dev/null | tail -n1 | tr -d ' ')
  truncate -s $(((last_sector + 1) * 512)) "${DEST_IMG}"

  local aftersize
  aftersize="$(ls -lh "${DEST_IMG}" | cut -d ' ' -f 5)"

  echo -e "\033[0;32m### Shrunk ${DEST_IMG} from ${beforesize} to ${aftersize}\033[0m"
}

