# Pemeriksaan otomatis

Delapan skrip untuk memeriksa aplikasi sebelum dipakai atau didemokan.
Semuanya butuh server berjalan di `http://127.0.0.1:8000` dan database terisi.

```
php -S 127.0.0.1:8000 -t public server-dev.php
```

Lalu di terminal lain, dari folder proyek:

| Perintah | Yang diperiksa |
|---|---|
| `php tests/scan-method.php` | Setiap pemanggilan method dicocokkan dengan method yang benar-benar ada. |
| `php tests/uji-rute.php` | Semua method controller dipanggil lewat HTTP dengan id nyata dan peran yang sesuai. |
| `php tests/uji-form.php` | Setiap formulir POST dikirim memakai persis field yang dirender view-nya. |
| `bash tests/uji-check.sh` | Nilai kosong dan nilai asing pada kolom yang dibatasi CHECK di database. |
| `php tests/jelajah.php` | Menelusuri seluruh aplikasi: buka halaman, kumpulkan setiap tautan, buka satu per satu, **ikuti redirect sampai tujuan akhir**. |
| `php tests/uji-berkas.php` | Setiap tombol berkas (unduh.php) dibuka dan diperiksa apakah berkasnya benar-benar keluar. |
| `bash tests/uji-akses-berkas.sh` | Berkas pribadi tetap tertolak untuk yang tidak berhak, dan tetap terbuka untuk yang berhak. |
| `bash tests/uji-alamat-cacat.sh` | Alamat salah ketik tidak boleh memunculkan halaman fatal error PHP. |

## Empat jebakan yang pernah membuat pemeriksaan lolos padahal ada bug

Keempatnya pernah benar-benar terjadi di proyek ini.

1. **Status 302 dianggap aman.** Bug "tandai dibaca jadi 404" lolos karena
   pemeriksaan hanya melihat kodenya 302, tidak pernah mengikuti ke mana
   perginya. Sekarang redirect selalu diikuti sampai tujuan akhir.

2. **Ikut menekan tombol Keluar.** Begitu sesi hilang, semua halaman
   dialihkan ke halaman masuk yang berstatus 200, sehingga semuanya terlihat
   lolos padahal tidak pernah benar-benar dibuka. Alamat `keluar` sekarang
   dilewati, dan terlempar ke halaman masuk dihitung sebagai masalah.

3. **Tautan berkas dilewati.** Tombol seperti "Lihat file" pada sertifikat
   tidak pernah diuji sama sekali, padahal selalu ditolak. Sekarang setiap
   tautan `unduh.php` dibuka dan isinya diperiksa.

4. **Nama berkas yang sama untuk semua orang.** Kalau data uji memakai satu
   nama berkas untuk semua akun, pemeriksaan hak akses tidak bisa membedakan
   pemiliknya sehingga kebocoran tidak terdeteksi. Data uji sekarang memakai
   nama berkas berbeda per orang, memakai NIM atau nomor perusahaan.

## Catatan

Sebagian skrip mengubah data, misalnya menonaktifkan pengguna atau menutup
lowongan. Bangun ulang databasenya sebelum dipakai demo:

```
psql -U postgres -c "DROP DATABASE karirku_polinema;"
psql -U postgres -c "CREATE DATABASE karirku_polinema;"
psql -U postgres -d karirku_polinema -f database/01-schema.sql
psql -U postgres -d karirku_polinema -f database/02-seed.sql
```
