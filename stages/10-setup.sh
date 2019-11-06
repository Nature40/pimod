post_stage() {
  if [ -z "${SOURCE_IMG}" ]; then
    echo -e "\033[0;31m### Error: SOURCE_IMG was not set; please call FROM\033[0m"
    return 1
  fi

  if [ -z "${DEST_IMG}" ]; then
    DEST_IMG="`dirname ${SOURCE_IMG}`/rpi.img"
    echo "DEST_IMG was not set, defaults to ${DEST_IMG}"
  fi

  echo -e "\033[0;32m### TO ${DEST_IMG}\033[0m"
  if [ ${SOURCE_IMG} != ${DEST_IMG} ]; then
    cp "${SOURCE_IMG}" "${DEST_IMG}"
  else
    echo -e "\033[0;33m### Warning: SOURCE_IMG and DEST_IMG are identical, ${DEST_IMG} will be overwritten.\033[0m"
  fi

}

# FROM sets the SOURCE_IMG variable to the given file. This file will be used
# as the base for the new image.
#
# Usage: FROM PATH_TO_IMAGE
FROM() {
  if [[ ! -f "${1}" ]]; then
    echo -e "\033[0;31m### Error: ${1} does not exists!\033[0m"
    return 1
  fi

  SOURCE_IMG="${1}"

  if [ -z "${2}" ]; then
    IMG_ROOT="2"
  else
    IMG_ROOT="${2}"
  fi

  echo -e "\033[0;32m### FROM ${SOURCE_IMG} ${IMG_ROOT}\033[0m"
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
