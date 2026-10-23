#!/usr/bin/env bash
# =============================================================================
# Lab 30 · traffic.sh — plays a busy Friday evening for N minutes (default 10)
#
#   - Shoppers: GET /, GET /products and five POST /checkout calls per round
#     against the storefront web app.
#   - Product images: every third round it uploads, lists and downloads a blob
#     in the product-images container, and asks for one that doesn't exist
#     (a 404 you'll find in StorageBlobLogs).
#
# Usage (run it in the background so you can keep working):
#   bash traffic.sh 20
#   nohup bash traffic.sh 25 > "$HOME/lab30-out/traffic.log" 2>&1 &
# Scratch files go to $HOME/lab30-out/traffic and are removed by cleanup.sh.
# =============================================================================
set -uo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
AZL_QUIET=1 source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

MINUTES="${1:-10}"
if ! [[ "$MINUTES" =~ ^[0-9]+$ ]] || (( MINUTES < 1 || MINUTES > 120 )); then
  echo "Usage: bash traffic.sh [minutes between 1 and 120]"
  exit 1
fi

HOST="$(az_q webapp show --resource-group "$RG" --name "$APP" --query defaultHostName)"
if [[ -z "$HOST" ]]; then
  echo "Web app ${APP} wasn't found in ${RG}. Run 'bash setup.sh' first."
  exit 1
fi
BASE="https://${HOST}"
SCRATCH="${OUT_DIR}/traffic"
mkdir -p "$SCRATCH"

checkouts=0; slow=0; failed=0; storage_ok=0; storage_err=0; round=0
hinted=0

storage_round() {
  local blob
  blob="img-$(date +%s)-${round}.txt"
  echo "Nusantara Retail product image ${round} (lab test file)" > "${SCRATCH}/${blob}"
  if az storage blob upload --account-name "$ST" --container-name "$CONTAINER" --name "$blob" \
       --file "${SCRATCH}/${blob}" --auth-mode login --overwrite --only-show-errors --output none 2>/dev/null \
     && az storage blob list --account-name "$ST" --container-name "$CONTAINER" --auth-mode login \
       --num-results 20 --only-show-errors --output none 2>/dev/null \
     && rm -f "${SCRATCH}/download.txt" \
     && az storage blob download --account-name "$ST" --container-name "$CONTAINER" --name "$blob" \
       --file "${SCRATCH}/download.txt" --auth-mode login --only-show-errors --output none 2>/dev/null; then
    storage_ok=$((storage_ok + 1))
  else
    storage_err=$((storage_err + 1))
    if (( hinted == 0 )); then
      note "A storage call failed. Right after setup.sh your new role assignment can take a few minutes to apply;"
      note "failed calls still show up in StorageBlobLogs, so keep going."
      hinted=1
    fi
  fi
  # Ask for an image that doesn't exist: expected to fail with BlobNotFound (404).
  az storage blob download --account-name "$ST" --container-name "$CONTAINER" --name "banner-1212-sale.jpg" \
    --file "${SCRATCH}/missing.jpg" --auth-mode login --only-show-errors --output none >/dev/null 2>&1 || true
  rm -f "${SCRATCH}/${blob}" "${SCRATCH}/missing.jpg"
}

banner "Friday evening traffic for ${MINUTES} minute(s) against ${BASE}"
end=$(( $(date +%s) + MINUTES * 60 ))
while (( $(date +%s) < end )); do
  round=$((round + 1))
  curl -s -o /dev/null --max-time 15 "${BASE}/" || true
  curl -s -o /dev/null --max-time 15 "${BASE}/products" || true
  for _ in 1 2 3 4 5; do
    result="$(curl -s -o /dev/null -w '%{http_code} %{time_total}' --max-time 20 -X POST "${BASE}/checkout" || true)"
    code="${result%% *}"
    seconds="${result##* }"
    checkouts=$((checkouts + 1))
    if [[ "$code" != "200" ]]; then
      failed=$((failed + 1))
    elif awk -v s="${seconds:-0}" 'BEGIN { exit !(s > 1.0) }'; then
      slow=$((slow + 1))
    fi
  done
  if (( round % 3 == 1 )); then
    storage_round
  fi
  info "$(date +%H:%M:%S) round ${round}: ${checkouts} checkouts, ${slow} slow (over 1 s), ${failed} failed · storage rounds ok/failed: ${storage_ok}/${storage_err}"
  sleep 5
done

banner "Done"
info "Checkouts: ${checkouts} · slow: ${slow} · failed: ${failed}"
info "Storage rounds: ${storage_ok} succeeded, ${storage_err} failed"
info "Telemetry reaches the workspace within a few minutes. Continue with the KQL exercises."
