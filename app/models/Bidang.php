<?php
/**
 * Model tabel bidang
 * PIC   : Muhamad Nafi' Hanif (Modul Mahasiswa dan Alumni)
 * Status: DIISI.
 */

class Bidang extends Model
{
    protected string $tabel = 'bidang';

    public function semuaUrut(): array
    {
        return Database::fetchAll('SELECT * FROM bidang ORDER BY nama');
    }

    /* --------------------- relasi mahasiswa_minat --------------------- */

    public function minatMahasiswa(int $mahasiswaId): array
    {
        return Database::fetchAll(
            'SELECT b.id, b.nama FROM mahasiswa_minat mm
             JOIN bidang b ON b.id = mm.bidang_id
             WHERE mm.mahasiswa_id = ? ORDER BY b.nama',
            [$mahasiswaId]
        );
    }

    public function setMinatMahasiswa(int $mahasiswaId, array $bidangIds): void
    {
        Database::beginTransaction();
        try {
            Database::execute('DELETE FROM mahasiswa_minat WHERE mahasiswa_id = ?', [$mahasiswaId]);
            foreach (array_unique(array_map('intval', $bidangIds)) as $bidangId) {
                Database::execute(
                    'INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) VALUES (?, ?)',
                    [$mahasiswaId, $bidangId]
                );
            }
            Database::commit();
        } catch (Throwable $e) {
            Database::rollBack();
            throw $e;
        }
    }
}
