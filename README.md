# pimod
[![CI: Tests](https://github.com/Nature40/pimod/actions/workflows/tests.yml/badge.svg)](https://github.com/Nature40/pimod/actions/workflows/tests.yml)
[![CI: Shellcheck](https://github.com/Nature40/pimod/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/Nature40/pimod/actions/workflows/shellcheck.yml)
[![CI: Build and upload DockerHub image](https://github.com/Nature40/pimod/actions/workflows/dockerhub.yml/badge.svg)](https://github.com/Nature40/pimod/actions/workflows/dockerhub.yml)
[![Docker Hub: Version](https://img.shields.io/docker/v/nature40/pimod?color=blue&label=Docker%20Hub&logo=docker&logoColor=lightgrey&sort=semver)](https://hub.docker.com/r/nature40/pimod/tags)

Reconfigure Raspberry Pi images with an easy, Docker-like configuration file.

## About
pimod overtakes a given Raspberry Pi image file by mounting a copy and modifying it within a QEMU chroot.
This allows the execution of a Pi's ARM code on whatever target, e.g., a x86\_64 host.

To ease the usability, a Docker-inspired recipe, called the Pifile, is used to instrument pimod.

```
# Example Pifile to create a customized version of the Raspberry Pi OS Lite

# Based on a remote image, which will be cached locally, create the altered raspi_example.img file
FROM https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2023-02-22/2023-02-21-raspios-bullseye-arm64-lite.img.xz
TO rapsi_example.img

# Increase the image by 100 MB
PUMP 100M

# Install an ssh key from local sources
RUN mkdir -p /home/pi/.ssh
INSTALL id_rsa.pub /home/pi/.ssh/authorized_keys

# Enable the serial console and SSH
RUN raspi-config nonint do_serial 0
RUN raspi-config nonint do_ssh 0

# Install the important cowsay util
RUN apt-get update
RUN apt-get install -y cowsay
```

## Installation, Usage
```
Usage: pimod.sh [Options] Pifile

Options:
  -c --cache DEST   Define cache location.
  -d --debug        Debug on failure; run an interactive shell before tear down.
  -h --help         Print this help message.
  -r --resolv TYPE  Specify which /etc/resolv.conf file to use for networking.
                    By default, TYPE "auto" is used, which prefers an already
                    existing resolv.conf, only to be replaced by the host's if
                    missing.
                    TYPE "guest" never mounts the host's file within the guest,
                    even when such a file is absent within the image.
                    TYPE "host" always uses the host's file within the guest.
                    Be aware that when run within Docker, the host's file might
                    be Docker's resolv.conf file.
  -t --trace        Trace each executed command for debugging.
```

### Docker
#### Getting or Building the Docker Image
There are pre-built images available on [Docker Hub](https://hub.docker.com/r/nature40/pimod):

```sh
docker pull nature40/pimod
```

Alternatively, you can simply build the image yourself locally.
This is essential for development, among other things:

```sh
git clone https://github.com/Nature40/pimod.git
cd pimod
docker build -t nature40/pimod .
```

#### Using the Docker Image
Afterwards, the Docker image can either be used by `docker` or `docker compose`:

```sh
# Using Docker:
docker run --rm --privileged -v $PWD:/pimod nature40/pimod pimod.sh examples/RPi-OpenWRT.Pifile

# Using Docker Compose:
docker compose run nature40/pimod pimod.sh examples/RPi-OpenWRT.Pifile
```

### Debian
Of course, Docker isn't really necessary and pimod can also be used on, e.g., a Debian directly:

```sh
sudo apt-get install \
  binfmt-support \
  fdisk \
  file \
  kpartx \
  lsof \
  p7zip-full \
  qemu-user-static \
  unzip \
  wget \
  xz-utils \
  units

sudo ./pimod.sh Pifile
```

### GitHub Actions
Pimod can also be used as a GitHub Action and is available on the [marketplace](https://github.com/marketplace/actions/run-pimod).

```yml
name: tests
on: push

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        with:
          submodules: recursive
      - name: Run pimod OpenWRT example
        uses: Natur40/pimod@master
        with:
          pifile: examples/RPi-OpenWRT.Pifile
```

## Pifile
The Pifile contains commands to modify the image.

Those commands are grouped in stages which pimod executes in their corresponding order.

- First, all _setup stage_ commands are being executed to download the base image and configure the output.
- The _prepare stage_ follows which pre-flight commands, e.g., resizing the output image.
- The action happens in the _chroot stage_ where the QEMU chroot is built, commands are executed within, files are copied and so on.
- Finally, the _postprocess stage_ might clean up some things.

However, as the Pifile being just a Bash script by itself and the commands are functions, which are loaded in different stages, Bash scripting is possible within the Pifile to some extend.

More internals are documented in our [our scientific paper](https://jonashoechst.de/assets/papers/hoechst2020pimod.pdf).
If you stumble upon details there that you think belong in this README, feel free to create an issue or pull request.

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
$ sudo ./pimod.sh Upgrade.Pifile

# Write the new image to a SD card present at /dev/sdc.
$ dd if=Upgrade.img of=/dev/sdc bs=4M status=progress
```

Further and more expressive examples are available in this repository's `./example` directory.
Please take a look and feel free to submit your own examples if they are covering a current blind spot.

### Commands
#### Stage independent
##### `INCLUDE PATH_TO_PIFILE`
`INCLUDE` includes the provided Pifile in the current one for modularity and re-use.
The included file _has_ to have a `.Pifile` extension which need not be specified.

#### 1. Setup Stage
##### `FROM PATH_TO_IMAGE [PARTITION_NO]`, `FROM URL [PARTITION_NO]`
`FROM` sets the `SOURCE_IMG` variable to a target.
This might be a local file or a remote URL, which will be downloaded.
This file will become the base for the new image.

By default, the Raspberry Pi's default partition number 2 will be used, but can be altered for other targets.

##### `TO PATH_TO_IMAGE`
`TO` sets the `DEST_IMG` variable to the given file.
This file will contain the new image.
Existing files will be overridden.

Instead of calling `TO`, the Pifile's filename can also indicate the output file, if the Pifile ends with *".Pifile"*.
The part before this suffix will be the new `DEST_IMG`.

If neither `TO` is called nor the Pifile indicates the output, `DEST_IMG` will default to *rpi.img* in the source file's directory.

##### `INPLACE FROM_ARGS...`
`INPLACE` does not create a copy of the image, but performs all further operations on the given image.
This is an alternative to `FROM` and `TO`.

#### 2. Prepare Stage
##### `PUMP SIZE`
`PUMP` increases the image's size about the given amount (suffixes K, M, G are allowed).

##### `ADDPART SIZE PTYPE FS`
`PUMP` appends a partition of the size (suffixes K, M, G are allowed) using a partion type and file system (ext4, exfat, ...).

#### 3. Chroot Stage
##### `INSTALL <MODE> SOURCE DEST`
`INSTALL` installs a given file or directory into the destination in the image.
The optionally permission mode (*chmod*) can be set as the first parameter.

##### `EXTRACT SOURCE DEST`
`EXTRACT` copies a given file or directory from the image to the destination.

##### `PATH /my/guest/path`
`PATH` adds the given path to an overlaying PATH variable, used within the `RUN` command.

##### `WORKDIR /my/guest/path`
`WORKDIR` sets the working directory within the image.

##### `ENV KEY [VALUE]`
`ENV` either sets or unsets an environment variable to be used within the image.
If two parameters are given, the first is the key and the second the value.
If one parameter is given, the environment variable will be removed.

An environment variable can be either used via `$VAR` within another sub-shell (`sh -c 'echo $VAR'`) or substituted beforehand via `@@VAR@@`.

```
ENV FOO BAR

RUN sh -c 'echo FOO = $FOO'   # FOO = BAR - substituted within a sh in the image
RUN echo FOO = @@FOO@@        # FOO = BAR - substituted beforehand via pimod

ENV FOO
```

##### `RUN CMD [PARAMS...]`
`RUN` executes a command in the chrooted image based on QEMU user emulation.

Caveat: because the Pifile is just a Bash script, pipes do not work as one might suspect.
A possible workaround could be the usage of `bash -c`:

```
RUN bash -c 'hexdump /dev/urandom | head'
```

##### `HOST CMD [PARAMS...]`
`HOST` executed a command on the local host and can be used to prepare files, cross-compile software, etc.

#### 4. Postprocess Stage
##### `ZERO`
`ZERO` fills unused space in the filesystem with zeros.
This allows for better compression of the resulting image, resulting in smaller image files.
Useful when creating images for distribution.

##### `SHRINK [SIZE]`
`SHRINK` shrinks the image to its minimal possible size using [PiShrink](https://github.com/Drewsif/PiShrink).
Optionally, you can specify a target size (suffixes K, M, G are allowed) - the image will be shrunk to minimum and then expanded to the specified size if needed.
This is useful to reduce the final image size for distribution.

Examples:
```sh
SHRINK          # Shrink to minimum possible size
SHRINK 4G       # Shrink to minimum, then ensure image is 4GB
```

Note: PiShrink is automatically downloaded and cached on first use.

### Pifile Extensions
Because the *Pifile* is just a Bash script, some ~~dirty~~ brilliant hacks and extensions are possible.

#### Bulk execution
Sub shells can be used with the `RUN` command.

```sh
RUN sh -c '
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
apt-get install -y sl
'
```

#### Inplace Files
Here documents can also be used to create files inside of the guest system, e.g., by using `tee` or `dd`.

```bash
RUN tee /bin/example.sh <<EOF
#!/bin/sh

echo "Example output."
EOF
```

## Scientific Usage & Citation
If you happen to use pimod in a scientific project, we would very much appreciate if you cited [our scientific paper](https://jonashoechst.de/assets/papers/hoechst2020pimod.pdf):

```bibtex
@inproceedings{hoechst2020pimod,
  author = {{Höchst}, Jonas and Penning, Alvar and Lampe, Patrick and Freisleben, Bernd},
  title = {{PIMOD: A Tool for Configuring Single-Board Computer Operating System Images}},
  booktitle = {{2020 IEEE Global Humanitarian Technology Conference (GHTC 2020)}},
  address = {Seattle, USA},
  days = {29},
  month = oct,
  year = {2020},
  keywords = {Single-Board Computer; Operating System Image; System Provisioning},
}
```

## Notable Mentions
- [Debian Wiki, qemu-user-static](https://wiki.debian.org/RaspberryPi/qemu-user-static)
- [raspberry-pi-chroot-armv7-qemu.md](https://gist.github.com/jkullick/9b02c2061fbdf4a6c4e8a78f1312a689)
- [chroot-to-pi.sh](https://gist.github.com/htruong/7df502fb60268eeee5bca21ef3e436eb)
- [PiShrink](https://github.com/Drewsif/PiShrink)
- [pi-bootstrap](https://github.com/aniongithub/pi-bootstrap)
