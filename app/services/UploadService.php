<?php
/**
 * Penanganan unggah file
 * PIC   : Aqillah (UI/UX, Frontend, dan Integrasi)
 * Status: DIISI.
 *
 * Semua unggahan disimpan di storage/uploads/{subfolder}, DI LUAR public/,
 * lalu dilayani lewat public/unduh.php setelah dicek hak aksesnya (lihat
 * NotifikasiController & routing unduh di public/index.php).
 */

class UploadService
{
    /**
     * Validasi & pindahkan file dari $_FILES ke folder tujuan dengan nama acak.
     * Mengembalikan ['nama' => string, 'ukuran_kb' => int] kalau berhasil.
     * Melempar RuntimeException berisi pesan yang aman ditampilkan ke pengguna kalau gagal.
     */
    public static function simpan(string $field, string $subfolder, array $tipeDiizinkan = ['pdf', 'jpg', 'jpeg', 'png']): array
    {
        $cfg = require __DIR__ . '/../config/config.php';

        if (!isset($_FILES[$field]) || $_FILES[$field]['error'] === UPLOAD_ERR_NO_FILE) {
            throw new RuntimeException('File belum dipilih.');
        }
        $berkas = $_FILES[$field];

        if ($berkas['error'] !== UPLOAD_ERR_OK) {
            throw new RuntimeException('Gagal mengunggah file (kode error: ' . $berkas['error'] . ').');
        }

        if (!validasiUkuranFile($berkas['size'], $cfg['max_upload_kb'])) {
            throw new RuntimeException('Ukuran file maksimal ' . $cfg['max_upload_kb'] . ' KB.');
        }

        if (!validasiTipeFile($berkas['name'], $tipeDiizinkan)) {
            throw new RuntimeException('Tipe file tidak diizinkan. Gunakan: ' . implode(', ', $tipeDiizinkan));
        }

        $ekstensi = ekstensiFile($berkas['name']);
        $namaBaru = buatNamaFileAcak($ekstensi);
        $folderTujuan = rtrim($cfg['upload_dir'], '/') . '/' . $subfolder;

        if (!is_dir($folderTujuan) && !mkdir($folderTujuan, 0755, true) && !is_dir($folderTujuan)) {
            throw new RuntimeException('Gagal menyiapkan folder penyimpanan.');
        }

        $tujuan = $folderTujuan . '/' . $namaBaru;
        if (!move_uploaded_file($berkas['tmp_name'], $tujuan)) {
            throw new RuntimeException('Gagal menyimpan file ke server.');
        }

        return [
            'nama'      => $namaBaru,
            'ukuran_kb' => (int) ceil($berkas['size'] / 1024),
        ];
    }

    /** Path lengkap di server untuk satu file yang sudah tersimpan (dipakai public/unduh.php). */
    public static function pathLengkap(string $subfolder, string $namaFile): string
    {
        $cfg = require __DIR__ . '/../config/config.php';
        return rtrim($cfg['upload_dir'], '/') . '/' . $subfolder . '/' . basename($namaFile);
    }

    public static function ada(string $subfolder, string $namaFile): bool
    {
        return is_file(self::pathLengkap($subfolder, $namaFile));
    }
}
