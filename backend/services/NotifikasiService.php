<?php
// ===== BACKEND · SERVICE · Notifikasi ================================

class NotifikasiService
{
    // --- Helper ------------------------------------------------------
    private static function notif(): Notifikasi
    {
        return new Notifikasi();
    }

    // --- Akun --------------------------------------------------------
    public static function registrasiBerhasil(array $pengguna, string $noPendaftaran): void
    {
        MailService::kirimPendaftaranDiterima($pengguna['email'], $noPendaftaran);
    }

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

    /** Mengembalikan true bila email benar-benar diterima server SMTP. */
    public static function statusAkunBerubah(int $penggunaId, string $email, string $keputusan, ?string $catatan): bool
    {
        $judul = [
            'disetujui' => 'Akun Anda telah disetujui',
            'perbaikan' => 'Data pendaftaran perlu diperbaiki',
            'ditolak'   => 'Pendaftaran tidak dapat disetujui',
        ][$keputusan] ?? 'Status akun diperbarui';

        self::notif()->buat($penggunaId, 'status_akun', $judul, mb_substr($catatan ?: 'Silakan cek Halaman Status Akun.', 0, 500), 'status-akun');
        return MailService::kirimStatusAkun($email, $keputusan, $catatan);
    }

    public static function statusAktivasiBerubah(int $penggunaId, string $email, bool $nonaktif, ?string $alasan): bool
    {
        $judul = $nonaktif ? 'Akun Anda dinonaktifkan' : 'Akun Anda diaktifkan kembali';
        self::notif()->buat($penggunaId, 'status_akun', $judul, mb_substr($alasan ?: 'Silakan masuk seperti biasa.', 0, 500), $nonaktif ? null : 'beranda');
        return MailService::kirimStatusAktivasi($email, $nonaktif, $alasan);
    }

    /** Pesan tambahan yang jujur tentang email untuk ditampilkan ke Admin. */
    public static function keteranganEmail(): string
    {
        $t = MailService::$terakhir;
        if (!$t) {
            return '';
        }
        return match ($t['status']) {
            'terkirim' => ' Email pemberitahuan terkirim.',
            'gagal'    => ' Namun email pemberitahuan GAGAL dikirim (' . $t['keterangan'] . '). Kirim ulang dari Pengaturan > Email.',
            default    => ' Email belum dikirim karena SMTP belum dikonfigurasi (hanya dicatat di log). Pengguna tetap mendapat notifikasi di aplikasi.',
        };
    }

