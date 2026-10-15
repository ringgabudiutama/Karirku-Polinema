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
| Helper: format, keamanan, validasi | `app/helpers/` |
| Pelayan berkas unggahan | `public/unduh.php` |
| Skema & data uji | `database/` |

## Penanda di dalam file
- Baris 2 tiap file PHP: `// ===== FRONTEND · ... =====` atau `// ===== BACKEND · ... =====`
- Pemisah bagian di PHP/JS: `// --- Nama bagian ---`
- Pemisah bagian di view: `<!-- ===== Nama bagian ===== -->`
- Di CSS: `/* ===== 05. Nama bagian ===== */` (nomor sesuai daftar isi)

## Alur singkat satu request
URL → `public/index.php` → `Router` → `XxxController::method()` → `Model` (query) → `view()` → file di `app/views/`
