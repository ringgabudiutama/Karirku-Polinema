<?php
/**
 * Penjelajah seluruh aplikasi.
 *
 * Untuk tiap peran: masuk, buka semua halaman, kumpulkan SETIAP tautan di
 * dalamnya, lalu buka satu per satu. Redirect DIIKUTI sampai tujuan akhir,
 * karena bug notifikasi kemarin lolos justru di situ: statusnya 302, tapi
 * tujuannya halaman yang tidak ada.
 */
$B = 'http://127.0.0.1:8000';
$S = '/tmp/claude-0/-home-claude/34c7d75d-6ec8-5e75-91f4-7f39653d6878/scratchpad';

function ambil(string $url, string $jar, bool $ikuti = true): array {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true, CURLOPT_FOLLOWLOCATION => $ikuti,
        CURLOPT_MAXREDIRS => 6, CURLOPT_COOKIEJAR => $jar, CURLOPT_COOKIEFILE => $jar,
        CURLOPT_TIMEOUT => 20,
    ]);
    $body = curl_exec($ch);
    $kode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $akhir = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
    curl_close($ch);
    return [$kode, (string) $body, $akhir];
}
function login(string $B, string $e, string $p, string $jar): bool {
    @unlink($jar);
    [, $h] = ambil("$B/masuk", $jar);
    if (!preg_match('/name="csrf_token" value="([^"]+)"/', $h, $m)) return false;
    $ch = curl_init("$B/auth/proses-masuk");
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query(['csrf_token' => $m[1], 'email' => $e, 'password' => $p]),
        CURLOPT_COOKIEJAR => $jar, CURLOPT_COOKIEFILE => $jar, CURLOPT_FOLLOWLOCATION => true]);
    $b = curl_exec($ch); curl_close($ch);
    // Berhasil kalau sudah TIDAK melihat formulir masuk lagi.
    return strpos($b, 'name="password"') === false;
}

/* Halaman awal tiap peran. Sisanya ditemukan sendiri dari tautan di dalamnya. */
$awal = [
  'tamu'       => ['', ['', 'masuk', 'daftar', 'auth/lupa-sandi']],
  'mahasiswa'  => [['mahasiswa@polinema.ac.id', 'mahasiswa123'],
                   ['mahasiswa/dashboard', 'lowongan/daftar', 'lamaran/lamaran-saya',
                    'mahasiswa/profil', 'mahasiswa/disimpan', 'notifikasi/semua',
                    'mahasiswa/pengaturan-akun']],
  'perusahaan' => [['perusahaan@polinema.ac.id', 'perusahaan123'],
                   ['perusahaan/dashboard', 'perusahaan/lowongan', 'perusahaan/pelamar',
                    'perusahaan/profil', 'lowongan/form-pasang', 'notifikasi/semua',
                    'perusahaan/pengaturan-akun']],
  'admin'      => [['admin@polinema.ac.id', 'admin123'],
                   ['admin/dashboard', 'admin/persetujuan', 'admin/kelola-pengguna',
                    'admin/monitoring-lowongan', 'admin/rekap-lamaran', 'admin/tracer-karier',
                    'admin/pengaturan', 'kirim-loker/index', 'notifikasi/semua']],
];

/* Alamat yang memang mengakhiri sesi atau mengubah data besar, dilewati */
$lewati = ['keluar', 'auth/keluar'];

$polaGalat = '/Fatal error|Parse error|Uncaught|Call to undefined|SQLSTATE|Warning:|Notice:|Deprecated:/i';
$totalMasalah = 0; $totalCek = 0;

