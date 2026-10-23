#!/usr/bin/env bash
# =============================================================================
# Lab 18 · names and one helper, shared by the lab scripts AND by you.
#
# Load it after the common settings (it needs SUFFIX, LOCATION and az login):
#     source ../common/config.sh
#     source lab-vars.sh
# Cloud Shell forgets variables when it restarts — just run both lines again.
# =============================================================================

RG="$(rg_name 18)"
SUB_ID="$(az account show --query id --output tsv 2>/dev/null)"
RG_ID="/subscriptions/${SUB_ID}/resourceGroups/${RG}"

COST_CENTER="CC-1001"            # finance's cost center for the e-commerce team
LEGACY_SA="stlegacy${SUFFIX}"    # created by setup.sh BEFORE the rules, with no tags
LEGACY_NSG="nsg-legacy"          # created by setup.sh BEFORE the rules, with no tags
COMPLIANT_SA="stnusa${SUFFIX}"   # the compliant storage account you create in Task 6
DENIED_SA="stdenied${SUFFIX}"    # the storage account the policy must refuse in Task 5

# A region that is NOT on the allowed list, used to prove the Deny effect.
if [[ "${LOCATION}" == "westeurope" ]]; then
  DENIED_LOCATION="northeurope"
else
  DENIED_LOCATION="westeurope"
fi

# Names of the policy assignments and of the remediation task
A_LOCATIONS="allowed-locations"
A_REQUIRE_TAG="require-costcenter-tag"
A_INHERIT_TAG="inherit-costcenter-tag"
REMEDIATION="fix-legacy-costcenter"

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

export RG SUB_ID RG_ID COST_CENTER LEGACY_SA LEGACY_NSG COMPLIANT_SA DENIED_SA DENIED_LOCATION \
  A_LOCATIONS A_REQUIRE_TAG A_INHERIT_TAG REMEDIATION
