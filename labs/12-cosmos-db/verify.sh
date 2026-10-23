#!/usr/bin/env bash
# =============================================================================
# Lab 12 · verify.sh — checks the Challenge brief.
#     bash verify.sh
# Read-only: it changes nothing. The item count goes through app/query_products.py,
# so the Python SDK from Task 4 must be installed.
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

banner "Cosmos DB account"
acct="$(az_q cosmosdb show -g "$RG" -n "$ACCOUNT" --query name)"
if [[ -z "$acct" ]]; then
  acct="$(az_q cosmosdb list -g "$RG" --query "[0].name")"
  [[ -n "$acct" ]] && note "Checking account ${acct} (the guide's name is ${ACCOUNT})."
fi
check_nonempty "A Cosmos DB account exists in ${RG} (Task 1)" "$acct"
if [[ -z "$acct" ]]; then
  summary
  exit $?
fi

kind="$(az_q cosmosdb show -g "$RG" -n "$acct" --query kind)"
caps="$(az_q cosmosdb show -g "$RG" -n "$acct" --query "capabilities[].name" | tr '\n' ' ')"
other_api_re="Enable(Cassandra|Gremlin|Table|Mongo)"
if [[ "$kind" == "GlobalDocumentDB" && ! "$caps" =~ $other_api_re ]]; then
  pass "The account uses the API for NoSQL"
else
  fail "The account uses the API for NoSQL (found kind '${kind:-?}', capabilities '${caps:-none}')"
fi
free="$(az_q cosmosdb show -g "$RG" -n "$acct" --query enableFreeTier)"
if [[ "$caps" == *EnableServerless* ]]; then
  pass "Capacity mode: serverless"
elif is_true "$free"; then
  pass "Capacity mode: provisioned throughput with the free tier"
else
  fail "Capacity mode is serverless or free tier (this account bills provisioned RU/s every hour)"
fi
consistency="$(az_q cosmosdb show -g "$RG" -n "$acct" --query consistencyPolicy.defaultConsistencyLevel)"
check_eq "Default consistency is Session (Task 6 puts it back)" "Session" "$consistency"

banner "Database ${DATABASE} and container ${CONTAINER}"
db="$(az_q cosmosdb sql database show -a "$acct" -g "$RG" -n "$DATABASE" --query name)"
check_eq "Database ${DATABASE} exists (Task 2)" "$DATABASE" "$db"
pk="$(az_q cosmosdb sql container show -a "$acct" -g "$RG" -d "$DATABASE" -n "$CONTAINER" \
  --query "resource.partitionKey.paths[0]")"
check_eq "Container ${CONTAINER} is partitioned by ${PARTITION_KEY} (Task 2)" "$PARTITION_KEY" "$pk"

banner "Data access"
me="$(my_object_id)"
role_id="$(az_q cosmosdb sql role definition list -a "$acct" -g "$RG" \
  --query "[?roleName=='${DATA_ROLE}'].id | [0]")"
mine="$(az_q cosmosdb sql role assignment list -a "$acct" -g "$RG" \
  --query "[?principalId=='${me}'].roleDefinitionId")"
if [[ -n "$me" && -n "$role_id" ]] && grep -qiF -- "$role_id" <<<"$mine"; then
  pass "You hold ${DATA_ROLE} on the account (Task 3)"
elif [[ -n "${COSMOS_KEY:-}" ]]; then
  note "No data-plane role for you; the scripts use the key fallback (COSMOS_KEY). Entra ID access is preferred."
else
  fail "You hold ${DATA_ROLE} on the account (Task 3)"
fi

endpoint="$(az_q cosmosdb show -g "$RG" -n "$acct" --query documentEndpoint)"
out="$(COSMOS_ENDPOINT="$endpoint" python3 "${LAB_DIR}/app/query_products.py" count 2>&1)"
rc=$?
count=""
if (( rc == 0 )); then
  count="$(tail -n 1 <<<"$out")"
else
  while IFS= read -r line; do info "$line"; done < <(head -n 4 <<<"$out")
fi
check_ge "Container ${CONTAINER} holds at least 20 items (Task 4)" 20 "$count"

summary
