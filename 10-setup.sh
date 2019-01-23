post_stage() {
  if [ -z $SOURCE_IMG ]; then
    echo "SOURCE_IMG was not set; please call FROM"
    return 1
  fi

  DEST_IMG="/result/rpi.img"
  cp $SOURCE_IMG $DEST_IMG
}

# FROM sets the SOURCE_IMG variable to the given file.
# Usage: FROM PATH_TO_IMAGE
FROM() {
  if [[ ! -f "$1" ]]; then
    echo "$1 does not exists!"
    return 1
  fi

  SOURCE_IMG=$1
}
