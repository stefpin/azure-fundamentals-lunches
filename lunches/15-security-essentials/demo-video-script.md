# Lunch 15 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show: a key vault with the
> RBAC permission model, a VM's managed identity being refused and then allowed, and the secure score in Defender for Cloud.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names and IDs, e-mail addresses, object IDs you will keep using, and any
> secret value (the lab script only prints a masked preview — keep it that way).

## Setup before you press record

- About 15 minutes before recording, in Cloud Shell (Bash):

  ```bash
  cd azure-fundamentals-lunches/labs/15-security-essentials
  source ../common/config.sh
  RG=$(rg_name 15); KV_NAME="kv-nusa-${SUFFIX}"
  bash setup.sh                       # VM with the password in its config file (about 4 minutes)
  ```

- Then do Lab 15 Tasks 2, 3 and 4 off camera (vault with the RBAC model, your Key Vault Secrets Officer role, the
  `sql-connection` secret, the VM's system-assigned identity). **Don't** assign Key Vault Secrets User to the VM yet —
  the video shows that step.
- Run the Task 5 command once off camera so the Run Command extension is already installed (the first run is slower).
- Browser tabs to open in advance:
  1. The key vault › **Access configuration**
  2. The key vault › **Secrets**
  3. The key vault › **Access control (IAM)**
  4. `vm-app-1` › **Identity**
  5. **Microsoft Defender for Cloud** › **Overview**
  6. Cloud Shell (Bash) in the lab folder, font size increased, with `RG` and `KV_NAME` set
- Have a 2–3 minute cut ready for the role assignment to propagate (or record the retry later and splice it in).

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 A vault with the RBAC permission model
01:10 Owner is not enough: data-plane roles
01:50 The VM's managed identity
02:25 Run Command: the first request gets 403
03:20 Grant Key Vault Secrets User — then 200 OK
04:30 Secure score and recommendations
05:30 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 15 · Get the password out of the config file" | "Nusantara Retail's storefront keeps its database password in a config file. In the next six minutes we'll move that secret into Azure Key Vault and let the app read it with a managed identity — no password anywhere in code." |
| 00:25 | Key vault › Overview, then **Access configuration** | "This is our vault, kv-nusa plus a random suffix. Under Access configuration you can see the permission model: Azure role-based access control. That's the default for new vaults now, and it means access to secrets is managed with ordinary Azure role assignments." |
| 00:50 | **Properties** blade: soft delete and retention, purge protection | "Soft delete is on — it always is — with seven days of retention for this lab. Purge protection is off here so I can clean up afterwards. In production I'd turn it on, and it can never be turned off again." |
| 01:10 | **Secrets** blade showing `sql-connection`; hover over the value column (don't open the value) | "Here's the secret, sql-connection. I can see it because I gave myself Key Vault Secrets Officer. Being subscription Owner wasn't enough — Owner is a control-plane role. Reading secrets is a data-plane action, and it needs a data-plane role." |
| 01:50 | `vm-app-1` › **Identity** › System assigned: **On**; zoom on the Object (principal) ID — blur the full value | "The app server, vm-app-1, has a system-assigned managed identity. Azure created a service principal for it in Microsoft Entra ID and looks after its credentials. The app never sees a password; it asks the VM's metadata endpoint for a token instead." |
| 02:25 | Cloud Shell: run the Task 5 Run Command (`--scripts @vm/read-secret.sh`) | "Let's ask for the secret from inside the VM. The script first calls the identity endpoint at 169.254.169.254 for a token whose audience is vault.azure.net, then calls Key Vault's REST API with that token." |
| 02:55 | Output: token audience, then `HTTP 403`, `Forbidden / ForbiddenByRbac` | "Look at the result. The token is valid — authentication worked. But Key Vault answered 403 Forbidden, ForbiddenByRbac, because this identity has no role on the vault. Signing in is not the same as being allowed." |
| 03:20 | Key vault › **Access control (IAM)** › Add role assignment › **Key Vault Secrets User** › Members: Managed identity › Virtual machine › `vm-app-1` › Review + assign | "So I grant least privilege: Key Vault Secrets User, which can read secret values and nothing more, scoped to this one vault, assigned to the VM's managed identity." |
| 03:55 | Cut marker "≈ 3 minutes later", then rerun the Run Command | "Role assignments take a few minutes to propagate — the error message even says so. A few minutes later, same command…" |
| 04:10 | Output: `HTTP 200` and the masked value `Server=tcp:sql-nusa-orders...` | "…200 OK. The app has its connection string, and notice the script prints only a masked preview. Next, the lab removes the password from the config file, leaving only the vault address and the secret's name." |
| 04:30 | **Microsoft Defender for Cloud** › Overview: secure score tile | "Now the coach. Defender for Cloud's foundational CSPM is free. It checks resources against the Microsoft cloud security benchmark and turns the results into a secure score." |
| 04:55 | **Recommendations**, filtered to the lab resource group; open one recommendation (for example on the key vault or the VM) | "Each recommendation names the affected resources, explains the risk and offers remediation steps. A fresh lab can take some hours to show findings, because controls are recalculated on a schedule." |
| 05:15 | **Environment settings** › subscription › **Defender plans** (scroll, don't change anything) | "Paid Defender plans add threat detection per workload — servers, storage, databases, Key Vault. They bill per protected resource, so in a lab I just look." |
| 05:30 | Recap slide: three bullets | "Three things to remember: Owner can't read secrets — data needs data-plane roles. Managed identities replace passwords in code. And Defender for Cloud's free tier tells you what to fix next. Don't forget to run cleanup.sh — it also purges the soft-deleted vault." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: Entra, IMDS, ForbiddenByRbac, CSPM).
- Add the chapter list to the description.
- Paste the video link into the lunch README (section 🎬 Demo).
- Delete the demo resources: `bash cleanup.sh` in the lab folder (it deletes the resource group and purges the vault).
