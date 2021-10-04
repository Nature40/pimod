if [ -z "${PIMOD_CACHE+x}" ]; then 
  PIMOD_CACHE="/var/cache/pimod"
fi

# from_remote_valid checks if the given string indicates a valid URL.
from_remote_valid() {
  local schemeRegexp="^(https?|ftp)://.*"
  [[ $1 =~ $schemeRegexp ]]
}

# unarchive_image extracts files from an image and moves the largest to a given path.
unarchive_image() {
  local archive="${1}"
  local tmpfile="${2}"
  local unzip_image
  unzip_dir=$(mktemp -d)

  7z e -bd -o"${unzip_dir}" "${archive}"

  # pick largest file, as it is most likely the image
  # shellcheck disable=SC2012
  unzip_image=$(ls -S -1 "${unzip_dir}" | head -n1)
  mv "${unzip_dir}/${unzip_image}" "${tmpfile}"
  rm -rf "${unzip_dir}"
}

# from_remote_fetch tries to fetch a remote image and uses it for FROM.
from_remote_fetch() {
  local url
  local url_path
  local download_path
  
  url="${1}"
  url_path=$(echo "${url}" | sed 's/.*:\/\///')
  download_path="${PIMOD_CACHE}/${url_path}"

  if [ -f "${download_path}" ]; then
    echo "Using cache: ${download_path}"
  else
    echo "Fetching remote: ${url}"
    mkdir -p "$(dirname "${download_path}")"
    wget --progress=dot:giga -O "${download_path}" "${url}" || rm "${download_path}"
  fi

  local tmpfile
  local mime

  tmpfile=$(mktemp -u)
  mime=$(file -b --mime-type "${download_path}")

  case "${mime}" in
    application/octet-stream)
      # let's seriously hope it's an image..
      cp "${download_path}" "${tmpfile}"
      ;;

    application/zip)
      unarchive_image "${download_path}" "${tmpfile}"
      ;;

    application/x-7z-compressed)
      unarchive_image "${download_path}" "${tmpfile}"
      ;;

    application/gzip)
      gunzip -c "${download_path}" > "${tmpfile}"
      ;;

    application/x-gzip)
      gunzip -c "${download_path}" > "${tmpfile}"
      ;;

    application/x-xz)
      unxz -c "${download_path}" > "${tmpfile}"
      ;;

    *)
      echo -e "\033[0;31m### Error: Unknown MIME ${mime}\033[0m"
      return 1
      ;;
  esac

  export SOURCE_IMG="${tmpfile}"
  export SOURCE_IMG_TMP=1
}
