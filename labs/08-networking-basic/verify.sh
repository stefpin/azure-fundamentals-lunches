#!/usr/bin/env bash
# =============================================================================
# Lab 08 · verify.sh — checks the Challenge brief and prints PASS/FAIL per check.
#   bash verify.sh
# Read-only: it creates nothing. Takes about 3 minutes, because it sends real
# test traffic through Run Command and asks IP flow verify about key rules.
# =============================================================================
set -uo pipefail
# shellcheck source=../common/config.sh
source "$(dirname "$0")/../common/config.sh"
require_az

RG="$(rg_name 08)"
VNET="vnet-nusa-shop"

# run_on <vm> <script>  -> output of a Run Command script (empty if it could not run)
run_on() {
  az vm run-command invoke -g "$RG" -n "$1" --command-id RunShellScript \
    --scripts "$2" --query "value[0].message" -o tsv 2>/dev/null || true
}
# flow <vm> <direction> <local ip:port> <remote ip:port>  -> Allow, Deny or empty
flow() {
  az network watcher test-ip-flow -g "$RG" --vm "$1" --direction "$2" --protocol TCP \
    --local "$3" --remote "$4" --query access -o tsv 2>/dev/null || true
}
# running <vm>  -> true when the VM is running
running() {
  [[ "$(az_q vm get-instance-view -g "$RG" -n "$1" \
    --query "instanceView.statuses[?starts_with(code, 'PowerState/')].code | [0]")" == "PowerState/running" ]]
}

banner "Resource group"
rg_exists="$(az_q group exists -n "$RG")"
if [[ "${rg_exists,,}" != "true" ]]; then
  fail "Resource group $RG not found — start with Task 1"
  summary
  exit 1
fi
pass "Resource group $RG exists"

banner "Virtual network and private subnets (Task 1)"
check_contains "VNet $VNET has the address space 10.20.0.0/16" "10.20.0.0/16" \
  "$(az_q network vnet show -g "$RG" -n "$VNET" --query "join(',', addressSpace.addressPrefixes)")"
for spec in "snet-web 10.20.1.0/24 nsg-web" "snet-app 10.20.2.0/24 nsg-app"; do
  read -r snet prefix nsg <<< "$spec"
  check_contains "$snet uses $prefix" "$prefix" \
    "$(az_q network vnet subnet show -g "$RG" --vnet-name "$VNET" -n "$snet" --query "to_string([addressPrefix, addressPrefixes])")"
  check_eq "$snet is a private subnet (defaultOutboundAccess = false)" "false" \
    "$(az_q network vnet subnet show -g "$RG" --vnet-name "$VNET" -n "$snet" --query defaultOutboundAccess)"
  check_contains "$snet is associated with $nsg (Task 2)" "/networkSecurityGroups/$nsg" \
    "$(az_q network vnet subnet show -g "$RG" --vnet-name "$VNET" -n "$snet" --query networkSecurityGroup.id)"
done

banner "Application security group and VMs (Tasks 2–3)"
check_nonempty "Application security group asg-web exists" "$(az_q network asg show -g "$RG" -n asg-web --query id)"
WEB_NIC_ID="$(az_q vm show -g "$RG" -n vm-web --query "networkProfile.networkInterfaces[0].id")"
APP_NIC_ID="$(az_q vm show -g "$RG" -n vm-app --query "networkProfile.networkInterfaces[0].id")"
check_nonempty "VM vm-web exists" "$WEB_NIC_ID"
check_nonempty "VM vm-app exists" "$APP_NIC_ID"

WEB_PRIV=""; APP_PRIV=""; WEB_IP=""
if [[ -n "$WEB_NIC_ID" ]]; then
  WEB_PRIV="$(az_q network nic show --ids "$WEB_NIC_ID" --query "ipConfigurations[0].privateIPAddress || ipConfigurations[0].privateIpAddress")"
  check_contains "vm-web's NIC is a member of asg-web" "/applicationSecurityGroups/asg-web" \
    "$(az_q network nic show --ids "$WEB_NIC_ID" --query "to_string(ipConfigurations[].applicationSecurityGroups[].id)")"
  check_eq "vm-web has no NIC-level NSG (rules live on the subnet)" "" \
    "$(az_q network nic show --ids "$WEB_NIC_ID" --query networkSecurityGroup.id)"
  WEB_PIP_ID="$(az_q network nic show --ids "$WEB_NIC_ID" --query "ipConfigurations[0].publicIPAddress.id || ipConfigurations[0].publicIpAddress.id")"
  check_nonempty "vm-web has a public IP address" "$WEB_PIP_ID"
  if [[ -n "$WEB_PIP_ID" ]]; then
    check_eq "vm-web's public IP uses the Standard SKU" "Standard" \
      "$(az_q network public-ip show --ids "$WEB_PIP_ID" --query sku.name)"
    WEB_IP="$(az_q network public-ip show --ids "$WEB_PIP_ID" --query ipAddress)"
  fi
