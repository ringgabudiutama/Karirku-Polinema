# Peta Struktur KarirKu Polinema (FRONTEND vs BACKEND)

## FRONTEND (tampilan)
| Bagian | Lokasi |
|---|---|
| CSS (semua gaya, ada daftar isi di baris atas) | `public/assets/css/style.css` |
| JS bersama (ikon, modal, tab, navbar, tabel) | `public/assets/js/app.js` |
| Gambar | `public/assets/img/` |
| Layout dashboard (sidebar + topbar) | `app/views/layouts/` |
| Halaman publik: beranda, masuk, daftar, status akun, info loker, 403/404 | `app/views/publik/` |
| Halaman mahasiswa/alumni | `app/views/mahasiswa/` |
| Halaman perusahaan | `app/views/perusahaan/` |
| Halaman admin (Career Center) | `app/views/admin/` |
| Prototipe HTML lama (acuan desain saja) | `public/*.html` |

## BACKEND (logika & data)
| Bagian | Lokasi |
|---|---|
| Pintu masuk semua request | `public/index.php` |
| Konfigurasi aplikasi & database | `app/config/` |
| Inti: Router, Controller induk, Model induk, Database | `app/core/` |
| Cek login & cek peran | `app/middleware/` |
| Controller (alur tiap fitur) | `app/controllers/` |
| Model (query per tabel) | `app/models/` |
| Service: email, PDF, unggah, notifikasi, WhatsApp | `app/services/` |
| Helper: format, keamanan, validasi, tampilan, item profil | `app/helpers/` |
| Pelayan berkas unggahan | `public/unduh.php` |
| Skema & data uji | `database/` |

## Penanda di dalam file
- Di atas setiap method controller: `// [URL] GET /admin/profil  →  tampil: views/admin/profil.php · peran: admin`.
  Jadi saat live coding cukup Ctrl+F alamat yang sedang dibuka di browser (mis. `/admin/profil`).
- Baris 2 tiap file PHP: `// ===== FRONTEND · ... =====` atau `// ===== BACKEND · ... =====`
- Pemisah bagian di PHP/JS: `// --- Nama bagian ---`
- Pemisah bagian di view: `<!-- ===== Nama bagian ===== -->`
- Di CSS: `/* ===== 05. Nama bagian ===== */` (nomor sesuai daftar isi). Revisi ada di bagian 30 dan 31.
- Di `app.js`: daftar isi di baris paling atas; huruf A–M merujuk ke poin revisi dosen.

## Alur singkat satu request
URL → `public/index.php` → `Router` → `XxxController::method()` → `Model` (query) → `view()` → file di `app/views/`

## Peta URL → Controller → View (semua halaman)

Cara baca: alamat di browser `/admin/profil` = `AdminController::profil()`. Tanda hubung jadi huruf besar (`simpan-profil` → `simpanProfil`).

### AdminController (`app/controllers/AdminController.php`)

