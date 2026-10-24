# Makan Siang 01 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sesungguhnya untuk makan siang ini, yaitu bagian yang tidak bisa
> ditunjukkan oleh animasi: tur singkat portal, membuka Cloud Shell, meng-clone repositori kursus, dan membuat anggaran
> (budget) kursus.
> **Target durasi:** 5½ menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription demo pribadi atau khusus — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat email, dan alamat IP publik yang masih akan Anda pakai.

## Sebelum menekan tombol rekam

- Subscription demo tempat Anda menjadi Owner, dan **belum ada anggaran** (Anda membuatnya di depan kamera). Jika masih
  ada anggaran sisa gladi resik, hapus dulu: *Cost Management › Budgets › pilih anggarannya › Delete*.
- Cloud Shell sudah pernah diinisialisasi sekali (Bash, dengan persistent storage), supaya pertanyaan soal penyimpanan
  saat pertama kali dijalankan tidak memakan waktu rekaman. Cukup sebutkan pertanyaan itu di narasi.
- Belum ada hasil clone di Cloud Shell: jalankan `rm -rf ~/azure-fundamentals-lunches` sebelum merekam.
- Tab browser sudah dibuka sebelumnya: `https://portal.azure.com` (sudah login, MFA sudah selesai) dan repositori kursus
  di GitHub.
- Rencana blur: menu akun (kanan atas), ID subscription di `az account show`, dan alamat email yang Anda ketik di daftar
  penerima alert anggaran.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:20 Tur portal dua menit
01:40 Membuka Cloud Shell (Bash)
02:20 Clone file kursus dan periksa lingkungan Anda
03:20 Membuat anggaran bulanan dengan alert 50/80/100%
04:50 Membuat, memeriksa, dan menghapus resource group bertag
05:20 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 01 · Lab Azure, perkakas, dan pagar pengaman biaya Anda" | "Dalam lima menit ke depan, kita siapkan subscription lab untuk seluruh kursus: tur singkat portal, Cloud Shell, file kursus, dan anggaran yang memperingatkan kita sebelum pengeluaran lepas kendali." |
| 00:20 | Halaman beranda portal; tunjuk kotak pencarian | "Ini Azure portal. Kotak pencarian di bagian atas adalah jalan tercepat ke mana saja: layanan, resource, bahkan dokumentasi. Mari kita pakai." |
| 00:40 | Cari **Subscriptions** › buka subscription lab › **Overview** (blur ID-nya) | "Ini subscription lab saya. Halaman overview menunjukkan jenis penawarannya dan peran saya. Ini subscription pribadi — jangan pernah memakai subscription kantor untuk bereksperimen." |
| 01:05 | Cari **Resource groups** (daftarnya kosong) | "Resource group adalah 'folder'-nya Azure. Setiap lab di kursus ini memakai tepat satu resource group, jadi bersih-bersihnya cukup dengan satu kali hapus." |
| 01:20 | Cari **Cost Management** › tunjukkan menu kiri (Cost analysis, Budgets) | "Cost Management adalah tempat semua urusan uang. Ingat menu Budgets ini — dua menit lagi kita kembali ke sini." |
| 01:40 | Pilih ikon Cloud Shell `>_` di toolbar atas; pilih **Bash** | "Cloud Shell adalah terminal di dalam browser, sudah dalam keadaan login, dengan Azure CLI, PowerShell, Git, dan Bicep yang sudah terpasang. Pada kali pertama, ia menanyakan Bash atau PowerShell — kita pakai Bash — dan apakah perlu memasang penyimpanan. Persistent storage menyimpan file Anda dari sesi ke sesi; ephemeral session lebih cepat, tetapi melupakan semuanya." |
| 02:05 | Ketik `az account show --query "{subscription:name, state:state}" --output table` | "Kebiasaan pertama: periksa Anda sedang berada di subscription yang mana. Enabled, dan ini memang subscription lab. Bagus." |
| 02:20 | Ketik `git clone https://github.com/stefpin/azure-fundamentals-lunches.git` lalu `cd azure-fundamentals-lunches` | "Sekarang file kursusnya. Cukup satu kali clone, dan semua skrip lab sudah ada di sini." |
| 02:40 | Ketik `bash labs/common/check-environment.sh`; biarkan berjalan | "Skrip ini hanya membaca. Ia memeriksa region, apakah ukuran VM kecil yang dipakai lab tersedia untuk Anda, kuota vCPU Anda, dan resource group lab yang lupa Anda hapus." |
| 03:10 | Gulir ke "All … checks passed" | "Semuanya hijau. Kalau ada ukuran VM yang gagal di tempat Anda, jangan panik — lab-lab VM menjelaskan cara memilih ukuran lain." |
| 03:20 | Portal › **Cost Management › Budgets**; tunjuk **Scope** | "Kembali ke Budgets. Periksa scope-nya dulu: harus subscription, supaya anggaran ini mencakup semuanya." |
| 03:35 | **+ Add**: nama `budget-azure-lunches`, reset period **Monthly**, expiration setahun ke depan, jumlah yang kecil | "Nama, reset bulanan, tanggal kedaluwarsa yang masih jauh — anggaran yang kedaluwarsa akan dihapus — dan jumlah yang rela Anda keluarkan untuk belajar dalam sebulan." |
| 04:05 | **Next** › alert conditions: Actual 50, Actual 80, Actual 100, Forecasted 100; penerima (di-blur) › **Create** | "Alert di lima puluh, delapan puluh, dan seratus persen dari biaya aktual, ditambah satu alert prakiraan yang memperingatkan sebelum kita sampai ke sana. Penting: anggaran hanya mengirim email. Anggaran tidak pernah menghentikan apa pun." |
| 04:40 | Anggaran muncul di daftar | "Itu dia. Anggaran ini melindungi setiap lab mulai sekarang, jadi kita simpan." |
| 04:50 | Cloud Shell: `cd labs/01-before-you-begin && source ../common/config.sh && RG=$(rg_name 01) && ensure_rg "$RG" 01` lalu `az group show --name "$RG" --query tags` | "Terakhir, ritme lab: buat resource group bertag, lihat tag-nya…" |
| 05:05 | `az group delete --name "$RG" --yes` lalu `az group exists --name "$RG"` → `false` | "…lalu hapus. Menghapus group berarti menghapus semua isinya." |
| 05:20 | Slide rangkuman: tiga poin | "Tiga hal yang perlu diingat: pakai subscription lab Anda sendiri; setiap perkakas berbicara dengan Azure Resource Manager; dan anggaran adalah alarm, bukan rem — kebiasaan bersih-bersih ada di tangan Anda. Sampai jumpa di Lab 01." |

## Setelah merekam
- Tambahkan subtitle (caption): buat otomatis, lalu koreksi istilah Azure secara manual: Cloud Shell, Azure Resource
  Manager, Cost Management.
- Tambahkan daftar chapter ke deskripsi video.
- Tempel tautan video ke README makan siang ini (bagian 🎬 Demo).
- Hapus resource demo. Simpan atau hapus anggaran demo, tergantung apakah subscription itu masih dipakai untuk rekaman
  lain.
