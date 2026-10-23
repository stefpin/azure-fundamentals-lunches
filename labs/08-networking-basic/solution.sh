#!/usr/bin/env bash
# =============================================================================
# Lab 08 · solution.sh — reference solution for Tasks 1–7 (Guided mode).
#   bash solution.sh
# Safe to re-run: every create step checks whether the resource already exists.
# Takes about 15 minutes, mostly VM creation and Run Command calls.
# The Break-it-and-fix-it exercise is not included.
# =============================================================================
set -euo pipefail
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../common/config.sh
source "$LAB_DIR/../common/config.sh"
require_az

RG="$(rg_name 08)"
VNET="vnet-nusa-shop"
ZONE="nusantara-retail-${SUFFIX}.xyz"

# run_on <vm> <script>  -> runs a shell script inside the VM through the VM agent and prints its output
run_on() {
  az vm run-command invoke -g "$RG" -n "$1" --command-id RunShellScript \
    --scripts "$2" --query "value[0].message" -o tsv
}
# exists <az command...>  -> true when the 'show' command finds the resource
exists() { "$@" --output none >/dev/null 2>&1; }

# -----------------------------------------------------------------------------
banner "Task 1 · Virtual network with two private subnets"
ensure_rg "$RG" 08
info "Resource group $RG in $LOCATION"
if exists az network vnet show -g "$RG" -n "$VNET"; then
  info "$VNET already exists"
else
  az network vnet create -g "$RG" -n "$VNET" --location "$LOCATION" \
    --address-prefixes 10.20.0.0/16 --output none
  info "Created $VNET (10.20.0.0/16)"
fi
for spec in "snet-web 10.20.1.0/24" "snet-app 10.20.2.0/24"; do
  read -r snet prefix <<< "$spec"
  if exists az network vnet subnet show -g "$RG" --vnet-name "$VNET" -n "$snet"; then
    info "$snet already exists"
  else
    az network vnet subnet create -g "$RG" --vnet-name "$VNET" -n "$snet" \
      --address-prefixes "$prefix" --default-outbound-access false --output none
    info "Created private subnet $snet ($prefix)"
  fi
done

# -----------------------------------------------------------------------------
banner "Task 2 · NSGs, application security group and rules"
# 'nsg create' replaces an existing NSG's rules, so only create when missing.
for nsg in nsg-web nsg-app; do
  if exists az network nsg show -g "$RG" -n "$nsg"; then
    info "$nsg already exists"
  else
    az network nsg create -g "$RG" -n "$nsg" --location "$LOCATION" --output none
    info "Created $nsg"
  fi
done
if ! exists az network asg show -g "$RG" -n asg-web; then
  az network asg create -g "$RG" -n asg-web --location "$LOCATION" --output none
  info "Created asg-web"
fi

az network nsg rule create -g "$RG" --nsg-name nsg-web -n Allow-HTTP-Internet \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes Internet --source-port-ranges '*' \
  --destination-asgs asg-web --destination-port-ranges 80 --output none
az network nsg rule create -g "$RG" --nsg-name nsg-app -n Allow-Web-To-App-8080 \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-asgs asg-web --source-port-ranges '*' \
  --destination-address-prefixes 10.20.2.0/24 --destination-port-ranges 8080 --output none
az network nsg rule create -g "$RG" --nsg-name nsg-app -n Deny-VNet-Inbound \
  --priority 4000 --direction Inbound --access Deny --protocol '*' \
  --source-address-prefixes VirtualNetwork --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges '*' --output none
info "Rules: nsg-web 100 Allow-HTTP-Internet · nsg-app 100 Allow-Web-To-App-8080, 4000 Deny-VNet-Inbound"

az network vnet subnet update -g "$RG" --vnet-name "$VNET" -n snet-web --nsg nsg-web --output none
az network vnet subnet update -g "$RG" --vnet-name "$VNET" -n snet-app --nsg nsg-app --output none
info "nsg-web -> snet-web, nsg-app -> snet-app"

# -----------------------------------------------------------------------------
banner "Task 3 · Web VM (public IP, asg-web) and app VM (private only)"
if exists az vm show -g "$RG" -n vm-web; then
  info "vm-web already exists"
else
  info "Creating vm-web (2-4 minutes)..."
  az vm create -g "$RG" -n vm-web --location "$LOCATION" \
    --image "$VM_IMAGE" --size "$VM_SIZE_SMALL" \
    --vnet-name "$VNET" --subnet snet-web --private-ip-address 10.20.1.4 \
    --public-ip-address pip-vm-web --public-ip-sku Standard \
    --nsg "" --asgs asg-web \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    --custom-data "$AZL_COMMON_DIR/cloud-init-web.yml" --output none
fi
if exists az vm show -g "$RG" -n vm-app; then
  info "vm-app already exists"
else
  info "Creating vm-app (2-4 minutes)..."
  az vm create -g "$RG" -n vm-app --location "$LOCATION" \
    --image "$VM_IMAGE" --size "$VM_SIZE_SMALL" \
    --vnet-name "$VNET" --subnet snet-app --private-ip-address 10.20.2.4 \
    --public-ip-address "" --nsg "" \
    --admin-username "$ADMIN_USER" --generate-ssh-keys \
    --custom-data "$LAB_DIR/app-cloud-init.yml" --output none
fi
az vm list -g "$RG" -d --query "[].{vm:name, private:privateIps, public:publicIps, state:powerState}" -o table

