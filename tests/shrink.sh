#!/usr/bin/env bash
# Runs SHRINK on a generated test image and validates the result: the
# partition table (including the backup GPT header) and the root file system.
# Requires root, kpartx and, for GPT, sgdisk (gdisk).
#
# Usage: sudo tests/shrink.sh dos|gpt [SHRINK_SIZE]

set -euo pipefail

label="${1:?usage: $0 dos|gpt [SHRINK_SIZE]}"
size="${2:-}"

pimod="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)/pimod.sh"
work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
cd "${work}"

# map_root IMAGE attaches IMAGE and prints the device of its partition 2.
map_root() {
  local loop
  loop=$(losetup -f --show "${1}")
  kpartx -as "${loop}"
  echo "/dev/mapper/$(basename "${loop}")p2"
}

# unmap IMAGE_DEVICE detaches the loop device behind a mapped partition.
unmap() {
  local loop="/dev/${1#/dev/mapper/}"
  loop="${loop%p2}"
  kpartx -ds "${loop}"
  losetup -d "${loop}"
}

# Source image: a 16 MiB first partition and an ext4 root file system with
# 20 MiB of data, as a minimal chroot target.
truncate -s 256M src.img
if [[ "${label}" == "gpt" ]]; then type=L; else type=83; fi
printf 'label: %s\n,16M\n,,%s\n' "${label}" "${type}" | sfdisk -q src.img

root=$(map_root src.img)
mkfs.ext4 -q "${root}"
mkdir rootfs
mount "${root}" rootfs
mkdir rootfs/etc rootfs/dev rootfs/sys rootfs/proc
touch rootfs/etc/resolv.conf
head -c 20M /dev/urandom > rootfs/data
umount rootfs
unmap "${root}"

printf 'FROM src.img 2\nTO out.img\nSHRINK %s\n' "${size}" > Test.Pifile
"${pimod}" Test.Pifile

echo "### Validating out.img ($(stat -c %s out.img) bytes)"
sfdisk -V out.img

if [[ "${label}" == "gpt" ]]; then
  verify=$(sgdisk -v out.img)
  echo "${verify}"
  grep -q "No problems found" <<< "${verify}"
fi

root=$(map_root out.img)
e2fsck -fn "${root}"
unmap "${root}"

echo "### SHRINK on ${label} passed"
