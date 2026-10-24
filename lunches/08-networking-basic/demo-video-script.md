# Lunch 08 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: building a virtual
> network with private subnets, reading NSG rules in priority order, and getting evidence from IP flow verify.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- In Cloud Shell, run the Lab 08 reference solution once so the VMs, NAT gateway and DNS zone already exist
  (about 15 minutes):
  `cd azure-fundamentals-lunches/labs/08-networking-basic && bash solution.sh`
- Keep everything exactly as the solution builds it. During the recording you create a *second, empty* VNet
  (`vnet-demo-record`, `10.99.0.0/16`) only to show the creation wizard, and you delete it afterwards.
- Browser tabs to open in advance:
  1. Portal › **Virtual networks** (list view)
  2. Portal › `nsg-app` › **Inbound security rules**
  3. Portal › **Network Watcher › IP flow verify**
  4. Portal › `ng-nusa-app` (NAT gateway) › **Outbound IP**
- Note your own public IP (`curl -s https://api.ipify.org` in Cloud Shell) for the IP flow verify step, but keep it off
  screen or blur it in editing.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 Create a virtual network with private subnets
01:35 NSG rules in priority order
02:35 Application security groups and effective rules
03:30 IP flow verify: allowed and denied
04:35 The NAT gateway gives the app tier a way out
05:20 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 08 · Virtual networking in the portal" | "In the next five minutes we'll look at the storefront network in the portal: private subnets, network security group rules in priority order, and how to prove a rule works with IP flow verify." |
| 00:25 | Portal › Virtual networks › **+ Create**; Basics tab, name `vnet-demo-record` | "Creating a virtual network takes a minute. Region first — production for Nusantara Retail would be Indonesia Central; the labs use Southeast Asia." |
| 00:50 | **IP addresses** tab: change the space to `10.99.0.0/16`, open the default subnet | "The address space is the plan. We never overlap head office's 10.0.0.0/16. Inside the subnet settings, notice the private subnet option: it's on by default, so VMs here get no default outbound internet access." |
| 01:20 | Review + create (don't wait for completion), switch to tab 2 | "That's the whole wizard. Now let's look at the network we built in the lab." |
| 01:35 | `nsg-app` › **Inbound security rules**, default rules visible | "This is nsg-app on the app subnet. Two rules of ours at the top, three default rules at the bottom. Azure reads them from the lowest number up, and the first match wins." |
| 02:00 | Hover rule 100, then rule 4000, then AllowVnetInBound at 65000 | "Rule 100 allows the web servers to reach port 8080. Rule 4000 denies everything else from inside the virtual network — which matters, because the default rule at 65000 would otherwise allow it." |
| 02:35 | Open rule 100: **Source = Application security group**, `asg-web` | "The source isn't an IP address. It's an application security group, asg-web. Any VM whose network interface joins that group is covered — no rule edits when Dewi adds a third web server." |
| 03:00 | `vm-app` › Networking › **Effective security rules** | "Effective security rules show the merged view the platform actually applies, with the group and the service tags expanded into real addresses. When in doubt, trust this view over your notes." |
| 03:30 | Tab 3: **IP flow verify**; VM `vm-app`, inbound, TCP, local `10.20.2.4:8080`, remote `10.20.1.4:50000` › Check | "IP flow verify tests one packet against the rules without sending anything. Web server to app server on 8080: Access allowed, and it names the rule — Allow-Web-To-App-8080." |
| 04:00 | Change local port to `22` › Check | "Same source, port 22: denied, by Deny-VNet-Inbound. If someone ever adds a sneaky rule at priority 90, this tool tells you its name in seconds." |
| 04:20 | Change VM to `vm-web`, local `10.20.1.4:22`, remote your IP (blurred) › Check | "And SSH from the internet to the web server: denied by the default DenyAllInBound. The Standard public IP stays closed unless a rule opens it." |
| 04:35 | Tab 4: NAT gateway › **Outbound IP**, then **Subnets** | "The app tier has no public IP and lives in a private subnet, so it has no way out by default. This NAT gateway is attached to snet-app and gives every VM there one static outbound address — and accepts nothing inbound." |
| 05:00 | Cloud Shell: `az vm run-command invoke … vm-app … curl -s https://api.ipify.org` result | "Proof: from inside vm-app, the internet sees exactly the NAT gateway's address. Payment providers can allow-list it." |
| 05:20 | Recap slide: "Plan · Rules · Path · Evidence" | "Three things to remember: plan addresses that never overlap; rules are read lowest number first and the first match wins; and an allow rule is permission, not a path. Now build it yourself in Lab 08." |

## After recording

- Delete the demo VNet: `az network vnet delete -g <its resource group> -n vnet-demo-record`
- Delete the lab resources: `bash cleanup.sh` in `labs/08-networking-basic`
- Add captions (auto-generate, then correct Azure terms by hand: NSG, ASG, CIDR, NAT gateway, IP flow verify)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
