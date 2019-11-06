#!/usr/bin/env bash
set -eE

QEMU_ARCHS="arm armeb aarch64"

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
  kpartx -dvs "/dev/${1}" 1>&2
  losetup -d "/dev/${1}"
}

# handle_error handles an error which may occur during Pifile execution.
# Usage: handle_error RETURN_CODE COMMAND
handle_error() {
  # disable script abort on error
  set +eE
  # ignore further errors 
  trap "" ERR
  
  echo -e "\033[0;31m### Error: \"${2}\" returned ${1}, cleaning up...\033[0m"

  # teardown chroot / mount / loop environment
  chroot_teardown
  exit $RET
}

# chroot_setup mounts the given image file and prepares a chroot.
# Usage: chroot_setup PATH_TO_IMAGE
chroot_setup() {
  trap 'handle_error ${?} "${@}"' ERR

  LOOP=`mount_image "${1}"`
  CHROOT_MOUNT=`mktemp -d`

  local loop_root="/dev/mapper/${LOOP}p${IMG_ROOT}"
  mount "${loop_root}" "${CHROOT_MOUNT}/"

  mount --bind /dev "${CHROOT_MOUNT}/dev"
  mount --bind /sys "${CHROOT_MOUNT}/sys"
  mount --bind /proc "${CHROOT_MOUNT}/proc"
  mount --bind /dev/pts "${CHROOT_MOUNT}/dev/pts"

  # disable preloading (not working because of missing paths)
  test -f "${CHROOT_MOUNT}/etc/ld.so.preload" && \
    sed -i 's/^/#/g' "${CHROOT_MOUNT}/etc/ld.so.preload"

  # copy qemu binaries for selected platforms
  for arch in ${QEMU_ARCHS}; do 
    cp "/usr/bin/qemu-${arch}-static" "${CHROOT_MOUNT}/usr/bin/"
    update-binfmts --enable qemu-${arch}
  done

  # mount additional partitions
  chroot "${CHROOT_MOUNT}" mount -a
}

# chroot_teardown unmounts the given image file, mounted with chroot_setup.
# Usage: chroot_teardown PATH_TO_IMAGE
chroot_teardown() {
  for arch in ${QEMU_ARCHS}; do 
    update-binfmts --disable qemu-${arch}
    rm "${CHROOT_MOUNT}/usr/bin/qemu-${arch}-static"
  done
  
  # enable preloading libraries
  test -f "${CHROOT_MOUNT}/etc/ld.so.preload" && \
    sed -i 's/^#//g' "${CHROOT_MOUNT}/etc/ld.so.preload"

  # umount "${CHROOT_MOUNT}/boot"
  umount -Rv "${CHROOT_MOUNT}/"

  rm -r "${CHROOT_MOUNT}"
  unset CHROOT_MOUNT

  umount_image "${LOOP}"
  unset LOOP
}

# inspect_pifile_name checks the name of the given Pifile (first parameter)
# and sets the internal DEST_IMG variable to the first part of this filename,
# if the filename has the format of XYZ.Pifile, with XYZ being alphanumeric
# or signs.
# Usage: inspect_pifile_name PIFILE_NAME
inspect_pifile_name() {
  # local always returns 0..
  to_name=`echo "${1}" \
    | sed -E '/\.Pifile$/!{q1}; {s/^([[:graph:]]*)\.Pifile$/\1/}'`

  [ $? -eq 0 ] && DEST_IMG="${to_name}.img" || unset DEST_IMG
  unset to_name
}

# execute_pifile runs the given Pifile.
# Usage: execute_pifile PIFILE
execute_pifile() {
  if [ -z "${1}" ] || [ ! -f "${1}" ]; then
    echo -e "\033[0;31m### Error: Pifile \"${1}\" does not exist.\033[0m"
    return 1
  fi

  inspect_pifile_name $1

  bash -n $1


  stages="10-setup.sh 20-prepare.sh 30-chroot.sh"
  for stage in ${stages}; do
    . stages/00-commands.sh
    . "stages/${stage}"

    pre_stage
    . "${1}"
    post_stage
  done
}


if [ -z "${1}" ]; then
  echo "Usage: ${0} Pifile"
  exit 1
fi

execute_pifile "${1}"
