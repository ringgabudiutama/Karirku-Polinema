<?php
// ===== BACKEND · CORE · Bootstrap (dimuat pertama kali) ==============

$config = require __DIR__ . '/../config/config.php';

// base_url kosong = deteksi otomatis dari lokasi index.php. Jadi aplikasi
// tetap benar saat dibuka lewat http://localhost/karirku-polinema/public
// di XAMPP tanpa harus mengubah config.php.
if (($config['base_url'] ?? '') === '' && !in_array(PHP_SAPI, ['cli', 'cli-server'], true)) {
    $folderSkrip = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/'));
    $config['base_url'] = ($folderSkrip === '.' || $folderSkrip === '/') ? '' : rtrim($folderSkrip, '/');
}

date_default_timezone_set($config['zona_waktu']);
if ($config['debug']) {
    ini_set('display_errors', '1');
    error_reporting(E_ALL);
} else {
    ini_set('display_errors', '0');
    error_reporting(0);
}

// --- Header keamanan (revisi J) --------------------------------------
// Dikirim untuk setiap halaman PHP. unduh.php tetap boleh menampilkan PDF
// di <object> pada halaman sendiri karena memakai SAMEORIGIN.
// Nonce CSP: nilai acak PER PERMINTAAN, ditempel pada setiap <script> inline yang sah.
// Skrip suntikan penyerang tidak punya nonce ini, jadi diblokir browser.
$GLOBALS['cspNonce'] = rtrim(strtr(base64_encode(random_bytes(16)), '+/', '-_'), '=');
function cspNonce(): string
{
    return $GLOBALS['cspNonce'] ?? '';
}

if (PHP_SAPI !== 'cli' && !headers_sent()) {
    header_remove('X-Powered-By');
    header('X-Frame-Options: SAMEORIGIN');
    header('X-Content-Type-Options: nosniff');
    header('Referrer-Policy: strict-origin-when-cross-origin');
    header('Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=(), usb=()');
    header('Cross-Origin-Opener-Policy: same-origin');
    header('X-Permitted-Cross-Domain-Policies: none');
    if (koneksiHttps()) {
        header('Strict-Transport-Security: max-age=31536000');   // browser hanya mau HTTPS selama 1 tahun
    }
    // Content-Security-Policy: pertahanan lapis terakhir bila suatu hari ada XSS yang lolos.
    // Skrip hanya dari situs sendiri atau ber-nonce; tanpa 'unsafe-inline' untuk skrip.
    header('Content-Security-Policy: ' . implode('; ', array_filter([
        "default-src 'self'",
        "script-src 'self' 'nonce-" . cspNonce() . "'",
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
        "font-src 'self' https://fonts.gstatic.com data:",
        "img-src 'self' data: blob:",
        "frame-src 'self' https://www.google.com https://maps.google.com",
        "connect-src 'self'",
        "object-src 'self'",
        "base-uri 'self'",
        "form-action 'self'",
        "frame-ancestors 'self'",
        koneksiHttps() ? 'upgrade-insecure-requests' : '',
    ])));
}

