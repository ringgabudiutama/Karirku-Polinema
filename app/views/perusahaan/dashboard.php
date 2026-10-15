<?php
// ===== FRONTEND · PERUSAHAAN · Dashboard =============================
$page_title = 'Dashboard';
$active_menu = 'dashboard';
require __DIR__ . '/../layouts/app-header.php';

$logoUrl = !empty($perusahaan['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($perusahaan['logo'])) : null;
$userNow = Auth::penggunaSaatIni();
?>
<section class="view active">
  <!-- ===== Sambutan ===== -->
  <div class="welcome">
    <div class="hero-pattern"></div>
    <?php if ($logoUrl): ?>
      <img class="welcome-logo" src="<?= e($logoUrl) ?>" alt="">
    <?php else: ?>
      <span class="logo-sq welcome-logo"><?= e(inisial($perusahaan['nama_perusahaan'])) ?></span>
    <?php endif; ?>
    <div class="relative"><h1><?= e($perusahaan['nama_perusahaan']) ?></h1><p>Halo, <?= e($perusahaan['nama_pic']) ?> <span class="verified" data-ic="check">Mitra terverifikasi</span></p></div>
  </div>

  <!-- ===== Kartu statistik ===== -->
  <div class="grid g4 mb-18">
    <a class="stat" href="<?= url('perusahaan/lowongan') ?>"><div class="n"><?= (int) $lowonganAktif ?></div><div class="l">Lowongan aktif</div></a>
    <a class="stat" href="<?= url('perusahaan/pelamar?status=diajukan') ?>"><div class="n"><?= (int) $pelamarBaru ?></div><div class="l">Pelamar baru belum dibuka</div></a>
    <a class="stat" href="<?= url('perusahaan/pelamar?status=interview') ?>"><div class="n"><?= (int) $interviewTerjadwal ?></div><div class="l">Interview terjadwal</div></a>
    <a class="stat" href="<?= url('perusahaan/pelamar?status=diterima') ?>"><div class="n text-ok"><?= (int) $pelamarDiterima ?></div><div class="l">Pelamar diterima</div></a>
  </div>

  <!-- ===== Pelamar terbaru & grafik ===== -->
  <div class="grid g-side">
    <div class="panel">
      <div class="panel-head"><h2>Pelamar terbaru</h2><a href="<?= url('perusahaan/pelamar') ?>">Lihat semua</a></div>
      <div class="table-wrap"><table class="t">
        <tr><th>Pelamar</th><th>Lowongan</th><th>Tanggal</th><th>Status</th><th></th></tr>
        <?php if (empty($pelamarTerbaru)): ?>
          <tr><td colspan="5" class="muted kosong">Belum ada pelamar.</td></tr>
        <?php else: foreach ($pelamarTerbaru as $p): ?>
          <tr>
            <td><a class="person" href="<?= url('lamaran/detail-pelamar/' . $p['id']) ?>"><span class="avatar avatar-inisial fs-80"><?= e(inisial($p['nama_mahasiswa'])) ?></span><div><b><?= e($p['nama_mahasiswa']) ?></b></div></a></td>
            <td><?= e($p['posisi']) ?></td>
            <td><?= tanggalIndo($p['tanggal_lamar']) ?></td>
            <td><?= badgeHtml(labelStatusLamaran($p['status'])) ?></td>
            <td><a class="btn btn-sm btn-outline" href="<?= url('lamaran/detail-pelamar/' . $p['id']) ?>">Lihat detail</a></td>
          </tr>
        <?php endforeach; endif; ?>
      </table></div>
    </div>
    <!-- ===== Kolom kanan: grafik pelamar & kuota ===== -->
    <div>
      <div class="panel">
        <h3>Pelamar per lowongan</h3>
        <?php $maxPelamar = max(1, ...array_map(fn($l) => (int) $l['jumlah_pelamar'], $lowonganSaya ?: [['jumlah_pelamar' => 0]])); ?>
        <div class="cols" aria-label="Grafik pelamar per lowongan">
          <?php foreach (array_slice($lowonganSaya, 0, 4) as $l): $pctBar = max(6, round((int) $l['jumlah_pelamar'] / $maxPelamar * 100)); ?>
            <div class="c"><b><?= (int) $l['jumlah_pelamar'] ?></b><i style="height:<?= $pctBar ?>%"></i><?= e($l['posisi']) ?></div>
          <?php endforeach; ?>
          <?php if (empty($lowonganSaya)): ?><p class="muted">Belum ada lowongan.</p><?php endif; ?>
        </div>
      </div>
      <div class="panel">
        <h3>Kuota lowongan</h3>
        <div class="bars mt-12">
          <?php foreach (array_slice($lowonganSaya, 0, 5) as $l): $pct = $l['kuota'] > 0 ? min(100, round($l['terisi'] / $l['kuota'] * 100)) : 0; ?>
            <div class="bar-row bar-row-130">
              <span><?= e($l['posisi']) ?></span>
              <div class="bar-track"><i style="width:<?= $pct ?>%<?= $pct >= 100 ? ';background:var(--ok)' : '' ?>"></i></div>
              <b><?= (int) $l['terisi'] ?>/<?= (int) $l['kuota'] ?></b>
            </div>
          <?php endforeach; ?>
          <?php if (empty($lowonganSaya)): ?><p class="muted">Belum ada lowongan.</p><?php endif; ?>
        </div>
      </div>
    </div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
