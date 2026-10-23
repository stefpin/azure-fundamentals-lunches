#!/usr/bin/env bash
# =============================================================================
# Lab 22 · Checks the Challenge brief. Read-only: it changes nothing.
#     bash verify.sh
# =============================================================================
set -uo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 22)"
ROLE_NAME="Nusantara VM Operator ${SUFFIX}"
MI_NAME="id-nusa-reports"
APP_NAME="app-nusa-github-deploy-${SUFFIX}"

banner "Lab 22 · Resource group"
RG_ID="$(az_q group show --name "$RG" --query id)"
check_nonempty "Resource group ${RG} exists" "$RG_ID"
if [[ -n "$RG_ID" ]]; then
  check_eq "Resource group carries the lab tag lunch=22 (so cleanup.sh can find it)" "22" \
    "$(az_q group show --name "$RG" --query tags.lunch)"
fi

banner "Custom role '${ROLE_NAME}'"
ROLE_GUID=""
[[ -n "$RG_ID" ]] && ROLE_GUID="$(az_q role definition list --name "$ROLE_NAME" --scope "$RG_ID" --query "[0].name")"
check_nonempty "The custom role exists (looked up at the resource-group scope)" "$ROLE_GUID"
if [[ -n "$ROLE_GUID" ]]; then
  rd() { az_q role definition list --name "$ROLE_NAME" --scope "$RG_ID" --query "$1"; }
  check_eq "It is a custom role" "CustomRole" "$(rd "[0].roleType")"

  ACTIONS="$(rd "[0].permissions[0].actions")"
  for op in read start/action restart/action deallocate/action; do
    if grep -qix "Microsoft.Compute/virtualMachines/${op}" <<< "$ACTIONS"; then
      pass "Allows Microsoft.Compute/virtualMachines/${op}"
    else
      fail "Allows Microsoft.Compute/virtualMachines/${op} (missing from Actions)"
    fi
  done
  RISKY="$(grep -Ei '\*|/write$|/delete$' <<< "$ACTIONS" | tr '\n' ' ')"
  if [[ -z "${RISKY// /}" ]]; then
    pass "Grants no wildcard, write or delete actions"
  else
    fail "Grants no wildcard, write or delete actions (found: ${RISKY})"
  fi
  check_eq "Grants no data actions" "0" "$(rd "[0].permissions[0].dataActions | length(@)")"

  SCOPES="$(rd "[0].assignableScopes")"
  check_eq "Assignable only at the lab resource group" "$RG_ID" "$(tr -d '[:space:]' <<< "$SCOPES")"

  check_ge "The custom role is assigned at the resource-group scope" 1 \
    "$(az_q role assignment list --scope "$RG_ID" --fill-principal-name false \
         --query "[?ends_with(roleDefinitionId, '/${ROLE_GUID}')] | length(@)")"
fi

banner "Managed identity ${MI_NAME}"
MI_PID=""
[[ -n "$RG_ID" ]] && MI_PID="$(az_q identity show --name "$MI_NAME" --resource-group "$RG" --query principalId)"
check_nonempty "User-assigned managed identity ${MI_NAME} exists in ${RG}" "$MI_PID"
if [[ -n "$MI_PID" ]]; then
  SBDR_SCOPE="$(az_q role assignment list --assignee-object-id "$MI_PID" --all --fill-principal-name false \
    --query "[?roleDefinitionName=='Storage Blob Data Reader'].scope | [0]")"
  check_contains "The identity has Storage Blob Data Reader on a storage account in ${RG}" \
    "${RG_ID}/providers/Microsoft.Storage/storageAccounts/" "$SBDR_SCOPE"
  check_eq "The identity holds no other role assignments (least privilege)" "0" \
    "$(az_q role assignment list --assignee-object-id "$MI_PID" --all --fill-principal-name false \
         --query "[?roleDefinitionName!='Storage Blob Data Reader'] | length(@)")"
fi

banner "App registration ${APP_NAME}"
APP_ID="$(az_q ad app list --display-name "$APP_NAME" --query "[?displayName=='${APP_NAME}'].appId | [0]")"
check_nonempty "App registration ${APP_NAME} exists" "$APP_ID"
if [[ -n "$APP_ID" ]]; then
  SP_ID="$(az_q ad sp show --id "$APP_ID" --query id)"
  check_nonempty "It has a service principal in your tenant" "$SP_ID"
  check_eq "It has no client secrets" "0" "$(az_q ad app credential list --id "$APP_ID" --query "length(@)")"
  check_eq "It has no certificates" "0" "$(az_q ad app credential list --id "$APP_ID" --cert --query "length(@)")"
  if [[ -n "$SP_ID" && -n "$RG_ID" ]]; then
    check_ge "Its service principal has Reader on ${RG}" 1 \
      "$(az_q role assignment list --assignee-object-id "$SP_ID" --scope "$RG_ID" --fill-principal-name false \
           --query "[?roleDefinitionName=='Reader'] | length(@)")"
  fi

  FOUND=0
  SEEN=""
  while IFS=$'\t' read -r issuer subject audiences; do
    [[ -z "$issuer" ]] && continue
    SEEN+="${subject} "
    if [[ "$issuer" =~ ^https://token\.actions\.githubusercontent\.com/?$ \
          && "$audiences" == *"api://AzureADTokenExchange"* \
          && "$subject" =~ ^repo:[^/:]+/[^/:]+:ref:refs/heads/main$ ]]; then
      FOUND=1
      info "Trusted subject: ${subject}"
    fi
  done < <(az_q ad app federated-credential list --id "$APP_ID" --query "[].[issuer, subject, join(',', audiences)]")
  if (( FOUND == 1 )); then
    pass "Federated credential trusts GitHub Actions on main (issuer, audience and subject are correct)"
  else
    fail "Federated credential trusts GitHub Actions on main (found subjects: ${SEEN:-none})"
  fi
fi

summary
