<?php
// ===== BACKEND · CORE · Database (PDO PostgreSQL) ====================

class Database
{
    private static ?\PDO $pdo = null;

    // --- Koneksi -----------------------------------------------------
    public static function pdo(): \PDO
    {
        if (self::$pdo === null) {
            $cfg = require __DIR__ . '/../config/database.php';
            $dsn = sprintf('pgsql:host=%s;port=%s;dbname=%s;sslmode=%s', $cfg['host'], $cfg['port'], $cfg['nama'], $cfg['sslmode'] ?? 'prefer');

            try {
                self::$pdo = new \PDO($dsn, $cfg['user'], $cfg['pass'], [
                    \PDO::ATTR_ERRMODE            => \PDO::ERRMODE_EXCEPTION,
                    \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
                    \PDO::ATTR_EMULATE_PREPARES   => false,
                    \PDO::ATTR_PERSISTENT         => !empty($cfg['persisten']),
                ]);
                if (!empty($cfg['persisten'])) {
                    // Koneksi bekas permintaan lain: buang transaksi yang menggantung, kunci,
                    // dan pengaturan sesi sebelum dipakai (sama seperti server_reset_query PgBouncer).
                    if (self::$pdo->inTransaction()) {
                        self::$pdo->exec('ROLLBACK');
                    }
                    self::$pdo->exec('DISCARD ALL');
                }
                // Revisi: samakan zona waktu database dengan aplikasi (WIB), supaya
                // now(), CURRENT_DATE, batas lamaran, dan filter tanggal tidak meleset 7 jam.
                $zona = (require __DIR__ . '/../config/config.php')['zona_waktu'] ?? 'Asia/Jakarta';
                self::$pdo->exec("SET TIME ZONE '" . str_replace("'", '', $zona) . "'");
                self::pastikanSkemaTerbaru(self::$pdo, $cfg);
            } catch (\PDOException $e) {
                $appCfg = require __DIR__ . '/../config/config.php';
                // Alasan sebenarnya hanya masuk log server (untuk pengelola), tidak ke layar pengunjung.
                error_log('[KarirKu] Koneksi database gagal: ' . $e->getMessage());
                http_response_code(503);   // 503 = layanan sementara tidak tersedia (terbaca oleh pemantau uptime)
                if ($appCfg['debug']) {
                    die('Koneksi database gagal: ' . $e->getMessage());
                }
                die('Terjadi gangguan pada server. Silakan coba lagi nanti.');
            }
        }

        return self::$pdo;
    }

