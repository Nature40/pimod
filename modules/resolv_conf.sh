# resolv_conf_setup checks the /etc/resolv.conf file within an image and remaps
# it, if necessary.
resolv_conf_setup() {
  trap 'handle_error ${?} "${@}"' ERR

  local resolv_conf="${CHROOT_MOUNT}/etc/resolv.conf"
  if [ -f "$resolv_conf" ] && [ -s "$resolv_conf" ]; then
    return
  fi

  if [ -L "$resolv_conf" ]; then
    rm "$resolv_conf"
  fi

  touch "$resolv_conf"

  mount -o ro,bind /etc/resolv.conf "$resolv_conf"
}
