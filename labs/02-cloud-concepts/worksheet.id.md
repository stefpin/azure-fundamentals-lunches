# Lembar kerja Lab 02 · Menyusun justifikasi bisnis

🇬🇧 [Read in English](worksheet.md)

Gunakan lembar kerja ini bersama [Lab 02](README.id.md). Salin ke catatan Anda sendiri (atau cetak), lalu isi kolom
**Jawaban Anda**. Jawab setiap bagian *sebelum* membuka blok jawabannya, lalu nilai hasil kerja Anda. Lembar kerja ini
terdiri atas tujuh bagian (Bagian 1–7); Bagian 1–5 berisi total 40 soal.

---

## Bagian 1 · IaaS, PaaS, SaaS, atau serverless? (10)

| # | Layanan atau situasi di Nusantara Retail | Jawaban Anda |
|---:|---|---|
| 1 | Azure Virtual Machines yang menjalankan Ubuntu, dengan web server yang dipasang dan di-patch oleh Pak Budi | |
| 2 | Azure App Service yang menjalankan kode toko online yang di-deploy oleh Dewi | |
| 3 | Kotak surat Microsoft 365 dan Teams untuk kantor pusat | |
| 4 | Sebuah function Azure Functions yang mengirim email konfirmasi pesanan setiap kali ada pesanan masuk | |
| 5 | Azure SQL Database yang menyimpan data pesanan | |
| 6 | Aplikasi penggajian online yang dipakai tim HR dengan login; vendor menjalankan semuanya | |
| 7 | Virtual network dan managed disk di balik VM lift and shift | |
| 8 | Alur kerja Azure Logic Apps yang mengirim pesan ke tim stok saat sebuah barang habis terjual | |
| 9 | Storage account Azure Storage yang menyimpan foto-foto produk | |
| 10 | Dynamics 365, dipakai oleh tim layanan pelanggan | |

<details><summary>Jawaban Bagian 1</summary>

| # | Jawaban | Alasan |
|---:|---|---|
| 1 | IaaS | Anda menyewa VM dan mengelola sistem operasi serta semua yang ada di atasnya. |
| 2 | PaaS | Anda membawa kode; Microsoft menjalankan dan mem-patch platform di bawahnya. |
| 3 | SaaS | Aplikasi jadi: Anda mengonfigurasinya dan mengelola pengguna, tidak lebih. |
| 4 | Serverless (salah satu bentuk PaaS) | Kode yang dipicu event, tanpa server yang perlu dikelola, bayar per eksekusi. |
| 5 | PaaS | Layanan database terkelola: Microsoft mem-patch mesin database-nya dan mengurus backup. |
| 6 | SaaS | Vendor menjalankan seluruh aplikasi; HR hanya memakai dan mengonfigurasinya. |
| 7 | IaaS | Virtual network dan disk adalah blok bangunan infrastruktur yang Anda konfigurasikan sendiri. |
| 8 | Serverless (salah satu bentuk PaaS) | Alur kerja yang dipicu event, diskalakan dan ditagih per eksekusi. |
| 9 | PaaS | Penyimpanan adalah layanan platform terkelola: Anda menyimpan data, Microsoft menjalankan layanannya. |
| 10 | SaaS | Aplikasi bisnis jadi yang disediakan dalam bentuk langganan. |

</details>

---

## Bagian 2 · CapEx atau OpEx? (8)

| # | Pengeluaran | Jawaban Anda |
|---:|---|---|
| 1 | Membeli server yang lebih besar untuk ruangan di samping pantry | |
| 2 | Invoice Azure bulanan untuk toko online | |
| 3 | UPS dan AC baru untuk ruang server | |
| 4 | Lisensi Microsoft 365, dibayar setiap bulan per pengguna | |
| 5 | Tagihan listrik untuk ruang server | |
| 6 | Kontrak pemeliharaan tahunan untuk server yang ada | |
| 7 | Membeli switch jaringan untuk keempat puluh gerai | |
| 8 | Biaya untuk data yang dikirim dari Azure ke pelanggan di internet | |

<details><summary>Jawaban Bagian 2</summary>

