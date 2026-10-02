<?php
/**
 * Model tabel riwayat_lamaran
 * PIC   : Muhamad Nafi' Hanif (Modul Mahasiswa dan Alumni)
 * Status: DIISI.
 */

class RiwayatLamaran extends Model
{
    protected string $tabel = 'riwayat_lamaran';

    public function catat(int $lamaranId, string $status, ?int $diubahOleh, ?string $catatan = null): int
    {
        return $this->simpan([
            'lamaran_id'  => $lamaranId,
            'status'      => $status,
            'diubah_oleh' => $diubahOleh,
            'catatan'     => $catatan,
        ]);
    }

    public function untukLamaran(int $lamaranId): array
    {
        return Database::fetchAll(
            'SELECT * FROM riwayat_lamaran WHERE lamaran_id = ? ORDER BY tanggal ASC',
            [$lamaranId]
        );
    }
}
