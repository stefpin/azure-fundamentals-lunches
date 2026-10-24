# Silabus — Dasar-Dasar Azure: Satu Makan Siang, Satu Pelajaran

🇬🇧 [Read in English](SYLLABUS.md)

Ini adalah rincian setiap makan siang: apa yang dibahas di bacaan, apa yang ditunjukkan demo interaktif, dan apa yang
dibangun di lab mandiri. Kursus ini terdiri atas **31 makan siang** yang dibagi ke dalam dua "bulan":

- **Bulan inti (Makan Siang 01–21, Dasar):** setiap layanan dasar Azure, pada tingkat yang Anda perlukan untuk
  menjelaskan, memilih, dan memakainya. Kira-kira empat minggu makan siang di hari kerja. Selaras dengan kerangka
  keterampilan AZ-900 (keterampilan yang diukur per 20 Juli 2026).
- **Bulan pendalaman (Makan Siang 22–31, Lanjutan):** separuh lanjutan dari setiap topik yang terlalu besar untuk satu
  jam. Kira-kira dua minggu makan siang di hari kerja. Lebih condong ke pekerjaan sehari-hari administrator dan arsitek
  (wilayah AZ-104).
- **Tantangan capstone lanjutan (hanya lab):** proyek yang hanya berisi persyaratan dan menyatukan semua materi
  pendalaman.

Topik yang tidak muat dalam satu jam dipecah menjadi makan siang **Dasar** (bulan inti) dan makan siang **Lanjutan**
(bulan pendalaman):

| Topik | Dasar (bulan inti) | Lanjutan (bulan pendalaman) |
|---|---|---|
| Hierarki resource & tata kelola | 04 Hierarki resource & ARM · 18 Tata kelola & kepatuhan | 31 Tata kelola skala besar |
| Identitas & akses | 05 Identitas & akses (Dasar) | 22 Identitas & akses (Lanjutan) |
| Virtual machine | 06 Virtual machine (Dasar) | 23 Virtual machine (Lanjutan) |
| Penyimpanan | 07 Penyimpanan (Dasar) | 24 Penyimpanan (Lanjutan) |
| Jaringan | 08 Jaringan virtual (Dasar) | 25 Jaringan virtual (Lanjutan) · 26 Konektivitas hibrid |
| Penyeimbangan beban | 09 Penyeimbangan beban (Dasar) | 27 Penyeimbangan beban (Lanjutan) |
| Database relasional | 11 Database relasional (Dasar) | 28 Database relasional (Lanjutan) |
| Kontainer | 13 Kontainer (Dasar) | 29 Kontainer (Lanjutan): AKS |
| Pemantauan | 16 Pemantauan (Dasar) | 30 Pemantauan (Lanjutan) |

Topik yang cukup satu makan siang: konsep cloud, infrastruktur global, App Service, Cosmos DB, serverless, esensi
keamanan, pencadangan & pemulihan bencana (DR), manajemen biaya, infrastructure as code (*infrastruktur sebagai kode*),
dan capstone inti.

**Skenario sepanjang kursus.** Anda adalah cloud engineer baru di **Nusantara Retail** (PT Nusantara Retail), peritel
menengah dengan empat puluh toko dan satu situs e-commerce yang masih berjalan di satu server fisik, di sebuah ruang kecil
di sebelah pantry. Trafiknya sudah naik tiga kali lipat; servernya tidak. Di rapat bulanan terakhir, direktur bertanya:
*"Kalau server itu mati, berapa lama kita tidak bisa jualan?"* Tidak ada yang menjawab. Setiap makan siang membawa
Nusantara Retail selangkah lebih dekat ke jawabannya.

**Kelompok biaya yang dipakai di lab:** 💲 gratis atau hampir gratis · 💲💲 biaya kecil selama resource berjalan
(biasanya beberapa sen per jam) · 💲💲💲 biaya yang terasa selama berjalan, atau gateway yang lama dibuat — hapus segera
setelah lab selesai.

---

## Bulan inti — Bagian 1 · Fondasi

### Makan Siang 01 · Sebelum Memulai: Lab Azure, Perkakas, dan Pagar Pengaman Biaya Anda (Dasar)
- **Bacaan:** cara kerja kursus (anatomi satu makan siang, dua bulan, lab mandiri); berkenalan dengan Nusantara Retail;
  mendapatkan subscription Azure (*langganan*): akun gratis, Azure for Students, atau pay-as-you-go, batas pengeluaran
  (spending limit), serta aturan untuk memakai subscription pribadi atau khusus lab — jangan pernah subscription
  produksi atau kantor; tiga pintu masuk — Azure portal, Azure Cloud Shell (Bash/PowerShell), Azure CLI dan Azure
  PowerShell di PC Anda (plus VS Code); apa yang terjadi saat Anda mengeklik "Create" (permintaan melewati Azure
  Resource Manager menuju resource provider); konvensi lab: satu region (*wilayah*), satu resource group (*grup sumber
  daya*) per lab, penamaan, tag, dan sufiks acak; pagar pengaman biaya: anggaran (budget) dan alert (*pemberitahuan*),
  auto-shutdown, kelompok biaya, dan kebiasaan membersihkan resource; keamanan akun (MFA, *autentikasi multifaktor*).
- **Demo (animasi):** "Dari klik ke resource" — permintaan dari portal, CLI, dan PowerShell semuanya mengalir lewat
  Azure Resource Manager ke resource provider; indikator anggaran terisi hingga 50/80/100% dan mengirim alert; menghapus
  resource group akan menghapus semua isinya.
- **Ide video:** tur portal, membuka Cloud Shell, meng-clone repo, membuat budget.
- **Lab 01 · Menyiapkan lingkungan lab (≈30 menit, 💲):** buka Cloud Shell (Bash), clone repo, jalankan
  `check-environment.sh`; buat budget bulanan dengan alert 50/80/100% di Cost Management (portal); buat resource group
  bertag dengan CLI, lihat di portal, lalu hapus; perangkat lokal opsional. *Rusak lalu perbaiki:* pakai nama region
  yang salah ketik dan baca pesan error-nya. Verifikasi: sudah sign in, subscription aktif (enabled), budget ada, tidak
  ada grup lunch-01 yang tersisa.

