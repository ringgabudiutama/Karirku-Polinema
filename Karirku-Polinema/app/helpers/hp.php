<?php
// ===== FRONTEND · HELPER · Komponen tampilan HP (mode aplikasi) =========
// Dipakai blok berkelas "hp" di view (tampil hanya di layar <= 768px, lihat hp.css).
// Bentuk & kelasnya sama dengan model UI (kanvas desain), semua kelas berawalan "m-".

function hpIk(string $nama, int $ukuran = 20, float $tebal = 1.9, string $isi = 'none'): string
{
    static $ik = [
        'home' => '<path d="M3 10.2 12 3l9 7.2V20a1 1 0 0 1-1 1h-5.5v-6h-5v6H4a1 1 0 0 1-1-1z"/>',
        'briefcase' => '<rect x="3" y="7" width="18" height="13" rx="2.5"/><path d="M8.5 7V5.5A2.5 2.5 0 0 1 11 3h2a2.5 2.5 0 0 1 2.5 2.5V7M3 12.5h18"/>',
        'file' => '<path d="M14 3H6.5A2.5 2.5 0 0 0 4 5.5v13A2.5 2.5 0 0 0 6.5 21h11a2.5 2.5 0 0 0 2.5-2.5V9z"/><path d="M14 3v6h6M8.5 13h7M8.5 17h4.5"/>',
        'user' => '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
        'users' => '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M18 14a6.5 6.5 0 0 1 3.5 6"/>',
        'bell' => '<path d="M6 8.5a6 6 0 0 1 12 0c0 6.5 2.5 8.5 2.5 8.5h-17S6 15 6 8.5"/><path d="M10.3 20.5a1.94 1.94 0 0 0 3.4 0"/>',
        'search' => '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.6-3.6"/>',
        'bookmark' => '<path d="M18.5 21 12 16.5 5.5 21V5.5A2.5 2.5 0 0 1 8 3h8a2.5 2.5 0 0 1 2.5 2.5z"/>',
        'sliders' => '<path d="M4 6.5h9M17 6.5h3M4 12h3M11 12h9M4 17.5h11M19 17.5h1"/><circle cx="15" cy="6.5" r="2"/><circle cx="9" cy="12" r="2"/><circle cx="17" cy="17.5" r="2"/>',
        'pin' => '<path d="M12 21s-7-6.2-7-11.2a7 7 0 0 1 14 0C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.8" r="2.5"/>',
        'clock' => '<circle cx="12" cy="12" r="9"/><path d="M12 7.5V12l3 2"/>',
        'chev' => '<path d="m9.5 6 6 6-6 6"/>',
        'chevd' => '<path d="m6 9.5 6 6 6-6"/>',
        'back' => '<path d="M15 5.5 8.5 12l6.5 6.5"/>',
        'share' => '<path d="M12 3v12M7.5 7.5 12 3l4.5 4.5"/><path d="M5 12.5V19a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6.5"/>',
        'verified' => '<path d="M12 2.8l2.3 1.7 2.9.1 1 2.7 2.3 1.8-.8 2.8.8 2.8-2.3 1.8-1 2.7-2.9.1L12 21.2l-2.3-1.7-2.9-.1-1-2.7-2.3-1.8.8-2.8-.8-2.8 2.3-1.8 1-2.7 2.9-.1z"/><path d="m8.8 12 2.2 2.2 4.2-4.4"/>',
        'check' => '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
        'checkc' => '<circle cx="12" cy="12" r="9"/><path d="m8.2 12.3 2.6 2.6 5-5.4"/>',
        'cal' => '<rect x="3.5" y="5" width="17" height="16" rx="2.5"/><path d="M16 3v4M8 3v4M3.5 10h17"/>',
        'money' => '<rect x="2.5" y="6" width="19" height="13" rx="2.5"/><circle cx="12" cy="12.5" r="2.6"/><path d="M6 10v5M18 10v5"/>',
        'grid' => '<rect x="3.5" y="3.5" width="7" height="7" rx="2"/><rect x="13.5" y="3.5" width="7" height="7" rx="2"/><rect x="3.5" y="13.5" width="7" height="7" rx="2"/><rect x="13.5" y="13.5" width="7" height="7" rx="2"/>',
        'shield' => '<path d="M12 3 4.5 6v5.5c0 4.8 3.2 8.2 7.5 9.5 4.3-1.3 7.5-4.7 7.5-9.5V6z"/><path d="m9 12 2.2 2.2L15.2 10"/>',
        'plus' => '<path d="M12 5v14M5 12h14"/>',
        'x' => '<path d="M6.5 6.5l11 11M17.5 6.5l-11 11"/>',
        'upload' => '<path d="M12 15.5V4M7.5 8.5 12 4l4.5 4.5M4.5 15v3.5A2.5 2.5 0 0 0 7 21h10a2.5 2.5 0 0 0 2.5-2.5V15"/>',
        'download' => '<path d="M12 4v11.5M7.5 11 12 15.5 16.5 11M4.5 15v3.5A2.5 2.5 0 0 0 7 21h10a2.5 2.5 0 0 0 2.5-2.5V15"/>',
        'wand' => '<path d="M15 4V2.5M15 9.5V8M11.5 6H10M20 6h-1.5M17.6 3.4l-1 1M17.6 8.6l-1-1M3.5 20.5 13 11"/>',
        'gear' => '<path d="M12 15.2a3.2 3.2 0 1 0 0-6.4 3.2 3.2 0 0 0 0 6.4z"/><path d="M19.4 13.5a7.6 7.6 0 0 0 0-3l2-1.6-2-3.4-2.4.9a7.5 7.5 0 0 0-2.6-1.5L14 2.4h-4l-.4 2.5A7.5 7.5 0 0 0 7 6.4l-2.4-.9-2 3.4 2 1.6a7.6 7.6 0 0 0 0 3l-2 1.6 2 3.4 2.4-.9a7.5 7.5 0 0 0 2.6 1.5l.4 2.5h4l.4-2.5a7.5 7.5 0 0 0 2.6-1.5l2.4.9 2-3.4z"/>',
        'logout' => '<path d="M9.5 21H6a2.5 2.5 0 0 1-2.5-2.5v-13A2.5 2.5 0 0 1 6 3h3.5M16 16.5 20.5 12 16 7.5M20.5 12H9.5"/>',
        'school' => '<path d="M2.5 9 12 4.5 21.5 9 12 13.5z"/><path d="M6.5 11v5c3 2.2 8 2.2 11 0v-5M21.5 9v5"/>',
        'star' => '<path d="m12 3.5 2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.8l-5.2 2.8 1-5.8-4.3-4.1 5.9-.8z"/>',
        'award' => '<circle cx="12" cy="9" r="5.5"/><path d="M8.8 13.8 7.5 21.5 12 19l4.5 2.5-1.3-7.7"/>',
        'image' => '<rect x="3" y="3.5" width="18" height="17" rx="2.5"/><circle cx="9" cy="9.5" r="1.8"/><path d="m21 15.5-4.8-4.8L6 20.5"/>',
        'chart' => '<path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/>',
        'building' => '<path d="M4 21V5.5A2.5 2.5 0 0 1 6.5 3h6A2.5 2.5 0 0 1 15 5.5V21M15 10h3.5a2 2 0 0 1 2 2v9M2.5 21h19"/><path d="M8 7.5h3M8 11.5h3M8 15.5h3"/>',
        'clip' => '<rect x="5" y="4.5" width="14" height="17" rx="2.5"/><path d="M9 4.5V3.5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v1M9 11h6M9 15h4"/>',
        'send' => '<path d="M21 3 10.5 13.5M21 3l-6.5 18-4-7.5-7.5-4z"/>',
        'eye' => '<path d="M2.5 12S6 5 12 5s9.5 7 9.5 7-3.5 7-9.5 7-9.5-7-9.5-7z"/><circle cx="12" cy="12" r="3"/>',
        'edit' => '<path d="M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16z"/><path d="m13.5 6.5 4 4"/>',
        'copy' => '<rect x="8.5" y="8.5" width="12" height="12" rx="2.5"/><path d="M15.5 8.5V6a2.5 2.5 0 0 0-2.5-2.5H6A2.5 2.5 0 0 0 3.5 6v7A2.5 2.5 0 0 0 6 15.5h2.5"/>',
        'refresh' => '<path d="M20 11.5A8 8 0 0 0 6 6.3L3.5 8.5M3.5 4v4.5H8M4 12.5A8 8 0 0 0 18 17.7l2.5-2.2M20.5 20v-4.5H16"/>',
        'lock' => '<rect x="4.5" y="10.5" width="15" height="10.5" rx="2.5"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>',
        'mail' => '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="m3.5 6.5 8.5 6 8.5-6"/>',
        'phone' => '<path d="M5 3.5h3.5l1.8 4.5-2.3 1.5a11 11 0 0 0 6.5 6.5l1.5-2.3 4.5 1.8V19a1.5 1.5 0 0 1-1.5 1.5A16.5 16.5 0 0 1 3.5 5 1.5 1.5 0 0 1 5 3.5z"/>',
        'alert' => '<path d="M10.3 4.2 2.6 17.5A2 2 0 0 0 4.3 20.5h15.4a2 2 0 0 0 1.7-3L13.7 4.2a2 2 0 0 0-3.4 0z"/><path d="M12 9.5v4.5M12 17.2v.3"/>',
        'info' => '<circle cx="12" cy="12" r="9"/><path d="M12 11v5.5M12 7.8v.3"/>',
        'more' => '<circle cx="5.5" cy="12" r="1.3"/><circle cx="12" cy="12" r="1.3"/><circle cx="18.5" cy="12" r="1.3"/>',
        'video' => '<rect x="2.5" y="6" width="13" height="12" rx="2.5"/><path d="m15.5 10.5 6-3.5v10l-6-3.5"/>',
        'msg' => '<path d="M20.5 12a8.5 8.5 0 0 1-12.3 7.6L3.5 21l1.4-4.7A8.5 8.5 0 1 1 20.5 12z"/>',
        'ban' => '<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>',
        'trend' => '<path d="m3 17 6-6 4 4 8-8"/><path d="M15 7h6v6"/>',
        'eyeoff' => '<path d="M3 3l18 18M10.6 5.1A9.6 9.6 0 0 1 12 5c6 0 9.5 7 9.5 7a16 16 0 0 1-3 3.9M6.3 6.3C3.8 8 2.5 12 2.5 12s3.5 7 9.5 7a9.4 9.4 0 0 0 4.4-1.1"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
    ];
    return '<svg width="' . $ukuran . '" height="' . $ukuran . '" viewBox="0 0 24 24" fill="' . $isi . '" stroke="currentColor" stroke-width="' . $tebal
        . '" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' . ($ik[$nama] ?? '') . '</svg>';
}

