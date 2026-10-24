# Makan Siang 23 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sesungguhnya untuk makan siang ini — wizard pembuatan scale set (zona,
> autoscale, Spot, kesehatan, dan perbaikan), scale set sungguhan yang melakukan scale-out di bawah beban beserta run
> history-nya, dan patch assessment di Azure Update Manager. Bagian-bagian inilah yang tidak bisa ditampilkan animasi.
> **Target durasi:** sekitar 5 menit 30 detik (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah di subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema default.
> **Sembunyikan dari layar:** ID subscription, nama tenant, alamat e-mail, alamat IP publik yang akan terus Anda pakai.

## Sebelum menekan tombol rekam

- Scale set sungguhan untuk diperlihatkan, dibangun dari lab sekitar 30 menit sebelumnya (kuota: hingga 6 vCPU dengan ukuran
  default 2 vCPU):

  ```bash
  cd ~/azure-fundamentals-lunches/labs/23-virtual-machines-advanced
  bash setup.sh && bash solution.sh
  ```

- Sekitar **10 menit sebelum merekam**, mulai beban CPU pada instance agar scale-out terjadi selagi Anda merekam:

  ```bash
  source ../common/config.sh && RG=$(rg_name 23)
  for vm in $(az vm list -g "$RG" --query "[?virtualMachineScaleSet].name" -o tsv); do
    az vm run-command invoke -g "$RG" -n "$vm" --command-id RunShellScript \
      --scripts @load-cpu.sh --parameters 900 --query "value[0].message" -o tsv
  done
  ```

- Tab browser: (1) *Virtual machine scale sets › Create* (akan Anda batalkan di akhir); (2) `vmss-web` milik lab
  › *Instances*; (3) `vmss-web` › *Scaling* › *Run history*; (4) *Azure Update Manager › Machines*.
- Jika scale-out belum terjadi saat Anda tiba di bab 5, jeda rekaman dan lanjutkan setelah run history menampilkannya —
  jangan dipalsukan.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lihat
00:20 Scale set Flexible di tiga zona
01:20 Aturan autoscale di wizard
02:00 Spot, jaringan, kesehatan, dan automatic repairs
02:40 Scale set sungguhan: instance di setiap zona
03:20 Beban, scale-out, dan run history
04:20 Patch assessment dengan Azure Update Manager
05:10 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 23 · Siap menghadapi 12.12" | "Promo 12.12 Nusantara Retail sudah di depan mata. Dalam lima menit, Anda akan melihat bagaimana sebuah scale set membesar dengan sendirinya, bertahan saat satu zona gagal, dan tetap ter-patch." |
| 00:20 | Tab 1, **Basics**: orchestration mode *Flexible*; availability zones *1, 2, 3*; security type *Trusted launch*; image *Ubuntu Server 24.04 LTS* | "Orkestrasi Flexible adalah mode yang direkomendasikan: setiap instance adalah VM biasa. Saya memilih ketiga zona, sehingga Azure menyebar instance ke tiga pusat data. Trusted Launch sudah aktif secara default." |
| 00:55 | Pemilih ukuran; *Instance count* 2 | "Satu ukuran kecil untuk seluruh set. Dua instance sebagai awal — kita tidak pernah mau kurang dari dua zona yang melayani pelanggan." |
| 01:20 | Bagian **Scaling**: scaling mode *Autoscaling* › *Configure*: minimum 2, maksimum 3, scale-out saat CPU > 70% selama 5 menit, scale-in saat CPU < 30% | "Autoscale tinggal di Azure Monitor. Sebuah minimum, sebuah maksimum, dan dua aturan dengan jarak lebar di antaranya — scale-out di atas 70, scale-in di bawah 30 — supaya set tidak flapping." |
| 02:00 | Tab **Spot**: tunjuk *Run with Azure Spot discount*, eviction policy, dan tautan riwayat harga (biarkan nonaktif) | "Kapasitas Spot jauh lebih murah, tetapi bisa diambil kembali dengan pemberitahuan sekitar 30 detik. Cocok untuk batch job; jangan pernah untuk checkout — jadi di sini saya biarkan nonaktif." |
| 02:15 | Tab **Networking**: virtual network, network security group pada NIC yang mengizinkan HTTP; *Load balancing* › Azure load balancer › backend pool yang sudah ada | "Instance otomatis bergabung ke backend pool load balancer. Dan ingat: instance Flexible tidak punya akses keluar bawaan — subnet ini punya NAT gateway." |
| 02:30 | Tab **Health**: *Enable application health monitoring* (HTTP, port 80, path `/health`); *Automatic repairs* aktif, grace period 10 menit. Lalu **Cancel** wizard-nya | "Application Health extension menanyakan /health ke setiap instance. Jika sebuah instance tetap tidak sehat setelah grace period, automatic repairs menggantinya. Wizard ini saya batalkan, lalu saya pindah ke set yang sudah saya bangun sebelumnya." |
| 02:40 | Tab 2, `vmss-web` › **Instances**: kolom nama, zona, dan status | "Inilah set sungguhan dari lab. Setiap instance adalah VM biasa dengan namanya sendiri, di zona yang berbeda." |
| 03:00 | Klik satu instance › **Overview** › Metrics: *Percentage CPU* | "Sepuluh menit lalu saya memulai beban CPU di setiap instance. Ini dia CPU-nya, di 100%." |
| 03:20 | Tab 3, **Scaling** › **Run history**: grafik jumlah instance dan peristiwa scale-out | "Dan inilah keputusan autoscale: rata-rata CPU bertahan di atas 70% selama lima menit, jadi ia menambah satu instance — langsung ke zona yang belum punya instance." |
| 03:50 | Kembali ke **Instances**: instance baru muncul di zona 3, status *Running* | "VM baru ini lahir dari model yang sama: image yang sama, cloud-init yang sama, pool load balancer yang sama. Setelah cool-down dan begitu beban berhenti, autoscale membuangnya lagi." |
| 04:20 | Tab 4, **Azure Update Manager › Machines**, filter ke resource group lab; pilih satu instance › *Check for updates*; lalu buka hasilnya | "Mem-patch sebuah armada: Update Manager menilai instance sesuai permintaan — atau setiap 24 jam — dan menampilkan update kritis, update keamanan, dan update lainnya. Ia butuh akses keluar ke mirror Ubuntu, yang disediakan NAT gateway." |
| 04:50 | Tombol *Schedule updates*, tampilkan formulir maintenance configuration (jangan disimpan) | "Untuk produksi, Anda akan membuat maintenance configuration — misalnya setiap Selasa pukul 02.00 waktu Jakarta — dan membiarkannya mem-patch seluruh set." |
| 05:10 | Slide rangkuman: tiga poin | "Tiga hal untuk diingat: zona mengalahkan availability set untuk bertahan dari gangguan pusat data; autoscale butuh ambang yang berjauhan dan cool-down; dan instance Flexible butuh akses keluar yang eksplisit agar tetap ter-patch. Sekarang cobalah Lab 23 — dan jalankan skrip cleanup-nya setelah selesai." |

## Setelah merekam
- Tambahkan teks/caption (buat otomatis, lalu koreksi istilah Azure secara manual: *Flexible orchestration*, *autoscale*,
  *Spot*, *Update Manager*, *NAT gateway*).
- Tambahkan daftar chapter ke deskripsi video.
- Tempelkan tautan video ke README makan siang (bagian 🎬 Demo).
- Hapus resource demo: `bash cleanup.sh` di folder lab (perintah ini menghapus resource group beserta seluruh isinya).
