# PUMP increases the image's size about the given amount of megabytes.
#
# Usage: PUMP SIZE_IN_MB
PUMP() {
  echo -e "\033[0;32m### PUMP ${1}\033[0m"
  dd if=/dev/zero bs=${1} count=1 >> "${DEST_IMG}"

  TARGET_DETAILS=($(fdisk -l "${DEST_IMG}" | tail -n1))
  (fdisk "${DEST_IMG}" || echo "Continue...") <<EOF
delete
${IMG_ROOT}
new
primary
${IMG_ROOT}
${TARGET_DETAILS[1]}

w
EOF

  local loop=`mount_image "${DEST_IMG}"`

  e2fsck -y -f "/dev/mapper/${loop}p${IMG_ROOT}"
  resize2fs "/dev/mapper/${loop}p${IMG_ROOT}"

  fdisk -l "/dev/${loop}"

  umount_image "${loop}"
}
