# Makan Siang 25 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sebenarnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan
> oleh animasi: peering yang berstatus Connected, user-defined route yang menang di effective routes, Network Watcher
> yang menyebutkan next hop, VM hub yang benar-benar meneruskan paket, dan nama private endpoint yang di-resolve menjadi
> IP privat.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, dan alamat IP publik yang masih akan Anda
> pakai.

## Sebelum menekan tombol rekam
- Di Cloud Shell, bangun lab dalam kondisi sudah selesai satu kali (sekitar 15 menit):
  `cd azure-fundamentals-lunches/labs/25-networking-advanced && bash setup.sh && bash solution.sh`
- Tambahkan storage account dengan private endpoint di hub, untuk bagian DNS (sekitar 3 menit, ada biaya kecil per jam
  untuk endpoint-nya):

  ```bash
  source ../common/config.sh
  RG="$(rg_name 25)"; ST="stnusa25${SUFFIX}"
  az network vnet subnet create -g "$RG" --vnet-name vnet-nusa-hub -n snet-endpoints \
    --address-prefixes 10.30.3.0/24 --default-outbound-access false --output none
  az storage account create -g "$RG" -n "$ST" -l "$LOCATION" --sku Standard_LRS --kind StorageV2 --output none
  az storage account update -g "$RG" -n "$ST" --public-network-access Disabled --output none
  az network private-endpoint create -g "$RG" -n pe-stnusa --vnet-name vnet-nusa-hub --subnet snet-endpoints \
    --private-connection-resource-id "$(az storage account show -g "$RG" -n "$ST" --query id -o tsv)" \
    --group-id blob --connection-name pe-stnusa-conn --output none
  az network private-dns zone create -g "$RG" -n privatelink.blob.core.windows.net --output none
  az network private-dns link vnet create -g "$RG" --zone-name privatelink.blob.core.windows.net -n link-spoke1 \
    --virtual-network vnet-nusa-spoke1 --registration-enabled false --output none
  az network private-endpoint dns-zone-group create -g "$RG" --endpoint-name pe-stnusa -n default \
    --private-dns-zone privatelink.blob.core.windows.net --zone-name blob --output none
  ```

- Siapkan dua perintah di Cloud Shell (jangan dijalankan dulu): uji paket terusan dari Lab 25 Tugas 6, dan pasangan
  perintah `nslookup` yang dipakai di menit 04:35.