    /**
     * Migrasi otomatis: kalau database masih versi lama (file 03/04/06/07 belum
     * dijalankan), file SQL di folder database/ dijalankan sendiri satu kali,
     * jadi aplikasi tidak error "column ... does not exist".
     * Semua file migrasi aman dijalankan ulang.
     */
    private static function pastikanSkemaTerbaru(\PDO $pdo, array $cfg = []): void
    {
        $sudahTerbaru = static fn(): bool => (bool) $pdo->query(
            "SELECT to_regclass('public.log_aktivitas_admin') IS NOT NULL
                AND EXISTS (SELECT 1 FROM information_schema.columns
                            WHERE table_schema = 'public' AND table_name = 'perusahaan' AND column_name = 'kode_pos')
                AND EXISTS (SELECT 1 FROM information_schema.columns
                            WHERE table_schema = 'public' AND table_name = 'pengguna' AND column_name = 'wajib_ganti_sandi')
                AND EXISTS (SELECT 1 FROM information_schema.columns
                            WHERE table_schema = 'public' AND table_name = 'profil_item' AND column_name = 'detail')
                AND EXISTS (SELECT 1 FROM information_schema.columns
                            WHERE table_schema = 'public' AND table_name = 'admin' AND column_name = 'foto')
                AND EXISTS (SELECT 1 FROM information_schema.columns
                            WHERE table_schema = 'public' AND table_name = 'lowongan' AND column_name = 'search_vector')
                AND to_regclass('public.v_rekap_lamaran') IS NOT NULL
                AND to_regclass('public.percobaan_login') IS NOT NULL
                AND to_regclass('public.idx_lamaran_tanggal') IS NOT NULL"
        )->fetchColumn();
        if ($sudahTerbaru()) {
            return;
        }
        if (array_key_exists('migrasi_otomatis', $cfg) && !$cfg['migrasi_otomatis']) {
            throw new \PDOException('Skema database belum terbaru dan migrasi otomatis dimatikan (DB_MIGRASI_OTOMATIS=0). '
                . 'Jalankan file database/03, 04, 06, dan 07 sebagai pemilik database, lalu muat ulang halaman.');
        }

        $folder = __DIR__ . '/../../database/';
        $pdo->exec('SELECT pg_advisory_lock(271027)');   // cegah dua request menjalankan bersamaan
        try {
            if ($sudahTerbaru()) {
                return;
            }
            $kosong = !(bool) $pdo->query("SELECT to_regclass('public.pengguna') IS NOT NULL")->fetchColumn();
            $daftar = $kosong
                ? ['01-schema.sql', '02-seed.sql', '03-migrasi-revisi.sql', '04-revisi-dosen.sql', '06-revisi-profil.sql', '05-data-dummy.sql', '07-peningkatan-materi-dosen.sql']
                : ['03-migrasi-revisi.sql', '04-revisi-dosen.sql', '06-revisi-profil.sql', '07-peningkatan-materi-dosen.sql'];
            foreach ($daftar as $f) {
                $sql = @file_get_contents($folder . $f);
                if ($sql === false) {
                    throw new \PDOException('File database/' . $f . ' tidak ditemukan. Jalankan file itu secara manual di pgAdmin.');
                }
                try {
                    $pdo->exec($sql);
                } catch (\PDOException $e) {
                    throw new \PDOException('Migrasi otomatis database/' . $f . ' gagal: ' . $e->getMessage()
                        . ' — jalankan file itu secara manual di pgAdmin (Query Tool).');
                }
            }
        } finally {
            $pdo->exec('SELECT pg_advisory_unlock(271027)');
        }
    }

    // --- Query -------------------------------------------------------
    public static function query(string $sql, array $params = []): \PDOStatement
    {
        $stmt = self::pdo()->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    }

    public static function fetch(string $sql, array $params = []): ?array
    {
        $baris = self::query($sql, $params)->fetch();
        return $baris ?: null;
    }

    public static function fetchAll(string $sql, array $params = []): array
    {
        return self::query($sql, $params)->fetchAll();
    }

    public static function execute(string $sql, array $params = []): int
    {
        return self::query($sql, $params)->rowCount();
    }

    public static function lastInsertId(?string $sequenceOrColumn = null): string
    {
        return self::pdo()->lastInsertId($sequenceOrColumn);
    }

    // --- Transaksi (aman dipanggil bertingkat) -----------------------
    // Model lama memanggil beginTransaction() sendiri. Supaya model itu bisa
    // dipakai di dalam transaksi yang lebih besar, hanya level terluar yang
    // benar-benar membuka/menyimpan transaksi. Rollback di level mana pun
    // membatalkan seluruh transaksi.
    private static int $kedalaman = 0;

    public static function beginTransaction(): bool
    {
        if (self::$kedalaman === 0 && !self::pdo()->inTransaction()) {
            self::pdo()->beginTransaction();
        }
        self::$kedalaman++;
        return true;
    }

    public static function commit(): bool
    {
        if (self::$kedalaman > 0) {
            self::$kedalaman--;
        }
        if (self::$kedalaman === 0 && self::pdo()->inTransaction()) {
            return self::pdo()->commit();
        }
        return true;
    }

    public static function rollBack(): bool
    {
        self::$kedalaman = 0;
        if (self::pdo()->inTransaction()) {
            return self::pdo()->rollBack();
        }
        return true;
    }

    public static function inTransaction(): bool
    {
        return self::pdo()->inTransaction();
    }

    /** Sama seperti inTransaction() tetapi tidak membuka koneksi baru. */
    public static function inTransactionAman(): bool
    {
        return self::$pdo !== null && self::$pdo->inTransaction();
    }

    /**
     * Jalankan $fn di dalam satu transaksi. Exception apa pun membatalkan
     * seluruh perubahan (termasuk perubahan dari transaksi di luarnya).
     */
    public static function transaksi(callable $fn)
    {
        self::beginTransaction();
        try {
            $hasil = $fn();
            self::commit();
            return $hasil;
        } catch (\Throwable $e) {
            self::rollBack();
            throw $e;
        }
    }
}
