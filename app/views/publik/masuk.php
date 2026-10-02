<?php
/**
 * View: publik/masuk
 * Dipanggil oleh: AuthController::formMasuk()
 * Variabel tersedia: $emailSebelumnya
 */
$f = flashAmbil();
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Masuk | KarirKu Polinema</title>
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
      <div>
        <q>Keterampilan vokasi, dipertemukan dengan industri yang tepat.</q>
        <p style="opacity:.8;margin-top:14px">Satu akun untuk melamar, memantau lamaran, dan menyimpan data kariermu.</p>
      </div>
    </div>
  </aside>

  <main class="auth-main">
    <div class="auth-box">
      <a class="back" href="<?= url('beranda') ?>"><span data-ic="left"></span>Kembali ke beranda</a>
      <h1 style="font-size:2rem">Masuk</h1>
      <p class="muted">Gunakan email yang kamu daftarkan. Peran akun dikenali otomatis.</p>

      <?php if ($f): ?>
        <div class="alert alert-<?= $f['tipe'] === 'ok' ? 'ok' : ($f['tipe'] === 'warn' ? 'warn' : 'bad') ?>">
          <span data-ic="alert"></span><span><?= e($f['pesan']) ?></span>
        </div>
      <?php endif; ?>

      <form method="post" action="<?= url('auth/proses-masuk') ?>" novalidate>
        <?= csrfField() ?>
        <div class="field">
          <label for="email">Email</label>
          <input class="input" id="email" name="email" type="email" autocomplete="email" placeholder="nama@email.com" value="<?= e($emailSebelumnya) ?>" required>
        </div>
        <div class="field">
          <label for="pw">Kata sandi</label>
          <div class="pw"><input class="input" id="pw" name="password" type="password" autocomplete="current-password" placeholder="Minimal 8 karakter" required><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div>
        </div>
        <div style="display:flex;justify-content:flex-end;align-items:center;margin-bottom:18px">
          <a href="<?= url('auth/lupa-sandi') ?>">Lupa kata sandi?</a>
        </div>
        <button class="btn btn-primary" style="width:100%;padding:13px" type="submit">Masuk</button>
      </form>
      <p style="text-align:center;margin-top:20px">Belum punya akun? <a href="<?= url('daftar') ?>"><b>Daftar</b></a></p>
    </div>
  </main>
</div>

<script src="<?= url('assets/js/app.js') ?>"></script>
</body>
</html>
