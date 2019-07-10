FROM debian:stretch-slim

RUN apt-get update && \
  apt-get install -y kpartx qemu qemu-user-static binfmt-support parted

RUN mkdir /pimod
COPY *.sh /pimod/
ENV PATH="/pimod:${PATH}"

WORKDIR /pimod
CMD pimod.sh Pifile