# -----------------------------------------------------------------------------
banner "Task 4 · Traffic tests"
WEB_IP="$(az network public-ip show -g "$RG" -n pip-vm-web --query ipAddress -o tsv)"
info "vm-web public IP: $WEB_IP — waiting for the web server to answer..."
wait_until "vm-web answers HTTP" 300 curl -s -f --max-time 5 "http://$WEB_IP" \
  || note "vm-web did not answer yet; cloud-init may still be running"
curl -s --max-time 10 "http://$WEB_IP" | grep -o '<h1>.*</h1>' || true
if timeout 5 bash -c "</dev/tcp/$WEB_IP/22" 2>/dev/null; then
  note "port 22 on vm-web is OPEN from the internet — check nsg-web"
else
  info "port 22 on vm-web is closed from the internet (expected)"
fi
info "vm-web -> vm-app on 8080 (expect a JSON line):"
run_on vm-web 'curl -s --max-time 5 http://10.20.2.4:8080/ || echo "8080 BLOCKED"'
info "vm-web -> vm-app on 22 (expect 22 BLOCKED):"
run_on vm-web 'timeout 5 bash -c "</dev/tcp/10.20.2.4/22" && echo "22 OPEN" || echo "22 BLOCKED"'

# -----------------------------------------------------------------------------
banner "Task 5 · NAT gateway for the private app tier"
if [[ -z "$(az_q network vnet subnet show -g "$RG" --vnet-name "$VNET" -n snet-app --query natGateway.id)" ]]; then
  info "Before the NAT gateway (expect NO OUTBOUND ACCESS):"
  run_on vm-app 'curl -s --max-time 10 https://api.ipify.org || echo "NO OUTBOUND ACCESS"'
fi
if ! exists az network public-ip show -g "$RG" -n pip-ng-nusa-app; then
  az network public-ip create -g "$RG" -n pip-ng-nusa-app --location "$LOCATION" \
    --sku Standard --allocation-method Static --output none
fi
if ! exists az network nat gateway show -g "$RG" -n ng-nusa-app; then
  az network nat gateway create -g "$RG" -n ng-nusa-app --location "$LOCATION" \
    --public-ip-addresses pip-ng-nusa-app --idle-timeout 4 --output none
fi
az network vnet subnet update -g "$RG" --vnet-name "$VNET" -n snet-app \
  --nat-gateway ng-nusa-app --output none
NAT_IP="$(az network public-ip show -g "$RG" -n pip-ng-nusa-app --query ipAddress -o tsv)"
info "NAT gateway public IP: $NAT_IP — giving the association 30 seconds..."
sleep 30
info "After the NAT gateway (expect $NAT_IP):"
run_on vm-app 'curl -s --max-time 10 https://api.ipify.org || echo "NO OUTBOUND ACCESS"'

# -----------------------------------------------------------------------------
banner "Task 6 · IP flow verify"
MY_IP="$(my_public_ip || true)"
[[ -z "$MY_IP" ]] && MY_IP="13.107.21.200"
ipflow() {  # ipflow <label> <az network watcher test-ip-flow arguments...>
  local label="$1"; shift
  local result
  result="$(az network watcher test-ip-flow -g "$RG" --protocol TCP "$@" \
    --query "[access, ruleName]" -o tsv 2>/dev/null | tr '\n\t' '  ' || true)"
  info "${label}: ${result:-no answer — is Network Watcher enabled in $LOCATION?}"
}
ipflow "web -> app 8080 (expect Allow)" --vm vm-app --direction Inbound --local 10.20.2.4:8080 --remote 10.20.1.4:50000
ipflow "web -> app 22   (expect Deny)"  --vm vm-app --direction Inbound --local 10.20.2.4:22 --remote 10.20.1.4:50000
ipflow "you -> web 22   (expect Deny)"  --vm vm-web --direction Inbound --local 10.20.1.4:22 --remote "$MY_IP:50000"
ipflow "you -> web 80   (expect Allow)" --vm vm-web --direction Inbound --local 10.20.1.4:80 --remote "$MY_IP:50000"
ipflow "app -> internet 443 (expect Allow)" --vm vm-app --direction Outbound --local 10.20.2.4:50000 --remote 13.107.21.200:443

# -----------------------------------------------------------------------------
banner "Task 7 · Public DNS zone $ZONE"
if ! exists az network dns zone show -g "$RG" -n "$ZONE"; then
  az network dns zone create -g "$RG" -n "$ZONE" --output none
  info "Created zone $ZONE"
fi
if ! exists az network dns record-set a show -g "$RG" -z "$ZONE" -n www; then
  az network dns record-set a add-record -g "$RG" -z "$ZONE" -n www -a "$WEB_IP" --ttl 300 --output none
fi
az network dns record-set cname set-record -g "$RG" -z "$ZONE" -n shop -c "www.$ZONE" --ttl 300 --output none
az network dns record-set list -g "$RG" -z "$ZONE" -o table
NS1="$(az network dns zone show -g "$RG" -n "$ZONE" --query "nameServers[0]" -o tsv)"
info "Asking Azure name server $NS1 directly:"
if command -v nslookup >/dev/null 2>&1; then
  nslookup "www.$ZONE" "$NS1" || true
  nslookup "shop.$ZONE" "$NS1" || true
elif command -v dig >/dev/null 2>&1; then
  dig @"$NS1" "www.$ZONE" +short || true
  dig @"$NS1" "shop.$ZONE" +short || true
else
  note "Neither nslookup nor dig is available in this shell."
fi

banner "Done"
info "Every task is complete. Check it with:  bash verify.sh"
info "Delete everything afterwards with:     bash cleanup.sh"
