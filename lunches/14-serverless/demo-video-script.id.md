# Makan Siang 14 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menunjukkan pengalaman Azure yang sesungguhnya untuk makan siang ini — memilih hosting plan untuk
> Functions, sebuah function yang mengubah HTTP request menjadi pesan di queue, serbuan pesanan di Live metrics, dan run
> Logic App yang langkah-langkahnya bisa Anda buka satu per satu. Animasi hanya bisa menyimulasikan hal-hal ini.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat email, alamat IP publik yang masih akan Anda pakai —
> dan khusus di makan siang ini juga **function key** dan **connection string storage**.

## Sebelum menekan tombol rekam

- Sekitar 20 menit sebelum merekam, bangun versi jadi lab ini (💲, sekitar 10 menit) lalu periksa hasilnya:

  ```bash
  cd ~/azure-fundamentals-lunches/labs/14-serverless
  source ../common/config.sh && source lab.env
  bash solution.sh        # storage account + queue, workspace, Flex Consumption app, code, Logic App
  bash verify.sh          # every check should say PASS
  ```

- Kosongkan queue, supaya penonton hanya melihat pesanan yang Anda kirim di depan kamera (Logic App menambahkan satu
  pesanan heartbeat setiap 15 menit; itu tidak masalah):

  ```bash
  az storage message clear --queue-name "$QUEUE" --account-name "$ST" --auth-mode key --only-show-errors
  ```

- Di sesi Cloud Shell yang sama, muat URL dan key dari Tugas 5 di lab, lalu bersihkan layar agar key itu tidak pernah
  tampil. Jangan pernah meng-`echo` key di depan kamera:

  ```bash
  ORDER_URL=$(az functionapp function show -g "$RG" -n "$FUNC" --function-name new_order --query invokeUrlTemplate --output tsv)
  FUNC_KEY=$(az functionapp function keys list -g "$RG" -n "$FUNC" --function-name new_order --query default --output tsv)
  clear
  ```

- Siapkan tiga perintah `curl` dari Tugas 5 dan perintah serbuan berikut agar tinggal ditempel (300 pesanan, 25
  sekaligus):

  ```bash
  seq 1 300 | xargs -P 25 -I{} curl -s -o /dev/null -w "%{http_code}\n" -X POST "$ORDER_URL" \
    -H "x-functions-key: $FUNC_KEY" -H "Content-Type: application/json" \
    -d '{"orderId":"BURST-{}","store":"Jakarta - Kemang","items":[{"sku":"KOPI-TORAJA-250G","qty":1}]}' | sort | uniq -c
  ```

- Tab browser: (1) halaman beranda portal; (2) function app `func-nusa-<suffix>`; (3) storage account
  `stnusaorders<suffix>` › *Storage browser › Queues › orders*; (4) resource Application Insights di
  `rg-lunch14-<suffix>` › *Live metrics*; (5) Logic App `logic-nusa-orders` › *Logic app designer*.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:25 Tempat function berjalan: pilihan hosting
