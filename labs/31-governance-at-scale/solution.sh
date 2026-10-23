#!/usr/bin/env bash
# =============================================================================
# Lab 31 · reference solution (Tasks 1–9), end to end.
#   bash setup.sh && bash solution.sh                     Path A: your subscription stays where it is
#   bash setup.sh && MOVE_SUBSCRIPTION=yes bash solution.sh
#                                                         Path B: your subscription moves under the corp
#                                                         management group (cleanup.sh moves it back)
# About 25–40 minutes, mostly waiting. Safe to re-run: existing items are kept.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
require_az
source "${LAB_DIR}/lab-vars.sh"
cd "$LAB_DIR"

if ! az group show --name "$CORP_RG" --output none 2>/dev/null || ! az group show --name "$SANDBOX_RG" --output none 2>/dev/null; then
  echo "The lab resource groups were not found. Run 'bash setup.sh' first."
  exit 1
fi

# retry <attempts> <seconds between attempts> <command...>
retry() {
  local attempts="$1" pause="$2" i
  shift 2
  for i in $(seq 1 "$attempts"); do
    if "$@"; then
      return 0
    fi
    if (( i < attempts )); then
      info "Not ready yet (attempt ${i} of ${attempts}) — trying again in ${pause} seconds..."
      sleep "$pause"
    fi
  done
  return 1
}

# ensure_mg <name> <display name> [parent name]
ensure_mg() {
  local name="$1" display="$2" parent="${3:-}"
  if az account management-group show --name "$name" --output none 2>/dev/null; then
    info "Management group ${name} already exists."
    return 0
  fi
  info "Creating management group ${name} (${display})..."
  if [[ -n "$parent" ]]; then
    retry 6 30 az account management-group create --name "$name" --display-name "$display" --parent "$parent" --output none
  else
    retry 6 30 az account management-group create --name "$name" --display-name "$display" --output none
  fi
}

# ensure_identity_role -> the assignment's managed identity gets Contributor on the corp resource group
ensure_identity_role() {
  local pid count i
  pid="$(az_q policy assignment show --name "$ASSIGNMENT" --scope "$ASSIGN_SCOPE" --query identity.principalId)"
  if [[ -z "$pid" ]]; then
    echo "Assignment ${ASSIGNMENT} has no managed identity."
    return 1
  fi
  for i in $(seq 1 6); do
    count="$(az_q role assignment list --scope "$CORP_RG_ID" --query "length([?principalId=='${pid}'])")"
    if [[ "${count:-0}" =~ ^[0-9]+$ ]] && (( count >= 1 )); then
      info "Managed identity ${pid} holds a role on ${CORP_RG}."
      return 0
    fi
    info "Granting Contributor on ${CORP_RG} to the managed identity (attempt ${i})..."
    if az role assignment create --assignee-object-id "$pid" --assignee-principal-type ServicePrincipal \
        --role Contributor --scope "$CORP_RG_ID" --output none 2>/dev/null; then
      return 0
    fi
    sleep 20   # a brand-new identity can take a moment to replicate in Microsoft Entra ID
  done
  return 1
}

# graph <query> -> runs an Azure Resource Graph query and prints a table
graph() {
  az graph query --graph-query "$1" --first 200 --query data --output table
}

# Retries are generous on Path B: right after a subscription move, Azure can take a while to see the new hierarchy.
if [[ "$LAB31_PATH" == "B" || "${MOVE_SUBSCRIPTION:-no}" == "yes" ]]; then
  SLOW_ATTEMPTS=10
else
  SLOW_ATTEMPTS=3
fi

banner "Task 1 · Look at the starting point and find the built-in definitions"
az account show --query "{tenant:tenantId, subscription:name}" --output table
if ! az extension show --name resource-graph --output none 2>/dev/null; then
  info "Installing the Azure CLI extension for Resource Graph..."
  az extension add --name resource-graph --only-show-errors --output none
fi
lookup_builtin_ids
if [[ -z "$ALLOWED_LOCATIONS_ID" || -z "$REQUIRE_TAG_ID" || -z "$INHERIT_TAG_ID" ]]; then
  echo "Could not find all three built-in definitions. Check that 'az policy definition list' works."
  exit 1
