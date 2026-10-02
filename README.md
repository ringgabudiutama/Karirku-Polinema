# KarirKu Polinema

Sistem Informasi Manajemen Karier, Lowongan Kerja, dan Rekrutmen Terpusat
bagi Mahasiswa, Alumni, dan Perusahaan Mitra Politeknik Negeri Malang.
Proyek PBL Terintegrasi Teknologi Informasi Semester 3.

## Cara menjalankan saat ini

Backend sudah aktif (Router, Model, Controller, Service, dan seluruh query
database sudah diisi). Yang masih perlu dikerjakan tim frontend/integrasi
adalah memindahkan tampilan dari `public/*.html` ke `app/views/*.php` --
lihat `app/views/PANDUAN-VIEW.md` untuk daftar lengkap variabel yang sudah
disiapkan tiap halaman.

**Panduan lengkap dan sudah teruji ada di `PANDUAN-JALANKAN.md`.** Ringkasnya:

1. Aktifkan ekstensi `pdo_pgsql` dan `pgsql` di `php.ini`, lalu restart Apache.
2. Buat database `karirku_polinema`, jalankan `database/01-schema.sql` lalu
   `database/02-seed.sql`. Akan terbentuk 24 tabel berisi 7 jurusan, 32 program
   studi, 51 akun mahasiswa dan alumni, 16 perusahaan, 40 lowongan, dan 34
   lamaran dengan status bervariasi. Kalau databasenya sudah dibuat dengan
   skema versi lama, jalankan juga `database/03-migrasi-revisi.sql`.
3. Isi password PostgreSQL di `app/config/database.php`.
4. Sesuaikan `base_url` di `app/config/config.php`:
   kosongkan (`''`) kalau `public/` jadi document root, atau isi
   `/karirku-polinema/public` kalau diakses lewat subfolder XAMPP.
5. Jalankan. Paling cepat: klik dua kali `jalankan.bat` (tanpa perlu Apache),
   lalu buka `http://localhost:8000`.
6. Buka `/cek-sistem.php` lebih dulu untuk memastikan PHP, koneksi database,
   tabel, dan izin folder sudah benar.

Akun demo (ada di `database/02-seed.sql`, **wajib diganti** sebelum dipakai
sungguhan):

| Peran | Email | Password |
|---|---|---|
| Admin | `admin@polinema.ac.id` | `admin123` |
| Mahasiswa | `mahasiswa@polinema.ac.id` | `mahasiswa123` |
| Perusahaan | `perusahaan@polinema.ac.id` | `perusahaan123` |

`composer install` sifatnya opsional: tanpa itu aplikasi tetap jalan, hanya
email dicatat ke `storage/logs/email.log` dan PDF tampil sebagai halaman HTML
yang siap dicetak.

Sudah diuji jalan di PHP 8.4 + PostgreSQL 16: schema dan seed masuk tanpa
error, login tiga peran berhasil, dan seluruh halaman Admin, Mahasiswa, serta
Perusahaan terbuka tanpa error PHP. `debug` di `app/config/config.php`
sengaja dibiarkan `true` selama pengembangan supaya pesan error gampang
dilacak; ubah ke `false` sebelum demo atau produksi.

## Struktur folder

```
karirku-polinema/
├── public/              Document root
│   ├── index.php        Titik masuk backend (AKTIF)
│   ├── unduh.php         Pelayan file unggahan dengan kontrol akses (AKTIF)
│   ├── .htaccess         Pretty URL -> index.php?url=... (AKTIF)
│   ├── *.html            Prototipe lama, masih bisa dibuka manual sebagai acuan desain
│   └── assets/
│       ├── css/style.css    Seluruh gaya, warna ada di bagian :root
│       ├── js/app.js        Ikon, navigasi, modal, notifikasi, data dummy
│       └── img/             Foto, pamflet, avatar, dokumen contoh
├── app/
│   ├── config/          Konfigurasi aplikasi dan database (DIISI)
│   ├── core/            Database, Router, Controller, Model induk, bootstrap (DIISI)
│   ├── middleware/      Auth dan Role (DIISI)
│   ├── controllers/     8 controller, semua method sudah berlogika (DIISI)
│   ├── models/          19 model, satu file per tabel (DIISI)
│   ├── services/        Email, PDF, unggah file, notifikasi, WhatsApp (DIISI)
│   ├── helpers/         Validasi, keamanan, format tampilan (DIISI)
│   └── views/           SUDAH DIISI (38 file) -- lihat PANDUAN-VIEW.md untuk kontrak lengkap
├── database/
│   ├── 01-schema.sql                     Skema utama
│   ├── 02-seed.sql                       Data acuan + data uji lengkap
│   ├── 03-migrasi-revisi.sql             Tambahan kolom untuk database lama
├── docs/                ERD, EERD, flowchart, alur demo, pembagian tugas
├── storage/             Hasil unggahan dan log, di luar folder publik
├── composer.json        Dependensi PHPMailer & Dompdf (jalankan composer install)
└── tests/               Checklist pengujian
```

## Yang masih perlu dikerjakan

- **Penyempurnaan visual** (`app/views/*.php`): semua halaman sudah render
  dan tersambung ke backend, dengan style asli (`style.css`/`app.js`)
  dipakai apa adanya. Boleh dirapikan lagi sesuai selera tim frontend --
  jaga nama variabel dan `action` form tetap sama seperti di
  `app/views/PANDUAN-VIEW.md` supaya tidak putus dari backend.
- **`composer install`**: belum dijalankan di draf ini (lingkungan penyusunan
  tidak tersambung internet). Email & PDF punya fallback otomatis selama
  belum di-install (lihat `app/services/MailService.php` & `PdfService.php`).
- **Pengujian ujung ke ujung** di server PHP + PostgreSQL sungguhan, karena
  draf ini ditulis tanpa akses ke keduanya. Cek `tests/` untuk daftar
  skenario yang perlu dicoba satu per satu.
- **Fitur "Alasan Penolakan" siap pakai**: daftar contoh alasan disimpan di
  Pengaturan > Alasan Penolakan (satu baris teks per alasan, tanpa tabel
  baru), tapi belum ada tombol "sisipkan" otomatis ke kolom catatan --
  masih perlu disalin manual untuk sekarang.

## Urutan penjelasan saat demo

Ada di `docs/01-alur-demo.md`. Ikuti urutan nomornya dari atas ke bawah.

## Pembagian tugas

Ada di `docs/02-pembagian-tugas.md`. Setiap file PHP juga sudah diberi nama PIC
dan daftar tugas di bagian atas filenya, jadi tiap orang tinggal membuka file
miliknya lalu mengisi bagian bertanda TODO.
