<?php
/**
 * View: mahasiswa/disimpan
 * Dipanggil oleh: MahasiswaController::disimpan()
 * Variabel: $lowongan
 */
$page_title = 'Disimpan';
$active_menu = 'disimpan';
require __DIR__ . '/../layouts/app-header.php';
?>
<section class="view active">
  <div class="page-head"><div><h1>Disimpan</h1><p>Lowongan yang kamu tandai. Perhatikan batas lamarannya.</p></div></div>
  <div class="jobs">
    <?php if (empty($lowongan)): ?>
      <div class="panel" style="text-align:center">
        <h3>Belum ada lowongan disimpan</h3>
        <p class="muted">Tekan Simpan pada lowongan yang menarik agar mudah ditemukan lagi.</p>
        <a class="btn btn-primary" href="<?= url('lowongan/daftar') ?>">Cari lowongan</a>
      </div>
    <?php else: foreach ($lowongan as $l): include __DIR__ . '/_kartu-lowongan.php'; endforeach; endif; ?>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
