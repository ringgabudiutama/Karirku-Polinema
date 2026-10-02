<?php
/**
 * Model tabel verifikasi_akun
 * PIC   : Aqillah (UI/UX, Frontend, dan Integrasi)
 * Status: DIISI.
 */

class VerifikasiAkun extends Model
{
    protected string $tabel = 'verifikasi_akun';

    public function riwayatUntuk(int $penggunaId): array
    {
        return Database::fetchAll(
            'SELECT va.*, a.nama AS nama_admin
             FROM verifikasi_akun va JOIN admin a ON a.id = va.admin_id
             WHERE va.pengguna_id = ? ORDER BY va.tanggal DESC',
            [$penggunaId]
        );
    }

    /**
     * Simpan satu keputusan + perbarui status_akun pengguna, dalam SATU
     * transaksi supaya baris riwayat dan status akun tidak pernah beda.
     * $keputusan salah satu dari: disetujui, perbaikan, ditolak, nonaktif, aktif.
     */
    public function putuskan(int $penggunaId, int $adminId, string $keputusan, ?string $catatan): void
    {
        $petaStatus = [
            'disetujui' => 'aktif',
            'perbaikan' => 'perbaikan',
            'ditolak'   => 'ditolak',
            'nonaktif'  => 'nonaktif',
            'aktif'     => 'aktif',
        ];
        if (!isset($petaStatus[$keputusan])) {
            throw new InvalidArgumentException('Keputusan tidak dikenal: ' . $keputusan);
        }
        // aturan sama seperti CHECK di database/01-schema.sql: keputusan selain
        // disetujui/aktif wajib punya catatan.
        if (!in_array($keputusan, ['disetujui', 'aktif'], true) && !validasiWajibIsi((string) $catatan)) {
            throw new InvalidArgumentException('Catatan wajib diisi untuk keputusan ini.');
        }

        Database::beginTransaction();
        try {
            $this->simpan([
                'pengguna_id' => $penggunaId,
                'admin_id'    => $adminId,
                'keputusan'   => $keputusan,
                'catatan'     => $catatan,
            ]);
            Database::execute('UPDATE pengguna SET status_akun = ? WHERE id = ?', [$petaStatus[$keputusan], $penggunaId]);
            Database::commit();
        } catch (Throwable $e) {
            Database::rollBack();
            throw $e;
        }
    }
}
