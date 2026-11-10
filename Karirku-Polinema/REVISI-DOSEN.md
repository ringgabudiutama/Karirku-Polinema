# Revisi Dosen (Oktober 2026) — PHP Native

Semua revisi dikerjakan langsung di kode **PHP native MVC** proyek ini
(Router, Controller, Model, View buatan sendiri + PDO PostgreSQL).
**Tidak memakai framework apa pun** (bukan Laravel). Pustaka opsional dari
`composer.json` (PHPMailer, Dompdf) tetap opsional: tanpa composer, email
dikirim oleh `app/services/SmtpSederhana.php` yang ditulis sendiri.

Langkah wajib setelah mengambil versi ini:

0. **Cara termudah di pgAdmin:** buka Query Tool pada database
   `karirku_polinema`, buka `database/00-INSTAL-ULANG.sql`, tekan Execute.
   Satu file itu membuat ulang semua tabel + data demo (01–06).
   File 01–04 juga sudah **aman dijalankan berulang dan tidak error** bila
   sudah pernah dijalankan; bila urutannya salah, pesannya menyebut solusinya.
1. Database **diperbarui otomatis**: saat aplikasi pertama kali tersambung ke
   database versi lama, file `03`, `04`, dan `06` dijalankan sendiri (database kosong:
   `01`–`06`). Bila gagal, pesannya menyebut file mana yang harus dijalankan
   manual di pgAdmin. Menjalankan `04-revisi-dosen.sql` manual juga tetap boleh.
2. Isi SMTP dan `APP_URL` (lihat README langkah 6). Tanpa SMTP, email hanya
   dicatat dan statusnya ditampilkan jujur, tidak pura-pura "terkirim".
3. Buka `/cek-sistem.php`: semua baris harus hijau, termasuk
   "Migrasi revisi dosen", mbstring, dan openssl.
4. `base_url` boleh dibiarkan kosong: terdeteksi otomatis, baik lewat
   `jalankan.bat` (localhost:8000) maupun subfolder XAMPP
   (`localhost/karirku-polinema/public`).

---

---

## Revisi tahap 2 (30 Oktober 2026)

Database: file baru **`database/06-revisi-profil.sql`** (kolom `profil_item.detail`
JSONB untuk data lengkap, serta `admin.foto`, `admin.jabatan`, `admin.no_whatsapp`).
Aplikasi menjalankannya **otomatis** saat pertama tersambung; boleh juga dijalankan
manual atau cukup jalankan ulang `00-INSTAL-ULANG.sql`. Semua file aman dijalankan
berulang dan dalam urutan 01→06 maupun 01→04, 06, 05.

### Mahasiswa / Alumni

| No | Permintaan | Yang dikerjakan | Cara melihat |
|---|---|---|---|
| 1 | Input berkas apa pun dipratinjau/dikonfirmasi dulu baru tersimpan | Setiap formulir yang berisi berkas memunculkan jendela **"Periksa berkas sebelum disimpan"**: gambar tampil, PDF tampil langsung di halaman, nama + ukuran berkas, tombol **Batal, pilih ulang** / **Ya, simpan**. Berkas baru tersimpan setelah *Ya, simpan*. Foto profil, logo, dan foto admin menampilkan **gambar lama → gambar baru**. | Profil Karier > ganti foto, unggah CV, tab Dokumen, tambah sertifikat |
| 2 | Pendidikan lengkap (ijazah, NIM, jurusan, dll.) | Field: jenjang, sekolah/PT, program studi, jurusan/fakultas, **NIM/NIS/NISN**, kota, tanggal masuk & lulus, **IPK/nilai + skala**, **nomor ijazah/SKL**, akreditasi, prestasi/TA, **scan ijazah** dan **transkrip**. Tombol *Tambah pendidikan Polinema (terisi otomatis)* mengisi NIM, prodi, jurusan, jenjang dari data akun. | Profil Karier > Pendidikan |
| 3 | Klik simpan jangan kembali ke Data diri | Setelah simpan, halaman kembali ke **tab yang sama** (alamat `#pendidikan`, `#dokumen`, dst.) dan posisi gulir dipulihkan. | Simpan di tab mana pun |
| 4 | Pengalaman lebih lengkap | Jenis (magang/PKL, penuh waktu, paruh waktu, kontrak, freelance, proyek, organisasi, kepanitiaan, relawan), posisi, perusahaan, bidang/departemen, lokasi, sistem kerja, periode, tugas, **pencapaian terukur**, **tools**, **referensi + kontak**, **paklaring**. | Profil Karier > Pengalaman |
| 5 | Sertifikat detail | Jenis sertifikat, nama, penerbit, **nomor/ID kredensial**, tanggal terbit, **berlaku sampai**, skor/nilai, **tautan verifikasi**, kompetensi yang diuji, file sertifikat (wajib). | Profil Karier > Sertifikat |
| 6 | Dokumen dipratinjau dulu | Tab Dokumen: pratinjau di bawah kotak unggah + jendela konfirmasi sebelum disimpan. | Profil Karier > Dokumen |

