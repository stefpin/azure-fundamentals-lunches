# Makan Siang 21 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sesungguhnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan oleh animasi: platform capstone yang sudah jadi di portal, latihan kegagalan zone yang nyata, dan guardrail yang bereaksi.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail (action group, e-mail alert, nama administrator SQL Anda), serta public IP address dan nama DNS toko online jika Anda tetap menyimpan lingkungannya setelah merekam.

## Sebelum menekan tombol rekam

- Deploy lab setidaknya 30 menit sebelum merekam, supaya metrik, backup database pertama, dan log audit Key Vault sudah tersedia:

  ```bash
  cd azure-fundamentals-lunches/labs/21-core-capstone
  source ../common/config.sh && source lab.env
  bash deploy.sh
  az keyvault secret show --vault-name "$KV" -n "$SECRET" --query name -o tsv   # creates one audit log entry
  ```

- Buat budget `budget-lunch21` (Lab 21, Tugas 7) supaya halaman Budgets tidak kosong.
- Pastikan kedua server menjawab: `who_answers 6`.
- Tab browser, dengan urutan ini: (1) overview *rg-lunch21-&lt;suffix&gt;*, (2) URL toko online dari output deployment, (3) *lb-nusa-shop › Monitoring › Insights*, (4) overview *vm-web-1*, (5) *Monitor › Alerts* yang difilter ke resource group, (6) *Policy › Assignments*, (7) *Cost Management › Budgets* untuk resource group, (8) *kv-nusa-&lt;suffix&gt;*, (9) *sql-nusa-&lt;suffix&gt;*.
- Cloud Shell terbuka di panel samping, di folder lab, dengan nama-nama resource sudah dimuat (`source ../common/config.sh && source lab.env`).
- Aplikasi e-mail terbuka di jendela terpisah, yang bisa Anda tampilkan dengan alamat yang diburamkan.

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:25 Satu deployment, enam modul
01:05 Ikuti satu request: toko online dan Insights load balancer
01:50 Kehilangan zone 1 — toko tetap buka
03:05 Pemantauan: alert yang sampai ke inbox
03:40 Guardrail: penolakan policy dan budget
04:35 Sekilas keamanan: Key Vault dan Azure SQL
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 21 · Toko yang tetap buka" | "Dalam enam menit ke depan, kita berkeliling platform inti Nusantara Retail yang sudah jadi, sengaja mematikan satu availability zone, lalu melihat toko tetap berjualan." |
| 00:25 | Tab 1 › *Settings › Deployments*: `capstone` ditambah `network`, `web`, `sql`, `keyvault`, `monitoring`, `policy` | "Semua yang ada di resource group ini berasal dari satu deployment Bicep. Setiap modul muncul sebagai nested deployment tersendiri, dengan urutan yang disusun Bicep dari output-outputnya. Tidak ada satu pun resource ini yang dibuat dengan klik manual." |
| 00:45 | Tab 1 › *Resource visualizer* | "Resource visualizer menggambar bagaimana semuanya terhubung: satu public IP, satu load balancer, dua kartu jaringan, dua VM — ditambah database, vault, dan komponen-komponen pemantauan." |
| 01:05 | Tab 2: refresh toko online beberapa kali | "Inilah toko online-nya. Setiap koneksi baru bisa mendarat di server yang berbeda: vm-web-1 di zone 1 atau vm-web-2 di zone 2." |
| 01:25 | Tab 3: diagram *Insights*, arahkan kursor ke probe dan kedua backend | "Insights milik load balancer menampilkan frontend, rule di port 80, health probe di slash health, dan kedua backend dalam keadaan sehat." |
| 01:50 | Cloud Shell: jalankan `watch_shop 120` | "Sekarang latihannya. Di Cloud Shell, watch_shop meminta halaman setiap dua detik dan mencetak server mana yang menjawab." |
| 02:05 | Tab 4: *vm-web-1 › Stop*, lalu konfirmasi | "Saya menghentikan vm-web-1 — semua yang kita jalankan di zone 1. Inilah cara paling dekat yang bisa dilakukan seorang pelanggan untuk 'mematikan' sebuah pusat data." |
| 02:25 | Cloud Shell: campuran, mungkin satu *(no answer)*, lalu hanya `vm-web-2` | "Satu atau dua request meleset selagi probe menyadarinya, lalu setiap jawaban datang dari zone 2. Tidak ada pengaturan yang diubah. Beberapa detik itulah waktu pemulihan hasil pengukuran kita untuk kegagalan zone." |
| 02:45 | Tab 3 › *Metrics*: Health Probe Status, di-split berdasarkan Backend IP Address | "Pandangan load balancer sependapat: garis untuk vm-web-1 berhenti, karena VM yang dihentikan sama sekali tidak diperiksa oleh probe." |
| 03:05 | Tab 5: *alert-web-vm-stopped* yang menyala; lalu e-mail-nya (alamat diburamkan) | "Dalam hitungan menit, activity log alert menyala dan action group mengirim e-mail kepada engineer yang sedang piket. Pemantauan menyadarinya sebelum ada pembeli yang mengeluh." |
| 03:25 | Tab 4: *vm-web-1 › Start* | "Saya menyalakan vm-web-1 lagi. Begitu ia menjawab probe, ia bergabung kembali ke rotasi dengan sendirinya." |
| 03:40 | Cloud Shell: `az network nsg create -g "$RG" -n nsg-policy-test --location eastus` → `RequestDisallowedByPolicy` | "Sekarang guardrail-nya. Bahkan network security group kosong di East US pun ditolak. Policy Allowed locations menolaknya, dan error-nya membawa pesan yang kita tulis di dalam assignment." |
| 04:05 | Tab 6: assignment `allowed-locations` pada resource group | "Assignment ini terpasang pada resource group dan hanya mengizinkan region kita. Policy bertindak sebelum apa pun dibangun." |
| 04:20 | Tab 7: `budget-lunch21` dengan alert 50, 80, dan 100 persen | "Dan Cost Management mengawasi uangnya: budget dengan alert pada 50, 80, dan 100 persen. Budget memperingatkan; ia tidak pernah mematikan apa pun." |
| 04:35 | Tab 8: *Access control (IAM) › Role assignments*, lalu *Secrets* | "Key Vault memakai Azure RBAC. Saya memegang Key Vault Secrets Officer hanya pada vault ini, dan connection string di dalamnya sama sekali tidak berisi kata sandi…" |
| 04:55 | Tab 9: *Settings › Microsoft Entra ID*, "Support only Microsoft Entra authentication" tercentang | "…karena Azure SQL hanya menerima identitas Microsoft Entra. Tidak ada SQL login yang bisa bocor." |
| 05:15 | Slide rangkuman: tabel RTO dan RPO dari bacaan | "Tiga hal untuk diingat. Sebarkan lapisan yang stateless ke beberapa zone. Buat cadangan untuk semua yang menyimpan state, dan uji restore-nya. Dan masukkan guardrail — alert, policy, budget — ke dalam kode sejak hari pertama. Setelah itu, jalankan cleanup.sh." |
| 05:45 | Kartu penutup dengan tautan Lab 21 | "Bangun sendiri di Lab 21, dan sampai jumpa di bulan pendalaman." |

## Setelah merekam
- Tambahkan caption (buat otomatis, lalu koreksi istilah Azure secara manual: Microsoft Entra ID, Key Vault, Bicep, what-if)
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo) — untuk rekaman berbahasa Indonesia, di `README.id.md`
- Hapus resource demo: `bash cleanup.sh` di `labs/21-core-capstone`