| URL | Jenis | Method | Model yang dipakai | Hasil |
|---|---|---|---|---|
| `/admin/dashboard` | GET | `dashboard()` | Pengguna, Notifikasi | `views/admin/dashboard.php` |
| `/admin/persetujuan` | GET | `persetujuan()` | Pengguna, Jurusan | `views/admin/persetujuan-akun.php` |
| `/admin/detail-pendaftar/{penggunaId}` | GET | `detailPendaftar()` | Pengguna, Mahasiswa, Perusahaan, DokumenVerifikasi, VerifikasiAkun | `views/admin/persetujuan-detail.php` |
| `/admin/putuskan/{penggunaId}` | POST | `putuskan()` | VerifikasiAkun, Pengguna | redirect ke `/admin/persetujuan` |
| `/admin/persetujuan-lowongan` | GET | `persetujuanLowongan()` | Lowongan | `views/admin/persetujuan-lowongan.php` |
| `/admin/detail-lowongan/{id}` | GET | `detailLowongan()` | Lowongan, Perusahaan | `views/admin/lowongan-detail.php` |
| `/admin/putuskan-lowongan/{id}` | POST | `putuskanLowongan()` | Lowongan | redirect ke `/admin/persetujuan-lowongan` |
| `/admin/kelola-pengguna` | GET | `kelolaPengguna()` | Mahasiswa, Perusahaan, Jurusan | `views/admin/kelola-pengguna.php` |
| `/admin/nonaktifkan-pengguna/{penggunaId}` | POST | `nonaktifkanPengguna()` | VerifikasiAkun, Pengguna | proses |
| `/admin/aktifkan-pengguna/{penggunaId}` | POST | `aktifkanPengguna()` | VerifikasiAkun, Pengguna | proses |
| `/admin/reset-sandi-pengguna/{penggunaId}` | POST | `resetSandiPengguna()` | Pengguna, Notifikasi | proses |
| `/admin/profil-mahasiswa/{mahasiswaId}` | GET | `profilMahasiswa()` | Mahasiswa, ProfilItem, Skill, Bidang, Lamaran, VerifikasiAkun | `views/admin/profil-mahasiswa.php` |
| `/admin/profil-perusahaan/{perusahaanId}` | GET | `profilPerusahaan()` | Perusahaan, Lowongan, DokumenVerifikasi, VerifikasiAkun | `views/admin/profil-perusahaan.php` |
| `/admin/monitoring-lowongan` | GET | `monitoringLowongan()` | Lowongan, Bidang, Jurusan | `views/admin/monitoring-lowongan.php` |
| `/admin/nonaktifkan-lowongan/{id}` | POST | `nonaktifkanLowongan()` | Lowongan | proses |
| `/admin/unduh-rekap-lowongan` | GET | `unduhRekapLowongan()` | Lowongan | proses |
| `/admin/rekap-lamaran` | GET | `rekapLamaran()` | Lamaran, Mahasiswa, Jurusan | `views/admin/rekap-lamaran.php` |
| `/admin/unduh-rekap-lamaran` | GET | `unduhRekapLamaran()` | Lamaran | proses |
| `/admin/tracer-karier` | GET | `tracerKarier()` | Mahasiswa, Jurusan | `views/admin/tracer-karier.php` |
| `/admin/unduh-tracer-karier` | GET | `unduhTracerKarier()` | Mahasiswa | proses |
| `/admin/pengaturan` | GET | `pengaturan()` | Pengaturan, AdminJurusanKontak, Pengguna | `views/admin/pengaturan.php` |
| `/admin/simpan-pengaturan` | POST | `simpanPengaturan()` | Pengaturan | redirect ke `/admin/pengaturan#email` |
| `/admin/kirim-email-uji` | POST | `kirimEmailUji()` | - | redirect ke `/admin/pengaturan#email` |
| `/admin/kirim-ulang-email/{logId}` | POST | `kirimUlangEmail()` | - | redirect ke `/admin/pengaturan?` |
| `/admin/ganti-password` | POST | `gantiPassword()` | - | proses |
| `/admin/profil` | GET | `profil()` | Admin, Pengguna | `views/admin/profil.php` |
| `/admin/simpan-profil` | POST | `simpanProfil()` | Admin, Pengguna | redirect ke `/admin/profil` |

### AkunController (`app/controllers/AkunController.php`)

| URL | Jenis | Method | Model yang dipakai | Hasil |
|---|---|---|---|---|
| `/akun/ganti-sandi-wajib` | GET | `gantiSandiWajib()` | - | `views/publik/ganti-sandi-wajib.php` |
| `/akun/simpan-sandi-wajib` | POST | `simpanSandiWajib()` | Pengguna | redirect ke `/akun/ganti-sandi-wajib` |

### AuthController (`app/controllers/AuthController.php`)