Data lengkap ini juga tampil di **Detail pelamar (perusahaan)**, **Profil mahasiswa (admin)**,
dan **CV otomatis**. Item bisa **diubah** (tombol *Ubah*) dan berkasnya bisa diganti atau dihapus.

### Perusahaan

| No | Permintaan | Yang dikerjakan |
|---|---|---|
| 1 | Panel Proses seleksi tidak bisa digulir sebelum kolom kiri | Di layar laptop, panel kanan punya gulir sendiri (setinggi layar), jadi bisa langsung digulir tanpa menunggu kolom kiri. Di tablet/HP panel kembali mengikuti alur halaman. |
| 2 | UI Lowongan Saya jelek, kolom Aksi jadi 2 baris | Tabel diganti **kartu lowongan**: pamflet, posisi, status berikon, bidang, jenis & sistem kerja, batas + hitung mundur berwarna, jumlah pelamar + label "baru", bar kuota diterima. Aksi = **1 tombol utama** sesuai status (Perbaiki & ajukan / Lihat pelamar / Edit) + menu **Kelola ▾** (Lihat seperti pelamar, Kelola pelamar, Edit, Salin jadi baru, Perpanjang, Tutup). Tidak pernah pecah 2 baris; di HP tombol melebar penuh. |
| 3 | Ganti logo perlu pratinjau + konfirmasi | Pilih logo → jendela konfirmasi menampilkan **logo saat ini → logo baru** → *Ya, simpan* atau *Batal, pilih ulang*. |

### Admin

| No | Permintaan | Yang dikerjakan |
|---|---|---|
| 1 | Admin bisa ganti profil | Menu baru **Profil Saya** (sidebar + menu nama di kanan atas): ganti foto (dengan konfirmasi), nama, jabatan, nomor WhatsApp, email login (wajib kata sandi saat ini), hapus foto, ringkasan antrean, dan riwayat aktivitas sendiri. Nama, jabatan, dan foto langsung tampil di topbar. |
| 2 | UI Monitoring lowongan, terutama status | Kartu ringkasan per status (klik untuk memfilter), tab status dengan jumlah, **pill status berwarna + ikon**, garis warna status di kiri kartu, logo + nama perusahaan, pamflet, batas + hitung mundur, tanggal diajukan, jumlah pelamar, bar kuota, alasan nonaktif, tombol *Tinjau/Detail* + menu *Kelola* (detail, profil perusahaan, halaman publik, nonaktifkan). |

Data dummy: semua pendidikan, pengalaman, dan sertifikat contoh sudah berisi data lengkap
(NIM, IPK, nomor ijazah, jenis pengalaman, tools, nomor kredensial, dll.).

### Bukti pengujian tahap 2

