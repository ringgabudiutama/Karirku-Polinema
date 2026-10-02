# Cara Menjalankan KarirKu Polinema di Laptop

Panduan ini sudah diuji sampai berhasil: database terpasang, login tiga peran
berhasil, dan semua halaman terbuka tanpa error.

Ada dua cara. **Cara A** paling cepat dan cocok untuk demo. **Cara B** dipakai
kalau kamu sudah terbiasa dengan XAMPP.

---

## Yang perlu dipasang lebih dulu

| Kebutuhan | Keterangan |
|---|---|
| PHP 8.0 ke atas | Sudah termasuk kalau kamu memasang XAMPP atau Laragon |
| PostgreSQL 14 ke atas | Unduh di postgresql.org/download/windows |
| Ekstensi `pdo_pgsql` | Ikut terpasang bersama PHP, tapi biasanya masih perlu diaktifkan |

Saat memasang PostgreSQL, **catat password untuk user `postgres`** yang kamu
buat di layar instalasi. Password itu dipakai di langkah 3.

---

## Langkah 1: Aktifkan ekstensi PostgreSQL di PHP

Ini penyebab error paling sering. PHP bawaan XAMPP sudah menyertakan file
ekstensinya, tapi masih dimatikan.

1. Buka file `php.ini`.
   - XAMPP: `C:\xampp\php\php.ini`
   - Laragon: klik kanan ikon Laragon, PHP, php.ini
2. Tekan Ctrl+F, cari `pdo_pgsql`.
3. Hapus tanda titik koma di depan dua baris ini:

   ```ini
   extension=pdo_pgsql
   extension=pgsql
   ```

4. Simpan, lalu restart Apache dari panel XAMPP atau Laragon.

---

## Langkah 2: Buat database dan isi tabelnya

Buka **pgAdmin** (ikut terpasang bersama PostgreSQL).

1. Klik kanan **Databases**, pilih **Create**, lalu **Database**.
2. Isi nama: `karirku_polinema`, lalu Save.
3. Klik database `karirku_polinema` yang baru dibuat.
4. Menu **Tools**, lalu **Query Tool**.
5. Klik ikon folder, buka file `database/01-schema.sql`, lalu tekan tombol
   **Execute** (ikon segitiga atau F5).
6. Ulangi untuk `database/02-seed.sql`.

Kalau berhasil, akan terbentuk **24 tabel** berisi data siap pakai:

| Isi | Jumlah |
|---|---|
| Jurusan Polinema | 7 |
| Program studi (D-II, D-III, D-IV, dan S2 Terapan) | 32 |
| Akun mahasiswa dan alumni | 51 |
| Akun perusahaan | 16 |
| Lowongan | 40 |
| Lamaran dengan status bervariasi | 34 |
| Jadwal interview (luring dan daring) | 7 |

Jadi begitu login, semua menu sudah ada isinya dan langsung bisa didemokan.

### Databasemu sudah dibuat dengan versi lama?

Gejalanya: pilihan jurusan dan program studi di halaman pendaftaran masih
sedikit dan belum sesuai Polinema. Itu karena `02-seed.sql` hanya mengisi
database yang masih kosong, sedangkan punyamu sudah terisi daftar lama.

Jangan dihapus databasenya. Cukup jalankan **satu file** ini sekali lewat
pgAdmin, Tools, Query Tool:

```
database/03-migrasi-revisi.sql
```

File itu akan:

- menambah kolom baru untuk status karier dan interview luring,
- mengisi 20 skill awal supaya tab Skills tidak kosong,
- mengganti daftar jurusan dan program studi menjadi 7 jurusan dan 32 program
  studi sesuai Polinema, termasuk jenjang S2 Terapan,
- memindahkan mahasiswa yang terdaftar di program studi lama ke program studi
  resmi yang paling cocok di jurusan yang sama, jadi tidak ada data hilang,
- mengisi notifikasi untuk tiga akun demo, supaya lonceng dan halaman
  Notifikasi ada isinya saat didemokan,
- mengisi berkas contoh untuk foto profil, logo perusahaan, sertifikat, dan
  dokumen legalitas, supaya tombol "Lihat" dan "Lihat file" tidak berakhir di
  halaman "Berkas tidak ditemukan".