foreach ($awal as $peran => [$akun, $halamanAwal]) {
    $jar = "$S/jelajah-$peran";
    if (is_array($akun)) {
        if (!login($B, $akun[0], $akun[1], $jar)) { echo "GAGAL login $peran\n"; continue; }
    } else { @unlink($jar); }

    echo "=== $peran ===\n";
    $sudah = [];
    $antre = $halamanAwal;
    $asal = [];
    foreach ($halamanAwal as $h) $asal[$h] = '(halaman awal)';

    while ($antre) {
        $jalur = array_shift($antre);
        if (isset($sudah[$jalur])) continue;
        $sudah[$jalur] = true;

        $bersih = strtok(ltrim($jalur, '/'), '?');
        if (in_array($bersih, $lewati, true)) continue;

        [$kode, $isi, $akhir] = ambil("$B/" . ltrim($jalur, '/'), $jar, true);
        $totalCek++;

        if (getenv('DEBUG_TANDAI') && strpos($jalur, 'tandai') !== false) {
            echo "    [debug] /$jalur -> kode $kode, akhir $akhir\n";
        }
        $masalah = [];
        if ($kode === 404) $masalah[] = 'HTTP 404';
        elseif ($kode >= 500) $masalah[] = "HTTP $kode";
        elseif ($kode !== 200) $masalah[] = "HTTP $kode";
        if (preg_match($polaGalat, $isi, $g)) $masalah[] = 'PHP: ' . trim($g[0]);
        /* Halaman 404 yang dirender aplikasi sendiri (status 404 sudah tertangkap,
           tapi sebagian halaman merender 404 dengan status 200) */
        if (strpos($isi, 'Halaman tidak ditemukan') !== false) $masalah[] = 'isi halaman 404';
        /* Tautan berkas: halaman galatnya rapi, jadi dikenali dari judulnya. */
        foreach (['Berkas tidak ditemukan', 'Berkas ini bukan untukmu',
                  'Permintaan berkas tidak dikenal'] as $jg) {
            if (strpos($isi, $jg) !== false) $masalah[] = $jg;
        }
        /* Terlempar ke halaman masuk padahal sedang login berarti sesi hilang
           atau hak aksesnya salah. Ini harus dilaporkan, bukan dianggap lolos,
           karena halaman masuk statusnya 200. */
        if (is_array($akun) && preg_match('#/masuk$#', parse_url($akhir, PHP_URL_PATH) ?? '')) {
            $masalah[] = 'terlempar ke halaman masuk';
        }

        if ($masalah) {
            $tujuan = parse_url($akhir, PHP_URL_PATH) . (parse_url($akhir, PHP_URL_QUERY) ? '?' . parse_url($akhir, PHP_URL_QUERY) : '');
            echo "  MASALAH  /$jalur\n";
            echo "           " . implode(' | ', $masalah) . "\n";
            echo "           berakhir di: $tujuan\n";
            echo "           ditemukan dari: " . ($asal[$jalur] ?? '?') . "\n";
            $totalMasalah++;
            continue;
        }

        /* Kumpulkan tautan di halaman ini */
        if (preg_match_all('/href="([^"#]+)"/i', $isi, $m)) {
            foreach ($m[1] as $t) {
                if (preg_match('#^(https?:|mailto:|tel:|javascript:|data:)#i', $t)) continue;
                $t = html_entity_decode($t);
                $t = ltrim($t, '/');
                if ($t === '' || str_starts_with($t, 'assets/')) continue;
                if (!isset($sudah[$t]) && !in_array($t, $antre, true)) {
                    $antre[] = $t;
                    if (!isset($asal[$t])) $asal[$t] = "/$jalur";
                }
            }
        }
    }
    echo "  " . count($sudah) . " alamat ditelusuri\n";
    if (getenv('DEBUG_TANDAI')) {
        foreach (array_keys($sudah) as $a) if (strpos($a, 'tandai') !== false) echo "    [debug] $a\n";
    }
}

echo "\n$totalCek alamat diperiksa. " .
     ($totalMasalah === 0 ? "Tidak ada yang bermasalah.\n" : "$totalMasalah bermasalah.\n");
exit($totalMasalah > 0 ? 1 : 0);
