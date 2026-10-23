#!/usr/bin/env bash
# =============================================================================
# Lab 18 · cleanup — removes everything the lab created:
#   1. any locks in the resource group (stretch goal), so it can be deleted
#   2. the role assignments of the policy assignments' managed identities
#   3. the policy assignments on the resource group
#   4. the resource group itself (and everything in it, including remediation tasks)
#   bash cleanup.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az
source "$(dirname "$0")/lab-vars.sh"

banner "Lab 18 cleanup · ${RG}"

if az group show --name "$RG" --output none 2>/dev/null; then
  while IFS= read -r lock_id; do
    if [[ -n "$lock_id" ]]; then
      info "Removing lock ${lock_id##*/}..."
      az lock delete --ids "$lock_id" --output none || note "Could not remove lock ${lock_id}"
    fi
  done < <(az_q lock list --resource-group "$RG" --query "[].id")

  # Policy assignments that live directly on the resource group: name <TAB> identity principal id <TAB> scope
  while IFS=$'\t' read -r name pid scope; do
    if [[ -z "$name" || "${scope,,}" != "${RG_ID,,}" ]]; then
      continue
    fi
    if [[ -n "$pid" && "$pid" != "None" ]]; then
      while IFS= read -r ra_id; do
        if [[ -n "$ra_id" ]]; then
          info "Removing role assignment of ${name}'s managed identity..."
          az role assignment delete --ids "$ra_id" --output none || note "Could not remove role assignment ${ra_id}"
        fi
      done < <(az_q role assignment list --all --query "[?principalId=='${pid}'].id")
    fi
    info "Deleting policy assignment ${name}..."
    az policy assignment delete --name "$name" --scope "$RG_ID" --output none || note "Could not delete ${name}"
  done < <(az_q policy assignment list --resource-group "$RG" --query "[].[name, identity.principalId, scope]")
else
  info "Resource group ${RG} not found — nothing inside it to clean up."
fi

delete_lunch_rgs 18
info "Done. Deletion continues in the background for a few minutes."
info "Check with: az group list --tag lunch=18 --query \"[].name\" --output tsv"
