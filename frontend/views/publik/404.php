<?php /* ===== FRONTEND · PUBLIK · Halaman 404 (tidak ditemukan) ===== */ ?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, interactive-widget=resizes-content">
<meta name="theme-color" content="#ffffff">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<meta name="apple-mobile-web-app-title" content="KarirKu">
<link rel="manifest" href="<?= url('manifest.webmanifest') ?>">
<link rel="icon" type="image/png" sizes="192x192" href="<?= url('assets/img/ikon-192.png') ?>">
<link rel="apple-touch-icon" href="<?= url('assets/img/ikon-180.png') ?>">
<title>404 - Halaman Tidak Ditemukan | KarirKu Polinema</title>
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
</head>
<body class="halaman-galat">
  <?php $peran404 = class_exists('Auth', false) ? (Auth::penggunaSaatIni()['role'] ?? null) : null; ?>
  <div class="max-w-460 text-center">
    <h1 class="galat-kode">404</h1>
    <h3>Halaman tidak ditemukan</h3>
    <p class="muted">Tautan yang kamu buka mungkin sudah tidak berlaku, belum disetujui, atau salah ketik.</p>
    <div class="d-flex flex-wrap justify-center gap-10 mt-16">
      <a class="btn btn-primary" href="<?= url($peran404 ? $peran404 . '/dashboard' : 'beranda') ?>"><?= $peran404 ? 'Kembali ke dashboard' : 'Kembali ke beranda' ?></a>
      <a class="btn btn-outline" href="#" data-kembali>Halaman sebelumnya</a>
    </div>
  </div>
<script nonce="<?= cspNonce() ?>">
document.addEventListener('click', function (e) {
  var k = e.target.closest && e.target.closest('[data-kembali]');
  if (k) { e.preventDefault(); history.back(); }
});
</script>
</body>
</html>