- Tab browser yang perlu dibuka lebih dulu:
  1. Portal › `vnet-nusa-hub` › **Peerings**
  2. Portal › network interface milik `vm-spoke1` › **Effective routes**
  3. Portal › **Network Watcher › Next hop**
  4. Portal › network interface milik `vm-hub-nva` › **IP configurations**
  5. Portal › `pe-stnusa` (private endpoint) › **DNS configuration**

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:20 Peering: Connected, dan forwarded traffic diizinkan
01:00 Effective routes: user-defined route yang menang
01:45 Next hop menyebutkan appliance
02:25 Mengubah VM hub menjadi router
03:05 Bukti: paket yang diteruskan oleh hub
03:50 DNS private endpoint: nama, alias, IP privat
05:20 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 25 · Hub-and-spoke di portal" | "Dalam lima menit ke depan, kita akan mengikuti satu paket dari spoke toko online ke spoke back office melalui sebuah router di hub — lalu menyaksikan nama sebuah storage berubah menjadi alamat IP privat." |
| 00:20 | Tab 1: `vnet-nusa-hub` › Peerings, kedua link *Connected* | "Hub punya dua peering, satu ke masing-masing spoke, dan keduanya berstatus Connected. Itu hanya terjadi jika setiap sisi punya link sendiri. Perhatikan juga: tidak ada peering di antara kedua spoke — dan itu disengaja." |
| 00:40 | Buka `vnet-nusa-spoke1` › Peerings › `peer-spoke1-to-hub` | "Di link milik spoke sendiri, setelan yang membuatnya mau menerima forwarded traffic sudah dinyalakan. Tanpa setelan itu, paket yang diteruskan router hub ke spoke ini akan ditolak di depan pintu." |
| 01:00 | Tab 2: effective routes NIC `vm-spoke1`, daftar lengkap | "Inilah rute yang benar-benar diterapkan Azure pada vm-spoke1. Rentangnya sendiri menuju virtual network, rentang hub menuju peering, dan blok privat besar seperti 10.0.0.0/8 menuju None — alias dibuang." |
| 01:20 | Sorot baris `10.32.0.0/16 · User · Virtual appliance · 10.30.1.4` | "Baris ini milik kita: rentang back office, sumbernya User, next hop-nya virtual appliance di 10.30.1.4. Rute ini lebih spesifik daripada /8, jadi ia yang menang. Tanpa rute ini, toko online tidak akan pernah bisa menjangkau back office — peering tidak transitif." |
| 01:45 | Tab 3: Next hop, VM `vm-spoke1`, source `10.31.1.4`, destination `10.32.1.4` › Next hop | "Effective routes menunjukkan seluruh tabel; next hop menjawab satu pertanyaan saja. Dari VM toko online ke VM back office: virtual appliance, 10.30.1.4 — dan ia bahkan menyebutkan route table yang mengambil keputusan itu." |
| 02:05 | Ganti ke `vm-spoke2`, source `10.32.1.4`, destination `10.31.1.4` › Next hop | "Dan untuk balasannya: appliance yang sama. Rute selalu berpasangan; kalau jawaban ini berbeda, sebuah firewall hanya akan melihat separuh dari setiap percakapan." |
| 02:25 | Tab 4: NIC `vm-hub-nva` › IP configurations, **IP forwarding: Enabled** | "Sekarang router-nya sendiri. Secara default, Azure membuang setiap paket yang tiba di sebuah network interface tetapi dialamatkan ke pihak lain. Kotak centang ini — IP forwarding — memberi tahu Azure bahwa VM ini boleh meneruskan lalu lintas." |
| 02:45 | Cloud Shell: baris `/etc/sysctl.d/99-nusa-router.conf` dari lab | "Sakelar kedua ada di Linux: net.ipv4.ip_forward. Lab mengaturnya lewat Run Command dan menuliskannya ke sebuah file supaya tetap berlaku setelah reboot. Lewatkan salah satu sakelar, dan paket mati di hub." |
| 03:05 | Cloud Shell: jalankan uji Tugas 6 — counter, ping dan curl dari `vm-spoke1`, lalu counter lagi | "Bukti, bukan harapan. Kita baca penghitung paket terusan di hub, lakukan ping dan ambil halaman web back office dari VM toko online, lalu baca penghitungnya sekali lagi." |
| 03:30 | Perbesar output: balasan dari `10.32.1.4`, `HTTP from vm-spoke2: OK`, counter naik | "Balasan kembali, halamannya termuat, dan penghitung di hub naik. Lalu lintasnya benar-benar mengambil jalan memutar lewat hub — persis di tempat Azure Firewall akan berdiri di lingkungan produksi." |
| 03:50 | Tab 5: `pe-stnusa` › DNS configuration: FQDN `…blob.core.windows.net`, IP `10.30.3.4` | "Cerita kedua: storage account untuk faktur. Akses publiknya dinonaktifkan; private endpoint ini memberinya sebuah network interface di hub dengan alamat 10.30.3.4." |
| 04:10 | Private DNS zone `privatelink.blob.core.windows.net` › Recordsets, lalu **Virtual network links** | "Private DNS zone ini menyimpan A record untuk akun tersebut, dan zonanya di-link ke spoke toko online. Link itulah kuncinya — VNet mana pun yang tidak punya link tidak akan pernah melihat record ini." |
| 04:35 | Cloud Shell: `nslookup <account>.blob.core.windows.net` (atau `dig` jika nslookup tidak tersedia) | "Dari Cloud Shell, di luar jaringan kita, nama itu melewati alias privatelink dan berakhir di alamat publik. Koneksi ke sana ditolak, karena public network access dimatikan." |
| 04:55 | Cloud Shell: output `az vm run-command invoke … vm-spoke1 … nslookup <account>.blob.core.windows.net` | "Ajukan pertanyaan yang sama dari vm-spoke1: nama publik yang sama, alias yang sama, tetapi kini zona yang ter-link menjawab dengan 10.30.3.4. Connection string aplikasi tidak pernah berubah; DNS-lah yang menentukan pintu mana yang dipakai." |
| 05:20 | Slide rangkuman: "Peering · Rute · Teruskan · Resolusi" | "Tiga hal yang perlu diingat: peering tidak transitif, jadi lalu lintas antar-spoke butuh rute lewat hub; appliance butuh IP forwarding di NIC dan di OS; dan private endpoint hanya berfungsi jika private zone-nya di-link ke VNet Anda. Bangun sendiri di Lab 25." |

## Setelah merekam
- Hapus semuanya, termasuk private endpoint dan storage account: `bash cleanup.sh` di
  `labs/25-networking-advanced`
- Tambahkan teks terjemahan (caption) — buat otomatis, lalu koreksi istilah Azure secara manual: peering, UDR, next hop,
  NVA, privatelink, Private Resolver
- Tambahkan daftar chapter ke deskripsi video
- Tempel link video ke README makan siang (bagian 🎬 Demo)
