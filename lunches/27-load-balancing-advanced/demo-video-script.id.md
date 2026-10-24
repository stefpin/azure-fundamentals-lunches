# Makan Siang 27 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menunjukkan pengalaman Azure yang sesungguhnya untuk makan siang ini — listener, path rule, dan backend
> health sebuah Application Gateway, WAF policy yang dialihkan ke mode Prevention lalu memblokir request sungguhan,
> serta failover Traffic Manager yang terlihat lewat DNS — hal-hal yang hanya bisa disimulasikan oleh animasi.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, alamat IP publik gateway, dan nama host
> aplikasi jika Anda tetap menyimpannya setelah merekam.

## Sebelum menekan tombol rekam

- Gateway butuh 5–15 menit untuk dibuat, jadi bangun semuanya **30–40 menit sebelum merekam**, lalu kembalikan WAF ke
  mode Detection agar Anda bisa mengaktifkan Prevention di depan kamera:

  ```bash
  cd azure-fundamentals-lunches/labs/27-load-balancing-advanced
  source ../common/config.sh && source lab.env
  bash setup.sh && bash solution.sh
  load_hosts; GW_IP=$(gw_ip)
  az network application-gateway waf-policy policy-setting update -g "$RG" --policy-name "$WAF_POLICY" \
    --mode Detection --state Enabled --request-body-check true --output none
  ```

- Tab browser: (1) portal yang terbuka di resource group `rg-lunch27-<suffix>`; (2) Azure Cloud Shell (Bash) dengan
  baris-baris `source`, `load_hosts`, dan `GW_IP=$(gw_ip)` yang sudah dijalankan, dan layar yang sudah dibersihkan.
- Siapkan baris-baris berikut untuk ditempel di Cloud Shell:
  - `curl -s "http://${GW_IP}/" | grep -o "Served by the [A-Z]* app"` (dan yang sama untuk `/images/`)
  - `curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://${GW_IP}/?id=1%27%20OR%201%3D1--"`
  - `az webapp stop -g "$RG" -n "$APP_STORE"` dan `tm_watch 9`
- Dua waktu tunggu dipotong saat editing: sekitar satu menit setelah mengganti mode WAF, dan sekitar satu menit selama
  failover. Ucapkan "kita lompat sedikit ke depan" di depan kamera agar potongannya terasa alami.
- Gateway ditagih setiap jam selama ia ada: jalankan `bash cleanup.sh` begitu Anda sudah mendapatkan semua take yang
  dibutuhkan.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:20 Dua aplikasi dan satu gateway
