<?php
// ===== PINTU MASUK · Semua permintaan dari browser masuk lewat sini ===
//   /assets/...  -> berkas FRONTEND (CSS, JS, gambar) dari frontend/assets
//   selain itu   -> diteruskan ke BACKEND (Router -> Controller -> Model),
//                   lalu Controller menampilkan halaman dari frontend/views

$jalurUrl = ltrim((string) ($_GET['url'] ?? ''), '/');
if (str_starts_with($jalurUrl, 'assets/')) {
    require __DIR__ . '/aset.php';
    kirimAset(substr($jalurUrl, strlen('assets/')));
    exit;
}

require __DIR__ . '/../backend/core/bootstrap.php';

(new Router())->jalankan($_GET['url'] ?? '');
