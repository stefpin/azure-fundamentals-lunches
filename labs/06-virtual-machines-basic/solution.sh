#!/usr/bin/env bash
# =============================================================================
# Lab 06 · Reference solution — builds the whole lab without SSH (it uses Run
# Command for everything that happens inside the VM).
#
#   bash solution.sh             # full run, about 15 minutes
#   QUICK=1 bash solution.sh     # skip the resize and stop/deallocate demos
#
# Optional settings: NEW_SIZE (resize target, default Standard_B2als_v2),
# SHUTDOWN_UTC (auto-shutdown time as hhmm in UTC, default three hours from now).
# Safe to re-run: every step checks what already exists.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
require_az

RG="$(rg_name 06)"
VM="vm-web-1"
NEW_SIZE="${NEW_SIZE:-Standard_B2als_v2}"
SHUTDOWN_UTC="${SHUTDOWN_UTC:-$(date -u -d '+3 hours' +%H00)}"

http_code() { curl -s -o /dev/null -w '%{http_code}' --max-time 8 "http://$1/" || true; }
port80_rules() {
  az network nsg rule list -g "$RG" --nsg-name nsg-web \
    --query "length([?direction=='Inbound' && access=='Allow' && destinationPortRange=='80'])" -o tsv 2>/dev/null || echo 0
}

banner "Task 1 · Create the VM"
ensure_rg "$RG" 06
if az vm show -g "$RG" -n "$VM" --output none 2>/dev/null; then
  info "VM ${VM} already exists — skipping create."
else
  info "Creating ${VM} (${VM_SIZE}, ${VM_IMAGE}) — about two minutes..."
  az vm create \
    --resource-group "$RG" \
    --name "$VM" \
    --location "$LOCATION" \
    --image "$VM_IMAGE" \
    --size "$VM_SIZE" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --vnet-name vnet-nusa-web --vnet-address-prefix 10.20.0.0/16 \
    --subnet snet-web --subnet-address-prefix 10.20.1.0/24 \
    --nsg nsg-web \
    --public-ip-address pip-web-1 --public-ip-sku Standard \
    --os-disk-name osdisk-web-1 --storage-sku StandardSSD_LRS \
    --output none
fi
if [[ "$(az vm show -d -g "$RG" -n "$VM" --query powerState -o tsv)" != "VM running" ]]; then
  info "Starting ${VM}..."
  az vm start -g "$RG" -n "$VM" --output none
fi
IP="$(az vm show -d -g "$RG" -n "$VM" --query publicIps -o tsv)"
info "Public IP: ${IP}"
az resource list -g "$RG" --query "[].{type:type, name:name}" -o table

banner "Task 3 · Install nginx and publish the page (Run Command)"
PAGE_B64="$(base64 -w0 "${LAB_DIR}/app/index.html")"
az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript --query "value[0].message" -o tsv --scripts "
cloud-init status --wait >/dev/null 2>&1 || true
export DEBIAN_FRONTEND=noninteractive
if ! command -v nginx >/dev/null 2>&1; then
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    apt-get update -q && apt-get install -y -q nginx && break
    echo 'apt is busy or unreachable — retrying in 20 seconds...'
    sleep 20
  done
fi
echo '${PAGE_B64}' | base64 -d > /var/www/html/index.html
systemctl enable --now nginx
curl -s localhost | grep -o '<title>.*</title>'
"

banner "Task 4 · Open port 80"
if [[ "$(port80_rules)" -ge 1 ]]; then
  info "An inbound allow rule for port 80 already exists."
else
  az vm open-port -g "$RG" -n "$VM" --port 80 --priority 900 --output none
fi
az network nsg rule list -g "$RG" --nsg-name nsg-web \
  --query "[].{name:name, priority:priority, port:destinationPortRange, access:access}" -o table
wait_until "HTTP 200 from http://${IP}/" 180 bash -c "[[ \"\$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://${IP}/)\" == 200 ]]" \
  && info "http://${IP}/ answers 200."

banner "Task 5 · Add and mount a data disk"
if [[ "$(az vm show -g "$RG" -n "$VM" --query 'length(storageProfile.dataDisks[?lun==`0`])' -o tsv)" == "0" ]]; then
  az vm disk attach -g "$RG" --vm-name "$VM" \
    --name disk-web-1-data --new --size-gb 8 --sku StandardSSD_LRS --lun 0 --output none
else
  info "A data disk is already attached at LUN 0."
fi
az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript \
  --scripts @"${LAB_DIR}/mount-data-disk.sh" --query "value[0].message" -o tsv

if [[ -z "${QUICK:-}" ]]; then
  banner "Task 6 · Resize the VM (and back)"
  CURRENT="$(az vm show -g "$RG" -n "$VM" --query hardwareProfile.vmSize -o tsv)"
  if [[ "${CURRENT,,}" == "${NEW_SIZE,,}" ]]; then NEW_SIZE="Standard_B2as_v2"; fi
  if az vm list-vm-resize-options -g "$RG" -n "$VM" --query "[].name" -o tsv | grep -qix "$NEW_SIZE"; then
    info "Resizing ${CURRENT} -> ${NEW_SIZE} (the VM restarts)..."
    az vm resize -g "$RG" -n "$VM" --size "$NEW_SIZE" --output none
    info "Now $(az vm show -g "$RG" -n "$VM" --query hardwareProfile.vmSize -o tsv); HTTP $(http_code "$IP"). Resizing back to ${CURRENT}..."
    az vm resize -g "$RG" -n "$VM" --size "$CURRENT" --output none
  else
    note "${NEW_SIZE} is not offered on this VM's hardware cluster — skipping the resize demo."
  fi
fi

banner "Task 7 · Schedule auto-shutdown at ${SHUTDOWN_UTC} UTC"
az vm auto-shutdown -g "$RG" -n "$VM" --time "$SHUTDOWN_UTC" --output none
SCHED="$(az resource list -g "$RG" --resource-type Microsoft.DevTestLab/schedules --query "[0].name" -o tsv)"
az resource show -g "$RG" --resource-type Microsoft.DevTestLab/schedules -n "$SCHED" \
  --query "{name:name, status:properties.status, time:properties.dailyRecurrence.time, timeZone:properties.timeZoneId}" -o table

if [[ -z "${QUICK:-}" ]]; then
  banner "Task 8 · Stopped versus deallocated"
  az vm stop -g "$RG" -n "$VM" --output none
  info "After az vm stop:       $(az vm show -d -g "$RG" -n "$VM" --query powerState -o tsv)  (compute still billed)"
  az vm deallocate -g "$RG" -n "$VM" --output none
  info "After az vm deallocate: $(az vm show -d -g "$RG" -n "$VM" --query powerState -o tsv)  (compute not billed)"
  info "Public IP while deallocated: $(az vm show -d -g "$RG" -n "$VM" --query publicIps -o tsv)"
  az vm start -g "$RG" -n "$VM" --output none
  info "After az vm start:      $(az vm show -d -g "$RG" -n "$VM" --query powerState -o tsv)"
fi

wait_until "HTTP 200 after the restarts" 180 bash -c "[[ \"\$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://${IP}/)\" == 200 ]]" || true
banner "Done"
info "Shop: http://${IP}/  (HTTP $(http_code "$IP"))"
info "Next: bash verify.sh — and bash cleanup.sh when you have finished."
