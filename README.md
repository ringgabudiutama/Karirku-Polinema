# KarirKu Polinema

Sistem informasi karier, lowongan kerja, dan rekrutmen terpusat untuk Career Center Politeknik Negeri Malang.
Proyek PBL Kelompok 3, kelas TI 2I, D-IV Teknik Informatika.

PHP 8 native (pola MVC, tanpa framework) dan PostgreSQL.

## Struktur folder

| Folder | Bagian | Isi |
| --- | --- | --- |
| `frontend/views/` | Frontend | Halaman yang dilihat pengguna, dikelompokkan per peran: `publik`, `mahasiswa`, `perusahaan`, `admin`, `umum`, dan kerangka `layouts` |
| `frontend/assets/` | Frontend | `css/style.css` (tampilan laptop), `css/hp.css` (tampilan HP), `js/app.js` (interaksi), `img/` |
| `frontend/helpers/` | Frontend | Potongan HTML yang dipakai banyak halaman (tombol kembali, kartu, komponen HP) |
| `backend/controllers/` | Backend | Menerima permintaan, memeriksa hak akses dan isian, lalu memanggil model dan memilih halaman |
| `backend/models/` | Backend | Kueri ke database, satu kelas per tabel |
| `backend/services/` | Backend | Email, PDF, unggah berkas, notifikasi, WhatsApp |
| `backend/middleware/` | Backend | Cek login (`Auth`) dan cek peran (`Role`) |
| `backend/core/` | Backend | Router, koneksi database, kelas induk Controller dan Model |
| `backend/helpers/` | Backend | Validasi, keamanan (CSRF, sesi), format tanggal dan angka |
| `backend/config/` | Backend | Pengaturan aplikasi, database, dan email |
| `public/` | Pintu masuk | `index.php` (semua halaman), `unduh.php` (berkas dengan cek hak akses) |
| `database/` | Database | Skrip SQL: skema, data awal, migrasi |
| `storage/` | Data | Berkas unggahan (KTM, ijazah, CV, logo) dan log |
| `vendor/` | Pustaka | Dompdf (PDF) dan PHPMailer (email) |
| `tests/` | Pengujian | Skrip uji rute, alur, berkas, dan keamanan |
| `docs/` | Desain | ERD, EERD, dan flowchart |

Alur satu permintaan:

```
Browser -> public/index.php -> backend/core/Router.php -> backend/controllers/XxxController.php
        -> backend/models/Xxx.php -> PostgreSQL
        -> frontend/views/<peran>/<halaman>.php -> HTML kembali ke browser
```

Setiap berkas diawali komentar `BACKEND · ...` atau `FRONTEND · ...`, dan setiap method controller
diberi komentar `[URL] GET /alamat -> tampil: frontend/views/...` supaya mudah dicari saat demo.

## Menjalankan di laptop

1. Buat database `karirku_polinema` di PostgreSQL, lalu jalankan `database/00-INSTAL-ULANG.sql`
   (pgAdmin: Query Tool, buka berkasnya, Execute).
2. Salin `backend/config/database.lokal.contoh.php` menjadi `database.lokal.php`, isi password PostgreSQL.
3. Klik dua kali `jalankan.bat` (Windows) atau `bash jalankan.sh` (Linux/Mac).
4. Buka http://localhost:8000/cek-sistem.php untuk memeriksa kesiapan, lalu http://localhost:8000/masuk.

Agar email benar-benar terkirim, salin `backend/config/email.lokal.contoh.php` menjadi `email.lokal.php`
dan isi alamat Gmail serta App Password-nya, lalu coba tombol Kirim email uji di Admin, Pengaturan.

`database.lokal.php` dan `email.lokal.php` berisi kata sandi, jadi jangan ikut di-zip atau di-commit.

## Akun demo

| Peran | Email | Sandi |
| --- | --- | --- |
| Admin Career Center | admin@polinema.ac.id | admin123 |
| Mahasiswa | mahasiswa@polinema.ac.id | mahasiswa123 |
| Perusahaan | perusahaan@polinema.ac.id | perusahaan123 |

## Pengujian

Jalankan saat server hidup di port 8000:

```
php tests/uji-rute.php                  # semua method controller
php tests/jelajah.php                   # telusur semua alamat sebagai 4 peran
python3 tests/uji-alur-revisi.py        # alur utama ujung ke ujung, termasuk BUG-01 sampai BUG-03
python3 tests/keamanan/uji-akses-peran.py
python3 tests/keamanan/uji-unggah.py
```
