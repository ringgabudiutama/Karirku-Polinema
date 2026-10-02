<?php
/**
 * View: publik/lupa-sandi
 * Dipanggil oleh: AuthController::lupaSandi()
 * Variabel tersedia: $tersedia (bool)
 */
$f = flashAmbil();
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Lupa Kata Sandi | KarirKu Polinema</title>
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
      <a class="back" href="<?= url('masuk') ?>"><span data-ic="left"></span>Kembali ke halaman masuk</a>
      <h1 style="font-size:1.8rem">Atur ulang kata sandi</h1>
      <p class="muted">Masukkan email akunmu. Kami kirim tautan untuk membuat kata sandi baru, berlaku 60 menit.</p>

      <?php if ($f): ?>
        <div class="alert alert-<?= $f['tipe'] === 'ok' ? 'ok' : 'bad' ?>"><span data-ic="alert"></span><span><?= e($f['pesan']) ?></span></div>
      <?php endif; ?>

      <?php if (!$tersedia): ?>
        <div class="alert alert-warn"><span data-ic="info"></span><span>Fitur ini belum aktif di server ini. Hubungi Admin/PIC backend untuk menjalankan <code>database/03-tambahan-reset-password.sql</code>.</span></div>
      <?php else: ?>
        <form method="post" action="<?= url('auth/proses-lupa-sandi') ?>">
          <?= csrfField() ?>
          <div class="field"><label for="email">Email</label><input class="input" id="email" name="email" type="email" required placeholder="nama@email.com"></div>
          <button class="btn btn-primary" style="width:100%;padding:13px" type="submit">Kirim tautan reset</button>
        </form>
      <?php endif; ?>
    </div>
  </main>
</div>
<script src="<?= url('assets/js/app.js') ?>"></script>
</body>
</html>
