FROM debian:stretch-slim

RUN apt-get update && \
  apt-get install -y binfmt-support kpartx parted proot qemu qemu-user-static

COPY 00-commands.sh /
COPY 10-setup.sh /
COPY 20-prepare.sh /
COPY 30-chroot.sh /
COPY pimod.sh /
COPY Pifile /

CMD ./pimod.sh /Pifile
