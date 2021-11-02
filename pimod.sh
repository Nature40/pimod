#!/usr/bin/env bash

set -euE

pushd "$(dirname "$0")" > /dev/null

. ./modules/chroot.sh
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
  -c cache  Define cache location.
  -d        Debug on failure; run an interactive shell before tear down
  -t        Trace each executed command for debugging.
  -h        Print this help message.
EOF
}

while getopts "c:dth" opt; do
  case "${opt}" in
  c)
    PIMOD_CACHE="${OPTARG}"
    ;;
  d)
    PIMOD_DEBUG=1
    ;;
  t)
    set -x
    ;;
  h)
    show_help
    exit 0
    ;;
  *)
    show_help
    exit 1
    ;;
  esac
done

PIFILE=${*:$OPTIND:1}

if [[ -z "${PIFILE}" ]]; then
  show_help
  exit 1
fi

execute_pifile "${PIFILE}"
