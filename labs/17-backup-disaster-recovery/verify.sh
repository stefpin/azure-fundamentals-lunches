#!/usr/bin/env bash
# =============================================================================
# Lab 17 · verify.sh — checks the Challenge brief.
#     bash verify.sh
# Read-only: it changes nothing. One check runs vm/check-orders.sh inside the VM
# through Run Command, so the whole script takes a minute or two.
# =============================================================================
set -uo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

is_true() { [[ "${1,,}" == "true" ]]; }

banner "Resource group ${RG}"
rg_state="$(az_q group show -n "$RG" --query properties.provisioningState)"
check_eq "Resource group ${RG} exists" "Succeeded" "$rg_state"

banner "Recovery Services vault"
vault="$(az_q backup vault show -g "$RG" -n "$VAULT" --query name)"
if [[ -z "$vault" ]]; then
  vault="$(az_q backup vault list -g "$RG" --query "[0].name")"
  [[ -n "$vault" ]] && note "Checking vault ${vault} (the guide's name is ${VAULT})."
fi
check_nonempty "A Recovery Services vault exists in ${RG} (Task 2)" "$vault"
if [[ -z "$vault" ]]; then
  summary
  exit $?
fi
vault_location="$(az_q backup vault show -g "$RG" -n "$vault" --query location)"
vm_location="$(az_q vm show -g "$RG" -n "$VM" --query location)"
check_eq "The vault is in the VM's region (Task 2)" "${vm_location:-<no VM>}" "$vault_location"

soft="$(az_q backup vault show -g "$RG" -n "$vault" --query properties.securitySettings.softDeleteSettings.softDeleteState)"
if [[ -z "$soft" ]]; then
  soft="$(az_q resource show -g "$RG" -n "$vault" --resource-type Microsoft.RecoveryServices/vaults \
    --query properties.securitySettings.softDeleteSettings.softDeleteState)"
fi
case "${soft,,}" in
  alwayson|enabled) pass "Soft delete is on (${soft})" ;;
  "") note "Could not read the soft-delete state of ${vault}." ;;
  *) fail "Soft delete is on (found '${soft}'). Switch it back on: Task 3" ;;
esac
redundancy="$(az_q backup vault show -g "$RG" -n "$vault" \
  --query properties.redundancySettings.standardTierStorageRedundancy)"
if [[ "$redundancy" == "LocallyRedundant" ]]; then
  pass "Backup storage is locally redundant (Task 2)"
else
  note "Backup storage redundancy is '${redundancy:-unknown}'. Fine, but a lab only needs LocallyRedundant."
fi

banner "Protection of ${VM}"
item_q() {
  az_q backup item list -g "$RG" --vault-name "$vault" --backup-management-type AzureIaasVM \
    --query "[?properties.friendlyName=='${VM}'] | [0].properties.$1"
}
state="$(item_q protectionState)"
policy="$(item_q policyName)"
if is_true "$(item_q isScheduledForDeferredDelete)"; then
  fail "${VM} is protected (its backup data is soft-deleted: see Break it and fix it)"
elif [[ "$state" == "Protected" ]]; then
  pass "${VM} is protected by ${vault} (Task 4)"
elif [[ "$state" == "IRPending" ]]; then
  pass "${VM} is protected by ${vault} (Task 4)"
  note "The first backup hasn't finished yet (IRPending). That's fine once a recovery point exists."
else
  fail "${VM} is protected by ${vault} (found '${state:-not protected}'): Task 4"
fi
if [[ "$policy" == "$POLICY" ]]; then
  pass "The backup policy is ${POLICY}"
elif [[ -n "$policy" ]]; then
  note "The VM uses policy '${policy}' instead of ${POLICY}. Accepted."
fi
points="$(az_q backup recoverypoint list -g "$RG" --vault-name "$vault" -c "$VM" -i "$VM" \
  --backup-management-type AzureIaasVM --query "length(@)")"
check_ge "At least one recovery point exists for ${VM} (Task 5)" 1 "$points"

banner "The restore"
restores="$(az_q backup job list -g "$RG" --vault-name "$vault" --operation Restore --status Completed \
  --query "length(@)")"
check_ge "A restore job completed (Task 7)" 1 "$restores"
out="$(az_q vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript \
  --scripts @"${LAB_DIR}/vm/check-orders.sh" --query "value[0].message")"
status="$(grep -o "ORDERS_OK\|ORDERS_MISSING\|ORDERS_CHANGED\|NO_FINGERPRINT" <<<"$out" | head -n 1)"
[[ -z "$status" ]] && info "Run Command didn't answer. Is ${VM} running? Is another Run Command still busy?"
check_eq "/data/orders.csv is back and identical to the original (Tasks 6-7)" "ORDERS_OK" "$status"

summary
