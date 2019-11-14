# chroot_setup mounts the given image file and prepares a chroot.
# Usage: chroot_setup PATH_TO_IMAGE
chroot_setup() {
  trap 'handle_error ${?} "${@}"' ERR

  LOOP=`mount_image "${1}"`
  CHROOT_MOUNT=`mktemp -d`

  local loop_root="/dev/mapper/${LOOP}p${IMG_ROOT}"
  mount "${loop_root}" "${CHROOT_MOUNT}/"

  mount --bind /dev "${CHROOT_MOUNT}/dev"
  mount --bind /sys "${CHROOT_MOUNT}/sys"
  mount --bind /proc "${CHROOT_MOUNT}/proc"
  mount --bind /dev/pts "${CHROOT_MOUNT}/dev/pts"

  qemu_setup

  # mount additional partitions
  chroot "${CHROOT_MOUNT}" mount -a
}

# chroot_teardown unmounts the given image file, mounted with chroot_setup.
# Usage: chroot_teardown PATH_TO_IMAGE
chroot_teardown() {
  qemu_teardown

  # umount "${CHROOT_MOUNT}/boot"
  umount -Rv "${CHROOT_MOUNT}/"

  rm -r "${CHROOT_MOUNT}"
  unset CHROOT_MOUNT

  umount_image "${LOOP}"
  unset LOOP
}

