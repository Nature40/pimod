pre_stage() {
  chroot_setup $DEST_IMG
}

post_stage() {
  chroot_teardown $DEST_IMG
}

# INSTALL installs a given file or directory to the given directory in the
# image. The permission mode (chmod) can be optionally set as the first
# parameter.
# Usage: INSTALL [MODE] SOURCE DEST
INSTALL() {
  echo -e "\033[0;32m### INSTALL $@\033[0m"
  case "$#" in
    "2")
      cp -a "$1" "${CHROOT_MOUNT}/${2}"
      ;;

    "3")
      cp -a "$2" "${CHROOT_MOUNT}/${3}"
      chmod $1 "${CHROOT_MOUNT}/${3}"
      ;;

    *)
      echo "Error: INSTALL [MODE] SOURCE DEST"
      return 1
      ;;
  esac
}

# RUN executes a command in the chrooted image.
# Usage: RUN CMD PARAMS...
RUN() {
  echo -e "\033[0;32m### RUN $@\033[0m"
  chroot $CHROOT_MOUNT "$@"
}