- `php tests/scan-method.php`, `uji-rute.php` (75 method), `uji-form.php` (94 form),
  `jelajah.php` (1.020 alamat), `uji-berkas.php` (556 berkas): semua bersih.
- Uji browser alur nyata: tambah sertifikat + berkas → jendela konfirmasi → tersimpan dan
  tetap di tab Sertifikat; ubah sertifikat; tambah pengalaman; tab Minat & Dokumen kembali
  ke tab yang sama; foto/logo/foto admin menampilkan lama → baru; batal mengosongkan pilihan;
  panel Proses seleksi bisa digulir sendiri; profil admin tersimpan, ganti email tanpa sandi
  yang benar ditolak.
- Instal SQL diuji 4 skenario (00 saja; 01→06; 01–04, 06, 05; 00 dua kali + 06) dan
  migrasi otomatis dari database versi sebelumnya: tidak ada error.

---

## Data dummy untuk demo

`database/05-data-dummy.sql` (sudah termasuk di `00-INSTAL-ULANG.sql`):
140 lowongan dari 16 perusahaan, semuanya dengan pamflet bergambar
(ilustrasi sesuai bidang), logo perusahaan, jurusan sasaran, dan riwayat
persetujuan; plus akun **ringga.perusahaan@karirku.id / ringga123** (PT Ringga Karya
Digital) berisi 6 lowongan dan 35 pelamar dengan status diajukan, screening,
interview, diterima, dan ditolak. Gambar dibuat ulang dengan
`python3 tests/buat-data-dummy.py`.

## Ringkasan per poin

| Poin | Permintaan | Status | Di mana dilihat saat demo |
|---|---|---|---|
| A | Tombol kembali + detail mitra sebelum login | Selesai | Semua halaman detail/form; Beranda > logo mitra > `/mitra/{id}` |
| B | Email & login (Ingat saya, kembali ke tujuan, status email jujur) | Selesai | Halaman Masuk; Admin > Pengaturan > Email |
| C | Pratinjau pamflet sebelum unggah | Selesai | Perusahaan > Pasang lowongan |
| D | Perpanjang lowongan lewat modal | Selesai | Perusahaan > Lowongan Saya > Perpanjang |
| E | Form lamaran terisi otomatis + snapshot | Selesai | Mahasiswa > Lamar; Perusahaan > Detail pelamar |
| F | Alamat lengkap (alamat, kota, provinsi, kode pos) | Selesai | Pengaturan Akun (mahasiswa & perusahaan) |
| G | Isian tidak hilang saat gagal / sesi habis | Selesai | Form apa pun, coba kirim dengan isian salah |
| H | Paginasi 10 data per halaman | Selesai | Semua daftar (lowongan, pelamar, pengguna, rekap, log) |
| I | Filter rekap angkatan + rentang tanggal | Selesai | Admin > Rekap Lamaran + Unduh PDF |
| J | Keamanan cookie & sesi | Selesai | DevTools > Application > Cookies |
| K | Alasan penolakan wajib + template + riwayat | Selesai | Admin > Persetujuan Akun / Lowongan |
| L | Reset kata sandi oleh admin | Selesai | Admin > Kelola Pengguna > profil > Reset sandi |
| M | Lowongan wajib disetujui admin dulu | Selesai | Perusahaan pasang → Admin > Persetujuan Lowongan |
| + | Tampilan responsif (HP, tablet, laptop) | Selesai | Buka di HP / DevTools mode perangkat |

---

## A. Tombol kembali dan detail mitra publik

- Helper `tombolKembali()` (`app/helpers/tampilan.php`) dipasang di semua
  halaman detail dan formulir. Bila halaman dibuka dari dalam aplikasi, tombol
  memakai riwayat browser (posisi filter/halaman sebelumnya tetap); bila dibuka
  langsung dari tautan, tombol jatuh ke halaman induk yang masuk akal.
