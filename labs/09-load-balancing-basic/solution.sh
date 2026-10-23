#!/usr/bin/env bash
# =============================================================================
# Lab 09 · solution.sh — reference solution for Tasks 2–7 (run setup.sh first)
#
# Builds a Standard public load balancer in front of vm-web-1 and vm-web-2:
#   zone-redundant frontend · NIC-based backend pool · HTTP probe on /health ·
#   LB rule TCP 80 (outbound SNAT disabled) · inbound NAT 50001 -> vm-web-1:22 ·
#   outbound rule (SNAT through the frontend IP)
# Safe to run again. Takes about 5 minutes.
#     bash solution.sh
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${LAB_DIR}/../common/config.sh"
source "${LAB_DIR}/lab.env"
require_az

if [[ -z "$(az_q vm show -g "$RG" -n "$VM2" --query id)" ]]; then
  echo "The starting point is missing. Run: bash setup.sh"
  exit 1
fi

banner "Task 2 · Zone-redundant Standard public IP ${PIP}"
if [[ -z "$(az_q network public-ip show -g "$RG" -n "$PIP" --query id)" ]]; then
  az network public-ip create -g "$RG" -n "$PIP" -l "$LOCATION" \
    --sku Standard --allocation-method Static --zone 1 2 3 --output none
fi
info "Frontend IP: $(lb_ip)"

banner "Task 3 · Standard load balancer ${LB} and backend pool ${POOL}"
if [[ -z "$(az_q network lb show -g "$RG" -n "$LB" --query id)" ]]; then
  az network lb create -g "$RG" -n "$LB" -l "$LOCATION" --sku Standard \
    --public-ip-address "$PIP" --frontend-ip-name "$FE" --backend-pool-name "$POOL" \
    --output none
fi
for nic in "$NIC1" "$NIC2"; do
  pools="$(az_q network nic show -g "$RG" -n "$nic" \
    --query 'ipConfigurations[0].loadBalancerBackendAddressPools[].id')"
  if ! grep -q "/backendAddressPools/${POOL}$" <<<"$pools"; then
    az network nic ip-config address-pool add -g "$RG" --nic-name "$nic" \
      --ip-config-name "$IPCONFIG" --lb-name "$LB" --address-pool "$POOL" --output none
  fi
  info "${nic} is in ${POOL}"
done

banner "Task 4 · Health probe ${PROBE} and load-balancing rule ${RULE}"
if [[ -z "$(az_q network lb probe show -g "$RG" --lb-name "$LB" -n "$PROBE" --query id)" ]]; then
  az network lb probe create -g "$RG" --lb-name "$LB" -n "$PROBE" \
    --protocol Http --port 80 --path /health --interval 5 --output none
fi
if [[ -z "$(az_q network lb rule show -g "$RG" --lb-name "$LB" -n "$RULE" --query id)" ]]; then
  az network lb rule create -g "$RG" --lb-name "$LB" -n "$RULE" \
    --protocol Tcp --frontend-port 80 --backend-port 80 \
    --frontend-ip "$FE" --backend-pool-name "$POOL" --probe "$PROBE" \
    --disable-outbound-snat true --idle-timeout 15 --enable-tcp-reset true --output none
fi
info "Waiting 30 seconds for the first health probes..."
sleep 30
who_answers 6 || true

banner "Task 6 · Inbound NAT rule ${NAT_RULE} (${NAT_PORT} -> ${VM1}:22)"
if [[ -z "$(az_q network lb inbound-nat-rule show -g "$RG" --lb-name "$LB" -n "$NAT_RULE" --query id)" ]]; then
  az network lb inbound-nat-rule create -g "$RG" --lb-name "$LB" -n "$NAT_RULE" \
    --protocol Tcp --frontend-ip "$FE" --frontend-port "$NAT_PORT" --backend-port 22 \
    --output none
fi
nat_rules="$(az_q network nic show -g "$RG" -n "$NIC1" \
  --query 'ipConfigurations[0].loadBalancerInboundNatRules[].id')"
if ! grep -q "/inboundNatRules/${NAT_RULE}$" <<<"$nat_rules"; then
  az network nic ip-config inbound-nat-rule add -g "$RG" --nic-name "$NIC1" \
    --ip-config-name "$IPCONFIG" --lb-name "$LB" --inbound-nat-rule "$NAT_RULE" --output none
fi
my_ip="$(my_public_ip || true)"
if [[ -n "$my_ip" ]]; then
  # The NSG sees the translated destination port (22), not the frontend port.
  az network nsg rule create -g "$RG" --nsg-name "$NSG" -n Allow-SSH-MyIP \
    --priority 120 --direction Inbound --access Allow --protocol Tcp \
    --source-address-prefixes "${my_ip}/32" --source-port-ranges '*' \
    --destination-address-prefixes '*' --destination-port-ranges 22 --output none
  info "SSH allowed from ${my_ip} only. Try: ssh -p ${NAT_PORT} ${ADMIN_USER}@$(lb_ip)"
else
  note "Could not detect your public IP — add the SSH NSG rule by hand (Task 6)."
fi

banner "Task 7 · Outbound rule ${OUT_RULE}"
if [[ -z "$(az_q network lb outbound-rule show -g "$RG" --lb-name "$LB" -n "$OUT_RULE" --query id)" ]]; then
  az network lb outbound-rule create -g "$RG" --lb-name "$LB" -n "$OUT_RULE" \
    --frontend-ip-configs "$FE" --address-pool "$POOL" --protocol All \
    --outbound-ports 10000 --idle-timeout 15 --enable-tcp-reset true --output none
fi
info "Asking ${VM1} which public IP the internet sees (about 30 seconds)..."
seen="$(az vm run-command invoke -g "$RG" -n "$VM1" --command-id RunShellScript \
  --scripts "curl -s --max-time 10 https://api.ipify.org || echo no-outbound" \
  --query 'value[0].message' --output tsv 2>/dev/null | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}|no-outbound' | head -n1 || true)"
info "Outbound address seen from ${VM1}: ${seen:-unknown} (frontend IP is $(lb_ip))"

banner "Done"
info "Run: bash verify.sh"
