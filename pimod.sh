#!/usr/bin/env bash

set -euE

pushd "$(dirname "$0")" > /dev/null

. ./modules/chroot.sh
. ./modules/env.sh
. ./modules/error.sh
. ./modules/esceval.sh
. ./modules/from_remote.sh
. ./modules/mount.sh
. ./modules/path.sh
. ./modules/pifile.sh
. ./modules/qemu.sh
. ./modules/resolv_conf.sh
. ./modules/workdir.sh

popd > /dev/null

show_help() {
  cat <<EOF
Usage: ${0} [Options] Pifile

Options:
  -c --cache DEST   Define cache location.
  -d --debug        Debug on failure; run an interactive shell before tear down.
  -h --help         Print this help message.
  -r --resolv TYPE  Specify which /etc/resolv.conf file to use for networking.
                    By default, TYPE "auto" is used, which prefers an already
                    existing resolv.conf, only to be replaced by the host's if
                    missing.
                    TYPE "guest" never mounts the host's file within the guest,
                    even when such a file is absent within the image.
                    TYPE "host" always uses the host's file within the guest.
                    Be aware that when run within Docker, the host's file might
                    be Docker's resolv.conf file.
  -t --trace        Trace each executed command for debugging.
EOF
}

main() {
  local pifile

  while :; do
    case "$1" in
      -c|--cache)
        [[ "$#" -le "2" ]] && (echo "Usage: $0 --cache DEST"; exit 1)
        # PIMOD_CACHE is defined in modules/from_remote.sh
        PIMOD_CACHE="$2"
        shift
        ;;

      -d|--debug)
        # PIMOD_DEBUG is defined in modules/error.sh
        PIMOD_DEBUG=1
        ;;

      -h|--help)
        show_help
        exit 0
        ;;

      -r|--resolv)
        [[ "$#" -le "2" ]] && (echo "Usage: $0 --resolv KIND"; exit 1)
        case "$2" in
          auto|guest|host)
            # PIMOD_HOST_RESOLV_TYPE is defined in modules/resolv_conf.sh
            PIMOD_HOST_RESOLV_TYPE="$2"
            ;;

          *)
            echo "Usage: $0 --resolv KIND"
            exit 1
        esac
        shift
        ;;

      -t|--trace)
        set -x
        ;;

      -?*)
        show_help
        exit 1
        ;;

      *)
        pifile="$1"
        break
    esac

    shift
  done

  if [[ -z "$pifile" ]]; then
    show_help
    exit 1
  fi

  execute_pifile "$pifile"
}

main "$@"
