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
        'menunggu' => 'Menunggu Persetujuan',
        'revisi'   => 'Perlu Revisi',
        'ditolak'  => 'Ditolak',
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


/**
 * Pesan error database (SQLSTATE ...) tidak boleh tampil apa adanya ke pengguna.
 * Diterjemahkan menjadi kalimat yang jelas; pesan asli tetap dicatat di log server.
 */
function pesanRamah(string $pesan): string
{
    if (stripos($pesan, 'SQLSTATE') === false && stripos($pesan, 'PDOException') === false) {
        return $pesan;
    }
    error_log('[KarirKu] pesan database disaring: ' . $pesan);
    $peta = [
        '23505' => 'Data yang sama sudah tersimpan sebelumnya (misalnya email, NIM, atau data ganda). Periksa kembali isian Anda.',
        '23514' => 'Ada isian yang tidak sesuai aturan, misalnya tanggal selesai lebih awal dari tanggal mulai atau angka di luar batas. Periksa kembali isian Anda.',
        '23502' => 'Ada kolom wajib yang masih kosong. Lengkapi lalu kirim ulang.',
        '23503' => 'Data yang dipilih tidak ditemukan atau sudah dihapus. Muat ulang halaman lalu coba lagi.',
        '22001' => 'Ada isian yang terlalu panjang. Persingkat lalu kirim ulang.',
        '22007' => 'Format tanggal atau jam tidak valid.',
        '22008' => 'Tanggal di luar jangkauan yang diizinkan.',
        '22P02' => 'Ada isian dengan format tidak valid (misalnya huruf di kolom angka).',
        '22003' => 'Angka yang diisi terlalu besar.',
        '40001' => 'Data sedang diubah pengguna lain bersamaan. Coba kirim ulang.',
        '40P01' => 'Data sedang diubah pengguna lain bersamaan. Coba kirim ulang.',
        '42703' => 'Struktur database belum diperbarui. Muat ulang halaman; bila masih terjadi, jalankan database/04-revisi-dosen.sql.',
        '42P01' => 'Struktur database belum lengkap. Jalankan database/00-INSTAL-ULANG.sql atau 03 dan 04.',
    ];
    if (preg_match('/SQLSTATE\[([0-9A-Z]{5})\]/', $pesan, $m) && isset($peta[$m[1]])) {
        return $peta[$m[1]];
    }
    return 'Data belum bisa disimpan karena gangguan sistem. Isian Anda aman; silakan kirim ulang.';
}
