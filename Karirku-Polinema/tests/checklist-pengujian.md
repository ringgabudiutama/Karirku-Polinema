# Checklist Pengujian

Tandai setiap baris setelah diuji. Kolom terakhir diisi nama penguji.

## Registrasi dan verifikasi
- [ ] Daftar mahasiswa dengan data benar berhasil
- [ ] Email dan NIM ganda ditolak
- [ ] File lebih dari 2 MB ditolak
- [ ] Daftar perusahaan tanpa NPWP ditolak
- [ ] Pernyataan bukan outsourcing wajib dicentang
- [ ] Admin menyetujui akun, pendaftar menerima email dan notifikasi
- [ ] Admin meminta perbaikan, pendaftar dapat mengirim ulang
- [ ] Admin menolak, alasan tampil di Halaman Status Akun

## Login dan hak akses
- [ ] Login benar masuk ke dashboard sesuai peran
- [ ] Login salah menampilkan pesan umum
- [ ] Gagal 5 kali mengunci login 15 menit
- [ ] Akun menunggu hanya bisa membuka Halaman Status Akun
- [ ] Akun dinonaktifkan tidak bisa masuk
- [ ] Membuka URL peran lain menampilkan halaman 403

## Lowongan
- [ ] Pasang lowongan tanpa pamflet ditolak
- [ ] Lowongan tayang dan terlihat oleh mahasiswa
- [ ] Filter jurusan, bidang, dan lokasi bekerja
- [ ] Lowongan lewat batas lamaran berstatus ditutup
- [ ] Kuota penuh menutup lowongan otomatis
- [ ] Halaman pratinjau kedaluwarsa setelah batas lamaran

## Lamaran
- [ ] Profil belum lengkap tidak bisa melamar
- [ ] Melamar tanpa surat pengantar ditolak
- [ ] Satu lowongan hanya bisa dilamar sekali
- [ ] Membuka detail pelamar mengubah status menjadi Screening CV
- [ ] Interview wajib mengisi tanggal, jam, mode, dan lokasi
- [ ] Menerima pelamar memperbarui status karier, kuota, rekap, dan tracer
- [ ] Membatalkan lamaran hanya bisa saat status diajukan

## Laporan
- [ ] Rekap Lowongan per Perusahaan terunduh sesuai filter
- [ ] Rekap Lamaran terunduh sesuai filter
- [ ] Laporan Tracer Karier terunduh sesuai filter
