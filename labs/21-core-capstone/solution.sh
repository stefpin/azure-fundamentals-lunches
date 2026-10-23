#!/usr/bin/env bash
# =============================================================================
# Lab 21 · solution.sh — the reference solution, end to end and unattended:
#   Task 2  deploy the platform (deploy.sh without the question)
#   Task 4  zone-failure drill: deallocate vm-web-1 and count successful requests
#   Task 7  create the budget with the (preview) CLI instead of the portal
#   then    run verify.sh
#
#     bash solution.sh
#
# The guided tasks teach more; use this to check your understanding or for CI.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Task 2 · Deploy the platform"
ASSUME_YES=1 bash "${LAB_DIR}/deploy.sh"
IP="$(lb_ip)"

banner "Task 4 · Lose zone 1, keep the shop open"
info "Deallocating ${VM1} (availability zone 1) in the background..."
az vm deallocate --resource-group "$RG" --name "$VM1" --no-wait
ok=0
total=0
for _ in {1..45}; do
  total=$((total + 1))
  if curl -fs --max-time 3 "http://${IP}/" > /dev/null; then ok=$((ok + 1)); fi
  sleep 2
done
info "The storefront answered ${ok} of ${total} requests while zone 1 went down."
az vm wait --resource-group "$RG" --name "$VM1" --timeout 900 \
  --custom "instanceView.statuses[?code=='PowerState/deallocated']" || note "${VM1} is not deallocated yet."
served="$(curl -s --max-time 5 "http://${IP}/" | grep -oE 'vm-web-[0-9]+' | head -n1 || true)"
info "With zone 1 down, the answer came from: ${served:-nobody}"
info "Starting ${VM1} again..."
az vm start --resource-group "$RG" --name "$VM1" --output none

# both_answer  -> succeeds when 20 requests were served by both web servers
both_answer() {
  local seen="" _
  for _ in {1..20}; do
    seen="${seen} $(curl -s --max-time 3 "http://${IP}/" | grep -oE 'vm-web-[0-9]+' || true)"
  done
  [[ "$seen" == *vm-web-1* && "$seen" == *vm-web-2* ]]
}
wait_until "both web servers answer" 300 both_answer || note "${VM1} is not back in rotation yet."

banner "Task 7 · Budget on the resource group"
if [[ -z "$(az consumption budget list --resource-group "$RG" --query "[?name=='${BUDGET}'].name" --output tsv 2>/dev/null)" ]]; then
  # The portal path in Task 7 also adds the 50/80/100% e-mail alerts; this CLI command creates the budget only.
  az consumption budget create --budget-name "$BUDGET" --resource-group "$RG" \
    --amount "${BUDGET_AMOUNT:-10}" --category cost --time-grain monthly \
    --start-date "$(date -u +%Y-%m-01)" --end-date "$(date -u -d '+1 year' +%Y-%m-01)" --output none \
    || note "Budget creation failed (preview command or unsupported offer). Create it in the portal (Task 7)."
else
  info "Budget ${BUDGET} already exists."
fi

banner "Verify"
bash "${LAB_DIR}/verify.sh"
