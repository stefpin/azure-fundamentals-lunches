# Makan Siang 29 · Naskah video panduan (≤ 6 menit)

🇬🇧 [Read in English](demo-video-script.md)

> **Tujuan:** menampilkan pengalaman Azure yang sebenarnya untuk makan siang ini — bagian yang tidak bisa ditunjukkan
> oleh animasi: cluster AKS sungguhan beserta node resource group-nya, `kubectl` yang berbicara dengan API server, pod
> yang dihapus lalu tergantikan dalam hitungan detik, rolling update yang tidak pernah menjatuhkan satu request pun, dan
> Horizontal Pod Autoscaler yang menambah pod di bawah beban sungguhan.
> **Target durasi:** sekitar 5½ menit (video pendek menjaga perhatian; pecah apa pun yang lebih panjang).
> **Rekam di:** subscription pribadi atau subscription khusus demo — jangan pernah subscription perusahaan.
> **Sebelum merekam:** zoom browser 125–150%, profil browser yang bersih, notifikasi dimatikan, portal dengan tema
> default.
> **Sembunyikan di layar:** ID subscription, nama tenant, alamat e-mail, dan alamat IP publik yang akan terus Anda pakai.
> IP publik storefront ikut terhapus bersama cluster setelah perekaman, tetapi jangan pernah menampilkan alamat jaringan
> Anda sendiri.

## Sebelum menekan tombol rekam

- Buat cluster lebih dulu dari Cloud Shell, persis seperti di Lab 29, Tugas 1. Prosesnya 5 sampai 10 menit dan sejak
  saat itu sudah menimbulkan biaya, jadi rekamlah di hari yang sama:

  ```bash
  cd azure-fundamentals-lunches/labs/29-containers-advanced-aks
  source ../common/config.sh
  RG=$(rg_name 29); AKS=aks-nusa; AKS_NODE_SIZE=${AKS_NODE_SIZE:-Standard_D2s_v5}
  ensure_rg "$RG" 29
  az aks create --resource-group "$RG" --name "$AKS" --location "$LOCATION" --tier free \
    --node-count 1 --node-vm-size "$AKS_NODE_SIZE" --zones 1 2 3 \
    --network-plugin azure --network-plugin-mode overlay \
    --pod-cidr 192.168.0.0/16 --service-cidr 172.16.0.0/16 --dns-service-ip 172.16.0.10 \
    --generate-ssh-keys --output none
  az aks get-credentials --resource-group "$RG" --name "$AKS" --overwrite-existing
  ```

- Jangan terapkan manifest dulu; videolah yang akan melakukannya. Siapkan perintah-perintah berikut di text editor agar
  tinggal ditempel: perintah `az aks show … --output table` dan baris-baris `kubectl apply` dari Lab 29, Tugas 1 dan 2;
  baris penghapusan pod dari Tugas 3; loop pembeli di latar belakang, `kubectl set env`, dan `kubectl rollout undo` dari
  Tugas 4; serta loop pemantau HPA dari Tugas 5.
- Tab browser yang dibuka lebih dulu: Azure portal di **Kubernetes services › aks-nusa**; Cloud Shell (Bash) di tab
  kedua, dengan ukuran font diperbesar; dan satu tab kosong untuk halaman storefront.
- Rekaman ini punya tiga waktu tunggu: IP publik (1–2 menit), rollout (sekitar satu menit), dan HPA (1–2 menit).
  Potong atau percepat bagian itu saat editing, alih-alih mengisinya dengan obrolan.

## Chapter video (tempel ke deskripsi video)
```
00:00 Yang akan kita lakukan
00:20 Cluster dan node resource group-nya
01:10 Men-deploy storefront dengan kubectl
02:05 Self-healing: menghapus sebuah pod
02:30 Rolling update dan rollback
03:35 HPA di bawah beban
04:50 Objek yang sama di portal
05:15 Rangkuman
```

