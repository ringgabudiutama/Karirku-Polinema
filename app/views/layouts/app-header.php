<?php
// ===== FRONTEND · LAYOUT · Kerangka dashboard: sidebar + topbar (pembuka) ====
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
    $adminShell = (new Admin())->cariByPenggunaId($user['id']);
    $namaTampil = $adminShell['nama'] ?? (new Pengguna())->namaTampilan($user['id'], 'admin');
    $subTampil = !empty($adminShell['jabatan']) ? $adminShell['jabatan'] : 'Career Center';
    if (!empty($adminShell['foto'])) {
        $fotoTampil = url('unduh.php?tipe=foto&file=' . urlencode($adminShell['foto']));
    }
}

// --- Menu sidebar per peran ---
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
    ['persetujuan-lowongan', 'Persetujuan Lowongan', 'checkc', 'admin/persetujuan-lowongan'],
    ['pengguna', 'Kelola Pengguna', 'users', 'admin/kelola-pengguna'],
    ['monitoring', 'Monitoring Lowongan', 'briefcase', 'admin/monitoring-lowongan'],
    ['rekap', 'Rekap Lamaran', 'clipboard', 'admin/rekap-lamaran'],
    ['kirim-loker', 'Kirim Loker ke Jurusan', 'send', 'kirim-loker'],
    ['tracer', 'Tracer Karier', 'chart', 'admin/tracer-karier'],
];
$menuUtama = $role === 'mahasiswa' ? $menuMahasiswa : ($role === 'perusahaan' ? $menuPerusahaan : $menuAdmin);
$labelPeran = $role === 'mahasiswa' ? 'Mahasiswa dan alumni' : ($role === 'perusahaan' ? 'Perusahaan' : 'Career Center');

// --- Penanda jumlah antrean di menu Admin ---
$hitungMenu = [];
if ($role === 'admin') {
    $hitungMenu = [
        'persetujuan'          => (int) Database::fetch("SELECT COUNT(*) AS n FROM pengguna WHERE status_akun = 'menunggu'")['n'],
        'persetujuan-lowongan' => (int) Database::fetch("SELECT COUNT(*) AS n FROM lowongan WHERE status = 'menunggu'")['n'],
    ];
}

// --- Menu bawah (tampilan HP) ---
// Tiap item: [kunci, label, ikon, tautan, daftar active_menu yang membuatnya menyala, angka penanda]
if ($role === 'perusahaan') {
    $jmlPelamarBaru = !empty($prshShell['id']) ? (int) (Database::fetch(
        "SELECT COUNT(*) AS n FROM lamaran l JOIN lowongan lo ON lo.id = l.lowongan_id WHERE lo.perusahaan_id = ? AND l.status = 'diajukan'",
        [(int) $prshShell['id']])['n'] ?? 0) : 0;
}
$navBawah = [
    'mahasiswa' => [
        ['beranda', 'Beranda', 'home', 'mahasiswa/dashboard', ['dashboard'], 0],
        ['lowongan', 'Lowongan', 'briefcase', 'lowongan/daftar', ['lowongan', 'disimpan'], 0],
        ['lamaran', 'Lamaran', 'file', 'lamaran/lamaran-saya', ['lamaran'], 0],
        ['profil', 'Profil', 'user', 'mahasiswa/profil', ['profil', 'pengaturan'], 0],
    ],
    'perusahaan' => [
        ['beranda', 'Beranda', 'home', 'perusahaan/dashboard', ['dashboard'], 0],
        ['lowongan', 'Lowongan', 'briefcase', 'perusahaan/lowongan', ['lowongan'], 0],
        ['pelamar', 'Pelamar', 'users', 'perusahaan/pelamar', ['pelamar'], $jmlPelamarBaru ?? 0],
        ['profil', 'Profil', 'building', 'perusahaan/profil', ['profil', 'pengaturan'], 0],
    ],
    'admin' => [
        ['beranda', 'Beranda', 'home', 'admin/dashboard', ['dashboard'], 0],
        ['persetujuan', 'Persetujuan', 'shield', 'admin/persetujuan', ['persetujuan', 'persetujuan-lowongan'], array_sum($hitungMenu)],
        ['lowongan', 'Lowongan', 'briefcase', 'admin/monitoring-lowongan', ['monitoring'], 0],
        ['lainnya', 'Lainnya', 'grid', '', ['pengguna', 'rekap', 'kirim-loker', 'tracer', 'profil-admin', 'pengaturan'], 0],
    ],
][$role];

