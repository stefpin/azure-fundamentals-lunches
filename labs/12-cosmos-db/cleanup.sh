#!/usr/bin/env bash
# =============================================================================
# Lab 12 · cleanup.sh — deletes everything the lab created.
#     bash cleanup.sh
# Everything lives in rg-lunch12-<suffix>: the Cosmos DB account(s), the database,
# the items and the data-plane role assignment (which lives inside the account).
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Lab 12 clean-up"
delete_lunch_rgs 12
# A Challenge-mode resource group created without the course tags is not found above.
if [[ "$(az group exists --name "$RG" 2>/dev/null)" == "true" && "$(az_q group show -n "$RG" --query tags.lunch)" != "12" ]]; then
  info "Deleting resource group ${RG} (created without the lab tags)..."
  az group delete --name "$RG" --yes --no-wait
fi

if [[ -n "${COSMOS_KEY:-}" ]]; then
  note "COSMOS_KEY is still set in your shell. Run: unset COSMOS_KEY"
fi
info "Done. Deletion continues in the background for a few minutes."
info "The Python packages stay in your home directory; remove them with: pip uninstall azure-cosmos azure-identity"
