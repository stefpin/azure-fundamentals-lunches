# Lunch 10 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — one command that turns a folder of Python into a running
> web app, configuration without code changes, a fault found in the log stream, and a staging slot swapped into
> production while a poller watches. The animation can only simulate these.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- About 25 minutes before recording, build a **"prepared earlier" copy** on Standard S1 with a `staging` slot (💲💲
  while it exists). A different suffix keeps it in its own resource group, `rg-lunch10-<suffix>prep`:

  ```bash
  cd ~/azure-fundamentals-lunches/labs/10-app-service
  ( source ../common/config.sh && export SUFFIX="${SUFFIX}prep" && WITH_SLOT=1 bash solution.sh )
  # solution.sh ends with version 2.0 in production. Swap once more, so that production shows 1.0
  # and staging holds 2.0 for the swap on camera:
  ( source ../common/config.sh && export SUFFIX="${SUFFIX}prep" && source lab.env &&
    az webapp deployment slot swap -g "$RG" -n "$APP" --slot staging --target-slot production )
  ```

- For the main app, run only **Task 1** of the lab (`ensure_rg "$RG" 10` after the two `source` lines). Do **not**
  create the web app: `az webapp up` creates it on camera (Task 2). If you rehearsed, run `bash cleanup.sh` and wait
  until `az group list --tag lunch=10 --output table` is empty, then build the prepared copy again.
- Cloud Shell, session A (main app): `cd ~/azure-fundamentals-lunches/labs/10-app-service`, the two `source` lines,
  `cd app`, then `clear`.
- Cloud Shell, session B (prepared copy, *Open new session*), ready for the swap scene:

  ```bash
  cd ~/azure-fundamentals-lunches/labs/10-app-service
  source ../common/config.sh && export SUFFIX="${SUFFIX}prep" && source lab.env
  HOST=$(az webapp show -g "$RG" -n "$APP" --query defaultHostName --output tsv)
  clear
  # paste on camera:  for i in $(seq 1 60); do curl -s -o /dev/null -w "%{http_code} " "https://$HOST/"; sleep 2; done
  ```

- Browser tabs: (1) the portal at resource group `rg-lunch10-<suffix>`; (2) the prepared copy
  `app-nusa-<suffix>prep` › *Deployment slots*; (3) an empty tab for the storefront.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 From a folder of code to a running app
