# Lunch 26 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: a zone-redundant VPN
> gateway, a VNet-to-VNet connection reaching *Connected*, traffic crossing the tunnel, the route Azure adds, and where
> ExpressRoute and Virtual WAN choices live in the portal.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, the gateways' public IP addresses, and the shared
> key (never run `shared-key show` on camera).

## Setup before you press record

- **At least an hour before recording**, in Cloud Shell (Bash):

  ```bash
  cd azure-fundamentals-lunches/labs/26-hybrid-connectivity
  source ../common/config.sh
  RG=$(rg_name 26)
  bash setup.sh            # starts two VpnGw1AZ gateways; they need 30-45 minutes or more
  ```

- When both gateways show `Succeeded`, do Lab 26 Task 4 (the two connections) off camera, or keep it for the recording
  if you are happy to cut while the status changes from *Connecting* to *Connected*.
- Run the Task 6 traffic test once off camera so the Run Command extension is already installed on `vm-azure-1`.
- **Cost reminder:** the two gateways bill every hour they exist. Record on the same day and run `bash cleanup.sh`
  straight afterwards.
- Browser tabs to open in advance:
  1. `vgw-nusa-azure` › **Overview** and **Configuration**
  2. `vnet-nusa-azure` › **Subnets**
  3. `vgw-nusa-azure` › **Connections**
  4. `vm-azure-1` › **Networking** › network interface › **Effective routes**
  5. **Create a resource** › ExpressRoute (circuit creation form — you won't submit it)
  6. **Create a resource** › Virtual WAN (creation form — you won't submit it)
  7. Cloud Shell (Bash) in the lab folder, font size increased, with `RG` set

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 Two networks and their GatewaySubnets
01:00 A zone-redundant VPN gateway
01:45 VNet-to-VNet connections: Connected
02:35 Traffic through the tunnel
03:20 The route Azure added
04:00 Where ExpressRoute and Virtual WAN choices live
05:15 Recap and cleanup
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 26 · Connect head office" | "Nusantara Retail's head office in Jakarta needs a private path to Azure. In the next five minutes we'll look at a real VPN gateway, bring up an encrypted tunnel, and see where ExpressRoute and Virtual WAN fit." |
| 00:25 | `vnet-nusa-azure` › **Subnets**: `snet-app` and `GatewaySubnet` (/27); then the head-office VNet's address space 10.0.0.0/16 | "Two virtual networks: Azure on 10.40.0.0/16, and a simulated head office on 10.0.0.0/16. The ranges don't overlap — that's planned on purpose. Each has a subnet called exactly GatewaySubnet, a /27, with nothing else in it and no network security group." |
| 01:00 | `vgw-nusa-azure` › **Overview**: SKU **VpnGw1AZ**, VPN type **Route-based**, generation 1 | "This is the Azure side's VPN gateway. The SKU is VpnGw1AZ — the AZ SKUs are the ones to use for new gateways — and it's route-based, which point-to-site, BGP and active-active all require." |
| 01:25 | `vgw-nusa-azure` › **Configuration**: active-active **Disabled**, BGP **Disabled**; then the public IP resource showing zones 1, 2, 3 (blur the address) | "For this lab it runs active-standby without BGP. In production I'd enable both. Its Standard public IP is zone-redundant, so a zone failure in the region doesn't take the address with it. Creating this gateway took about forty minutes." |
| 01:45 | `vgw-nusa-azure` › **Connections**: `con-azure-to-hq` and `con-hq-to-azure`, status **Connected** | "Two connections, one in each direction, both using the same pre-shared key that the lab generated at run time. Status: Connected. That means IKE agreed on keys and algorithms and the IPsec security associations are up." |
| 02:10 | Open `con-azure-to-hq`: data in and data out counters | "The connection shows how many bytes went in and out. Those counters are the first thing to check when someone says the VPN is down." |
| 02:35 | Cloud Shell: Task 6 Run Command — `ping` and `curl` from `vm-azure-1` to 10.0.1.10 | "Now real traffic. From the Azure VM I ping the head-office VM's private address, 10.0.1.10, and fetch its web page. Neither VM has a public IP; the packets travel encrypted between the two gateways." |
| 03:00 | Output: 4 replies, then "Served by vm-hq-1" | "Replies, and the page says it was served by vm-hq-1. Before the connections existed, the same command lost every packet." |
| 03:20 | `vm-azure-1` NIC › **Effective routes**: row 10.0.0.0/16 · **Virtual network gateway** | "Why did it work? Azure added a route for 10.0.0.0/16 with the virtual network gateway as next hop. Before the connection, that address range fell into a built-in route that simply drops traffic." |
| 04:00 | **Create ExpressRoute circuit** form: port type, peering location list (scroll to Jakarta), bandwidth, SKU Local/Standard/Premium, billing Metered/Unlimited — then **Cancel** | "For heavier, steady traffic, ExpressRoute is the private alternative. Here you pick a provider and peering location — Jakarta has several — a bandwidth, a SKU, and metered or unlimited billing. I won't submit this: a real circuit needs a provider." |
| 04:40 | **Create Virtual WAN** form: type **Basic** vs **Standard** — then **Cancel** | "And when forty stores join, Virtual WAN gives you managed hubs. Basic does site-to-site VPN only; Standard adds ExpressRoute, user VPN, transit between networks and Azure Firewall." |
| 05:15 | Cloud Shell: `bash cleanup.sh` | "Three things to remember: plan addresses that never overlap, always choose an AZ SKU and pass it explicitly, and delete gateways the same day in a lab — they bill every hour. Cleanup is running now." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: GatewaySubnet, VpnGw1AZ, IKE, IPsec, ExpressRoute).
- Add the chapter list to the description.
- Paste the video link into the lunch README (section 🎬 Demo).
- Make sure the demo resources are gone: `az group list --tag lunch=26 --output table` should list nothing after a few minutes.