- Bila ada isian yang belum disimpan, tombol kembali meminta konfirmasi dulu.
- Halaman baru `/mitra/{id}` (`MitraController`) bisa dibuka **tanpa login**:
  profil perusahaan dan lowongan yang sedang tayang. Perusahaan yang belum
  aktif/dinonaktifkan menghasilkan 404, tidak membocorkan data.

## B. Email dan login

- **Ingat saya**: token acak `selector:validator`; yang disimpan di database
  hanya *hash* validator (tabel `token_ingat`), berlaku 30 hari, diganti setiap
  dipakai. Tanpa centang, sesi berakhir setelah 120 menit tidak aktif.
- **Kembali ke halaman tujuan**: buka halaman yang butuh login → diarahkan ke
  Masuk → setelah masuk langsung kembali ke halaman tadi (termasuk filternya).
  Tujuan dicek harus jalur internal dan sesuai peran (anti *open redirect*).
- **Semua email lewat satu pintu** `MailService::kirim()`, dan setiap email
  dicatat di tabel `log_email` dengan status `terkirim`, `gagal`, atau `log`
  (SMTP belum diisi). Pesan ke pengguna jujur: tidak pernah menulis "email
  terkirim" kalau sebenarnya gagal.
- Admin > Pengaturan > Email: status konfigurasi (tanpa menampilkan kata
  sandi SMTP), tombol **Kirim email uji**, riwayat email dengan filter status,
  dan tombol **Kirim ulang** untuk yang gagal. Isi email reset sandi tidak
  disimpan di log (berisi tautan rahasia).
- Lupa sandi: dibatasi 3 kali per 15 menit, tautan berlaku 60 menit, sekali
  pakai, dan memakai alamat absolut (`APP_URL`) sehingga bisa diklik dari email.

## C. Pratinjau pamflet

- Begitu berkas dipilih: pratinjau gambar atau PDF, nama, jenis, dan ukuran;
  tombol **Ganti** dan **Hapus pilihan**.
- Validasi di browser (jenis JPG/PNG/PDF, ukuran maksimum) **dan** di server
  (`UploadService`: cek MIME asli dengan `finfo`, `getimagesize` untuk gambar).
- Saat mengedit, pamflet lama tetap ditampilkan; bila unggahan baru gagal,
  pamflet lama **tidak** terhapus dan isian formulir tetap ada.

## D. Perpanjang lowongan

- Modal berisi batas lamaran baru dan kuota baru, maksimal 6 bulan ke depan,
  kuota 1–1000 dan harus lebih besar dari jumlah pelamar yang sudah diterima.
- Disimpan dalam transaksi dengan `SELECT … FOR UPDATE`, lowongan ditutup
  otomatis dibuka lagi, admin diberi notifikasi, dan tercatat di riwayat.
- Perpanjang **tidak** butuh persetujuan ulang (isi lowongan tidak berubah).

## E. Lamaran terisi otomatis

- Formulir lamaran menampilkan data dari profil (nama, NIM, prodi, angkatan,
  kontak, alamat, skill, CV) sebagai blok "Data yang akan dikirim", dengan
  tautan ke profil bila ada yang perlu dibetulkan. Pelamar wajib mencentang
  "Data di atas sudah benar".
- Saat dikirim, data disimpan sebagai **snapshot** (JSON). Di halaman
  perusahaan, snapshot saat melamar ditampilkan terpisah dari profil terkini,
  sehingga perubahan profil sesudahnya tidak mengubah berkas lamaran.
- Melamar dua kali, setelah batas waktu, atau saat kuota penuh ditolak di
  server (bukan cuma tombol yang disembunyikan); dobel klik dicegah dengan
  kunci baris + unique constraint.
- Form jadwal interview terisi otomatis dari jadwal sebelumnya; validasi
  tanggal tidak boleh lampau, jam HH:MM, tautan `https` untuk daring, tempat
  wajib untuk luring.