### Makan Siang 02 · Konsep Cloud (Dasar)
- **Bacaan:** apa itu cloud computing (*komputasi awan*); model tanggung jawab bersama (on-premises vs IaaS vs PaaS vs
  SaaS); cloud publik, privat, hibrid, dan multicloud; belanja modal (CapEx) vs belanja operasional (OpEx) serta
  consumption-based model (*model berbasis penggunaan*); manfaat cloud — ketersediaan tinggi, skalabilitas
  (vertikal/horizontal), elastisitas, keandalan, prediktabilitas, keamanan, tata kelola, kemudahan pengelolaan; IaaS,
  PaaS, dan SaaS (*infrastruktur, platform, dan perangkat lunak sebagai layanan*) — plus serverless — beserta contoh
  penggunaannya; semuanya diterapkan pada masalah server tunggal Nusantara Retail.
- **Demo (animasi):** "penggeser" tanggung jawab bersama (on-prem → IaaS → PaaS → SaaS menunjukkan siapa yang memegang
  setiap lapisan), lalu kapasitas on-prem yang tetap vs kapasitas cloud yang elastis saat trafik melonjak (kapasitas
  terbuang vs gangguan vs ukuran yang pas).
- **Ide video:** memakai Azure pricing calculator (*kalkulator harga*) untuk membandingkan desain berbasis VM dan desain
  berbasis PaaS.
- **Lab 02 · Menyusun justifikasi bisnis (≈40 menit, 💲, tanpa membuat resource):** estimasi pricing calculator untuk dua
  desain; lembar kerja klasifikasi (IaaS/PaaS/SaaS, CapEx/OpEx, siapa yang bertanggung jawab) dengan jawaban di blok
  yang bisa dibuka-tutup; rekomendasi satu halaman untuk direktur. Opsional: tampilkan daftar region Azure dan resource
  provider dengan CLI.

### Makan Siang 03 · Infrastruktur Global Azure: Region, Availability Zone, dan Region Pair (Dasar)
- **Bacaan:** pusat data (datacenter), region, geografi; availability zone (*zona ketersediaan*) dengan daya listrik,
  pendinginan, dan jaringan yang terpisah, serta layanan zonal vs zone-redundant vs regional; region pair (*pasangan
  wilayah*) — apa yang Anda dapat dan tidak dapat darinya (tidak ada replikasi otomatis) — dan region baru tanpa
  pasangan (misalnya Indonesia Central); sovereign cloud (*wilayah berdaulat*); cara memilih region (residensi data dan
  kepatuhan, latensi, ketersediaan layanan dan SKU, harga, zona, opsi pemulihan bencana (disaster recovery, DR)).
- **Demo (animasi):** zoom dari bola dunia ke sebuah geografi, sebuah region, tiga zonanya, dan pusat-pusat datanya;
  kegagalan satu zona melumpuhkan resource zonal, sementara resource zone-redundant tetap hidup; pilihan DR dengan
  region berpasangan vs tanpa pasangan.
- **Ide video:** peta region, memeriksa ketersediaan layanan per region, opsi zona saat membuat resource.
- **Lab 03 · Menjelajahi region dan zona (≈35 menit, 💲):** kueri CLI untuk region, pasangan region, dan ukuran VM yang
  mendukung zona; buat Standard public IP yang zone-redundant dan yang zonal, lalu bandingkan; buat storage account
  (*akun penyimpanan*) LRS vs ZRS dan bandingkan properti keduanya; uji latensi opsional dari browser Anda. Verifikasi:
  dua public IP dengan pengaturan zona yang diharapkan, satu account ZRS.

### Makan Siang 04 · Hierarki Resource dan Azure Resource Manager (Dasar)
- **Bacaan:** tenant (Microsoft Entra ID, *ID Microsoft Entra*) → root management group → management group (*grup
  manajemen*) → subscription → resource group → resource (*sumber daya*); Azure Resource Manager (ARM) sebagai
  satu-satunya control plane; control plane vs data plane; resource provider dan resource type; anatomi sebuah resource
  ID; scope dan pewarisan (RBAC atau *kontrol akses berbasis peran*, Policy, budget, lock); subscription sebagai batas
  penagihan dan batas skala; aturan resource group (siklus hidup, lokasi, memindahkan resource); konvensi penamaan
  (singkatan dari Cloud Adoption Framework); tag (tidak diwariskan secara default); lock (*kunci sumber daya*) —
  CanNotDelete, ReadOnly, dan kejutan-kejutannya; Azure Resource Graph. Desain tingkat lanjut dibahas di Makan Siang 31.
- **Demo (animasi):** membangun hierarki tingkat demi tingkat; menunjukkan pewarisan yang mengalir ke bawah (role di
  management group, policy di subscription, lock di resource group); membedah sebuah resource ID.
- **Ide video:** menjelajahi management group/subscription/resource group di portal, tag, lock.
- **Lab 04 · Menata Nusantara Retail (≈40 menit, 💲):** dua resource group bertag; sebuah storage account; baca resource
  ID-nya; lock CanNotDelete memblokir penghapusan; lock ReadOnly memblokir pengambilan daftar key (sebuah aksi POST);
  pindahkan resource antar-grup; kueri Resource Graph berdasarkan tag; management group opsional. *Rusak lalu perbaiki:*
  lock-nya. Verifikasi: tag, resource yang sudah dipindahkan, tidak ada lock yang tertinggal.

### Makan Siang 05 · Identitas dan Akses (Dasar)
- **Bacaan:** autentikasi vs otorisasi; Microsoft Entra ID (tenant, user, grup, guest, sekilas tentang app
  registration), Entra ID vs AD DS on-premises (Entra Connect, Entra Domain Services); MFA, passwordless (*tanpa kata
  sandi*) — Windows Hello, security key FIDO2 dan passkey, Microsoft Authenticator — serta SSO (*sistem masuk tunggal*);
  Conditional Access (*Akses Bersyarat*): sinyal → keputusan → penegakan; identitas eksternal; Azure RBAC — security
  principal, role definition, scope, role assignment; built-in role (Owner, Contributor, Reader, User Access
  Administrator, Role Based Access Control Administrator); izin yang bersifat aditif dan deny assignment; role Entra vs
  role Azure; prinsip hak akses minimum (least privilege); perkenalan pertama dengan Zero Trust.
- **Demo (animasi):** "Bisakah Dewi me-restart VM?" — autentikasi, lalu role assignment dikumpulkan dari setiap scope,
  izin digabungkan, hasilnya diizinkan atau ditolak; kemudian keputusan sign-in oleh Conditional Access.
- **Ide video:** membuat user dan grup, memberikan role di scope resource group, "Check access".
- **Lab 05 · Beri kontraktor akses secukupnya (≈40 menit, 💲):** di tenant Entra **milik Anda sendiri** (bukan tenant
  kantor): buat user dan grup uji; berikan role Reader lalu Contributor di scope resource group; sign in sebagai user
  uji di jendela browser privat dan lihat perbedaannya; tampilkan daftar assignment yang berlaku dengan CLI. *Rusak lalu
  perbaiki:* role di scope yang salah. Verifikasi: user, keanggotaan grup, role yang diharapkan di scope yang
  diharapkan. Pembersihan menghapus user, grup, dan assignment.

