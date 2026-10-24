# Makan Siang 24 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sesungguhnya untuk makan siang ini — bagian yang tidak bisa ditampilkan
> animasi.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan dari layar:** ID subscription, nama tenant, alamat e-mail, alamat IP publik yang akan terus Anda pakai.

## Sebelum menekan tombol rekam

Jalankan ini di Cloud Shell (Bash) sekitar 15 menit sebelum merekam. Perintah ini membuat sebuah account,
virtual network, dan private endpoint beserta private DNS zone-nya; container dan dua fakturnya Anda tambahkan lewat
portal sesudahnya (lihat daftar di bawah). Pilih nama account Anda sendiri
dan pastikan masih tersedia dengan `az storage account check-name --name <name> --query nameAvailable`.

```bash
RG=rg-lunch24-video; LOC=southeastasia; ST=stnusavid24abc   # change ST to your own free name
az group create -n $RG -l $LOC --tags course=azure-fundamentals-lunches lunch=24 -o none
az storage account create -n $ST -g $RG -l $LOC --kind StorageV2 --sku Standard_LRS \
  --min-tls-version TLS1_2 --allow-blob-public-access false -o none
ST_ID=$(az storage account show -n $ST -g $RG --query id -o tsv)
az role assignment create --role "Storage Blob Data Contributor" --assignee-principal-type User \
  --assignee-object-id $(az ad signed-in-user show --query id -o tsv) --scope $ST_ID -o none
az network vnet create -g $RG -n vnet-video --address-prefixes 10.24.0.0/16 \
  --subnet-name snet-pe --subnet-prefixes 10.24.2.0/24 -o none
az network private-endpoint create -g $RG -n pe-video-blob --vnet-name vnet-video --subnet snet-pe \
  --private-connection-resource-id $ST_ID --group-id blob --connection-name pec-video-blob -o none
az network private-dns zone create -g $RG -n privatelink.blob.core.windows.net -o none
az network private-dns link vnet create -g $RG -z privatelink.blob.core.windows.net -n link-vnet-video \
  -v vnet-video --registration-enabled false -o none
az network private-endpoint dns-zone-group create -g $RG --endpoint-name pe-video-blob -n default \
  --private-dns-zone privatelink.blob.core.windows.net --zone-name blob -o none
```

- Di portal, buka halaman **Configuration** milik account dan setel *Default to Microsoft Entra authorization in the
  Azure portal* ke **Enabled**, agar Storage browser memakai role data Anda.
- Buat container `invoices` dan unggah dua file teks pendek, `INV-2026-0042.txt` dan `INV-2026-0043.txt`
  (keduanya ada di folder `labs/24-storage-advanced/sample-files/` milik lab). Siapkan file kedua bernama
  `INV-2026-0042.txt` di desktop Anda, yang satu-satunya barisnya berbunyi `ENCRYPTED BY RANSOMWARE`.
- Tab browser: halaman **Data protection** milik storage account, dan private DNS zone
  `privatelink.blob.core.windows.net`.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:20 Mengaktifkan perlindungan data