## F. Alamat terstruktur

- Kolom `alamat`, `kota/kabupaten`, `provinsi` (pilihan dari 38 provinsi),
  `kode_pos` (5 digit) untuk mahasiswa dan perusahaan, divalidasi server
  (`validasiAlamat()`).

## G. Isian tidak hilang

- Gagal validasi → kembali ke formulir dengan **semua isian lama** dan daftar
  kesalahan yang jelas (kata sandi tidak pernah diisi ulang).
- Token CSRF kedaluwarsa (halaman dibiarkan lama) → **tidak** muncul halaman
  error 419; pengguna dikembalikan ke formulir dengan isian utuh dan pesan
  "silakan kirim ulang".
- Draft otomatis di browser per akun (tidak tercampur antar akun di komputer
  lab), muncul tawaran **Pulihkan / Buang draft**, terhapus otomatis setelah
  berhasil dikirim atau setelah 7 hari. Berkas dan kata sandi tidak disimpan.
- Peringatan saat meninggalkan halaman dengan perubahan belum disimpan.
- Tombol kirim terkunci setelah diklik (tidak ada data ganda); formulir
  bertahap (pendaftaran) tidak ikut terkunci saat pindah langkah.
- **Berkas tidak perlu dipilih ulang** (`app/services/BerkasSementara.php`):
  berkas pada pengiriman yang gagal (validasi, sesi habis, error server)
  disimpan sementara maks. 2 jam khusus untuk sesi pemiliknya, ditampilkan
  lagi di formulir ("Berkas tadi masih tersimpan", lengkap dengan pratinjau,
  tombol Ganti / Jangan pakai), dan dipakai otomatis saat dikirim ulang.
- **Kata sandi pendaftaran tidak perlu diketik ulang**: yang disimpan di sesi
  hanya hash-nya (bukan teks asli), maks. 2 jam.
- Pendaftaran yang gagal langsung membuka **langkah yang bermasalah** (mis.
  NIM sudah dipakai → langkah 2), bukan mengulang dari langkah 1.
- **Semua formulir dipulihkan otomatis**, termasuk yang berada di jendela
  pop-up (pop-up dibuka kembali dengan isiannya) dan tab profil.
- Error tak terduga menampilkan halaman ramah dengan tombol **Kembali ke
  formulir**; isian dan berkas sudah diamankan. Pesan teknis database
  (`SQLSTATE ...`) tidak pernah tampil ke pengguna, diganti kalimat jelas.

## Isian otomatis (auto input)

| Formulir | Yang terisi sendiri |
|---|---|
| Jadwal interview (detail pelamar) | Hari kerja terdekat (H+2) jam 09.00, alamat kantor, narahubung = PIC + WhatsApp PIC, pakaian, berkas yang dibawa, catatan. Jadwal lama yang sudah lewat diganti otomatis. |
| Tolak pelamar | Tombol isi cepat alasan yang sudah memuat nama pelamar dan posisi. |
| Pasang lowongan baru | Lokasi = kota perusahaan, bidang = bidang usaha, batas lamaran +30 hari; atau **salin dari lowongan sebelumnya** (tombol "Salin jadi baru"). |
| Perpanjang lowongan | Batas lama + 30 hari (maks. 6 bulan), kuota sekarang. |
| Lamaran mahasiswa | Data profil, CV, alamat, skill; contoh pesan untuk perusahaan memakai nama, prodi, posisi. |
| Status karier | Dari lamaran yang **diterima**: perusahaan, posisi, tanggal mulai. |
| Alamat | Provinsi terisi dari kota/kabupaten (daftar 109 kota, semua kab/kota Jawa Timur). |
| Reset sandi oleh admin | Sandi sementara acak; tanpa SMTP, pilihan "kirim tautan" dinonaktifkan dan "sandi sementara" langsung terpilih. |
| Masuk / Lupa sandi | Email terakhir yang dipakai di browser ini. |

