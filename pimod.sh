#!/usr/bin/env bash

set -euE

PIMOD_BASE="`dirname $0`"
for mod in ${PIMOD_BASE}/modules/*.sh; do
  . "${mod}"
done

if [[ -z ${1+x} ]]; then
  echo "Usage: ${0} Pifile"
  exit 1
fi

execute_pifile "${1}"