01:05 Function app di Flex Consumption
01:50 Membuat pesanan dengan curl
02:20 Pesanan menunggu di queue
02:45 Serbuan pesanan di Live metrics
03:35 Logic App, langkah demi langkah
04:50 Layanan pesan yang mana?
05:20 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 14 · Serverless — Azure Functions dan Logic Apps" | "Toko-toko Nusantara Retail mengirim pesanan sepanjang hari, dengan malam yang sepi dan lonjakan liar di hari promo. Dalam enam menit ke depan, kita melihat sebuah function yang menerima pesanan dan menaruhnya di queue, menyaksikannya menangani serbuan pesanan, lalu menambahkan workflow yang menguji alur ini setiap lima belas menit. Tidak ada server yang perlu dikelola di mana pun." |
| 00:25 | Tab 1: *Create a resource* › *Create* di bawah *Function App*: halaman *Select a hosting option*; tunjuk setiap opsi; lalu tutup halamannya | "Saat membuat function app, pertanyaan pertamanya adalah di mana ia berjalan. Flex Consumption adalah plan serverless yang direkomendasikan: ia menyusut ke nol, dan bertambah menjadi banyak instance ketika event membanjir. Functions Premium menjaga instance tetap hangat, App Service menjalankan function di plan yang sudah Anda bayar, dan Container Apps menjalankannya di samping container Anda. Plan Consumption kini berstatus legacy. Saya tutup halaman ini: aplikasi kita sudah ada." |
| 01:05 | Tab 2: `func-nusa-<suffix>` › *Overview*: Flex Consumption, Python; daftar function menampilkan `new_order` (HTTP trigger) | "Inilah aplikasi dari lab: Flex Consumption, Python. Isinya satu function, new_order, yang dipicu oleh HTTP." |
| 01:15 | *Settings › Environment variables*: tunjuk `OrdersStorage__queueServiceUri` (sebuah URL) tanpa memperlihatkan nilai lain; *Settings › Identity*: system-assigned **On**; *Settings › Scale and concurrency*: maximum instance count 10, instance memory 2.048 MB, tanpa always-ready instance | "Function ini menulis ke storage queue melalui output binding. Pengaturan koneksinya hanya berisi alamat queue: aplikasi melakukan sign-in dengan managed identity-nya, yang memegang role queue di storage account. Tanpa connection string, tanpa secret. Scale and concurrency menampilkan pagar pengamannya: paling banyak sepuluh instance berukuran 2 GB, dan tanpa always-ready instance, jadi waktu menganggur tidak memakan biaya compute." |
| 01:50 | Cloud Shell: pesanan valid dari Tugas 5 → `{"status": "queued", …}` dan `HTTP 200`; pesanan tanpa item → `400` beserta alasannya; panggilan tanpa key → `401` | "Mari kita buat pesanan seperti yang dilakukan toko online: sebuah POST berisi JSON dan function key. Queued, lengkap dengan tracking ID. Panggilan pertama setelah masa sepi bisa memakan beberapa detik; itulah cold start. Pesanan yang rusak mendapat 400 beserta alasannya. Tanpa key, tidak boleh masuk: 401." |
| 02:20 | Tab 3: *Storage browser › Queues › orders* › *Refresh*; buka pesannya: JSON dengan `receivedAtUtc` dan `trackingId` | "Dan inilah pesanannya, menunggu di queue untuk sistem gudang. Function itu tidak pernah memanggil SDK storage: binding-lah yang menulis pesan ketika function selesai. Kalau sistem gudang offline selama satu jam, pesanan cukup menunggu di sini." |
| 02:45 | Tab 4: *Live metrics*; Cloud Shell: tempel perintah serbuan; perhatikan request rate dan jumlah server naik; perintah selesai dengan `300 200` | "Sekarang serbuan: tiga ratus pesanan, dua puluh lima sekaligus. Di Live metrics, request rate melonjak dan platform menambah instance untuk mengimbanginya. Berapa banyak instance-nya bergantung pada beban dan pada berapa request yang diterima setiap instance sekaligus. Setiap pesanan dijawab 200. Ketika serbuan berakhir, instance-instance itu menganggur dan, setelah beberapa saat, aplikasi kembali ke nol." |
| 03:35 | Tab 5: designer: **Recurrence** (setiap 15 menit) → **HTTP** (POST ke function, dua header, body JSON); jangan buka *Code view* | "Separuh lain dari serverless adalah workflow. Logic App Consumption ini adalah heartbeat dari lab: Recurrence trigger setiap lima belas menit dan sebuah action HTTP yang mengirim pesanan uji. Anda bisa membangunnya di sini dengan drag and drop, atau men-deploy-nya sebagai JSON dari command line, seperti yang dilakukan lab." |
| 04:05 | *Overview* › *Run trigger* › *Run*; buka entri baru di *Run history*: kedua langkah hijau beserta durasinya; buka **outputs** dari langkah HTTP (status 200, body `queued`), bukan input-nya | "Jalankan trigger-nya sekarang, tidak perlu menunggu. Di run history, setiap langkah menyala hijau beserta durasinya, dan output langkah HTTP menampilkan jawaban function: queued. Setiap run menyimpan catatan langkah demi langkah seperti ini, sehingga kegagalan mudah ditemukan." |
| 04:35 | Tab 3: *Refresh*: sebuah pesan yang `orderId`-nya diawali `HB-` | "Kembali ke queue, pesanan heartbeat sudah tiba. Sebuah function dan sebuah workflow, keduanya dibayar sesuai pemakaian, dan keduanya menganggur hampir sepanjang waktu." |
| 04:50 | Slide: Event Grid · Service Bus · Event Hubs · Storage queues, masing-masing satu baris | "Satu keputusan lagi sebelum Anda membangun: layanan pesan yang mana? Event Grid mendorong pemberitahuan bahwa sesuatu telah terjadi, misalnya blob baru. Service Bus membawa pesan bisnis, lengkap dengan urutan dan transaksi. Event Hubs menampung stream telemetri berisi jutaan event per detik. Storage queues adalah penyangga sederhana dan murah yang baru saja kita pakai." |
| 05:20 | Slide rangkuman: "Flex Consumption untuk function baru · Binding + managed identity · Logic Apps untuk menghubungkan layanan" | "Ada tiga hal yang perlu diingat. Pilih Flex Consumption untuk function serverless baru. Biarkan binding dan managed identity mengurus sambungannya, tanpa secret di pengaturan. Dan gunakan Logic Apps bila pekerjaannya sebagian besar menghubungkan layanan. Lab membangun semua ini, lalu membersihkannya." |

## Setelah merekam
- Tambahkan teks (caption): buat otomatis, lalu koreksi istilah Azure secara manual: *Flex Consumption*, *output
  binding*, *managed identity*, *Logic App*, *Event Grid*, *Service Bus*, *Event Hubs*.
- Tambahkan daftar chapter ke deskripsi video.
- Tempel tautan video ke README makan siang (bagian 🎬 Demo).
- Hapus resource demo: `bash cleanup.sh` di `labs/14-serverless`. Skrip ini juga menghapus `~/lab14-out`, yang berisi
  file workflow yang sudah terisi function key.
- Periksa setiap frame untuk mencari function key (*App keys*, *Code view*, input langkah HTTP, `workflow.json` yang
  sudah terisi) dan *Show value* dari `AzureWebJobsStorage` atau `DEPLOYMENT_STORAGE_CONNECTION_STRING`. Samarkan
  (blur) semua yang Anda temukan, walaupun key itu berhenti berfungsi begitu aplikasinya dihapus.
