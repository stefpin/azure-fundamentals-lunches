#!/usr/bin/env bash
# =============================================================================
# Lab 19 · compare-prices.sh — pay-as-you-go vs reservations vs savings plans
# for one VM size, straight from the public Azure Retail Prices API.
#
#   bash compare-prices.sh                                  # uses $VM_SIZE and $LOCATION
#   VM_SIZE=Standard_D2s_v5 bash compare-prices.sh          # another size
#   LOCATION=indonesiacentral bash compare-prices.sh        # another region
#   CURRENCY=EUR bash compare-prices.sh                     # another currency (USD is the default)
#
# The API needs no sign-in and this script creates nothing, so it costs nothing.
# Prices are retail list prices for Linux; your agreement may differ.
# =============================================================================
set -euo pipefail
AZL_QUIET=1 source "$(dirname "$0")/../common/config.sh"
CURRENCY="${CURRENCY:-USD}"

banner "Retail prices for ${VM_SIZE} (Linux) in ${LOCATION}, ${CURRENCY}"
VM_SIZE="$VM_SIZE" LOCATION="$LOCATION" CURRENCY="$CURRENCY" python3 - <<'PY'
import json, os, sys, urllib.parse, urllib.request

size, region, currency = os.environ["VM_SIZE"], os.environ["LOCATION"], os.environ["CURRENCY"]
flt = (f"serviceName eq 'Virtual Machines' and armRegionName eq '{region}' "
       f"and armSkuName eq '{size}'")
url = ("https://prices.azure.com/api/retail/prices?api-version=2023-01-01-preview"
       f"&currencyCode='{currency}'&$filter=" + urllib.parse.quote(flt))
items = []
try:
    while url:
        with urllib.request.urlopen(url, timeout=30) as resp:
            page = json.load(resp)
        items += page.get("Items", [])
        url = page.get("NextPageLink")
except Exception as err:
    print(f"   Could not read the Azure Retail Prices API: {err}")
    print("   Check the region, size and currency names, or use the pricing calculator instead.")
    sys.exit(1)

def linux(i):
    text = (i.get("productName", "") + " " + i.get("meterName", "")).lower()
    return "windows" not in text and "spot" not in text and "low priority" not in text

primary = [i for i in items if i.get("isPrimaryMeterRegion", True) and linux(i)]
payg = next((i for i in primary if i.get("type") == "Consumption"), None)
if payg is None:
    print(f"   No pay-as-you-go Linux price found for {size} in {region}.")
    print("   Check the size name (case matters, for example Standard_D2s_v5) and the region.")
    sys.exit(1)

hourly = payg["retailPrice"]
rows = [("Pay-as-you-go", hourly, "")]
for term, years in (("1 Year", 1), ("3 Years", 3)):
    ri = next((i for i in primary if i.get("type") == "Reservation" and i.get("reservationTerm") == term), None)
    if ri:
        # Reservation prices in the API are for the whole term, so divide by the hours in the term.
        rows.append((f"{years}-year reservation", ri["retailPrice"] / (8760 * years),
                     f"(whole term: {ri['retailPrice']:,.2f})"))
    sp = next((p for p in payg.get("savingsPlan", []) if p.get("term") == term), None)
    if sp:
        rows.append((f"{years}-year savings plan", sp["retailPrice"], ""))

print(f"   {'Option':<24}{'per hour':>12}{'per month (730 h)':>20}{'vs pay-as-you-go':>18}")
for name, per_hour, extra in rows:
    saving = "" if name == "Pay-as-you-go" else f"{(1 - per_hour / hourly) * 100:.0f}% less"
    print(f"   {name:<24}{per_hour:>12.4f}{per_hour * 730:>20.2f}{saving:>18}  {extra}")
if len(rows) == 1:
    print("   No reservation or savings plan prices were returned for this size. Try another size,")
    print("   for example: VM_SIZE=Standard_D2s_v5 bash compare-prices.sh")
print()
print("   Break-even: a one-year reservation only pays off if the VM would otherwise run more than")
ri1 = next((r for r in rows if r[0] == "1-year reservation"), None)
if ri1:
    print(f"   about {ri1[1] / hourly * 100:.0f}% of the hours in the year at pay-as-you-go rates.")
else:
    print("   the reservation price divided by the pay-as-you-go price, as a share of the year.")
PY
info "Source: Azure Retail Prices API (prices.azure.com). Compare with the pricing calculator in Task 6."
