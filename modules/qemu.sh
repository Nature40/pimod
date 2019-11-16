QEMU_ARCHS="arm armeb aarch64"

qemu_setup() {
  # disable preloading (not working because of missing paths)
  [[ -f "${CHROOT_MOUNT}/etc/ld.so.preload" ]] && \
    sed -i 's/^/#/g' "${CHROOT_MOUNT}/etc/ld.so.preload"

  QEMU_MOUNTS=""

  # bind mount
  for arch in ${QEMU_ARCHS}; do
    # get local paths of qemu
    local qemu_path=`which "qemu-${arch}-static"`
    local bin_path=`dirname "${qemu_path}"`

    # recreate bin folders
    mkdir -p "${CHROOT_MOUNT}/${bin_path}"
    touch "${CHROOT_MOUNT}/${qemu_path}"

    mount -o ro,bind "${qemu_path}" "${CHROOT_MOUNT}/${qemu_path}"
    QEMU_MOUNTS="$QEMU_MOUNTS ${CHROOT_MOUNT}/${qemu_path}"

    # enable arch
    update-binfmts --enable qemu-${arch}
  done
}

qemu_teardown() {
  # unmount qemu binaries, remove temp files
  umount ${QEMU_MOUNTS}
  rm ${QEMU_MOUNTS}
  unset QEMU_MOUNTS

  # disable arch
  for arch in ${QEMU_ARCHS}; do
    update-binfmts --disable qemu-${arch}
  done

  # enable preloading libraries
  [[ -f "${CHROOT_MOUNT}/etc/ld.so.preload" ]] && \
    sed -i 's/^#//g' "${CHROOT_MOUNT}/etc/ld.so.preload"

  return 0
}
