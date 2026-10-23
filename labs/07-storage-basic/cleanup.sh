#!/usr/bin/env bash
# =============================================================================
# Lab 07 · Store product images and invoices — removes everything the lab created
#   bash cleanup.sh            (asks for confirmation)
#   ASSUME_YES=1 bash cleanup.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
RG="$(rg_name 07)"
ACCOUNT="${ACCOUNT:-stnusa07${SUFFIX}}"

banner "Lab 07 cleanup"
info "This deletes every resource group tagged lunch=07 (for example ${RG}) and the local work/ folder."
if ! confirm "Continue?"; then
  info "Nothing deleted."
  exit 0
fi

banner "Role assignments on the storage account"
# They are deleted together with the account; removing them first keeps your role list tidy.
ACCOUNT_ID="$(az_q storage account show --name "$ACCOUNT" --resource-group "$RG" --query id)"
if [[ -n "$ACCOUNT_ID" ]]; then
  ids="$(az_q role assignment list --scope "$ACCOUNT_ID" --query "[?scope=='${ACCOUNT_ID}'].id")"
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    az role assignment delete --ids "$id" --output none 2>/dev/null || note "Could not delete role assignment ${id}"
  done <<< "$ids"
  info "Role assignments scoped to ${ACCOUNT} removed."
else
  info "Storage account ${ACCOUNT} not found — nothing to remove here."
fi

banner "Resource groups"
delete_lunch_rgs 07

banner "Local files"
rm -rf "${LAB_DIR}/work"
info "Removed ${LAB_DIR}/work."
info "In your own shell, also run: unset AZCOPY_AUTO_LOGIN_TYPE AZCOPY_TENANT_ID"

banner "Done"
info "Resource group deletion continues in the background for a few minutes."
