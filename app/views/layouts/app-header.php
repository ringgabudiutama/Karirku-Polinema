<?php
/**
 * Layout: app-header (sidebar + topbar)
 * PIC: Ringga Budi Utama (Project Lead, UI/UX, dan Frontend)
 *
 * Di-include di baris pertama setiap view mahasiswa/perusahaan/admin.
 * WAJIB set $page_title dan $active_menu sebelum include file ini.
 * Ditutup oleh layouts/app-footer.php di baris terakhir view.
 */
$user = Auth::penggunaSaatIni();
$role = $user['role'];

$namaTampil = $user['email'];
$subTampil = '';
$fotoTampil = url('assets/img/avatar-1.jpg');

if ($role === 'mahasiswa') {
    $mhsShell = (new Mahasiswa())->cariByPenggunaId($user['id']);
    if ($mhsShell) {
        $namaTampil = $mhsShell['nama'];
        $subTampil = $mhsShell['jenjang'] . ' ' . $mhsShell['nama_prodi'];
        if (!empty($mhsShell['foto'])) {
            $fotoTampil = url('unduh.php?tipe=foto&file=' . urlencode($mhsShell['foto']));
        }
    }
} elseif ($role === 'perusahaan') {
    $prshShell = (new Perusahaan())->cariByPenggunaId($user['id']);
    if ($prshShell) {
        $namaTampil = $prshShell['nama_perusahaan'];
        $subTampil = $prshShell['bidang_usaha'];
        if (!empty($prshShell['logo'])) {
            $fotoTampil = url('unduh.php?tipe=logo&file=' . urlencode($prshShell['logo']));
        }
    }
} else {
    $namaTampil = (new Pengguna())->namaTampilan($user['id'], 'admin');
    $subTampil = 'Career Center';
}

$menuMahasiswa = [
    ['dashboard', 'Dashboard', 'home', 'mahasiswa/dashboard'],
    ['lowongan', 'Lowongan', 'briefcase', 'lowongan/daftar'],
    ['disimpan', 'Disimpan', 'bookmark', 'mahasiswa/disimpan'],
    ['lamaran', 'Lamaran Saya', 'file', 'lamaran/lamaran-saya'],
    ['profil', 'Profil Karier', 'user', 'mahasiswa/profil'],
];
$menuPerusahaan = [
    ['dashboard', 'Dashboard', 'home', 'perusahaan/dashboard'],
    ['lowongan', 'Lowongan Saya', 'briefcase', 'perusahaan/lowongan'],
    ['pelamar', 'Pelamar', 'users', 'perusahaan/pelamar'],
    ['profil', 'Profil Perusahaan', 'building', 'perusahaan/profil'],
];
$menuAdmin = [
    ['dashboard', 'Dashboard', 'home', 'admin/dashboard'],
    ['persetujuan', 'Persetujuan Akun', 'shield', 'admin/persetujuan'],
    ['pengguna', 'Kelola Pengguna', 'users', 'admin/kelola-pengguna'],
    ['monitoring', 'Monitoring Lowongan', 'briefcase', 'admin/monitoring-lowongan'],
    ['rekap', 'Rekap Lamaran', 'clipboard', 'admin/rekap-lamaran'],
    ['kirim-loker', 'Kirim Loker ke Jurusan', 'send', 'kirim-loker'],
    ['tracer', 'Tracer Karier', 'chart', 'admin/tracer-karier'],
];
$menuUtama = $role === 'mahasiswa' ? $menuMahasiswa : ($role === 'perusahaan' ? $menuPerusahaan : $menuAdmin);
$labelPeran = $role === 'mahasiswa' ? 'Mahasiswa dan alumni' : ($role === 'perusahaan' ? 'Perusahaan' : 'Career Center');

