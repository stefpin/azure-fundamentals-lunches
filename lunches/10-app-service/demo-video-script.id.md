# Makan Siang 10 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** memperlihatkan pengalaman Azure yang sesungguhnya untuk makan siang ini — satu perintah yang mengubah
> sebuah folder berisi kode Python menjadi web app yang berjalan, konfigurasi tanpa mengubah kode, kesalahan yang
> ditemukan lewat log stream, dan slot staging yang di-swap ke production sementara sebuah poller (skrip yang terus
> memanggil halaman) mengawasi. Animasi hanya bisa menyimulasikan semua ini.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan dari layar:** ID subscription, nama tenant, alamat e-mail, dan alamat IP publik yang masih akan terus
> Anda pakai.

## Sebelum menekan tombol rekam

- Sekitar 25 menit sebelum merekam, siapkan sebuah **salinan "yang sudah disiapkan sebelumnya"** di Standard S1 dengan
  slot `staging` (💲💲 selama masih ada). Suffix yang berbeda membuatnya berada di resource group tersendiri,
  `rg-lunch10-<suffix>prep`:

  ```bash
  cd ~/azure-fundamentals-lunches/labs/10-app-service
  ( source ../common/config.sh && export SUFFIX="${SUFFIX}prep" && WITH_SLOT=1 bash solution.sh )
  # solution.sh ends with version 2.0 in production. Swap once more, so that production shows 1.0
  # and staging holds 2.0 for the swap on camera:
  ( source ../common/config.sh && export SUFFIX="${SUFFIX}prep" && source lab.env &&
    az webapp deployment slot swap -g "$RG" -n "$APP" --slot staging --target-slot production )
  ```

- Untuk aplikasi utama, jalankan hanya **Tugas 1** dari lab (`ensure_rg "$RG" 10` setelah kedua baris `source`).
  **Jangan** membuat web app-nya: `az webapp up` membuatnya di depan kamera (Tugas 2). Jika Anda sudah berlatih
  sebelumnya, jalankan `bash cleanup.sh` dan tunggu sampai `az group list --tag lunch=10 --output table` kosong, lalu
  buat lagi salinan yang sudah disiapkan tadi.
- Cloud Shell, sesi A (aplikasi utama): `cd ~/azure-fundamentals-lunches/labs/10-app-service`, kedua baris `source`,
  `cd app`, lalu `clear`.
- Cloud Shell, sesi B (salinan yang sudah disiapkan, lewat *Open new session*), siap untuk adegan swap:

  ```bash
  cd ~/azure-fundamentals-lunches/labs/10-app-service
  source ../common/config.sh && export SUFFIX="${SUFFIX}prep" && source lab.env
  HOST=$(az webapp show -g "$RG" -n "$APP" --query defaultHostName --output tsv)
  clear
  # paste on camera:  for i in $(seq 1 60); do curl -s -o /dev/null -w "%{http_code} " "https://$HOST/"; sleep 2; done
  ```

