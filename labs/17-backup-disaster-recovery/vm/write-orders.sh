#!/bin/sh
# Lab 17 · runs INSIDE vm-orders (setup.sh sends it with az vm run-command).
# Writes Nusantara Retail's order export /data/orders.csv and stores its SHA-256
# fingerprint in /var/lib/nusa/orders.sha256 so a restore can be checked later.
# The content is generated deterministically. It never overwrites an existing file,
# and it never recreates a file that was lost after the fingerprint was taken:
# getting that file back is the point of the lab.
set -eu
FILE=/data/orders.csv
SUM=/var/lib/nusa/orders.sha256

if [ -f "$FILE" ]; then
  echo "ORDERS_EXISTS $(wc -l < "$FILE") lines in $FILE"
  exit 0
fi
if [ -f "$SUM" ]; then
  echo "ORDERS_MISSING: $FILE was deleted after it was created. Restore it from a backup (Task 7)."
  exit 0
fi

mkdir -p /data /var/lib/nusa
awk 'BEGIN {
  OFS = ","
  split("Jakarta Kemang|Bandung Dago|Surabaya Tunjungan|Medan Merdeka|Makassar Losari|Online storefront", store, "|")
  split("Kopi Gayo Arabica 250 g|Teh Melati 100 g|Kemeja Batik Parang|Keripik Tempe 200 g|Sambal Roa 150 g|Tas Rotan Lombok|Kopi Toraja Kalosi 250 g|Dodol Kopi Garut 250 g", item, "|")
  split("85000|32000|450000|18000|42000|275000|92000|30000", price, "|")
  print "order_id", "order_date", "store", "item", "qty", "total_idr"
  for (i = 1; i <= 50; i++) {
    s = (i * 7) % 6 + 1
    it = (i * 5) % 8 + 1
    q = (i * 3) % 4 + 1
    d = 19 + (i % 7)
    printf "NR-%05d,2026-10-%02d,%s,%s,%d,%d\n", 10000 + i, d, store[s], item[it], q, q * price[it]
  }
}' > "$FILE"
sha256sum "$FILE" > "$SUM"
sync || true
echo "ORDERS_WRITTEN $(wc -l < "$FILE") lines in $FILE"
cat "$SUM"
