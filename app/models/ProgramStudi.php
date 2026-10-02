<?php
/**
 * Model tabel program_studi
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 */

class ProgramStudi extends Model
{
    protected string $tabel = 'program_studi';

    public function berdasarkanJurusan(int $jurusanId): array
    {
        return Database::fetchAll(
            'SELECT * FROM program_studi WHERE jurusan_id = ? ORDER BY jenjang, nama',
            [$jurusanId]
        );
    }

    public function semuaDenganJurusan(): array
    {
        return Database::fetchAll(
            'SELECT ps.*, j.nama AS nama_jurusan
             FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
             ORDER BY j.nama, ps.jenjang, ps.nama'
        );
    }
}
