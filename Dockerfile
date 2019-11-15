FROM debian:buster-slim

RUN apt-get update && \
  apt-get install -y \
    binfmt-support \
    file \
    kpartx \
    parted \
    qemu \
    qemu-user-static \
    unzip \
    wget \
    xz-utils

RUN mkdir /pimod
COPY pimod.sh modules stages /pimod/

ENV PATH="/pimod:${PATH}"
WORKDIR /pimod

CMD pimod.sh Pifile
