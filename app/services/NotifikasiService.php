<?php
/**
 * Pembuat notifikasi
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * Satu titik pemanggilan untuk seluruh peristiwa pada matriks notifikasi
 * proposal (14 peristiwa). Controller cukup memanggil method di sini,
 * tidak perlu tahu detail tabel notifikasi maupun kapan harus kirim email.
 * Nomor di komentar tiap method cocok dengan nomor baris matriks di proposal.
 */

class NotifikasiService
{
    private static function notif(): Notifikasi
    {
        return new Notifikasi();
    }

    /** 1. Registrasi berhasil -> halaman sukses (ditangani view) + email. */
    public static function registrasiBerhasil(array $pengguna, string $noPendaftaran): void
    {
        MailService::kirimPendaftaranDiterima($pengguna['email'], $noPendaftaran);
    }

    /** 2. Pendaftar baru atau data perbaikan dikirim ulang -> Admin (website). */
    public static function pendaftarBaruUntukAdmin(string $namaPendaftar, string $role): void
    {
        $admin = Database::fetchAll("SELECT pengguna_id FROM admin");
        foreach ($admin as $a) {
            self::notif()->buat(
                (int) $a['pengguna_id'],
                'pendaftar_baru',
                'Pendaftar baru menunggu verifikasi',
                ucfirst($role) . ' baru mendaftar: ' . $namaPendaftar,
                'admin/persetujuan'
            );
        }
    }

    /** 3 & 4. Akun disetujui / perlu perbaikan / ditolak -> pendaftar (website + email). */
    public static function statusAkunBerubah(int $penggunaId, string $email, string $keputusan, ?string $catatan): void
    {
        $judul = [
            'disetujui' => 'Akun Anda telah disetujui',
            'perbaikan' => 'Data pendaftaran perlu diperbaiki',
            'ditolak'   => 'Pendaftaran tidak dapat disetujui',
        ][$keputusan] ?? 'Status akun diperbarui';

        self::notif()->buat($penggunaId, 'status_akun', $judul, $catatan ?: 'Silakan cek Halaman Status Akun.', 'status-akun');
        MailService::kirimStatusAkun($email, $keputusan, $catatan);
    }

    /** 5. Akun dinonaktifkan / diaktifkan kembali -> pengguna (website + email). */
    public static function statusAktivasiBerubah(int $penggunaId, string $email, bool $nonaktif, ?string $alasan): void
    {
        $judul = $nonaktif ? 'Akun Anda dinonaktifkan' : 'Akun Anda diaktifkan kembali';
        self::notif()->buat($penggunaId, 'status_akun', $judul, $alasan ?: '-', 'masuk');
        MailService::kirimStatusAktivasi($email, $nonaktif, $alasan);
    }

    /** 7. Lowongan baru sesuai bidang minat -> mahasiswa/alumni yang berminat (website). */
    public static function lowonganBaruSesuaiMinat(int $lowonganId, string $posisi, string $namaPerusahaan, int $bidangId): void
    {
        $peminat = Database::fetchAll(
            'SELECT m.pengguna_id FROM mahasiswa_minat mm
             JOIN mahasiswa m ON m.id = mm.mahasiswa_id
             WHERE mm.bidang_id = ?',
            [$bidangId]
        );
        foreach ($peminat as $p) {
            self::notif()->buat(
                (int) $p['pengguna_id'],
                'lowongan_baru',
                'Lowongan baru sesuai minat Anda',
                $posisi . ' di ' . $namaPerusahaan,
                'lowongan/detail/' . $lowonganId
            );
        }
    }

    /** 8. Lowongan yang disimpan tersisa 3 hari -> mahasiswa/alumni (website).
     *  Dipanggil saat pengguna login (tanpa cron job), lihat AuthController::prosesMasuk(). */
    public static function ingatkanLowonganDisimpanHampirTutup(int $penggunaId, int $mahasiswaId): void
    {
        $akanTutup = Database::fetchAll(
            "SELECT l.id, l.posisi, l.batas_lamaran
             FROM lowongan_disimpan ld
             JOIN lowongan l ON l.id = ld.lowongan_id
             WHERE ld.mahasiswa_id = ? AND l.status = 'aktif'
               AND l.batas_lamaran = CURRENT_DATE + INTERVAL '3 days'",
            [$mahasiswaId]
        );
        foreach ($akanTutup as $l) {
            self::notif()->buat(
                $penggunaId,
                'lowongan_tersisa',
                'Lowongan tersimpan tersisa 3 hari lagi',
                $l['posisi'] . ' - batas lamar ' . tanggalIndo($l['batas_lamaran']),
                'lowongan/detail/' . $l['id']
            );
        }
    }

