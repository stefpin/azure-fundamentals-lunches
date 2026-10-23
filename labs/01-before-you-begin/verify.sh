#!/usr/bin/env bash
# =============================================================================
# Lab 01 · Set up your lab environment — verification
#   bash verify.sh
# Read-only: it checks your work and changes nothing.
#
# Checks
#   1. You are signed in to the Azure CLI.
#   2. The current subscription is Enabled.
#   3. A budget exists at subscription scope, monthly, with alerts at 50/80/100%.
#      Subscription types that Cost Management does not support (Azure for
#      Students, Azure for Students Starter, sponsorships) are checked for an
#      active spending limit instead.
#   4. No Lab 01 resource group is left behind.
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 01)"
SUB_ID="$(az_q account show --query id)"
COST_API="2023-08-01"   # Microsoft.CostManagement/budgets API version used as a fallback

# budget_rows -> "id<TAB>name<TAB>timeGrain" for every budget visible at subscription level.
# Uses the Azure CLI first (az consumption, a preview command group) and falls back to the
# Cost Management REST API if that command is unavailable.
budget_rows() {
  local rows
  if rows="$(az consumption budget list --query "[].[id, name, timeGrain]" --output tsv 2>/dev/null)"; then
    printf '%s\n' "$rows"
    return 0
  fi
  az rest --method get \
    --url "https://management.azure.com/subscriptions/${SUB_ID}/providers/Microsoft.CostManagement/budgets?api-version=${COST_API}" \
    --query "value[].[id, name, properties.timeGrain]" --output tsv 2>/dev/null || true
}

# budget_thresholds <name> -> one alert threshold (percent) per line
budget_thresholds() {
  local name="$1" t
  t="$(az consumption budget show --budget-name "$name" --query "notifications.*.threshold" --output tsv 2>/dev/null)"
  if [[ -z "$t" ]]; then
    t="$(az rest --method get \
      --url "https://management.azure.com/subscriptions/${SUB_ID}/providers/Microsoft.CostManagement/budgets/${name}?api-version=${COST_API}" \
      --query "properties.notifications.*.threshold" --output tsv 2>/dev/null)"
  fi
  printf '%s\n' "$t" | tr '\t' '\n' | sed '/^[[:space:]]*$/d'
}

# join_lines <separator>  -> joins the non-empty lines read from stdin
join_lines() {
  local sep="$1" line out=""
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    out+="${out:+$sep}${line}"
  done
  printf '%s' "$out"
}

# has_threshold <percent> <list> -> success if the list contains that percentage (50, 50.0, ...)
has_threshold() {
  grep -Eq "^${1}(\.0+)?$" <<< "$2"
}

banner "Task 1 · Signed in, subscription enabled"
user="$(az_q account show --query user.name)"
sub_name="$(az_q account show --query name)"
check_nonempty "Signed in to the Azure CLI as ${user:-<unknown>}" "$user"
check_eq "Subscription '${sub_name}' is enabled" "Enabled" "$(az_q account show --query state)"

banner "Task 2 · Budget at subscription scope"
mapfile -t sub_budgets < <(budget_rows | grep -iv '/resourcegroups/' | sed '/^[[:space:]]*$/d')

if (( ${#sub_budgets[@]} > 0 )); then
  names="$(printf '%s\n' "${sub_budgets[@]}" | cut -f2 | join_lines ', ')"
  pass "Found ${#sub_budgets[@]} budget(s) at subscription scope: ${names}"

  good="" readable=0 seen=""
  for row in "${sub_budgets[@]}"; do
    IFS=$'\t' read -r _b_id b_name b_grain <<< "$row"
    th="$(budget_thresholds "$b_name")"
    [[ -n "$th" ]] && readable=1
    seen+="${b_name} (period: ${b_grain:-?}; alerts: $(join_lines ',' <<< "${th:-none}")) "
    if [[ -z "$b_grain" || "${b_grain,,}" == *month* ]] \
      && has_threshold 50 "$th" && has_threshold 80 "$th" && has_threshold 100 "$th"; then
      good="$b_name"
      break
    fi
  done

  if [[ -n "$good" ]]; then
    pass "Budget '${good}' resets monthly and alerts at 50%, 80% and 100%"
  elif (( readable == 0 )); then
    note "Could not read the alert thresholds. Check them in the portal: Cost Management › Budgets."
  else
    fail "No monthly budget with alerts at 50%, 80% and 100% — found: ${seen}(revisit Task 2)"
  fi
else
  policies_url="https://management.azure.com/subscriptions/${SUB_ID}?api-version=2022-12-01"
  quota_id="$(az_q rest --method get --url "$policies_url" --query "subscriptionPolicies.quotaId")"
  spending_limit="$(az_q rest --method get --url "$policies_url" --query "subscriptionPolicies.spendingLimit")"
  case "$quota_id" in
    AzureForStudents*|DreamSpark*|Sponsored*)
      note "Your subscription type (${quota_id}) is listed as not supported by Cost Management budgets."
      check_eq "Fallback guardrail: the spending limit is on" "On" "$spending_limit"
      ;;
    *)
      fail "No budget found at subscription scope (revisit Task 2). A new budget can take a few minutes to appear; brand-new subscriptions can need up to 48 hours before Budgets is available."
      ;;
  esac
fi

banner "Task 5 · Nothing left behind"
mapfile -t leftovers < <(
  {
    az_q group list --tag lunch=01 --query "[?tags.course=='${COURSE_TAG}'].name"
    for g in "$RG" "$(rg_name 01 typo)"; do
      [[ "$(az_q group exists --name "$g")" == "true" ]] && echo "$g"
    done
  } | sed '/^[[:space:]]*$/d' | sort -fu
)
remaining=()
deleting=()
for g in "${leftovers[@]}"; do
  state="$(az_q group show --name "$g" --query properties.provisioningState)"
  if [[ "$state" == "Deleting" ]]; then
    deleting+=("$g")
  elif [[ -n "$state" ]]; then
    remaining+=("$g")
  fi
done
if (( ${#remaining[@]} == 0 )); then
  pass "No Lab 01 resource group is left behind"
  if (( ${#deleting[@]} > 0 )); then
    note "Still being deleted (that is fine): ${deleting[*]}"
  fi
else
  fail "Lab 01 resource group(s) still exist: ${remaining[*]} — delete them (Task 5) or run: bash cleanup.sh"
fi

summary
