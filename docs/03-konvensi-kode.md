# Konvensi Kode

## Penamaan
- Tabel dan kolom database: huruf kecil dengan garis bawah, contoh `status_akun`.
- Kelas PHP: PascalCase, contoh `LamaranController`.
- Fungsi dan variabel PHP: camelCase, contoh `simpanProfil()`.
- Kelas CSS: huruf kecil dengan tanda hubung, contoh `.job-actions`.
- Id dan fungsi JavaScript: camelCase.

## Huruf

- Judul memakai Fraunces, serif modern, dipanggil lewat variabel `--font-head`.
- Isi dan antarmuka memakai Plus Jakarta Sans, dipanggil lewat variabel `--font`.
- Keduanya dimuat dari Google Fonts pada bagian `<head>` setiap halaman, jadi
  saat demo sebaiknya ada internet. Tanpa internet, halaman tetap terbaca karena
  ada cadangan Georgia untuk judul dan huruf bawaan sistem untuk isi.
- Untuk mengganti huruf, cukup ubah dua variabel di bagian `:root` pada
  `style.css` dan satu baris `<link>` di setiap file HTML.

## Frontend
- Warna diambil dari variabel di `:root` pada `style.css`. Jangan menulis kode
  warna langsung di file HTML.
- Ikon memakai fungsi `ic('nama')` di `app.js`, bukan gambar terpisah.
- Semua teks memakai bahasa Indonesia.

## Backend
- Seluruh query memakai prepared statement.
- Setiap halaman memeriksa sesi, peran, dan status akun di sisi server.
- Setiap formulir memakai token CSRF.
- File unggahan diperiksa tipe dan ukurannya, diberi nama acak, dan disimpan di
  `storage/uploads`, bukan di dalam `public/`.

## Git
- Pesan commit: `modul: ringkasan singkat`, contoh `lamaran: tambah validasi surat pengantar`.
- Commit kecil dan sering, jangan menumpuk satu commit besar.
