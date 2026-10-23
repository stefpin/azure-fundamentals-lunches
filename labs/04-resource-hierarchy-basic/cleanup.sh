#!/usr/bin/env bash
# =============================================================================
# Lab 04 · Clean up: deletes everything the lab created.
#   bash cleanup.sh
# Order matters: locks first (a locked resource group can't be deleted), then the
# optional management group, then the resource groups.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

MG="mg-nusa-lab-${SUFFIX}"

banner "Removing resource locks from every Lab 04 resource group"
mapfile -t lab_rgs < <(az group list --tag lunch=04 --query "[?tags.course=='${COURSE_TAG}'].name" --output tsv 2>/dev/null || true)
removed=0
if (( ${#lab_rgs[@]} > 0 )); then
  pattern="/resourcegroups/($(IFS='|'; echo "${lab_rgs[*]}"))(/|$)"
  while IFS= read -r lock_id; do
    [[ -z "$lock_id" ]] && continue
    info "Deleting lock ${lock_id##*/}"
    az lock delete --ids "$lock_id" || note "Could not delete ${lock_id##*/}; delete it in the portal, then run cleanup again."
    removed=$((removed + 1))
  done < <(az lock list --query "[].id" --output tsv 2>/dev/null | grep -iE "$pattern" || true)
fi
if (( removed == 0 )); then
  info "No locks found."
else
  info "Removed ${removed} lock(s). Waiting a moment before deleting the resource groups..."
  sleep 20
fi

banner "Removing the optional management group"
if az account management-group show --name "$MG" --no-register --output none 2>/dev/null; then
  if az account management-group delete --name "$MG" --no-register --output none; then
    info "Deleted management group ${MG}."
  else
    note "Could not delete ${MG}. If you moved a subscription into it, move the subscription back to the Tenant root group first, then run cleanup.sh again."
  fi
else
  info "No lab management group found."
fi

banner "Deleting the Lab 04 resource groups"
delete_lunch_rgs 04
info "Check progress with:  az group list --tag lunch=04 --output table"
info "Optional: make the Azure CLI ask again before installing extensions:  az config unset extension.use_dynamic_install"
