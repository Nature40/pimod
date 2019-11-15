# from_remote_valid checks if the given string indicates a valid URL.
from_remote_valid() {
  local schemeRegexp="^(https?|ftp)://.*"
  [[ $1 =~ $schemeRegexp ]]
}

# unarchive_image extracts files from an image and moves the largest to a given path.
unarchive_image() {
  local archive="${1}"
  local tmpfile="${2}"
  local unzip_dir=`mktemp -d`

  7z e -bd -o"${unzip_dir}" "${archive}"
  rm "${archive}"

  # pick largest file, as it is most likely the image
  local unzip_image=`ls -S -1 "${unzip_dir}" | head -n1`
  mv "${unzip_dir}/${unzip_image}" "${tmpfile}"
}

# from_remote_fetch tries to fetch a remote image and uses it for FROM.
from_remote_fetch() {
  local tmpfile=`mktemp -u`
  local logfile=`mktemp -u`
  local download_cmd="wget --progress=dot:giga -O ${tmpfile} $1"

  if ! `${download_cmd}`; then
    while read -r line; do
      echo -e "\033[0;31m### Error: ${line}\033[0m"
    done < "${logfile}"

    return 1
  fi

  local mime=`file -b --mime-type "${tmpfile}"`
  case "${mime}" in
    application/octet-stream)
      # let's seriously hope it's an image..
      ;;

    application/zip)
      mv "${tmpfile}" "${tmpfile}.zip"
      unarchive_image "${tmpfile}.zip" "${tmpfile}"
      ;;

    application/x-7z-compressed)
      mv "${tmpfile}" "${tmpfile}.7z"
      unarchive_image "${tmpfile}.7z" "${tmpfile}"
      ;;

    application/gzip)
      mv "${tmpfile}" "${tmpfile}.gz"
      gunzip "${tmpfile}.gz"
      ;;

    application/x-xz)
      mv "${tmpfile}" "${tmpfile}.xz"
      unxz "${tmpfile}.xz"
      ;;

    *)
      echo -e "\033[0;31m### Error: Unknown MIME ${mime}\033[0m"
      return 1
      ;;
  esac

  SOURCE_IMG="${tmpfile}"
}
