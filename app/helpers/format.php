<?php
// ===== BACKEND · HELPER · Format tampilan ============================

// --- Tanggal ---------------------------------------------------------
function tanggalIndo(?string $tgl): string
{
    if (!$tgl) {
        return '-';
    }
    $bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    $ts = strtotime($tgl);
    return date('j', $ts) . ' ' . $bulan[(int) date('n', $ts)] . ' ' . date('Y', $ts);
}

function tanggalWaktuIndo(?string $tgl): string
{
    if (!$tgl) {
        return '-';
    }
    return tanggalIndo($tgl) . ', ' . date('H:i', strtotime($tgl));
}

function sisaHari(string $tanggal): int
{
    $sekarang = new DateTime('today');
    $target = new DateTime($tanggal);
    return (int) $sekarang->diff($target)->format('%r%a');
}

// --- Label & badge status --------------------------------------------
function labelStatusAkun(string $status): array
{
    $peta = [
        'menunggu'  => 'Menunggu Verifikasi',
        'perbaikan' => 'Perlu Perbaikan',
        'ditolak'   => 'Ditolak',
        'aktif'     => 'Aktif',
        'nonaktif'  => 'Dinonaktifkan',
    ];
    return [$peta[$status] ?? ucfirst($status), $status];
}

function labelStatusLamaran(string $status): array
{
    $peta = [
        'diajukan'   => 'Diajukan',
        'screening'  => 'Screening CV',
        'interview'  => 'Interview',
        'diterima'   => 'Diterima',
        'ditolak'    => 'Ditolak',
        'dibatalkan' => 'Dibatalkan',
    ];
    return [$peta[$status] ?? ucfirst($status), $status];
}

function labelStatusLowongan(string $status): array
{
    $peta = [
        'aktif'    => 'Aktif',
        'ditutup'  => 'Ditutup',
        'nonaktif' => 'Dinonaktifkan',
    ];
    return [$peta[$status] ?? ucfirst($status), $status];
}

function badgeHtml(array $labelStatus): string
{
    [$label, $statusMentah] = $labelStatus;
    return '<span class="pill p-' . e($statusMentah) . '">' . e($label) . '</span>';
}

// --- Teks ------------------------------------------------------------
function formatRupiah(?string $angka): string
{
    if (!$angka || !is_numeric($angka)) {
        return $angka ?: '-';
    }
    return 'Rp' . number_format((float) $angka, 0, ',', '.');
}

function ringkas(string $teks, int $panjang = 120): string
{
    $teks = trim(strip_tags($teks));
    if (mb_strlen($teks) <= $panjang) {
        return $teks;
    }
    return mb_substr($teks, 0, $panjang) . '...';
}

function inisial(string $nama): string
{
    $kata = preg_split('/\s+/', trim($nama));
    $inisial = strtoupper(mb_substr($kata[0] ?? '?', 0, 1));
    if (count($kata) > 1) {
        $inisial .= strtoupper(mb_substr(end($kata), 0, 1));
    }
    return $inisial;
}

// --- Berkas ----------------------------------------------------------
function berkasAda(?string $nama, string ...$folder): bool
{
    if ($nama === null || trim($nama) === '') {
        return false;
    }
    foreach ($folder as $f) {
        if (UploadService::ada($f, $nama)) {
            return true;
        }
    }
    return false;
}

function labelBerkas(?string $nama, string ...$folder): string
{
    if ($nama === null || trim($nama) === '') {
        return 'Belum diunggah';
    }
    return berkasAda($nama, ...$folder) ? 'Sudah tersimpan' : 'Perlu diunggah ulang';
}
