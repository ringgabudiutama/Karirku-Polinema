# Panduan Integrasi View (kontrak Backend <-> Frontend)

PIC backend: M. Ubaidillah, dibantu isi controller oleh seluruh anggota
sesuai `docs/02-pembagian-tugas.md`.
PIC frontend/integrasi: Ringga Budi Utama & Aqillah (lihat `CATATAN.md` di
tiap folder `app/views/*`).

**Status: seluruh `app/views/*.php` SUDAH diisi** (38 file, tampilan
dipindahkan dari `public/*.html` dan disambungkan ke data controller
sungguhan). Dokumen ini sekarang berfungsi sebagai REFERENSI kontrak
(halaman mana dapat variabel apa), bukan lagi daftar tugas kosong.
Silakan sesuaikan detail visualnya (warna, susunan, komponen) sesuka hati --
yang penting nama variabel dan action form di bawah ini tetap dipakai,
supaya tidak putus dari backend.

Dokumen ini adalah **daftar kontrak** antara controller (backend, sudah
selesai) dan view (frontend, sudah diisi versi pertama): setiap method
controller memanggil `$this->view('nama/file', [...])`, artinya file
`app/views/nama/file.php` HARUS ada dan boleh memakai variabel yang
disebutkan tanpa perlu query database lagi -- controller sudah menyiapkan
semuanya.

Cara lanjut menyempurnakan tampilan:
1. Buka file view yang mau dipercantik, bandingkan dengan desain aslinya di
   `public/*.html` (masih disimpan sebagai acuan, tidak dipakai lagi oleh
   aplikasi).
2. Ubah markup/CSS sesuka hati -- variabel PHP dan `<form action="...">`
   yang sudah terpasang JANGAN diganti nama/tujuannya, karena itu yang
   menyambungkan ke backend.
3. Style asli (`public/assets/css/style.css`, `public/assets/js/app.js`)
   sudah dipakai apa adanya di semua view -- app.js sudah disederhanakan
   (hash-router & data dummy prototipe dibuang, karena sekarang setiap
   halaman adalah route PHP sungguhan), tapi ikon, modal, tab, dan navbar
   publik tetap jalan seperti prototipe.

---

## Cara kerja Router (ringkas)

URL berpola `controller/method/param1/param2`, ditulis kebab-case:

```
lamaran/detail-pelamar/12   ->  LamaranController::detailPelamar(12)
mahasiswa/dashboard         ->  MahasiswaController::dashboard()
```

Beberapa alias pendek (lihat `app/core/Router.php`):

| URL           | Menuju                          |
|---------------|----------------------------------|
| `/` (kosong)  | `app/views/publik/beranda.php` (langsung, tanpa controller) |
| `daftar`      | `AuthController::formDaftar()`   |
| `masuk`       | `AuthController::formMasuk()`    |
| `keluar`      | `AuthController::keluar()`       |
| `status-akun` | `AuthController::statusAkun()`   |
| `info-loker/{kode}` | `LowonganController::pratinjau($kode)` |

Semua tautan dan `action` form di view **wajib** dibungkus `url()`, contoh:
`<a href="<?= url('lowongan/detail/'.$l['id']) ?>">`.

---

## AuthController (publik, tanpa login / sebelum aktif)

| Method | Route | HTTP | View | Variabel tersedia |
|---|---|---|---|---|
| `formMasuk` | `masuk` | GET | `publik/masuk` | `$emailSebelumnya` |
| `prosesMasuk` | `auth/proses-masuk` | POST | - (redirect) | field form: `email`, `password` |
| `formDaftar` | `daftar` atau `daftar?peran=mahasiswa\|perusahaan` | GET | `publik/daftar` | `$jurusan`, `$prodi`, `$peranTerpilih` |
| `prosesDaftar` | `auth/proses-daftar` | POST | - (redirect) | lihat daftar field di bawah |
| `statusAkun` | `status-akun` | GET | `publik/status-akun` | `$pengguna`, `$riwayat`, `$dokumen` |
| `kirimPerbaikan` | `auth/kirim-perbaikan` | POST | - (redirect) | file upload: `file_ktm`/`file_ijazah`/`file_nib`/dst (nama field fleksibel) |
| `lupaSandi` | `auth/lupa-sandi` | GET | `publik/lupa-sandi` | `$tersedia` (bool) |
| `prosesLupaSandi` | `auth/proses-lupa-sandi` | POST | - (redirect) | field: `email` |
| `resetSandi` | `auth/reset-sandi/{token}` | GET | `publik/reset-sandi` | `$token` |
| `prosesResetSandi` | `auth/proses-reset-sandi/{token}` | POST | - (redirect) | field: `password`, `konfirmasi_password` |
| `keluar` | `keluar` | GET | - (redirect) | - |

