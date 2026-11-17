<?php
// ===== FRONTEND · HELPER · Komponen tampilan yang dipakai banyak halaman ====
// Satu tempat untuk komponen revisi dosen, supaya tampilannya seragam:
//   tombolKembali()  revisi A
//   pamfletHtml()    revisi C
//   paginasiHtml()   revisi H
//   opsiProvinsi()   revisi F
//   chipsAlasan()    revisi K
//   riwayatHtml()    revisi K & M

// --- A. Tombol kembali -----------------------------------------------
/**
 * Tombol "Kembali". Bila halaman sebelumnya berasal dari situs ini, JS
 * memakai riwayat browser (posisi & filter tetap). Bila halaman dibuka
 * langsung (tab baru / tautan WA), tombol membuka $halamanInduk.
 *
 * $selaluKeInduk = true: tombol SELALU membuka $halamanInduk (tautan biasa, tanpa
 * history.back). Dipakai di halaman publik (detail mitra, info loker) supaya
 * tombol tidak pernah membawa pengunjung keluar dari situs.
 */
function tombolKembali(string $halamanInduk, string $label = 'Kembali', bool $selaluKeInduk = false): string
{
    return '<a class="btn btn-outline btn-sm btn-kembali"' . ($selaluKeInduk ? '' : ' data-kembali') . ' href="' . e(url($halamanInduk)) . '">'
        . '<span data-ic="left"></span>' . e($label) . '</a>';
}

/**
 * Kepala halaman standar: jejak halaman (crumb) + tombol Kembali.
 * Dipakai semua halaman di dalam dashboard supaya tidak ada halaman tanpa jalan pulang.
 * $jejak: [['Label', 'url/induk'], ..., ['Halaman ini']]  (elemen terakhir tanpa url)
 */
function kepalaKembali(string $halamanInduk, array $jejak): string
{
    $bagian = [];
    foreach ($jejak as $i => $j) {
        $label = e($j[0]);
        $bagian[] = isset($j[1]) ? '<a href="' . e(url($j[1])) . '">' . $label . '</a>' : '<span aria-current="page">' . $label . '</span>';
    }
    // Halaman utama tiap menu (induknya Dashboard) diberi kelas "akar": di HP menu bawah sudah
    // menjadi jalan pulang, jadi baris ini disembunyikan. Halaman turunan memindah tombol
    // Kembalinya ke app bar atas (lihat app.js initAppHp).
    $akar = str_ends_with($halamanInduk, '/dashboard') ? ' akar' : '';
    return '<div class="kepala-halaman' . $akar . '"><nav class="crumb" aria-label="Jejak halaman">'
        . implode(' <span aria-hidden="true">/</span> ', $bagian) . '</nav>'
        . tombolKembali($halamanInduk) . '</div>';
}

// --- C. Pamflet (gambar atau PDF) ------------------------------------
function pamfletUrl(?string $file): ?string
{
    if ($file === null || trim($file) === '') {
        return null;
    }
    return url('unduh.php?tipe=pamflet&file=' . urlencode($file));
}

function pamfletPdf(?string $file): bool
{
    return $file !== null && strtolower(pathinfo($file, PATHINFO_EXTENSION)) === 'pdf';
}

/**
 * $varian: 'mini' (ikon kecil di tabel), 'thumb' (kartu), 'besar' (halaman detail).
 * PDF ditampilkan langsung di halaman (object) dengan tombol buka/unduh,
 * karena tag <img> tidak bisa menampilkan PDF.
 */
