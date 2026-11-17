<?php
// ===== BACKEND · MODEL · VerifikasiAkun (tabel verifikasi_akun) ======

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
        if (!in_array($keputusan, ['disetujui', 'aktif'], true) && !validasiWajibIsi((string) $catatan)) {
            throw new InvalidArgumentException('Catatan wajib diisi untuk keputusan ini.');
        }

        // Bug #8 & #9: status saat ini dikunci dan dicek di dalam transaksi,
        // sehingga klik ganda tidak mencatat/mengirim email dua kali dan akun
        // yang belum diverifikasi tidak bisa "diaktifkan" melewati pemeriksaan dokumen.
        $statusAsal = [
            'disetujui' => ['menunggu'], 'perbaikan' => ['menunggu'], 'ditolak' => ['menunggu'],
            'nonaktif'  => ['aktif'],    'aktif'     => ['nonaktif'],
        ][$keputusan];

        Database::transaksi(function () use ($penggunaId, $adminId, $keputusan, $catatan, $petaStatus, $statusAsal) {
            $p = Database::fetch('SELECT status_akun, role FROM pengguna WHERE id = ? FOR UPDATE', [$penggunaId]);
            if (!$p || $p['role'] === 'admin') {
                throw new InvalidArgumentException('Akun tidak ditemukan atau tidak bisa diubah.');
            }
            if (!in_array($p['status_akun'], $statusAsal, true)) {
                throw new InvalidArgumentException('Akun ini sudah berstatus "' . labelStatusAkun($p['status_akun'])[0]
                    . '", jadi keputusan tidak disimpan ulang. Muat ulang halaman untuk melihat data terbaru.');
            }
            $this->simpan([
                'pengguna_id' => $penggunaId,
                'admin_id'    => $adminId,
                'keputusan'   => $keputusan,
                'catatan'     => $catatan !== null ? mb_substr($catatan, 0, 500) : null,
            ]);
            Database::execute('UPDATE pengguna SET status_akun = ? WHERE id = ?', [$petaStatus[$keputusan], $penggunaId]);
            if ($keputusan === 'nonaktif') {
                Auth::cabutSemuaSesi($penggunaId);   // revisi J: sesi aktif langsung keluar
            }
        });
    }
}
