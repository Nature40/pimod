# chroot_setup mounts the given image file and prepares a chroot.
# Usage: chroot_setup PATH_TO_IMAGE
chroot_setup() {
  trap 'handle_error ${?} "${@}"' ERR

  LOOP=$(mount_image "${1}")
  CHROOT_MOUNT=$(mktemp -d)

  local loop_root="/dev/mapper/${LOOP}p${IMG_ROOT}"
  mount "${loop_root}" "${CHROOT_MOUNT}/"

  mount --bind /dev "${CHROOT_MOUNT}/dev"
  mount --rbind /sys "${CHROOT_MOUNT}/sys"
  mount --bind /proc "${CHROOT_MOUNT}/proc"
  mount --bind /dev/pts "${CHROOT_MOUNT}/dev/pts"

  qemu_setup

  # mount additional partitions
  chroot "${CHROOT_MOUNT}" mount -a || \
      echo -e "\033[0;33m### Warning: Mounting image partitions using /etc/fstab failed.\033[0m"
}

# zero_fill fills the unused space in the filesystem with zeros
# Usage: zero_fill
zero_fill() {
  local zero_file="${CHROOT_MOUNT}/zero.fill"

  dd if=/dev/zero of=${zero_file} bs=1M status=progress || true
  rm ${zero_file}
}

# chroot_teardown unmounts the given image file, mounted with chroot_setup.
# Usage: chroot_teardown PATH_TO_IMAGE
chroot_teardown() {
  # disable script abort on error
  set +eE
  # ignore further errors
  trap "" ERR

  mapfile -t RUNNING < <(lsof -t "${CHROOT_MOUNT}")
  if [ "${RUNNING[*]}" ]; then
    echo -e "\033[0;33m### Warning: Remaining processes (${RUNNING[*]}) are killed.\033[0m"
    kill -9 "${RUNNING[@]}"
  fi
  unset RUNNING

  qemu_teardown

  i=0
  while ! umount -Rflv "${CHROOT_MOUNT}/"; do
    if [ $((i=i+1)) -ge 10 ]; then
      return 102
    fi
    sleep 1
  done

  rm -r "${CHROOT_MOUNT}"
  unset CHROOT_MOUNT

  umount_image "${LOOP}"
  unset LOOP
}

