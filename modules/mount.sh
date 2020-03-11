# mount_image mounts the given image file as a loop device and "returns"/prints
# the name of the loop device (e.g. loop0).
# Usage: mount_image PATH_TO_IMAGE
mount_image() {
  local loop_path=`losetup -f "${1}" --show`
  kpartx -avs "${loop_path}" 1>&2

  basename "${loop_path}"
}

# umount_image unmounts the given image file, mounted with mount_image.
# Usage: umount_image LOOP_NAME
umount_image() {
  for i in `seq 0 2`; do
    kpartx -dvs "/dev/${1}" 1>&2 && losetup -d "/dev/${1}" && return
    sleep 1
  done
}
