#!/usr/bin/env bash
# =============================================================================
# Lab 30 · Verify your work (checks the Challenge brief).
# Read-only: safe to run as often as you like.
# The last section counts rows per table. Those lines are notes, not failures:
# a brand-new pipeline can take 5-15 minutes to deliver its first rows.
#   bash verify.sh
# =============================================================================
set -uo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Starting point (setup.sh)"
check "Resource group ${RG} exists" az group show --name "$RG"
LAW_ID="$(az_q monitor log-analytics workspace show --resource-group "$RG" --workspace-name "$LAW" --query id)"
LAW_GUID="$(az_q monitor log-analytics workspace show --resource-group "$RG" --workspace-name "$LAW" --query customerId)"
check_nonempty "Log Analytics workspace ${LAW} exists" "$LAW_ID"
VM_ID="$(az_q vm show --resource-group "$RG" --name "$VM" --query id)"
check_nonempty "VM ${VM} exists" "$VM_ID"
ST_ID="$(az_q storage account show --resource-group "$RG" --name "$ST" --query id)"
check_nonempty "Storage account ${ST} exists" "$ST_ID"
HOST="$(az_q webapp show --resource-group "$RG" --name "$APP" --query defaultHostName)"
check_nonempty "Web app ${APP} exists" "$HOST"

banner "Task 2 · Managed identity and the Azure Monitor Agent"
check_contains "${VM} has a system-assigned managed identity" "SystemAssigned" \
  "$(az_q vm show --resource-group "$RG" --name "$VM" --query identity.type)"
check_eq "AzureMonitorLinuxAgent extension is provisioned" "Succeeded" \
  "$(az_q vm extension show --resource-group "$RG" --vm-name "$VM" --name AzureMonitorLinuxAgent --query provisioningState)"
if [[ "$(az_q vm extension list --resource-group "$RG" --vm-name "$VM" --query "[?name=='OmsAgentForLinux'] | length(@)")" =~ ^[1-9] ]]; then
  note "The retired Log Analytics agent (OmsAgentForLinux) is installed. Remove it: the Azure Monitor Agent replaces it."
fi

banner "Task 3 · Data collection rule and association"
mapfile -t rule_ids < <(az_q monitor data-collection rule association list --resource "${VM_ID:-none}" \
  --query "[].[dataCollectionRuleId || properties.dataCollectionRuleId] | []" | sed '/^$/d;/^None$/d')
check_ge "${VM} is associated with at least one data collection rule" 1 "${#rule_ids[@]}"

# Pick the associated rule to inspect: the one named ${DCR} if present, otherwise the first.
rule_id=""
for id in ${rule_ids[@]+"${rule_ids[@]}"}; do
  [[ -z "$rule_id" ]] && rule_id="$id"
  [[ "${id,,}" == *"/datacollectionrules/${DCR,,}" ]] && rule_id="$id"
done
dcr_q() { [[ -n "$rule_id" ]] && az_q monitor data-collection rule show --ids "$rule_id" --query "$1"; }
levels="$(dcr_q "(dataSources || properties.dataSources).syslog[].logLevels[]" | tr '\n' ' ')"
levels="${levels% }"
if [[ " ${levels,,} " == *" warning "* || "$levels" == *"*"* ]]; then
  pass "The rule collects Syslog at Warning level (levels: ${levels})"
else
  fail "The rule collects Syslog at Warning level (levels: ${levels:-none}) — see Break it and fix it"
fi
check_ge "The rule collects performance counters" 1 \
  "$(dcr_q "length((dataSources || properties.dataSources).performanceCounters[].counterSpecifiers[])")"
check_contains "The rule sends its data to ${LAW}" "${LAW_ID:-<no workspace>}" \
  "$(dcr_q "(destinations || properties.destinations).logAnalytics[].workspaceResourceId")"

banner "Task 4 · Diagnostic setting for the blob service"
diag_q() {
  [[ -n "$ST_ID" ]] && az_q monitor diagnostic-settings list --resource "${ST_ID}/blobServices/default" --query "$1"
}
check_contains "A diagnostic setting sends blob logs to ${LAW}" "${LAW_ID:-<no workspace>}" \
  "$(diag_q "(value || @)[].workspaceId")"
