<?php
// ===== PINTU MASUK · Pengirim berkas statis frontend ===================
// CSS, JS, dan gambar disimpan di frontend/assets (di luar folder public),
// jadi dikirim lewat fungsi ini. Hanya berkas di dalam frontend/assets
// dengan ekstensi yang dikenal yang boleh dibuka.

function kirimAset(string $jalur): void
{
    $folder = realpath(__DIR__ . '/../frontend/assets');
    $jalur = rawurldecode($jalur);
    $berkas = ($folder !== false && !str_contains($jalur, "\0")) ? realpath($folder . '/' . $jalur) : false;

    $jenis = [
        'css' => 'text/css; charset=utf-8', 'js' => 'text/javascript; charset=utf-8',
        'png' => 'image/png', 'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'gif' => 'image/gif',
        'webp' => 'image/webp', 'svg' => 'image/svg+xml', 'ico' => 'image/x-icon',
        'woff' => 'font/woff', 'woff2' => 'font/woff2', 'ttf' => 'font/ttf',
    ];
    $ext = $berkas ? strtolower(pathinfo($berkas, PATHINFO_EXTENSION)) : '';

    if ($berkas === false || !is_file($berkas) || !isset($jenis[$ext])
        || !str_starts_with($berkas, $folder . DIRECTORY_SEPARATOR)) {
        http_response_code(404);
        header('Content-Type: text/plain; charset=utf-8');
        echo 'Berkas tidak ditemukan.';
        return;
    }

    $waktu = filemtime($berkas);
    $etag = '"' . dechex($waktu) . '-' . dechex(filesize($berkas)) . '"';
    header('Content-Type: ' . $jenis[$ext]);
    header('X-Content-Type-Options: nosniff');
    header('ETag: ' . $etag);
    header('Last-Modified: ' . gmdate('D, d M Y H:i:s', $waktu) . ' GMT');
    // Berkas dengan ?v=... (versi) aman disimpan lama di browser.
    header(isset($_GET['v']) ? 'Cache-Control: public, max-age=31536000, immutable' : 'Cache-Control: public, max-age=3600');

    if (trim($_SERVER['HTTP_IF_NONE_MATCH'] ?? '') === $etag) {
        http_response_code(304);
        return;
    }
    header('Content-Length: ' . filesize($berkas));
    readfile($berkas);
}
