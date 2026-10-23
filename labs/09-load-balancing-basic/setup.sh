#!/usr/bin/env bash
# =============================================================================
# Lab 09 · setup.sh — creates the starting point for the load balancer lab
#
#   * resource group  rg-lunch09-<suffix>
#   * NSG             nsg-web: allow TCP 80 from Internet and from AzureLoadBalancer
#   * VNet            vnet-nusa-web 10.9.0.0/16 with a PRIVATE subnet snet-web 10.9.1.0/24
#   * two web VMs     vm-web-1 (zone 1) and vm-web-2 (zone 2), no public IPs,
#                     running the shared cloud-init web server ( / and /health )
#
# Takes about 6–10 minutes. Safe to run again: it skips what already exists.
#     bash setup.sh
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

banner "Resource group ${RG}"
ensure_rg "$RG" 09
info "Region: ${LOCATION}"

banner "Network security group ${NSG}"
if [[ -z "$(az_q network nsg show -g "$RG" -n "$NSG" --query id)" ]]; then
  az network nsg create -g "$RG" -n "$NSG" -l "$LOCATION" --output none
fi
# Shoppers reach the web servers on TCP 80 (the NSG sees the real client IP: a Standard
# load balancer passes traffic through without changing the source address).
az network nsg rule create -g "$RG" --nsg-name "$NSG" -n Allow-HTTP-Internet \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes Internet --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 80 --output none
# Health probes come from 168.63.129.16, which the AzureLoadBalancer service tag represents.
# A default NSG rule already allows it; this explicit rule documents the dependency.
az network nsg rule create -g "$RG" --nsg-name "$NSG" -n Allow-HTTP-AzureLoadBalancer \
  --priority 110 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes AzureLoadBalancer --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges 80 --output none
info "Rules: Allow-HTTP-Internet (100), Allow-HTTP-AzureLoadBalancer (110)"

banner "Virtual network ${VNET} with a private subnet ${SUBNET}"
if [[ -z "$(az_q network vnet show -g "$RG" -n "$VNET" --query id)" ]]; then
  az network vnet create -g "$RG" -n "$VNET" -l "$LOCATION" \
    --address-prefixes 10.9.0.0/16 --output none
fi
if [[ -z "$(az_q network vnet subnet show -g "$RG" --vnet-name "$VNET" -n "$SUBNET" --query id)" ]]; then
  # --default-outbound-access false makes the subnet private: VMs get no implicit internet
  # access, so outbound connectivity must be configured explicitly (Task 7 of the lab).
  az network vnet subnet create -g "$RG" --vnet-name "$VNET" -n "$SUBNET" \
    --address-prefixes 10.9.1.0/24 --network-security-group "$NSG" \
    --default-outbound-access false --output none
fi
info "Subnet ${SUBNET} 10.9.1.0/24 (private, protected by ${NSG})"

banner "Network interfaces (no public IPs)"
for i in 1 2; do
  nic="nic-vm-web-${i}"
  if [[ -z "$(az_q network nic show -g "$RG" -n "$nic" --query id)" ]]; then
    az network nic create -g "$RG" -n "$nic" -l "$LOCATION" \
      --vnet-name "$VNET" --subnet "$SUBNET" --output none
  fi
  info "${nic}: $(az_q network nic show -g "$RG" -n "$nic" --query 'ipConfigurations[0].privateIPAddress')"
done

banner "Two web VMs in availability zones 1 and 2 (about 2 minutes each)"
for i in 1 2; do
  vm="vm-web-${i}"
  if [[ -n "$(az_q vm show -g "$RG" -n "$vm" --query id)" ]]; then
    info "${vm} already exists — skipping."
    continue
  fi
  info "Creating ${vm} (${VM_SIZE_SMALL}, ${VM_IMAGE}) in zone ${i}..."
  az vm create -g "$RG" -n "$vm" -l "$LOCATION" --zone "$i" \
    --image "$VM_IMAGE" --size "$VM_SIZE_SMALL" \
    --nics "nic-vm-web-${i}" \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    --custom-data "${AZL_COMMON_DIR}/cloud-init-web.yml" \
    --output none
done

banner "Checking the web server on each VM (about 1 minute per VM)"
for i in 1 2; do
  vm="vm-web-${i}"
  out="$(az vm run-command invoke -g "$RG" -n "$vm" --command-id RunShellScript \
    --scripts "cloud-init status --wait >/dev/null 2>&1; curl -s --max-time 5 http://localhost/health" \
    --query 'value[0].message' --output tsv 2>/dev/null || true)"
  if grep -qx 'ok' <<<"$out"; then
    pass "${vm}: the web server answers /health"
  else
    note "${vm}: no answer from /health yet. Wait a minute, then see Troubleshooting in the lab guide."
  fi
done

banner "Starting point ready"
info "Resource group : ${RG}"
info "Web VMs        : ${VM1} (zone 1), ${VM2} (zone 2) — private IPs only"
info "Next           : follow Task 1 in README.md"