### Field form pendaftaran mahasiswa (`prosesDaftar`, `peran=mahasiswa`)
`email`, `password`, `konfirmasi_password`, `nama`, `nim`, `no_whatsapp`,
`program_studi_id`, `status_mahasiswa` (`aktif`/`alumni`), `angkatan`,
`tahun_lulus` (wajib kalau alumni), file `file_dokumen` (KTM kalau aktif,
ijazah kalau alumni), checkbox `setuju_syarat`.

### Field form pendaftaran perusahaan (`prosesDaftar`, `peran=perusahaan`)
`email`, `password`, `konfirmasi_password`, `nama_perusahaan`,
`bidang_usaha`, `jenis_perusahaan`, `alamat`, `kota`, `website`, `nama_pic`,
`jabatan_pic`, `whatsapp_pic`, file `file_nib`, `file_npwp`, `file_akta`
(wajib), `file_domisili`, `file_logo` (opsional), checkbox
`bukan_outsourcing` dan `setuju_syarat`.

---

## MahasiswaController (butuh login + akun aktif + role mahasiswa)

| Method | Route | HTTP | View | Variabel tersedia |
|---|---|---|---|---|
| `dashboard` | `mahasiswa/dashboard` | GET | `mahasiswa/dashboard` | `$mahasiswa`, `$kelengkapan`, `$lamaranAktif`, `$jumlahDisimpan`, `$rekomendasi`, `$lamaranTerbaru`, `$perluUpdateKarier` |
| `disimpan` | `mahasiswa/disimpan` | GET | `mahasiswa/disimpan` | `$lowongan` (lowongan disimpan, urut deadline terdekat) |
| `profil` | `mahasiswa/profil` | GET | `mahasiswa/profil` | `$mahasiswa`, `$pendidikan`, `$pengalaman`, `$sertifikat`, `$portofolio`, `$skillTerpilih`, `$semuaSkill`, `$minatTerpilih`, `$semuaBidang` |
| `simpanProfil` | `mahasiswa/simpan-profil` | POST | - (redirect) | field wajib `aksi` = `data_diri`\|`foto`\|`dokumen`\|`item_tambah`\|`item_hapus`\|`skill`\|`minat` (lihat detail tiap aksi di `MahasiswaController.php`) |
| `generateCv` | `mahasiswa/generate-cv` | GET | - (langsung keluar PDF/HTML) | - |
| `unggahCv` | `mahasiswa/unggah-cv` | POST | - (redirect) | file `file_cv` |
| `statusKarier` | `mahasiswa/status-karier` | POST | - (redirect) | `status_karier`, `tempat_kerja`, `posisi_kerja`, `level_jabatan`, `tanggal_mulai_kerja` |
| `pengaturanAkun` | `mahasiswa/pengaturan-akun` | GET | `mahasiswa/pengaturan` | `$pengguna` |
| `simpanPengaturanAkun` | `mahasiswa/simpan-pengaturan-akun` | POST | - (redirect) | `aksi` = `email`\|`password`\|`whatsapp` |
| `statusKarier` | `mahasiswa/status-karier` | POST | - (redirect) | `status_karier`, `tempat_kerja`, `posisi_kerja`, `level_jabatan`, `tanggal_mulai_kerja` (duplikat method ada juga sebagai form terpisah di halaman Profil Karier tab Status Karier) |

