#!/usr/bin/env bash
# =============================================================================
# Lab 20 · cleanup.sh — deletes every deployment stack in the lab resource group together with
# the resources it manages (its deny assignment would otherwise block the deletes), then the
# resource group itself.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 20)"

banner "Deployment stacks in ${RG}"
if [[ "$(az_q group exists --name "$RG")" == "true" ]]; then
  stacks="$(az_q stack group list --resource-group "$RG" --query "[].name")"
  if [[ -z "$stacks" ]]; then
    info "No deployment stacks found (Task 7 already deleted it, or it was never created)."
  fi
  while IFS= read -r stack; do
    [[ -z "$stack" ]] && continue
    info "Deleting stack ${stack} and the resources it manages (takes a few minutes)..."
    az stack group delete --name "$stack" --resource-group "$RG" \
      --action-on-unmanage deleteResources --yes --output none \
      || note "Could not delete stack ${stack}. Delete it in the portal (resource group › Deployment stacks), then run cleanup.sh again."
  done <<< "$stacks"
else
  info "Resource group ${RG} not found, so there are no stacks in it."
fi

banner "Resource groups for lunch 20"
delete_lunch_rgs 20
info "The Log Analytics workspace stays soft-deleted (recoverable) for 14 days; that costs nothing."
info "Your local main.bicep and main.json in this folder are not Azure resources; keep or delete them as you like."
