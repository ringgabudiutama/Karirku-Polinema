<?php
/**
 * Model tabel admin
 * PIC   : Atha Rasya Farras (Modul Operator dan Career Center)
 * Status: DIISI.
 */

class Admin extends Model
{
    protected string $tabel = 'admin';

    public function cariByPenggunaId(int $penggunaId): ?array
    {
        return $this->satuBerdasarkan('pengguna_id', $penggunaId);
    }

    public function idDariPenggunaId(int $penggunaId): ?int
    {
        $baris = $this->cariByPenggunaId($penggunaId);
        return $baris ? (int) $baris['id'] : null;
    }
}
