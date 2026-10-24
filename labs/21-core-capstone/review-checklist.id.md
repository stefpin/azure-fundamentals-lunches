# Lab 21 · Tinjauan mandiri Well-Architected

🇬🇧 [Read in English](review-checklist.md)

> **Dipakai di:** [Tugas 9](README.id.md#tugas-9--melakukan-tinjauan-mandiri-well-architected-20-menit) dari [Lab 21 · Proyek capstone](README.id.md)
> **Waktu:** sekitar 20 menit · **Berdasarkan:** lima pilar [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)

Tinjauan hanya berguna jika jujur. Untuk setiap pemeriksaan, lihat buktinya, lalu beri tanda:

- ✅ **beres** — desain melakukan hal ini, dan Anda sudah melihat buktinya
- ⚠️ **sebagian, atau risiko yang diterima** — tuliskan mengapa hal ini bisa diterima *untuk sementara*
- ❌ **belum ada** — masuk ke daftar perbaikan

Kolom **Build lab** menunjukkan apa yang dilakukan Bicep yang disediakan, sehingga Anda juga bisa membandingkannya dengan build buatan Anda sendiri (mode Tantangan). Jalankan perintah-perintahnya dari folder lab setelah `source ../common/config.sh && source lab.env`.

## Reliability (keandalan) — apakah toko tetap berjualan saat ada yang rusak?

| # | Pemeriksaan | Cara melihatnya | Build lab | Tanda Anda | Catatan / langkah berikutnya |
|---|---|---|---|---|---|
| R1 | Lapisan web berjalan di minimal dua availability zone | `az vm list -g "$RG" --query "[].{vm:name, zone:zones[0]}" -o table` | ✅ zone 1 dan 2 | | |
| R2 | Titik masuk tetap hidup saat satu zone hilang | `az network public-ip show -g "$RG" -n "$PIP" --query zones` | ✅ IP zone-redundant (1, 2, 3) | | |
| R3 | Health probe menguji aplikasi, bukan hanya port | `az network lb probe list -g "$RG" --lb-name "$LB" -o table` | ✅ HTTP GET `/health` setiap 5 detik | | |
| R4 | Database tetap hidup saat satu zone hilang | `az sql db show -g "$RG" -s "$SQL" -n "$DB" --query zoneRedundant` | ⚠️ `false` agar lab tetap murah | | Production: zone-redundant |
| R5 | Cadangan ada **dan** restore sudah pernah diuji | `az sql db show -g "$RG" -s "$SQL" -n "$DB" --query earliestRestoreDate` | ⚠️ point-in-time restore (7 hari); belum ada restore yang diuji di sini | | Berlatih di Lab 17 |
| R6 | RTO dan RPO disepakati dengan bisnis, termasuk rencana jika region hilang | catatan Tugas 8 Anda | ⚠️ sudah ditulis; belum ada region kedua | | Makan Siang 28: failover group |
| R7 | Ketahanan diuji dengan sengaja, bukan sekadar diasumsikan | output Tugas 4 Anda | ✅ VM di zone 1 dihentikan, toko tetap buka | | Ulangi setelah setiap perubahan besar |

## Security (keamanan) — apakah hanya orang dan kode yang tepat yang bisa menjangkau data?

| # | Pemeriksaan | Cara melihatnya | Build lab | Tanda Anda | Catatan / langkah berikutnya |
|---|---|---|---|---|---|
| S1 | Tidak ada VM yang punya public IP sendiri; tidak ada SSH atau RDP yang masuk | `az vm list -g "$RG" -d --query "[].{vm:name, publicIp:publicIps}" -o table` | ✅ Run Command untuk tugas admin | | |
| S2 | NSG hanya mengizinkan apa yang dibutuhkan workload | `az network nsg rule list -g "$RG" --nsg-name "$NSG" -o table` | ✅ TCP 80 dari Internet dan AzureLoadBalancer | | |
| S3 | Pembeli memakai HTTPS | buka URL toko online | ❌ hanya HTTP | | TLS di Application Gateway atau Front Door (Makan Siang 27) |
| S4 | Database hanya menerima identitas Microsoft Entra, melalui TLS 1.2+ | `az sql server ad-only-auth get -g "$RG" -n "$SQL"` | ✅ | | |
| S5 | Database tidak bisa dijangkau dari internet | `az sql server firewall-rule list -g "$RG" -s "$SQL" -o table` | ⚠️ public endpoint aktif, tetapi tidak ada firewall rule | | Private endpoint (Makan Siang 28) |
| S6 | Secret disimpan di Key Vault; role di-assign pada scope yang paling sempit | `az role assignment list --scope "$(az keyvault show -n "$KV" --query id -o tsv)" -o table` | ✅ Secrets Officer hanya pada vault | | |
| S7 | Secret dan vault yang terhapus tidak bisa di-purge oleh penyerang | `az keyvault show -n "$KV" --query properties.enablePurgeProtection` | ❌ dimatikan agar cleanup bisa mem-purge lab | | Production: purge protection aktif |
| S8 | Rekomendasi Defender for Cloud sudah ditinjau | Portal › Microsoft Defender for Cloud › Recommendations | ⚠️ bukan bagian dari lab | | CSPM dasar yang gratis (Makan Siang 15) |

## Cost Optimization (pengoptimalan biaya) — apakah kita hanya membayar untuk hal yang menghasilkan nilai?

| # | Pemeriksaan | Cara melihatnya | Build lab | Tanda Anda | Catatan / langkah berikutnya |
|---|---|---|---|---|---|
| C1 | Budget dengan alert mengawasi pengeluaran | `az consumption budget list -g "$RG" -o table` | ✅ setelah Tugas 7 | | |
| C2 | Ukuran VM sesuai dengan beban | `az vm list -g "$RG" --query "[].hardwareProfile.vmSize" -o tsv` | ✅ B-series burstable | | Pantau CPU credit saat beban stabil |
| C3 | Resource yang menganggur akan pause atau scale in | `az sql db show -g "$RG" -s "$SQL" -n "$DB" --query autoPauseDelay` | ✅ serverless pause setelah 60 menit | | |
| C4 | Setiap resource diberi tag untuk laporan biaya | `az resource list -g "$RG" --query "[?tags.workload==null].name" -o tsv` (seharusnya tidak mencetak apa pun) | ✅ tag `workload`, `environment` | | |
| C5 | Ingesti log punya batas atas dan retensi yang masuk akal | `az monitor log-analytics workspace show -g "$RG" -n "$LAW" --query "{cap:workspaceCapping.dailyQuotaGb, days:retentionInDays}"` | ✅ batas 1 GB/hari, 30 hari | | |
| C6 | Diskon komitmen dipertimbangkan untuk beban production yang stabil | [pricing calculator](https://azure.microsoft.com/pricing/calculator/) | ⚠️ tidak relevan untuk lab | | Reservation atau savings plan (Makan Siang 19) |
| C7 | Tidak ada yang berjalan saat tidak dibutuhkan | `bash cleanup.sh` di akhir | ⚠️ tergantung Anda | | |

## Operational Excellence (keunggulan operasional) — bisakah kita men-deploy, mengubah, memantau, dan memperbaikinya dengan aman?

| # | Pemeriksaan | Cara melihatnya | Build lab | Tanda Anda | Catatan / langkah berikutnya |
|---|---|---|---|---|---|
| O1 | Semuanya di-deploy dari kode dan dipratinjau dengan what-if | `infra/` dan `deploy.sh` | ✅ | | |
| O2 | Drift terdeteksi dan diperbaiki | latihan Rusak lalu perbaiki | ⚠️ deploy ulang memperbaiki drift; perubahan manual masih mungkin terjadi | | Deployment stack dengan deny settings (Makan Siang 20) |
| O3 | Alert sampai ke manusia yang bisa bertindak | `az monitor action-group show -g "$RG" -n "$AG" --query emailReceivers` | ⚠️ satu alamat e-mail pribadi | | Mailbox tim, kanal notifikasi kedua |
| O4 | Log dikumpulkan secara terpusat untuk investigasi | query KQL di Tugas 6 | ⚠️ hanya log audit Key Vault | | Azure Monitor Agent untuk VM (Makan Siang 30) |
| O5 | Runbook tersedia untuk kegagalan zone dan untuk restore | catatan Anda | ❌ | | Jadikan catatan Tugas 4 dan Tugas 8 satu halaman |
| O6 | Guardrail mencegah kesalahan umum sebelum terjadi | `az policy assignment list -g "$RG" -o table` | ✅ allowed locations | | Tambahkan tag wajib (Makan Siang 18) |
| O7 | Patch sistem operasi sudah direncanakan | Portal › Azure Update Manager | ⚠️ belum dikonfigurasi | | Makan Siang 23 |

## Performance Efficiency (efisiensi performa) — apakah sistem tetap sanggup saat permintaan berubah?

| # | Pemeriksaan | Cara melihatnya | Build lab | Tanda Anda | Catatan / langkah berikutnya |
|---|---|---|---|---|---|
| P1 | Lapisan web bisa scale out, tidak hanya scale up | `az vm list -g "$RG" -o table` | ⚠️ tetap dua VM | | Scale set dengan autoscale (Makan Siang 23) |
| P2 | Tekanan CPU terlihat sebelum pembeli merasakannya | `az monitor metrics alert list -g "$RG" -o table` | ✅ alert pada CPU 80% | | |
| P3 | Toko sudah diuji beban sebelum masa puncak seperti 12.12 | — | ❌ | | Uji beban (load test) di salinan lingkungan |
| P4 | Konten statis di-cache dekat dengan pembeli | — | ❌ | | Caching Front Door (Makan Siang 27) |
| P5 | Tier database sesuai dengan workload | `az sql db show -g "$RG" -s "$SQL" -n "$DB" --query currentServiceObjectiveName` | ⚠️ request pertama setelah pause harus menunggu database aktif kembali (resume) | | Production: kapasitas minimum yang tidak pernah pause |

## Trade-off yang Anda terima

Tulis masing-masing dalam satu baris. Diri Anda di masa depan (dan auditor) akan berterima kasih.

| Keputusan | Pilar yang terbantu | Pilar yang dikorbankan | Mengapa bisa diterima di sini | Tinjau ulang saat… |
|---|---|---|---|---|
| Database tidak zone-redundant | Cost | Reliability | Lab, tidak ada pesanan sungguhan | Pelanggan sungguhan mulai memakainya |
| Purge protection dimatikan | Operational excellence (pembongkaran yang bersih) | Security | Lab, tidak ada secret sungguhan | Vault production mana pun |
| HTTP alih-alih HTTPS | Kesederhanaan | Security | Tidak ada data pribadi di lab | Sebelum pembeli sungguhan pertama datang |
| | | | | |

## Tiga perbaikan teratas Anda

Pilih tiga tanda yang paling merugikan Nusantara Retail, dan sebutkan apa yang akan Anda kerjakan lebih dulu.

1. …
2. …
3. …

## Rekap nilai (scorecard)

| Pilar | ✅ | ⚠️ | ❌ |
|---|---:|---:|---:|
| Reliability | | | |
| Security | | | |
| Cost Optimization | | | |
| Operational Excellence | | | |
| Performance Efficiency | | | |

Ingin pendapat kedua? Kerjakan penilaian [Azure Well-Architected Review](https://learn.microsoft.com/assessments/azure-architecture-review/) yang gratis untuk toko online, lalu bandingkan rekomendasinya dengan daftar Anda.

---

⬅️ [Kembali ke Lab 21](README.id.md) · 🏠 [Semua lab](../README.id.md) · 🏠 [Beranda kursus](../../README.id.md)

<sub>Terakhir divalidasi: Oktober 2026 · Ada yang tidak berfungsi? [Laporkan masalah lab](../../CONTRIBUTING.md).</sub>
