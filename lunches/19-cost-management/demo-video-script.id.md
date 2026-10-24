# Makan Siang 19 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Cost Management yang sesungguhnya — cost analysis yang dikelompokkan per layanan,
> resource group, dan tag, perburuan resource yatim di Resource Graph Explorer, tab cost di Advisor, dan pembuatan
> anggaran (budget) — bagian-bagian yang hanya bisa disimulasikan oleh animasi.
> **Target durasi:** sekitar 5 menit 45 detik.
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah subscription perusahaan. Gunakan
> subscription pay-as-you-go atau akun gratis; Azure for Students tidak didukung oleh Cost Management.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat email (termasuk penerima anggaran), detail billing
> account dan invoice, serta alamat IP publik yang masih akan Anda pakai.

## Sebelum menekan tombol rekam

- **Setidaknya sehari sebelumnya:** di Cloud Shell, jalankan `bash labs/19-cost-management/setup.sh` agar ketiga
  resource yatim ada cukup lama sehingga biaya pertamanya sampai ke Cost Management (biasanya 8–24 jam, hingga 72 jam
  untuk sebagian subscription pay-as-you-go). Pertahankan beberapa resource group lain yang bertag agar tampilan biaya
  punya sesuatu untuk ditunjukkan.
- Tentukan alias email demo untuk alert anggaran dan pastikan Anda bisa mengaburkannya saat penyuntingan.
- Buka tab-tab berikut terlebih dahulu:
  1. **Cost Management › Cost analysis** di scope subscription, pada smart view **Services**.
  2. **Resource Graph Explorer** dengan kueri kosong.
  3. **Advisor › Cost**.
  4. Resource group lab `rg-lunch19-<suffix>` › **Budgets**.
  5. [Azure pricing calculator](https://azure.microsoft.com/pricing/calculator/) dengan estimate kosong.
- Siapkan ketiga kueri resource yatim dari README lab agar tinggal ditempel.

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:25 Cost analysis: tagihan per layanan
01:10 Kelompokkan per resource group dan per tag
02:00 Berburu resource yatim di Resource Graph Explorer
02:55 Tab Cost di Advisor
03:25 Anggaran dengan alert 50/80/100%
04:40 Pay-as-you-go vs reservation satu tahun
05:25 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 19 · Manajemen Biaya" | "Dalam lima menit ke depan, kita akan membongkar sebuah tagihan Azure, memburu pemborosan di dalamnya, dan memasang alert supaya bulan depan tidak ada kejutan." |
| 00:25 | Cost analysis, scope subscription, smart view **Services**; tunjuk rentang tanggal dan angka totalnya | "Ini cost analysis untuk seluruh subscription. View Services mengelompokkan satu angka total per layanan: virtual machine, penyimpanan, jaringan. Perhatikan bahwa pemakaian hari ini belum ada di sini — data biaya datang secara berkelompok, biasanya 8 sampai 24 jam kemudian." |
| 00:55 | Buka baris layanan teratas untuk menampilkan meter-meternya | "Buka satu baris, dan Anda akan melihat meter-meter di baliknya: jam compute, kapasitas disk, transfer data. Setiap baris di invoice hanyalah jumlah dikali harga." |
| 01:10 | Beralih ke view **Resource groups**, lalu buka view yang bisa disesuaikan dan atur **Group by** ke tag `costCenter` | "Kelompokkan per resource group untuk melihat lingkungan mana menghabiskan berapa. Lalu kelompokkan per tag costCenter — inilah showback. Apa pun yang tidak bertag masuk ke keranjang untagged, dan itulah daftar pekerjaan untuk kebijakan tag Anda." |
| 01:45 | Simpan view-nya dan tunjukkan opsi **Share** | "Simpan view ini dan bagikan ke tim keuangan, supaya semua orang membaca angka yang sama di rapat bulanan." |
| 02:00 | Resource Graph Explorer: tempel kueri disk yang tidak terpasang, pilih **Run query** | "Data biaya tidak bisa memberi tahu apa yang ada saat ini; Resource Graph bisa. Kueri ini menampilkan setiap disk yang statusnya Unattached, di semua subscription yang bisa saya baca, dalam sekitar satu detik." |
| 02:25 | Jalankan kueri IP publik, lalu kueri App Service plan kosong | "Prinsip yang sama berlaku untuk IP publik tanpa IP configuration, dan untuk App Service plan dengan nol aplikasi. Tiga resource yatim, semuanya bertag retail-lab, semuanya masih ditagih." |
| 02:55 | Advisor › tab **Cost**; filter ke subscription demo | "Tab cost di Advisor menambahkan rekomendasi right-sizing, reservation, dan savings plan, ditambah pemeriksaan untuk disk yang tidak terpasang dan plan yang kosong. Aturan-aturan ini butuh riwayat berhari-hari, jadi pemborosan yang masih baru mungkin belum muncul — karena itulah kita juga berburu dengan Resource Graph." |
| 03:25 | Resource group lab › **Budgets** › **Add**; reset bulanan, jumlah, tanggal kedaluwarsa | "Sekarang pencegahan. Di resource group ini saya menambahkan anggaran bulanan. Jumlahnya dalam mata uang penagihan subscription." |
| 03:55 | **Alert conditions**: Actual 50, 80, 100 persen; tambahkan email (yang dikaburkan); sebutkan **Manage action group** | "Tiga alert biaya aktual pada 50, 80, dan 100 persen, dikirim ke para pemilik. Anggaran tidak pernah menghentikan resource — anggaran adalah alarm, bukan rem. Untuk tindakan otomatis, pasang action group yang menjalankan otomatisasi." |
| 04:25 | Pilih **Create**; tunjukkan anggaran di daftar | "Anggaran dievaluasi sekitar sekali sehari, jadi anggap ini sebagai peringatan dini, bukan meteran real-time." |
| 04:40 | Pricing calculator: tambahkan **Virtual machines**, region Southeast Asia, Linux, ukuran kecil; ubah **Savings options** dari pay as you go ke one-year reserved | "Terakhir, opsi pembelian. VM kecil yang sama, pay-as-you-go dibandingkan reservation satu tahun. Perhatikan selisih bulanannya — tetapi ingat urutannya: buang pemborosan dan sesuaikan ukuran dulu, berkomitmen paling akhir." |
| 05:25 | Slide rangkuman: tiga poin | "Tiga hal untuk diingat: data biaya tertinggal beberapa jam; Resource Graph menemukan pemborosan saat ini juga; anggaran adalah alarm, bukan rem. Di Lab 19 Anda akan melakukan semua ini sendiri — lalu menghapus pemborosannya." |

## Setelah merekam
- Tambahkan takarir (caption) — buat otomatis, lalu koreksi istilah Azure secara manual: Resource Graph, Advisor,
  savings plan, App Service plan
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: jalankan `bash labs/19-cost-management/cleanup.sh`, yang juga menghapus anggarannya
