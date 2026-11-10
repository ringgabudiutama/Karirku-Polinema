<?php
// ===== BACKEND · SERVICE · Email (revisi B) ===========================
// Semua email keluar lewat satu pintu kirim():
//   1. dikirim lewat PHPMailer (bila Composer terpasang) atau SmtpSederhana;
//   2. hasilnya SELALU dicatat di tabel log_email: terkirim / gagal / log;
//   3. fungsi mengembalikan true HANYA bila server SMTP menerima email,
//      sehingga aplikasi tidak pernah mengaku "email terkirim" padahal gagal.
// Isi email rahasia (tautan reset sandi) tidak disimpan di log.

class MailService
{
    // --- Konfigurasi -------------------------------------------------
    public const SUBJEK_DEFAULT = [
        'disetujui' => '[KarirKu] Akun Anda telah disetujui',
        'perbaikan' => '[KarirKu] Data pendaftaran Anda perlu diperbaiki',
        'ditolak'   => '[KarirKu] Pendaftaran Anda tidak dapat kami setujui',
    ];

    /** Hasil pengiriman terakhir, dipakai controller untuk pesan yang jujur. */
    public static ?array $terakhir = null;

    private static function cfg(): array
    {
        return (require __DIR__ . '/../config/config.php')['email'];
    }

    public static function siapKirim(): bool
    {
        return trim((string) self::cfg()['host']) !== '';
    }

    /** Ringkasan konfigurasi untuk halaman Pengaturan (tanpa membocorkan sandi). */
    public static function statusKonfigurasi(): array
    {
        $c = self::cfg();
        $user = (string) $c['user'];
        $samar = $user === '' ? '-' : (mb_substr($user, 0, 2) . str_repeat('•', max(3, mb_strpos($user, '@') ?: 3)) . (strstr($user, '@') ?: ''));
        return [
            'siap'      => self::siapKirim(),
            'host'      => $c['host'] ?: '-',
            'port'      => (int) $c['port'],
            'enkripsi'  => strtoupper((string) $c['enkripsi']),
            'user'      => $samar,
            'ada_sandi' => (string) $c['pass'] !== '',
            'mesin'     => is_file(__DIR__ . '/../../vendor/autoload.php') ? 'PHPMailer (Composer)' : 'Klien SMTP bawaan (tanpa Composer)',
        ];
    }

    // --- Pengiriman --------------------------------------------------
    private static function kirim(string $ke, string $subjek, string $isiHtml, string $jenis, bool $simpanIsi = true, ?int $logId = null): bool
    {
        $status = 'log';
        $keterangan = 'SMTP belum dikonfigurasi: email hanya dicatat, TIDAK dikirim.';

        if (self::siapKirim()) {
            try {
                self::kirimLewatSmtp($ke, $subjek, $isiHtml);
                $status = 'terkirim';
                $keterangan = null;
            } catch (Throwable $e) {
                $status = 'gagal';
                $keterangan = self::sensor($e->getMessage());
            }
        }

        try {
            if ($logId) {
                Database::execute(
                    'UPDATE log_email SET status = ?, keterangan = ?, percobaan = percobaan + 1, diperbarui_pada = now() WHERE id = ?',
                    [$status, $keterangan, $logId]
                );
            } else {
                $logId = (int) Database::fetch(
                    'INSERT INTO log_email (tujuan, subjek, jenis, isi_html, status, keterangan) VALUES (?, ?, ?, ?, ?, ?) RETURNING id',
                    [$ke, mb_substr($subjek, 0, 255), $jenis, $simpanIsi ? $isiHtml : null, $status, $keterangan]
                )['id'];
            }
        } catch (Throwable $e) {
            // Tabel log belum ada (migrasi 04 belum dijalankan): catat ke file saja.
        }
        self::catatKeFile($ke, $subjek, $simpanIsi ? $isiHtml : '(isi rahasia tidak dicatat)', $status, $keterangan);

        self::$terakhir = ['status' => $status, 'keterangan' => $keterangan, 'log_id' => $logId];
        return $status === 'terkirim';
    }

    private static function kirimLewatSmtp(string $ke, string $subjek, string $isiHtml): void
    {
        $c = self::cfg();
        $pengaturan = new Pengaturan();
        $namaPengirim = $pengaturan->ambil('smtp_nama_pengirim', $c['dari_nama']);
        $alamatPengirim = $pengaturan->ambil('smtp_alamat_pengirim', $c['dari_email']);

        if (is_file(__DIR__ . '/../../vendor/autoload.php')) {
            require_once __DIR__ . '/../../vendor/autoload.php';
            $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
            $mail->isSMTP();
            $mail->Host = $c['host'];
            $mail->Port = (int) $c['port'];
            $mail->SMTPAuth = $c['user'] !== '';
            $mail->Username = $c['user'];
            $mail->Password = $c['pass'];
            $mail->SMTPSecure = $c['enkripsi'] === 'ssl'
                ? \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS
                : \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
            $mail->Timeout = 15;
            $mail->CharSet = 'UTF-8';
            $mail->setFrom($alamatPengirim, $namaPengirim);
            $mail->addAddress($ke);
            $mail->isHTML(true);
            $mail->Subject = $subjek;
            $mail->Body = $isiHtml;
            $mail->AltBody = trim(html_entity_decode(strip_tags(str_replace(['<br>', '</p>'], "\n", $isiHtml))));
            $mail->send();
            return;
        }

        (new SmtpSederhana($c['host'], (int) $c['port'], (string) $c['user'], (string) $c['pass'], (string) $c['enkripsi']))
            ->kirim($alamatPengirim, $namaPengirim, $ke, $subjek, $isiHtml);
    }

