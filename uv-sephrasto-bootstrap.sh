#!/bin/sh
ME="$0"
MYNAME=`basename "$ME"`
MYDIR=`dirname "$ME"`
MYDIR=`cd "$MYDIR"; pwd`
WD=`pwd`

type uv >/dev/null 2>&1 || { echo "[E] Please install uv: https://docs.astral.sh/uv/" >&2; exit 1; }
type git >/dev/null 2>&1 || { echo "[E] Please install 'git'" >&2; exit 1; }
type wget >/dev/null 2>&1 || { echo "[E] Please install 'wget'" >&2; exit 1; }

#
# Get run script.
wget https://raw.githubusercontent.com/kgitthoene/multi-linux-sephrasto-installer/master/uv-run-sephrasto.sh
chmod a+rx uv-run-sephrasto.sh
echo "[I] Downloaded 'uv-run-sephrasto.sh' for you." >&2

#
# This is where all the stuff is installed inside.
SEPHRASTO_DIR="Sephrasto"
[ -d "$SEPHRASTO_DIR" ] && { echo "[E] Directory exists! Remove it first! DIR='$SEPHRASTO_DIR'" >&2; exit 1; }
uv init "$SEPHRASTO_DIR" || { echo "[E] Cannot initialize Sephrasto with uv!" >&2; exit 1; }
#
cd "$SEPHRASTO_DIR"
SEPHRASTO_DIR=`pwd`
#
echo "[I] Clone Sephrasto ..." >&2
git clone https://github.com/Aeolitus/Sephrasto.git || { echo "[E] Cannot clone Sephrasto!" >&2; exit 1; }
#
echo "[I] Install Sephrasto python requirements..." >&2
uv add -r "Sephrasto/requirements.txt" || { echo "[E] Cannot install Sephrasto requirements!" >&2; exit 1; }
#
# Create the .desktop file.
cat > "$MYDIR/Sephrasto.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Sephrasto
Exec="$MYDIR/uv-run-sephrasto.sh"
Comment=Sephrasto
Icon=$MYDIR/Sephrasto/Sephrasto/src/Sephrasto/icon_large.png
Categories=Game;
Terminal=false
EOF
  echo "[I] Created 'Sephrasto.desktop' for you." >&2
  mkdir -p "$HOME/.local/share/applications"
  #cp "$MYDIR/Sephrasto.desktop" "$HOME/.local/share/applications"
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
