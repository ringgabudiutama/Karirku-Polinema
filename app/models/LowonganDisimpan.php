<?php
/**
 * Model tabel lowongan_disimpan
 * PIC   : Muhamad Nafi' Hanif (Modul Mahasiswa dan Alumni)
 * Status: DIISI.
 * Primary key komposit (mahasiswa_id, lowongan_id), jadi TIDAK memakai
 * cari()/ubah()/hapus() bawaan Model induk yang mengasumsikan satu kolom id.
 */

class LowonganDisimpan extends Model
{
    protected string $tabel = 'lowongan_disimpan';

    public function simpanBookmark(int $mahasiswaId, int $lowonganId): void
    {
        Database::execute(
            'INSERT INTO lowongan_disimpan (mahasiswa_id, lowongan_id) VALUES (?, ?)
             ON CONFLICT DO NOTHING',
            [$mahasiswaId, $lowonganId]
        );
    }

    public function batalBookmark(int $mahasiswaId, int $lowonganId): void
    {
        Database::execute(
            'DELETE FROM lowongan_disimpan WHERE mahasiswa_id = ? AND lowongan_id = ?',
            [$mahasiswaId, $lowonganId]
        );
    }

    public function sudahDisimpan(int $mahasiswaId, int $lowonganId): bool
    {
        return Database::fetch(
            'SELECT 1 FROM lowongan_disimpan WHERE mahasiswa_id = ? AND lowongan_id = ?',
            [$mahasiswaId, $lowonganId]
        ) !== null;
    }

    public function daftarMilik(int $mahasiswaId): array
    {
        return Database::fetchAll(
            'SELECT l.*, pr.nama_perusahaan, pr.logo, ld.dibuat_pada AS disimpan_pada
             FROM lowongan_disimpan ld
             JOIN lowongan l ON l.id = ld.lowongan_id
             JOIN perusahaan pr ON pr.id = l.perusahaan_id
             WHERE ld.mahasiswa_id = ?
             ORDER BY ld.dibuat_pada DESC',
            [$mahasiswaId]
        );
    }

    public function hitungMilik(int $mahasiswaId): int
    {
        $baris = Database::fetch(
            'SELECT COUNT(*) AS jumlah FROM lowongan_disimpan WHERE mahasiswa_id = ?',
            [$mahasiswaId]
        );
        return (int) ($baris['jumlah'] ?? 0);
    }
}
