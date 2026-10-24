# Makan Siang 16 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** memperlihatkan pengalaman nyata di Azure untuk makan siang ini — bagian yang tidak bisa ditunjukkan oleh
> animasi.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat email, dan alamat IP publik yang akan terus Anda pakai.

## Sebelum menekan tombol rekam
- Jalankan titik awal lab sekitar 30 menit sebelum merekam, agar VM sudah punya riwayat metrik:

  ```bash
  cd azure-fundamentals-lunches/labs/16-monitoring-basic
  bash setup.sh
  ```

- Sepuluh menit sebelum merekam, jalankan sedikit beban CPU agar grafiknya menampilkan tonjolan yang jelas (bebannya
  berhenti dengan sendirinya):

  ```bash
  source ../common/config.sh
  az vm run-command invoke -g "$(rg_name 16)" -n vm-nusa-web --command-id RunShellScript \
    --scripts @cpu-load.sh --parameters 10 --query "value[0].message" -o tsv
  ```

- Gunakan kotak surat sekali pakai (atau samarkan alamatnya) untuk email dari action group.
- Tab browser yang perlu dibuka sebelumnya: halaman **Metrics** milik VM, **Monitor › Alerts**, **Monitor › Activity log**,
  **Service Health**, dan **Advisor**.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:25 Data gratis: metrik CPU milik VM
01:05 Action group yang mengirim email ke engineer piket
01:55 Metric alert: CPU rata-rata di atas 70% selama 5 menit
02:55 "Siapa yang menghentikan VM?" di activity log
03:45 Service Health vs Resource Health
04:35 Rekomendasi Advisor
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 16 · Tahu lebih dulu daripada pelanggan" | "Jumat lalu, pelanggan kita lebih dulu menyadari toko yang lambat daripada kita. Dalam lima menit ke depan, kita akan memasang alert yang seharusnya memperingatkan kita lebih dulu, lalu mencari tahu siapa yang menghentikan VM." |
| 00:25 | VM › Metrics › *Percentage CPU*, agregasi **Avg**, satu jam terakhir; lalu ganti ke **Max** | "Grafik ini gratis dan tidak butuh pengaturan apa pun — metrik platform masuk setiap menit. Perhatikan tonjolannya saat saya mengganti Average ke Maximum: agregasi yang Anda pilih mengubah ceritanya." |
| 01:05 | Monitor › Alerts › Action groups › Create: nama `ag-nusa-oncall`, display name, notifikasi **Email** | "Action group adalah daftar 'siapa yang diberi tahu'. Hari ini isinya satu alamat email; di produksi, isinya kotak surat on-call bersama dan ponsel piket." |
| 01:35 | Action group › **Test action group** › email contoh tiba (samarkan alamatnya) | "Selalu uji. Lebih baik menemukan email-nya di folder spam sekarang daripada saat insiden." |
| 01:55 | VM › Alerts › Create alert rule › sinyal *Percentage CPU* › Static, **Average**, Greater than **70**, check every **1 minute**, lookback **5 minutes** | "Setiap menit, Azure merata-ratakan CPU selama lima menit terakhir dan membandingkannya dengan 70. Rata-rata lima menit berarti 'sibuk untuk beberapa lama', bukan 'satu lonjakan sesaat'." |
| 02:30 | Tab Actions › pilih `ag-nusa-oncall` › Details: Severity 2, nama `alert-cpu-high` › Create | "Pasang action group-nya — tanpa itu, alert hanya muncul di portal dan tidak ada yang mendengarnya." |
| 02:55 | VM › Stop (konfirmasi deallocate); lalu Monitor › Activity log, filter berdasarkan resource group, operasi *Deallocate Virtual Machine* | "Sekarang seseorang menghentikan VM. Activity log mencatat setiap perubahan control plane selama 90 hari, gratis." |
| 03:20 | Buka event-nya › **Summary**: Event initiated by (samarkan nama caller), status Succeeded › sekilas tab JSON | "Inilah jawabannya: caller, waktu, dan hasilnya. Tidak ada lagi 'bukan saya'." |
| 03:45 | VM › Resource health: status saat ini dan entri riwayat untuk penghentian tadi | "Resource Health melihat satu resource. Statusnya unavailable — user initiated. Itu menunjuk ke kita, bukan ke Azure." |
| 04:05 | Service Health › Service issues (kosong atau yang sedang berlangsung), lalu Health alerts › Create (tunjukkan pilihan layanan, region, dan jenis event; lalu batalkan) | "Service Health bersifat personal: hanya layanan dan region yang Anda pakai. Setiap subscription sebaiknya punya Service Health alert yang tersambung ke sebuah action group." |
| 04:35 | Advisor › Overview dengan lima kategori dan Advisor score; buka satu rekomendasi | "Advisor adalah pendapat kedua yang gratis dalam lima kategori: keandalan, keamanan, performa, biaya, dan keunggulan operasional. Tinjau setiap minggu." |
| 05:15 | Slide rangkuman: data gratis · alert = scope + condition + action group · activity log = siapa · Resource vs Service Health | "Tiga hal yang perlu diingat: mulailah dari data gratis, beri setiap alert action group yang menjangkau sebuah tim, dan gunakan activity log serta Resource Health untuk membedakan 'kita' dari 'Azure'. Lab akan memandu Anda melakukan semuanya." |

## Setelah merekam
- Tambahkan teks (caption): buat secara otomatis, lalu koreksi istilah Azure secara manual
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: `bash cleanup.sh` di `labs/16-monitoring-basic`
