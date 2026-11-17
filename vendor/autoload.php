<?php
// Autoloader pustaka pihak ketiga (Dompdf dan PHPMailer).
// Setara dengan hasil "composer install", sehingga laptop tanpa Composer tetap bisa membuat PDF dan mengirim email.

$__petaNamespace = [
    'Dompdf\\'               => __DIR__ . '/dompdf/dompdf/src/',
    'FontLib\\'              => __DIR__ . '/dompdf/php-font-lib/src/FontLib/',
    'Svg\\'                  => __DIR__ . '/dompdf/php-svg-lib/src/Svg/',
    'Masterminds\\'          => __DIR__ . '/masterminds/html5/src/',
    'Sabberworm\\CSS\\'      => __DIR__ . '/sabberworm/php-css-parser/src/',
    'PHPMailer\\PHPMailer\\' => __DIR__ . '/phpmailer/phpmailer/src/',
];

spl_autoload_register(static function (string $kelas) use ($__petaNamespace): void {
    if ($kelas === 'Dompdf\\Cpdf') {
        require __DIR__ . '/dompdf/dompdf/lib/Cpdf.php';
        return;
    }
    foreach ($__petaNamespace as $awalan => $folder) {
        if (strncmp($kelas, $awalan, strlen($awalan)) === 0) {
            $berkas = $folder . str_replace('\\', '/', substr($kelas, strlen($awalan))) . '.php';
            if (is_file($berkas)) {
                require $berkas;
            }
            return;
        }
    }
});

require_once __DIR__ . '/sabberworm/php-css-parser/src/Rule/Rule.php';
require_once __DIR__ . '/sabberworm/php-css-parser/src/RuleSet/RuleContainer.php';
unset($__petaNamespace);