Form di `mahasiswa/profil.php` sebaiknya beberapa `<form>` terpisah (satu per
aksi), semua nge-`POST` ke `mahasiswa/simpan-profil` dengan `<input
type="hidden" name="aksi" value="...">` sesuai aksinya.

---

## LowonganController (mahasiswa mencari, perusahaan mengelola)

| Method | Route | HTTP | Peran | View | Variabel |
|---|---|---|---|---|---|
| `daftar` | `lowongan/daftar` | GET | mahasiswa | `mahasiswa/lowongan` | `$lowongan`, `$total`, `$halaman`, `$totalHalaman`, `$filter`, `$jurusan`, `$bidang` |
| `detail` | `lowongan/detail/{id}` | GET | mahasiswa | `mahasiswa/lowongan-detail` | `$lowongan`, `$jurusanSasaran`, `$sudahDisimpan`, `$sudahMelamar`, `$profilLengkap` |
| `simpan` | `lowongan/simpan/{id}` | POST | mahasiswa | - (redirect) | field opsional `kembali` (url tujuan setelah toggle simpan) |
| `formPasang` | `lowongan/form-pasang` (baru) atau `lowongan/form-pasang/{id}` (edit) | GET | perusahaan | `perusahaan/lowongan-form` | `$lowongan` (null kalau baru), `$jurusanTerpilih`, `$bidang`, `$jurusan` |
| `prosesPasang` | `lowongan/proses-pasang` | POST | perusahaan | - (redirect) | `id` (kosongkan kalau baru), `bidang_id`, `posisi`, `jenis_pekerjaan`, `sistem_kerja`, `lokasi`, `gaji`, `kuota`, `batas_lamaran`, `deskripsi`, `kualifikasi`, `skill_dibutuhkan`, file `pamflet` (wajib untuk baru), array checkbox `jurusan_id[]` |
| `tutup` | `lowongan/tutup/{id}` | POST | perusahaan | - (redirect) | - |
| `pratinjau` | `info-loker/{kode}` | GET | publik (tanpa login) | `publik/info-loker` | `$lowongan`, `$kedaluwarsa` |

Catatan untuk `daftar()`: query string yang didukung: `q` (kata kunci),
`jurusan_id`, `bidang_id`, `lokasi`, `jenis_pekerjaan`, `urutan`
(`batas_lamaran` untuk urut deadline terdekat), `halaman`.

Catatan untuk `publik/info-loker.php`: **wajib** ada meta Open Graph
(`og:image` mengarah ke pamflet lewat `public/unduh.php`, lihat bagian
Unduhan File di bawah) supaya pratinjau tautan WhatsApp menampilkan gambar
pamflet, plus `<meta name="robots" content="noindex">` supaya tidak
diindeks mesin pencari.

---

## LamaranController

| Method | Route | HTTP | Peran | View | Variabel |
|---|---|---|---|---|---|
| `kirim` | `lamaran/kirim/{lowonganId}` | GET tampilkan form, POST proses | mahasiswa | `mahasiswa/lamaran-form` | GET: `$lowongan`, `$mahasiswa`. POST field: `jenis_cv` (`generate`\|`unggah`), `catatan_pelamar`, file `file_surat_pengantar` |
| `lamaranSaya` | `lamaran/lamaran-saya` | GET | mahasiswa | `mahasiswa/lamaran` | `$lamaran` |
| `batalkan` | `lamaran/batalkan/{id}` | POST | mahasiswa | - (redirect) | - |
| `detailPelamar` | `lamaran/detail-pelamar/{id}` | GET | perusahaan | `perusahaan/pelamar-detail` | `$lamaran`, `$mahasiswa`, `$profilItem`, `$skill`, `$riwayat`, `$interview` |
| `ubahStatus` | `lamaran/ubah-status/{id}` | POST | perusahaan | - (redirect) | `aksi` = `jadwal_interview` (field `tanggal`,`jam`,`mode`,`lokasi_tautan`,`catatan`) atau `tolak` (field `catatan_perusahaan`, wajib diisi) |
| `terima` | `lamaran/terima/{id}` | POST | perusahaan | - (redirect) | - |

---

## PerusahaanController

