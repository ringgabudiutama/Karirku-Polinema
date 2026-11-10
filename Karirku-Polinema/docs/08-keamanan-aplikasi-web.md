# Keamanan aplikasi web KarirKu Polinema

Dokumen ini melengkapi `05-panduan-hosting-aman.md` (database dan server). Isinya hasil audit
lapisan **aplikasi web**: apa yang ditemukan, bagaimana dibuktikan, apa perbaikannya, dan apa
yang masih belum tercakup. Semua temuan di bawah **dibuktikan dengan serangan nyata** terhadap
aplikasi yang berjalan (bukan hanya membaca kode), lalu diuji ulang setelah diperbaiki.

## 1. Temuan dan perbaikan

| # | Temuan | Tingkat | Bukti serangan | Perbaikan |
|---|---|---|---|---|
| 1 | **Folder proyek terbuka lewat URL** di XAMPP/hosting bersama: `storage/uploads/` (KTM, ijazah) bisa dilihat daftar isinya dan diunduh tanpa login; `email.log`, `database/*.sql`, bahkan `tests/*.php` bisa dibuka/dijalankan | Kritis | Apache bergaya XAMPP, kode asli: 9 dari 11 alamat sensitif menjawab 200 (termasuk daftar isi folder root proyek) | `.htaccess` di root (hanya `public/` yang boleh), `Require all denied` di `app`, `storage`, `database`, `docs`, `tests`, `scripts`; `Options -Indexes`. Sesudah: 0 dari 11 menjawab 200 (semua 403, root dialihkan ke `public/`), 10 trik penyelundupan alamat gagal |
| 2 | **XSS tersimpan lewat `javascript:`**: tautan portofolio mahasiswa diperiksa `FILTER_VALIDATE_URL` saja, yang meloloskan `javascript://x.com/%0Aalert(1)`; `e()` tidak memblokir skema | Tinggi | Mahasiswa menyimpan tautan itu; halaman admin merender `href="javascript://..."` | `urlHttpValid()` (wajib `http(s)://`) saat simpan, `tautanAman()` saat tampil (melindungi juga data lama). Sesudah: ditolak, dan data lama dinetralkan |
| 3 | **Penebak password tanpa batas**: pembatas login disimpan di sesi, penyerang cukup membuang cookie | Tinggi | 40 tebakan dengan sesi baru: tidak pernah terkunci | Pembatas di database (`percobaan_login`): 5 per (email+IP), 20 per email dari semua IP. Sesudah: terkunci di tebakan ke-6 / ke-21 |
| 4 | **Email terdaftar bisa dibedakan** dari waktu respons login (68 ms vs 21 ms) | Sedang | 30 percobaan masing-masing, selisih median 47 ms | Selalu membandingkan dengan hash palsu bila email tidak ada. Sesudah: selisih 0,3 ms |
| 5 | **Email reset bisa dibanjirkan**: batas 3 permintaan disimpan di sesi | Sedang | Sesi baru tiap permintaan: tanpa batas | `batasLaju()` di database: 3 per email dan 30 per IP per 15 menit |
| 6 | **Email terdaftar bisa dibedakan** dari waktu respons lupa-sandi (1.072 ms vs 22 ms) karena email dikirim di dalam permintaan | Sedang | SMTP lambat 1 detik: selisih 1.050 ms | Email dikirim setelah jawaban dilepas (`fastcgi_finish_request`) dan kunci sesi dilepas lebih dulu. Sesudah: selisih 6 ms, email tetap sampai (3 dari 3) |
| 7 | **Password lemah diterima** (hanya cek panjang 8): `12345678`, `password123`, `polinema2026`; bcrypt memotong di 72 byte | Sedang | Uji kebijakan | `validasiPassword()`: 8 sampai 72 byte, menolak password umum, kata umum + angka, pola berulang |
| 8 | **Tidak ada Content-Security-Policy** (pertahanan terakhir bila ada XSS) | Sedang | Header tidak ada | CSP dengan nonce per permintaan; semua `<script>` inline diberi nonce; 14 atribut `on*=` dan 2 `javascript:` diganti `data-*` ditangani `app.js`. Sesudah: 1.156 halaman patuh |
| 9 | Header lain kurang: HSTS, COOP, `X-Powered-By` bocor | Rendah | Header tidak ada | HSTS (hanya HTTPS), `Cross-Origin-Opener-Policy`, `X-Permitted-Cross-Domain-Policies`, hapus `X-Powered-By` |
| 10 | Data ke `<script>` tanpa `JSON_HEX_TAG`; parameter `?peran=` tidak divalidasi | Rendah | Tidak bisa dieksploitasi (sudah di-escape), tapi rapuh | `jsonAman()` dan daftar putih peran |
| 11 | `cek-sistem.php` terbuka untuk umum (alamat DB, versi PHP, **akun admin demo + password**) | Tinggi | Halaman menjawab 200 | 404 kecuali `APP_DEBUG` menyala |
| 12 | Password database tertulis di `database.php` dan ikut di zip | Tinggi | Ada di berkas | Pindah ke env / `database.lokal.php` (lihat `05-...`) |

