#!/usr/bin/env bash
# =============================================================================
# Lab 14 · solution.sh — reference solution for Tasks 2–6 (runs setup.sh first).
#     bash solution.sh
# Safe to re-run. Takes about 10 minutes, mostly waiting for Azure.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

bash "${LAB_DIR}/setup.sh"

banner "Task 2 · Function app ${FUNC} on Flex Consumption"
if az functionapp show -g "$RG" -n "$FUNC" --output none 2>/dev/null; then
  info "The function app already exists."
else
  az functionapp create -g "$RG" -n "$FUNC" \
    --storage-account "$ST" \
    --flexconsumption-location "$LOCATION" \
    --runtime python --runtime-version "$PY_VERSION" \
    --functions-version 4 \
    --instance-memory 2048 \
    --maximum-instance-count 10 \
    --workspace "$LAW" \
    --https-only true \
    --output none
  info "Created ${FUNC}."
fi

banner "Task 3 · Managed identity, queue role and connection setting"
principal_id="$(az functionapp identity assign -g "$RG" -n "$FUNC" --query principalId --output tsv)"
st_id="$(az storage account show -g "$RG" -n "$ST" --query id --output tsv)"
existing="$(az role assignment list --assignee "$principal_id" --scope "$st_id" \
  --role "Storage Queue Data Contributor" --query "length(@)" --output tsv)"
if [[ "$existing" == "0" ]]; then
  az role assignment create --assignee-object-id "$principal_id" --assignee-principal-type ServicePrincipal \
    --role "Storage Queue Data Contributor" --scope "$st_id" --output none
  info "Granted Storage Queue Data Contributor on ${ST}."
fi
queue_uri="$(az storage account show -g "$RG" -n "$ST" --query primaryEndpoints.queue --output tsv)"
az functionapp config appsettings set -g "$RG" -n "$FUNC" \
  --settings "${CONNECTION}__queueServiceUri=${queue_uri%/}" --output none

banner "Task 4 · Deploy the code with a remote build (1–3 minutes)"
mkdir -p "$OUT_DIR"
rm -f "${OUT_DIR}/function.zip"
(cd "${LAB_DIR}/function" && python3 -m zipfile -c "${OUT_DIR}/function.zip" function_app.py host.json requirements.txt)
az functionapp deployment source config-zip -g "$RG" -n "$FUNC" \
  --src "${OUT_DIR}/function.zip" --build-remote true --output none

wait_until "function new_order to appear" 300 \
  az functionapp function show -g "$RG" -n "$FUNC" --function-name new_order || true
order_url="$(az functionapp function show -g "$RG" -n "$FUNC" --function-name new_order \
  --query invokeUrlTemplate --output tsv)"
key=""
for _ in $(seq 1 12); do
  key="$(az_q functionapp function keys list -g "$RG" -n "$FUNC" --function-name new_order --query default)"
  [[ -n "$key" ]] && break
  sleep 10
done
if [[ -z "$key" ]]; then
  echo "Could not read the function key for new_order. Wait a minute and run solution.sh again."
  exit 1
fi

banner "Task 5 · Send a test order"
code=""
for attempt in 1 2 3 4 5 6; do
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 60 -X POST "$order_url" \
    -H "x-functions-key: ${key}" -H 'Content-Type: application/json' \
    -d '{"orderId":"JKT-1001","store":"Jakarta - Kemang","items":[{"sku":"KOPI-TORAJA-250G","qty":2}]}' || true)"
  info "Attempt ${attempt}: HTTP ${code}"
  [[ "$code" == "200" ]] && break
  sleep 20   # a new role assignment can take a few minutes to apply
done

banner "Task 6 · Logic App ${LOGIC}"
sed -e "s|__ORDER_URL__|${order_url}|" -e "s|__FUNCTION_KEY__|${key}|" \
  "${LAB_DIR}/logicapp/workflow.json" > "${OUT_DIR}/workflow.json"
chmod 600 "${OUT_DIR}/workflow.json"
az logic workflow create -g "$RG" -n "$LOGIC" -l "$LOCATION" \
  --definition "${OUT_DIR}/workflow.json" --output none
logic_id="$(az logic workflow show -g "$RG" -n "$LOGIC" --query id --output tsv)"
az rest --method post \
  --url "https://management.azure.com${logic_id}/triggers/Every_15_minutes/run?api-version=2016-06-01" \
  --output none
info "Started one run now; the schedule adds one every 15 minutes."

banner "Done"
info "Check your work with: bash verify.sh"
