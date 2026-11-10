<?php
// ===== FRONTEND · PUBLIK · Lupa kata sandi ===========================
$f = flashAmbil();
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
<title>Lupa Kata Sandi | KarirKu Polinema</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Fraunces:opsz,wght@9..144,500..700&display=swap" rel="stylesheet" media="(max-width: 768px)">
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
</head>
<body>
<div class="auth">
  <!-- ===== Panel gambar kiri ===== -->
  <aside class="auth-side">
    <img src="<?= url('assets/img/login.jpg') ?>" alt="">
    <div class="shade"></div>
    <div class="hero-pattern"></div>
    <div class="auth-side-content">
      <a class="brand" href="<?= url('beranda') ?>"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu Polinema<small>Career Center Politeknik Negeri Malang</small></span></a>
    </div>
  </aside>
  <!-- ===== Form lupa kata sandi ===== -->
  <main class="auth-main">
    <div class="auth-box">
      <a class="back" href="<?= url('masuk') ?>"><span data-ic="left"></span>Kembali ke halaman masuk</a>
      <h1 class="fs-180">Atur ulang kata sandi</h1>
      <p class="muted">Masukkan email akunmu. Kami kirim tautan untuk membuat kata sandi baru, berlaku 60 menit.</p>

      <?php if ($f): ?>
        <div class="alert flash alert-<?= $f['tipe'] === 'ok' ? 'ok' : 'bad' ?>"><span data-ic="alert"></span><span><?= e($f['pesan']) ?></span></div>
      <?php endif; ?>

      <?php if (!$tersedia): ?>
        <div class="alert alert-warn"><span data-ic="info"></span><span>Fitur ini belum aktif di server ini. Hubungi Admin/PIC backend untuk menjalankan <code>database/03-tambahan-reset-password.sql</code>.</span></div>
      <?php else: ?>
        <form method="post" action="<?= url('auth/proses-lupa-sandi') ?>">
          <?= csrfField() ?>
          <div class="field"><label for="email">Email</label><input class="input" id="email" name="email" type="email" required placeholder="nama@email.com" autocomplete="email" value="<?= e((string) old('email', '')) ?>" data-ingat-email></div>
          <button class="btn btn-primary btn-block" type="submit">Kirim tautan reset</button>
        </form>
      <?php endif; ?>
    </div>
  </main>
</div>
<?= skripPemulihanFormulir() ?>
<script src="<?= asetUrl('assets/js/app.js') ?>"></script>
</body>
</html>