## Bulan inti — Bagian 2 · Infrastruktur inti

### Makan Siang 06 · Virtual Machines (Dasar)
- **Bacaan:** kapan virtual machine (*komputer virtual*) IaaS menjadi alat yang tepat; komponen penyusunnya — image,
  ukuran (keluarga seri, B-series yang burstable), OS disk, temporary disk, data disk, jenis managed disk (Standard HDD,
  Standard SSD, Premium SSD, Premium SSD v2, Ultra Disk), NIC, virtual network (*jaringan virtual*) dan subnet, Standard
  public IP, NSG; autentikasi (SSH key, kata sandi, login dengan Entra ID); cara terhubung (SSH, RDP, Azure Bastion, Run
  Command, serial console); status VM dan penagihannya (running, stopped, deallocated); mengubah ukuran (resize);
  auto-shutdown; sekilas tentang cloud-init dan extension; opsi harga (pay-as-you-go, reservation, savings plan, Spot,
  Azure Hybrid Benefit); akses outbound eksplisit untuk virtual network baru.
- **Demo (animasi):** "Apa yang sebenarnya dibuat saat Anda membuat VM" — resource muncul satu per satu; paket SSH lolos
  dari NSG sementara HTTP diblokir sampai port 80 dibuka; deallocate menghentikan meteran biaya compute, tetapi tidak
  menghentikan meteran biaya disk.
- **Ide video:** membuat VM Linux di portal dan terhubung dari Cloud Shell.
- **Lab 06 · VM web server pertama Anda (≈45 menit, 💲💲):** VM Ubuntu dengan CLI (jalur lewat portal juga ditunjukkan);
  masuk lewat SSH, pasang nginx, terbitkan halaman Nusantara Retail; buka port 80; tambahkan dan mount sebuah data disk;
  ubah ukuran VM; atur auto-shutdown; bandingkan stopped vs deallocated. *Rusak lalu perbaiki:* hapus rule port 80.
  Verifikasi: VM, rule, data disk, jadwal, HTTP 200.

### Makan Siang 07 · Penyimpanan (Dasar)
- **Bacaan:** storage account beserta jenis, tingkat performa, endpoint, dan penamaannya; redundansi (*opsi redundansi*)
  — LRS, ZRS, GRS, GZRS dan varian read-access-nya, serta kegagalan apa saja yang bisa dilalui masing-masing; layanan —
  Blob (container; block blob, append blob, dan page blob), Azure Files (SMB/NFS, Azure File Sync), Queue, Table; access
  tier blob (*tingkatan penyimpanan*): hot, cool, cold, archive, periode penghapusan dini, dan rehidrasi; mengamankan
  akses — Microsoft Entra ID + data role RBAC, shared key, SAS (utamakan user-delegation SAS), akses anonim dimatikan;
  perangkat dan pemindahan data — Storage browser, Azure Storage Explorer, AzCopy, Azure File Sync, Data Box.
- **Demo (animasi):** pemilih redundansi — salinan data di berbagai disk, zona, dan region saat terjadi kegagalan (disk,
  pusat data, zona, region); lalu jungkat-jungkit access tier (biaya penyimpanan vs biaya akses).
- **Ide video:** membuat account, mengunggah dengan Storage browser, mengganti tier, membuat SAS.
- **Lab 07 · Menyimpan gambar produk dan faktur (≈45 menit, 💲):** account StorageV2 yang aman (TLS 1.2, tanpa akses
  anonim); berikan data role untuk diri Anda sendiri; unggah ke container dengan CLI dan AzCopy; ganti tier;
  user-delegation SAS dengan masa berlaku; file share Azure Files. *Rusak lalu perbaiki:* SAS kedaluwarsa → 403.
  Verifikasi: pengaturan account, blob, satu blob Cool, file share.

### Makan Siang 08 · Virtual Networking (Dasar)
- **Bacaan:** virtual network dan address space (CIDR, rentang alamat privat, perencanaan agar tidak tumpang-tindih
  dengan jaringan on-premises); subnet (lima alamat yang dicadangkan); NIC; alamat IP privat dan publik (hanya SKU
  Standard); network security group (rule, prioritas, default rule, service tag, subnet vs NIC, effective rule) dan
  application security group; Azure DNS (zona publik, resolusi nama bawaan Azure); konektivitas outbound (subnet privat
  secara default di virtual network baru; NAT gateway, outbound rule load balancer, atau public IP); public endpoint vs
  private endpoint (*titik akhir publik / privat*) sebagai pengantar; Network Watcher (IP flow verify, connection
  troubleshoot, flow log).
- **Demo (animasi):** evaluator rule NSG — paket bertemu NSG di subnet dan di NIC, rule diperiksa menurut prioritas,
  rule pertama yang cocok yang menang; SSH dari internet, HTTP, VM-ke-VM, dan akses internet outbound dari subnet privat
  dengan dan tanpa NAT gateway.
- **Ide video:** membangun virtual network dengan subnet dan NSG; IP flow verify.
- **Lab 08 · Membangun jaringan Nusantara Retail (≈50 menit, 💲💲):** VNet 10.20.0.0/16 dengan subnet web dan app; NSG dan
  sebuah ASG; VM web (dengan public IP) dan VM app (hanya IP privat) di belakang NAT gateway; uji trafik; diagnosis
  dengan IP flow verify; zona DNS publik beserta record-nya. *Rusak lalu perbaiki:* rule deny dengan prioritas lebih
  tinggi. Verifikasi: VNet, subnet, NSG, ASG, NAT gateway, record DNS.

### Makan Siang 09 · Load Balancing (Dasar): Azure Load Balancer
- **Bacaan:** mengapa beban perlu diseimbangkan; layer 4 vs layer 7; Azure Load Balancer Standard (SKU Basic sudah
  dipensiunkan pada 30 September 2025); publik vs internal; frontend IP configuration, backend pool, health probe,
  load-balancing rule dan cara distribusinya (hash 5-tuple, session persistence), inbound NAT rule, outbound rule dan
  SNAT; frontend zone-redundant; HA ports; sekilas tentang gateway load balancer dan cross-region load balancer;
  perkenalan pertama dalam memilih antara Load Balancer, Application Gateway, Front Door, dan Traffic Manager
  (pendalamannya di Makan Siang 27).
- **Demo (animasi):** permintaan tersebar ke dua VM di dua zona; satu VM gagal health probe dan dikeluarkan dari rotasi;
  pemulihan; koneksi outbound lewat outbound rule.
