<?php
// ===== BACKEND · SERVICE · Berkas sementara (revisi G lanjutan) =========
// Masalah: bila formulir gagal (validasi, sesi kedaluwarsa, gangguan server),
// isian teks bisa dikembalikan, tetapi berkas yang tadi dipilih HILANG dan
// pengguna harus memilih ulang KTM/NIB/pamflet/surat.
//
// Solusi: berkas yang terunggah pada pengiriman yang GAGAL disimpan sementara
// di storage/uploads/_sementara (maks. 2 jam, hanya untuk sesi pemiliknya).
// Saat formulir yang sama dikirim ulang tanpa memilih berkas baru, berkas tadi
// dipasang kembali ke $_FILES, sehingga seluruh controller tetap bekerja seperti
// biasa tanpa perubahan. Berhasil disimpan -> berkas sementara dibersihkan.

class BerkasSementara
{
    private const KUNCI = '_berkas_sementara';
    private const UMUR_DETIK = 7200;
    private const MAKS_PER_SESI = 20;

    private static function folder(): string
    {
        $cfg = require __DIR__ . '/../config/config.php';
        $f = rtrim($cfg['upload_dir'], '/\\') . '/_sementara';
        if (!is_dir($f)) {
            @mkdir($f, 0755, true);
        }
        return $f;
    }

    /** Jalur formulir tujuan (tanpa base_url & query), mis. "lowongan/proses-pasang". */
    public static function jalur(?string $path = null): string
    {
        $p = $path ?? (class_exists('Auth') ? Auth::pathSaatIni() : '');
        return trim((string) strtok($p, '?'), '/');
    }

    /** Dipanggil di awal setiap POST: pasang kembali berkas tersimpan ke $_FILES. */
    public static function pasangKeRequest(): void
    {
        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST' || empty($_SESSION[self::KUNCI])) {
            return;
        }
        self::bersihkanKedaluwarsa();
        $jalur = self::jalur();
        $daftar = $_SESSION[self::KUNCI][$jalur] ?? [];
        $hapus = is_array($_POST['hapus_sementara'] ?? null) ? $_POST['hapus_sementara'] : [];
        foreach ($daftar as $field => $b) {
            if (isset($hapus[$field])) {
                self::buang($jalur, $field);
                continue;
            }
            $kosong = !isset($_FILES[$field]) || !is_array($_FILES[$field]['error'] ?? null) && ($_FILES[$field]['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE;
            $path = self::folder() . '/' . basename($b['file']);
            if ($kosong && !is_file($path)) {
                $path = PenyimpananBerkas::pastikanLokal('_sementara', $b['file']);
            }
            if ($kosong && is_file($path)) {
                $_FILES[$field] = [
                    'name' => $b['nama'], 'type' => $b['tipe'], 'tmp_name' => $path,
                    'error' => UPLOAD_ERR_OK, 'size' => filesize($path), 'sementara' => true,
                ];
            }
        }
    }

    /** Pengiriman gagal: simpan berkas yang baru diunggah agar tidak perlu dipilih ulang. */
    public static function simpanDariRequest(): void
    {
        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST' || empty($_FILES)) {
            return;
        }
        $jalur = self::jalur();
        foreach ($_FILES as $field => $f) {
            if (!is_string($f['name'] ?? null) || ($f['error'] ?? 1) !== UPLOAD_ERR_OK) {
                continue;
            }
            if (!empty($f['sementara'])) {
                continue;                                    // sudah tersimpan sebelumnya
            }
            if (!is_uploaded_file($f['tmp_name']) || $f['size'] <= 0 || $f['size'] > 10 * 1024 * 1024) {
                continue;
            }
            $ext = strtolower(pathinfo($f['name'], PATHINFO_EXTENSION));
            if (!in_array($ext, ['pdf', 'jpg', 'jpeg', 'png'], true)) {
                continue;                                    // jenis tak dikenal tidak disimpan
            }
            if (count($_SESSION[self::KUNCI] ?? [], COUNT_RECURSIVE) > self::MAKS_PER_SESI * 6) {
                break;
            }
            self::buang($jalur, $field);
            $nama = bin2hex(random_bytes(16)) . '.' . $ext;
            if (@move_uploaded_file($f['tmp_name'], self::folder() . '/' . $nama)) {
                PenyimpananBerkas::simpan('_sementara', $nama, self::folder() . '/' . $nama);
                $_SESSION[self::KUNCI][$jalur][$field] = [
                    'file' => $nama, 'nama' => mb_substr(basename($f['name']), 0, 150),
                    'tipe' => deteksiMime(self::folder() . '/' . $nama), 'ukuran' => (int) $f['size'], 'waktu' => time(),
                ];
            }
        }
    }

