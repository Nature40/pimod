pre_stage() {
  chroot_setup "${DEST_IMG}" "${IMG_ROOT}"

  resolv_conf_setup
}

# INSTALL installs a given file or directory into the destination in the
# image. The optionally permission mode (chmod) can be set as the first
# parameter.
#
# Usage: INSTALL [MODE] SOURCE DEST
INSTALL() {
  echo -e "\033[0;32m### INSTALL $*\033[0m"

  local src=""
  local dst=""

  case "$#" in
    "2")
      src="$1"
      dst="$2"
      ;;

    "3")
      src="$2"
      dst="$3"
      ;;

    *)
      echo -e "\033[0;31m### Error: INSTALL [MODE] SOURCE DEST\033[0m"
      return 1
      ;;
  esac

  if [[ -d "${src}" ]]; then
    cp -r -T -P --preserve=mode "${src}" "${CHROOT_MOUNT}/${dst}"
  else
    cp -r -P --preserve=mode "${src}" "${CHROOT_MOUNT}/${dst}"
  fi

  if [[ "$#" -eq "3" ]]; then
    chmod "$1" "${CHROOT_MOUNT}/${dst}"
  fi
}

# EXTRACT copies a given file or directory from the image to the destination.
#
# Usage: EXTRACT SOURCE DEST
EXTRACT() {
  echo -e "\033[0;32m### EXTRACT $*\033[0m"

  local src="${CHROOT_MOUNT}/$1"
  local dst=$2

  if [[ -d "${src}" ]]; then
    cp -r -T -P --preserve=mode "${src}" "${dst}"
  else
    cp -r -P --preserve=mode "${src}" "${dst}"
  fi
}

# PATH adds the given path to an overlaying PATH variable, used within the RUN
# command.
#
# Usage: PATH /my/guest/path
PATH() {
  path_add "${1}"
  echo -e "\033[0;32m### PATH ${GUEST_PATH}\033[0m"
}

# WORKDIR sets the working directory within the image.
#
# Usage: WORKDIR /my/guest/path
WORKDIR() {
  workdir_set "${1}"
  echo -e "\033[0;32m### WORKDIR ${WORKDIR_PATH}\033[0m"
}

# ENV either sets or unsets an environment variable to be used within the image.
# If two parameters are given, the first is the key and the second the value.
# If one parameter is given, the environment variable will be removed.
#
# An environment variable can be either used via $VAR within another sub-shell
# (sh -c 'echo $VAR') or substituted beforehand via @@VAR@@.
#
# Usage: ENV KEY [VALUE]
ENV() {
  local key=""
  local value=""

  case "$#" in
    "1")
      key="$1"
      env_vars_del "$key"
      ;;

    "2")
      key="$1"
      value="$2"
      env_vars_set "$key" "$value"
      ;;

    *)
      echo -e "\033[0;31m### Error: ENV KEY [VALUE]\033[0m"
      return 1
      ;;
  esac

  echo -e "\033[0;32m### ENV ${key}=${value}\033[0m"
}

# RUN executes a command in the chrooted image based on QEMU user emulation.
#
# Caveat: because the Pifile is just a Bash script, pipes do not work as one
# might suspect. A possible workaround could be the usage of `bash -c`:
# > RUN bash -c 'hexdump /dev/urandom | head'
#
# Usage: RUN CMD PARAMS...
RUN() {
  echo -e "\033[0;32m### RUN ${*}\033[0m"

  local cmd_esceval="$(esceval "$@")"
  local cmd_env_subst="$(env_vars_subst "$cmd_esceval")"

  PATH=${GUEST_PATH} chroot "${CHROOT_MOUNT}" \
    /bin/sh -c "cd ${WORKDIR_PATH}; $(env_vars_export_cmd) ${cmd_env_subst}"
}

# HOST executed a command on the local host and can be used to prepare files,
# cross-compile software, etc.
#
# Usage: HOST CMD PARAMS...
HOST() {
  echo -e "\033[0;32m### HOST ${*}\033[0m"

  local cmd_esceval="$(esceval "$@")"
  local cmd_env_subst="$(env_vars_subst "$cmd_esceval")"

  /bin/sh -c "$(env_vars_export_cmd) ${cmd_env_subst}"
}
