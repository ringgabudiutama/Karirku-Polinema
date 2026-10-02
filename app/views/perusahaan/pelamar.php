<?php
/**
 * View: perusahaan/pelamar
 * Dipanggil oleh: PerusahaanController::pelamar()
 * Variabel: $pelamar, $lowonganSaya, $jurusan, $filter
 */
$page_title = 'Pelamar';
$active_menu = 'pelamar';
require __DIR__ . '/../layouts/app-header.php';

$statusOpsi = ['' => 'Semua status', 'diajukan' => 'Diajukan', 'screening' => 'Screening CV', 'interview' => 'Interview', 'diterima' => 'Diterima', 'ditolak' => 'Ditolak'];
?>
<section class="view active">
  <div class="page-head"><div><h1>Pelamar</h1><p>Klik nama pelamar untuk melihat profil lengkap, CV, dan portofolio.</p></div></div>
  <div class="panel">
    <form class="filters" method="get" action="<?= url('perusahaan/pelamar') ?>">
      <input class="input grow" type="search" name="q" value="<?= e($filter['keyword'] ?? '') ?>" placeholder="Cari nama pelamar">
      <select class="input jur-filter" name="jurusan_id" onchange="this.form.submit()">
        <option value="">Semua jurusan</option>
        <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
      </select>
      <select class="input jur-filter" name="lowongan_id" onchange="this.form.submit()">
        <option value="">Semua lowongan</option>
        <?php foreach ($lowonganSaya as $l): ?><option value="<?= (int) $l['id'] ?>" <?= (string) $filter['lowongan_id'] === (string) $l['id'] ? 'selected' : '' ?>><?= e($l['posisi']) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="status" onchange="this.form.submit()">
        <?php foreach ($statusOpsi as $k => $v): ?><option value="<?= $k ?>" <?= $filter['status'] === $k ? 'selected' : '' ?>><?= e($v) ?></option><?php endforeach; ?>
      </select>
      <button class="btn btn-outline" type="submit">Cari</button>
    </form>
    <div class="table-wrap"><table class="t">
      <tr><th>Pelamar</th><th>Lowongan</th><th>Tanggal</th><th>Status</th><th></th></tr>
      <?php if (empty($pelamar)): ?>
        <tr><td colspan="5" class="muted" style="text-align:center;padding:30px">Tidak ada pelamar dengan filter ini.</td></tr>
      <?php else: foreach ($pelamar as $p):
          $fotoUrlP = !empty($p['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($p['foto'])) : null;
      ?>
        <tr>
          <td><a class="person" href="<?= url('lamaran/detail-pelamar/' . $p['id']) ?>">
            <?php if ($fotoUrlP): ?><img src="<?= e($fotoUrlP) ?>" alt=""><?php else: ?><span class="avatar" style="display:inline-flex;align-items:center;justify-content:center;background:var(--blue-soft);color:var(--navy);font-weight:700;font-size:.8rem"><?= e(inisial($p['nama_mahasiswa'])) ?></span><?php endif; ?>
            <div><b><?= e($p['nama_mahasiswa']) ?></b><small><?= e($p['nama_prodi']) ?></small></div>
          </a></td>
          <td><?= e($p['posisi']) ?></td>
          <td><?= tanggalIndo($p['tanggal_lamar']) ?></td>
          <td><?= badgeHtml(labelStatusLamaran($p['status'])) ?></td>
          <td><a class="btn btn-sm btn-outline" href="<?= url('lamaran/detail-pelamar/' . $p['id']) ?>">Lihat detail</a></td>
        </tr>
      <?php endforeach; endif; ?>
    </table></div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
