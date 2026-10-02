<?php
/**
 * View: publik/info-loker
 * Dipanggil oleh: LowonganController::pratinjau($kode)
 * Variabel tersedia: $lowongan, $kedaluwarsa
 */
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
<!-- Open Graph: agar pamflet tampil sebagai gambar pratinjau saat tautan dikirim di WhatsApp -->
<meta property="og:title" content="Info Loker: <?= e($lowongan['posisi']) ?> di <?= e($lowongan['nama_perusahaan']) ?>">
<meta property="og:description" content="Batas lamaran <?= tanggalIndo($lowongan['batas_lamaran']) ?>. Lamar lewat KarirKu Polinema.">
<meta property="og:image" content="<?= e($pamfletUrl) ?>">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<?= url('assets/css/style.css') ?>">
</head>
<body style="background:var(--sky)">
<header class="simple-top">
  <div class="container">
    <a class="brand" href="<?= url('beranda') ?>"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu Polinema</span></a>
    <span class="muted" style="margin-left:auto;font-size:.9rem">Info loker dari Career Center</span>
  </div>
</header>
<main class="container" style="max-width:980px;padding:32px 0 60px">
  <div class="detail">
    <?php if ($kedaluwarsa): ?>
      <div class="panel" style="grid-column:1/-1;text-align:center;padding:48px">
        <div class="feature-ic" style="margin:0 auto 14px" data-ic="clock"></div>
        <h1 style="font-size:1.6rem">Info loker ini sudah tidak berlaku</h1>
        <p class="muted">Lowongan sudah ditutup atau melewati batas lamaran.</p>
        <a class="btn btn-primary" href="<?= url('masuk') ?>">Masuk untuk melihat lowongan lain</a>
      </div>
    <?php else: ?>
      <div>
        <div class="poster">
          <img src="<?= e($pamfletUrl) ?>" alt="Pamflet lowongan <?= e($lowongan['posisi']) ?> <?= e($lowongan['nama_perusahaan']) ?>">
          <div class="actions"><a class="btn btn-primary btn-sm" style="flex:1" href="<?= e($pamfletUrl) ?>" download="Pamflet-<?= e(str_replace(' ', '-', $lowongan['posisi'])) ?>.jpg" data-ic="download">Unduh pamflet</a></div>
        </div>
      </div>
      <div class="panel">
        <div class="person" style="margin-bottom:14px">
          <?php if (!empty($lowongan['logo'])): ?>
            <img class="avatar" src="<?= e($origin . url('unduh.php?tipe=logo&file=' . urlencode($lowongan['logo']))) ?>" alt="">
          <?php else: ?>
            <span class="avatar" style="display:inline-flex;align-items:center;justify-content:center;background:var(--blue-soft);color:var(--navy);font-weight:700"><?= e(inisial($lowongan['nama_perusahaan'])) ?></span>
          <?php endif; ?>
          <div><b><?= e($lowongan['nama_perusahaan']) ?></b><small><span data-ic="shield"></span> Mitra terverifikasi Career Center</small></div>
        </div>
        <h1 style="font-size:1.9rem;margin-bottom:6px"><?= e($lowongan['posisi']) ?></h1>
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
        <a class="btn btn-primary" style="width:100%;padding:13px" href="<?= url('masuk') ?>">Lamar lewat KarirKu</a>
        <p class="muted" style="text-align:center;font-size:.88rem;margin-top:12px">Belum punya akun? <a href="<?= url('daftar') ?>">Daftar di sini</a></p>
      </div>
    <?php endif; ?>
  </div>
</main>
<script src="<?= url('assets/js/app.js') ?>"></script>
</body>
</html>
