# Makan Siang 09 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** memperlihatkan pengalaman Azure yang sesungguhnya untuk makan siang ini — membuat Standard load balancer
> di portal dan menyaksikan status kesehatan backend berubah ketika sebuah server gagal, hal yang hanya bisa
> disimulasikan oleh animasi.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan dari layar:** ID subscription, nama tenant, alamat e-mail, dan alamat IP publik yang masih akan terus
> Anda pakai.

## Sebelum menekan tombol rekam

- Jalankan titik awal lab sekitar 15 menit sebelum merekam, agar kedua VM sudah selesai booting:

  ```bash
  cd azure-fundamentals-lunches/labs/09-load-balancing-basic
  source ../common/config.sh && source lab.env
  bash setup.sh
  ```

- **Jangan** membuat IP publik atau load balancer lebih dulu — Anda membangunnya di depan kamera (Tugas 2–4 di lab).
- Tab browser: (1) portal yang terbuka di resource group `rg-lunch09-<suffix>`; (2) Azure Cloud Shell (Bash) dengan kedua
  baris `source` di atas sudah dijalankan, dan layarnya sudah dibersihkan.
- Siapkan perintah ini untuk ditempel di Cloud Shell pada adegan failover:
  `az vm run-command invoke -g "$RG" -n "$VM2" --command-id RunShellScript --scripts "systemctl stop nusa-web"`
- Setelah merekam, lanjutkan lab atau jalankan `bash cleanup.sh`.

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:25 Dua server web, tanpa IP publik
00:55 Membuat Standard load balancer publik
02:15 Health probe dan load-balancing rule
03:05 Request di dua zona
03:40 Sebuah server gagal — dan toko tetap buka
04:50 Sekilas inbound NAT rule dan outbound rule
05:25 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 09 · Azure Load Balancer — toko tetap buka" | "Nusantara Retail punya dua server web di dua availability zone, tetapi pembeli hanya bisa menemukan salah satunya. Dalam lima menit ke depan, kita memberi kedua server itu satu pintu depan, lalu melihatnya mengalihkan lalu lintas saat terjadi kegagalan." |
| 00:25 | Portal › resource group `rg-lunch09-<suffix>` › overview `vm-web-1`: zona 1, hanya IP privat, tanpa IP publik | "Ini dua server dari setup lab: vm-web-1 di zona 1, vm-web-2 di zona 2. Perhatikan, tidak ada IP publik — keduanya berada di subnet privat, dan NSG hanya mengizinkan lalu lintas web serta probe dari load balancer." |
| 00:55 | *Create a resource* › *Load Balancer* › tab Basics: Standard, Public, Regional; region Southeast Asia | "Kita buat load balancer. SKU-nya Standard — SKU Basic sudah dipensiunkan pada September 2025. Type-nya Public, karena pembeli datang dari internet. Tier-nya Regional; tier Global dipakai untuk menyebarkan lalu lintas ke beberapa region." |
| 01:30 | *Frontend IP configuration* › Add › buat IP publik `pip-lb-nusa-web`, Availability zone **Zone-redundant** | "Frontend adalah satu alamat yang dilihat pembeli. Saya membuat Standard public IP baru dan menjadikannya zone-redundant, agar alamat ini tetap menjawab meskipun satu zona padam." |
| 01:55 | *Backend pools* › Add `be-web`, configuration type NIC, tambahkan `vm-web-1` dan `vm-web-2` | "Backend pool berisi daftar server yang boleh menerima lalu lintas — di sini, network interface milik kedua VM." |
| 02:15 | *Inbound rules* › Add a load balancing rule: TCP 80 → 80; buat health probe HTTP, port 80, path `/health`, interval 5 | "Sekarang rule-nya: TCP port 80 di frontend diteruskan ke port 80 di pool. Rule ini membutuhkan health probe: HTTP GET ke garis miring health setiap lima detik. Hanya server yang menjawab 200 OK yang mendapat koneksi baru." |
| 02:45 | Dialog yang sama: *Outbound source network address translation* diatur ke opsi yang memakai outbound rule; *Review + create* › *Create* | "Saya memberi tahu rule ini agar tidak menangani lalu lintas keluar — nanti kita memberi server jalan keluar yang disengaja lewat outbound rule. Review, create. Standard load balancer selesai di-deploy dalam waktu jauh di bawah satu menit." |
| 03:05 | Cloud Shell: `who_answers 10` | "Mari kita uji dari Cloud Shell. Fungsi bantu ini mengirim sepuluh request ke frontend dan mencetak server mana yang menjawab. Kedua zona muncul — setiap koneksi baru ditempatkan berdasarkan hash, jadi urutannya tidak bergantian secara ketat." |
| 03:40 | Cloud Shell: tempel perintah `systemctl stop nusa-web` untuk `vm-web-2`, lalu `who_answers 10` | "Sekarang saya membuat layanan web di vm-web-2 crash. VM-nya masih berjalan, tetapi tidak ada yang menjawab di port 80. Dalam hitungan detik probe gagal, dan semua jawaban kini datang dari vm-web-1. Pembeli tidak perlu alamat baru." |
| 04:15 | Portal › load balancer › *Monitoring* › *Metrics* › **Health Probe Status**, dipecah (split) berdasarkan Backend IP Address | "Di portal, metrik Health Probe Status yang dipecah per alamat backend memperlihatkan satu server keluar dari barisan. Metrik tertinggal satu atau dua menit, jadi toko sudah pulih sebelum grafiknya sempat menyadari." |
| 04:35 | Cloud Shell: jalankan lagi layanannya, `who_answers 6` | "Jalankan lagi layanannya, dan vm-web-2 bergabung kembali dengan sendirinya — tak seorang pun menyentuh load balancer." |
| 04:50 | Portal › load balancer › blade *Inbound NAT rules* dan *Outbound rules* (kosong) | "Ada dua blade lagi yang penting. Inbound NAT rule meneruskan satu port frontend ke satu VM — praktis untuk SSH darurat. Outbound rule membiarkan pool menjangkau internet melalui IP frontend. Anda akan membangun keduanya di lab." |
| 05:25 | Slide rangkuman: frontend · pool · probe · rule · NAT · outbound | "Tiga hal yang perlu diingat: gunakan SKU Standard, periksa sesuatu yang bermakna lewat probe, dan buat akses keluar secara eksplisit. Lab akan memandu Anda di setiap langkah — termasuk bersih-bersihnya." |

## Setelah merekam
- Tambahkan teks (caption): buat otomatis, lalu koreksi istilah Azure secara manual: *Standard SKU*, *backend pool*,
  *health probe*, *SNAT*.
- Tambahkan daftar chapter ke deskripsi video.
- Tempel link video ke README makan siang ini (bagian 🎬 Demo).
- Hapus resource demo: `bash cleanup.sh` di `labs/09-load-balancing-basic`.
- Samarkan (blur) alamat IP publik frontend saat penyuntingan jika terlihat di tangkapan layar Cloud Shell atau portal.