check_ge "It enables the allLogs category group" 1 \
  "$(diag_q "length((value || @)[?logs[?categoryGroup=='allLogs' && enabled]])")"

banner "Task 5 · Application Insights and the availability test"
appi_q() { az_q monitor app-insights component show --app "$APPI" --resource-group "$RG" --query "$1"; }
APPI_ID="$(appi_q id)"
check_nonempty "Application Insights ${APPI} exists" "$APPI_ID"
check_contains "${APPI} is workspace-based and uses ${LAW}" "${LAW_ID:-<no workspace>}" \
  "$(appi_q "workspaceResourceId || properties.WorkspaceResourceId")"
setting() {
  az_q webapp config appsettings list --resource-group "$RG" --name "$APP" --query "[?name=='$1'].value | [0]"
}
check_eq "Autoinstrumentation is on (ApplicationInsightsAgent_EXTENSION_VERSION = ~3)" "~3" \
  "$(setting ApplicationInsightsAgent_EXTENSION_VERSION)"
ikey="$(appi_q "instrumentationKey || properties.InstrumentationKey")"
check_contains "The web app's connection string points at ${APPI}" "${ikey:-<no instrumentation key>}" \
  "$(setting APPLICATIONINSIGHTS_CONNECTION_STRING)"
tests="$(az_q monitor app-insights web-test list --resource-group "$RG" \
  --query "[?contains(to_string(tags), '${APPI}')].[name, webTestKind || properties.Kind, to_string(enabled || properties.Enabled)]")"
if grep -qiP '\tstandard\ttrue$' <<< "$tests"; then
  pass "An enabled standard availability test is linked to ${APPI} ($(grep -iP '\tstandard\ttrue$' <<< "$tests" | cut -f1 | head -1))"
else
  fail "An enabled standard availability test is linked to ${APPI} (found: ${tests:-none})"
fi

banner "Task 7 · Log search alert"
sq() { az_q monitor scheduled-query show --resource-group "$RG" --name "$ALERT" --query "$1"; }
check_nonempty "Log search alert ${ALERT} exists" "$(sq id)"
check_eq "${ALERT} is enabled" "true" "$(sq "enabled || properties.enabled")"
check_contains "${ALERT} queries AppRequests" "AppRequests" \
  "$(sq "(criteria || properties.criteria).allOf[0].query")"
scope="$(sq "(scopes || properties.scopes)[0]")"
if [[ -n "$scope" && ( "${scope,,}" == "${LAW_ID,,}" || "${scope,,}" == "${APPI_ID,,}" ) ]]; then
  pass "${ALERT} is scoped to ${LAW} or ${APPI}"
else
  fail "${ALERT} is scoped to ${LAW} or ${APPI} (scope: ${scope:-none})"
fi

banner "Data arriving in ${LAW} (notes only)"
rows() {
  local n
  n="$(az_q monitor log-analytics query --workspace "${LAW_GUID:-none}" --analytics-query "$1 | count" --query "[0].Count")"
  [[ "$n" =~ ^[0-9]+$ ]] && echo "$n" || echo "?"
}
report() {
  local label="$1" n
  n="$(rows "$2")"
  if [[ "$n" == "?" ]]; then
    note "${label}: couldn't run the query (is the log-analytics CLI extension installed?)"
  elif (( n > 0 )); then
    info "✔ ${label}: ${n} rows"
  else
    note "${label}: no rows yet — wait 5-15 minutes after setting up the pipe, then run verify.sh again"
  fi
}
report "Agent heartbeats from ${VM} (last 30 min)" \
  "Heartbeat | where TimeGenerated > ago(30m) and Category == 'Azure Monitor Agent' and Computer =~ '${VM}'"
report "Syslog warnings (last 4 h)" "Syslog | where TimeGenerated > ago(4h) and SeverityLevel =~ 'warning'"
report "Performance counters (last 30 min)" "Perf | where TimeGenerated > ago(30m)"
report "Blob storage logs (last 4 h)" "StorageBlobLogs | where TimeGenerated > ago(4h)"
report "Storefront requests (last 4 h)" "AppRequests | where TimeGenerated > ago(4h)"
report "Availability test results (last 4 h)" "AppAvailabilityResults | where TimeGenerated > ago(4h)"

summary
