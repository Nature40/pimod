#!/usr/bin/env bash

set -eE

if [ -z "${1}" ]; then
  echo "Usage: ${0} Pifile"
  exit 1
fi

PIMOD_BASE="`dirname $0`"

for mod in ${PIMOD_BASE}/modules/*.sh; do
  . "${mod}"
done

execute_pifile "${1}"
