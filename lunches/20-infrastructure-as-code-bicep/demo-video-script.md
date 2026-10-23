# Lunch 20 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real authoring and deployment experience — Bicep IntelliSense in VS Code, a compile error, what-if
> output, the Deployments page, a redeploy, and a deployment stack refusing a delete — which the animation can only simulate.
> **Length target:** about 5 minutes 50 seconds.
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** editor font 16 px or larger, minimap off, browser zoom 125–150%, clean browser profile,
> notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs (they appear in what-if scopes and resource IDs — crop or blur them), tenant names,
> e-mail addresses, object IDs in error messages.

## Setup before you press record

- VS Code with the **Bicep** extension installed, and the Azure CLI signed in to the demo subscription
  (`az login`, then `az account show` to double-check). Cloud Shell works for the CLI parts if you prefer.
- An empty resource group, created in advance:
  `az group create --name rg-lunch20-demo --location southeastasia --tags course=azure-fundamentals-lunches lunch=20`
- Copy `labs/20-infrastructure-as-code-bicep/starter/main.bicep` to a scratch folder and open it in VS Code. Keep
  `solution/main.bicep` open in a second window that you don't record, as a crib sheet.
- A terminal in the scratch folder, cleared, with a large font.
- A portal tab on the resource group's **Deployments** page and another on **Settings › Deployment stacks**.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 IntelliSense writes the NSG
01:15 A symbolic reference and the visualizer
01:50 Build — and a compile error on purpose
02:25 what-if: four to create
03:00 Deploy and read the Deployments page
03:40 Redeploy, then change one parameter
04:30 Deployment stack with DenyDelete
05:30 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 20 · Infrastructure as Code with Bicep" | "Nineteen lunches of clicks, in one file. In the next six minutes we'll write part of a Bicep file, preview it, deploy it, change it, and protect it." |
| 00:20 | VS Code, starter `main.bicep`; scroll past the parameters and the finished storage account to EXERCISE 1 | "The starter file already has parameters and a storage account. Exercise one is a network security group." |
| 00:35 | Type `resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {` and accept the IntelliSense suggestion for required properties; add the HTTP rule | "Bicep's IntelliSense knows every resource type and API version. It suggests the required properties, and it validates property names as I type — no more guessing JSON." |
| 01:15 | Add the virtual network from the crib sheet; hover over `nsgWeb.id`; open the Bicep visualizer | "In the virtual network, the web subnet points at nsgWeb.id. That symbolic reference is all Bicep needs to deploy the NSG first. The visualizer draws the dependency for you." |
| 01:50 | Terminal: change `nsgWeb.id` to `nsgWbe.id`, run `az bicep build --file main.bicep`; show the error; fix it and build again | "Before Azure sees anything, I compile locally. A typo in a symbolic name is an error, with the line number and a suggestion. Fix it, build again, and we get main.json — the ARM template Bicep generates." |
| 02:25 | `az deployment group what-if --resource-group rg-lunch20-demo --template-file main.bicep` | "What-if compares the file with what exists. Plus means create: four resources, nothing else touched. This is what a reviewer should see in every pull request." |
| 03:00 | `az deployment group create … --name lab20-main`; then the portal **Deployments** page: inputs, outputs, template | "Deploy. Resource Manager orders the work from the dependencies and creates independent resources in parallel. The Deployments page keeps the template, the parameters and the outputs for every run." |
| 03:40 | Run the same deploy again; then what-if with `--parameters environment=test` | "Run it again: nothing changes, because the deployment is idempotent. Now change one parameter. Every resource shows a tilde — modify — and the detail line shows the environment tag going from lab to test. If you see other properties listed, read them: what-if can show defaults as noise." |
| 04:30 | `az stack group create --name stack-nusa-iac … --deny-settings-mode denyDelete --action-on-unmanage deleteResources --yes`; portal **Deployment stacks** page | "Now the same file as a deployment stack with DenyDelete. The stack lists the resources it manages and puts a deny assignment on them." |
| 04:55 | `az storage account delete --name <storage> --resource-group rg-lunch20-demo --yes`; show `DenyAssignmentAuthorizationFailed` (blur IDs) | "Even as an Owner, deleting the storage account is refused by the stack's deny assignment. To remove things, you change the file or delete the stack — which is exactly what we do next." |
| 05:15 | `az stack group delete --name stack-nusa-iac --resource-group rg-lunch20-demo --action-on-unmanage deleteResources --yes` | "Deleting the stack with deleteResources removes everything it managed. The file can rebuild it in minutes." |
| 05:30 | Recap slide: three bullets | "Three things to remember: the file is the truth; always run what-if first; and deployment stacks add lifecycle and protection. In Lab 20 you'll complete the file yourself." |

## After recording

- Add captions (auto-generate, then correct terms by hand: Bicep, what-if, idempotent, deployment stack, DenyDelete)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: delete the stack if it still exists, then
  `az group delete --name rg-lunch20-demo --yes --no-wait`
