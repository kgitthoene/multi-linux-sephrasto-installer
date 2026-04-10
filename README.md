# multi-linux-sephrasto-installer
Bourne shell script to install [Sephrasto](https://github.com/Aeolitus/Sephrasto) on popular Linux distributions.

It works on [Ubuntu](https://ubuntu.com/)/[Debian](https://www.debian.org/)/[Linux Mint](https://linuxmint.com/), [Fedora](https://getfedora.org/), [Arch Linux](https://archlinux.org/) and [Void Linux](https://voidlinux.org/) - `glibc` variant. Doesn't work with `musl`, see tests.

A separate Python version is installed, which does not interfere with the Python installation of the operating system.

## Table of Contents

### Install [pyenv](https://github.com/pyenv/pyenv)

#### Install Python build dependencies

Follow this guide to install the Python build dependencies: [pyenv-wiki](https://github.com/pyenv/pyenv?tab=readme-ov-file#d-install-python-build-dependencies).
Scroll to your OS and follow the instructions.

#### Install pyenv

Follow the instructions [here](https://github.com/pyenv/pyenv?tab=readme-ov-file#installation) or use the automatic installer (recommended):

```
curl -fsSL https://pyenv.run | bash

```

Add pyenv to your login shell, the instructions for this are displayed at the end of the installation.

#### Install the Python version recommended by the Sephrasto team

For Sephrasto 5.1.0, 5.2.0 (2026, April) Python version 3.11.x is recommended by the Sephrasto team.
Install Python version 3.11.15:

```
pyenv install 3.11.15
```

#### Install the latest version of Sephrasto

```
mkdir Sephrasto
cd Sephrasto
pyenv local 3.11.15
wget https://raw.githubusercontent.com/kgitthoene/multi-linux-sephrasto-installer/master/sephrasto-bootstrap.sh
chmod a+rx sephrasto-bootstrap.sh
./sephrasto-bootstrap.sh

```

It is not necessary to name the top level directory `Sephrasto`, take any name of your choice at any place.

You'll find Sephrasto under 'Games' aka. 'Spiele' (DE).

### Tests

The tests were carried out on fresh installations.

| Linux Distribution                        | Version                              | Type        | Test Result |
| ----------                                | ----------                           | ----------  | ----------  |
| [Void Linux](https://voidlinux.org/)      | `x86_64-20230628-xfce glibc`         | Void        | WORKING     |
| [Debian](https://www.debian.org/)         | `12.2.0-amd64-xfce`                  | Debian      | WORKING     |
| [Xubuntu](https://xubuntu.org/)           | `22.04.3-desktop-amd64 LTS`          | Ubuntu      | WORKING     |
| [Xubuntu](https://xubuntu.org/)           | `23.10-desktop-amd64`                | Ubuntu      | WORKING     |
| [Linux Mint](https://linuxmint.com/)      | `22.1_x64`                           | Debian      | WORKING     |
| [MX Linux](https://mxlinux.org/)          | `23.1_x64`                           | Debian      | WORKING     |
| [Garuda Linux](https://garudalinux.org/)  | `xfce-linux-lts-231029`              | Arch        | WORKING     |
| [Fedora](https://getfedora.org/)          | `x86_64-38-1.6`                      | Fedora      | WORKING     |
| [Manjaro Linux](https://manjaro.org/)     | `xfce-23.0.4-231015-linux65`         | Arch        | WORKING     |
| [Void Linux](https://voidlinux.org/)      | `x86_64-musl-20230628-xfce musl`[^1] | Void        | FAIL        |

[^1]: There seems to be no distribution of [PySide6](https://pypi.org/project/PySide6/) for [musl](https://www.musl-libc.org/). :confused:
