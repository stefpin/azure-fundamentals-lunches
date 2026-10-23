#!/usr/bin/env bash
# =============================================================================
# Lab 19 · verify.sh — checks the Challenge brief:
#   * no unattached managed disks, unassociated public IPs or empty App Service plans in the lab resource group
#   * a budget on the lab resource group with alerts at 50, 80 and 100 percent
# Read-only: it changes nothing.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 19)"

# Budget names on the resource group (CLI first, REST API as a fallback).
budget_names() {
  local out
  out="$(az_q consumption budget list --resource-group "$RG" --query "[].name")"
  if [[ -z "$out" ]]; then
    out="$(az_q rest --method get \
      --url "/subscriptions/{subscriptionId}/resourceGroups/${RG}/providers/Microsoft.Consumption/budgets?api-version=2019-10-01" \
      --query "value[].name")"
  fi
  printf '%s\n' "$out"
}

# Alert thresholds (percent) of one budget, one per line.
budget_thresholds() {
  local out
  out="$(az_q consumption budget show-with-rg --resource-group "$RG" --budget-name "$1" \
    --query "(notifications || properties.notifications).*.threshold")"
  if [[ -z "$out" ]]; then
    out="$(az_q rest --method get \
      --url "/subscriptions/{subscriptionId}/resourceGroups/${RG}/providers/Microsoft.Consumption/budgets/$1?api-version=2019-10-01" \
      --query "properties.notifications.*.threshold")"
  fi
  printf '%s\n' "$out"
}

banner "Lab resource group"
if [[ "$(az_q group exists --name "$RG")" != "true" ]]; then
  fail "Resource group ${RG} not found — run 'bash setup.sh' (or you already ran cleanup.sh)"
  summary
  exit $?
fi
pass "Resource group ${RG} exists"

banner "Waste removed (Task 7)"
disks="$(az_q disk list --resource-group "$RG" --query "length([?diskState=='Unattached'])")"
check_eq "No unattached managed disks in ${RG}" "0" "$disks"
ips="$(az_q network public-ip list --resource-group "$RG" --query "length([?ipConfiguration==null && natGateway==null])")"
check_eq "No public IP addresses associated with nothing in ${RG}" "0" "$ips"
plans="$(az_q appservice plan list --resource-group "$RG" --query 'length([?numberOfSites==`0`])')"
check_eq "No App Service plans without apps in ${RG}" "0" "$plans"

banner "Budget on the resource group (Task 4)"
budget="$(budget_names | sed '/^$/d' | head -n 1)"
check_nonempty "A budget exists on ${RG}" "$budget"
if [[ -n "$budget" ]]; then
  info "Checking alert thresholds of budget '${budget}'..."
  thresholds="$(budget_thresholds "$budget")"
  for pct in 50 80 100; do
    if grep -Eq "^${pct}(\.0+)?$" <<< "$thresholds"; then
      pass "Budget alert at ${pct}%"
    else
      fail "Budget alert at ${pct}% (add it to the budget — see Task 4)"
    fi
  done
fi

summary
