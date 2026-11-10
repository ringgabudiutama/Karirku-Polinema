<?php
// ===== BACKEND · SERVICE · Unggah berkas =============================

class UploadService
{
    // --- Unggah ------------------------------------------------------
    public static function simpan(string $field, string $subfolder, array $tipeDiizinkan = ['pdf', 'jpg', 'jpeg', 'png']): array
    {
        $cfg = require __DIR__ . '/../config/config.php';

        if (!isset($_FILES[$field]) || $_FILES[$field]['error'] === UPLOAD_ERR_NO_FILE) {
            throw new RuntimeException('File belum dipilih.');
        }
        $berkas = $_FILES[$field];

        if ($berkas['error'] !== UPLOAD_ERR_OK) {
            $pesan = [
                UPLOAD_ERR_INI_SIZE   => 'Ukuran file melebihi batas server (maksimal ' . $cfg['max_upload_kb'] . ' KB).',
                UPLOAD_ERR_FORM_SIZE  => 'Ukuran file melebihi batas formulir (maksimal ' . $cfg['max_upload_kb'] . ' KB).',
                UPLOAD_ERR_PARTIAL    => 'File hanya terunggah sebagian. Periksa koneksi lalu coba lagi.',
                UPLOAD_ERR_NO_TMP_DIR => 'Folder sementara server tidak tersedia. Hubungi Admin.',
                UPLOAD_ERR_CANT_WRITE => 'Server gagal menyimpan file. Hubungi Admin.',
            ][$berkas['error']] ?? 'Gagal mengunggah file (kode error: ' . $berkas['error'] . ').';
            throw new RuntimeException($pesan);
        }

        if (!validasiUkuranFile($berkas['size'], $cfg['max_upload_kb'])) {
            throw new RuntimeException('Ukuran file maksimal ' . $cfg['max_upload_kb'] . ' KB.');
        }

        if (!validasiTipeFile($berkas['name'], $tipeDiizinkan)) {
            throw new RuntimeException('Tipe file tidak diizinkan. Gunakan: ' . implode(', ', $tipeDiizinkan));
        }

        // Revisi C: isi berkas dicek, bukan hanya nama ekstensinya. File .exe
        // yang diganti nama menjadi .jpg/.pdf akan ditolak di sini.
        $ekstensi = ekstensiFile($berkas['name']);
        $mimeHarapan = [
            'pdf' => ['application/pdf'], 'jpg' => ['image/jpeg', 'image/pjpeg'], 'jpeg' => ['image/jpeg', 'image/pjpeg'],
            'png' => ['image/png'],
        ][$ekstensi] ?? null;
        if ($mimeHarapan !== null && is_file($berkas['tmp_name'])) {
            $mimeAsli = deteksiMime($berkas['tmp_name']);
            if (!in_array($mimeAsli, $mimeHarapan, true)) {
                throw new RuntimeException('Isi file tidak sesuai dengan formatnya (.' . $ekstensi . '). Simpan ulang file sebagai '
                    . strtoupper($ekstensi) . ' yang benar lalu unggah lagi.');
            }
            if ($ekstensi !== 'pdf' && @getimagesize($berkas['tmp_name']) === false) {
                throw new RuntimeException('Gambar rusak atau tidak bisa dibaca. Coba simpan ulang gambarnya.');
            }
        }

        $namaBaru = buatNamaFileAcak($ekstensi);
        $folderTujuan = rtrim($cfg['upload_dir'], '/') . '/' . $subfolder;

        if (!is_dir($folderTujuan) && !mkdir($folderTujuan, 0755, true) && !is_dir($folderTujuan)) {
            throw new RuntimeException('Gagal menyiapkan folder penyimpanan.');
        }

        $tujuan = $folderTujuan . '/' . $namaBaru;
        if (!empty($berkas['sementara'])) {
            // Berkas dari pengiriman sebelumnya yang gagal (BerkasSementara).
            if (!@rename($berkas['tmp_name'], $tujuan) && !(@copy($berkas['tmp_name'], $tujuan) && @unlink($berkas['tmp_name']))) {
                throw new RuntimeException('Gagal menyimpan file ke server.');
            }
            PenyimpananBerkas::hapus('_sementara', basename($berkas['tmp_name']));
            BerkasSementara::terpakai($field);
        } elseif (!move_uploaded_file($berkas['tmp_name'], $tujuan)) {
            throw new RuntimeException('Gagal menyimpan file ke server.');
        }

        // Lapis kedua: bersihkan ISI berkas. Berkas yang sah sebagai gambar/PDF tetap bisa menyelipkan
        // kode (polyglot). Lokasi di luar folder web melindungi, ini memastikan isinya pun bersih.
        try {
            if ($ekstensi === 'pdf') {
                self::periksaPdf($tujuan);
            } elseif (in_array($ekstensi, ['jpg', 'jpeg', 'png'], true)) {
                self::bersihkanGambar($tujuan, $ekstensi);
            }
        } catch (RuntimeException $e) {
            @unlink($tujuan);
            throw $e;
        }

        // Mode serverless (Vercel): salinan permanen di database.
        PenyimpananBerkas::simpan($subfolder, $namaBaru, $tujuan);

        return [
            'nama'      => $namaBaru,
            'ukuran_kb' => (int) ceil((int) @filesize($tujuan) / 1024),
        ];
    }

