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
            // Neon: sertakan ID endpoint agar tetap tersambung walau pustaka libpq server tidak mengirim SNI
            // (tanpa ini muncul "Endpoint ID is not specified").
            if (preg_match('/^(ep-[a-z0-9-]+?)(-pooler)?\.[a-z0-9.-]+\.neon\.tech$/i', (string) $cfg['host'], $mNeon)) {
                $dsn .= ";options='endpoint=" . $mNeon[1] . "'";
            }

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
                // Petunjuk penyebab (tanpa membuka kata sandi/host) agar pemilik situs bisa memperbaikinya.
                die(self::halamanGangguan(self::penyebabGagal($e->getMessage(), $cfg)));
            }
        }

        return self::$pdo;
    }

    /** Menggolongkan pesan galat koneksi menjadi petunjuk yang aman ditampilkan. */
    private static function penyebabGagal(string $pesan, array $cfg): array
    {
        $adaUrl = (bool) (getenv('DATABASE_URL') ?: getenv('DATABASE_URL_UNPOOLED') ?: getenv('POSTGRES_URL') ?: getenv('POSTGRES_URL_NON_POOLING') ?: getenv('DB_HOST'));
        $p = strtolower($pesan);
        if (!$adaUrl && in_array($cfg['host'] ?? '', ['127.0.0.1', 'localhost'], true) && (getenv('VERCEL') || getenv('KARIRKU_SERVERLESS'))) {
            return ['DB-01', 'Alamat database belum diatur.', 'Di Vercel: Settings → Environment Variables, tambahkan DATABASE_URL (connection string Neon), lalu Deployments → Redeploy.'];
        }
        if (str_contains($p, 'migrasi otomatis')) {
            return ['DB-07', 'Database tersambung, tetapi pemasangan tabel otomatis gagal.', 'Buka Logs di Vercel dan cari "[KarirKu]" untuk melihat file SQL yang gagal, atau jalankan database/00-INSTAL-ULANG.sql di SQL Editor Neon.'];
        }
        if (str_contains($p, 'password authentication failed') || str_contains($p, 'authentication')) {
            return ['DB-02', 'Nama pengguna atau kata sandi database ditolak.', 'Salin ulang connection string dari Neon (tombol Copy), tempel ke DATABASE_URL, lalu Redeploy.'];
        }
        if (str_contains($p, 'endpoint id') || str_contains($p, 'sni')) {
            return ['DB-03', 'Server database meminta ID endpoint.', 'Pastikan DATABASE_URL memakai alamat host asli dari Neon (ep-....neon.tech), lalu Redeploy.'];
        }
        if (str_contains($p, 'could not translate host name') || str_contains($p, 'name or service not known') || str_contains($p, 'nodename nor servname')) {
            return ['DB-04', 'Alamat host database tidak ditemukan.', 'Periksa ejaan host di DATABASE_URL. Bila memakai Supabase, gunakan alamat "Session pooler" (bukan "Direct connection" yang hanya IPv6).'];
        }
        if (str_contains($p, 'does not exist')) {
            return ['DB-05', 'Nama database di alamat koneksi tidak ada.', 'Periksa bagian nama database di akhir DATABASE_URL (Neon: biasanya neondb).'];
        }
        if (str_contains($p, 'ssl')) {
            return ['DB-06', 'Koneksi aman (SSL) ke database gagal.', 'Pastikan DATABASE_URL diakhiri ?sslmode=require, lalu Redeploy.'];
        }
        return ['DB-08', 'Server database tidak bisa dihubungi.', 'Periksa DATABASE_URL dan pastikan database Neon aktif (tidak dihapus). Bila memakai Supabase, gunakan alamat "Session pooler".'];
    }

    private static function halamanGangguan(array $p): string
    {
        [$kode, $judul, $saran] = $p;
        $h = static fn(string $t): string => htmlspecialchars($t, ENT_QUOTES, 'UTF-8');
        return '<!DOCTYPE html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
            . '<title>Gangguan server | KarirKu Polinema</title><style>body{font-family:system-ui,Segoe UI,Roboto,sans-serif;background:#f3f6fb;color:#16233a;margin:0;display:grid;place-items:center;min-height:100vh;padding:20px;box-sizing:border-box}'
            . '.k{background:#fff;border-radius:18px;box-shadow:0 0 0 1px #e1e8f2,0 12px 30px rgba(10,38,86,.08);padding:28px;max-width:460px}h1{font-size:20px;margin:0 0 8px}p{margin:0 0 12px;line-height:1.55;color:#5a6a82}'
            . '.s{background:#f4f7fc;border-radius:12px;padding:12px 14px;color:#16233a;font-size:14px}code{font-size:12px;color:#5a6a82}</style></head><body><div class="k">'
            . '<h1>Terjadi gangguan pada server</h1><p>Silakan coba lagi nanti. Bila Anda pengelola situs:</p>'
            . '<div class="s"><b>' . $h($judul) . '</b><br>' . $h($saran) . '</div><p style="margin-top:12px"><code>Kode: ' . $h($kode) . '</code></p></div></body></html>';
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
