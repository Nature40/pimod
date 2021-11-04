FROM debian:bullseye-slim

LABEL description="Reconfigure Raspberry Pi images with an easy, Docker-like configuration file"
LABEL maintainer="hoechst@mathematik.uni-marburg.de"
LABEL version="0.2.1"

RUN apt-get update && \
  apt-get install -y \
  binfmt-support \
  file \
  kpartx \
  lsof \
  p7zip-full \
  parted \
  qemu \
  qemu-user-static \
  unzip \
  wget \
  xz-utils \
  units

RUN mkdir /pimod
COPY . /pimod/

ENV PATH="/pimod:${PATH}"
ENV PIMOD_CACHE=".cache"

WORKDIR /pimod
CMD pimod.sh Pifile
