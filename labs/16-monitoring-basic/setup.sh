#!/usr/bin/env bash
# =============================================================================
# Lab 16 · Know before customers do — starting point
#
# Creates resource group rg-lunch16-<suffix> with one small Linux VM,
# vm-nusa-web, that plays the Nusantara Retail storefront.
#   - Size $VM_SIZE_SMALL, image $VM_IMAGE, SSH key authentication.
#   - A Standard public IP, ONLY so the VM has outbound internet access:
#     Run Command needs outbound HTTPS to return its output, and new virtual
#     networks have no default outbound access.
#   - A network security group with NO inbound rules: nothing can connect in.
#
# Takes about 3-5 minutes. Safe to run again: existing resources are kept.
#   bash setup.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 16)"
VM_NAME="vm-nusa-web"

banner "Resource group"
ensure_rg "$RG" 16
info "Resource group ${RG} is ready in ${LOCATION}."

banner "Storefront VM"
if az vm show --resource-group "$RG" --name "$VM_NAME" --output none 2>/dev/null; then
  info "${VM_NAME} already exists, keeping it."
  state="$(az_q vm get-instance-view --resource-group "$RG" --name "$VM_NAME" \
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]")"
  info "Current state: ${state:-unknown}"
  if [[ "$state" != "VM running" ]]; then
    info "Starting ${VM_NAME} so the lab tasks can use it..."
    az vm start --resource-group "$RG" --name "$VM_NAME" --output none
  fi
else
  info "Creating ${VM_NAME} (${VM_SIZE_SMALL}, ${VM_IMAGE}). This takes about 2-4 minutes..."
  az vm create \
    --resource-group "$RG" \
    --name "$VM_NAME" \
    --location "$LOCATION" \
    --image "$VM_IMAGE" \
    --size "$VM_SIZE_SMALL" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --public-ip-sku Standard \
    --nsg-rule NONE \
    --custom-data "$AZL_COMMON_DIR/cloud-init-web.yml" \
    --tags course="$COURSE_TAG" lunch=16 role=storefront \
    --output none
fi

VM_ID="$(az vm show --resource-group "$RG" --name "$VM_NAME" --query id --output tsv)"

banner "Done"
info "VM:   ${VM_NAME}"
info "ID:   ${VM_ID}"
info "No inbound ports are open. You will reach the VM only through Azure (Run Command)."
echo
info "Next steps:"
info "  1. export ALERT_EMAIL=\"you@example.com\"   # an address you can read on your phone"
info "  2. Continue with Task 1 in README.md"
info "Remember: the VM costs money while it runs. Finish with: bash cleanup.sh"