**Databasemu tidak perlu dihapus.** Semua bagian di atas hanya menambah yang
belum ada, dan tidak menimpa berkas yang sudah pernah diunggah sungguhan.
Akun, lowongan, dan lamaran yang sudah kamu buat tetap utuh.

Aman dijalankan berulang kali. Setelah selesai, muat ulang halaman
pendaftaran, daftarnya langsung berubah.

Kalau isi databasemu memang masih data percobaan, cara yang lebih singkat
adalah menghapus databasenya lalu membuat ulang dengan `01-schema.sql` dan
`02-seed.sql`. Bonusnya, kamu langsung dapat data uji lengkap di tabel di
atas sehingga semua menu ada isinya saat demo.

Lebih suka lewat terminal? Jalankan dua perintah ini di folder proyek:

```bash
psql -U postgres -c "CREATE DATABASE karirku_polinema;"
psql -U postgres -d karirku_polinema -f database/01-schema.sql
psql -U postgres -d karirku_polinema -f database/02-seed.sql
```

Khusus database lama yang sudah berisi data, tambahkan satu perintah ini:

```bash
psql -U postgres -d karirku_polinema -f database/03-migrasi-revisi.sql
```

---

## Langkah 3: Isi password database di konfigurasi

Buka `app/config/database.php`, ganti bagian `'pass'` dengan password
PostgreSQL milikmu:

```php
return [
    'host' => getenv('DB_HOST') ?: '127.0.0.1',
    'port' => getenv('DB_PORT') ?: 5432,
    'nama' => getenv('DB_NAME') ?: 'karirku_polinema',
    'user' => getenv('DB_USER') ?: 'postgres',
    'pass' => getenv('DB_PASS') ?: 'password_postgres_kamu',
];
```

Kalau nama database yang kamu buat berbeda, ganti juga bagian `'nama'`.

---

## Cara A: Jalankan tanpa Apache (paling cepat)

Cara ini tidak perlu menyalin folder ke `htdocs` dan tidak perlu mengatur
Apache sama sekali.

1. Buka `app/config/config.php`, pastikan baris `base_url` **dikosongkan**:

   ```php
   'base_url'      => '',
   ```

2. Klik dua kali **`jalankan.bat`** di folder proyek.
   (Mac atau Linux: buka terminal, ketik `bash jalankan.sh`)

3. Buka browser ke **http://localhost:8000/cek-sistem.php**

   Halaman ini memeriksa PHP, ekstensi PostgreSQL, koneksi database, jumlah
   tabel, dan izin folder. Kalau ada baris merah, di bawahnya langsung ada
   cara memperbaikinya.

4. Kalau semua hijau, buka **http://localhost:8000/masuk**

Kalau muncul pesan `PHP belum terdeteksi di PATH`, jalankan perintah ini di
terminal dari dalam folder proyek:

```
C:\xampp\php\php.exe -S localhost:8000 -t public server-dev.php
```

Untuk menghentikan server, tekan Ctrl+C di jendela hitamnya.

---

## Cara B: Jalankan lewat XAMPP (Apache)

