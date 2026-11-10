<?php
// ===== FRONTEND · ADMIN · Rekap lamaran (revisi I) ===================
$page_title = 'Rekap Lamaran';
$active_menu = 'rekap';
require __DIR__ . '/../layouts/app-header.php';

$r = $ringkasan;
$diproses = ($r['diajukan'] ?? 0) + ($r['screening'] ?? 0) + ($r['interview'] ?? 0);
$ditolakBatal = ($r['ditolak'] ?? 0) + ($r['dibatalkan'] ?? 0);
$statusOpsi = ['' => 'Semua status', 'diajukan' => 'Diajukan', 'screening' => 'Screening CV', 'interview' => 'Interview',
               'diterima' => 'Diterima', 'ditolak' => 'Ditolak', 'dibatalkan' => 'Dibatalkan'];
$filterAktif = array_filter($filter, fn($v) => $v !== '' && $v !== null);
?>
<section class="view active">
  <?= kepalaKembali('admin/dashboard', [['Dashboard', 'admin/dashboard'], ['Rekap lamaran']]) ?>
  <div class="page-head"><div><h1>Rekap lamaran</h1><p>Seluruh lamaran dari semua perusahaan. Angka ringkasan dihitung dari <b>semua</b> data yang cocok dengan filter, bukan hanya halaman yang tampil.</p></div>
    <a class="btn btn-primary" href="<?= url('admin/unduh-rekap-lamaran?' . http_build_query($filterAktif)) ?>" target="_blank" rel="noopener"><span data-ic="download"></span>Unduh PDF (sesuai filter)</a>
  </div>

  <!-- ===== Filter (semua bisa digabung) ===== -->
  <div class="panel">
    <form class="filters filters-lengkap" method="get" action="<?= url('admin/rekap-lamaran') ?>">
      <input class="input grow" type="search" name="q" value="<?= e($filter['q']) ?>" placeholder="Cari nama pelamar, NIM, perusahaan, atau posisi" aria-label="Kata kunci">
      <select class="input" name="status" aria-label="Status lamaran">
        <?php foreach ($statusOpsi as $k => $v): ?><option value="<?= $k ?>" <?= $filter['status'] === $k ? 'selected' : '' ?>><?= e($v) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="jurusan_id" id="filterJurusan" aria-label="Jurusan">
        <option value="">Semua jurusan</option>
        <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="prodi_id" id="filterProdi" aria-label="Program studi">
        <option value="">Semua prodi</option>
        <?php foreach ($prodi as $ps): ?><option value="<?= (int) $ps['id'] ?>" data-jurusan="<?= (int) $ps['jurusan_id'] ?>" <?= (string) $filter['prodi_id'] === (string) $ps['id'] ? 'selected' : '' ?>><?= e(trim(($ps['jenjang'] ?? '') . ' ' . $ps['nama'])) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="angkatan" aria-label="Angkatan">
        <option value="">Semua angkatan</option>
        <?php foreach ($angkatan as $ang): ?><option value="<?= (int) $ang ?>" <?= (string) $filter['angkatan'] === (string) $ang ? 'selected' : '' ?>>Angkatan <?= (int) $ang ?></option><?php endforeach; ?>
      </select>
      <label class="field-inline"><span>Tanggal lamar dari</span><input class="input" type="date" name="tanggal_dari" value="<?= e($filter['tanggal_dari']) ?>"></label>
      <label class="field-inline"><span>sampai</span><input class="input" type="date" name="tanggal_sampai" value="<?= e($filter['tanggal_sampai']) ?>"></label>
      <button class="btn btn-primary" type="submit"><span data-ic="search"></span>Terapkan</button>
      <?php if ($filterAktif): ?><a class="btn btn-outline" href="<?= url('admin/rekap-lamaran') ?>">Hapus filter (tampilkan semua)</a><?php endif; ?>
    </form>
    <?php if ($labelFilter): ?>
      <p class="filter-aktif"><b>Filter aktif:</b> <?= e(implode(' · ', $labelFilter)) ?>. Rentang tanggal dihitung WIB dan termasuk hari terakhir sampai pukul 23.59.</p>
    <?php endif; ?>
  </div>

  <!-- ===== Kartu ringkasan (seluruh data terfilter) ===== -->
  <div class="grid g4 mb-18">
    <div class="stat"><div class="n"><?= number_format($r['total'] ?? 0) ?></div><div class="l">Total lamaran</div></div>
    <div class="stat"><div class="n"><?= number_format($diproses) ?></div><div class="l">Sedang diproses</div></div>
    <div class="stat"><div class="n text-ok"><?= number_format($r['diterima'] ?? 0) ?></div><div class="l">Diterima</div></div>
    <div class="stat"><div class="n text-bad"><?= number_format($ditolakBatal) ?></div><div class="l">Ditolak atau dibatalkan</div></div>
  </div>

  <div>
    <div class="panel">
      <div class="table-wrap"><table class="t">
        <tr><th>Tanggal</th><th>Pelamar</th><th>Prodi</th><th>Angkatan</th><th>Perusahaan</th><th>Posisi</th><th>Status</th></tr>
        <?php if (empty($lamaran)): ?><tr><td colspan="7" class="muted kosong">Tidak ada lamaran yang cocok dengan filter ini.</td></tr><?php endif; ?>
        <?php foreach ($lamaran as $l): ?>
          <tr>
            <td><?= tanggalWaktuIndo($l['tanggal_lamar']) ?></td>
            <td><a href="<?= url('admin/profil-mahasiswa/' . $l['mahasiswa_id']) ?>"><b><?= e($l['nama_mahasiswa']) ?></b></a><br><small class="muted"><?= e($l['nim']) ?></small></td>
            <td><?= e(trim(($l['jenjang'] ?? '') . ' ' . $l['nama_prodi'])) ?><br><small class="muted"><?= e($l['nama_jurusan']) ?></small></td>
            <td><?= (int) $l['angkatan'] ?></td>
            <td><?= e($l['nama_perusahaan']) ?></td>
            <td><?= e($l['posisi']) ?></td>
            <td><?= badgeHtml(labelStatusLamaran($l['status'])) ?></td>
          </tr>
        <?php endforeach; ?>
      </table></div>
      <?= paginasiHtml($paginasi, 'lamaran') ?>
    </div>
    <!-- ===== Ringkasan per perusahaan (seluruh data terfilter) ===== -->
    <div class="panel">
      <h3>Per perusahaan</h3>
      <div class="table-wrap"><table class="t"><tr><th>Perusahaan</th><th>Pelamar</th><th>Diterima</th></tr>
        <?php if (!$perPerusahaan): ?><tr><td colspan="3" class="muted kosong">Tidak ada data.</td></tr><?php endif; ?>
        <?php foreach (array_slice($perPerusahaan, 0, 10) as $p): ?>
          <tr><td><?= e($p['nama_perusahaan']) ?></td><td><?= (int) $p['total'] ?></td><td><?= (int) $p['diterima'] ?></td></tr>
        <?php endforeach; ?>
      </table></div>
      <?php if (count($perPerusahaan) > 10): ?><p class="muted fs-85 mt-10">10 teratas dari <?= count($perPerusahaan) ?> perusahaan. Daftar lengkap ada di PDF.</p><?php endif; ?>
    </div>
  </div>
</section>
<!-- ===== Prodi menyesuaikan jurusan yang dipilih ===== -->
<script nonce="<?= cspNonce() ?>">
(function(){
  var jur = document.getElementById('filterJurusan'), prodi = document.getElementById('filterProdi');
  if (!jur || !prodi) return;
  function saring(){
    prodi.querySelectorAll('option[data-jurusan]').forEach(function(o){
      o.hidden = jur.value !== '' && o.dataset.jurusan !== jur.value;
      if (o.hidden && o.selected) prodi.value = '';
    });
  }
  jur.addEventListener('change', saring);
  saring();
})();
</script>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
