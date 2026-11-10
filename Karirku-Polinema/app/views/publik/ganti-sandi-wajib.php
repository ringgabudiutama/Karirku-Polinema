<?php /* ===== FRONTEND · PUBLIK · Ganti kata sandi sementara (wajib) ===== */
$f = flashAmbil(); ?>
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
<title>Ganti Kata Sandi | KarirKu Polinema</title>
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
</head>
<body class="halaman-galat">
  <div class="panel max-w-460 w-100">
    <h3 class="mb-8">Ganti kata sandi sementara</h3>
    <p class="muted fs-90">Admin Career Center baru saja mengatur kata sandi sementara untuk akun
      <b><?= e(Auth::penggunaSaatIni()['email']) ?></b>. Demi keamanan, buat kata sandi baru milik Anda sendiri sebelum melanjutkan.</p>
    <?php if ($f): ?><div class="alert flash alert-<?= $f['tipe'] === 'ok' ? 'ok' : 'bad' ?>"><span><?= e($f['pesan']) ?></span></div><?php endif; ?>
    <form method="post" action="<?= url('akun/simpan-sandi-wajib') ?>">
      <?= csrfField() ?>
      <div class="field"><label for="pl">Kata sandi sementara</label><input class="input" id="pl" type="password" name="password_lama" autocomplete="current-password" required></div>
      <div class="field"><label for="pb">Kata sandi baru</label><input class="input" id="pb" data-panduan-sandi type="password" name="password_baru" minlength="8" autocomplete="new-password" required></div>
      <div class="field"><label for="pk">Ulangi kata sandi baru</label><input class="input" id="pk" type="password" name="konfirmasi_password" minlength="8" autocomplete="new-password" required></div>
      <button class="btn btn-primary w-100" type="submit" data-proses="Menyimpan...">Simpan kata sandi baru</button>
    </form>
    <form class="mt-12 text-center" method="post" action="<?= url('keluar') ?>"><?= csrfField() ?><button class="btn btn-link" type="submit">Keluar dulu</button></form>
  </div>
<?= skripPemulihanFormulir() ?>
<script src="<?= asetUrl('assets/js/app.js') ?>"></script>
</body>
</html>
