# Makan Siang 26 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sebenarnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan
> oleh animasi: VPN gateway yang zone-redundant, koneksi VNet-to-VNet yang mencapai *Connected*, lalu lintas yang
> menyeberangi tunnel, rute yang ditambahkan Azure, dan letak pilihan ExpressRoute serta Virtual WAN di portal.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, alamat IP publik milik gateway, dan shared key
> (jangan pernah menjalankan `shared-key show` di depan kamera).

## Sebelum menekan tombol rekam
- **Setidaknya satu jam sebelum merekam**, di Cloud Shell (Bash):

  ```bash
  cd azure-fundamentals-lunches/labs/26-hybrid-connectivity
  source ../common/config.sh
  RG=$(rg_name 26)
  bash setup.sh            # starts two VpnGw1AZ gateways; they need 30-45 minutes or more
  ```

- Ketika kedua gateway sudah menunjukkan `Succeeded`, kerjakan Lab 26 Tugas 4 (kedua koneksi) di luar kamera, atau
  simpan untuk rekaman jika Anda tidak keberatan memotong bagian saat status berubah dari *Connecting* menjadi
  *Connected*.
- Jalankan uji lalu lintas Tugas 6 sekali di luar kamera, supaya ekstensi Run Command sudah terpasang di `vm-azure-1`.
- **Pengingat biaya:** kedua gateway ditagih setiap jam keberadaannya. Rekam di hari yang sama dan jalankan
  `bash cleanup.sh` segera sesudahnya.
