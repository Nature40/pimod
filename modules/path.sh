# GUEST_PATH is an overlay PATH variable used within RUN. Initially, it is
# identical to the PATH variable of the host.
GUEST_PATH="${PATH}"

# path_add adds a given PATH to the overlay GUEST_PATH variable.
path_add() {
  if [[ -z ${GUEST_PATH+x} ]]; then
    GUEST_PATH=${1}
  else
    GUEST_PATH=${GUEST_PATH}:${1}
  fi
}