fi
info "Allowed locations                                -> ${ALLOWED_LOCATIONS_ID}"
info "Require a tag on resources                       -> ${REQUIRE_TAG_ID}"
info "Inherit a tag from the resource group if missing -> ${INHERIT_TAG_ID}"

banner "Task 2 · Build the management group hierarchy"
info "The first management group in a tenant can take up to 15 minutes to appear."
ensure_mg "$MG_ROOT" "Nusantara Retail (lab ${SUFFIX})"
ensure_mg "$MG_PLATFORM" "Platform" "$MG_ROOT"
ensure_mg "$MG_LZ" "Landing zones" "$MG_ROOT"
ensure_mg "$MG_CORP" "Corp" "$MG_LZ"
for mg in "$MG_ROOT" "$MG_PLATFORM" "$MG_LZ" "$MG_CORP"; do
  info "${mg}  ->  parent: $(mg_parent "$mg")"
done

banner "Task 3 · (Optional) Move your lab subscription into the hierarchy"
if [[ "${MOVE_SUBSCRIPTION:-no}" == "yes" ]]; then
  if [[ "$LAB31_PATH" == "B" ]]; then
    info "Already moved earlier (${LAB31_STATE_FILE} exists)."
  else
    original_parent="$(az graph query --graph-query "resourcecontainers | where type =~ 'microsoft.resources/subscriptions' and subscriptionId == '${SUB_ID}' | project parent = tostring(properties.managementGroupAncestorsChain[0].name)" \
      --query "data[0].parent" --output tsv 2>/dev/null || true)"
    if [[ -z "$original_parent" || "$original_parent" == "$MG_CORP" ]]; then
      original_parent="$TENANT_ID"
    fi
    info "Current parent: ${original_parent}"
    info "Moving subscription ${SUB_ID} into ${MG_CORP}..."
    retry 4 30 az account management-group subscription add --name "$MG_CORP" --subscription "$SUB_ID" --output none
    echo "$original_parent" > "$LAB31_STATE_FILE"
    info "The original parent is saved in ${LAB31_STATE_FILE}, so cleanup.sh can move the subscription back."
    source "${LAB_DIR}/lab-vars.sh"
    info "Moved. Azure can take up to 30 minutes to apply inherited settings everywhere."
  fi
else
  info "Skipped — Path A. (Run with MOVE_SUBSCRIPTION=yes to try Path B.)"
fi
info "Path ${LAB31_PATH}: initiative saved at ${INITIATIVE_ID%%/providers/Microsoft.Authorization*}"
info "         assignment scope: ${ASSIGN_SCOPE}"

banner "Task 4 · Create the initiative from the policy-as-code files"
mkdir -p generated
sed -e "s#__ALLOWED_LOCATIONS_ID__#${ALLOWED_LOCATIONS_ID}#" \
    -e "s#__REQUIRE_TAG_ID__#${REQUIRE_TAG_ID}#" \
    -e "s#__INHERIT_TAG_ID__#${INHERIT_TAG_ID}#" \
    policy/nusa-baseline/policyset.definitions.json > generated/policyset.definitions.json
# shellcheck disable=SC2086  # INITIATIVE_SCOPE_FLAG is empty (Path A) or two words (Path B)
if az policy set-definition show --name "$INITIATIVE" $INITIATIVE_SCOPE_FLAG --output none 2>/dev/null; then
  info "Initiative ${INITIATIVE} already exists."
else
  # shellcheck disable=SC2086
  az policy set-definition create --name "$INITIATIVE" $INITIATIVE_SCOPE_FLAG \
    --display-name "Nusantara baseline" \
    --description "Allowed locations, a required costCenter tag, and the costCenter tag inherited from the resource group." \
    --definitions ./generated/policyset.definitions.json \
    --params ./policy/nusa-baseline/policyset.parameters.json \
    --output none
  info "Created initiative ${INITIATIVE}."
fi
# shellcheck disable=SC2086
az policy set-definition show --name "$INITIATIVE" $INITIATIVE_SCOPE_FLAG \
  --query "policyDefinitions[].{reference:policyDefinitionReferenceId, definition:policyDefinitionId}" --output table

