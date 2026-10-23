# Lunch 25 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: Connected peerings,
> a user-defined route winning in the effective routes, Network Watcher naming the next hop, a hub VM that really
> forwards packets, and a private endpoint name resolving to a private IP.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- In Cloud Shell, build the finished lab once (about 15 minutes):
  `cd azure-fundamentals-lunches/labs/25-networking-advanced && bash setup.sh && bash solution.sh`
- Add a storage account with a private endpoint in the hub, for the DNS part (about 3 minutes, small hourly charge for
  the endpoint):

  ```bash
  source ../common/config.sh
  RG="$(rg_name 25)"; ST="stnusa25${SUFFIX}"
  az network vnet subnet create -g "$RG" --vnet-name vnet-nusa-hub -n snet-endpoints \
    --address-prefixes 10.30.3.0/24 --default-outbound-access false --output none
  az storage account create -g "$RG" -n "$ST" -l "$LOCATION" --sku Standard_LRS --kind StorageV2 --output none
  az storage account update -g "$RG" -n "$ST" --public-network-access Disabled --output none
  az network private-endpoint create -g "$RG" -n pe-stnusa --vnet-name vnet-nusa-hub --subnet snet-endpoints \
    --private-connection-resource-id "$(az storage account show -g "$RG" -n "$ST" --query id -o tsv)" \
    --group-id blob --connection-name pe-stnusa-conn --output none
  az network private-dns zone create -g "$RG" -n privatelink.blob.core.windows.net --output none
  az network private-dns link vnet create -g "$RG" --zone-name privatelink.blob.core.windows.net -n link-spoke1 \
    --virtual-network vnet-nusa-spoke1 --registration-enabled false --output none
  az network private-endpoint dns-zone-group create -g "$RG" --endpoint-name pe-stnusa -n default \
    --private-dns-zone privatelink.blob.core.windows.net --zone-name blob --output none
  ```

- Prepare two commands in Cloud Shell (don't run them yet): the forwarded-packet test from Lab 25 Task 6, and the
  `nslookup` pair used at 04:35.
- Browser tabs to open in advance:
  1. Portal › `vnet-nusa-hub` › **Peerings**
  2. Portal › `vm-spoke1`'s network interface › **Effective routes**
  3. Portal › **Network Watcher › Next hop**
  4. Portal › `vm-hub-nva`'s network interface › **IP configurations**
  5. Portal › `pe-stnusa` (private endpoint) › **DNS configuration**

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 Peerings: Connected, and forwarded traffic allowed
01:00 Effective routes: the user-defined route wins
01:45 Next hop names the appliance
02:25 Turning the hub VM into a router
03:05 Proof: packets forwarded by the hub
03:50 Private endpoint DNS: name, alias, private IP
05:20 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 25 · Hub and spoke in the portal" | "In the next five minutes we'll follow one packet from the storefront spoke to the back-office spoke through a router in the hub — and then watch a storage name turn into a private IP address." |
| 00:20 | Tab 1: `vnet-nusa-hub` › Peerings, both links *Connected* | "The hub has two peerings, one to each spoke, and both say Connected. That only happens when each side has its own link. Notice there's no peering between the two spokes — on purpose." |
| 00:40 | Open `vnet-nusa-spoke1` › Peerings › `peer-spoke1-to-hub` | "On the spoke's own link, the setting that lets it receive forwarded traffic is switched on. Without it, packets that the hub's router forwards into this spoke would be turned away at the door." |
| 01:00 | Tab 2: effective routes of `vm-spoke1`'s NIC, full list | "These are the routes Azure really applies to vm-spoke1. Its own range goes to the virtual network, the hub's range to the peering, and the big private blocks like 10.0.0.0/8 go to None — dropped." |
| 01:20 | Highlight the row `10.32.0.0/16 · User · Virtual appliance · 10.30.1.4` | "This row is ours: the back office's range, source User, next hop a virtual appliance at 10.30.1.4. It's more specific than the /8, so it wins. Without it, the storefront could never reach the back office — peering isn't transitive." |
| 01:45 | Tab 3: Next hop, VM `vm-spoke1`, source `10.31.1.4`, destination `10.32.1.4` › Next hop | "Effective routes show the whole table; next hop answers one question. From the storefront VM to the back-office VM: virtual appliance, 10.30.1.4, and it even names the route table that made the decision." |
| 02:05 | Swap to `vm-spoke2`, source `10.32.1.4`, destination `10.31.1.4` › Next hop | "And the reply: same appliance. Routes come in pairs; if this answer were different, a firewall would only ever see half of each conversation." |
| 02:25 | Tab 4: `vm-hub-nva`'s NIC › IP configurations, **IP forwarding: Enabled** | "Now the router itself. By default Azure drops any packet that arrives at a network interface but is addressed to someone else. This checkbox — IP forwarding — tells Azure the VM is allowed to pass traffic on." |
| 02:45 | Cloud Shell: the `/etc/sysctl.d/99-nusa-router.conf` line from the lab | "The second switch lives in Linux: net.ipv4.ip_forward. The lab sets it through Run Command and writes it to a file so it survives a reboot. Miss either switch and the packet dies in the hub." |
| 03:05 | Cloud Shell: run the Task 6 test — counter, ping and curl from `vm-spoke1`, counter again | "Proof, not hope. We read the hub's forwarded-packet counter, ping and fetch the back-office web page from the storefront VM, then read the counter again." |
| 03:30 | Zoom on the output: replies from `10.32.1.4`, `HTTP from vm-spoke2: OK`, counter higher | "Replies came back, the page loaded, and the hub's counter went up. The traffic really took the long way through the hub — exactly where Azure Firewall would sit in production." |
| 03:50 | Tab 5: `pe-stnusa` › DNS configuration: FQDN `…blob.core.windows.net`, IP `10.30.3.4` | "Second story: the invoices storage account. Its public access is disabled; this private endpoint gave it a network interface in the hub with the address 10.30.3.4." |
| 04:10 | Private DNS zone `privatelink.blob.core.windows.net` › Recordsets, then **Virtual network links** | "The private DNS zone holds an A record for the account, and the zone is linked to the storefront spoke. That link is the whole trick — any VNet without it never sees this record." |
| 04:35 | Cloud Shell: `nslookup <account>.blob.core.windows.net` (or `dig` if nslookup is missing) | "From Cloud Shell, outside our networks, the name goes through a privatelink alias and ends at a public address. Connections there are refused, because public network access is off." |
| 04:55 | Cloud Shell: `az vm run-command invoke … vm-spoke1 … nslookup <account>.blob.core.windows.net` output | "Ask the same question from vm-spoke1: same public name, same alias, but now the linked zone answers with 10.30.3.4. The app's connection string never changes; DNS decides which door it uses." |
| 05:20 | Recap slide: "Peer · Route · Forward · Resolve" | "Three things to remember: peering is not transitive, so spoke-to-spoke needs a route through the hub; an appliance needs IP forwarding on the NIC and in the OS; and a private endpoint only works when its private zone is linked to your VNet. Build it yourself in Lab 25." |

## After recording

- Delete everything, including the private endpoint and storage account: `bash cleanup.sh` in
  `labs/25-networking-advanced`
- Add captions (auto-generate, then correct Azure terms by hand: peering, UDR, next hop, NVA, privatelink, Private
  Resolver)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
