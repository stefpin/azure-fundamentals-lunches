# Lunch 18 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- About **45 minutes before** recording, run this in Cloud Shell so compliance data has time to appear:

  ```bash
  az group create --name rg-demo18 --location southeastasia --output none
  az storage account create --name "stdemo18old$RANDOM" --resource-group rg-demo18 \
    --location southeastasia --sku Standard_LRS --output none     # an "old" untagged resource
  RG_ID=$(az group show --name rg-demo18 --query id --output tsv)
  REQUIRE_TAG_ID=$(az policy definition list \
    --query "[?policyType=='BuiltIn' && displayName=='Require a tag on resources'].id | [0]" --output tsv)
  az policy assignment create --name require-costcenter-tag --scope "$RG_ID" \
    --policy "$REQUIRE_TAG_ID" --params "{ 'tagName': { 'value': 'costCenter' } }" --output none
  az policy state trigger-scan --resource-group rg-demo18 --no-wait
  ```

- Browser tabs: **Policy › Definitions**, **Policy › Compliance** (scope filtered to `rg-demo18`), and Cloud Shell (Bash).
- Plan one cut: after you assign *Allowed locations* on camera, stop recording for about 5–10 minutes until the
  assignment takes effect, then continue at the "Watch a deployment fail" chapter.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 Find a built-in policy definition
01:10 Assign Allowed locations to a resource group
02:10 Watch a deployment fail
03:05 Read the compliance view
04:05 Let a Modify policy add a missing tag
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 18 · Azure Policy in five minutes" | "Nusantara Retail found a storage account in West Europe and a pile of untagged resources. In the next five minutes we put guardrails in place so that cannot happen again — using Azure Policy." |
| 00:25 | Portal › Policy › Definitions; type *Allowed locations* in the search box; open it | "Azure ships thousands of built-in definitions. Here is *Allowed locations*. Look at the JSON: an `if` that compares the resource's location with a list, and a `then` that denies. The list is a parameter, so one definition fits every company." |
| 00:55 | Scroll the definition: mode **Indexed**, parameters **listOfAllowedLocations** and **effect** | "Two things to notice: Indexed mode means it skips resource groups, and the effect is a parameter with Deny as the default." |
| 01:10 | Select **Assign policy**; Scope › `rg-demo18` (blur the subscription ID) | "Assigning is where the rule starts working. I pick the scope — just this resource group for the demo; in production it would be the subscription or a management group." |
| 01:35 | Parameters tab › Allowed locations: *Southeast Asia*; Non-compliance message: "Use Southeast Asia — Nusantara cloud policy" | "I allow only Southeast Asia and add a friendly message. That message appears in the error, so developers know what to do instead of filing a ticket." |
| 01:55 | Review + create › Create | "Create. A new assignment takes about five minutes to reach its scope, so I'll pause the recording here." |
| 02:10 | Cloud Shell: `az storage account create --name stdemo18weu$RANDOM --resource-group rg-demo18 --location westeurope --sku Standard_LRS` | "Five minutes later. I own this subscription, so RBAC is happy — but watch what Azure Policy says about West Europe." |
| 02:35 | The error: highlight `RequestDisallowedByPolicy`, the assignment name and the custom message | "RequestDisallowedByPolicy. The message names the assignment and shows our custom text. Nothing was created, and no amount of permissions would change that — only the policy owner can." |
| 02:50 | Run the same command with `--location southeastasia --tags costCenter=CC-1001` | "Same request in Southeast Asia, with the tag our other policy requires. Success." |
| 03:05 | Portal › Policy › Compliance; select *Require a tag on resources* | "Now the report card. The tag policy I assigned before recording has evaluated the resource group." |
| 03:25 | Resource compliance tab: the old storage account shows **Non-compliant**; open *Compliance details* | "The old storage account is non-compliant — it has no costCenter tag. Notice it was not deleted: Deny blocks new requests, and existing resources are only reported." |
| 03:50 | Point at the *Last evaluated* time and the **Create remediation task** button (greyed out for Deny) | "Deny policies can't fix anything. For automatic fixes you need a Modify or DeployIfNotExists policy — let's add one." |
| 04:05 | Assign *Inherit a tag from the resource group if missing*, tag name `costCenter`; Remediation tab: system-assigned managed identity, location Southeast Asia, tick **Create a remediation task** | "The portal creates a managed identity and gives it the role the definition asks for. Ticking *Create a remediation task* fixes the existing resources too." |
| 04:40 | Resource group › Tags: add `costCenter = CC-1001` | "The inherit policy copies the tag from the resource group, so the resource group itself needs it." |
| 04:55 | Policy › Remediation › Remediation tasks: the task moves to **Complete**; open the old storage account › Tags | "A few minutes later the remediation task has finished, and the old storage account carries costCenter CC-1001. Nobody edited it by hand." |
| 05:15 | Recap slide: Definition → Assignment → Effect → Compliance → Remediation | "Three things to remember: a definition becomes active only when you assign it to a scope; Deny blocks new requests but never deletes; and Modify plus a remediation task fixes what already exists. Try it yourself in Lab 18." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *Azure Policy*, *RequestDisallowedByPolicy*, *Modify*, *remediation*)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources — the assignments (and the role assignment of the inherit policy's managed identity) live
  on the resource group, so remove them first, then the group:

  ```bash
  for a in $(az policy assignment list --resource-group rg-demo18 --query "[].name" --output tsv); do
    pid=$(az policy assignment show --name "$a" --resource-group rg-demo18 --query identity.principalId --output tsv)
    if [ -n "$pid" ]; then
      az role assignment delete --assignee "$pid" --resource-group rg-demo18
    fi
    az policy assignment delete --name "$a" --resource-group rg-demo18
  done
  az group delete --name rg-demo18 --yes --no-wait
  ```
