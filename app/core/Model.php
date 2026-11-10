<?php
// ===== BACKEND · CORE · Model induk (CRUD dasar) =====================

abstract class Model
{
    protected string $tabel = '';
    protected string $primaryKey = 'id';

    // --- Pengaman nama kolom -----------------------------------------
    // Nilai data selalu lewat placeholder (?). Nama kolom/urutan tidak bisa
    // memakai placeholder, jadi dibatasi huruf/angka/garis bawah saja. Hari ini
    // semua pemanggil memberi nama literal; aturan ini menjaga agar kelak tidak
    // ada yang tanpa sengaja meneruskan input pengguna ke sini (SQL injection).
    private static function idAman(string $nama): string
    {
        if (!preg_match('/^[a-z_][a-z0-9_]*$/i', $nama)) {
            throw new InvalidArgumentException('Nama kolom tidak valid.');
        }
        return $nama;
    }

    private static function urutanAman(string $orderBy): string
    {
        $unit = '[a-z_][a-z0-9_]*(?:\s+(?:ASC|DESC))?';
        if (!preg_match('/^' . $unit . '(?:\s*,\s*' . $unit . ')*$/i', trim($orderBy))) {
            throw new InvalidArgumentException('Urutan tidak valid.');
        }
        return trim($orderBy);
    }

    // --- Baca data ---------------------------------------------------
    public function cari(int $id): ?array
    {
        $sql = "SELECT * FROM {$this->tabel} WHERE {$this->primaryKey} = ?";
        return Database::fetch($sql, [$id]);
    }

    public function semua(string $orderBy = ''): array
    {
        $sql = "SELECT * FROM {$this->tabel}";
        if ($orderBy !== '') {
            $sql .= ' ORDER BY ' . self::urutanAman($orderBy);
        }
        return Database::fetchAll($sql);
    }

    public function cariBerdasarkan(string $kolom, $nilai): array
    {
        $kolom = self::idAman($kolom);
        $sql = "SELECT * FROM {$this->tabel} WHERE {$kolom} = ?";
        return Database::fetchAll($sql, [$nilai]);
    }

    public function satuBerdasarkan(string $kolom, $nilai): ?array
    {
        $kolom = self::idAman($kolom);
        $sql = "SELECT * FROM {$this->tabel} WHERE {$kolom} = ?";
        return Database::fetch($sql, [$nilai]);
    }

    // --- Tulis data --------------------------------------------------
    public function simpan(array $data): int
    {
        $kolom = array_map([self::class, 'idAman'], array_map('strval', array_keys($data)));
        $placeholder = array_fill(0, count($kolom), '?');

        $sql = sprintf(
            'INSERT INTO %s (%s) VALUES (%s) RETURNING %s',
            $this->tabel,
            implode(', ', $kolom),
            implode(', ', $placeholder),
            $this->primaryKey
        );

        $stmt = Database::query($sql, array_values($data));
        return (int) $stmt->fetchColumn();
    }

    public function ubah(int $id, array $data): bool
    {
        $set = implode(', ', array_map(fn($k) => self::idAman((string) $k) . ' = ?', array_keys($data)));
        $sql = "UPDATE {$this->tabel} SET {$set} WHERE {$this->primaryKey} = ?";
        $params = array_values($data);
        $params[] = $id;
        return Database::execute($sql, $params) > 0;
    }

    public function hapus(int $id): bool
    {
        $sql = "DELETE FROM {$this->tabel} WHERE {$this->primaryKey} = ?";
        return Database::execute($sql, [$id]) > 0;
    }

    // --- Hitung ------------------------------------------------------
    public function hitung(string $where = '1=1', array $params = []): int
    {
        $sql = "SELECT COUNT(*) AS jumlah FROM {$this->tabel} WHERE {$where}";
        $baris = Database::fetch($sql, $params);
        return (int) ($baris['jumlah'] ?? 0);
    }
}
