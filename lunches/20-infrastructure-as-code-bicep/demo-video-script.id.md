# Makan Siang 20 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman menulis dan men-deploy yang sesungguhnya — IntelliSense Bicep di VS Code, sebuah
> error kompilasi, output what-if, halaman Deployments, sebuah redeploy, dan deployment stack yang menolak penghapusan —
> yang hanya bisa disimulasikan oleh animasi.
> **Target durasi:** sekitar 5 menit 50 detik.
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah subscription perusahaan.
> **Sebelum merekam:** font editor 16 px atau lebih besar, minimap dimatikan, zoom browser 125–150%, profil browser yang
> bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan di layar:** ID subscription (muncul di scope what-if dan di ID resource — potong atau kaburkan), nama
> tenant, alamat email, serta object ID di pesan error.

## Sebelum menekan tombol rekam

- VS Code dengan extension **Bicep** terpasang, dan Azure CLI yang sudah login ke subscription demo (`az login`, lalu
  `az account show` untuk memastikan). Jika lebih suka, Cloud Shell juga bisa dipakai untuk bagian CLI.
- Sebuah resource group kosong yang dibuat sebelumnya:
  `az group create --name rg-lunch20-demo --location southeastasia --tags course=azure-fundamentals-lunches lunch=20`
- Salin `labs/20-infrastructure-as-code-bicep/starter/main.bicep` ke folder kerja sementara dan buka di VS Code. Biarkan
  `solution/main.bicep` terbuka di jendela kedua yang tidak Anda rekam, sebagai contekan.
- Sebuah terminal di folder kerja itu, sudah dibersihkan, dengan font besar.
- Satu tab portal di halaman **Deployments** milik resource group, dan satu lagi di **Settings › Deployment stacks**.

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:20 IntelliSense menuliskan NSG
01:15 Symbolic reference dan visualizer
01:50 Build — dan error kompilasi yang disengaja
02:25 what-if: empat resource akan dibuat
03:00 Deploy dan baca halaman Deployments
03:40 Redeploy, lalu ubah satu parameter
04:30 Deployment stack dengan DenyDelete
05:30 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 20 · Infrastructure as Code dengan Bicep" | "Sembilan belas makan siang penuh klik, dalam satu file. Dalam enam menit ke depan kita akan menulis sebagian file Bicep, melihat pratinjaunya, men-deploy-nya, mengubahnya, lalu melindunginya." |
| 00:20 | VS Code, `main.bicep` starter; gulir melewati parameter dan storage account yang sudah jadi sampai ke EXERCISE 1 | "File starter ini sudah berisi parameter dan sebuah storage account. Latihan pertama adalah network security group." |
| 00:35 | Ketik `resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {` dan terima saran IntelliSense untuk properti wajib; tambahkan aturan HTTP | "IntelliSense Bicep mengenal setiap jenis resource dan versi API. Ia menyarankan properti yang wajib diisi, dan memvalidasi nama properti saat saya mengetik — tidak perlu lagi menebak-nebak JSON." |
| 01:15 | Tambahkan virtual network dari contekan; arahkan kursor ke `nsgWeb.id`; buka Bicep visualizer | "Di virtual network, subnet web menunjuk ke nsgWeb.id. Symbolic reference itu saja sudah cukup bagi Bicep untuk men-deploy NSG lebih dulu. Visualizer menggambarkan dependensinya untuk Anda." |
| 01:50 | Terminal: ubah `nsgWeb.id` menjadi `nsgWbe.id`, jalankan `az bicep build --file main.bicep`; tunjukkan error-nya; perbaiki lalu build lagi | "Sebelum Azure melihat apa pun, saya mengompilasinya secara lokal. Salah ketik pada symbolic name adalah error, lengkap dengan nomor baris dan saran perbaikannya. Perbaiki, build lagi, dan kita mendapatkan main.json — template ARM yang dihasilkan Bicep." |
| 02:25 | `az deployment group what-if --resource-group rg-lunch20-demo --template-file main.bicep` | "What-if membandingkan file dengan apa yang sudah ada. Tanda plus berarti dibuat: empat resource, tidak ada hal lain yang tersentuh. Inilah yang seharusnya dilihat peninjau di setiap pull request." |
| 03:00 | `az deployment group create … --name lab20-main`; lalu halaman **Deployments** di portal: input, output, template | "Deploy. Resource Manager mengurutkan pekerjaan berdasarkan dependensi dan membuat resource yang tidak saling bergantung secara paralel. Halaman Deployments menyimpan template, parameter, dan output untuk setiap eksekusi." |
| 03:40 | Jalankan deploy yang sama sekali lagi; lalu what-if dengan `--parameters environment=test` | "Jalankan lagi: tidak ada yang berubah, karena deployment-nya idempoten. Sekarang ubah satu parameter. Setiap resource menampilkan tilde — modify, alias diubah — dan baris detailnya menunjukkan tag environment berubah dari lab menjadi test. Jika Anda melihat properti lain tercantum, bacalah: what-if bisa menampilkan nilai default sebagai noise." |
| 04:30 | `az stack group create --name stack-nusa-iac … --deny-settings-mode denyDelete --action-on-unmanage deleteResources --yes`; halaman **Deployment stacks** di portal | "Sekarang file yang sama sebagai deployment stack dengan DenyDelete. Stack mencantumkan resource yang dikelolanya dan memasang deny assignment pada resource-resource itu." |
| 04:55 | `az storage account delete --name <storage> --resource-group rg-lunch20-demo --yes`; tunjukkan `DenyAssignmentAuthorizationFailed` (kaburkan ID-nya) | "Bahkan sebagai Owner, penghapusan storage account ditolak oleh deny assignment milik stack. Untuk menghapus sesuatu, Anda mengubah file atau menghapus stack — dan itulah yang kita lakukan berikutnya." |
| 05:15 | `az stack group delete --name stack-nusa-iac --resource-group rg-lunch20-demo --action-on-unmanage deleteResources --yes` | "Menghapus stack dengan deleteResources ikut menghapus semua yang dikelolanya. File ini bisa membangunnya kembali dalam hitungan menit." |
| 05:30 | Slide rangkuman: tiga poin | "Tiga hal untuk diingat: file adalah sumber kebenaran; selalu jalankan what-if lebih dulu; dan deployment stack menambahkan pengelolaan siklus hidup serta perlindungan. Di Lab 20 Anda akan melengkapi file itu sendiri." |

## Setelah merekam
- Tambahkan takarir (caption) — buat otomatis, lalu koreksi istilah secara manual: Bicep, what-if, idempoten, deployment
  stack, DenyDelete
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: hapus stack-nya jika masih ada, lalu `az group delete --name rg-lunch20-demo --yes --no-wait`
