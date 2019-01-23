# PUMP increases the image's size about the given amount of megabytes.
# Usage: PUMP SIZE_IN_MB
PUMP() {
  dd if=/dev/zero bs=1M count=$1 >> $DEST_IMG

  local loop=`mount_image $DEST_IMG`

  e2fsck -f "/dev/mapper/${loop}p2"
  resize2fs "/dev/mapper/${loop}p2"

  fdisk -l "/dev/${loop}"

  umount_image $DEST_IMG
}
