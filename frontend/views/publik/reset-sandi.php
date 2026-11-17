<?php
// ===== FRONTEND · PUBLIK · Buat kata sandi baru ======================
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
<title>Buat Kata Sandi Baru | KarirKu Polinema</title>
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
  <!-- ===== Form kata sandi baru ===== -->
  <main class="auth-main">
    <div class="auth-box">
      <a class="back" href="<?= url('masuk') ?>"><span data-ic="left"></span>Kembali ke halaman masuk</a>
      <h1 class="fs-180">Buat kata sandi baru</h1>
      <p class="muted">Tautan ini berlaku sekali pakai. Kata sandi baru minimal 8 karakter.</p>

      <?php if ($f): ?>
        <div class="alert flash alert-bad"><span data-ic="alert"></span><span><?= e($f["pesan"]) ?></span></div>
      <?php endif; ?>

      <form method="post" action="<?= url('auth/proses-reset-sandi/' . $token) ?>">
        <?= csrfField() ?>
        <div class="field"><label for="password">Kata sandi baru</label><div class="pw"><input class="input" id="password" name="password" data-panduan-sandi autocomplete="new-password" type="password" required minlength="8" placeholder="Minimal 8 karakter"><button type="button" data-ic="eye"></button></div></div>
        <div class="field"><label for="konfirmasi">Ulangi kata sandi</label><div class="pw"><input class="input" id="konfirmasi" name="konfirmasi_password" type="password" required placeholder="Ketik ulang"><button type="button" data-ic="eye"></button></div></div>
        <button class="btn btn-primary btn-block" type="submit">Simpan kata sandi baru</button>
      </form>
    </div>
  </main>
</div>
<?= skripPemulihanFormulir() ?>
<script src="<?= asetUrl('assets/js/app.js') ?>"></script>
</body>
</html>
