<?php
/**
 * Penyusun tautan wa.me
 * PIC   : Aqillah (UI/UX, Frontend, dan Integrasi)
 * Status: DIISI.
 *
 * Tautan wa.me hanya bisa mengisi TEKS pesan, tidak bisa mengirim gambar
 * pamflet secara otomatis (batasan resmi WhatsApp untuk tautan tanpa API
 * berbayar). Karena itu pamflet disampaikan lewat tiga cara terpisah di
 * halaman pratinjau info loker: gambar pratinjau tautan (meta Open Graph),
 * tombol unduh, dan tombol salin gambar.
 */

class WhatsappService
{
    /**
     * Ganti kata kunci {posisi}, {perusahaan}, {lokasi}, {deadline}, {tautan}
     * (dan {jurusan} bila admin menambahkannya sendiri di template) pada
     * template pesan dengan data lowongan & jurusan yang sesungguhnya.
     */
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

    /** Bikin URL wa.me lengkap. Nomor dirapikan ke format 62xxxxxxxxxx tanpa spasi/tanda. */
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