// --- Sesi & cookie (revisi J) ----------------------------------------
// HttpOnly: cookie tidak bisa dibaca JavaScript. SameSite=Lax: cookie tidak
// ikut terkirim dari situs lain saat POST. Secure otomatis bila HTTPS.
// Session ID tidak pernah diterima lewat URL.
function koneksiHttps(): bool
{
    return (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https')
        || ((int) ($_SERVER['SERVER_PORT'] ?? 0) === 443);
}

// --- Autoload kelas --------------------------------------------------
spl_autoload_register(function (string $kelas) {
    $folder = ['core', 'controllers', 'models', 'services', 'middleware'];
    foreach ($folder as $f) {
        $path = __DIR__ . '/../' . $f . '/' . $kelas . '.php';
        if (is_file($path)) {
            require_once $path;
            return;
        }
    }
});

if (PHP_SAPI !== 'cli' && !empty($config['serverless'])) {
    // Vercel: tiap permintaan bisa dilayani server berbeda, jadi sesi tidak boleh di berkas.
    session_set_save_handler(new SesiDb(), true);
}

if (PHP_SAPI !== 'cli') {
    ini_set('session.use_strict_mode', '1');
    ini_set('session.use_only_cookies', '1');
    ini_set('session.use_trans_sid', '0');
    ini_set('session.gc_maxlifetime', (string) ($config['sesi_menit'] * 60));
    session_name($config['sesi_nama']);
    session_set_cookie_params([
        'lifetime' => 0,               // cookie sesi hilang saat browser ditutup
        'path'     => '/',
        'secure'   => koneksiHttps(),
        'httponly' => true,
        'samesite' => 'Lax',
    ]);
    session_start();
}

// --- Helper ----------------------------------------------------------
require_once __DIR__ . '/../helpers/keamanan.php';
require_once __DIR__ . '/../helpers/validasi.php';
require_once __DIR__ . '/../helpers/format.php';
require_once __DIR__ . '/../helpers/tampilan.php';
require_once __DIR__ . '/../helpers/profil-item.php';
require_once __DIR__ . '/../helpers/hp.php';

// --- Fungsi global ---------------------------------------------------
function url(string $path = ''): string
{
    global $config;
    $base = rtrim($config['base_url'], '/');
    return $base . '/' . ltrim($path, '/');
}

/**
 * URL lengkap (https://host/...) untuk tautan yang dibuka DI LUAR aplikasi:
 * email reset kata sandi dan pesan WhatsApp ke admin jurusan. Tautan relatif
 * seperti "/info-loker/abc" tidak bisa diklik dari aplikasi WhatsApp/email.
 */
function urlAbsolut(string $path = ''): string
{
    global $config;
    $asal = rtrim((string) ($config['app_url'] ?? ''), '/');
    if ($asal === '') {
        $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
        // Hanya karakter nama host yang sah, untuk mencegah Host header injection.
        $host = preg_match('/^[A-Za-z0-9.\-]+(:\d+)?$/', $host) ? $host : 'localhost';
        $asal = (koneksiHttps() ? 'https' : 'http') . '://' . $host;
    }
    return $asal . url($path);
}

function asetUrl(string $path): string
{
    $fileFisik = __DIR__ . '/../../public/' . ltrim($path, '/');
    $versi = is_file($fileFisik) ? filemtime($fileFisik) : time();
    return url($path) . '?v=' . $versi;
}

function flashAmbil(): ?array
{
    if (empty($_SESSION['flash'])) {
        return null;
    }
    $f = $_SESSION['flash'];
    unset($_SESSION['flash']);
    $f['pesan'] = implode("\n", array_map('pesanRamah', explode("\n", (string) ($f['pesan'] ?? ''))));
    return $f;
}

function jumlahNotifBelumDibaca(int $penggunaId): int
{
    $baris = Database::fetch(
        'SELECT COUNT(*) AS jumlah FROM notifikasi WHERE pengguna_id = ? AND dibaca = FALSE',
        [$penggunaId]
    );
    return (int) ($baris['jumlah'] ?? 0);
}

function notifTerbaru(int $penggunaId, int $limit = 6): array
{
    return Database::fetchAll(
        'SELECT * FROM notifikasi WHERE pengguna_id = ? ORDER BY dibuat_pada DESC, id DESC LIMIT ' . (int) $limit,
        [$penggunaId]
    );
}

// --- Pemulihan isian formulir (revisi G) ------------------------------
// Saat validasi gagal, controller memanggil flash('bad', ...). Pada request
// POST, isian ikut disimpan di sesi (tanpa kata sandi, token, dan berkas)
// lalu dipakai ulang oleh view lewat old('nama_field', nilaiBawaan).
$GLOBALS['_old_input'] = $_SESSION['_old_input'] ?? [];
$GLOBALS['_old_path'] = $_SESSION['_old_path'] ?? '';
unset($_SESSION['_old_input'], $_SESSION['_old_path']);

function simpanIsianLama(): void
{
    if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
        return;
    }
    $isian = $_POST;
    foreach (array_keys($isian) as $k) {
        if (preg_match('/password|sandi|csrf|token/i', (string) $k)) {
            unset($isian[$k]);
        }
    }
    $_SESSION['_old_input'] = $isian;
    $_SESSION['_old_path'] = BerkasSementara::jalur();
}

