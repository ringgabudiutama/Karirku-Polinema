<?php
// ===== FRONTEND · PUBLIK · Info loker (pratinjau tanpa login) ========
// Dibuka dari tautan WhatsApp/admin jurusan. Hanya lowongan yang sudah
// disetujui Admin (revisi M); selain itu controller menampilkan 404.
$pamfletAbs = urlAbsolut('unduh.php?tipe=pamflet&file=' . urlencode($lowongan['pamflet']));
$kualifikasi = array_values(array_filter(array_map(fn($b) => trim(ltrim(trim($b), "-•*0123456789.) ")), preg_split('/\R/', (string) $lowongan['kualifikasi']))));
$jenisLabel = ['full_time' => 'Penuh waktu', 'part_time' => 'Paruh waktu', 'kontrak' => 'Kontrak', 'magang' => 'Magang', 'freelance' => 'Freelance'];
$sistemLabel = ['wfo' => 'Di kantor (WFO)', 'hybrid' => 'Hybrid', 'wfh' => 'Jarak jauh (WFH)'];
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
<meta name="robots" content="noindex, nofollow">
<title><?= e($lowongan['posisi']) ?> di <?= e($lowongan['nama_perusahaan']) ?> | KarirKu Polinema</title>
<meta property="og:title" content="Info Loker: <?= e($lowongan['posisi']) ?> di <?= e($lowongan['nama_perusahaan']) ?>">
<meta property="og:description" content="Batas lamaran <?= tanggalIndo($lowongan['batas_lamaran']) ?>. Lamar lewat KarirKu Polinema.">
<?php if (!pamfletPdf($lowongan['pamflet'])): ?><meta property="og:image" content="<?= e($pamfletAbs) ?>"><?php endif; ?>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Fraunces:opsz,wght@9..144,500..700&display=swap" rel="stylesheet" media="(max-width: 768px)">
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
</head>
<body class="bg-sky">
<!-- ===== Header ===== -->
<header class="simple-top">
  <div class="container">
    <a class="brand" href="<?= url('beranda') ?>"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu Polinema</span></a>
    <span class="muted ml-auto fs-90 sembunyi-ponsel">Info loker dari Career Center</span>
  </div>
</header>
<!-- ===== Isi info loker ===== -->
<main class="container halaman-info">
  <div class="kepala-halaman"><span></span><?= tombolKembali('beranda', 'Kembali', true) ?></div>
  <div class="detail">
    <div>
      <div class="poster">
        <?= pamfletHtml($lowongan['pamflet'], 'besar', 'Pamflet lowongan ' . $lowongan['posisi'] . ' ' . $lowongan['nama_perusahaan']) ?>
        <div class="actions"><a class="btn btn-primary btn-sm flex-1" href="<?= e($pamfletAbs) ?>" download data-ic="download">Unduh pamflet</a></div>
      </div>
    </div>
    <div class="panel">
      <?php if ($kedaluwarsa): ?>
        <div class="alert alert-warn"><span data-ic="clock"></span><span><b>Lowongan ini sudah tidak menerima lamaran.</b> <?= e($alasanTutup) ?></span></div>
      <?php endif; ?>
      <div class="person mb-14">
        <?php if (!empty($lowongan['logo'])): ?>
          <img class="avatar" src="<?= e(url('unduh.php?tipe=logo&file=' . urlencode($lowongan['logo']))) ?>" alt="">
        <?php else: ?>
          <span class="avatar avatar-inisial"><?= e(inisial($lowongan['nama_perusahaan'])) ?></span>
        <?php endif; ?>
        <div><b><a href="<?= url('mitra/' . (int) $lowongan['perusahaan_id']) ?>"><?= e($lowongan['nama_perusahaan']) ?></a></b><small><span data-ic="shield"></span> Mitra terverifikasi Career Center</small></div>
      </div>
      <h1 class="fs-190 mb-6"><?= e($lowongan['posisi']) ?></h1>
      <div class="meta">
        <span><span data-ic="pin"></span><?= e($lowongan['lokasi']) ?></span>
        <span><span data-ic="briefcase"></span><?= e($jenisLabel[$lowongan['jenis_pekerjaan']] ?? $lowongan['jenis_pekerjaan']) ?></span>
        <span><span data-ic="calendar"></span>Batas <?= tanggalIndo($lowongan['batas_lamaran']) ?></span>
      </div>
      <div class="kv">
        <div><small>Sistem kerja</small><b><?= e($sistemLabel[$lowongan['sistem_kerja']] ?? $lowongan['sistem_kerja']) ?></b></div>
        <div><small>Kuota</small><b><?= (int) $lowongan['kuota'] ?> orang</b></div>
        <div><small>Bidang</small><b><?= e($lowongan['nama_bidang']) ?></b></div>
        <div><small>Jurusan sasaran</small><b><?= e(implode(', ', array_column($jurusanSasaran, 'nama')) ?: 'Semua jurusan') ?></b></div>
      </div>
      <!-- Bug #11: kualifikasi diambil dari isian lowongan, bukan teks contoh. -->
      <h3>Ringkasan kualifikasi</h3>
      <?php if ($kualifikasi): ?>
        <ul class="bullets">
          <?php foreach (array_slice($kualifikasi, 0, 5) as $k): ?><li><?= e($k) ?></li><?php endforeach; ?>
          <?php if (count($kualifikasi) > 5): ?><li class="muted">dan <?= count($kualifikasi) - 5 ?> kualifikasi lain (lihat setelah masuk)</li><?php endif; ?>
        </ul>
      <?php else: ?><p class="muted">Kualifikasi lengkap tersedia setelah masuk.</p><?php endif; ?>
      <h3>Tentang pekerjaan</h3>
      <p><?= e(ringkas((string) $lowongan['deskripsi'], 280)) ?></p>
      <div class="alert alert-info"><span data-ic="lock"></span><span>Detail lengkap dan pengiriman lamaran hanya tersedia untuk mahasiswa dan alumni Polinema yang sudah masuk.</span></div>
      <?php if (!$kedaluwarsa): ?>
        <a class="btn btn-primary btn-block" href="<?= url('masuk') ?>">Lamar lewat KarirKu</a>
      <?php else: ?>
        <a class="btn btn-primary btn-block" href="<?= url('masuk') ?>">Masuk untuk melihat lowongan lain</a>
      <?php endif; ?>
      <p class="muted text-center fs-88 mt-12">Belum punya akun? <a href="<?= url('daftar') ?>">Daftar di sini</a></p>
    </div>
  </div>
</main>
<script src="<?= asetUrl('assets/js/app.js') ?>"></script>
</body>
</html>