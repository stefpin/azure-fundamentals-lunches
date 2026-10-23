#!/usr/bin/env bash
# =============================================================================
# Lab 30 · solution.sh — reference solution for Tasks 2-7.
# It also repairs the break-and-fix exercise: the DCR is always written from the
# original dcr-linux-nusa.json, which collects Warning and above.
#
#   bash solution.sh
#   ALERT_EMAIL="you@example.com" bash solution.sh   # also an action group for the alert
#   RUN_TRAFFIC=1 bash solution.sh                   # also runs traffic.sh for 10 minutes
#
# Run setup.sh first. Safe to re-run.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

if ! az group show --name "$RG" --output none 2>/dev/null; then
  echo "Resource group ${RG} wasn't found. Run 'bash setup.sh' first."
  exit 1
fi

LAW_ID="$(az monitor log-analytics workspace show --resource-group "$RG" --workspace-name "$LAW" --query id --output tsv)"
LAW_GUID="$(az monitor log-analytics workspace show --resource-group "$RG" --workspace-name "$LAW" --query customerId --output tsv)"
VM_ID="$(az vm show --resource-group "$RG" --name "$VM" --query id --output tsv)"
ST_ID="$(az storage account show --resource-group "$RG" --name "$ST" --query id --output tsv)"
HOST="$(az webapp show --resource-group "$RG" --name "$APP" --query defaultHostName --output tsv)"
mkdir -p "$OUT_DIR"

# rows "<KQL>"  -> number of rows the query returns (0 when the query fails)
rows() {
  local n
  n="$(az monitor log-analytics query --workspace "$LAW_GUID" --analytics-query "$1 | count" \
        --query "[0].Count" --output tsv 2>/dev/null || true)"
  [[ "$n" =~ ^[0-9]+$ ]] && echo "$n" || echo 0
}

banner "Task 2 · Managed identity and the Azure Monitor Agent"
az vm identity assign --resource-group "$RG" --name "$VM" --output none
az vm extension set \
  --resource-group "$RG" \
  --vm-name "$VM" \
  --name AzureMonitorLinuxAgent \
  --publisher Microsoft.Azure.Monitor \
  --enable-auto-upgrade true \
  --output none
info "Agent: $(az_q vm extension show --resource-group "$RG" --vm-name "$VM" --name AzureMonitorLinuxAgent --query provisioningState)"

banner "Task 3 · Data collection rule ${DCR} and its association"
sed "s|__WORKSPACE_RESOURCE_ID__|${LAW_ID}|" "${LAB_DIR}/dcr-linux-nusa.json" > "${OUT_DIR}/dcr.json"
az monitor data-collection rule create \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --name "$DCR" \
  --rule-file "${OUT_DIR}/dcr.json" \
  --output none
DCR_ID="$(az monitor data-collection rule show --resource-group "$RG" --name "$DCR" --query id --output tsv)"
az monitor data-collection rule association create \
  --name "$DCR_ASSOC" \
  --rule-id "$DCR_ID" \
  --resource "$VM_ID" \
  --output none
info "Associated ${DCR} with ${VM}."
info "Writing three Syslog messages on the VM (warning, info, error)..."
az vm run-command invoke --resource-group "$RG" --name "$VM" --command-id RunShellScript \
  --scripts "logger -p user.warning -t nusa-orders 'Order batch 4471 retry 3/5: payment API slow'; logger -p user.info -t nusa-orders 'Order batch 4471 started'; logger -p user.err -t nusa-orders 'Order batch 4470 failed after 5 retries'" \
  --output none

banner "Task 4 · Diagnostic setting ${DIAG} on the blob service"
az monitor diagnostic-settings create \
  --name "$DIAG" \
  --resource "${ST_ID}/blobServices/default" \
  --workspace "$LAW_ID" \
  --logs '[{"categoryGroup":"allLogs","enabled":true}]' \
  --output none
info "Blob reads, writes and deletes now go to StorageBlobLogs in ${LAW}."

banner "Task 5 · Application Insights ${APPI} and the availability test"
if ! az monitor app-insights component show --app "$APPI" --resource-group "$RG" --output none 2>/dev/null; then
  az monitor app-insights component create \
    --app "$APPI" \
    --resource-group "$RG" \
    --location "$LOCATION" \
    --workspace "$LAW_ID" \
    --application-type web \
    --kind web \
    --tags course="$COURSE_TAG" lunch=30 \
    --output none
