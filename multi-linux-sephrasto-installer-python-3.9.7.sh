#!/bin/sh
# #region[rgba(0, 255, 0, 0.05)] SOURCE-STUB
#
#----------
# Copyright (c) 2023 Kai Thöne
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#----------
#
#----------
# Set Startup Variables
ME="$0"
MYNAME=`basename "$ME"`
MYDIR=`dirname "$ME"`
MYDIR=`cd "$MYDIR"; pwd`
WD=`pwd`
SCRIPT_OPT_DEBUG=false
SCRIPT_OPT_SUDORESTART=false
#
#----------
# Library Script Functions
#
error() {
  unset ECHO_OPTION; [ "`echo -e`" = '-e' ] || ECHO_OPTION='-e'
  # red, bold
  echo $ECHO_OPTION "\033[1;31mE\033[0;1m $MYNAME: ${*}\033[0m" >&2; return 0
}

info() {
  unset ECHO_OPTION; [ "`echo -e`" = '-e' ] || ECHO_OPTION='-e'
  # cyan
  echo $ECHO_OPTION "\033[1;36mI\033[0m $MYNAME: ${*}\033[0m" >&2; return 0
}

debug() {
  [ "$SCRIPT_OPT_DEBUG" = true ] && {
    unset ECHO_OPTION; [ "`echo -e`" = '-e' ] || ECHO_OPTION='-e'
    # blue
    echo $ECHO_OPTION "\033[1;34mD\033[0m $MYNAME: ${*}\033[0m" >&2
  }; return 0
}

warn() {
  unset ECHO_OPTION; [ "`echo -e`" = '-e' ] || ECHO_OPTION='-e'
  # yellow
  echo $ECHO_OPTION "\033[1;33mW\033[0m $MYNAME: ${*}\033[0m" >&2; return 0
}

log() {
  LOGFILE="${MYNAME}.log"
  case "$1" in
    DEBUG|INFO|WARN|ERROR|CRIT) STAGE="$1"; shift;;
    *) STAGE="----";;
  esac
  STAGE="`echo "$STAGE     " | sed -e 's/^\(.\{5\}\).*$/\1/'`"
  TIMESTAMP="`date +%Y%m%d-%H:%M:%S.%N | sed -e 's/\.\([0-9]\{3\}\)[0-9]*$/.\1/'`"
  echo "${TIMESTAMP} ${STAGE} ${*}" >> "$LOGFILE"
  SIZE=`du -b "$LOGFILE" | cut -f1`
  if [ $SIZE -gt 2000000 ]; then
    INDEX=10
    while [ $INDEX -ge 1 ]; do
      INDEXPLUS=`echo "1+$INDEX" | bc`
      SUBLOGFILE="${LOGFILE}.$INDEX"
      [ -f "$SUBLOGFILE" ] && {
        if [ $INDEX -ge 10 ]; then
          rm -f "$SUBLOGFILE"
        else
          mv "$SUBLOGFILE" "${LOGFILE}.$INDEXPLUS"
        fi
      }
      INDEX=$INDEXPLUS
    done
  fi
}

cmd_exists() {
  type "$1" >/dev/null 2>&1
  return $?
}

infofile() {
  while [ -n "$1" ]; do
    [ -r "$1" -a -s "$1" ] && {
      sed 's,.*,\x1b[1;36mI\x1b[0m '"$MYNAME"': \x1b[1;32m&\x1b[0m,' "$1" >&2
    }
    shift
  done
}

check_tool() {
  while [ -n "$1" ]; do
    type "$1" >/dev/null 2>&1 || return 1
    shift
  done
  return 0
}

check_tools() {
  while [ -n "$1" ]; do
    check_tool "$1" || {
      error "Cannot find program '$1'!"
      exit 1
    }
    shift
  done
  return 0
}

getyesorno() {
  # Returns 0 for YES. Returns 1 for NO.
  # Returns 2 for abort.
  DEFAULT_ANSWER="$1"
  USER_PROMPT="$2"
  unset READ_OPTS
  echo " " | read -n 1 >/dev/null 2>&1 && READ_OPTS='-n 1'
  #--
  unset OK_FLAG
  while [ -z "$OK_FLAG" ]; do
    read -r $READ_OPTS -p "? $MYNAME: $USER_PROMPT" YNANSWER
    [ $? -ne 0 ] && return 2
    if [ -z "$YNANSWER" ]; then
      YNANSWER="$DEFAULT_ANSWER"
    else
      echo
    fi
    case "$YNANSWER" in
      [yY])
        YNANSWER=Y
        return 0
        ;;
      [nN])
        YNANSWER=N
        return 1
        ;;
    esac
  done
}  # getyesorno

read_string() {
  # Usage: read_string PROMPT VARIABLE
  # Returns 0 for YES. Returns 1 for NO.
  USER_PROMPT="$1"
  VARIABLE="$2"
  #--
  unset OK_FLAG
  while [ -z "$OK_FLAG" ]; do
    read -r -p "QUESTION -- $USER_PROMPT" $VARIABLE
    [ $? -ne 0 ] && return 1
    # VALUE=`eval echo \\\${$VARIABLE}`
    # echo "$VARIABLE=$VALUE RC=$RC"
    # [ -z "$VALUE" ] && return 1
    return 0
  done
}  # read_string

open34() {
  OPEN34_TMPFILE=`mktemp -p "$MYDIR" "$MYNAME-34-XXXXXXX"`
  exec 3>"$OPEN34_TMPFILE"
  exec 4<"$OPEN34_TMPFILE"
  rm -f "$OPEN34_TMPFILE"
}  # open34

