# Makan Siang 06 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sebenarnya untuk makan siang ini — membuat VM Linux di portal, terhubung ke VM
> itu dari Cloud Shell, membuka port 80, dan melihat perbedaan antara *Stopped* dan *Stopped (deallocated)* — bagian-bagian
> yang tidak bisa ditunjukkan oleh animasi.
> **Target durasi:** sekitar 5 menit 30 detik (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, dan alamat IP publik yang masih akan Anda pakai.

## Sebelum menekan tombol rekam

- Resource group di Southeast Asia, dibuat di Cloud Shell:
  `az group create --name rg-video06 --location southeastasia --tags course=azure-fundamentals-lunches lunch=06`
- Sepasang SSH key di Cloud Shell: `ls ~/.ssh/id_rsa.pub || ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""`. Salin
  output `cat ~/.ssh/id_rsa.pub` ke text editor **di luar layar rekaman** supaya Anda bisa menempelkannya ke portal.
- Folder lab yang berisi halaman contoh dari repositori sudah terbuka di Cloud Shell: `cd ~/azure-fundamentals-lunches/labs/06-virtual-machines-basic`.
- Tab browser: portal Azure di halaman **Home**, dan panel Cloud Shell (Bash) di portal yang siap dibuka.
- Deployment memakan waktu satu sampai tiga menit. Rencanakan jump cut (potongan lompat) di 02:40 daripada merekam waktu tunggunya.
- Public IP VM akan terlihat di layar. Alamat itu dilepas saat Anda menghapus resource group, tetapi kaburkan saat penyuntingan
  jika Anda menyimpan VM lebih lama.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita bangun
00:20 Basics: image, size, dan SSH key
01:20 Disk dan jaringan: resource yang tidak terlihat
02:15 Review + create, dan apa yang sebenarnya dibuat
02:50 SSH dari Cloud Shell dan pasang nginx
03:50 Buka port 80 dan muat halamannya
04:25 Stopped, deallocated, dan auto-shutdown
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 06 · VM pertama Anda di Azure" | "Dalam lima menit ke depan, kita akan menyewa server pertama Nusantara Retail di Azure, terhubung ke server itu, membawa tokonya online, dan melihat kapan server itu berhenti memakan biaya." |
| 00:20 | Portal › Virtual machines › Create › Azure virtual machine › **Basics** | "Resource group rg-video06, nama vm-web-1, region Southeast Asia. Untuk satu server uji, saya memilih tanpa infrastructure redundancy — kita akan membereskannya di makan siang berikutnya." |
| 00:45 | Security type *Trusted launch*; Image *Ubuntu Server 24.04 LTS – x64 Gen2* | "Trusted Launch sudah terpilih: Secure Boot dan virtual TPM, tanpa biaya tambahan. Image-nya Ubuntu 24.04, sama seperti toko online saat ini." |
| 01:00 | Size › *See all sizes* › cari `B2ats` | "Size dikelompokkan dalam keluarga. B artinya burstable: baseline rendah dengan credit untuk lonjakan singkat. Standard_B2ats_v2 punya dua vCPU dan memori satu gigabyte — cukup untuk nginx." |
| 01:10 | Authentication *SSH public key*, source *Use existing public key*, tempel kuncinya; inbound ports *SSH (22)* | "Tanpa kata sandi. Saya menempelkan bagian publik dari kunci Cloud Shell saya; bagian privatnya tidak pernah meninggalkan Cloud Shell. Portal akan membuka port 22 — boleh untuk demo ini, tidak untuk production." |
| 01:20 | Tab **Disks**: OS disk type *Standard SSD*; tunjuk *Delete with VM* | "OS disk adalah resource managed disk tersendiri. Standard SSD membuat demo tetap murah; production akan memakai Premium SSD. Perhatikan *Delete with VM* — sisa-sisa resource tetap memakan biaya." |
| 01:40 | Tab **Networking**: virtual network baru, ubah address space menjadi 10.20.0.0/16 dan subnet snet-web 10.20.1.0/24; public IP (new); NIC network security group *Basic* | "Inilah resource yang jarang disebut orang: virtual network dan subnet — saya memilih 10.20, bukan rentang 10.0 milik kantor pusat — sebuah Standard public IP, dan network security group pada kartu jaringan." |
| 02:00 | Tab **Management**: *Enable auto-shutdown* aktif, 19:00, time zone *(UTC+07:00) Bangkok, Hanoi, Jakarta* | "Auto-shutdown melakukan deallocate pada VM setiap malam. Bagus untuk mesin uji — jangan pernah untuk toko production." |
| 02:15 | **Review + create** › *Create*; lalu (setelah potongan) daftar *Resource* milik deployment | "Validasi lolos, dan deployment dimulai. *(potong)* Selesai. Lihat daftarnya: VM, disk, network interface, NSG, public IP, virtual network — satu klik, enam resource." |
| 02:50 | VM overview: salin public IP; buka Cloud Shell (Bash): `ssh azureuser@<IP>` | "Saya terhubung dari Cloud Shell. Pada kali pertama, SSH meminta saya memercayai host key server ini." |
| 03:10 | Di dalam VM: `sudo apt-get update && sudo apt-get install -y nginx` | "nginx diambil dari mirror Ubuntu. Itu berhasil karena VM punya public IP sendiri — jalur outbound yang eksplisit. Virtual network baru tidak memberi VM akses internet secara default." |
| 03:35 | Di Cloud Shell (keluar dari SSH dulu): `scp app/index.html azureuser@<IP>:index.html` dan `ssh azureuser@<IP> 'sudo cp ~/index.html /var/www/html/'`; browser ke `http://<IP>` terus berputar | "Halamannya sudah ada di server — tetapi browser hanya berputar. Ada sesuatu di depan VM yang membuang port 80." |
| 03:50 | VM › Networking › Network settings › *Create port rule* › Inbound › service HTTP, priority 900 › Add; muat ulang browser | "NSG tadi hanya mengizinkan SSH. Satu aturan inbound untuk HTTP dengan priority 900, tunggu beberapa detik, dan Nusantara Retail pun online." |
| 04:25 | VM overview › **Stop**; status berubah menjadi *Stopped (deallocated)* | "Tombol Stop di portal melakukan deallocate: VM melepaskan host-nya, dan meteran compute berhenti. Disk dan public IP tetap ada — dan tetap ditagih." |
| 04:50 | Cloud Shell: `az vm start -g rg-video06 -n vm-web-1` lalu `az vm stop -g rg-video06 -n vm-web-1`; lalu `az vm show -d -g rg-video06 -n vm-web-1 --query powerState` → `VM stopped` | "Hati-hati: perintah stop di CLI, atau shutdown dari dalam Ubuntu, hanya mematikan VM. VM itu masih menempati host-nya — dan Anda tetap membayar compute. Gunakan az vm deallocate sebagai gantinya." |
| 05:15 | Slide rangkuman: tiga poin | "Tiga hal untuk diingat: VM adalah sekumpulan resource; NSG menentukan apa yang boleh masuk, dan jaringan baru membutuhkan outbound yang eksplisit; hanya deallocation yang menghentikan tagihan compute. Sekarang kerjakan Lab 06 — dan hapus resource group-nya setelah selesai." |

## Setelah merekam
- Tambahkan caption (subtitle): buat otomatis, lalu koreksi istilah Azure secara manual (*NSG*, *deallocated*, *B2ats_v2*, *Trusted Launch*).
- Tambahkan daftar chapter ke deskripsi video.
- Tempel link video ke README makan siang (bagian 🎬 Demo).
- Hapus resource demo: `az group delete --name rg-video06 --yes --no-wait`.
