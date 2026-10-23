# Lunch 16 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- Run the lab's starting point about 30 minutes before recording, so the VM has some metric history:

  ```bash
  cd azure-fundamentals-lunches/labs/16-monitoring-basic
  bash setup.sh
  ```

- Ten minutes before recording, start some CPU load so the chart has a visible bump (it stops by itself):

  ```bash
  source ../common/config.sh
  az vm run-command invoke -g "$(rg_name 16)" -n vm-nusa-web --command-id RunShellScript \
    --scripts @cpu-load.sh --parameters 10 --query "value[0].message" -o tsv
  ```

- Use a throwaway mailbox (or blur the address) for the action group email.
- Browser tabs to open in advance: the VM's **Metrics** page, **Monitor › Alerts**, **Monitor › Activity log**,
  **Service Health**, and **Advisor**.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 Free data: the VM's CPU metric
01:05 An action group that emails the on-call engineer
01:55 A metric alert: average CPU above 70% for 5 minutes
02:55 "Who stopped the VM?" in the activity log
03:45 Service Health vs Resource Health
04:35 Advisor recommendations
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 16 · Know before customers do" | "Last Friday our customers noticed a slow shop before we did. In the next five minutes we'll set up the alerts that would have warned us first, and find out who stopped the VM." |
| 00:25 | VM › Metrics › *Percentage CPU*, aggregation **Avg**, last hour; then switch to **Max** | "This chart costs nothing and needed no setup — platform metrics arrive every minute. Watch the bump when I switch from Average to Maximum: the aggregation you pick changes the story." |
| 01:05 | Monitor › Alerts › Action groups › Create: name `ag-nusa-oncall`, display name, **Email** notification | "An action group is the 'who to tell' list. Today it's one email address; in production it's a shared on-call mailbox and the duty phone." |
| 01:35 | Action group › **Test action group** › sample email arrives (blur the address) | "Always test it. Better to find the email in a spam folder now than during an incident." |
| 01:55 | VM › Alerts › Create alert rule › signal *Percentage CPU* › Static, **Average**, Greater than **70**, check every **1 minute**, lookback **5 minutes** | "Every minute, Azure averages the last five minutes of CPU and compares it with 70. Average over five minutes means 'busy for a while', not 'one spike'." |
| 02:30 | Actions tab › select `ag-nusa-oncall` › Details: Severity 2, name `alert-cpu-high` › Create | "Attach the action group — without it, the alert only shows up in the portal and nobody hears it." |
| 02:55 | VM › Stop (confirm deallocate); then Monitor › Activity log, filter on the resource group, operation *Deallocate Virtual Machine* | "Now someone stops the VM. The activity log records every control-plane change for 90 days, free." |
| 03:20 | Open the event › **Summary**: Event initiated by (blur the caller name), status Succeeded › JSON tab briefly | "Here's our answer: the caller, the time and the result. No more 'bukan saya'." |
| 03:45 | VM › Resource health: current status and history entry for the stop | "Resource Health looks at one resource. It says unavailable — user initiated. That points to us, not Azure." |
| 04:05 | Service Health › Service issues (empty or current), then Health alerts › Create (show the service, region and event type pickers; cancel) | "Service Health is personal: only the services and regions you use. Every subscription should have a Service Health alert wired to an action group." |
| 04:35 | Advisor › Overview with the five categories and Advisor score; open one recommendation | "Advisor is a free second opinion in five categories: reliability, security, performance, cost and operational excellence. Review it weekly." |
| 05:15 | Recap slide: free data · alert = scope + condition + action group · activity log = who · Resource vs Service Health | "Three things to remember: start with the free data, give every alert an action group that reaches a team, and use the activity log and Resource Health to tell 'us' from 'Azure'. The lab walks you through all of it." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: `bash cleanup.sh` in `labs/16-monitoring-basic`