close34() {
  exec 3>&-
  exec 4<&-
}  # close34

open56() {
  OPEN56_TMPFILE=`mktemp -p "$MYDIR" "$MYNAME-56-XXXXXXX"`
  exec 5>"$OPEN56_TMPFILE"
  exec 6<"$OPEN56_TMPFILE"
  rm -f "$OPEN56_TMPFILE"
}  # open56

close56() {
  exec 5>&-
  exec 6<&-
}  # close56

getdirectory() {
  #Usage: getdirectory [DIR ...]
  #Echoes the directory names for current or given directories.
  if [ -z "$1" ]; then
    DIR=`pwd`
    BNDIR=`basename "$DIR"`
    echo "$BNDIR"
  else
    while [ -n "$1" ]; do
      BNDIR=`basename "$1"`
      echo "$BNDIR"
      shift
    done
  fi
  return 0
}  # getdirectory

do_check_cmd() {
  echo "$*"
  "$@" || {
    error "Cannot do this! CMD='$*'"
    exit 1
  }
}

do_check_cmd_info() {
  info "$*"
  "$@" || {
    error "Cannot do this! CMD='$*'"
    exit 1
  }
}

do_check_cmd_no_echo() {
  "$@" || {
    error "Cannot do this! CMD='$*'"
    exit 1
  }
}

do_cmd() {
  echo "$*"
  "$@"
}

do_cmd_info() {
  info "$*"
  "$@" || {
    error "Cannot do this! CMD='$*'"
    return 1
  }
  return 0
}

do_check_cmd_output_only_on_error() {
  echo "$*"
  open34
  "$@" >&3 2>&1
  DO_CHECK_CMD_RC=$?
  [ $DO_CHECK_CMD_RC != 0 ] && cat <&4
  close34
  [ $DO_CHECK_CMD_RC != 0 ] && {
    error "Cannot do this! CMD='$*'"
    exit $DO_CHECK_CMD_RC
  }
  return 0
}

do_by_xterm() {
  TMPFILE_PARAM=`mktemp -p "$MYDIR" "$MYNAME-XTERM-XXXXXXX"`
  while [ -n "$1" ]; do
    echo -n "\"$1\" " >> "$TMPFILE_PARAM"
    shift
  done
  XTERM_CMD=`cat "$TMPFILE_PARAM"`
  rm -f "$TMPFILE_PARAM"; unset TMPFILE_PARAM
  TMPFILE_LOG=`mktemp -p "$MYDIR" "$MYNAME-XTERM-XXXXXXX"`
  TMPFILE_RC=`mktemp -p "$MYDIR" "$MYNAME-XTERM-XXXXXXX"`
  xterm -iconic -l -lf "$TMPFILE_LOG" -e /bin/sh -c "if $XTERM_CMD; then echo 0 > \"$TMPFILE_RC\"; else echo 1 > \"$TMPFILE_RC\"; fi"
  XTERM_RC=`cat "$TMPFILE_RC"`
  rm -f "$TMPFILE_RC"; unset TMPFILE_RC
  infofile "$TMPFILE_LOG"
  rm -f "$TMPFILE_LOG"; unset TMPFILE_LOG
  [ "$XTERM_RC" = 0 ] && return 0
  [ -n "$XTERM_RC" ] && return "$XTERM_RC"
  return 1
} # do_by_xterm

cmdpath() {
  CMD="$*"
  case "$CMD" in
    /*)
      [ -x "$CMD" ] && FOUNDPATH="$CMD"
      ;;
    */*)
      [ -x "$CMD" ] && FOUNDPATH="$CMD"
      ;;
    *)
      IFS=:
      for DIR in $PATH; do
        if [ -x "$DIR/$CMD" ]; then
          FOUNDPATH="$DIR/$CMD"
          break
        fi
      done
      unset IFS
      ;;
  esac
  if [ -n "$FOUNDPATH" ]; then
    echo "$FOUNDPATH"
  else
    return 1
  fi
}  # cmdpath

is_glibc() {
  ldd --version 2>&1 | head -1 | grep -iE '(glibc|gnu)' >/dev/null 2>&1
} # is_glibc

unset PIDFILE
unset TMPFILE
unset TMPDIR
unset OPEN34_TMPFILE
unset OPEN56_TMPFILE
at_exit() {
  [ -n "$PIDFILE" ] && [ -f "$PIDFILE" ] && rm -f "$PIDFILE"
  [ -n "$TMPFILE" ] && [ -f "$TMPFILE" ] && rm -f "$TMPFILE"
  [ -n "$TMPDIR" ] && [ -d "$TMPDIR" ] && rm -rf "$TMPDIR"
  [ -n "$OPEN34_TMPFILE" ] && [ -f "$OPEN34_TMPFILE" ] && rm "$OPEN34_TMPFILE"
  [ -n "$OPEN56_TMPFILE" ] && [ -f "$OPEN56_TMPFILE" ] && rm "$OPEN56_TMPFILE"
} # at_exit

trap at_exit EXIT HUP INT QUIT TERM
#
#----------
  #if TMPDIR=`mktemp -p . -d`; then
  #  trap at_exit EXIT HUP INT QUIT TERM && \
  #  (
  #    cd "$TMPDIR"
  #    echo "DISTRIBUTION=$DISTNAME"
  #  )
  #else
  #  echo "ERROR -- Cannot create temporary directory! CURRENT-DIR=`pwd`" >&2
  #  return 1
  #fi
# #endregion
#
#----------
# Internal Script Variables
#