function pamfletHtml(?string $file, string $varian = 'besar', string $alt = 'Pamflet lowongan'): string
{
    $src = pamfletUrl($file);
    if ($src === null) {
        return '<span class="pamflet-kosong pamflet-' . e($varian) . '" title="Belum ada pamflet">—</span>';
    }
    if (pamfletPdf($file)) {
        if ($varian === 'besar') {
            return '<div class="pamflet-pdf"><object data="' . e($src) . '#view=FitH" type="application/pdf" aria-label="' . e($alt) . '">'
                . '<p class="muted">Browser ini tidak bisa menampilkan PDF di halaman.</p></object>'
                . '<a class="btn btn-outline btn-sm mt-8" href="' . e($src) . '" target="_blank" rel="noopener"><span data-ic="file"></span>Buka pamflet PDF</a></div>';
        }
        return '<a class="pamflet-ikon-pdf pamflet-' . e($varian) . '" href="' . e($src) . '" target="_blank" rel="noopener" title="Buka pamflet PDF">PDF</a>';
    }
    $kelas = $varian === 'mini' ? 'pamflet-mini' : ($varian === 'thumb' ? 'pamflet-thumb' : 'gambar-bingkai pamflet-besar');
    return '<img class="' . $kelas . '" src="' . e($src) . '" alt="' . e($alt) . '" loading="lazy">';
}

// --- C2. Komponen kartu lowongan (Lowongan Saya & Monitoring) --------
/** Label jenis pekerjaan & sistem kerja yang mudah dibaca. */
function labelJenisKerja(string $jenis, string $sistem = ''): string
{
    $j = ['full_time' => 'Penuh waktu', 'part_time' => 'Paruh waktu', 'kontrak' => 'Kontrak', 'magang' => 'Magang', 'freelance' => 'Freelance'][$jenis] ?? ucwords(str_replace('_', ' ', $jenis));
    $s = ['wfo' => 'WFO', 'wfh' => 'WFH (remote)', 'hybrid' => 'Hybrid', 'remote' => 'Remote'][$sistem] ?? ucfirst($sistem);
    return $sistem === '' ? $j : $j . ' · ' . $s;
}

/** Pill status lowongan dengan ikon. */
function statusLowonganHtml(string $status): string
{
    $ikon = ['menunggu' => 'hourglass', 'revisi' => 'edit', 'aktif' => 'checkc', 'ditutup' => 'lock',
             'ditolak' => 'x', 'nonaktif' => 'ban'][$status] ?? 'info';
    [$label] = labelStatusLowongan($status);
    return '<span class="pill pill-ikon p-' . e($status) . '"><span data-ic="' . $ikon . '"></span>' . e($label) . '</span>';
}

/** Chip batas lamaran: tanggal + hitung mundur berwarna. */
function batasLowonganHtml(string $batas, string $status): string
{
    $sisa = sisaHari($batas);
    $kelas = 'lw-chip';
    $ket = '';
    if (in_array($status, ['aktif', 'menunggu', 'revisi'], true)) {
        if ($sisa < 0)       { $kelas .= ' c-bad';  $ket = 'lewat ' . abs($sisa) . ' hari'; }
        elseif ($sisa === 0) { $kelas .= ' c-bad';  $ket = 'hari ini'; }
        elseif ($sisa <= 3)  { $kelas .= ' c-warn'; $ket = $sisa . ' hari lagi'; }
        else                 { $ket = $sisa . ' hari lagi'; }
    }
    return '<span class="' . $kelas . '" title="Batas lamaran"><span data-ic="calendar"></span>' . tanggalIndo($batas)
        . ($ket ? ' <em>&middot; ' . e($ket) . '</em>' : '') . '</span>';
}

/** Bar kuota diterima/kuota. */
function kuotaLowonganHtml(int $terisi, int $kuota): string
{
    $persen = $kuota > 0 ? min(100, (int) round($terisi / $kuota * 100)) : 0;
    $kelas = $persen >= 100 ? ' penuh' : '';
    return '<div class="lw-kuota' . $kelas . '" title="Diterima ' . $terisi . ' dari kuota ' . $kuota . '">'
        . '<div class="lw-kuota-lbl"><span>Diterima</span><b>' . $terisi . '/' . $kuota . '</b></div>'
        . '<div class="progress"><i style="width:' . $persen . '%"></i></div></div>';
}

/** Logo perusahaan kecil (atau inisial). */
function logoPerusahaanHtml(?string $logo, string $nama, string $kelas = 'lw-logo'): string
{
    if ($logo) {
        return '<img class="' . e($kelas) . '" src="' . e(url('unduh.php?tipe=logo&file=' . urlencode($logo))) . '" alt="">';
    }
    return '<span class="' . e($kelas) . ' avatar-inisial">' . e(inisial($nama)) . '</span>';
}

