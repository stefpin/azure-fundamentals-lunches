#!/usr/bin/env bash
# =============================================================================
# Lab 17 · solution.sh — runs the whole restore drill (Tasks 1-7).
#     bash solution.sh
# Takes 30-90 minutes, mostly waiting for the first backup. Safe to re-run: it
# reuses the vault, the protection and existing recovery points, and repeats the
# drill (delete the file, restore it) each time.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

is_true() { [[ "${1,,}" == "true" ]]; }
vm_status() {   # prints ORDERS_OK, ORDERS_MISSING, ORDERS_CHANGED or NO_FINGERPRINT
  az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript \
    --scripts @"${LAB_DIR}/vm/check-orders.sh" --query "value[0].message" --output tsv 2>/dev/null \
    | grep -o "ORDERS_OK\|ORDERS_MISSING\|ORDERS_CHANGED\|NO_FINGERPRINT" | head -n 1 || true
}
item_q() {
  az_q backup item list -g "$RG" --vault-name "$VAULT" --backup-management-type AzureIaasVM \
    --query "[?properties.friendlyName=='${VM}'] | [0].properties.$1"
}
rp_count() {
  az_q backup recoverypoint list -g "$RG" --vault-name "$VAULT" -c "$VM" -i "$VM" \
    --backup-management-type AzureIaasVM --query "length(@)"
}

banner "Task 1 · Starting point and the orders file"
if [[ -z "$(az_q vm show -g "$RG" -n "$VM" --query id)" ]]; then
  bash "${LAB_DIR}/setup.sh"
fi
status="$(vm_status)"
info "Orders file: ${status:-unknown}"
if [[ "$status" == "NO_FINGERPRINT" ]]; then
  bash "${LAB_DIR}/setup.sh"
  status="$(vm_status)"
fi

banner "Task 2 · Recovery Services vault ${VAULT}"
if [[ -z "$(az_q backup vault show -g "$RG" -n "$VAULT" --query name)" ]]; then
  az backup vault create -g "$RG" -n "$VAULT" -l "$LOCATION" --output none
  az backup vault backup-properties set -g "$RG" -n "$VAULT" \
    --backup-storage-redundancy LocallyRedundant --output none
  info "Created ${VAULT} with locally redundant storage."
else
  info "${VAULT} already exists."
fi

banner "Task 3 · Soft delete"
info "softDeleteState: $(az_q backup vault show -g "$RG" -n "$VAULT" \
  --query properties.securitySettings.softDeleteSettings.softDeleteState) (on, and it stays on)"

banner "Task 4 · Protect ${VM} with ${POLICY}"
if is_true "$(item_q isScheduledForDeferredDelete)"; then
  info "The backup data is soft-deleted (Break it and fix it). Undeleting and resuming protection..."
  az backup protection undelete -g "$RG" --vault-name "$VAULT" -c "$VM" -i "$VM" \
    --backup-management-type AzureIaasVM --workload-type VM --output none
  az backup protection resume -g "$RG" --vault-name "$VAULT" -c "$VM" -i "$VM" \
    --backup-management-type AzureIaasVM --policy-name "$POLICY" --output none
elif [[ -z "$(item_q protectionState)" ]]; then
  az backup protection enable-for-vm -g "$RG" --vault-name "$VAULT" --vm "$VM" \
    --policy-name "$POLICY" --output none
elif [[ "$(item_q protectionState)" == "ProtectionStopped" ]]; then
  az backup protection resume -g "$RG" --vault-name "$VAULT" -c "$VM" -i "$VM" \
    --backup-management-type AzureIaasVM --policy-name "$POLICY" --output none
fi
info "Protection state: $(item_q protectionState), policy: $(item_q policyName)"

banner "Task 5 · A recovery point"
if [[ "$(rp_count)" =~ ^[1-9] ]]; then
  info "$(rp_count) recovery point(s) already exist."
