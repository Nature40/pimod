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

# pump_image increases the size of the given image and fixes its partition
# table.
# Usage: pump_image PATH_TO_IMAGE PUMP_SIZE_IN_MB
pump_image() {
  dd if=/dev/zero of="$1" bs=1M count=$2 oflag=append conv=notrunc

  local loop=`mount_image $1`
  parted "/dev/${loop}" -- resizepart 2 -1s

  e2fsck -f "/dev/mapper/${loop}p2"
  resize2fs "/dev/mapper/${loop}p2"

  umount_image $1
}

# chroot_image mounts the given image file and drops a chroot.
# Usage: chroot_image PATH_TO_IMAGE
chroot_image() {
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

  arm_chroot uname -a

  sed -i 's/^#//g' /mnt/rpi/etc/ld.so.preload

  umount /mnt/rpi/{dev/pts,proc,sys,dev,boot,}

  umount_image $1
}

arm_chroot() {
  proot -0 -q qemu-arm-static -w / -r /mnt/rpi $@
}

update-binfmts --enable qemu-arm

# pump_image "/result/rpi.img" 200
chroot_image "/result/rpi.img"
