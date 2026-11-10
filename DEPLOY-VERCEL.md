# Deploy KarirKu Polinema ke Vercel

Proyek ini sudah siap di-deploy ke Vercel. Berkas yang dipakai:

| Berkas | Fungsi |
|---|---|
| `vercel.json` | Runtime PHP 8.3 (`vercel-php`), semua alamat diarahkan ke `api/index.php`, region Singapura |
| `api/index.php` | Pintu masuk: kirim aset dari `public/`, jalankan aplikasi. Isi `app/`, `database/`, `storage/` tidak pernah bisa diunduh |
| `api/php.ini` | Batas unggah, memori, zona waktu |
| `.vercelignore` | Berkas yang tidak ikut di-deploy (termasuk `database.lokal.php` yang berisi kata sandi) |

Di Vercel tidak ada folder yang bisa ditulis secara permanen, jadi aplikasi otomatis
masuk **mode serverless** (terdeteksi dari variabel `VERCEL`):

- **Sesi login** disimpan di tabel `sesi` (PostgreSQL), bukan berkas.
- **Berkas unggahan** (foto, CV, KTM, pamflet, logo, dokumen) disimpan di tabel
  `berkas_tersimpan`. Kedua tabel dibuat otomatis.
- Di XAMPP/hosting biasa semuanya tetap seperti dulu (berkas di `storage/uploads`).

---

## Langkah 1 · Siapkan database PostgreSQL (gratis)

Vercel tidak punya PostgreSQL bawaan, pakai **Neon** (gratis, cocok dengan Vercel).

**Cara termudah (lewat Vercel):** setelah proyek dibuat di Langkah 2, buka
**Storage → Create Database → Neon**, pilih region **Singapore**, lalu **Connect**.
Vercel otomatis mengisi `DATABASE_URL` dan `DATABASE_URL_UNPOOLED`. Selesai.

**Cara manual:** buat proyek di <https://neon.tech> (region *AWS Asia Pacific – Singapore*),
salin *connection string* versi **Direct connection** (bukan *Pooled*), bentuknya:

```
postgresql://USER:PASSWORD@ep-xxxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
```

Tidak perlu menjalankan SQL apa pun: saat halaman pertama dibuka, aplikasi memasang
skema dan data awal sendiri (10–30 detik untuk pertama kali).

## Langkah 2 · Deploy

**Lewat GitHub (disarankan)**
1. Unggah folder proyek ini ke repositori GitHub.
2. Di <https://vercel.com/new>, impor repositori tersebut.
3. *Framework Preset*: **Other**. *Build Command* dan *Output Directory*: biarkan kosong.
4. Buka **Environment Variables**, isi tabel di bawah, lalu **Deploy**.

**Lewat Vercel CLI**
```bash
npm i -g vercel
cd Karirku-Polinema
vercel                     # jawab pertanyaan, pilih "Other"
vercel env add DATABASE_URL
vercel --prod
```

## Environment Variables

| Nama | Wajib | Isi |
|---|---|---|
| `DATABASE_URL` | Ya (otomatis bila pakai integrasi Neon) | Connection string PostgreSQL di atas |
| `APP_URL` | Disarankan | Alamat situs, mis. `https://karirku-polinema.vercel.app` (untuk tautan di email & WhatsApp) |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_DARI` | Opsional | Agar email benar-benar terkirim (Gmail: `smtp.gmail.com`, `587`, App Password) |
| `APP_DEBUG` | Jangan diisi | Hanya untuk lokal |

## Langkah 3 · Setelah online

1. Buka alamat Vercel-nya. Pembukaan pertama memasang database (tunggu sebentar).
2. **Ganti kata sandi akun demo** (`admin@polinema.ac.id / admin123`, dst.) lewat
   Pengaturan, karena data demo ikut terpasang dan kata sandinya tertulis di dokumentasi.
3. Di HP, buka situsnya lalu pilih **Tambahkan ke layar utama**: KarirKu terpasang
   seperti aplikasi (ikon sendiri, layar penuh tanpa bilah alamat).

## Batasan yang perlu diketahui

- Ukuran berkas maksimal **2 MB** (aturan aplikasi). Vercel sendiri membatasi satu
  permintaan 4,5 MB.
- Paket gratis Neon: 0,5 GB. Berkas unggahan ikut memakai kuota ini.
- Permintaan pertama setelah lama tidak dipakai bisa 1–3 detik lebih lambat (*cold start*).
- Halaman `cek-sistem.php` dan `cek-berkas.php` sengaja mati di produksi (404).

## Gambar & berkas data demo

Folder `storage/uploads/` sengaja diabaikan Git (`.gitignore`), jadi isinya tidak ikut ke GitHub/Vercel.
Karena itu semua berkas data demo (logo, pamflet, foto, CV, KTM, dokumen perusahaan) disalin ke
**`storage/demo-uploads/`** — folder ini *ikut* ke GitHub dan di-deploy. Aplikasi otomatis mencari berkas
di sana bila tidak ditemukan di folder unggahan. Pastikan folder ini ikut ter-commit/ter-upload.