- **Ide video:** membuat Standard load balancer di portal dan memantau kesehatan backend.
- **Lab 09 · Menjaga toko tetap buka saat server gagal (≈50 menit, 💲💲):** `setup.sh` membuat VNet dan dua VM web di zona
  1 dan 2 (tanpa public IP); Anda membuat Standard public load balancer dengan frontend zone-redundant, probe, rule,
  inbound NAT rule, dan outbound rule; saksikan trafik bergantian; hentikan satu web server dan saksikan failover.
  Verifikasi: SKU, probe, rule, dua backend yang sehat, HTTP 200 lewat frontend.

## Bulan inti — Bagian 3 · Layanan platform dan data

### Makan Siang 10 · Aplikasi Web dengan Azure App Service
- **Bacaan:** PaaS untuk aplikasi web dan API; App Service plan (OS, region, pricing tier, scale up vs scale out,
  autoscale); runtime stack dan kontainer; opsi deployment (`az webapp up`, zip deploy, GitHub Actions, deployment
  center); konfigurasi (app setting, connection string, referensi Key Vault); deployment slot dan swap; custom domain
  dan managed certificate; autentikasi bawaan; sekilas tentang access restriction, VNet integration, dan private
  endpoint; log stream dan Application Insights; App Service vs VM vs Container Apps vs Static Web Apps.
- **Demo (animasi):** permintaan melewati front end App Service menuju worker; scale out; slot staging melakukan warm-up
  lalu di-swap ke produksi tanpa downtime.
- **Ide video:** deployment dari CLI, app setting, log stream, swap slot.
- **Lab 10 · Memindahkan toko online ke PaaS (≈45 menit, 💲 / 💲💲 untuk tantangan tambahan slot):** deploy aplikasi web
  kecil yang disediakan dengan `az webapp up` di tier Free; app setting; HTTPS only; log stream; tantangan tambahan:
  plan Standard, slot staging, swap. *Rusak lalu perbaiki:* app setting yang rusak → halaman error. Verifikasi: aplikasi
  berjalan, setting ada, HTTP 200 dengan teks yang diharapkan.

### Makan Siang 11 · Database Relasional (Dasar): Azure SQL
- **Bacaan:** data relasional vs non-relasional; memilih database di Azure (keluarga Azure SQL, Azure Database for
  PostgreSQL/MySQL flexible server, Azure Cosmos DB); opsi deployment Azure SQL (SQL Database single dan elastic pool,
  SQL Managed Instance, SQL Server di Azure VM); logical server; model pembelian (DTU vs vCore), service tier (General
  Purpose, Business Critical, Hyperscale), auto-pause pada serverless, dan penawaran gratis (free offer); konektivitas
  (firewall rule server, private endpoint menyusul); autentikasi Microsoft Entra (Entra-only); sekilas tentang cadangan
  bawaan dan point-in-time restore; perangkat (Query editor, VS Code, sqlcmd).
- **Demo (animasi):** pohon keputusan interaktif "database yang mana?"; koneksi yang melewati gateway dan firewall;
  auto-pause dan resume pada serverless.
- **Ide video:** membuat database dengan autentikasi Entra-only dan menjalankan kueri di portal.
- **Lab 11 · Database pesanan Nusantara Retail (≈45 menit, 💲):** logical server dengan autentikasi Entra-only; database
  serverless atau free offer; firewall rule untuk klien Anda; buat dan kueri tabel Orders dengan sqlcmd dan Query
  editor. *Rusak lalu perbaiki:* koneksi diblokir firewall. Verifikasi: autentikasi Entra-only, database, firewall rule,
  baris data di tabel.

### Makan Siang 12 · NoSQL dengan Azure Cosmos DB (Dasar)
- **Bacaan:** model data NoSQL (dokumen, key-value, column-family, graf); API Cosmos DB; account → database → container
  → item; partisi dan cara memilih partition key (hindari hot partition); request unit, kapasitas provisioned
  (manual/autoscale) vs serverless, free tier; distribusi global, penulisan multi-region; lima tingkat konsistensi
  beserta untung-ruginya; pengindeksan otomatis; change feed; kapan memilih Cosmos DB vs Azure SQL.
- **Demo (animasi):** item mendarat di partisi logis menurut key-nya (partition key yang baik vs yang memicu hot
  partition); data yang ditulis di satu region lalu dibaca dari region lain dengan tingkat konsistensi yang
  berbeda-beda.
- **Ide video:** Data Explorer — buat container, tambahkan item, jalankan kueri, dan baca biaya RU-nya.
- **Lab 12 · Katalog produk yang siap tumbuh (≈45 menit, 💲):** Cosmos DB for NoSQL (serverless atau free tier);
  container yang dipartisi dengan `/category`; muat item contoh dengan skrip yang disediakan; point read vs kueri lintas
  partisi beserta biaya RU-nya; ubah default consistency. *Rusak lalu perbaiki:* kueri yang mahal, lalu tambahkan filter
  partition key. Verifikasi: account, API, container dan partition key, jumlah item.

### Makan Siang 13 · Containers (Dasar): Container Registry, Container Instances, dan Container Apps
- **Bacaan:** kontainer vs VM; image, registry, tag; Azure Container Registry (SKU, autentikasi, import dan build task);
  Azure Container Instances (kontainer tunggal yang cepat, penagihan per detik); Azure Container Apps (environment,
  revision, ingress, scale rule, scale to zero, sekilas tentang Dapr); kapan pindah ke AKS (Makan Siang 29); tabel
  perbandingan (ACI vs Container Apps vs AKS vs App Service untuk kontainer).
- **Demo (animasi):** build → push → run; Container Apps di-scale 0 → 1 → 5 → 0 replika mengikuti beban HTTP; pembagian
  trafik antar-revision 80/20.
- **Ide video:** membuat container app dari sebuah image dan menyaksikan jumlah replika berubah.
- **Lab 13 · Mengemas toko online (≈45 menit, 💲):** registry; import image contoh publik; jalankan di ACI; deploy ke
  Container Apps dengan external ingress dan scale rule (min 0); bangkitkan beban; revision baru dengan pembagian
  trafik. *Rusak lalu perbaiki:* target port yang salah. Verifikasi: image di registry, ACI berjalan, container app
  dengan ingress dan min replicas 0.

### Makan Siang 14 · Serverless: Azure Functions, Logic Apps, dan Event Grid
- **Bacaan:** arti serverless (digerakkan event, bayar per eksekusi, scale to zero); Azure Functions (trigger dan
  binding, bahasa pemrograman, hosting plan: Flex Consumption, Premium, Dedicated, Container Apps; cold start; Durable
  Functions); Logic Apps (Consumption vs Standard, connector, designer); event vs message — Event Grid, Service Bus,
  Event Hubs, Storage queue (tabel keputusan); Functions vs Logic Apps.
