# pimod
Reconfigure Raspberry Pi images with an easy, Docker-like configuration file.


## About
*pimod* overtakes a given Raspberry Pi image by mounting a copy and modifying
this copy through QEMU chroot. Therefore one can execute Pi's ARM-code easily
on its x86\_64 host.


## Installation, Usage
### Debian
```bash
$ sudo apt-get install kpartx qemu qemu-user-static binfmt-support

$ sudo ./pimod.sh Pifile
```


## Pifile
The *Pifile* contains commands to modify the image. However, the *Pifile*
itself is just a Bash script and the commands are functions, which are loaded
in different stages.


### Example
```
$ cat Upgrade.Pifile
FROM 2018-11-13-raspbian-stretch-lite.img

PUMP 100M

RUN raspi-config nonint do_serial 0

RUN apt-get update
RUN bash -c 'DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade'
RUN apt-get install -y sl


# The Upgrade.Pifile will create, called by the following command, a new
# Upgrade.img image based on the given Raspbian image. This image's size is
# increased about 100MB, has an enabled UART/serial output, the latest software
# and sl installed.

# Docker:
$ ./pimod-docker.sh \
  Upgrade.Pifile ~/Downloads/2018-11-13-raspbian-stretch-lite.img Upgrade.img

# Plain:
$ sudo ./pimod.sh Upgrade.Pifile

# Write the new image to a SD card present at /dev/sdc.
$ dd if=Upgrade.img of=/dev/sdc bs=4M status=progress
```

More examples are available in the
[Sensorboxes](https://github.com/Nature40/Sensorboxes) repository.


### Commands
#### `FROM`
`FROM` sets the `SOURCE_IMG` variable to the given file. This file will be
used as the base for the new image.

*Usage:* `FROM PATH_TO_IMAGE`


#### `TO`
`TO` sets the `DEST_IMG` variable to the given file. This file will contain
the new image. Existing files will be overridden.

Instead of calling `TO`, the Pifile's filename can also indicate the output
file, if the Pifile ends with *".Pifile"*. The part before this suffix will be
the new `DEST_IMG`.

If neither `TO` is called nor the Pifile indicates the output, `DEST_IMG` will
default to *rpi.img* in the source file's directory.

*Usage:* `TO PATH_TO_IMAGE`


#### `INPLACE`
`INPLACE` does not create a copy of the image, but performs all further
operations on the given image. This is an alternative to `FROM` and `TO`.

*Usage:* `INPLACE PATH_TO_IMAGE`


#### `PUMP`
`PUMP` increases the image's size about the given amount (suffixes K, M, G are allowed).

*Usage:* `PUMP SIZE`


#### `INSTALL`
`INSTALL` installs a given file or directory into the destination in the
image. The optionally permission mode (*chmod*) can be set as the first
parameter.

*Usage*: `INSTALL [MODE] SOURCE DEST`


#### `RUN`
`RUN` executes a command in the chrooted image based on QEMU user emulation.

Caveat: because the Pifile is just a Bash script, pipes do not work as one
might suspect. A possible workaround could be the usage of `bash -c`:

```
RUN bash -c 'hexdump /dev/urandom | head'
```

*Usage:* `RUN CMD PARAMS...`


### Hacks
Because the *Pifile* is just a Bash script, some ~~dirty~~ brilliant hacks
are possible.


#### Inherit another Pifile
Another *Pifile* can be extended by sourcing it in the first line.

```
source Parent.Pifile
```


#### Bulk execution
Here documents can be used with the `RUN` command.

```
RUN <<EOF
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
apt-get install -y sl
EOF
```


## Notable Mentions
- [Debian Wiki, qemu-user-static](https://wiki.debian.org/RaspberryPi/qemu-user-static)
- [raspberry-pi-chroot-armv7-qemu.md](https://gist.github.com/jkullick/9b02c2061fbdf4a6c4e8a78f1312a689)
- [chroot-to-pi.sh](https://gist.github.com/htruong/7df502fb60268eeee5bca21ef3e436eb)
- [PiShrink](https://github.com/Drewsif/PiShrink)