banner "Task 5 · Assign the initiative in DoNotEnforce mode, with a managed identity"
params="{\"allowedLocations\":{\"value\":[\"${LOCATION}\"]},\"tagName\":{\"value\":\"costCenter\"}}"
if az policy assignment show --name "$ASSIGNMENT" --scope "$ASSIGN_SCOPE" --output none 2>/dev/null; then
  info "Assignment ${ASSIGNMENT} already exists."
else
  if ! retry "$SLOW_ATTEMPTS" 30 az policy assignment create --name "$ASSIGNMENT" --display-name "Nusantara baseline (Lab 31)" \
      --scope "$ASSIGN_SCOPE" --policy-set-definition "$INITIATIVE_ID" --params "$params" \
      --enforcement-mode DoNotEnforce \
      --mi-system-assigned --location "$LOCATION" --identity-scope "$CORP_RG_ID" --role Contributor \
      --output none; then
    note "The assignment may exist without its role assignment — checking and fixing that next."
  fi
  az policy assignment non-compliance-message create --name "$ASSIGNMENT" --scope "$ASSIGN_SCOPE" \
    --message "Nusantara baseline (Lab 31): use ${LOCATION} and add a costCenter tag. Remove it with labs/31-governance-at-scale/cleanup.sh." \
    --output none || note "Could not add the non-compliance message (optional)."
  info "Created assignment ${ASSIGNMENT} at ${ASSIGN_SCOPE}."
fi
ensure_identity_role
az policy assignment show --name "$ASSIGNMENT" --scope "$ASSIGN_SCOPE" \
  --query "{name:name, enforcementMode:enforcementMode, identity:identity.type, allowedLocations:parameters.allowedLocations.value}" \
  --output jsonc

banner "Task 6 · Remediate the corp resource group"
if az policy remediation show --name "$REMEDIATION" --resource-group "$CORP_RG" --output none 2>/dev/null; then
  info "Remediation task ${REMEDIATION} already exists."
else
  retry "$SLOW_ATTEMPTS" 60 az policy remediation create --name "$REMEDIATION" --resource-group "$CORP_RG" \
    --policy-assignment "$ASSIGNMENT_ID" --definition-reference-id inheritCostCenterTag \
    --resource-discovery-mode ReEvaluateCompliance --output none
  info "Created remediation task ${REMEDIATION}."
fi
for i in $(seq 1 40); do
  state="$(az_q policy remediation show --name "$REMEDIATION" --resource-group "$CORP_RG" --query provisioningState)"
  info "Remediation state: ${state:-unknown} (check ${i} of 40)"
  case "$state" in
    Succeeded | Failed | Canceled) break ;;
  esac
  sleep 30
done
az policy remediation show --name "$REMEDIATION" --resource-group "$CORP_RG" \
  --query "{state:provisioningState, deployments:deploymentStatus}" --output jsonc
az resource list --resource-group "$CORP_RG" --query "[].{name:name, costCenter:tags.costCenter}" --output table
if [[ -z "$(az_q storage account show --name "$LEGACY_SA" --resource-group "$CORP_RG" --query tags.costCenter)" ]]; then
  note "The tag has not arrived yet. Wait a few minutes; if it is still missing, create a second remediation task with another --name."
fi

banner "Task 7 · Grant the sandbox a time-boxed Waiver"
expires="$(date -u -d '+30 days' '+%Y-%m-%dT%H:%M:%SZ')"
exemption_args=(--name "$EXEMPTION" --resource-group "$SANDBOX_RG" --policy-assignment "$ASSIGNMENT_ID"
  --exemption-category Waiver --expires-on "$expires"
  --display-name "Sandbox experiment in ${SECONDARY_LOCATION} (NUSA-1042)"
  --description "Dewi tests a partner integration in ${SECONDARY_LOCATION} for 30 days. Risk accepted by Ibu Sari."
  --metadata "{requestedBy:Dewi,approvedBy:'Ibu Sari',ticketRef:NUSA-1042}" --output none)
if az policy exemption show --name "$EXEMPTION" --resource-group "$SANDBOX_RG" --output none 2>/dev/null; then
  info "Exemption ${EXEMPTION} already exists."
elif retry "$SLOW_ATTEMPTS" 60 az policy exemption create "${exemption_args[@]}"; then
  info "Created exemption ${EXEMPTION}, expiring ${expires}."
