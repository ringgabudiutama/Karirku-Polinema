<?php
/**
 * Router untuk PHP built-in web server (mode pengembangan, tanpa Apache).
 *
 * Dipakai oleh perintah:
 *     php -S localhost:8000 -t public server-dev.php
 *
 * Gunanya menggantikan public/.htaccess, karena PHP built-in server tidak
 * membaca file .htaccess. Logikanya sama persis: kalau yang diminta browser
 * adalah file asli (CSS, JS, gambar) maka langsung disajikan; selain itu
 * dilempar ke public/index.php dengan path aslinya dikirim sebagai "url".
 */

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$fileAsli = __DIR__ . '/public' . $path;

// File asli (aset, gambar, cek-sistem.php, unduh.php) disajikan apa adanya.
if ($path !== '/' && file_exists($fileAsli) && !is_dir($fileAsli)) {
    if (substr($path, -4) === '.php') {
        require $fileAsli;
        return true;
    }
    return false; // biarkan PHP built-in server yang menyajikan
}

$_GET['url'] = ltrim($path, '/');
require __DIR__ . '/public/index.php';
