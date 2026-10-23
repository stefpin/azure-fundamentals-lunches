#!/usr/bin/env bash
# =============================================================================
# Lab 24 · Ransomware-proof invoices — removes everything the lab created
#   bash cleanup.sh            (asks for confirmation)
#   ASSUME_YES=1 bash cleanup.sh
# Uses only management (control-plane) calls, so it works with public network
# access Disabled.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
RG="$(rg_name 24)"
LOCKED=0

banner "Lab 24 cleanup"
info "This deletes every resource group tagged lunch=24 (for example ${RG}): the storage account,"
info "private endpoint, private DNS zone, VM, NAT gateway and virtual network — and the local work/ folder."
if ! confirm "Continue?"; then
  info "Nothing deleted."
  exit 0
fi

banner "Immutability policies and role assignments"
for acct in $(az_q storage account list --resource-group "$RG" --query "[].name"); do
  for c in $(az_q storage container-rm list --storage-account "$acct" --resource-group "$RG" \
               --query "[?hasImmutabilityPolicy].name"); do
    state="$(az_q storage container-rm show --storage-account "$acct" --resource-group "$RG" --name "$c" \
      --query immutabilityPolicy.state)"
    if [[ "$state" == "Locked" ]]; then
      note "${acct}/${c} has a LOCKED retention policy. It can't be removed, so the account can't be deleted yet."
      LOCKED=1
      continue
    fi
    etag="$(az_q storage container immutability-policy show --account-name "$acct" --resource-group "$RG" \
      --container-name "$c" --query etag)"
    if az storage container immutability-policy delete --account-name "$acct" --resource-group "$RG" \
         --container-name "$c" --if-match "$etag" --output none 2>/dev/null; then
      info "Removed the unlocked retention policy on ${acct}/${c}."
    else
      note "Could not remove the retention policy on ${acct}/${c}; the resource group deletion may still work."
    fi
  done
  # Role assignments go away with the account; removing them first keeps your role list tidy.
  acct_id="$(az_q storage account show --name "$acct" --resource-group "$RG" --query id)"
  for id in $(az_q role assignment list --scope "$acct_id" --query "[?scope=='${acct_id}'].id"); do
    az role assignment delete --ids "$id" --output none 2>/dev/null || note "Could not delete role assignment ${id}"
  done
done

banner "Resource groups"
delete_lunch_rgs 24

banner "Local files"
rm -rf "${LAB_DIR}/work"
info "Removed ${LAB_DIR}/work."
info "In your own shell, also run: unset SAS_URL"

if (( LOCKED == 1 )); then
  banner "Action needed: locked retention policy"
  info "The storage account (and its resource group) will survive until the retention period ends."
  info "Follow 'If you locked the policy' in the Clean up section of README.md, then run this script again."
fi

banner "Done"
info "Resource group deletion continues in the background for a few minutes."
