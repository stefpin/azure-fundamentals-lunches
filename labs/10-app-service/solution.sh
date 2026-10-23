#!/usr/bin/env bash
# =============================================================================
# Lab 10 · solution.sh — reference solution for the core tasks (Free F1 plan).
# It uses the explicit commands (plan create + webapp create + webapp deploy),
# which do the same as the one-step `az webapp up` from Task 2 but will keep
# working after `az webapp up` is removed from the Azure CLI.
#     bash solution.sh
#     WITH_SLOT=1 bash solution.sh    # also the stretch: S1, staging slot, v2, swap (💲💲)
# Safe to re-run.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Resource group ${RG}"
ensure_rg "$RG" 10

banner "Linux App Service plan ${PLAN}"
if az appservice plan show -g "$RG" -n "$PLAN" --output none 2>/dev/null; then
  info "The plan already exists; keeping its current pricing tier."
else
  az appservice plan create -g "$RG" -n "$PLAN" --location "$LOCATION" --is-linux --sku F1 --output none
  info "Created ${PLAN} (Linux, Free F1)."
fi

banner "Web app ${APP} (${RUNTIME})"
if az webapp show -g "$RG" -n "$APP" --output none 2>/dev/null; then
  info "The web app already exists."
else
  az webapp create -g "$RG" -n "$APP" --plan "$PLAN" --runtime "$RUNTIME" --output none
  info "Created ${APP}."
fi

banner "App settings, HTTPS only and container logging"
az webapp config appsettings set -g "$RG" -n "$APP" \
  --settings "STORE_NAME=${STORE}" SCM_DO_BUILD_DURING_DEPLOYMENT=true --output none
az webapp update -g "$RG" -n "$APP" --https-only true --output none
az webapp log config -g "$RG" -n "$APP" --docker-container-logging filesystem --output none

banner "Package and deploy version 1.0 (the build takes a few minutes)"
mkdir -p "$OUT_DIR"
rm -f "${OUT_DIR}/storefront-v1.zip"
(cd "${LAB_DIR}/app" && python3 -m zipfile -c "${OUT_DIR}/storefront-v1.zip" app.py requirements.txt)
az webapp deploy -g "$RG" -n "$APP" --src-path "${OUT_DIR}/storefront-v1.zip" --type zip --output none

HOST="$(az webapp show -g "$RG" -n "$APP" --query defaultHostName --output tsv)"
info "Storefront: https://${HOST}"

if [[ "${WITH_SLOT:-0}" == "1" ]]; then
  banner "Stretch: Standard S1, staging slot, version 2.0 and a swap"
  az appservice plan update -g "$RG" -n "$PLAN" --sku S1 --output none
  if ! az webapp show -g "$RG" -n "$APP" --slot staging --output none 2>/dev/null; then
    az webapp deployment slot create -g "$RG" -n "$APP" --slot staging --configuration-source "$APP" --output none
  fi
  az webapp update -g "$RG" -n "$APP" --slot staging --https-only true --output none
  az webapp config appsettings set -g "$RG" -n "$APP" --slot staging \
    --settings "STORE_NAME=${STORE}" SCM_DO_BUILD_DURING_DEPLOYMENT=true --output none

  rm -rf "${OUT_DIR}/v2" && mkdir -p "${OUT_DIR}/v2"
  cp "${LAB_DIR}/app/app.py" "${LAB_DIR}/app/requirements.txt" "${OUT_DIR}/v2/"
  sed -i 's/^APP_VERSION = "1.0"/APP_VERSION = "2.0"/' "${OUT_DIR}/v2/app.py"
  rm -f "${OUT_DIR}/storefront-v2.zip"
  (cd "${OUT_DIR}/v2" && python3 -m zipfile -c "${OUT_DIR}/storefront-v2.zip" app.py requirements.txt)
  az webapp deploy -g "$RG" -n "$APP" --slot staging --src-path "${OUT_DIR}/storefront-v2.zip" --type zip --output none

  az webapp deployment slot swap -g "$RG" -n "$APP" --slot staging --target-slot production --output none
  info "Production now serves version 2.0; staging holds version 1.0. Swap again to roll back."
fi

banner "Done"
info "Check your work with: bash verify.sh"
