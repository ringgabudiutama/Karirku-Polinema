<?php
/**
 * Model tabel admin_jurusan_kontak
 * PIC   : Aqillah (UI/UX, Frontend, dan Integrasi)
 * Status: DIISI.
 */

class AdminJurusanKontak extends Model
{
    protected string $tabel = 'admin_jurusan_kontak';

    public function semuaDenganJurusan(): array
    {
        // LEFT JOIN dari jurusan (bukan INNER JOIN dari admin_jurusan_kontak):
        // jurusan yang belum pernah diisi kontaknya tetap harus muncul di
        // tabel Pengaturan > Kontak admin jurusan, dengan nama_kontak/nomor_wa
        // kosong (null), supaya adminnya bisa mengisi lewat baris itu.
        return Database::fetchAll(
            'SELECT j.id AS jurusan_id, j.nama AS nama_jurusan,
                    ajk.nama_kontak, ajk.nomor_wa
             FROM jurusan j LEFT JOIN admin_jurusan_kontak ajk ON ajk.jurusan_id = j.id
             ORDER BY j.nama'
        );
    }

    public function untukJurusan(int $jurusanId): ?array
    {
        return $this->satuBerdasarkan('jurusan_id', $jurusanId);
    }

    public function simpanKontak(int $jurusanId, string $namaKontak, string $nomorWa, int $adminId): void
    {
        Database::execute(
            'INSERT INTO admin_jurusan_kontak (jurusan_id, nama_kontak, nomor_wa, diperbarui_oleh)
             VALUES (?, ?, ?, ?)
             ON CONFLICT (jurusan_id) DO UPDATE SET
                nama_kontak = EXCLUDED.nama_kontak, nomor_wa = EXCLUDED.nomor_wa,
                diperbarui_oleh = EXCLUDED.diperbarui_oleh, diperbarui_pada = now()',
            [$jurusanId, $namaKontak, $nomorWa, $adminId]
        );
    }
}