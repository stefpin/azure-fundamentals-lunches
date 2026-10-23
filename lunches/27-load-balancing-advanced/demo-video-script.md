# Lunch 27 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — an Application Gateway's listeners, path rules and
> backend health, a WAF policy switched to Prevention mode blocking a real request, and a Traffic Manager failover seen
> through DNS — which the animation can only simulate.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, the gateway's public IP address and the apps'
> host names if you keep them after recording.

## Setup before you press record

- The gateway takes 5–15 minutes to create, so build everything **30–40 minutes before recording**, then put the WAF
  back into Detection mode so you can switch it on camera:

  ```bash
  cd azure-fundamentals-lunches/labs/27-load-balancing-advanced
  source ../common/config.sh && source lab.env
  bash setup.sh && bash solution.sh
  load_hosts; GW_IP=$(gw_ip)
  az network application-gateway waf-policy policy-setting update -g "$RG" --policy-name "$WAF_POLICY" \
    --mode Detection --state Enabled --request-body-check true --output none
  ```

- Browser tabs: (1) the portal open at resource group `rg-lunch27-<suffix>`; (2) Azure Cloud Shell (Bash) with the
  `source` lines, `load_hosts` and `GW_IP=$(gw_ip)` already run, and the screen cleared.
- Have these lines ready to paste in Cloud Shell:
  - `curl -s "http://${GW_IP}/" | grep -o "Served by the [A-Z]* app"` (and the same for `/images/`)
  - `curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://${GW_IP}/?id=1%27%20OR%201%3D1--"`
  - `az webapp stop -g "$RG" -n "$APP_STORE"` and `tm_watch 9`
- Two waits are cut in the edit: about a minute after switching the WAF mode, and about a minute during the failover.
  Say "let's skip ahead" on camera so the cut feels natural.
- The gateway is billed every hour it exists: run `bash cleanup.sh` as soon as you have the takes you need.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 Two apps and one gateway
00:45 Listener, rule and path map
01:35 Backend settings and the App Service host name
02:10 Backend health and a quick test
02:35 The WAF: from Detection to Prevention
03:50 Traffic Manager: priority endpoints
04:25 A failover through DNS
05:25 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 27 · Protect and route the storefront" | "Nusantara Retail's storefront needs three things: one address for two apps, protection from attacks, and a plan for when a site goes down. In six minutes we look at each one in the real portal." |
| 00:20 | Portal › resource group `rg-lunch27-<suffix>`: the plan, two apps, `agw-nusa`, `waf-nusa`, `pip-agw-nusa`, `tm-nusa` | "Here's the lab's resource group: a storefront app and an images app on a Free App Service plan, an Application Gateway with its WAF policy and public IP, and a Traffic Manager profile." |
| 00:45 | `agw-nusa` › *Overview* (SKU WAF_v2, autoscale 1–2), then *Listeners* › `appGatewayHttpListener` (HTTP, port 80) | "The gateway runs the WAF_v2 SKU and autoscales between one and two instances to keep the lab cheap. Its listener waits for HTTP on port 80. In production this would be HTTPS with a certificate from Key Vault." |
| 01:05 | *Rules* › `rule1` › *Backend targets* tab: path-based, `/images/*` → `pool-images`, default → `appGatewayBackendPool` | "The rule links the listener to its targets. It's path-based: anything under slash-images goes to the images pool, and everything else to the default pool, which holds the storefront." |
| 01:35 | *Backend settings* › `appGatewayBackendHttpSettings`: HTTPS 443, *Override with new host name* = yes, *Pick host name from backend target*, custom probe `probe-app` | "Backend settings say how to talk to the apps: HTTPS on 443. This switch matters most. App Service finds an app by its host name, so the gateway must send each app its own name, not the one the shopper typed." |
| 02:10 | *Monitoring* › *Backend health*: both app host names **Healthy**; then Cloud Shell: the two `curl` lines | "Backend health confirms both apps answer the probe. A quick test from Cloud Shell: the root path is served by the storefront app, slash-images by the images app — one address, two apps." |
| 02:35 | `waf-nusa` › *Overview* (policy mode **Detection**) and *Managed rules* (Microsoft_DefaultRuleSet 2.2); Cloud Shell: the attack `curl` → `HTTP 200` | "Now the firewall. The policy uses Microsoft's Default Rule Set, version 2.2, and starts in Detection mode. I send a classic SQL-injection probe… and it gets through with 200. Detection only writes a log entry." |
| 03:05 | *Policy settings* › Mode **Prevention** › *Save* (or *Switch to prevention mode* on *Overview*); cut; Cloud Shell: the attack `curl` → `HTTP 403`, then `/?id=42` → `HTTP 200` | "Switch to Prevention and save. The change takes a minute to reach the gateway, so let's skip ahead. Same request: 403 Forbidden. The SQL-injection rule is critical, worth five points, and five is the blocking threshold. A normal request still works." |
| 03:50 | `tm-nusa` › *Overview* (DNS name, routing method **Priority**); *Endpoints* (`ep-store` priority 1, `ep-images` priority 2, both **Online**); *Configuration* (DNS TTL 30, HTTPS, probing every 10 s) | "Traffic Manager works in DNS only. This profile uses Priority routing: the storefront first, the images app as a stand-in for a second region. It checks both over HTTPS every ten seconds, and answers live for thirty seconds." |
| 04:25 | Cloud Shell: `dig +noall +answer nusa-shop-<suffix>.trafficmanager.net` → CNAME to `app-nusa-store-…`; `az webapp stop …`; `tm_watch 9`; cut; `ep-store:Degraded`, answer → `app-nusa-img-…` | "The DNS answer points at the storefront. Now I stop the storefront app. Let's skip ahead about a minute: the endpoint is Degraded and new DNS answers name the standby. Anyone who cached the old answer keeps it for up to thirty seconds — that's the DNS trade-off." |
| 05:05 | Cloud Shell: `az webapp start -g "$RG" -n "$APP_STORE"` and `tm_watch 6` | "Start the app again, and once its health checks pass, the storefront is back at the top of the answers." |
| 05:25 | Recap slide: Application Gateway (regional, layer 7) · WAF policy (Detection → Prevention) · Front Door (global edge) · Traffic Manager (DNS) | "Three things to remember: fix the host name for App Service backends, start a WAF in Detection and finish in Prevention, and when DNS failover is too slow, look at Front Door. The lab walks you through all of it — and the cleanup." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *Application Gateway*, *WAF_v2*, *listener*,
  *backend settings*, *Default Rule Set*, *Traffic Manager*).
- Add the chapter list to the description.
- Paste the video link into the lunch README (section 🎬 Demo).
- Delete the demo resources straight away: `bash cleanup.sh` in `labs/27-load-balancing-advanced`.
- Blur the gateway's public IP address and the apps' host names in the edit if they are visible.
