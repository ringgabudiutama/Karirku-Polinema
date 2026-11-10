# Pembagian Tugas

Nama PIC juga sudah ditulis di bagian atas setiap file PHP.

## Ringga Budi Utama, Project Lead, UI/UX, dan Frontend
- Koordinasi dan timeline tim.
- Design system, prototipe, dan implementasi frontend seluruh peran.
- `public/assets/css/style.css`, `public/assets/js/app.js`, seluruh file HTML.
- `app/helpers/format.php`, `app/views/layouts/`.
- Dokumentasi dan presentasi.

## Aqillah, Project Lead, UI/UX, Frontend, dan Integrasi
- Requirement dan user flow, wireframe.
- `app/controllers/AuthController.php` dan `KirimLokerController.php`.
- `app/models/DokumenVerifikasi.php`, `VerifikasiAkun.php`, `AdminJurusanKontak.php`, `PengirimanLoker.php`.
- `app/services/UploadService.php` dan `WhatsappService.php`.
- `app/helpers/validasi.php`.

## M. Ubaidillah, Backend dan Database
- `database/01-schema.sql` dan data uji.
- `app/config/`, `app/core/`, `app/middleware/`.
- `app/models/Pengguna.php`, `Jurusan.php`, `ProgramStudi.php`, `Notifikasi.php`, `Pengaturan.php`.
- `app/services/MailService.php`, `PdfService.php`, `NotifikasiService.php`.
- `app/helpers/keamanan.php`, deployment, dan backend testing.

## Atha Rasya Farras, Modul Operator dan Career Center
- `app/controllers/PerusahaanController.php`, `LowonganController.php`, `AdminController.php`.
- `app/models/Perusahaan.php`, `Admin.php`, `Lowongan.php`, `Interview.php`.
- `app/views/perusahaan/` dan `app/views/admin/`.
- Testing modul operator.

## Muhamad Nafi' Hanif, Modul Mahasiswa dan Alumni
- `app/controllers/MahasiswaController.php` dan `LamaranController.php`.
- `app/models/Mahasiswa.php`, `ProfilItem.php`, `Skill.php`, `Bidang.php`, `LowonganDisimpan.php`, `Lamaran.php`, `RiwayatLamaran.php`.
- `app/views/mahasiswa/`.
- Testing modul mahasiswa dan alumni.

## Aturan bersama
- Satu orang satu branch, nama branch `modul/nama-anggota`.
- Jangan mengubah file milik anggota lain tanpa memberi tahu.
- Isi logbook mingguan setiap selesai satu tugas.
