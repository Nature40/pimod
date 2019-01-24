#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 Pifile input.img output.img"
  exit 1
fi

touch `realpath $3`
docker run -t --rm --privileged \
  -v `realpath $1`:/Pifile \
  -v `realpath $2`:/`basename $2` \
  -v `realpath $3`:/`basename $3` \
  pimod