| # | Jawaban | Alasan |
|---:|---|---|
| 1 | CapEx | Aset fisik yang dibeli di muka dan disusutkan selama bertahun-tahun. |
| 2 | OpEx | Layanan yang dibayar pada periode pemakaiannya. |
| 3 | CapEx | Peralatan fisik yang dimiliki Nusantara Retail. |
| 4 | OpEx | Langganan yang dibayar sesuai pemakaian. |
| 5 | OpEx | TI on-premises juga punya biaya operasional, dan biaya itu harus masuk dalam perbandingan yang adil. |
| 6 | OpEx | Kontrak layanan yang dibayar per periode, bukan aset. |
| 7 | CapEx | Perangkat keras yang dibeli dan dimiliki, meskipun letaknya di gerai. |
| 8 | OpEx | Biaya berbasis pemakaian yang mengikuti penggunaan. |

</details>

---

## Bagian 3 · Siapa yang bertanggung jawab: Nusantara Retail, Microsoft, atau bersama? (10)

| # | Tugas | Jawaban Anda |
|---:|---|---|
| 1 | Mem-patch sistem operasi VM web di Desain A | |
| 2 | Mengganti disk fisik yang rusak di pusat data Azure yang menampung Desain A | |
| 3 | Mem-patch sistem operasi di bawah App Service di Desain B | |
| 4 | Menentukan staf HR mana yang boleh melihat data gaji di aplikasi penggajian SaaS | |
| 5 | Mewajibkan MFA untuk akun setiap kepala gerai | |
| 6 | Aturan firewall (network security group) di depan VM Desain A | |
| 7 | Akses jaringan ke aplikasi toko online di Desain B: kontrol yang disediakan platform dan cara mengonfigurasinya | |
| 8 | Satpam dan kartu akses di pusat data Azure | |
| 9 | Menjaga library di dalam kode toko online sendiri tetap mutakhir di Desain B | |
| 10 | Melindungi laptop tim keuangan dari malware | |

<details><summary>Jawaban Bagian 3</summary>

| # | Jawaban | Alasan |
|---:|---|---|
| 1 | Nusantara Retail | Di IaaS, sistem operasi adalah milik pelanggan. |
| 2 | Microsoft | Host fisik selalu menjadi tugas Microsoft di cloud. |
| 3 | Microsoft | Di PaaS, penyedia menjalankan dan mem-patch sistem operasi. |
| 4 | Nusantara Retail | Identitas dan akses selalu milik pelanggan, bahkan di SaaS. |
| 5 | Nusantara Retail | Keamanan akun adalah bagian dari identitas dan akses. |
| 6 | Nusantara Retail | Di IaaS, Anda mengonfigurasi semua kontrol jaringan di depan VM Anda. |
| 7 | Bersama | Di PaaS, Microsoft menyediakan dan mengamankan fitur jaringan platform; Anda menentukan siapa yang bisa menjangkau aplikasinya. |
| 8 | Microsoft | Keamanan fisik pusat data selalu berpindah ke penyedia. |
| 9 | Nusantara Retail | Aplikasi adalah tanggung jawab bersama di PaaS, tetapi kode yang Anda tulis, beserta library-nya, adalah bagian Anda. |
| 10 | Nusantara Retail | Perangkat (laptop dan ponsel) selalu menjadi tanggung jawab pelanggan, di semua jenis layanan, bahkan di SaaS. |

</details>

---

## Bagian 4 · Model cloud yang mana? (4)

| # | Situasi | Jawaban Anda |
|---:|---|---|
| 1 | Toko online pindah ke Azure; gerai-gerai tetap memakai server lokalnya, yang terhubung ke Azure | |
| 2 | Semua yang dijalankan Nusantara Retail ada di Azure; tidak ada yang tersisa di on-premises | |
| 3 | Sebuah bank membangun virtual machine layanan mandiri di pusat datanya sendiri, khusus untuk divisi-divisinya sendiri | |
| 4 | Toko online berjalan di Azure, dan sebuah perkakas analitik pemasaran berjalan di penyedia cloud lain | |

<details><summary>Jawaban Bagian 4</summary>

