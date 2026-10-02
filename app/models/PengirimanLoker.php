<?php
/**
 * Model tabel pengiriman_loker
 * PIC   : Aqillah (UI/UX, Frontend, dan Integrasi)
 * Status: DIISI.
 */

class PengirimanLoker extends Model
{
    protected string $tabel = 'pengiriman_loker';

    public function sudahDikirim(int $lowonganId, int $jurusanId): bool
    {
        return Database::fetch(
            'SELECT 1 FROM pengiriman_loker WHERE lowongan_id = ? AND jurusan_id = ?',
            [$lowonganId, $jurusanId]
        ) !== null;
    }

    public function catat(int $lowonganId, int $jurusanId, int $adminId): void
    {
        Database::execute(
            'INSERT INTO pengiriman_loker (lowongan_id, jurusan_id, admin_id) VALUES (?, ?, ?)
             ON CONFLICT DO NOTHING',
            [$lowonganId, $jurusanId, $adminId]
        );
    }

    /** Daftar jurusan_id yang SUDAH menerima loker ini, untuk menandai tombol jadi "Terkirim". */
    public function jurusanSudahDikirimUntuk(int $lowonganId): array
    {
        $baris = Database::fetchAll('SELECT jurusan_id FROM pengiriman_loker WHERE lowongan_id = ?', [$lowonganId]);
        return array_column($baris, 'jurusan_id');
    }
}
