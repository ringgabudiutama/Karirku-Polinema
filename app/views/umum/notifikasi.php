<?php
// ===== FRONTEND · UMUM · Notifikasi (satu view untuk tiga peran) =======
$page_title = 'Notifikasi';
$active_menu = 'notifikasi';
require __DIR__ . '/../layouts/app-header.php';

$ikonTipe = [
    'lamaran_diterima' => 'checkc', 'status_lamaran' => 'clock', 'lowongan_tersisa' => 'clock',
    'lamaran_masuk' => 'users', 'lamaran_dibatalkan' => 'x', 'status_akun' => 'shield',
    'lowongan_baru' => 'briefcase', 'kuota_penuh' => 'info', 'lowongan_nonaktif' => 'alert',
    'pendaftar_baru' => 'shield', 'lowongan_menunggu' => 'hourglass', 'status_lowongan' => 'briefcase',
    'lowongan_diperpanjang' => 'calendar', 'keamanan' => 'lock',
];
?>
<section class="view active">
  <?= kepalaKembali($role . '/dashboard', [['Dashboard', $role . '/dashboard'], ['Notifikasi']]) ?>
  <div class="page-head"><div><h1>Notifikasi</h1><p>Pemberitahuan terbaru tentang akun, lowongan, dan lamaran.</p></div>
    <form method="post" action="<?= url('notifikasi/tandai-semua-dibaca') ?>"><?= csrfField() ?><button class="btn btn-outline btn-sm" type="submit">Tandai semua dibaca</button></form>
  </div>
  <div class="panel p-0">
    <?php if (empty($notifikasi)): ?>
      <div class="muted kosong">Belum ada notifikasi.</div>
    <?php else: foreach ($notifikasi as $n): ?>
      <a class="notif <?= $n['dibaca'] ? '' : 'unread' ?>" href="<?= url('notifikasi/tandai-dibaca/' . $n['id']) ?>">
        <span class="list-ic" data-ic="<?= $ikonTipe[$n['tipe']] ?? 'bell' ?>"></span>
        <span><b class="t1"><?= e($n['judul']) ?></b><br><?= e($n['pesan']) ?><br><small><?= tanggalWaktuIndo($n['dibuat_pada']) ?></small></span>
      </a>
    <?php endforeach; endif; ?>
  </div>
  <?= paginasiHtml($paginasi, 'notifikasi') ?>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
