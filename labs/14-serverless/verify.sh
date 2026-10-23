#!/usr/bin/env bash
# =============================================================================
# Lab 14 · verify.sh — checks the Challenge brief.
#     bash verify.sh
# It sends one test order (orderId VERIFY-hhmmss) to your function; apart from
# that queue message it changes nothing.
# =============================================================================
set -uo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Function app ${FUNC}"
state="$(az_q functionapp show -g "$RG" -n "$FUNC" --query state)"
check_eq "Function app ${FUNC} exists and is Running" "Running" "$state"
plan_id="$(az_q functionapp show -g "$RG" -n "$FUNC" --query serverFarmId)"
plan_sku=""
[[ -n "$plan_id" ]] && plan_sku="$(az_q appservice plan show --ids "$plan_id" --query "[sku.name, sku.tier]" | tr '\n\t' '  ')"
if [[ "${plan_sku,,}" == *flex* || "${plan_sku,,}" == *fc1* ]]; then
  pass "It runs on the Flex Consumption plan"
else
  fail "It runs on the Flex Consumption plan (found: ${plan_sku:-unknown})"
fi
fn="$(az_q functionapp function show -g "$RG" -n "$FUNC" --function-name new_order --query name)"
check_nonempty "Function new_order is deployed" "$fn"

banner "Connection ${CONNECTION}"
settings="$(az_q functionapp config appsettings list -g "$RG" -n "$FUNC" --query "[].name")"
if grep -qx "${CONNECTION}__queueServiceUri" <<<"$settings"; then
  pass "Connection ${CONNECTION} uses the managed identity (${CONNECTION}__queueServiceUri)"
elif grep -qx "${CONNECTION}" <<<"$settings"; then
  pass "Connection ${CONNECTION} is set (connection string)"
  note "A managed identity connection (${CONNECTION}__queueServiceUri) would avoid storing a secret."
else
  fail "App setting ${CONNECTION}__queueServiceUri is missing (Task 3)"
fi

banner "A test order"
order_url="$(az_q functionapp function show -g "$RG" -n "$FUNC" --function-name new_order --query invokeUrlTemplate)"
key="$(az_q functionapp function keys list -g "$RG" -n "$FUNC" --function-name new_order --query default)"
code=""
if [[ -n "$order_url" && -n "$key" ]]; then
  body='{"orderId":"VERIFY-'"$(date +%H%M%S)"'","store":"verify.sh","items":[{"sku":"TEST","qty":1}]}'
  for attempt in 1 2 3; do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 60 -X POST "$order_url" \
      -H "x-functions-key: ${key}" -H 'Content-Type: application/json' -d "$body" 2>/dev/null || true)"
    [[ "$code" == "200" || "$attempt" == "3" ]] && break
    info "Attempt ${attempt}: HTTP ${code:-no answer}. Waiting 15 s (the app may be starting from zero)..."
    sleep 15
  done
else
  info "Could not read the function URL or key."
fi
check_eq "POST /api/orders with a valid order returns HTTP 200" "200" "$code"

banner "Queue ${QUEUE}"
count="$(az_q storage message peek --queue-name "$QUEUE" --account-name "$ST" --auth-mode key \
  --num-messages 32 --query "length(@)")"
check_ge "Queue '${QUEUE}' in ${ST} holds at least one order message" 1 "$count"

banner "Logic App ${LOGIC}"
la_state="$(az_q resource show -g "$RG" -n "$LOGIC" --resource-type Microsoft.Logic/workflows --query properties.state)"
check_eq "Logic App ${LOGIC} exists and is Enabled" "Enabled" "$la_state"
la_id="$(az_q resource show -g "$RG" -n "$LOGIC" --resource-type Microsoft.Logic/workflows --query id)"
if [[ -n "$la_id" ]]; then
  last="$(az_q rest --method get --url "https://management.azure.com${la_id}/runs?api-version=2016-06-01" \
    --query "value[0].properties.status")"
  if [[ "$last" == "Succeeded" ]]; then
    info "Latest run: Succeeded"
  elif [[ -n "$last" ]]; then
    note "Latest run: ${last}. Open the run history to see which step failed."
  else
    note "No runs yet. Start one (Task 6) or wait up to 15 minutes for the schedule."
  fi
fi

summary