#
#----------
# Internal Script Functions
#
calc() { printf "%s\n" "$@" | bc -l; }
calc_to_i() { echo "($@+0.5)/1" | bc; }
#
output_percentage() {
  PERCENT="$1"
  PPERCENT=`calc_to_i "$PERCENT"`
  [ `calc "$PPERCENT>100"` = 1 ] && PPERCENT=100
  [ "$OUTPUT_PERCENTAGE_PPERCENT" = "$PPERCENT" ] || {
    PCOUNT=`calc "$PERCENT/10"`
    PCOUNT=`calc_to_i "$PCOUNT"`
    COUNT=0
    echo -n "[ " >&2
    while [ `calc "$COUNT<$PCOUNT"` = 1 ]; do
      echo -n "#" >&2
      COUNT=`calc "$COUNT+1"`
    done
    while [ `calc "$COUNT<10"` = 1 ]; do
      echo -n " " >&2
      COUNT=`calc "$COUNT+1"`
    done
    OUTPUT_PERCENTAGE_PPERCENT=`calc_to_i "$PERCENT"`
    printf " ] %s%%\r" $OUTPUT_PERCENTAGE_PPERCENT >&2
  }
}  # output_percentage
#
output_in_case_of_error() {
  # Usage: output_in_case_of_error [--count [EXPECTED_LINES]]
  CMD="$1"
  unset ECHO_OPTION; [ "`echo -e`" = '-e' ] || ECHO_OPTION='-e'
  TMPFILE=`mktemp "$MYNAME-output_in_case_of_error-XXXXXXX"`
  trap at_exit EXIT HUP INT QUIT TERM
  COUNT=0
  IS_CALCULATOR_AVAILABLE=false
  type bc >/dev/null 2>&1 && IS_CALCULATOR_AVAILABLE=true
  if [ "$CMD" = "--count" -a $IS_CALCULATOR_AVAILABLE = true ]; then
    IS_OUTPUT_AS_PERCENTAGE_BAR=false
    [ -n "$2" ] && {
      IS_OUTPUT_AS_PERCENTAGE_BAR=true
      NR_OF_EXPECTED_LINES="$2"
    }
    if [ $IS_OUTPUT_AS_PERCENTAGE_BAR = true ]; then
      NR_LINE=0
      {
        while read LINE; do
          NR_LINE=`calc "$NR_LINE+1"`
          PERCENTAGE=`calc "100.0*($NR_LINE/$NR_OF_EXPECTED_LINES)"`
          echo $LINE
          output_percentage $PERCENTAGE
          COUNT=`echo "$COUNT+1" | bc`
        done
        output_percentage 100
      } >"$TMPFILE"
    else
      while read LINE; do
        echo $LINE
        echo -n $ECHO_OPTION "$COUNT\r" >&2
        COUNT=`echo "$COUNT+1" | bc`
      done >"$TMPFILE"
    fi
    echo "" >&2
  else
    cat > "$TMPFILE"
  fi
  RC=$?; [ "$RC" = 0 ] || exit 1
  LINE=`tail -n 1 "$TMPFILE"`
  RC=0
  case "$LINE" in
    PIPESTATE*=*) RC=`echo "$LINE" | sed -e 's/PIPESTATE.*=//'`;;
    *) RC=1;;
  esac
  #echo "output_in_case_of_error: RC=$RC" >&2
  [ "$RC" = "0" ] || { head -n -1 "$TMPFILE"; }
  rm -f "$TMPFILE"
  return $RC
}  # output_in_case_of_error
#
get_dists() {
  GET_DISTS_SCRIPT_OPT_CHECK=""
  while [ "${#}" != "0" ]; do
    SCRIPT_OPTION="true"
    case "${1}" in
      --check) if [ -n "$2" ]; then shift; GET_DISTS_SCRIPT_OPT_CHECK="$1"; else error "Missing argument for option! OPTION='${1}'"; exit 1; fi; shift; continue;;
    esac
    if [ "$SCRIPT_OPTION" = "true" ]; then
      flag="${1#?}"
      while [ -n "${flag}" ]; do
        case "${flag}" in
          c) if [ -n "$2" ]; then shift; GET_DISTS_SCRIPT_OPT_CHECK="$1"; else error "Missing argument for option! OPTION='-${flag}'"; exit 1; fi;;
          *) error "Invalid option! OPTION='${flag%"${flag#?}"}'"; exit 1;;
        esac
        flag="${flag#?}"
      done
    fi
    shift
  done
  #
  if [ -n "$GET_DISTS_SCRIPT_OPT_CHECK" ]; then
    # Check if given distribution is valid.
    get_dists | { VALID_DISTRIBUTION=false; while read DISTRIBUTION; do
        [ "$GET_DISTS_SCRIPT_OPT_CHECK" = "$DISTRIBUTION" ] && { VALID_DISTRIBUTION=true; break; }
      done; }
    RC=$?
    return $RC
  else
    # Echo all known distributions.
    for D in Void Ubuntu 'Debian GNU/Linux' Arch 'Garuda Linux' Fedora 'Fedora Linux'; do echo "$D"; done
  fi
  return 0
}  # get_dists
#
sudo_install_void_packages() {
  # Packages to build python3:
  info "Update system ... (On a fresh system this may take a long time.)"
  { xbps-install -y -Su 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error || { xbps-install -y -u xbps >/dev/null 2>&1; } || { error "Failed: xbps-install -y -u xbps"; exit 1; }
  { xbps-install -y -Su 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error || { error "Failed: xbps-install -y -Su"; exit 1; }
  # Packages to build python
  info "Install packages to build python ..."
  { xbps-install -y base-devel binutils tar bc wget git xz openssl-devel zlib-devel ncurses-devel readline-devel libyaml-devel libffi-devel libxcb-devel libzstd-devel gdbm-devel liblzma-devel tk-devel libipset-devel libnsl-devel libtirpc-devel; echo PIPESTATE0=$?; } 2>&1 | output_in_case_of_error || { error "Failed to install packages to build python!"; exit 1; }
  # Packages to run Sephrasto
  info "Install packages to run Sephrasto ..."
  { xbps-install -y qt5 libxcb libxcb-devel xcb-util-cursor xcb-imdkit xcb-util-errors xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm xcb-util-xrm; echo PIPESTATE0=$?; } 2>&1 | output_in_case_of_error || { error "Failed to install packages to run Sephrasto!"; exit 1; }
}  # sudo_install_void_packages
#
sudo_install_ubuntu_packages() {
  # Packages to build python3:
  info "Update system ... (On a fresh system this may take a long time.)"
  { apt -y update 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error || { error "Failed: apt -y update"; exit 1; }
  { apt -y upgrade 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error || { error "Failed: apt -y upgrade"; exit 1; }
  # Packages to build python
  info "Install packages to build python ..."
  { apt -y install build-essential binutils bc tar wget git xz-utils autoconf libtool libssl-dev libzip-dev libncurses-dev libreadline-dev libyaml-dev libffi-dev libx11-xcb-dev libzstd-dev libgdbm-dev liblzma-dev tk-dev libipset-dev libnsl-dev libtirpc-dev libncursesw5-dev libc6-dev libsqlite3-dev libbz2-dev libsqlite3-dev zlib1g zlib1g-dev 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error || { error "Failed to install packages to build python!"; exit 1; }
  # Packages to run Sephrasto
  info "Install packages to run Sephrasto ..."
  { apt -y install qtcreator qtbase5-dev qt5-qmake libxcb-composite0 libxcb-cursor0 libxcb-damage0 libxcb-doc libxcb-dpms0 libxcb-dri2-0 libxcb-dri3-0 libxcb-ewmh2 libxcb-glx0 libxcb-icccm4 libxcb-image0 libxcb-imdkit1 libxcb-keysyms1 libxcb-present0 libxcb-randr0 libxcb-record0 libxcb-render-util0 libxcb-render0 libxcb-res0 libxcb-screensaver0 libxcb-shape0 libxcb-shm0 libxcb-sync1 libxcb-util1 libxcb-xf86dri0 libxcb-xfixes0 libxcb-xinerama0 libxcb-xinput0 libxcb-xkb1 libxcb-xrm0 libxcb-xtest0 libxcb-xv0 libxcb-xvmc0 libxcb1 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error || { error "Failed to install packages to run Sephrasto!"; exit 1; }
}  # sudo_install_ubuntu_packages
#
sudo_install_arch_packages() {
  # Packages to build python3:
  info "Update system ... (On a fresh system this may take a long time.)"
  pacman --noconfirm -Syu || { error "Failed: pacman -Syu"; exit 1; }
  # Packages to build python
  info "Install packages to build python and to run Sephrasto ..."
  pacman --noconfirm --needed -S base-devel binutils bc tar wget git xz autoconf libtool openssl zlib ncurses readline libyaml libffi libxcb zstd gdbm lzlib tk ipset libnsl libtirpc sqlite zlib  qtcreator qt5-base libxcb xcb-util xcb-util-cursor xcb-util-errors xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm xcb-util-xrm || { error "Failed to install packages to build python and to run Sephrasto!"; exit 1; }
}  # sudo_install_arch_packages
#
sudo_install_fedora_packages() {
  # Packages to build python3:
  info "Update system ... (On a fresh system this may take a long time.)"
  dnf -y upgrade || { error "Failed: dnf -y upgrade"; exit 1; }
  # Packages to build python
  info "Install packages to build python and to run Sephrasto ..."
  dnf -y install make automake gcc gcc-c++ kernel-devel binutils bc tar wget git xz autoconf libtool openssl-devel zlib-devel ncurses-devel readline-devel libyaml-devel libffi-devel libxcb libxcb-devel libzstd-devel gdbm-devel liblzf-devel xz-devel tk-devel ipset-devel libnsl2-devel libtirpc-devel sqlite-devel zlib-devel  qt5-qtbase qt5-qtbase-gui qt5-qtbase-static xcb-util xcb-util-cursor xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm xcb-util-xrm || { error "Failed to install packages to build python and to run Sephrasto!"; exit 1; }
}  # sudo_install_fedora_packages
#
do_with_sudo() {
  CMD="$1"
  [ -z "$CMD" ] && {
    error "Internal error! Missing command for do_with_sudo!"
    exit 1
  }
  #
  #----------
  # Check root permissions.
  #
  unset MEUID
  MEUID=`id -u`
  [ "$MEUID" != 0 ] && {
    [ "$SCRIPT_OPT_SUDORESTART" = true ] && {
      error "Must run this script as root!" >&2
      exit 1
    }
    if type sudo >/dev/null 2>&1; then
      warn "You don't have super cow powers! Try to start commands with sudo ..."
      sudo -H "$SHELL" "$ME" - "$CMD"; RC=$?
      info "|< End of sudo command sequence."
      [ "$RC" = "0" ] || exit $RC
    else
      error "Must run this commands as root! Missing tool! TOOL='sudo'"
      exit 1
    fi
  }
  unset MEUID CMD
}  # do_with_sudo
#
do_update_sephrasto() {
  LOCAL_SEPHRASTRO_DIR="$HOME/.localpython/bin"
  [ -d "$LOCAL_SEPHRASTRO_DIR/venv-sephrasto-$PYHTON_VERSION_TO_INSTALL" ] || {
    error "Missing directory! Execute command 'build' first! DIR='$LOCAL_SEPHRASTRO_DIR/venv-sephrasto-$PYHTON_VERSION_TO_INSTALL'"
    return 1
  }
  [ -f "$LOCAL_SEPHRASTRO_DIR/venv-sephrasto-$PYHTON_VERSION_TO_INSTALL/bin/activate" ] || {
    error "Missing 'activate' script in virtual environment! Execute command 'build' first!"
    return 1
  }
  cd "$LOCAL_SEPHRASTRO_DIR/venv-sephrasto-$PYHTON_VERSION_TO_INSTALL"
  . ./bin/activate
  ./bin/python3 -m pip install --upgrade pip
  [ -d "Sephrasto" ] && {
    # Remove old version of Sephrasto.
    rm -rf "Sephrasto"
  }
  info "Download Sephrasto ..."
  [ -d Sephrasto ] || git clone https://github.com/Aeolitus/Sephrasto.git || { error "Cannot download Sephrasto! GIT CLONE"; exit 1; }
  info "Install Sephrasto requirements ..."
  ./bin/pip install -r Sephrasto/requirements.txt || { error "Cannot install Sephrasto requierements! PIP INSTALL"; exit 1; }
  RC=$?; [ $RC = 0 ] || return 1
  info "Create Sephrasto .desktop file ..."
  cat > "$LOCAL_SEPHRASTRO_DIR/Sephrasto.desktop" <<EOF
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
GenericName=Sephrasto
Name=Sephrasto
Comment=A character generator for the DSA house rules system Ilaris.
Exec=/bin/sh "$LOCAL_SEPHRASTRO_DIR/Sephrasto.sh"
Icon=$LOCAL_SEPHRASTRO_DIR/venv-sephrasto-$PYHTON_VERSION_TO_INSTALL/Sephrasto/src/Sephrasto/icon_large.png
Terminal=false
StartupNotify=true
Categories=Game;
Name[de_DE]=Sephrasto
EOF
  info "Create Sephrasto startup script ..."
  cat > "$LOCAL_SEPHRASTRO_DIR/Sephrasto.sh" <<EOF
#!/bin/sh
IS_START_BY_COMMAND=false
[ "\$1" = "run" ] && IS_START_BY_COMMAND=true
cd "$LOCAL_SEPHRASTRO_DIR/venv-sephrasto-$PYHTON_VERSION_TO_INSTALL"
. ./bin/activate
if [ "\$IS_START_BY_COMMAND" = true ]; then
  ./bin/python3 Sephrasto/src/Sephrasto/Sephrasto.py || cat sephrasto.log >&2
else
  exec ./bin/python3 Sephrasto/src/Sephrasto/Sephrasto.py
fi
EOF
  info "Install Sephrasto with \`$MYNAME install\`"
  info "Start Sephrasto with \`$MYNAME run\`"
  return 0
}  # do_update_sephrasto
#
do_build() {
  DISTRIBUTION="$1"; shift
  case "$DISTRIBUTION" in
    Void) do_with_sudo sudo_install_void_packages || exit 1;;
    Ubuntu|'Debian GNU/Linux') do_with_sudo sudo_install_ubuntu_packages || exit 1;;
    Arch|'Garuda Linux') do_with_sudo sudo_install_arch_packages || exit 1;;
    Fedora|'Fedora Linux') do_with_sudo sudo_install_fedora_packages || exit 1;;
    *)
      error "Unknown or invalid distribution! DISTRIBUTION='$DIST_NAME'"
      exit 1
      ;;
  esac
  #
  info "Create build directories ..."
  LOCAL_PYTHON_BUILD_DIR="$HOME/.localpython/build"
  [ -d "$LOCAL_PYTHON_BUILD_DIR" ] || mkdir -p "$LOCAL_PYTHON_BUILD_DIR" || { error "Cannot create directory! DIR='$LOCAL_PYTHON_BUILD_DIR'"; exit 1; }
  LOCAL_SEPHRASTRO_DIR="$HOME/.localpython/bin"
  [ -d "$LOCAL_SEPHRASTRO_DIR" ] || mkdir -p "$LOCAL_SEPHRASTRO_DIR" || { error "Cannot create directory! DIR='$LOCAL_SEPHRASTRO_DIR'"; exit 1; }
  LOCAL_PYTHON_INSTALLATION_DIR="$HOME/.localpython/python-$PYHTON_VERSION_TO_INSTALL"
  [ -d "$LOCAL_PYTHON_INSTALLATION_DIR" ] || mkdir -p "$LOCAL_PYTHON_INSTALLATION_DIR" || { error "Cannot create directory! DIR='$LOCAL_PYTHON_INSTALLATION_DIR'"; exit 1; }
  #
  # Download python.
  info "Download python source tarball ..."
  TMPFILE=`mktemp -p "$LOCAL_PYTHON_BUILD_DIR" "$MYNAME-python-src-XXXXXXX"`
  trap at_exit EXIT HUP INT QUIT TERM
  wget -q "https://www.python.org/ftp/python/$PYHTON_VERSION_TO_INSTALL/Python-$PYHTON_VERSION_TO_INSTALL.tar.xz" -O - > "$TMPFILE" || exit 1
  (
    cd "$LOCAL_PYTHON_BUILD_DIR" || exit 1
    tar xf "$TMPFILE" || exit 1
    rm -f "$TMPFILE"
    info "Build python version=$PYHTON_VERSION_TO_INSTALL"
    cd "Python-$PYHTON_VERSION_TO_INSTALL" ||  { error "Cannot change to directory! DIR='$LOCAL_PYTHON_BUILD_DIR/Python-$PYHTON_VERSION_TO_INSTALL'"; exit 1; }
    #
    case "$DISTRIBUTION" in
      Void)
        info "Build python: ./configure ..."
        unset OUTPUT_PERCENTAGE_PPERCENT
        { ./configure --prefix="$LOCAL_PYTHON_INSTALLATION_DIR" 2>&1 ; echo PIPESTATE0=$?; } | output_in_case_of_error --count 746 || { error "Failed: ./configure ..."; exit 1; }
        info "Build python: make"
        unset OUTPUT_PERCENTAGE_PPERCENT
        { make 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error --count 753 || { error "Failed: make"; exit 1; }
        info "Build python: make install"
        unset OUTPUT_PERCENTAGE_PPERCENT
        { make install 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error --count 8096 || { error "Failed: make install"; exit 1; }
        ;;
      Ubuntu|'Debian GNU/Linux')
        info "Build python: ./configure ..."
        unset OUTPUT_PERCENTAGE_PPERCENT
        { ./configure --prefix="$LOCAL_PYTHON_INSTALLATION_DIR" 2>&1 ; echo PIPESTATE0=$?; } | output_in_case_of_error --count 747 || { error "Failed: ./configure ..."; exit 1; }
        info "Build python: make"
        unset OUTPUT_PERCENTAGE_PPERCENT
        { make 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error --count 733 || { error "Failed: make"; exit 1; }
        info "Build python: make install"
        unset OUTPUT_PERCENTAGE_PPERCENT
        { make install 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error --count 8125 || { error "Failed: make install"; exit 1; }
        ;;
      Arch|'Garuda Linux')
        info "Build python: ./configure ..."
        unset OUTPUT_PERCENTAGE_PPERCENT
        { ./configure --prefix="$LOCAL_PYTHON_INSTALLATION_DIR" 2>&1 ; echo PIPESTATE0=$?; } | output_in_case_of_error --count 746 || { error "Failed: ./configure ..."; exit 1; }
        info "Build python: make"
        unset OUTPUT_PERCENTAGE_PPERCENT
        { make 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error --count 776 || { error "Failed: make"; exit 1; }
        info "Build python: make install"
        unset OUTPUT_PERCENTAGE_PPERCENT
        { make install 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error --count 8119 || { error "Failed: make install"; exit 1; }
        ;;
      Fedora|'Fedora Linux')
        info "Build python: ./configure ..."
        unset OUTPUT_PERCENTAGE_PPERCENT
        { ./configure --prefix="$LOCAL_PYTHON_INSTALLATION_DIR" 2>&1 ; echo PIPESTATE0=$?; } | output_in_case_of_error --count 746 || { error "Failed: ./configure ..."; exit 1; }
        info "Build python: make"
        unset OUTPUT_PERCENTAGE_PPERCENT
        { make 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error --count 779 || { error "Failed: make"; exit 1; }
        info "Build python: make install"
        unset OUTPUT_PERCENTAGE_PPERCENT
        { make install 2>&1; echo PIPESTATE0=$?; } | output_in_case_of_error --count 8129 || { error "Failed: make install"; exit 1; }
        ;;
      *)
        error "Unknown or invalid distribution! DISTRIBUTION='$DIST_NAME'"
        exit 1
        ;;
    esac
    exit 0
  )
  RC=$?
  [ -f "$TMPFILE" ] && rm -f "$TMPFILE"
  [ $RC = 0 ] || exit 1
  (
    info "Create Sephrasto python environment ..."
    (
      cd "$LOCAL_PYTHON_INSTALLATION_DIR"
      ./bin/python3 -m pip install --upgrade pip
      ./bin/python3 -m pip install virtualenv
      exit 0
    )
    RC=$?; [ $RC = 0 ] || exit 1
    cd "$LOCAL_SEPHRASTRO_DIR"
    # Create virtual environment.
    "$LOCAL_PYTHON_INSTALLATION_DIR/bin/python3" -m venv "venv-sephrasto-$PYHTON_VERSION_TO_INSTALL"
    # Install Sephrasto to virtual environment.
    do_update_sephrasto || exit 1
    exit 0
  )
  RC=$?
  [ -f "$TMPFILE" ] && rm -f "$TMPFILE"
  [ $RC = 0 ] || return 1
  return 0
}  # do_build
#
do_install() {
  LOCAL_SEPHRASTRO_DIR="$HOME/.localpython/bin"
  [ -d "$LOCAL_SEPHRASTRO_DIR" ] || { error "Cannot find directory! DIR='$LOCAL_SEPHRASTRO_DIR'"; exit 1; }
  for FILE in Sephrasto.desktop; do
    [ -f "$LOCAL_SEPHRASTRO_DIR/$FILE" ] || {
      error "Cannot find file! FILE='$LOCAL_SEPHRASTRO_DIR/$FILE'"
      info "Try \`$MYNAME build\` first!"
      exit 1
    }
  done
  [ -d "$HOME/.local/share/applications" ] || mkdir -p "$HOME/.local/share/applications" || { error "Cannot create directory! DIR='$HOME/.local/share/applications'"; exit 1; }
  cp "$LOCAL_SEPHRASTRO_DIR/Sephrasto.desktop" "$HOME/.local/share/applications" || { error "Cannot copy file! FROM='$LOCAL_SEPHRASTRO_DIR/Sephrasto.desktop' TO-DIR='$HOME/.local/share/applications'"; exit 1; }
  info "Installation complete."
  info "'Sephrasto.desktop' was copied to '$HOME/.local/share/applications'"
  return 0
}
#
do_clean() {
  IS_SOMETHING_TO_CLEAN=false
  for DIR in \
    "$HOME/.localpython/build/Python-$PYHTON_VERSION_TO_INSTALL" \
    "$HOME/.localpython/bin/venv-sephrasto-$PYHTON_VERSION_TO_INSTALL" \
    "$HOME/.localpython/python-$PYHTON_VERSION_TO_INSTALL"; do
    [ -d "$DIR" ] && { info "Directory to remove: '$DIR'"; IS_SOMETHING_TO_CLEAN=true; }
  done
  for FILE in \
    "$HOME/.localpython/bin/Sephrasto.desktop" \
    "$HOME/.localpython/bin/Sephrasto.sh" \
    "$HOME/.local/share/applications/Sephrasto.desktop"; do
    [ -f "$FILE" ] && { info "File to remove: '$FILE'"; IS_SOMETHING_TO_CLEAN=true; }
  done
  if [ "$IS_SOMETHING_TO_CLEAN" = true ]; then
    if getyesorno N "Do you want to proceed? [yN]" <&1; then
      for DIR in \
        "$HOME/.localpython/build/Python-$PYHTON_VERSION_TO_INSTALL" \
        "$HOME/.localpython/bin/venv-sephrasto-$PYHTON_VERSION_TO_INSTALL" \
        "$HOME/.localpython/python-$PYHTON_VERSION_TO_INSTALL"; do
        [ -d "$DIR" ] && { rm -rf "$DIR"; }
      done
      for FILE in \
        "$HOME/.localpython/bin/Sephrasto.desktop" \
        "$HOME/.localpython/bin/Sephrasto.sh" \
        "$HOME/.local/share/applications/Sephrasto.desktop"; do
        [ -f "$FILE" ] && { rm -f "$FILE"; }
      done
      info "Cleaned!"
    fi
  else
    info "Nothing to clean."
  fi
  return 0
}  # do_clean
#
do_run() {
  LOCAL_SEPHRASTRO_DIR="$HOME/.localpython/bin"
  [ -d "$LOCAL_SEPHRASTRO_DIR" ] || { error "Cannot find directory! DIR='$LOCAL_SEPHRASTRO_DIR'"; exit 1; }
  [ -r "$LOCAL_SEPHRASTRO_DIR/Sephrasto.sh" ] || {
    error "Cannot find file! FILE='$LOCAL_SEPHRASTRO_DIR/Sephrasto.sh'"
    info "Try \`$MYNAME build\` first!"
    exit 1
  }
  exec /bin/sh "$LOCAL_SEPHRASTRO_DIR/Sephrasto.sh" run
}  # do_run
#
usage() {
  cat >&2 <<EOF
Usage: $MYNAME [OPTIONS] COMMAND [...]
Commands:
  build           -- Download, build and prepare all packages needed by Sephrasto.
  install         -- Install .desktop file for Sephrasto.
  update          -- Update Sephrasto to the newest version.
  clean           -- Remove all installed stuff.
  uninstall       -- Same as clean.
  run             -- Start Sephrasto.
  start           -- Same as run.
  list            -- Show all known supported distributions.
Options:
  -D DISTRIBUTION-NAME, --distribution DISTRIBUTION-NAME
                  -- Overwrite the OS given distribution name.
  -d, --debug     -- Output debug messages.
  -h, --help      -- Print this text.
EOF
}
#
do_list_distributions() {
  info "Valid distributions:"
  get_dists | while read DISTRIBUTION; do
    info "  $DISTRIBUTION"
  done
  info "Your OS is '$OS_DIST_NAME'."
  return 0
}  # do_list_distributions
#
#----------
# Check restart of this script.
#
check_tools printf tar sed basename dirname sudo grep
[ "$1" = "-" ] && { SCRIPT_OPT_SUDORESTART=true; shift; }
#
#----------
# Read options.
#
SCRIPT_ARGS_HERE=false
SCRIPT_LAST_OPT=""
SCRIPT_OPT_PARAMETER=false
SCRIPT_OPT_QUIT=false
SCRIPT_OPT_VERBOSE=false
SCRIPT_OPT_LIST_LANGS=false
SCRIPT_OPT_BASENAME=false
SCRIPT_OPT_RM_MULTIPLE_EMPTY_LINES=false
SCRIPT_OPT_LANGUAGE="$OCR_LANGUAGE"
SCRIPT_ARGS_HERE="false"
SCRIPT_OPT_PIDFN="/var/run/$MYNAE.pid"
SCRIPT_OPT_DIST_NAME=""
open56
while [ "${#}" != "0" ]; do
  SCRIPT_OPTION="true"
  case "${1}" in
    --clean) info "CLEAN"; exit $?;;
    --debug) SCRIPT_OPT_DEBUG=true; shift; continue;;
    --quit) SCRIPT_OPT_QUIT=true; shift; continue;;
    --verbose) SCRIPT_OPT_VERBOSE=true; shift; continue;;
    --pid-file) if [ -n "$2" ]; then shift; SCRIPT_OPT_PIDFN="$1"; else error "Missing argument for option! OPTION='${1}'"; exit 1; fi; shift; continue;;
    --distribution) if [ -n "$2" ]; then shift; SCRIPT_OPT_DIST_NAME="$1"; else error "Missing argument for option! OPTION='${1}'"; exit 1; fi; shift; continue;;
    --log-invalid) log "'${1}' invalid. Use ${1}=... instead"; exit 1; continue;;
    --help) usage; exit 0;;
    --*) error "Invalid option. OPTION='${1}'"; usage 1; exit 1;;
    # Posix getopt stops after first non-option
    -*);;
    *) echo "$1" >&5; SCRIPT_OPTION="false"; SCRIPT_ARGS_HERE="true";;  # Put normal args to tempfile.
  esac
  if [ "$SCRIPT_OPTION" = "true" ]; then
    flag="${1#?}"
    while [ -n "${flag}" ]; do
      case "${flag}" in
        h*) usage; exit 0;;
        c*) info "CLEAN"; exit $? ;;
        d*) SCRIPT_OPT_DEBUG=true;;
        l*) SCRIPT_OPT_LOCAL=true;;
        D) if [ -n "$2" ]; then shift; SCRIPT_OPT_DIST_NAME="$1"; else error "Missing argument for option! OPTION='-${flag}'"; exit 1; fi;;
        P) if [ -n "$2" ]; then shift; SCRIPT_OPT_PIDFN="$1"; else error "Missing argument for option! OPTION='-${flag}'"; exit 1; fi;;
        C*) info "BIG-CLEAN"; exit $? ;;
        q*) SCRIPT_OPT_QUIT=true;;
        Q*) exit 0;;
        *) error "Invalid option! OPTION='-${flag%"${flag#?}"}'"; usage 1; exit 1;;
      esac
      flag="${flag#?}"
    done
  fi
  shift
done
#
#----------------------------------------------------------------------
# START
#
#
#----------
# Check distribution.
# 1: /etc/*-release file method.
#
DIST_NAME=`cat /etc/*-release 2>/dev/null | sed -e 's/^NAME=\(.*\)/\1/' -e tfound -e d -e :found -e 's/^"\(.*\)"$/\1/' -e 's/^\s*\(.*\)\s*$/\1/' | head -1`
DIST_VERSION=`cat /etc/*-release 2>/dev/null | sed -e 's/^VERSION_ID=\(.*\)/\1/' -e tfound -e d -e :found -e 's/^"\(.*\)"$/\1/' -e 's/^\s*\(.*\)\s*$/\1/' | head -1`
#
# 2: lsb_release command method.
#
[ -z "$DIST_NAME" ] && {
  type lsb_release >/dev/null 2>&1 && {
    DIST_NAME=`lsb_release -a 2>/dev/null | sed -e 's/^Distributor ID:\(.*\)/\1/' -e tfound -e d -e :found -e 's/^"\(.*\)"$/\1/'  -e 's/^\s*\(.*\)\s*$/\1/' | head -1`
    DIST_VERSION=`lsb_release -a 2>/dev/null | sed -e 's/^Release:\(.*\)/\1/' -e tfound -e d -e :found -e 's/^"\(.*\)"$/\1/'  -e 's/^\s*\(.*\)\s*$/\1/' | head -1`
  }
}
#
# 3: hostnamectl command method:
#
[ -z "$DIST_NAME" ] && {
  type hostnamectl >/dev/null 2>&1 && {
    DIST_VERSION=`hostnamectl 2>/dev/null | sed -e 's/^.*Operating System:\(.*\)/\1/' -e tfound -e d -e :found -e 's/^"\(.*\)"$/\1/'  -e 's/^\s*\(.*\)\s*$/\1/' | head -1`
  }
}
[ -z "$DIST_NAME" ] && { DIST_NAME="(unknown)"; }
OS_DIST_NAME="$DIST_NAME"
#
[ -n "$SCRIPT_OPT_DIST_NAME" ] && {
  DIST_NAME="$SCRIPT_OPT_DIST_NAME"
  DIST_VERSION=""
}
debug "DIST_NAME='$DIST_NAME' DIST_VERSION='$DIST_VERSION'"
# Check distribution.
get_dists --check "$DIST_NAME" || {
  error "Invalid or unknown distribution! DISTRIBUTION='$DIST_NAME'"
  error "List all valid distributions with command \`list\`."
  exit 1
}
is_glibc || {
  error "Sorry, you should have glibc (https://www.gnu.org/software/libc/) to run Sephrasto!"
  exit 1
}
#
#----------
# Do commands:
export PYHTON_VERSION_TO_INSTALL="3.9.7"
cat <&6 | while read ARG; do
  case "$ARG" in
    build) do_build "$DIST_NAME"; RC=$?; [ $RC = 0 ] || exit $RC;;
    install) do_install; RC=$?; [ $RC = 0 ] || exit $RC;;
    update) do_update_sephrasto; RC=$?; [ $RC = 0 ] || exit $RC;;
    clean|uninstall) do_clean; RC=$?; [ $RC = 0 ] || exit $RC;;
    run|start) do_run; RC=$?; [ $RC = 0 ] || exit $RC;;
    sudo_install_void_packages) sudo_install_void_packages; RC=$?; [ $RC = 0 ] || exit $RC;;
    sudo_install_ubuntu_packages) sudo_install_ubuntu_packages; RC=$?; [ $RC = 0 ] || exit $RC;;
    sudo_install_arch_packages) sudo_install_arch_packages; RC=$?; [ $RC = 0 ] || exit $RC;;
    sudo_install_fedora_packages) sudo_install_fedora_packages; RC=$?; [ $RC = 0 ] || exit $RC;;
    list) do_list_distributions; RC=$?; [ $RC = 0 ] || exit $RC;;
    *) error "Unknown command! CMD='$ARG'"; exit 10;;
  esac
done
close56
#
if [ "$SCRIPT_ARGS_HERE" = false ]; then
  error "No commands given!"
  usage
fi
