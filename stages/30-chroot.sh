pre_stage() {
  chroot_setup "${DEST_IMG}" "${IMG_ROOT}"

  resolv_conf_setup
}

post_stage() {
  chroot_teardown "${DEST_IMG}"
}

# INSTALL installs a given file or directory into the destination in the
# image. The optionally permission mode (chmod) can be set as the first
# parameter.
#
# Usage: INSTALL [MODE] SOURCE DEST
INSTALL() {
  echo -e "\033[0;32m### INSTALL $@\033[0m"
  case "$#" in
    "2")
      cp -d -R --preserve=mode "${1}" "${CHROOT_MOUNT}/${2}"
      ;;

    "3")
      cp -d -R --preserve=mode "${2}" "${CHROOT_MOUNT}/${3}"
      chmod "${1}" "${CHROOT_MOUNT}/${3}"
      ;;

    *)
      echo -e "\033[0;31m### Error: INSTALL [MODE] SOURCE DEST\033[0m"
      return 1
      ;;
  esac
}

# RUN executes a command in the chrooted image based on QEMU user emulation.
#
# Caveat: because the Pifile is just a Bash script, pipes do not work as one
# might suspect. A possible workaround could be the usage of `bash -c`:
# > RUN bash -c 'hexdump /dev/urandom | head'
#
# Usage: RUN CMD PARAMS...
RUN() {
  echo -e "\033[0;32m### RUN ${@}\033[0m"
  chroot "${CHROOT_MOUNT}" "${@}"
}
