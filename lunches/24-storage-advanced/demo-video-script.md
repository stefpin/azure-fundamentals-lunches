# Lunch 24 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

Run this in Cloud Shell (Bash) about 15 minutes before recording. It creates an account,
a virtual network and a private endpoint with its private DNS zone; you add the container and its two invoices in
the portal afterwards (see the list below). Pick your own account name and check it is free
with `az storage account check-name --name <name> --query nameAvailable`.

```bash
RG=rg-lunch24-video; LOC=southeastasia; ST=stnusavid24abc   # change ST to your own free name
az group create -n $RG -l $LOC --tags course=azure-fundamentals-lunches lunch=24 -o none
az storage account create -n $ST -g $RG -l $LOC --kind StorageV2 --sku Standard_LRS \
  --min-tls-version TLS1_2 --allow-blob-public-access false -o none
ST_ID=$(az storage account show -n $ST -g $RG --query id -o tsv)
az role assignment create --role "Storage Blob Data Contributor" --assignee-principal-type User \
  --assignee-object-id $(az ad signed-in-user show --query id -o tsv) --scope $ST_ID -o none
az network vnet create -g $RG -n vnet-video --address-prefixes 10.24.0.0/16 \
  --subnet-name snet-pe --subnet-prefixes 10.24.2.0/24 -o none
az network private-endpoint create -g $RG -n pe-video-blob --vnet-name vnet-video --subnet snet-pe \
  --private-connection-resource-id $ST_ID --group-id blob --connection-name pec-video-blob -o none
az network private-dns zone create -g $RG -n privatelink.blob.core.windows.net -o none
az network private-dns link vnet create -g $RG -z privatelink.blob.core.windows.net -n link-vnet-video \
  -v vnet-video --registration-enabled false -o none
az network private-endpoint dns-zone-group create -g $RG --endpoint-name pe-video-blob -n default \
  --private-dns-zone privatelink.blob.core.windows.net --zone-name blob -o none
```

- In the portal, open the account's **Configuration** page and set *Default to Microsoft Entra authorization in the
  Azure portal* to **Enabled**, so Storage browser uses your data role.
- Create a container `invoices` and upload two short text files, `INV-2026-0042.txt` and `INV-2026-0043.txt`
  (the lab's `labs/24-storage-advanced/sample-files/` folder has both). Keep a second file called `INV-2026-0042.txt`
  on your desktop whose only line is `ENCRYPTED BY RANSOMWARE`.
- Browser tabs: the storage account's **Data protection** page, and the private DNS zone
  `privatelink.blob.core.windows.net`.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 Turn on data protection
01:05 Overwrite an invoice, then restore a version
01:55 Delete an invoice and get it back
02:35 A ten-year lifecycle rule
03:20 Time-based retention, unlocked
04:10 Private endpoint, private DNS and public access off
05:25 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 24 · Ransomware-proof invoices — the portal tour" | "Ransomware hit one of Nusantara Retail's suppliers last night. In the next five minutes we'll make sure our own invoices can be recovered, can't be tampered with, cost little for ten years, and can only be reached from our own network." |
| 00:20 | Storage account › **Data management › Data protection**. Tick *Enable versioning for blobs*, *Enable soft delete for blobs* (14 days), *Enable soft delete for containers* (14 days), *Enable blob change feed*. Point at *Enable point-in-time restore for containers* without ticking it › **Save** | "Data protection is one page. Versioning keeps every old copy of a blob. Soft delete keeps deleted blobs and containers for fourteen days. Change feed logs every change. Point-in-time restore builds on all three — notice it would switch them on for you — but we leave it off here, because it can't be combined with the immutability policy we add later." |
| 01:05 | **Storage browser** › `invoices` › **Upload** the ransomware `INV-2026-0042.txt` with *Overwrite if files already exist* ticked. Open the blob › **Edit** to show the line `ENCRYPTED BY RANSOMWARE` | "Now I play the attacker and overwrite invoice forty-two with garbage. Without versioning, the original would be gone." |
| 01:30 | Blob › **Versions** tab: two versions, newest marked current. Select the older one › **Make current version**. Reopen the blob: the original text is back | "The Versions tab lists the old content with its own version ID. Make current version copies it over the blob — the invoice is back, and the encrypted copy becomes just another old version we can clean up later." |
| 01:55 | Delete `INV-2026-0043.txt`. Toggle **Show deleted blobs**: it reappears marked *Deleted*. Open it › **Versions** › select the latest version › **Make current version** | "Delete invoice forty-three — gone from the list. Toggle Show deleted blobs and there it is. With versioning on, a delete only turns the current version into a previous one, so restoring is the same move as before." |
| 02:35 | Storage account › **Lifecycle management** › **Add a rule**: name `invoices-ten-years`, limit to block blobs with prefix `invoices/`. On *Base blobs*: cool after 30 days, cold after 90, archive after 365, delete after 3,650. Switch to **Code view** | "Nobody wants to tier ten years of invoices by hand. A lifecycle rule does it: cool after thirty days, cold after ninety, archive after a year, delete after ten. Code view shows the same rule as JSON — that's the file you deploy in the lab. Rules run once a day and can take up to a day to start." |
| 03:20 | Create container `invoices-2025`, upload one file. Container › **Access policy** › *Immutable blob storage* › **Add policy**: *Time-based retention*, 1 day › Save. Status shows **Unlocked** | "Closed tax years get a stronger lock. On this new container I add a time-based retention policy — one day for the demo, ten years in real life. It starts unlocked, which is for testing." |
| 03:45 | Try to **Delete** the blob in `invoices-2025` → error notification about the immutability policy. Open the policy's **…** menu and point at **Lock policy** without clicking | "Try deleting the invoice: refused, even though I'm the owner of everything here. In production you would now lock the policy — after that it can only be extended, and nobody can delete these invoices or the account until the period ends. We don't lock it, so we can clean up." |
| 04:10 | Storage account › **Security + networking › Networking** › *Private endpoints* tab: `pe-video-blob`, status **Approved**. Click through to its network interface: private IP 10.24.2.4 | "I created a private endpoint before recording. It gives the account's blob service a private IP address inside our virtual network, and because I own both sides, the connection was approved automatically." |
| 04:35 | Private DNS zone tab: A record `<account>` → 10.24.2.4; *Virtual network links* shows `link-vnet-video` | "The private DNS zone holds the matching A record, and it's linked to the virtual network. Inside that network, the normal blob name now resolves to the private IP; everywhere else it still resolves to the public one." |
| 04:55 | Networking › *Firewalls and virtual networks*: **Public network access** › **Disabled** › Save. Back to Storage browser › `invoices` → error about network access | "Last step: close the public door. Public network access: Disabled. And look — even I can no longer browse the blobs from the portal, because my browser is on the internet, not in the virtual network. That's why you finish every data-plane task before this switch." |
| 05:25 | Recap slide: three bullets | "Three things to remember: versioning and soft delete undo overwrites and deletes, and a locked immutability policy stops them altogether; lifecycle rules handle ten years of tiering for free; and a private endpoint only works when its DNS zone is linked — then you can turn public access off. The lab does all of this from the CLI and tests DNS from a VM." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *soft delete*, *change feed*, *WORM*, *privatelink*, *Entra*)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources. The immutability policy is unlocked, so the group can be deleted directly:
  `az group delete --name rg-lunch24-video --yes --no-wait`. If the deletion fails anyway, delete the policy first
  (`invoices-2025` › **Access policy** › **…** › **Delete**) and try again.
- Check that no account name or private DNS record you will keep using is readable in the final video
