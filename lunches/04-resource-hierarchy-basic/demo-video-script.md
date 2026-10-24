# Lunch 04 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: finding your way
> through management groups, subscriptions and resource groups in the portal, reading a resource ID, and working with
> tags, locks and Resource Graph Explorer.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.
> In this video that includes **resource IDs** (they contain the subscription ID) and the **Tenant root group ID**
> (it is the tenant ID): blur them in editing or zoom so they stay off screen.

## Setup before you press record

- In Cloud Shell (Bash), from the repository root, create a small tagged resource group and storage account to show:

  ```bash
  source labs/common/config.sh
  RG_VIDEO=$(rg_name 04 video)
  ensure_rg "$RG_VIDEO" 04
  az tag update --resource-id "$(az group show --name "$RG_VIDEO" --query id --output tsv)" \
    --operation Merge --tags costCenter=ecommerce env=lab --output none
  az storage account create --name "stnusavid${SUFFIX}" --resource-group "$RG_VIDEO" --location "$LOCATION" \
    --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false --output none
  ```

- Open these browser tabs in advance:
  1. Azure portal › **Management groups** (only view it; you don't create anything in this video).
  2. Azure portal › **Resource groups** › `rg-lunch04-video-<suffix>`.
  3. Azure portal › **Resource Graph Explorer**.
- Delete the resources after recording (see the last section).

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 Management groups and the Tenant root group
01:10 Subscription, resource group and a resource's ID
02:10 Tags: on the group, not on the resource
03:05 Locks: Delete and Read-only in action
04:20 Resource Graph Explorer
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 04 · Resource hierarchy in the real portal" | "In five minutes we'll walk down the Azure hierarchy in the portal, take a resource ID apart, and see tags, locks and Resource Graph doing their jobs." |
| 00:20 | Portal › Management groups. Point at **Tenant root group** and the subscription under it (ID blurred). | "Every tenant has one Tenant root group. Its ID is the tenant ID, which is why I've blurred it. Subscriptions land here by default. In a company you would build management groups below it, such as production and non-production, but that's a tenant-wide change, so in a personal lab I only look." |
| 00:50 | Click the subscription › **Resource groups**. | "One level down are subscriptions: the boundary for billing and quotas. Inside them, resource groups hold resources that share a lifecycle." |
| 01:10 | Open `rg-lunch04-video-<suffix>` › the storage account › **JSON View**. Highlight the `id` field (subscription part blurred). | "Every resource has a resource ID. Read it left to right: subscription, resource group, provider namespace Microsoft.Storage, type storageAccounts, and the name. Scripts, role assignments and locks all use this path." |
| 01:45 | Storage account › **Overview**, point at **Location** and **Resource group (move)** link. | "Notice the move link next to the resource group. Moving changes the resource group part of the ID, never the region." |
| 02:10 | Resource group › **Tags**: show `costCenter=ecommerce`, `env=lab`. | "I tagged the resource group with a cost centre and an environment." |
| 02:30 | Storage account › **Tags**: empty. | "But the storage account inside has no tags at all. Tags are not inherited. If the cost report needs them on every resource, tag the resources or let Azure Policy copy them." |
| 02:50 | Storage account › Tags: add `app=product-images` and **Apply**. | "So I tag the resource itself. Names are case-insensitive, values aren't, so agree on the spelling up front." |
| 03:05 | Storage account › **Locks** › Add: name `lock-nodelete`, type **Delete**. | "Now a lock. In the portal it's called Delete; in the CLI it's CanNotDelete." |
| 03:25 | Storage account › **Delete** › type the name › confirm. Show the error notification. | "Even as the subscription owner, I can't delete it. The lock overrides my permissions. I remove the lock first when I really mean it." |
| 03:50 | Locks › change to **Read-only**; then **Access keys** › **Show** (or Security + networking › Access keys). Show the error or empty state. | "A Read-only lock goes further. Listing access keys is a POST action, not a simple read, so the lock blocks it. That is the surprise that breaks apps in production." |
| 04:10 | Locks › delete the lock. | "And I remove the lock again." |
| 04:20 | Resource Graph Explorer: run `Resources \| where tags.app == 'product-images' \| project name, resourceGroup, location` | "Resource Graph finds things across every subscription I can read, in seconds. Here, every resource tagged as product images." |
| 04:50 | Run `ResourceContainers \| where type =~ 'microsoft.resources/subscriptions/resourcegroups' \| where tags.costCenter == 'ecommerce' \| project name` | "Resource groups live in the ResourceContainers table. Same query language, different table." |
| 05:15 | Recap slide: hierarchy · resource ID · tags don't inherit · locks and POST | "Three things to remember. Rules flow down the hierarchy, but tags don't. The resource ID tells you exactly where something lives. And a Read-only lock blocks more than you think. Lab 04 lets you try all of it." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: "Azure Resource Manager", "CanNotDelete", "ReadOnly",
  "Resource Graph", "Tenant root group")
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: remove any lock you left on the storage account, then run
  `bash labs/04-resource-hierarchy-basic/cleanup.sh` (it deletes every resource group tagged `lunch=04`)
