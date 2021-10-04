post_stage() {
  resolv_conf_teardown

  chroot_teardown "${DEST_IMG}"
}

# PUMP increases the image's size about the given amount.
#
# Usage: PUMP SIZE_IN_MB
PUMP() {
  echo -e "\033[0;32m### PUMP ${1}; file system usage:\033[0m"
  df -h "${CHROOT_MOUNT}"
}
