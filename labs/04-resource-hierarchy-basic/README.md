# Lab 04 · Organise Nusantara Retail

> **Pairs with:** [Lunch 04 · Resource Hierarchy and Azure Resource Manager (Basic)](../../lunches/04-resource-hierarchy-basic/README.md)
> **Time:** about 40 minutes · **Cost:** 💲 (see [cost bands](../README.md#cost-bands)) · **Difficulty:** ★★☆
> **Works on its own:** ✅ You do not need any earlier lab. Everything this lab needs is created by its own steps.

## 🎯 What you'll build

Nusantara Retail is replacing its pile of experiments with a structure. You create two tagged resource groups, one for
the storefront and one for shared services, and a storage account for product photos. You take the account's resource
ID apart, prove that resource group tags don't reach the resources inside, and watch two kinds of lock stop you: a
`CanNotDelete` lock blocks a deletion, and a `ReadOnly` lock blocks something that looks like a simple read. Then you
move the account to the shared resource group, where it belongs, and find everything again with Azure Resource Graph.
Optionally, you create a management group in your own tenant.

```mermaid
flowchart LR
  subgraph sub["Your subscription"]
    subgraph shop["rg-lunch04-shop-&lt;suffix&gt;<br/>project=storefront · costCenter=ecommerce"]
      st1["stnusaimg&lt;suffix&gt;<br/>created here, locked, unlocked"]
    end
    subgraph shared["rg-lunch04-shared-&lt;suffix&gt;<br/>project=shared-services · costCenter=it"]
      st2["stnusaimg&lt;suffix&gt;<br/>after the move"]
    end
  end
  st1 -- "az resource move" --> st2
  graph["Azure Resource Graph<br/>queries by tag"] -.-> shop
  graph -.-> shared
```

## ✅ Before you start

- An Azure subscription where you are **Owner** (see [Lab 01](../01-before-you-begin/README.md)). Creating and
  removing locks needs Owner or User Access Administrator; Contributor isn't enough.
- **Azure Cloud Shell (Bash)** — open [shell.azure.com](https://shell.azure.com). Nothing to install.
- Get the lab files and load the shared settings:

```bash
git clone https://github.com/stefpin/azure-fundamentals-lunches.git   # first time only
cd azure-fundamentals-lunches/labs/04-resource-hierarchy-basic
source ../common/config.sh
RG_SHOP=$(rg_name 04 shop)
RG_SHARED=$(rg_name 04 shared)
ST="stnusaimg${SUFFIX}"
ST_TYPE="Microsoft.Storage/storageAccounts"
```

- This lab has no `setup.sh`: you create everything yourself.
- If Cloud Shell times out and restarts, `cd` back into the lab folder and run the five lines after `cd` again. Task 3
  shows how to get the storage account's ID back into `ST_ID`.

> [!IMPORTANT]
> Lab resources cost money while they exist (an empty storage account costs next to nothing, but clean up anyway). If
> you stop halfway, run **Clean up**: it removes any lock you left behind before deleting the resource groups.

## 🧭 Choose your mode

| Mode | For you if… | How |
|---|---|---|
| **Guided** | you want every step explained | follow Tasks 1–8 below |
| **Challenge** | you already know the basics | read only the [Challenge brief](#-challenge-brief), build it your way, then run `bash verify.sh` |

## Task 1 · Two tagged resource groups

The storefront and the shared services have different owners and lifecycles, so they get separate resource groups.
`ensure_rg` creates each group with the course's `course` and `lunch` tags (the cleanup script finds groups by them);
then you **merge** in your own tags.

```bash
ensure_rg "$RG_SHOP" 04
ensure_rg "$RG_SHARED" 04

az tag update --resource-id "$(az group show --name "$RG_SHOP" --query id --output tsv)" \
  --operation Merge --tags project=storefront env=lab costCenter=ecommerce --output none
az tag update --resource-id "$(az group show --name "$RG_SHARED" --query id --output tsv)" \
  --operation Merge --tags project=shared-services env=lab costCenter=it --output none

az group list --query "[?tags.lunch=='04'].{name:name, location:location, project:tags.project, costCenter:tags.costCenter}" \
  --output table
```

`Merge` adds tags and updates existing ones. `Replace` would throw away every tag that isn't in your list, including
the `course` and `lunch` tags that cleanup relies on, so be careful which one you pick.

> [!TIP]
> **Prefer the portal?** *Resource groups › rg-lunch04-shop-… › Tags*: add the three tags and select **Apply**. The
> portal edits the same tag set that the CLI does.

> ✅ **Checkpoint:** the table shows both groups in your `LOCATION`, with `storefront`/`ecommerce` and
> `shared-services`/`it`.

## Task 2 · A storage account, and tags that don't flow down

Create the product-photo storage account in the storefront's resource group, then look at its tags.

```bash
az storage account create --name "$ST" --resource-group "$RG_SHOP" --location "$LOCATION" \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false \
  --output none

az storage account show --name "$ST" --resource-group "$RG_SHOP" --query tags
```

The answer is `{}` (or nothing at all): the group's `project`, `env` and `costCenter` tags did **not** flow down to the
account. Tag the resource itself:

```bash
ST_ID=$(az storage account show --name "$ST" --resource-group "$RG_SHOP" --query id --output tsv)
az tag update --resource-id "$ST_ID" --operation Merge --tags app=product-images env=lab --output none
az tag list --resource-id "$ST_ID" --query properties.tags
```

> ✅ **Checkpoint:** the account exists in the shop group and carries exactly the tags you gave it, `app` and `env`,
> and none of the group's tags.

## Task 3 · Take the resource ID apart

A resource ID is the address Azure Resource Manager uses for everything. Print it, then split it on the slashes.

```bash
echo "$ST_ID"
IFS='/' read -r -a parts <<< "$ST_ID"
for i in "${!parts[@]}"; do printf '%2d  %s\n' "$i" "${parts[$i]}"; done
```

Read the numbered output: `1`–`2` are the subscription (keep the ID to yourself), `3`–`4` the resource group, `5`–`6`
the resource provider namespace, `7` the resource type and `8` the name. The ID alone is enough to find the resource:

```bash
az resource show --ids "$ST_ID" --query "{name:name, type:type, location:location, group:resourceGroup}" --output table
```

Now look at the resource provider behind it, the resource types it offers and the newest API versions of the storage
account type:

```bash
az provider show --namespace Microsoft.Storage --query "{namespace:namespace, state:registrationState}" --output table
az provider show --namespace Microsoft.Storage --query "resourceTypes[].resourceType" --output tsv | head -n 12
az provider show --namespace Microsoft.Storage \
  --query "resourceTypes[?resourceType=='storageAccounts'].apiVersions | [0][:3]" --output tsv
```

> [!TIP]
> Lost `ST_ID` after a Cloud Shell restart? Get it back with
> `ST_ID=$(az storage account list --query "[?name=='${ST}'].id | [0]" --output tsv)`, which finds the account in
> whichever resource group it is in now.

> ✅ **Checkpoint:** you can say which part of the ID is the subscription, the resource group, the provider namespace
> (`Microsoft.Storage`), the type (`storageAccounts`) and the name. The provider shows `Registered`.

## Task 4 · A CanNotDelete lock blocks deletion

Pak Budi wants the photo store protected against accidental deletion. A `CanNotDelete` lock (called **Delete** in the
portal) does that for everyone, Owners included.

```bash
az lock create --name lock-nodelete --lock-type CanNotDelete \
  --resource-group "$RG_SHOP" --resource "$ST" --resource-type "$ST_TYPE" \
  --notes "Product photos - do not delete" --output none

az lock list --resource-group "$RG_SHOP" --resource "$ST" --resource-type "$ST_TYPE" \
  --query "[].{name:name, level:level}" --output table
```

Give the lock a few seconds, then try to delete the account. The `az lock show … &&` part is a safety net: the delete
only runs if the lock really exists.

```bash
sleep 15
az lock show --name lock-nodelete --resource-group "$RG_SHOP" \
  --resource "$ST" --resource-type "$ST_TYPE" --output none \
  && az storage account delete --name "$ST" --resource-group "$RG_SHOP" --yes
```

The delete fails with an error code **ScopeLocked** and a message saying that the scope can't perform the delete
operation because a scope is locked. Changes are still allowed, because this lock only blocks deletion:

```bash
az tag update --resource-id "$ST_ID" --operation Merge --tags owner=dewi --output none \
  && echo "Tag added: a CanNotDelete lock still allows changes."
```

Remove the lock before the next task:

```bash
az lock delete --name lock-nodelete --resource-group "$RG_SHOP" --resource "$ST" --resource-type "$ST_TYPE"
```

> [!TIP]
> **Prefer the portal?** *Storage account › Settings › Locks › Add*, lock type **Delete**. Then try **Delete** on the
> account's Overview page and read the notification.

> ✅ **Checkpoint:** the delete was refused with `ScopeLocked`, the tag update worked, and the lock list is empty again.

## Task 5 · A ReadOnly lock blocks more than you expect

A `ReadOnly` lock (**Read-only** in the portal) lets everyone read and nobody change anything. "Reading" means GET
requests only, and that's where the surprise comes from.

```bash
az lock create --name lock-readonly --lock-type ReadOnly \
  --resource-group "$RG_SHOP" --resource "$ST" --resource-type "$ST_TYPE" --output none
sleep 15

# 1) Reading the account's properties is a GET: allowed
az storage account show --name "$ST" --resource-group "$RG_SHOP" --query "{name:name, sku:sku.name}" --output table

# 2) Listing the access keys is a POST: blocked (the query prints only how many keys, never the keys themselves)
az storage account keys list --account-name "$ST" --resource-group "$RG_SHOP" --query "length(@)" --output tsv

# 3) Changing a tag is a write: blocked
az tag update --resource-id "$ST_ID" --operation Merge --tags reviewed=yes --output none
```

Commands 2 and 3 fail with **ScopeLocked**. Listing keys feels like a read, but it's a POST action on purpose: the keys
give full access to every blob in the account, so Azure doesn't hand them out through an ordinary GET. A ReadOnly lock
blocks every POST, because Resource Manager can't know which POST actions change something. An application that
fetches its storage keys at startup would break the moment someone adds this lock.

Remove the lock and confirm that keys can be listed again (still only the count):

```bash
az lock delete --name lock-readonly --resource-group "$RG_SHOP" --resource "$ST" --resource-type "$ST_TYPE"
sleep 15
az storage account keys list --account-name "$ST" --resource-group "$RG_SHOP" --query "length(@)" --output tsv
```

> ✅ **Checkpoint:** with the ReadOnly lock in place, `show` worked while `keys list` and `tag update` were refused.
> After removing the lock, `keys list` prints `2`.

## Task 6 · Move the account to the shared resource group

Other apps, such as the stores' tablets, will use the product photos too, so the account belongs in the shared group.
Moving it changes its resource group, and therefore its ID, but not its region or its data.

```bash
OLD_ID="$ST_ID"
az resource move --destination-group "$RG_SHARED" --ids "$OLD_ID"
```

The move takes a minute or two. While it runs, both resource groups are locked against changes, but the storage
account keeps serving data. When the prompt returns, compare the IDs:

```bash
ST_ID=$(az storage account show --name "$ST" --resource-group "$RG_SHARED" --query id --output tsv)
echo "old: $OLD_ID"
echo "new: $ST_ID"
az resource show --ids "$OLD_ID" --output none      # fails with ResourceNotFound: the old address is gone
az storage account show --name "$ST" --resource-group "$RG_SHARED" \
  --query "{group:resourceGroup, location:primaryLocation, tags:tags}" --output json
```

The location is unchanged and the account's own tags (`app`, `env`, `owner`) travelled with it, but it didn't pick up
the shared group's `costCenter=it`: tags still don't inherit.

> [!TIP]
> **Prefer the portal?** On the account's *Overview* page, select **move** next to *Resource group*, then
> **Move to another resource group**. The portal validates the move before it starts.

> ✅ **Checkpoint:** the new ID contains `rg-lunch04-shared-<suffix>`, the old ID returns `ResourceNotFound`, and the
> account's location is still your `LOCATION`.

## Task 7 · Find everything with Azure Resource Graph

Resource Graph searches every subscription you can read, in seconds. Its CLI commands live in the `resource-graph`
extension; this setting lets the Azure CLI install extensions automatically, without asking:

```bash
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
```

Resource groups live in the `ResourceContainers` table:

```bash
az graph query -q "ResourceContainers
  | where type =~ 'microsoft.resources/subscriptions/resourcegroups'
  | where tags.lunch == '04'
  | project name, location, project=tostring(tags.project), costCenter=tostring(tags.costCenter)" \
  --query "data[]" --output table
```

Resources live in the `Resources` table:

```bash
az graph query -q "Resources | where tags.app == 'product-images' | project name, type, resourceGroup, location" \
  --query "data[]" --output table

# Proof that tags don't inherit: no resource carries the shared group's costCenter=it
az graph query -q "Resources | where tags.costCenter == 'it' | project name, resourceGroup" \
  --query "data[]" --output table
```

Resource Graph is an index of your resources, so a change you made seconds ago may take a little while to appear. If a
result looks stale, wait a minute and run the query again.

> [!TIP]
> **Prefer the portal?** Search for **Resource Graph Explorer**, paste a query without the `az graph query -q` part
> and select **Run query**. You can save queries and pin results to a dashboard.

> ✅ **Checkpoint:** the first query lists both resource groups with their project and cost centre, the second lists
> the storage account in the shared group, and the third returns no rows.

## Task 8 (optional) · A management group in your own tenant

> [!WARNING]
> Do this only in **your own** tenant, for example the one created with your free account, where you are a Global
> Administrator. Management groups are tenant-wide: in a company tenant you could affect other people's governance, or
> your administrators may have blocked it. Never move a work subscription. The first management group in a tenant can
> take up to 15 minutes to appear, because Azure first sets up the root management group.

```bash
MG="mg-nusa-lab-${SUFFIX}"
az account management-group create --name "$MG" --display-name "Nusantara Retail (lab)" --output none
az account management-group show --name "$MG" \
  --query "{name:name, displayName:displayName, parent:details.parent.displayName}" --output table
```

The new group's parent is the Tenant root group. In the portal (*Management groups*) you can see your subscription
under the Tenant root group, next to the new, empty management group. Leave the subscription where it is; Lunch 31
covers designing and filling a hierarchy. `cleanup.sh` deletes this management group for you.

> ✅ **Checkpoint:** `az account management-group show` prints your group with *Tenant Root Group* as its parent. If you
> get an authorization error, your tenant requires permission to create management groups; skip this task.

## 🔧 Break it and fix it

Pak Budi decides to "protect" the whole shared resource group with a ReadOnly lock, without telling anyone:

```bash
az lock create --name lock-protect-shared --lock-type ReadOnly --resource-group "$RG_SHARED" \
  --notes "Added by Pak Budi" --output none
sleep 15
```

Now try a harmless change on the storage account:

```bash
az tag update --resource-id "$ST_ID" --operation Merge --tags reviewed=yes --output none
```

**Symptom:** the update fails with **ScopeLocked**, yet you never put a lock on the storage account. Find out where the
lock lives and fix it.

<details><summary>Hint and fix</summary>

Locks are inherited. Listing the locks that apply to a resource includes the ones on its resource group and
subscription, and each lock's ID shows the scope where it was set:

```bash
az lock list --resource-group "$RG_SHARED" --resource "$ST" --resource-type "$ST_TYPE" \
  --query "[].{name:name, level:level, scope:id}" --output table
```

The ID of `lock-protect-shared` ends at the resource group, not at the storage account. Remove it and retry:

```bash
az lock delete --name lock-protect-shared --resource-group "$RG_SHARED"
sleep 15
az tag update --resource-id "$ST_ID" --operation Merge --tags reviewed=yes --output none && echo "Fixed."
```

What should Pak Budi have used? A `CanNotDelete` lock protects the group from deletion without blocking everyday
changes, and role assignments decide who may change things.

</details>

## 🧪 Verify your work

```bash
bash verify.sh
```

Every check should say **PASS**. If one fails, the message tells you which task to revisit.

## 🧹 Clean up (do not skip!)

```bash
bash cleanup.sh
```

This removes any lock left in the Lab 04 resource groups, deletes the optional management group `mg-nusa-lab-<suffix>`
if it exists, and then deletes both resource groups with the storage account. Deletion continues in the background for
a few minutes. If you want the Azure CLI to ask again before installing extensions, run
`az config unset extension.use_dynamic_install`.

## 🩺 Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `(AuthorizationFailed) ... does not have authorization to perform action 'Microsoft.Authorization/locks/write'` | You are Contributor, not Owner or User Access Administrator | Use a subscription where you are Owner, such as your own free account |
| `(ScopeLocked) The scope '...' cannot perform delete operation because following scope(s) are locked` | A lock on the resource or one of its parents | `az lock list --resource-group ... --resource ... --resource-type ...` shows every lock that applies; remove the right one |
| `az resource move` fails with `ScopeLocked` | A ReadOnly lock on the source or destination resource group (or the subscription) | Remove the lock, then move again |
| `az resource show --ids "$OLD_ID"` says `ResourceNotFound` | Expected after the move: the ID changed | Use the new ID from Task 6 |
| `az graph query` asks to install an extension or says the command isn't found | The `resource-graph` extension isn't installed yet | Run the `az config set extension.use_dynamic_install=yes_without_prompt` line from Task 7, or `az extension add --name resource-graph` |
| A Resource Graph query doesn't show a change you just made | The index is still catching up | Wait a minute and run the query again |
| `(StorageAccountAlreadyTaken) The storage account named ... is already taken.` | Storage account names are global | Run `bash cleanup.sh`, then `rm ~/.azlunches-suffix`, `source ../common/config.sh` again and restart from Task 1 |
| `ensure_rg` fails with `ScopeLocked` when you rerun Task 1 | A lock from Task 4, 5 or the break-and-fix exercise is still in place | Remove it (see the break-and-fix hint), then rerun |
| Management group creation fails with `AuthorizationFailed` | Hierarchy protection in your tenant requires permissions to create management groups | Skip Task 8; it is optional |

## 🚀 Stretch goals

- Validate a move without performing it: `az resource invoke-action --action validateMoveResources` with the source
  group's ID and a request body naming the resource and the target group (see the
  [move documentation](https://learn.microsoft.com/azure/azure-resource-manager/management/move-resource-group-and-subscription)).
- Pick three resource types you expect to use in later lunches and look them up in the
  [list of resource types that support move](https://learn.microsoft.com/azure/azure-resource-manager/management/move-support-resources).
- Create a blob container through the control plane (`az storage container-rm create`), print its resource ID and
  find the child-resource segments that follow the account name.
- Write a Resource Graph query that lists every resource in your subscription that has **no** `costCenter` tag, and
  save it in Resource Graph Explorer.

## 🏁 Challenge brief

Build the following, any way you like (portal, CLI, Bicep):

1. Two resource groups in your `LOCATION`: `rg-lunch04-shop-<suffix>` with the tags `project=storefront`, `env=lab`
   and `costCenter=ecommerce`, and `rg-lunch04-shared-<suffix>` with `project=shared-services`, `env=lab` and
   `costCenter=it`. Both also keep `course=azure-fundamentals-lunches` and `lunch=04` (`ensure_rg` adds them).
2. A StorageV2 account `stnusaimg<suffix>` (`Standard_LRS`, TLS 1.2 minimum, anonymous blob access disabled), tagged
   `app=product-images` and `env=lab`, created in the shop group and then **moved** to the shared group.
3. Not checked by the script: prove that a `CanNotDelete` lock blocks deleting the account and that a `ReadOnly` lock
   blocks listing its keys.
4. No resource locks left on either resource group or on the account.
5. Not checked by the script: a Resource Graph query that lists both resource groups by their `lunch` tag.

Then run `bash verify.sh`. Stuck? Peek at `solution.sh` or switch to Guided mode.

---

⬅️ [Lunch 04 reading](../../lunches/04-resource-hierarchy-basic/README.md) · 🏠 [All labs](../README.md) · 🏠 [Course home](../../README.md)

<sub>Last validated: October 2026 · Something broken? [Report a lab problem](../../CONTRIBUTING.md).</sub>
