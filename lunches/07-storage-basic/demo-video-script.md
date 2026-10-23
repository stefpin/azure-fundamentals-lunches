# Lunch 07 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- A resource group for the recording, for example `rg-lunch07-video`, in Southeast Asia. Create it in Cloud Shell:
  `az group create --name rg-lunch07-video --location southeastasia --tags course=azure-fundamentals-lunches lunch=07`
- Do **not** create the storage account yet — creating it is part of the video. Pick the name in advance
  (for example `stnusavideo` plus a few random characters) and check it is free:
  `az storage account check-name --name <your-name> --query nameAvailable`
- Assign yourself **Storage Blob Data Contributor** on the resource group a few minutes before recording, so the
  Storage browser and the user delegation SAS work immediately:
  `az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $(az ad signed-in-user show --query id -o tsv) --assignee-principal-type User --scope $(az group show -n rg-lunch07-video --query id -o tsv)`
- Two small files on your desktop: `batik-shirt.svg` (any product picture) and `INV-2026-0001.txt` (any short text).
  The lab's `labs/07-storage-basic/sample-files/` folder has both.
- Browser tabs: the Azure portal (signed in), and a **private/incognito window** for testing the SAS link.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 Create a secure storage account
01:45 Containers and uploads in Storage browser
02:45 Change a blob's access tier (Cool and Archive)
03:35 Generate a user delegation SAS
04:35 Open the link — and watch it expire
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 07 · Storage — the portal tour" | "In the next five minutes we'll create a storage account for Nusantara Retail, upload a product image and an invoice, move them between access tiers, and share one file safely with a link that expires." |
| 00:25 | Portal › Storage accounts › **Create** › Basics tab | "Basics first. The name must be globally unique — three to twenty-four lowercase letters and numbers — because it becomes part of the URL. Region: Southeast Asia. Primary service: Azure Blob Storage. Performance: Standard. Redundancy: I'll pick locally redundant storage for this demo; for the real storefront we'd choose zone-redundant." |
| 01:00 | **Advanced** tab: *Require secure transfer* ✔, *Allow enabling anonymous access on individual containers* ☐, *Default to Microsoft Entra authorization in the Azure portal* ✔, *Minimum TLS version* 1.2, *Access tier* Hot | "On Advanced, a few settings matter today. Secure transfer stays on, anonymous access stays off, the portal should use my Entra identity rather than the account key, and the minimum TLS version is 1.2. The default access tier is Hot — new blobs land there unless we say otherwise." |
| 01:30 | **Review + create** › **Create**, then *Go to resource* | "Review, create — it takes a few seconds. Notice the Overview page lists separate endpoints for blobs, files, queues and tables: one account, four services." |
| 01:45 | Storage account › **Storage browser** › Blob containers › **+ Add container** `products` (Anonymous access level: Private) | "Storage browser is the portal's file explorer. I create a container called products. The anonymous access level is Private — and it couldn't be anything else, because we disabled anonymous access for the whole account." |
| 02:10 | Inside `products`: **Upload** `batik-shirt.svg`; create `invoices` and upload `INV-2026-0001.txt` | "Upload a product image… then a second container, invoices, with one invoice. The authentication method above the list says *Microsoft Entra user account* — because of that checkbox, the portal uses my data role, not the account key." |
| 02:45 | Select the invoice › **Change tier** › Archive › Save. Then select the image › Change tier › Cool | "This invoice is closed, so it goes to the archive tier — the cheapest place to keep it. The product image from last season goes to cool. Both changes are instant when you move to a cooler tier." |
| 03:15 | Try to **Download** the archived invoice; show the message. Open *Change tier* again to show the rehydrate priority options | "Now try downloading the archived invoice: refused — archived blobs are offline. To read it again we'd rehydrate it, with standard priority, up to fifteen hours, or high priority, often under an hour for small files. Copying it to a new blob avoids the early deletion charge." |
| 03:35 | Select `batik-shirt.svg` › **Generate SAS**: Signing method *User delegation key*, Permissions *Read*, Expiry *now + 1 hour*, Allowed protocols *HTTPS only* › **Generate SAS token and URL** | "Rizky, our contractor, needs this picture today. Instead of handing out the account key, I generate a SAS signed with a user delegation key — that's my Entra identity, not a storage key. Read only, one blob, one hour, HTTPS only." |
| 04:10 | Copy the **Blob SAS URL**; blur the `sig=` part while zoomed | "The URL carries the permissions and the expiry time in its query string, plus a signature. Anyone holding this link can use it until it expires, so treat it like a password." |
| 04:35 | Paste the URL into the private window → the image appears. Remove the query string and reload → error XML | "In a private window — no sign-in at all — the link works. Remove the SAS part and try again: an error, because anonymous access is off. That is exactly what we want." |
| 04:55 | Back in Storage browser: generate a second SAS that expires in 1 minute (prepared earlier), open it → `AuthenticationFailed` | "And here's a SAS that expired a minute ago: 403, authentication failed. Short lifetimes limit the damage if a link leaks." |
| 05:15 | Recap slide: three bullets | "Three things to remember: redundancy decides which failure you survive; access tiers trade storage price for access price, with minimum stays; and when you share, share a short-lived user delegation SAS — never the account key. The lab walks you through all of this with the CLI and AzCopy." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *ZRS*, *AzCopy*, *SAS*, *rehydrate*, *Entra*)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: `az group delete --name rg-lunch07-video --yes --no-wait`
- Check that no SAS URL or account name you will keep using is readable in the final video
