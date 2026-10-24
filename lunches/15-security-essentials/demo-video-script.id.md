# Makan Siang 15 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** memperlihatkan pengalaman nyata di Azure untuk makan siang ini — bagian yang tidak bisa ditunjukkan oleh
> animasi: key vault dengan RBAC permission model, managed identity milik VM yang mula-mula ditolak lalu diizinkan, dan
> secure score di Defender for Cloud.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan di layar:** ID subscription, nama dan ID tenant, alamat email, object ID yang akan terus Anda pakai, dan
> nilai secret apa pun (skrip lab hanya mencetak pratinjau yang disamarkan — pertahankan seperti itu).

## Sebelum menekan tombol rekam
- Sekitar 15 menit sebelum merekam, di Cloud Shell (Bash):

  ```bash
  cd azure-fundamentals-lunches/labs/15-security-essentials
  source ../common/config.sh
  RG=$(rg_name 15); KV_NAME="kv-nusa-${SUFFIX}"
  bash setup.sh                       # VM with the password in its config file (about 4 minutes)
  ```

- Lalu kerjakan Tugas 2, 3, dan 4 dari Lab 15 di luar kamera (vault dengan model RBAC, peran Key Vault Secrets Officer
  untuk Anda, secret `sql-connection`, dan system-assigned identity milik VM). **Jangan** dulu memberikan Key Vault
  Secrets User kepada VM — langkah itulah yang ditunjukkan di video.
- Jalankan perintah Tugas 5 sekali di luar kamera agar ekstensi Run Command sudah terpasang (eksekusi pertama lebih
  lambat).
- Tab browser yang perlu dibuka sebelumnya:
  1. Key vault › **Access configuration**
  2. Key vault › **Secrets**
  3. Key vault › **Access control (IAM)**
  4. `vm-app-1` › **Identity**
  5. **Microsoft Defender for Cloud** › **Overview**
  6. Cloud Shell (Bash) di folder lab, dengan ukuran huruf diperbesar serta variabel `RG` dan `KV_NAME` sudah diisi
