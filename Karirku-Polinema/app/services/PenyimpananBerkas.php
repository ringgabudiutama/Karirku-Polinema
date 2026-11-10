<?php
// ===== BACKEND · SERVICE · Cermin berkas unggahan di database (mode serverless) =====
// Di Vercel, berkas hanya bisa ditulis ke /tmp dan /tmp bisa terhapus kapan saja,
// serta tidak dibagi antarserver. Maka setiap berkas unggahan juga disimpan di tabel
// berkas_tersimpan. Saat berkas dibutuhkan dan belum ada di /tmp server yang sedang
// melayani, isinya dipulihkan dari database. Di XAMPP/hosting biasa kelas ini diam saja.

class PenyimpananBerkas
{
    private static bool $tabelSiap = false;

    public static function aktif(): bool
    {
        $cfg = require __DIR__ . '/../config/config.php';
        return !empty($cfg['serverless']);
    }

    private static function siapkanTabel(): void
    {
        if (self::$tabelSiap) {
            return;
        }
        Database::pdo()->exec('CREATE TABLE IF NOT EXISTS berkas_tersimpan (
            subfolder   varchar(40)  NOT NULL,
            nama        varchar(255) NOT NULL,
            isi         bytea        NOT NULL,
            ukuran      integer      NOT NULL DEFAULT 0,
            dibuat_pada timestamptz  NOT NULL DEFAULT now(),
            PRIMARY KEY (subfolder, nama)
        )');
        self::$tabelSiap = true;
    }

    private static function lokal(string $subfolder, string $nama): string
    {
        $cfg = require __DIR__ . '/../config/config.php';
        return rtrim($cfg['upload_dir'], '/') . '/' . $subfolder . '/' . basename($nama);
    }

    /** Simpan salinan berkas yang baru ditulis ke /tmp. */
    public static function simpan(string $subfolder, string $nama, string $pathLokal): void
    {
        if (!self::aktif() || !is_file($pathLokal)) {
            return;
        }
        self::siapkanTabel();
        $fp = fopen($pathLokal, 'rb');
        $st = Database::pdo()->prepare(
            'INSERT INTO berkas_tersimpan (subfolder, nama, isi, ukuran) VALUES (?, ?, ?, ?)
             ON CONFLICT (subfolder, nama) DO UPDATE SET isi = EXCLUDED.isi, ukuran = EXCLUDED.ukuran, dibuat_pada = now()'
        );
        $st->bindValue(1, $subfolder);
        $st->bindValue(2, basename($nama));
        $st->bindValue(3, $fp, \PDO::PARAM_LOB);
        $st->bindValue(4, (int) filesize($pathLokal), \PDO::PARAM_INT);
        $st->execute();
        fclose($fp);
    }

    /**
     * Jalur berkas yang siap dibaca. Urutan: /tmp server ini → berkas bawaan proyek
     * (data demo) → pulihkan dari database. Bila tidak ada di mana pun, jalur /tmp
     * dikembalikan (is_file() akan false, sama seperti berkas yang hilang biasa).
     */
    public static function pastikanLokal(string $subfolder, string $nama): string
    {
        $path = self::lokal($subfolder, $nama);
        if (is_file($path)) {
            return $path;
        }
        $cfg = require __DIR__ . '/../config/config.php';
        $bawaan = rtrim($cfg['upload_dir_bawaan'], '/') . '/' . $subfolder . '/' . basename($nama);
        if (is_file($bawaan)) {
            return $bawaan;
        }
        if (!self::aktif() || basename($nama) === '') {
            return $path;
        }
        self::siapkanTabel();
        $st = Database::pdo()->prepare('SELECT isi FROM berkas_tersimpan WHERE subfolder = ? AND nama = ?');
        $st->execute([$subfolder, basename($nama)]);
        $isi = $st->fetchColumn();
        if ($isi === false) {
            return $path;
        }
        $data = is_resource($isi) ? stream_get_contents($isi) : (string) $isi;
        if (!is_dir(dirname($path))) {
            @mkdir(dirname($path), 0755, true);
        }
        @file_put_contents($path, $data, LOCK_EX);
        return $path;
    }

    public static function hapus(string $subfolder, string $nama): void
    {
        if (!self::aktif()) {
            return;
        }
        self::siapkanTabel();
        Database::execute('DELETE FROM berkas_tersimpan WHERE subfolder = ? AND nama = ?', [$subfolder, basename($nama)]);
    }

    /** Berkas sementara (formulir gagal) yang sudah lewat 2 jam. */
    public static function bersihkanSementara(int $umurDetik): void
    {
        if (!self::aktif()) {
            return;
        }
        self::siapkanTabel();
        Database::execute("DELETE FROM berkas_tersimpan WHERE subfolder = '_sementara' AND dibuat_pada < now() - make_interval(secs => ?)", [$umurDetik]);
    }
}