- Tab browser: (1) portal di resource group `rg-lunch10-<suffix>`; (2) salinan yang sudah disiapkan
  `app-nusa-<suffix>prep` › *Deployment slots*; (3) tab kosong untuk toko online.

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:25 Dari folder berisi kode menjadi aplikasi yang berjalan
01:20 App settings dan HTTPS Only
02:30 Rusak: baca log stream, lalu perbaiki
03:30 Plan, tier, dan scaling
04:20 Slot staging dan swap tanpa downtime
05:20 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 10 · Azure App Service — urus tokonya, bukan servernya" | "Dewi, developer Nusantara Retail, punya toko online Python yang kecil dan tidak punya waktu untuk mengurus server. Dalam enam menit ke depan, kita menayangkannya secara online dengan satu perintah, mengonfigurasinya tanpa menyentuh kode, menemukan kesalahan lewat log stream, lalu merilis versi 2 melalui slot staging sementara toko tetap buka." |
| 00:25 | Cloud Shell sesi A di `labs/10-app-service/app`: `ls`, lalu tempel perintah `az webapp up` dari Tugas 2 lab (`--sku F1 --runtime "$RUNTIME"`, yaitu `PYTHON:3.12`); peringatan deprecated berwarna kuning muncul | "Inilah seluruh aplikasinya: satu file Python dan satu file requirements. Dari folder ini, az webapp up membuat App Service plan Linux di tier Free, membuat web app dengan stack Python 3.12, men-zip folder ini, lalu men-deploy-nya. Baris kuning itu memberi tahu bahwa perintah ini sudah deprecated. Perintahnya masih berfungsi, dan lab juga menunjukkan perintah-perintah eksplisit penggantinya." |
| 00:55 | Percepat bagian menunggu (caption: "sekitar 4 menit kemudian"); ringkasan JSON; lalu `HOST=$(az webapp show -g "$RG" -n "$APP" --query defaultHostName --output tsv)` dan `curl -s "https://$HOST/health"` mencetak `ok` | "Di server, proses build menginstal Flask dan Gunicorn. Bagian itu yang lambat, jadi saya mempercepatnya. Endpoint health menjawab ok. Perhatikan apa yang tidak saya lakukan: tidak ada virtual machine, tidak ada patch sistem operasi, tidak ada server web yang harus dikonfigurasi." |
| 01:20 | Portal › `app-nusa-<suffix>` › *Overview*: status Running, default domain, plan `asp-nusa-<suffix>` di F1 (samarkan ID subscription); buka default domain di tab toko online: "Sorry, the shop is having a moment." | "Di portal, aplikasinya berjalan di plan Free. Mari kita buka… dan kita mendapat halaman error yang sopan. Kodenya perlu tahu toko mana dirinya, dan kita belum memberitahunya." |
| 01:40 | *Settings › Environment variables › App settings* › **+ Add** `STORE_NAME` = `Nusantara Retail - Kemang` › *Apply* › *Confirm*; refresh toko online: nama toko, **Version 1.0**, nama instance | "App settings sampai ke kode sebagai environment variable. Saya menambahkan STORE_NAME, menerapkannya, dan mengonfirmasi restart. Refresh: toko Kemang, versi 1.0, dan nama instance yang melayani saya. Kode yang sama bisa berjalan sebagai toko uji coba di tempat lain, tanpa build ulang." |
| 02:10 | *Settings › Configuration › General settings*: **HTTPS Only** On, **Minimum inbound TLS Version** 1.2 › *Save* | "Setiap aplikasi mendapat sertifikat untuk alamat azurewebsites.net-nya. HTTPS Only mengalihkan HTTP biasa ke HTTPS, dan versi TLS minimum tetap 1.2. Cukup satu sakelar, tanpa urusan sertifikat." |
| 02:30 | Sesi A: `az webapp log config -g "$RG" -n "$APP" --docker-container-logging filesystem --output none` dan `az webapp config appsettings delete -g "$RG" -n "$APP" --setting-names STORE_NAME --output none`; refresh toko online: halaman error lagi | "Pertama, saya mengaktifkan container logging, yang dibutuhkan aplikasi Linux untuk log stream. Sekarang mari kita rusak aplikasinya seperti yang terjadi di dunia nyata: seseorang merapikan konfigurasi dan menghapus setting yang tidak ia kenali. Toko menampilkan halaman error umumnya. Cukup baik bagi pelanggan, tetapi tidak membantu kita." |
| 02:55 | Portal › *Monitoring › Log stream*; refresh tab toko online dua kali; baris `ERROR [storefront] Required app setting STORE_NAME is missing` muncul | "Log stream menampilkan apa yang ditulis aplikasi, secara langsung. Refresh tokonya, dan itulah penyebabnya: setting wajib STORE_NAME hilang. Umum bagi pelanggan, spesifik di log: begitulah seharusnya penanganan error." |
| 03:15 | *Environment variables* › tambahkan kembali `STORE_NAME` › *Apply* › *Confirm*; refresh: toko online kembali | "Kembalikan setting-nya, konfirmasi restart, dan toko buka lagi. Pelajarannya: konfigurasi adalah bagian dari rilis, jadi perlakukan dengan kehati-hatian yang sama seperti kode." |
| 03:30 | Plan › *Scale up (App Service plan)*: telusuri tier dan daftar fiturnya; jangan pilih apa pun | "Semua yang bisa dilakukan aplikasi ini bergantung pada plan-nya. Free bersifat bersama dan dibatasi 60 menit CPU per hari. Basic memberi instance dedicated. Standard menambahkan autoscale dan deployment slot. Premium menambahkan perangkat keras yang lebih cepat dan instance yang lebih banyak. Saya hanya melihat-lihat: tidak ada yang berubah sampai Anda menerapkan tier baru." |
| 04:00 | Tab 2: salinan yang sudah disiapkan `app-nusa-<suffix>prep` di Standard S1 › *Scale out (App Service plan)*: opsi manual, automatic, dan rules-based; jangan simpan apa pun | "Untuk rilis, saya sudah menyiapkan sebuah salinan sebelumnya, di Standard S1. Scale out menawarkan jumlah instance manual, autoscale berbasis aturan pada metrik atau jadwal, dan automatic scaling, yang membutuhkan tier Premium." |
| 04:20 | *Deployment slots*: production dan `staging`, dengan persentase lalu lintasnya; buka kedua alamat berdampingan: production **Version 1.0**, staging **Version 2.0** | "Dewi sudah men-deploy versi 2 ke slot staging: aplikasi hidup di plan yang sama, dengan alamatnya sendiri. Staging menampilkan 2.0, production masih menampilkan 1.0. Pelanggan belum melihat apa-apa." |
| 04:45 | Sesi B: tempel poller; portal › *Swap*: source `staging`, target `production`; tampilkan daftar perubahan konfigurasi; konfirmasi (percepat bagian menunggu); refresh production: **Version 2.0**; sesi B hanya menampilkan `200` | "Di Cloud Shell kedua, sebuah poller meminta halaman production setiap dua detik. Sekarang, swap. Dialognya mencantumkan setting yang akan berubah. App Service lebih dulu melakukan warm-up versi 2 di setiap instance, baru kemudian mengalihkan routing. Production menampilkan 2.0, dan poller tidak mencetak apa pun selain 200. Kalau ada yang salah, swap yang sama adalah rollback-nya." |
| 05:20 | Slide rangkuman: "Plan-lah yang Anda bayar · Setting, bukan kode · Log stream lebih dulu · Rilis lewat slot" | "Tiga hal yang perlu diingat. Anda membayar plan, bukan aplikasinya. Simpan konfigurasi di app settings, dan baca log stream lebih dulu ketika ada yang rusak. Dan rilis lewat slot staging, agar versi baru tayang tanpa downtime. Lab akan memandu Anda melalui semuanya, termasuk bersih-bersihnya." |

## Setelah merekam
- Tambahkan teks (caption): buat otomatis, lalu koreksi istilah Azure secara manual: *App Service plan*, *Gunicorn*,
  *app settings*, *log stream*, *deployment slot*, *swap*.
- Tambahkan daftar chapter ke deskripsi video.
- Tempel link video ke README makan siang ini (bagian 🎬 Demo).
- Hapus resource demo: `bash cleanup.sh` di `labs/10-app-service` menghapus **kedua** resource group, karena keduanya
  membawa tag `lunch=10`. Periksa dengan `az group list --tag lunch=10 --output table` beberapa menit kemudian.
- Samarkan (blur) ID subscription di halaman *Overview* dan nama akun Anda di header portal jika terlihat.
