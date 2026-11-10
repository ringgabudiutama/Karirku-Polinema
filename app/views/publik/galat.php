<?php
/* ===== FRONTEND · PUBLIK · Halaman galat umum (405, 419, 429, 500, 503) =====
   Variabel: $judul (wajib), $pesan (opsional), kode diambil dari http_response_code(). */
$kodeGalat = http_response_code() ?: 500;
$pesan = $pesan ?? [
    405 => 'Alamat ini hanya bisa dibuka lewat tombol di aplikasi, bukan diketik langsung di browser.',
    419 => 'Halaman sudah terlalu lama dibuka sehingga sesinya kedaluwarsa. Muat ulang halaman lalu coba lagi.',
    429 => 'Terlalu banyak permintaan dalam waktu singkat. Tunggu sebentar lalu coba lagi.',
    500 => 'Terjadi gangguan pada server. Data Anda tidak berubah. Coba lagi beberapa saat lagi; bila terus terjadi, hubungi Career Center.',
    503 => 'Sistem sedang dalam pemeliharaan. Coba lagi beberapa saat lagi.',
][$kodeGalat] ?? 'Terjadi kesalahan.';
$peranGalat = class_exists('Auth', false) ? (Auth::penggunaSaatIni()['role'] ?? null) : null;
$tujuanGalat = $peranGalat ? $peranGalat . '/dashboard' : 'beranda';
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
<title><?= (int) $kodeGalat ?> - <?= e($judul) ?> | KarirKu Polinema</title>
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
</head>
<body class="halaman-galat">
  <div class="max-w-460 text-center">
    <h1 class="galat-kode"><?= (int) $kodeGalat ?></h1>
    <h3 class="mb-8"><?= e($judul) ?></h3>
    <p class="muted"><?= e($pesan) ?></p>
    <div class="d-flex flex-wrap justify-center gap-10 mt-16">
      <a class="btn btn-primary" href="<?= url($tujuanGalat) ?>"><?= $peranGalat ? 'Kembali ke dashboard' : 'Kembali ke beranda' ?></a>
      <?php $asalGalat = function_exists('perujukInternal') ? perujukInternal() : null; ?>
      <?php if ($asalGalat): ?>
        <a class="btn btn-outline" href="<?= e(url($asalGalat)) ?>">Kembali ke formulir</a>
      <?php else: ?>
        <a class="btn btn-outline" href="#" data-kembali>Halaman sebelumnya</a>
      <?php endif; ?>
    </div>
    <?php if (!empty($detailTeknis)): ?>
      <details class="detail-teknis"><summary>Detail teknis (hanya tampil saat mode debug)</summary><pre><?= e($detailTeknis) ?></pre></details>
    <?php endif; ?>
  </div>
<script nonce="<?= cspNonce() ?>">
document.addEventListener('click', function (e) {
  var k = e.target.closest && e.target.closest('[data-kembali]');
  if (k) { e.preventDefault(); history.back(); }
});
</script>
</body>
</html>
