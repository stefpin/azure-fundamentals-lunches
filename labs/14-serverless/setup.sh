#!/usr/bin/env bash
# =============================================================================
# Lab 14 · setup.sh — creates the starting point (about 2 minutes):
#   * checks that your region offers the Flex Consumption plan
#   * resource group rg-lunch14-<suffix>
#   * storage account stnusaorders<suffix> with the queue "orders"
#   * Log Analytics workspace log-nusa (Application Insights keeps its data there)
#   * the Azure CLI extension "logic" (for az logic workflow)
#     bash setup.sh
# Safe to re-run. Set SKIP_FLEX_CHECK=1 to skip the region check.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Does ${LOCATION} offer the Flex Consumption plan?"
if [[ "${SKIP_FLEX_CHECK:-0}" != "1" ]]; then
  want="$(printf '%s' "$LOCATION" | tr -d ' ' | tr '[:upper:]' '[:lower:]')"
  regions="$(az functionapp list-flexconsumption-locations --query "[].name" --output tsv 2>/dev/null \
    | tr -d ' ' | tr '[:upper:]' '[:lower:]' || true)"
  if [[ -z "$regions" ]]; then
    note "Could not read the list of Flex Consumption regions. Continuing; if Task 2 fails, choose another region."
  elif grep -qx "$want" <<<"$regions"; then
    info "Yes. ${LOCATION} offers Flex Consumption."
  else
    echo
    echo "Flex Consumption isn't offered in '${LOCATION}' for your subscription. Regions that offer it include:"
    printf '%s\n' "$regions" | sort | head -40 | sed 's/^/   - /'
    echo
    echo "Choose one near you (eastasia, for example) and start again:"
    echo "   export LOCATION=eastasia && source ../common/config.sh && source lab.env && bash setup.sh"
    exit 1
  fi
fi

banner "Resource group ${RG}"
ensure_rg "$RG" 14

banner "Storage account ${ST} and queue '${QUEUE}'"
if az storage account show -g "$RG" -n "$ST" --output none 2>/dev/null; then
  info "The storage account already exists."
else
  available="$(az_q storage account check-name --name "$ST" --query nameAvailable)"
  if [[ "$available" == "false" ]]; then
    echo "The storage account name ${ST} is already taken. Pick another one and run setup.sh again:"
    echo "   export LAB14_ST=\"stnusaorders${SUFFIX}2\" && source lab.env && bash setup.sh"
    exit 1
  fi
  # The CLI connects the function host to this account with a connection string by default,
  # so shared key access stays on. The queue itself is reached with a managed identity (Task 3).
  az storage account create -g "$RG" -n "$ST" -l "$LOCATION" \
    --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
    --allow-blob-public-access false --allow-shared-key-access true --output none
  info "Created ${ST}."
fi
az storage queue create --name "$QUEUE" --account-name "$ST" --auth-mode key --only-show-errors --output none
info "Queue '${QUEUE}' is ready."

banner "Log Analytics workspace ${LAW}"
if az monitor log-analytics workspace show -g "$RG" -n "$LAW" --output none 2>/dev/null; then
  info "The workspace already exists."
else
  az monitor log-analytics workspace create -g "$RG" -n "$LAW" -l "$LOCATION" --output none
  info "Created ${LAW}."
fi

banner "Azure CLI extension 'logic'"
az extension add --name logic --upgrade --only-show-errors
info "Installed or updated."

banner "Starting point ready"
info "Resource group : ${RG} (${LOCATION})"
info "Storage account: ${ST} with queue '${QUEUE}'"
info "Workspace      : ${LAW}"
info "Next: Task 1 in README.md"
