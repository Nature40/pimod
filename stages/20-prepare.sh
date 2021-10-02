#!/usr/bin/env bash

# PUMP increases the image's size about the given amount of megabytes.
#
# Usage: PUMP SIZE_IN_MB
PUMP() {
  if [[ -b "${DEST_IMG}" ]]; then
    echo -e "\033[0;31m### Error: Block device ${DEST_IMG} cannot be pumped.\033[0m"
    return 1
  fi

  echo -e "\033[0;32m### PUMP ${1}\033[0m"
  dd if=/dev/zero bs="${1}" count=1 >> "${DEST_IMG}"

  # Fix the GPT if necessary and resize the partition afterwards.
  # The fix is currently kind of hackish..
  echo -e "Fix\n" | parted ---pretend-input-tty "${DEST_IMG}" print
  parted -s "${DEST_IMG}" resizepart "${IMG_ROOT}" "100%"

  local loop
  loop=$(mount_image "${DEST_IMG}")

  e2fsck -p -f "/dev/mapper/${loop}p${IMG_ROOT}" || (
    ERR="${?}"
    if [ "${ERR}" -gt 2 ]; then
      echo -e "\033[0;31m### Error: File system repair failed (${ERR}).\033[0m"
      return "${ERR}"
    fi
  )
  resize2fs "/dev/mapper/${loop}p${IMG_ROOT}"

  umount_image "${loop}"
}
