<?php /* ===== FRONTEND · PUBLIK · Halaman 403 (akses ditolak) ===== */ ?>
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
<title>403 - Akses Ditolak | KarirKu Polinema</title>
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
</head>
<body class="halaman-galat">
  <div class="max-w-460">
    <h1 class="galat-kode">403</h1>
    <h3>Halaman ini bukan untuk peranmu</h3>
    <?php
      $peranKini = class_exists('Auth') ? (Auth::penggunaSaatIni()['role'] ?? null) : null;
      $tujuan = [
          'mahasiswa'  => ['mahasiswa/dashboard', 'Dashboard mahasiswa'],
          'perusahaan' => ['perusahaan/dashboard', 'Dashboard perusahaan'],
          'admin'      => ['admin/dashboard', 'Dashboard admin'],
      ][$peranKini] ?? null;
    ?>
    <?php if (!empty($pesanTambahan)): ?>
    <p class="muted"><?= e($pesanTambahan) ?></p>
    <?php else: ?>
    <p class="muted">
      <?= $tujuan
            ? 'Kamu sedang masuk sebagai ' . e($peranKini) . '. Halaman yang kamu buka khusus untuk peran lain.'
            : 'Halaman ini khusus untuk peran tertentu. Masuk dengan akun yang sesuai untuk melanjutkan.' ?>
    </p>
    <?php endif; ?>
    <div class="d-flex flex-wrap justify-center gap-10 mt-16">
      <a class="btn btn-outline" href="#" data-kembali>Halaman sebelumnya</a>
      <?php if ($tujuan): ?>
        <a class="btn btn-primary" href="<?= url($tujuan[0]) ?>"><?= e($tujuan[1]) ?></a>
        <a class="btn btn-outline" href="<?= url('beranda') ?>">Beranda</a>
      <?php else: ?>
        <a class="btn btn-primary" href="<?= url('masuk') ?>">Masuk</a>
        <a class="btn btn-outline" href="<?= url('beranda') ?>">Beranda</a>
      <?php endif; ?>
    </div>
  </div>
<script nonce="<?= cspNonce() ?>">
document.addEventListener('click', function (e) {
  var k = e.target.closest && e.target.closest('[data-kembali]');
  if (k) { e.preventDefault(); history.length > 1 ? history.back() : location.href = <?= jsonAman(url('beranda')) ?>; }
});
</script>
</body>
</html>
