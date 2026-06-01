#!/bin/sh
ME="$0"
MYNAME=`basename "$ME"`
MYDIR=`dirname "$ME"`
MYDIR=`cd "$MYDIR"; pwd`
WD=`pwd`
#
# This is where all the stuff is installed inside.
cd "$MYDIR"

type uv >/dev/null 2>&1 || { echo "[E] Please install uv: https://docs.astral.sh/uv/" >&2; exit 1; }

#
# This is where all the stuff is installed inside.
SEPHRASTO_DIR="Sephrasto"
[ -d "$SEPHRASTO_DIR" ] || { echo "[E] Non-existing directory! DIR='$SEPHRASTO_DIR'" >&2; exit 1; }
#
cd "$SEPHRASTO_DIR"
SEPHRASTO_DIR=`pwd`

PYSIDELIB=`ls -d "$SEPHRASTO_DIR"/.venv/lib/python*/site-packages/PySide6/Qt/lib | head -1`
[ -n "$PYSIDELIB" -a -d "$PYSIDELIB" ] || { echo "[E] Cannot find python PySide library directory! DIR='$SEPHRASTO_DIR/.venv/lib/python*/site-packages/PySide6/Qt/lib'" >&2; exit 1; }
echo "[I] PYSIDELIB='$PYSIDELIB'" >&2

export LD_LIBRARY_PATH="$PYSIDELIB${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
echo "[I] LD_LIBRARY_PATH='$LD_LIBRARY_PATH'" >&2
#
# Start python program.
echo "[I] Start programm ..." >&2
cd "$SEPHRASTO_DIR" || { echo "[E] Cannot change to directory! DIR='$SEPHRASTO_DIR'" >&2; exit 1; }
PRG="Sephrasto/src/Sephrasto/Sephrasto.py"
if uv run "$PRG"; then
  echo "[I] Normal program termination." >&2
else
  echo "[E] Abnormal program termination." >&2
fi
exit 0
