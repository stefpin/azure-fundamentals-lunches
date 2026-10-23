#!/usr/bin/env bash
# =============================================================================
# Lab 16 · Reference solution (Tasks 2, 3, 5 and 6, plus the fixed rule from
# "Break it and fix it" if you created it).
#
# Run setup.sh first, then:
#   ALERT_EMAIL="you@example.com" bash solution.sh
# Optional:
#   GENERATE_LOAD=1   also starts 15 minutes of CPU load (Task 4)
#   DEALLOCATE=1      also deallocates the VM at the end (Task 6)
#
# Safe to run again: every step checks first or updates in place.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 16)"
VM_NAME="vm-nusa-web"
AG_NAME="ag-nusa-oncall"
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -z "${ALERT_EMAIL:-}" ]]; then
  echo "Set ALERT_EMAIL first, for example:  export ALERT_EMAIL=\"you@example.com\""
  exit 1
fi

VM_ID="$(az vm show --resource-group "$RG" --name "$VM_NAME" --query id --output tsv)"
RG_ID="$(az group show --name "$RG" --query id --output tsv)"
SUB_ID="$(az account show --query id --output tsv)"

banner "Task 2 · Action group ${AG_NAME}"
az monitor action-group create \
  --resource-group "$RG" \
  --name "$AG_NAME" \
  --short-name nusaoncall \
  --action email oncall-email "$ALERT_EMAIL" usecommonalertschema \
  --output none
AG_ID="$(az monitor action-group show --resource-group "$RG" --name "$AG_NAME" --query id --output tsv)"
info "Action group ready."

banner "Task 3 · Metric alert alert-cpu-high"
az monitor metrics alert create \
  --resource-group "$RG" \
  --name alert-cpu-high \
  --scopes "$VM_ID" \
  --condition "avg Percentage CPU > 70" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action "$AG_ID" \
  --description "Storefront VM: average CPU above 70% for 5 minutes" \
  --output none
info "Metric alert ready."

if [[ "${GENERATE_LOAD:-0}" == "1" ]]; then
  banner "Task 4 · CPU load for 15 minutes"
  az vm run-command invoke \
    --resource-group "$RG" \
    --name "$VM_NAME" \
    --command-id RunShellScript \
    --scripts @"${LAB_DIR}/cpu-load.sh" \
    --parameters 15 \
    --query "value[0].message" --output tsv
fi

banner "Task 5 · Service Health alert (stored in ${RG}, watches the subscription)"
if az monitor activity-log alert show --resource-group "$RG" --name alert-service-health --output none 2>/dev/null; then
  info "alert-service-health already exists."
else
  az monitor activity-log alert create \
    --resource-group "$RG" \
    --name alert-service-health \
    --scope "/subscriptions/${SUB_ID}" \
    --condition category=ServiceHealth \
    --action-group "$AG_ID" \
    --description "Azure service issues, planned maintenance and advisories for this subscription" \
    --output none
  info "Service Health alert created."
fi

banner "Task 6 · Activity log alert alert-vm-deallocated"
if az monitor activity-log alert show --resource-group "$RG" --name alert-vm-deallocated --output none 2>/dev/null; then
  info "alert-vm-deallocated already exists."
else
  az monitor activity-log alert create \
    --resource-group "$RG" \
    --name alert-vm-deallocated \
    --scope "$RG_ID" \
    --condition "category=Administrative and operationName=Microsoft.Compute/virtualMachines/deallocate/action and status=Succeeded" \
    --action-group "$AG_ID" \
    --description "A VM in this resource group was deallocated" \
    --output none
  info "Activity log alert created."
fi

banner "Break it and fix it · alert-cpu-rizky"
if az monitor metrics alert show --resource-group "$RG" --name alert-cpu-rizky --output none 2>/dev/null; then
  info "Replacing Rizky's rule with a working one (Average over 5 minutes)..."
  az monitor metrics alert delete --resource-group "$RG" --name alert-cpu-rizky --output none
  az monitor metrics alert create \
    --resource-group "$RG" \
    --name alert-cpu-rizky \
    --scopes "$VM_ID" \
    --condition "avg Percentage CPU > 70" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 3 \
    --action "$AG_ID" \
    --description "Rizky's CPU alert, fixed: average over 5 minutes" \
    --output none
else
  info "alert-cpu-rizky not found: nothing to fix."
fi

if [[ "${DEALLOCATE:-0}" == "1" ]]; then
  banner "Task 6 · Deallocate the VM (the activity log alert should fire)"
  az vm deallocate --resource-group "$RG" --name "$VM_NAME" --output none
  info "VM deallocated. The alert email usually arrives within a few minutes (up to about 20)."
fi

banner "Done"
info "Run: bash verify.sh"
