<?php
/**
 * Pengiriman email lewat SMTP
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * WAJIB jalankan `composer install` dulu supaya folder vendor/ dan PHPMailer
 * tersedia (lihat composer.json di root proyek). Selama vendor/ belum ada,
 * kelas ini TIDAK menggagalkan aplikasi -- pengiriman email akan dilewati
 * dan dicatat ke storage/logs/email.log saja, supaya alur registrasi/
 * verifikasi tetap bisa dites tanpa SMTP asli.
 */

class MailService
{
    /**
     * Kunci Pengaturan untuk subjek tiap status keputusan pendaftaran, dipakai
     * kirimStatusAkun() dan disunting admin lewat menu Pengaturan > Template
     * email (dropdown "Pilih template" + field "Subjek"). Isi/body pesannya
     * sendiri tetap di kode (tidak ada di desain UI/UX menu ini).
     */
    public const SUBJEK_DEFAULT = [
        'disetujui' => '[KarirKu] Pendaftaran Anda sudah kami terima',
        'perbaikan' => '[KarirKu] Data pendaftaran Anda perlu diperbaiki',
        'ditolak'   => '[KarirKu] Pendaftaran Anda tidak dapat kami setujui',
    ];

    private static function siapPakai(): bool
    {
        return is_file(__DIR__ . '/../../vendor/autoload.php');
    }

    /**
     * Method inti pengiriman. Semua method kirimXxx() di bawah memanggil ini.
     * Kalau PHPMailer belum ter-install ATAU konfigurasi SMTP kosong (lihat
     * app/config/config.php -> 'email'), email dicatat ke log saja supaya
     * developer tetap bisa lihat isinya tanpa perlu SMTP sungguhan.
     */
    private static function kirim(string $keTujuan, string $subjek, string $isiHtml): bool
    {
        $cfg = (require __DIR__ . '/../config/config.php')['email'];

        if (!self::siapPakai() || empty($cfg['host'])) {
            self::catatKeLog($keTujuan, $subjek, $isiHtml);
            return false;
        }

        require_once __DIR__ . '/../../vendor/autoload.php';

        $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
        try {
            $mail->isSMTP();
            $mail->Host = $cfg['host'];
            $mail->Port = $cfg['port'];
            $mail->SMTPAuth = true;
            $mail->Username = $cfg['user'];
            $mail->Password = $cfg['pass'];
            $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
            $mail->CharSet = 'UTF-8';

            $namaPengirim = (new Pengaturan())->ambil('smtp_nama_pengirim', $cfg['dari_nama']);
            $alamatPengirim = (new Pengaturan())->ambil('smtp_alamat_pengirim', $cfg['dari_email']);
            $mail->setFrom($alamatPengirim, $namaPengirim);
            $mail->addAddress($keTujuan);
            $mail->isHTML(true);
            $mail->Subject = $subjek;
            $mail->Body = $isiHtml;

            $mail->send();
            return true;
        } catch (\Throwable $e) {
            self::catatKeLog($keTujuan, $subjek, $isiHtml, $e->getMessage());
            return false;
        }
    }

    private static function catatKeLog(string $ke, string $subjek, string $isi, ?string $error = null): void
    {
        $baris = sprintf(
            "[%s] KE: %s | SUBJEK: %s%s\n%s\n%s\n\n",
            date('Y-m-d H:i:s'), $ke, $subjek,
            $error ? " | ERROR: {$error}" : ' | (SMTP belum dikonfigurasi, dicatat sebagai log saja)',
            str_repeat('-', 60),
            strip_tags($isi)
        );
        @file_put_contents(__DIR__ . '/../../storage/logs/email.log', $baris, FILE_APPEND);
    }

    /* --------------------- lima template email --------------------- */

    public static function kirimPendaftaranDiterima(string $email, string $noPendaftaran): bool
    {
        $isi = "<p>Pendaftaran Anda di KarirKu Polinema telah kami terima.</p>
                <p>Nomor pendaftaran Anda: <b>{$noPendaftaran}</b></p>
                <p>Silakan pantau perkembangannya di Halaman Status Akun. Admin Career Center
                akan memeriksa data dan dokumen Anda dalam waktu maksimal 2 hari kerja.</p>";
        return self::kirim($email, 'Pendaftaran KarirKu Polinema Diterima', self::bungkus($isi));
    }

    public static function kirimStatusAkun(string $email, string $keputusan, ?string $catatan): bool
    {
        $peta = [
            'disetujui' => '<p>Selamat, akun KarirKu Polinema Anda telah disetujui. Silakan masuk dan lengkapi profil Anda.</p>',
            'perbaikan' => '<p>Admin menemukan data atau dokumen yang perlu diperbaiki.</p><p><b>Catatan Admin:</b> ' . e((string) $catatan) . '</p>',
            'ditolak'   => '<p>Mohon maaf, pendaftaran Anda tidak dapat kami setujui.</p><p><b>Alasan:</b> ' . e((string) $catatan) . '</p>',
        ];
        $isi = $peta[$keputusan] ?? '<p>Status akun Anda telah diperbarui.</p>';
        $subjek = isset(self::SUBJEK_DEFAULT[$keputusan])
            ? (new Pengaturan())->ambil('template_email_subjek_' . $keputusan, self::SUBJEK_DEFAULT[$keputusan])
            : 'Status Akun Diperbarui - KarirKu Polinema';
        return self::kirim($email, $subjek, self::bungkus($isi));
    }

    public static function kirimStatusAktivasi(string $email, bool $nonaktif, ?string $alasan): bool
    {
        $subjek = $nonaktif ? 'Akun Anda Dinonaktifkan' : 'Akun Anda Diaktifkan Kembali';
        $isi = $nonaktif
            ? '<p>Akun KarirKu Polinema Anda telah dinonaktifkan Admin.</p><p><b>Alasan:</b> ' . e((string) $alasan) . '</p>'
            : '<p>Akun KarirKu Polinema Anda telah diaktifkan kembali. Silakan masuk seperti biasa.</p>';
        return self::kirim($email, $subjek . ' - KarirKu Polinema', self::bungkus($isi));
    }

    public static function kirimResetKataSandi(string $email, string $tautanReset): bool
    {
        $isi = "<p>Kami menerima permintaan untuk mengatur ulang kata sandi akun KarirKu Polinema Anda.</p>
                <p><a href=\"{$tautanReset}\">Klik di sini untuk membuat kata sandi baru</a></p>
                <p>Tautan ini hanya berlaku selama <b>60 menit</b>. Abaikan email ini bila Anda tidak meminta reset kata sandi.</p>";
        return self::kirim($email, 'Atur Ulang Kata Sandi - KarirKu Polinema', self::bungkus($isi));
    }

    private static function bungkus(string $isi): string
    {
        return '<div style="font-family:Arial,sans-serif;font-size:14px;color:#1c2230;max-width:520px">
                    <h2 style="color:#16305e">KarirKu Polinema</h2>' . $isi .
                '<p style="color:#8a93a3;font-size:12px;margin-top:24px">
                    Email ini dikirim otomatis oleh sistem KarirKu Polinema. Mohon tidak membalas email ini.
                 </p></div>';
    }
}