    /** Hapus apa pun yang mirip kata sandi dari pesan error sebelum disimpan. */
    private static function sensor(string $pesan): string
    {
        $pass = (string) self::cfg()['pass'];
        if ($pass !== '') {
            $pesan = str_replace([$pass, base64_encode($pass)], '••••', $pesan);
        }
        return mb_substr($pesan, 0, 480);
    }

    private static function catatKeFile(string $ke, string $subjek, string $isi, string $status, ?string $ket): void
    {
        $baris = sprintf(
            "[%s] %s | KE: %s | SUBJEK: %s%s\n%s\n%s\n\n",
            date('Y-m-d H:i:s'), strtoupper($status), $ke, $subjek, $ket ? ' | ' . $ket : '',
            str_repeat('-', 60),
            trim(html_entity_decode(strip_tags($isi)))
        );
        $dirLog = (require __DIR__ . '/../config/config.php')['log_dir'];
        if (!is_dir($dirLog)) {
            @mkdir($dirLog, 0755, true);
        }
        @file_put_contents($dirLog . '/email.log', $baris, FILE_APPEND);
    }

    // --- Riwayat, kirim ulang, uji (Admin > Pengaturan > Email) --------
    public static function kirimUlang(int $logId): bool
    {
        $log = Database::fetch('SELECT * FROM log_email WHERE id = ?', [$logId]);
        if (!$log || $log['isi_html'] === null || $log['status'] === 'terkirim') {
            return false;
        }
        return self::kirim($log['tujuan'], $log['subjek'], $log['isi_html'], $log['jenis'], true, (int) $log['id']);
    }

    public static function kirimUji(string $ke): bool
    {
        $isi = '<p>Ini email uji dari KarirKu Polinema.</p><p>Bila Anda menerima email ini, pengaturan SMTP sudah benar dan '
             . 'email notifikasi (verifikasi akun, status lowongan, reset kata sandi) akan terkirim.</p>'
             . '<p>Dikirim pada ' . e(tanggalWaktuIndo(date('Y-m-d H:i:s'))) . ' WIB.</p>';
        return self::kirim($ke, 'Email Uji - KarirKu Polinema', self::bungkus($isi), 'uji');
    }

    // --- Template email ----------------------------------------------
    public static function kirimPendaftaranDiterima(string $email, string $noPendaftaran): bool
    {
        $isi = '<p>Pendaftaran Anda di KarirKu Polinema telah kami terima.</p>
                <p>Nomor pendaftaran Anda: <b>' . e($noPendaftaran) . '</b></p>
                <p>Admin Career Center akan memeriksa data dan dokumen Anda dalam waktu maksimal 2 hari kerja.
                Pantau perkembangannya di <a href="' . e(urlAbsolut('status-akun')) . '">Halaman Status Akun</a>.</p>';
        return self::kirim($email, 'Pendaftaran KarirKu Polinema Diterima', self::bungkus($isi), 'registrasi');
    }

    public static function kirimStatusAkun(string $email, string $keputusan, ?string $catatan): bool
    {
        $peta = [
            'disetujui' => '<p>Selamat, akun KarirKu Polinema Anda telah disetujui. Silakan <a href="' . e(urlAbsolut('masuk')) . '">masuk</a> dan lengkapi profil Anda.</p>',
            'perbaikan' => '<p>Admin menemukan data atau dokumen yang perlu diperbaiki.</p><p><b>Catatan Admin:</b> ' . nl2br(e((string) $catatan)) . '</p>'
                         . '<p>Masuk ke KarirKu, lalu unggah perbaikan di <a href="' . e(urlAbsolut('status-akun')) . '">Halaman Status Akun</a>.</p>',
            'ditolak'   => '<p>Mohon maaf, pendaftaran Anda tidak dapat kami setujui.</p><p><b>Alasan:</b> ' . nl2br(e((string) $catatan)) . '</p>'
                         . '<p>Hubungi Career Center Polinema bila ada pertanyaan.</p>',
        ];
        $isi = $peta[$keputusan] ?? '<p>Status akun Anda telah diperbarui.</p>';
        $subjek = isset(self::SUBJEK_DEFAULT[$keputusan])
            ? (new Pengaturan())->ambil('template_email_subjek_' . $keputusan, self::SUBJEK_DEFAULT[$keputusan])
            : 'Status Akun Diperbarui - KarirKu Polinema';
        return self::kirim($email, $subjek, self::bungkus($isi), 'status_akun');
    }

