# void-linux-sephrasto-installer
Bourne shell script to install [Sephrasto](https://github.com/Aeolitus/Sephrasto) on [Void Linux](https://voidlinux.org/) - `glibc` variant. Doesn't work with `musl`, see Tests.

## Table of Contents

### Download of the Installer
Download the installer.
```
wget https://raw.githubusercontent.com/kgitthoene/void-linux-sephrasto-installer/master/void-linux-sephrasto-installer-python3.9.7.sh
```

### Example

Download, build and install Python 3.9.7 and Sephrasto.

```
/bin/sh ./void-linux-sephrasto-installer-python3.9.7.sh build install
```

### Tests

Tested with a fresh installed Void Linux `x86_64-20230628-xfce glibc`.

Doesn't work with Void Linux `x86_64-musl-20230628-xfce musl`. :sob:
There seems to be no distribution of [PySide6](https://pypi.org/project/PySide6/) for [musl](https://www.musl-libc.org/). :confused:

### Usage

```
Usage: void-linux-sephrasto-installer-python3.9.7.sh [OPTIONS] COMMAND [...]
Commands:
  build           -- Download, build and prepare all packages needed by Sephrasto.
  install         -- Install .desktop file for Sephrasto.
  clean           -- Remove all installed stuff.
  uninstall       -- Same as clean.
  run             -- Start Sephrasto.
  start           -- Same as run.
Options:
  -d, --debug     -- Output debug messages.
  -h, --help      -- Print this text.
```

#### build

The `build` command updates Void Linux, installs all needed packages, builds [Python](https://www.python.org/) 3.9.7 in a separate directory and creates a virtual Python environment to run Sephrasto.

The Python build is placed in `~/.localpython/python3.9.7`.

The Sephrato [venv](https://docs.python.org/3/library/venv.html) is placed in `~/.localpython/bin/venv-sephrasto-3.9.7`.

The script `Sephrasto.sh` to run Sephrasto is placed in `~/.localpython/bin`.

The .desktop file `Sephrasto.desktop` is placed in `~/.localpython/bin`.

The log file from Sephrato `sephrasto.log` can be found in `~/.localpython/bin/venv-sephrasto-3.9.7`.

#### install

Copies the `Sephrasto.desktop` file to `~/.local/share/applications`.

#### clean

Removes all installed stuff, including the separately installed Python and Sephrasto.

