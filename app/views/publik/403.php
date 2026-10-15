<?php /* ===== FRONTEND · PUBLIK · Halaman 403 (akses ditolak) ===== */ ?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>403 - Akses Ditolak | KarirKu Polinema</title>
<link rel="stylesheet" href="<?= url('assets/css/style.css') ?>">
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
    <p class="muted">
      <?= $tujuan
            ? 'Kamu sedang masuk sebagai ' . e($peranKini) . '. Halaman yang kamu buka khusus untuk peran lain.'
            : 'Halaman ini khusus untuk peran tertentu. Masuk dengan akun yang sesuai untuk melanjutkan.' ?>
    </p>
    <div class="d-flex flex-wrap justify-center gap-10 mt-16">
      <?php if ($tujuan): ?>
        <a class="btn btn-primary" href="<?= url($tujuan[0]) ?>"><?= e($tujuan[1]) ?></a>
        <a class="btn btn-outline" href="<?= url('beranda') ?>">Beranda</a>
      <?php else: ?>
        <a class="btn btn-primary" href="<?= url('masuk') ?>">Masuk</a>
        <a class="btn btn-outline" href="<?= url('beranda') ?>">Beranda</a>
      <?php endif; ?>
    </div>
  </div>
</body>
</html>
