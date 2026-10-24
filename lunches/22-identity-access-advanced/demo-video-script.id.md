# Makan Siang 22 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sesungguhnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan oleh animasi.
> **Target durasi:** 4–6 menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, dan public IP address yang masih akan Anda pakai.

**Topik:** custom role dengan hak akses minimum, managed identity user-assigned dengan data role, dan app registration yang satu-satunya kredensialnya adalah federated credential — lalu sebuah run GitHub Actions yang sign-in ke Azure dengan OpenID Connect tanpa secret yang disimpan.

## Sebelum menekan tombol rekam

- **Tenant dan subscription demo pribadi**. Saat menyunting video, buramkan juga tenant ID dan client ID: keduanya bukan rahasia, tetapi tidak ada alasan untuk memublikasikannya.
- Jalankan solusi referensi Lab 22 sekali, supaya resource-nya sudah ada, dan simpan output-nya (di luar layar):

  ```bash
  cd azure-fundamentals-lunches/labs/22-identity-access-advanced
  GITHUB_REPO="<your-github-user>/<your-demo-repo>" bash solution.sh
  ```

- Di **repository GitHub pribadi** yang disebut dalam federated credential: tambahkan `github-workflow-example.yml` sebagai `.github/workflows/azure-oidc.yml`, tiga repository secret dan satu repository variable yang dijelaskan di lab, lalu buat branch kedua bernama `feature/test` yang berisi workflow yang sama.
- Tab browser:
  1. Azure portal › *rg-lunch22-&lt;suffix&gt;* › **Access control (IAM)**
  2. Azure portal › **Managed Identities** › *id-nusa-reports*
  3. Microsoft Entra admin center › **App registrations** › *app-nusa-github-deploy-&lt;suffix&gt;*
  4. GitHub › repository Anda › **Actions**

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:25 Custom role yang hanya bisa mengoperasikan VM
01:30 Managed identity user-assigned dengan data role
02:25 App registration tanpa secret
03:35 GitHub Actions sign-in dengan OpenID Connect
04:35 Branch yang salah ditolak
05:20 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 22 · Pipeline tanpa kata sandi dan hak akses minimum" | "Auditor Nusantara Retail menemukan client secret di sebuah build log, dan seorang operator dengan kuasa yang jauh melebihi kebutuhan pekerjaannya. Dalam enam menit kita akan membereskan keduanya: role yang mengerjakan tepat satu tugas, dan pipeline yang sign-in ke Azure tanpa secret yang disimpan." |
| 00:25 | Resource group › tab **Access control (IAM) › Roles** › cari *Nusantara VM Operator* › buka role-nya › tampilan **JSON** | "Inilah custom role kita. Empat operasi pada virtual machine: read, start, restart, dan deallocate — tidak ada create, tidak ada change, tidak ada delete. Dan lihat assignable scopes-nya: hanya resource group ini. Role ini bahkan tidak bisa di-assign di tempat lain." |
| 01:05 | Tab **Role assignments**, difilter ke custom role tersebut | "Role ini di-assign ke grup operator VM pada scope ini. Operator shift malam bisa me-restart VM toko online pukul 3 pagi, tetapi tidak bisa mengubah ukurannya, menghapusnya, atau menyentuh jaringan." |
| 01:30 | Managed Identities › *id-nusa-reports* › **Overview** (tunjuk Client ID dan Object ID) | "Berikutnya, managed identity user-assigned untuk aplikasi pelaporan. Ini adalah resource Azure tersendiri, jadi tetap ada saat compute aplikasinya dibangun ulang. Azure mengelola kredensialnya; tidak ada yang pernah melihatnya." |
| 01:55 | Storage account › **Access control (IAM) › Role assignments**: *Storage Blob Data Reader* untuk identitas tersebut | "Identitas ini memegang satu data role pada satu storage account: Storage Blob Data Reader. Ia bisa membaca ekspor penjualan dan tidak lebih — bahkan tidak bisa menampilkan key milik account itu." |
| 02:25 | App registration › **Certificates & secrets** › tab *Client secrets* (kosong) | "Sekarang pipeline-nya. App registration ini tidak punya client secret maupun certificate — tab-nya kosong, dan akan tetap kosong." |
| 02:45 | Tab **Federated credentials** › buka *github-main-branch* | "Sebagai gantinya, ia punya federated credential. Issuer-nya adalah layanan token GitHub, audience-nya adalah nilai untuk pertukaran token, dan subject-nya menyebut satu repository dan satu branch: main. Entra ID hanya akan memercayai token yang cocok persis dengan ketiganya." |
| 03:15 | **Add credential** › skenario *GitHub Actions deploying Azure resources* (tunjukkan field-nya, lalu batalkan) | "Portal menyusun subject untuk Anda dari organisasi, repository, dan entity type — branch, environment, pull request, atau tag. Batalkan saja; kita sudah punya credential sendiri." |
| 03:35 | GitHub › file workflow: `permissions: id-token: write` dan langkah `azure/login@v3` | "Di GitHub, workflow meminta izin untuk meminta ID token, dan hanya meneruskan client ID, tenant ID, dan subscription ID ke Azure Login. Tidak satu pun dari ketiganya rahasia." |
| 03:55 | **Actions** › jalankan workflow pada *main* › buka log run-nya | "Jalankan di main. Azure Login menukar token GitHub yang berumur pendek dengan access token Azure, dan langkah berikutnya menampilkan apa yang bisa dilihat service principal: satu resource group, hanya-baca." |
| 04:35 | Jalankan workflow pada *feature/test* › langkah login gagal, error dengan `AADSTS700213` | "Sekarang workflow yang sama dari branch lain. GitHub menerbitkan token yang sepenuhnya sah, tetapi subject-nya berakhiran feature/test, dan tidak ada federated credential yang cocok. Entra ID menolak pertukaran itu, dan job tidak pernah mendekati Azure." |
| 05:00 | Salin subject dari pesan error | "Tips bonus: error itu menampilkan subject persis yang dikirim GitHub. Jika suatu saat Anda melihat ini pada branch yang *memang* Anda percayai, itulah nilai untuk federated credential yang baru." |
| 05:20 | Slide rangkuman: custom role · managed identity · federated credential | "Tiga hal untuk diingat. Custom role memberikan tepat operasi yang dibutuhkan sebuah pekerjaan, pada scope yang Anda pilih. Managed identity dan federated credential berarti tidak ada rahasia yang harus disimpan atau dirotasi. Dan subject adalah batas keamanan Anda — buat sesempit pekerjaannya." |

## Setelah merekam
- Tambahkan caption (buat otomatis, lalu koreksi istilah Azure secara manual)
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo) — untuk rekaman berbahasa Indonesia, di `README.id.md`
- Hapus resource demo: jalankan `bash cleanup.sh` di folder lab, lalu hapus workflow, secret, dan variable dari repository GitHub Anda
