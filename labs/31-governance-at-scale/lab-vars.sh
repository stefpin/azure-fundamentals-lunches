#!/usr/bin/env bash
# =============================================================================
# Lab 31 · names and helpers, shared by the lab scripts AND by you.
#
# Load it after the common settings (it needs SUFFIX, LOCATION and az login):
#     source ../common/config.sh
#     source lab-vars.sh
# Cloud Shell forgets variables when it restarts — just run both lines again.
# Run it again, too, after you move (or move back) your subscription in Task 3.
# =============================================================================

SUB_ID="$(az account show --query id --output tsv 2>/dev/null)"
TENANT_ID="$(az account show --query tenantId --output tsv 2>/dev/null)"
SUB_SCOPE="/subscriptions/${SUB_ID}"

# Resource groups: "corp" holds a workload with a costCenter tag, "sandbox" holds an experiment
CORP_RG="$(rg_name 31 corp)"
SANDBOX_RG="$(rg_name 31 sandbox)"
CORP_RG_ID="${SUB_SCOPE}/resourceGroups/${CORP_RG}"
SANDBOX_RG_ID="${SUB_SCOPE}/resourceGroups/${SANDBOX_RG}"
COST_CENTER="CC-2001"                 # finance's cost center for the corp workload
LEGACY_SA="stcorp${SUFFIX}"           # created by setup.sh with no tags
LEGACY_NSG="nsg-corp-legacy"          # created by setup.sh with no tags
SANDBOX_NSG="nsg-sandbox-legacy"      # created by setup.sh in SECONDARY_LOCATION, no tags

# The miniature landing-zone hierarchy (management group IDs never change once created)
MG_ROOT="mg-nusa-${SUFFIX}"                     # intermediate root
MG_PLATFORM="mg-nusa-platform-${SUFFIX}"
MG_LZ="mg-nusa-landingzones-${SUFFIX}"
MG_CORP="mg-nusa-corp-${SUFFIX}"
MG_PREFIX="/providers/Microsoft.Management/managementGroups"

# Policy names (assignment names at management-group scope must be 24 characters or fewer)
INITIATIVE="nusa-baseline"
ASSIGNMENT="nusa-baseline"
REMEDIATION="fix-corp-costcenter"
EXEMPTION="sandbox-waiver"
SCOPE_TEST="nusa-scope-test"          # the definition used in "Break it and fix it"

# Path A (default): your subscription stays where it is. The initiative is saved in the
#   subscription and assigned to the subscription.
# Path B (optional, Task 3): your subscription moves under the corp management group. The
#   initiative is saved at the intermediate root and assigned to the landing zones group.
# The file below exists only while your subscription is moved; it remembers where it came from.
LAB31_STATE_FILE="${HOME}/.azlunches-lab31-original-parent"
if [[ -s "$LAB31_STATE_FILE" ]]; then
  LAB31_PATH="B"
else
  LAB31_PATH="A"
fi

if [[ "$LAB31_PATH" == "B" ]]; then
  INITIATIVE_SCOPE_FLAG="--management-group ${MG_ROOT}"
  INITIATIVE_ID="${MG_PREFIX}/${MG_ROOT}/providers/Microsoft.Authorization/policySetDefinitions/${INITIATIVE}"
  ASSIGN_SCOPE="${MG_PREFIX}/${MG_LZ}"
else
  INITIATIVE_SCOPE_FLAG=""
  INITIATIVE_ID="${SUB_SCOPE}/providers/Microsoft.Authorization/policySetDefinitions/${INITIATIVE}"
  ASSIGN_SCOPE="${SUB_SCOPE}"
fi
ASSIGNMENT_ID="${ASSIGN_SCOPE}/providers/Microsoft.Authorization/policyAssignments/${ASSIGNMENT}"

# lookup_builtin_ids -> sets ALLOWED_LOCATIONS_ID, REQUIRE_TAG_ID and INHERIT_TAG_ID.
# Built-in definitions are looked up by display name, never by a hard-coded GUID.
lookup_builtin_ids() {
  local name id
  ALLOWED_LOCATIONS_ID=""
  REQUIRE_TAG_ID=""
  INHERIT_TAG_ID=""
  while IFS=$'\t' read -r name id; do
    case "$name" in
      "Allowed locations") ALLOWED_LOCATIONS_ID="$id" ;;
      "Require a tag on resources") REQUIRE_TAG_ID="$id" ;;
      "Inherit a tag from the resource group if missing") INHERIT_TAG_ID="$id" ;;
    esac
  done < <(az policy definition list \
    --query "[?policyType=='BuiltIn' && (displayName=='Allowed locations' || displayName=='Require a tag on resources' || displayName=='Inherit a tag from the resource group if missing')].[displayName, id]" \
    --output tsv 2>/dev/null)
  export ALLOWED_LOCATIONS_ID REQUIRE_TAG_ID INHERIT_TAG_ID
}

# mg_parent <management group name> -> prints the name of its parent (empty if it does not exist)
mg_parent() {
  az account management-group show --name "$1" \
    --query "details.parent.name || properties.details.parent.name" --output tsv 2>/dev/null || true
}

# sub_in_mg <management group name> -> succeeds when your subscription sits directly in that group
sub_in_mg() {
  az account management-group subscription show --name "$1" --subscription "$SUB_ID" --output none 2>/dev/null
}

export SUB_ID TENANT_ID SUB_SCOPE CORP_RG SANDBOX_RG CORP_RG_ID SANDBOX_RG_ID COST_CENTER LEGACY_SA LEGACY_NSG \
  SANDBOX_NSG MG_ROOT MG_PLATFORM MG_LZ MG_CORP MG_PREFIX INITIATIVE ASSIGNMENT REMEDIATION EXEMPTION SCOPE_TEST \
  LAB31_STATE_FILE LAB31_PATH INITIATIVE_SCOPE_FLAG INITIATIVE_ID ASSIGN_SCOPE ASSIGNMENT_ID
