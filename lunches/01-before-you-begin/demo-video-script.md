# Lunch 01 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: a quick portal tour,
> opening Cloud Shell, cloning the course repository, and creating the course budget.
> **Length target:** 5½ minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- A demo subscription where you are Owner, with **no budget yet** (you create it on camera). If one exists from a
  rehearsal, delete it first: *Cost Management › Budgets › select it › Delete*.
- Cloud Shell already initialised once (Bash, with persistent storage), so the first-run storage prompt does not eat
  recording time. Mention the prompt in the narration instead.
- No existing clone in Cloud Shell: run `rm -rf ~/azure-fundamentals-lunches` before recording.
- Browser tabs open in advance: `https://portal.azure.com` (signed in, MFA already completed) and the course repository
  on GitHub.
- Blur plan: the account menu (top right), the subscription ID in `az account show`, and the e-mail address you type
  into the budget's alert recipients.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 A two-minute portal tour
01:40 Open Cloud Shell (Bash)
02:20 Clone the course and check your environment
03:20 Create a monthly budget with 50/80/100% alerts
04:50 Create, inspect and delete a tagged resource group
05:20 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 01 · Your Azure lab, tools and cost guardrails" | "In the next five minutes we'll get a lab subscription ready for the whole course: a quick tour of the portal, Cloud Shell, the course files, and a budget that warns us before spending gets out of hand." |
| 00:20 | Portal home page; point at the search bar | "This is the Azure portal. The search bar at the top is the fastest way to anything: services, resources, even documentation. Let's use it." |
| 00:40 | Search **Subscriptions** › open the lab subscription › **Overview** (blur the ID) | "Here's my lab subscription. The overview shows its offer and my role. It's a personal subscription — never use a company one for experiments." |
| 01:05 | Search **Resource groups** (empty list) | "Resource groups are the folders of Azure. Every lab in this course uses exactly one, so cleanup is a single delete." |
| 01:20 | Search **Cost Management** › show the left menu (Cost analysis, Budgets) | "Cost Management is where the money lives. Remember the Budgets entry — we'll be back in two minutes." |
| 01:40 | Select the Cloud Shell icon `>_` in the top toolbar; choose **Bash** | "Cloud Shell is a terminal in the browser, already signed in, with the Azure CLI, PowerShell, Git and Bicep installed. The first time, it asks Bash or PowerShell — we use Bash — and whether to mount storage. Persistent storage keeps your files between sessions; an ephemeral session is faster but forgets everything." |
| 02:05 | Type `az account show --query "{subscription:name, state:state}" --output table` | "First habit: check which subscription you're in. Enabled, and it's the lab one. Good." |
| 02:20 | Type `git clone https://github.com/stefpin/azure-fundamentals-lunches.git` then `cd azure-fundamentals-lunches` | "Now the course files. One clone, and every lab script is here." |
| 02:40 | Type `bash labs/common/check-environment.sh`; let it run | "This script only reads. It checks the region, whether the small VM sizes the labs use are available to you, your vCPU quota, and any lab resource groups you forgot to delete." |
| 03:10 | Scroll to "All … checks passed" | "All green. If a VM size fails for you, don't panic — the VM labs explain how to pick another." |
| 03:20 | Portal › **Cost Management › Budgets**; point at **Scope** | "Back to budgets. Check the scope first: it must be the subscription, so the budget covers everything." |
| 03:35 | **+ Add**: name `budget-azure-lunches`, reset period **Monthly**, expiration a year ahead, a small amount | "Name, monthly reset, an expiration date well in the future — an expired budget is deleted — and an amount you're comfortable spending on learning in a month." |
| 04:05 | **Next** › alert conditions: Actual 50, Actual 80, Actual 100, Forecasted 100; recipients (blurred) › **Create** | "Alerts at fifty, eighty and a hundred percent of actual cost, plus one forecast alert that warns before we get there. Important: a budget only sends email. It never stops anything." |
| 04:40 | Budget appears in the list | "There it is. It protects every lab from now on, so we keep it." |
| 04:50 | Cloud Shell: `cd labs/01-before-you-begin && source ../common/config.sh && RG=$(rg_name 01) && ensure_rg "$RG" 01` then `az group show --name "$RG" --query tags` | "Finally, the lab rhythm: create a tagged resource group, look at the tags…" |
| 05:05 | `az group delete --name "$RG" --yes` then `az group exists --name "$RG"` → `false` | "…and delete it. Deleting a group deletes everything inside it." |
| 05:20 | Recap slide: three bullets | "Three things to remember: use your own lab subscription; every tool talks to Azure Resource Manager; and a budget is an alarm, not a brake — the cleanup habit is yours. See you in Lab 01." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: Cloud Shell, Azure Resource Manager, Cost Management).
- Add the chapter list to the description.
- Paste the video link into the lunch README (section 🎬 Demo).
- Delete the demo resources. Keep or delete the demo budget depending on whether the subscription is used for other recordings.