    // --- Pembersihan isi berkas ----------------------------------------
    /** Dimensi maksimum gambar: mencegah "bom piksel" (berkas kecil yang memakan GB memori saat didekode). */
    private const MAKS_PIKSEL = 25000000;   // 25 juta piksel (± 5000 x 5000)
    private const MAKS_SISI   = 10000;

    /**
     * Gambar didekode lalu ditulis ulang dari nol: apa pun yang diselipkan di luar piksel (data di ujung berkas,
     * komentar JPEG, blok teks PNG, metadata EXIF) ikut terbuang. Orientasi EXIF diterapkan lebih dulu agar foto
     * dari ponsel tidak jadi miring. Tanpa ekstensi GD, gambar tetap dipindai dan ditolak bila memuat tag kode.
     */
    private static function bersihkanGambar(string $path, string $ekstensi): void
    {
        $info = @getimagesize($path);
        if ($info === false) {
            throw new RuntimeException('Gambar rusak atau tidak bisa dibaca. Coba simpan ulang gambarnya.');
        }
        [$w, $h] = $info;
        if ($w < 1 || $h < 1 || $w > self::MAKS_SISI || $h > self::MAKS_SISI || $w * $h > self::MAKS_PIKSEL) {
            throw new RuntimeException('Dimensi gambar terlalu besar. Perkecil gambarnya (maksimal 5000 x 5000 piksel) lalu unggah lagi.');
        }
        $mentah = (string) file_get_contents($path);
        if (preg_match('/<\?(?:php|=)|<script\b/i', $mentah)) {
            throw new RuntimeException('Gambar mengandung kode yang tidak diizinkan. Gunakan foto/scan biasa.');
        }
        if (!function_exists('imagecreatefromstring')) {
            error_log('[KarirKu] Ekstensi PHP GD tidak terpasang: gambar hanya dipindai, tidak dibuat ulang. Pasang php-gd.');
            return;
        }
        if (self::batasMemoriByte() < 256 * 1024 * 1024) {
            @ini_set('memory_limit', '256M');
        }
        $im = @imagecreatefromstring($mentah);
        unset($mentah);
        if ($im === false) {
            throw new RuntimeException('Gambar rusak atau tidak bisa dibaca. Coba simpan ulang gambarnya.');
        }
        if (in_array($ekstensi, ['jpg', 'jpeg'], true) && function_exists('exif_read_data')) {
            $exif = @exif_read_data($path);
            $im = self::terapkanOrientasi($im, (int) ($exif['Orientation'] ?? 1));
        }
        $sementara = $path . '.bersih';
        if (in_array($ekstensi, ['jpg', 'jpeg'], true)) {
            $ok = @imagejpeg($im, $sementara, 90);
        } else {
            imagealphablending($im, false);
            imagesavealpha($im, true);
            $ok = @imagepng($im, $sementara, 6);
        }
        imagedestroy($im);
        if (!$ok || !is_file($sementara) || filesize($sementara) === 0 || !@rename($sementara, $path)) {
            @unlink($sementara);
            throw new RuntimeException('Gagal memproses gambar. Coba simpan ulang gambarnya lalu unggah lagi.');
        }
    }

