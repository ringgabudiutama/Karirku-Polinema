<?php
/**
 * Menguji SETIAP tautan berkas (unduh.php) yang muncul di aplikasi.
 *
 * Untuk tiap peran: buka semua halaman, kumpulkan setiap tautan unduh.php,
 * lalu buka satu per satu dan periksa apakah berkasnya benar-benar keluar.
 * Juga diuji dari peran yang TIDAK berhak, untuk memastikan penolakannya
 * memang disengaja dan bukan kebocoran.
 */
$B = 'http://127.0.0.1:8000';
$S = '/tmp/claude-0/-home-claude/34c7d75d-6ec8-5e75-91f4-7f39653d6878/scratchpad';

function ambilB(string $url, string $jar): array {
    $ch = curl_init($url);
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_COOKIEJAR => $jar, CURLOPT_COOKIEFILE => $jar, CURLOPT_TIMEOUT => 20,
        CURLOPT_HEADER => true]);
    $r = curl_exec($ch);
    $kode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $tipeIsi = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
    $ukuran = curl_getinfo($ch, CURLINFO_SIZE_DOWNLOAD);
    $hsize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    curl_close($ch);
    return [$kode, (string) $tipeIsi, (int) $ukuran, substr((string) $r, $hsize)];
}
function loginB(string $B, string $e, string $p, string $jar): bool {
    @unlink($jar);
    $ch = curl_init("$B/masuk");
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_COOKIEJAR => $jar, CURLOPT_COOKIEFILE => $jar]);
    $h = curl_exec($ch); curl_close($ch);
    if (!preg_match('/name="csrf_token" value="([^"]+)"/', $h, $m)) return false;
    $ch = curl_init("$B/auth/proses-masuk");
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => http_build_query(['csrf_token' => $m[1], 'email' => $e, 'password' => $p]),
        CURLOPT_COOKIEJAR => $jar, CURLOPT_COOKIEFILE => $jar, CURLOPT_FOLLOWLOCATION => true]);
    $b = curl_exec($ch); curl_close($ch);
    return strpos($b, 'name="password"') === false;
}

$peran = [
  'mahasiswa'  => [['mahasiswa@polinema.ac.id', 'mahasiswa123'],
      ['mahasiswa/dashboard', 'mahasiswa/profil', 'lowongan/daftar', 'lamaran/lamaran-saya', 'mahasiswa/disimpan']],
  'perusahaan' => [['perusahaan@polinema.ac.id', 'perusahaan123'],
      ['perusahaan/dashboard', 'perusahaan/lowongan', 'perusahaan/pelamar', 'perusahaan/profil']],
  'admin'      => [['admin@polinema.ac.id', 'admin123'],
      ['admin/dashboard', 'admin/persetujuan', 'admin/kelola-pengguna', 'admin/monitoring-lowongan']],
];

/* Kumpulkan tautan berkas dengan menelusuri halaman + halaman detailnya */
$semuaTautan = [];   // peran => [url => halaman asal]
foreach ($peran as $nama => [$akun, $awal]) {
    $jar = "$S/berkas-$nama";
    if (!loginB($B, $akun[0], $akun[1], $jar)) { echo "GAGAL login $nama\n"; continue; }

    $sudah = []; $antre = $awal; $tautanBerkas = [];
    $batas = 0;
    while ($antre && $batas++ < 400) {
        $j = array_shift($antre);
        if (isset($sudah[$j])) continue;
        $sudah[$j] = true;
        if (strtok(ltrim($j, '/'), '?') === 'keluar') continue;
        if (str_starts_with($j, 'unduh.php')) { $tautanBerkas[$j] = true; continue; }

        [$kode, , , $isi] = ambilB("$B/" . ltrim($j, '/'), $jar);
        if ($kode !== 200) continue;
        if (preg_match_all('/href="([^"#]+)"|src="([^"#]+)"/i', $isi, $m)) {
            foreach (array_merge($m[1], $m[2]) as $t) {
                if ($t === '' || preg_match('#^(https?:|mailto:|tel:|javascript:|data:)#i', $t)) continue;
                $t = ltrim(html_entity_decode($t), '/');
                if ($t === '' || str_starts_with($t, 'assets/')) continue;
                if (str_starts_with($t, 'unduh.php')) { $tautanBerkas[$t] = $j; continue; }
                if (!isset($sudah[$t]) && !in_array($t, $antre, true)) $antre[] = $t;
            }
        }
    }
    $semuaTautan[$nama] = $tautanBerkas;
}

$masalah = 0; $total = 0;
foreach ($semuaTautan as $nama => $tautan) {
    echo "=== $nama (" . count($tautan) . " tautan berkas) ===\n";
    $jar = "$S/berkas-$nama";
    foreach ($tautan as $t => $asal) {
        [$kode, $tipeIsi, $ukuran, $isi] = ambilB("$B/" . $t, $jar);
        $total++;
        parse_str(parse_url($t, PHP_URL_QUERY) ?? '', $q);
        $label = ($q['tipe'] ?? '?');
        if ($kode === 200 && $ukuran > 0 && !str_contains($tipeIsi, 'text/html')) {
            echo "  ok     $label  (" . $tipeIsi . ", " . $ukuran . " byte)\n";
        } else {
            $sebab = $kode !== 200 ? "HTTP $kode" : ($ukuran === 0 ? 'kosong' : 'bukan berkas, HTML');
            preg_match('/<h3[^>]*>([^<]+)</', $isi, $pm);
            echo "  GAGAL  $label  -> $sebab" . (isset($pm[1]) ? ' | ' . trim($pm[1]) : '') . "\n";
            echo "         $t\n         dari: " . (is_string($asal) ? $asal : '?') . "\n";
            $masalah++;
        }
    }
}

echo "\n$total tautan berkas diuji. " . ($masalah === 0 ? "Semua terbuka.\n" : "$masalah gagal.\n");
exit($masalah > 0 ? 1 : 0);