- **Demo (animasi):** foto produk diunggah → event → function berjalan → thumbnail disimpan; lonjakan event membuat
  instance function di-scale out lalu kembali ke nol; workflow Logic App menyala langkah demi langkah.
- **Ide video:** membuat function app, menguji HTTP trigger, membangun Logic App kecil.
- **Lab 14 · Menanggapi pesanan baru secara otomatis (≈50 menit, 💲):** function app Flex Consumption dengan function
  ber-HTTP trigger (kode disediakan) yang menulis ke storage queue; Logic App Consumption yang memanggilnya sesuai
  jadwal atau lewat permintaan HTTP. *Rusak lalu perbaiki:* app setting yang hilang. Verifikasi: function app, function
  merespons, queue menerima pesan, Logic App aktif (enabled).

## Bulan inti — Bagian 4 · Keamanan, operasional, dan tata kelola

### Makan Siang 15 · Esensi Keamanan: Defense in Depth, Key Vault, dan Defender for Cloud (Dasar)
- **Bacaan:** lapisan-lapisan defense in depth (*pertahanan mendalam*); prinsip Zero Trust (verifikasi secara eksplisit,
  hak akses minimum, asumsikan sudah dibobol); menengok kembali model tanggung jawab bersama; Microsoft Defender for
  Cloud (*Microsoft Defender untuk Cloud*) dengan CSPM dasar yang gratis, secure score, rekomendasi, dan Defender plan;
  Azure Key Vault (secret, key, sertifikat; model izin RBAC; soft delete dan purge protection); managed identity
  (system-assigned vs user-assigned) — tanpa secret di dalam kode; enkripsi saat disimpan (at rest) dan saat dikirim (in
  transit); sekilas tentang Azure Firewall, DDoS Protection, dan WAF; sekilas tentang Microsoft Sentinel.
- **Demo (animasi):** jalur penyerang yang dihentikan di lapisan pertahanan demi lapisan; sebuah VM mengambil token dari
  endpoint managed identity dan membaca secret Key Vault — awalnya ditolak, lalu diizinkan setelah ada role assignment.
- **Ide video:** Key Vault dengan RBAC, sebuah managed identity, secure score di Defender for Cloud.
- **Lab 15 · Keluarkan kata sandi dari file konfigurasi (≈45 menit, 💲💲):** Key Vault (model RBAC) dan sebuah secret; VM
  dengan system-assigned identity; baca secret dari VM dengan Run Command (403 sebelum role diberikan, berhasil
  sesudahnya); tinjau secure score dan rekomendasi. Verifikasi: vault RBAC, secret, role assignment, pembacaan yang
  berhasil. Pembersihan juga mem-purge vault yang sudah di-soft-delete.

### Makan Siang 16 · Pemantauan (Dasar): Azure Monitor, Alert, Service Health, dan Advisor
- **Bacaan:** mengapa perlu memantau; Azure Monitor — metrik vs log, activity log, resource log dan diagnostic setting,
  workspace Log Analytics (pengantar), alert berbasis metrik, log search, dan activity log beserta action group,
  dashboard dan workbook; sekilas tentang Application Insights; Azure Service Health vs Resource Health; rekomendasi
  Azure Advisor.
- **Demo (animasi):** metrik CPU melewati ambang batas → alert menyala → action group mengirim email ke engineer yang
  sedang piket (on-call); activity log menjawab "siapa yang menghapus VM saya?"; cakupan Service Health vs Resource
  Health.
- **Ide video:** membuat action group dan metric alert, membaca activity log.
- **Lab 16 · Tahu lebih dulu daripada pelanggan (≈45 menit, 💲💲):** `setup.sh` membuat VM kecil; action group dengan
  email Anda; metric alert CPU; bangkitkan beban CPU dengan Run Command dan terima alert-nya; activity log alert;
  Service Health alert; rekomendasi Advisor. *Rusak lalu perbaiki:* alert yang tidak pernah menyala. Verifikasi: action
  group, alert aktif.

### Makan Siang 17 · Pencadangan Data dan Pemulihan Bencana (Dasar)
- **Bacaan:** ketersediaan tinggi vs pemulihan bencana vs cadangan (backup); RPO dan RTO — RPO (Recovery Point
  Objective) adalah batas data yang boleh hilang, diukur dalam waktu, sedangkan RTO (Recovery Time Objective) adalah
  batas lama layanan boleh berhenti sampai pulih kembali; Azure Backup (Recovery Services vault vs Backup vault, policy,
  apa saja yang bisa dilindungi, instant restore); melindungi cadangan (soft delete, immutability, multi-user
  authorization); opsi pemulihan (VM, disk, file); Azure Site Recovery (replikasi, test failover, zona-ke-zona dan
  region-ke-region); cadangan bawaan layanan PaaS; perencanaan DR untuk region tanpa pasangan; uji proses pemulihan Anda
  secara berkala.
- **Demo (animasi):** RPO/RTO di atas garis waktu; ransomware menghapus cadangan — soft delete menyelamatkannya;
  failover Site Recovery ke region kedua.
- **Ide video:** mengaktifkan backup VM, menjalankan backup, memulihkan file.
- **Lab 17 · Latihan pemulihan data (≈60–90 menit, sebagian besar menunggu, 💲💲):** `setup.sh` membuat VM berisi file
  pesanan; Recovery Services vault (soft delete dimatikan khusus untuk lab ini, disertai peringatan untuk lingkungan
  produksi); aktifkan backup; backup on-demand; "hilangkan" file-nya; pulihkan kembali. Verifikasi: vault, VM yang
  terlindungi, recovery point. Pembersihan menghentikan perlindungan, menghapus data dan vault.

### Makan Siang 18 · Tata Kelola dan Kepatuhan (Dasar): Azure Policy, Lock, Tag, dan Microsoft Purview
- **Bacaan:** arti tata kelola; Azure Policy (definition, initiative, assignment, scope, parameter; effect Deny, Audit,
  Modify, Append, DeployIfNotExists, AuditIfNotExists, Disabled; kepatuhan; exemption; initiative bawaan dan
  regulatori); menengok kembali resource lock; strategi tagging dan penegakannya; sekilas tentang Microsoft Purview
  (tata kelola data dan kepatuhan); Service Trust Portal dan pernyataan privasi Microsoft; Azure Blueprints sudah
  dipensiunkan (dihentikan bertahap mulai 31 Juli 2026, pensiun penuh pada 31 Januari 2027) — gunakan Azure Policy
  ditambah deployment stack dan template spec.
