# The execution of a Pifile has multiple stages. However, the file will be
# sourced in each stage. Therefore this file defines a nop version of each known
# command and will disable them. This is kind of hacky, tbh.

# Every stage

# pre_stage will be called at the start of each stage. Checks, setups or the
# like may be executed here. Overriding this function is optional.
pre_stage() {
  :
}

# post_stage will be called at the end of each stage. Checks, clean ups or the
# like may be executed here. Overriding this function is optional.
post_stage() {
  :
}

# INCLUDE sources the provided Pifile from a local path or remote URL.
# For URLs, the file is downloaded to the cache and then sourced.
#
# Usage: INCLUDE path/to/pifile[.Pifile]
#        INCLUDE https://example.com/path/to/pifile[.Pifile]
INCLUDE() {
  local target="${1}"
  local filename
  local cached_file

  # Check if it's a URL
  if from_remote_valid "${target}"; then
    # Download to cache
    local url_path
    url_path=$(echo "${target}" | sed 's/.*:\/\///')
    cached_file="${PIMOD_CACHE}/${url_path}"

    if [ -f "${cached_file}" ]; then
      echo "Using cached Pifile: ${cached_file}"
    else
      echo "Fetching remote Pifile: ${target}"
      mkdir -p "$(dirname "${cached_file}")"
      wget --progress=dot:giga -O "${cached_file}" "${target}" || rm "${cached_file}"
    fi

    filename="${cached_file}"
  else
    # Local file - remove .Pifile extension if present
    filename="${target%.*}"
    filename="${filename}.Pifile"
  fi

  # Source the Pifile
  # shellcheck disable=SC1090
  source "${filename}"
}

# Stage 1x
FROM() {
  :
}

TO() {
  :
}

INPLACE() {
  :
}


# Stage 2x
PUMP() {
  :
}

ADDPART() {
  :
}

# Stage 3x
INSTALL() {
  :
}

EXTRACT() {
  :
}

PATH() {
  :
}

WORKDIR() {
  :
}

ENV() {
  :
}

RUN() {
  :
}

HOST() {
  :
}

ZERO() {
  :
}

SHRINK() {
  :
}
