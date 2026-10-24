# Lunch 22 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

**Topic:** a least-privilege custom role, a user-assigned managed identity with a data role, and an app registration
whose only credential is a federated credential — then a GitHub Actions run that signs in to Azure with OpenID Connect
and no stored secret.

## Setup before you press record

- A **personal demo tenant and subscription**. Also blur tenant IDs and client IDs in the edit: they aren't secrets, but
  there's no reason to publish them.
- Run Lab 22's reference solution once, so the resources exist, and keep its output (off screen):

  ```bash
  cd azure-fundamentals-lunches/labs/22-identity-access-advanced
  GITHUB_REPO="<your-github-user>/<your-demo-repo>" bash solution.sh
  ```

- In a **personal GitHub repository** named in the federated credential: add `github-workflow-example.yml` as
  `.github/workflows/azure-oidc.yml`, the three repository secrets and the repository variable described in the lab,
  and create a second branch called `feature/test` that contains the same workflow.
- Browser tabs:
  1. Azure portal › *rg-lunch22-&lt;suffix&gt;* › **Access control (IAM)**
  2. Azure portal › **Managed Identities** › *id-nusa-reports*
  3. Microsoft Entra admin center › **App registrations** › *app-nusa-github-deploy-&lt;suffix&gt;*
  4. GitHub › your repository › **Actions**

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 A custom role that can only operate VMs
01:30 A user-assigned managed identity with a data role
02:25 An app registration without a secret
03:35 GitHub Actions signs in with OpenID Connect
04:35 The wrong branch is refused
05:20 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 22 · Passwordless pipelines and least privilege" | "Nusantara Retail's auditor found a client secret in a build log and an operator with far more power than his job needs. In six minutes we'll fix both: a role that does exactly one job, and a pipeline that signs in to Azure without any stored secret." |
| 00:25 | Resource group › **Access control (IAM) › Roles** tab › search *Nusantara VM Operator* › open the role › **JSON** view | "Here's our custom role. Four operations on virtual machines: read, start, restart and deallocate — no create, no change, no delete. And look at the assignable scopes: just this resource group. The role can't even be assigned anywhere else." |
| 01:05 | **Role assignments** tab, filtered to the custom role | "It's assigned to the VM operators group at this scope. The night-shift operator can restart the storefront VM at 3 a.m., but he can't resize it, delete it or touch the network." |
| 01:30 | Managed Identities › *id-nusa-reports* › **Overview** (point at Client ID and Object ID) | "Next, a user-assigned managed identity for the reporting app. It's an Azure resource of its own, so it survives when the app's compute is rebuilt. Azure manages its credentials; nobody ever sees them." |
| 01:55 | Storage account › **Access control (IAM) › Role assignments**: *Storage Blob Data Reader* for the identity | "It holds one data role on one storage account: Storage Blob Data Reader. It can read the sales exports and nothing else — it can't even list the account's keys." |
| 02:25 | App registration › **Certificates & secrets** › *Client secrets* tab (empty) | "Now the pipeline. This app registration has no client secrets and no certificates — the tab is empty, and it stays empty." |
| 02:45 | **Federated credentials** tab › open *github-main-branch* | "Instead it has a federated credential. The issuer is GitHub's token service, the audience is the token-exchange value, and the subject names one repository and one branch: main. Entra ID will only trust tokens that match all three exactly." |
| 03:15 | **Add credential** › scenario *GitHub Actions deploying Azure resources* (show the fields, then cancel) | "The portal builds the subject for you from organisation, repository and entity type — branch, environment, pull request or tag. Cancel; we already have ours." |
| 03:35 | GitHub › the workflow file: `permissions: id-token: write` and the `azure/login@v3` step | "In GitHub, the workflow asks for permission to request an ID token and passes only a client ID, a tenant ID and a subscription ID to Azure Login. None of them are secrets." |
| 03:55 | **Actions** › run the workflow on *main* › open the run log | "Run it on main. Azure Login exchanges GitHub's short-lived token for an Azure access token, and the next step lists what the service principal can see: one resource group, read-only." |
| 04:35 | Run the workflow on *feature/test* › failed login step, error with `AADSTS700213` | "Now the same workflow from another branch. GitHub issues a perfectly valid token, but its subject ends in feature/test, and no federated credential matches. Entra ID refuses the exchange, and the job never gets near Azure." |
| 05:00 | Copy the subject from the error message | "Bonus tip: the error shows the exact subject GitHub sent. If you ever see this on a branch you *do* trust, that's the value for a new federated credential." |
| 05:20 | Recap slide: custom role · managed identity · federated credential | "Three things to remember. Custom roles grant exactly the operations a job needs, at a scope you choose. Managed identities and federated credentials mean there's nothing secret to store or rotate. And the subject is your security boundary — keep it as narrow as the job." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: run `bash cleanup.sh` in the lab folder, then delete the workflow, secrets and variable from
  your GitHub repository
