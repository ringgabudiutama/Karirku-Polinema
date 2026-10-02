<?php
/**
 * Mengirim SETIAP form POST di aplikasi, memakai persis field yang dirender
 * view-nya, lalu memeriksa apakah ada PHP warning / fatal / exception.
 * Tujuannya menangkap kasus seperti whatsapp_pic: kolom NOT NULL di database
 * tetapi field-nya tidak pernah ada di form.
 */
$B = 'http://127.0.0.1:8000';
$jarDir = '/tmp/claude-0/-home-claude/34c7d75d-6ec8-5e75-91f4-7f39653d6878/scratchpad';

function req(string $url, array $post = null, string $jar = ''): array {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true, CURLOPT_FOLLOWLOCATION => false,
        CURLOPT_COOKIEJAR => $jar, CURLOPT_COOKIEFILE => $jar,
    ]);
    if ($post !== null) { curl_setopt($ch, CURLOPT_POST, true); curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($post)); }
    $body = curl_exec($ch);
    $kode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return [$kode, $body];
}
function login(string $B, string $email, string $pass, string $jar): void {
    @unlink($jar);
    [, $h] = req("$B/masuk", null, $jar);
    preg_match('/name="csrf_token" value="([^"]+)"/', $h, $m);
    req("$B/auth/proses-masuk", ['csrf_token' => $m[1], 'email' => $email, 'password' => $pass], $jar);
}

/** Ambil semua form dari sebuah halaman beserta field dan nilai bawaannya. */
function formDi(string $html, string $B): array {
    $hasil = [];
    if (!preg_match_all('/<form\b[^>]*>.*?<\/form>/is', $html, $fm)) return $hasil;
    foreach ($fm[0] as $f) {
        if (!preg_match('/method=["\']?post/i', $f)) continue;
        preg_match('/action=["\']([^"\']*)["\']/', $f, $am);
        $action = $am[1] ?? '';
        if ($action === '' || str_contains($action, 'keluar')) continue;

        $data = [];
        // input biasa
        preg_match_all('/<input\b[^>]*>/i', $f, $im);
        foreach ($im[0] as $inp) {
            if (!preg_match('/name=["\']([^"\']+)["\']/', $inp, $nm)) continue;
            $nama = $nm[1];
            if (preg_match('/type=["\']?(file|submit|button)/i', $inp)) continue;
            preg_match('/value=["\']([^"\']*)["\']/', $inp, $vm);
            $nilai = $vm[1] ?? '';
            if (preg_match('/type=["\']?(checkbox|radio)/i', $inp)) {
                if (!preg_match('/\bchecked\b/i', $inp)) continue;
            }
            if ($nilai === '' && preg_match('/type=["\']?(date)/i', $inp))   $nilai = '2026-12-01';
            if ($nilai === '' && preg_match('/type=["\']?(time)/i', $inp))   $nilai = '09:00';
            if ($nilai === '' && preg_match('/type=["\']?(number)/i', $inp)) $nilai = '2';
            if ($nilai === '' && preg_match('/type=["\']?(url)/i', $inp))    $nilai = 'https://contoh.test/x';
            if ($nilai === '' && preg_match('/type=["\']?(email)/i', $inp))  $nilai = '';
            if ($nilai === '' && $nama !== 'csrf_token')                     $nilai = $nilai ?: 'Uji Otomatis';
            $data[$nama] = $nilai;
        }
        // textarea
        preg_match_all('/<textarea\b[^>]*name=["\']([^"\']+)["\'][^>]*>(.*?)<\/textarea>/is', $f, $tm, PREG_SET_ORDER);
        foreach ($tm as $t) $data[$t[1]] = trim($t[2]) ?: 'Catatan uji otomatis.';
        // select: ambil option pertama yang punya value
        preg_match_all('/<select\b[^>]*name=["\']([^"\']+)["\'][^>]*>(.*?)<\/select>/is', $f, $sm, PREG_SET_ORDER);
        foreach ($sm as $s) {
            $nama = $s[1];
            preg_match_all('/<option[^>]*value=["\']([^"\']*)["\'][^>]*>/i', $s[2], $om);
            $pilih = '';
            foreach ($om[1] as $v) { if ($v !== '') { $pilih = $v; break; } }
            $data[rtrim($nama, '[]')] = $pilih;
        }
        if (!isset($data['csrf_token'])) continue;
        $hasil[] = ['action' => $action, 'data' => $data];
    }
    return $hasil;
}

$peran = [
  'mahasiswa'  => ['mahasiswa@polinema.ac.id', 'mahasiswa123', ['mahasiswa/profil','mahasiswa/pengaturan-akun','lowongan/daftar','__lamar__']],
  'perusahaan' => ['perusahaan@polinema.ac.id','perusahaan123',['perusahaan/profil','perusahaan/pengaturan-akun','lowongan/form-pasang','__pelamar__']],
  'admin'      => ['admin@polinema.ac.id',     'admin123',     ['admin/pengaturan','admin/kelola-pengguna','kirim-loker/index']],
];

$polaGalat = '/Fatal error|Parse error|Warning:|Notice:|Deprecated:|Uncaught|SQLSTATE/i';
$masalah = 0; $diuji = 0;

foreach ($peran as $nama => [$email, $pass, $halaman]) {
    $jar = "$jarDir/jar-uji-$nama";
    login($B, $email, $pass, $jar);
    echo "=== $nama ===\n";
    foreach ($halaman as $h) {
        // halaman yang alamatnya harus ditemukan dulu dari daftar
        if ($h === '__lamar__') {
            [, $d] = req("$B/lowongan/daftar", null, $jar);
            if (!preg_match('#href="[^"]*lowongan/detail/(\d+)"#', $d, $dm)) continue;
            $h = 'lamaran/kirim/' . $dm[1];
        }
        if ($h === '__pelamar__') {
            [, $d] = req("$B/perusahaan/pelamar", null, $jar);
            if (!preg_match('#href="[^"]*detail-pelamar/(\d+)"#', $d, $dm)) continue;
            $h = 'lamaran/detail-pelamar/' . $dm[1];
        }
        [, $html] = req("$B/$h", null, $jar);
        foreach (formDi($html, $B) as $form) {
            $diuji++;
            $url = str_starts_with($form['action'], 'http') ? $form['action'] : "$B/" . ltrim($form['action'], '/');
            [$kode, $body] = req($url, $form['data'], $jar);
            $jalur = parse_url($url, PHP_URL_PATH);
            if (preg_match($polaGalat, $body, $g)) {
                echo "  GAGAL  $jalur  (dari /$h)\n";
                preg_match('/(Fatal error|Warning|Notice|Deprecated|Uncaught)[^\n<]{0,180}/i', strip_tags($body), $pesan);
                echo "         " . trim($pesan[0] ?? $g[0]) . "\n";
                $masalah++;
            } else {
                echo "  ok     $jalur  ($kode)\n";
            }
        }
    }
}
echo "\n$diuji form diuji. " . ($masalah === 0 ? "Semua bersih.\n" : "$masalah bermasalah.\n");
