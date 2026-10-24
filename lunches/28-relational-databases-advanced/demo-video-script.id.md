# Makan Siang 28 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menunjukkan pengalaman Azure yang sesungguhnya untuk makan siang ini — failover group di portal,
> listener-nya, sebuah planned failover, halaman point-in-time restore, serta pengaturan masking dan auditing. Animasi
> menjelaskan mekanismenya; video ini menunjukkan di mana semuanya berada.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail (akun Anda adalah **Microsoft Entra admin** di
> kedua server), alamat IP publik (firewall rule), dan kolom data pelanggan yang asli jika Anda memakai data Anda
> sendiri.

## Sebelum menekan tombol rekam

- Di Cloud Shell, jalankan titik awal lab setidaknya **40 menit** sebelum merekam, agar database sudah memiliki
  restore point: `cd azure-fundamentals-lunches/labs/28-relational-databases-advanced && bash setup.sh`
- Jalankan skrip masking sekali, agar halaman masking punya sesuatu untuk ditampilkan:
  `source ../common/config.sh && source azsql.sh && azsql "sql-nusa-main-${SUFFIX}.database.windows.net" sqldb-orders -i masking.sql`
- Putuskan apakah failover group dibuat secara langsung saat merekam (butuh beberapa menit seeding — potong waktu
  tunggunya saat editing) atau sebelumnya dengan perintah Tugas 3 dari lab.
- Tab browser yang sudah dibuka sebelumnya: *Overview* server utama (`sql-nusa-main-…`), *Overview* database
  `sqldb-orders`, dan Cloud Shell.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:30 Dua server di dua region
01:00 Membuat failover group
02:10 Dua nama listener
02:45 Planned failover dari portal
03:45 Point-in-time restore: restore point paling awal
04:30 Halaman masking dan auditing
05:20 Rangkuman
```

## Naskah per adegan

| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 28 · Pesanan yang selamat dari gangguan region" | "Ibu Sari bertanya berapa banyak pesanan yang akan hilang jika satu region gagal total. Dalam lima menit ke depan, kita siapkan jawabannya di portal: sebuah failover group, drill failover, dan tombol undo untuk kesalahan." |
| 00:30 | Daftar *SQL servers* yang difilter dengan `sql-nusa-`: satu server di Southeast Asia, satu di East Asia | "Kita mulai dengan dua logical server di dua region, keduanya dengan autentikasi Microsoft Entra-only. Database pesanan tinggal di server utama di Southeast Asia." |
| 01:00 | Server utama › *Data management › Failover groups* › **+ Add group** | "Failover group butuh nama yang unik secara global, karena nama itu akan menjadi nama DNS. Saya memilih server East Asia sebagai secondary." |
| 01:25 | Failover policy: **Customer managed**; pilihan database: `sqldb-orders` | "Failover policy tetap customer managed, sesuai saran Microsoft: kita yang memutuskan kapan failover. Saya tambahkan database pesanan, lalu membuat group-nya." |
| 01:50 | Halaman failover group: peta dengan kedua region; daftar database yang menunjukkan seeding, lalu tersinkron | "Azure melakukan seeding pada secondary, lalu terus mengalirkan perubahan. Peta menunjukkan region mana yang memegang primary." *(Potong waktu tunggu seeding.)* |
| 02:10 | Zoom ke **read/write listener endpoint** dan **read-only listener endpoint** | "Dua nama inilah yang dipakai aplikasi: read-write listener selalu mengarah ke primary, read-only listener ke secondary. Keduanya tidak pernah berubah, bahkan setelah failover." |
| 02:45 | Tombol **Failover** › dialog konfirmasi | "Sekarang sebuah drill. Planned failover menyinkronkan semuanya lebih dulu, lalu menukar peran, jadi tidak ada yang hilang. Beginilah wujud tes DR setiap kuartal." |
| 03:15 | Peta lagi: East Asia sekarang primary; pindah ke Cloud Shell dan jalankan query `@@SERVERNAME` dari Tugas 4 lewat read-write listener | "East Asia sekarang primary. Connection string-nya sama, server di belakangnya baru — itulah inti dari listener." |
| 03:45 | Database › *Overview* › **Restore** | "Replikasi juga menyalin kesalahan, jadi inilah tombol undo-nya. Point-in-time restore menampilkan restore point paling awal dan membiarkan saya memilih momen mana pun sejak saat itu." |
| 04:10 | Formulir restore: restore point, nama database baru; lalu **Cancel** | "Restore selalu membuat database baru di samping yang asli, jadi Anda bisa membandingkan dulu sebelum menyalin apa pun kembali. Database yang benar-benar baru belum punya restore point sampai backup pertamanya selesai." |
| 04:30 | Database › *Security › Dynamic Data Masking* | "Halaman masking menampilkan rule yang dibuat oleh skrip T-SQL kita: e-mail dan nomor telepon disamarkan bagi semua orang yang tidak punya permission UNMASK. Admin tetap melihat nilai aslinya." |
| 04:55 | Server › *Security › Auditing*: tujuan Storage, Log Analytics, Event Hub | "Auditing dikonfigurasi per server, jadi pasang di kedua server dalam failover group. Log Analytics adalah tempat termudah untuk mencari tahu siapa melakukan apa." |
| 05:20 | Slide rangkuman: zona · region · kesalahan | "Zone redundancy untuk zona yang gagal, failover group dengan listener untuk region yang gagal, point-in-time restore untuk manusia yang khilaf. Lab 28 memandu Anda melalui semuanya dari Cloud Shell." |

## Setelah merekam

- Tambahkan caption atau subtitel (buat secara otomatis, lalu koreksi istilah Azure secara manual: *failover group*,
  *listener*, *geo-secondary*, *Entra*)
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: `bash cleanup.sh` di folder lab (skrip ini menghapus failover group lebih dulu)
