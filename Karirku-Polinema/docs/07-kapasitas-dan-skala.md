# Kapasitas dan skala: 20.000 pengguna atau lebih

**Jawaban singkat:** ya, arsitektur sekarang (PHP + PostgreSQL) cukup untuk 20.000 akun,
bahkan jauh lebih. Yang menentukan bukan jumlah akun, tetapi **berapa orang membuka
bersamaan** (lonjakan saat lowongan baru atau hari batas lamaran), dan itu diatur lewat
ukuran server serta beberapa pengaturan di bawah ini. Dokumen ini berisi angka yang
diukur, asumsinya, dan tahapan naik skala.

## 1. Yang diukur

Database uji: **20.000 mahasiswa, 2.000 lowongan, 60.000 lamaran** (ukuran database 48 MB,
di luar berkas unggahan). Semua kueri yang dipakai halaman mahasiswa dan perusahaan
selesai di bawah 10 ms. Halaman admin lebih berat karena membaca seluruh data:

| Kueri | Waktu |
|---|---|
| Login (cari akun lewat email) | < 1 ms |
| Daftar lowongan, pencarian FTS, lamaran milik satu mahasiswa | 1 sampai 10 ms |
| Admin: rekap lamaran halaman 1 | **92 ms menjadi 0,8 ms** setelah `idx_lamaran_tanggal` |
| Admin: kartu ringkasan seluruh data | ± 64 ms (bertambah seiring jumlah lamaran) |
| Memasukkan 20.000 lamaran sekaligus (dengan trigger riwayat) | 0,77 detik |

Uji beban halaman (nginx + PHP-FPM 8 pekerja + akun database terbatas, data di atas,
login sebagai mahasiswa, 0 permintaan gagal). **Diukur pada 1 CPU yang dipakai bersama
PostgreSQL, nginx, dan alat uji**, jadi ini batas bawah; server sungguhan dengan core
khusus akan lebih cepat.

| Halaman | Permintaan/detik | Dengan koneksi persisten |
|---|---|---|
| Beranda | 24 | **43** |
| Daftar lowongan | 23 | **38** |
| Cari lowongan (FTS) | 22 | **36** |
| Dasbor mahasiswa | 28 | **48** |
| Lamaran saya | 35 | **73** |

Pada 40 pengunjung bersamaan kecepatannya tetap sama, hanya waktu tunggu naik: CPU jenuh,
bukan database. Biaya terbesar yang ditemukan: **membuka koneksi database baru = 10,7 ms**
(autentikasi SCRAM), sedangkan satu kueri pada koneksi yang sudah terbuka hanya 0,06 ms.
Solusinya `DB_PERSISTEN=1` (bagian 3). Bagian PHP aplikasi sendiri nyaris gratis.

## 2. Perkiraan untuk 20.000 akun

Asumsi (silakan ganti dengan data nyata setelah berjalan): puncak 10% akun online
bersamaan = 2.000 orang, masing-masing memuat satu halaman tiap ± 15 detik, yaitu **± 130
permintaan/detik**. Berkas CSS/JS/gambar dilayani nginx, tidak dihitung.

| Ukuran server | Kira-kira kapasitas halaman dinamis | Cukup untuk |
|---|---|---|
| 2 vCPU / 4 GB | 80 sampai 140 req/detik | ± 1.200 sampai 2.000 pengunjung bersamaan |
| **4 vCPU / 8 GB** | 160 sampai 280 req/detik | **± 2.400 sampai 4.000, sesuai target 20.000 akun** |
| 8 vCPU / 16 GB | 320 sampai 560 req/detik | lonjakan besar, 50.000+ akun |

Perkiraan ini mengalikan hasil uji (40 sampai 70 req/detik per core dengan koneksi
persisten) dengan jumlah core, lalu memberi margin. Belum diuji di server nyata dan belum
mencakup **proses tulis** (melamar dengan unggah berkas) maupun pengiriman email. Setelah
online, ukur ulang dengan lalu lintas sebenarnya.

**Disk:** database kecil (48 MB untuk 20.000 mahasiswa). Yang membesar adalah **berkas
unggahan**. Berkas contoh hanya 4 KB karena data dummy; scan asli biasanya 0,2 sampai 2 MB.
Dengan 3 sampai 5 berkas per mahasiswa, 20.000 mahasiswa = **± 12 sampai 200 GB**. Backup
harian/mingguan/bulanan ikut membesar mengikuti itu: sediakan ruang backup ≥ 3x ukuran
`storage/uploads`, atau kurangi retensi (`KEEP_*`).

## 3. Pengaturan yang disarankan (tahap 1, satu server)

1. **`DB_PERSISTEN=1`** di environment PHP-FPM: ± 1,7x lebih cepat. Koneksi dibersihkan
   tiap dipakai ulang (transaksi menggantung dibuang, kunci dilepas, zona waktu direset;
   teruji dengan satu pekerja yang sengaja meninggalkan transaksi terbuka).
2. **Samakan batas koneksi dan pekerja:** `pm.max_children` di PHP-FPM ≤ batas koneksi akun
   aplikasi (`-v max_koneksi=...` pada `08-hardening-produksi.sql`, bawaan 60), dan jumlah
   keseluruhan < `max_connections` PostgreSQL (bawaan 100). Titik awal: `pm = static`,
   `pm.max_children` = 2 sampai 4 x jumlah core (kerja kita banyak menunggu database).
   Terlalu kecil: antrean. Terlalu besar: memori habis.
