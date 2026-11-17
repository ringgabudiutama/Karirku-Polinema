<?php
// ===== FRONTEND · PUBLIK · Detail perusahaan mitra (revisi A) =========
// Bisa dibuka sebelum login dari bagian "Perusahaan mitra" di beranda.
$logoUrl = !empty($mitra['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($mitra['logo'])) : null;
$website = $mitra['website'] ? (preg_match('#^https?://#i', $mitra['website']) ? $mitra['website'] : 'https://' . $mitra['website']) : null;
$sudahMasuk = Auth::sudahLogin();
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, interactive-widget=resizes-content">
<meta name="theme-color" content="#ffffff">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<meta name="apple-mobile-web-app-title" content="KarirKu">
<link rel="manifest" href="<?= url('manifest.webmanifest') ?>">
<link rel="icon" type="image/png" sizes="192x192" href="<?= url('assets/img/ikon-192.png') ?>">
<link rel="apple-touch-icon" href="<?= url('assets/img/ikon-180.png') ?>">
<title><?= e($mitra['nama_perusahaan']) ?> | Mitra KarirKu Polinema</title>
<meta name="description" content="<?= e(ringkas((string) ($mitra['deskripsi'] ?: $mitra['nama_perusahaan'] . ' adalah perusahaan mitra Career Center Politeknik Negeri Malang.'), 150)) ?>">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Fraunces:opsz,wght@9..144,500..700&display=swap" rel="stylesheet" media="(max-width: 768px)">
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
</head>
<body class="bg-sky">
<header class="simple-top">
  <div class="container">
    <a class="brand" href="<?= url('beranda') ?>"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu Polinema</span></a>
    <a class="btn btn-sm btn-primary ml-auto" href="<?= url($sudahMasuk ? (Auth::penggunaSaatIni()['role'] . '/dashboard') : 'masuk') ?>"><?= $sudahMasuk ? 'Dashboard' : 'Masuk' ?></a>
  </div>
</header>
<main class="container halaman-info">
  <div class="kepala-halaman">
    <div class="crumb"><a href="<?= url('beranda') ?>#mitra">Perusahaan mitra</a> <span>/</span> <span><?= e($mitra['nama_perusahaan']) ?></span></div>
    <?= tombolKembali('beranda', 'Kembali', true) ?>
  </div>
  <div class="panel">
    <div class="person mb-14">
      <?php if ($logoUrl): ?><img class="avatar-64" src="<?= e($logoUrl) ?>" alt="Logo <?= e($mitra['nama_perusahaan']) ?>"><?php else: ?><span class="avatar-inisial avatar-64 fs-120"><?= e(inisial($mitra['nama_perusahaan'])) ?></span><?php endif; ?>
      <div><h1 class="fs-160 m-0"><?= e($mitra['nama_perusahaan']) ?></h1><small class="text-ok"><span data-ic="shield"></span> Mitra terverifikasi Career Center</small></div>
    </div>
    <dl class="dl">
      <dt>Bidang usaha</dt><dd><?= e($mitra['bidang_usaha']) ?></dd>
      <dt>Jenis</dt><dd><?= e($mitra['jenis_perusahaan']) ?></dd>
      <dt>Lokasi</dt><dd><?= e(implode(', ', array_filter([$mitra['kota'], $mitra['provinsi'] ?? null]))) ?></dd>
      <dt>Website</dt><dd><?= $website ? '<a href="' . e($website) . '" target="_blank" rel="noopener nofollow">' . e($mitra['website']) . '</a>' : '-' ?></dd>
    </dl>
    <h3>Tentang perusahaan</h3>
    <p><?= nl2br(e($mitra['deskripsi'] ?: $mitra['nama_perusahaan'] . ' telah bermitra dengan Career Center Politeknik Negeri Malang.')) ?></p>
  </div>
  <div class="panel">
    <h3>Lowongan yang sedang dibuka (<?= count($lowongan) ?>)</h3>
    <?php if (!$lowongan): ?><p class="muted">Belum ada lowongan aktif dari perusahaan ini.</p><?php endif; ?>
    <div class="loker-grid">
      <?php foreach ($lowongan as $l): ?>
        <a class="loker-kartu" href="<?= url('info-loker/' . $l['kode_pratinjau']) ?>">
          <h3><?= e($l['posisi']) ?></h3>
          <div class="meta"><span><?= e($l['lokasi']) ?></span><span><?= e(strtoupper($l['sistem_kerja'])) ?></span></div>
          <div class="meta">Lamar sebelum <?= tanggalIndo($l['batas_lamaran']) ?></div>
        </a>
      <?php endforeach; ?>
    </div>
    <p class="muted fs-88 mt-12">Untuk melamar, <a href="<?= url('masuk') ?>">masuk</a> dengan akun mahasiswa atau alumni Polinema.</p>
  </div>
</main>
<script src="<?= asetUrl('assets/js/app.js') ?>"></script>
</body>
</html>