else
  running="$(az_q backup job list -g "$RG" --vault-name "$VAULT" --operation Backup --status InProgress \
    --query "length(@)")"
  if [[ "$running" != "0" && -n "$running" ]]; then
    info "A backup job is already running."
  else
    job="$(az backup protection backup-now -g "$RG" --vault-name "$VAULT" -c "$VM" -i "$VM" \
      --backup-management-type AzureIaasVM --query name --output tsv)"
    info "Started backup job ${job}."
  fi
  info "Waiting for the snapshot phase to create a recovery point (usually 5-15 minutes, up to 2 hours)..."
  waited=0
  until [[ "$(rp_count)" =~ ^[1-9] ]]; do
    if (( waited >= 7200 )); then
      echo "No recovery point after 2 hours. Check the job in the portal, then run solution.sh again." >&2
      exit 1
    fi
    sleep 60
    waited=$((waited + 60))
  done
  info "Recovery point ready after about $((waited / 60)) minute(s)."
fi

banner "Task 6 · Lose the orders file"
status="$(vm_status)"
if [[ "$status" == "ORDERS_OK" || "$status" == "ORDERS_CHANGED" ]]; then
  vm_run "rm -f /data/orders.csv" >/dev/null
  info "Deleted /data/orders.csv. Status now: $(vm_status)"
else
  info "Orders file: ${status:-unknown}. Nothing to delete."
fi

banner "Task 7 · Restore it from the newest recovery point"
for old in $(az_q vm show -g "$RG" -n "$VM" --query "storageProfile.dataDisks[].name"); do
  info "Detaching and deleting ${old}, left over from an earlier restore..."
  az vm disk detach -g "$RG" --vm-name "$VM" --name "$old" --output none
  az disk delete -g "$RG" -n "$old" --yes --output none
done
if [[ -z "$(az_q storage account show -g "$RG" -n "$STAGING" --query name)" ]]; then
  az storage account create -g "$RG" -n "$STAGING" -l "$LOCATION" \
    --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --output none
fi
rp="$(az backup recoverypoint list -g "$RG" --vault-name "$VAULT" -c "$VM" -i "$VM" \
  --backup-management-type AzureIaasVM --query "sort_by(@, &properties.recoveryPointTime)[-1].name" --output tsv)"
info "Restoring the OS disk from recovery point ${rp} (5-15 minutes)..."
rjob="$(az backup restore restore-disks -g "$RG" --vault-name "$VAULT" -c "$VM" -i "$VM" \
  --rp-name "$rp" --storage-account "$STAGING" --target-resource-group "$RG" \
  --restore-only-osdisk true --query name --output tsv)"
az backup job wait -g "$RG" --vault-name "$VAULT" --name "$rjob" --timeout 3600 >/dev/null || true
rstate="$(az_q backup job show -g "$RG" --vault-name "$VAULT" --name "$rjob" --query properties.status)"
if [[ "$rstate" != "Completed" ]]; then
  echo "Restore job ${rjob} ended as '${rstate:-unknown}'. Open it in the portal (vault › Backup jobs)." >&2
  exit 1
fi
disk="$(az disk list -g "$RG" --query "sort_by([?diskState=='Unattached'], &timeCreated)[-1].name" --output tsv)"
info "Attaching restored disk ${disk} to ${VM} at LUN 0..."
az vm disk attach -g "$RG" --vm-name "$VM" --name "$disk" --lun 0 --output none
out="$(vm_run @"${LAB_DIR}/vm/recover-orders.sh" || true)"
while IFS= read -r line; do info "$line"; done < <(grep -E "RESTORE_|Restored|Copied" <<<"$out" || true)
info "Detaching and deleting ${disk}..."
az vm disk detach -g "$RG" --vm-name "$VM" --name "$disk" --output none
az disk delete -g "$RG" -n "$disk" --yes --no-wait --output none

status="$(vm_status)"
if [[ "$status" == "ORDERS_OK" ]]; then
  pass "The orders file is back and identical to the original."
else
  echo "The orders file is not back yet (${status:-unknown}). See Troubleshooting in README.md." >&2
  exit 1
fi
info "Done. Run 'bash verify.sh' to check, and 'bash cleanup.sh' when you have finished."