| URL | Jenis | Method | Model yang dipakai | Hasil |
|---|---|---|---|---|
| `/masuk` | GET | `formMasuk()` | - | `views/publik/masuk.php` |
| `/auth/proses-masuk` | POST | `prosesMasuk()` | Pengguna, Mahasiswa | redirect ke `/masuk` |
| `/daftar` | GET | `formDaftar()` | Jurusan, ProgramStudi | `views/publik/daftar.php` |
| `/auth/proses-daftar` | POST | `prosesDaftar()` | - | redirect ke `/daftar?peran=` |
| `/status-akun` | GET | `statusAkun()` | Pengguna, Mahasiswa, Perusahaan, VerifikasiAkun, DokumenVerifikasi | `views/publik/status-akun.php` |
| `/auth/kirim-perbaikan` | POST | `kirimPerbaikan()` | Pengguna, DokumenVerifikasi | redirect ke `/status-akun` |
| `/auth/lupa-sandi` | GET | `lupaSandi()` | Pengguna | `views/publik/lupa-sandi.php` |
| `/auth/proses-lupa-sandi` | POST | `prosesLupaSandi()` | Pengguna | redirect ke `/auth/lupa-sandi` |
| `/auth/reset-sandi/{token}` | GET | `resetSandi()` | Pengguna | `views/publik/reset-sandi.php` |
| `/auth/proses-reset-sandi/{token}` | POST | `prosesResetSandi()` | Pengguna | redirect ke `/masuk` |
| `/keluar` | GET | `keluar()` | - | `views/publik/keluar.php` |

### KirimLokerController (`app/controllers/KirimLokerController.php`)

| URL | Jenis | Method | Model yang dipakai | Hasil |
|---|---|---|---|---|
| `/kirim-loker/index` | GET | `index()` | AdminJurusanKontak, Lowongan, PengirimanLoker, Jurusan, Pengaturan | `views/admin/kirim-loker.php` |
| `/kirim-loker/kirim/{lowonganId}/{jurusanId}` | GET | `kirim()` | Lowongan, Jurusan, AdminJurusanKontak, Admin, PengirimanLoker, Pengaturan | redirect ke `/kirim-loker?lowongan_id=` |
| `/kirim-loker/simpan-kontak` | POST | `simpanKontak()` | Admin, AdminJurusanKontak | redirect ke `/admin/pengaturan` |

### LamaranController (`app/controllers/LamaranController.php`)

| URL | Jenis | Method | Model yang dipakai | Hasil |
|---|---|---|---|---|
| `/lamaran/kirim/{lowonganId}` | GET | `kirim()` | Lowongan, Mahasiswa, Lamaran, Skill | `views/mahasiswa/lamaran-form.php` |
| `/lamaran/lamaran-saya` | GET | `lamaranSaya()` | Mahasiswa, Lamaran | `views/mahasiswa/lamaran.php` |
| `/lamaran/batalkan/{id}` | POST | `batalkan()` | Mahasiswa, Lamaran | redirect ke `/lamaran/lamaran-saya` |
| `/lamaran/detail-pelamar/{id}` | GET | `detailPelamar()` | Lamaran, Interview, Perusahaan, Mahasiswa, ProfilItem, Skill, RiwayatLamaran | `views/perusahaan/pelamar-detail.php` |
| `/lamaran/ubah-status/{id}` | POST | `ubahStatus()` | Lamaran | proses |
| `/lamaran/terima/{id}` | POST | `terima()` | Lamaran | redirect ke `/lamaran/detail-pelamar/` |

### LowonganController (`app/controllers/LowonganController.php`)

| URL | Jenis | Method | Model yang dipakai | Hasil |
|---|---|---|---|---|
| `/lowongan/daftar` | GET | `daftar()` | Lowongan, Mahasiswa, LowonganDisimpan, Jurusan, Bidang | `views/mahasiswa/lowongan.php` |
| `/lowongan/detail/{id}` | GET | `detail()` | Lowongan, Mahasiswa, LowonganDisimpan, Lamaran | `views/mahasiswa/lowongan-detail.php` |
| `/lowongan/simpan/{id}` | POST | `simpan()` | Mahasiswa, LowonganDisimpan, Lowongan | proses |
| `/lowongan/form-pasang/{id}` | GET | `formPasang()` | Lowongan, Perusahaan, Bidang, Jurusan | `views/perusahaan/lowongan-form.php` |
| `/lowongan/proses-pasang` | POST | `prosesPasang()` | Perusahaan, Lowongan, Bidang | redirect ke `/perusahaan/lowongan` |
| `/lowongan/tutup/{id}` | POST | `tutup()` | Lowongan | redirect ke `/perusahaan/lowongan` |
| `/lowongan/perpanjang/{id}` | POST | `perpanjang()` | Lowongan | redirect ke `/perusahaan/lowongan` |
| `/info-loker/{kode}` | GET | `pratinjau()` | Lowongan | `views/publik/info-loker.php` |

