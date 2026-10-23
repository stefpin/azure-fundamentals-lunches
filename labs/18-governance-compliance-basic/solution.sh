#!/usr/bin/env bash
# =============================================================================
# Lab 18 · reference solution (Tasks 1–8), end to end.
#   bash setup.sh && bash solution.sh     (about 25–40 minutes, mostly waiting)
# Safe to re-run: existing assignments, resources and remediation tasks are kept.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
require_az
source "${LAB_DIR}/lab-vars.sh"

if ! az group show --name "$RG" --output none 2>/dev/null; then
  echo "Resource group ${RG} not found. Run 'bash setup.sh' first."
  exit 1
fi

# wait_for_deny <label> <extra arguments for az deployment group validate>
# Validates (never deploys) policy-probe.json until Azure Policy rejects it.
wait_for_deny() {
  local label="$1" i out
  shift
  for i in $(seq 1 40); do
    out="$(az deployment group validate --resource-group "$RG" --template-file "${LAB_DIR}/policy-probe.json" \
      "$@" --only-show-errors --output none 2>&1 || true)"
    if grep -qiE "RequestDisallowedByPolicy|disallowed by policy|policy violation" <<<"$out"; then
      info "${label}: enforced."
      return 0
    elif [[ -n "$out" ]]; then
      echo "$out"
      return 1
    fi
    info "${label}: not enforced yet (check ${i} of 40) — next check in 30 seconds..."
    sleep 30
  done
  return 1
}

# expect_denied <description> <az arguments...>  -> runs a command that policy must refuse
expect_denied() {
  local d="$1" out
  shift
  if out="$(az "$@" --output none 2>&1)"; then
    note "Unexpected: '${d}' succeeded. The policy was not enforced yet; the extra resource is removed by cleanup.sh."
  elif grep -q "RequestDisallowedByPolicy" <<<"$out"; then
    info "✔ Refused as expected (${d}): RequestDisallowedByPolicy"
    grep -o "Resource '[^']*' was disallowed by policy" <<<"$out" | head -n 1 | sed 's/^/     /' || true
  else
    echo "$out"
    note "'${d}' failed, but not because of policy. Read the error above."
  fi
}

# ensure_identity_role <assignment name> -> the assignment's identity gets Contributor on the RG
ensure_identity_role() {
  local name="$1" pid count i
  pid="$(az_q policy assignment show --name "$name" --scope "$RG_ID" --query identity.principalId)"
  if [[ -z "$pid" ]]; then
    echo "Assignment ${name} has no managed identity."
    return 1
  fi
  for i in $(seq 1 6); do
    count="$(az_q role assignment list --scope "$RG_ID" --query "length([?principalId=='${pid}'])")"
    if [[ "${count:-0}" -ge 1 ]]; then
      info "Managed identity ${pid} holds a role on ${RG}."
      return 0
    fi
    info "Granting Contributor on ${RG} to the managed identity (attempt ${i})..."
    if az role assignment create --assignee-object-id "$pid" --assignee-principal-type ServicePrincipal \
        --role Contributor --scope "$RG_ID" --output none 2>/dev/null; then
      return 0
    fi
    sleep 20   # a brand-new identity can take a moment to replicate in Microsoft Entra ID
  done
  return 1
}

banner "Task 1 · Look up the built-in definitions by display name"
lookup_builtin_ids
if [[ -z "$ALLOWED_LOCATIONS_ID" || -z "$REQUIRE_TAG_ID" || -z "$INHERIT_TAG_ID" ]]; then
  echo "Could not find all three built-in definitions. Check that 'az policy definition list' works."
  exit 1
fi
info "Allowed locations                               -> ${ALLOWED_LOCATIONS_ID}"
info "Require a tag on resources                      -> ${REQUIRE_TAG_ID}"
info "Inherit a tag from the resource group if missing -> ${INHERIT_TAG_ID}"

banner "Task 2 · Assign Allowed locations (${LOCATION} only)"
if az policy assignment show --name "$A_LOCATIONS" --scope "$RG_ID" --output none 2>/dev/null; then
  info "Assignment ${A_LOCATIONS} already exists."
else
  az policy assignment create --name "$A_LOCATIONS" --display-name "Lunch 18 - Allowed locations" \
    --scope "$RG_ID" --policy "$ALLOWED_LOCATIONS_ID" \
    --params "{ 'listOfAllowedLocations': { 'value': [ '${LOCATION}' ] } }" --output none
  az policy assignment non-compliance-message create --name "$A_LOCATIONS" --scope "$RG_ID" \
    --message "Nusantara Retail keeps lab resources in ${LOCATION}. Please choose that region." --output none
  info "Created ${A_LOCATIONS}."
fi

banner "Task 3 · Assign Require a tag on resources (costCenter)"
if az policy assignment show --name "$A_REQUIRE_TAG" --scope "$RG_ID" --output none 2>/dev/null; then
  info "Assignment ${A_REQUIRE_TAG} already exists."
