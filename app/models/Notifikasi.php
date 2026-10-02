<?php
/**
 * Model tabel notifikasi
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 */

class Notifikasi extends Model
{
    protected string $tabel = 'notifikasi';

    public function buat(int $penggunaId, string $tipe, string $judul, string $pesan, ?string $tautan = null): int
    {
        return $this->simpan([
            'pengguna_id' => $penggunaId,
            'tipe'        => $tipe,
            'judul'       => $judul,
            'pesan'       => $pesan,
            'tautan'      => $tautan,
        ]);
    }

    public function milikPengguna(int $penggunaId, int $limit = 50): array
    {
        return Database::fetchAll(
            'SELECT * FROM notifikasi WHERE pengguna_id = ? ORDER BY dibuat_pada DESC LIMIT ' . (int) $limit,
            [$penggunaId]
        );
    }

    public function jumlahBelumDibaca(int $penggunaId): int
    {
        return jumlahNotifBelumDibaca($penggunaId);
    }

    public function tandaiDibaca(int $id, int $penggunaId): void
    {
        // syarat pengguna_id memastikan orang tidak bisa menandai notifikasi milik orang lain
        Database::execute('UPDATE notifikasi SET dibaca = TRUE WHERE id = ? AND pengguna_id = ?', [$id, $penggunaId]);
    }

    public function tandaiSemuaDibaca(int $penggunaId): void
    {
        Database::execute('UPDATE notifikasi SET dibaca = TRUE WHERE pengguna_id = ?', [$penggunaId]);
    }
}
