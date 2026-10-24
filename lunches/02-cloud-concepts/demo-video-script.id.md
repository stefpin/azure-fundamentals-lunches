# Makan Siang 02 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sesungguhnya untuk makan siang ini, yaitu bagian yang tidak bisa
> ditunjukkan oleh animasi: memakai Azure pricing calculator untuk membandingkan desain berbasis VM (IaaS) dengan desain
> PaaS untuk toko online Nusantara Retail.
> **Target durasi:** 5½ menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** profil browser yang tidak login ke akun perusahaan. Kalkulator tidak membutuhkan subscription; jika Anda
> login untuk menyimpan estimasi, gunakan akun demo pribadi atau khusus — jangan pernah akun perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat email, dan alamat IP publik yang masih akan Anda pakai.

## Sebelum menekan tombol rekam

- Buka `https://azure.microsoft.com/pricing/calculator/` dan, jika estimasi lama ikut termuat, pilih **Reset now** atau
  kosongkan estimasinya supaya Anda mulai dari nol.
- Pilih mata uang yang akan Anda pakai untuk seluruh video, dan jangan diganti.
- Siapkan kartu kebutuhan Lab 02 (Tugas 1 di lab) di tab kedua untuk sesekali dilirik.
- Putuskan sejak awal untuk tidak membacakan harga: harga berubah dan berbeda menurut region. Bicarakan baris *mana* yang
  lebih besar dan *mengapa*, bukan angka pastinya.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:20 Tur singkat pricing calculator
01:00 Desain A: lift and shift ke virtual machine
02:40 Desain B: App Service dan Azure SQL Database
04:00 Opsi penghematan dan region kedua
05:00 Ekspor, bagikan, dan apa yang tidak terlihat oleh kalkulator
05:30 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 02 · Menghitung harga dua desain untuk toko online" | "Ibu Sari ingin tahu berapa biaya memindahkan toko online ke Azure. Dalam lima menit, kita hitung harga dua desain secara berdampingan: virtual machine, dan layanan platform." |
| 00:20 | Beranda kalkulator: tab **Products**, kotak pencarian, area **Your estimate** | "Pricing calculator ini gratis dan tidak membutuhkan akun Azure. Cari produk, tambahkan, lalu konfigurasikan di Your estimate. Pilih satu mata uang di awal, dan jangan diganti." |
| 00:45 | Tunjuk kolom **Region** pada sebuah item | "Setiap item punya region sendiri. Data pelanggan Nusantara sebaiknya tetap di Indonesia, jadi kita pakai Indonesia Central. Kalau ada yang tidak tersedia di sana, kita catat dan pakai Southeast Asia." |
| 01:00 | Tambahkan **Virtual Machines**: Linux, Standard, D2s v5, 2 VM, 730 jam, pay as you go | "Desain A adalah lift and shift. Dua web server, karena satu server adalah persis masalah yang sedang kita selesaikan. Masing-masing dua vCPU dan delapan gigabyte, menyala sepanjang bulan: 730 jam." |
| 01:40 | Item yang sama: managed disk Premium SSD P6 | "Setiap VM butuh OS disk. Premium SSD untuk web server." |
| 01:55 | Tambahkan item **Virtual Machines** kedua: D4s v5, 1 VM; tambahkan **Managed Disks** P15 | "Database mendapat VM sendiri yang lebih besar, plus data disk 256 gigabyte. Di VM, memasang, mem-patch, dan mem-backup database itu adalah tugas kita sendiri." |
| 02:20 | Tambahkan **Load Balancer** (Standard) dan **Bandwidth** (100 GB keluar) | "Load balancer Standard membagi trafik ke dua web server, dan bandwidth menghitung data yang dikirim ke pelanggan. Perhatikan betapa banyak baris yang dibutuhkan IaaS." |
| 02:40 | Gulir ke bawah: tambahkan **App Service**: Linux, Premium v3, P1v3, 2 instance, 730 jam | "Desain B adalah PaaS. Sama-sama dua instance dengan dua vCPU dan delapan gigabyte, tetapi kini Microsoft yang menjalankan sistem operasi dan web server di bawahnya." |
| 03:15 | Tambahkan **Azure SQL Database**: single database, vCore, General Purpose, provisioned, 2 vCore, 256 GB | "Database-nya menjadi Azure SQL Database: patching, ketersediaan tinggi, dan backup sudah menjadi bagian dari layanannya." |
| 03:45 | Tambahkan **Bandwidth** (100 GB) untuk Desain B; bandingkan subtotalnya | "Bandwidth yang sama, supaya perbandingannya adil. Lebih sedikit item, dan lebih sedikit hal yang harus diurus Pak Budi pukul dua dini hari." |
| 04:00 | Pada item VM web, ubah **Savings options** ke komitmen 1 tahun; perhatikan angka bulanannya | "Beban kerja yang stabil dan menyala 24 jam adalah kandidat yang baik untuk komitmen satu atau tiga tahun. Bandingkan apel dengan apel: jika Anda memberi diskon pada satu desain, cari opsi yang sama di desain lainnya." |
| 04:30 | Ubah region salah satu item ke Southeast Asia, lalu kembalikan | "Harga berbeda menurut region. Penghematan kecil di tempat lain harus ditimbang dengan keharusan menyimpan data di Indonesia." |
| 05:00 | Pilih **Export** (spreadsheet) dan **Share** | "Ekspor estimasinya untuk tim keuangan, atau bagikan tautannya. Dan ingat apa yang tidak terlihat oleh kalkulator: jam kerja tim Anda untuk patching, backup, dan bangun tengah malam." |
| 05:30 | Slide rangkuman: tiga poin | "Tiga hal yang perlu diingat: hitung kedua desain dengan kebutuhan yang sama; bandingkan apel dengan apel; dan hitung juga waktu orang, bukan hanya tagihannya. Giliran Anda di Lab 02." |

## Setelah merekam
- Tambahkan subtitle (caption): buat otomatis, lalu koreksi istilah Azure secara manual: App Service, Azure SQL
  Database, Premium v3, vCore.
- Tambahkan daftar chapter ke deskripsi video.
- Tempel tautan video ke README makan siang ini (bagian 🎬 Demo).
- Tidak ada yang perlu dihapus di Azure: kalkulator tidak membuat resource. Kosongkan atau hapus estimasi demo jika Anda
  sempat menyimpannya.
