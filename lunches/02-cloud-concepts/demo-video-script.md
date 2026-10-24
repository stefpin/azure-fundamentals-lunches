# Lunch 02 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: using the Azure
> pricing calculator to compare a VM-based (IaaS) design with a PaaS design for Nusantara Retail's storefront.
> **Length target:** 5½ minutes (short videos keep attention; split anything longer).
> **Record in:** a browser profile that is not signed in to a company account. The calculator needs no subscription; if
> you sign in to save estimates, use a personal or dedicated demo account — never a company one.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- Open `https://azure.microsoft.com/pricing/calculator/` and, if an old estimate loads, select **Reset now** or clear the
  estimate so you start empty.
- Choose the currency you will use for the whole video and keep it.
- Have the Lab 02 requirements card (Task 1 of the lab) open in a second tab to glance at.
- Decide in advance not to read prices aloud: prices change and differ by region. Talk about *which* line is bigger and
  *why*, not about the exact numbers.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 A quick tour of the pricing calculator
01:00 Design A: lift and shift to virtual machines
02:40 Design B: App Service and Azure SQL Database
04:00 Savings options and a second region
05:00 Export, share, and what the calculator cannot see
05:30 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 02 · Pricing two designs for the storefront" | "Ibu Sari wants to know what moving the storefront to Azure costs. In five minutes we'll price two designs side by side: virtual machines, and platform services." |
| 00:20 | Calculator home: **Products** tab, search box, **Your estimate** area | "The pricing calculator is free and needs no Azure account. Search for a product, add it, and configure it in Your estimate. Pick one currency at the start and keep it." |
| 00:45 | Point at the **Region** field on an item | "Every item has its own region. Nusantara's customer data should stay in Indonesia, so we use Indonesia Central. If something isn't offered there, we'll note it and use Southeast Asia." |
| 01:00 | Add **Virtual Machines**: Linux, Standard, D2s v5, 2 VMs, 730 hours, pay as you go | "Design A is lift and shift. Two web servers, because one server is exactly the problem we're trying to solve. Two vCPUs and eight gigabytes each, running all month: 730 hours." |
| 01:40 | Same item: managed disk Premium SSD P6 | "Each VM needs an OS disk. Premium SSD for the web servers." |
| 01:55 | Add a second **Virtual Machines** item: D4s v5, 1 VM; add **Managed Disks** P15 | "The database gets its own, larger VM and a 256-gigabyte data disk. On a VM, installing, patching and backing up that database is our job." |
| 02:20 | Add **Load Balancer** (Standard) and **Bandwidth** (100 GB out) | "A Standard load balancer spreads traffic across the two web servers, and bandwidth covers data sent to customers. Notice how many line items IaaS needs." |
| 02:40 | Scroll down: add **App Service**: Linux, Premium v3, P1v3, 2 instances, 730 hours | "Design B is PaaS. The same two instances of two vCPUs and eight gigabytes, but now Microsoft runs the operating system and the web server underneath." |
| 03:15 | Add **Azure SQL Database**: single database, vCore, General Purpose, provisioned, 2 vCores, 256 GB | "The database becomes Azure SQL Database: patching, high availability and backups are part of the service." |
| 03:45 | Add **Bandwidth** (100 GB) for Design B; compare the subtotals | "Same bandwidth, so the comparison is fair. Fewer items, and fewer things for Pak Budi to look after at two in the morning." |
| 04:00 | On the web VM item, switch **Savings options** to a 1-year commitment; watch the monthly figure | "Steady, round-the-clock workloads are good candidates for one- or three-year commitments. Compare like with like: if you discount one design, look for the same option on the other." |
| 04:30 | Change one item's region to Southeast Asia, then back | "Prices differ by region. A small saving elsewhere has to be weighed against keeping data in Indonesia." |
| 05:00 | Select **Export** (spreadsheet) and **Share** | "Export the estimate for the finance team, or share a link. And remember what the calculator can't see: the hours your team spends patching, backing up and getting up at night." |
| 05:30 | Recap slide: three bullets | "Three things to remember: price both designs with the same requirements; compare like with like; and count people time, not just the bill. Your turn in Lab 02." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: App Service, Azure SQL Database, Premium v3, vCore).
- Add the chapter list to the description.
- Paste the video link into the lunch README (section 🎬 Demo).
- Nothing to delete in Azure: the calculator creates no resources. Clear or delete the demo estimate if you saved it.
