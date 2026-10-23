#!/usr/bin/env bash
# =============================================================================
# Lab 16 · Clean up
#
# Everything this lab creates lives in resource group rg-lunch16-<suffix>:
# the VM and its disk, NIC, public IP, NSG and virtual network, the action
# group, and all alert rules — including the Service Health alert, which is
# stored in the resource group even though it watches the whole subscription.
# Nothing is created outside the resource group.
#
#   bash cleanup.sh                 # asks before deleting
#   ASSUME_YES=1 bash cleanup.sh    # no question (for automation)
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 16)"

banner "Lab 16 · Clean up"
info "This deletes resource group ${RG} and everything in it."
if ! confirm "Delete all Lab 16 resources now?"; then
  info "Nothing deleted."
  exit 0
fi

delete_lunch_rgs 16

banner "Done"
info "Deletion continues in the background for a few minutes. Check with:"
info "  az group list --tag lunch=16 --output table"
info "Fired alerts stay visible under Monitor > Alerts for up to 30 days, and the activity log keeps"
info "its entries for 90 days. Neither costs anything, and neither can be deleted by hand."
