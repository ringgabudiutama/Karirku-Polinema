<?php
// ===== BACKEND · MODEL · Jurusan (tabel jurusan) =====================

class Jurusan extends Model
{
    protected string $tabel = 'jurusan';

    public function semuaUrut(): array
    {
        return Database::fetchAll('SELECT * FROM jurusan ORDER BY nama');
    }
}
