FROM debian:stretch-slim

RUN apt-get update && \
  apt-get install -y dosfstools git kpartx parted proot qemu qemu-user-static

COPY builder.sh /

RUN chmod +x /builder.sh

CMD ./builder.sh
