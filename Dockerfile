FROM debian:stretch-slim

RUN apt-get update && \
  apt-get install -y kpartx proot qemu qemu-user-static

RUN mkdir /pimod
COPY *.sh /pimod/
ENV PATH="/pimod:${PATH}"

WORKDIR /pimod
CMD pimod.sh Pifile
