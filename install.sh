#!/bin/bash
# ==========================================================================
#  Thai voice pack installer for Pi-Star / ircDDBGateway (D-Star)
#  Run ON the hotspot:   sudo bash install.sh
#  Reverts with:         sudo bash restore.sh
# ==========================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/voices"
# Only the MAIN voice pack (link/reflector announcements). The TIME announcements are left
# untouched (they stay in the node's original English) — Thai 12h/AM-PM ordering is unnatural.
FILES="en_GB.indx en_GB.ambe"

# Candidate install dirs (install into every one that already has en_GB.indx)
CANDIDATES="/usr/local/etc/ircddbgateway /usr/local/etc"

echo "=== Thai D-Star voice pack installer ==="

if [ "$(id -u)" != "0" ]; then
  echo "!! Please run with sudo:  sudo bash install.sh"; exit 1
fi

for f in $FILES; do
  [ -f "$SRC/$f" ] || { echo "!! Missing source file: $SRC/$f"; exit 1; }
done

# Pi-Star roots are usually mounted read-only. Remount rw if needed, restore on exit.
REMOUNTED=0
if mount | grep -qE ' / .*\bro\b'; then
  echo "-- root is read-only, remounting rw"
  mount -o remount,rw / && REMOUNTED=1
fi
cleanup() { [ "$REMOUNTED" = "1" ] && mount -o remount,ro / 2>/dev/null && echo "-- remounted root read-only"; }
trap cleanup EXIT

INSTALLED=0
for d in $CANDIDATES; do
  [ -f "$d/en_GB.indx" ] || continue          # only touch dirs that already hold the pack
  echo "-- installing into $d"
  for f in $FILES; do
    if [ -f "$d/$f" ] && [ ! -f "$d/$f.orig" ]; then
      cp -a "$d/$f" "$d/$f.orig"               # one-time backup of the English original
      echo "   backed up $f -> $f.orig"
    fi
    cp "$SRC/$f" "$d/$f"
    echo "   installed $f"
  done
  INSTALLED=1
done

if [ "$INSTALLED" = "0" ]; then
  echo "!! Could not find an ircDDBGateway voice dir (no en_GB.indx under $CANDIDATES)."
  echo "   Is this an ircDDBGateway / Pi-Star host with D-Star set up?"; exit 1
fi

# The pack lives in the 'en_GB' (English) slot, so ircDDBGateway must be set to language=0.
if [ -f /etc/ircddbgateway ]; then
  LANG_LINE="$(grep -E '^language=' /etc/ircddbgateway | head -1)"
  if [ "$LANG_LINE" != "language=0" ]; then
    echo "!! NOTE: /etc/ircddbgateway has '$LANG_LINE' (Thai pack needs language=0 = en_GB)."
    echo "   Set it in the Pi-Star web config (Language: English_(UK)) or edit that line to language=0."
  fi
fi

echo "-- restarting ircddbgateway"
systemctl restart ircddbgateway 2>/dev/null && echo "   ircddbgateway restarted"

echo ""
echo "=== DONE. Link a D-Star reflector to hear the Thai announcement. ==="
echo "    To revert to English:  sudo bash restore.sh"
