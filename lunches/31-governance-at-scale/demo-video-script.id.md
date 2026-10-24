# Makan Siang 31 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sesungguhnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan oleh animasi.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription demo pribadi atau khusus — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, dan alamat IP publik yang masih akan Anda pakai.

## Sebelum menekan tombol rekam

- Gunakan **tenant demo pribadi** milik Anda sendiri. Management group berlaku untuk seluruh tenant, dan rekaman ini memindahkan sebuah subscription.
- Sekitar **satu jam sebelum** merekam, bangun titik awalnya dengan skrip Lab 31 (Jalur B, atau *Path B* di skrip), lalu hapus
  exemption-nya agar Anda bisa membuatnya di depan kamera:

  ```bash
  cd azure-fundamentals-lunches/labs/31-governance-at-scale
  source ../common/config.sh && source lab-vars.sh
  ASSUME_YES=1 bash setup.sh
  MOVE_SUBSCRIPTION=yes bash solution.sh      # hierarchy, move, initiative, assignment, remediation, exemption
  source lab-vars.sh
  az policy exemption delete --name "$EXEMPTION" --resource-group "$SANDBOX_RG"
  az policy state trigger-scan --resource-group "$SANDBOX_RG" --no-wait
  ```

- Tab browser: **Management groups**, **Policy › Definitions**, **Policy › Compliance** (scope: intermediate root
  `mg-nusa-<suffix>`), **Resource Graph Explorer**.
