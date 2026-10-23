#!/usr/bin/env bash
# =============================================================================
# Lab 23 · Reference solution — builds what the Challenge brief asks for.
#
#   bash solution.sh                   # scale set, load balancer test, autoscale, patch assessment (~12 min)
#   RUN_LOAD_TEST=1 bash solution.sh   # also generates CPU load and watches autoscale (+30 min)
#   RUN_SPOT=1 bash solution.sh        # also creates a Spot VM, simulates an eviction, then deletes it
#   SKIP_ASSESS=1 bash solution.sh     # skip the patch assessment
#
# Optional settings: INSTANCES / AS_MIN / AS_MAX (default 2 / 2 / 3),
# SPOT_SIZE (default Standard_D2as_v5 — Spot doesn't support B-series sizes).
# Runs setup.sh first if the starting point is missing. Safe to re-run.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
require_az

RG="$(rg_name 23)"
INSTANCES="${INSTANCES:-2}"
AS_MIN="${AS_MIN:-2}"
AS_MAX="${AS_MAX:-3}"
SPOT_SIZE="${SPOT_SIZE:-Standard_D2as_v5}"
VMSS="vmss-web"
AUTOSCALE="autoscale-web"

exists() { az "$@" --output none >/dev/null 2>&1; }
instances() { az_q vm list -g "$RG" --query "[?virtualMachineScaleSet].name"; }
instance_count() { az_q vm list -g "$RG" --query "length([?virtualMachineScaleSet])"; }

if ! exists network lb show -g "$RG" -n lb-nusa-web; then
  banner "Starting point not found — running setup.sh first"
  bash "${LAB_DIR}/setup.sh"
fi

banner "Task 2 · Flexible scale set ${VMSS} across zones 1, 2 and 3"
if exists vmss show -g "$RG" -n "$VMSS"; then
  info "Scale set ${VMSS} already exists — keeping it."
else
  info "Creating ${INSTANCES} instance(s) of ${VM_SIZE_SMALL} — about 3 to 5 minutes..."
  az vmss create \
    --resource-group "$RG" \
    --name "$VMSS" \
    --location "$LOCATION" \
    --orchestration-mode Flexible \
    --image "$VM_IMAGE" \
    --vm-sku "$VM_SIZE_SMALL" \
    --instance-count "$INSTANCES" \
    --zones 1 2 3 \
    --platform-fault-domain-count 1 \
    --vnet-name vnet-nusa-web \
    --subnet snet-web \
    --nsg nsg-web \
    --lb lb-nusa-web \
    --backend-pool-name bep-web \
    --custom-data "${AZL_COMMON_DIR}/cloud-init-web.yml" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --storage-sku StandardSSD_LRS \
    --upgrade-policy-mode Manual \
    --output none
fi
az vm list -g "$RG" --query "[?virtualMachineScaleSet].{name:name, zone:zones[0], size:hardwareProfile.vmSize}" -o table

