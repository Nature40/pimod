# chroot_setup mounts the given image file and prepares a chroot.
# Usage: chroot_setup PATH_TO_IMAGE
chroot_setup() {
  trap 'handle_error ${?} "${@}"' ERR

  LOOP=`mount_image "${1}"`
  CHROOT_MOUNT=`mktemp -d`

  local loop_root="/dev/mapper/${LOOP}p${IMG_ROOT}"
  mount "${loop_root}" "${CHROOT_MOUNT}/"

  local mnt_targets="/dev /sys /proc /dev/pts"
  for mnt_target in ${mnt_targets}; do
    [ ! -d "${CHROOT_MOUNT}${mnt_target}" ] && mkdir -p "${CHROOT_MOUNT}${mnt_target}"
    mount --bind "${mnt_target}" "${CHROOT_MOUNT}${mnt_target}"
  done

  #mount --bind /dev "${CHROOT_MOUNT}/dev"
  #mount --bind /sys "${CHROOT_MOUNT}/sys"
  #mount --bind /proc "${CHROOT_MOUNT}/proc"
  #mount --bind /dev/pts "${CHROOT_MOUNT}/dev/pts"

  # disable preloading (not working because of missing paths)
  test -f "${CHROOT_MOUNT}/etc/ld.so.preload" && \
    sed -i 's/^/#/g' "${CHROOT_MOUNT}/etc/ld.so.preload"

  # copy qemu binaries for selected platforms
  [ ! -d "${CHROOT_MOUNT}/usr/bin" ] && mkdir -p "${CHROOT_MOUNT}/usr/bin"

  for arch in ${QEMU_ARCHS}; do
    cp "/usr/bin/qemu-${arch}-static" "${CHROOT_MOUNT}/usr/bin/"
    update-binfmts --enable qemu-${arch}
  done

  # mount additional partitions
  # chroot "${CHROOT_MOUNT}" mount -a  # XXX: remove comment
}

# chroot_teardown unmounts the given image file, mounted with chroot_setup.
# Usage: chroot_teardown PATH_TO_IMAGE
chroot_teardown() {
  for arch in ${QEMU_ARCHS}; do
    update-binfmts --disable qemu-${arch}
    rm "${CHROOT_MOUNT}/usr/bin/qemu-${arch}-static"
  done

  # enable preloading libraries
  test -f "${CHROOT_MOUNT}/etc/ld.so.preload" && \
    sed -i 's/^#//g' "${CHROOT_MOUNT}/etc/ld.so.preload"

  # umount "${CHROOT_MOUNT}/boot"
  umount -Rv "${CHROOT_MOUNT}/"

  rm -r "${CHROOT_MOUNT}"
  unset CHROOT_MOUNT

  umount_image "${LOOP}"
  unset LOOP
}

