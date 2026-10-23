#!/usr/bin/env bash
# =============================================================================
# Lab 06 · Verify — checks the Challenge brief. Read-only: it changes nothing.
#   bash verify.sh
# The data-disk mount check uses Run Command, so the script takes about a minute.
# =============================================================================
set -uo pipefail
AZL_QUIET=1 source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 06)"
VM="${VM_NAME:-vm-web-1}"

banner "Lab 06 · checking ${VM} in ${RG}"

if ! az group show -n "$RG" --output none 2>/dev/null; then
  fail "Resource group ${RG} exists (create it with: ensure_rg \"\$RG\" 06)"
  summary
  exit 1
fi
pass "Resource group ${RG} exists"
check_eq "Resource group is tagged lunch=06 (so cleanup.sh can find it)" "06" "$(az_q group show -n "$RG" --query tags.lunch)"

if ! az vm show -g "$RG" -n "$VM" --output none 2>/dev/null; then
  fail "VM ${VM} exists (Task 1)"
  summary
  exit 1
fi
pass "VM ${VM} exists"

POWER="$(az_q vm show -d -g "$RG" -n "$VM" --query powerState)"
check_eq "VM is running (if not: az vm start -g ${RG} -n ${VM})" "VM running" "$POWER"
check_contains "VM runs an Ubuntu image (Task 1)" "ubuntu" "$(az_q vm show -g "$RG" -n "$VM" --query storageProfile.imageReference.offer)"
check_eq "Password sign-in is disabled — SSH keys only (Task 1)" "true" \
  "$(az_q vm show -g "$RG" -n "$VM" --query osProfile.linuxConfiguration.disablePasswordAuthentication)"

# --- Network: public IP and NSG rules -------------------------------------------
NIC_ID="$(az_q vm show -g "$RG" -n "$VM" --query 'networkProfile.networkInterfaces[0].id')"
PIP_ID=""
NSG_IDS=()
if [[ -n "$NIC_ID" ]]; then
  PIP_ID="$(az_q network nic show --ids "$NIC_ID" --query 'ipConfigurations[0].publicIPAddress.id')"
  nic_nsg="$(az_q network nic show --ids "$NIC_ID" --query 'networkSecurityGroup.id')"
  subnet_id="$(az_q network nic show --ids "$NIC_ID" --query 'ipConfigurations[0].subnet.id')"
  subnet_nsg=""
  [[ -n "$subnet_id" ]] && subnet_nsg="$(az_q network vnet subnet show --ids "$subnet_id" --query 'networkSecurityGroup.id')"
  [[ -n "$nic_nsg" ]] && NSG_IDS+=("$nic_nsg")
  [[ -n "$subnet_nsg" ]] && NSG_IDS+=("$subnet_nsg")
fi

IP=""
if [[ -n "$PIP_ID" ]]; then
  check_eq "VM has a Standard SKU public IP (Task 1)" "Standard" "$(az_q network public-ip show --ids "$PIP_ID" --query sku.name)"
  IP="$(az_q network public-ip show --ids "$PIP_ID" --query ipAddress)"
else
  fail "VM has a public IP address (Task 1)"
fi

if (( ${#NSG_IDS[@]} == 0 )); then
  fail "An NSG is associated with the VM's NIC or subnet (Task 1)"
else
  allow80_everywhere=1
  for nsg in "${NSG_IDS[@]}"; do
    n="$(az_q network nsg show --ids "$nsg" --query \
      "length(securityRules[?direction=='Inbound' && access=='Allow' && (protocol=='Tcp' || protocol=='*') && (destinationPortRange=='80' || destinationPortRange=='*' || contains(destinationPortRanges || \`[]\`, '80'))])")"
    if ! [[ "$n" =~ ^[0-9]+$ ]] || (( n < 1 )); then
      allow80_everywhere=0
      info "No inbound allow rule for TCP 80 in NSG ${nsg##*/}"
    fi
  done
  if (( allow80_everywhere == 1 )); then
    pass "Every NSG on the VM's path allows inbound TCP 80 (Task 4)"
  else
    fail "Every NSG on the VM's path allows inbound TCP 80 (Task 4 — az vm open-port --port 80)"
  fi
fi

# --- Data disk ------------------------------------------------------------------
DISKS="$(az_q vm show -g "$RG" -n "$VM" --query 'length(storageProfile.dataDisks)')"
check_ge "At least one data disk is attached (Task 5)" 1 "$DISKS"

if [[ "$POWER" == "VM running" ]] && [[ "${DISKS:-0}" =~ ^[0-9]+$ ]] && (( DISKS >= 1 )); then
  info "Asking the VM whether /datadrive is mounted (Run Command, about 30 seconds)..."
  MOUNT_OUT="$(az_q vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript \
    --scripts "findmnt -n -o SOURCE /datadrive || echo NOT-MOUNTED" \
    --query 'value[0].message')"
  if [[ "$MOUNT_OUT" == *"/dev/"* && "$MOUNT_OUT" != *"NOT-MOUNTED"* ]]; then
    pass "The data disk is mounted at /datadrive (Task 5)"
  else
    fail "The data disk is mounted at /datadrive (Task 5 — run mount-data-disk.sh with Run Command)"
  fi
else
  note "Skipped the /datadrive mount check (the VM must be running and have a data disk)."
fi

# --- Auto-shutdown schedule -----------------------------------------------------
VM_ID="$(az_q vm show -g "$RG" -n "$VM" --query id)"
SCHEDULE_OK=0
while IFS= read -r sid; do
  [[ -z "$sid" ]] && continue
  target="$(az_q resource show --ids "$sid" --query properties.targetResourceId)"
  status="$(az_q resource show --ids "$sid" --query properties.status)"
  if [[ "${target,,}" == "${VM_ID,,}" && "${status,,}" == "enabled" ]]; then
    SCHEDULE_OK=1
    info "Auto-shutdown: $(az_q resource show --ids "$sid" --query properties.dailyRecurrence.time) ($(az_q resource show --ids "$sid" --query properties.timeZoneId))"
  fi
done < <(az_q resource list -g "$RG" --resource-type Microsoft.DevTestLab/schedules --query '[].id')
if (( SCHEDULE_OK == 1 )); then
  pass "An enabled daily auto-shutdown schedule targets the VM (Task 7)"
else
  fail "An enabled daily auto-shutdown schedule targets the VM (Task 7 — az vm auto-shutdown)"
fi

# --- The website ----------------------------------------------------------------
if [[ -n "$IP" ]]; then
  CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://${IP}/" || true)"
  check_eq "http://${IP}/ answers HTTP 200 (Tasks 3–4)" "200" "$CODE"
  BODY="$(curl -s --max-time 10 "http://${IP}/" || true)"
  check_contains "The page contains 'Nusantara Retail' (Task 3)" "Nusantara Retail" "$BODY"
else
  fail "The website answers HTTP 200 (no public IP found)"
fi

summary
