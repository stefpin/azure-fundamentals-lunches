#!/usr/bin/env bash
# =============================================================================
# Lab 11 · Clean up — deletes everything this lab created.
#   bash cleanup.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

banner "Lab 11 · Clean up"
info "The logical server, the database and its firewall rules all live in the lab resource group."
delete_lunch_rgs 11

# Remove any access-token file a cancelled azsql call might have left behind.
rm -f "${HOME}"/.azsql-token-* 2>/dev/null || true

info "Nothing was created outside the resource group, so there is nothing else to remove."
info "Deleting a free-offer database also frees its slot in your subscription's free allowance."
info "Check in a few minutes with: az group list --tag lunch=11 --output table"
