#!/bin/sh
# Lab 17 · runs INSIDE vm-orders (through az vm run-command).
# Prints exactly one status word first: ORDERS_OK, ORDERS_MISSING, ORDERS_CHANGED or NO_FINGERPRINT.
FILE=/data/orders.csv
SUM=/var/lib/nusa/orders.sha256

if [ ! -f "$SUM" ]; then
  echo "NO_FINGERPRINT: $SUM doesn't exist. Run setup.sh first."
elif [ ! -f "$FILE" ]; then
  echo "ORDERS_MISSING: $FILE doesn't exist."
elif sha256sum -c "$SUM" >/dev/null 2>&1; then
  echo "ORDERS_OK: $FILE matches the fingerprint taken when it was created ($(wc -l < "$FILE") lines)."
else
  echo "ORDERS_CHANGED: $FILE exists but its content differs from the original."
fi