### MahasiswaController (`app/controllers/MahasiswaController.php`)

| URL | Jenis | Method | Model yang dipakai | Hasil |
|---|---|---|---|---|
| `/mahasiswa/dashboard` | GET | `dashboard()` | ProfilItem, Skill, Lamaran, Mahasiswa, LowonganDisimpan, Lowongan | `views/mahasiswa/dashboard.php` |
| `/mahasiswa/disimpan` | GET | `disimpan()` | LowonganDisimpan | `views/mahasiswa/disimpan.php` |
| `/mahasiswa/profil` | GET | `profil()` | ProfilItem, Skill, Mahasiswa, Bidang | `views/mahasiswa/profil.php` |
| `/mahasiswa/simpan-profil` | POST | `simpanProfil()` | ProfilItem, Mahasiswa, DokumenVerifikasi, Skill, Bidang | redirect ke `/mahasiswa/profil` |
| `/mahasiswa/generate-cv` | GET | `generateCv()` | ProfilItem, Skill | proses |
| `/mahasiswa/unggah-cv` | POST | `unggahCv()` | Mahasiswa | redirect ke `/mahasiswa/profil` |
| `/mahasiswa/status-karier` | POST | `statusKarier()` | Mahasiswa | redirect ke `/mahasiswa/profil#karier` |
| `/mahasiswa/pengaturan-akun` | GET | `pengaturanAkun()` | Pengguna | `views/mahasiswa/pengaturan.php` |
| `/mahasiswa/simpan-pengaturan-akun` | POST | `simpanPengaturanAkun()` | Pengguna, Mahasiswa | redirect ke `/mahasiswa/pengaturan-akun#alamat` |

### MitraController (`app/controllers/MitraController.php`)

| URL | Jenis | Method | Model yang dipakai | Hasil |
|---|---|---|---|---|
| `/mitra/{id}` | GET | `detail()` | Perusahaan, Lowongan | `views/publik/mitra-detail.php` |

### NotifikasiController (`app/controllers/NotifikasiController.php`)

| URL | Jenis | Method | Model yang dipakai | Hasil |
|---|---|---|---|---|
| `/notifikasi/semua` | GET | `semua()` | Notifikasi | `views/umum/notifikasi.php` |
| `/notifikasi/tandai-dibaca/{id}` | GET | `tandaiDibaca()` | Notifikasi | proses |
| `/notifikasi/tandai-semua-dibaca` | POST | `tandaiSemuaDibaca()` | Notifikasi | proses |

### PerusahaanController (`app/controllers/PerusahaanController.php`)

| URL | Jenis | Method | Model yang dipakai | Hasil |
|---|---|---|---|---|
| `/perusahaan/dashboard` | GET | `dashboard()` | Lowongan, Lamaran | `views/perusahaan/dashboard.php` |
| `/perusahaan/lowongan` | GET | `lowongan()` | Lowongan | `views/perusahaan/lowongan.php` |
| `/perusahaan/pelamar` | GET | `pelamar()` | Lamaran, Lowongan, Jurusan | `views/perusahaan/pelamar.php` |
| `/perusahaan/profil` | GET | `profil()` | - | `views/perusahaan/profil.php` |
| `/perusahaan/simpan-profil` | POST | `simpanProfil()` | Perusahaan | redirect ke `/perusahaan/profil` |
| `/perusahaan/pengaturan-akun` | GET | `pengaturanAkun()` | Pengguna | `views/perusahaan/pengaturan.php` |
| `/perusahaan/simpan-pengaturan-akun` | POST | `simpanPengaturanAkun()` | Pengguna, Perusahaan | redirect ke `/perusahaan/pengaturan-akun` |
