# resolv_conf_setup checks the /etc/resolv.conf file within an image and remaps
# it, if necessary.
resolv_conf_setup() {
  local resolv_conf="${CHROOT_MOUNT}/etc/resolv.conf"

  if [[ -f "${resolv_conf}" ]] && [[ -s "${resolv_conf}" ]]; then
    return
  fi

  if [[ -L "${resolv_conf}" ]]; then
    RESOLV_CONF_BACKUP=$(mktemp -u)
    mv "${resolv_conf}" "${RESOLV_CONF_BACKUP}"
  fi

  if ! touch "${resolv_conf}"; then
    echo -e "\033[0;33m### Warning: Mounting ${resolv_conf} failed.\033[0m"
    return
  fi
  mount -o ro,bind /etc/resolv.conf "${resolv_conf}"

  RESOLVE_MOUNT=1
}

# resolv_conf_teardown resets the actions done by resolv_conf_setup.
resolv_conf_teardown() {
  [[ -z ${RESOLVE_MOUNT+x} ]] && return 0

  local resolv_conf="${CHROOT_MOUNT}/etc/resolv.conf"

  umount "${resolv_conf}"

  if [[ -n ${RESOLV_CONF_BACKUP+x} ]]; then
    mv "${RESOLV_CONF_BACKUP}" "${resolv_conf}"
  fi
}
