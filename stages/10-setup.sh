post_stage() {
  if [[ -z ${SOURCE_IMG+x} ]]; then
    echo -e "\033[0;31m### Error: No source was set, use FROM or INPLACE\033[0m"
    return 1
  fi

  if [[ "${SOURCE_IMG}" == "${DEST_IMG}" ]]; then
    echo "Working inplace ${SOURCE_IMG}."
    return 0
  fi

  if [[ -b "${DEST_IMG}" ]]; then
    echo "Writing ${SOURCE_IMG} to block device ${DEST_IMG}."
    umount "${DEST_IMG}"* || true
    dd if="${SOURCE_IMG}" of="${DEST_IMG}" bs=1M status=progress
    if [[ -n "${SOURCE_IMG_TMP+x}" ]]; then
      rm "${SOURCE_IMG}"
      unset SOURCE_IMG_TMP
    fi

    return 0
  fi

  if [[ -n "${SOURCE_IMG_TMP+x}" ]]; then
    echo "Moving temporary ${SOURCE_IMG} to ${DEST_IMG}"
    mv "${SOURCE_IMG}" "${DEST_IMG}"
    unset SOURCE_IMG_TMP

    return 0
  fi

  echo "Copying ${SOURCE_IMG} to ${DEST_IMG}."
  cp "${SOURCE_IMG}" "${DEST_IMG}"
}

# FROM sets the SOURCE_IMG variable to a target. This might be a local file or
# a remote URL, which will be downloaded. This file will become the base for
# the new image.
#
# By default, the Raspberry Pi's default partition number 2 will be used, but
# can be altered for other targets.
#
# Usage: FROM PATH_TO_IMAGE [PARTITION_NO]
#        FROM URL [PARTITION_NO]
FROM() {
  echo -e "\033[0;32m### FROM ${*}\033[0m"

  # Hande remote sources
  if [[ -f "${1}" || -b "${1}" ]]; then
    SOURCE_IMG="${1}"
  elif from_remote_valid "${1}"; then
    from_remote_fetch "${1}"
  else
    echo -e "\033[0;31m### Error: ${1} is not a file, device or fetachable!\033[0m"
    return 1
  fi

  # Set default root partition, if not specified
  if [[ -z ${2+x} ]]; then
    IMG_ROOT="2"
  else
    IMG_ROOT="${2}"
  fi

  export IMG_ROOT
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
  echo -e "\033[0;32m### TO ${1}\033[0m"
  DEST_IMG="${1}"
}

# INPLACE does not create a copy of the image, but performs all further
# operations on the given image. This is an alternative to FROM and TO.
#
# Usage: INPLACE FROM_ARGS...
INPLACE() {
  if from_remote_valid "${1}"; then
    echo -e "\033[0;31m### Error: INPLACE cannot be used with a URL.\033[0m"
    return 1
  fi

  FROM "$@"
  TO "$1"
}
