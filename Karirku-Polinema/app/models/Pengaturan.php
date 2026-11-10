<?php
// ===== BACKEND · MODEL · Pengaturan (tabel pengaturan) ===============

class Pengaturan extends Model
{
    protected string $tabel = 'pengaturan';

    public function ambil(string $kunci, string $default = ''): string
    {
        $baris = $this->satuBerdasarkan('kunci', $kunci);
        return $baris['nilai'] ?? $default;
    }

    public function simpanNilai(string $kunci, string $nilai, ?int $adminId): void
    {
        Database::execute(
            'INSERT INTO pengaturan (kunci, nilai, diperbarui_oleh) VALUES (?, ?, ?)
             ON CONFLICT (kunci) DO UPDATE SET
                nilai = EXCLUDED.nilai, diperbarui_oleh = EXCLUDED.diperbarui_oleh, diperbarui_pada = now()',
            [$kunci, $nilai, $adminId]
        );
    }

    public function semuaSebagaiPeta(): array
    {
        $peta = [];
        foreach ($this->semua('kunci') as $baris) {
            $peta[$baris['kunci']] = $baris['nilai'];
        }
        return $peta;
    }
}
