# KarirKu Polinema

Sistem Informasi Manajemen Karier, Lowongan Kerja, dan Rekrutmen Terpusat
bagi Mahasiswa, Alumni, dan Perusahaan Mitra Politeknik Negeri Malang.
Proyek PBL Terintegrasi Teknologi Informasi Semester 3.

## Cara menjalankan saat ini

Frontend sudah berjalan penuh dan tidak butuh server.

1. Buka folder ini di VS Code.
2. Klik kanan `public/index.html` lalu pilih Open with Live Server,
   atau klik dua kali filenya di File Explorer.
3. Sambungkan internet agar huruf Fraunces dan Plus Jakarta Sans termuat.
   Tanpa internet halaman tetap jalan dengan huruf cadangan.
4. Tampilan sudah menyesuaikan layar ponsel, tablet, dan laptop. Untuk mencoba,
   tekan F12 di browser lalu pilih ikon ponsel.

Backend masih kosong. File PHP di folder `app/` baru berisi kerangka kelas dan
daftar tugas. Setelah backend dipasang, jalankan lewat `public/index.php`.

## Struktur folder

```
karirku-polinema/
├── public/              Frontend yang sudah jadi, sekaligus document root
│   ├── index.html       Beranda
│   ├── masuk.html       Login semua peran
│   ├── daftar.html      Registrasi 3 langkah
│   ├── status-akun.html Halaman akun yang belum aktif
│   ├── info-loker.html  Pratinjau loker tanpa login
│   ├── mahasiswa.html   Menu mahasiswa dan alumni
│   ├── perusahaan.html  Menu perusahaan
│   ├── admin.html       Menu admin Career Center
│   ├── index.php        Titik masuk backend (belum aktif)
│   └── assets/
│       ├── css/style.css    Seluruh gaya, warna ada di bagian :root
│       ├── js/app.js        Ikon, navigasi, modal, notifikasi, data dummy
│       └── img/             Foto, pamflet, avatar, dokumen contoh
├── app/                 Backend, masih kerangka kosong
│   ├── config/          Konfigurasi aplikasi dan database
│   ├── core/            Database, Router, Controller, Model induk
│   ├── middleware/      Auth dan Role
│   ├── controllers/     Satu file per modul
│   ├── models/          Satu file per tabel
│   ├── services/        Email, PDF, unggah file, notifikasi, WhatsApp
│   ├── helpers/         Validasi, keamanan, format tampilan
│   └── views/           Template PHP, diisi saat backend mulai dipasang
├── database/            Skema dan data uji PostgreSQL
├── docs/                ERD, EERD, flowchart, alur demo, pembagian tugas
├── storage/             Hasil unggahan dan log, di luar folder publik
└── tests/               Checklist pengujian
```

## Urutan penjelasan saat demo

Ada di `docs/01-alur-demo.md`. Ikuti urutan nomornya dari atas ke bawah.

## Pembagian tugas

Ada di `docs/02-pembagian-tugas.md`. Setiap file PHP juga sudah diberi nama PIC
dan daftar tugas di bagian atas filenya, jadi tiap orang tinggal membuka file
miliknya lalu mengisi bagian bertanda TODO.