- Siapkan potongan (cut) 2–3 menit untuk menunggu role assignment menyebar (atau rekam percobaan ulangnya belakangan,
  lalu sisipkan).

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:25 Vault dengan RBAC permission model
01:10 Owner saja tidak cukup: peran data plane
01:50 Managed identity milik VM
02:25 Run Command: permintaan pertama mendapat 403
03:20 Berikan Key Vault Secrets User — lalu 200 OK
04:30 Secure score dan rekomendasi
05:30 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 15 · Keluarkan kata sandi dari file konfigurasi" | "Toko online Nusantara Retail menyimpan kata sandi database-nya di sebuah file konfigurasi. Dalam enam menit ke depan, kita akan memindahkan secret itu ke Azure Key Vault dan membiarkan aplikasi membacanya dengan managed identity — tanpa kata sandi di mana pun di dalam kode." |
| 00:25 | Key vault › Overview, lalu **Access configuration** | "Ini vault kita, kv-nusa ditambah akhiran acak. Di Access configuration Anda bisa melihat permission model-nya: Azure role-based access control. Sekarang itulah default untuk vault baru, dan artinya akses ke secret dikelola dengan role assignment Azure biasa." |
| 00:50 | Blade **Properties**: soft delete dan masa retensi, purge protection | "Soft delete aktif — memang selalu aktif — dengan retensi tujuh hari untuk lab ini. Purge protection dimatikan di sini supaya saya bisa membersihkan semuanya setelah selesai. Di produksi saya akan mengaktifkannya, dan fitur itu tidak akan pernah bisa dimatikan lagi." |
| 01:10 | Blade **Secrets** yang menampilkan `sql-connection`; arahkan kursor ke kolom nilai (jangan buka nilainya) | "Ini secret-nya, sql-connection. Saya bisa melihatnya karena saya sudah memberi diri saya peran Key Vault Secrets Officer. Menjadi Owner subscription saja tidak cukup — Owner adalah peran control plane. Membaca secret adalah aksi data plane, dan itu butuh peran data plane." |
| 01:50 | `vm-app-1` › **Identity** › System assigned: **On**; perbesar tampilan Object (principal) ID — samarkan nilai lengkapnya | "Server aplikasi kita, vm-app-1, memiliki system-assigned managed identity. Azure membuatkan service principal untuknya di Microsoft Entra ID dan mengurus kredensialnya. Aplikasi tidak pernah melihat kata sandi; ia meminta token ke metadata endpoint milik VM." |
| 02:25 | Cloud Shell: jalankan Run Command dari Tugas 5 (`--scripts @vm/read-secret.sh`) | "Mari kita minta secret-nya dari dalam VM. Skrip ini pertama-tama memanggil identity endpoint di 169.254.169.254 untuk meminta token dengan audience vault.azure.net, lalu memanggil REST API Key Vault dengan token tersebut." |
| 02:55 | Output: audience token, lalu `HTTP 403`, `Forbidden / ForbiddenByRbac` | "Lihat hasilnya. Tokennya valid — autentikasi berhasil. Tetapi Key Vault menjawab 403 Forbidden, ForbiddenByRbac, karena identitas ini belum punya peran apa pun di vault. Berhasil masuk tidak sama dengan diizinkan." |
| 03:20 | Key vault › **Access control (IAM)** › Add role assignment › **Key Vault Secrets User** › Members: Managed identity › Virtual machine › `vm-app-1` › Review + assign | "Jadi saya memberikan hak akses minimum: Key Vault Secrets User, yang hanya bisa membaca nilai secret dan tidak lebih, dengan cakupan satu vault ini saja, untuk managed identity milik VM." |
| 03:55 | Penanda potongan "≈ 3 menit kemudian", lalu jalankan ulang Run Command | "Role assignment butuh beberapa menit untuk menyebar — pesan error-nya bahkan menyebutkan hal itu. Beberapa menit kemudian, perintah yang sama…" |
| 04:10 | Output: `HTTP 200` dan nilai tersamar `Server=tcp:sql-nusa-orders...` | "…200 OK. Aplikasi sudah mendapat connection string-nya, dan perhatikan bahwa skrip hanya mencetak pratinjau yang disamarkan. Berikutnya, lab menghapus kata sandi dari file konfigurasi, sehingga yang tersisa hanya alamat vault dan nama secret-nya." |
| 04:30 | **Microsoft Defender for Cloud** › Overview: tile secure score | "Sekarang sang pelatih. Foundational CSPM di Defender for Cloud gratis. Ia memeriksa resource berdasarkan Microsoft cloud security benchmark dan mengubah hasilnya menjadi secure score." |
| 04:55 | **Recommendations**, difilter ke resource group lab; buka satu rekomendasi (misalnya untuk key vault atau VM) | "Setiap rekomendasi menyebutkan resource yang terdampak, menjelaskan risikonya, dan menawarkan langkah perbaikan. Lab yang baru dibuat bisa butuh beberapa jam sebelum temuan muncul, karena kontrol dihitung ulang sesuai jadwal." |
| 05:15 | **Environment settings** › subscription › **Defender plans** (cukup gulir, jangan ubah apa pun) | "Paket Defender berbayar menambahkan deteksi ancaman per workload — server, storage, database, Key Vault. Paket ini ditagih per resource yang dilindungi, jadi di lab saya hanya melihat-lihat." |
| 05:30 | Slide rangkuman: tiga poin | "Tiga hal yang perlu diingat: Owner tidak bisa membaca secret — data membutuhkan peran data plane. Managed identity menggantikan kata sandi di dalam kode. Dan tier gratis Defender for Cloud memberi tahu apa yang perlu diperbaiki berikutnya. Jangan lupa menjalankan cleanup.sh — skrip itu juga melakukan purge pada vault yang sudah di-soft-delete." |

## Setelah merekam
- Tambahkan teks (caption): buat secara otomatis, lalu koreksi istilah Azure secara manual: Entra, IMDS, ForbiddenByRbac,
  CSPM.
- Tambahkan daftar chapter ke deskripsi video.
- Tempel tautan video ke README makan siang (bagian 🎬 Demo).
- Hapus resource demo: `bash cleanup.sh` di folder lab (skrip ini menghapus resource group dan melakukan purge pada
  vault).
