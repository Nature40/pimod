if [ -z "${PIMOD_HOST_RESOLV_TYPE+x}" ]; then
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
      # Always use the host's DNS configuration.
      # When the host uses the systemd-resolved stub resolver, its
      # /etc/resolv.conf only points at 127.0.0.53, which is not reachable
      # from within the chroot. In that case copy the real upstream servers
      # from /run/systemd/resolve/resolv.conf instead of bind mounting the
      # stub file.
      if grep -q "127.0.0.53" /etc/resolv.conf 2>/dev/null && [ -f /run/systemd/resolve/resolv.conf ]; then
        # Back up the image's own resolv.conf so it can be restored on
        # teardown, then drop in the host's resolved upstream servers.
        if [[ -e "${resolv_conf}" || -L "${resolv_conf}" ]]; then
          RESOLV_CONF_BACKUP=$(mktemp -u)
          mv "${resolv_conf}" "${RESOLV_CONF_BACKUP}"
        fi
        cp /run/systemd/resolve/resolv.conf "${resolv_conf}"
        RESOLV_CONF_COPIED=1
        return
      fi
      # Otherwise fall through to the bind mount below.
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
  local resolv_conf="${CHROOT_MOUNT}/etc/resolv.conf"

  if [[ -n ${RESOLVE_MOUNT+x} ]]; then
    umount "${resolv_conf}"
  elif [[ -n ${RESOLV_CONF_COPIED+x} ]]; then
    rm -f "${resolv_conf}"
  else
    return 0
  fi

  if [[ -n ${RESOLV_CONF_BACKUP+x} ]]; then
    mv "${RESOLV_CONF_BACKUP}" "${resolv_conf}"
  fi
}
