<?php /** Dipanggil langsung oleh Router::halaman404() dan beberapa controller
        saat data tidak ditemukan. PIC frontend boleh timpa tampilannya,
        tapi file ini harus tetap ada di path ini karena dipanggil via require. */ ?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>404 - Halaman Tidak Ditemukan | KarirKu Polinema</title>
<link rel="stylesheet" href="<?= url('assets/css/style.css') ?>">
</head>
<body style="display:flex;align-items:center;justify-content:center;min-height:100vh;background:var(--sky);text-align:center;padding:20px">
  <div>
    <h1 style="font-size:3rem;margin-bottom:4px">404</h1>
    <h3>Halaman tidak ditemukan</h3>
    <p class="muted">Tautan yang kamu buka mungkin sudah tidak berlaku atau salah ketik.</p>
    <a class="btn btn-primary" href="<?= url('beranda') ?>">Kembali ke Beranda</a>
  </div>
</body>
</html>
