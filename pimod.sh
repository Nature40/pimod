#!/usr/bin/env bash
set -e

# mount_image mounts the given image file as a loop device and "returns"/prints
# the name of the loop device (e.g. loop0).
# Usage: mount_image PATH_TO_IMAGE
mount_image() {
  kpartx -avs "$1" \
    | sed -E 's/.*(loop[0-9])p.*/\1/g' \
    | head -n 1
}

# umount_image unmounts the given image file, mounted with mount_image.
# Usage: umount_image PATH_TO_IMAGE
umount_image() {
  kpartx -d "$1"
  dmsetup remove_all
}

# chroot_setup mounts the given image file and prepares a chroot.
# Usage: chroot_setup PATH_TO_IMAGE
chroot_setup() {
  local loop=`mount_image $1`

  local loop_boot="/dev/mapper/${loop}p1"
  local loop_root="/dev/mapper/${loop}p2"

  mkdir -p /mnt/rpi

  mount $loop_root /mnt/rpi
  mount $loop_boot /mnt/rpi/boot

  mount --bind /dev /mnt/rpi/dev
  mount --bind /sys /mnt/rpi/sys
  mount --bind /proc /mnt/rpi/proc
  mount --bind /dev/pts /mnt/rpi/dev/pts

  sed -i 's/^/#/g' /mnt/rpi/etc/ld.so.preload
}

# chroot_teardown unmounts the given image file, mounted with chroot_setup.
# Usage: chroot_teardown PATH_TO_IMAGE
chroot_teardown() {
  sed -i 's/^#//g' /mnt/rpi/etc/ld.so.preload

  umount /mnt/rpi/{dev/pts,proc,sys,dev,boot,}

  umount_image $1
}

# execute_pifile runs the given Pifile.
# Usage: execute_pifile PIFILE
execute_pifile() {
  if [ -z $1 ] || [ ! -f $1 ]; then
    echo "No given file or file does not exists"
    return 1
  fi

  bash -n $1

  stages=("10-setup.sh" "20-prepare.sh" "30-chroot.sh")
  for stage in "${stages[@]}"; do
    . 00-commands.sh
    . $stage

    pre_stage
    . $1
    post_stage
  done
}


# TODO: check if this is necessary
update-binfmts --enable qemu-arm


if [ -z $1 ]; then
  echo "Usage: $0 Pifile"
  exit 1
fi

execute_pifile $1
