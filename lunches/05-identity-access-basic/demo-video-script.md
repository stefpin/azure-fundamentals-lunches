# Lunch 05 · Walkthrough video script (≤ 6 minutes)

🇮🇩 [Baca dalam Bahasa Indonesia](demo-video-script.id.md)

> **Purpose:** show the real Azure experience for this lunch — the part an animation cannot show.
> **Length target:** 4–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

**Topic:** create a test user and a group in Microsoft Entra ID, assign a role at resource-group scope, and use
*Check access* to prove what the user can and can't do.

## Setup before you press record

- Use a **personal demo tenant** where you are Global Administrator (the tenant your free account created). The video
  shows user and group names, so never record in a company tenant.
- Create the resource group and a free network security group to look at (Cloud Shell, Bash):

  ```bash
  az group create --name rg-lunch05-demo --location southeastasia --tags course=azure-fundamentals-lunches lunch=05
  az network nsg create --resource-group rg-lunch05-demo --name nsg-web --output none
  ```

- Decide the test user's name in advance (for example *Rizky (demo)*, `rizky-demo@<your-tenant>.onmicrosoft.com`).
  You'll let the portal auto-generate the temporary password; plan to **blur it** in the edit.
- Browser tabs, signed in as your admin account:
  1. Azure portal › **Microsoft Entra ID › Users**
  2. Azure portal › **Microsoft Entra ID › Groups**
  3. Azure portal › **Resource groups › rg-lunch05-demo › Access control (IAM)**
- Optional: a slide with the formula **security principal + role definition + scope = role assignment**.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:25 Create a test user
01:25 Create a group and add the user
02:15 Assign Reader at resource-group scope
03:20 Check access: what can Rizky do?
04:10 Upgrade to Contributor, and what Contributor still can't do
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 05 · Give a contractor just enough access" | "Nusantara Retail's new contractor, Rizky, starts on Monday. In the next five minutes we'll give him his own identity, put him in a group, and give that group exactly one role at exactly one scope — then prove what he can and can't do." |
| 00:25 | Entra ID › Users › **New user › Create new user** | "Everything starts in Microsoft Entra ID, our tenant's directory. I'll create a user for Rizky. The user principal name ends with the tenant's domain. I'll let the portal auto-generate a temporary password — it's blurred in this video — and Rizky sets his own at his first sign-in, so only he ever knows his real password." |
| 01:05 | User created; open the user's **Overview** | "Here's Rizky's account. Notice there are no Azure permissions anywhere on this page — a user account only answers *who are you*. What he can do comes later, from role assignments." |
| 01:25 | Entra ID › Groups › **New group**: type *Security*, name *grp-nusa-contractors-demo* | "We never give access to a person directly. I'll create a security group for contractors, so when the next contractor arrives — or Rizky leaves — it's a single membership change." |
| 01:55 | Group › **Members › Add members** › select Rizky | "Add Rizky as a member. That's the identity side done: one user, one group." |
| 02:15 | Resource groups › rg-lunch05-demo › **Access control (IAM) › Add › Add role assignment** | "Now authorization. I'm on the *Access control (IAM)* page of one resource group — that's our scope. Every assignment I add here applies to this resource group and everything inside it, and nothing else." |
| 02:40 | **Role** tab: search *Reader*; point at Owner, Contributor and Reader on the privileged and job-function tabs | "Role definition next. Owner can do everything, including granting access. Contributor can manage everything but can't grant access. Reader can only look. We'll start Rizky on Reader." |
| 03:00 | **Members** tab: *User, group, or service principal* › select the group › **Review + assign** | "And the security principal: the contractors group, not Rizky himself. Security principal, role, scope — that's a role assignment." |
| 03:20 | IAM › **Check access** › search *Rizky* | "Can Rizky do anything here? *Check access* answers that. It shows Reader on this resource group, inherited through his group membership. Notice the subscription and every other resource group aren't in the list — he can't see them at all." |
| 03:50 | IAM › **Role assignments** tab, filtered to the group | "The assignment list says the same thing from the resource group's point of view: one group, one role, this scope. Role changes can take a few minutes to reach a signed-in user, so if you test in another window, sign out and back in." |
| 04:10 | Add a second role assignment: **Contributor** for the same group; then remove the Reader assignment | "When the migration work starts, Rizky's team needs to change things. I add Contributor for the same group at the same scope and remove Reader, because Contributor already includes reading. Least privilege also means no leftovers." |
| 04:45 | IAM › **Check access** › Rizky › open the Contributor assignment and point at *NotActions* | "Even as Contributor, Rizky can't add role assignments — Contributor excludes the permissions to manage access — and he still can't see anything outside this resource group." |
| 05:15 | Recap slide: principal + role + scope | "Three things to remember. One: people get their own accounts, never shared ones. Two: grant roles to groups, at the narrowest scope that works. Three: *Check access* tells you the truth, so use it before and after every change. In Lab 05 you'll do all of this yourself and sign in as Rizky." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: remove the role assignments, delete the test user and the group, then
  `az group delete --name rg-lunch05-demo --yes --no-wait`
