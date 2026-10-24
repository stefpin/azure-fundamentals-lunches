# Makan Siang 18 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sebenarnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan
> oleh animasi.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, dan alamat IP publik yang masih akan terus
> Anda pakai.

## Sebelum menekan tombol rekam
- Sekitar **45 menit sebelum** merekam, jalankan perintah ini di Cloud Shell agar data kepatuhan sempat muncul:

  ```bash
  az group create --name rg-demo18 --location southeastasia --output none
  az storage account create --name "stdemo18old$RANDOM" --resource-group rg-demo18 \
    --location southeastasia --sku Standard_LRS --output none     # an "old" untagged resource
  RG_ID=$(az group show --name rg-demo18 --query id --output tsv)
  REQUIRE_TAG_ID=$(az policy definition list \
    --query "[?policyType=='BuiltIn' && displayName=='Require a tag on resources'].id | [0]" --output tsv)
  az policy assignment create --name require-costcenter-tag --scope "$RG_ID" \
    --policy "$REQUIRE_TAG_ID" --params "{ 'tagName': { 'value': 'costCenter' } }" --output none
  az policy state trigger-scan --resource-group rg-demo18 --no-wait
  ```

- Tab browser: **Policy › Definitions**, **Policy › Compliance** (scope difilter ke `rg-demo18`), dan Cloud Shell
  (Bash).
- Rencanakan satu potongan: setelah Anda meng-assign *Allowed locations* di depan kamera, hentikan rekaman sekitar
  5–10 menit sampai assignment itu berlaku, lalu lanjutkan dari chapter "Melihat deployment gagal".

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:25 Mencari definisi policy bawaan
01:10 Meng-assign Allowed locations ke resource group
02:10 Melihat deployment gagal
03:05 Membaca tampilan kepatuhan
04:05 Membiarkan policy Modify menambahkan tag yang hilang
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 18 · Azure Policy dalam lima menit" | "Nusantara Retail menemukan sebuah storage account di West Europe dan setumpuk resource tanpa tag. Dalam lima menit ke depan, kita memasang pagar pengaman agar hal itu tidak terulang — dengan Azure Policy." |
| 00:25 | Portal › Policy › Definitions; ketik *Allowed locations* di kotak pencarian; buka definisinya | "Azure menyediakan ribuan definisi bawaan. Ini dia *Allowed locations*. Lihat JSON-nya: sebuah `if` yang membandingkan lokasi resource dengan sebuah daftar, dan sebuah `then` yang menolak. Daftar itu adalah parameter, jadi satu definisi cocok untuk perusahaan mana pun." |
| 00:55 | Gulir definisinya: mode **Indexed**, parameter **listOfAllowedLocations** dan **effect** | "Ada dua hal yang perlu diperhatikan: mode Indexed berarti definisi ini melewati resource group, dan effect-nya adalah parameter dengan Deny sebagai nilai default." |
| 01:10 | Pilih **Assign policy**; Scope › `rg-demo18` (blur ID subscription) | "Assignment adalah saat aturan mulai bekerja. Saya memilih scope-nya — hanya resource group ini untuk demo; di produksi, scope-nya adalah subscription atau management group." |
| 01:35 | Tab Parameters › Allowed locations: *Southeast Asia*; Non-compliance message: "Gunakan Southeast Asia — kebijakan cloud Nusantara" | "Saya hanya mengizinkan Southeast Asia dan menambahkan pesan yang ramah. Pesan itu muncul di dalam error, jadi developer tahu apa yang harus dilakukan, alih-alih membuka tiket." |
| 01:55 | Review + create › Create | "Create. Assignment baru butuh sekitar lima menit untuk menjangkau scope-nya, jadi saya jeda rekamannya di sini." |
| 02:10 | Cloud Shell: `az storage account create --name stdemo18weu$RANDOM --resource-group rg-demo18 --location westeurope --sku Standard_LRS` | "Lima menit kemudian. Saya pemilik subscription ini, jadi RBAC tidak keberatan — tetapi lihat apa kata Azure Policy tentang West Europe." |
| 02:35 | Error-nya: sorot `RequestDisallowedByPolicy`, nama assignment, dan pesan kustomnya | "RequestDisallowedByPolicy. Pesannya menyebut nama assignment dan menampilkan teks kustom kita. Tidak ada yang dibuat, dan sebanyak apa pun izin yang Anda punya tidak akan mengubahnya — hanya pemilik policy yang bisa." |
| 02:50 | Jalankan perintah yang sama dengan `--location southeastasia --tags costCenter=CC-1001` | "Permintaan yang sama di Southeast Asia, dengan tag yang diwajibkan oleh policy kita yang lain. Berhasil." |
| 03:05 | Portal › Policy › Compliance; pilih *Require a tag on resources* | "Sekarang rapornya. Policy tag yang saya assign sebelum merekam sudah mengevaluasi resource group ini." |
| 03:25 | Tab Resource compliance: storage account lama berstatus **Non-compliant**; buka *Compliance details* | "Storage account lama itu non-compliant — ia tidak punya tag costCenter. Perhatikan, storage account itu tidak dihapus: Deny memblokir permintaan baru, dan resource yang sudah ada hanya dilaporkan." |
| 03:50 | Tunjuk waktu *Last evaluated* dan tombol **Create remediation task** (berwarna abu-abu untuk Deny) | "Policy Deny tidak bisa memperbaiki apa pun. Untuk perbaikan otomatis, Anda membutuhkan policy Modify atau DeployIfNotExists — mari kita tambahkan satu." |
| 04:05 | Assign *Inherit a tag from the resource group if missing*, nama tag `costCenter`; tab Remediation: system-assigned managed identity, lokasi Southeast Asia, centang **Create a remediation task** | "Portal membuat sebuah managed identity dan memberinya role yang diminta definisi. Mencentang *Create a remediation task* juga memperbaiki resource yang sudah ada." |
| 04:40 | Resource group › Tags: tambahkan `costCenter = CC-1001` | "Policy inherit menyalin tag dari resource group, jadi resource group itu sendiri harus punya tag tersebut." |
| 04:55 | Policy › Remediation › Remediation tasks: task berpindah ke **Complete**; buka storage account lama › Tags | "Beberapa menit kemudian, remediation task sudah selesai, dan storage account lama kini membawa costCenter CC-1001. Tidak ada yang mengeditnya secara manual." |
| 05:15 | Slide rangkuman: Definition → Assignment → Effect → Compliance → Remediation | "Tiga hal yang perlu diingat: sebuah definisi baru aktif setelah Anda meng-assign-nya ke sebuah scope; Deny memblokir permintaan baru tetapi tidak pernah menghapus; dan Modify ditambah remediation task memperbaiki apa yang sudah ada. Cobalah sendiri di Lab 18." |

## Setelah merekam
- Tambahkan caption (teks di layar): buat otomatis, lalu koreksi istilah Azure secara manual (*Azure Policy*,
  *RequestDisallowedByPolicy*, *Modify*, *remediation*)
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo — assignment (dan role assignment milik managed identity dari policy inherit) berada di resource
  group, jadi hapus semuanya lebih dulu, baru kemudian group-nya:

  ```bash
  for a in $(az policy assignment list --resource-group rg-demo18 --query "[].name" --output tsv); do
    pid=$(az policy assignment show --name "$a" --resource-group rg-demo18 --query identity.principalId --output tsv)
    if [ -n "$pid" ]; then
      az role assignment delete --assignee "$pid" --resource-group rg-demo18
    fi
    az policy assignment delete --name "$a" --resource-group rg-demo18
  done
  az group delete --name rg-demo18 --yes --no-wait
  ```
