# Lab praktik

🇬🇧 [Read in English](README.md)

Setiap makan siang punya **lab mandiri** yang bisa Anda kerjakan di waktu luang, sesuai kecepatan Anda sendiri. Baca
dulu makan siang pasangannya; lalu bangun, rusak, perbaiki, dan verifikasi semuanya di subscription Azure milik Anda
sendiri.

## Cara kerja lab

- **Berdiri sendiri.** Tidak ada lab yang membutuhkan lab lain. Jika sebuah lab butuh titik awal (misalnya dua web
  server untuk lab penyeimbangan beban), `setup.sh` milik lab itulah yang membuatnya.
- **Azure Cloud Shell (Bash)** sudah cukup: buka [shell.azure.com](https://shell.azure.com), pilih Bash, lalu:

  ```bash
  git clone https://github.com/stefpin/azure-fundamentals-lunches.git   # first time only
  cd azure-fundamentals-lunches
  bash labs/common/check-environment.sh                                               # checks region, VM sizes, quota
  ```

- **Dua mode.** *Terpandu* menuntun Anda melewati setiap tugas, lengkap dengan titik pemeriksaan. *Tantangan* hanya
  memberi Anda daftar persyaratannya.
- **Skrip di setiap folder lab:**

  | Skrip | Fungsinya |
  |---|---|
  | `setup.sh` | membuat titik awal (hanya di lab yang membutuhkannya) |
  | `solution.sh` | solusi acuan (di lab yang tugas-tugasnya bisa dijalankan lewat skrip) |
  | `verify.sh` | memeriksa hasil kerja Anda dan mencetak PASS atau FAIL untuk setiap persyaratan |
  | `cleanup.sh` | menghapus semua yang dibuat oleh lab |

- **Pengaturan bersama** tersimpan di [`common/config.sh`](common/config.sh): region (`LOCATION`, default
  `southeastasia`), region kedua untuk lab multi-region (`SECONDARY_LOCATION`, default `eastasia`), ukuran VM yang
  kecil, dan sufiks acak yang menjaga nama-nama yang wajib unik secara global tetap unik. Ganti nilainya sebelum mulai,
  misalnya:

  ```bash
  export LOCATION=indonesiacentral        # Jakarta — check that each lab's services are offered there
  source labs/common/config.sh
  ```

## Kelompok biaya

| Kelompok | Arti | Yang perlu dilakukan |
|---|---|---|
| 💲 | gratis atau hampir gratis (memakai tier gratis atau resource yang sangat kecil) | tetap bersihkan — kebiasaan yang baik |
| 💲💲 | biaya kecil selama resource berjalan, biasanya beberapa sen per jam | selesaikan lab dalam sekali duduk, lalu jalankan `cleanup.sh` |
| 💲💲💲 | biaya yang terasa selama berjalan, atau gateway yang butuh waktu lama untuk dibuat | rencanakan lab-nya, lalu langsung hapus setelah selesai |

Harga berbeda-beda di setiap region dan berubah dari waktu ke waktu, jadi lab-lab ini tidak mencantumkannya. Gunakan
[kalkulator harga Azure](https://azure.microsoft.com/pricing/calculator/) jika Anda butuh angka, dan pasang anggaran
(budget) dari Lab 01 sebelum melakukan apa pun.

> [!WARNING]
> Jangan pernah menjalankan lab di subscription kantor atau produksi. Beberapa lab membuat user, role assignment,
> policy, atau management group, yang memengaruhi semua hal di dalam cakupan (scope) tersebut.

## Semua lab

<!-- LAB-TABLE:START -->
| Lab | Pasangan dari | Waktu | Biaya |
|---|---|---|---|
| [Lab 01 · Menyiapkan lingkungan lab](01-before-you-begin/README.id.md) | [Makan Siang 01 · Sebelum Memulai: Lab Azure, Perkakas, dan Pagar Pengaman Biaya Anda (Dasar)](../lunches/01-before-you-begin/README.id.md) | sekitar 30 menit | 💲 |
| [Lab 02 · Menyusun justifikasi bisnis](02-cloud-concepts/README.id.md) | [Makan Siang 02 · Konsep Cloud (Dasar)](../lunches/02-cloud-concepts/README.id.md) | sekitar 40 menit | 💲 |
| [Lab 03 · Menjelajahi region dan zona](03-global-infrastructure/README.id.md) | [Makan Siang 03 · Infrastruktur Global Azure: Region, Availability Zone, dan Region Pair (Dasar)](../lunches/03-global-infrastructure/README.id.md) | sekitar 35 menit | 💲 |
| [Lab 04 · Menata Nusantara Retail](04-resource-hierarchy-basic/README.id.md) | [Makan Siang 04 · Hierarki Resource dan Azure Resource Manager (Dasar)](../lunches/04-resource-hierarchy-basic/README.id.md) | sekitar 40 menit | 💲 |
| [Lab 05 · Beri kontraktor akses secukupnya](05-identity-access-basic/README.id.md) | [Makan Siang 05 · Identitas dan Akses (Dasar)](../lunches/05-identity-access-basic/README.id.md) | sekitar 40 menit | 💲 |
| [Lab 06 · VM web server pertama Anda](06-virtual-machines-basic/README.id.md) | [Makan Siang 06 · Virtual Machines (Dasar)](../lunches/06-virtual-machines-basic/README.id.md) | sekitar 45 menit | 💲💲 |
| [Lab 07 · Menyimpan gambar produk dan faktur](07-storage-basic/README.id.md) | [Makan Siang 07 · Penyimpanan (Dasar)](../lunches/07-storage-basic/README.id.md) | sekitar 45 menit | 💲 |
| [Lab 08 · Membangun jaringan Nusantara Retail](08-networking-basic/README.id.md) | [Makan Siang 08 · Virtual Networking (Dasar)](../lunches/08-networking-basic/README.id.md) | sekitar 50 menit | 💲💲 |
| [Lab 09 · Menjaga toko tetap buka saat server gagal](09-load-balancing-basic/README.id.md) | [Makan Siang 09 · Load Balancing (Dasar): Azure Load Balancer](../lunches/09-load-balancing-basic/README.id.md) | sekitar 50 menit | 💲💲 |
| [Lab 10 · Memindahkan toko online ke PaaS](10-app-service/README.id.md) | [Makan Siang 10 · Aplikasi Web dengan Azure App Service](../lunches/10-app-service/README.id.md) | sekitar 45 menit | 💲 |
| [Lab 11 · Database pesanan Nusantara Retail](11-relational-databases-basic/README.id.md) | [Makan Siang 11 · Database Relasional (Dasar): Azure SQL](../lunches/11-relational-databases-basic/README.id.md) | sekitar 45 menit | 💲 |
| [Lab 12 · Katalog produk yang siap tumbuh](12-cosmos-db/README.id.md) | [Makan Siang 12 · NoSQL dengan Azure Cosmos DB (Dasar)](../lunches/12-cosmos-db/README.id.md) | sekitar 45 menit | 💲 |
| [Lab 13 · Mengemas toko online](13-containers-basic/README.id.md) | [Makan Siang 13 · Containers (Dasar): Container Registry, Container Instances, dan Container Apps](../lunches/13-containers-basic/README.id.md) | sekitar 45 menit | 💲 |
| [Lab 14 · Menanggapi pesanan baru secara otomatis](14-serverless/README.id.md) | [Makan Siang 14 · Serverless: Azure Functions, Logic Apps, dan Event Grid](../lunches/14-serverless/README.id.md) | sekitar 50 menit | 💲 |
| [Lab 15 · Keluarkan kata sandi dari file konfigurasi](15-security-essentials/README.id.md) | [Makan Siang 15 · Esensi Keamanan: Defense in Depth, Key Vault, dan Defender for Cloud (Dasar)](../lunches/15-security-essentials/README.id.md) | sekitar 45 menit | 💲💲 |
| [Lab 16 · Tahu lebih dulu daripada pelanggan](16-monitoring-basic/README.id.md) | [Makan Siang 16 · Pemantauan (Dasar): Azure Monitor, Alert, Service Health, dan Advisor](../lunches/16-monitoring-basic/README.id.md) | sekitar 45 menit | 💲💲 |
| [Lab 17 · Latihan pemulihan data](17-backup-disaster-recovery/README.id.md) | [Makan Siang 17 · Pencadangan Data dan Pemulihan Bencana (Dasar)](../lunches/17-backup-disaster-recovery/README.id.md) | 60–90 menit | 💲💲 |
| [Lab 18 · Menjaga data tetap di tempat yang benar](18-governance-compliance-basic/README.id.md) | [Makan Siang 18 · Tata Kelola dan Kepatuhan (Dasar): Azure Policy, Lock, Tag, dan Microsoft Purview](../lunches/18-governance-compliance-basic/README.id.md) | sekitar 45 menit | 💲 |
| [Lab 19 · Temukan pemborosan buatan Anda sendiri](19-cost-management/README.id.md) | [Makan Siang 19 · Manajemen Biaya (Dasar)](../lunches/19-cost-management/README.id.md) | sekitar 40 menit | 💲 |
| [Lab 20 · Sembilan belas makan siang penuh klik dalam satu file](20-infrastructure-as-code-bicep/README.id.md) | [Makan Siang 20 · Infrastructure as Code dengan Bicep (Dasar)](../lunches/20-infrastructure-as-code-bicep/README.id.md) | sekitar 50 menit | 💲 |
| [Lab 21 · Proyek capstone](21-core-capstone/README.id.md) | [Makan Siang 21 · Capstone Inti: Menyatukan Semuanya (Dasar)](../lunches/21-core-capstone/README.id.md) | sekitar 2–3 jam | 💲💲 |
| [Lab 22 · Pipeline tanpa kata sandi dan hak akses minimum](22-identity-access-advanced/README.id.md) | [Makan Siang 22 · Identitas dan Akses (Lanjutan)](../lunches/22-identity-access-advanced/README.id.md) | sekitar 50 menit | 💲 |
| [Lab 23 · Siap menghadapi promo 12.12](23-virtual-machines-advanced/README.id.md) | [Makan Siang 23 · Virtual Machines (Lanjutan)](../lunches/23-virtual-machines-advanced/README.id.md) | sekitar 60 menit | 💲💲 |
| [Lab 24 · Faktur tahan ransomware](24-storage-advanced/README.id.md) | [Makan Siang 24 · Penyimpanan (Lanjutan)](../lunches/24-storage-advanced/README.id.md) | sekitar 60 menit | 💲💲 |
| [Lab 25 · Hub-and-spoke untuk Nusantara Retail](25-networking-advanced/README.id.md) | [Makan Siang 25 · Virtual Networking (Lanjutan)](../lunches/25-networking-advanced/README.id.md) | sekitar 60 menit | 💲💲 |
| [Lab 26 · Menghubungkan kantor pusat](26-hybrid-connectivity/README.id.md) | [Makan Siang 26 · Hybrid Connectivity: VPN Gateway, ExpressRoute, dan Virtual WAN (Lanjutan)](../lunches/26-hybrid-connectivity/README.id.md) | sekitar 90 menit | 💲💲💲 |
| [Lab 27 · Melindungi dan merutekan toko online](27-load-balancing-advanced/README.id.md) | [Makan Siang 27 · Load Balancing (Lanjutan): Application Gateway, Front Door, dan Traffic Manager](../lunches/27-load-balancing-advanced/README.id.md) | sekitar 75 menit | 💲💲💲 |
| [Lab 28 · Pesanan yang selamat dari gangguan region](28-relational-databases-advanced/README.id.md) | [Makan Siang 28 · Database Relasional (Lanjutan)](../lunches/28-relational-databases-advanced/README.id.md) | sekitar 60 menit | 💲💲 |
| [Lab 29 · Kubernetes untuk tim microservices](29-containers-advanced-aks/README.id.md) | [Makan Siang 29 · Containers (Lanjutan): Azure Kubernetes Service](../lunches/29-containers-advanced-aks/README.id.md) | sekitar 60 menit | 💲💲💲 |
| [Lab 30 · Mengapa checkout lambat pada hari Jumat?](30-monitoring-advanced/README.id.md) | [Makan Siang 30 · Pemantauan (Lanjutan): Log Analytics, KQL, dan Application Insights](../lunches/30-monitoring-advanced/README.id.md) | sekitar 60 menit | 💲💲 |
| [Lab 31 · Tata kelola untuk seluruh perusahaan](31-governance-at-scale/README.id.md) | [Makan Siang 31 · Hierarki Resource dan Tata Kelola (Lanjutan): Tata Kelola Skala Besar](../lunches/31-governance-at-scale/README.id.md) | sekitar 60 menit | 💲 |
| [Tantangan capstone lanjutan](32-advanced-capstone-challenge/README.id.md) | Makan Siang 22–31 | proyek beberapa sesi | 💲💲💲 |
<!-- LAB-TABLE:END -->

## Jika terjadi masalah

1. Baca pesan error-nya — sebagian besar kegagalan disebabkan oleh region yang tidak menyediakan suatu ukuran VM, batas
   kuota, atau nama yang sudah dipakai pihak lain. `bash labs/common/check-environment.sh` memeriksa dua penyebab
   pertama.
2. Periksa tabel **Pemecahan masalah** di lab tersebut.
3. Masih buntu? [Laporkan masalah lab](../CONTRIBUTING.md) dengan menyertakan nomor lab, perintah yang dijalankan, dan
   pesan error lengkapnya.

---

🏠 [Beranda kursus](../README.id.md)
