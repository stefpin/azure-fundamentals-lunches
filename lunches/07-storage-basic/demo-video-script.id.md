# Makan Siang 07 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sesungguhnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan oleh animasi.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan dari layar:** ID subscription, nama tenant, alamat email, dan alamat public IP yang masih akan Anda pakai.

## Sebelum menekan tombol rekam

- Sebuah resource group untuk rekaman, misalnya `rg-lunch07-video`, di Southeast Asia. Buat di Cloud Shell:
  `az group create --name rg-lunch07-video --location southeastasia --tags course=azure-fundamentals-lunches lunch=07`
- **Jangan** membuat storage account dulu — membuatnya adalah bagian dari video. Tentukan namanya lebih awal
  (misalnya `stnusavideo` ditambah beberapa karakter acak) dan pastikan nama itu masih tersedia:
  `az storage account check-name --name <your-name> --query nameAvailable`
- Tetapkan **Storage Blob Data Contributor** untuk diri Anda di resource group itu beberapa menit sebelum merekam, agar
  Storage browser dan user delegation SAS langsung berfungsi:
  `az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $(az ad signed-in-user show --query id -o tsv) --assignee-principal-type User --scope $(az group show -n rg-lunch07-video --query id -o tsv)`
- Dua file kecil di desktop Anda: `batik-shirt.svg` (gambar produk apa saja) dan `INV-2026-0001.txt` (teks pendek apa
  saja). Folder `labs/07-storage-basic/sample-files/` milik lab sudah berisi keduanya.
- Tab browser: Azure portal (sudah dalam keadaan masuk), dan sebuah **jendela private/incognito** untuk menguji tautan
  SAS.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:25 Membuat storage account yang aman
01:45 Container dan unggahan di Storage browser
02:45 Mengubah access tier blob (Cool dan Archive)
03:35 Membuat user delegation SAS
04:35 Membuka tautannya — dan melihatnya kedaluwarsa
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 07 · Storage — tur portal" | "Dalam lima menit ke depan, kita akan membuat storage account untuk Nusantara Retail, mengunggah satu gambar produk dan satu faktur, memindahkan keduanya antar-access tier, lalu membagikan satu file dengan aman lewat tautan yang bisa kedaluwarsa." |
| 00:25 | Portal › Storage accounts › **Create** › tab Basics | "Mulai dari Basics. Namanya harus unik di seluruh dunia — tiga sampai dua puluh empat huruf kecil dan angka — karena nama itu menjadi bagian dari URL. Region: Southeast Asia. Primary service: Azure Blob Storage. Performance: Standard. Redundancy: untuk demo ini saya memilih locally redundant storage; untuk toko online sungguhan, kita akan memilih zone-redundant." |
| 01:00 | Tab **Advanced**: *Require secure transfer* ✔, *Allow enabling anonymous access on individual containers* ☐, *Default to Microsoft Entra authorization in the Azure portal* ✔, *Minimum TLS version* 1.2, *Access tier* Hot | "Di tab Advanced, ada beberapa pengaturan yang penting hari ini. Secure transfer tetap aktif, akses anonim tetap mati, portal sebaiknya memakai identitas Entra saya alih-alih account key, dan minimum TLS version-nya 1.2. Access tier default-nya Hot — blob baru akan masuk ke sana kecuali kita menentukan lain." |
| 01:30 | **Review + create** › **Create**, lalu *Go to resource* | "Review, create — hanya butuh beberapa detik. Perhatikan bahwa halaman Overview mencantumkan endpoint terpisah untuk blob, file, queue, dan table: satu account, empat layanan." |
| 01:45 | Storage account › **Storage browser** › Blob containers › **+ Add container** `products` (Anonymous access level: Private) | "Storage browser adalah file explorer-nya portal. Saya membuat container bernama products. Anonymous access level-nya Private — dan memang tidak bisa yang lain, karena kita sudah mematikan akses anonim untuk seluruh account." |
| 02:10 | Di dalam `products`: **Upload** `batik-shirt.svg`; buat `invoices` lalu unggah `INV-2026-0001.txt` | "Unggah satu gambar produk… lalu container kedua, invoices, berisi satu faktur. Metode autentikasi di atas daftar bertuliskan *Microsoft Entra user account* — berkat kotak centang tadi, portal memakai data role saya, bukan account key." |
| 02:45 | Pilih faktur › **Change tier** › Archive › Save. Lalu pilih gambar › Change tier › Cool | "Faktur ini sudah ditutup, jadi masuk ke tier archive — tempat termurah untuk menyimpannya. Gambar produk musim lalu masuk ke cool. Kedua perubahan berlaku seketika kalau Anda pindah ke tier yang lebih dingin." |
| 03:15 | Coba **Download** faktur yang diarsipkan; tunjukkan pesannya. Buka lagi *Change tier* untuk menunjukkan pilihan rehydrate priority | "Sekarang coba unduh faktur yang diarsipkan: ditolak — blob archive bersifat offline. Untuk membacanya lagi, kita harus melakukan rehydrate, dengan prioritas standard yang bisa sampai lima belas jam, atau prioritas high yang sering kurang dari satu jam untuk file kecil. Menyalinnya ke blob baru menghindari biaya early deletion." |
| 03:35 | Pilih `batik-shirt.svg` › **Generate SAS**: Signing method *User delegation key*, Permissions *Read*, Expiry *sekarang + 1 jam*, Allowed protocols *HTTPS only* › **Generate SAS token and URL** | "Rizky, kontraktor kita, butuh gambar ini hari ini. Alih-alih menyerahkan account key, saya membuat SAS yang ditandatangani dengan user delegation key — itu identitas Entra saya, bukan storage key. Hanya baca, satu blob, satu jam, hanya HTTPS." |
| 04:10 | Salin **Blob SAS URL**; samarkan bagian `sig=` saat di-zoom | "URL ini membawa izin dan waktu kedaluwarsa di query string-nya, ditambah sebuah tanda tangan. Siapa pun yang memegang tautan ini bisa memakainya sampai kedaluwarsa, jadi perlakukan seperti kata sandi." |
| 04:35 | Tempel URL di jendela private → gambar muncul. Hapus query string lalu muat ulang → XML error | "Di jendela private — tanpa masuk sama sekali — tautannya berfungsi. Hapus bagian SAS lalu coba lagi: error, karena akses anonim mati. Persis itulah yang kita inginkan." |
| 04:55 | Kembali di Storage browser: buat SAS kedua yang kedaluwarsa dalam 1 menit (disiapkan sebelumnya), buka → `AuthenticationFailed` | "Dan ini SAS yang sudah kedaluwarsa semenit yang lalu: 403, authentication failed. Masa berlaku yang singkat membatasi kerugian kalau sebuah tautan bocor." |
| 05:15 | Slide rangkuman: tiga poin | "Tiga hal yang perlu diingat: redundansi menentukan kegagalan mana yang bisa Anda lewati; access tier menukar harga penyimpanan dengan harga akses, lengkap dengan masa simpan minimum; dan kalau berbagi, bagikan user delegation SAS yang berumur pendek — jangan pernah account key. Lab akan memandu Anda melakukan semua ini dengan CLI dan AzCopy." |

## Setelah merekam
- Tambahkan teks (caption): buat otomatis, lalu koreksi istilah Azure secara manual: *ZRS*, *AzCopy*, *SAS*, *rehydrate*, *Entra*
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: `az group delete --name rg-lunch07-video --yes --no-wait`
- Pastikan tidak ada URL SAS atau nama account yang masih akan Anda pakai yang terbaca di video final
