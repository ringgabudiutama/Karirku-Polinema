<?php
// ===== BACKEND · CORE · Bootstrap (dimuat pertama kali) ==============

$config = require __DIR__ . '/../config/config.php';

date_default_timezone_set($config['zona_waktu']);
if ($config['debug']) {
    ini_set('display_errors', '1');
    error_reporting(E_ALL);
} else {
    ini_set('display_errors', '0');
    error_reporting(0);
}

// --- Sesi ------------------------------------------------------------
session_name($config['sesi_nama']);
session_start();

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

// --- Helper ----------------------------------------------------------
require_once __DIR__ . '/../helpers/keamanan.php';
require_once __DIR__ . '/../helpers/validasi.php';
require_once __DIR__ . '/../helpers/format.php';

// --- Fungsi global ---------------------------------------------------
function url(string $path = ''): string
{
    global $config;
    $base = rtrim($config['base_url'], '/');
    return $base . '/' . ltrim($path, '/');
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
        'SELECT * FROM notifikasi WHERE pengguna_id = ? ORDER BY dibuat_pada DESC LIMIT ' . (int) $limit,
        [$penggunaId]
    );
}
