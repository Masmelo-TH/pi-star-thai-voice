#!/bin/bash
# ==========================================================================
#  Restore the ORIGINAL English voice files (undo install.sh)
#  Run ON the hotspot:   sudo bash restore.sh
# ==========================================================================
set -e
FILES="en_GB.indx en_GB.ambe TIME_en_GB.indx TIME_en_GB.ambe"
CANDIDATES="/usr/local/etc/ircddbgateway /usr/local/etc"

echo "=== Restore English voice pack ==="
if [ "$(id -u)" != "0" ]; then echo "!! Run with sudo:  sudo bash restore.sh"; exit 1; fi

REMOUNTED=0
if mount | grep -qE ' / .*\bro\b'; then
  mount -o remount,rw / && REMOUNTED=1
fi
cleanup() { [ "$REMOUNTED" = "1" ] && mount -o remount,ro / 2>/dev/null; }
trap cleanup EXIT

FOUND=0
for d in $CANDIDATES; do
  for f in $FILES; do
    if [ -f "$d/$f.orig" ]; then
      cp -a "$d/$f.orig" "$d/$f"
      echo "-- restored $d/$f"
      FOUND=1
    fi
  done
done

[ "$FOUND" = "1" ] || { echo "!! No .orig backups found — nothing to restore."; exit 1; }

systemctl restart ircddbgateway 2>/dev/null || true
systemctl restart timeserver   2>/dev/null || true
echo "=== English voice restored. ==="
