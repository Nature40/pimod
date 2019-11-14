# from_remote_valid checks if the given string indicates a valid URL.
from_remote_valid() {
  local schemeRegexp="^(https?|ftp)://.*"
  [[ $1 =~ $schemeRegexp ]]
}

# from_remote_fetch tries to fetch a remote image and uses it for FROM.
from_remote_fetch() {
  local tmpfile=`mktemp -u`
  local logfile=`mktemp -u`
  local download_cmd="wget -nv -O ${tmpfile} -o ${logfile} $1"

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
      local unzip_dir=`mktemp -d`

      mv "${tmpfile}" "${tmpfile}.zip"
      unzip -q -d "${unzip_dir}" "${tmpfile}.zip"

      local unzip_files=`ls -1 "${unzip_dir}" | wc -l`
      if [[ "$unzip_files" -ne "1" ]]; then
        echo -e "\033[0;31m### Error: Expected only one file in the ZIP archive, got ${unzip_files}\033[0m"
        return 1
      fi

      for f in ${unzip_dir}/*; do
        mv "${f}" "${tmpfile}"
      done
      ;;

    application/gzip)
      mv "${tmpfile}" "${tmpfile}.gz"
      gunzip "${tmpfile}.gz"
      ;;

    *)
      echo -e "\033[0;31m### Error: Unknown MIME ${mime}\033[0m"
      return 1
      ;;
  esac

  SOURCE_IMG="${tmpfile}"
}
