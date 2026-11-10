# Panduan hosting aman: database KarirKu Polinema

> Kapasitas dan tahapan naik skala (20.000 akun atau lebih): lihat `07-kapasitas-dan-skala.md`.
> Keamanan lapisan aplikasi web (XSS, hak akses, unggahan, CSP, login): lihat `08-keamanan-aplikasi-web.md`.
> Contoh konfigurasi nginx yang sudah diuji: `contoh-nginx.conf`.

Tujuan: database tidak mudah dibobol, dan kalau suatu hari ada celah di aplikasi,
kerusakannya terkurung. Dokumen ini berisi apa yang **sudah dikerjakan di kode**,
lalu apa yang **harus kamu kerjakan di server**.

## 1. Lapisan pertahanan

| Lapisan | Perlindungan | Di mana |
|---|---|---|
| Aplikasi | Semua nilai lewat placeholder `?` (bukan string ditempel); nama kolom dinamis divalidasi; pencarian dibersihkan dari operator | `Database.php`, `Model.php`, `Lowongan::klausaCariTeks` |
| Akun database | Aplikasi memakai `karirku_app`: tidak bisa DROP/ALTER/CREATE, tidak bisa membaca berkas server atau menjalankan perintah OS, batas waktu kueri 30 detik | `database/08-hardening-produksi.sql` |
| Login | Pembatas percobaan login di database (per email + IP, dan per email), tidak bisa dihindari dengan membuang cookie | `percobaan_login`, `app/helpers/keamanan.php` |
| Data | Status lamaran final tidak bisa diubah, riwayat tidak bisa dipalsukan, log tidak bisa dihapus oleh aplikasi | trigger di `07-...sql` + hak akses di `08-...sql` |
| Jaringan | Database hanya menerima koneksi dari server aplikasi | `pg_hba.conf`, firewall (bagian 4) |
| Pemulihan | Backup harian, mingguan, bulanan, terenkripsi, dan diuji pulih | `scripts/` (bagian 6) |

Sudah diuji di sandbox: dengan akun `karirku_app`, 16 jenis serangan (hapus tabel,
ubah arsip, baca `pg_authid`, baca `/etc/passwd`, `COPY ... TO PROGRAM`, buat
superuser, dan seterusnya) semuanya ditolak, sedangkan seluruh tes aplikasi
(1.016 halaman, 94 formulir, 552 berkas) berjalan tanpa satu pun galat izin.

## 2. WAJIB sebelum online

- [ ] **Ganti password `postgres` yang lama.** Password sebelumnya pernah tertulis
      di `app/config/database.php` dan ikut di dalam zip yang dikirim. Anggap sudah
      diketahui orang lain. Ganti juga di laptop: `ALTER USER postgres PASSWORD '...';`
- [ ] **Jangan pernah mengirim `app/config/database.lokal.php`**, `storage/uploads`,
      dan `storage/logs` (sudah masuk `.gitignore`).
- [ ] **Jangan jalankan `00-INSTAL-ULANG.sql` atau `05-data-dummy.sql` di server.**
      Keduanya berisi data contoh dan menghapus seluruh isi database.
- [ ] **Ganti atau hapus akun demo** dari `02-seed.sql` (admin, mahasiswa, perusahaan
      contoh). Akun admin demo memakai password yang tertulis di dokumentasi.
- [ ] **Biarkan `APP_DEBUG` kosong** di server. Dengan debug nyala, pesan error
      membuka host, nama database, dan jalur file; halaman `cek-sistem.php` dan
      `cek-berkas.php` juga hanya hidup saat debug nyala.
- [ ] **Pakai konfigurasi `docs/contoh-nginx.conf`** (HTTPS, pembatas laju, folder sensitif tertutup) atau minimal pastikan `.htaccess` di root proyek ikut ter-upload dan `AllowOverride All` aktif di Apache.
- [ ] **Document root web server harus folder `public/`**, bukan folder proyek,
      supaya `app/`, `database/`, `storage/`, dan `tests/` tidak bisa dibuka lewat URL.
