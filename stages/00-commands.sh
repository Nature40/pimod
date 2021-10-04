# The execution of a Pifile has multiple stages. However, the file will be
# sourced in each stage. Therefore this file defines a nop version of each known
# command and will disable them. This is kind of hacky, tbh.

# Every stage

# pre_stage will be called at the start of each stage. Checks, setups or the
# like may be executed here. Overriding this function is optional.
pre_stage() {
  :
}

# post_stage will be called at the end of each stage. Checks, clean ups or the
# like may be executed here. Overriding this function is optional.
post_stage() {
  :
}

# INCLUDE sources the provided Pifile
#
# Usage: INCLUDE path/to/pifile[.Pifile]
INCLUDE() {
  filename="${1%.*}"
  # shellcheck disable=SC1090
  source "${filename}.Pifile"
}

# Stage 1x
FROM() {
  :
}

TO() {
  :
}

INPLACE() {
  :
}


# Stage 2x
PUMP() {
  :
}

# Stage 3x
INSTALL() {
  :
}

PATH() {
  :
}

WORKDIR() {
  :
}

RUN() {
  :
}

HOST() {
  :
}
