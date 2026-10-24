# Makan Siang 30 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sebenarnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan
> oleh animasi.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, connection string, dan instrumentation key.

## Sebelum menekan tombol rekam

- Sekitar satu jam sebelum merekam, bangun seluruh lab dan biarkan datanya terkumpul (setup butuh sekitar 10 menit,
  solution sekitar 10 menit lagi):

  ```bash
  cd azure-fundamentals-lunches/labs/30-monitoring-advanced
  bash setup.sh
  bash solution.sh
  source ../common/config.sh && source lab.env
  nohup bash traffic.sh 45 > "$OUT_DIR/traffic.log" 2>&1 &
  ```

- Pastikan tabel-tabel sudah berisi baris (`bash verify.sh` mencetak jumlahnya di bagian akhir) dan bahwa
  `alert-slow-checkout` sudah berbunyi setidaknya sekali.
- Tab browser yang dibuka lebih dulu: `log-nusa` › *Tables*, *Monitor › Data Collection Rules* › `dcr-linux-nusa`,
  *Diagnostic settings* milik storage account, `log-nusa` › *Logs* (mode KQL), `appi-nusa-shop` › *Application map*,
  *Performance*, *Failures*, dan *Availability*, serta *Monitor › Alerts*.
- Tempel query yang akan Anda pakai ke sebuah file teks: solusi 1, 4, 8, dan 9 dari Lab 30, Tugas 6.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:20 Satu workspace, banyak tabel
00:55 Data VM: Azure Monitor Agent dan data collection rule
01:40 Platform log: diagnostic setting
02:05 KQL: dari ribuan baris menjadi satu grafik
03:15 Application Insights: performa, kegagalan, ketersediaan
04:30 Dari query menjadi alert
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 30 · Mengapa checkout lambat pada hari Jumat?" | "Jumat lalu checkout butuh empat detik, padahal semua grafik CPU tampak baik-baik saja. Dalam lima menit ke depan, kita kumpulkan buktinya di satu tempat dan biarkan data yang memutuskan siapa yang benar." |
| 00:20 | `log-nusa` › *Settings › Tables*: urutkan berdasarkan nama, tunjuk kolom *Plan* dan *Retention* untuk `AppRequests`, `Syslog`, dan `StorageBlobLogs` | "Log Analytics workspace ini adalah ruang bukti kita. Setiap sumber menulis ke tabelnya sendiri, dan setiap tabel punya plan dan masa retention — di situlah besar tagihan ditentukan." |
| 00:55 | VM › *Extensions + applications*: `AzureMonitorLinuxAgent`, Succeeded | "Di VM order job, Azure Monitor Agent terpasang sebagai extension. Ia masuk ke Azure Monitor dengan managed identity milik VM." |
| 01:10 | *Monitor › Data Collection Rules* › `dcr-linux-nusa` › *Data sources* (Syslog, minimum level Warning; Performance counters), lalu *Resources* (vm-nusa-app), lalu sekilas *JSON View* | "Agent tidak melakukan apa pun sampai sebuah data collection rule memberitahunya apa yang dikumpulkan dan ke mana mengirimnya: Syslog level warning ke atas, dan beberapa counter setiap menit. Rule ini berupa JSON biasa, jadi bisa disimpan di source control." |
| 01:40 | Storage account › *Monitoring › Diagnostic settings* › blob › `diag-blob-to-log-nusa`: *allLogs* ke `log-nusa` | "Platform log membutuhkan diagnostic setting. Yang satu ini mengirim setiap pembacaan dan penulisan blob ke workspace yang sama — gambar produk milik Dewi kini tercatat." |
| 02:05 | `log-nusa` › *Logs*, mode KQL: ketik solusi 1 (Heartbeat) lalu jalankan | "Sekarang saatnya bertanya. KQL dimulai dari sebuah tabel dan mengalirkan baris melalui operator. Apakah agent-nya hidup? Satu baris per komputer, terakhir terlihat semenit yang lalu." |
| 02:30 | Jalankan solusi 4 (timechart CPU dari Perf); arahkan kursor ke garis yang datar | "Apakah VM Pak Budi sibuk? CPU rata-rata dalam ember lima menitan — datar dan rendah. Tidak bersalah." |
| 02:50 | Susun solusi 8 langkah demi langkah: `AppRequests` (tunjukkan jumlah barisnya), tambahkan `where Name has "checkout"`, tambahkan `summarize … by bin`, tambahkan `render timechart` | "Perhatikan jumlah baris yang menyusut di setiap langkah, sampai yang tersisa hanya sebuah grafik. Median checkout cepat, tetapi persentil kesembilan puluh lima berada di sekitar tiga detik. Rata-rata akan menyembunyikan hal itu." |
| 03:15 | `appi-nusa-shop` › *Application map*: node storefront dengan laju request, durasi, dan tingkat kegagalan | "Application Insights mengumpulkan semua ini tanpa satu baris pun kode pemantauan — autoinstrumentation App Service, yang dibangun di atas OpenTelemetry." |
| 03:35 | *Performance* › `POST /checkout` › pilih sampel yang lambat di distribusi durasi › end-to-end transaction dengan trace warning | "Telusuri satu checkout yang lambat, dan Anda mendapatkan seluruh ceritanya: request-nya, dan warning yang dicatat kode — payment gateway butuh dua setengah detik." |
| 04:00 | *Failures* › `POST /checkout` › tipe exception `PaymentGatewayTimeout`; lalu *Availability*: hasil hijau standard test per lokasi | "Kegagalannya punya penyebab yang sama. Dan availability test memeriksa toko dari lima lokasi setiap lima menit — dari Singapura sampai Pantai Barat Amerika Serikat." |
| 04:30 | Kembali ke *Logs*: jalankan solusi 9 (join); lalu *Monitor › Alerts* › `alert-slow-checkout` berbunyi; buka kondisi rule-nya | "Satu join menyandingkan setiap checkout yang gagal dengan exception-nya: Rizky benar — penyedia pembayaran. Dan query yang sama, disimpan sebagai log search alert, kini memeriksa setiap lima menit dan melihat sepuluh menit ke belakang, agar baris yang terlambat tetap terhitung." |
| 05:15 | Slide rangkuman: satu workspace · tiga pipa (agent + DCR, diagnostic setting, Application Insights) · pipeline KQL · alert | "Tiga hal untuk diingat: rancang satu workspace dan pilih table plan Anda, hubungkan setiap sumber melalui pipa yang tepat, dan ubah query yang menemukan masalah menjadi alert yang menangkapnya lain kali. Lab-nya membangun semua itu." |

## Setelah merekam
- Tambahkan teks (caption): buat otomatis, lalu koreksi istilah Azure secara manual
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video di README makan siang (bagian 🎬 Demo)
- Hapus resource demo: `bash cleanup.sh` di `labs/30-monitoring-advanced`
