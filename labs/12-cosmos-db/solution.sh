#!/usr/bin/env bash
# =============================================================================
# Lab 12 · solution.sh — builds the whole lab in one go (Tasks 1-6).
#     bash solution.sh
# Safe to re-run: every step checks what already exists. Takes about 10 minutes,
# most of it waiting for the Cosmos DB account.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

is_true() { [[ "${1,,}" == "true" ]]; }

banner "Task 1 · Serverless account ${ACCOUNT}"
info "Registering the Microsoft.DocumentDB resource provider (quick if it's already registered)..."
az provider register --namespace Microsoft.DocumentDB --wait --output none
ensure_rg "$RG" 12
if az cosmosdb show -g "$RG" -n "$ACCOUNT" --output none 2>/dev/null; then
  info "Account ${ACCOUNT} already exists."
else
  info "Creating account ${ACCOUNT} in ${LOCATION} (3-10 minutes)..."
  az cosmosdb create \
    --name "$ACCOUNT" \
    --resource-group "$RG" \
    --kind GlobalDocumentDB \
    --locations regionName="$LOCATION" failoverPriority=0 isZoneRedundant=False \
    --capabilities EnableServerless \
    --default-consistency-level Session \
    --output none
fi

banner "Task 2 · Database ${DATABASE} and container ${CONTAINER}"
if is_true "$(az_q cosmosdb sql database exists -a "$ACCOUNT" -g "$RG" -n "$DATABASE")"; then
  info "Database ${DATABASE} already exists."
else
  az cosmosdb sql database create -a "$ACCOUNT" -g "$RG" -n "$DATABASE" --output none
fi
if is_true "$(az_q cosmosdb sql container exists -a "$ACCOUNT" -g "$RG" -d "$DATABASE" -n "$CONTAINER")"; then
  info "Container ${CONTAINER} already exists."
else
  az cosmosdb sql container create -a "$ACCOUNT" -g "$RG" -d "$DATABASE" -n "$CONTAINER" \
    --partition-key-path "$PARTITION_KEY" --output none
fi

banner "Task 3 · Data-plane role for you"
me="$(my_object_id || true)"
if [[ -z "$me" ]]; then
  echo "Could not read your object ID (az ad signed-in-user show). Sign in as a user and try again." >&2
  exit 1
fi
role_id="$(az_q cosmosdb sql role definition list -a "$ACCOUNT" -g "$RG" \
  --query "[?roleName=='${DATA_ROLE}'].id | [0]")"
existing="$(az_q cosmosdb sql role assignment list -a "$ACCOUNT" -g "$RG" \
  --query "[?principalId=='${me}'].roleDefinitionId")"
if [[ -n "$role_id" ]] && grep -qiF -- "$role_id" <<<"$existing"; then
  info "You already hold ${DATA_ROLE}."
else
  az cosmosdb sql role assignment create -a "$ACCOUNT" -g "$RG" --scope "/" \
    --principal-id "$me" --role-definition-name "$DATA_ROLE" --output none
  info "Assigned ${DATA_ROLE}. It can take a few minutes to take effect."
fi

banner "Task 4 · SDK and products"
if ! python3 -c "import azure.cosmos, azure.identity" 2>/dev/null; then
  info "Installing azure-cosmos and azure-identity into your home directory..."
  python3 -m pip install --user --quiet azure-cosmos azure-identity
fi
export COSMOS_ENDPOINT
COSMOS_ENDPOINT="$(az cosmosdb show -g "$RG" -n "$ACCOUNT" --query documentEndpoint --output tsv)"
loaded=0
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  rc=0
  python3 "${LAB_DIR}/app/load_products.py" || rc=$?
  if (( rc == 0 )); then loaded=1; break; fi
  if (( rc != 3 )); then exit "$rc"; fi
  info "Attempt ${attempt}: access not granted yet (role assignments take a few minutes). Waiting 30 s..."
  sleep 30
done
if (( loaded == 0 )); then
  echo "The data-plane role still isn't effective. Wait a few minutes and run solution.sh again." >&2
  exit 3
fi

banner "Task 5 · Point read vs queries"
python3 "${LAB_DIR}/app/query_products.py" compare

banner "Task 6 · Default consistency"
current="$(az_q cosmosdb show -g "$RG" -n "$ACCOUNT" --query consistencyPolicy.defaultConsistencyLevel)"
if [[ "$current" != "Session" ]]; then
  info "Setting the default consistency back to Session (was ${current:-unknown})..."
  az cosmosdb update -g "$RG" -n "$ACCOUNT" --default-consistency-level Session --output none
fi
info "Default consistency: Session. Try: python3 app/query_products.py read p-coffee-001 coffee --consistency Eventual"

banner "Break it and fix it"
python3 "${LAB_DIR}/app/query_products.py" query \
  "SELECT c.id, c.category, c.name, c.price FROM c WHERE c.category = 'coffee' AND CONTAINS(c.name, 'kopi', true)" \
  --pk coffee

info "Done. Run 'bash verify.sh' to check, and 'bash cleanup.sh' when you have finished."