| # | Jawaban | Alasan |
|---:|---|---|
| 1 | Cloud hibrid | Cloud publik dan sistem on-premises yang terhubung dan bekerja sama. Azure Arc juga bisa mengelola server gerai. |
| 2 | Cloud publik | Semua beban kerja berjalan di infrastruktur bersama milik penyedia. |
| 3 | Cloud privat | Layanan mandiri bergaya cloud, khusus untuk satu organisasi, di perangkat keras miliknya sendiri. |
| 4 | Multicloud | Dua atau lebih penyedia cloud publik dipakai bersamaan. |

</details>

---

## Bagian 5 · Sebutkan manfaatnya (8)

Pilih dari: **ketersediaan tinggi, skalabilitas, elastisitas, keandalan, prediktabilitas, keamanan, tata kelola,
kemudahan pengelolaan**. Masing-masing dipakai satu kali.

| # | Pernyataan | Jawaban Anda |
|---:|---|---|
| 1 | Dua instance web di availability zone yang berbeda menjaga toko tetap buka saat satu zone gagal | |
| 2 | Selama 12.12, lapisan web bertambah dari dua menjadi enam instance secara otomatis, lalu menyusut kembali | |
| 3 | Saat katalog produk berlipat dua, Anda bisa memindahkan database ke ukuran yang lebih besar | |
| 4 | Anggaran dan pricing calculator memberi tahu tim keuangan kira-kira berapa biaya bulan depan | |
| 5 | Sebuah policy memblokir siapa pun yang membuat resource di luar Indonesia Central | |
| 6 | Microsoft mem-patch platform di bawah App Service, dan Defender for Cloud menandai sebuah pengaturan yang berisiko | |
| 7 | Satu templat membuat ulang seluruh lingkungan, alih-alih empat puluh klik di portal | |
| 8 | Setelah terjadi kerusakan perangkat keras, layanan pulih di infrastruktur yang sehat dan tetap berfungsi | |

<details><summary>Jawaban Bagian 5</summary>

| # | Jawaban | Alasan |
|---:|---|---|
| 1 | Ketersediaan tinggi | Layanan tetap aktif meskipun sebuah komponen atau zone gagal. |
| 2 | Elastisitas | Kapasitas bertambah *dan* berkurang secara otomatis mengikuti permintaan. |
| 3 | Skalabilitas | Kemampuan menambah resource, di sini dengan scale up (vertikal). |
| 4 | Prediktabilitas | Prediktabilitas biaya: memperkirakan dan melacak pengeluaran. |
| 5 | Tata kelola | Aturan yang menjaga deployment tetap sesuai standar perusahaan dan regulasi. |
| 6 | Keamanan | Penyedia mengamankan dan mem-patch bagiannya; perkakas keamanan membantu bagian Anda. |
| 7 | Kemudahan pengelolaan | Mengelola resource secara konsisten dengan templat dan perkakas, bukan secara manual. |
| 8 | Keandalan | Kemampuan pulih dari kegagalan dan terus berfungsi. |

</details>

---

## Bagian 6 · Estimasi Anda

Isi bagian ini selama Tugas 2–4. Gunakan mata uang yang sama di semua tempat, dan tuliskan di baris pertama.

| | Desain A · lift and shift (IaaS) | Desain B · PaaS |
|---|---|---|
| Mata uang dan region yang dipakai (catat jika ada item yang memakai Southeast Asia) | | |
| Total bulanan, pay-as-you-go | | |
| Item dengan biaya terbesar | | |
| Total bulanan dengan komitmen satu tahun jika tersedia | | |
| Item mana saja yang menawarkan komitmen? | | |
| Total bulanan di Southeast Asia (pay-as-you-go) | | |
| Tugas rutin yang masih dikerjakan Nusantara Retail | | |
| Estimasi Anda untuk jam kerja orang per bulan | | |
| Single point of failure yang tersisa | | |
| Jika satu web server gagal, apa yang dirasakan pelanggan? | | |

Tiga pertanyaan untuk dijawab, masing-masing dalam satu kalimat:

1. Desain mana yang lebih murah di tagihan Azure?
2. Desain mana yang lebih murah setelah waktu kerja orang ikut dihitung?
3. Desain mana yang punya lebih sedikit single point of failure, dan mengapa?

---

## Bagian 7 · Rekomendasi satu halaman (templat)

Salin templat di bawah ke sebuah dokumen, lalu isi. Batasi hanya satu halaman.

> **Kepada:** Ibu Sari, Direktur · **Dari:** *nama Anda*, Cloud Engineer · **Tanggal:** *hari ini*
> **Perihal:** Memindahkan toko online dari server pantry
>
> **1. Pertanyaannya.** "Kalau server itu mati, berapa lama kita tidak bisa jualan?" Saat ini jawabannya: *sampai
> server diperbaiki atau diganti, yang bisa memakan waktu berhari-hari*.
>
> **2. Rekomendasi (satu kalimat).** *Kita sebaiknya …*
>
> **3. Opsi yang dipertimbangkan.**
>
> | Opsi | Biaya bulanan (pay-as-you-go) | Dengan komitmen 1 tahun | Jika satu server gagal | Siapa yang mem-patch server |
> |---|---|---|---|---|
> | Membeli server yang lebih besar | *pembelian sekali bayar* | — | Penjualan berhenti sampai server diperbaiki | Nusantara Retail |
> | A · Lift and shift (IaaS) | | | | |
> | B · PaaS | | | | |
>
> **4. Alasan.** *Uang (CapEx versus OpEx), risiko (single point of failure), usaha (waktu kerja orang), kecepatan (waktu
> sampai go-live).*
>
> **5. Yang tetap menjadi tanggung jawab kita.** *Data, pengaturan, identitas dan akses (MFA), serta bagian kita dari
> semua hal yang ditanggung bersama.*
>
> **6. Risiko dan cara kita menguranginya.** *Misalnya: keterampilan, downtime saat migrasi, biaya tak terduga (anggaran
> dan alert).*
>
> **7. Langkah berikutnya.** *Sebuah pilot, siapa mengerjakan apa, dan keputusan apa yang dibutuhkan beserta
> tenggatnya.*

<details><summary>Contoh rekomendasi (salah satu jawaban yang mungkin)</summary>

**Rekomendasi:** pindahkan toko online ke Desain B (App Service dan Azure SQL Database di Indonesia Central) dalam dua
bulan, dengan langkah lift and shift singkat hanya jika kodenya butuh waktu lebih lama untuk disesuaikan.

**Alasan:** saat ini satu kerusakan perangkat keras menghentikan penjualan online sampai server diperbaiki. Kedua desain
cloud menghilangkan single point of failure itu dengan menjalankan dua instance web. Estimasi terlampir menunjukkan
tagihan Azure bulanan untuk setiap desain. Desain B butuh lebih sedikit komponen dan menghilangkan sebagian besar
pekerjaan patching sistem operasi dan backup, sehingga Pak Budi punya lebih banyak waktu untuk gerai; menurut estimasi
kami, itu sekitar *N* jam per bulan. Pengeluaran berpindah dari pembelian server sekali bayar (CapEx) ke tagihan bulanan
(OpEx) yang naik di bulan Desember dan turun di bulan-bulan sepi, dan komitmen satu tahun bisa menurunkannya setelah
pemakaian stabil.

**Yang tetap menjadi tanggung jawab kita:** data pelanggan, konfigurasi, dan siapa yang boleh masuk. Kita akan
mewajibkan MFA untuk setiap akun yang punya akses dan meninjau izin setiap kuartal.

**Risiko:** Dewi mungkin perlu mengubah sebagian kode dan konfigurasi (kita mulai dengan pilot), dan biaya cloud bisa
merayap naik (anggaran dengan alert di 50, 80, dan 100% sudah terpasang).

**Langkah berikutnya:** pilot dua minggu toko online di App Service, lalu keputusan lanjut/tidak (go/no-go) pada rapat
bulanan berikutnya.

</details>

---

⬅️ [Kembali ke Lab 02](README.id.md) · [Bacaan Makan Siang 02](../../lunches/02-cloud-concepts/README.id.md)