else
  az policy assignment create --name "$A_REQUIRE_TAG" --display-name "Lunch 18 - Require costCenter tag" \
    --scope "$RG_ID" --policy "$REQUIRE_TAG_ID" \
    --params "{ 'tagName': { 'value': 'costCenter' } }" --output none
  info "Created ${A_REQUIRE_TAG}."
fi

banner "Task 4 · Assign Inherit a tag from the resource group if missing (Modify + managed identity)"
if az policy assignment show --name "$A_INHERIT_TAG" --scope "$RG_ID" --output none 2>/dev/null; then
  info "Assignment ${A_INHERIT_TAG} already exists."
else
  if ! az policy assignment create --name "$A_INHERIT_TAG" --display-name "Lunch 18 - Inherit costCenter from the resource group" \
      --scope "$RG_ID" --policy "$INHERIT_TAG_ID" \
      --params "{ 'tagName': { 'value': 'costCenter' } }" \
      --mi-system-assigned --location "$LOCATION" --identity-scope "$RG_ID" --role Contributor --output none; then
    note "The assignment may exist without its role assignment — checking and fixing that next."
  fi
  info "Created ${A_INHERIT_TAG}."
fi
ensure_identity_role "$A_INHERIT_TAG"

banner "Task 5 · Wait for the guardrails, then prove the denials"
info "New assignments take about five minutes (sometimes longer) to reach their scope."
wait_for_deny "Allowed locations" --parameters location="$DENIED_LOCATION"
expect_denied "storage account in ${DENIED_LOCATION}" storage account create --name "$DENIED_SA" \
  --resource-group "$RG" --location "$DENIED_LOCATION" --sku Standard_LRS --tags costCenter="$COST_CENTER"

rg_cost_center="$(az_q group show --name "$RG" --query "tags.costCenter")"
if [[ -n "$rg_cost_center" ]]; then
  note "The resource group is already tagged (re-run?), so Modify would add the tag — skipping the tag denial test."
else
  wait_for_deny "Require a tag on resources" --parameters location="$LOCATION" tags='{}'
  expect_denied "network security group without tags" network nsg create --name nsg-untagged \
    --resource-group "$RG" --location "$LOCATION"
fi

banner "Task 6 · Create compliant resources"
if az storage account show --name "$COMPLIANT_SA" --resource-group "$RG" --output none 2>/dev/null; then
  info "Storage account ${COMPLIANT_SA} already exists."
else
  az storage account create --name "$COMPLIANT_SA" --resource-group "$RG" --location "$LOCATION" \
    --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false \
    --tags costCenter="$COST_CENTER" --output none
  info "Created ${COMPLIANT_SA} with costCenter=${COST_CENTER}."
fi

info "Tagging the resource group costCenter=${COST_CENTER} (Merge keeps the existing tags)..."
az tag update --resource-id "$RG_ID" --operation Merge --tags costCenter="$COST_CENTER" --output none

info "Creating nsg-app WITHOUT tags — the Modify rule should add costCenter from the resource group..."
for i in $(seq 1 10); do
  if az network nsg create --name nsg-app --resource-group "$RG" --location "$LOCATION" --output none 2>/dev/null; then
    break
  fi
  info "Not accepted yet (the new resource-group tag can take a moment to be seen) — retrying in 30 seconds..."
  sleep 30
done
info "nsg-app costCenter tag: $(az_q network nsg show --name nsg-app --resource-group "$RG" --query tags.costCenter)"

banner "Task 7 · Remediate the legacy resources"
INHERIT_ASSIGNMENT_ID="$(az policy assignment show --name "$A_INHERIT_TAG" --scope "$RG_ID" --query id --output tsv)"
if az policy remediation show --name "$REMEDIATION" --resource-group "$RG" --output none 2>/dev/null; then
  info "Remediation task ${REMEDIATION} already exists."
else
  az policy remediation create --name "$REMEDIATION" --resource-group "$RG" \
    --policy-assignment "$INHERIT_ASSIGNMENT_ID" --resource-discovery-mode ReEvaluateCompliance --output none
  info "Created remediation task ${REMEDIATION}."
fi
for i in $(seq 1 40); do
  state="$(az_q policy remediation show --name "$REMEDIATION" --resource-group "$RG" --query provisioningState)"
  info "Remediation state: ${state:-unknown} (check ${i} of 40)"
  case "$state" in
    Succeeded | Failed | Canceled) break ;;
  esac
  sleep 30
done
az resource list --resource-group "$RG" \
  --query "[].{name:name, location:location, costCenter:tags.costCenter}" --output table

banner "Task 8 · Read the compliance results"
info "Starting an on-demand compliance scan of ${RG} (this usually takes a few minutes)..."
az policy state trigger-scan --resource-group "$RG" --output none
az policy state summarize --resource-group "$RG" --query "results || value[0].results" --output jsonc
az policy state list --resource-group "$RG" --filter "complianceState eq 'NonCompliant'" \
  --query "[].{assignment:policyAssignmentName, type:resourceType, location:resourceLocation}" --output table

banner "Done"
info "Now run: bash verify.sh"
