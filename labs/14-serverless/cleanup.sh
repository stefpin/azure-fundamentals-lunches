#!/usr/bin/env bash
# =============================================================================
# Lab 14 · cleanup.sh — deletes everything the lab created.
#     bash cleanup.sh
# Everything lives in rg-lunch14-<suffix>: the storage account, the function app
# and its plan, Application Insights, the workspace and the Logic App. The role
# assignment on the storage account disappears with the account.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Lab 14 clean-up"
if az monitor log-analytics workspace show -g "$RG" -n "$LAW" --output none 2>/dev/null; then
  info "Deleting workspace ${LAW} without the 14-day soft-delete, so a re-run starts clean..."
  az monitor log-analytics workspace delete -g "$RG" -n "$LAW" --force true --yes --output none \
    || note "Could not force-delete the workspace; it is deleted with the resource group instead."
fi

delete_lunch_rgs 14

info "Removing local files in ${OUT_DIR} (zip package and the workflow file with the function key)..."
rm -rf "${OUT_DIR}"

info "Done. Deletion continues in the background for a few minutes."
