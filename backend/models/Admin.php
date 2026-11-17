<?php
// ===== BACKEND · MODEL · Admin (tabel admin) =========================

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
