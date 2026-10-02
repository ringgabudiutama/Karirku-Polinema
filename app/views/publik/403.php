<?php /** Dipanggil langsung oleh Role::wajib() saat peran tidak cocok.
        PIC frontend boleh timpa tampilannya, tapi file ini harus tetap ada
        di path ini karena dipanggil via require. */ ?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>403 - Akses Ditolak | KarirKu Polinema</title>
<link rel="stylesheet" href="<?= url('assets/css/style.css') ?>">
</head>
<body style="display:flex;align-items:center;justify-content:center;min-height:100vh;background:var(--sky);text-align:center;padding:20px">
  <div style="max-width:460px">
    <h1 style="font-size:3rem;margin-bottom:4px">403</h1>
    <h3>Halaman ini bukan untuk peranmu</h3>
    <?php
      /* Kalau pengguna sudah login, arahkan ke dashboard miliknya sendiri,
         jangan dibiarkan buntu hanya dengan tombol kembali ke beranda. */
      $peranKini = class_exists('Auth') ? (Auth::penggunaSaatIni()['role'] ?? null) : null;
      $tujuan = [
          'mahasiswa'  => ['mahasiswa/dashboard', 'Dashboard mahasiswa'],
          'perusahaan' => ['perusahaan/dashboard', 'Dashboard perusahaan'],
          'admin'      => ['admin/dashboard', 'Dashboard admin'],
      ][$peranKini] ?? null;
    ?>
    <p class="muted">
      <?= $tujuan
            ? 'Kamu sedang masuk sebagai ' . e($peranKini) . '. Halaman yang kamu buka khusus untuk peran lain.'
            : 'Halaman ini khusus untuk peran tertentu. Masuk dengan akun yang sesuai untuk melanjutkan.' ?>
    </p>
    <div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap;margin-top:16px">
      <?php if ($tujuan): ?>
        <a class="btn btn-primary" href="<?= url($tujuan[0]) ?>"><?= e($tujuan[1]) ?></a>
        <a class="btn btn-outline" href="<?= url('beranda') ?>">Beranda</a>
      <?php else: ?>
        <a class="btn btn-primary" href="<?= url('masuk') ?>">Masuk</a>
        <a class="btn btn-outline" href="<?= url('beranda') ?>">Beranda</a>
      <?php endif; ?>
    </div>
  </div>
</body>
</html>