01:05 Menimpa faktur, lalu memulihkan versinya
01:55 Menghapus faktur dan mengembalikannya
02:35 Aturan lifecycle sepuluh tahun
03:20 Time-based retention, unlocked
04:10 Private endpoint, private DNS, dan public access dimatikan
05:25 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 24 · Faktur tahan ransomware — tur portal" | "Semalam ransomware menyerang salah satu pemasok Nusantara Retail. Dalam lima menit ke depan, kita akan memastikan faktur kita sendiri bisa dipulihkan, tidak bisa diutak-atik, murah selama sepuluh tahun, dan hanya bisa dijangkau dari jaringan kita sendiri." |
| 00:20 | Storage account › **Data management › Data protection**. Centang *Enable versioning for blobs*, *Enable soft delete for blobs* (14 hari), *Enable soft delete for containers* (14 hari), *Enable blob change feed*. Tunjuk *Enable point-in-time restore for containers* tanpa mencentangnya › **Save** | "Perlindungan data cukup satu halaman. Versioning menyimpan setiap salinan lama sebuah blob. Soft delete menyimpan blob dan container yang terhapus selama empat belas hari. Change feed mencatat setiap perubahan. Point-in-time restore dibangun di atas ketiganya — perhatikan bahwa ia akan mengaktifkan ketiganya untuk Anda — tetapi kali ini kita biarkan nonaktif, karena ia tidak bisa digabungkan dengan immutability policy yang akan kita tambahkan nanti." |
| 01:05 | **Storage browser** › `invoices` › **Upload** `INV-2026-0042.txt` versi ransomware dengan *Overwrite if files already exist* dicentang. Buka blob › **Edit** untuk menunjukkan baris `ENCRYPTED BY RANSOMWARE` | "Sekarang saya berperan sebagai penyerang dan menimpa faktur empat puluh dua dengan sampah. Tanpa versioning, aslinya pasti hilang." |
| 01:30 | Blob › tab **Versions**: dua versi, yang terbaru ditandai current. Pilih yang lebih lama › **Make current version**. Buka lagi blob: teks aslinya kembali | "Tab Versions menampilkan isi lama dengan version ID-nya sendiri. Make current version menyalinnya ke atas blob — fakturnya kembali, dan salinan terenkripsi menjadi sekadar versi lama yang bisa kita bersihkan nanti." |
| 01:55 | Hapus `INV-2026-0043.txt`. Aktifkan **Show deleted blobs**: file itu muncul lagi dengan tanda *Deleted*. Buka › **Versions** › pilih versi terbaru › **Make current version** | "Hapus faktur empat puluh tiga — hilang dari daftar. Aktifkan Show deleted blobs, dan itu dia. Dengan versioning aktif, penghapusan hanya mengubah versi saat ini menjadi versi sebelumnya, jadi cara memulihkannya sama seperti tadi." |
| 02:35 | Storage account › **Lifecycle management** › **Add a rule**: nama `invoices-ten-years`, batasi ke block blob dengan prefix `invoices/`. Di *Base blobs*: cool setelah 30 hari, cold setelah 90, archive setelah 365, delete setelah 3.650. Beralih ke **Code view** | "Tidak ada yang mau memindahkan tier faktur sepuluh tahun secara manual. Aturan lifecycle mengerjakannya: cool setelah tiga puluh hari, cold setelah sembilan puluh, archive setelah setahun, hapus setelah sepuluh tahun. Code view menampilkan aturan yang sama dalam bentuk JSON — itulah file yang Anda deploy di lab. Aturan berjalan sekali sehari dan bisa memerlukan hingga satu hari untuk mulai bekerja." |
| 03:20 | Buat container `invoices-2025`, unggah satu file. Container › **Access policy** › *Immutable blob storage* › **Add policy**: *Time-based retention*, 1 hari › Save. Status menunjukkan **Unlocked** | "Tahun pajak yang sudah ditutup mendapat kunci yang lebih kuat. Pada container baru ini saya menambahkan time-based retention policy — satu hari untuk demo, sepuluh tahun di dunia nyata. Kebijakan ini dimulai dalam keadaan unlocked, yang memang untuk pengujian." |
| 03:45 | Coba **Delete** blob di `invoices-2025` → notifikasi error tentang immutability policy. Buka menu **…** milik kebijakan dan tunjuk **Lock policy** tanpa mengkliknya | "Coba hapus fakturnya: ditolak, padahal saya pemilik semua resource di sini. Di produksi, sekarang Anda akan mengunci kebijakan ini — setelah itu ia hanya bisa diperpanjang, dan tidak ada yang bisa menghapus faktur-faktur ini atau account-nya sampai periodenya berakhir. Kita tidak menguncinya, supaya bisa bersih-bersih nanti." |
| 04:10 | Storage account › **Security + networking › Networking** › tab *Private endpoints*: `pe-video-blob`, status **Approved**. Klik sampai ke network interface-nya: IP privat 10.24.2.4 | "Saya sudah membuat private endpoint sebelum merekam. Endpoint ini memberi layanan blob milik account sebuah alamat IP privat di dalam virtual network kita, dan karena saya pemilik kedua sisinya, koneksinya disetujui otomatis." |
| 04:35 | Tab private DNS zone: A record `<account>` → 10.24.2.4; *Virtual network links* menampilkan `link-vnet-video` | "Private DNS zone menyimpan A record yang sepadan, dan zona ini tertaut ke virtual network. Di dalam jaringan itu, nama blob yang biasa kini diterjemahkan ke IP privat; di tempat lain, nama itu tetap mengarah ke IP publik." |
| 04:55 | Networking › *Firewalls and virtual networks*: **Public network access** › **Disabled** › Save. Kembali ke Storage browser › `invoices` → error tentang akses jaringan | "Langkah terakhir: tutup pintu publik. Public network access: Disabled. Dan lihat — bahkan saya tidak bisa lagi menelusuri blob dari portal, karena browser saya ada di internet, bukan di virtual network. Itulah sebabnya Anda menyelesaikan semua tugas data plane sebelum menekan sakelar ini." |
| 05:25 | Slide rangkuman: tiga poin | "Tiga hal untuk diingat: versioning dan soft delete membatalkan penimpaan dan penghapusan, dan immutability policy yang terkunci mencegahnya sama sekali; aturan lifecycle mengurus tiering selama sepuluh tahun secara gratis; dan private endpoint baru berfungsi jika DNS zone-nya tertaut — barulah Anda bisa mematikan public access. Lab-nya mengerjakan semua ini dari CLI dan menguji DNS dari sebuah VM." |

## Setelah merekam
- Tambahkan teks/caption (buat otomatis, lalu koreksi istilah Azure secara manual: *soft delete*, *change feed*,
  *WORM*, *privatelink*, *Entra*)
- Tambahkan daftar chapter ke deskripsi video
- Tempelkan tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo. Immutability policy-nya masih unlocked, jadi resource group bisa langsung dihapus:
  `az group delete --name rg-lunch24-video --yes --no-wait`. Jika penghapusan tetap gagal, hapus dulu kebijakannya
  (`invoices-2025` › **Access policy** › **…** › **Delete**) lalu coba lagi.
- Pastikan tidak ada nama account atau private DNS record yang akan terus Anda pakai yang terbaca di video final
