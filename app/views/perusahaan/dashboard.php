<?php
// ===== FRONTEND · PERUSAHAAN · Dashboard =============================
$page_title = 'Dashboard';
$active_menu = 'dashboard';
$hp_tanpa_bar = true;
require __DIR__ . '/../layouts/app-header.php';

$logoUrl = !empty($perusahaan['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($perusahaan['logo'])) : null;
$userNow = Auth::penggunaSaatIni();
$labelStatusHp = fn($st) => hpStatusLamaran($st);
?>
<!-- ===== Tampilan HP (model UI: Beranda perusahaan) ===== -->
<section class="hp" aria-label="Beranda perusahaan">
  <header class="m-kepala">
    <?= hpLogo($perusahaan['nama_perusahaan'], $perusahaan['logo'] ?? null, 44) ?>
    <div class="m-sapa"><span><?= e($perusahaan['bidang_usaha'] ?: hpSapaan()) ?></span><b><?= e($perusahaan['nama_perusahaan']) ?></b></div>
    <a class="m-ib m-soft" href="<?= $hrefNotif ?>" aria-label="Notifikasi"><?= hpIk('bell', 21) ?><?php if ($jumlahNotif): ?><span class="m-dot"><?= (int) $jumlahNotif ?></span><?php endif; ?></a>
  </header>
  <div style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px">
    <a class="m-stat" href="<?= url('perusahaan/pelamar?status=diajukan') ?>" style="background:#0a2656;box-shadow:none"><div class="m-n" style="color:#fff"><?= (int) $pelamarBaru ?></div><div class="m-l" style="color:#b9cbec">Pelamar baru</div><div style="margin-top:8px;font-size:11.5px;font-weight:700;color:#7fe0a5;display:flex;gap:4px;align-items:center"><?= hpIk('trend', 14, 2.2) ?>Belum dibuka</div></a>
    <a class="m-stat" href="<?= url('perusahaan/lowongan') ?>" style="color:inherit"><div class="m-n"><?= (int) $lowonganAktif ?></div><div class="m-l">Lowongan aktif</div><?php if ($lowonganMenunggu): ?><div style="margin-top:8px;font-size:11.5px;font-weight:700;color:#8a5a00"><?= (int) $lowonganMenunggu ?> menunggu admin</div><?php endif; ?></a>
    <a class="m-stat" href="<?= url('perusahaan/pelamar?status=interview') ?>" style="color:inherit"><div class="m-n"><?= (int) $interviewTerjadwal ?></div><div class="m-l">Tahap interview</div></a>
    <a class="m-stat" href="<?= url('perusahaan/pelamar?status=diterima') ?>" style="color:inherit"><div class="m-n"><?= (int) $pelamarDiterima ?></div><div class="m-l">Diterima</div></a>
  </div>
  <div class="m-sec"><h2>Pelamar terbaru</h2><a href="<?= url('perusahaan/pelamar') ?>">Semua</a></div>
  <?php if (empty($pelamarTerbaru)): ?>
    <div class="m-card m-muted" style="padding:16px;font-size:13.5px">Belum ada pelamar. Lowongan yang tayang akan muncul di beranda mahasiswa.</div>
  <?php else: ?>
  <div class="m-group">
    <?php foreach ($pelamarTerbaru as $p): [$bj, $bt] = hpStatusLamaran($p['status']); ?>
      <a class="m-row" href="<?= url('lamaran/detail-pelamar/' . $p['id']) ?>"><?= hpAvatar($p['nama_mahasiswa'], !empty($p['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($p['foto'])) : null, 38) ?>
        <span class="m-rt"><?= e($p['nama_mahasiswa']) ?><span class="m-rs"><?= e($p['posisi']) ?></span></span><?= hpBadge($bj, $bt) ?></a>
    <?php endforeach; ?>
  </div>
  <?php endif; ?>
  <?php foreach ($lowonganSaya as $lw): if (!in_array($lw['status'], ['menunggu', 'revisi'], true)) continue; ?>
    <a class="m-card" href="<?= url('perusahaan/lowongan') ?>" style="padding:14px;display:flex;gap:12px;align-items:center;background:#fffaf0;box-shadow:inset 0 0 0 1px #f3e0ae;color:#122036"><span class="m-ri m-o"><?= hpIk('clock', 19) ?></span><span style="flex:1;font-size:13px"><b><?= e($lw['posisi']) ?></b><span class="m-muted" style="display:block"><?= $lw['status'] === 'revisi' ? 'Diminta perbaikan oleh Career Center' : 'Sedang ditinjau Career Center' ?></span></span></a>
  <?php endforeach; ?>
  <a class="m-fab" href="<?= url('lowongan/form-pasang') ?>"><?= hpIk('plus', 20, 2.6) ?>Pasang lowongan</a>
</section>

<section class="view active hanya-laptop">
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
  <div class="grid g4 g-stat-5 mb-18">
    <a class="stat" href="<?= url('perusahaan/lowongan?status=aktif') ?>"><div class="n"><?= (int) $lowonganAktif ?></div><div class="l">Lowongan aktif</div></a>
    <a class="stat" href="<?= url('perusahaan/lowongan?status=menunggu') ?>"><div class="n"><?= (int) $lowonganMenunggu ?></div><div class="l">Menunggu persetujuan / revisi</div></a>
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
