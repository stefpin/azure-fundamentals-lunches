#!/usr/bin/env bash
# =============================================================================
# Lab 16 · Verify your work (checks the Challenge brief).
# Read-only: safe to run as often as you like.
#   bash verify.sh
#   ALERT_EMAIL="you@example.com" bash verify.sh   # also checks the receiver address
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 16)"
VM_NAME="vm-nusa-web"
AG_NAME="ag-nusa-oncall"
SUB_ID="$(az_q account show --query id)"

banner "Starting point (setup.sh)"
check "Resource group ${RG} exists" az group show --name "$RG"
VM_ID="$(az_q vm show --resource-group "$RG" --name "$VM_NAME" --query id)"
check_nonempty "VM ${VM_NAME} exists" "$VM_ID"

banner "Task 2 · Action group"
ag() { az_q monitor action-group show --resource-group "$RG" --name "$AG_NAME" --query "$1"; }
AG_ID="$(ag id)"
check_nonempty "Action group ${AG_NAME} exists" "$AG_ID"
check_eq "${AG_NAME} is enabled" "true" "$(ag enabled)"
check_ge "${AG_NAME} has at least one email receiver" 1 "$(ag 'length(emailReceivers)')"
if [[ -n "${ALERT_EMAIL:-}" ]]; then
  check_contains "An email receiver uses ALERT_EMAIL" "$ALERT_EMAIL" "$(ag 'emailReceivers[].emailAddress')"
fi
receiver_status="$(ag 'emailReceivers[0].status')"
if [[ -n "$receiver_status" && "${receiver_status,,}" != "enabled" ]]; then
  note "The first email receiver's status is '${receiver_status}'. See Troubleshooting: enable-receiver."
fi

banner "Task 3 · CPU metric alert"
ma() { az_q monitor metrics alert show --resource-group "$RG" --name alert-cpu-high --query "$1"; }
check_nonempty "Metric alert alert-cpu-high exists" "$(ma id)"
check_eq "alert-cpu-high is enabled" "true" "$(ma enabled)"
check_contains "alert-cpu-high watches ${VM_NAME}" "/virtualMachines/${VM_NAME}" "$(ma 'scopes[0]')"
check_eq "Metric is Percentage CPU" "Percentage CPU" "$(ma 'criteria.allOf[0].metricName')"
check_eq "Aggregation is Average" "Average" "$(ma 'criteria.allOf[0].timeAggregation')"
check_eq "Operator is GreaterThan" "GreaterThan" "$(ma 'criteria.allOf[0].operator')"
check_eq "Threshold is 70" "true" "$(ma 'criteria.allOf[0].threshold == `70`')"
check_eq "Window (lookback) is 5 minutes" "PT5M" "$(ma windowSize)"
check_ge "alert-cpu-high uses an action group" 1 "$(ma 'length(actions)')"

banner "Task 5 · Service Health alert"
sh_q() { az_q monitor activity-log alert show --resource-group "$RG" --name alert-service-health --query "$1"; }
check_nonempty "Activity log alert alert-service-health exists in ${RG}" "$(sh_q id)"
check_eq "alert-service-health is enabled" "true" "$(sh_q enabled)"
check_eq "It listens to the ServiceHealth category" "ServiceHealth" \
  "$(sh_q "condition.allOf[?field=='category'].equals | [0]")"
check_eq "It is scoped to the whole subscription" "/subscriptions/${SUB_ID}" "$(sh_q 'scopes[0]')"
check_ge "alert-service-health uses an action group" 1 "$(sh_q 'length(actions.actionGroups)')"

banner "Task 6 · Activity log alert for a deallocated VM"
da_q() { az_q monitor activity-log alert show --resource-group "$RG" --name alert-vm-deallocated --query "$1"; }
check_nonempty "Activity log alert alert-vm-deallocated exists" "$(da_q id)"
check_eq "alert-vm-deallocated is enabled" "true" "$(da_q enabled)"
check_contains "It watches the VM deallocate operation" "virtualMachines/deallocate" \
  "$(da_q "condition.allOf[?field=='operationName'].equals | [0]")"
check_ge "alert-vm-deallocated uses an action group" 1 "$(da_q 'length(actions.actionGroups)')"

banner "Break it and fix it"
rz() { az_q monitor metrics alert show --resource-group "$RG" --name alert-cpu-rizky --query "$1"; }
if [[ -n "$(rz id)" ]]; then
  window="$(rz windowSize)"
  aggregation="$(rz 'criteria.allOf[0].timeAggregation')"
  case "${window^^}" in
    PT1M|PT5M|PT15M) pass "alert-cpu-rizky uses a short window (${window})" ;;
    *) fail "alert-cpu-rizky still uses a long window (${window:-unknown}). See 'Break it and fix it'." ;;
  esac
  check_eq "alert-cpu-rizky aggregates with Average" "Average" "$aggregation"
else
  note "alert-cpu-rizky not found. That's fine if you skipped the exercise or deleted the duplicate rule."
fi

banner "Information"
state="$(az_q vm get-instance-view --resource-group "$RG" --name "$VM_NAME" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]")"
info "VM state: ${state:-unknown} (deallocated is fine after Task 6, and cheaper)."
info "Fired alerts are listed in the portal: Monitor > Alerts (filter on resource group ${RG})."

summary
