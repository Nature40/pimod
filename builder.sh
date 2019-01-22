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
  dd if=/dev/zero bs=1M count=$2 >> $1

  local loop=`mount_image $1`

  e2fsck -f "/dev/mapper/${loop}p2"
  resize2fs "/dev/mapper/${loop}p2"

  fdisk -l "/dev/${loop}"

  umount_image $1
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

# chroot_exec executes a command in the chroot, created with chroot_setup.
# Usage: chroot_exec CMD
chroot_exec() {
  proot -0 -q qemu-arm-static -w / -r /mnt/rpi $@
}

update-binfmts --enable qemu-arm

pump_image "/result/rpi.img" 500

chroot_setup "/result/rpi.img"

chroot_exec uname -a
chroot_exec apt-get update
chroot_exec apt-get install -y sl

echo enable_uart=1 >> /mnt/rpi/boot/config.txt

chroot_teardown "/result/rpi.img"
