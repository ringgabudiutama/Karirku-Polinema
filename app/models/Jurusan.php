<?php
/**
 * Model tabel jurusan
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 */

class Jurusan extends Model
{
    protected string $tabel = 'jurusan';

    public function semuaUrut(): array
    {
        return Database::fetchAll('SELECT * FROM jurusan ORDER BY nama');
    }
}