- **Demo (animasi):** permintaan deployment bertemu mesin policy — ditolak oleh allowed locations; resource yang sudah
  ada diaudit ke dalam tampilan kepatuhan; policy Modify menambahkan tag yang hilang secara otomatis.
- **Ide video:** meng-assign policy bawaan dan menyaksikan deployment yang tidak patuh gagal.
- **Lab 18 · Menjaga data tetap di tempat yang benar (≈45 menit, 💲):** assign "Allowed locations", "Require a tag on
  resources", dan "Inherit a tag from the resource group if missing" di scope resource group; buktikan penolakannya;
  lakukan remediasi; baca status kepatuhan. Verifikasi: assignment dan status kepatuhan.

### Makan Siang 19 · Manajemen Biaya (Dasar)
- **Bacaan:** apa saja yang memengaruhi biaya (jenis dan ukuran resource, pemakaian, region, transfer data keluar,
  lisensi); pricing calculator; opsi pembelian (pay-as-you-go, reservation, savings plan for compute, Spot, Azure Hybrid
  Benefit, harga dev/test); Cost Management (*manajemen biaya*): cost analysis, budget dan alert, anomaly alert, export;
  rekomendasi biaya dari Advisor; tag untuk showback; dasar-dasar FinOps; pemborosan yang umum (disk yang tidak
  terpasang, public IP yang tidak dipakai, resource yang kebesaran atau menganggur).
- **Demo (animasi):** tagihan yang diurai menjadi compute, penyimpanan, dan jaringan; "perburuan resource yatim" yang
  menyorot resource tak terpakai; alert anggaran di 50/80/100%.
- **Ide video:** cost analysis yang dikelompokkan per tag dan resource group; membuat budget.
- **Lab 19 · Temukan pemborosan buatan Anda sendiri (≈40 menit, 💲):** `setup.sh` membuat "pemborosan" yang murah (disk
  yang tidak terpasang, public IP yang tidak dipakai, plan yang menganggur); temukan dengan Resource Graph dan Advisor;
  analisis biaya per tag; buat budget untuk resource group; bandingkan harga pay-as-you-go vs reservation di kalkulator;
  singkirkan pemborosannya. Verifikasi: tidak ada resource yatim yang tersisa, budget ada.

### Makan Siang 20 · Infrastructure as Code dengan Bicep (Dasar)
- **Bacaan:** mengapa perlu infrastructure as code; deklaratif vs imperatif; ARM template (*templat ARM*), Bicep, dan
  Terraform; anatomi Bicep (parameter, variabel, resource, symbolic name, dependensi implisit, output, modul, loop,
  kondisi, decorator); deployment scope dan mode; what-if; template spec; deployment stack (siklus hidup + deny setting,
  pengganti Blueprints yang direkomendasikan); Azure Verified Modules; sekilas tentang GitHub Actions dengan OpenID
  Connect.
- **Demo (animasi):** file Bicep yang "mengetik dirinya sendiri" sementara resource bermunculan; diff what-if (+ create,
  ~ modify, − delete); deploy ulang tidak mengubah apa pun; hapus grupnya lalu bangun ulang dalam hitungan menit.
- **Ide video:** menulis file Bicep di VS Code, what-if, deploy, deploy ulang.
- **Lab 20 · Sembilan belas makan siang penuh klik dalam satu file (≈50 menit, 💲):** lengkapi `main.bicep` awal (storage
  account, VNet dengan dua subnet, NSG, workspace Log Analytics); build, what-if, deploy, ubah, deploy ulang; deploy
  sebagai deployment stack dengan deny setting dan saksikan penghapusan manual gagal; hapus stack-nya. *Rusak lalu
  perbaiki:* error kompilasi. Verifikasi: resource, tag, stack.

### Makan Siang 21 · Capstone Inti: Menyatukan Semuanya (Dasar)
- **Bacaan:** pilar Azure Well-Architected Framework (keandalan, keamanan, optimasi biaya, keunggulan operasional,
  efisiensi performa) beserta untung-ruginya; sekilas tentang Cloud Adoption Framework (landing zone); arsitektur target
  Nusantara Retail (web tier yang tahan kegagalan zona, Azure SQL, Key Vault, pemantauan, cadangan, policy, anggaran,
  semuanya sebagai kode); menjawab pertanyaan direktur dengan RTO dan RPO; langkah selanjutnya — persiapan AZ-900 dan
  bulan pendalaman.
- **Demo (animasi):** sebuah permintaan dari ujung ke ujung melewati arsitektur target; satu zona gagal dan toko tetap
  buka; pagar pengaman berupa pemantauan, anggaran, dan policy menyala.
- **Ide video:** menelusuri capstone yang sudah di-deploy di portal.
- **Lab 21 · Proyek capstone (≈2–3 jam, bisa dicicil, 💲💲):** deploy platform inti dari Bicep modular yang disediakan
  (jaringan, dua VM web di dua zona di belakang Standard load balancer, Azure SQL, Key Vault, Log Analytics dan sebuah
  alert, policy allowed locations); buktikan ketahanan terhadap kegagalan zona; periksa pemantauan; tinjau sendiri
  hasilnya dengan daftar periksa Well-Architected. Mode Tantangan hanya memberi persyaratan. Verifikasi memeriksa setiap
  komponen.

---

## Bulan pendalaman — Makan siang lanjutan

### Makan Siang 22 · Identitas dan Akses (Lanjutan)
- **Bacaan:** managed identity secara mendalam (system-assigned vs user-assigned, siklus hidup,
  `DefaultAzureCredential`); app registration vs service principal; secret dan sertifikat vs workload identity
  federation (OpenID Connect untuk GitHub Actions dan Kubernetes); policy Conditional Access (condition, grant control
  dan session control, report-only); Privileged Identity Management (eligible vs active, aktivasi just-in-time,
  persetujuan); custom role (actions, notActions, dataActions, assignable scopes); access review; akun akses darurat
  (emergency access); catatan lisensi (Entra ID P1/P2); External ID untuk mitra dan pelanggan.
- **Demo (animasi):** GitHub Actions → token OIDC → federated credential → access token → deployment, tanpa secret yang
  disimpan; garis waktu aktivasi PIM (eligible → aktivasi → aktif selama dua jam → kedaluwarsa).
- **Lab 22 · Pipeline tanpa kata sandi dan hak akses minimum (≈50 menit, 💲):** custom role "VM Operator"; user-assigned
  managed identity yang diberi data role; app registration dengan federated credential untuk sebuah repositori GitHub
  plus contoh workflow; panduan opsional Conditional Access/PIM (butuh lisensi P1/P2 atau versi uji coba). Verifikasi:
  role definition, identity dan role assignment, federated credential.

