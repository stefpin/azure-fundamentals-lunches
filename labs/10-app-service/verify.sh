#!/usr/bin/env bash
# =============================================================================
# Lab 10 · verify.sh — checks the Challenge brief. Read-only: it changes nothing.
#     bash verify.sh
# =============================================================================
set -uo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Resource group and App Service plan"
check "Resource group ${RG} exists" az group show --name "$RG"
plan_linux="$(az_q appservice plan show -g "$RG" -n "$PLAN" --query reserved)"
check_eq "App Service plan ${PLAN} exists and runs Linux" "true" "$plan_linux"
plan_size="$(az_q appservice plan show -g "$RG" -n "$PLAN" --query sku.name)"
[[ -n "$plan_size" ]] && info "Plan size: ${plan_size}"

banner "Web app ${APP}"
state="$(az_q webapp show -g "$RG" -n "$APP" --query state)"
check_eq "Web app ${APP} is Running" "Running" "$state"
fx="$(az_q webapp config show -g "$RG" -n "$APP" --query linuxFxVersion)"
check_contains "Runtime stack is Python (found: ${fx:-none})" "python" "$fx"
https_only="$(az_q webapp show -g "$RG" -n "$APP" --query httpsOnly)"
check_eq "HTTPS only is enabled" "true" "$https_only"
store="$(az_q webapp config appsettings list -g "$RG" -n "$APP" --query "[?name=='STORE_NAME'].value | [0]")"
check_nonempty "App setting STORE_NAME is set" "$store"

banner "Home page"
host="$(az_q webapp show -g "$RG" -n "$APP" --query defaultHostName)"
body=""
if [[ -z "$host" ]]; then
  fail "Could not read the web app's host name (does the app exist?)"
else
  code=""
  for attempt in 1 2 3; do
    resp="$(curl -s --max-time 60 -w $'\n%{http_code}' "https://${host}/" 2>/dev/null || true)"
    code="${resp##*$'\n'}"
    body="${resp%$'\n'*}"
    [[ "$code" == "200" || "$attempt" == "3" ]] && break
    info "Attempt ${attempt}: HTTP ${code:-no answer}. Waiting 15 s (Free tier apps can be slow to wake up)..."
    sleep 15
  done
  check_eq "https://${host}/ returns HTTP 200" "200" "$code"
  if [[ -n "$store" ]]; then
    expected="$(python3 -c 'import html, sys; print(html.escape(sys.argv[1]))' "$store" 2>/dev/null || printf '%s' "$store")"
    check_contains "The home page shows the store name '${store}'" "$expected" "$body"
  fi
fi

banner "Stretch goal (optional)"
if az webapp show -g "$RG" -n "$APP" --slot staging --output none 2>/dev/null; then
  pass "Deployment slot 'staging' exists"
  if [[ "$body" == *"Version 2.0"* ]]; then
    info "Production serves version 2.0, so your swap worked."
  else
    info "Production serves version 1.0 (swap staging into production to release version 2.0)."
  fi
else
  note "No 'staging' slot. That's fine for the core lab (slots need the Standard tier or higher)."
fi

summary
