<?php
// ===== BACKEND · SERVICE · WhatsApp ==================================

class WhatsappService
{
    // --- Pesan -------------------------------------------------------
    public static function susunPesan(string $template, array $lowongan, string $namaJurusan, string $tautanPratinjau): string
    {
        $pengganti = [
            '{jurusan}'     => $namaJurusan,
            '{perusahaan}'  => $lowongan['nama_perusahaan'],
            '{posisi}'      => $lowongan['posisi'],
            '{lokasi}'      => $lowongan['lokasi'] ?? '',
            '{deadline}'    => tanggalIndo($lowongan['batas_lamaran']),
            '{batas_lamar}' => tanggalIndo($lowongan['batas_lamaran']),
            '{tautan}'      => $tautanPratinjau,
        ];
        return strtr($template, $pengganti);
    }

    // --- Nomor & tautan ----------------------------------------------
    public static function buatTautan(string $nomorWa, string $pesan): string
    {
        $nomor = self::rapikanNomor($nomorWa);
        return 'https://wa.me/' . $nomor . '?text=' . rawurlencode($pesan);
    }

    public static function rapikanNomor(string $nomor): string
    {
        $bersih = preg_replace('/[^0-9]/', '', $nomor);
        if (str_starts_with($bersih, '0')) {
            $bersih = '62' . substr($bersih, 1);
        }
        return $bersih;
    }

    public static function nomorValid(?string $nomor): bool
    {
        return !empty($nomor) && strlen(self::rapikanNomor($nomor)) >= 10;
    }
}