    private static function terapkanOrientasi($im, int $o)
    {
        $putar = static function ($gambar, int $derajat) {
            $r = @imagerotate($gambar, $derajat, 0);
            if ($r !== false) {
                imagedestroy($gambar);
                return $r;
            }
            return $gambar;
        };
        switch ($o) {
            case 2: imageflip($im, IMG_FLIP_HORIZONTAL); break;
            case 3: $im = $putar($im, 180); break;
            case 4: imageflip($im, IMG_FLIP_VERTICAL); break;
            case 5: imageflip($im, IMG_FLIP_HORIZONTAL); $im = $putar($im, -90); break;
            case 6: $im = $putar($im, -90); break;
            case 7: imageflip($im, IMG_FLIP_HORIZONTAL); $im = $putar($im, 90); break;
            case 8: $im = $putar($im, 90); break;
        }
        return $im;
    }

    private static function batasMemoriByte(): int
    {
        $v = trim((string) ini_get('memory_limit'));
        if ($v === '-1') {
            return PHP_INT_MAX;
        }
        $n = (int) $v;
        return match (strtolower(substr($v, -1))) {
            'g' => $n * 1024 * 1024 * 1024,
            'm' => $n * 1024 * 1024,
            'k' => $n * 1024,
            default => $n,
        };
    }

    /**
     * PDF tidak boleh membawa konten aktif: JavaScript, Launch (menjalankan program), file tertanam, form yang
     * mengirim data. Pemindaian juga menembus nama yang disamarkan (/J#61vaScript) dan isi stream terkompresi.
     * Catatan: ini bukan pengganti antivirus (ClamAV).
     */
    private static function periksaPdf(string $path): void
    {
        $mentah = (string) file_get_contents($path, false, null, 0, 6 * 1024 * 1024);
        $berbahaya = static function (string $data): bool {
            $data = preg_replace_callback('/#([0-9A-Fa-f]{2})/', static fn ($m) => chr(hexdec($m[1])), $data) ?? $data;
            return (bool) preg_match('#/(JavaScript|JS|Launch|EmbeddedFiles?|RichMedia|XFA|SubmitForm|ImportData|GoToE|GoToR)\b#', $data);
        };
        $ketemu = $berbahaya($mentah);
        for ($pos = 0, $n = 0; !$ketemu && $n < 300 && ($a = strpos($mentah, 'stream', $pos)) !== false; $n++) {
            $mulai = $a + 6;
            if (substr($mentah, $mulai, 2) === "\r\n") { $mulai += 2; } elseif (($mentah[$mulai] ?? '') === "\n") { $mulai += 1; }
            $akhir = strpos($mentah, 'endstream', $mulai);
            if ($akhir === false) { break; }
            $isi = substr($mentah, $mulai, $akhir - $mulai);
            $pos = $akhir + 9;
            if ($isi !== '' && strlen($isi) <= 2000000) {
                $d = @zlib_decode($isi, 8000000);   // batas keluaran: bom kompresi tidak memakan memori
                if ($d !== false && $berbahaya($d)) { $ketemu = true; }
            }
        }
        if ($ketemu) {
            throw new RuntimeException('PDF mengandung skrip atau konten aktif (JavaScript, program, atau file tertanam) yang tidak diizinkan. Simpan ulang dokumen sebagai PDF biasa (Print to PDF).');
        }
    }

    /** Hapus berkas lama dengan aman (dipakai saat diganti). */
    public static function hapus(string $subfolder, ?string $namaFile): void
    {
        if ($namaFile === null || $namaFile === '' || str_starts_with($namaFile, 'contoh-')) {
            return;
        }
        $cfg = require __DIR__ . '/../config/config.php';
        $path = rtrim($cfg['upload_dir'], '/') . '/' . $subfolder . '/' . basename($namaFile);
        if (is_file($path)) {
            @unlink($path);
        }
        PenyimpananBerkas::hapus($subfolder, $namaFile);
    }

    // --- Lokasi berkas -----------------------------------------------
    public static function pathLengkap(string $subfolder, string $namaFile): string
    {
        // Mencari di /tmp, berkas bawaan proyek, lalu (mode serverless) database.
        return PenyimpananBerkas::pastikanLokal($subfolder, $namaFile);
    }

    public static function ada(string $subfolder, string $namaFile): bool
    {
        return is_file(self::pathLengkap($subfolder, $namaFile));
    }
}
