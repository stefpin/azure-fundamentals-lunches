# Lunch 09 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — creating a Standard load balancer in the portal and
> watching backend health change when a server fails, which the animation can only simulate.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- Run the lab's starting point about 15 minutes before recording, so both VMs have finished booting:

  ```bash
  cd azure-fundamentals-lunches/labs/09-load-balancing-basic
  source ../common/config.sh && source lab.env
  bash setup.sh
  ```

- Do **not** create the public IP or load balancer in advance — you build them on camera (Tasks 2–4 of the lab).
- Browser tabs: (1) the portal open at resource group `rg-lunch09-<suffix>`; (2) Azure Cloud Shell (Bash) with the two
  `source` lines above already run, and the screen cleared.
- Have this command ready to paste in Cloud Shell for the failover scene:
  `az vm run-command invoke -g "$RG" -n "$VM2" --command-id RunShellScript --scripts "systemctl stop nusa-web"`
- After recording, either continue with the lab or run `bash cleanup.sh`.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 Two web servers, no public IPs
00:55 Create a Standard public load balancer
02:15 Health probe and load-balancing rule
03:05 Requests across two zones
03:40 A server fails — and the shop stays open
04:50 Inbound NAT and outbound rules at a glance
05:25 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 09 · Azure Load Balancer — keep the shop open" | "Nusantara Retail has two web servers in two availability zones, but shoppers can only find one of them. In the next five minutes we give both servers one front door and watch it route around a failure." |
| 00:25 | Portal › resource group `rg-lunch09-<suffix>` › `vm-web-1` overview: zone 1, private IP only, no public IP | "Here are the two servers from the lab setup: vm-web-1 in zone 1, vm-web-2 in zone 2. Notice there's no public IP — they sit in a private subnet, and the NSG only allows web traffic and the load balancer's probes." |
| 00:55 | *Create a resource* › *Load Balancer* › Basics: Standard, Public, Regional; region Southeast Asia | "Create a load balancer. SKU Standard — the Basic SKU was retired in September 2025. Type Public, because shoppers come from the internet. Tier Regional; the Global tier is for spreading traffic across regions." |
| 01:30 | *Frontend IP configuration* › Add › create public IP `pip-lb-nusa-web`, Availability zone **Zone-redundant** | "The frontend is the one address shoppers see. I create a new Standard public IP and make it zone-redundant, so it keeps answering even if a zone goes down." |
| 01:55 | *Backend pools* › Add `be-web`, configuration type NIC, add `vm-web-1` and `vm-web-2` | "The backend pool lists the servers that can receive traffic — here, the network interfaces of both VMs." |
| 02:15 | *Inbound rules* › Add a load balancing rule: TCP 80 → 80; create health probe HTTP, port 80, path `/health`, interval 5 | "Now the rule: TCP port 80 on the frontend goes to port 80 in the pool. It needs a health probe: an HTTP GET on slash-health every five seconds. Only servers that answer 200 OK get new connections." |
| 02:45 | Same dialog: *Outbound source network address translation* set to the option that uses outbound rules; *Review + create* › *Create* | "I tell this rule not to handle outbound traffic — we'll give the servers a deliberate way out with an outbound rule. Review, create. Standard load balancers deploy in well under a minute." |
| 03:05 | Cloud Shell: `who_answers 10` | "Let's test from Cloud Shell. This helper sends ten requests to the frontend and prints which server answered. Both zones show up — every new connection is placed by a hash, so it's not strict alternation." |
| 03:40 | Cloud Shell: paste the `systemctl stop nusa-web` command for `vm-web-2`, then `who_answers 10` | "Now I crash the web service on vm-web-2. The VM is still running, but nothing answers on port 80. Within seconds the probe fails, and every answer now comes from vm-web-1. Shoppers didn't need a new address." |
| 04:15 | Portal › load balancer › *Monitoring* › *Metrics* › **Health Probe Status**, split by Backend IP Address | "In the portal, the Health Probe Status metric, split by backend address, shows one server dropping out. Metrics lag a minute or two behind, so the shop recovered before the chart noticed." |
| 04:35 | Cloud Shell: start the service again, `who_answers 6` | "Start the service again, and vm-web-2 rejoins on its own — nobody touched the load balancer." |
| 04:50 | Portal › load balancer › *Inbound NAT rules* and *Outbound rules* blades (empty) | "Two more blades matter. Inbound NAT rules forward one frontend port to one VM — handy for emergency SSH. Outbound rules let the pool reach the internet through the frontend IP. You'll build both in the lab." |
| 05:25 | Recap slide: frontend · pool · probe · rule · NAT · outbound | "Three things to remember: use the Standard SKU, probe something meaningful, and make outbound access explicit. The lab walks you through every step — and the cleanup." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *Standard SKU*, *backend pool*, *health probe*, *SNAT*).
- Add the chapter list to the description.
- Paste the video link into the lunch README (section 🎬 Demo).
- Delete the demo resources: `bash cleanup.sh` in `labs/09-load-balancing-basic`.
- Blur the frontend public IP address in the edit if it is visible in the Cloud Shell or portal shots.
