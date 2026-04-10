#!/bin/sh
ME="$0"
MYNAME=`basename "$ME"`
MYDIR=`dirname "$ME"`
MYDIR=`cd "$MYDIR"; pwd`
WD=`pwd`
#
# This is where all the stuff is installed inside.
cd "$MYDIR"
SEPHRASTO_DIR="Sephrasto"
[ -d "$SEPHRASTO_DIR" ] || { echo "[E] Directory missing! DIR='$MYDIR/$SEPHRASTO_DIR'" >&2; exit 1; }
#
cd "$SEPHRASTO_DIR"
SEPHRASTO_DIR=`pwd`
#
# Check venv
ACTIVATE="$SEPHRASTO_DIR/.venv/bin/activate"
[ -r "$ACTIVATE" ] || {
  echo "[E] Cannot find python virtual enviroment!" >&2
  echo "[E]   FILE='$ACTIVATE'" >&2
  echo "[I] How to create such an environment:" >&2
  echo "[I]   cd '$SEPHRASTO_DIR'" >&2
  echo "[I]   python -m venv .venv" >&2
  exit 1
}
#
# Enter venv.
. "$ACTIVATE" && {
  echo "[I] Python venv activated." >&2
  #
  PYSIDELIB=`echo "$SEPHRASTO_DIR"/.venv/lib/python*/site-packages/PySide6/Qt/lib | head -1`
  [ -n "$PYSIDELIB" -a -d "$PYSIDELIB" ] || { echo "[E] Cannot find python PySide library directory! DIR='$SEPHRASTO_DIR/.venv/lib/python*/site-packages/PySide6/Qt/lib'" >&2; exit 1; }
  echo "[I] PYSIDELIB='$PYSIDELIB'" >&2

  export LD_LIBRARY_PATH="$PYSIDELIB${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  echo "[I] LD_LIBRARY_PATH='$LD_LIBRARY_PATH'" >&2
  #
  # Start python program.
  echo "[I] Start programm ..." >&2
  cd "$SEPHRASTO_DIR" || { echo "[E] Cannot change to directory! DIR='$SEPHRASTO_DIR'" >&2; exit 1; }
  PRG="Sephrasto/src/Sephrasto/Sephrasto.py"
  if python "$PRG"; then
    echo "[I] Normal program termination." >&2
  else
    echo "[E] Abnormal program termination." >&2
  fi
}
exit 0
