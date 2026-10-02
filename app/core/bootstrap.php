<?php
/**
 * Bootstrap aplikasi
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * File tambahan (di luar daftar kerangka awal) untuk menyatukan urutan
 * pemuatan: config -> session -> autoload kelas -> helper -> siap dipakai
 * Router. Dibuat terpisah dari public/index.php supaya index.php tetap
 * pendek dan gampang dibaca sebagai front controller.
 */

$config = require __DIR__ . '/../config/config.php';

date_default_timezone_set($config['zona_waktu']);
if ($config['debug']) {
    ini_set('display_errors', '1');
    error_reporting(E_ALL);
} else {
    ini_set('display_errors', '0');
    error_reporting(0);
}

session_name($config['sesi_nama']);
session_start();

/** Autoload otomatis: Controller/Model/Service/Middleware/Core sesuai nama file = nama kelas. */
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

require_once __DIR__ . '/../helpers/keamanan.php';
require_once __DIR__ . '/../helpers/validasi.php';
require_once __DIR__ . '/../helpers/format.php';

/** Bikin URL relatif terhadap base_url aplikasi (lihat app/config/config.php). */
function url(string $path = ''): string
{
    global $config;
    $base = rtrim($config['base_url'], '/');
    return $base . '/' . ltrim($path, '/');
}

/**
 * Sama seperti url(), tapi menambahkan ?v=<waktu file terakhir diubah> di
 * belakangnya. Dipakai khusus untuk aset statis (CSS/JS) supaya browser
 * pengguna otomatis ambil versi baru setiap file itu diedit di server,
 * tanpa mereka perlu hard refresh / bersihkan cache secara manual.
 */
function asetUrl(string $path): string
{
    $fileFisik = __DIR__ . '/../../public/' . ltrim($path, '/');
    $versi = is_file($fileFisik) ? filemtime($fileFisik) : time();
    return url($path) . '?v=' . $versi;
}

/* ---------------------------------------------------------------------------
 * FLASH MESSAGE: pesan sekali-tampil setelah redirect (dipakai oleh
 * Controller::flash() dan view layouts untuk menampilkannya).
 * ------------------------------------------------------------------------ */
function flashAmbil(): ?array
{
    if (empty($_SESSION['flash'])) {
        return null;
    }
    $f = $_SESSION['flash'];
    unset($_SESSION['flash']);
    return $f;
}

/* ---------------------------------------------------------------------------
 * NOTIFIKASI: dipakai layouts/topbar untuk ikon lonceng, sengaja fungsi
 * global (bukan lewat NotifikasiService) supaya bisa dipanggil langsung
 * dari file view mana pun tanpa perlu instance controller.
 * ------------------------------------------------------------------------ */
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