banner "Task 3 · The website through the load balancer"
LB_IP="$(az_q network public-ip show -g "$RG" -n pip-lb-web --query ipAddress)"
http_ok() { [[ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://${LB_IP}/" || true)" == "200" ]]; }
info "Waiting for HTTP 200 from http://${LB_IP}/ (cloud-init needs a minute or two)..."
if wait_until "HTTP 200 from the load balancer" 420 http_ok; then
  for _ in 1 2 3 4 5 6; do
    curl -s --max-time 5 "http://${LB_IP}/" | grep -o 'Served by.*' | sed -e 's/<[^>]*>//g' || true
  done
fi

banner "Task 4 · Autoscale ${AUTOSCALE}: minimum ${AS_MIN}, maximum ${AS_MAX}, CPU rules"
if ! exists monitor autoscale show -g "$RG" -n "$AUTOSCALE"; then
  az monitor autoscale create -g "$RG" \
    --resource "$VMSS" --resource-type Microsoft.Compute/virtualMachineScaleSets \
    --name "$AUTOSCALE" --min-count "$AS_MIN" --max-count "$AS_MAX" --count "$AS_MIN" --output none
fi
if [[ "$(az_q monitor autoscale show -g "$RG" -n "$AUTOSCALE" --query "length(profiles[0].rules)")" == "0" ]]; then
  az monitor autoscale rule create -g "$RG" --autoscale-name "$AUTOSCALE" \
    --condition "Percentage CPU > 70 avg 5m" --scale out 1 --cooldown 5 --output none
  az monitor autoscale rule create -g "$RG" --autoscale-name "$AUTOSCALE" \
    --condition "Percentage CPU < 30 avg 5m" --scale in 1 --cooldown 5 --output none
fi
az monitor autoscale rule list -g "$RG" --autoscale-name "$AUTOSCALE" \
  --query "[].{metric:metricTrigger.metricName, operator:metricTrigger.operator, threshold:metricTrigger.threshold, window:metricTrigger.timeWindow, direction:scaleAction.direction, change:scaleAction.value, cooldown:scaleAction.cooldown}" \
  -o table

if [[ "${RUN_LOAD_TEST:-0}" == "1" ]]; then
  banner "Task 5 · CPU load for 15 minutes on every instance"
  for vm in $(instances); do
    az vm run-command invoke -g "$RG" -n "$vm" --command-id RunShellScript \
      --scripts @"${LAB_DIR}/load-cpu.sh" --parameters 900 --query "value[0].message" -o tsv
  done
  VMSS_ID="$(az_q vmss show -g "$RG" -n "$VMSS" --query id)"
  info "Watching for 30 minutes: scale-out during the load, scale-in after it stops."
  for _ in {1..30}; do
    cpu="$(az_q monitor metrics list --resource "$VMSS_ID" --metric "Percentage CPU" --interval PT1M \
      --aggregation Average --offset 1h --query "value[0].timeseries[0].data[?average] | [-1].average")"
    printf '   %s  average CPU: %5.1f%%  instances: %s\n' "$(date +%H:%M)" "${cpu:-0}" "$(instance_count)"
    sleep 60
  done
  az monitor activity-log list -g "$RG" --offset 1h \
    --query "[?category.value=='Autoscale'].{time:eventTimestamp, operation:operationName.localizedValue, status:status.localizedValue}" \
    -o table
fi

if [[ "${SKIP_ASSESS:-0}" != "1" ]]; then
  banner "Task 6 · Patch assessment with Azure Update Manager"
  FIRST_VM="$(az_q vm list -g "$RG" --query "[?virtualMachineScaleSet].name | [0]")"
  info "Assessing ${FIRST_VM} — about 2 to 5 minutes..."
  az vm assess-patches -g "$RG" -n "$FIRST_VM" \
    --query "{status:status, criticalAndSecurity:criticalAndSecurityPatchCount, other:otherPatchCount, rebootPending:rebootPending}" \
    -o table || note "The assessment failed — see Troubleshooting in the README."
fi

if [[ "${RUN_SPOT:-0}" == "1" ]]; then
  banner "Task 7 · Spot VM vm-spot-1 (${SPOT_SIZE}) and a simulated eviction"
  if az vm create \
      --resource-group "$RG" --name vm-spot-1 --location "$LOCATION" \
      --image "$VM_IMAGE" --size "$SPOT_SIZE" \
      --priority Spot --eviction-policy Deallocate --max-price -1 \
      --vnet-name vnet-nusa-web --subnet snet-web --nsg "" --public-ip-address "" \
      --os-disk-delete-option Delete --nic-delete-option Delete \
      --admin-username "$ADMIN_USER" --generate-ssh-keys --storage-sku StandardSSD_LRS --output none; then
    az vm show -g "$RG" -n vm-spot-1 \
      --query "{priority:priority, evictionPolicy:evictionPolicy, maxPrice:billingProfile.maxPrice}" -o table
    az vm simulate-eviction -g "$RG" -n vm-spot-1 --output none
    evicted() {
      [[ "$(az_q vm get-instance-view -g "$RG" -n vm-spot-1 \
        --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]")" == "VM deallocated" ]]
    }
    if wait_until "Spot VM evicted" 900 evicted; then
      info "vm-spot-1 was evicted and is now deallocated."
    fi
    az vm delete -g "$RG" -n vm-spot-1 --yes --output none
    info "vm-spot-1 deleted (its disk and NIC were deleted with it)."
  else
    note "Couldn't create the Spot VM (Spot quota or subscription offer). It isn't checked by verify.sh."
  fi
fi

banner "Done"
info "Load balancer: http://${LB_IP}/"
info "Now run: bash verify.sh"
