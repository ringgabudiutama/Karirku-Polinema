<?php
/**
 * Pembungkus koneksi PDO
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: KERANGKA KOSONG, belum diisi logika.
 *
 * Yang harus dikerjakan:
 *   - Buat koneksi PDO singleton dari config/database.php.
 *   - Sediakan metode query, fetch, fetchAll, execute, beginTransaction, commit, rollBack.
 */

class Database
{
    private static ?\PDO $pdo = null;

    public static function pdo(): \PDO
    {
        // TODO: buat koneksi PDO dan simpan di self::$pdo
        throw new \RuntimeException('Belum diimplementasikan.');
    }
}
