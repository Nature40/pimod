# inspect_pifile_name checks the name of the given Pifile (first parameter)
# and sets the internal DEST_IMG variable to the first part of this filename,
# if the filename has the format of XYZ.Pifile, with XYZ being alphanumeric
# or signs.
# Usage: inspect_pifile_name PIFILE_NAME
inspect_pifile_name() {
  local name
  name="${1%.Pifile}"

  if [ "${name}" ]; then
    DEST_IMG="${name}.img"
  else
    DEST_IMG="${1}.img"
  fi

  export DEST_IMG
}

# execute_pifile runs the given Pifile.
# Usage: execute_pifile PIFILE
execute_pifile() {
  if [[ -z ${1+x} ]] || [[ ! -f "${1}" ]]; then
    echo -e "\033[0;31m### Error: Pifile \"${1}\" does not exist.\033[0m"
    return 1
  fi

  grep -q $'\r' "${1}" && \
    echo -e "\033[0;33m### Warning: Pifile contains CRLF, please use a Unix-like newline.\033[0m"

  inspect_pifile_name "$1"

  bash -n "$1"

  # Resolve absolute paths for modules and stages so pimod works when
  # invoked via a symlink or from a different working directory.
  MODULE_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
  STAGES_DIR="${MODULE_DIR}/../stages"

  # Absolute path to the provided Pifile.
  PIFILE_ABS="$(cd -P "$(dirname "$1")" >/dev/null && pwd)/$(basename "$1")"

  declare -a stages=( "10-setup" "20-prepare" "30-chroot" "40-postprocess" "50-finalize" )
  for stage in "${stages[@]}"; do
    # shellcheck disable=SC1090
    . "${STAGES_DIR}/00-commands.sh"
    # shellcheck disable=SC1090
    . "${STAGES_DIR}/${stage}.sh"

    pre_stage

    # shellcheck disable=SC1090
    . "${PIFILE_ABS}"

    post_stage
  done
}