// --- H. Pagination ---------------------------------------------------
/**
 * Navigasi halaman. Semua filter di URL (GET) ikut terbawa.
 * $info dari Controller::infoPaginasi().
 */
function paginasiHtml(array $info, string $label = 'data'): string
{
    $total = (int) $info['total'];
    $html = '<div class="paginasi"><p class="paginasi-info">';
    $html .= $total === 0
        ? 'Tidak ada ' . e($label) . '.'
        : 'Menampilkan ' . $info['dari'] . '–' . $info['sampai'] . ' dari ' . $total . ' ' . e($label);
    $html .= '</p>';
    if ($info['totalHalaman'] <= 1) {
        return $html . '</div>';
    }

    $q = $_GET;
    unset($q['url']);
    $path = strtok(Auth::pathSaatIni(), '?');
    $tautan = function (int $h) use ($q, $path): string {
        $q['halaman'] = $h;
        return e(url($path) . '?' . http_build_query($q));
    };

    $hal = (int) $info['halaman'];
    $akhir = (int) $info['totalHalaman'];
    $html .= '<nav class="pagination" aria-label="Halaman">';
    $html .= $hal > 1
        ? '<a href="' . $tautan($hal - 1) . '" aria-label="Sebelumnya"><span data-ic="left"></span></a>'
        : '<span class="disabled" aria-hidden="true"><span data-ic="left"></span></span>';

    $nomor = array_unique(array_filter([1, $hal - 1, $hal, $hal + 1, $akhir], fn($n) => $n >= 1 && $n <= $akhir));
    sort($nomor);
    $sebelumnya = 0;
    foreach ($nomor as $n) {
        if ($n - $sebelumnya > 1) {
            $html .= '<span class="gap">…</span>';
        }
        $html .= $n === $hal
            ? '<a class="active" aria-current="page" href="' . $tautan($n) . '">' . $n . '</a>'
            : '<a href="' . $tautan($n) . '">' . $n . '</a>';
        $sebelumnya = $n;
    }

    $html .= $hal < $akhir
        ? '<a href="' . $tautan($hal + 1) . '" aria-label="Berikutnya"><span data-ic="right"></span></a>'
        : '<span class="disabled" aria-hidden="true"><span data-ic="right"></span></span>';
    return $html . '</nav></div>';
}

// --- F. Provinsi -----------------------------------------------------
const DAFTAR_PROVINSI = [
    'Aceh', 'Sumatera Utara', 'Sumatera Barat', 'Riau', 'Kepulauan Riau', 'Jambi', 'Bengkulu',
    'Sumatera Selatan', 'Kepulauan Bangka Belitung', 'Lampung', 'Banten', 'DKI Jakarta', 'Jawa Barat',
    'Jawa Tengah', 'DI Yogyakarta', 'Jawa Timur', 'Bali', 'Nusa Tenggara Barat', 'Nusa Tenggara Timur',
    'Kalimantan Barat', 'Kalimantan Tengah', 'Kalimantan Selatan', 'Kalimantan Timur', 'Kalimantan Utara',
    'Sulawesi Utara', 'Gorontalo', 'Sulawesi Tengah', 'Sulawesi Barat', 'Sulawesi Selatan', 'Sulawesi Tenggara',
    'Maluku', 'Maluku Utara', 'Papua', 'Papua Barat', 'Papua Barat Daya', 'Papua Tengah', 'Papua Pegunungan',
    'Papua Selatan',
];


