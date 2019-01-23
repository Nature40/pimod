pre_stage() {
  chroot_setup $DEST_IMG
}

post_stage() {
  chroot_teardown $DEST_IMG
}

# ENABLE_UART enables the UART/serial port of the Pi.
# Usage: ENABLE_UART
ENABLE_UART() {
  echo enable_uart=1 >> /mnt/rpi/boot/config.txt
}

# RUN executes a command in the chrooted image.
# Usage: RUN CMD
RUN() {
  proot -0 -q qemu-arm-static -w / -r /mnt/rpi $@
}
