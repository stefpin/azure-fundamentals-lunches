#!/usr/bin/env bash
# =============================================================================
# Lab 27 · cleanup.sh — deletes everything this lab created.
#     bash cleanup.sh            (asks for confirmation)
#     ASSUME_YES=1 bash cleanup.sh
# The Application Gateway, WAF policy, public IP, Traffic Manager profile, optional
# Front Door profile, App Service plan and apps all live in rg-lunch27-<suffix>;
# nothing is created outside it. The local out/ folder (zip packages) is removed too.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Clean up Lab 27"
if ! confirm "Delete every resource group created for Lunch 27 (gateway, WAF policy, Traffic Manager, Front Door, apps)?"; then
  info "Nothing deleted."
  exit 0
fi

delete_lunch_rgs 27
rm -rf "${LAB_DIR}/out"

info "Any deletion started above continues in the background; the Application Gateway alone can take"
info "5–10 minutes to disappear. Check with:  az group list --tag lunch=27 --output table"
info "Billing for the gateway stops once it is deleted."