/** Warna gradasi tetap per nama (logo inisial perusahaan / avatar). */
function hpWarna(string $nama): string
{
    static $palet = [['#5b4bd1', '#3a2f9c'], ['#e2343f', '#a9121c'], ['#1673a8', '#0b4a73'], ['#169a5c', '#0b6a3e'], ['#d07a18', '#9a5208'],
                     ['#9a2a3a', '#5f1420'], ['#2a6be0', '#163f95'], ['#0f8b8d', '#08585a'], ['#7a3fc4', '#4e2390']];
    [$a, $b] = $palet[crc32($nama) % count($palet)];
    return "linear-gradient(135deg,{$a},{$b})";
}

function hpInisial(string $nama): string
{
    $nama = preg_replace('/^(PT|CV|UD|PD|Tbk)\.?\s+/i', '', trim($nama));
    $kata = preg_split('/\s+/', (string) $nama) ?: [''];
    return mb_strtoupper(mb_substr($kata[0], 0, 1) . mb_substr($kata[1] ?? '', 0, 1));
}

/** Logo perusahaan: gambar bila ada, selain itu inisial di atas gradasi. */
function hpLogo(string $nama, ?string $logo, int $ukuran = 46): string
{
    $r = (int) round($ukuran * 0.3);
    $gaya = "width:{$ukuran}px;height:{$ukuran}px;border-radius:{$r}px";
    if (!empty($logo)) {
        return '<img class="m-logo m-logo-img" style="' . $gaya . '" src="' . e(url('unduh.php?tipe=logo&file=' . urlencode($logo))) . '" alt="" loading="lazy">';
    }
    return '<span class="m-logo" style="' . $gaya . ';font-size:' . round($ukuran * 0.31) . 'px;background:' . hpWarna($nama) . '" aria-hidden="true">' . e(hpInisial($nama)) . '</span>';
}