// Notifikasi berlaku untuk semua peran, termasuk Admin (lonceng topbar +
// halaman Notifikasi, isinya diambil dari tabel notifikasi yang sama
// dengan yang dipakai NotifikasiService::pendaftarBaruUntukAdmin() dan
// NotifikasiService::pelamarDiterima()).
$jumlahNotif = jumlahNotifBelumDibaca($user['id']);
$notifTerbaru = notifTerbaru($user['id'], 5);
$hrefNotif = url('notifikasi/semua');
$hrefPengaturan = $role === 'admin' ? url('admin/pengaturan') : url($role . '/pengaturan-akun');
$hrefProfil = $role === 'admin' ? url('admin/pengaturan') : url($role . '/profil');
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= e($page_title) ?> | KarirKu Polinema</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
</head>
<body>
<div class="app">
  <aside class="side" aria-label="Menu utama">
    <div class="side-inner">
      <a class="brand" href="<?= url($role . '/dashboard') ?>"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu<small><?= e($labelPeran) ?></small></span></a>
      <ul class="menu">
        <?php foreach ($menuUtama as [$key, $label, $iconName, $href]): ?>
        <li><a href="<?= url($href) ?>" data-ic="<?= $iconName ?>" class="<?= $active_menu === $key ? 'active' : '' ?>"><?= e($label) ?></a></li>
        <?php endforeach; ?>
      </ul>
      <div class="side-label">Akun</div>
      <ul class="menu">
        <li><a href="<?= $hrefNotif ?>" data-ic="bell" class="<?= $active_menu === 'notifikasi' ? 'active' : '' ?>">Notifikasi <?php if ($jumlahNotif > 0): ?><span class="count"><?= $jumlahNotif ?></span><?php endif; ?></a></li>
        <li><a href="<?= $hrefPengaturan ?>" data-ic="settings" class="<?= $active_menu === 'pengaturan' ? 'active' : '' ?>">Pengaturan Akun</a></li>
      </ul>
      <div class="side-foot"><a href="<?= url('keluar') ?>" data-ic="logout">Keluar</a></div>
    </div>
  </aside>

  <div class="main">
    <header class="topbar">
      <button class="icon-btn menu-toggle" aria-label="Buka menu" data-ic="menu"></button>
      <b class="top-title"><?= e($page_title) ?></b>
      <div class="top-right">
        <div class="wrap-rel">
          <button class="icon-btn" aria-label="Notifikasi<?= $jumlahNotif > 0 ? ", {$jumlahNotif} belum dibaca" : '' ?>" data-pop="popN" data-ic="bell"><?php if ($jumlahNotif > 0): ?><span class="dot"><?= $jumlahNotif ?></span><?php endif; ?></button>
          <div class="pop" id="popN">
            <div class="pop-head">Notifikasi <a href="<?= url('notifikasi/tandai-semua-dibaca') ?>">Tandai dibaca</a></div>
            <?php if (empty($notifTerbaru)): ?>
              <div class="item muted" style="padding:14px">Belum ada notifikasi.</div>
            <?php else: foreach ($notifTerbaru as $n): ?>
              <a class="item <?= $n['dibaca'] ? '' : 'unread' ?>" href="<?= url('notifikasi/tandai-dibaca/' . $n['id']) ?>">
                <span class="list-ic" data-ic="bell"></span>
                <span><b><?= e($n['judul']) ?></b><br><?= e($n['pesan']) ?><br><small class="muted"><?= tanggalWaktuIndo($n['dibuat_pada']) ?></small></span>
              </a>
            <?php endforeach; endif; ?>
            <div class="pop-foot"><a href="<?= $hrefNotif ?>">Lihat semua notifikasi</a></div>
          </div>
        </div>
        <div class="wrap-rel">
          <button class="user-btn" data-pop="popU">
            <img src="<?= e($fotoTampil) ?>" alt="">
            <span><b><?= e($namaTampil) ?></b><small><?= e($subTampil) ?></small></span>
          </button>
          <div class="pop" id="popU" style="width:220px">
            <?php if ($role !== 'admin'): ?><a class="item" href="<?= $hrefProfil ?>"><?= $role === 'mahasiswa' ? 'Profil Karier' : 'Profil Perusahaan' ?></a><?php endif; ?>
            <a class="item" href="<?= $hrefPengaturan ?>">Pengaturan Akun</a>
            <a class="item" href="<?= url('keluar') ?>">Keluar</a>
          </div>
        </div>
      </div>
    </header>
    <div class="page">
      <?php $flashShell = flashAmbil(); if ($flashShell): ?>
        <div class="alert alert-<?= $flashShell['tipe'] === 'ok' ? 'ok' : ($flashShell['tipe'] === 'warn' ? 'warn' : 'bad') ?>"><span data-ic="alert"></span><span><?= e($flashShell['pesan']) ?></span></div>
      <?php endif; ?>