    /** Berkas sementara sudah dipindah ke lokasi permanen oleh UploadService. */
    public static function terpakai(string $field): void
    {
        $jalur = self::jalur();
        unset($_SESSION[self::KUNCI][$jalur][$field]);
        if (empty($_SESSION[self::KUNCI][$jalur])) {
            unset($_SESSION[self::KUNCI][$jalur]);
        }
    }

    /** Pengiriman berhasil: semua berkas sementara formulir ini tidak diperlukan lagi. */
    public static function bersihkan(?string $jalur = null): void
    {
        $jalur = $jalur ?? self::jalur();
        foreach (array_keys($_SESSION[self::KUNCI][$jalur] ?? []) as $field) {
            self::buang($jalur, $field);
        }
    }

    private static function buang(string $jalur, string $field): void
    {
        $b = $_SESSION[self::KUNCI][$jalur][$field] ?? null;
        if ($b) {
            @unlink(self::folder() . '/' . basename($b['file']));
            PenyimpananBerkas::hapus('_sementara', $b['file']);
        }
        unset($_SESSION[self::KUNCI][$jalur][$field]);
        if (empty($_SESSION[self::KUNCI][$jalur])) {
            unset($_SESSION[self::KUNCI][$jalur]);
        }
    }

    private static function bersihkanKedaluwarsa(): void
    {
        foreach ($_SESSION[self::KUNCI] ?? [] as $jalur => $daftar) {
            foreach ($daftar as $field => $b) {
                if (time() - (int) $b['waktu'] > self::UMUR_DETIK) {
                    self::buang($jalur, $field);
                }
            }
        }
        // Berkas yatim (sesi sudah hilang) dibersihkan sesekali.
        if (random_int(1, 50) === 1) {
            PenyimpananBerkas::bersihkanSementara(self::UMUR_DETIK);
            foreach (glob(self::folder() . '/*') ?: [] as $f) {
                if (is_file($f) && time() - filemtime($f) > self::UMUR_DETIK) {
                    @unlink($f);
                }
            }
        }
    }

    /** Apakah berkas ini milik sesi saat ini (untuk pratinjau lewat unduh.php). */
    public static function milikSesi(string $file): ?array
    {
        foreach ($_SESSION[self::KUNCI] ?? [] as $daftar) {
            foreach ($daftar as $b) {
                if (hash_equals($b['file'], basename($file))) {
                    return $b + ['path' => PenyimpananBerkas::pastikanLokal('_sementara', $b['file'])];
                }
            }
        }
        return null;
    }

    /** Data untuk JavaScript: jalur formulir -> field -> info berkas. */
    public static function untukTampilan(): array
    {
        self::bersihkanKedaluwarsa();
        $hasil = [];
        foreach ($_SESSION[self::KUNCI] ?? [] as $jalur => $daftar) {
            foreach ($daftar as $field => $b) {
                $hasil[$jalur][$field] = [
                    'nama' => $b['nama'], 'ukuran' => (int) $b['ukuran'],
                    'gambar' => str_starts_with((string) $b['tipe'], 'image/'),
                    'url' => url('unduh.php?tipe=sementara&file=' . urlencode($b['file'])),
                ];
            }
        }
        return $hasil;
    }

    /** <script> JSON yang dibaca app.js (initBerkasSementara). Aman: di-escape JSON_HEX_*. */
    public static function skrip(): string
    {
        $data = self::untukTampilan();
        if (!$data) {
            return '';
        }
        global $config;
        return '<script type="application/json" id="dataBerkasSementara">'
            . json_encode(['base' => rtrim((string) ($config['base_url'] ?? ''), '/'), 'berkas' => $data],
                JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_UNESCAPED_UNICODE)
            . '</script>';
    }
}
