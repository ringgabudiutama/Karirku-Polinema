<?php
// ===== FRONTEND · ADMIN · Persetujuan lowongan (revisi M) =============
$page_title = 'Persetujuan Lowongan';
$active_menu = 'persetujuan-lowongan';
require __DIR__ . '/../layouts/app-header.php';

$tabOpsi = ['menunggu' => 'Menunggu', 'revisi' => 'Diminta revisi', 'ditolak' => 'Ditolak'];
?>
<section class="view active">
  <?= kepalaKembali('admin/dashboard', [['Dashboard', 'admin/dashboard'], ['Persetujuan lowongan']]) ?>
  <div class="page-head"><div><h1>Persetujuan lowongan</h1>
    <p>Lowongan baru dan lowongan yang isinya diubah perusahaan baru tayang untuk mahasiswa setelah disetujui di sini.</p></div></div>
  <div class="panel">
    <div class="tabs">
      <?php foreach ($tabOpsi as $k => $v): ?>
        <a href="<?= url('admin/persetujuan-lowongan?status=' . $k) ?>" class="<?= $filter['status'] === $k ? 'active' : '' ?>"><?= e($v) ?><span class="c"><?= (int) $jumlah[$k] ?></span></a>
      <?php endforeach; ?>
    </div>
    <form class="filters" method="get" action="<?= url('admin/persetujuan-lowongan') ?>">
      <input type="hidden" name="status" value="<?= e($filter['status']) ?>">
      <input class="input grow" type="search" name="q" value="<?= e($filter['q']) ?>" placeholder="Cari posisi atau perusahaan" aria-label="Cari lowongan">
      <button class="btn btn-primary" type="submit"><span data-ic="search"></span>Cari</button>
      <?php if ($filter['q'] !== ''): ?><a class="btn btn-link" href="<?= url('admin/persetujuan-lowongan?status=' . $filter['status']) ?>">Hapus filter</a><?php endif; ?>
    </form>
    <div class="table-wrap"><table class="t">
      <tr><th>Lowongan</th><th>Perusahaan</th><th>Diajukan</th><th>Batas lamaran</th><th>Status</th><th></th></tr>
      <?php if (empty($lowongan)): ?>
        <tr><td colspan="6" class="muted kosong"><?= $filter['status'] === 'menunggu' ? 'Tidak ada lowongan yang menunggu persetujuan.' : 'Tidak ada data.' ?></td></tr>
      <?php else: foreach ($lowongan as $l): $hari = (int) floor((time() - strtotime($l['diajukan_pada'])) / 86400); ?>
        <tr>
          <td><div class="person"><?= pamfletHtml($l['pamflet'], 'mini') ?><div><b><?= e($l['posisi']) ?></b><small><?= e($l['nama_bidang']) ?></small></div></div></td>
          <td><?= e($l['nama_perusahaan']) ?></td>
          <td><?= tanggalWaktuIndo($l['diajukan_pada']) ?><?php if ($l['status'] === 'menunggu'): ?><br><small class="<?= $hari > 2 ? 'wait-r' : ($hari > 0 ? 'wait-y' : 'wait-g') ?>"><?= $hari <= 0 ? 'Hari ini' : $hari . ' hari menunggu' ?></small><?php endif; ?></td>
          <td><?= tanggalIndo($l['batas_lamaran']) ?><?php if (strtotime($l['batas_lamaran']) < strtotime('today')): ?><br><small class="text-bad">sudah lewat</small><?php endif; ?></td>
          <td><?= badgeHtml(labelStatusLowongan($l['status'])) ?><?php if ($l['catatan_admin']): ?><br><small class="muted"><?= e(ringkas($l['catatan_admin'], 60)) ?></small><?php endif; ?></td>
          <td><a class="btn btn-sm btn-primary" href="<?= url('admin/detail-lowongan/' . $l['id']) ?>"><?= $l['status'] === 'menunggu' ? 'Tinjau' : 'Lihat' ?></a></td>
        </tr>
      <?php endforeach; endif; ?>
    </table></div>
    <?= paginasiHtml($paginasi, 'lowongan') ?>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
