#!/usr/bin/env bash
set -e

# mount_image mounts the given image file as a loop device and "returns"/prints
# the name of the loop device (e.g. loop0).
# Usage: mount_image /tmp/raspi.img
mount_image() {
  kpartx -avs "$1" \
    | sed -E 's/.*(loop[0-9])p.*/\1/g' \
    | head -n 1
}

# umount_image unmounts the given image file, mounted with mount_image.
# Usage: umount_image /tmp/raspi.img
umount_image() {
  kpartx -d "$1"
}

# pump_image increases the size of the given image and fixes its partition
# table.
# Usage: pump_image PATH_TO_IMAGE PUMP_SIZE_IN_MB
pump_image() {
  dd if=/dev/zero of="$1" bs=1M count=$2 oflag=append conv=notrunc

  local loop=`mount_image $1`
  parted "/dev/${loop}" -- resizepart 2 -1s
  umount_image $1
}

arm_chroot() {
  proot -0 -q qemu-arm-static -w / -r /mnt/rootfs $@
}


pump_image "/result/rpi.img" 200


#LOOP_BOOT="/dev/mapper/${LOOP}p1"
#LOOP_ROOT="/dev/mapper/${LOOP}p2"

# write files
#mkdir -p /mnt/bootfs
#mkdir -p /mnt/rootfs

#mount $LOOP_BOOT /mnt/bootfs
#mount $LOOP_ROOT /mnt/rootfs

# ricing
# echo baumbox > /mnt/rootfs/etc/hostname
# echo "127.0.0.1\tbaumbox" >> /mnt/rootfs/etc/hosts

# cat > /mnt/rootfs/etc/fstab << EOF
# /dev/mmcblk0p1 /boot vfat sync,dirsync         0 0
# /dev/mmcblk0p2 /     ext4 sync,dirsync,noatime 0 0
# proc           /proc proc defaults             0 0
#
# EOF

# arm_chroot /bin/systemctl disable getty@ttyS0.service
# arm_chroot /bin/systemctl disable serial-getty@ttyS0.service

#sync

#umount /mnt/bootfs
#umount /mnt/rootfs

