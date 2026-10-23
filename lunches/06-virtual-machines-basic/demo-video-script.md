# Lunch 06 · Walkthrough video script (≤ 6 minutes)

> **Purpose:** show the real Azure experience for this lunch — creating a Linux VM in the portal, connecting to it from
> Cloud Shell, opening port 80, and seeing the difference between *Stopped* and *Stopped (deallocated)* — the parts an
> animation cannot show.
> **Length target:** about 5 minutes 30 seconds (short videos keep attention; split anything longer).
> **Record in:** a personal or dedicated demo subscription — never a company subscription.
> **Before recording:** browser zoom 125–150%, clean browser profile, notifications off, portal in the default theme.
> **Hide on screen:** subscription IDs, tenant names, e-mail addresses, public IP addresses you will keep using.

## Setup before you press record

- A resource group in Southeast Asia, created in Cloud Shell:
  `az group create --name rg-video06 --location southeastasia --tags course=azure-fundamentals-lunches lunch=06`
- An SSH key pair in Cloud Shell: `ls ~/.ssh/id_rsa.pub || ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""`. Copy the
  output of `cat ~/.ssh/id_rsa.pub` into a text editor **off-screen** so you can paste it into the portal.
- The sample page from the repository open in Cloud Shell: `cd ~/azure-fundamentals-lunches/labs/06-virtual-machines-basic`.
- Browser tabs: the Azure portal on **Home**, and the portal's Cloud Shell pane (Bash) ready to open.
- Deployment takes one to three minutes. Plan a jump cut at 02:40 rather than recording the wait.
- The VM's public IP appears on screen. It is released when you delete the resource group, but blur it in editing if
  you keep the VM for longer.

## Chapters (paste into the video description)

```
00:00 What we'll build
00:20 Basics: image, size and SSH key
01:20 Disks and networking: the resources you don't see
02:15 Review + create, and what really got created
02:50 SSH from Cloud Shell and install nginx
03:50 Open port 80 and load the page
04:25 Stopped, deallocated and auto-shutdown
05:15 Recap
```

## Script

| Time | On screen | Narration |
|---|---|---|
| 00:00 | Title card: "Lunch 06 · Your first VM in Azure" | "In the next five minutes we'll rent Nusantara Retail's first server in Azure, connect to it, put the shop online, and see when it stops costing money." |
| 00:20 | Portal › Virtual machines › Create › Azure virtual machine › **Basics** | "Resource group rg-video06, name vm-web-1, region Southeast Asia. For a single test server I choose no infrastructure redundancy — we'll fix that in later lunches." |
| 00:45 | Security type *Trusted launch*; Image *Ubuntu Server 24.04 LTS – x64 Gen2* | "Trusted Launch is already selected: Secure Boot and a virtual TPM, at no extra cost. The image is Ubuntu 24.04, the same as the storefront today." |
| 01:00 | Size › *See all sizes* › search `B2ats` | "Sizes are families. B is burstable: a low baseline with credits for short bursts. Standard_B2ats_v2 has two vCPUs and one gigabyte of memory — enough for nginx." |
| 01:10 | Authentication *SSH public key*, source *Use existing public key*, paste the key; inbound ports *SSH (22)* | "No password. I paste the public half of my Cloud Shell key; the private half never leaves Cloud Shell. The portal will open port 22 — fine for this demo, not for production." |
| 01:20 | **Disks** tab: OS disk type *Standard SSD*; point at *Delete with VM* | "The OS disk is its own managed disk resource. Standard SSD keeps the demo cheap; production would use Premium SSD. Notice *Delete with VM* — leftovers cost money." |
| 01:40 | **Networking** tab: new virtual network, edit address space to 10.20.0.0/16 and subnet snet-web 10.20.1.0/24; public IP (new); NIC network security group *Basic* | "Here are the resources nobody mentions: a virtual network and subnet — I choose 10.20, not head office's 10.0 range — a Standard public IP, and a network security group on the network card." |
| 02:00 | **Management** tab: *Enable auto-shutdown* on, 19:00, time zone *(UTC+07:00) Bangkok, Hanoi, Jakarta* | "Auto-shutdown deallocates the VM every evening. Great for test machines — never for the production shop." |
| 02:15 | **Review + create** › *Create*; then (after the cut) the deployment's *Resource* list | "Validation passes, and the deployment starts. *(cut)* Done. Look at the list: VM, disk, network interface, NSG, public IP, virtual network — one click, six resources." |
| 02:50 | VM overview: copy the public IP; open Cloud Shell (Bash): `ssh azureuser@<IP>` | "I connect from Cloud Shell. The first time, SSH asks me to trust the host key." |
| 03:10 | In the VM: `sudo apt-get update && sudo apt-get install -y nginx` | "nginx comes from the Ubuntu mirror. That works because the VM has its own public IP — an explicit outbound path. New virtual networks don't give VMs internet access by default." |
| 03:35 | In Cloud Shell (exit SSH first): `scp app/index.html azureuser@<IP>:index.html` and `ssh azureuser@<IP> 'sudo cp ~/index.html /var/www/html/'`; browser to `http://<IP>` spins | "The page is on the server — but the browser just spins. Something in front of the VM is dropping port 80." |
| 03:50 | VM › Networking › Network settings › *Create port rule* › Inbound › service HTTP, priority 900 › Add; reload the browser | "The NSG only allowed SSH. One inbound rule for HTTP at priority 900, a few seconds, and Nusantara Retail is online." |
| 04:25 | VM overview › **Stop**; status changes to *Stopped (deallocated)* | "The portal's Stop button deallocates: the VM releases its host, and the compute meter stops. The disks and the public IP remain — and are still billed." |
| 04:50 | Cloud Shell: `az vm start -g rg-video06 -n vm-web-1` then `az vm stop -g rg-video06 -n vm-web-1`; then `az vm show -d -g rg-video06 -n vm-web-1 --query powerState` → `VM stopped` | "Careful: the CLI's stop, or a shutdown inside Ubuntu, only powers the VM off. It still holds its host — and you still pay for compute. Use az vm deallocate instead." |
| 05:15 | Recap slide: three bullets | "Three things to remember: a VM is a bundle of resources; the NSG decides what gets in, and new networks need explicit outbound; only deallocation stops the compute bill. Now do Lab 06 — and delete the resource group when you're done." |

## After recording

- Add captions (auto-generate, then correct Azure terms by hand: *NSG*, *deallocated*, *B2ats_v2*, *Trusted Launch*).
- Add the chapter list to the description.
- Paste the video link into the lunch README (section 🎬 Demo).
- Delete the demo resources: `az group delete --name rg-video06 --yes --no-wait`.
