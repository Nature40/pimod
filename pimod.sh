#!/usr/bin/env bash

set -euE

PIMOD_BASE="`dirname $0`"
for mod in ${PIMOD_BASE}/modules/*.sh; do
  . "${mod}"
done

show_help() {
  cat <<EOF
Usage: ${0} [Options] Pifile

Options:
  -c cache  Define cache location.
  -d        Debug on failure; run an interactive shell before tear down
  -h        Print this help message.
EOF
}

while getopts "c:dh" opt; do
  case "${opt}" in
  c)
    PIMOD_CACHE="${OPTARG}"
    ;;
  d)
    PIMOD_DEBUG=1
    ;;
  h)
    show_help
    exit 0
    ;;
  esac
done

PIFILE=${@:$OPTIND:1}

if [[ -z "${PIFILE}" ]]; then
  show_help
  exit 1
fi

execute_pifile "${PIFILE}"