    // --- Lowongan ----------------------------------------------------
    public static function lowonganBaruSesuaiMinat(int $lowonganId, string $posisi, string $namaPerusahaan, int $bidangId): void
    {
        $peminat = Database::fetchAll(
            "SELECT m.pengguna_id FROM mahasiswa_minat mm
             JOIN mahasiswa m ON m.id = mm.mahasiswa_id
             JOIN pengguna p ON p.id = m.pengguna_id
             WHERE mm.bidang_id = ? AND p.status_akun = 'aktif'",
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

    // --- Lamaran -----------------------------------------------------
    public static function lamaranMasukUntukPerusahaan(int $perusahaanPenggunaId, string $namaMahasiswa, string $posisi, int $lowonganId): void
    {
        self::notif()->buat(
            $perusahaanPenggunaId,
            'lamaran_masuk',
            'Lamaran baru masuk',
            $namaMahasiswa . ' melamar sebagai ' . $posisi,
            'perusahaan/pelamar?lowongan_id=' . $lowonganId
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

    public static function statusLamaranBerubah(int $mahasiswaPenggunaId, string $posisi, string $status, ?string $catatan = null): void
    {
        $judul = [
            'screening' => 'CV Anda sedang ditinjau',
            'interview' => 'Jadwal interview telah ditentukan',
            'ditolak'   => 'Lamaran belum berhasil kali ini',
        ][$status] ?? 'Status lamaran diperbarui';

        self::notif()->buat(
            $mahasiswaPenggunaId, 'status_lamaran', $judul,
            mb_substr($posisi . ($catatan ? ' - ' . $catatan : ''), 0, 500),
            'lamaran/lamaran-saya'
        );
    }

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

    // --- Persetujuan lowongan (revisi M) ------------------------------
    public static function lowonganMenungguUntukAdmin(int $lowonganId, string $posisi, string $namaPerusahaan, bool $ulang): void
    {
        foreach (Database::fetchAll('SELECT pengguna_id FROM admin') as $a) {
            self::notif()->buat(
                (int) $a['pengguna_id'], 'lowongan_menunggu',
                $ulang ? 'Lowongan diajukan ulang' : 'Lowongan baru menunggu persetujuan',
                $posisi . ' - ' . $namaPerusahaan,
                'admin/detail-lowongan/' . $lowonganId
            );
        }
    }

    /** Notifikasi + email ke perusahaan. Mengembalikan true bila email terkirim. */
    public static function statusLowonganUntukPerusahaan(int $perusahaanPenggunaId, string $email, string $keputusan, string $posisi, ?string $alasan): bool
    {
        $judul = [
            'disetujui' => 'Lowongan disetujui dan tayang',
            'ditutup'   => 'Lowongan disetujui (langsung ditutup)',
            'revisi'    => 'Lowongan perlu direvisi',
            'ditolak'   => 'Lowongan ditolak',
            'nonaktif'  => 'Lowongan dinonaktifkan Admin',
        ][$keputusan] ?? 'Status lowongan diperbarui';
        $pesan = $posisi . ($alasan ? ' - ' . $alasan : '');
        if ($keputusan === 'ditutup') {
            $pesan = $posisi . ' disetujui, tetapi batas lamaran sudah lewat atau kuota penuh. Gunakan tombol Perpanjang.';
        }
        self::notif()->buat($perusahaanPenggunaId, 'status_lowongan', $judul, mb_substr($pesan, 0, 500), 'perusahaan/lowongan');
        return MailService::kirimStatusLowongan($email, $keputusan === 'ditutup' ? 'disetujui' : $keputusan, $posisi, $alasan);
    }

    public static function lowonganDiperpanjangUntukAdmin(int $lowonganId, string $posisi, string $namaPerusahaan, string $batasBaru): void
    {
        foreach (Database::fetchAll('SELECT pengguna_id FROM admin') as $a) {
            self::notif()->buat(
                (int) $a['pengguna_id'], 'lowongan_diperpanjang', 'Lowongan diperpanjang perusahaan',
                $posisi . ' - ' . $namaPerusahaan . ' sampai ' . tanggalIndo($batasBaru),
                'admin/detail-lowongan/' . $lowonganId
            );
        }
    }

    // --- Lowongan (perusahaan) ---------------------------------------
    public static function kuotaTerpenuhi(int $perusahaanPenggunaId, string $posisi): void
    {
        self::notif()->buat(
            $perusahaanPenggunaId, 'kuota_penuh', 'Kuota lowongan terpenuhi',
            $posisi . ' otomatis ditutup karena kuota sudah penuh.'
        );
    }

    public static function lowonganDinonaktifkanAdmin(int $perusahaanPenggunaId, string $posisi, string $alasan, ?string $email = null): bool
    {
        if ($email !== null) {
            return self::statusLowonganUntukPerusahaan($perusahaanPenggunaId, $email, 'nonaktif', $posisi, $alasan);
        }
        self::notif()->buat(
            $perusahaanPenggunaId, 'lowongan_nonaktif', 'Lowongan dinonaktifkan Admin',
            mb_substr($posisi . ' - alasan: ' . $alasan, 0, 500), 'perusahaan/lowongan'
        );
        return false;
    }

    // --- Tracer karier -----------------------------------------------
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
