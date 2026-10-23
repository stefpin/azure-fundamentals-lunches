#!/usr/bin/env bash
# =============================================================================
# Lab 03 · Clean up: deletes everything the lab created.
#   bash cleanup.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

banner "Deleting the Lab 03 resource group (public IPs and storage accounts)"
delete_lunch_rgs 03
info "Lab 03 creates nothing outside its resource group, so there is nothing else to remove."
info "Check progress with:  az group list --tag lunch=03 --output table"
