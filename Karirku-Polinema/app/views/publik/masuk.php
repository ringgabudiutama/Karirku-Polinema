<?php
// ===== FRONTEND · PUBLIK · Halaman masuk (login) =====================
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
<title>Masuk | KarirKu Polinema</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Fraunces:opsz,wght@9..144,500..700&display=swap" rel="stylesheet" media="(max-width: 768px)">
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
<link rel="stylesheet" href="<?= asetUrl('assets/css/hp.css') ?>" media="(max-width: 768px)">
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
      <div>
        <q>Keterampilan vokasi, dipertemukan dengan industri yang tepat.</q>
        <p class="opacity-80 mt-14">Satu akun untuk melamar, memantau lamaran, dan menyimpan data kariermu.</p>
      </div>
    </div>
  </aside>

  <!-- ===== Form masuk ===== -->
  <main class="auth-main">
    <!-- HP: kepala navy (model UI: Masuk) -->
    <div class="hp m-masuk-hero" aria-hidden="false">
      <a class="m-masuk-merek" href="<?= url('beranda') ?>"><img src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt=""><span><b>KarirKu</b><small>Career Center Polinema</small></span></a>
      <h1 class="m-serif">Selamat datang kembali</h1>
      <p>Masuk untuk melanjutkan lamaran dan melihat lowongan terbaru.</p>
    </div>
    <div class="auth-box">
      <a class="back" href="<?= url('beranda') ?>"><span data-ic="left"></span>Kembali ke beranda</a>
      <h1 class="fs-200">Masuk</h1>
      <p class="muted">Gunakan email yang kamu daftarkan. Peran akun dikenali otomatis.</p>

      <?php if ($f): ?>
        <div class="alert flash alert-<?= $f['tipe'] === 'ok' ? 'ok' : ($f['tipe'] === 'warn' ? 'warn' : 'bad') ?>">
          <span data-ic="alert"></span><span><?= e($f['pesan']) ?></span>
        </div>
      <?php endif; ?>

      <form method="post" action="<?= url('auth/proses-masuk') ?>" novalidate>
        <?= csrfField() ?>
        <div class="field">
          <label for="email">Email</label>
          <input class="input" id="email" name="email" type="email" autocomplete="email" placeholder="nama@email.com" value="<?= e($emailSebelumnya) ?>" required data-ingat-email>
        </div>
        <div class="field">
          <label for="pw">Kata sandi</label>
          <div class="pw"><input class="input" id="pw" name="password" type="password" autocomplete="current-password" placeholder="Minimal 8 karakter" required><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div>
        </div>
        <div class="d-flex justify-between items-center flex-wrap gap-10 mb-18">
          <label class="check-inline"><input type="checkbox" name="ingat_saya" value="1"> Ingat saya di perangkat ini</label>
          <a href="<?= url('auth/lupa-sandi') ?>">Lupa kata sandi?</a>
        </div>
        <p class="hint mt-0 mb-12">Centang &ldquo;Ingat saya&rdquo; hanya di perangkat pribadi. Anda tetap masuk sampai 30 hari atau sampai menekan Keluar.</p>
        <button class="btn btn-primary btn-block" type="submit" data-proses="Memeriksa...">Masuk</button>
      </form>
      <p class="text-center mt-20">Belum punya akun? <a href="<?= url('daftar') ?>"><b>Daftar<span class="hp-inline"> sekarang</span></b></a></p>
      <p class="hp m-masuk-catatan"><?= hpIk('shield', 14, 2) ?> Akun diverifikasi oleh Career Center Polinema</p>
    </div>
  </main>
</div>

<?= skripPemulihanFormulir() ?>
<script src="<?= asetUrl('assets/js/app.js') ?>"></script>
</body>
</html>
