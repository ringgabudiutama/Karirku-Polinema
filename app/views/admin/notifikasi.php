<?php
/**
 * View: admin/notifikasi (route: notifikasi/semua)
 * Dipanggil oleh: NotifikasiController::semua()
 * Variabel: $notifikasi
 */
$page_title = 'Notifikasi';
$active_menu = 'notifikasi';
require __DIR__ . '/../layouts/app-header.php';

$ikonTipe = [
    'pendaftar_baru'   => 'shield',
    'lamaran_diterima' => 'checkc',
];
?>
<section class="view active">
  <div class="page-head"><div><h1>Notifikasi</h1></div><a class="btn btn-outline btn-sm" href="<?= url('notifikasi/tandai-semua-dibaca') ?>">Tandai semua dibaca</a></div>
  <div class="panel" style="padding:0">
    <?php if (empty($notifikasi)): ?>
      <div class="muted" style="padding:30px;text-align:center">Belum ada notifikasi.</div>
    <?php else: foreach ($notifikasi as $n): ?>
      <a class="notif <?= $n['dibaca'] ? '' : 'unread' ?>" href="<?= url('notifikasi/tandai-dibaca/' . $n['id']) ?>">
        <span class="list-ic" data-ic="<?= $ikonTipe[$n['tipe']] ?? 'bell' ?>"></span>
        <span><b class="t1"><?= e($n['judul']) ?></b><br><?= e($n['pesan']) ?><br><small><?= tanggalWaktuIndo($n['dibuat_pada']) ?></small></span>
      </a>
    <?php endforeach; endif; ?>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>