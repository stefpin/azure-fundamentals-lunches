#!/usr/bin/env bash
# =============================================================================
# Lab 10 · cleanup.sh — deletes everything the lab created.
#     bash cleanup.sh
# The plan, the web app and its slots all live in rg-lunch10-<suffix>; nothing
# is created outside the resource group. Local build files are removed too.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Lab 10 clean-up"
delete_lunch_rgs 10

# If `az webapp up` created the group before you ran Task 1, it has no lab tags.
rg_state="$(az_q group show --name "$RG" --query properties.provisioningState)"
if [[ -n "$rg_state" && "$rg_state" != "Deleting" ]]; then
  info "Deleting untagged resource group ${RG}..."
  az group delete --name "$RG" --yes --no-wait
fi

info "Removing local build files (${OUT_DIR}) and the az webapp up defaults (app/.azure)..."
rm -rf "${OUT_DIR}" "${LAB_DIR}/app/.azure"

info "Done. Deletion continues in the background for a few minutes."