- [ ] **Pakai HTTPS** (Let's Encrypt). Tanpa HTTPS, sandi dan sesi login terkirim polos.
- [ ] Pastikan ekstensi PHP **gd**, **exif**, **fileinfo**, **mbstring**, dan **pdo_pgsql** aktif. `gd` membuat ulang foto yang
      diunggah sehingga kode yang diselipkan terbuang (lihat `08-keamanan-aplikasi-web.md`).
- [ ] Periksa folder `public/` dan hapus halaman prototipe atau alat bantu yang tidak
      dipakai di produksi.
- [ ] Pakai **PostgreSQL 16 atau lebih baru**. Versi 14 mendekati akhir masa dukungan
      (sekitar November 2026; cek jadwal di postgresql.org/support/versioning).

## 3. Memasang database di server

Jalankan sebagai pemilik database (mis. `postgres`), **sekali**, berurutan:

```bash
createdb -U postgres karirku_polinema
psql -U postgres -d karirku_polinema -f database/01-schema.sql
psql -U postgres -d karirku_polinema -f database/02-seed.sql      # lalu ganti/hapus akun demo
psql -U postgres -d karirku_polinema -f database/03-migrasi-revisi.sql
psql -U postgres -d karirku_polinema -f database/04-revisi-dosen.sql
psql -U postgres -d karirku_polinema -f database/06-revisi-profil.sql
psql -U postgres -d karirku_polinema -f database/07-peningkatan-materi-dosen.sql

# Buat akun aplikasi (password acak panjang; simpan di pengelola password):
PW=$(openssl rand -base64 24); echo "$PW"
psql -U postgres -d karirku_polinema -v app_pass="$PW" -v max_koneksi=60 -f database/08-hardening-produksi.sql
```

`max_koneksi` = batas koneksi bersamaan akun aplikasi. Harus ≥ `pm.max_children` PHP-FPM dan
< `max_connections` PostgreSQL. Terlalu kecil membuat pengunjung ditolak saat ramai.

Atur aplikasi lewat **variabel lingkungan** (bukan file di repositori):

| Variabel | Nilai di server |
|---|---|
| `DB_HOST`, `DB_PORT`, `DB_NAME` | alamat database, mis. `127.0.0.1`, `5432`, `karirku_polinema` |
| `DB_USER` | `karirku_app` |
| `DB_PASS` | password dari langkah di atas |
| `DB_MIGRASI_OTOMATIS` | `0`  (migrasi dijalankan manual oleh pemilik, bukan oleh akun aplikasi) |
| `DB_SSLMODE` | `require` bila database di server lain |
| `DB_PERSISTEN` | `1`: koneksi dipakai ulang, ± 1,7x lebih cepat (lihat `07-kapasitas-dan-skala.md`) |
| `APP_DEBUG` | **jangan diisi** |

Contoh PHP-FPM (`/etc/php/8.x/fpm/pool.d/www.conf`): `env[DB_USER] = karirku_app`.
Contoh Apache (di vhost, **bukan** `.htaccess` dalam `public/`): `SetEnv DB_USER karirku_app`.
Batasi hak baca file konfigurasi itu hanya untuk akun web server (`chmod 640`).

**Memperbarui skema di kemudian hari:** jalankan file migrasi baru sebagai `postgres`,
lalu `database/08-hardening-produksi.sql` sekali lagi bila ada tabel baru (hak
`karirku_app` otomatis ikut lewat `ALTER DEFAULT PRIVILEGES`, tetapi menjalankannya
ulang aman dan memastikan semuanya konsisten).

## 4. Mengunci jaringan database

Di `pg_hba.conf` (urutan penting; baris pertama yang cocok yang dipakai):

```
# TYPE   DATABASE          USER         ADDRESS          METHOD
local    all               postgres                      peer
host     karirku_polinema  karirku_app  127.0.0.1/32     scram-sha-256
# bila aplikasi di server LAIN, ganti alamat dan wajibkan SSL:
# hostssl karirku_polinema karirku_app  10.0.0.5/32      scram-sha-256
host     all               all          0.0.0.0/0        reject
```

Dengan aturan ini `karirku_app` hanya bisa masuk ke database KarirKu, dari alamat yang
ditentukan (menutup celah "bisa tersambung ke database `postgres`" yang terlihat saat uji).

Di `postgresql.conf`: `listen_addresses = 'localhost'` (atau alamat jaringan privat),
`password_encryption = scram-sha-256`, `ssl = on` bila lintas server, dan
`log_connections = on`, `log_disconnections = on`, `log_min_duration_statement = 1000`
(mencatat kueri lambat). **Firewall: port 5432 tidak boleh terbuka ke internet.**

## 5. Menjaga database tetap ringan dan sehat (5 tahun)

- `07-...sql` sudah memasang index untuk kolom foreign key dan pencarian teks (GIN).
  Rekap admin halaman 1 pada 60 ribu lamaran turun dari 92 ms ke 0,8 ms berkat `idx_lamaran_tanggal`.
  Pada uji pencarian (100 ribu lowongan) waktunya turun dari 121 ms ke 0,04 ms, dan
  membaca riwayat satu lamaran (600 ribu baris riwayat) dari 40,8 ms ke 0,05 ms (angka dari sandbox; di mesinmu berbeda, bukti bisa
  diulang dengan `database/demo-bukti-kecepatan.sql`).
- **Retensi data**: tabel `log_email` (berisi alamat dan isi email), `notifikasi`, dan
  token lama terus bertambah. Jadwal bulanan di `scripts/karirku-backup.cron` memanggil
  `fn_bersihkan_data_lama()` (log email > 180 hari, notifikasi terbaca > 365 hari, token
  kedaluwarsa, catatan percobaan login). Riwayat lamaran/lowongan dan log admin **tidak** dihapus.
- Ganti password `karirku_app` setahun sekali (jalankan ulang `08-...sql` dengan
  `-v app_pass=...` baru, lalu ubah `DB_PASS`).
- Pasang pembaruan keamanan PostgreSQL dan sistem operasi secara berkala.

## 6. Backup harian, mingguan, bulanan

`scripts/backup-db.sh` mencadangkan **database dan folder `storage/uploads`** (KTM, ijazah,
CV): tabel hanya menyimpan nama berkas, jadi keduanya harus ikut.

| Jenis | Kapan dibuat | Disimpan |
|---|---|---|
| Harian | tiap hari 02:15 | 14 terakhir |
| Mingguan | otomatis tiap hari **Minggu** | 8 terakhir |
| Bulanan | otomatis tiap **tanggal 1** | 24 terakhir (isi `KEEP_BULANAN=60` untuk 5 tahun) |

Satu jadwal cron saja; skrip memutuskan sendiri. Salinan mingguan/bulanan memakai hard
link, jadi tidak memakan ruang dobel.

```bash
sudo mkdir -p /etc/karirku /var/backups/karirku
sudo cp scripts/backup.env.contoh /etc/karirku/backup.env    # lalu sesuaikan
sudo cp scripts/karirku-backup.cron /etc/cron.d/karirku-backup   # sesuaikan jalur proyek
sudo -u postgres scripts/backup-db.sh                         # coba sekali sekarang
cat /var/backups/karirku/STATUS                               # harus berawalan OK
```

**Enkripsi (sangat disarankan):** isi `BACKUP_GPG_PENERIMA` dengan kunci publikmu. Simpan
**kunci pribadi di luar server** (tanpa itu backup terenkripsi tidak bisa dibuka, dan
sebaliknya, pencuri backup tidak bisa membukanya).

**Aturan 3-2-1:** minimal 3 salinan, 2 media berbeda, 1 di luar lokasi. Backup yang berada
di server yang sama dengan database akan ikut hilang bila server diretas atau rusak.
Gunakan `rclone`/`rsync` ke tempat lain (contoh ada di berkas cron).

**Uji pulih tiap minggu** (sudah dijadwalkan): `scripts/restore-db.sh --uji` memulihkan
backup terbaru ke database sementara, memeriksa isinya (jumlah data, trigger, view,
vektor pencarian), lalu menghapusnya. Backup yang belum pernah diuji belum bisa dipercaya.

**Pulih sungguhan:**

```bash
# 1. ke database baru dulu, periksa:
sudo -u postgres scripts/restore-db.sh /var/backups/karirku/harian/karirku_polinema_<waktu>.dump karirku_baru
# 2. atau mengganti produksi (hentikan aplikasi dulu; akan diminta mengetik YA):
sudo -u postgres scripts/restore-db.sh --timpa /var/backups/karirku/harian/karirku_polinema_<waktu>.dump
# 3. pasang ulang hak akun aplikasi, lalu pulihkan berkas unggahan:
psql -U postgres -d karirku_polinema -v app_pass="..." -f database/08-hardening-produksi.sql
tar -xzf uploads_<waktu>.tar.gz -C /opt/karirku/storage/
```

## 7. Yang dilindungi, dan yang TIDAK

Dilindungi: SQL injection yang lolos tidak bisa menghapus tabel, memalsukan arsip, atau
menguasai server database; kueri yang menggantung dihentikan sendiri; data lama tidak
menumpuk tanpa batas; kehilangan atau kerusakan data bisa dipulihkan.

**Belum tercakup dan perlu kamu perhatikan:**

- Saya hanya memeriksa kode yang mengakses database. Celah di sisi aplikasi lain (XSS,
  pembajakan sesi, unggah berkas berbahaya, kelemahan hak akses antar-peran) tidak diaudit
  menyeluruh. Tes bawaan proyek memeriksa sebagian (CSRF, path traversal pada unduhan).
- Akun aplikasi yang dicuri lewat phishing tetap bisa membaca dan mengubah data biasa
  sebagaimana pemiliknya. Wajibkan password kuat untuk admin.
- Kompromi seluruh server (bukan hanya database) tidak tertahan oleh langkah di sini.
- Serangan membanjiri (DDoS) perlu perlindungan di tingkat jaringan/penyedia hosting.
- Tidak ada sistem yang 100% aman. Tujuan semua langkah ini: mempersulit penyerang,
  membatasi kerusakan, dan memastikan kamu bisa pulih.
