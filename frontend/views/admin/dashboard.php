<?php
// ===== FRONTEND · ADMIN · Dashboard ==================================
$page_title = 'Dashboard Admin';
$active_menu = 'dashboard';
$hp_tanpa_bar = true;
require __DIR__ . '/../layouts/app-header.php';

$persenBekerja = $statistik['total_alumni'] > 0 ? round($statistik['alumni_bekerja'] / $statistik['total_alumni'] * 100) : 0;
$statusLamaranHp = Database::fetchAll("SELECT status, COUNT(*) AS n FROM lamaran GROUP BY status");
$jmlStatus = array_column($statusLamaranHp, 'n', 'status');
$warnaStatus = ['diajukan' => ['#94a3b8', 'Diajukan'], 'screening' => ['#3d82f0', 'Screening'], 'interview' => ['#f2b233', 'Interview'],
                'diterima' => ['#1f9254', 'Diterima'], 'ditolak' => ['#d6564c', 'Ditolak'], 'dibatalkan' => ['#4b5565', 'Dibatalkan']];
$namaAdmin = $adminShell['nama'] ?? 'Admin Career Center';
?>
<!-- ===== Tampilan HP (model UI: Beranda admin) ===== -->
<section class="hp" aria-label="Beranda admin">
  <header class="m-kepala">
    <a href="<?= $hrefProfil ?>" aria-label="Profil saya"><?= hpAvatar($namaAdmin, !empty($adminShell['foto']) ? $fotoTampil : null, 44) ?></a>
    <div class="m-sapa"><span><?= e($subTampil ?: 'Career Center') ?></span><b><?= e($namaAdmin) ?></b></div>
    <a class="m-ib m-soft" href="<?= $hrefNotif ?>" aria-label="Notifikasi"><?= hpIk('bell', 21) ?><?php if ($jumlahNotif): ?><span class="m-dot"><?= (int) $jumlahNotif ?></span><?php endif; ?></a>
  </header>
  <div class="m-sec"><h2>Antrean hari ini</h2></div>
  <div style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px">
    <a href="<?= url('admin/persetujuan') ?>" style="border-radius:20px;padding:16px;color:#fff;background:linear-gradient(145deg,#1d5bc6,#0f3474)"><span style="opacity:.85"><?= hpIk('shield', 22) ?></span><div style="font-size:28px;font-weight:800;margin-top:10px;line-height:1"><?= (int) $statistik['menunggu_verifikasi'] ?></div><div style="font-size:12.5px;font-weight:700;color:#d4e1f8;margin-top:3px">Akun menunggu</div></a>
    <a href="<?= url('admin/persetujuan-lowongan') ?>" style="border-radius:20px;padding:16px;color:#3d2a00;background:linear-gradient(145deg,#ffe6a8,#ffd27a)"><span><?= hpIk('briefcase', 22) ?></span><div style="font-size:28px;font-weight:800;margin-top:10px;line-height:1"><?= (int) $statistik['lowongan_menunggu'] ?></div><div style="font-size:12.5px;font-weight:700;margin-top:3px;color:#6b4a00">Lowongan menunggu</div></a>
  </div>
  <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px">
    <a class="m-stat" href="<?= url('admin/monitoring-lowongan') ?>" style="padding:12px;color:inherit"><div class="m-n" style="font-size:20px"><?= (int) $statistik['lowongan_aktif'] ?></div><div class="m-l">Loker aktif</div></a>
    <a class="m-stat" href="<?= url('admin/rekap-lamaran') ?>" style="padding:12px;color:inherit"><div class="m-n" style="font-size:20px"><?= (int) $statistik['total_lamaran'] ?></div><div class="m-l">Lamaran</div></a>
    <a class="m-stat" href="<?= url('admin/kelola-pengguna?tab=perusahaan') ?>" style="padding:12px;color:inherit"><div class="m-n" style="font-size:20px"><?= (int) $statistik['total_perusahaan'] ?></div><div class="m-l">Mitra</div></a>
  </div>
  <?php $totLam = array_sum($jmlStatus); if ($totLam > 0): ?>
  <div class="m-card" style="padding:16px">
    <div style="display:flex;justify-content:space-between;align-items:baseline"><b style="font-size:14.5px">Status lamaran</b><span class="m-muted" style="font-size:12px"><?= (int) $totLam ?> total</span></div>
    <div style="display:flex;height:12px;border-radius:6px;overflow:hidden;margin:12px 0 10px;gap:2px">
      <?php foreach ($warnaStatus as $k => [$w, $l]): if (empty($jmlStatus[$k])) continue; ?><span style="flex:<?= (int) $jmlStatus[$k] ?>;background:<?= $w ?>"></span><?php endforeach; ?>
    </div>
    <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:6px 10px;font-size:12px;font-weight:600;color:#33435c">
      <?php foreach ($warnaStatus as $k => [$w, $l]): ?><span style="display:flex;align-items:center;gap:6px"><i style="width:8px;height:8px;border-radius:2px;background:<?= $w ?>;display:block;flex:none"></i><?= $l ?> <?= (int) ($jmlStatus[$k] ?? 0) ?></span><?php endforeach; ?>
    </div>
  </div>
  <?php endif; ?>
  <a class="m-card" href="<?= url('admin/tracer-karier') ?>" style="padding:14px 16px;display:flex;align-items:center;gap:14px;color:#122036">
    <div style="width:52px;height:52px;border-radius:50%;background:conic-gradient(#1f9254 0 <?= (int) $persenBekerja ?>%,#e4eaf3 0);display:grid;place-items:center;flex:none"><div style="width:42px;height:42px;border-radius:50%;background:#fff;display:grid;place-items:center;font-weight:800;font-size:12.5px;color:#17663a"><?= (int) $persenBekerja ?>%</div></div>
    <div style="flex:1"><b style="font-size:14px">Alumni sudah bekerja</b><div class="m-muted m-small"><?= (int) $statistik['alumni_bekerja'] ?> dari <?= (int) $statistik['total_alumni'] ?> alumni · Tracer karier</div></div><span class="m-rc"><?= hpIk('chev', 19, 2) ?></span></a>
