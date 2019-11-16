post_stage() {
  if [[ -z ${SOURCE_IMG+x} ]]; then
    echo -e "\033[0;31m### Error: SOURCE_IMG was not set; please call FROM\033[0m"
    return 1
  fi

  if [[ -z ${DEST_IMG+x} ]]; then
    DEST_IMG="`dirname ${SOURCE_IMG}`/rpi.img"
    echo "DEST_IMG was not set, defaults to ${DEST_IMG}"
  fi

  if [[ -z ${INPLACE_MODE+x} ]]; then
    echo -e "\033[0;32m### TO ${DEST_IMG}\033[0m"
    if [[ "${SOURCE_IMG}" != "${DEST_IMG}" ]]; then
      cp "${SOURCE_IMG}" "${DEST_IMG}"
    else
      echo -e "\033[0;33m### Warning: SOURCE_IMG and DEST_IMG are identical, ${DEST_IMG} will be overwritten.\033[0m"
    fi
  else
    unset INPLACE_MODE
  fi
}

# FROM sets the SOURCE_IMG variable to a target. This might be a local file or
# a remote URL, which will be downloaded. This file will become the base for
# the new image.
#
# Usage: FROM PATH_TO_IMAGE
#        FROM URL
FROM() {
  if [[ -f "${1}" ]]; then
    SOURCE_IMG="${1}"
  elif from_remote_valid "${1}"; then
    if ! from_remote_fetch "${1}"; then
      return 1
    fi
  else
    echo -e "\033[0;31m### Error: ${1} is neither a file nor fetachable!\033[0m"
    return 1
  fi

  [[ -z ${2+x} ]] && IMG_ROOT="2" || IMG_ROOT="${2}"

  if [[ -z ${INPLACE_MODE+x} ]]; then
    echo -e "\033[0;32m### FROM ${SOURCE_IMG} ${IMG_ROOT}\033[0m"
  fi
}

# TO sets the DEST_IMG variable to the given file. This file will contain the
# new image. Existing files will be overridden.
#
# Instead of calling TO, the Pifile's filename can also indicate the output
# file, if the Pifile ends with ".Pifile". The part before this suffix will be
# the new DEST_IMG.
#
# If neither TO is called nor the Pifile indicates the output, DEST_IMG will
# default to rpi.img in the source file's directory.
#
# Usage: TO PATH_TO_IMAGE
TO() {
  DEST_IMG=$1
}

# INPLACE does not create a copy of the image, but performs all further
# operations on the given image. This is an alternative to FROM and TO.
#
# Usage: INPLACE PATH_TO_IMAGE
INPLACE() {
  if from_remote_valid "${1}"; then
    echo -e "\033[0;31m### Error: INPLACE cannot be used with a URLs.\033[0m"
    return 1
  fi

  INPLACE_MODE=1

  FROM "$@"
  TO "$1"

  echo -e "\033[0;32m### INPLACE ${@}\033[0m"
}
