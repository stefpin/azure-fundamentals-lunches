#!/usr/bin/env bash
# =============================================================================
# Lab 30 · Clean up — removes everything this lab created.
#   1. The diagnostic setting on the blob service (diagnostic settings can
#      outlive their resource and reattach to a new one with the same name).
#   2. Your Storage Blob Data Contributor role assignment on the storage account.
#   3. The Log Analytics workspace, deleted permanently (--force) instead of
#      waiting 14 days in the soft-deleted state.
#   4. Resource group rg-lunch30-<suffix> with everything else in it.
#   5. Local files in $HOME/lab30-out.
#
#   bash cleanup.sh
#   ASSUME_YES=1 bash cleanup.sh    # no question asked
# =============================================================================
set -uo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Lab 30 clean-up"
info "This permanently deletes workspace ${LAW} (with all collected logs) and resource group ${RG}."
if ! confirm "Delete everything from Lab 30?"; then
  info "Nothing deleted."
  exit 0
fi

ST_ID="$(az_q storage account show --resource-group "$RG" --name "$ST" --query id)"
if [[ -n "$ST_ID" ]]; then
  banner "Diagnostic settings on ${ST}"
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    az monitor diagnostic-settings delete --name "$name" --resource "${ST_ID}/blobServices/default" --output none \
      && info "Deleted diagnostic setting ${name}."
  done < <(az_q monitor diagnostic-settings list --resource "${ST_ID}/blobServices/default" --query "(value || @)[].name")

  banner "Role assignment on ${ST}"
  ME="$(my_object_id || true)"
  if [[ -n "$ME" ]] && az role assignment delete --assignee "$ME" --role "Storage Blob Data Contributor" \
       --scope "$ST_ID" --output none 2>/dev/null; then
    info "Removed your Storage Blob Data Contributor assignment."
  else
    info "No role assignment to remove."
  fi
fi

if az monitor log-analytics workspace show --resource-group "$RG" --workspace-name "$LAW" --output none 2>/dev/null; then
  banner "Workspace ${LAW}"
  az monitor log-analytics workspace delete --resource-group "$RG" --workspace-name "$LAW" \
    --force true --yes --output none \
    && info "Deleted ${LAW} permanently."
fi

banner "Resource group"
delete_lunch_rgs 30

banner "Local files"
rm -rf "$OUT_DIR"
info "Removed ${OUT_DIR}."

echo
info "Deletion continues in the background for a few minutes. Check with:"
info "  az group list --tag lunch=30 --query \"[].{name:name, state:properties.provisioningState}\" --output table"