- Privasi: ID tenant root group adalah **ID tenant** Anda, dan halaman Management groups menampilkannya di samping ID
  subscription Anda. Buramkan keduanya saat penyuntingan, atau potong dari layar selagi merekam.

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:25 Pohon management group
01:15 Satu initiative, disimpan di atas
02:05 Assignment di Landing zones
02:50 Kepatuhan dilihat dari puncak
03:35 Waiver untuk sandbox
04:25 Resource Graph lintas tenant
05:10 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 31 · Tata kelola untuk seluruh perusahaan" | "Nusantara Retail sedang menuju dua puluh subscription. Dalam lima menit ke depan, Anda akan melihat bagaimana satu hierarki dan satu initiative mengatur semuanya — langsung di portal sungguhan." |
| 00:25 | Portal › Management groups; buka **Tenant root group** › *Nusantara Retail (lab)* › Platform, Landing zones › Corp (buramkan ID) | "Ini pohon landing zone versi kecil. Di bawah tenant root group ada intermediate root kita, lalu Platform dan Landing zones, dan Corp di bawahnya. Versi sungguhannya masih menambahkan Security, Management, Connectivity, Identity, Online, Sandboxes, dan Decommissioned." |
| 00:50 | Buka **Corp**: subscription demo tercantum sebagai anak; buka menu **…** untuk menunjukkan **Move** tanpa memakainya | "Subscription demo saya tinggal di Corp, jadi ia mewarisi semua yang ditetapkan di atasnya. Memindahkan subscription cukup satu klik — justru karena itulah hanya tim platform yang boleh melakukannya." |
| 01:15 | Policy › Definitions; filter *Definition type: Initiative*, *Type: Custom*; buka **Nusantara baseline** | "Berikutnya, aturannya. Initiative kustom ini membundel tiga policy bawaan: lokasi yang diizinkan, tag costCenter yang wajib, dan tag yang diwarisi dari resource group." |
| 01:35 | Tunjuk **Definition location**: intermediate root; gulir ke daftar policy beserta reference ID-nya, lalu ke parameter | "Perhatikan lokasi definisinya: intermediate root. Sebuah definisi hanya bisa ditetapkan di tempat ia disimpan atau di bawahnya, jadi menyimpannya di atas membuat setiap grup di bawahnya bisa memakainya ulang. Dua parameter initiative mengisi ketiga policy sekaligus." |
| 01:50 | Pilih **+ Initiative definition** dan buka pemilih **Definition location**, lalu batalkan | "Saat Anda membuatnya sendiri, pemilih inilah keputusan yang paling penting. Simpan di sebuah subscription, dan definisi itu tidak akan pernah bisa menjangkau management group." |
| 02:05 | Policy › Assignments, scope **Landing zones**; buka **Nusantara baseline (Lab 31)** | "Initiative ini ditetapkan satu kali saja, di Landing zones. Setiap subscription yang mendarat di Corp atau Online otomatis mendapatkannya — yang ada hari ini maupun yang datang tahun depan." |
| 02:20 | Tunjukkan **Policy enforcement: Disabled**, parameter lokasi yang diizinkan, dan bagian **Managed identity** | "Dua detail. Policy enforcement dalam keadaan disabled — itulah DoNotEnforce, ring pertama dari rollout yang aman: laporkan semuanya, jangan blokir apa pun. Lalu ada managed identity, karena policy Modify membutuhkannya untuk memperbaiki resource." |
| 02:50 | Policy › Compliance, scope intermediate root; buka halaman kepatuhan milik initiative | "Inilah kepatuhan, dilihat dari puncak pohon. Satu halaman untuk setiap subscription di bawah intermediate root." |
| 03:05 | Tab **Resource compliance**: resource corp **Compliant**; network security group sandbox **Non-compliant** untuk dua policy | "Resource corp sudah patuh — tadi sebuah remediation task menyalin tag costCenter dari resource group-nya. Eksperimen di sandbox melanggar dua aturan: region-nya salah, tag-nya tidak ada." |
| 03:35 | Buka resource sandbox › **Create exemption**: scope = resource group sandbox; kategori **Waiver**; tanggal kedaluwarsa 30 hari ke depan; deskripsi dengan tiket NUSA-1042 | "Ibu Sari menerima risiko itu selama tiga puluh hari. Itulah Waiver: risiko yang diterima, dengan tanggal berakhir dan alasan yang jelas, dibuat oleh orang yang berwenang memberi pengecualian — bukan lubang diam-diam dalam aturan." |
| 04:05 | Policy › Exemptions: exemption yang baru; kembali ke Compliance (setelah refresh), resource sandbox tampil **Exempt** | "Ia muncul sebagai Exempt, jadi auditor tetap bisa melihatnya. Begitu kedaluwarsa, resource-nya kembali tidak patuh — tidak ada yang perlu ingat untuk menghapusnya." |
| 04:25 | Resource Graph Explorer: jalankan query nomor 1 dari Lab 31 Tugas 8 (hasil per policy anggota dan per status) | "Terakhir, Resource Graph. Satu query KQL lintas semua subscription yang bisa saya baca: kepatuhan per policy dan per status." |
| 04:50 | Jalankan query nomor 4 (subscription beserta induknya); tunjuk **Corp** | "Dan di mana setiap subscription berada dalam hierarki. Dengan dua puluh subscription, cara ini jauh lebih cepat daripada mengeklik pohonnya satu per satu." |
| 05:10 | Slide rangkuman: hierarki → initiative disimpan di atas → assignment di Landing zones → remediasi → exemption → query | "Tiga hal untuk diingat: rancang pohon untuk policy, bukan untuk bagan organisasi; simpan definisi di atas dan tetapkan sekali saja, dimulai dengan DoNotEnforce; dan buat pengecualian tetap terlihat dengan exemption berbatas waktu. Bangun sendiri di Lab 31." |

## Setelah merekam
- Tambahkan caption/subtitel (buat otomatis, lalu koreksi istilah Azure secara manual: *management group*,
  *initiative*, *DoNotEnforce*, *Waiver*, *Resource Graph*, *KQL*)
- Tambahkan daftar chapter ke deskripsi video
- Tempelkan tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo — `cleanup.sh` menghapus exemption, assignment beserta role milik identitasnya, dan initiative,
  memindahkan subscription kembali, lalu menghapus management group (anak lebih dulu) dan resource group:

  ```bash
  cd azure-fundamentals-lunches/labs/31-governance-at-scale
  bash cleanup.sh
  ```
