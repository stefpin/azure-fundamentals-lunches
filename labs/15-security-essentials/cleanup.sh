#!/usr/bin/env bash
# =============================================================================
# Lab 15 · cleanup.sh — removes everything the lab created:
#   1. deletes the lab key vault(s) (they move to the soft-deleted state),
#   2. deletes the lab resource group (VM, disk, NIC, VNet, NSG) in the background,
#   3. purges the soft-deleted vault(s) so the names are free again.
# Role assignments at vault scope disappear with the vault; nothing else exists
# outside the resource group. Tolerates vaults that are already purged.
#   bash cleanup.sh            (asks first; ASSUME_YES=1 bash cleanup.sh skips the question)
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 15)"
KV_NAME="kv-nusa-${SUFFIX}"

banner "Lab 15 cleanup"
if ! confirm "Delete resource group ${RG} and permanently purge the lab key vault(s) for suffix ${SUFFIX}?"; then
  info "Nothing deleted."
  exit 0
fi

# Every vault this lab may have created: the main vault, any extra vault in the lab
# resource group (stretch goals), and lab vaults already sitting in the soft-deleted list.
mapfile -t VAULTS < <(
  {
    echo "$KV_NAME"
    az_q keyvault list --resource-group "$RG" --query "[].name"
    az_q keyvault list-deleted --resource-type vault \
      --query "[?starts_with(name, 'kv-nusa') && ends_with(name, '-${SUFFIX}')].name"
  } | sed '/^$/d' | sort -u
)

# 1. Delete active vaults first, so they are soft-deleted right away.
for kv in "${VAULTS[@]}"; do
  if az keyvault show --name "$kv" --output none 2>/dev/null; then
    info "Deleting key vault ${kv} (it moves to the soft-deleted state)..."
    az keyvault delete --name "$kv" --output none || note "Could not delete ${kv} now; the resource group deletion will."
  fi
done

# 2. Delete the resource group(s) tagged for lunch 15.
delete_lunch_rgs 15

# 3. Purge the soft-deleted vaults.
purge_vault() {
  local kv="$1" waited=0 location protected
  while az keyvault show --name "$kv" --output none 2>/dev/null; do
    if (( waited >= 600 )); then
      note "${kv} still exists after 10 minutes. Run 'bash cleanup.sh' again later to purge it."
      return 0
    fi
    sleep 15
    waited=$((waited + 15))
  done
  location="$(az_q keyvault list-deleted --resource-type vault --query "[?name=='${kv}'].properties.location | [0]")"
  if [[ -z "$location" ]]; then
    info "${kv}: not in the soft-deleted list (already purged, or never created). Nothing to purge."
    return 0
  fi
  protected="$(az_q keyvault list-deleted --resource-type vault --query "[?name=='${kv}'].properties.purgeProtectionEnabled | [0]")"
  if [[ "${protected,,}" == "true" ]]; then
    note "${kv} has purge protection, so it can't be purged. Azure removes it after its retention period; the name stays reserved until then."
    return 0
  fi
  info "Purging ${kv} in ${location} (permanent; this can take a few minutes)..."
  if az keyvault purge --name "$kv" --location "$location" --output none 2>/dev/null; then
    info "${kv} purged."
  elif [[ -z "$(az_q keyvault list-deleted --resource-type vault --query "[?name=='${kv}'].name | [0]")" ]]; then
    info "${kv} is already purged."
  else
    note "Could not purge ${kv} yet. Try again later: az keyvault purge --name ${kv} --location ${location}"
  fi
}

for kv in "${VAULTS[@]}"; do
  purge_vault "$kv"
done

banner "Cleanup started"
info "The resource group is being deleted in the background (a few minutes)."
info "Check later with: az group list --tag lunch=15 --output table"
