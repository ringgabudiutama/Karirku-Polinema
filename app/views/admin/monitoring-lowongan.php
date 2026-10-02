<?php
/**
 * View: admin/monitoring-lowongan
 * Dipanggil oleh: AdminController::monitoringLowongan()
 * Variabel: $lowongan, $bidang, $jurusan, $filter
 */
$page_title = 'Monitoring Lowongan';
$active_menu = 'monitoring';
require __DIR__ . '/../layouts/app-header.php';
?>
<section class="view active">
  <div class="page-head"><div><h1>Monitoring lowongan</h1><p>Semua lowongan dari seluruh perusahaan mitra.</p></div>
    <a class="btn btn-outline" href="<?= url('admin/unduh-rekap-lowongan?' . http_build_query($filter)) ?>" target="_blank"><span data-ic="download"></span>Unduh laporan PDF</a>
  </div>
  <div class="panel">
    <form class="filters" method="get" action="<?= url('admin/monitoring-lowongan') ?>">
      <input class="input grow" type="text" id="cariLowongan" placeholder="Cari posisi atau perusahaan" autocomplete="off">
      <select class="input jur-filter" name="jurusan_id" onchange="this.form.submit()">
        <option value="">Semua jurusan</option>
        <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="status" onchange="this.form.submit()">
        <option value="">Semua status</option>
        <option value="aktif" <?= $filter['status'] === 'aktif' ? 'selected' : '' ?>>Aktif</option>
        <option value="ditutup" <?= $filter['status'] === 'ditutup' ? 'selected' : '' ?>>Ditutup</option>
        <option value="nonaktif" <?= $filter['status'] === 'nonaktif' ? 'selected' : '' ?>>Dinonaktifkan</option>
      </select>
      <select class="input" name="bidang_id" onchange="this.form.submit()">
        <option value="">Semua bidang</option>
        <?php foreach ($bidang as $b): ?><option value="<?= (int) $b['id'] ?>" <?= (string) $filter['bidang_id'] === (string) $b['id'] ? 'selected' : '' ?>><?= e($b['nama']) ?></option><?php endforeach; ?>
      </select>
    </form>
    <div class="table-wrap"><table class="t" id="tabelLowongan">
      <tr><th>Lowongan</th><th>Perusahaan</th><th>Batas</th><th>Pelamar</th><th>Kuota</th><th>Status</th><th></th></tr>
      <?php if (empty($lowongan)): ?><tr><td colspan="7" class="muted" style="text-align:center;padding:30px">Tidak ada lowongan dengan filter ini.</td></tr><?php endif; ?>
      <?php foreach ($lowongan as $l): ?>
        <tr data-cari="<?= e(mb_strtolower($l['posisi'] . ' ' . $l['nama_perusahaan'])) ?>">
          <td><b><?= e($l['posisi']) ?></b><br><small class="muted"><?= e($l['nama_bidang']) ?></small></td>
          <td><?= e($l['nama_perusahaan']) ?></td>
          <td><?= tanggalIndo($l['batas_lamaran']) ?></td>
          <td><?= (int) $l['terisi'] ?></td>
          <td><?= (int) $l['terisi'] ?>/<?= (int) $l['kuota'] ?></td>
          <td><?= badgeHtml(labelStatusLowongan($l['status'])) ?><?php if ($l['status'] === 'nonaktif' && $l['alasan_nonaktif']): ?><br><small class="muted"><?= e($l['alasan_nonaktif']) ?></small><?php endif; ?></td>
          <td style="white-space:nowrap">
            <a class="btn btn-sm btn-outline" href="<?= url('info-loker/' . $l['kode_pratinjau']) ?>" target="_blank">Lihat</a>
            <?php if ($l['status'] === 'aktif'): ?>
              <button class="btn btn-sm btn-outline" type="button" style="color:var(--bad);border-color:var(--bad)" data-open="mNon<?= (int) $l['id'] ?>">Nonaktifkan</button>
            <?php endif; ?>
          </td>
        </tr>
      <?php endforeach; ?>
    </table></div>
  </div>
</section>
<script>
(function(){
  var cari = document.getElementById('cariLowongan');
  var tabel = document.getElementById('tabelLowongan');
  if (!cari || !tabel) return;
  cari.addEventListener('input', function(){
    var kata = cari.value.trim().toLowerCase();
    tabel.querySelectorAll('tr[data-cari]').forEach(function(tr){
      tr.style.display = tr.dataset.cari.indexOf(kata) === -1 ? 'none' : '';
    });
  });
})();
</script>

<?php foreach ($lowongan as $l): if ($l['status'] !== 'aktif') continue; ?>
<div class="modal" id="mNon<?= (int) $l['id'] ?>" role="dialog" aria-modal="true">
  <div class="modal-box">
    <div class="modal-head"><h3>Nonaktifkan lowongan?</h3><button class="close" data-close aria-label="Tutup" data-ic="x"></button></div>
    <form method="post" action="<?= url('admin/nonaktifkan-lowongan/' . $l['id']) ?>">
      <?= csrfField() ?>
      <div class="modal-body">
        <p><b><?= e($l['posisi']) ?></b> di <?= e($l['nama_perusahaan']) ?> akan disembunyikan dari pencarian mahasiswa dan alumni. Perusahaan menerima notifikasi.</p>
        <div class="field"><label>Alasan</label><textarea class="input" name="alasan" rows="3" required placeholder="Tulis alasan yang jelas"></textarea></div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Batal</button><button type="submit" class="btn btn-danger">Nonaktifkan</button></div>
    </form>
  </div>
</div>
<?php endforeach; ?>

<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
