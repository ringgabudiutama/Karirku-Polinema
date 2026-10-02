<?php
/**
 * View: publik/reset-sandi
 * Dipanggil oleh: AuthController::resetSandi($token)
 * Variabel tersedia: $token
 */
$f = flashAmbil();
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Buat Kata Sandi Baru | KarirKu Polinema</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<?= url('assets/css/style.css') ?>">
</head>
<body>
<div class="auth">
  <aside class="auth-side">
    <img src="<?= url('assets/img/login.jpg') ?>" alt="">
    <div class="shade"></div>
    <div class="hero-pattern"></div>
    <div class="auth-side-content">
      <a class="brand" href="<?= url('beranda') ?>" style="color:#fff"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu Polinema<small>Career Center Politeknik Negeri Malang</small></span></a>
    </div>
  </aside>
  <main class="auth-main">
    <div class="auth-box">
      <h1 style="font-size:1.8rem">Buat kata sandi baru</h1>
      <p class="muted">Tautan ini berlaku sekali pakai. Kata sandi baru minimal 8 karakter.</p>

      <?php if ($f): ?>
        <div class="alert alert-bad"><span data-ic="alert"></span><span><?= e($f['pesan']) ?></span></div>
      <?php endif; ?>

      <form method="post" action="<?= url('auth/proses-reset-sandi/' . $token) ?>">
        <?= csrfField() ?>
        <div class="field"><label for="password">Kata sandi baru</label><div class="pw"><input class="input" id="password" name="password" type="password" required minlength="8" placeholder="Minimal 8 karakter"><button type="button" data-ic="eye"></button></div></div>
        <div class="field"><label for="konfirmasi">Ulangi kata sandi</label><div class="pw"><input class="input" id="konfirmasi" name="konfirmasi_password" type="password" required placeholder="Ketik ulang"><button type="button" data-ic="eye"></button></div></div>
        <button class="btn btn-primary" style="width:100%;padding:13px" type="submit">Simpan kata sandi baru</button>
      </form>
    </div>
  </main>
</div>
<script src="<?= url('assets/js/app.js') ?>"></script>
</body>
</html>
