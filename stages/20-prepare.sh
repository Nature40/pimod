# PUMP increases the image's size about the given amount of megabytes.
#
# Usage: PUMP SIZE
PUMP() {
  if [[ -b "${DEST_IMG}" ]]; then
    echo -e "\033[0;31m### Error: Block device ${DEST_IMG} cannot be pumped.\033[0m"
    return 1
  fi

  echo -e "\033[0;32m### PUMP ${1}\033[0m"

  BS="1M"

  # units does not print to stderr, thus test call before using output
  echo -n "pump conversion to ${BS} * "
  units -t "${1}B" "${BS}B"

  COUNT=$(units -t ${1}B ${BS}B)

  # Ceil the number if a decimal is given.
  if [[ "${COUNT}" == *.* ]]; then
    COUNT=$(( $(echo "${COUNT}" | cut -d. -f1) + 1 ))
  fi

  echo "pump ceil: ${BS} * ${COUNT}"

  dd if=/dev/zero bs="${BS}" count="${COUNT}" >> "${DEST_IMG}"

  echo ", +" | sfdisk -N "${IMG_ROOT}" "${DEST_IMG}"

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

# ADDPART adds a partition of a given size, partition type and file system
#
# Usage: ADDPART SIZE PTYPE FS
ADDPART() {
  if [ $# -ne 3 ]; then
    echo -e "\033[0;31m### Error: usage ADDPART SIZE PTYPE FS\033[0m"
    return 1
  fi

  echo -e "\033[0;32m### ADDPART ${1} ${2} ${3}\033[0m"

  if [[ -b "${DEST_IMG}" ]]; then
    echo -e "\033[0;31m### Error: Block device ${DEST_IMG} cannot be altered.\033[0m"
    return 1
  fi

  BS="1M"

  # units does not print to stderr, thus test call before using output
  echo -n "addpart conversion to ${BS} * "
  units -t "${1}B" "${BS}B"

  COUNT=$(units -t ${1}B ${BS}B)

  # Ceil the number if a decimal is given.
  if [[ "${COUNT}" == *.* ]]; then
    COUNT=$(( $(echo "${COUNT}" | cut -d. -f1) + 1 ))
  fi

  echo "addpart ceil: ${BS} * ${COUNT}"

  # Error on unset PTYPE
  if [[ -z ${2+x} ]]; then
    echo -e "\033[0;31m### Error: Partition type unspecified, possible options:\033[0m"
    sfdisk -T
    return 1
  fi

  echo "checking mkfs.${3}"

  if ! command -v mkfs.${3}; then
    echo -e "\033[0;31m### Error: file system ${3} is not available.\033[0m"
    return 1
  fi

  dd if=/dev/zero bs="${BS}" count="${COUNT}" >> "${DEST_IMG}"

  local data_part_start
  data_part_start=$(( $(sfdisk -l "${DEST_IMG}" -o END -n | tail -n1) + 1 ))

  echo "$data_part_start,+,${2}" | sfdisk -a "${DEST_IMG}"

  local loop
  loop=$(mount_image "${DEST_IMG}")

  mkfs.${3} "/dev/mapper/${loop}p$((IMG_ROOT + 1))"

  umount_image "${loop}"
}
