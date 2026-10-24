# Lab 04 · Menata Nusantara Retail

🇬🇧 [Read in English](README.md)

> **Pasangan dari:** [Makan Siang 04 · Hierarki Resource dan Azure Resource Manager (Dasar)](../../lunches/04-resource-hierarchy-basic/README.id.md)
> **Waktu:** sekitar 40 menit · **Biaya:** 💲 (lihat [kelompok biaya](../README.id.md#kelompok-biaya)) · **Tingkat kesulitan:** ★★☆
> **Bisa dikerjakan terpisah:** ✅ Anda tidak memerlukan lab sebelumnya. Semua yang dibutuhkan lab ini dibuat oleh langkah-langkahnya sendiri.
> **Penulis:** Stefanus Pinarta · [Tentang penulis](../../README.id.md#tentang-penulis)

## 🎯 Yang akan Anda bangun

Nusantara Retail sedang mengganti tumpukan eksperimennya dengan sebuah struktur. Anda membuat dua resource group
bertag, satu untuk toko online dan satu untuk layanan bersama, serta sebuah storage account untuk foto produk. Anda
membongkar resource ID account itu, membuktikan bahwa tag resource group tidak sampai ke resource di dalamnya, dan
melihat dua jenis lock menghentikan Anda: lock `CanNotDelete` memblokir penghapusan, dan lock `ReadOnly` memblokir
sesuatu yang tampak seperti operasi baca biasa. Setelah itu, Anda memindahkan account itu ke resource group bersama,
tempat yang semestinya, lalu menemukan semuanya kembali dengan Azure Resource Graph. Sebagai opsi, Anda bisa membuat
management group di tenant Anda sendiri.

```mermaid
flowchart LR
  subgraph sub["Subscription Anda"]
    subgraph shop["rg-lunch04-shop-&lt;suffix&gt;<br/>project=storefront · costCenter=ecommerce"]
      st1["stnusaimg&lt;suffix&gt;<br/>dibuat di sini, dikunci, lalu dibuka lagi"]
    end
    subgraph shared["rg-lunch04-shared-&lt;suffix&gt;<br/>project=shared-services · costCenter=it"]
      st2["stnusaimg&lt;suffix&gt;<br/>setelah dipindahkan"]
    end
  end
  st1 -- "az resource move" --> st2
  graph["Azure Resource Graph<br/>query berdasarkan tag"] -.-> shop
  graph -.-> shared
```

## ✅ Sebelum mulai

- Subscription Azure tempat Anda berperan sebagai **Owner** (lihat [Lab 01](../01-before-you-begin/README.id.md)).
  Membuat dan melepas lock membutuhkan Owner atau User Access Administrator; Contributor tidak cukup.
- **Azure Cloud Shell (Bash)** — buka [shell.azure.com](https://shell.azure.com). Tidak ada yang perlu dipasang.
- Ambil file lab dan muat pengaturan bersama:

```bash
git clone https://github.com/stefpin/azure-fundamentals-lunches.git   # first time only
cd azure-fundamentals-lunches/labs/04-resource-hierarchy-basic
source ../common/config.sh
RG_SHOP=$(rg_name 04 shop)
RG_SHARED=$(rg_name 04 shared)
ST="stnusaimg${SUFFIX}"
ST_TYPE="Microsoft.Storage/storageAccounts"
```

- Lab ini tidak punya `setup.sh`: Anda membuat semuanya sendiri.
- Jika Cloud Shell kehabisan waktu (timeout) lalu dimulai ulang, `cd` kembali ke folder lab dan jalankan lagi lima
  baris setelah `cd`. Tugas 3 menunjukkan cara mengembalikan ID storage account ke dalam `ST_ID`.

> [!IMPORTANT]
> Resource lab dikenai biaya selama masih ada (storage account yang kosong nyaris tidak berbiaya, tetapi tetap
> bersihkan). Jika Anda berhenti di tengah jalan, jalankan **Bersihkan**: langkah itu melepas lock yang masih tertinggal
> sebelum menghapus resource group.

## 🧭 Pilih mode Anda

| Mode | Cocok untuk Anda jika… | Caranya |
|---|---|---|
| **Terpandu** | Anda ingin setiap langkah dijelaskan | ikuti Tugas 1–8 di bawah |
| **Tantangan** | Anda sudah menguasai dasarnya | baca hanya [Ringkasan tantangan](#-ringkasan-tantangan), bangun dengan cara Anda sendiri, lalu jalankan `bash verify.sh` |

## Tugas 1 · Dua resource group bertag

Toko online dan layanan bersama punya pemilik dan siklus hidup yang berbeda, jadi keduanya mendapat resource group
terpisah. `ensure_rg` membuat setiap grup dengan tag `course` dan `lunch` milik kursus (script pembersihan menemukan grup
berdasarkan tag itu); lalu Anda **menggabungkan** (merge) tag milik Anda sendiri.

```bash
ensure_rg "$RG_SHOP" 04
ensure_rg "$RG_SHARED" 04

az tag update --resource-id "$(az group show --name "$RG_SHOP" --query id --output tsv)" \
  --operation Merge --tags project=storefront env=lab costCenter=ecommerce --output none
az tag update --resource-id "$(az group show --name "$RG_SHARED" --query id --output tsv)" \
  --operation Merge --tags project=shared-services env=lab costCenter=it --output none

az group list --query "[?tags.lunch=='04'].{name:name, location:location, project:tags.project, costCenter:tags.costCenter}" \
  --output table
```

`Merge` menambahkan tag dan memperbarui tag yang sudah ada. `Replace` akan membuang setiap tag yang tidak ada di daftar
Anda, termasuk tag `course` dan `lunch` yang diandalkan proses pembersihan, jadi berhati-hatilah saat memilih.

> [!TIP]
> **Lebih suka portal?** *Resource groups › rg-lunch04-shop-… › Tags*: tambahkan ketiga tag lalu pilih **Apply**.
> Portal mengedit kumpulan tag yang sama dengan yang diedit CLI.

> ✅ **Pemeriksaan:** tabel menampilkan kedua grup di `LOCATION` Anda, dengan `storefront`/`ecommerce` dan
> `shared-services`/`it`.

## Tugas 2 · Storage account, dan tag yang tidak mengalir ke bawah

Buat storage account untuk foto produk di resource group toko online, lalu lihat tag-nya.

```bash
az storage account create --name "$ST" --resource-group "$RG_SHOP" --location "$LOCATION" \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false \
  --output none

az storage account show --name "$ST" --resource-group "$RG_SHOP" --query tags
```

Jawabannya `{}` (atau tidak ada apa-apa sama sekali): tag `project`, `env`, dan `costCenter` milik grup **tidak**
mengalir ke account itu. Pasang tag pada resource-nya sendiri:

```bash
ST_ID=$(az storage account show --name "$ST" --resource-group "$RG_SHOP" --query id --output tsv)
az tag update --resource-id "$ST_ID" --operation Merge --tags app=product-images env=lab --output none
az tag list --resource-id "$ST_ID" --query properties.tags
```

> ✅ **Pemeriksaan:** account itu ada di grup shop dan membawa persis tag yang Anda berikan, `app` dan `env`, tanpa satu
> pun tag milik grup.

## Tugas 3 · Membongkar resource ID

Resource ID adalah alamat yang dipakai Azure Resource Manager untuk segala hal. Cetak ID-nya, lalu pecah berdasarkan
garis miring.

```bash
echo "$ST_ID"
IFS='/' read -r -a parts <<< "$ST_ID"
for i in "${!parts[@]}"; do printf '%2d  %s\n' "$i" "${parts[$i]}"; done
```

Baca output bernomor itu: `1`–`2` adalah subscription (simpan ID itu untuk diri sendiri), `3`–`4` resource group,
`5`–`6` namespace resource provider, `7` tipe resource, dan `8` namanya. ID saja sudah cukup untuk menemukan
resource-nya:

```bash
az resource show --ids "$ST_ID" --query "{name:name, type:type, location:location, group:resourceGroup}" --output table
```

Sekarang lihat resource provider di baliknya, tipe-tipe resource yang ditawarkannya, dan versi API terbaru untuk tipe
storage account:

```bash
az provider show --namespace Microsoft.Storage --query "{namespace:namespace, state:registrationState}" --output table
az provider show --namespace Microsoft.Storage --query "resourceTypes[].resourceType" --output tsv | head -n 12
az provider show --namespace Microsoft.Storage \
  --query "resourceTypes[?resourceType=='storageAccounts'].apiVersions | [0][:3]" --output tsv
```

> [!TIP]
> `ST_ID` hilang setelah Cloud Shell dimulai ulang? Ambil kembali dengan
> `ST_ID=$(az storage account list --query "[?name=='${ST}'].id | [0]" --output tsv)`, yang menemukan account itu di
> resource group mana pun ia berada sekarang.

> ✅ **Pemeriksaan:** Anda bisa menyebutkan bagian mana dari ID itu yang merupakan subscription, resource group,
> namespace provider (`Microsoft.Storage`), tipe (`storageAccounts`), dan nama. Provider menampilkan `Registered`.

## Tugas 4 · Lock CanNotDelete memblokir penghapusan

Pak Budi ingin tempat penyimpanan foto terlindungi dari penghapusan yang tidak disengaja. Lock `CanNotDelete` (disebut
**Delete** di portal) melakukannya untuk semua orang, termasuk Owner.

```bash
az lock create --name lock-nodelete --lock-type CanNotDelete \
  --resource-group "$RG_SHOP" --resource "$ST" --resource-type "$ST_TYPE" \
  --notes "Product photos - do not delete" --output none

az lock list --resource-group "$RG_SHOP" --resource "$ST" --resource-type "$ST_TYPE" \
  --query "[].{name:name, level:level}" --output table
```

Beri lock itu waktu beberapa detik, lalu coba hapus account-nya. Bagian `az lock show … &&` adalah jaring pengaman:
perintah hapus hanya berjalan jika lock-nya benar-benar ada.

```bash
sleep 15
az lock show --name lock-nodelete --resource-group "$RG_SHOP" \
  --resource "$ST" --resource-type "$ST_TYPE" --output none \
  && az storage account delete --name "$ST" --resource-group "$RG_SHOP" --yes
```

Penghapusan gagal dengan kode error **ScopeLocked** dan pesan yang menyatakan bahwa scope itu tidak bisa menjalankan
operasi delete karena ada scope yang dikunci. Perubahan tetap diizinkan, karena lock ini hanya memblokir penghapusan:

```bash
az tag update --resource-id "$ST_ID" --operation Merge --tags owner=dewi --output none \
  && echo "Tag added: a CanNotDelete lock still allows changes."
```

Lepas lock itu sebelum tugas berikutnya:

```bash
az lock delete --name lock-nodelete --resource-group "$RG_SHOP" --resource "$ST" --resource-type "$ST_TYPE"
```

> [!TIP]
> **Lebih suka portal?** *Storage account › Settings › Locks › Add*, lock type **Delete**. Lalu coba **Delete** di
> halaman Overview account itu dan baca notifikasinya.

> ✅ **Pemeriksaan:** penghapusan ditolak dengan `ScopeLocked`, pembaruan tag berhasil, dan daftar lock kembali kosong.

## Tugas 5 · Lock ReadOnly memblokir lebih banyak dari dugaan Anda

Lock `ReadOnly` (**Read-only** di portal) membiarkan semua orang membaca dan tidak membiarkan siapa pun mengubah apa
pun. "Membaca" di sini berarti hanya permintaan GET, dan dari situlah kejutannya datang.

```bash
az lock create --name lock-readonly --lock-type ReadOnly \
  --resource-group "$RG_SHOP" --resource "$ST" --resource-type "$ST_TYPE" --output none
sleep 15

# 1) Reading the account's properties is a GET: allowed
az storage account show --name "$ST" --resource-group "$RG_SHOP" --query "{name:name, sku:sku.name}" --output table

# 2) Listing the access keys is a POST: blocked (the query prints only how many keys, never the keys themselves)
az storage account keys list --account-name "$ST" --resource-group "$RG_SHOP" --query "length(@)" --output tsv

# 3) Changing a tag is a write: blocked
az tag update --resource-id "$ST_ID" --operation Merge --tags reviewed=yes --output none
```

Perintah 2 dan 3 gagal dengan **ScopeLocked**. Menampilkan key terasa seperti membaca, tetapi sengaja dibuat sebagai
aksi POST: key itu memberi akses penuh ke setiap blob di account tersebut, jadi Azure tidak membagikannya lewat GET
biasa. Lock ReadOnly memblokir setiap POST, karena Resource Manager tidak bisa tahu aksi POST mana yang mengubah
sesuatu. Aplikasi yang mengambil storage key saat dinyalakan akan langsung rusak begitu seseorang memasang lock ini.

Lepas lock itu dan pastikan key bisa ditampilkan lagi (tetap hanya jumlahnya):

```bash
az lock delete --name lock-readonly --resource-group "$RG_SHOP" --resource "$ST" --resource-type "$ST_TYPE"
sleep 15
az storage account keys list --account-name "$ST" --resource-group "$RG_SHOP" --query "length(@)" --output tsv
```

> ✅ **Pemeriksaan:** dengan lock ReadOnly terpasang, `show` berhasil sementara `keys list` dan `tag update` ditolak.
> Setelah lock dilepas, `keys list` mencetak `2`.

## Tugas 6 · Memindahkan account ke resource group bersama

Aplikasi lain, misalnya tablet di toko-toko, juga akan memakai foto produk, jadi account itu semestinya berada di grup
bersama. Memindahkannya mengubah resource group-nya, dan karena itu juga ID-nya, tetapi tidak mengubah region maupun
datanya.

```bash
OLD_ID="$ST_ID"
az resource move --destination-group "$RG_SHARED" --ids "$OLD_ID"
```

Pemindahan memakan waktu satu atau dua menit. Selama berlangsung, kedua resource group dikunci dari perubahan, tetapi
storage account tetap melayani data. Setelah prompt muncul kembali, bandingkan ID-nya:

```bash
ST_ID=$(az storage account show --name "$ST" --resource-group "$RG_SHARED" --query id --output tsv)
echo "old: $OLD_ID"
echo "new: $ST_ID"
az resource show --ids "$OLD_ID" --output none      # fails with ResourceNotFound: the old address is gone
az storage account show --name "$ST" --resource-group "$RG_SHARED" \
  --query "{group:resourceGroup, location:primaryLocation, tags:tags}" --output json
```

Lokasinya tidak berubah dan tag milik account itu sendiri (`app`, `env`, `owner`) ikut terbawa, tetapi account itu tidak
mendapat `costCenter=it` milik grup bersama: tag tetap tidak diwariskan.

> [!TIP]
> **Lebih suka portal?** Di halaman *Overview* account itu, pilih **move** di samping *Resource group*, lalu
> **Move to another resource group**. Portal memvalidasi pemindahan sebelum memulainya.

> ✅ **Pemeriksaan:** ID baru memuat `rg-lunch04-shared-<suffix>`, ID lama menghasilkan `ResourceNotFound`, dan lokasi
> account masih `LOCATION` Anda.

## Tugas 7 · Menemukan semuanya dengan Azure Resource Graph

Resource Graph menelusuri setiap subscription yang bisa Anda baca, dalam hitungan detik. Perintah CLI-nya ada di
extension `resource-graph`; pengaturan berikut membuat Azure CLI memasang extension secara otomatis, tanpa bertanya:

```bash
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
```

Resource group berada di tabel `ResourceContainers`:

```bash
az graph query -q "ResourceContainers
  | where type =~ 'microsoft.resources/subscriptions/resourcegroups'
  | where tags.lunch == '04'
  | project name, location, project=tostring(tags.project), costCenter=tostring(tags.costCenter)" \
  --query "data[]" --output table
```

Resource berada di tabel `Resources`:

```bash
az graph query -q "Resources | where tags.app == 'product-images' | project name, type, resourceGroup, location" \
  --query "data[]" --output table

# Proof that tags don't inherit: no resource carries the shared group's costCenter=it
az graph query -q "Resources | where tags.costCenter == 'it' | project name, resourceGroup" \
  --query "data[]" --output table
```

Resource Graph adalah indeks dari resource Anda, jadi perubahan yang baru Anda buat beberapa detik lalu mungkin butuh
sedikit waktu untuk muncul. Jika hasilnya tampak usang, tunggu satu menit lalu jalankan query-nya lagi.

> [!TIP]
> **Lebih suka portal?** Cari **Resource Graph Explorer**, tempel sebuah query tanpa bagian `az graph query -q`, lalu
> pilih **Run query**. Anda bisa menyimpan query dan menyematkan hasilnya ke dashboard.

> ✅ **Pemeriksaan:** query pertama menampilkan kedua resource group beserta project dan pusat biayanya, query kedua
> menampilkan storage account di grup bersama, dan query ketiga tidak mengembalikan baris apa pun.

## Tugas 8 (opsional) · Management group di tenant Anda sendiri

> [!WARNING]
> Lakukan ini hanya di tenant **milik Anda sendiri**, misalnya tenant yang dibuat bersama akun gratis Anda, tempat Anda
> menjadi Global Administrator. Management group berlaku di tingkat tenant: di tenant perusahaan, Anda bisa memengaruhi
> tata kelola milik orang lain, atau administrator Anda mungkin sudah memblokirnya. Jangan pernah memindahkan
> subscription kantor. Management group pertama di sebuah tenant bisa butuh waktu hingga 15 menit untuk muncul, karena
> Azure terlebih dahulu menyiapkan root management group.

```bash
MG="mg-nusa-lab-${SUFFIX}"
az account management-group create --name "$MG" --display-name "Nusantara Retail (lab)" --output none
az account management-group show --name "$MG" \
  --query "{name:name, displayName:displayName, parent:details.parent.displayName}" --output table
```

Induk grup baru itu adalah Tenant root group. Di portal (*Management groups*), Anda bisa melihat subscription Anda di
bawah Tenant root group, bersebelahan dengan management group baru yang masih kosong. Biarkan subscription tetap di
tempatnya; Makan Siang 31 membahas cara merancang dan mengisi sebuah hierarki. `cleanup.sh` akan menghapus management
group ini untuk Anda.

> ✅ **Pemeriksaan:** `az account management-group show` mencetak grup Anda dengan *Tenant Root Group* sebagai induknya.
> Jika Anda mendapat error otorisasi, tenant Anda mewajibkan izin untuk membuat management group; lewati tugas ini.

## 🔧 Rusak lalu perbaiki

Pak Budi memutuskan untuk "melindungi" seluruh resource group bersama dengan lock ReadOnly, tanpa memberi tahu siapa
pun:

```bash
az lock create --name lock-protect-shared --lock-type ReadOnly --resource-group "$RG_SHARED" \
  --notes "Added by Pak Budi" --output none
sleep 15
```

Sekarang coba perubahan kecil yang tidak berbahaya pada storage account:

```bash
az tag update --resource-id "$ST_ID" --operation Merge --tags reviewed=yes --output none
```

**Gejala:** pembaruan gagal dengan **ScopeLocked**, padahal Anda tidak pernah memasang lock pada storage account. Cari
tahu di mana lock itu berada, lalu perbaiki.

<details><summary>Petunjuk dan perbaikan</summary>

Lock itu diwariskan. Daftar lock yang berlaku untuk sebuah resource juga mencakup lock di resource group dan
subscription-nya, dan ID setiap lock menunjukkan scope tempat lock itu dipasang:

```bash
az lock list --resource-group "$RG_SHARED" --resource "$ST" --resource-type "$ST_TYPE" \
  --query "[].{name:name, level:level, scope:id}" --output table
```

ID `lock-protect-shared` berakhir di resource group, bukan di storage account. Lepas lock itu lalu coba lagi:

```bash
az lock delete --name lock-protect-shared --resource-group "$RG_SHARED"
sleep 15
az tag update --resource-id "$ST_ID" --operation Merge --tags reviewed=yes --output none && echo "Fixed."
```

Apa yang seharusnya dipakai Pak Budi? Lock `CanNotDelete` melindungi grup dari penghapusan tanpa memblokir perubahan
sehari-hari, sedangkan role assignment menentukan siapa yang boleh mengubah sesuatu.

</details>

## 🧪 Verifikasi hasil kerja Anda

```bash
bash verify.sh
```

Setiap pemeriksaan semestinya menampilkan **PASS**. Jika ada yang gagal, pesannya memberi tahu tugas mana yang perlu
Anda ulangi.

## 🧹 Bersihkan (jangan dilewati!)

```bash
bash cleanup.sh
```

Script ini melepas lock yang masih tertinggal di resource group Lab 04, menghapus management group opsional
`mg-nusa-lab-<suffix>` jika ada, lalu menghapus kedua resource group beserta storage account-nya. Penghapusan berlanjut
di latar belakang selama beberapa menit. Jika Anda ingin Azure CLI kembali bertanya sebelum memasang extension,
jalankan `az config unset extension.use_dynamic_install`.

## 🩺 Pemecahan masalah

| Gejala | Kemungkinan penyebab | Perbaikan |
|---|---|---|
| `(AuthorizationFailed) ... does not have authorization to perform action 'Microsoft.Authorization/locks/write'` | Anda berperan sebagai Contributor, bukan Owner atau User Access Administrator | Gunakan subscription tempat Anda menjadi Owner, misalnya akun gratis milik Anda sendiri |
| `(ScopeLocked) The scope '...' cannot perform delete operation because following scope(s) are locked` | Ada lock pada resource atau pada salah satu induknya | `az lock list --resource-group ... --resource ... --resource-type ...` menampilkan setiap lock yang berlaku; lepas lock yang tepat |
| `az resource move` gagal dengan `ScopeLocked` | Ada lock ReadOnly pada resource group sumber atau tujuan (atau pada subscription) | Lepas lock-nya, lalu pindahkan lagi |
| `az resource show --ids "$OLD_ID"` menyatakan `ResourceNotFound` | Memang begitu seharusnya setelah pemindahan: ID-nya berubah | Gunakan ID baru dari Tugas 6 |
| `az graph query` meminta pemasangan extension atau menyatakan perintahnya tidak ditemukan | Extension `resource-graph` belum terpasang | Jalankan baris `az config set extension.use_dynamic_install=yes_without_prompt` dari Tugas 7, atau `az extension add --name resource-graph` |
| Query Resource Graph tidak menampilkan perubahan yang baru Anda buat | Indeksnya masih menyusul | Tunggu satu menit lalu jalankan query-nya lagi |
| `(StorageAccountAlreadyTaken) The storage account named ... is already taken.` | Nama storage account bersifat global | Jalankan `bash cleanup.sh`, lalu `rm ~/.azlunches-suffix`, `source ../common/config.sh` lagi, dan mulai ulang dari Tugas 1 |
| `ensure_rg` gagal dengan `ScopeLocked` saat Anda menjalankan ulang Tugas 1 | Lock dari Tugas 4, Tugas 5, atau latihan rusak-lalu-perbaiki masih terpasang | Lepas lock itu (lihat petunjuk di latihan rusak-lalu-perbaiki), lalu jalankan ulang |
| Pembuatan management group gagal dengan `AuthorizationFailed` | Hierarchy protection di tenant Anda mewajibkan izin untuk membuat management group | Lewati Tugas 8; tugas itu opsional |

## 🚀 Tantangan tambahan

- Validasi pemindahan tanpa benar-benar menjalankannya: `az resource invoke-action --action validateMoveResources`
  dengan ID grup sumber dan request body yang menyebutkan resource serta grup tujuannya (lihat
  [dokumentasi pemindahan](https://learn.microsoft.com/azure/azure-resource-manager/management/move-resource-group-and-subscription)).
- Pilih tiga tipe resource yang Anda perkirakan akan dipakai di makan siang berikutnya, lalu cari di
  [daftar tipe resource yang mendukung pemindahan](https://learn.microsoft.com/azure/azure-resource-manager/management/move-support-resources).
- Buat blob container melalui control plane (`az storage container-rm create`), cetak resource ID-nya, dan temukan
  segmen resource anak yang mengikuti nama account.
- Tulis query Resource Graph yang menampilkan setiap resource di subscription Anda yang **tidak** punya tag
  `costCenter`, lalu simpan di Resource Graph Explorer.

## 🏁 Ringkasan tantangan

Bangun hal-hal berikut dengan cara apa pun yang Anda suka (portal, CLI, Bicep):

1. Dua resource group di `LOCATION` Anda: `rg-lunch04-shop-<suffix>` dengan tag `project=storefront`, `env=lab`, dan
   `costCenter=ecommerce`, serta `rg-lunch04-shared-<suffix>` dengan `project=shared-services`, `env=lab`, dan
   `costCenter=it`. Keduanya juga tetap membawa `course=azure-fundamentals-lunches` dan `lunch=04` (`ensure_rg`
   menambahkannya).
2. Account StorageV2 `stnusaimg<suffix>` (`Standard_LRS`, minimum TLS 1.2, akses blob anonim dinonaktifkan), dengan tag
   `app=product-images` dan `env=lab`, yang dibuat di grup shop lalu **dipindahkan** ke grup shared.
3. Tidak diperiksa oleh script: buktikan bahwa lock `CanNotDelete` memblokir penghapusan account dan bahwa lock
   `ReadOnly` memblokir penampilan daftar key-nya.
4. Tidak ada resource lock yang tersisa di kedua resource group maupun di account.
5. Tidak diperiksa oleh script: query Resource Graph yang menampilkan kedua resource group berdasarkan tag `lunch`-nya.

Lalu jalankan `bash verify.sh`. Buntu? Intip `solution.sh` atau beralih ke mode Terpandu.

---

⬅️ [Bacaan Makan Siang 04](../../lunches/04-resource-hierarchy-basic/README.id.md) · 🏠 [Semua lab](../README.id.md) · 🏠 [Beranda kursus](../../README.id.md)

<sub>Terakhir divalidasi: Oktober 2026 · Ada yang tidak berfungsi? [Laporkan masalah lab](../../CONTRIBUTING.md).</sub>
