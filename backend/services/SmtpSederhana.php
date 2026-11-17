<?php
// ===== BACKEND · SERVICE · Klien SMTP bawaan (tanpa Composer) =========
// Dipakai MailService bila PHPMailer belum dipasang lewat Composer.
// Mendukung STARTTLS (port 587), SSL langsung (port 465), dan AUTH LOGIN,
// cukup untuk Gmail (App Password), Outlook, dan server SMTP kampus.
// Kata sandi TIDAK pernah ikut ditulis ke pesan error atau log.

class SmtpSederhana
{
    /** @var resource|null */
    private $soket = null;
    private int $batasDetik = 15;

    public function __construct(
        private string $host,
        private int $port,
        private string $user,
        private string $pass,
        private string $enkripsi = 'tls'
    ) {
    }

    public function kirim(string $dariEmail, string $dariNama, string $ke, string $subjek, string $isiHtml): void
    {
        $alamat = ($this->enkripsi === 'ssl' ? 'ssl://' : 'tcp://') . $this->host . ':' . $this->port;
        $konteks = stream_context_create(['ssl' => ['verify_peer' => true, 'verify_peer_name' => true, 'SNI_enabled' => true]]);
        $this->soket = @stream_socket_client($alamat, $kodeErr, $pesanErr, $this->batasDetik, STREAM_CLIENT_CONNECT, $konteks);
        if (!$this->soket) {
            throw new RuntimeException("Tidak bisa terhubung ke server SMTP {$this->host}:{$this->port} ({$pesanErr}).");
        }
        stream_set_timeout($this->soket, $this->batasDetik);

        try {
            $this->harap(220);
            $namaKlien = preg_replace('/[^A-Za-z0-9.\-]/', '', $_SERVER['SERVER_NAME'] ?? 'localhost') ?: 'localhost';
            $this->perintah('EHLO ' . $namaKlien, 250);

            if ($this->enkripsi === 'tls') {
                $this->perintah('STARTTLS', 220);
                if (!@stream_socket_enable_crypto($this->soket, true,
                        STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT | STREAM_CRYPTO_METHOD_TLSv1_3_CLIENT)) {
                    throw new RuntimeException('Gagal membuka koneksi terenkripsi (STARTTLS).');
                }
                $this->perintah('EHLO ' . $namaKlien, 250);
            }

            if ($this->user !== '') {
                $this->perintah('AUTH LOGIN', 334);
                $this->perintah(base64_encode($this->user), 334, true);
                $this->perintah(base64_encode($this->pass), 235, true);
            }

            $this->perintah('MAIL FROM:<' . $this->bersihkanAlamat($dariEmail) . '>', 250);
            $this->perintah('RCPT TO:<' . $this->bersihkanAlamat($ke) . '>', [250, 251]);
            $this->perintah('DATA', 354);

            $domain = substr(strrchr($dariEmail, '@') ?: '@localhost', 1);
            $header = [
                'Date: ' . date('r'),
                'From: ' . $this->kodekan($dariNama) . ' <' . $this->bersihkanAlamat($dariEmail) . '>',
                'To: <' . $this->bersihkanAlamat($ke) . '>',
                'Subject: ' . $this->kodekan($subjek),
                'Message-ID: <' . bin2hex(random_bytes(12)) . '@' . $domain . '>',
                'MIME-Version: 1.0',
                'Content-Type: text/html; charset=UTF-8',
                'Content-Transfer-Encoding: base64',
            ];
            $data = implode("\r\n", $header) . "\r\n\r\n" . rtrim(chunk_split(base64_encode($isiHtml), 76, "\r\n")) . "\r\n.";
            $this->perintah($data, 250, true);
            $this->tulis('QUIT');
        } finally {
            if (is_resource($this->soket)) {
                fclose($this->soket);
            }
            $this->soket = null;
        }
    }

    // --- Protokol ----------------------------------------------------
    private function perintah(string $baris, $kodeHarapan, bool $rahasia = false): string
    {
        $this->tulis($baris);
        return $this->harap($kodeHarapan, $rahasia ? '(data tersembunyi)' : strtok($baris, "\r\n"));
    }

    private function tulis(string $baris): void
    {
        if (@fwrite($this->soket, $baris . "\r\n") === false) {
            throw new RuntimeException('Koneksi ke server SMTP terputus.');
        }
    }

    private function harap($kodeHarapan, string $konteks = 'salam pembuka'): string
    {
        $balasan = '';
        while (($baris = fgets($this->soket, 515)) !== false) {
            $balasan .= $baris;
            if (strlen($baris) < 4 || $baris[3] === ' ') {
                break;
            }
        }
        $kode = (int) substr($balasan, 0, 3);
        if (!in_array($kode, (array) $kodeHarapan, true)) {
            $info = stream_get_meta_data($this->soket);
            $alasan = !empty($info['timed_out']) ? 'waktu tunggu habis' : trim($balasan);
            if ($kode === 535) {
                $alasan = 'username atau App Password SMTP ditolak server (535)';
            }
            throw new RuntimeException('SMTP gagal pada ' . $konteks . ': ' . mb_substr($alasan, 0, 200));
        }
        return $balasan;
    }

    private function kodekan(string $teks): string
    {
        return preg_match('/[^\x20-\x7e]/', $teks) ? '=?UTF-8?B?' . base64_encode($teks) . '?=' : str_replace(["\r", "\n"], '', $teks);
    }

    private function bersihkanAlamat(string $email): string
    {
        $email = trim(str_replace(["\r", "\n", '<', '>'], '', $email));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new RuntimeException('Alamat email tidak valid: ' . $email);
        }
        return $email;
    }
}
