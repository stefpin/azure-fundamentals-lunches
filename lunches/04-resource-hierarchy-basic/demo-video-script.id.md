# Makan Siang 04 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menunjukkan pengalaman Azure yang sesungguhnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan
> oleh animasi: menelusuri management group, subscription, dan resource group di portal, membaca resource ID, serta
> bekerja dengan tag, lock, dan Resource Graph Explorer.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema bawaan.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, alamat IP publik yang akan terus Anda pakai.
> Dalam video ini, itu termasuk **resource ID** (karena memuat ID subscription) dan **ID Tenant root group** (karena
> sama dengan ID tenant): samarkan saat mengedit, atau atur zoom agar keduanya tidak tampil di layar.

## Sebelum menekan tombol rekam

- Di Cloud Shell (Bash), dari root repositori, buat resource group kecil yang bertag beserta sebuah storage account
  untuk ditunjukkan:

  ```bash
  source labs/common/config.sh
  RG_VIDEO=$(rg_name 04 video)
  ensure_rg "$RG_VIDEO" 04
  az tag update --resource-id "$(az group show --name "$RG_VIDEO" --query id --output tsv)" \
    --operation Merge --tags costCenter=ecommerce env=lab --output none
  az storage account create --name "stnusavid${SUFFIX}" --resource-group "$RG_VIDEO" --location "$LOCATION" \
    --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false --output none
  ```

- Buka tab-tab browser berikut terlebih dahulu:
  1. Azure portal › **Management groups** (cukup dilihat; Anda tidak membuat apa pun di video ini).
  2. Azure portal › **Resource groups** › `rg-lunch04-video-<suffix>`.
  3. Azure portal › **Resource Graph Explorer**.
- Hapus resource-nya setelah merekam (lihat bagian terakhir).

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:20 Management group dan Tenant root group
01:10 Subscription, resource group, dan ID sebuah resource
02:10 Tag: di grup, bukan di resource
03:05 Lock: Delete dan Read-only beraksi
04:20 Resource Graph Explorer
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 04 · Hierarki resource di portal sungguhan" | "Dalam lima menit, kita akan menyusuri hierarki Azure di portal, membongkar sebuah resource ID, dan melihat tag, lock, serta Resource Graph menjalankan tugasnya." |
| 00:20 | Portal › Management groups. Tunjuk **Tenant root group** dan subscription di bawahnya (ID disamarkan). | "Setiap tenant punya satu Tenant root group. ID-nya sama dengan ID tenant, itulah sebabnya saya menyamarkannya. Subscription masuk ke sini secara bawaan. Di perusahaan, Anda akan membangun management group di bawahnya, misalnya produksi dan nonproduksi, tetapi itu perubahan di tingkat tenant, jadi di lab pribadi ini saya hanya melihat." |
| 00:50 | Klik subscription › **Resource groups**. | "Satu tingkat di bawahnya ada subscription: batas untuk penagihan dan kuota. Di dalamnya, resource group menampung resource yang berbagi siklus hidup." |
| 01:10 | Buka `rg-lunch04-video-<suffix>` › storage account › **JSON View**. Sorot kolom `id` (bagian subscription disamarkan). | "Setiap resource punya resource ID. Baca dari kiri ke kanan: subscription, resource group, namespace provider Microsoft.Storage, tipe storageAccounts, lalu namanya. Script, role assignment, dan lock semuanya memakai jalur ini." |
| 01:45 | Storage account › **Overview**, tunjuk **Location** dan tautan **Resource group (move)**. | "Perhatikan tautan move di samping resource group. Memindahkan resource mengubah bagian resource group pada ID-nya, tetapi tidak pernah mengubah region-nya." |
| 02:10 | Resource group › **Tags**: tunjukkan `costCenter=ecommerce`, `env=lab`. | "Saya memberi resource group ini tag pusat biaya dan tag lingkungan." |
| 02:30 | Storage account › **Tags**: kosong. | "Tetapi storage account di dalamnya sama sekali tidak punya tag. Tag tidak diwariskan. Kalau laporan biaya membutuhkannya di setiap resource, pasang tag pada resource-nya atau biarkan Azure Policy yang menyalinnya." |
| 02:50 | Storage account › Tags: tambahkan `app=product-images` lalu **Apply**. | "Jadi saya pasang tag pada resource-nya sendiri. Nama tag tidak peka huruf besar-kecil, tetapi nilainya peka, jadi sepakati ejaannya sejak awal." |
| 03:05 | Storage account › **Locks** › Add: nama `lock-nodelete`, tipe **Delete**. | "Sekarang sebuah lock. Di portal namanya Delete; di CLI namanya CanNotDelete." |
| 03:25 | Storage account › **Delete** › ketik namanya › konfirmasi. Tunjukkan notifikasi error-nya. | "Bahkan sebagai owner subscription, saya tidak bisa menghapusnya. Lock mengalahkan izin saya. Kalau memang berniat menghapus, saya lepas dulu lock-nya." |
| 03:50 | Locks › ubah menjadi **Read-only**; lalu **Access keys** › **Show** (atau Security + networking › Access keys). Tunjukkan error atau tampilan kosongnya. | "Lock Read-only bertindak lebih jauh. Menampilkan access key adalah aksi POST, bukan sekadar membaca, jadi lock ini memblokirnya. Inilah kejutan yang bisa merusak aplikasi di produksi." |
| 04:10 | Locks › hapus lock-nya. | "Dan saya lepas lock-nya lagi." |
| 04:20 | Resource Graph Explorer: jalankan `Resources \| where tags.app == 'product-images' \| project name, resourceGroup, location` | "Resource Graph menemukan apa saja di setiap subscription yang bisa saya baca, dalam hitungan detik. Di sini, setiap resource yang diberi tag product images." |
| 04:50 | Jalankan `ResourceContainers \| where type =~ 'microsoft.resources/subscriptions/resourcegroups' \| where tags.costCenter == 'ecommerce' \| project name` | "Resource group berada di tabel ResourceContainers. Bahasa query-nya sama, tabelnya berbeda." |
| 05:15 | Slide rangkuman: hierarki · resource ID · tag tidak diwariskan · lock dan POST | "Tiga hal yang perlu diingat. Aturan mengalir ke bawah hierarki, tetapi tag tidak. Resource ID memberi tahu persis di mana sesuatu tinggal. Dan lock Read-only memblokir lebih banyak dari dugaan Anda. Di Lab 04, Anda bisa mencoba semuanya." |

## Setelah merekam
- Tambahkan teks (caption): buat otomatis, lalu koreksi istilah Azure secara manual: "Azure Resource Manager",
  "CanNotDelete", "ReadOnly", "Resource Graph", "Tenant root group"
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: lepas lock yang masih tertinggal di storage account, lalu jalankan
  `bash labs/04-resource-hierarchy-basic/cleanup.sh` (script ini menghapus setiap resource group yang bertag `lunch=04`)
