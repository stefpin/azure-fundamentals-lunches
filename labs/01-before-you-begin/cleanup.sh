#!/usr/bin/env bash
# =============================================================================
# Lab 01 · Set up your lab environment — clean up
#   bash cleanup.sh
# Deletes every resource group this lab created. It deliberately KEEPS your
# budget: the budget is free and protects every lab in the course.
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

banner "Lab 01 · deleting resource groups"
tagged="$(az_q group list --tag lunch=01 --query "[?tags.course=='${COURSE_TAG}'].name")"
delete_lunch_rgs 01

# Also catch groups created without the course tags (for example in the portal).
for g in "$RG" "$(rg_name 01 typo)"; do
  if grep -qixF "$g" <<< "$tagged"; then
    continue
  fi
  if [[ "$(az_q group exists --name "$g")" == "true" ]]; then
    state="$(az_q group show --name "$g" --query properties.provisioningState)"
    if [[ "$state" != "Deleting" ]]; then
      info "Deleting untagged resource group ${g} (runs in the background)..."
      az group delete --name "$g" --yes --no-wait
    fi
  fi
done

banner "Kept on purpose"
budgets="$(az_q consumption budget list --query "[].name" | join_lines ', ')"
if [[ -n "$budgets" ]]; then
  info "Budget(s) kept: ${budgets}"
fi
info "Your budget is free and protects every lab in the course, so this script does not delete it."
info "When you finish the course, delete it in Cost Management › Budgets, or with:"
info "  az consumption budget delete --budget-name <name>"
info "Cloud Shell storage (resource group cloud-shell-storage-<region>) is not part of this lab;"
info "keep it while you use Cloud Shell, because it holds your home directory."
echo
info "Done. Run 'bash verify.sh' in a minute to confirm nothing from Lab 01 is left."