else
  note "Still refused — retrying without the assignment-scope check (needed only right after a subscription move)."
  az policy exemption create "${exemption_args[@]}" --assignment-scope-validation DoNotValidate
fi
az policy exemption show --name "$EXEMPTION" --resource-group "$SANDBOX_RG" \
  --query "{name:name, category:exemptionCategory, expiresOn:expiresOn, metadata:metadata}" --output jsonc

banner "Task 8 · Read compliance at scale"
info "Starting on-demand compliance scans of both lab resource groups..."
az policy state trigger-scan --resource-group "$CORP_RG" --no-wait --output none
az policy state trigger-scan --resource-group "$SANDBOX_RG" --no-wait --output none
for i in $(seq 1 30); do
  corp_states="$(az_q policy state list --resource-group "$CORP_RG" --filter "policyAssignmentName eq '${ASSIGNMENT}'" --query "length(@)")"
  sandbox_states="$(az_q policy state list --resource-group "$SANDBOX_RG" --filter "policyAssignmentName eq '${ASSIGNMENT}'" --query "length(@)")"
  info "Compliance records — corp: ${corp_states:-0}, sandbox: ${sandbox_states:-0} (check ${i} of 30)"
  if [[ "${corp_states:-0}" =~ ^[1-9][0-9]*$ && "${sandbox_states:-0}" =~ ^[1-9][0-9]*$ ]]; then
    break
  fi
  sleep 30
done
az policy state list --resource-group "$CORP_RG" --filter "policyAssignmentName eq '${ASSIGNMENT}'" \
  --query "[].{resource:resourceId, policy:policyDefinitionReferenceId, state:complianceState}" --output table
info "Resource Graph sees every subscription you can read. Results can lag a few minutes behind."
graph "policyresources
| where type == 'microsoft.policyinsights/policystates'
| where tostring(properties.policyAssignmentName) == '${ASSIGNMENT}'
| summarize resources = count() by policy = tostring(properties.policyDefinitionReferenceId), state = tostring(properties.complianceState)
| order by policy asc"
graph "policyresources
| where type == 'microsoft.policyinsights/policystates'
| where tostring(properties.policyAssignmentName) == '${ASSIGNMENT}'
| where tostring(properties.complianceState) == 'NonCompliant'
| where tolower(tostring(properties.resourceId)) contains '/resourcegroups/rg-lunch31-'
| project resource = extract('[^/]+$', 0, tostring(properties.resourceId)), policy = tostring(properties.policyDefinitionReferenceId)"
graph "policyresources
| where type == 'microsoft.authorization/policyexemptions'
| project name, resourceGroup, category = tostring(properties.exemptionCategory), expiresOn = tostring(properties.expiresOn)"
graph "resourcecontainers
| where type == 'microsoft.resources/subscriptions'
| project subscription = name, parent = tostring(properties.managementGroupAncestorsChain[0].displayName)"

banner "Task 9 · Export the governance as code"
out="exported/${INITIATIVE}"
mkdir -p "${out}/exemptions.${ASSIGNMENT}"
# shellcheck disable=SC2086
az policy set-definition show --name "$INITIATIVE" $INITIATIVE_SCOPE_FLAG \
  --query "{name:name, displayName:displayName, description:description, parameters:parameters, policyDefinitions:policyDefinitions}" \
  --output json > "${out}/policyset.json"
az policy assignment show --name "$ASSIGNMENT" --scope "$ASSIGN_SCOPE" \
  --query "{name:name, displayName:displayName, scope:scope, policyDefinitionId:policyDefinitionId, enforcementMode:enforcementMode, parameters:parameters, nonComplianceMessages:nonComplianceMessages, identityType:identity.type, location:location}" \
  --output json > "${out}/assign.${ASSIGNMENT}.json"
az policy exemption show --name "$EXEMPTION" --resource-group "$SANDBOX_RG" \
  --query "{name:name, displayName:displayName, exemptionCategory:exemptionCategory, expiresOn:expiresOn, policyAssignmentId:policyAssignmentId, metadata:metadata}" \
  --output json > "${out}/exemptions.${ASSIGNMENT}/${EXEMPTION}.json"
find exported -type f | sort

banner "Done"
info "Now run: bash verify.sh"