/**
 * Isian lama untuk JavaScript (initIsianLama): memulihkan SEMUA formulir secara
 * otomatis, termasuk formulir di dalam jendela modal (dibuka kembali), walau
 * view-nya tidak memakai old(). Kata sandi/token tidak pernah ikut.
 */
function skripPemulihanFormulir(): string
{
    $html = class_exists('BerkasSementara') ? BerkasSementara::skrip() : '';
    if (!empty($GLOBALS['_old_input'])) {
        global $config;
        $html .= '<script type="application/json" id="dataIsianLama">'
            . json_encode(['base' => rtrim((string) ($config['base_url'] ?? ''), '/'), 'jalur' => $GLOBALS['_old_path'] ?? '',
                           'isian' => $GLOBALS['_old_input']],
                JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_UNESCAPED_UNICODE | JSON_PARTIAL_OUTPUT_ON_ERROR)
            . '</script>';
    }
    return $html;
}

function old(string $kunci, $bawaan = '')
{
    $isian = $GLOBALS['_old_input'] ?? [];
    return array_key_exists($kunci, $isian) ? $isian[$kunci] : $bawaan;
}

function adaIsianLama(): bool
{
    return !empty($GLOBALS['_old_input']);
}

// --- Halaman galat 500 yang ramah (bukan halaman putih) -------------
set_exception_handler(function (Throwable $e) use ($config) {
    if (Database::inTransactionAman()) {
        Database::rollBack();
    }
    error_log('[KarirKu] ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());
    if (PHP_SAPI === 'cli') {
        throw $e;
    }
    if (!headers_sent()) {
        http_response_code(500);
    }
    // Isian & berkas formulir yang gagal disimpan, supaya tidak perlu diisi ulang.
    simpanIsianLama();
    $judul = 'Terjadi gangguan';
    $pesan = 'Permintaan Anda belum tersimpan karena gangguan di server. Isian formulir Anda (termasuk berkas yang dipilih) '
        . 'sudah diamankan: tekan "Kembali ke formulir" lalu kirim ulang tanpa mengisi dari awal.';
    $detailTeknis = $config['debug']
        ? get_class($e) . ': ' . $e->getMessage() . "\n" . $e->getFile() . ':' . $e->getLine() . "\n\n" . $e->getTraceAsString()
        : null;
    require __DIR__ . '/../views/publik/galat.php';
});

// --- Pemulihan berkas pada formulir yang gagal (revisi G lanjutan) ---
// Awal POST: berkas yang tadi gagal disimpan dipasang kembali ke $_FILES.
// Akhir POST: gagal (pesan merah/kuning, error 500) -> berkas disimpan sementara;
//             berhasil (pesan hijau) -> berkas sementara formulir ini dibuang.
if (PHP_SAPI !== 'cli' && ($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
    BerkasSementara::pasangKeRequest();
    register_shutdown_function(function () {
        try {
            $tipe = $_SESSION['flash']['tipe'] ?? null;
            $gagal = in_array($tipe, ['bad', 'warn'], true) || http_response_code() >= 500;
            $fatal = error_get_last();
            if ($fatal && in_array($fatal['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR], true)) {
                $gagal = true;
                simpanIsianLama();
            }
            if ($gagal) {
                BerkasSementara::simpanDariRequest();
            } elseif ($tipe === 'ok') {
                BerkasSementara::bersihkan();
            }
        } catch (Throwable $e) {
            error_log('[KarirKu] berkas sementara: ' . $e->getMessage());
        }
    });
}

// --- Penjaga sesi: idle timeout, versi sesi, "Ingat saya" (revisi J & L) ---
if (PHP_SAPI !== 'cli') {
    Auth::jagaSesi();
}
