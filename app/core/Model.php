<?php
// ===== BACKEND · CORE · Model induk (CRUD dasar) =====================

abstract class Model
{
    protected string $tabel = '';
    protected string $primaryKey = 'id';

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
            $sql .= " ORDER BY {$orderBy}";
        }
        return Database::fetchAll($sql);
    }

    public function cariBerdasarkan(string $kolom, $nilai): array
    {
        $sql = "SELECT * FROM {$this->tabel} WHERE {$kolom} = ?";
        return Database::fetchAll($sql, [$nilai]);
    }

    public function satuBerdasarkan(string $kolom, $nilai): ?array
    {
        $sql = "SELECT * FROM {$this->tabel} WHERE {$kolom} = ?";
        return Database::fetch($sql, [$nilai]);
    }

    // --- Tulis data --------------------------------------------------
    public function simpan(array $data): int
    {
        $kolom = array_keys($data);
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
        $set = implode(', ', array_map(fn($k) => "{$k} = ?", array_keys($data)));
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
