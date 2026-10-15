<?php
// ===== ALAT BANTU · Router untuk php -S (pengganti .htaccess) ========

$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$fileAsli = __DIR__ . '/public' . $path;

if ($path !== '/' && file_exists($fileAsli) && !is_dir($fileAsli)) {
    if (substr($path, -4) === '.php') {
        require $fileAsli;
        return true;
    }
    return false;
}

$_GET['url'] = ltrim($path, '/');
require __DIR__ . '/public/index.php';
