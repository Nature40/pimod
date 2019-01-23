pre_stage() {
  chroot_setup $DEST_IMG
}

post_stage() {
  chroot_teardown $DEST_IMG
}

# ENABLE_UART enables the UART/serial port of the Pi.
# Usage: ENABLE_UART
ENABLE_UART() {
  grep -qxF "enable_uart=1" /mnt/rpi/boot/config.txt || \
    echo enable_uart=1 >> /mnt/rpi/boot/config.txt
}

# INSTALL installs a given file or directory to the given directory in the
# image. The permission mode (chmod) can be optionally set as the first
# parameter.
# Usage: INSTALL [MODE] SOURCE DEST
INSTALL() {
  case "$#" in
    "2")
      if [ -d $1 ]; then
        install -d "$1" "/mnt/rpi${2}"
      else
        install "$1" "/mnt/rpi${2}"
      fi
      ;;

    "3")
      if [ -d $2 ]; then
        install -d -m $1 "$2" "/mnt/rpi${3}"
      else
        install -m $1 "$2" "/mnt/rpi${3}"
      fi
      ;;

    *)
      echo "Usage: INSTALL [MODE] SOURCE DEST"
      return 1
      ;;
  esac
}

# RUN executes a command in the chrooted image.
# Usage: RUN CMD PARAMS...
RUN() {
  proot -0 -q qemu-arm-static -w / -r /mnt/rpi $@
}
