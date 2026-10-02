<?php
/**
 * Model tabel dokumen_verifikasi
 * PIC   : Aqillah (UI/UX, Frontend, dan Integrasi)
 * Status: DIISI.
 *
 * Tabel ini tidak punya kolom "versi aktif": setiap kali pendaftar unggah
 * ulang (alur Perbaiki Data), baris BARU ditambahkan, baris lama tetap
 * tersimpan sebagai riwayat. Yang dipakai Admin untuk menilai adalah
 * dokumen dengan diunggah_pada TERBARU per tipe (lihat terbaruPerTipe()).
 */

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

    /** Satu dokumen terbaru untuk tiap tipe (dipakai di halaman Detail Pendaftar Admin). */
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
