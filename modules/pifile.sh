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

  pushd "$(dirname "$0")/modules" > /dev/null || exit 2
  . "../stages/00-commands.sh"
  . "../stages/10-setup.sh"
  popd > /dev/null || exit 2
  pre_stage
  # shellcheck disable=SC1090
  . "$1"
  post_stage

  pushd "$(dirname "$0")/modules" > /dev/null || exit 2
  . "../stages/00-commands.sh"
  . "../stages/20-prepare.sh"
  popd > /dev/null || exit 2
  pre_stage
  # shellcheck disable=SC1090
  . "$1"
  post_stage

  pushd "$(dirname "$0")/modules" > /dev/null || exit 2
  . "../stages/00-commands.sh"
  . "../stages/30-chroot.sh"
  popd > /dev/null || exit 2
  pre_stage
  # shellcheck disable=SC1090
  . "$1"
  post_stage

  pushd "$(dirname "$0")/modules" > /dev/null || exit 2
  . "../stages/00-commands.sh"
  . "../stages/40-postprocess.sh"
  popd > /dev/null || exit 2
  pre_stage
  # shellcheck disable=SC1090
  . "$1"
  post_stage
}


