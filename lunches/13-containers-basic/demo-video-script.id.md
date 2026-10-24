# Makan Siang 13 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menunjukkan pengalaman Azure yang sesungguhnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan
> oleh animasi: image di registry sungguhan, container app yang menarik image itu dengan managed identity, replica yang
> benar-benar bermunculan saat diberi beban, dan pembagian trafik yang dikonfigurasi di portal.
> **Target durasi:** sekitar 5½ menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat email, dan alamat IP publik yang masih akan Anda pakai.

## Sebelum menekan tombol rekam

- Buat bagian-bagian yang lambat lebih dulu (sekitar 5 menit) dari Cloud Shell, supaya video tidak perlu
  menunggunya:

  ```bash
  cd azure-fundamentals-lunches/labs/13-containers-basic
  source ../common/config.sh
  RG=$(rg_name 13); ACR_NAME="acrnusa${SUFFIX}"; APP=ca-nusa-storefront
  ensure_rg "$RG" 13
  az acr create --resource-group "$RG" --name "$ACR_NAME" --sku Basic --location "$LOCATION" --output none
  az acr import --name "$ACR_NAME" --source mcr.microsoft.com/azuredocs/aks-helloworld:v1 --image storefront:v1
  az containerapp env create --name cae-nusa --resource-group "$RG" --location "$LOCATION" --output none
  LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer --output tsv)
  ```

- Siapkan perintah panjang `az containerapp create` dari Lab 13, Tugas 3 di sebuah editor teks agar tinggal Anda tempel.
- Tempel juga loop beban dari Tugas 4 ke editor yang sama, dengan `FQDN` diisi setelah aplikasinya ada.
- Tab browser yang perlu dibuka lebih dulu: portal Azure di resource group `rg-lunch13-<suffix>`; halaman
  **Repositories** milik registry; Cloud Shell (Bash) di tab kedua, dengan ukuran font diperbesar.
- Tunggu setidaknya lima menit setelah request uji terakhir sebelum merekam chapter 5, supaya aplikasi mulai dari nol
  replica.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:20 Image di registry privat Anda
01:00 Membuat container app dari CLI
01:45 Ingress, identity, dan scale rule di portal
02:40 Dari nol ke lima replica di bawah beban
03:50 Revision kedua dan pembagian 80/20
05:00 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 13 · Dari registry ke container app yang bisa menyusut hingga nol" | "Dalam lima menit ke depan, Anda akan melihat image toko online Nusantara Retail berpindah dari registry privat ke sebuah container app yang tidur di nol replica, bangun ketika pembeli datang, dan membagi trafik di antara dua versi." |
| 00:20 | Portal › Container registries › acrnusa… › **Repositories** › storefront › tag **v1** | "Ini Azure Container Registry privat kita. Repository storefront menyimpan tag v1. Perhatikan digest-nya: tag adalah label yang bisa kita pindahkan, sedangkan digest mengunci isi yang persis." |
| 00:45 | Registry › **Settings › Access keys**: admin user tidak dicentang | "Admin user dalam keadaan nonaktif. Tidak ada bagian demo ini yang memakai kata sandi registry; aplikasinya akan sign-in dengan managed identity." |
| 01:00 | Cloud Shell: tempel perintah `az containerapp create` dari Lab 13, Tugas 3; sorot `--registry-identity system`, `--target-port 80`, `--min-replicas 0` | "Kita membuat container app dari registry. Ada tiga flag yang penting: registry identity system, yang mengaktifkan managed identity dan memberinya AcrPull; target port 80, tempat aplikasi ini mendengarkan; dan minimum nol replica." |
| 01:30 | Perintah selesai; jalankan `az containerapp show ... --query properties.configuration.ingress.fqdn`; buka URL-nya di tab baru | "Ini alamat HTTPS-nya. Request pertama butuh beberapa detik: itulah cold start, yaitu sebuah replica yang sedang dinyalakan dari image." |
| 01:45 | Portal › Container Apps › ca-nusa-storefront › **Settings › Ingress** | "Ingress-nya external, trafik menuju target port 80, dan HTTPS sudah diurus untuk kita." |
| 02:05 | **Settings › Identity** (System assigned: On), lalu **Azure role assignments** yang menampilkan AcrPull pada registry | "System-assigned identity sudah ada dan memegang AcrPull pada registry kita, dan hanya pada registry kita. Itulah prinsip hak akses minimum (least privilege), tanpa secret yang perlu dirotasi." |
| 02:25 | **Application › Scale**: min 0, max 5, HTTP rule dengan 10 request bersamaan | "Inilah scale rule-nya: tambah satu replica untuk kira-kira setiap sepuluh request bersamaan, tidak pernah lebih dari lima, dan nol ketika tidak ada yang berbelanja." |
| 02:40 | **Application › Revisions and replicas** (*Revision management* di beberapa versi portal): 0 replica. Pindah ke Cloud Shell, jalankan loop beban | "Saat ini tidak ada replica yang berjalan, jadi tidak ada biaya compute. Mari kita mainkan promo 12.12: empat puluh request sekaligus selama dua menit." |
| 03:05 | Kembali ke **Revisions and replicas**, refresh setiap 15 detik: jumlah replica naik ke 5 | "Replica bermunculan seiring beban meningkat, dan berhenti di lima, batas maksimum kita. Batas itu melindungi tagihan sekaligus platformnya." |
| 03:30 | **Monitoring › Metrics**: Replica Count (Max) dan Requests selama 30 menit terakhir | "Metric-nya menceritakan kisah yang sama. Ketika trafik berhenti, platform menunggu masa tenang selama lima menit, lalu menyusut kembali ke nol." |
| 03:50 | **Revisions and replicas › Choose revision mode › Multiple**; lalu trafik ke revision saat ini = 100%; **Save** | "Agar rilis berjalan aman, kita izinkan beberapa revision aktif sekaligus, lalu kita kunci semua trafik ke revision saat ini sebelum men-deploy apa pun yang baru." |
| 04:15 | **Create new revision** › edit container › environment variable `TITLE` = "Nusantara Retail storefront v2" › suffix `v2` › **Create** | "Environment variable baru adalah perubahan di tingkat revision, jadi ia membuat revision v2. Revision itu aktif, tetapi belum menerima pembeli." |
| 04:35 | Kolom Traffic: v1 = 80, v2 = 20 › **Save** | "Sekarang canary-nya: delapan puluh persen tetap di v1, dua puluh persen menuju v2." |
| 04:45 | Cloud Shell: sampel 40 request `curl` yang di-pipe ke `sort` dan `uniq -c` | "Empat puluh request: sebagian besar dijawab oleh v1, kira-kira satu dari lima dijawab oleh v2. Kalau v2 bermasalah, kita kembalikan bobotnya ke nol dalam hitungan detik." |
| 05:00 | Slide rangkuman: "Image → registry → managed identity → revision → menyusut hingga nol" | "Ada tiga hal yang perlu diingat. Build image sekali dan simpan di registry privat. Biarkan layanan menarik image dengan managed identity. Dan biarkan Container Apps menyesuaikan skalanya dengan jumlah pembeli Anda, sampai ke nol. Sekarang giliran Anda di Lab 13." |

## Setelah merekam
- Tambahkan teks (caption): buat otomatis, lalu koreksi istilah Azure secara manual: Container Apps, ACR, AcrPull, KEDA,
  revision
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: `bash labs/13-containers-basic/cleanup.sh`
