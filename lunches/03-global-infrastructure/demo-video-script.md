# Lunch 03 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: finding regions and
> their pairs, checking whether a service is offered in a region, and the zone choices you meet when you create resources.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- Nothing needs to exist in Azure. You stop every portal "Create" page **before** the Review + create step, so the
  recording creates no resources and costs nothing.
- Open these browser tabs in advance:
  1. [List of Azure regions](https://learn.microsoft.com/azure/reliability/regions-list) (Asia Pacific tab selected).
  2. [Products available by region](https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/).
  3. Azure portal › **Create a virtual machine** (Basics tab), signed in to the demo subscription.
  4. Azure portal › **Create public IP address**.
  5. Azure portal › **Create a storage account** (Basics tab).
  6. Azure Cloud Shell (Bash) with the repository cloned and `source labs/common/config.sh` already run, so the region
     commands are one keystroke away. Clear the screen afterwards (`clear`).
- Optional: in Cloud Shell, run `az account list-locations --output none` once before recording so the first real
  command answers quickly.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 Regions, geographies and pairs in the region list
01:15 Is my service offered in this region?
02:05 Zone choices when you create a VM
03:05 Zone choices for a public IP and a storage account
04:05 Pairs and zone mapping from Cloud Shell
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 03 · Regions, zones and pairs in the real portal" | "In the next five minutes we'll look at where Azure resources actually live: regions, availability zones and region pairs, and where those choices show up when you create something." |
| 00:25 | Region list page, Asia Pacific tab. Point at Indonesia Central, Southeast Asia and East Asia rows. | "This is Microsoft's list of regions. Indonesia Central in Jakarta has three availability zones and no paired region. Southeast Asia in Singapore also has three zones, and its pair is East Asia in Hong Kong. Notice the geography column: Jakarta is in the Indonesia geography, Singapore and Hong Kong in Asia Pacific." |
| 00:55 | Scroll to a region marked N/A in the paired-region column (for example Malaysia West). | "Many newer regions show N/A here. No pair doesn't mean no disaster recovery. It means you choose the second region yourself." |
| 01:15 | Products-by-region page. Choose Indonesia Central and Southeast Asia, search for a service such as Azure Container Apps. | "Before you commit to a region, check that every service you need is offered there. Here I compare Jakarta and Singapore for one service. A newer region can start with a smaller catalogue." |
| 01:45 | Same page, search for a second service you plan to use (for example Azure Cosmos DB). | "Do this for every service in your design, and for the specific tiers and sizes, not just the product name." |
| 02:05 | Portal › Create a virtual machine › Basics. Open the **Region** dropdown and type "Asia". | "The region dropdown groups regions by geography. I'll pick Southeast Asia." |
| 02:25 | **Availability options** dropdown: show "Availability zone" and the zone picker. Select zones 1 and 2 if the portal offers multi-select. | "Here is the zonal choice. A VM always lives in exactly one zone. If the portal lets me pick several zones, it simply creates one VM per zone. That's how you spread web servers so a zone failure doesn't take the shop down." |
| 02:50 | Change **Size** › "See all sizes". Hover over a size that is unavailable in a zone, if any. | "Sizes can differ per region and even per zone. If a size is greyed out, that's the reason. Now I'll leave this page without creating anything." |
| 03:05 | Portal › Create public IP address. Show **SKU: Standard** and the **Availability zone** setting and its options. | "For a public IP the zone choice is different. Standard is the only SKU now; Basic was retired in September 2025. I can pin the address to one zone, which makes it zonal, or make it zone-redundant so it survives any single zone failure." |
| 03:35 | Portal › Create a storage account › **Redundancy** dropdown: LRS, ZRS, GRS, GZRS. | "Storage shows the same idea as a redundancy choice. Locally redundant keeps three copies in one datacenter. Zone-redundant keeps copies in three zones. The geo options copy to the paired region, which is why you won't find them in a region without a pair." |
| 04:05 | Cloud Shell: `az account list-locations --query "[?contains(['indonesiacentral','southeastasia','eastasia'], name)].{region:name, geography:metadata.geography, pair:metadata.pairedRegion[0].name}" -o table` | "The CLI shows the same facts. Southeast Asia's pair is East Asia. Indonesia Central has no pair." |
| 04:40 | Cloud Shell: `az account list-locations --query "[?name=='southeastasia'].availabilityZoneMappings \| [0]" -o table` | "And this is something the portal hides: my subscription's mapping from logical zones to physical zones. My zone 1 might be a different building from your zone 1." |
| 05:15 | Recap slide with three bullets: residency → region → zones; zonal vs zone-redundant; pairs don't copy your data. | "Three things to remember. Pick the region on purpose: residency, latency, services, price, zones and recovery. Know whether each resource is zonal or zone-redundant. And a region pair never copies your data unless you turn on a feature that does. In Lab 03 you'll try all of this yourself." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: "zonal", "zone-redundant", "Indonesia Central",
  "availability zone", "LRS", "ZRS")
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Close the portal "Create" pages without creating anything; confirm in **Resource groups** that nothing new exists
