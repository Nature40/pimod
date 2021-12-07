# ENV_VARS is an associative array of environment variables, set via ENV.
declare -A ENV_VARS=()

# env_vars_set saves an environment variable mapping.
# Usage: env_vars_set KEY VALUE
env_vars_set() {
  ENV_VARS["${1}"]="${2}"
}

# env_vars_del removes an environment variable mapping.
# Usage: env_vars_del KEY
env_vars_del() {
  unset ENV_VARS["${1}"]
}

# env_vars_export_cmd creates a single "export K1=V1 K2=V2 ...;" output. If no
# values are present, an empty output is generated.
# Usage: env_vars_export_cmd
env_vars_export_cmd() {
  if [[ "${#ENV_VARS[@]}" -eq "0" ]]; then
    echo ""
    return
  fi

  declare -a pairs

  for key in "${!ENV_VARS[@]}"; do
    pairs+=("${key}=${ENV_VARS["$key"]}")
  done

  echo "export ${pairs[*]};"
}

# env_vars_subst replaces all previously defined environment variables in the
# form of "@@ENV@@" by its value.
# Usage: env_vars_subst echo hello @@USER_NAME@@
env_vars_subst() {
  for part in "${@}"; do
    for key in "${!ENV_VARS[@]}"; do
      part="${part/"@@${key}@@"/${ENV_VARS["$key"]}}"
    done
    printf '%s ' "$part"
  done
}
