# Lunch 17 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch, which the animation can't show: a Recovery Services
> vault and its security settings, turning on backup for a VM, an on-demand backup job, and getting one lost file back
> with **File Recovery**.
> **Length target:** 5–6 minutes (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, the VM's public IP address, the File Recovery
> **password** and your Cloud Shell prompt if it shows your user name.

## Setup before you press record

The video records in **two sessions**, because the first backup needs time. Session A shows the vault, protection and
**Backup now**. Session B starts after the backup job has passed its snapshot phase, at least 30 minutes later.

- Two recording-only differences from Lab 17. First, File Recovery runs a script that needs outbound network access
  from the machine where you run it, and you need a shell on that machine, so the video VM gets a public IP and allows
  SSH from your Cloud Shell's address only. (The lab VM stays private and restores through a disk instead.) Second,
  the portal offers only Enhanced policies for Trusted Launch VMs, so the video VM uses the Standard security type to
  keep DefaultPolicy on screen, as in the lab, which sets that policy with the CLI.

  ```bash
  cd azure-fundamentals-lunches/labs/17-backup-disaster-recovery
  source ../common/config.sh && source lab.env
  ensure_rg "$RG" 17
  az vm create -g "$RG" -n "$VM" --image "$VM_IMAGE" --size "$VM_SIZE" --security-type Standard \
    --admin-username "$ADMIN_USER" --generate-ssh-keys --public-ip-sku Standard --nsg-rule NONE --output none
  az network nsg rule create -g "$RG" --nsg-name "${VM}NSG" -n allow-ssh-from-cloud-shell --priority 1000 \
    --access Allow --protocol Tcp --destination-port-ranges 22 --source-address-prefixes "$(my_public_ip)" --output none
  az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript --scripts @vm/write-orders.sh \
    --query "value[0].message" --output tsv
  az backup vault create -g "$RG" -n "$VAULT" -l "$LOCATION" --output none
  az backup vault backup-properties set -g "$RG" -n "$VAULT" --backup-storage-redundancy LocallyRedundant --output none
  ```

- Browser tabs: the vault **Overview**, the VM **Overview**, and Cloud Shell (Bash) in a second tab, already in the
  lab folder.
- Afterwards, delete everything with `bash cleanup.sh` from the lab folder. It stops protection first, because a vault
  with protected items can't be deleted.

## Chapters (paste into the video description)

```
00:00 What we'll do
00:20 The vault and its security settings
01:00 Turn on backup for the orders VM
01:45 Back up now and watch the job
02:30 Lose the orders file
03:00 File Recovery: mount a recovery point
04:20 Copy the file back and unmount
05:10 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 17 · Your first restore drill" | "Backups are only worth what you can restore. In the next five minutes we'll protect Nusantara Retail's orders VM with Azure Backup, take a backup, delete a file on purpose and get it back." |
| 00:20 | Vault **Overview** (`rsv-nusa`), then **Properties** | "This is a Recovery Services vault: a separate resource that holds the backups, outside the VM it protects. Under Properties I set the storage to locally redundant, which is fine for a demo and only possible before the first backup." |
| 00:40 | **Properties › Security settings**: soft-delete section with the retention of 14 days | "Here's the security setting that matters most: soft delete. It's on, and on current vaults it can't be switched off. Deleted backups wait here for 14 days before they're really gone." |
| 01:00 | VM **Overview** › **Backup + disaster recovery › Backup** | "Now the VM. On its Backup page I pick the vault and a policy." |
| 01:15 | Policy drop-down: **DefaultPolicy**; point at "daily", "retain 30 days", "instant restore 2 days" | "DefaultPolicy takes one backup a day and keeps it for 30 days. The newest snapshots also stay next to the disks for two days, so recent restores are fast. That's an RPO of up to 24 hours. Fine for daily exports, not for the orders database." |
| 01:30 | **Enable backup**; the notification "Configuring backup" | "Enable backup. Azure adds the backup extension to the VM. No agent to install by hand, and no inbound port to open." |
| 01:45 | VM › **Backup › Backup now** › keep the default retention › **OK** | "The scheduled backup would run tonight. For a drill I don't want to wait, so: Backup now." |
| 02:00 | Vault › **Monitoring › Backup jobs** › the job › **View details**: sub-tasks *Take Snapshot* and *Transfer data to vault* | "The job has two phases. First a snapshot, usually done in minutes. That's already a recovery point we can restore from. Then the copy into the vault, which can take an hour the first time." |
| 02:20 | Title card: "Session B: 40 minutes later" | (no narration) |
| 02:30 | Cloud Shell: `ssh "$ADMIN_USER@<public IP>"`, then `ls -l /data`, `sudo rm /data/orders.csv`, `ls -l /data` | "Forty minutes later. Here's the orders file on the VM, and here's a very bad afternoon: the file is gone." |
| 03:00 | VM › **Backup › File Recovery** › Step 1: pick the newest recovery point | "File Recovery mounts a recovery point as ordinary folders, so I don't have to restore the whole VM. Step one: choose the recovery point from before the deletion." |
| 03:20 | Step 2: **Download script**; blur the password; show the downloaded file name | "Step two: download the script, and note the password; it's only valid for this script. The script must run on a machine that can reach Azure Backup over the internet." |
| 03:40 | Cloud Shell: **Upload** the script, `scp` it to the VM, then in the SSH session `sudo python3 <script name>.py` and paste the password | "I copy it to the VM and run it with sudo. It connects to the recovery point over iSCSI and asks for that password." |
| 04:00 | Script output listing the mounted volumes; `ls` the mount folder it printed | "And there are the disks from the recovery point, mounted read-only next to the live ones." |
| 04:20 | `sudo cp <mount folder>/Volume1/data/orders.csv /data/` (use the path the script printed), then `sudo sha256sum -c /var/lib/nusa/orders.sha256` | "I copy the orders file back and check its fingerprint against the one we saved when the file was created. OK: the restored file is identical." |
| 04:45 | Portal: **File Recovery › Step 3: Unmount disks** | "Always finish with Unmount disks. Otherwise the connection stays open until it times out." |
| 05:10 | Recap slide: three bullets | "Three things to remember. A vault keeps backups outside the thing it protects, and soft delete keeps them even if someone deletes them. Your policy is your RPO, so pick it per system. And a restore you haven't tried is just a hope. In Lab 17 you'll run the same drill on a private VM, with no internet access at all." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: Recovery Services vault, soft delete, DefaultPolicy,
  instant restore, File Recovery, iSCSI)
- Add the chapter list to the description
- Paste the video link into the lunch README (section 🎬 Demo)
- Delete the demo resources: `bash cleanup.sh` in `labs/17-backup-disaster-recovery` (it removes the public IP and the
  NSG with the resource group)