- Tab browser yang perlu dibuka lebih dulu:
  1. `vgw-nusa-azure` › **Overview** dan **Configuration**
  2. `vnet-nusa-azure` › **Subnets**
  3. `vgw-nusa-azure` › **Connections**
  4. `vm-azure-1` › **Networking** › network interface › **Effective routes**
  5. **Create a resource** › ExpressRoute (formulir pembuatan circuit — tidak akan Anda kirim)
  6. **Create a resource** › Virtual WAN (formulir pembuatan — tidak akan Anda kirim)
  7. Cloud Shell (Bash) di folder lab, dengan ukuran font diperbesar dan `RG` sudah diatur

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:25 Dua jaringan dan GatewaySubnet masing-masing
01:00 VPN gateway yang zone-redundant
01:45 Koneksi VNet-to-VNet: Connected
02:35 Lalu lintas melewati tunnel
03:20 Rute yang ditambahkan Azure
04:00 Tempat pilihan ExpressRoute dan Virtual WAN
05:15 Rangkuman dan pembersihan
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 26 · Menghubungkan kantor pusat" | "Kantor pusat Nusantara Retail di Jakarta membutuhkan jalur privat ke Azure. Dalam lima menit ke depan, kita akan melihat VPN gateway sungguhan, menghidupkan tunnel terenkripsi, dan melihat di mana posisi ExpressRoute dan Virtual WAN." |
| 00:25 | `vnet-nusa-azure` › **Subnets**: `snet-app` dan `GatewaySubnet` (/27); lalu ruang alamat VNet kantor pusat 10.0.0.0/16 | "Dua virtual network: Azure di 10.40.0.0/16, dan kantor pusat simulasi di 10.0.0.0/16. Rentangnya tidak tumpang-tindih — itu memang sengaja direncanakan. Masing-masing punya subnet yang namanya persis GatewaySubnet, berukuran /27, tanpa isi lain dan tanpa network security group." |
| 01:00 | `vgw-nusa-azure` › **Overview**: SKU **VpnGw1AZ**, VPN type **Route-based**, generation 1 | "Inilah VPN gateway di sisi Azure. SKU-nya VpnGw1AZ — SKU AZ adalah yang dipakai untuk gateway baru — dan tipenya route-based, yang dibutuhkan oleh point-to-site, BGP, dan active-active." |
| 01:25 | `vgw-nusa-azure` › **Configuration**: active-active **Disabled**, BGP **Disabled**; lalu resource IP publik yang menunjukkan zona 1, 2, 3 (samarkan alamatnya) | "Untuk lab ini, gateway berjalan active-standby tanpa BGP. Di produksi, saya akan mengaktifkan keduanya. IP publik Standard-nya zone-redundant, jadi kegagalan satu zona di region tidak ikut membawa pergi alamatnya. Pembuatan gateway ini memakan waktu sekitar empat puluh menit." |
| 01:45 | `vgw-nusa-azure` › **Connections**: `con-azure-to-hq` dan `con-hq-to-azure`, status **Connected** | "Dua koneksi, satu untuk setiap arah, keduanya memakai pre-shared key yang sama, yang dibuat oleh lab saat runtime. Status: Connected. Artinya IKE sudah menyepakati kunci dan algoritma, dan IPsec security association sudah aktif." |
| 02:10 | Buka `con-azure-to-hq`: penghitung data in dan data out | "Koneksi ini menunjukkan berapa byte yang masuk dan keluar. Penghitung itulah hal pertama yang perlu diperiksa ketika seseorang bilang VPN-nya mati." |
| 02:35 | Cloud Shell: Run Command dari Tugas 6 — `ping` dan `curl` dari `vm-azure-1` ke 10.0.1.10 | "Sekarang lalu lintas sungguhan. Dari VM Azure, saya melakukan ping ke alamat privat VM kantor pusat, 10.0.1.10, lalu mengambil halaman web-nya. Kedua VM tidak punya IP publik; paket-paketnya berjalan terenkripsi di antara kedua gateway." |
| 03:00 | Output: 4 balasan, lalu "Served by vm-hq-1" | "Ada balasan, dan halamannya menyatakan dilayani oleh vm-hq-1. Sebelum koneksi dibuat, perintah yang sama kehilangan setiap paketnya." |
| 03:20 | NIC `vm-azure-1` › **Effective routes**: baris 10.0.0.0/16 · **Virtual network gateway** | "Kenapa sekarang berhasil? Azure menambahkan rute untuk 10.0.0.0/16 dengan virtual network gateway sebagai next hop. Sebelum koneksi ada, rentang alamat itu jatuh ke rute bawaan yang langsung membuang lalu lintas." |
| 04:00 | Formulir **Create ExpressRoute circuit**: port type, daftar peering location (gulir ke Jakarta), bandwidth, SKU Local/Standard/Premium, billing Metered/Unlimited — lalu **Cancel** | "Untuk lalu lintas yang lebih berat dan stabil, ExpressRoute adalah alternatif privatnya. Di sini Anda memilih penyedia dan peering location — Jakarta punya beberapa — lalu bandwidth, SKU, dan penagihan metered atau unlimited. Saya tidak akan mengirim formulir ini: circuit sungguhan membutuhkan penyedia." |
| 04:40 | Formulir **Create Virtual WAN**: type **Basic** vs **Standard** — lalu **Cancel** | "Dan ketika empat puluh toko bergabung, Virtual WAN memberi Anda hub terkelola. Basic hanya melayani site-to-site VPN; Standard menambahkan ExpressRoute, user VPN, transit antar-jaringan, dan Azure Firewall." |
| 05:15 | Cloud Shell: `bash cleanup.sh` | "Tiga hal yang perlu diingat: rencanakan alamat yang tidak pernah tumpang-tindih, selalu pilih SKU AZ dan sebutkan secara eksplisit, dan di lab, hapus gateway pada hari yang sama — gateway ditagih setiap jam. Pembersihannya sedang berjalan sekarang." |

## Setelah merekam
- Tambahkan teks terjemahan (caption) — buat otomatis, lalu koreksi istilah Azure secara manual: GatewaySubnet,
  VpnGw1AZ, IKE, IPsec, ExpressRoute.
- Tambahkan daftar chapter ke deskripsi video.
- Tempel link video ke README makan siang (bagian 🎬 Demo).
- Pastikan resource demo sudah hilang: `az group list --tag lunch=26 --output table` seharusnya tidak menampilkan apa
  pun setelah beberapa menit.
