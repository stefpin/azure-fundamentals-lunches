# Makan Siang 03 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menunjukkan pengalaman Azure yang sesungguhnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan
> oleh animasi: menemukan region dan pasangannya, memeriksa apakah sebuah layanan tersedia di suatu region, dan pilihan
> zona yang Anda temui saat membuat resource.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema bawaan.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, alamat IP publik yang akan terus Anda pakai.

## Sebelum menekan tombol rekam

- Tidak ada yang perlu disiapkan di Azure. Anda berhenti di setiap halaman "Create" di portal **sebelum** langkah
  Review + create, sehingga rekaman ini tidak membuat resource apa pun dan tidak menimbulkan biaya.
- Buka tab-tab browser berikut terlebih dahulu:
  1. [Daftar region Azure](https://learn.microsoft.com/azure/reliability/regions-list) (dengan tab Asia Pacific terpilih).
  2. [Produk yang tersedia per region](https://azure.microsoft.com/en-us/explore/global-infrastructure/products-by-region/).
  3. Azure portal › **Create a virtual machine** (tab Basics), sudah masuk ke subscription demo.
  4. Azure portal › **Create public IP address**.
  5. Azure portal › **Create a storage account** (tab Basics).
  6. Azure Cloud Shell (Bash) dengan repositori yang sudah di-clone dan `source labs/common/config.sh` yang sudah
     dijalankan, sehingga perintah-perintah region tinggal satu ketukan. Bersihkan layar setelahnya (`clear`).
- Opsional: di Cloud Shell, jalankan `az account list-locations --output none` sekali sebelum merekam agar perintah
  sungguhan yang pertama menjawab dengan cepat.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:25 Region, geografi, dan pasangan di daftar region
01:15 Apakah layanan saya tersedia di region ini?
02:05 Pilihan zona saat membuat VM
03:05 Pilihan zona untuk public IP dan storage account
04:05 Pasangan dan pemetaan zona dari Cloud Shell
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 03 · Region, zona, dan pasangan di portal sungguhan" | "Dalam lima menit ke depan, kita akan melihat di mana resource Azure sebenarnya tinggal: region, availability zone, dan region pair, serta di mana pilihan-pilihan itu muncul saat Anda membuat sesuatu." |
| 00:25 | Halaman daftar region, tab Asia Pacific. Tunjuk baris Indonesia Central, Southeast Asia, dan East Asia. | "Ini daftar region dari Microsoft. Indonesia Central di Jakarta punya tiga availability zone dan tidak punya region pasangan. Southeast Asia di Singapura juga punya tiga zona, dan pasangannya adalah East Asia di Hong Kong. Perhatikan kolom geografi: Jakarta ada di geografi Indonesia, sedangkan Singapura dan Hong Kong di Asia Pacific." |
| 00:55 | Gulir ke region yang bertanda N/A di kolom paired region (misalnya Malaysia West). | "Banyak region yang lebih baru menampilkan N/A di sini. Tanpa pasangan bukan berarti tanpa pemulihan bencana. Artinya, Anda sendiri yang memilih region kedua." |
| 01:15 | Halaman products-by-region. Pilih Indonesia Central dan Southeast Asia, lalu cari layanan seperti Azure Container Apps. | "Sebelum memutuskan sebuah region, pastikan setiap layanan yang Anda butuhkan tersedia di sana. Di sini saya membandingkan Jakarta dan Singapura untuk satu layanan. Region yang lebih baru bisa dimulai dengan katalog yang lebih kecil." |
| 01:45 | Halaman yang sama, cari layanan kedua yang akan Anda pakai (misalnya Azure Cosmos DB). | "Lakukan ini untuk setiap layanan dalam desain Anda, termasuk tier dan ukurannya yang spesifik, bukan hanya nama produknya." |
| 02:05 | Portal › Create a virtual machine › Basics. Buka dropdown **Region** dan ketik "Asia". | "Dropdown region mengelompokkan region per geografi. Saya pilih Southeast Asia." |
| 02:25 | Dropdown **Availability options**: tunjukkan "Availability zone" dan pemilih zonanya. Pilih zona 1 dan 2 jika portal menyediakan pilihan ganda. | "Inilah pilihan zonal. Sebuah VM selalu tinggal di tepat satu zona. Kalau portal membolehkan saya memilih beberapa zona, portal hanya membuat satu VM per zona. Begitulah cara menyebar web server agar kegagalan satu zona tidak menjatuhkan toko." |
| 02:50 | Ubah **Size** › "See all sizes". Arahkan kursor ke ukuran yang tidak tersedia di suatu zona, jika ada. | "Ukuran VM bisa berbeda per region, bahkan per zona. Kalau sebuah ukuran berwarna abu-abu, itulah alasannya. Sekarang saya tinggalkan halaman ini tanpa membuat apa pun." |
| 03:05 | Portal › Create public IP address. Tunjukkan **SKU: Standard** dan pengaturan **Availability zone** beserta pilihannya. | "Untuk public IP, pilihan zonanya berbeda. Standard kini satu-satunya SKU; Basic sudah dipensiunkan pada September 2025. Saya bisa mematok alamat ini ke satu zona, sehingga menjadi zonal, atau menjadikannya zone-redundant agar tetap bertahan saat zona mana pun gagal." |
| 03:35 | Portal › Create a storage account › dropdown **Redundancy**: LRS, ZRS, GRS, GZRS. | "Storage menunjukkan gagasan yang sama dalam bentuk pilihan redundansi. Locally redundant menyimpan tiga salinan di satu pusat data. Zone-redundant menyimpan salinan di tiga zona. Opsi geo menyalin ke region pasangan, itulah sebabnya Anda tidak akan menemukannya di region tanpa pasangan." |
| 04:05 | Cloud Shell: `az account list-locations --query "[?contains(['indonesiacentral','southeastasia','eastasia'], name)].{region:name, geography:metadata.geography, pair:metadata.pairedRegion[0].name}" -o table` | "CLI menampilkan fakta yang sama. Pasangan Southeast Asia adalah East Asia. Indonesia Central tidak punya pasangan." |
| 04:40 | Cloud Shell: `az account list-locations --query "[?name=='southeastasia'].availabilityZoneMappings \| [0]" -o table` | "Dan ini sesuatu yang disembunyikan portal: pemetaan zona logis ke zona fisik di subscription saya. Zona 1 saya bisa jadi gedung yang berbeda dengan zona 1 Anda." |
| 05:15 | Slide rangkuman dengan tiga poin: residensi → region → zona; zonal vs zone-redundant; pasangan tidak menyalin data Anda. | "Tiga hal yang perlu diingat. Pilih region dengan sengaja: residensi, latensi, layanan, harga, zona, dan pemulihan. Ketahui apakah setiap resource itu zonal atau zone-redundant. Dan region pair tidak pernah menyalin data Anda kecuali Anda menyalakan fitur yang melakukannya. Di Lab 03, Anda akan mencoba semuanya sendiri." |

## Setelah merekam
- Tambahkan teks (caption): buat otomatis, lalu koreksi istilah Azure secara manual: "zonal", "zone-redundant",
  "Indonesia Central", "availability zone", "LRS", "ZRS"
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Tutup halaman "Create" di portal tanpa membuat apa pun; pastikan di **Resource groups** bahwa tidak ada yang baru