01:20 App settings and HTTPS Only
02:30 Break it: read the log stream, then fix it
03:30 Plans, tiers and scaling
04:20 A staging slot and a zero-downtime swap
05:20 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 10 · Azure App Service — ship the storefront, not the servers" | "Dewi, Nusantara Retail's developer, has a small Python storefront and no time to look after servers. In the next six minutes we put it online with one command, configure it without touching the code, find a fault in the log stream, and ship version 2 through a staging slot while the shop stays open." |
| 00:25 | Cloud Shell session A in `labs/10-app-service/app`: `ls`, then paste the `az webapp up` command from Lab Task 2 (`--sku F1 --runtime "$RUNTIME"`, which is `PYTHON:3.12`); the yellow deprecation warning appears | "Here's the whole app: one Python file and a requirements file. From this folder, az webapp up creates a Linux App Service plan on the Free tier, creates the web app with the Python 3.12 stack, zips the folder and deploys it. The yellow line says the command is deprecated. It still works, and the lab also shows the explicit commands that replace it." |
| 00:55 | Speed up the wait (caption: "about 4 minutes later"); the JSON summary; then `HOST=$(az webapp show -g "$RG" -n "$APP" --query defaultHostName --output tsv)` and `curl -s "https://$HOST/health"` prints `ok` | "On the server, the build installs Flask and Gunicorn. That's the slow part, so I've sped it up. The health endpoint answers ok. Notice what I didn't do: no virtual machine, no operating system patches, no web server to configure." |
| 01:20 | Portal › `app-nusa-<suffix>` › *Overview*: status Running, default domain, plan `asp-nusa-<suffix>` on F1 (blur the subscription ID); open the default domain in the storefront tab: "Sorry, the shop is having a moment." | "In the portal, the app is running on the Free plan. Let's open it… and we get a polite error page. The code needs to know which store it is, and we haven't told it yet." |
| 01:40 | *Settings › Environment variables › App settings* › **+ Add** `STORE_NAME` = `Nusantara Retail - Kemang` › *Apply* › *Confirm*; refresh the storefront: store name, **Version 1.0**, instance name | "App settings reach the code as environment variables. I add STORE_NAME, apply, and confirm the restart. Refresh: the Kemang store, version 1.0, and the name of the instance that served me. The same code could run as a test store somewhere else, with no rebuild." |
| 02:10 | *Settings › Configuration › General settings*: **HTTPS Only** On, **Minimum inbound TLS Version** 1.2 › *Save* | "Every app gets a certificate for its azurewebsites.net address. HTTPS Only redirects plain HTTP to HTTPS, and the minimum TLS version stays at 1.2. One switch, no certificate work." |
| 02:30 | Session A: `az webapp log config -g "$RG" -n "$APP" --docker-container-logging filesystem --output none` and `az webapp config appsettings delete -g "$RG" -n "$APP" --setting-names STORE_NAME --output none`; refresh the storefront: the error page again | "First I switch on container logging, which Linux apps need for the log stream. Now let's break things the way it happens in real life: someone tidies up the configuration and deletes a setting they don't recognise. The shop shows its generic error page. Fine for customers, no help for us." |
| 02:55 | Portal › *Monitoring › Log stream*; refresh the storefront tab twice; the line `ERROR [storefront] Required app setting STORE_NAME is missing` appears | "The log stream shows what the app writes, live. Refresh the shop, and there's the cause: the required setting STORE_NAME is missing. Generic for customers, specific in the logs: that's how error handling should work." |
| 03:15 | *Environment variables* › add `STORE_NAME` back › *Apply* › *Confirm*; refresh: the storefront is back | "Put the setting back, confirm the restart, and the shop is open again. The lesson: configuration is part of the release, so treat it with the same care as code." |
| 03:30 | The plan › *Scale up (App Service plan)*: browse the tiers and their feature lists; select nothing | "Everything this app can do depends on its plan. Free is shared and capped at 60 CPU minutes a day. Basic gives you dedicated instances. Standard adds autoscale and deployment slots. Premium adds faster hardware and more instances. I'm only looking: nothing changes until you apply a new tier." |
| 04:00 | Tab 2: the prepared copy `app-nusa-<suffix>prep` on Standard S1 › *Scale out (App Service plan)*: the manual, automatic and rules-based options; save nothing | "For the release I prepared a copy earlier, on Standard S1. Scale out offers a manual instance count, rules-based autoscale on metrics or a schedule, and automatic scaling, which needs a Premium tier." |
| 04:20 | *Deployment slots*: production and `staging`, with their traffic percentages; open both addresses side by side: production **Version 1.0**, staging **Version 2.0** | "Dewi has deployed version 2 to a staging slot: a live app in the same plan, with its own address. Staging says 2.0, production still says 1.0. Customers see nothing yet." |
| 04:45 | Session B: paste the poller; portal › *Swap*: source `staging`, target `production`; show the list of configuration changes; confirm (speed up the wait); refresh production: **Version 2.0**; session B shows only `200`s | "In a second Cloud Shell, a poller requests the production page every two seconds. Now, swap. The dialog lists any settings that will change. App Service first warms version 2 up on every instance, and only then switches the routing. Production shows 2.0, and the poller printed nothing but 200s. If something's wrong, the same swap is the rollback." |
| 05:20 | Recap slide: "The plan is what you pay for · Settings, not code · Log stream first · Release through a slot" | "Three things to remember. You pay for the plan, not the app. Keep configuration in app settings, and read the log stream first when something breaks. And release through a staging slot, so new versions go live without downtime. The lab walks you through all of it, including the clean-up." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *App Service plan*, *Gunicorn*, *app settings*,
  *log stream*, *deployment slot*, *swap*).
- Add the chapter list to the description.
- Paste the video link into the lunch README (section 🎬 Demo).
- Delete the demo resources: `bash cleanup.sh` in `labs/10-app-service` deletes **both** resource groups, because both
  carry the `lunch=10` tag. Check with `az group list --tag lunch=10 --output table` a few minutes later.
- Blur the subscription ID on the *Overview* page and your account name in the portal header if they are visible.