// --- Notifikasi & tautan akun ---
$jumlahNotif = jumlahNotifBelumDibaca($user['id']);
$notifTerbaru = notifTerbaru($user['id'], 5);
$hrefNotif = url('notifikasi/semua');
$hrefPengaturan = $role === 'admin' ? url('admin/pengaturan') : url($role . '/pengaturan-akun');
$hrefProfil = $role === 'admin' ? url('admin/profil') : url($role . '/profil');
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
<title><?= e($page_title) ?> | KarirKu Polinema</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Fraunces:opsz,wght@9..144,500..700&display=swap" rel="stylesheet" media="(max-width: 768px)">
<link rel="stylesheet" href="<?= asetUrl('assets/css/style.css') ?>">
<link rel="stylesheet" href="<?= asetUrl('assets/css/hp.css') ?>" media="(max-width: 768px)">
</head>
<body data-uid="<?= (int) $user['id'] ?>" class="peran-<?= e($role) ?><?= !empty($hp_tanpa_bar) ? ' hp-tanpa-bar' : '' ?>">
<div class="app">
  <!-- ===== Sidebar ===== -->
  <aside class="side" aria-label="Menu utama">
    <div class="side-inner">
      <a class="brand" href="<?= url($role . '/dashboard') ?>"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu<small><?= e($labelPeran) ?></small></span></a>
      <ul class="menu">
        <?php foreach ($menuUtama as [$key, $label, $iconName, $href]): ?>
        <li><a href="<?= url($href) ?>" data-ic="<?= $iconName ?>" class="<?= $active_menu === $key ? 'active' : '' ?>"><?= e($label) ?><?php if (!empty($hitungMenu[$key])): ?> <span class="count"><?= (int) $hitungMenu[$key] ?></span><?php endif; ?></a></li>
        <?php endforeach; ?>
      </ul>
      <div class="side-label">Akun</div>
      <ul class="menu">
        <li><a href="<?= $hrefNotif ?>" data-ic="bell" class="<?= $active_menu === 'notifikasi' ? 'active' : '' ?>">Notifikasi <?php if ($jumlahNotif > 0): ?><span class="count"><?= $jumlahNotif ?></span><?php endif; ?></a></li>
        <?php if ($role === 'admin'): ?><li><a href="<?= $hrefProfil ?>" data-ic="user" class="<?= $active_menu === 'profil-admin' ? 'active' : '' ?>">Profil Saya</a></li><?php endif; ?>
        <li><a href="<?= $hrefPengaturan ?>" data-ic="settings" class="<?= $active_menu === 'pengaturan' ? 'active' : '' ?>">Pengaturan Akun</a></li>
      </ul>
      <div class="side-foot">
        <form class="logout-form" method="post" action="<?= url('keluar') ?>"><?= csrfField() ?><button type="submit" class="logout-btn" data-ic="logout">Keluar</button></form>
      </div>
    </div>
  </aside>

  <div class="main">
    <!-- ===== Topbar ===== -->
    <header class="topbar">
      <button class="icon-btn menu-toggle" aria-label="Buka menu" data-ic="menu"></button>
      <a class="icon-btn tb-kembali" href="<?= url($role . '/dashboard') ?>" aria-label="Kembali" data-kembali data-ic="left" hidden></a>
      <b class="top-title"><?= e($page_title) ?></b>
      <div class="top-right">
        <div class="wrap-rel">
          <button class="icon-btn" aria-label="Notifikasi<?= $jumlahNotif > 0 ? ", {$jumlahNotif} belum dibaca" : '' ?>" data-pop="popN" data-ic="bell"><?php if ($jumlahNotif > 0): ?><span class="dot"><?= $jumlahNotif ?></span><?php endif; ?></button>
          <div class="pop" id="popN">
            <div class="pop-head">Notifikasi <form class="d-inline" method="post" action="<?= url('notifikasi/tandai-semua-dibaca') ?>"><?= csrfField() ?><button type="submit" class="btn-link-kecil">Tandai dibaca</button></form></div>
            <?php if (empty($notifTerbaru)): ?>
              <div class="item muted p-14">Belum ada notifikasi.</div>
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
          <div class="pop pop-kecil" id="popU">
            <a class="item" href="<?= $hrefProfil ?>"><?= $role === 'mahasiswa' ? 'Profil Karier' : ($role === 'perusahaan' ? 'Profil Perusahaan' : 'Profil Saya') ?></a>
            <a class="item" href="<?= $hrefPengaturan ?>">Pengaturan Akun</a>
            <form class="logout-form" method="post" action="<?= url('keluar') ?>"><?= csrfField() ?><button type="submit" class="item">Keluar</button></form>
          </div>
        </div>
      </div>
    </header>
    <!-- ===== Isi halaman (diisi oleh view) ===== -->
    <div class="page">
      <?php require __DIR__ . '/_flash.php'; ?>