## H. Paginasi

- 10 data per halaman, dihitung **di database** (`LIMIT/OFFSET` + `COUNT`),
  bukan dipotong di PHP. Filter dan kata kunci tetap terbawa saat pindah
  halaman; nomor halaman di luar jangkauan dialihkan ke halaman terakhir.

## I. Rekap lamaran

- Filter digabung: kata kunci, status, jurusan, prodi, **angkatan**, dan
  **rentang tanggal** (WIB, tanggal akhir ikut terhitung sampai 23.59).
- Kartu ringkasan dan tabel per perusahaan dihitung dari **seluruh** data yang
  cocok dengan filter, bukan hanya 10 baris yang tampil.
- PDF memakai filter yang sama persis dan mencantumkan filter aktif.

## J. Cookie dan sesi

- Cookie sesi `HttpOnly`, `SameSite=Lax`, `Secure` otomatis bila HTTPS,
  `use_strict_mode`; ID sesi diganti saat masuk; keluar menghapus sesi dan
  token Ingat saya.
- Keluar hanya lewat **POST + CSRF** (tautan GET hanya menampilkan konfirmasi).
- Ganti/reset kata sandi atau akun dinonaktifkan → semua sesi di perangkat
  lain dan token Ingat saya dicabut (`versi_sesi`).
- Halaman setelah login dikirim `Cache-Control: no-store` (tombol Back setelah
  keluar tidak menampilkan data). Header `X-Frame-Options`,
  `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`.

## K. Alasan penolakan

- Tolak / minta perbaikan / nonaktifkan wajib beralasan minimal 10 karakter
  (dicek di browser dan server). Tersedia tombol **isi cepat** dari template
  yang bisa diubah admin di Pengaturan.
- **Perbaikan/Revisi** (masih bisa diajukan ulang) dibedakan dari **Ditolak**
  (final). Semua keputusan tersimpan di riwayat beserta alasan, waktu, dan
  admin yang memutuskan; alasan ikut dikirim di notifikasi dan email.

## L. Reset sandi oleh admin

- Dua cara: kirim **tautan reset** ke email, atau buat **sandi sementara**.
- Admin wajib memasukkan kata sandinya sendiri sebagai konfirmasi.
- Sandi sementara memaksa pengguna menggantinya saat masuk berikutnya
  (`/akun/ganti-sandi-wajib`); semua sesi lama dicabut.
- Tercatat di `log_aktivitas_admin` (siapa, kapan, ke akun siapa, dari IP mana).

## M. Persetujuan lowongan

- Alur status: `menunggu` → `aktif` / `revisi` / `ditolak`; dari `revisi`
  perusahaan memperbaiki lalu otomatis `menunggu` lagi.
- Mengubah **isi** lowongan yang sudah tayang mengembalikannya ke `menunggu`
  (disembunyikan sampai disetujui ulang).
- Lowongan yang belum disetujui menghasilkan **404** di halaman publik,
  pratinjau WhatsApp, dan untuk mahasiswa; tidak bisa dilamar dan tidak ikut
  dikirim ke jurusan.
- Keputusan admin memakai kunci baris (`FOR UPDATE`), jadi dua admin yang
  menekan tombol bersamaan tidak menghasilkan keputusan ganda.
- Menu baru **Persetujuan Lowongan** dengan angka antrean di sidebar.

## Responsif

- Tabel berubah menjadi kartu di layar ≤ 640 px; filter, paginasi, modal,
  tab, dan tombol aksi menyesuaikan lebar layar.
- Diuji di lebar 390, 768, dan 1280 px untuk 4 peran (tamu, mahasiswa,
  perusahaan, admin): **tidak ada geser horizontal dan tidak ada error JS**.

---

## Bug lama yang ikut diperbaiki

- Tautan di email dan WhatsApp sebelumnya relatif (tidak bisa diklik) →
  sekarang alamat absolut.