00:45 Listener, rule, dan path map
01:35 Backend settings dan nama host App Service
02:10 Backend health dan tes singkat
02:35 WAF: dari Detection ke Prevention
03:50 Traffic Manager: endpoint berprioritas
04:25 Failover lewat DNS
05:25 Rangkuman
```

## Naskah per adegan

| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 27 · Melindungi dan merutekan toko online" | "Toko online Nusantara Retail butuh tiga hal: satu alamat untuk dua aplikasi, perlindungan dari serangan, dan rencana ketika sebuah situs mati. Dalam enam menit, kita lihat ketiganya langsung di portal yang sebenarnya." |
| 00:20 | Portal › resource group `rg-lunch27-<suffix>`: plan, dua aplikasi, `agw-nusa`, `waf-nusa`, `pip-agw-nusa`, `tm-nusa` | "Ini resource group lab kita: aplikasi toko online dan aplikasi gambar di App Service plan Free, sebuah Application Gateway dengan WAF policy dan IP publiknya, serta sebuah profil Traffic Manager." |
| 00:45 | `agw-nusa` › *Overview* (SKU WAF_v2, autoscale 1–2), lalu *Listeners* › `appGatewayHttpListener` (HTTP, port 80) | "Gateway ini memakai SKU WAF_v2 dan melakukan autoscale antara satu dan dua instance supaya lab tetap murah. Listener-nya menunggu HTTP di port 80. Di produksi, ini akan menjadi HTTPS dengan sertifikat dari Key Vault." |
| 01:05 | *Rules* › `rule1` › tab *Backend targets*: path-based, `/images/*` → `pool-images`, default → `appGatewayBackendPool` | "Rule menghubungkan listener ke target-targetnya. Rule ini path-based: apa pun di bawah slash-images pergi ke pool gambar, dan semua yang lain ke pool default, yang berisi toko online." |
| 01:35 | *Backend settings* › `appGatewayBackendHttpSettings`: HTTPS 443, *Override with new host name* = yes, *Pick host name from backend target*, custom probe `probe-app` | "Backend settings mengatur cara berbicara dengan aplikasi: HTTPS di 443. Sakelar inilah yang paling penting. App Service menemukan aplikasi dari nama host-nya, jadi gateway harus mengirim nama milik masing-masing aplikasi, bukan nama yang diketik pembeli." |
| 02:10 | *Monitoring* › *Backend health*: kedua nama host aplikasi **Healthy**; lalu Cloud Shell: dua baris `curl` | "Backend health memastikan kedua aplikasi menjawab probe. Tes singkat dari Cloud Shell: path root dilayani aplikasi toko online, slash-images oleh aplikasi gambar — satu alamat, dua aplikasi." |
| 02:35 | `waf-nusa` › *Overview* (policy mode **Detection**) dan *Managed rules* (Microsoft_DefaultRuleSet 2.2); Cloud Shell: `curl` serangan → `HTTP 200` | "Sekarang firewall-nya. Policy ini memakai Default Rule Set dari Microsoft, versi 2.2, dan dimulai di mode Detection. Saya kirim probe SQL injection klasik… dan request-nya lolos dengan 200. Mode Detection hanya menulis entri log." |
| 03:05 | *Policy settings* › Mode **Prevention** › *Save* (atau *Switch to prevention mode* di *Overview*); potong; Cloud Shell: `curl` serangan → `HTTP 403`, lalu `/?id=42` → `HTTP 200` | "Alihkan ke Prevention lalu simpan. Perubahannya butuh satu menit untuk sampai ke gateway, jadi kita lompat sedikit ke depan. Request yang sama: 403 Forbidden. Rule SQL injection berkategori critical, bernilai lima poin, dan lima adalah ambang blokirnya. Request normal tetap berjalan." |
| 03:50 | `tm-nusa` › *Overview* (nama DNS, routing method **Priority**); *Endpoints* (`ep-store` prioritas 1, `ep-images` prioritas 2, keduanya **Online**); *Configuration* (DNS TTL 30, HTTPS, probing setiap 10 detik) | "Traffic Manager hanya bekerja di DNS. Profil ini memakai routing Priority: toko online lebih dulu, aplikasi gambar sebagai pengganti region kedua. Ia memeriksa keduanya lewat HTTPS setiap sepuluh detik, dan jawabannya berlaku selama tiga puluh detik." |
| 04:25 | Cloud Shell: `dig +noall +answer nusa-shop-<suffix>.trafficmanager.net` → CNAME ke `app-nusa-store-…`; `az webapp stop …`; `tm_watch 9`; potong; `ep-store:Degraded`, jawaban → `app-nusa-img-…` | "Jawaban DNS mengarah ke toko online. Sekarang saya hentikan aplikasi toko online. Kita lompat sekitar satu menit: endpoint-nya Degraded dan jawaban DNS yang baru menyebut standby. Siapa pun yang sudah menyimpan jawaban lama tetap memakainya hingga tiga puluh detik — itulah kompromi DNS." |
| 05:05 | Cloud Shell: `az webapp start -g "$RG" -n "$APP_STORE"` dan `tm_watch 6` | "Nyalakan lagi aplikasinya, dan begitu health check-nya lolos, toko online kembali ke urutan teratas jawaban DNS." |
| 05:25 | Slide rangkuman: Application Gateway (regional, layer 7) · WAF policy (Detection → Prevention) · Front Door (edge global) · Traffic Manager (DNS) | "Tiga hal yang perlu diingat: perbaiki nama host untuk backend App Service, mulai WAF di Detection dan akhiri di Prevention, dan ketika failover DNS terlalu lambat, lirik Front Door. Lab-nya memandu Anda melalui semuanya — termasuk bersih-bersihnya." |

## Setelah merekam

- Tambahkan caption atau subtitel (buat secara otomatis, lalu koreksi istilah Azure secara manual: *Application
  Gateway*, *WAF_v2*, *listener*, *backend settings*, *Default Rule Set*, *Traffic Manager*).
- Tambahkan daftar chapter ke deskripsi video.
- Tempel tautan video ke README makan siang (bagian 🎬 Demo).
- Segera hapus resource demo: `bash cleanup.sh` di `labs/27-load-balancing-advanced`.
- Samarkan (blur) alamat IP publik gateway dan nama host aplikasi saat editing jika terlihat.
