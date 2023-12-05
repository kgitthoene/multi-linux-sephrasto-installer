# multi-linux-sephrasto-installer
Bourne shell script to install [Sephrasto](https://github.com/Aeolitus/Sephrasto) on [Void Linux](https://voidlinux.org/) - `glibc` variant. Doesn't work with `musl`, see tests.

It also works on [Ubuntu](https://ubuntu.com/)/[Debian](https://www.debian.org/), [Fedora](https://getfedora.org/) and [Arch Linux](https://archlinux.org/).

A separate Python version is installed, which does not interfere with the Python installation of the operating system.

## Table of Contents

### Download of the Installer
Download the installer.
```
wget https://raw.githubusercontent.com/kgitthoene/multi-linux-sephrasto-installer/master/multi-linux-sephrasto-installer-python-3.9.7.sh
```

### Example

Download, build and install Python 3.9.7 and Sephrasto.

```
/bin/sh ./multi-linux-sephrasto-installer-python-3.9.7.sh build install
```

### Tests

The tests were carried out on fresh installations.

| Linux Distribution                        | Version                              | Type        | Test Result |
| ----------                                | ----------                           | ----------  | ----------  |
| [Void Linux](https://voidlinux.org/)      | `x86_64-20230628-xfce glibc`         | Void        | WORKING     |
| [Debian](https://www.debian.org/)         | `12.2.0-amd64-xfce`                  | Debian      | WORKING     |
| [Xubuntu](https://xubuntu.org/)           | `22.04.3-desktop-amd64 LTS`          | Ubuntu      | WORKING     |
| [Xubuntu](https://xubuntu.org/)           | `23.10-desktop-amd64`                | Ubuntu      | WORKING     |
| [MX Linux](https://mxlinux.org/)          | `23.1_x64`                           | Debian      | WORKING     |
| [Garuda Linux](https://garudalinux.org/)  | `xfce-linux-lts-231029`              | Arch        | WORKING     |
| [Fedora](https://getfedora.org/)          | `x86_64-38-1.6`                      | Fedora      | WORKING     |
| [Manjaro Linux](https://manjaro.org/)     | `xfce-23.0.4-231015-linux65`         | Arch        | WORKING     |
| [Void Linux](https://voidlinux.org/)      | `x86_64-musl-20230628-xfce musl`[^1] | Void        | FAIL        |

[^1]: There seems to be no distribution of [PySide6](https://pypi.org/project/PySide6/) for [musl](https://www.musl-libc.org/). :confused:

### Usage

```
Usage: multi-linux-sephrasto-installer-python-3.9.7.sh [OPTIONS] COMMAND [...]
Commands:
  build           -- Download, build and prepare all packages needed by Sephrasto.
  install         -- Install .desktop file for Sephrasto.
  clean           -- Remove all installed stuff.
  update          -- Update Sephrasto to the newest version.
  uninstall       -- Same as clean.
  run             -- Start Sephrasto.
  start           -- Same as run.
  list            -- Show all known supported distributions.
Options:
  -D DISTRIBUTION-NAME, --distribution DISTRIBUTION-NAME
                  -- Overwrite the OS given distribution name.
  -d, --debug     -- Output debug messages.
  -h, --help      -- Print this text.
```

#### build

The `build` command updates your Linux, installs all needed packages, builds [Python](https://www.python.org/) 3.9.7 in a separate directory and creates a virtual Python environment to run Sephrasto.

The Python build is placed in `~/.localpython/python3.9.7`.

The Sephrasto [venv](https://docs.python.org/3/library/venv.html) is placed in `~/.localpython/bin/venv-sephrasto-3.9.7`.

The script `Sephrasto.sh` to run Sephrasto is placed in `~/.localpython/bin`.

The .desktop file `Sephrasto.desktop` is placed in `~/.localpython/bin`.

The log file from Sephrasto `sephrasto.log` can be found in `~/.localpython/bin/venv-sephrasto-3.9.7`.

#### install

Copies the `Sephrasto.desktop` file to `~/.local/share/applications`.[^2]

#### run

Start Sephrasto from command line.[^2]

[^2]: This only works if you have previously run the build command.

#### clean

Removes all installed stuff[^3], including the separately installed Python and Sephrasto.

[^3]: But not the installed OS packages.
  I'am not going to destruct your system!
