<?php
// ===== FRONTEND · PERUSAHAAN · Daftar pelamar ========================
$page_title = 'Pelamar';
$active_menu = 'pelamar';
require __DIR__ . '/../layouts/app-header.php';

$statusOpsi = ['' => 'Semua status', 'diajukan' => 'Diajukan', 'screening' => 'Screening CV', 'interview' => 'Interview', 'diterima' => 'Diterima', 'ditolak' => 'Ditolak', 'dibatalkan' => 'Dibatalkan'];
$adaFilter = array_filter($filter, fn($v) => $v !== '' && $v !== null);
?>
<section class="view active">
  <?php if (!empty($filter['lowongan_id'])): ?>
  <?= kepalaKembali('perusahaan/lowongan', [['Lowongan saya', 'perusahaan/lowongan'], ['Kelola pelamar']]) ?>
  <?php else: ?>
  <?= kepalaKembali('perusahaan/dashboard', [['Dashboard', 'perusahaan/dashboard'], ['Pelamar']]) ?>
  <?php endif; ?>
  <div class="page-head"><div><h1>Pelamar</h1><p>Klik nama pelamar untuk melihat profil lengkap, CV, dan portofolio.</p></div></div>
  <div class="panel">
    <!-- ===== Filter (revisi I: angkatan & rentang tanggal lamar) ===== -->
    <form class="filters filters-lengkap" method="get" action="<?= url('perusahaan/pelamar') ?>">
      <input class="input grow" type="search" name="q" value="<?= e($filter['keyword'] ?? '') ?>" placeholder="Cari nama, NIM, atau posisi" aria-label="Cari pelamar">
      <select class="input" name="lowongan_id" aria-label="Lowongan">
        <option value="">Semua lowongan</option>
        <?php foreach ($lowonganSaya as $l): ?><option value="<?= (int) $l['id'] ?>" <?= (string) $filter['lowongan_id'] === (string) $l['id'] ? 'selected' : '' ?>><?= e($l['posisi']) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="status" aria-label="Status">
        <?php foreach ($statusOpsi as $k => $v): ?><option value="<?= $k ?>" <?= $filter['status'] === $k ? 'selected' : '' ?>><?= e($v) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="jurusan_id" aria-label="Jurusan">
        <option value="">Semua jurusan</option>
        <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="angkatan" aria-label="Angkatan">
        <option value="">Semua angkatan</option>
        <?php foreach ($angkatan as $a): ?><option value="<?= (int) $a ?>" <?= (string) $filter['angkatan'] === (string) $a ? 'selected' : '' ?>>Angkatan <?= (int) $a ?></option><?php endforeach; ?>
      </select>
      <label class="field-inline"><span>Lamar dari</span><input class="input" type="date" name="tanggal_dari" value="<?= e($filter['tanggal_dari']) ?>"></label>
      <label class="field-inline"><span>sampai</span><input class="input" type="date" name="tanggal_sampai" value="<?= e($filter['tanggal_sampai']) ?>"></label>
      <button class="btn btn-primary" type="submit"><span data-ic="search"></span>Terapkan</button>
      <?php if ($adaFilter): ?><a class="btn btn-link" href="<?= url('perusahaan/pelamar') ?>">Hapus filter</a><?php endif; ?>
    </form>
    <!-- HP: kartu pelamar ringkas (model UI) -->
    <div class="hp" style="gap:10px">
      <?php if (empty($pelamar)): ?>
        <div class="m-card m-muted" style="padding:16px;font-size:13.5px">Belum ada pelamar yang cocok dengan filter ini.</div>
      <?php endif; foreach ($pelamar as $p): [$bj, $bt] = hpStatusLamaran($p['status']); ?>
        <a class="m-card" href="<?= url('lamaran/detail-pelamar/' . $p['id']) ?>" style="display:flex;gap:12px;padding:14px;align-items:center;color:#122036">
          <?= hpAvatar($p['nama_mahasiswa'], !empty($p['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($p['foto'])) : null, 46) ?>
          <span style="flex:1;min-width:0"><span style="display:flex;justify-content:space-between;gap:8px;align-items:center"><b style="font-size:15px" class="m-elip"><?= e($p['nama_mahasiswa']) ?></b><?= hpBadge($bj, $bt) ?></span>
            <span class="m-muted m-elip" style="display:block;font-size:12.5px"><?= e($p['nama_prodi']) ?> · <?= (int) $p['angkatan'] ?></span>
            <span style="display:flex;gap:5px;align-items:center;font-size:12.5px;color:#33435c;margin-top:2px"><?= hpIk('briefcase', 13, 2) ?><span class="m-elip"><?= e($p['posisi']) ?></span></span></span>
        </a>
      <?php endforeach; ?>
    </div>
    <div class="table-wrap hanya-laptop"><table class="t">
      <tr><th>Pelamar</th><th>Angkatan</th><th>Lowongan</th><th>Tanggal lamar</th><th>Status</th><th></th></tr>
      <?php if (empty($pelamar)): ?>
        <tr><td colspan="6" class="muted kosong">Tidak ada pelamar dengan filter ini.</td></tr>
      <?php else: foreach ($pelamar as $p):
          $fotoUrlP = !empty($p['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($p['foto'])) : null;
      ?>
        <tr>
          <td><a class="person" href="<?= url('lamaran/detail-pelamar/' . $p['id']) ?>">
            <?php if ($fotoUrlP): ?><img src="<?= e($fotoUrlP) ?>" alt=""><?php else: ?><span class="avatar avatar-inisial fs-80"><?= e(inisial($p['nama_mahasiswa'])) ?></span><?php endif; ?>
            <div><b><?= e($p['nama_mahasiswa']) ?></b><small><?= e($p['nim']) ?> &middot; <?= e($p['nama_prodi']) ?></small></div>
          </a></td>
          <td><?= (int) $p['angkatan'] ?></td>
          <td><?= e($p['posisi']) ?></td>
          <td><?= tanggalWaktuIndo($p['tanggal_lamar']) ?></td>
          <td><?= badgeHtml(labelStatusLamaran($p['status'])) ?></td>
          <td><a class="btn btn-sm btn-outline" href="<?= url('lamaran/detail-pelamar/' . $p['id']) ?>">Lihat detail</a></td>
        </tr>
      <?php endforeach; endif; ?>
    </table></div>
    <?= paginasiHtml($paginasi, 'pelamar') ?>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
