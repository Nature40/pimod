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
  -h        Print this help message.
EOF
}

while getopts "h" opt; do
  case "$opt" in
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
