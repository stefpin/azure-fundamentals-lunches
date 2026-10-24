# Makan Siang 05 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sebenarnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan oleh animasi.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, dan alamat IP publik yang masih akan Anda pakai.

**Topik:** membuat pengguna uji dan grup di Microsoft Entra ID, memberi role di scope resource group, lalu memakai
*Check access* untuk membuktikan apa yang bisa dan tidak bisa dilakukan pengguna tersebut.

## Sebelum menekan tombol rekam

- Gunakan **tenant demo pribadi** tempat Anda menjadi Global Administrator (tenant yang dibuat bersama akun gratis Anda). Video
  ini memperlihatkan nama pengguna dan nama grup, jadi jangan pernah merekam di tenant perusahaan.
- Buat resource group dan sebuah network security group gratis sebagai contoh yang akan ditampilkan (Cloud Shell, Bash):

  ```bash
  az group create --name rg-lunch05-demo --location southeastasia --tags course=azure-fundamentals-lunches lunch=05
  az network nsg create --resource-group rg-lunch05-demo --name nsg-web --output none
  ```

- Tentukan nama pengguna uji sejak awal (misalnya *Rizky (demo)*, `rizky-demo@<your-tenant>.onmicrosoft.com`).
  Biarkan portal membuat kata sandi sementara secara otomatis; rencanakan untuk **mengaburkannya (blur)** saat penyuntingan.
- Tab browser, dalam keadaan sign-in dengan akun admin Anda:
  1. Portal Azure › **Microsoft Entra ID › Users**
  2. Portal Azure › **Microsoft Entra ID › Groups**
  3. Portal Azure › **Resource groups › rg-lunch05-demo › Access control (IAM)**
- Opsional: slide berisi rumus **security principal + role definition + scope = role assignment**.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:25 Membuat pengguna uji
01:25 Membuat grup dan menambahkan pengguna
02:15 Memberi role Reader di scope resource group
03:20 Check access: apa yang bisa dilakukan Rizky?
04:10 Naik ke Contributor, dan apa yang tetap tidak bisa dilakukan Contributor
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 05 · Beri kontraktor akses secukupnya" | "Rizky, kontraktor baru Nusantara Retail, mulai bekerja hari Senin. Dalam lima menit ke depan, kita akan memberinya identitas sendiri, memasukkannya ke sebuah grup, dan memberi grup itu tepat satu role di tepat satu scope — lalu membuktikan apa yang bisa dan tidak bisa dia lakukan." |
| 00:25 | Entra ID › Users › **New user › Create new user** | "Semuanya dimulai di Microsoft Entra ID, direktori milik tenant kita. Saya akan membuat pengguna untuk Rizky. User principal name-nya — nama untuk sign-in — berakhiran domain tenant. Saya biarkan portal membuat kata sandi sementara secara otomatis — di video ini sudah dikaburkan — dan Rizky akan menetapkan kata sandinya sendiri saat sign-in pertama, jadi hanya dia yang tahu kata sandi aslinya." |
| 01:05 | Pengguna selesai dibuat; buka halaman **Overview** milik pengguna | "Inilah akun Rizky. Perhatikan: tidak ada izin Azure apa pun di halaman ini — akun pengguna hanya menjawab pertanyaan *siapa Anda*. Apa yang boleh dia lakukan baru datang nanti, dari role assignment." |
| 01:25 | Entra ID › Groups › **New group**: type *Security*, name *grp-nusa-contractors-demo* | "Kita tidak pernah memberi akses langsung kepada seseorang. Saya membuat security group untuk kontraktor, supaya saat kontraktor berikutnya datang — atau Rizky pergi — cukup satu perubahan keanggotaan." |
| 01:55 | Group › **Members › Add members** › pilih Rizky | "Tambahkan Rizky sebagai anggota. Sisi identitas selesai: satu pengguna, satu grup." |
| 02:15 | Resource groups › rg-lunch05-demo › **Access control (IAM) › Add › Add role assignment** | "Sekarang otorisasi. Saya berada di halaman *Access control (IAM)* milik satu resource group — itulah scope kita. Setiap assignment yang saya tambahkan di sini berlaku untuk resource group ini beserta semua isinya, dan tidak berlaku di tempat lain." |
| 02:40 | Tab **Role**: cari *Reader*; tunjuk Owner, Contributor, dan Reader di tab *Privileged administrator roles* dan *Job function roles* | "Berikutnya role definition. Owner bisa melakukan segalanya, termasuk memberi akses. Contributor bisa mengelola segalanya, tetapi tidak bisa memberi akses. Reader hanya bisa melihat. Kita mulai Rizky dengan Reader." |
| 03:00 | Tab **Members**: *User, group, or service principal* › pilih grup › **Review + assign** | "Lalu security principal-nya: grup kontraktor, bukan Rizky sendiri. Security principal, role, scope — itulah sebuah role assignment." |
| 03:20 | IAM › **Check access** › cari *Rizky* | "Bisakah Rizky melakukan sesuatu di sini? *Check access* menjawabnya. Hasilnya Reader di resource group ini, diwariskan lewat keanggotaan grupnya. Perhatikan bahwa subscription dan resource group lain tidak ada di daftar — dia sama sekali tidak bisa melihatnya." |
| 03:50 | IAM › tab **Role assignments**, difilter ke grup tersebut | "Daftar assignment mengatakan hal yang sama dari sudut pandang resource group: satu grup, satu role, scope ini. Perubahan role bisa butuh beberapa menit untuk sampai ke pengguna yang sedang sign-in, jadi kalau Anda menguji di jendela lain, sign out lalu sign in lagi." |
| 04:10 | Tambahkan role assignment kedua: **Contributor** untuk grup yang sama; lalu hapus assignment Reader | "Saat pekerjaan migrasi dimulai, tim Rizky perlu mengubah berbagai hal. Saya menambahkan Contributor untuk grup yang sama di scope yang sama, lalu menghapus Reader, karena Contributor sudah mencakup akses baca. Least privilege juga berarti tidak ada sisa-sisa." |
| 04:45 | IAM › **Check access** › Rizky › buka assignment Contributor dan tunjuk *NotActions* | "Bahkan sebagai Contributor, Rizky tidak bisa menambahkan role assignment — Contributor mengecualikan izin untuk mengelola akses — dan dia tetap tidak bisa melihat apa pun di luar resource group ini." |
| 05:15 | Slide rangkuman: principal + role + scope | "Tiga hal untuk diingat. Satu: setiap orang mendapat akunnya sendiri, tidak pernah akun bersama. Dua: berikan role ke grup, di scope tersempit yang masih berfungsi. Tiga: *Check access* selalu menunjukkan keadaan yang sebenarnya, jadi gunakan sebelum dan sesudah setiap perubahan. Di Lab 05, Anda akan melakukan semua ini sendiri dan sign-in sebagai Rizky." |

## Setelah merekam
- Tambahkan caption (subtitle): buat otomatis, lalu koreksi istilah Azure secara manual
- Tambahkan daftar chapter ke deskripsi video
- Tempel link video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: cabut role assignment, hapus pengguna uji dan grupnya, lalu
  `az group delete --name rg-lunch05-demo --yes --no-wait`
