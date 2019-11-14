QEMU_ARCHS="arm armeb aarch64"

qemu_setup() {
  # disable preloading (not working because of missing paths)
  [[ -f "${CHROOT_MOUNT}/etc/ld.so.preload" ]] && \
    sed -i 's/^/#/g' "${CHROOT_MOUNT}/etc/ld.so.preload"

  QEMU_HOST=`mktemp -d`

  for arch in ${QEMU_ARCHS}; do
    ln -t "${QEMU_HOST}" "/usr/bin/qemu-${arch}-static"
    update-binfmts --enable qemu-${arch}
  done

  QEMU_GUEST=`mktemp -d -p "${CHROOT_MOUNT}"`
  mount --bind "${QEMU_HOST}" "${QEMU_GUEST}"
  path_add "/`basename ${QEMU_GUEST}`"
}

qemu_teardown() {
  for arch in ${QEMU_ARCHS}; do
    update-binfmts --disable qemu-${arch}
  done

  umount "${QEMU_GUEST}"
  rm -r "${QEMU_HOST}"

  # enable preloading libraries
  [[ -f "${CHROOT_MOUNT}/etc/ld.so.preload" ]] && \
    sed -i 's/^#//g' "${CHROOT_MOUNT}/etc/ld.so.preload"

  return 0
}
