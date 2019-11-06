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