- Lupa sandi sebelumnya mengarah ke halaman 404.
- Notifikasi ganda saat perusahaan menolak/menerima pelamar.
- Status "Screening CV" tidak memberi notifikasi ke pelamar.
- Pilihan jenis perusahaan tidak terbaca karena beda huruf besar/kecil.
- Kolom "Pelamar" menampilkan jumlah yang diterima, bukan jumlah pelamar.
- Pencarian hanya di halaman yang tampil (sekarang di server).
- Parameter `kembali` bisa dipakai mengalihkan ke situs luar.
- Zona waktu PHP dan database tidak sama (sekarang keduanya Asia/Jakarta).
- Lowongan perusahaan yang dinonaktifkan masih tampil dan bisa dilamar.
- Info loker publik menampilkan kualifikasi contoh, bukan isian perusahaan.
- Grafik level jabatan tracer karier hanya menghitung halaman yang tampil.

---

## Bukti pengujian (dijalankan pada database baru 01–04)

| Skrip | Hasil |
|---|---|
| `php tests/scan-method.php` | Semua method yang dipanggil tersedia |
| `php tests/jelajah.php` | 613 alamat ditelusuri 4 peran, tidak ada yang bermasalah |
| `php tests/uji-rute.php` | 73 method controller, tidak ada error |
| `php tests/uji-form.php` | 81 formulir POST, semua bersih |
| `php tests/uji-berkas.php` | 157 tautan berkas, semua terbuka |
| `bash tests/uji-akses-berkas.sh` | Semua aturan akses berkas benar |
| `bash tests/uji-check.sh` | Semua nilai salah ditolak dengan pesan biasa |
| `bash tests/uji-alamat-cacat.sh` | Semua alamat cacat ditangani rapi |
| `python3 tests/uji-alur-revisi.py` | Alur A–M ujung ke ujung, 0 gagal |
| `node tests/uji-browser.js` | Draft, pratinjau, tombol kembali, alasan wajib, modal reset: semua lolos, 0 error JS |

Seluruh pengujian di atas juga dijalankan ulang di **Apache + .htaccess dalam
subfolder** (`/karirku-polinema/public`, seperti XAMPP): 619 alamat, alur A–M,
dan uji browser semuanya lolos tanpa warning PHP.

Catatan: `uji-form.php` dan `uji-alur-revisi.py` mengubah data (menonaktifkan
akun, membuat lowongan). Muat ulang database sebelum demo.

---

## Pertanyaan dosen yang mungkin muncul

**"Kalau SMTP mati, pengguna tahu?"** Ya. Status email di log `gagal`/`log`,
pesan ke admin menyebut email belum terkirim, dan bisa dikirim ulang.

**"Kalau dua admin menyetujui lowongan yang sama bersamaan?"** Baris dikunci
`FOR UPDATE`, admin kedua mendapat pesan bahwa lowongan sudah diputuskan.

**"Kalau perusahaan ubah lowongan diam-diam setelah disetujui?"** Perubahan
isi mengembalikan status ke `menunggu` dan lowongan hilang dari publik sampai
disetujui ulang; semua perubahan tercatat di riwayat.

**"Kalau akun dinonaktifkan saat sedang login di HP?"** Permintaan berikutnya
dari HP itu langsung dikeluarkan (versi sesi berubah), termasuk Ingat saya.

**"Kalau sesi habis saat mengisi formulir panjang?"** Isian kembali utuh,
ditambah draft di browser yang bisa dipulihkan.

**"Password disimpan bagaimana?"** `password_hash` (bcrypt); token reset dan
Ingat saya hanya disimpan dalam bentuk hash.

**"Kenapa tidak pakai framework?"** Sesuai ketentuan mata kuliah: PHP native
dengan pola MVC buatan sendiri (`app/core/Router.php`, `Controller.php`,
`Model.php`, `Database.php`).