function hpAvatar(string $nama, ?string $fotoUrl, int $ukuran = 44): string
{
    $gaya = "width:{$ukuran}px;height:{$ukuran}px";
    if ($fotoUrl) {
        return '<img class="m-av m-av-img" style="' . $gaya . '" src="' . e($fotoUrl) . '" alt="">';
    }
    return '<span class="m-av" style="' . $gaya . ';font-size:' . round($ukuran * 0.33) . 'px;background:#dfe8fb" aria-hidden="true">' . e(hpInisial($nama)) . '</span>';
}

/** "Rp 5.000.000 - Rp 7.000.000" → "Rp 5–7 jt"; teks lain (Negosiasi) apa adanya. */
function hpGaji(?string $gaji): string
{
    $gaji = trim((string) $gaji);
    if ($gaji === '') {
        return 'Gaji dirahasiakan';
    }
    preg_match_all('/\d[\d.]*/', $gaji, $m);
    $angka = array_values(array_filter(array_map(fn($x) => (int) str_replace('.', '', $x), $m[0]), fn($n) => $n >= 100000));
    if (!$angka) {
        return $gaji;
    }
    $jt = fn(int $n): string => rtrim(rtrim(number_format($n / 1000000, 1, ',', ''), '0'), ',');
    return 'Rp ' . $jt($angka[0]) . (isset($angka[1]) ? '–' . $jt($angka[1]) : '') . ' jt';
}

