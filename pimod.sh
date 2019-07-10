#!/usr/bin/env bash
set -e

# mount_image mounts the given image file as a loop device and "returns"/prints
# the name of the loop device (e.g. loop0).
# Usage: mount_image PATH_TO_IMAGE
mount_image() {
  kpartx -avs "$1" \
    | sed -E 's/.*(loop[0-9])p.*/\1/g' \
    | head -n 1
}

# umount_image unmounts the given image file, mounted with mount_image.
# Usage: umount_image PATH_TO_IMAGE
umount_image() {
  kpartx -d "$1"
  dmsetup remove_all
}

# chroot_setup mounts the given image file and prepares a chroot.
# Usage: chroot_setup PATH_TO_IMAGE
chroot_setup() {
  local loop=`mount_image $1`

  local loop_boot="/dev/mapper/${loop}p1"
  local loop_root="/dev/mapper/${loop}p2"

  CHROOT_MOUNT=`mktemp -d`

  mount $loop_root "${CHROOT_MOUNT}/"
  mount $loop_boot "${CHROOT_MOUNT}/boot"

  mount --bind /dev "${CHROOT_MOUNT}/dev"
  mount --bind /sys "${CHROOT_MOUNT}/sys"
  mount --bind /proc "${CHROOT_MOUNT}/proc"
  mount --bind /dev/pts "${CHROOT_MOUNT}/dev/pts"

  sed -i 's/^/#/g' "${CHROOT_MOUNT}/etc/ld.so.preload"

  update-binfmts --enable qemu-arm
  cp /usr/bin/qemu-arm-static "${CHROOT_MOUNT}/usr/bin/"
}

# chroot_teardown unmounts the given image file, mounted with chroot_setup.
# Usage: chroot_teardown PATH_TO_IMAGE
chroot_teardown() {
  sed -i 's/^#//g' "${CHROOT_MOUNT}/etc/ld.so.preload"

  umount "${CHROOT_MOUNT}/dev/pts"
  umount "${CHROOT_MOUNT}/proc"
  umount "${CHROOT_MOUNT}/sys"
  umount "${CHROOT_MOUNT}/dev"
  umount "${CHROOT_MOUNT}/boot"
  umount "${CHROOT_MOUNT}/"

  rm -r $CHROOT_MOUNT
  unset CHROOT_MOUNT

  umount_image $1

  update-binfmts --disable qemu-arm
}

# inspect_pifile_name checks the name of the given Pifile (first parameter)
# and sets the internal DEST_IMG variable to the first part of this filename,
# if the filename has the format of XYZ.Pifile, with XYZ being alphanumeric
# or signs.
# Usage: inspect_pifile_name PIFILE_NAME
inspect_pifile_name() {
  # local always returns 0..
  to_name=`echo "$1" \
    | sed -E '/\.Pifile$/!{q1}; {s/^([[:graph:]]*)\.Pifile$/\1/}'`

  [ $? -eq 0 ] && DEST_IMG="${to_name}.img" || unset DEST_IMG
  unset to_name
}

# execute_pifile runs the given Pifile.
# Usage: execute_pifile PIFILE
execute_pifile() {
  if [ -z $1 ] || [ ! -f $1 ]; then
    echo "No given file or file does not exists"
    return 1
  fi

  inspect_pifile_name $1

  bash -n $1

  stages=("10-setup.sh" "20-prepare.sh" "30-chroot.sh")
  for stage in "${stages[@]}"; do
    . 00-commands.sh
    . $stage

    pre_stage
    . $1
    post_stage
  done
}


if [ -z $1 ]; then
  echo "Usage: $0 Pifile"
  exit 1
fi

execute_pifile $1
