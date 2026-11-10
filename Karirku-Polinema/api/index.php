<?php
// ===== DEPLOY · Vercel · Pintu masuk tunggal =========================
// Runtime vercel-php menjalankan PHP built-in server dengan berkas ini sebagai
// router (sama seperti server-dev.php untuk lokal). Semua permintaan masuk ke sini:
//   1. Berkas statis di public/ (CSS, JS, gambar, ikon) dikirim langsung.
//   2. public/*.php (unduh.php, dll.) dijalankan.
//   3. Selain itu diteruskan ke public/index.php (Router aplikasi).
// Berkas di luar public/ (app/, database/, storage/) TIDAK PERNAH dikirim mentah.

$publik = realpath(__DIR__ . '/../public');
$jalur = rawurldecode(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/');

if ($jalur !== '/' && !str_contains($jalur, '..') && !str_contains($jalur, "\0")) {
    $berkas = realpath($publik . $jalur);
    if ($berkas !== false && str_starts_with($berkas, $publik . DIRECTORY_SEPARATOR) && is_file($berkas)
        && !str_starts_with(basename($berkas), '.')) {
        $ext = strtolower(pathinfo($berkas, PATHINFO_EXTENSION));
        if ($ext === 'php') {
            chdir(dirname($berkas));
            require $berkas;
            return;
        }
        $mime = [
            'css' => 'text/css; charset=utf-8', 'js' => 'text/javascript; charset=utf-8', 'json' => 'application/json',
            'webmanifest' => 'application/manifest+json', 'svg' => 'image/svg+xml', 'png' => 'image/png',
            'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'gif' => 'image/gif', 'webp' => 'image/webp', 'ico' => 'image/x-icon',
            'woff' => 'font/woff', 'woff2' => 'font/woff2', 'ttf' => 'font/ttf', 'pdf' => 'application/pdf',
            'html' => 'text/html; charset=utf-8', 'txt' => 'text/plain; charset=utf-8', 'xml' => 'application/xml',
        ][$ext] ?? null;
        if ($mime !== null) {
            header('Content-Type: ' . $mime);
            header('Content-Length: ' . filesize($berkas));
            header('X-Content-Type-Options: nosniff');
            // Aset ber-versi (?v=...) boleh disimpan lama di CDN Vercel dan browser.
            header(isset($_GET['v'])
                ? 'Cache-Control: public, max-age=31536000, s-maxage=31536000, immutable'
                : 'Cache-Control: public, max-age=3600, s-maxage=86400');
            readfile($berkas);
            return;
        }
    }
}

$_GET['url'] = ltrim($jalur, '/');
chdir($publik);
require $publik . '/index.php';
