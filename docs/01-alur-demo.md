# Urutan Demo

Jelaskan berurutan dari nomor 1 sampai 7. Setiap bagian sudah punya halamannya
sendiri, jadi tidak perlu melompat-lompat.

## 1. Masalah dan solusi (1 menit)
Buka `public/index.html`.
- Hero berisi empat foto bergantian dan kalimat visi vokasi Polinema.
- Bagian Tentang, Alur Penggunaan, Keunggulan, Mitra, FAQ, dan Kontak.
- Tekankan: Beranda sengaja tidak menampilkan lowongan karena KarirKu khusus
  civitas Polinema.

## 2. Registrasi dan verifikasi (2 menit)
Klik Daftar.
- Pilih peran, lalu isi formulir tiga langkah.
- Mahasiswa mengunggah KTM atau ijazah.
- Perusahaan mengunggah NIB, NPWP, dan akta pendirian, serta mencentang
  pernyataan bukan perusahaan outsourcing.
- Tunjukkan pesan error saat dokumen belum diunggah.
- Setelah dikirim, klik Lihat status akun.

## 3. Halaman Status Akun (1 menit)
Di `status-akun.html` ada tombol Mode demo di kiri bawah untuk berpindah status:
menunggu, perlu perbaikan, ditolak, dan disetujui. Tunjukkan bahwa menu lain
terkunci selama akun belum aktif.

## 4. Peran mahasiswa dan alumni (3 menit)
Buka Masuk, klik akun demo Mahasiswa aktif.
- Pop-up selamat datang dan lencana Terverifikasi.
- Menu Lowongan: filter jurusan, bidang, lokasi, dan kondisi hasil kosong.
- Detail lowongan, lalu Lamar: pilih CV, lampirkan KTM dan surat pengantar.
  Coba kirim tanpa surat pengantar untuk menunjukkan validasinya.
- Lamaran Saya: linimasa status dan jadwal interview.
- Profil Karier: tab Dokumen, Buat CV, dan Status Karier.

## 5. Peran perusahaan (3 menit)
Keluar, lalu masuk dengan akun demo Perusahaan.
- Lowongan Saya, lalu Pasang Lowongan. Tombol Tayangkan mati sebelum pamflet
  diunggah.
- Menu Pelamar, buka Detail Pelamar: profil lengkap, CV, KTM, dan surat
  pengantar.
- Tekan Terima pelamar, lalu jelaskan pembaruan otomatis ke tiga pihak.

## 6. Peran admin Career Center (3 menit)
Masuk dengan akun demo Admin.
- Persetujuan Akun: antrean, detail dokumen, tiga keputusan.
- Monitoring Lowongan dan Rekap Lamaran.
- Kirim Loker ke Jurusan: tujuh tombol WhatsApp dan halaman pratinjau.
- Tracer Karier beserta laporan PDF.

## 7. Rancangan teknis (2 menit)
Buka folder `docs/`.
- ERD dan EERD.
- Empat flowchart alur utama.
- `database/01-schema.sql` sebagai bukti rancangan siap dieksekusi.
- Folder `app/` sebagai kerangka backend beserta pembagian tugasnya.

## Akun demo

| Tombol di halaman Masuk | Hasil |
|---|---|
| Mahasiswa aktif | Dashboard mahasiswa dan alumni |
| Perusahaan | Dashboard perusahaan |
| Admin | Dashboard admin Career Center |
| Akun menunggu | Halaman Status Akun |
| Akun dinonaktifkan | Pesan akun dinonaktifkan |
