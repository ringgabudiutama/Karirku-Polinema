<?php
/**
 * View: mahasiswa/lowongan
 * Dipanggil oleh: LowonganController::daftar()
 * Variabel: $lowongan, $total, $halaman, $totalHalaman, $filter, $jurusan, $bidang
 */
$page_title = 'Lowongan';
$active_menu = 'lowongan';
require __DIR__ . '/../layouts/app-header.php';

$jenisPekerjaanOpsi = ['full_time' => 'Penuh waktu', 'part_time' => 'Paruh waktu', 'kontrak' => 'Kontrak', 'magang' => 'Magang', 'freelance' => 'Freelance'];
?>
<section class="view active">
  <div class="page-head"><div><h1>Lowongan</h1><p>Lowongan dari perusahaan mitra terverifikasi Career Center.</p></div></div>

  <form class="filters" method="get" action="<?= url('lowongan/daftar') ?>">
    <input class="input grow" name="q" type="search" placeholder="Cari posisi atau perusahaan" value="<?= e($filter['keyword']) ?>">
    <select class="input jur-filter" name="jurusan_id" onchange="this.form.submit()">
      <option value="">Semua jurusan</option>
      <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
    </select>
    <select class="input" name="bidang_id" onchange="this.form.submit()">
      <option value="">Semua bidang</option>
      <?php foreach ($bidang as $b): ?><option value="<?= (int) $b['id'] ?>" <?= (string) $filter['bidang_id'] === (string) $b['id'] ? 'selected' : '' ?>><?= e($b['nama']) ?></option><?php endforeach; ?>
    </select>
    <select class="input" name="lokasi" onchange="this.form.submit()">
      <option value="">Semua lokasi</option>
      <?php foreach ($lokasiOpsi as $lk): ?><option value="<?= e($lk) ?>" <?= $filter['lokasi'] === $lk ? 'selected' : '' ?>><?= e($lk) ?></option><?php endforeach; ?>
    </select>
    <select class="input" name="jenis_pekerjaan" onchange="this.form.submit()">
      <option value="">Semua jenis</option>
      <?php foreach ($jenisPekerjaanOpsi as $k => $v): ?><option value="<?= $k ?>" <?= $filter['jenis_pekerjaan'] === $k ? 'selected' : '' ?>><?= e($v) ?></option><?php endforeach; ?>
    </select>
    <select class="input" name="urutan" onchange="this.form.submit()">
      <option value="">Terbaru</option>
      <option value="batas_lamaran" <?= $filter['urutan'] === 'batas_lamaran' ? 'selected' : '' ?>>Deadline terdekat</option>
    </select>
    <noscript><button class="btn btn-outline" type="submit">Terapkan</button></noscript>
  </form>

  <p class="muted" style="font-size:.9rem"><?= (int) $total ?> lowongan ditemukan</p>

  <div class="jobs">
    <?php if (empty($lowongan)): ?>
      <div class="panel" style="text-align:center">
        <h3>Belum ada lowongan yang cocok</h3>
        <p class="muted">Coba ubah kata kunci atau hapus filter.</p>
        <a class="btn btn-outline" href="<?= url('lowongan/daftar') ?>">Hapus filter</a>
      </div>
    <?php else: foreach ($lowongan as $l): include __DIR__ . '/_kartu-lowongan.php'; endforeach; endif; ?>
  </div>

  <?php if ($totalHalaman > 1): ?>
    <div class="pagination">
      <?php for ($p = 1; $p <= $totalHalaman; $p++):
          $q = array_filter($filter);
          $q['halaman'] = $p;
      ?>
        <a class="<?= $p === $halaman ? 'active' : '' ?>" href="<?= url('lowongan/daftar?' . http_build_query($q)) ?>"><?= $p ?></a>
      <?php endfor; ?>
    </div>
  <?php endif; ?>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>