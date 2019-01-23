FROM debian:stretch-slim

RUN apt-get update && \
  apt-get install -y kpartx proot qemu qemu-user-static

COPY *.sh /

CMD ./pimod.sh /Pifile
