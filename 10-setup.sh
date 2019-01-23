post_stage() {
  if [ -z $SOURCE_IMG ]; then
    echo "SOURCE_IMG was not set; please call FROM"
    return 1
  fi

  if [ -z $DEST_IMG ]; then
    DEST_IMG="`dirname $SOURCE_IMG`/rpi.img"
    echo "DEST_IMG was not set, defaults to $DEST_IMG"
  fi

  cp $SOURCE_IMG $DEST_IMG
}

# FROM sets the SOURCE_IMG variable to the given file. This file will be used
# as source base file.
# Usage: FROM PATH_TO_IMAGE
FROM() {
  if [[ ! -f "$1" ]]; then
    echo "$1 does not exists!"
    return 1
  fi

  SOURCE_IMG=$1
}

# TO sets the DEST_IMG variable to the given file. This file will be contain
# the new image. Existing files will be overridden. If TO is not called, the
# default DEST_IMG will be rpi.img in the source file's directory.
TO() {
  if [[ -f "$1" ]]; then
    rm "$1"
  fi

  DEST_IMG=$1
}