</section>

<section class="view active hanya-laptop">
  <div class="page-head"><div><h1>Selamat datang, Career Center</h1><p>Ringkasan KarirKu per <?= tanggalIndo(date('Y-m-d')) ?>.</p></div></div>
  <!-- ===== Kartu statistik ===== -->
  <div class="grid g4 g-stat-5 mb-18">
    <a class="stat <?= $statistik['menunggu_verifikasi'] > 0 ? 'alert-stat' : '' ?>" href="<?= url('admin/persetujuan') ?>"><div class="n"><?= (int) $statistik['menunggu_verifikasi'] ?></div><div class="l">Akun menunggu verifikasi</div></a>
    <a class="stat <?= $statistik['lowongan_menunggu'] > 0 ? 'alert-stat' : '' ?>" href="<?= url('admin/persetujuan-lowongan') ?>"><div class="n"><?= (int) $statistik['lowongan_menunggu'] ?></div><div class="l">Lowongan menunggu persetujuan</div></a>
    <a class="stat" href="<?= url('admin/kelola-pengguna') ?>"><div class="n"><?= number_format($statistik['total_mahasiswa']) ?></div><div class="l">Mahasiswa dan alumni</div></a>
    <a class="stat" href="<?= url('admin/monitoring-lowongan?status=aktif') ?>"><div class="n"><?= number_format($statistik['lowongan_aktif']) ?></div><div class="l">Lowongan aktif dari <?= number_format($statistik['total_perusahaan']) ?> perusahaan</div></a>
    <a class="stat" href="<?= url('admin/tracer-karier') ?>"><div class="n text-ok"><?= $persenBekerja ?>%</div><div class="l">Alumni sudah bekerja</div></a>
  </div>

  <!-- ===== Grafik & antrean verifikasi ===== -->
  <div class="grid g-side">
    <div>
      <div class="panel">
        <div class="panel-head"><h2>Lamaran per bulan</h2><a href="<?= url('admin/rekap-lamaran') ?>">Rekap lamaran</a></div>
        <?php $maxLamaran = max(1, max(array_column($lamaranPerBulan, 'jumlah'))); ?>
        <div class="cols">
          <?php foreach ($lamaranPerBulan as $bln): ?>
            <div class="c">
              <b><?= number_format($bln['jumlah']) ?></b>
              <i style="height:<?= $bln['jumlah'] > 0 ? max(6, round($bln['jumlah'] / $maxLamaran * 100)) : 0 ?>%"></i>
              <span><?= e($bln['label']) ?></span>
            </div>
          <?php endforeach; ?>
        </div>
      </div>
      <div class="panel">
        <div class="panel-head"><h2>Antrean verifikasi</h2><a href="<?= url('admin/persetujuan') ?>">Buka semua</a></div>
        <div class="table-wrap"><table class="t">
          <tr><th>Pendaftar</th><th>Tanggal</th><th>Menunggu</th><th>Jenis</th><th></th></tr>
          <?php if (empty($antreanVerifikasi)): ?>
            <tr><td colspan="5" class="muted text-center p-24">Tidak ada antrean. Semua sudah diperiksa.</td></tr>
          <?php else: foreach ($antreanVerifikasi as $q):
              $detik = time() - strtotime($q['dibuat_pada']);
              $hari = (int) floor($detik / 86400);
              if ($hari >= 2) { $kelasTunggu = 'wait-r'; $labelTunggu = $hari . ' hari'; }
              elseif ($hari >= 1) { $kelasTunggu = 'wait-y'; $labelTunggu = $hari . ' hari'; }
              elseif ($detik >= 3600) { $kelasTunggu = 'wait-g'; $labelTunggu = floor($detik / 3600) . ' jam'; }
              else { $kelasTunggu = 'wait-g'; $labelTunggu = 'Baru saja'; }
          ?>
            <tr>
              <td><b><?= e($q['nama']) ?></b><?php if ($q['nama_jurusan']): ?><br><small class="muted"><?= e($q['nama_jurusan']) ?></small><?php endif; ?></td>
              <td><?= tanggalIndo($q['dibuat_pada']) ?></td>
              <td class="<?= $kelasTunggu ?>"><?= $labelTunggu ?></td>
              <td><span class="pill <?= !empty($q['jumlah_perbaikan']) ? 'p-perbaikan' : 'p-diajukan' ?>"><?= !empty($q['jumlah_perbaikan']) ? 'Kiriman ulang' : 'Baru' ?></span></td>
              <td><a class="btn btn-sm btn-primary" href="<?= url('admin/detail-pendaftar/' . $q['pengguna_id']) ?>">Periksa</a></td>
            </tr>
          <?php endforeach; endif; ?>
        </table></div>
      </div>
    </div>
    <!-- ===== Aktivitas terbaru ===== -->
    <div class="panel">
      <h3>Aktivitas terbaru</h3>
      <ul class="activity">
        <?php if (empty($notifikasi)): ?><li class="muted">Belum ada aktivitas.</li><?php endif; ?>
        <?php foreach ($notifikasi as $n): ?>
          <li><span class="list-ic" data-ic="bell"></span><span><b><?= e($n['judul']) ?></b><?= e($n['pesan']) ?><small><?= tanggalWaktuIndo($n['dibuat_pada']) ?></small></span></li>
        <?php endforeach; ?>
      </ul>
    </div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
