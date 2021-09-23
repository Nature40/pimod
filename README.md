# pimod
[![tests](https://github.com/Nature40/pimod/workflows/tests/badge.svg?branch=master)](https://github.com/Nature40/pimod/actions?query=workflow%3Atests)
[![shellcheck](https://github.com/Nature40/pimod/workflows/shellcheck/badge.svg?branch=master)](https://github.com/Nature40/pimod/actions?query=workflow%3Ashellcheck)

Reconfigure Raspberry Pi images with an easy, Docker-like configuration file.


## About
*pimod* overtakes a given Raspberry Pi image by mounting a copy and modifying this copy through QEMU chroot.
Therefore one can execute Pi's ARM-code easily on its x86\_64 host.

```
# Create a customized version of the Raspberry Pi OS Lite

FROM 2020-05-27-raspios-buster.img
TO raspbian-buster-upgraded.img

# Increase the image by 100 MB
PUMP 100M

# Enable serial console using built-in configuration tool
RUN raspi-config nonint do_serial 0

# Upgrade the operating system image
RUN apt-get update
RUN bash -c 'DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade'

# Install an ssh key from local sources
INSTALL id_rsa.pub /home/pi/.ssh/authorized_keys
```

For detailed information [read our paper](https://jonashoechst.de/assets/papers/hoechst2020pimod.pdf).


## Installation, Usage
```
pimod pimod.sh -h
Usage: pimod.sh [Options] Pifile

Options:
  -c cache  Define cache location.
  -d        Debug on failure; run an interactive shell before tear down
  -t        Trace each executed command for debugging.
  -h        Print this help message.
```

### Debian
```bash
sudo apt-get install binfmt-support fdisk file kpartx lsof parted qemu qemu-user-static unzip p7zip-full wget xz-utils
sudo ./pimod.sh Pifile
```

### Docker
```bash
# build the docker container
docker build -t pimod .

# run the container privileged to allow loop device usage or…
docker run --rm --privileged -v $PWD:/pimod pimod pimod.sh examples/RPi-OpenWRT.Pifile

# …alternatively use docker-compose
docker-compose run pimod pimod.sh examples/RPi-OpenWRT.Pifile
```

### GitHub Actions
```yml
name: tests
on: push

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v1
        with:
          submodules: recursive
      - name: Run pimod OpenWRT example
        uses: Natur40/pimod@master
        with:
          pifile: examples/RPi-OpenWRT.Pifile
```

## Pifile
The Pifile contains commands to modify the image.

However, the Pifile itself is just a Bash script and the commands are functions, which are loaded in different stages.


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


### Commands
#### `FROM [PATH_TO_IMAGE]`, `FROM [URL|`
`FROM` sets the `SOURCE_IMG` variable to a target.
This might be a local file or a remote URL, which will be downloaded.
This file will become the base for the new image.

#### `TO [PATH_TO_IMAGE]`
`TO` sets the `DEST_IMG` variable to the given file.
This file will contain the new image.
Existing files will be overridden.

Instead of calling `TO`, the Pifile's filename can also indicate the output file, if the Pifile ends with *".Pifile"*.
The part before this suffix will be the new `DEST_IMG`.

If neither `TO` is called nor the Pifile indicates the output, `DEST_IMG` will default to *rpi.img* in the source file's directory.

#### `INPLACE [PATH_TO_IMAGE]`
`INPLACE` does not create a copy of the image, but performs all further operations on the given image.
This is an alternative to `FROM` and `TO`.

#### `INCLUDE [PATH_TO_PIFILE]`
`INCLUDE` includes the provided Pifile in the current one for modularity and re-use.
The included file _has_ to have a `.Pifile` extension which need not be specified.

#### `PUMP [SIZE]`
`PUMP` increases the image's size about the given amount (suffixes K, M, G are allowed).

#### `INSTALL <MODE> [SOURCE] [DEST]`
`INSTALL` installs a given file or directory into the destination in the image.
The optionally permission mode (*chmod*) can be set as the first parameter.

#### `PATH [/my/guest/path]`
`PATH` adds the given path to an overlaying PATH variable, used within the `RUN` command.

#### `RUN [CMD] [PARAMS ...]`
`RUN` executes a command in the chrooted image based on QEMU user emulation.

Caveat: because the Pifile is just a Bash script, pipes do not work as one might suspect.
A possible workaround could be the usage of `bash -c`:

```
RUN bash -c 'hexdump /dev/urandom | head'
```

#### `HOST [CMD] [PARAMS ...]`
`HOST` executed a command on the local host and can be used to prepare files, cross-compile software, etc.


### Pifile Extensions
Because the *Pifile* is just a Bash script, some ~~dirty~~ brilliant hacks and extensions are possible.

#### Bulk execution
Here documents can be used with the `RUN` command.

```bash
RUN <<EOF
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
apt-get install -y sl
EOF
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
