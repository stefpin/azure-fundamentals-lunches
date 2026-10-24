# Makan Siang 11 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** memperlihatkan pengalaman Azure yang sebenarnya untuk makan siang ini — membuat database Azure SQL yang
> server-nya hanya menerima login Microsoft Entra, membuka firewall untuk satu alamat, lalu menjalankan query dari portal.
> Animasi menunjukkan konsepnya; video ini menunjukkan layarnya.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema bawaan.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail (akun Anda muncul sebagai **Microsoft Entra
> admin** dan di hasil query), serta alamat IP publik (muncul di aturan firewall dan di pesan error).

## Sebelum menekan tombol rekam

- Sebuah resource group khusus untuk rekaman, dibuat di Cloud Shell:
  `az group create --name rg-lunch11-demo --location southeastasia --tags course=azure-fundamentals-lunches lunch=11`
- Nama server yang unik secara global sudah dicatat, misalnya `sql-nusa-demo` ditambah empat karakter acak.
- Pastikan subscription Anda masih punya jatah database Azure SQL gratis (*Azure SQL hub* menampilkan penawarannya), atau
  bersiaplah memilih General Purpose **serverless** sebagai gantinya dan sebutkan hal itu dalam narasi.
- Sebuah file teks berisi skrip satu batch di bawah ini, siap ditempel ke Query editor:

  ```sql
  CREATE TABLE dbo.Orders (
      OrderId INT IDENTITY PRIMARY KEY,
      OrderDate DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
      StoreCode VARCHAR(10) NOT NULL,
      CustomerName NVARCHAR(100) NOT NULL,
      TotalIdr DECIMAL(14,0) NOT NULL);
  INSERT INTO dbo.Orders (StoreCode, CustomerName, TotalIdr)
  VALUES ('JKT-01', N'Andi Pratama', 349000), ('SBY-01', N'Siti Rahmawati', 1250000), ('MDN-01', N'Yusuf Hakim', 89000);
  SELECT * FROM dbo.Orders;
  ```

- Tab browser yang sudah dibuka sebelumnya: halaman beranda portal Azure, dan halaman portal *SQL databases*.

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:25 Server yang hanya menerima login Microsoft Entra
01:40 Database gratis (serverless)
02:40 Jaringan: satu aturan firewall, dan satu sakelar yang dibiarkan mati
03:30 Query editor: login sebagai diri sendiri, buat dan query tabel Orders
04:45 Tempat auto-pause dan jatah gratis terlihat
05:25 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 11 · Azure SQL Database dalam lima menit" | "Data pesanan Nusantara Retail masih tinggal di sebuah server di sebelah pantry, dilindungi satu kata sandi yang dipakai bersama. Dalam lima menit ke depan, kita membuatkan rumah barunya di Azure SQL Database — tanpa kata sandi bersama sama sekali." |
| 00:25 | Portal › *SQL databases* › **+ Create** › tab Basics | "Sebuah database selalu tinggal di sebuah logical server. Saya memilih resource group, menamai database-nya `sqldb-orders`, lalu memilih **Create new** untuk server-nya." |
| 00:45 | Panel *Create SQL Database Server*: nama server, lokasi **Southeast Asia** | "Nama server ini akan menjadi nama DNS di bawah `database.windows.net`, jadi harus unik di seluruh dunia. Ini bukan virtual machine — di sinilah aturan firewall dan admin-nya tinggal." |
| 01:05 | **Authentication method: Use Microsoft Entra-only authentication** › **Set admin** › pilih akun sendiri (diburamkan) | "Inilah pilihan yang penting. Entra-only authentication mematikan login SQL untuk seluruh server. Saya menetapkan diri saya sebagai Microsoft Entra admin — di produksi, ini seharusnya sebuah grup, bukan perorangan." |
| 01:40 | Kembali ke Basics: spanduk free offer dan ringkasan biaya | "Karena subscription ini masih punya satu database gratis, portal menerapkan free offer: database General Purpose serverless dengan jatah bulanan. Kartu biayanya menunjukkan nol." |
| 02:00 | Ringkasan *Compute + storage*, lalu pengaturan **Behavior when free limit reached** | "Database ini naik-turun di antara jumlah vCore minimum dan maksimum, dan berhenti sementara saat menganggur. Jika jatah gratisnya habis, saya ingin database ini berhenti sampai bulan depan — bukan menagih saya." |
| 02:25 | **Review + create** › **Create**; halaman deployment | "Deployment-nya memakan waktu satu atau dua menit." *(Potong bagian menunggu saat editing.)* |
| 02:40 | Server › *Security › Networking* | "Server baru tidak mengizinkan siapa pun masuk. Di Networking, saya menambahkan satu aturan firewall untuk alamat client saya saat ini — tombol ini menambahkan IP publik browser saya." |
| 03:00 | Sorot kotak centang **Allow Azure services and resources to access this server** (dibiarkan tidak dicentang) | "Dan sakelar yang ini tetap mati. Sakelar ini akan mengizinkan setiap alamat di dalam Azure, termasuk resource milik pelanggan lain. Simpan." |
| 03:30 | Database › *Query editor* › "Continue as …" (Microsoft Entra) | "Sekarang Query editor di portal. Saya login dengan akun Entra saya — tidak ada kolom kata sandi. Seandainya IP saya tidak diizinkan, editor akan menampilkan alamat yang ditolak dan menawarkan untuk menambahkannya." |
| 03:55 | Tempel dan jalankan skrip yang sudah disiapkan; grid hasil berisi tiga pesanan | "Saya membuat tabel Orders, memasukkan tiga pesanan dari Jakarta, Surabaya, dan Medan, lalu membacanya kembali. T-SQL yang sama seperti di SQL Server, tanpa server yang perlu di-patch." |
| 04:25 | Jalankan `SELECT SUSER_SNAME();` | "Lalu, siapa saya di dalam database? Identitas Entra saya — itulah yang akan tercatat di log audit, bukan login yang dipakai bersama." |
| 04:45 | *Overview* database: status, pricing tier, **Free monthly vCore amount** | "Di halaman Overview, Anda bisa melihat tier serverless dan berapa vCore-detik gratis yang tersisa bulan ini. Tutup Query editor setelah selesai; koneksi yang masih terbuka membuat database tetap terjaga." |
| 05:10 | *Settings › Compute + storage* milik database: auto-pause delay | "Auto-pause delay ada di sini: setelah sekian menit menganggur, database berhenti sementara dan penagihan komputasi pun berhenti." |
| 05:25 | Slide rangkuman: pilih · hubungkan · bayar | "Tiga hal yang perlu diingat: Azure SQL Database untuk data relasional yang berbicara T-SQL; firewall yang hanya mengizinkan alamat yang dikenal, ditambah login khusus Entra; serta serverless atau free offer untuk database kecil. Lab 11 membangun semua ini dari Cloud Shell." |

## Setelah merekam
- Tambahkan teks (caption) — buat otomatis, lalu koreksi istilah Azure secara manual: *Entra*, *serverless*, *vCore*, *T-SQL*
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: `az group delete --name rg-lunch11-demo --yes --no-wait`
