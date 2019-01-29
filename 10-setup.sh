post_stage() {
  if [ -z $SOURCE_IMG ]; then
    echo "Error: SOURCE_IMG was not set; please call FROM"
    return 1
  fi

  if [ -z $DEST_IMG ]; then
    DEST_IMG="`dirname $SOURCE_IMG`/rpi.img"
    echo "DEST_IMG was not set, defaults to $DEST_IMG"
  fi
  echo -e "\033[0;32m### TO $DEST_IMG\033[0m"

  cp $SOURCE_IMG $DEST_IMG
}

# FROM sets the SOURCE_IMG variable to the given file. This file will be used
# as the base for the new image.
#
# Usage: FROM PATH_TO_IMAGE
FROM() {
  if [[ ! -f "$1" ]]; then
    echo "Error: $1 does not exists!"
    return 1
  fi

  echo -e "\033[0;32m### FROM $1\033[0m"
  SOURCE_IMG=$1
}

# TO sets the DEST_IMG variable to the given file. This file will contain the
# new image. Existing files will be overridden.
#
# Instead of calling TO, the Pifile's filename can also indicate the output
# file, if the Pifile ends with ".Pifile". The part before this suffix will be
# the new DEST_IMG.
#
# If neither TO is called nor the Pifile indicates the output, DEST_IMG will
# default to rpi.img in the source file's directory.
#
# Usage: TO PATH_TO_IMAGE
TO() {
  DEST_IMG=$1
}