    /** 9. Lamaran baru masuk / dibatalkan -> perusahaan (website). */
    public static function lamaranMasukUntukPerusahaan(int $perusahaanPenggunaId, string $namaMahasiswa, string $posisi, int $lowonganId): void
    {
        self::notif()->buat(
            $perusahaanPenggunaId,
            'lamaran_masuk',
            'Lamaran baru masuk',
            $namaMahasiswa . ' melamar sebagai ' . $posisi,
            'lowongan/pelamar/' . $lowonganId
        );
    }

    public static function lamaranDibatalkanUntukPerusahaan(int $perusahaanPenggunaId, string $namaMahasiswa, string $posisi): void
    {
        self::notif()->buat(
            $perusahaanPenggunaId,
            'lamaran_dibatalkan',
            'Lamaran dibatalkan pelamar',
            $namaMahasiswa . ' membatalkan lamaran untuk ' . $posisi
        );
    }

    /** 10. Status lamaran berubah (screening/interview/ditolak) -> mahasiswa (website). */
    public static function statusLamaranBerubah(int $mahasiswaPenggunaId, string $posisi, string $status, ?string $catatan = null): void
    {
        $judul = [
            'screening' => 'CV Anda sedang ditinjau',
            'interview' => 'Jadwal interview telah ditentukan',
            'ditolak'   => 'Lamaran belum berhasil kali ini',
        ][$status] ?? 'Status lamaran diperbarui';

        self::notif()->buat(
            $mahasiswaPenggunaId, 'status_lamaran', $judul,
            $posisi . ($catatan ? ' - ' . $catatan : ''),
            'lamaran/lamaran-saya'
        );
    }

    /** 11. Pelamar diterima -> pelamar, perusahaan, dan admin (website). */
    public static function pelamarDiterima(int $mahasiswaPenggunaId, int $perusahaanPenggunaId, string $posisi, string $namaPerusahaan, string $namaMahasiswa): void
    {
        self::notif()->buat(
            $mahasiswaPenggunaId, 'lamaran_diterima', 'Selamat! Lamaran Anda diterima',
            'Anda diterima sebagai ' . $posisi . ' di ' . $namaPerusahaan, 'lamaran/lamaran-saya'
        );
        self::notif()->buat(
            $perusahaanPenggunaId, 'lamaran_diterima', 'Pelamar telah diterima',
            $namaMahasiswa . ' diterima sebagai ' . $posisi
        );
        foreach (Database::fetchAll('SELECT pengguna_id FROM admin') as $a) {
            self::notif()->buat(
                (int) $a['pengguna_id'], 'lamaran_diterima', 'Pelamar baru diterima bekerja',
                $namaMahasiswa . ' diterima sebagai ' . $posisi . ' di ' . $namaPerusahaan,
                'admin/tracer-karier'
            );
        }
    }

    /** 12. Kuota terpenuhi, lowongan ditutup otomatis -> perusahaan (website). */
    public static function kuotaTerpenuhi(int $perusahaanPenggunaId, string $posisi): void
    {
        self::notif()->buat(
            $perusahaanPenggunaId, 'kuota_penuh', 'Kuota lowongan terpenuhi',
            $posisi . ' otomatis ditutup karena kuota sudah penuh.'
        );
    }

    /** 13. Lowongan dinonaktifkan Admin -> perusahaan (website). */
    public static function lowonganDinonaktifkanAdmin(int $perusahaanPenggunaId, string $posisi, string $alasan): void
    {
        self::notif()->buat(
            $perusahaanPenggunaId, 'lowongan_nonaktif', 'Lowongan dinonaktifkan Admin',
            $posisi . ' - alasan: ' . $alasan
        );
    }

    /** 14. Status karier alumni belum diperbarui > 6 bulan -> banner di dashboard alumni.
     *  Tidak disimpan sebagai baris notifikasi (supaya tidak numpuk tiap login), cukup
     *  dihitung langsung saat dashboard dibuka. Lihat MahasiswaController::dashboard(). */
    public static function perluPembaruanKarier(array $mahasiswa): bool
    {
        if ($mahasiswa['status_mahasiswa'] !== 'alumni') {
            return false;
        }
        if (empty($mahasiswa['karier_diperbarui_pada'])) {
            return true;
        }
        $bulan = (strtotime('now') - strtotime($mahasiswa['karier_diperbarui_pada'])) / (30 * 24 * 3600);
        return $bulan > 6;
    }
}
