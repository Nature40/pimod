#!/usr/bin/env bash
set -e

# create image and its partitions
dd if=/dev/zero of=/result/rpi.img bs=1MB count=512
LOOP=`losetup -P --show -f /result/rpi.img | sed -E 's/.*(loop[0-9])/\1/g'`
fdisk "/dev/${LOOP}" << EOF
o
n
p
1
 
+64M
t
c
n
p
2
 
 
w
EOF
losetup -d "/dev/${LOOP}"

LOOP=`kpartx -avs /result/rpi.img | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -n 1`

LOOP_BOOT="/dev/mapper/${LOOP}p1"
LOOP_ROOT="/dev/mapper/${LOOP}p2"

# create file systems
mkfs.vfat $LOOP_BOOT
mkfs.ext4 $LOOP_ROOT

# write files
mkdir -p /mnt/bootfs
mkdir -p /mnt/rootfs

mount $LOOP_BOOT /mnt/bootfs
mount $LOOP_ROOT /mnt/rootfs

# multistrap straps a Debian/Raspbian to rootfs
multistrap -d /mnt/rootfs -f /multistrap.conf

# install the RaspberryPi's firmware
git clone --depth=1 https://github.com/raspberrypi/firmware.git /rpi-firmware
cp -ar /rpi-firmware/hardfp/opt/* /mnt/rootfs/opt/
cp -r /rpi-firmware/modules /mnt/rootfs/lib/
cp -r /rpi-firmware/boot/* /mnt/bootfs/

cat > /mnt/bootfs/config.txt << EOF
enable_uart=1
EOF

cat > /mnt/bootfs/cmdline.txt << EOF
dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet
EOF

umount /mnt/bootfs
umount /mnt/rootfs

kpartx -d /result/rpi.img