/** Kota/kabupaten -> provinsi, untuk isi otomatis provinsi di formulir alamat (revisi F). */
const PETA_KOTA_PROVINSI = [
    'Kabupaten Badung' => 'Bali',
    'Kabupaten Bangkalan' => 'Jawa Timur',
    'Kabupaten Bantul' => 'DI Yogyakarta',
    'Kabupaten Banyumas' => 'Jawa Tengah',
    'Kabupaten Banyuwangi' => 'Jawa Timur',
    'Kabupaten Bekasi' => 'Jawa Barat',
    'Kabupaten Blitar' => 'Jawa Timur',
    'Kabupaten Bogor' => 'Jawa Barat',
    'Kabupaten Bojonegoro' => 'Jawa Timur',
    'Kabupaten Bondowoso' => 'Jawa Timur',
    'Kabupaten Cilacap' => 'Jawa Tengah',
    'Kabupaten Gianyar' => 'Bali',
    'Kabupaten Gresik' => 'Jawa Timur',
    'Kabupaten Jayawijaya' => 'Papua Pegunungan',
    'Kabupaten Jember' => 'Jawa Timur',
    'Kabupaten Jepara' => 'Jawa Tengah',
    'Kabupaten Jombang' => 'Jawa Timur',
    'Kabupaten Karawang' => 'Jawa Barat',
    'Kabupaten Kediri' => 'Jawa Timur',
    'Kabupaten Kudus' => 'Jawa Tengah',
    'Kabupaten Lamongan' => 'Jawa Timur',
    'Kabupaten Lumajang' => 'Jawa Timur',
    'Kabupaten Madiun' => 'Jawa Timur',
    'Kabupaten Magetan' => 'Jawa Timur',
    'Kabupaten Malang' => 'Jawa Timur',
    'Kabupaten Mamuju' => 'Sulawesi Barat',
    'Kabupaten Manokwari' => 'Papua Barat',
    'Kabupaten Merauke' => 'Papua Selatan',
    'Kabupaten Mojokerto' => 'Jawa Timur',
    'Kabupaten Nabire' => 'Papua Tengah',
    'Kabupaten Nganjuk' => 'Jawa Timur',
    'Kabupaten Ngawi' => 'Jawa Timur',
    'Kabupaten Pacitan' => 'Jawa Timur',
    'Kabupaten Pamekasan' => 'Jawa Timur',
    'Kabupaten Pasuruan' => 'Jawa Timur',
    'Kabupaten Ponorogo' => 'Jawa Timur',
    'Kabupaten Probolinggo' => 'Jawa Timur',
    'Kabupaten Purwakarta' => 'Jawa Barat',
    'Kabupaten Sampang' => 'Jawa Timur',
    'Kabupaten Sidoarjo' => 'Jawa Timur',
    'Kabupaten Situbondo' => 'Jawa Timur',
    'Kabupaten Sleman' => 'DI Yogyakarta',
    'Kabupaten Sumenep' => 'Jawa Timur',
    'Kabupaten Tangerang' => 'Banten',
    'Kabupaten Trenggalek' => 'Jawa Timur',
    'Kabupaten Tuban' => 'Jawa Timur',
    'Kabupaten Tulungagung' => 'Jawa Timur',
    'Kota Ambon' => 'Maluku',
    'Kota Balikpapan' => 'Kalimantan Timur',
    'Kota Banda Aceh' => 'Aceh',
    'Kota Bandar Lampung' => 'Lampung',
    'Kota Bandung' => 'Jawa Barat',
    'Kota Banjarbaru' => 'Kalimantan Selatan',
    'Kota Banjarmasin' => 'Kalimantan Selatan',
    'Kota Batam' => 'Kepulauan Riau',
    'Kota Batu' => 'Jawa Timur',
    'Kota Bekasi' => 'Jawa Barat',
    'Kota Bengkulu' => 'Bengkulu',
    'Kota Blitar' => 'Jawa Timur',
    'Kota Bogor' => 'Jawa Barat',
    'Kota Cilegon' => 'Banten',
    'Kota Cimahi' => 'Jawa Barat',
    'Kota Cirebon' => 'Jawa Barat',
    'Kota Denpasar' => 'Bali',
    'Kota Depok' => 'Jawa Barat',
    'Kota Gorontalo' => 'Gorontalo',
    'Kota Jakarta Barat' => 'DKI Jakarta',
    'Kota Jakarta Pusat' => 'DKI Jakarta',
    'Kota Jakarta Selatan' => 'DKI Jakarta',
    'Kota Jakarta Timur' => 'DKI Jakarta',
    'Kota Jakarta Utara' => 'DKI Jakarta',
    'Kota Jambi' => 'Jambi',
    'Kota Jayapura' => 'Papua',
    'Kota Kediri' => 'Jawa Timur',
    'Kota Kendari' => 'Sulawesi Tenggara',
    'Kota Kupang' => 'Nusa Tenggara Timur',
    'Kota Madiun' => 'Jawa Timur',
    'Kota Magelang' => 'Jawa Tengah',
    'Kota Makassar' => 'Sulawesi Selatan',
    'Kota Malang' => 'Jawa Timur',
    'Kota Manado' => 'Sulawesi Utara',
    'Kota Mataram' => 'Nusa Tenggara Barat',
    'Kota Medan' => 'Sumatera Utara',
    'Kota Mojokerto' => 'Jawa Timur',
    'Kota Padang' => 'Sumatera Barat',
    'Kota Palangka Raya' => 'Kalimantan Tengah',
    'Kota Palembang' => 'Sumatera Selatan',
    'Kota Palu' => 'Sulawesi Tengah',
    'Kota Pangkal Pinang' => 'Kepulauan Bangka Belitung',
    'Kota Pasuruan' => 'Jawa Timur',
    'Kota Pekalongan' => 'Jawa Tengah',
    'Kota Pekanbaru' => 'Riau',
    'Kota Pontianak' => 'Kalimantan Barat',
    'Kota Probolinggo' => 'Jawa Timur',
    'Kota Salatiga' => 'Jawa Tengah',
    'Kota Samarinda' => 'Kalimantan Timur',
    'Kota Semarang' => 'Jawa Tengah',
    'Kota Serang' => 'Banten',
    'Kota Sorong' => 'Papua Barat Daya',
    'Kota Sukabumi' => 'Jawa Barat',
    'Kota Surabaya' => 'Jawa Timur',
    'Kota Surakarta' => 'Jawa Tengah',
    'Kota Tangerang' => 'Banten',
    'Kota Tangerang Selatan' => 'Banten',
    'Kota Tarakan' => 'Kalimantan Utara',
    'Kota Tasikmalaya' => 'Jawa Barat',
    'Kota Tegal' => 'Jawa Tengah',
    'Kota Ternate' => 'Maluku Utara',
    'Kota Yogyakarta' => 'DI Yogyakarta',
];