    public static function kirimStatusAktivasi(string $email, bool $nonaktif, ?string $alasan): bool
    {
        $subjek = $nonaktif ? 'Akun Anda Dinonaktifkan' : 'Akun Anda Diaktifkan Kembali';
        $isi = $nonaktif
            ? '<p>Akun KarirKu Polinema Anda telah dinonaktifkan Admin.</p><p><b>Alasan:</b> ' . nl2br(e((string) $alasan)) . '</p>'
            : '<p>Akun KarirKu Polinema Anda telah diaktifkan kembali. Silakan <a href="' . e(urlAbsolut('masuk')) . '">masuk</a> seperti biasa.</p>';
        return self::kirim($email, $subjek . ' - KarirKu Polinema', self::bungkus($isi), 'status_akun');
    }

    /** Revisi M: hasil peninjauan lowongan untuk perusahaan. */
    public static function kirimStatusLowongan(string $email, string $keputusan, string $posisi, ?string $alasan): bool
    {
        [$subjek, $isi] = match ($keputusan) {
            'disetujui' => ['Lowongan Anda Disetujui',
                '<p>Lowongan <b>' . e($posisi) . '</b> telah disetujui Admin Career Center dan kini tayang untuk mahasiswa dan alumni Polinema.</p>'],
            'revisi' => ['Lowongan Anda Perlu Direvisi',
                '<p>Admin meminta perbaikan pada lowongan <b>' . e($posisi) . '</b> sebelum dapat ditayangkan.</p>'
                . '<p><b>Catatan Admin:</b> ' . nl2br(e((string) $alasan)) . '</p>'
                . '<p>Perbaiki lowongan lalu ajukan kembali dari menu <a href="' . e(urlAbsolut('perusahaan/lowongan')) . '">Lowongan Saya</a>.</p>'],
            'ditolak' => ['Lowongan Anda Ditolak',
                '<p>Mohon maaf, lowongan <b>' . e($posisi) . '</b> ditolak Admin dan tidak akan ditayangkan.</p>'
                . '<p><b>Alasan:</b> ' . nl2br(e((string) $alasan)) . '</p><p>Hubungi Career Center Polinema bila ada pertanyaan.</p>'],
            default => ['Lowongan Anda Dinonaktifkan',
                '<p>Lowongan <b>' . e($posisi) . '</b> dinonaktifkan Admin dan tidak lagi tampil untuk pelamar.</p>'
                . '<p><b>Alasan:</b> ' . nl2br(e((string) $alasan)) . '</p>'],
        };
        return self::kirim($email, $subjek . ' - KarirKu Polinema', self::bungkus($isi), 'status_lowongan');
    }

    public static function kirimResetKataSandi(string $email, string $tautanReset): bool
    {
        $isi = '<p>Kami menerima permintaan untuk mengatur ulang kata sandi akun KarirKu Polinema Anda.</p>
                <p><a href="' . e($tautanReset) . '">Klik di sini untuk membuat kata sandi baru</a></p>
                <p>Tautan ini hanya berlaku selama <b>60 menit</b> dan hanya bisa dipakai sekali.
                Abaikan email ini bila Anda tidak meminta reset kata sandi.</p>';
        // Isi berisi token rahasia: tidak disimpan di log dan tidak bisa dikirim ulang.
        return self::kirim($email, 'Atur Ulang Kata Sandi - KarirKu Polinema', self::bungkus($isi), 'reset_sandi', false);
    }

    /** Revisi L: pemberitahuan bahwa Admin mengatur kata sandi sementara (sandinya TIDAK ikut dikirim). */
    public static function kirimSandiDiresetAdmin(string $email): bool
    {
        $isi = '<p>Admin Career Center telah mengatur ulang kata sandi akun KarirKu Polinema Anda.</p>
                <p>Kata sandi sementara disampaikan Admin melalui jalur resmi. Setelah masuk, Anda <b>wajib</b> menggantinya dengan kata sandi baru.</p>
                <p>Semua sesi login lama sudah dikeluarkan. Bila Anda tidak merasa meminta reset ini, segera hubungi Career Center.</p>';
        return self::kirim($email, 'Kata Sandi Anda Diatur Ulang Admin - KarirKu Polinema', self::bungkus($isi), 'reset_sandi_admin');
    }

    // --- Kerangka HTML email -----------------------------------------
    private static function bungkus(string $isi): string
    {
        return '<div style="font-family:Arial,sans-serif;font-size:14px;color:#1c2230;max-width:520px">
                    <h2 style="color:#16305e">KarirKu Polinema</h2>' . $isi .
                '<p style="color:#8a93a3;font-size:12px;margin-top:24px">
                    Email ini dikirim otomatis oleh sistem KarirKu Polinema. Mohon tidak membalas email ini.
                 </p></div>';
    }
}
