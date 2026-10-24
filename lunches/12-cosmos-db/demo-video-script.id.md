# Makan Siang 12 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** memperlihatkan pengalaman Azure yang sebenarnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan
> animasi: Data Explorer, item dengan bentuk yang berbeda-beda, dan request charge dari setiap query.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema bawaan.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, key dan connection string milik account
> (jangan pernah membuka blade **Keys** saat merekam), serta prompt Cloud Shell Anda jika menampilkan nama pengguna Anda.

## Sebelum menekan tombol rekam

- Sebuah account Azure Cosmos DB for NoSQL **serverless** yang belum berisi database apa pun, dibuat sekitar 15 menit
  sebelum merekam (pembuatan account memakan waktu beberapa menit):

  ```bash
  cd azure-fundamentals-lunches/labs/12-cosmos-db
  source ../common/config.sh && source lab.env
  ensure_rg "$RG" 12
  az cosmosdb create --name "$ACCOUNT" --resource-group "$RG" \
    --locations regionName="$LOCATION" failoverPriority=0 isZoneRedundant=False \
    --capabilities EnableServerless --default-consistency-level Session --output none
  ```

- Tiga item JSON kecil yang disalin dari [`labs/12-cosmos-db/app/products.json`](../../labs/12-cosmos-db/app/products.json)
  ke sebuah editor teks: satu kopi, satu kemeja batik, dan satu camilan (`p-coffee-001`, `p-batik-001`, `p-snacks-004`).
- Tab browser: halaman **Overview** milik account Cosmos DB, dan **Data Explorer** dari account yang sama.
- Setelah selesai, hapus semuanya dengan `bash cleanup.sh` dari folder lab.

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:25 Account: API, capacity mode, region, konsistensi
01:05 Membuat database catalog dan container products
01:55 Menambahkan item dengan bentuk berbeda-beda
02:50 Menjalankan query dan membaca request charge
03:50 Cross-partition query dan biaya fan-out
04:35 Tempat pengaturan consistency level bawaan
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 12 · Cosmos DB dalam lima menit" | "Dalam lima menit ke depan, kita akan membangun katalog produk Nusantara Retail di Azure Cosmos DB, menambahkan produk dengan bentuk yang berbeda-beda, dan melihat persis berapa biaya setiap query dalam request unit." |
| 00:25 | Portal › account Cosmos DB › **Overview** | "Ini adalah account Cosmos DB yang memakai API for NoSQL. Account ini serverless, jadi kita hanya membayar request unit yang kita pakai. Ia berada di satu region — account serverless tidak bisa menambah region lain." |
| 00:45 | Overview: tunjuk **Read Locations**, lalu buka sebentar **Settings › Default consistency** | "Konsistensi bawaannya adalah session, bawaan untuk setiap account baru. Kita akan kembali ke halaman ini di bagian akhir." |
| 01:05 | **Data Explorer › New Container** | "Di Data Explorer, saya membuat database baru bernama catalog dan sebuah container bernama products." |
| 01:25 | Panel New Container: ketik `/category` di **Partition key**; tunjukkan bahwa tidak ada kotak throughput | "Partition key adalah satu-satunya keputusan yang tidak bisa saya ubah belakangan. Halaman kategori kita meminta satu kategori setiap kali, jadi saya memilih garis miring category. Perhatikan, tidak ada pengaturan throughput — account ini serverless." |
| 01:55 | **products › Items › New Item**: tempel item kopi, **Save** | "Ini sebuah kopi. Ia punya tingkat sangrai dan tingkat gilingan." |
| 02:15 | New Item: tempel item batik, **Save**; lalu item camilan | "Dan ini kemeja batik dengan jenis bahan dan daftar ukuran — field-nya berbeda, container-nya sama, tanpa perubahan skema. Camilan ini punya bentuk yang lain lagi." |
| 02:35 | Daftar item: tunjuk kolom `id` dan `category` | "Setiap item punya id dan category. Bersama-sama, keduanya mengidentifikasi item, dan category menentukan logical partition-nya." |
| 02:50 | **New SQL Query**: `SELECT * FROM c WHERE c.category = 'coffee'` › **Execute Query** | "Sekarang halaman kategori. Query ini memfilter berdasarkan partition key, jadi ia hanya menuju tepat satu partisi." |
| 03:10 | Buka tab **Query Stats**; perbesar **Request Charge** | "Query Stats menampilkan request charge-nya: beberapa request unit. Angka itulah mata uang Cosmos DB — setiap operasi melaporkannya." |
| 03:30 | Query: `SELECT * FROM c WHERE c.id = 'p-coffee-001' AND c.category = 'coffee'` › Execute › Query Stats | "Bahkan query untuk satu item pun memakan dua-tiga RU. Di lab, Anda akan melakukan point read sungguhan dengan SDK, yang berbiaya sekitar satu RU." |
| 03:50 | Query: `SELECT * FROM c WHERE CONTAINS(LOWER(c.name), 'kopi')` › Execute › Query Stats | "Pencarian ini tidak menyebut category, jadi ia menjadi cross-partition query. Dengan tiga item, selisih biayanya sangat kecil." |
| 04:15 | Kembali ke panel Query Stats; beri kotak di sekitar **Request Charge** dan **Retrieved document count** | "Tetapi lihat retrieved document count-nya: query ini membaca setiap item untuk menjawab. Dengan sejuta produk yang tersebar di lima puluh partisi, inilah query yang akan menjadi mahal. Di lab, Anda akan memperbaikinya dengan menambahkan partition key." |
| 04:35 | **Settings › Default consistency**: arahkan kursor ke kelima opsi tanpa menyimpan | "Kembali ke konsistensi. Ada lima level, dari strong sampai eventual. Pembacaan strong berbiaya sekitar dua kali lipat RU; session membuat setiap pengguna bisa membaca penulisannya sendiri dengan harga level yang lebih lemah. Di lab, Anda akan mengubah pengaturan ini dan melihat biaya sebuah pembacaan menjadi dua kali lipat." |
| 05:15 | Slide rangkuman: tiga poin | "Tiga hal yang perlu diingat: pilih partition key dari query tersibuk Anda; baca request charge dari semua yang Anda jalankan; dan mulailah dengan session consistency. Setelah itu, bangun sendiri di Lab 12." |

## Setelah merekam
- Tambahkan teks (caption) — buat otomatis, lalu koreksi istilah Azure secara manual: Cosmos DB, RU, NoSQL, partition key, Data Explorer
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: `bash cleanup.sh` di `labs/12-cosmos-db`