3. **Setelan PostgreSQL** (untuk 8 GB RAM, sesuaikan): `shared_buffers = 2GB`,
   `effective_cache_size = 5GB`, `work_mem = 16MB`, `maintenance_work_mem = 256MB`,
   `random_page_cost = 1.1` bila disk SSD. Tool bantu: pgtune.
4. **OPcache aktif** di PHP-FPM (sudah bawaan di paket PHP modern; teruji aktif).
5. **Berkas statis** (CSS/JS/gambar) langsung oleh nginx dengan `expires` panjang, jangan
   lewat PHP.
6. Pantau: CPU, RAM, jumlah koneksi (`select count(*) from pg_stat_activity`), kueri lambat
   (`log_min_duration_statement = 1000`), dan ukuran disk. `STATUS` backup harus berawalan OK.

## 4. Titik lemah yang sudah diketahui (urutan pengerjaan)

Diperoleh dari membaca kode, bukan semuanya diukur; yang berlabel "belum diukur" perlu
dites sebelum dianggap masalah.

| Prioritas | Titik | Mengapa | Solusi |
|---|---|---|---|
| Tinggi | **Email dikirim langsung di dalam permintaan** (`MailService` lewat SMTP) | SMTP lambat atau mati menahan satu pekerja PHP; saat banyak pendaftar bersamaan, semua pekerja bisa habis (belum diukur) | Antrean: simpan ke `log_email` berstatus `antre`, kirim dari tugas cron tiap menit. Tabel sudah punya kolom status dan jumlah percobaan. |
| Tinggi | **Ekspor PDF seluruh rekap** | Mengambil semua baris ke memori; kueri SQL-nya cepat (± 125 ms untuk 60 ribu baris) tetapi merender 60 ribu baris ke PDF belum diukur dan hampir pasti berat | Batasi rentang tanggal atau jumlah baris per ekspor, atau buat ekspor sebagai tugas latar belakang |
| Sedang | **Unduhan berkas lewat PHP** (`readfile`) | Satu pekerja tertahan selama pengunduh menerima berkas | `X-Accel-Redirect` di nginx: PHP hanya memeriksa izin, nginx yang mengirim berkas |
| Sedang | **Kartu ringkasan admin** menghitung seluruh lamaran tiap dibuka | Linier: ± 64 ms di 60 ribu lamaran, ± 0,5 detik di sekitar 500 ribu | Simpan hasilnya 60 detik (cache), atau tabel ringkasan |
| Sedang | **Sesi berbasis berkas** | Hanya jalan di satu server; dua server aplikasi butuh sesi bersama | Redis untuk sesi, atau sticky session di load balancer |
| Rendah | Berkas unggahan di disk lokal | Terikat satu server, ikut memakan ruang backup | Penyimpanan objek (S3 kompatibel) + CDN, bila sudah > 1 server |

## 5. Tahapan naik skala

| Tahap | Pemicu | Tindakan |
|---|---|---|
| **0. Mulai** | < ± 5.000 akun | 1 server 2 vCPU/4 GB, semua di satu mesin, `DB_PERSISTEN=1`, backup + uji pulih |
| **1. Target 20.000** | CPU puncak > 60% atau waktu respons > 500 ms | Naik ke 4 vCPU/8 GB, setelan PostgreSQL, antrean email, ekspor dibatasi, `X-Accel-Redirect` |
| **2. 50.000+ atau lonjakan besar** | CPU database > 60% terus-menerus, atau satu server tak cukup | Pisahkan server database; PgBouncer di depannya; Redis untuk sesi; 2 server aplikasi di belakang load balancer; berkas ke penyimpanan objek + CDN |
| **3. Sangat besar** | Dibaca jauh lebih banyak daripada ditulis dan database jadi leher botol | Replika baca untuk halaman admin/rekap; partisi tabel log/riwayat per tahun |

Catatan PgBouncer (tahap 2): mode *transaction* tidak mempertahankan `SET TIME ZONE` per
sesi dan kunci advisory; pindahkan zona waktu ke pengaturan akun
(`ALTER ROLE karirku_app SET timezone = 'Asia/Jakarta'`) sebelum memakainya. Kerjakan saat
benar-benar perlu, bukan sekarang.

## 6. Keamanan saat pengguna banyak

- **Pembatas percobaan login kini di database** (`percobaan_login`), bukan di sesi.
  Sebelumnya penebak password cukup membuang cookie di tiap percobaan untuk mengulang dari
  nol (teruji: 40 tebakan tanpa terkunci). Sekarang: 5 percobaan salah per (email + IP)
  dalam 15 menit, dan 20 per email dari semua IP. Dampak sampingan yang disadari: akun
  yang sedang diserang dari banyak IP ikut terkunci 15 menit, itu harga untuk menghentikan
  tebakan massal. Di belakang reverse proxy, atur agar `REMOTE_ADDR` berisi IP pengunjung
  asli, kalau tidak semua pengunjung tampak satu IP.
- Wajibkan HTTPS, dan password admin yang kuat (lihat `05-panduan-hosting-aman.md`).
- Pasang pembatas tingkat permintaan di nginx (`limit_req`) untuk halaman login, daftar,
  dan lupa sandi. Pembatas di aplikasi hanya melindungi per akun.
