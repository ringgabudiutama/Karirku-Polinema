<?php
// ===== BACKEND · MODEL · Interview (tabel interview) =================

class Interview extends Model
{
    protected string $tabel = 'interview';

    // --- Baca data ---------------------------------------------------
    public function untukLamaran(int $lamaranId): ?array
    {
        return $this->satuBerdasarkan('lamaran_id', $lamaranId);
    }

    // --- Tulis data --------------------------------------------------
    public function jadwalkan(int $lamaranId, array $d): void
    {
        $luring = ($d['mode'] ?? '') === 'luring';
        $nol    = static fn($v) => ($v ?? '') !== '' ? $v : null;

        Database::execute(
            'INSERT INTO interview
                (lamaran_id, tanggal, jam, mode, lokasi_tautan, catatan,
                 tempat, ruangan, dresscode, yang_dibawa, narahubung)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT (lamaran_id) DO UPDATE SET
                tanggal = EXCLUDED.tanggal, jam = EXCLUDED.jam, mode = EXCLUDED.mode,
                lokasi_tautan = EXCLUDED.lokasi_tautan, catatan = EXCLUDED.catatan,
                tempat = EXCLUDED.tempat, ruangan = EXCLUDED.ruangan,
                dresscode = EXCLUDED.dresscode, yang_dibawa = EXCLUDED.yang_dibawa,
                narahubung = EXCLUDED.narahubung',
            [
                $lamaranId,
                $d['tanggal'],
                $d['jam'],
                $d['mode'],
                $luring ? ($nol($d['tempat'] ?? '') ?? '-') : ($d['lokasi_tautan'] ?: '-'),
                $nol($d['catatan'] ?? ''),
                $luring ? $nol($d['tempat'] ?? '')      : null,
                $luring ? $nol($d['ruangan'] ?? '')     : null,
                $luring ? $nol($d['dresscode'] ?? '')   : null,
                $luring ? $nol($d['yang_dibawa'] ?? '') : null,
                $luring ? $nol($d['narahubung'] ?? '')  : null,
            ]
        );
    }

    // --- Format tampilan ---------------------------------------------
    public static function rincian(array $iv): array
    {
        $baris = [];
        $tgl = isset($iv['tanggal']) ? tanggalIndo($iv['tanggal']) : '';
        $jam = isset($iv['jam']) ? substr((string) $iv['jam'], 0, 5) : '';
        $baris[] = ['Waktu', trim($tgl . ($jam ? ', pukul ' . $jam . ' WIB' : ''))];
        $baris[] = ['Mode', ($iv['mode'] ?? '') === 'luring' ? 'Luring (datang langsung)' : 'Daring (online)'];

        if (($iv['mode'] ?? '') === 'luring') {
            if (!empty($iv['tempat']))      $baris[] = ['Tempat', $iv['tempat']];
            if (!empty($iv['ruangan']))     $baris[] = ['Ruangan', $iv['ruangan']];
            if (!empty($iv['dresscode']))   $baris[] = ['Pakaian', $iv['dresscode']];
            if (!empty($iv['yang_dibawa'])) $baris[] = ['Yang dibawa', $iv['yang_dibawa']];
            if (!empty($iv['narahubung']))  $baris[] = ['Narahubung', $iv['narahubung']];
        } elseif (!empty($iv['lokasi_tautan']) && $iv['lokasi_tautan'] !== '-') {
            $baris[] = ['Tautan', $iv['lokasi_tautan']];
        }

        if (!empty($iv['catatan'])) $baris[] = ['Catatan', $iv['catatan']];
        return $baris;
    }
}
