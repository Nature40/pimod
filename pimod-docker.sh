#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 Pifile input.img output.img"
  exit 1
fi

touch `realpath $3`
docker run -t --rm --privileged \
  -v `realpath $1`:/pimod/Pifile \
  -v `realpath $2`:/pimod/`basename $2` \
  -v `realpath $3`:/pimod/`basename $3` \
  pimod
