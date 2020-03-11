FROM debian:buster-slim

RUN apt-get update && \
  apt-get install -y \
  binfmt-support \
  file \
  kpartx \
  lsof \
  parted \
  qemu \
  qemu-user-static \
  unzip \
  p7zip-full \
  wget \
  xz-utils

RUN mkdir /pimod
COPY pimod.sh modules stages /pimod/

ENV PATH="/pimod:${PATH}"
ENV PIMOD_CACHE=".cache"

WORKDIR /pimod
CMD pimod.sh Pifile