### Makan Siang 23 · Virtual Machines (Lanjutan)
- **Bacaan:** opsi ketersediaan dan SLA: VM tunggal, availability set (*set ketersediaan*) dengan fault domain/update
  domain, dan availability zone; Virtual Machine Scale Sets (*Kumpulan Skala Komputer Virtual*) dengan orkestrasi
  Flexible vs Uniform, autoscale (rule berbasis metrik dan jadwal), upgrade policy, automatic instance repair; image
  (Marketplace, custom, Azure Compute Gallery, VM Image Builder); extension dan cloud-init; Spot VM dan eviction;
  dedicated host dan proximity placement group; Azure Update Manager; Trusted Launch; sekilas tentang Azure Virtual
  Desktop.
- **Demo (animasi):** lonjakan trafik saat festival belanja → autoscale menambah instance di tiga zona → scale-in
  setelah masa cool-down; fault domain/update domain vs zona; eviction pada Spot VM.
- **Lab 23 · Siap menghadapi promo 12.12 (≈60 menit, 💲💲):** scale set Flexible lintas zona di belakang Standard load
  balancer (web server dari cloud-init bersama); profil autoscale; bangkitkan beban CPU dan saksikan scale-out; Spot VM
  dengan eviction policy; patch assessment dengan Update Manager. Perhatikan kuota vCPU Anda. Verifikasi: mode scale
  set, zona, autoscale, instance.

### Makan Siang 24 · Penyimpanan (Lanjutan)
- **Bacaan:** perlindungan data (soft delete, versioning, point-in-time restore, change feed, immutability, object
  replication); lifecycle management; keamanan jaringan (firewall, trusted service, service endpoint vs private endpoint
  dengan private DNS); menonaktifkan shared key dan SAS expiration policy; enkripsi dengan customer-managed key;
  Defender for Storage; Data Lake Storage (hierarchical namespace), SFTP dan NFS; target skalabilitas; pemindahan data
  skala besar (AzCopy sync, Storage Mover, Data Box); Azure File Sync; hosting static website; perubahan redundansi dan
  customer-managed failover.
- **Demo (animasi):** siklus hidup sebuah blob selama sepuluh tahun (hot → cool → cold → archive → delete); versioning
  dan soft delete menyelamatkan faktur yang tertimpa dan terhapus; trafik lewat private endpoint vs trafik lewat public
  endpoint.
- **Lab 24 · Faktur tahan ransomware (≈60 menit, 💲💲):** versioning, soft delete, dan change feed; timpa dan hapus data,
  lalu pulihkan; lifecycle policy; immutability berbasis waktu (unlocked); private endpoint dan private DNS zone, diuji
  dari sebuah VM; nonaktifkan public network access. Verifikasi: pengaturan perlindungan data, policy, private endpoint
  dan DNS link.

### Makan Siang 25 · Virtual Networking (Lanjutan)
- **Bacaan:** VNet peering (regional dan global, tidak transitif, gateway transit); hub-and-spoke; system route,
  user-defined route, effective route, dan jenis next hop; Azure Firewall (SKU, rule, DNAT, Firewall Manager) dan
  network virtual appliance; NAT gateway secara mendalam; SKU Azure Bastion; service endpoint vs Private Link dan
  private endpoint; private DNS zone dan Azure DNS Private Resolver; sekilas tentang Virtual Network Manager; Network
  Watcher (next hop, connection troubleshoot, VNet flow log, traffic analytics); DDoS Network Protection.
- **Demo (animasi):** hub dengan dua spoke — koneksi spoke-ke-spoke gagal (tidak transitif) sampai sebuah route mengirim
  trafik lewat appliance di hub; resolusi nama private endpoint (nama → alias privatelink → IP privat).
- **Lab 25 · Hub-and-spoke untuk Nusantara Retail (≈60 menit, 💲💲):** `setup.sh` membuat satu hub dan dua spoke,
  masing-masing dengan satu VM kecil (tanpa public IP); hubungkan dengan peering; buktikan sifat tidak transitifnya;
  jadikan VM di hub sebagai router sederhana (IP forwarding); tambahkan route table; periksa effective route dan next
  hop; jalur Azure Firewall opsional (💲💲💲). Verifikasi: peering, route, forwarding, konektivitas.

### Makan Siang 26 · Hybrid Connectivity: VPN Gateway, ExpressRoute, dan Virtual WAN (Lanjutan)
- **Bacaan:** mengapa perlu hibrid (kantor pusat dan empat puluh toko); VPN site-to-site (IPsec/IKE, route-based,
  active-active, BGP), VPN point-to-site (autentikasi Entra ID), VNet-to-VNet; SKU VPN Gateway (SKU AZ yang
  zone-redundant) dan GatewaySubnet; local network gateway; ExpressRoute (circuit, penyedia konektivitas, lokasi
  peering, private peering dan Microsoft peering, SKU, Global Reach, FastPath, ExpressRoute Direct, ketahanan, VPN
  sebagai cadangan); Virtual WAN; perencanaan alamat IP agar jaringan tidak pernah tumpang-tindih (mengingat kembali
  Makan Siang 08).
- **Demo (animasi):** terowongan site-to-site terbentuk dan trafik mengalir terenkripsi; jalur privat ExpressRoute vs
  jalur internet; hub Virtual WAN yang menghubungkan kantor-kantor cabang.
- **Lab 26 · Menghubungkan kantor pusat (≈90 menit termasuk pembuatan gateway, 💲💲💲):** simulasikan kantor pusat dengan
  VNet kedua; `setup.sh` mulai membuat dua VPN gateway (sekitar 30–45 menit, jadi silakan membaca sambil menunggu); buat
  koneksi VNet-to-VNet dengan shared key; uji trafik VM-ke-VM melintasi terowongan; segera hapus. Verifikasi: gateway,
  koneksi berstatus Connected, trafik.

### Makan Siang 27 · Load Balancing (Lanjutan): Application Gateway, Front Door, dan Traffic Manager
- **Bacaan:** penyeimbangan beban di layer 7; Application Gateway v2 (listener, rule, backend setting, probe, routing
  berbasis path dan multi-site, TLS termination, autoscale, zone redundancy, WAF policy); Azure Front Door (edge global,
  routing rule, origin group, caching, WAF, origin Private Link); Traffic Manager (metode routing berbasis DNS dan hal
  yang perlu diwaspadai soal TTL); cross-region Load Balancer; pohon keputusan (global vs regional, HTTP(S) atau bukan);
  kombinasi yang umum.
