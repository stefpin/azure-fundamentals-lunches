#!/usr/bin/env bash
# =============================================================================
# Lab 19 · solution.sh — the reference solution for the CLI tasks.
#   Task 2  hunt the orphans with Azure Resource Graph
#   Task 3  list Advisor cost recommendations
#   Task 4  create a monthly budget on the resource group (alerts at 50/80/100%)
#   Task 6  compare pay-as-you-go with reservations (compare-prices.sh)
#   Task 7  delete the waste
# Task 5 (cost analysis by tag) is a portal task — see the README.
#
# Set where the budget alerts go (defaults to your sign-in name if it is an email address):
#   BUDGET_EMAIL=you@example.com BUDGET_AMOUNT=10 bash solution.sh
# BUDGET_AMOUNT uses your subscription's billing currency.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
RG="$(rg_name 19)"
BUDGET_NAME="budget-lunch19"
BUDGET_AMOUNT="${BUDGET_AMOUNT:-10}"
BUDGET_EMAIL="${BUDGET_EMAIL:-$(az_q account show --query user.name)}"

if [[ "$(az_q group exists --name "$RG")" != "true" ]]; then
  echo "Resource group ${RG} not found. Run 'bash setup.sh' first."
  exit 1
fi

banner "Task 2 · Orphan hunt with Azure Resource Graph"
az extension add --name resource-graph --upgrade --only-show-errors --output none \
  || note "Could not install or update the resource-graph extension; trying az graph anyway."
info "Unattached managed disks:"
az graph query -q "
Resources
| where type =~ 'microsoft.compute/disks'
| where tostring(properties.diskState) =~ 'Unattached'
| where resourceGroup =~ '${RG}'
| project name, sku = tostring(sku.name), sizeGB = toint(properties.diskSizeGB), costCenter = tostring(tags['costCenter'])
" --query "data" --output table
info "Public IP addresses associated with nothing:"
az graph query -q "
Resources
| where type =~ 'microsoft.network/publicipaddresses'
| where isnull(properties.ipConfiguration) and isnull(properties.natGateway)
| where resourceGroup =~ '${RG}'
| project name, sku = tostring(sku.name), ip = tostring(properties.ipAddress), costCenter = tostring(tags['costCenter'])
" --query "data" --output table
info "App Service plans with no apps:"
az graph query -q "
Resources
| where type =~ 'microsoft.web/serverfarms'
| where toint(properties.numberOfSites) == 0
| where resourceGroup =~ '${RG}'
| project name, sku = tostring(sku.name), costCenter = tostring(tags['costCenter'])
" --query "data" --output table

banner "Task 3 · Advisor cost recommendations (often empty for brand-new resources)"
az advisor recommendation list --category Cost \
  --query "[].{impact:impact, problem:shortDescription.problem, resource:impactedValue}" --output table \
  || note "Could not read Advisor recommendations."

banner "Task 4 · Monthly budget on ${RG} with alerts at 50, 80 and 100%"
if [[ ! "$BUDGET_EMAIL" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; then
  echo "Set BUDGET_EMAIL to the address that should receive the alerts, for example:"
  echo "  BUDGET_EMAIL=you@example.com bash solution.sh"
  exit 1
fi
START_DATE="$(date -u +%Y-%m-01)"
END_DATE="$(date -u -d "${START_DATE} +1 year" +%Y-%m-%d)"
TIME_PERIOD="$(printf '{"start-date":"%s","end-date":"%s"}' "$START_DATE" "$END_DATE")"
NOTIFICATIONS=$(cat <<EOF
{
  "actual_GreaterThan_50_Percent":  {"enabled": true, "operator": "GreaterThan", "threshold": 50,  "contact-emails": ["${BUDGET_EMAIL}"]},
  "actual_GreaterThan_80_Percent":  {"enabled": true, "operator": "GreaterThan", "threshold": 80,  "contact-emails": ["${BUDGET_EMAIL}"]},
  "actual_GreaterThan_100_Percent": {"enabled": true, "operator": "GreaterThan", "threshold": 100, "contact-emails": ["${BUDGET_EMAIL}"]}
}
EOF
)
az consumption budget create-with-rg \
  --resource-group "$RG" \
  --budget-name "$BUDGET_NAME" \
  --amount "$BUDGET_AMOUNT" \
  --category Cost \
  --time-grain Monthly \
  --time-period "$TIME_PERIOD" \
  --notifications "$NOTIFICATIONS" \
  --output none
info "Budget ${BUDGET_NAME}: ${BUDGET_AMOUNT} per month from ${START_DATE}, alerts to ${BUDGET_EMAIL}."

banner "Task 6 · Pay-as-you-go vs commitments for ${VM_SIZE}"
bash "${LAB_DIR}/compare-prices.sh" || note "Price lookup failed; use the pricing calculator instead."

banner "Task 7 · Delete the waste"
az appservice plan delete --resource-group "$RG" --name asp-nusa-idle --yes --output none 2>/dev/null \
  || info "asp-nusa-idle not found (already deleted?)."
az network public-ip delete --resource-group "$RG" --name pip-nusa-orphan --output none 2>/dev/null \
  || info "pip-nusa-orphan not found (already deleted?)."
az disk delete --resource-group "$RG" --name disk-nusa-orphan --yes --output none 2>/dev/null \
  || info "disk-nusa-orphan not found (already deleted?)."
info "Waste removed. Resource Graph can take a minute to catch up."
info "Now run: bash verify.sh"
