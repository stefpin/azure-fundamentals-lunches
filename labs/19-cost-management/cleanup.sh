#!/usr/bin/env bash
# =============================================================================
# Lab 19 · cleanup.sh — deletes every budget on the lab resource group, then the
# resource group itself (with any waste that is still in it).
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 19)"
API="api-version=2019-10-01"

banner "Budgets on ${RG}"
if [[ "$(az_q group exists --name "$RG")" == "true" ]]; then
  budgets="$(az_q consumption budget list --resource-group "$RG" --query "[].name")"
  if [[ -z "$budgets" ]]; then
    budgets="$(az_q rest --method get \
      --url "/subscriptions/{subscriptionId}/resourceGroups/${RG}/providers/Microsoft.Consumption/budgets?${API}" \
      --query "value[].name")"
  fi
  if [[ -z "$budgets" ]]; then
    info "No budgets found on ${RG}."
  fi
  while IFS= read -r budget; do
    [[ -z "$budget" ]] && continue
    info "Deleting budget ${budget}..."
    az consumption budget delete-with-rg --resource-group "$RG" --budget-name "$budget" --output none 2>/dev/null \
      || az rest --method delete --output none \
           --url "/subscriptions/{subscriptionId}/resourceGroups/${RG}/providers/Microsoft.Consumption/budgets/${budget}?${API}" \
      || note "Could not delete budget ${budget}. Delete it in the portal: resource group › Budgets."
  done <<< "$budgets"
else
  info "Resource group ${RG} not found, so there are no budgets on it."
fi

banner "Resource groups for lunch 19"
delete_lunch_rgs 19
info "Done. Deleted resources disappear from Resource Graph within minutes; their last costs still show up in"
info "cost analysis for a day or so, because cost data arrives late."
