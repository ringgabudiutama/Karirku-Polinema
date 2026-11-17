<?php
/* ===== FRONTEND · PUBLIK · Konfirmasi keluar =====
   Muncul bila /keluar dibuka langsung lewat alamat. Keluar sendiri hanya
   lewat tombol POST di bawah (dilindungi token CSRF). */
$peranKeluar = Auth::penggunaSaatIni()['role'] ?? 'beranda';
?>
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
<title>Keluar | KarirKu Polinema</title>
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
</head>
<body class="halaman-galat">
  <div class="max-w-460 text-center">
    <h3 class="mb-8">Keluar dari KarirKu?</h3>
    <p class="muted">Sesi di perangkat ini akan diakhiri, termasuk &ldquo;Ingat saya&rdquo;.</p>
    <div class="d-flex flex-wrap justify-center gap-10 mt-16">
      <form method="post" action="<?= url('keluar') ?>"><?= csrfField() ?><button class="btn btn-primary" type="submit">Ya, keluar</button></form>
      <a class="btn btn-outline" href="<?= url($peranKeluar . '/dashboard') ?>">Batal</a>
    </div>
  </div>
</body>
</html>