1. Salin seluruh folder proyek ke `C:\xampp\htdocs\`, sehingga jadi
   `C:\xampp\htdocs\karirku-polinema`.

2. Buka `app/config/config.php`, isi `base_url` sesuai lokasi tadi:

   ```php
   'base_url'      => '/karirku-polinema/public',
   ```

3. Pastikan `mod_rewrite` aktif. Buka `C:\xampp\apache\conf\httpd.conf`,
   cari baris berikut dan hapus tanda pagar di depannya kalau masih ada:

   ```
   LoadModule rewrite_module modules/mod_rewrite.so
   ```

   Lalu cari blok `<Directory "C:/xampp/htdocs">` dan pastikan tertulis
   `AllowOverride All`, bukan `AllowOverride None`.

4. Restart Apache dari XAMPP Control Panel.

5. Buka **http://localhost/karirku-polinema/public/cek-sistem.php**

6. Kalau semua hijau, buka
   **http://localhost/karirku-polinema/public/masuk**

---

## Akun demo untuk mencoba

| Peran | Email | Password |
|---|---|---|
| Admin Career Center | `admin@polinema.ac.id` | `admin123` |
| Mahasiswa | `mahasiswa@polinema.ac.id` | `mahasiswa123` |
| Perusahaan | `perusahaan@polinema.ac.id` | `perusahaan123` |

Ganti password ini sebelum aplikasi dipakai sungguhan.

---

## Kalau muncul error

| Pesan atau gejala | Penyebab dan solusi |
|---|---|
| `could not find driver` | Ekstensi `pdo_pgsql` belum aktif. Ulangi Langkah 1, jangan lupa restart Apache. |
| `password authentication failed for user "postgres"` | Password di `app/config/database.php` salah. Samakan dengan yang kamu buat saat memasang PostgreSQL. |
| `database "karirku_polinema" does not exist` | Database belum dibuat. Ulangi Langkah 2. |
| `relation "pengguna" does not exist` | File `01-schema.sql` belum dijalankan di database yang benar. |
| `Connection refused` di port 5432 | Service PostgreSQL belum jalan. Buka Services di Windows, cari `postgresql`, klik Start. |
| Halaman tampil tanpa warna, polos | `base_url` tidak cocok. Buka `cek-sistem.php`, baris base_url akan menyebutkan nilai yang benar. |
| Semua halaman 404 kecuali beranda | Cara B saja: `mod_rewrite` belum aktif atau `AllowOverride` masih `None`. |
| Halaman putih kosong | Pastikan `'debug' => true` di `app/config/config.php` supaya pesan errornya muncul. |

---

## Catatan tambahan

**Composer tidak wajib.** Aplikasi tetap jalan tanpa menjalankan
`composer install`. Bedanya: email tidak benar-benar terkirim melainkan
dicatat ke `storage/logs/email.log`, dan CV serta laporan PDF tampil sebagai
halaman HTML yang bisa dicetak dengan Ctrl+P. Kalau ingin fitur penuh,
pasang Composer lalu jalankan `composer install` di folder proyek.

**Tampilan lama masih ada.** File `public/*.html` adalah prototipe statis
sebelum backend dipasang. Halaman yang sudah tersambung database ada di
`app/views/`. Jangan bingung kalau membuka `index.html` langsung, itu versi
lama yang datanya masih dummy.

**Hapus `cek-sistem.php` dan `cek-berkas.php`** sebelum aplikasi di-deploy ke
server publik, karena keduanya menampilkan detail konfigurasi dan isi data.

---

## Kalau ada tombol berkas yang berakhir di "Berkas tidak ditemukan"

Buka **http://localhost:8000/cek-berkas.php**

Halaman itu membandingkan nama berkas yang tercatat di database dengan isi
folder `storage/uploads/`, lalu menunjukkan mana yang hilang beserta
pemiliknya.

Penyebab paling sering: folder proyek diganti dengan versi baru, sedangkan
berkas yang pernah diunggah masih tertinggal di folder proyek yang lama.
Database tetap mencatat namanya, tetapi berkasnya tidak ikut pindah.

Cara memperbaikinya: salin seluruh isi `storage/uploads/` dari folder proyek
yang lama ke folder yang sekarang dipakai, lalu muat ulang halaman itu.

Kalau folder lamanya sudah terhapus, berkasnya memang sudah tidak ada. Minta
pemiliknya mengunggah ulang lewat Profil Karier. Di halaman itu statusnya
sekarang tertulis "Perlu diunggah ulang", bukan "Sudah tersimpan", jadi
ketahuan tanpa harus menebak.

---

## CV otomatis

CV otomatis **tidak diunggah dan tidak disimpan sebagai berkas**. Sistem
menyusunnya saat itu juga dari data Profil Karier, jadi isinya selalu
mengikuti data terbaru.

Membukanya: **Profil Karier**, lalu tombol **Buat & unduh CV** di kotak
"CV otomatis". Alamatnya `mahasiswa/generate-cv`.

Yang muncul adalah halaman CV berukuran A4 dengan tombol **Simpan sebagai
PDF** di atasnya. Tekan tombol itu, atau `Ctrl + P`, lalu pilih
**Save as PDF** pada tujuan pencetakan.

Kalau ingin keluar langsung sebagai berkas PDF tanpa lewat jendela cetak,
pasang Composer lalu jalankan `composer require dompdf/dompdf` di folder
proyek. Begitu Dompdf terpasang, tombol yang sama langsung mengunduh PDF.

Ini berbeda dengan **CV unggahan**, yaitu berkas PDF yang kamu unggah sendiri
di tab Dokumen. Saat melamar, kamu memilih salah satu dari keduanya.
