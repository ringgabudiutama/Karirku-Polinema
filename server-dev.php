<?php
// Router untuk server bawaan PHP (php -S), pengganti .htaccess saat pengembangan.
// Dipakai oleh jalankan.bat / jalankan.sh.

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$fileAsli = __DIR__ . '/public' . $path;

// Berkas yang benar-benar ada di public/ (unduh.php, manifest) dilayani langsung.
if ($path !== '/' && file_exists($fileAsli) && !is_dir($fileAsli)) {
    if (substr($path, -4) === '.php') {
        require $fileAsli;
        return true;
    }
    return false;
}

// Sisanya (halaman dan /assets/ frontend) lewat public/index.php.
$_GET['url'] = ltrim($path, '/');
require __DIR__ . '/public/index.php';