function hpJenis(?string $jenis): string
{
    $peta = ['full_time' => 'Penuh waktu', 'part_time' => 'Paruh waktu', 'kontrak' => 'Kontrak', 'magang' => 'Magang', 'freelance' => 'Freelance'];
    $j = (string) $jenis;
    return $peta[strtolower($j)] ?? ucfirst(str_replace('_', ' ', $j));
}

/** [teks, mendesak?] untuk batas lamaran. */
function hpTenggat(?string $batas): array
{
    if (!$batas) {
        return ['', false];
    }
    $sisa = sisaHari($batas);
    if ($sisa < 0) {
        return ['Sudah ditutup', false];
    }
    if ($sisa === 0) {
        return ['Tutup hari ini', true];
    }
    if ($sisa <= 7) {
        return ['Tutup ' . $sisa . ' hari lagi', $sisa <= 3];
    }
    $bln = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    $t = strtotime($batas);
    return ['Tutup ' . date('j', $t) . ' ' . $bln[(int) date('n', $t)], false];
}

function hpBadge(string $jenis, string $teks): string
{
    return '<span class="m-badge m-b-' . $jenis . '"><i></i>' . e($teks) . '</span>';
}

/** Badge + 4 bar tahap + keterangan untuk status lamaran. */
function hpStatusLamaran(string $status): array
{
    return [
        'diajukan'   => ['off', 'Diajukan', ['d', '', '', ''], 'Menunggu ditinjau'],
        'screening'  => ['blue', 'Screening', ['d', 'd', '', ''], 'Tahap 2 dari 4 · Screening CV'],
        'interview'  => ['warn', 'Interview', ['d', 'd', 'd', ''], 'Tahap 3 dari 4 · Interview'],
        'diterima'   => ['ok', 'Diterima', ['g', 'g', 'g', 'g'], 'Selesai · Selamat!'],
        'ditolak'    => ['bad', 'Ditolak', ['x', 'x', 'x', 'x'], 'Belum berhasil kali ini'],
        'dibatalkan' => ['off', 'Dibatalkan', ['', '', '', ''], 'Kamu membatalkan lamaran ini'],
    ][$status] ?? ['off', ucfirst($status), ['', '', '', ''], ''];
}

