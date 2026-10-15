<?php
// ===== FRONTEND · PUBLIK · Info loker (pratinjau tanpa login) ========
$origin = (($_SERVER['HTTPS'] ?? 'off') !== 'off' ? 'https' : 'http') . '://' . ($_SERVER['HTTP_HOST'] ?? 'localhost');
$pamfletUrl = $origin . url('unduh.php?tipe=pamflet&file=' . urlencode($lowongan['pamflet']));
$jurusanSasaran = (new Lowongan())->jurusanSasaran((int) $lowongan['id']);
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title><?= e($lowongan['posisi']) ?> di <?= e($lowongan['nama_perusahaan']) ?> | KarirKu Polinema</title>
<meta property="og:title" content="Info Loker: <?= e($lowongan['posisi']) ?> di <?= e($lowongan['nama_perusahaan']) ?>">
<meta property="og:description" content="Batas lamaran <?= tanggalIndo($lowongan['batas_lamaran']) ?>. Lamar lewat KarirKu Polinema.">
<meta property="og:image" content="<?= e($pamfletUrl) ?>">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<?= url('assets/css/style.css') ?>">
</head>
<body class="bg-sky">
<!-- ===== Header ===== -->
<header class="simple-top">
  <div class="container">
    <a class="brand" href="<?= url('beranda') ?>"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu Polinema</span></a>
    <span class="muted ml-auto fs-90">Info loker dari Career Center</span>
  </div>
</header>
<!-- ===== Isi info loker ===== -->
<main class="container halaman-info">
  <div class="detail">
    <?php if ($kedaluwarsa): ?>
      <div class="panel kolom-penuh text-center p-48">
        <div class="feature-ic m-0 mx-auto mb-14" data-ic="clock"></div>
        <h1 class="fs-160">Info loker ini sudah tidak berlaku</h1>
        <p class="muted">Lowongan sudah ditutup atau melewati batas lamaran.</p>
        <a class="btn btn-primary" href="<?= url('masuk') ?>">Masuk untuk melihat lowongan lain</a>
      </div>
    <?php else: ?>
      <div>
        <div class="poster">
          <img src="<?= e($pamfletUrl) ?>" alt="Pamflet lowongan <?= e($lowongan['posisi']) ?> <?= e($lowongan['nama_perusahaan']) ?>">
          <div class="actions"><a class="btn btn-primary btn-sm flex-1" href="<?= e($pamfletUrl) ?>" download="Pamflet-<?= e(str_replace(' ', '-', $lowongan['posisi'])) ?>.jpg" data-ic="download">Unduh pamflet</a></div>
        </div>
      </div>
      <div class="panel">
        <div class="person mb-14">
          <?php if (!empty($lowongan['logo'])): ?>
            <img class="avatar" src="<?= e($origin . url('unduh.php?tipe=logo&file=' . urlencode($lowongan['logo']))) ?>" alt="">
          <?php else: ?>
            <span class="avatar avatar-inisial"><?= e(inisial($lowongan['nama_perusahaan'])) ?></span>
          <?php endif; ?>
          <div><b><?= e($lowongan['nama_perusahaan']) ?></b><small><span data-ic="shield"></span> Mitra terverifikasi Career Center</small></div>
        </div>
        <h1 class="fs-190 mb-6"><?= e($lowongan['posisi']) ?></h1>
        <div class="meta">
          <span><span data-ic="pin"></span><?= e($lowongan['lokasi']) ?></span>
          <span><span data-ic="briefcase"></span><?= e(ucwords(str_replace('_', ' ', $lowongan['jenis_pekerjaan']))) ?></span>
          <span><span data-ic="calendar"></span>Batas <?= tanggalIndo($lowongan['batas_lamaran']) ?></span>
        </div>
        <div class="kv">
          <div><small>Sistem kerja</small><b><?= e(strtoupper($lowongan['sistem_kerja'])) ?></b></div>
          <div><small>Kuota</small><b><?= (int) $lowongan['kuota'] ?> orang</b></div>
          <div><small>Bidang</small><b><?= e($lowongan['nama_bidang']) ?></b></div>
          <div><small>Jurusan sasaran</small><b><?= e(implode(', ', array_column($jurusanSasaran, 'nama')) ?: 'Semua jurusan') ?></b></div>
        </div>
        <h3>Ringkasan kualifikasi</h3>
        <ul class="bullets">
          <li>Lulusan D-III atau D-IV Politeknik Negeri Malang</li>
          <li>Menguasai keterampilan dasar di bidang <?= e(mb_strtolower($lowongan['nama_bidang'])) ?></li>
          <li>Mampu bekerja dalam tim dan siap belajar</li>
        </ul>
        <div class="alert alert-info"><span data-ic="lock"></span><span>Detail lengkap dan pengiriman lamaran hanya tersedia untuk mahasiswa dan alumni Polinema yang sudah masuk.</span></div>
        <a class="btn btn-primary btn-block" href="<?= url('masuk') ?>">Lamar lewat KarirKu</a>
        <p class="muted text-center fs-88 mt-12">Belum punya akun? <a href="<?= url('daftar') ?>">Daftar di sini</a></p>
      </div>
    <?php endif; ?>
  </div>
</main>
<script src="<?= url('assets/js/app.js') ?>"></script>
</body>
</html>
