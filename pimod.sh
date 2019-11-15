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
  -d        Debug on failure; run an interactive shell before teardown
  -h        Print this help message.
EOF
}

DEBUG=0

while getopts "hd" opt; do
  case "$opt" in
  h)
    show_help
    exit 0
    ;;
  d)
    DEBUG=1
    ;;
  esac
done

PIFILE=${@:$OPTIND:1}

if [[ -z "${PIFILE}" ]]; then
  show_help
  exit 1
fi

execute_pifile "${PIFILE}"
