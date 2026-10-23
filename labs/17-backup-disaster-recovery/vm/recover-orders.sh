#!/bin/sh
# Lab 17 · runs INSIDE vm-orders (through az vm run-command) after you attached the
# restored OS disk as a data disk (Task 7).
#   1. finds the restored root file system: same label as the live one, but not mounted
#   2. mounts it read-only (ro,noload: nothing is written to the restored disk)
#   3. copies orders.csv back and checks it against the fingerprint from setup
#   4. unmounts, so the disk can be detached
# Prints RESTORE_OK or RESTORE_FAILED: <reason>.
set -u
FILE=/data/orders.csv
SUM=/var/lib/nusa/orders.sha256
MNT=/mnt/restore

ROOT_ID="$(mountpoint -d / 2>/dev/null || echo none)"
DEV=""
tries=0
while [ "$tries" -lt 12 ]; do
  udevadm settle 2>/dev/null || true
  for d in $(blkid -c /dev/null -t LABEL=cloudimg-rootfs -o device 2>/dev/null); do
    [ "$(lsblk -dno MAJ:MIN "$d" 2>/dev/null | tr -d ' ')" = "$ROOT_ID" ] && continue
    if ! findmnt -n -S "$d" >/dev/null 2>&1; then
      DEV="$d"
    fi
  done
  [ -n "$DEV" ] && break
  tries=$((tries + 1))
  sleep 5
done

if [ -z "$DEV" ]; then
  echo "RESTORE_FAILED: no unmounted disk with a restored root file system was found. Is the restored disk attached? (lsblk below)"
  lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT
  exit 1
fi
echo "Restored root file system found on $DEV"

mkdir -p "$MNT"
if ! mount -o ro,noload "$DEV" "$MNT"; then
  echo "RESTORE_FAILED: could not mount $DEV"
  exit 1
fi

if [ ! -f "$MNT$FILE" ]; then
  echo "RESTORE_FAILED: the recovery point has no $FILE. Was it taken before the file existed?"
  umount "$MNT"
  exit 1
fi

mkdir -p /data
cp -p "$MNT$FILE" "$FILE"
umount "$MNT"
echo "Copied $FILE back from the recovery point and unmounted $DEV"

if sha256sum -c "$SUM" >/dev/null 2>&1; then
  echo "RESTORE_OK: $FILE matches the fingerprint taken when it was created ($(wc -l < "$FILE") lines)."
else
  echo "RESTORE_FAILED: $FILE was copied back but doesn't match the original fingerprint."
  exit 1
fi
