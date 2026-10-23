#!/usr/bin/env bash
# =============================================================================
# Lab 17 · cleanup.sh — deletes everything the lab created, in the order backups need:
#   1. immutability off (only if it is still unlocked)
#   2. stop protection and delete the backup data (it becomes soft-deleted)
#   3. delete the VM's instant-restore snapshots, which live OUTSIDE the lab
#      resource group (AzureBackupRG_<region>_N) and keep costing money
#   4. delete the vault (with only soft-deleted items left, it becomes soft-deleted)
#   5. delete rg-lunch17-<suffix>
# Safe to run again.
#     bash cleanup.sh
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

no_jobs_running() {
  [[ "$(az_q backup job list -g "$RG" --vault-name "$VAULT" --status InProgress --query "length(@)")" == "0" ]]
}
no_delete_jobs_running() {
  [[ "$(az_q backup job list -g "$RG" --vault-name "$VAULT" --operation DeleteBackupData --status InProgress \
    --query "length(@)")" == "0" ]]
}

# Instant-restore snapshots are restore point collections in AzureBackupRG_<region>_<n>.
delete_instant_restore_snapshots() {
  local brg rpc src vm_id
  vm_id="/resourcegroups/${RG,,}/providers/microsoft.compute/virtualmachines/${VM,,}"
  while IFS= read -r brg; do
    [[ "${brg,,}" == "azurebackuprg_${LOCATION,,}_"* ]] || continue
    while IFS= read -r rpc; do
      [[ -z "$rpc" ]] && continue
      src="$(az_q resource show --ids "$rpc" --query properties.source.id)"
      if [[ "${src,,}" == *"$vm_id" ]]; then
        info "Deleting instant-restore snapshots ${rpc##*/} in ${brg}..."
        az resource delete --ids "$rpc" --output none \
          || note "Could not delete ${rpc##*/}. Delete it in the portal (resource group ${brg})."
      fi
    done < <(az_q resource list -g "$brg" --resource-type Microsoft.Compute/restorePointCollections --query "[].id")
    if [[ "$(az_q resource list -g "$brg" --query "length(@)")" == "0" ]]; then
      info "Resource group ${brg} is empty now. Deleting it..."
      az group delete -n "$brg" --yes --no-wait || true
    fi
  done < <(az_q group list --query "[].name")
}

banner "Lab 17 clean-up"
if [[ -n "$(az_q backup vault show -g "$RG" -n "$VAULT" --query name)" ]]; then
  immutability="$(az_q backup vault show -g "$RG" -n "$VAULT" \
    --query properties.securitySettings.immutabilitySettings.state)"
  if [[ "$immutability" == "Unlocked" ]]; then
    info "Switching immutability off (it was unlocked, so this is still allowed)..."
    az backup vault update -g "$RG" -n "$VAULT" --immutability-state Disabled --output none
  elif [[ "$immutability" == "Locked" ]]; then
    note "Immutability on ${VAULT} is LOCKED: recovery points can't be deleted before they expire."
    note "The vault and its backups stay until then. Everything else is deleted now."
  fi

  if ! no_jobs_running; then
    info "A backup or restore job is still running, and a transfer to the vault can't be cancelled."
    info "Waiting for it to finish (checked every 10 s, up to 90 minutes)..."
    wait_until "running backup jobs" 5400 no_jobs_running || true
  fi

  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    info "Stopping protection of ${item} and deleting its backup data (it moves to soft delete)..."
    az backup protection disable -g "$RG" --vault-name "$VAULT" -c "$item" -i "$item" \
      --backup-management-type AzureIaasVM --delete-backup-data true --yes --output none \
      || note "Could not stop protection of ${item}. Try again in a few minutes."
  done < <(az_q backup item list -g "$RG" --vault-name "$VAULT" --backup-management-type AzureIaasVM \
    --query "[?properties.isScheduledForDeferredDelete != \`true\`].properties.friendlyName")
  info "Waiting for the delete-backup-data jobs to finish (usually 1-5 minutes)..."
  wait_until "delete-backup-data jobs" 900 no_delete_jobs_running || true

  delete_instant_restore_snapshots

  info "Deleting vault ${VAULT}..."
  deleted=0
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if err="$(az backup vault delete -g "$RG" -n "$VAULT" --yes --output none 2>&1)"; then
      deleted=1
      break
    fi
    info "Attempt ${attempt}: the vault isn't ready to delete yet. Waiting 30 s..."
    sleep 30
  done
  if (( deleted == 1 )); then
    info "Vault deleted. With only soft-deleted items inside, it moves to a soft-deleted state and is purged"
    info "automatically after 14 days at no cost: az backup deleted-vault list --location ${LOCATION}"
  else
    note "The vault could not be deleted yet: $(tail -n 1 <<<"$err")"
    note "If the message mentions items in soft deleted state, run this script again after 14 days."
    note "Soft-deleted backup data costs nothing for those 14 days."
  fi
else
  info "No vault ${VAULT} in ${RG}."
  delete_instant_restore_snapshots
fi

delete_lunch_rgs 17
# A Challenge-mode resource group created without the course tags is not found above.
if [[ "$(az group exists --name "$RG" 2>/dev/null)" == "true" && "$(az_q group show -n "$RG" --query tags.lunch)" != "17" ]]; then
  info "Deleting resource group ${RG} (created without the lab tags)..."
  az group delete --name "$RG" --yes --no-wait
fi
info "Done. Deletion continues in the background for a few minutes."
