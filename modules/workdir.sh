# WORKDIR_PATH is the workdir to be used within the chroot.
WORKDIR_PATH="/"

# workdir_set overwrites the WORKDIR_PATH with the given parameter.
workdir_set() {
  WORKDIR_PATH=${1}
}
