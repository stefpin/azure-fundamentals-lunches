#!/usr/bin/env bash
# =============================================================================
# Lab 21 · cleanup.sh — removes everything the capstone created:
#   deployment stacks (stretch goal), the budget, the policy assignment, your
#   Key Vault role assignment, the Key Vault itself (deleted AND purged, so the
#   name is free again), and finally the resource group with everything in it.
#
#     bash cleanup.sh            (asks first; ASSUME_YES=1 skips the question)
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Lab 21 cleanup"
info "This deletes resource group ${RG} and everything in it, the budget ${BUDGET},"
info "the policy assignment, and purges Key Vault ${KV}. There is no undo."
if ! confirm "Delete the Lab 21 platform now?"; then
  info "Nothing deleted."
  exit 0
fi

if az group show --name "$RG" --output none 2>/dev/null; then
  # 1. Deployment stacks first (only if you tried the stretch goal): their deny
  #    settings would otherwise block deleting the resources they manage.
  for stack in $(az stack group list --resource-group "$RG" --query "[].name" --output tsv 2>/dev/null); do
    info "Deleting deployment stack ${stack} and the resources it manages..."
    az stack group delete --name "$stack" --resource-group "$RG" \
      --action-on-unmanage deleteAll --yes --output none || note "Could not delete stack ${stack}; continuing."
  done

  # 2. Budgets scoped to the resource group (Task 7).
  for budget in $(az consumption budget list --resource-group "$RG" --query "[].name" --output tsv 2>/dev/null); do
    info "Deleting budget ${budget}..."
    az consumption budget delete --budget-name "$budget" --resource-group "$RG" --output none \
      || note "Could not delete budget ${budget}; delete it in the portal (Cost Management > Budgets)."
  done

  # 3. Policy assignments at the resource group scope.
  for assignment in $(az policy assignment list --resource-group "$RG" --query "[].name" --output tsv 2>/dev/null); do
    info "Deleting policy assignment ${assignment}..."
    az policy assignment delete --name "$assignment" --resource-group "$RG" --output none \
      || note "Could not delete policy assignment ${assignment}; continuing."
  done

  # 4. Role assignments on the Key Vault, then the vault itself.
  kv_id="$(az_q keyvault show --name "$KV" --resource-group "$RG" --query id)"
  if [[ -n "$kv_id" ]]; then
    for ra in $(az role assignment list --scope "$kv_id" --query "[].id" --output tsv 2>/dev/null); do
      info "Deleting role assignment on ${KV}..."
      az role assignment delete --ids "$ra" --output none || note "Could not delete role assignment ${ra}."
    done
    info "Deleting Key Vault ${KV} (it moves to the soft-deleted state)..."
    az keyvault delete --name "$KV" --resource-group "$RG" --output none
  fi
else
  info "Resource group ${RG} not found. Checking for leftovers outside it..."
fi

# 5. Purge the soft-deleted vault so the name can be reused at once.
deleted_location="$(az_q keyvault list-deleted --query "[?name=='${KV}'].properties.location | [0]")"
if [[ -n "$deleted_location" ]]; then
  info "Purging soft-deleted Key Vault ${KV} (can take a minute or two)..."
  az keyvault purge --name "$KV" --location "$deleted_location" --output none \
    || note "Purge failed. Retry later: az keyvault purge --name ${KV} --location ${deleted_location}"
fi

# 6. The resource group and everything still in it.
delete_lunch_rgs 21

echo
info "Deletion continues in the background for a few minutes. Check with:"
info "  az group list --tag lunch=21 --output table"
info "Your SSH key in ~/.ssh is untouched (it is not an Azure resource)."
