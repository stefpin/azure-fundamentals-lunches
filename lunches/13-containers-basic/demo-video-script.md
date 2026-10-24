# Lunch 13 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: an image in a real
> registry, a container app pulling it with a managed identity, live replicas appearing under load, and a traffic split
> configured in the portal.
> **Length target:** about 5½ minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- Create the slow parts in advance (about 5 minutes) from Cloud Shell, so the video does not wait for them:

  ```bash
  cd azure-fundamentals-lunches/labs/13-containers-basic
  source ../common/config.sh
  RG=$(rg_name 13); ACR_NAME="acrnusa${SUFFIX}"; APP=ca-nusa-storefront
  ensure_rg "$RG" 13
  az acr create --resource-group "$RG" --name "$ACR_NAME" --sku Basic --location "$LOCATION" --output none
  az acr import --name "$ACR_NAME" --source mcr.microsoft.com/azuredocs/aks-helloworld:v1 --image storefront:v1
  az containerapp env create --name cae-nusa --resource-group "$RG" --location "$LOCATION" --output none
  LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer --output tsv)
  ```

- Keep the long `az containerapp create` command from Lab 13, Task 3 ready in a text editor so you can paste it.
- Paste the Task 4 load loop into the same editor, with `FQDN` set after the app exists.
- Browser tabs to open in advance: the Azure portal on the resource group `rg-lunch13-<suffix>`; the registry's
  **Repositories** page; Cloud Shell (Bash) in a second tab, font size increased.
- Wait at least five minutes after the last test request before you record chapter 5, so the app starts at zero
  replicas.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 The image in your private registry
01:00 Create the container app from the CLI
01:45 Ingress, identity and the scale rule in the portal
02:40 Zero to five replicas under load
03:50 A second revision and an 80/20 split
05:00 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 13 · From registry to a container app that scales to zero" | "In the next five minutes you'll see Nusantara Retail's storefront image go from a private registry to a container app that sleeps at zero replicas, wakes up for shoppers, and splits traffic between two versions." |
| 00:20 | Portal › Container registries › acrnusa… › **Repositories** › storefront › tag **v1** | "This is our private Azure Container Registry. The storefront repository holds tag v1. Notice the digest: the tag is a label we can move, the digest pins the exact content." |
| 00:45 | Registry › **Settings › Access keys**: admin user unchecked | "The admin user is off. Nothing in this demo uses a registry password; the app will sign in with a managed identity." |
| 01:00 | Cloud Shell: paste the `az containerapp create` command from Lab 13, Task 3; highlight `--registry-identity system`, `--target-port 80`, `--min-replicas 0` | "We create the container app from the registry. Three flags matter: registry identity system, which turns on a managed identity and grants it AcrPull; target port 80, where this app listens; and a minimum of zero replicas." |
| 01:30 | Command finishes; run `az containerapp show ... --query properties.configuration.ingress.fqdn`; open the URL in a new tab | "Here's the HTTPS address. The first request takes a few seconds: that's a cold start, a replica starting from the image." |
| 01:45 | Portal › Container Apps › ca-nusa-storefront › **Settings › Ingress** | "Ingress is external, traffic goes to target port 80, and HTTPS is handled for us." |
| 02:05 | **Settings › Identity** (System assigned: On), then **Azure role assignments** showing AcrPull on the registry | "The system-assigned identity exists and holds AcrPull on our registry, and only on our registry. That's least privilege, with no secret to rotate." |
| 02:25 | **Application › Scale**: min 0, max 5, HTTP rule with 10 concurrent requests | "The scale rule: one more replica for roughly every ten concurrent requests, never more than five, and zero when nobody is shopping." |
| 02:40 | **Application › Revisions and replicas** (*Revision management* in some portal versions): 0 replicas. Switch to Cloud Shell, start the load loop | "Right now no replica is running, so no compute is billed. Let's play the 12.12 sale: forty requests at a time for two minutes." |
| 03:05 | Back to **Revisions and replicas**, refresh every 15 seconds: replica count rises to 5 | "Replicas appear as the load builds, and they stop at five, our maximum. That cap protects the bill as well as the platform." |
| 03:30 | **Monitoring › Metrics**: Replica Count (Max) and Requests over the last 30 minutes | "The metrics tell the same story. When traffic stops, the platform waits for a cool-down of five minutes, then scales back to zero." |
| 03:50 | **Revisions and replicas › Choose revision mode › Multiple**; then traffic to the current revision = 100%; **Save** | "To release safely, we allow several revisions at once, and we pin all traffic to the current one before deploying anything new." |
| 04:15 | **Create new revision** › edit the container › environment variable `TITLE` = "Nusantara Retail storefront v2" › suffix `v2` › **Create** | "A new environment variable is a revision-scope change, so it creates revision v2. It's active, but it receives no shoppers yet." |
| 04:35 | Traffic column: v1 = 80, v2 = 20 › **Save** | "Now the canary: eighty percent stays on v1, twenty percent goes to v2." |
| 04:45 | Cloud Shell: the 40-request `curl` sample piped to `sort` and `uniq -c` | "Forty requests: most are answered by v1, about one in five by v2. If v2 misbehaves, we drag it back to zero in seconds." |
| 05:00 | Recap slide: "Image → registry → managed identity → revisions → scale to zero" | "Three things to remember. Build an image once and keep it in a private registry. Let services pull with a managed identity. And let Container Apps scale with your shoppers, all the way down to zero. Now it's your turn in Lab 13." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: Container Apps, ACR, AcrPull, KEDA, revision)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: `bash labs/13-containers-basic/cleanup.sh`