## Naskah per adegan
| Waktu | Di layar | Narasi |
|---|---|---|
| 00:00 | Kartu judul: "Makan Siang 29 · Cluster Kubernetes yang memulihkan, memperbarui, dan menskalakan dirinya sendiri" | "Dalam lima menit ke depan, Anda akan melihat cluster AKS sungguhan menjalankan toko online Nusantara Retail: Kubernetes mengganti pod yang kita hapus, rolling update yang tidak pernah menjatuhkan satu request pun, dan autoscaler yang menambah pod saat beban naik." |
| 00:20 | Cloud Shell: perintah `az aks show … --output table` dari Lab 29, Tugas 1 (state, version, tier, plugin, mode, rentang alamat) | "Inilah cluster kita. Tier Free: control plane tidak dikenai biaya dan tidak ada SLA uptime, dan itu tidak masalah untuk lab. Azure CNI Overlay memberi pod alamat dari rentang privat, dan kita sudah memindahkan rentang service menjauh dari 10.0.0.0/16 milik kantor pusat." |
| 00:45 | Portal › aks-nusa › **Settings › Node pools**: satu pool, satu node, Standard_D2s_v5 | "Satu system node pool dengan satu node berukuran dua vCPU. Di produksi, minimal ada tiga node, tersebar di beberapa zona." |
| 00:55 | **Settings › Properties** › tautan infrastructure resource group → grup `MC_…`: virtual machine scale set, load balancer, public IP, virtual network, network security group | "Perhatikan apa yang tidak ada di sini: control plane. Azure yang menjalankannya untuk kita. Node kita tinggal di sini, di node resource group yang dibuat dan dimiliki AKS. Kita boleh melihat, tetapi tidak mengubah apa pun di sini." |
| 01:10 | Cloud Shell: `kubectl get nodes -L topology.kubernetes.io/zone`, lalu dua baris `kubectl apply` dari Tugas 2 | "kubectl berbicara dengan API server milik cluster. Satu node, Ready, lengkap dengan label zonanya. Sekarang kita serahkan desired state kepada Kubernetes: sebuah namespace, sebuah Deployment dengan tiga replica, sebuah Service LoadBalancer, dan sebuah disruption budget." |
| 01:35 | `kubectl get pods --namespace nusa -o wide`: tiga pod `Running`, `READY 1/1`; lalu `kubectl get service storefront --namespace nusa --watch` (potong waktu tunggunya) | "Tiga pod, sudah dijadwalkan dan berjalan. READY satu dari satu berarti readiness probe sudah menjawab. Service meminta alamat IP publik kepada Azure, dan itu butuh satu atau dua menit." |
| 01:55 | Browser: `http://<EXTERNAL-IP>` menampilkan halaman storefront | "Dan itu dia tokonya, dilayani oleh pod mana pun dari tiga pod siap yang dipilih Service." |
| 02:05 | `kubectl delete pod <first pod> --namespace nusa --wait=false`, lalu `kubectl get pods --namespace nusa --watch` | "Sekarang mari kita rusak sesuatu. Kita hapus satu pod, seolah-olah pod itu crash. Deployment menginginkan tiga, melihat dua, lalu membuat pengganti bernama baru dalam hitungan detik. Tidak ada yang perlu turun tangan." |
| 02:30 | Jalankan loop pembeli di latar belakang dari Tugas 4; `kubectl set env deployment/storefront --namespace nusa TITLE="Nusantara Retail storefront v2"`; `kubectl rollout status …` | "Saatnya v2. Seorang pembeli di latar belakang memanggil situs dua kali per detik sementara kita mengubah pod template. Kubernetes menyalakan satu pod baru, menunggu readiness probe-nya, membuang satu pod lama, lalu mengulanginya." |
| 03:00 | Hitungan si pembeli: hanya `200`; `curl -s "http://${IP}/" \| grep -o "<title>[^<]*</title>"` menampilkan v2 | "Setiap request mendapat 200. Tidak pernah ada kurang dari tiga pod siap di belakang Service, dan judul halaman sekarang menyebut v2." |
| 03:15 | `kubectl rollout undo deployment/storefront --namespace nusa`; `kubectl rollout history …` | "Kalau v2 ternyata punya bug, satu perintah membawa kita kembali ke ReplicaSet sebelumnya dalam hitungan detik, dan riwayatnya menyimpan setiap revisi." |
| 03:35 | `kubectl top pods --namespace nusa`; `kubectl apply -f k8s/hpa.yaml`; `kubectl get hpa storefront --namespace nusa` | "Sekarang promo 12.12. Autoscaler mengukur CPU sebagai persentase dari request setiap pod, di sini lima puluh millicore, dan menargetkan lima puluh persen." |
| 03:55 | `kubectl apply -f k8s/load-generator.yaml`; loop `kubectl get hpa` setiap 15 detik dari Tugas 5 (percepat) | "Sebuah load generator di dalam cluster berperan sebagai kerumunan pembeli. CPU naik jauh di atas target, dan HPA menaikkan jumlah replica menuju batas maksimumnya, sepuluh." |
| 04:30 | `kubectl get pods --namespace nusa -o wide`: sekitar sepuluh pod `Running` di node tersebut | "Pod-pod baru menyala dalam hitungan detik karena node masih punya ruang. Kalau tidak, mereka akan menunggu di Pending, dan cluster autoscaler akan menambahkan node." |
| 04:50 | Portal › aks-nusa › **Kubernetes resources › Workloads** › storefront: daftar pod, lalu event milik deployment | "Portal menampilkan objek yang sama tanpa kubectl: Deployment, pod-podnya, dan event yang menjelaskan setiap perubahan." |
| 05:15 | Slide rangkuman: "Desired state → scheduler → self-healing → rolling update → HPA" | "Tiga hal untuk diingat. Anda menjelaskan desired state, dan Kubernetes terus mewujudkannya. Probe dan request-lah yang membuatnya bisa pulih, diperbarui, dan di-scale dengan aman. Dan Azure menjalankan control plane, tetapi node-nya Anda yang membayar, jadi hapus cluster ini setelah selesai. Sekarang giliran Anda di Lab 29." |

## Setelah merekam
- Tambahkan teks (caption): buat otomatis, lalu koreksi istilah Azure secara manual: AKS, kubectl, kubelet,
  ReplicaSet, HPA, Azure CNI Overlay
- Tambahkan daftar chapter ke deskripsi video
- Tempel tautan video di README makan siang (bagian 🎬 Demo)
- Segera hapus resource demo, karena cluster menimbulkan biaya setiap jam:
  `bash labs/29-containers-advanced-aks/cleanup.sh` (node resource group `MC_…` ikut terhapus bersama cluster)
