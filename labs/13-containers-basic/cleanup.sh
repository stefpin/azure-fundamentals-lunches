#!/usr/bin/env bash
# =============================================================================
# Lab 13 · Package the storefront — removes everything the lab created.
#   bash cleanup.sh            (asks before deleting)
#   ASSUME_YES=1 bash cleanup.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

banner "Lab 13 clean-up"
info "This deletes every resource group tagged for lunch 13: the registry, the container group(s),"
info "the Container Apps environment and app, any managed identity you created and the Log Analytics workspace."

if ! confirm "Delete the lab 13 resource groups now?"; then
  info "Nothing deleted."
  exit 0
fi

delete_lunch_rgs 13

info "Nothing in this lab lives outside the resource group: the AcrPull role assignments sit on the registry"
info "and are removed with it, and the app's system-assigned identity is deleted together with the app."
info "Follow the deletion with:  az group list --tag lunch=13 --output table"