fi
APPI_ID="$(az monitor app-insights component show --app "$APPI" --resource-group "$RG" --query id --output tsv)"
CONN="$(az monitor app-insights component show --app "$APPI" --resource-group "$RG" --query connectionString --output tsv)"
az webapp config appsettings set --resource-group "$RG" --name "$APP" \
  --settings "APPLICATIONINSIGHTS_CONNECTION_STRING=${CONN}" \
             "ApplicationInsightsAgent_EXTENSION_VERSION=~3" \
             "OTEL_SERVICE_NAME=nusa-storefront" \
  --output none
info "The web app restarts with autoinstrumentation turned on."

if ! az monitor app-insights web-test show --resource-group "$RG" --name "$WEBTEST" --output none 2>/dev/null; then
  az monitor app-insights web-test create \
    --resource-group "$RG" \
    --name "$WEBTEST" \
    --location "$LOCATION" \
    --web-test-kind standard \
    --defined-web-test-name "$WEBTEST" \
    --synthetic-monitor-id "$WEBTEST" \
    --enabled true \
    --frequency 300 \
    --timeout 30 \
    --retry-enabled true \
    --locations Id=apac-sg-sin-azr \
    --locations Id=apac-hk-hkn-azr \
    --locations Id=apac-jp-kaw-edge \
    --locations Id=emea-au-syd-edge \
    --locations Id=us-ca-sjc-azr \
    --http-verb GET \
    --request-url "https://${HOST}/health" \
    --expected-status-code 200 \
    --tags "hidden-link:${APPI_ID}=Resource" \
    --output none
fi
info "Standard availability test ${WEBTEST} checks https://${HOST}/health every 5 minutes from 5 locations."

banner "Waiting for the first AppRequests rows (usually 3-8 minutes)"
poke_and_check() {
  curl -s -o /dev/null --max-time 15 "https://${HOST}/products" || true
  curl -s -o /dev/null --max-time 20 -X POST "https://${HOST}/checkout" || true
  (( $(rows "AppRequests | where TimeGenerated > ago(1h)") > 0 ))
}
validation_args=()
if wait_until "AppRequests rows in ${LAW}" 900 poke_and_check; then
  info "Application Insights data has arrived."
else
  note "No AppRequests rows yet, so the alert query is created without validation."
  validation_args=(--skip-query-validation true)
fi

banner "Task 7 · Log search alert ${ALERT}"
action_args=()
if [[ -n "${ALERT_EMAIL:-}" ]]; then
  az monitor action-group create \
    --resource-group "$RG" \
    --name "$AG" \
    --short-name nusaoncall \
    --action email oncall-email "$ALERT_EMAIL" usecommonalertschema \
    --output none
  action_args=(--action-groups "$(az monitor action-group show --resource-group "$RG" --name "$AG" --query id --output tsv)")
  info "Action group ${AG} emails ${ALERT_EMAIL}."
else
  info "ALERT_EMAIL isn't set, so the alert shows up in the portal only."
fi
az monitor scheduled-query create \
  --resource-group "$RG" \
  --name "$ALERT" \
  --location "$LOCATION" \
  --scopes "$LAW_ID" \
  --condition "count 'SlowCheckout' > 3 at least 1 violations out of 1 aggregated points" \
  --condition-query SlowCheckout="AppRequests | where Name has 'checkout' and DurationMs > 1000" \
  --window-size 10m \
  --evaluation-frequency 5m \
  --severity 3 \
  --description "More than 3 checkouts slower than 1 second in 10 minutes" \
  ${action_args[@]+"${action_args[@]}"} \
  ${validation_args[@]+"${validation_args[@]}"} \
  --output none
info "Every 5 minutes the rule counts slow checkouts in the last 10 minutes."

if [[ "${RUN_TRAFFIC:-}" == "1" ]]; then
  bash "${LAB_DIR}/traffic.sh" 10
fi

banner "What has arrived so far"
for table in Heartbeat Syslog Perf StorageBlobLogs AppRequests AppExceptions AppTraces AppAvailabilityResults; do
  info "$(printf '%-24s %s rows in the last hour' "$table" "$(rows "${table} | where TimeGenerated > ago(1h)")")"
done
info "Tables that are still empty usually fill within 5-15 minutes. Then run: bash verify.sh"
