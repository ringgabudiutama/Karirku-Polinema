# Cara Mengganti Foto dan Gambar

Semua gambar ada di `public/assets/img/`. Ganti dengan nama file yang sama,
tanpa perlu mengubah kode.

## Empat foto bergerak di Beranda

Hero pada Beranda berganti otomatis setiap 7 detik dan bisa diklik lewat empat
tab di bawahnya.

| Nama file | Isi yang disarankan | Ukuran |
|---|---|---|
| `hero-1.jpg` | Mahasiswa di lingkungan kampus | 1920 x 1080 piksel |
| `hero-2.jpg` | Wisuda atau alumni | 1920 x 1080 piksel |
| `hero-3.jpg` | Praktik di laboratorium atau bengkel | 1920 x 1080 piksel |
| `hero-4.jpg` | Kerja sama dengan mitra industri | 1920 x 1080 piksel |

Catatan penting: sisi kiri foto tertutup lapisan biru untuk tempat judul, jadi
pilih foto yang objek utamanya berada di sisi kanan.

Teks pada setiap slide diubah di `public/index.html`, cari bagian
`<div class="hero-text">`. Judul tab slide ada di bagian `Tab slider`.

Durasi pergantian slide diubah di `public/assets/js/app.js`, cari angka `7000`
pada fungsi `initHero`.

## Gambar lain

| Nama file | Dipakai di | Ukuran |
|---|---|---|
| `about.jpg` | Bagian Tentang KarirKu | 1200 x 900 |
| `login.jpg` | Panel kiri halaman Masuk | 1200 x 1400 |
| `avatar-1.jpg` sampai `avatar-6.jpg` | Foto profil contoh | persegi |
| `pamflet-1.jpg` sampai `pamflet-6.jpg` | Pamflet lowongan contoh | rasio 4:5 |
| `dok-ktm.jpg`, `dok-nib.jpg` | Contoh dokumen verifikasi | bebas |

## Logo

Logo Politeknik Negeri Malang sudah dipasang di seluruh halaman, file-nya ada di
`public/assets/img/logo-polinema.png` berukuran 512 x 516 piksel.

Untuk menggantinya dengan file resmi dari kampus, timpa file itu dengan nama yang
sama. Gunakan PNG berlatar transparan atau putih, bentuk persegi, minimal 400
piksel. Ukuran tampilnya diatur lewat kelas `.brand-mark` di `style.css`, yaitu
42 piksel di navbar dan 38 piksel di sidebar.

## Kontak Career Center

Data kontak sudah diisi sesuai informasi resmi dan dipakai di Beranda, footer,
halaman Masuk, dan Halaman Status Akun.

| Data | Isi |
|---|---|
| Lokasi | Graha Polinema Lantai 3, Politeknik Negeri Malang |
| Layanan tatap muka | 08.00 sampai 16.00 WIB |
| Email | jpc@polinema.ac.id |
| Instagram | @polinemacareercenter |
| Facebook | lokerjpcpolinema |
| Telepon | Belum tersedia, sengaja tidak ditampilkan |

Peta di bagian Kontak memakai Google Maps yang disematkan dan tombol Buka di
Google Maps. Keduanya butuh internet. Untuk mengubah titik lokasi, cari kata
`Graha%20Polinema` dan `Graha+Polinema` di `public/index.html`.