function hpBarTahap(array $tahap): string
{
    return '<div class="m-steps">' . implode('', array_map(fn($k) => '<i class="' . ($k ? 'm-' . $k : '') . '"></i>', $tahap)) . '</div>';
}

/** Kartu lowongan bergaya model (dipakai Beranda, Lowongan, Disimpan). */
function hpKartuLowongan(array $l, bool $disimpan = false): string
{
    [$tenggat, $mendesak] = hpTenggat($l['batas_lamaran'] ?? null);
    $gaji = hpGaji($l['gaji'] ?? '');
    $perBulan = preg_match('/jt$/', $gaji) ? '<span class="m-muted" style="font-weight:600;font-size:12px"> /bln</span>' : '';
    $href = e(url('lowongan/detail/' . $l['id']));
    $tag = '<span class="m-tag">' . hpIk('pin', 13, 2) . e($l['lokasi'] ?? '') . '</span>'
         . '<span class="m-tag">' . e(hpJenis($l['jenis_pekerjaan'] ?? '')) . '</span>'
         . (!empty($l['sistem_kerja']) ? '<span class="m-tag">' . e($l['sistem_kerja']) . '</span>' : '');
    $simpan = '<form class="m-bm-form" method="post" action="' . e(url('lowongan/simpan/' . $l['id'])) . '">' . csrfField()
        . '<input type="hidden" name="kembali" value="' . e(Auth::pathSaatIni()) . '">'
        . '<button class="m-ib m-bm' . ($disimpan ? ' m-on' : '') . '" type="submit" aria-label="' . ($disimpan ? 'Hapus dari disimpan' : 'Simpan lowongan') . '">'
        . hpIk('bookmark', 21, 1.9, $disimpan ? 'currentColor' : 'none') . '</button></form>';
    return '<div class="m-card m-kartu-loker"><a class="m-job" href="' . $href . '"><div class="m-top">' . hpLogo($l['nama_perusahaan'] ?? '', $l['logo'] ?? null)
        . '<div style="min-width:0"><p class="m-t">' . e($l['posisi']) . '</p><div class="m-c"><span class="m-elip">' . e($l['nama_perusahaan'] ?? '') . '</span><span class="m-vf">' . hpIk('verified', 15) . '</span></div></div></div>'
        . '<div class="m-meta">' . $tag . '</div>'
        . '<div class="m-jf"><span class="m-pay">' . e($gaji) . $perBulan . '</span><span class="m-due' . ($mendesak ? ' m-hot' : '') . '">' . hpIk('clock', 14, 2.1) . e($tenggat) . '</span></div></a>'
        . $simpan . '</div>';
}

function hpSapaan(): string
{
    $jam = (int) date('G');
    return $jam < 11 ? 'Selamat pagi' : ($jam < 15 ? 'Selamat siang' : ($jam < 19 ? 'Selamat sore' : 'Selamat malam'));
}
