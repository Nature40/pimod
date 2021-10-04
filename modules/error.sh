if [ -z "${PIMOD_DEBUG+x}" ]; then
  PIMOD_DEBUG=0
fi

# handle_error handles an error which may occur during Pifile execution.
# Usage: handle_error RETURN_CODE COMMAND
handle_error() {
  if [[ -z ${2+x} ]]; then
    echo -e "\033[0;31m### Error ${1}, cleaning up...\033[0m"
  else
    echo -e "\033[0;31m### Error: \"${2}\" returned ${1}, cleaning up...\033[0m"
  fi

  if [ "${PIMOD_DEBUG}" -eq 1 ]; then
    echo "Running an interactive debug shell, use ^D or 'exit' to cleanup."
    $SHELL
  fi

  # teardown chroot / mount / loop environment
  chroot_teardown
  exit "${1}"
}
