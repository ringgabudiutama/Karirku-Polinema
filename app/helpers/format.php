<?php
/**
 * Fungsi bantu tampilan
 * PIC   : Ringga Budi Utama (Project Lead, UI/UX, dan Frontend)
 * Status: DIISI (silakan sesuaikan kelas CSS-nya kalau nama classnya beda).
 */

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

/** Positif = masih berapa hari lagi, negatif = sudah lewat berapa hari. */
function sisaHari(string $tanggal): int
{
    $sekarang = new DateTime('today');
    $target = new DateTime($tanggal);
    return (int) $sekarang->diff($target)->format('%r%a');
}

/** [label tampilan, nama warna] untuk status_akun pada tabel pengguna. */
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

/** [label tampilan, status mentah] untuk status pada tabel lamaran. Status mentah dipakai sebagai kelas warna .p-xxx di style.css. */
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

/** [label tampilan, status mentah] untuk status pada tabel lowongan. */
function labelStatusLowongan(string $status): array
{
    $peta = [
        'aktif'    => 'Aktif',
        'ditutup'  => 'Ditutup',
        'nonaktif' => 'Dinonaktifkan',
    ];
    return [$peta[$status] ?? ucfirst($status), $status];
}

/** Cetak <span class="pill p-xxx">label</span>, memakai kelas warna .p-xxx yang sudah ada di style.css. */
function badgeHtml(array $labelStatus): string
{
    [$label, $statusMentah] = $labelStatus;
    return '<span class="pill p-' . e($statusMentah) . '">' . e($label) . '</span>';
}

function formatRupiah(?string $angka): string
{
    if (!$angka || !is_numeric($angka)) {
        return $angka ?: '-';
    }
    return 'Rp' . number_format((float) $angka, 0, ',', '.');
}

/** Potong teks panjang untuk ringkasan kartu, tanpa memenggal di tengah kata. */
function ringkas(string $teks, int $panjang = 120): string
{
    $teks = trim(strip_tags($teks));
    if (mb_strlen($teks) <= $panjang) {
        return $teks;
    }
    return mb_substr($teks, 0, $panjang) . '...';
}

/** Inisial 1-2 huruf untuk logo kotak perusahaan yang belum unggah logo. */
function inisial(string $nama): string
{
    $kata = preg_split('/\s+/', trim($nama));
    $inisial = strtoupper(mb_substr($kata[0] ?? '?', 0, 1));
    if (count($kata) > 1) {
        $inisial .= strtoupper(mb_substr(end($kata), 0, 1));
    }
    return $inisial;
}

/**
 * Memeriksa apakah berkas yang tercatat di database benar-benar ada di
 * penyimpanan. Dipakai view supaya tidak menampilkan tombol "Lihat" yang
 * berakhir di halaman "Berkas tidak ditemukan".
 *
 * $folder boleh lebih dari satu, karena KTM dan ijazah memakai satu kolom
 * yang sama tetapi disimpan di folder berbeda.
 */
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

/** Keterangan singkat untuk status satu berkas di layar. */
function labelBerkas(?string $nama, string ...$folder): string
{
    if ($nama === null || trim($nama) === '') {
        return 'Belum diunggah';
    }
    return berkasAda($nama, ...$folder) ? 'Sudah tersimpan' : 'Perlu diunggah ulang';
}
