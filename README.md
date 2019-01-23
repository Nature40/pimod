# pimod, custom*pi*ze your Raspberry Pi image
*pimod* let you reconfigure your Raspberry Pi images with an easy, Docker-like
configuration file from QEMU-based from your host system.


## Install
### Docker
A simple option is running *pimod* within a Docker container.

```bash
$ docker build -t pimod .

$ cat Pifile
FROM /raspbian.img
TO /rpi-out.img

PUMP 200
ENABLE_UART

RUN apt-get update
RUN apt-get install -y sl

$ touch rpi-out.img
$ docker run -t --rm --privileged \
  -v `pwd`/Pifile:/Pifile \
  -v ~/Downloads/2018-11-13-raspbian-stretch-lite.img:/raspbian.img \
  -v `pwd`/rpi-out.img:/rpi-out.img \
  pimod
```


## Pifile a.k.a. Configuration
The `Pifile` should contain commands to modify the image. These commands will be
executed in different stages.


### Stage 1, Setup
- `FROM` sets the `SOURCE_IMG` variable to the given file. This file will be
  used as source base file.

  Usage: `FROM PATH_TO_IMAGE`
- `TO` sets the `DEST_IMG` variable to the given file. This file will be
  contain the new image. Existing files will be overridden. If TO is not called,
  the default `DEST_IMG` will be rpi.img in the source file's directory.

  Usage: `FROM PATH_TO_IMAGE`


### Stage 2, Preparation
- `PUMP` increases the image's size about the given amount of megabytes.

  Usage: `PUMP SIZE_IN_MB`


### Stage 3, chroot
- `ENABLE_UART` enables the UART/serial port of the Pi.

  Usage: `ENABLE_UART`
- `INSTALL` installs a given file or directory to the given directory in the
  image. The permission mode (chmod) can be optionally set as the first
  parameter.

  Usage: `INSTALL [MODE] SOURCE DEST`
- `RUN` executes a command in the chrooted image.

  Usage: `RUN CMD PARAMS...`


### Example Pifile
```
FROM /result/2018-11-13-raspbian-stretch-lite.img
TO /result/rpi.img

PUMP 200

ENABLE_UART

INSTALL 755 /result/foo.sh /bin/foo

RUN uname -a
RUN apt-get update
RUN apt-get install -y sl
```


## Notable Mentions
- [Debian Wiki, qemu-user-static](https://wiki.debian.org/RaspberryPi/qemu-user-static)
- [raspberry-pi-chroot-armv7-qemu.md ](https://gist.github.com/jkullick/9b02c2061fbdf4a6c4e8a78f1312a689)
- [chroot-to-pi.sh](https://gist.github.com/htruong/7df502fb60268eeee5bca21ef3e436eb)
