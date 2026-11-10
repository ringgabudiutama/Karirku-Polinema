<?php
// ===== FRONTEND · MAHASISWA · Cari lowongan ==========================
$page_title = 'Lowongan';
$active_menu = 'lowongan';
require __DIR__ . '/../layouts/app-header.php';

$jenisPekerjaanOpsi = ['full_time' => 'Penuh waktu', 'part_time' => 'Paruh waktu', 'kontrak' => 'Kontrak', 'magang' => 'Magang', 'freelance' => 'Freelance'];
?>
<section class="view active">
  <?= kepalaKembali('mahasiswa/dashboard', [['Dashboard', 'mahasiswa/dashboard'], ['Lowongan']]) ?>
  <div class="page-head"><div><h1>Lowongan</h1><p>Lowongan dari perusahaan mitra terverifikasi Career Center.</p></div></div>

  <!-- ===== Filter pencarian ===== -->
  <form class="filters" method="get" action="<?= url('lowongan/daftar') ?>">
    <input class="input grow" name="q" type="search" placeholder="Cari posisi atau perusahaan" value="<?= e($filter['keyword']) ?>">
    <select class="input jur-filter" name="jurusan_id" data-auto-submit>
      <option value="">Semua jurusan</option>
      <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
    </select>
    <select class="input" name="bidang_id" data-auto-submit>
      <option value="">Semua bidang</option>
      <?php foreach ($bidang as $b): ?><option value="<?= (int) $b['id'] ?>" <?= (string) $filter['bidang_id'] === (string) $b['id'] ? 'selected' : '' ?>><?= e($b['nama']) ?></option><?php endforeach; ?>
    </select>
    <select class="input" name="lokasi" data-auto-submit>
      <option value="">Semua lokasi</option>
      <?php foreach ($lokasiOpsi as $lk): ?><option value="<?= e($lk) ?>" <?= $filter['lokasi'] === $lk ? 'selected' : '' ?>><?= e($lk) ?></option><?php endforeach; ?>
    </select>
    <select class="input" name="jenis_pekerjaan" data-auto-submit>
      <option value="">Semua jenis</option>
      <?php foreach ($jenisPekerjaanOpsi as $k => $v): ?><option value="<?= $k ?>" <?= $filter['jenis_pekerjaan'] === $k ? 'selected' : '' ?>><?= e($v) ?></option><?php endforeach; ?>
    </select>
    <select class="input" name="urutan" data-auto-submit>
      <option value="">Terbaru</option>
      <option value="batas_lamaran" <?= $filter['urutan'] === 'batas_lamaran' ? 'selected' : '' ?>>Deadline terdekat</option>
    </select>
    <noscript><button class="btn btn-outline" type="submit">Terapkan</button></noscript>
  </form>

  <!-- HP: pilihan cepat jenis pekerjaan (model UI) -->
  <div class="hp m-chips" style="flex-direction:row;gap:8px;overflow-x:auto;scrollbar-width:none;margin:0 -16px 12px;padding:0 16px">
    <?php $q = array_filter(['q' => $filter['keyword']]);
      foreach (['' => 'Semua', 'magang' => 'Magang', 'full_time' => 'Penuh waktu', 'part_time' => 'Paruh waktu', 'kontrak' => 'Kontrak'] as $k => $v): ?>
      <a class="m-chip<?= (string) $filter['jenis_pekerjaan'] === $k ? ' m-on' : '' ?>" href="<?= url('lowongan/daftar' . (($p = http_build_query($q + array_filter(['jenis_pekerjaan' => $k]))) ? '?' . $p : '')) ?>"><?= $v ?></a>
    <?php endforeach; ?>
  </div>
  <p class="muted fs-90"><?= (int) $total ?> lowongan ditemukan</p>

  <!-- ===== Daftar lowongan ===== -->
  <div class="jobs">
    <?php if (empty($lowongan)): ?>
      <div class="panel text-center">
        <h3>Belum ada lowongan yang cocok</h3>
        <p class="muted">Coba ubah kata kunci atau hapus filter.</p>
        <a class="btn btn-outline" href="<?= url('lowongan/daftar') ?>">Hapus filter</a>
      </div>
    <?php else: foreach ($lowongan as $l): include __DIR__ . '/_kartu-lowongan.php'; endforeach; endif; ?>
  </div>

  <?= paginasiHtml($paginasi, 'lowongan') ?>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
