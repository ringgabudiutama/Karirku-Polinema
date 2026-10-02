<?php
/**
 * Model induk
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * Menyediakan CRUD dasar yang dipakai semua model anak (cari, semua, simpan,
 * ubah, hapus). Model anak menambahkan query khusus tabelnya sendiri di atas
 * fondasi ini (lihat app/models/*.php).
 *
 * Model dengan primary key komposit (mahasiswa_skill, lowongan_jurusan,
 * lowongan_disimpan) TIDAK memakai cari()/ubah()/hapus() di sini karena
 * method itu mengasumsikan satu kolom PK bernama $primaryKey; model tersebut
 * menulis query sendiri secara langsung.
 */

abstract class Model
{
    protected string $tabel = '';
    protected string $primaryKey = 'id';

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

    /** Cari banyak baris berdasarkan satu kolom, contoh: $model->cariBerdasarkan('pengguna_id', 5) */
    public function cariBerdasarkan(string $kolom, $nilai): array
    {
        $sql = "SELECT * FROM {$this->tabel} WHERE {$kolom} = ?";
        return Database::fetchAll($sql, [$nilai]);
    }

    /** Cari SATU baris berdasarkan satu kolom, contoh: $model->satuBerdasarkan('email', $email) */
    public function satuBerdasarkan(string $kolom, $nilai): ?array
    {
        $sql = "SELECT * FROM {$this->tabel} WHERE {$kolom} = ?";
        return Database::fetch($sql, [$nilai]);
    }

    /**
     * Simpan baris baru. $data adalah array asosiatif kolom => nilai.
     * Mengembalikan id baris baru (memakai RETURNING, cara yang benar di
     * PostgreSQL, karena lastInsertId() bawaan PDO tidak selalu akurat
     * untuk kolom serial).
     */
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

    public function hitung(string $where = '1=1', array $params = []): int
    {
        $sql = "SELECT COUNT(*) AS jumlah FROM {$this->tabel} WHERE {$where}";
        $baris = Database::fetch($sql, $params);
        return (int) ($baris['jumlah'] ?? 0);
    }
}
