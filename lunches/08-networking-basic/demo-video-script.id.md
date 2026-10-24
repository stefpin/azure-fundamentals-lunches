# Makan Siang 08 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sesungguhnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan
> oleh animasi: membangun virtual network dengan private subnet, membaca aturan NSG sesuai urutan prioritas, dan
> mendapatkan bukti dari IP flow verify.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan dari layar:** ID subscription, nama tenant, alamat email, dan alamat public IP yang masih akan Anda pakai.

## Sebelum menekan tombol rekam

- Di Cloud Shell, jalankan solusi referensi Lab 08 satu kali agar VM, NAT gateway, dan DNS zone sudah tersedia
  (sekitar 15 menit):
  `cd azure-fundamentals-lunches/labs/08-networking-basic && bash solution.sh`
- Biarkan semuanya persis seperti yang dibangun oleh solusi itu. Selama merekam, Anda membuat VNet *kedua yang kosong*
  (`vnet-demo-record`, `10.99.0.0/16`) hanya untuk menunjukkan wizard pembuatannya, lalu menghapusnya sesudahnya.
- Tab browser yang perlu dibuka lebih dulu:
  1. Portal › **Virtual networks** (tampilan daftar)
  2. Portal › `nsg-app` › **Inbound security rules**
  3. Portal › **Network Watcher › IP flow verify**
  4. Portal › `ng-nusa-app` (NAT gateway) › **Outbound IP**
- Catat public IP Anda sendiri (`curl -s https://api.ipify.org` di Cloud Shell) untuk langkah IP flow verify, tetapi
  jauhkan dari layar atau samarkan saat penyuntingan.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:25 Membuat virtual network dengan private subnet
01:35 Aturan NSG sesuai urutan prioritas
02:35 Application security group dan effective rules
03:30 IP flow verify: diizinkan dan ditolak
04:35 NAT gateway memberi app tier jalan keluar
05:20 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 08 · Virtual networking di portal" | "Dalam lima menit ke depan, kita akan melihat jaringan toko online di portal: private subnet, aturan network security group sesuai urutan prioritas, dan cara membuktikan bahwa sebuah aturan bekerja dengan IP flow verify." |
| 00:25 | Portal › Virtual networks › **+ Create**; tab Basics, nama `vnet-demo-record` | "Membuat virtual network hanya butuh semenit. Region dulu — lingkungan produksi Nusantara Retail akan berada di Indonesia Central; lab memakai Southeast Asia." |
| 00:50 | Tab **IP addresses**: ubah address space ke `10.99.0.0/16`, buka subnet default | "Address space adalah rencananya. Kita tidak pernah bertumpang tindih dengan 10.0.0.0/16 milik kantor pusat. Di dalam pengaturan subnet, perhatikan opsi private subnet: opsi ini aktif secara default, jadi VM di sini tidak mendapat akses internet keluar default." |
| 01:20 | Review + create (tidak perlu menunggu selesai), pindah ke tab 2 | "Itulah seluruh wizard-nya. Sekarang mari kita lihat jaringan yang kita bangun di lab." |
| 01:35 | `nsg-app` › **Inbound security rules**, aturan default terlihat | "Ini nsg-app di subnet app. Dua aturan buatan kita di atas, tiga aturan default di bawah. Azure membacanya dari nomor terkecil ke atas, dan kecocokan pertama yang menang." |
| 02:00 | Arahkan kursor ke aturan 100, lalu aturan 4000, lalu AllowVnetInBound di 65000 | "Aturan 100 mengizinkan web server menjangkau port 8080. Aturan 4000 menolak semua yang lain dari dalam virtual network — dan ini penting, karena tanpa aturan itu, aturan default di 65000 akan mengizinkannya." |
| 02:35 | Buka aturan 100: **Source = Application security group**, `asg-web` | "Sumbernya bukan alamat IP. Sumbernya application security group, asg-web. VM mana pun yang network interface-nya bergabung ke grup itu otomatis tercakup — tanpa mengubah aturan ketika Dewi menambah web server ketiga." |
| 03:00 | `vm-app` › Networking › **Effective security rules** | "Effective security rules menampilkan gabungan aturan yang benar-benar diterapkan platform, dengan grup dan service tag yang sudah dijabarkan menjadi alamat sungguhan. Kalau ragu, percayai tampilan ini, bukan catatan Anda." |
| 03:30 | Tab 3: **IP flow verify**; VM `vm-app`, inbound, TCP, local `10.20.2.4:8080`, remote `10.20.1.4:50000` › Check | "IP flow verify menguji satu paket terhadap aturan tanpa mengirim apa pun. Web server ke app server di port 8080: Access allowed, dan alat ini menyebutkan aturannya — Allow-Web-To-App-8080." |
| 04:00 | Ubah local port ke `22` › Check | "Sumber yang sama, port 22: ditolak, oleh Deny-VNet-Inbound. Kalau suatu hari ada yang menambahkan aturan siluman di prioritas 90, alat ini memberi tahu namanya dalam hitungan detik." |
| 04:20 | Ubah VM ke `vm-web`, local `10.20.1.4:22`, remote IP Anda (disamarkan) › Check | "Dan SSH dari internet ke web server: ditolak oleh aturan default DenyAllInBound. Public IP Standard tetap tertutup kecuali ada aturan yang membukanya." |
| 04:35 | Tab 4: NAT gateway › **Outbound IP**, lalu **Subnets** | "App tier tidak punya public IP dan tinggal di private subnet, jadi secara default ia tidak punya jalan keluar. NAT gateway ini terpasang di snet-app dan memberi setiap VM di sana satu alamat keluar yang statis — dan tidak menerima apa pun dari luar." |
| 05:00 | Cloud Shell: hasil `az vm run-command invoke … vm-app … curl -s https://api.ipify.org` | "Buktinya: dari dalam vm-app, internet melihat persis alamat NAT gateway. Penyedia pembayaran bisa memasukkannya ke allow list." |
| 05:20 | Slide rangkuman: "Rencana · Aturan · Jalur · Bukti" | "Tiga hal yang perlu diingat: rencanakan alamat yang tidak pernah tumpang tindih; aturan dibaca dari nomor terkecil dan kecocokan pertama yang menang; dan aturan allow adalah izin, bukan jalur. Sekarang bangun sendiri di Lab 08." |

## Setelah merekam
- Hapus VNet demo: `az network vnet delete -g <its resource group> -n vnet-demo-record`
- Hapus resource lab: `bash cleanup.sh` di `labs/08-networking-basic`
- Tambahkan teks (caption): buat otomatis, lalu koreksi istilah Azure secara manual: NSG, ASG, CIDR, NAT gateway, IP flow verify
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
