<?php
// ===== BACKEND · HELPER · Keamanan ===================================

// --- CSRF ------------------------------------------------------------
function csrfToken(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function csrfField(): string
{
    return '<input type="hidden" name="csrf_token" value="' . e(csrfToken()) . '">';
}

function csrfGantiToken(): void
{
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

/**
 * Revisi G: token formulir kedaluwarsa (misalnya halaman dibiarkan terbuka
 * terlalu lama atau sesi berakhir) TIDAK lagi memunculkan halaman putih.
 * Isian disimpan, pengguna dikembalikan ke formulirnya dengan pesan jelas,
 * dan isian (kecuali kata sandi & berkas) muncul kembali.
 */
function csrfVerifikasi(): void
{
    $kirim = (string) ($_POST['csrf_token'] ?? '');
    if (hash_equals((string) ($_SESSION['csrf_token'] ?? ''), $kirim) && $kirim !== '') {
        return;
    }
    simpanIsianLama();
    $_SESSION['flash'] = ['tipe' => 'warn', 'pesan' =>
        'Sesi formulir sudah kedaluwarsa, jadi data belum disimpan. Isian Anda sudah dikembalikan; '
        . 'periksa lalu kirim ulang. Berkas yang tadi dipilih sudah diamankan dan dipakai otomatis.'];
    $kembali = jalurInternalAman(perujukInternal() ?? '', 'beranda');
    http_response_code(303);
    header('Location: ' . url($kembali));
    exit;
}

/**
 * Revisi #16 (open redirect): tujuan redirect dari input pengguna hanya
 * boleh berupa path internal aplikasi, bukan alamat situs lain.
 */
function jalurInternalAman(?string $tujuan, string $cadangan): string
{
    $tujuan = trim((string) $tujuan);
    if ($tujuan === '' || preg_match('#^[a-z][a-z0-9+.\-]*:#i', $tujuan) || str_starts_with($tujuan, '//')
        || str_contains($tujuan, '\\') || preg_match('/[\x00-\x1f]/', $tujuan)) {
        return $cadangan;
    }
    return ltrim($tujuan, '/');
}

/** Path internal halaman sebelumnya (dari header Referer) bila berasal dari situs ini. */
function perujukInternal(): ?string
{
    $ref = (string) ($_SERVER['HTTP_REFERER'] ?? '');
    if ($ref === '') {
        return null;
    }
    $host = parse_url($ref, PHP_URL_HOST);
    if ($host && $host !== parse_url('http://' . ($_SERVER['HTTP_HOST'] ?? ''), PHP_URL_HOST)) {
        return null;
    }
    global $config;
    $path = (string) parse_url($ref, PHP_URL_PATH);
    $query = parse_url($ref, PHP_URL_QUERY);
    $base = rtrim((string) $config['base_url'], '/');
    if ($base !== '' && str_starts_with($path, $base)) {
        $path = substr($path, strlen($base));
    }
    return ltrim($path, '/') . ($query ? '?' . $query : '');
}

// --- Escape output ---------------------------------------------------
/**
 * URL web yang sah (hanya http/https). FILTER_VALIDATE_URL SAJA tidak cukup:
 * ia meloloskan "javascript://x.com/%0Aalert(1)" dan "vbscript://...".
 */
function urlHttpValid(?string $u): bool
{
    return is_string($u) && preg_match('#^https?://#i', $u) === 1 && filter_var($u, FILTER_VALIDATE_URL) !== false;
}

/** Untuk atribut href: URL bila aman, selain itu '#'. e() hanya meng-escape HTML, tidak memblokir javascript:. */
function tautanAman(?string $u): string
{
    $u = trim((string) $u);
    return urlHttpValid($u) ? $u : '#';
}

/** json_encode yang aman ditaruh di dalam <script> (tidak bisa menutup tag atau memutus string). */
function jsonAman($nilai): string
{
    return json_encode($nilai, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT);
}

function e(?string $s): string
{
    return htmlspecialchars($s ?? '', ENT_QUOTES, 'UTF-8');
}

// --- Password --------------------------------------------------------
function buatHashPassword(string $plain): string
{
    return password_hash($plain, PASSWORD_DEFAULT);
}

function cocokkanPassword(string $plain, string $hash): bool
{
    return password_verify($plain, $hash);
}

// Hash bcrypt (cost 10, sama dengan hash asli) dari password acak yang tidak pernah dipakai.
// Dibandingkan saat email TIDAK terdaftar, supaya waktu responsnya sama dengan email terdaftar
// (tanpa ini selisihnya ± 47 ms: penyerang bisa menyaring email mana yang punya akun).
const HASH_PALSU = '$2y$10$0o.fbTMAsg/SBgdsISop/eotmGJhiN0EGQYoN3hCBvkSEC8GfoIiS';

function cocokkanPasswordAtauPalsu(string $plain, ?string $hash): bool
{
    $ada = is_string($hash) && $hash !== '';
    $cocok = password_verify($plain, $ada ? $hash : HASH_PALSU);
    return $ada && $cocok;
}

function ipKlien(): string
{
    return (string) ($_SERVER['REMOTE_ADDR'] ?? '-');
}

/**
 * Pembatas laju umum, dihitung di DATABASE (tabel percobaan_login), bukan di sesi:
 * membuang cookie tidak mengulang hitungan. Mengembalikan TRUE bila sudah melewati batas
 * (permintaan harus ditolak). Setiap pemanggilan menghitung satu kejadian.
 * $subjek = siapa yang dibatasi (IP atau email); disimpan sebagai hash.
 */
function batasLaju(string $aksi, string $subjek, int $maks, int $menit): bool
{
    $kunci = hash('sha256', 'r|' . $aksi . '|' . mb_strtolower($subjek));
    $baris = Database::fetch(
        'INSERT INTO percobaan_login (kunci, jumlah, waktu_terakhir) VALUES (?, 1, now())
         ON CONFLICT (kunci) DO UPDATE SET
           jumlah = CASE WHEN percobaan_login.waktu_terakhir < now() - make_interval(mins => ?)
                         THEN 1 ELSE percobaan_login.jumlah + 1 END,
           waktu_terakhir = now()
         RETURNING jumlah',
        [$kunci, $menit]
    );
    return (int) ($baris['jumlah'] ?? 0) > $maks;
}

// --- Batas percobaan login -------------------------------------------
// Dihitung di DATABASE (tabel percobaan_login), bukan di sesi: penebak password
// tidak bisa mengulang dari nol dengan membuang cookie.
//   - per (email + IP): maksimal max_percobaan_login (5) kali dalam blokir_menit (15)
//   - per email saja  : 4x lebih longgar (20), menahan serangan dari banyak IP
// Catatan: di belakang reverse proxy, atur agar REMOTE_ADDR berisi IP pengunjung asli.
function loginKunci(string $email): array
{
    $e = mb_strtolower(trim($email));
    $ip = ipKlien();
    return [hash('sha256', 'p|' . $e . '|' . $ip), hash('sha256', 'a|' . $e)];
}

function loginTerlaluBanyakGagal(string $email): bool
{
    $cfg = require __DIR__ . '/../config/config.php';
    [$pasangan, $akun] = loginKunci($email);
    $baris = Database::fetchAll(
        'SELECT kunci, jumlah FROM percobaan_login
          WHERE kunci IN (?, ?) AND waktu_terakhir > now() - make_interval(mins => ?)',
        [$pasangan, $akun, (int) $cfg['blokir_menit']]
    );
    foreach ($baris as $b) {
        $batas = $b['kunci'] === $pasangan ? (int) $cfg['max_percobaan_login'] : (int) $cfg['max_percobaan_login'] * 4;
        if ((int) $b['jumlah'] >= $batas) {
            return true;
        }
    }
    return false;
}

function catatLoginGagal(string $email): void
{
    $cfg = require __DIR__ . '/../config/config.php';
    foreach (loginKunci($email) as $kunci) {
        Database::execute(
            'INSERT INTO percobaan_login (kunci, jumlah, waktu_terakhir) VALUES (?, 1, now())
             ON CONFLICT (kunci) DO UPDATE SET
               jumlah = CASE WHEN percobaan_login.waktu_terakhir < now() - make_interval(mins => ?)
                             THEN 1 ELSE percobaan_login.jumlah + 1 END,
               waktu_terakhir = now()',
            [$kunci, (int) $cfg['blokir_menit']]
        );
    }
}

function resetLoginGagal(string $email): void
{
    Database::execute('DELETE FROM percobaan_login WHERE kunci IN (?, ?)', loginKunci($email));
}

// --- Kode & nama acak ------------------------------------------------
function buatKodePratinjau(): string
{
    return bin2hex(random_bytes(16));
}

function buatNamaFileAcak(string $ekstensi): string
{
    return bin2hex(random_bytes(16)) . '.' . strtolower($ekstensi);
}


/** Sandi sementara acak yang mudah dibacakan (tanpa huruf mirip 0/O, 1/l). Revisi L: isi otomatis. */
function sandiSementaraAcak(): string
{
    $huruf = 'abcdefghjkmnpqrstuvwxyz';
    $angka = '23456789';
    $s = strtoupper($huruf[random_int(0, strlen($huruf) - 1)]);
    for ($i = 0; $i < 5; $i++) $s .= $huruf[random_int(0, strlen($huruf) - 1)];
    for ($i = 0; $i < 4; $i++) $s .= $angka[random_int(0, strlen($angka) - 1)];
    return $s;
}