| Method | Route | HTTP | View | Variabel |
|---|---|---|---|---|
| `dashboard` | `perusahaan/dashboard` | GET | `perusahaan/dashboard` | `$perusahaan`, `$lowonganAktif`, `$pelamarBaru`, `$interviewTerjadwal`, `$pelamarDiterima`, `$lowonganSaya`, `$pelamarTerbaru` |
| `lowongan` | `perusahaan/lowongan` | GET | `perusahaan/lowongan` | `$lowongan` |
| `pelamar` | `perusahaan/pelamar` | GET | `perusahaan/pelamar` | `$pelamar`, `$lowonganSaya`, `$jurusan`, `$filter` (query: `lowongan_id`, `status`, `jurusan_id`) |
| `profil` | `perusahaan/profil` | GET | `perusahaan/profil` | `$perusahaan` |
| `simpanProfil` | `perusahaan/simpan-profil` | POST | - (redirect) | `nama_perusahaan`, `bidang_usaha`, `jenis_perusahaan`, `alamat`, `kota`, `website`, `nama_pic`, `jabatan_pic`, `whatsapp_pic`, `deskripsi`, file opsional `logo` |
| `pengaturanAkun` | `perusahaan/pengaturan-akun` | GET | `perusahaan/pengaturan` | `$pengguna` |
| `simpanPengaturanAkun` | `perusahaan/simpan-pengaturan-akun` | POST | - (redirect) | `aksi` = `email`\|`password` |

Catatan: `pengaturanAkun`/`simpanPengaturanAkun` sengaja digandakan persis di `MahasiswaController` (route `mahasiswa/...`) dan `PerusahaanController` (route `perusahaan/...`) -- bukan duplikasi tidak sengaja, supaya masing-masing tetap mengikuti pola routing controller/method biasa tanpa pengecualian di Router.

---

## NotifikasiController (mahasiswa & perusahaan)

| Method | Route | HTTP | View | Variabel |
|---|---|---|---|---|
| `semua` | `notifikasi/semua` | GET | `mahasiswa/notifikasi` atau `perusahaan/notifikasi` (otomatis sesuai peran) | `$notifikasi` |
| `tandaiDibaca` | `notifikasi/tandai-dibaca/{id}` | GET | - (redirect ke tautan notifikasi) | - |
| `tandaiSemuaDibaca` | `notifikasi/tandai-semua-dibaca` | GET | - (redirect) | - |

Ikon lonceng di topbar (dipakai di `layouts/`) cukup panggil langsung fungsi
global (tidak perlu lewat controller): `jumlahNotifBelumDibaca($penggunaId)`
dan `notifTerbaru($penggunaId)`, keduanya sudah didefinisikan di
`app/core/bootstrap.php`.

---

## AdminController

