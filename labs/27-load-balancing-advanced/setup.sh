#!/usr/bin/env bash
# =============================================================================
# Lab 27 · setup.sh — creates the starting point for the advanced load balancing lab
#
#   * resource group  rg-lunch27-<suffix>
#   * VNet            vnet-nusa-edge 10.27.0.0/16 with snet-agw 10.27.0.0/24
#                     (a dedicated, empty subnet for Application Gateway)
#   * App Service     plan asp-nusa-edge (Free F1, Windows) with two apps, HTTPS only:
#                       app-nusa-store-<suffix>  -> the static pages in app/storefront
#                       app-nusa-img-<suffix>    -> the static pages in app/images
#
# Takes about 3–5 minutes. Safe to run again (it redeploys the pages).
#     bash setup.sh
# If your subscription refuses Free plans:  APP_SKU=B1 bash setup.sh   (small hourly charge)
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Resource providers"
for ns in Microsoft.Web Microsoft.Network; do
  state="$(az_q provider show -n "$ns" --query registrationState)"
  if [[ "$state" != "Registered" ]]; then
    info "Registering ${ns} (one-time, about a minute)..."
    az provider register -n "$ns" --wait --output none
  fi
  info "${ns}: Registered"
done

banner "Resource group ${RG}"
ensure_rg "$RG" 27
info "Region: ${LOCATION}"

banner "Virtual network ${VNET} with the Application Gateway subnet ${SUBNET_AGW}"
if [[ -z "$(az_q network vnet show -g "$RG" -n "$VNET" --query id)" ]]; then
  az network vnet create -g "$RG" -n "$VNET" -l "$LOCATION" \
    --address-prefixes 10.27.0.0/16 \
    --subnet-name "$SUBNET_AGW" --subnet-prefixes 10.27.0.0/24 --output none
fi
info "${SUBNET_AGW}: 10.27.0.0/24 (a /24 leaves room for autoscaling)"

banner "App Service plan ${PLAN} (${APP_SKU}, Windows)"
if [[ -z "$(az_q appservice plan show -g "$RG" -n "$PLAN" --query id)" ]]; then
  az appservice plan create -g "$RG" -n "$PLAN" -l "$LOCATION" --sku "$APP_SKU" --output none
fi

banner "Packaging the sample pages"
BUILD_DIR="${LAB_DIR}/out"                 # git-ignored (labs/**/out/)
mkdir -p "$BUILD_DIR"
for site in storefront images; do
  python3 - "${LAB_DIR}/app/${site}" "${BUILD_DIR}/${site}.zip" <<'PY'
import os
import sys
import zipfile

src, dst = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
    for root, _dirs, files in os.walk(src):
        for name in files:
            full = os.path.join(root, name)
            z.write(full, os.path.relpath(full, src))
PY
  info "${BUILD_DIR}/${site}.zip"
done

banner "Two web apps (HTTPS only)"
for pair in "${APP_STORE}:storefront" "${APP_IMG}:images"; do
  name="${pair%%:*}"
  site="${pair##*:}"
  if [[ -z "$(az_q webapp show -g "$RG" -n "$name" --query id)" ]]; then
    info "Creating ${name}..."
    az webapp create -g "$RG" -p "$PLAN" -n "$name" --https-only true --output none
  fi
  info "Deploying app/${site} to ${name}..."
  az webapp deploy -g "$RG" -n "$name" --src-path "${BUILD_DIR}/${site}.zip" --type zip --output none
done

banner "Checking both apps over HTTPS (up to 4 minutes on a cold start)"
load_hosts
page_has() { curl -s --max-time 15 "https://$1/" | grep -q "$2"; }
for pair in "${STORE_HOST}|STOREFRONT app" "${IMG_HOST}|IMAGES app"; do
  host="${pair%%|*}"
  marker="${pair#*|}"
  if [[ -n "$host" ]] && wait_until "$host" 240 page_has "$host" "$marker"; then
    pass "https://${host}/ shows the ${marker}"
  else
    note "https://${host:-<missing>}/ did not show the ${marker} yet — see Troubleshooting in the lab guide."
  fi
done

banner "Starting point ready"
info "Storefront app : https://${STORE_HOST}"
info "Images app     : https://${IMG_HOST}/images/"
info "Next           : follow Task 1 in README.md"
