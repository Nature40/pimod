#!/usr/bin/env bash
# Creates an update with pidiff between two generated images and applies it
# with the generated batch script: once to a writable target, which must end
# up with the updated files, and once to a read-only target, where the script
# must fail and report the rsync error.
# Requires root, kpartx and setcap (libcap2-bin).
#
# If KEEP_DIR is given, the generated base.img and updated.img are copied
# there, e.g., to test the pidiff GitHub Action with them.
#
# Usage: sudo tests/pidiff.sh [KEEP_DIR]

set -euo pipefail

keep_dir="${1:-}"
pidiff="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null && pwd)/pidiff.sh"
work=$(mktemp -d)
trap 'mountpoint -q "${work}/mnt" && umount "${work}/mnt"; rm -rf "${work}"' EXIT
cd "${work}"
mkdir mnt

# attach IMAGE attaches IMAGE and prints the device of its partition 2.
attach() {
  local loop
  loop=$(losetup -f --show "${1}")
  kpartx -as "${loop}"
  echo "/dev/mapper/$(basename "${loop}")p2"
}

# detach DEVICE detaches the loop device behind a mapped partition.
detach() {
  local loop="/dev/${1#/dev/mapper/}"
  loop="${loop%p2}"
  kpartx -ds "${loop}"
  losetup -d "${loop}"
}

fail() {
  echo "### FAIL: $*"
  exit 1
}

# Base image with an ext4 root file system.
truncate -s 64M base.img
printf ',16M\n,,83\n' | sfdisk -q base.img
dev=$(attach base.img)
mkfs.ext4 -q "${dev}"
mount "${dev}" mnt
mkdir mnt/etc
echo 'PRETTY_NAME="pidiff test"' > mnt/etc/os-release
echo "base" > mnt/changed
umount mnt
detach "${dev}"

# Updated image: a changed file, a new file with a file capability and a
# file excluded from the update.
cp base.img updated.img
dev=$(attach updated.img)
mount "${dev}" mnt
echo "updated content" > mnt/changed
cp /bin/true mnt/capability
setcap cap_net_raw+ep mnt/capability
echo "excluded" > mnt/excluded.pyc
umount mnt
detach "${dev}"

# The output name contains a space and a command substitution, which the
# generated batch script must treat as a plain file name.
# shellcheck disable=SC2016  # the command substitution must stay literal
update='update $(touch injected)'
"${pidiff}" --exclude='*.pyc' --output="${update}" base.img updated.img

# Apply the update to a writable copy of the base image.
cp base.img target.img
dev=$(attach target.img)
mount "${dev}" mnt
"./${update}.sh" "${work}/mnt"

[[ ! -e injected ]] || fail "batch script executed a command from its file name"
[[ "$(cat mnt/changed)" == "updated content" ]] || fail "changed file was not updated"
[[ "$(getcap mnt/capability)" == *cap_net_raw* ]] || fail "file capability was not transferred"
[[ ! -e mnt/excluded.pyc ]] || fail "excluded file was transferred"

# Apply the update to a read-only copy: rsync fails, the script must report it.
cp base.img readonly.img
umount mnt
detach "${dev}"
dev=$(attach readonly.img)
mount -o ro "${dev}" mnt

rc=0
output=$("./${update}.sh" "${work}/mnt" 2>&1) || rc=$?
echo "${output}"
[[ "${rc}" -ne 0 ]] || fail "update of a read-only target succeeded"
grep -qE "^(Error|Warning): " <<< "${output}" || fail "rsync error ${rc} was not reported"

umount mnt
detach "${dev}"

if [[ -n "${keep_dir}" ]]; then
  mkdir -p "${keep_dir}"
  cp base.img updated.img "${keep_dir}/"
fi

echo "### pidiff test passed"
