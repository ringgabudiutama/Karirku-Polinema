<?php
// ===== BACKEND · MODEL · Notifikasi (tabel notifikasi) ===============

class Notifikasi extends Model
{
    protected string $tabel = 'notifikasi';

    public function buat(int $penggunaId, string $tipe, string $judul, string $pesan, ?string $tautan = null): int
    {
        return $this->simpan([
            'pengguna_id' => $penggunaId,
            'tipe'        => mb_substr($tipe, 0, 30),
            'judul'       => mb_substr($judul, 0, 255),
            'pesan'       => mb_substr($pesan, 0, 500),
            'tautan'      => $tautan,
        ]);
    }

    public function milikPengguna(int $penggunaId, int $limit = 50, int $offset = 0): array
    {
        return Database::fetchAll(
            'SELECT * FROM notifikasi WHERE pengguna_id = ? ORDER BY dibuat_pada DESC, id DESC LIMIT ' . (int) $limit . ' OFFSET ' . (int) $offset,
            [$penggunaId]
        );
    }

    public function hitungMilik(int $penggunaId): int
    {
        return (int) Database::fetch('SELECT COUNT(*) AS n FROM notifikasi WHERE pengguna_id = ?', [$penggunaId])['n'];
    }

    public function jumlahBelumDibaca(int $penggunaId): int
    {
        return jumlahNotifBelumDibaca($penggunaId);
    }

    public function tandaiDibaca(int $id, int $penggunaId): void
    {
        Database::execute('UPDATE notifikasi SET dibaca = TRUE WHERE id = ? AND pengguna_id = ?', [$id, $penggunaId]);
    }

    public function tandaiSemuaDibaca(int $penggunaId): void
    {
        Database::execute('UPDATE notifikasi SET dibaca = TRUE WHERE pengguna_id = ?', [$penggunaId]);
    }
}
