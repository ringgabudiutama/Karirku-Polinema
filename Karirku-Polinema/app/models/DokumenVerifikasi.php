<?php
// ===== BACKEND · MODEL · DokumenVerifikasi (tabel dokumen_verifikasi) ====

class DokumenVerifikasi extends Model
{
    protected string $tabel = 'dokumen_verifikasi';

    public function tambah(int $penggunaId, string $tipe, string $file, int $ukuranKb): int
    {
        return $this->simpan([
            'pengguna_id' => $penggunaId,
            'tipe'        => $tipe,
            'file'        => $file,
            'ukuran_kb'   => $ukuranKb,
        ]);
    }

    public function semuaMilik(int $penggunaId): array
    {
        return Database::fetchAll(
            'SELECT * FROM dokumen_verifikasi WHERE pengguna_id = ? ORDER BY diunggah_pada DESC',
            [$penggunaId]
        );
    }

    public function terbaruPerTipe(int $penggunaId): array
    {
        return Database::fetchAll(
            'SELECT DISTINCT ON (tipe) *
             FROM dokumen_verifikasi
             WHERE pengguna_id = ?
             ORDER BY tipe, diunggah_pada DESC',
            [$penggunaId]
        );
    }
}