| 13 | **Foto asli yang diselipi kode (polyglot) diterima** dengan kode utuh: 4 dari 4 lolos, 3 di antaranya benar-benar menjalankan PHP bila server salah konfigurasi. Bom piksel (PNG 30.000x30.000 dari berkas 109 KB) juga diterima. PDF berisi JavaScript diterima | Sedang | 6 foto uji, kode dicek langsung di berkas tersimpan | Gambar didekode lalu **ditulis ulang** (semua data di luar piksel terbuang), orientasi EXIF diterapkan, pindai tag kode (`<?php`, `<?=`, `<script`), batas 25 juta piksel; PDF dipindai untuk JavaScript/Launch/file tertanam (menembus nama yang disamarkan dan stream terkompresi). Sesudah: 23 dari 23 uji lulus, foto sah tetap utuh |

Dua temuan sebelum ini (#11 dan #12) dikerjakan pada tahap database, dicatat di sini agar daftarnya lengkap.

## 2. Yang sudah baik sejak awal (diuji, tidak diubah)

- **SQL injection:** semua nilai lewat placeholder; 13 payload `1=1`/`UNION`/`DROP` ke formulir login: 0 tembus.
- **XSS tersimpan di HTML:** 71 kolom teks ditanami kanari berbahaya, 1.408 halaman ditelusuri sebagai 5 peran:
  58 kolom tampil dan di-escape, **0 bocor** (13 kolom tidak pernah tampil di halaman yang terjangkau).
- **Hak akses antar peran dan antar akun:** tidak ada `/admin/*` yang bisa dibuka non-admin; perusahaan A gagal
  membaca, mengubah, menerima, atau menutup data perusahaan B; mahasiswa gagal membatalkan lamaran orang lain
  (12 dari 12 serangan gagal, dengan kontrol yang membuktikan uji ini sah).
- **Unggah berkas (pemalsuan murni):** 15 serangan (PHP menyamar sebagai foto atau PDF, `.php.jpg`, `.htaccess`, byte NUL,
  HTML/SVG/GIF+PHP menyamar) ditolak; isi berkas dicek (bukan hanya nama), nama diacak, disimpan di luar folder web.
  Yang belum tertangani sejak awal (berkas sah yang diselipi kode) dijelaskan di temuan #13.
- **Reset password:** token 256 bit, disimpan sebagai hash, berlaku 60 menit, sekali pakai, token lain milik akun
  yang sama ikut batal; pesan sama untuk email terdaftar dan tidak.
- Sesi diganti saat login, batas waktu tidak aktif, cookie `HttpOnly` + `SameSite=Lax` (+ `Secure` di HTTPS),
  token "ingat saya" disimpan sebagai hash, tidak ada parameter pengalihan yang bisa dipakai untuk open redirect.

## 3. Pengaturan server (sudah diuji)

`docs/contoh-nginx.conf` adalah konfigurasi lengkap yang sudah dijalankan dan diuji: HTTP dialihkan ke HTTPS,
HSTS dan cookie `Secure` aktif, 11 jalur sensitif tertutup (404/403), halaman prototipe `.html` tertutup, dan
pembatas laju di nginx (login/daftar/lupa-sandi: 10 per menit per IP dengan lonjakan 5; setelah itu 429) tanpa
mengganggu halaman biasa. Apache: `.htaccess` di repositori sudah mencukupi, tetapi cara terbaik tetap mengarahkan
document root ke `public/`.

Di `php.ini` produksi: `expose_php = Off`, `display_errors = Off`, `log_errors = On`,
`session.cookie_httponly = 1`, `session.use_strict_mode = 1`. Aplikasi sudah mengatur sebagian secara mandiri.

## 4. Menjaga agar tetap aman saat menambah fitur

Aturan lengkap dan cara mengulang pengujian ada di `tests/keamanan/README.md`. Ringkasnya:
`<script>` inline wajib bernonce (`cspNonce()`); tanpa `onclick=`/`javascript:`; URL pengguna lewat
`urlHttpValid()` dan `tautanAman()`; data ke JavaScript lewat `jsonAman()`; pembatas lewat `batasLaju()`;
setiap output pengguna lewat `e()`.

## 5. Belum tercakup (rekomendasi, urut prioritas)

1. **Verifikasi dua langkah (2FA) untuk admin.** Akun admin bisa membaca data seluruh mahasiswa dan perusahaan;
   password saja terlalu tipis untuk akun sepenting itu.
2. **Antrean email** lewat cron. Perbaikan #6 menutup kebocoran waktu di PHP-FPM, tetapi di server dev PHP bawaan
   email masih dikirim berurutan, dan SMTP yang mati tetap menahan satu proses PHP.
3. **CAPTCHA** (mis. Cloudflare Turnstile) di pendaftaran dan lupa sandi. Pembatas per IP hanya menahan
   pembuatan akun massal dari satu sumber; jaringan kampus bersama membuat batasnya harus longgar.
4. **Pemindaian virus pada unggahan** (ClamAV). Pemindaian PDF di aplikasi mencari konten aktif (JavaScript, Launch, file
   tertanam) tetapi bukan antivirus: malware yang memakai celah di aplikasi pembaca PDF tidak terdeteksi. Pembuatan ulang
   gambar butuh ekstensi PHP `gd` (dan `exif` agar foto ponsel tidak miring); tanpa `gd`, gambar hanya dipindai. Halaman
   `cek-sistem.php` (lokal) menampilkan statusnya.
5. **Pemantauan:** fail2ban untuk login yang gagal berulang, peringatan bila `STATUS` backup tidak berawalan OK,
   dan log akses nginx dikirim ke tempat terpisah.
6. **Pesan "email sudah terdaftar" saat pendaftaran** masih membocorkan keberadaan akun. Ini kompromi umum
   (pengguna perlu tahu), dibatasi oleh pembatas pendaftaran per IP.
7. **Pustaka pihak ketiga** (font Google dan peta tertanam): jika privasi pengguna penting, simpan font secara lokal
   dan ketatkan `frame-src`.
8. **Uji penetrasi independen** sebelum dibuka untuk umum, dan pindai dengan OWASP ZAP/sqlmap pada situs yang
   sudah berjalan. Audit ini kuat tetapi dikerjakan oleh satu pihak dengan alat terbatas.

Audit ini **tidak** mencakup: serangan membanjiri (DDoS), server yang diretas langsung, admin yang terkena
phishing, dan kelemahan di sistem operasi atau PHP. Tidak ada sistem yang 100% aman.