function opsiProvinsi(?string $terpilih): string
{
    $html = '<option value="">Pilih provinsi</option>';
    foreach (DAFTAR_PROVINSI as $p) {
        $html .= '<option value="' . e($p) . '"' . ($p === $terpilih ? ' selected' : '') . '>' . e($p) . '</option>';
    }
    return $html;
}

// --- K. Template alasan ----------------------------------------------
/** Tombol isi cepat alasan dari Pengaturan (satu alasan per baris). */
function chipsAlasan(string $kunciPengaturan, string $idTextarea): string
{
    $teks = (new Pengaturan())->ambil($kunciPengaturan, '');
    $daftar = array_values(array_filter(array_map('trim', preg_split('/\R/', $teks) ?: [])));
    if (!$daftar) {
        return '';
    }
    $html = '<div class="chips-alasan" data-target="' . e($idTextarea) . '"><small class="muted">Isi cepat:</small>';
    foreach ($daftar as $alasan) {
        $html .= '<button type="button" data-alasan="' . e($alasan) . '">' . e(ringkas($alasan, 48)) . '</button>';
    }
    return $html . '</div>';
}

// --- K & M. Riwayat status -------------------------------------------
/** $baris: tiap item punya 'tanggal', 'judul', 'oleh' (opsional), 'catatan' (opsional). */
function riwayatHtml(array $baris): string
{
    if (!$baris) {
        return '<p class="muted">Belum ada riwayat.</p>';
    }
    $html = '<ul class="riwayat-status">';
    foreach ($baris as $r) {
        $html .= '<li><span class="titik"></span><div><b>' . e($r['judul']) . '</b>'
            . '<small>' . tanggalWaktuIndo($r['tanggal']) . (!empty($r['oleh']) ? ' · ' . e($r['oleh']) : '') . '</small>'
            . (!empty($r['catatan']) ? '<div class="fs-90">' . nl2br(e($r['catatan'])) . '</div>' : '')
            . '</div></li>';
    }
    return $html . '</ul>';
}