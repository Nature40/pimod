FROM debian:stretch-slim

RUN apt-get update \
  && apt-get install -y dosfstools git kpartx multistrap

COPY multistrap.conf /
COPY builder.sh /

RUN chmod +x /builder.sh

CMD ./builder.sh
