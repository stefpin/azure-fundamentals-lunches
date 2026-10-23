#!/usr/bin/env bash
# =============================================================================
# Lab 01 · Set up your lab environment — reference solution (CLI parts only)
#   bash solution.sh
# Task 2 (the budget) is a portal task; this script only shows existing budgets.
# Task 4 (looking around the portal) cannot be scripted.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 01)"

# join_lines <separator>  -> joins the non-empty lines read from stdin
join_lines() {
  local sep="$1" line out=""
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    out+="${out:+$sep}${line}"
  done
  printf '%s' "$out"
}
TYPO_RG="$(rg_name 01 typo)"

banner "Task 1 · Account and environment check"
az account show --query "{subscription:name, state:state, user:user.name}" --output table
bash "${AZL_COMMON_DIR}/check-environment.sh" || note "Some environment checks failed. Read the messages above."

banner "Task 2 · Budget (create it in the portal: Cost Management › Budgets › + Add)"
budgets="$(az_q consumption budget list --query "[].name" | join_lines ', ')"
if [[ -n "$budgets" ]]; then
  info "Budget(s) found: ${budgets}"
else
  note "No budget found yet. Follow Task 2 in the README."
fi

banner "Task 3 · Create a tagged resource group"
ensure_rg "$RG" 01
az group show --name "$RG" \
  --query "{name:name, location:location, tags:tags, state:properties.provisioningState}" --output json
az group list --tag course="$COURSE_TAG" --output table
info "Resource ID: $(az group show --name "$RG" --query id --output tsv)"

banner "Break it and fix it · an invalid region name"
if az group create --name "$TYPO_RG" --location southeastasai \
     --tags course="$COURSE_TAG" lunch=01 --output none; then
  note "Unexpected: the misspelled region was accepted. Deleting the group again."
  az group delete --name "$TYPO_RG" --yes --no-wait
else
  info "As expected, Azure Resource Manager rejected 'southeastasai'. Valid region names in Asia:"
  az account list-locations --query "[?metadata.regionType=='Physical'].name" --output tsv \
    | sort | grep -i -E 'asia|indonesia' | sed 's/^/     - /' || true
fi

banner "Task 5 · Delete the resource group"
az group delete --name "$RG" --yes
info "Does ${RG} still exist? $(az group exists --name "$RG")"

echo
info "Done. Run 'bash verify.sh' to check the whole lab (including the budget from Task 2)."
