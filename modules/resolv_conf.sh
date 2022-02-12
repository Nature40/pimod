if [ -z "${PIMOD_HOST_RESOLV+x}" ]; then
  PIMOD_HOST_RESOLV_TYPE="auto"
fi

# resolv_conf_setup checks the /etc/resolv.conf file within an image and remaps
# it, if necessary.
resolv_conf_setup() {
  local resolv_conf="${CHROOT_MOUNT}/etc/resolv.conf"

  case "${PIMOD_HOST_RESOLV_TYPE}" in
    auto)
      # Do not mount the host's file when a /etc/resolv.conf already exists.
      ((test -f "${resolv_conf}") || (RUN test -e "/etc/resolv.conf")) && return
      ;;

    guest)
      # Never mount the host's file.
      return
      ;;

    host)
      # Always mount the host's file as an overlay.
      ;;

    *)
      echo -e "\033[0;31m### Error: unknown resolv type ${PIMOD_HOST_RESOLV_TYPE} \033[0m"
      return 1
  esac

  if [[ -L "${resolv_conf}" ]]; then
    RESOLV_CONF_BACKUP=$(mktemp -u)
    mv "${resolv_conf}" "${RESOLV_CONF_BACKUP}"
  fi

  if ! touch "${resolv_conf}"; then
    echo -e "\033[0;31m### Error: Mounting ${resolv_conf} failed.\033[0m"
    return 1
  fi
  mount -o ro,bind /etc/resolv.conf "${resolv_conf}"

  RESOLVE_MOUNT=1
}

# resolv_conf_teardown resets the actions done by resolv_conf_setup.
resolv_conf_teardown() {
  [[ -z ${RESOLVE_MOUNT+x} ]] && return

  local resolv_conf="${CHROOT_MOUNT}/etc/resolv.conf"

  umount "${resolv_conf}"

  if [[ -n ${RESOLV_CONF_BACKUP+x} ]]; then
    mv "${RESOLV_CONF_BACKUP}" "${resolv_conf}"
  fi
}