| Method | Route | HTTP | View | Variabel |
|---|---|---|---|---|
| `dashboard` | `admin/dashboard` | GET | `admin/dashboard` | `$statistik` (array angka), `$antreanVerifikasi` (5 terlama), `$notifikasi` |
| `persetujuan` | `admin/persetujuan` | GET | `admin/persetujuan-akun` | `$antrean`, `$jurusan`, `$filter` |
| `detailPendaftar` | `admin/detail-pendaftar/{penggunaId}` | GET | `admin/persetujuan-detail` | `$pengguna`, `$profil`, `$dokumen`, `$riwayat` |
| `putuskan` | `admin/putuskan/{penggunaId}` | POST | - (redirect) | `keputusan` = `disetujui`\|`perbaikan`\|`ditolak`, `catatan` (wajib kecuali disetujui) |
| `kelolaPengguna` | `admin/kelola-pengguna` | GET | `admin/kelola-pengguna` | `$mahasiswa`, `$perusahaan`, `$jurusan`, `$filter` |
| `nonaktifkanPengguna` | `admin/nonaktifkan-pengguna/{penggunaId}` | POST | - (redirect) | `alasan` (wajib) |
| `aktifkanPengguna` | `admin/aktifkan-pengguna/{penggunaId}` | POST | - (redirect) | - |
| `monitoringLowongan` | `admin/monitoring-lowongan` | GET | `admin/monitoring-lowongan` | `$lowongan`, `$bidang`, `$jurusan`, `$filter` |
| `nonaktifkanLowongan` | `admin/nonaktifkan-lowongan/{id}` | POST | - (redirect) | `alasan` (wajib) |
| `unduhRekapLowongan` | `admin/unduh-rekap-lowongan` | GET | - (langsung keluar PDF) | query filter sama seperti monitoringLowongan |
| `rekapLamaran` | `admin/rekap-lamaran` | GET | `admin/rekap-lamaran` | `$lamaran`, `$perusahaan`, `$jurusan`, `$filter` |
| `unduhRekapLamaran` | `admin/unduh-rekap-lamaran` | GET | - (langsung keluar PDF) | query filter sama seperti rekapLamaran |
| `tracerKarier` | `admin/tracer-karier` | GET | `admin/tracer-karier` | `$alumni`, `$ringkasanStatus`, `$jurusan`, `$filter` |
| `unduhTracerKarier` | `admin/unduh-tracer-karier` | GET | - (langsung keluar PDF) | query filter sama seperti tracerKarier |
| `pengaturan` | `admin/pengaturan` | GET | `admin/pengaturan` | `$pengaturan` (peta kunci=>nilai), `$kontakJurusan`, `$pengguna` |
| `simpanPengaturan` | `admin/simpan-pengaturan` | POST | - (redirect) | field bernama sama seperti kunci `pengaturan` (`template_wa_loker`, dst) |
| `gantiPassword` | `admin/ganti-password` | POST | - (redirect) | `password_lama`, `password_baru`, `konfirmasi_password` |

---

## KirimLokerController (khusus admin)

| Method | Route | HTTP | View | Variabel |
|---|---|---|---|---|
| `index` | `kirim-loker` atau `kirim-loker?lowongan_id={id}` | GET | `admin/kirim-loker` | `$lowongan`, `$lowonganDipilih`, `$jurusan`, `$kontak` (peta jurusan_id => baris kontak), `$sudahDikirim` (array jurusan_id), `$tautanPratinjau`, `$templatePesan` |
| `kirim` | `kirim-loker/kirim/{lowonganId}/{jurusanId}` | GET (lihat alasan di komentar controller) | - (redirect ke wa.me) | dipakai sebagai `<a href target="_blank">`, BUKAN form |
| `simpanKontak` | `kirim-loker/simpan-kontak` | POST | - (redirect ke `admin/pengaturan`) | `jurusan_id`, `nama_kontak`, `nomor_wa` |

Untuk membuat pesan per baris jurusan di view `admin/kirim-loker.php`,
panggil langsung:
```php
<?php $pesan = WhatsappService::susunPesan($templatePesan, $lowonganDipilih, $j['nama'], $tautanPratinjau); ?>
```

---

## Unduhan file (dokumen, foto, logo, pamflet, CV)

Semua file unggahan disimpan DI LUAR `public/` (di `storage/uploads/...`),
jadi TIDAK bisa diakses langsung lewat `<img src="storage/uploads/...">`.
PIC frontend perlu satu file baru **`public/unduh.php`** (belum dibuat,
silakan buat bersama backend) yang membaca query `?tipe=foto&file=namafile`
lalu memanggil `UploadService::pathLengkap($tipe, $file)` dan mengirim
isinya lewat `readfile()` setelah memastikan file itu memang berkaitan
dengan sesi yang sedang login (atau publik untuk `pamflet`, karena pamflet
memang harus tampil di halaman pratinjau info loker tanpa login).

Contoh pemakaian di view: `<img src="<?= url('unduh.php?tipe=foto&file='.$mahasiswa['foto']) ?>">`.

---

## Style & komponen

CSS asli dari prototipe (`public/assets/css/style.css`,
`public/assets/js/app.js`, folder `public/assets/img/`) **sudah lengkap dan
responsif** -- tinggal dipakai apa adanya, tidak perlu dibuat ulang. Badge
status pakai fungsi `badgeHtml(labelStatusLamaran($lamaran['status']))` dkk
dari `app/helpers/format.php` supaya warna & labelnya konsisten di semua
halaman.