- **Demo (animasi):** pohon keputusan interaktif; pembeli di Surabaya diarahkan ke edge terdekat dan origin yang sehat;
  WAF memblokir permintaan SQL injection; failover berbasis prioritas Traffic Manager lewat DNS.
- **Lab 27 · Melindungi dan merutekan toko online (≈75 menit, 💲💲💲):** dua web app kecil; Application Gateway WAF_v2
  dengan routing berbasis path dan WAF policy dalam mode prevention (buktikan ada serangan yang diblokir); profil
  priority Traffic Manager dan uji failover; Front Door opsional. Verifikasi: gateway, WAF policy, path rule, endpoint
  Traffic Manager.

### Makan Siang 28 · Database Relasional (Lanjutan)
- **Bacaan:** ketersediaan tinggi Azure SQL (arsitektur General Purpose, Business Critical, Hyperscale; zone
  redundancy); pemulihan bencana (active geo-replication, failover group dan listener endpoint, geo-restore); cadangan
  (point-in-time restore, long-term retention, redundansi backup storage); scaling (vCore, elastic pool, Hyperscale,
  read scale-out); keamanan (autentikasi Entra-only, TDE dengan service-managed key atau customer-managed key, Always
  Encrypted, dynamic data masking, row-level security, auditing, Microsoft Defender for SQL, private endpoint); performa
  (Query Store, automatic tuning); HA dan read replica pada Azure Database for PostgreSQL/MySQL flexible server.
- **Demo (animasi):** sebuah failover group — replikasi asinkron ke region sekunder, listener mengikuti primary saat
  failover, dan RPO sama dengan jeda (lag) replikasi.
- **Lab 28 · Pesanan yang selamat dari gangguan region (≈60 menit, 💲💲):** dua logical server di dua region; sebuah
  database kecil; failover group; terhubung lewat listener; planned failover; point-in-time restore ke database baru;
  dynamic data masking; auditing. Verifikasi: peran di failover group, database hasil restore, masking rule.

### Makan Siang 29 · Containers (Lanjutan): Azure Kubernetes Service
- **Bacaan:** komponen dasar Kubernetes (cluster, control plane, node, pod, deployment, service, ingress, namespace,
  ConfigMap dan Secret, probe); arsitektur dan tier AKS; node pool system vs user; zona; jaringan (Azure CNI Overlay dan
  kawan-kawannya); opsi ingress; scaling (HPA, cluster autoscaler, KEDA); identitas (integrasi Entra, workload
  identity); integrasi ACR; upgrade; pemantauan (Container insights, managed Prometheus dan Grafana); AKS vs Container
  Apps.
- **Demo (animasi):** desired state sebuah deployment (tiga replika) dijadwalkan ke node di berbagai zona; sebuah node
  gagal lalu pod dijadwalkan ulang; horizontal pod autoscaler menambah pod saat beban naik; rolling update.
- **Lab 29 · Kubernetes untuk tim microservices (≈60 menit, 💲💲💲):** cluster AKS kecil; deploy manifest yang disediakan
  (deployment + service LoadBalancer); scale; rolling update; HPA; ingress opsional. *Rusak lalu perbaiki:* tag image
  yang salah → ImagePullBackOff. Verifikasi: cluster, replika yang siap (ready), IP eksternal. Segera hapus.

### Makan Siang 30 · Pemantauan (Lanjutan): Log Analytics, KQL, dan Application Insights
- **Bacaan:** desain workspace, retensi, dan table plan; pengumpulan data (diagnostic setting, Azure Monitor Agent dan
  data collection rule, VM insights); dasar-dasar KQL (where, project, summarize, bin, render, join); log search alert;
  Application Insights (berbasis workspace, OpenTelemetry, request, dependency, failure, availability test, application
  map, live metrics); workbook, dashboard, dan Azure Managed Grafana; mengendalikan biaya log.
- **Demo (animasi):** telemetri mengalir dari VM (agent + DCR), aplikasi (Application Insights), dan log platform
  (diagnostic setting) ke dalam satu workspace; pipeline kueri KQL mengubah baris-baris data menjadi grafik dan alert.
- **Lab 30 · Mengapa checkout lambat pada hari Jumat? (≈60 menit, 💲💲):** workspace; VM yang terhubung lewat Azure
  Monitor Agent dan data collection rule; diagnostic setting untuk sebuah resource PaaS; latihan KQL beserta solusinya;
  log search alert; availability test untuk sebuah web app. Verifikasi: DCR association, diagnostic setting, alert rule.

### Makan Siang 31 · Hierarki Resource dan Tata Kelola (Lanjutan): Tata Kelola Skala Besar
- **Bacaan:** desain management group (hierarki Azure landing zone: platform, landing zone, sandbox, decommissioned);
  subscription sebagai unit skala dan subscription vending; tata kelola berbasis policy (initiative di scope management
  group, parameter, exemption, remediasi Modify dan DeployIfNotExists dengan managed identity, policy as code);
  kepatuhan regulasi di Defender for Cloud; RBAC dalam skala besar (grup, PIM, custom role); Resource Graph dalam skala
  besar; budget di scope yang lebih tinggi; akselerator Azure landing zone; deployment stack untuk artefak tata kelola;
  Azure Arc untuk server dan Kubernetes di luar Azure; bermigrasi meninggalkan Blueprints.
- **Demo (animasi):** hierarki landing zone terbangun; initiative yang di-assign di sebuah management group mengalir ke
  bawah; remediasi DeployIfNotExists memperbaiki resource yang tidak patuh; sebuah exemption.
- **Lab 31 · Tata kelola untuk seluruh perusahaan (≈60 menit, 💲):** management group (memindahkan subscription Anda
  bersifat opsional); custom initiative (allowed locations, tag wajib, tag yang diwariskan); assignment, remediasi,
  exemption; kueri kepatuhan dengan Resource Graph; ekspor assignment sebagai kode. Verifikasi: management group,
  initiative, assignment, exemption.

### Tantangan capstone lanjutan (hanya lab)
Proyek yang hanya berisi persyaratan: jaringan hub-and-spoke dengan firewall atau appliance, private endpoint untuk SQL
dan storage, web tier zone-redundant di belakang Application Gateway WAF, failover group SQL, semuanya dalam Bicep di
bawah sebuah deployment stack, policy initiative, alert berbasis KQL, cadangan dan rencana DR untuk region tanpa
pasangan, serta tinjauan Well-Architected. Peserta merancang, membangun, memverifikasi dengan daftar periksa yang
disediakan, lalu membersihkan semuanya.
