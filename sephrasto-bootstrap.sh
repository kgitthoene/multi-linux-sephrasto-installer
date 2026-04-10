#!/bin/sh
ME="$0"
MYNAME=`basename "$ME"`
MYDIR=`dirname "$ME"`
MYDIR=`cd "$MYDIR"; pwd`
WD=`pwd`
#
# This is where all the stuff is installed inside.
SEPHRASTO_DIR="Sephrasto"
[ -d "$SEPHRASTO_DIR" ] && { echo "[E] Directory exists! Remove it first! DIR='$SEPHRASTO_DIR'" >&2; exit 1; }
mkdir "$SEPHRASTO_DIR"
#
# Get run script.
wget https://raw.githubusercontent.com/kgitthoene/multi-linux-sephrasto-installer/master/run-sephrasto.sh
chmod a+rx run-sephrasto.sh
echo "[I] Downloaded 'run-sephrasto.sh' for you." >&2
#
cd "$SEPHRASTO_DIR"
SEPHRASTO_DIR=`pwd`
#
# Check venv
ACTIVATE="$SEPHRASTO_DIR/.venv/bin/activate"
[ -r "$ACTIVATE" ] || {
  echo "[W] Cannot find python virtual enviroment!" >&2
  echo "[W]   FILE='$ACTIVATE'" >&2
  echo "[I] Now, creating python virtual environment ..." >&2
  python -m venv .venv || { echo "[E] Cannot create venv!" >&2; exit 1; }
}
#
# Enter venv.
. "$ACTIVATE" && {
  echo "[I] Python venv activated." >&2
  #
  echo "[I] Clone Sephrasto ..." >&2
  git clone https://github.com/Aeolitus/Sephrasto.git || { echo "[E] Cannot clone Sephrasto!" >&2; exit 1; }
  #
  echo "[I] Install Sephrasto python requirements..." >&2
  python -m pip install pip --upgrade || { echo "[E] Cannot upgrade pip!" >&2; exit 1; }
  python -m pip install -r "Sephrasto/requirements.txt" || { echo "[E] Cannot install Sephrasto requirements!" >&2; exit 1; }
  #
  # Create the .desktop file.
  cat > "$MYDIR/Sephrasto.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Sephrasto
Exec="$MYDIR/run-sephrasto.sh"
Comment=Sephrasto
Icon=$MYDIR/Sephrasto/Sephrasto/src/Sephrasto/icon_large.png
Categories=Game;
Terminal=false
EOF
  echo "[I] Created 'Sephrasto.desktop' for you." >&2
  mkdir -p "$HOME/.local/share/applications"
  cp "$MYDIR/Sephrasto.desktop" "$HOME/.local/share/applications"
  echo "[I] Installed 'Sephrasto.desktop' to \"\$HOME/.local/share/applications\"" >&2
  echo "[I]" >&2
  echo "[I] Remember: 'Sephrasto.desktop' depends on 'run-sephrasto.sh'!" >&2
  echo "[I]" >&2
  echo "[I] Start it to test Sephrasto:" >&2
  echo "[I]   ./run-sephrasto.sh" >&2
  echo "[I]" >&2
  echo "[I] You'll find Sephrasto under 'Games' aka. 'Spiele' (DE)." >&2
  echo "[I]" >&2
  #
}
exit 0
