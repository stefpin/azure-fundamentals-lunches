#!/usr/bin/env bash
# =============================================================================
# Shared helper functions for lab scripts (setup.sh, solution.sh, verify.sh,
# cleanup.sh). config.sh sources this file for you.
# =============================================================================

PASSED=0
FAILED=0

banner() { printf '\n\033[1;34m== %s ==\033[0m\n' "$*"; }
info()   { printf '   %s\n' "$*"; }
pass()   { printf '  \033[32m✔ PASS\033[0m  %s\n' "$*"; PASSED=$((PASSED + 1)); }
fail()   { printf '  \033[31m✘ FAIL\033[0m  %s\n' "$*"; FAILED=$((FAILED + 1)); }
note()   { printf '  \033[33m! NOTE\033[0m  %s\n' "$*"; }

# check "description" <command...>        PASS when the command succeeds
check() {
  local d="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi
}

# check_eq "description" expected actual   PASS when the strings are equal (case-insensitive)
check_eq() {
  if [[ "${2,,}" == "${3,,}" ]]; then pass "$1"; else fail "$1 (expected '$2', got '${3:-<empty>}')"; fi
}

# check_contains "description" needle haystack
check_contains() {
  if [[ "${3,,}" == *"${2,,}"* ]]; then pass "$1"; else fail "$1 (expected to find '$2')"; fi
}

# check_ge "description" minimum actual    PASS when actual is a number >= minimum
check_ge() {
  if [[ "${3:-}" =~ ^[0-9]+$ ]] && (( $3 >= $2 )); then pass "$1"; else fail "$1 (expected at least $2, got '${3:-<empty>}')"; fi
}

# check_nonempty "description" value
check_nonempty() {
  if [[ -n "${2:-}" ]]; then pass "$1"; else fail "$1 (nothing found)"; fi
}

# summary  -> prints the result and returns 1 if any check failed
summary() {
  echo
  if (( FAILED == 0 )); then
    printf '\033[32mAll %d checks passed. Nice work!\033[0m\n' "$PASSED"
    return 0
  fi
  printf '\033[31m%d of %d checks failed.\033[0m Re-read the matching task, fix it, and run the script again.\n' \
    "$FAILED" "$((PASSED + FAILED))"
  return 1
}

# require_az  -> stops the script unless the Azure CLI is installed and signed in
require_az() {
  if ! command -v az >/dev/null 2>&1; then
    echo "The Azure CLI was not found. Use Azure Cloud Shell (Bash) or install the Azure CLI."
    exit 1
  fi
  if ! az account show --output none >/dev/null 2>&1; then
    echo "You are not signed in to Azure. Run: az login"
    exit 1
  fi
}

# az_q <az arguments...>  -> prints the TSV result, or nothing if the call fails (never aborts)
az_q() { az "$@" --output tsv 2>/dev/null || true; }

# confirm "question"  -> returns 0 on yes. Set ASSUME_YES=1 to skip the prompt.
confirm() {
  [[ "${ASSUME_YES:-}" == "1" ]] && return 0
  local answer
  read -r -p "$1 [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

# ensure_rg <name> <lunch-number> [location]  -> creates (or updates) a tagged resource group
ensure_rg() {
  local rg="$1" lunch="$2" location="${3:-$LOCATION}"
  az group create --name "$rg" --location "$location" \
    --tags course="$COURSE_TAG" lunch="$lunch" --output none
}

# delete_lunch_rgs <lunch-number>  -> deletes every resource group tagged for that lunch
delete_lunch_rgs() {
  local lunch="$1" rg found=0
  while IFS= read -r rg; do
    [[ -z "$rg" ]] && continue
    found=1
    info "Deleting resource group ${rg} (runs in the background and takes a few minutes)..."
    az group delete --name "$rg" --yes --no-wait
  done < <(az group list --tag lunch="$lunch" --query "[?tags.course=='${COURSE_TAG}'].name" --output tsv 2>/dev/null)
  if (( found == 0 )); then
    info "No resource groups found for lunch ${lunch}. Nothing to delete."
  fi
}

# my_object_id  -> object id of the signed-in user (for role assignments)
my_object_id() { az ad signed-in-user show --query id --output tsv 2>/dev/null; }

# my_upn  -> user principal name of the signed-in user
my_upn() { az ad signed-in-user show --query userPrincipalName --output tsv 2>/dev/null; }

# my_public_ip  -> public IPv4 address your requests come from (Cloud Shell or your PC)
my_public_ip() { curl -s --max-time 10 https://api.ipify.org || curl -s --max-time 10 https://ifconfig.me; }

# wait_until "description" <seconds> <command...>  -> retries a command every 10 s
wait_until() {
  local d="$1" timeout="$2"; shift 2
  local waited=0
  until "$@" >/dev/null 2>&1; do
    if (( waited >= timeout )); then
      note "Timed out after ${timeout}s waiting for: ${d}"
      return 1
    fi
    sleep 10
    waited=$((waited + 10))
  done
}
