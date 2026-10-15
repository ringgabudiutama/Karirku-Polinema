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
            $dsn = sprintf('pgsql:host=%s;port=%s;dbname=%s', $cfg['host'], $cfg['port'], $cfg['nama']);

            try {
                self::$pdo = new \PDO($dsn, $cfg['user'], $cfg['pass'], [
                    \PDO::ATTR_ERRMODE            => \PDO::ERRMODE_EXCEPTION,
                    \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
                    \PDO::ATTR_EMULATE_PREPARES   => false,
                ]);
            } catch (\PDOException $e) {
                $appCfg = require __DIR__ . '/../config/config.php';
                if ($appCfg['debug']) {
                    die('Koneksi database gagal: ' . $e->getMessage());
                }
                die('Terjadi gangguan pada server. Silakan coba lagi nanti.');
            }
        }

        return self::$pdo;
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

    // --- Transaksi ---------------------------------------------------
    public static function beginTransaction(): bool
    {
        return self::pdo()->beginTransaction();
    }

    public static function commit(): bool
    {
        return self::pdo()->commit();
    }

    public static function rollBack(): bool
    {
        return self::pdo()->rollBack();
    }

    public static function inTransaction(): bool
    {
        return self::pdo()->inTransaction();
    }
}
