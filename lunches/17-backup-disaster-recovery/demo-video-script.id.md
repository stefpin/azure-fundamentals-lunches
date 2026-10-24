# Makan Siang 17 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sebenarnya untuk makan siang ini, yang tidak bisa ditunjukkan oleh
> animasi: sebuah Recovery Services vault dan pengaturan keamanannya, mengaktifkan backup untuk sebuah VM, job backup
> on-demand, dan mengembalikan satu file yang hilang dengan **File Recovery**.
> **Target durasi:** 5–6 menit (video pendek menjaga perhatian penonton; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, alamat IP publik VM, **kata sandi** File
> Recovery, dan prompt Cloud Shell Anda jika menampilkan nama pengguna Anda.

## Sebelum menekan tombol rekam
Video ini direkam dalam **dua sesi**, karena backup pertama butuh waktu. Sesi A menampilkan vault, perlindungan, dan
**Backup now**. Sesi B dimulai setelah job backup melewati fase snapshot-nya, setidaknya 30 menit kemudian.

- Ada dua perbedaan khusus perekaman dibandingkan Lab 17. Pertama, File Recovery menjalankan sebuah skrip yang
  membutuhkan akses jaringan keluar (outbound) dari mesin tempat skrip itu dijalankan, dan Anda membutuhkan shell di
  mesin tersebut, jadi VM untuk video mendapat IP publik dan hanya mengizinkan SSH dari alamat Cloud Shell Anda. (VM
  lab tetap privat dan me-restore lewat disk.) Kedua, portal hanya menawarkan policy Enhanced untuk VM Trusted Launch,
  jadi VM video memakai security type Standard agar DefaultPolicy tetap tampil di layar, sama seperti di lab, yang
  menetapkan policy itu lewat CLI.

  ```bash
  cd azure-fundamentals-lunches/labs/17-backup-disaster-recovery
  source ../common/config.sh && source lab.env
  ensure_rg "$RG" 17
  az vm create -g "$RG" -n "$VM" --image "$VM_IMAGE" --size "$VM_SIZE" --security-type Standard \
    --admin-username "$ADMIN_USER" --generate-ssh-keys --public-ip-sku Standard --nsg-rule NONE --output none
  az network nsg rule create -g "$RG" --nsg-name "${VM}NSG" -n allow-ssh-from-cloud-shell --priority 1000 \
    --access Allow --protocol Tcp --destination-port-ranges 22 --source-address-prefixes "$(my_public_ip)" --output none
  az vm run-command invoke -g "$RG" -n "$VM" --command-id RunShellScript --scripts @vm/write-orders.sh \
    --query "value[0].message" --output tsv
  az backup vault create -g "$RG" -n "$VAULT" -l "$LOCATION" --output none
  az backup vault backup-properties set -g "$RG" -n "$VAULT" --backup-storage-redundancy LocallyRedundant --output none
  ```

- Tab browser: **Overview** vault, **Overview** VM, dan Cloud Shell (Bash) di tab kedua, sudah berada di folder lab.
- Setelah selesai, hapus semuanya dengan `bash cleanup.sh` dari folder lab. Skrip ini menghentikan perlindungan lebih
  dulu, karena vault yang masih memiliki item terlindungi tidak bisa dihapus.

## Chapter video (tempel ke deskripsi video)
```
00:00 Apa yang akan kita lakukan
00:20 Vault dan pengaturan keamanannya
01:00 Mengaktifkan backup untuk VM pesanan
01:45 Backup now dan memantau job-nya
02:30 Menghilangkan file pesanan
03:00 File Recovery: me-mount sebuah recovery point
04:20 Menyalin file kembali dan unmount
05:10 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 17 · Latihan restore pertama Anda" | "Cadangan hanya berharga sejauh ia bisa di-restore. Dalam lima menit ke depan, kita akan melindungi VM pesanan Nusantara Retail dengan Azure Backup, mengambil backup, sengaja menghapus sebuah file, lalu mengembalikannya." |
| 00:20 | **Overview** vault (`rsv-nusa`), lalu **Properties** | "Ini adalah Recovery Services vault: resource terpisah yang menyimpan backup, di luar VM yang dilindunginya. Di Properties, saya mengatur penyimpanannya menjadi locally redundant; itu cukup untuk demo, dan hanya bisa dilakukan sebelum backup pertama." |
| 00:40 | **Properties › Security settings**: bagian soft delete dengan retensi 14 hari | "Inilah pengaturan keamanan yang paling penting: soft delete. Fitur ini aktif, dan di vault versi sekarang tidak bisa dimatikan. Backup yang dihapus menunggu di sini selama 14 hari sebelum benar-benar hilang." |
| 01:00 | **Overview** VM › **Backup + disaster recovery › Backup** | "Sekarang VM-nya. Di halaman Backup, saya memilih vault dan sebuah policy." |
| 01:15 | Drop-down policy: **DefaultPolicy**; tunjuk "daily", "retain 30 days", "instant restore 2 days" | "DefaultPolicy membuat satu backup per hari dan menyimpannya selama 30 hari. Snapshot terbaru juga disimpan di samping disk selama dua hari, jadi restore dari titik yang baru berjalan cepat. Artinya RPO hingga 24 jam. Cukup untuk ekspor harian, tetapi tidak untuk database pesanan." |
| 01:30 | **Enable backup**; notifikasi "Configuring backup" | "Enable backup. Azure menambahkan ekstensi backup ke VM. Tidak ada agen yang harus dipasang manual, dan tidak ada port masuk yang perlu dibuka." |
| 01:45 | VM › **Backup › Backup now** › biarkan retensi default › **OK** | "Backup terjadwal baru berjalan nanti malam. Untuk latihan, saya tidak mau menunggu, jadi: Backup now." |
| 02:00 | Vault › **Monitoring › Backup jobs** › job tersebut › **View details**: sub-tugas *Take Snapshot* dan *Transfer data to vault* | "Job ini punya dua fase. Pertama snapshot, biasanya selesai dalam beberapa menit. Itu sudah menjadi recovery point yang bisa kita pakai untuk restore. Lalu penyalinan ke vault, yang bisa memakan waktu satu jam untuk pertama kalinya." |
| 02:20 | Kartu judul: "Sesi B: 40 menit kemudian" | (tanpa narasi) |
| 02:30 | Cloud Shell: `ssh "$ADMIN_USER@<public IP>"`, lalu `ls -l /data`, `sudo rm /data/orders.csv`, `ls -l /data` | "Empat puluh menit kemudian. Ini file pesanan di VM, dan inilah sore yang sangat buruk itu: file-nya hilang." |
| 03:00 | VM › **Backup › File Recovery** › Step 1: pilih recovery point terbaru | "File Recovery me-mount recovery point sebagai folder biasa, jadi saya tidak perlu me-restore seluruh VM. Langkah pertama: pilih recovery point dari sebelum penghapusan." |
| 03:20 | Step 2: **Download script**; blur kata sandinya; tampilkan nama file yang diunduh | "Langkah kedua: unduh skripnya, dan catat kata sandinya; kata sandi itu hanya berlaku untuk skrip ini. Skrip harus dijalankan di mesin yang bisa menjangkau Azure Backup lewat internet." |
| 03:40 | Cloud Shell: **Upload** skripnya, `scp` ke VM, lalu di sesi SSH jalankan `sudo python3 <script name>.py` dan tempel kata sandinya | "Saya menyalinnya ke VM dan menjalankannya dengan sudo. Skrip ini tersambung ke recovery point melalui iSCSI dan meminta kata sandi tadi." |
| 04:00 | Output skrip yang menampilkan volume yang di-mount; `ls` folder mount yang dicetaknya | "Dan inilah disk-disk dari recovery point, di-mount dalam mode read-only di samping disk yang aktif." |
| 04:20 | `sudo cp <mount folder>/Volume1/data/orders.csv /data/` (gunakan path yang dicetak skrip), lalu `sudo sha256sum -c /var/lib/nusa/orders.sha256` | "Saya menyalin file pesanan kembali dan mencocokkan sidik jarinya dengan sidik jari yang kita simpan saat file itu dibuat. OK: file hasil restore identik." |
| 04:45 | Portal: **File Recovery › Step 3: Unmount disks** | "Selalu akhiri dengan Unmount disks. Kalau tidak, koneksinya tetap terbuka sampai waktunya habis." |
| 05:10 | Slide rangkuman: tiga poin | "Tiga hal yang perlu diingat. Vault menyimpan backup di luar hal yang dilindunginya, dan soft delete menjaganya meskipun ada yang menghapusnya. Policy Anda adalah RPO Anda, jadi pilihlah per sistem. Dan restore yang belum pernah dicoba hanyalah harapan. Di Lab 17, Anda akan menjalankan latihan yang sama pada VM privat, tanpa akses internet sama sekali." |

## Setelah merekam
- Tambahkan caption (teks di layar): buat otomatis, lalu koreksi istilah Azure secara manual (Recovery Services
  vault, soft delete, DefaultPolicy, instant restore, File Recovery, iSCSI)
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video ke README makan siang (bagian 🎬 Demo)
- Hapus resource demo: `bash cleanup.sh` di `labs/17-backup-disaster-recovery` (skrip ini menghapus IP publik dan NSG
  bersama resource group-nya)