fi
if [[ -n "$APP_NIC_ID" ]]; then
  APP_PRIV="$(az_q network nic show --ids "$APP_NIC_ID" --query "ipConfigurations[0].privateIPAddress || ipConfigurations[0].privateIpAddress")"
  check_eq "vm-app has no public IP address" "" \
    "$(az_q network nic show --ids "$APP_NIC_ID" --query "ipConfigurations[0].publicIPAddress.id || ipConfigurations[0].publicIpAddress.id")"
  check_eq "vm-app has no NIC-level NSG (rules live on the subnet)" "" \
    "$(az_q network nic show --ids "$APP_NIC_ID" --query networkSecurityGroup.id)"
fi

banner "NAT gateway on snet-app (Task 5)"
NAT_ID="$(az_q network vnet subnet show -g "$RG" --vnet-name "$VNET" -n snet-app --query natGateway.id)"
check_nonempty "snet-app has a NAT gateway attached" "$NAT_ID"
NAT_IP=""
if [[ -n "$NAT_ID" ]]; then
  NAT_PIP_ID="$(az_q network nat gateway show --ids "$NAT_ID" --query "publicIpAddresses[0].id")"
  check_nonempty "The NAT gateway has a public IP address" "$NAT_PIP_ID"
  if [[ -n "$NAT_PIP_ID" ]]; then
    NAT_IP="$(az_q network public-ip show --ids "$NAT_PIP_ID" --query ipAddress)"
  fi
fi

banner "Rules in action (Tasks 4–6) — this part takes a few minutes"
if [[ -n "$WEB_IP" ]]; then
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://$WEB_IP" 2>/dev/null || true)"
  check_eq "HTTP from the internet to vm-web returns 200" "200" "$code"
fi

MY_IP="$(my_public_ip 2>/dev/null || true)"
[[ -z "$MY_IP" ]] && MY_IP="13.107.21.200"
if [[ -n "$WEB_PRIV" ]]; then
  if running vm-web; then
    check_eq "IP flow verify: SSH from the internet to vm-web is denied" "Deny" \
      "$(flow vm-web Inbound "$WEB_PRIV:22" "$MY_IP:50000")"
  else
    fail "vm-web is not running — start it with: az vm start -g $RG -n vm-web"
  fi
fi
if [[ -n "$APP_PRIV" && -n "$WEB_PRIV" ]]; then
  if running vm-app; then
    check_eq "IP flow verify: vm-web -> vm-app on TCP 8080 is allowed" "Allow" \
      "$(flow vm-app Inbound "$APP_PRIV:8080" "$WEB_PRIV:50000")"
    check_eq "IP flow verify: vm-web -> vm-app on TCP 22 is denied" "Deny" \
      "$(flow vm-app Inbound "$APP_PRIV:22" "$WEB_PRIV:50000")"
  else
    fail "vm-app is not running — start it with: az vm start -g $RG -n vm-app"
  fi
fi
if [[ -n "$APP_PRIV" ]] && running vm-web; then
  out="$(run_on vm-web "curl -s --max-time 5 http://$APP_PRIV:8080/ || echo APP-UNREACHABLE")"
  check_contains "A real request from vm-web reaches the app tier on 8080" "nusantara-retail-app-tier" "$out"
fi
if [[ -n "$NAT_IP" ]] && running vm-app; then
  out="$(run_on vm-app 'curl -s --max-time 10 https://api.ipify.org || curl -s --max-time 10 https://ifconfig.me || echo NO-OUTBOUND')"
  check_contains "vm-app's outbound traffic leaves from the NAT gateway IP $NAT_IP" "$NAT_IP" "$out"
fi

banner "Public DNS zone (Task 7)"
ZONE="$(az_q network dns zone list -g "$RG" --query "[0].name")"
check_nonempty "A public DNS zone exists in $RG" "$ZONE"
if [[ -n "$ZONE" ]]; then
  a_json="$(az network dns record-set a show -g "$RG" -z "$ZONE" -n www -o json 2>/dev/null || true)"
  check_contains "www.$ZONE is an A record for vm-web's public IP" "\"${WEB_IP:-no-public-ip}\"" "$a_json"
  c_json="$(az network dns record-set cname show -g "$RG" -z "$ZONE" -n shop -o json 2>/dev/null || true)"
  check_contains "shop.$ZONE is a CNAME for www.$ZONE" "www.$ZONE" "$c_json"
fi

summary
