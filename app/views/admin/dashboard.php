<?php
/**
 * View: admin/dashboard
 * Dipanggil oleh: AdminController::dashboard()
 * Variabel: $statistik, $antreanVerifikasi, $notifikasi, $lamaranPerBulan
 */
$page_title = 'Dashboard Admin';
$active_menu = 'dashboard';
require __DIR__ . '/../layouts/app-header.php';

$persenBekerja = $statistik['total_alumni'] > 0 ? round($statistik['alumni_bekerja'] / $statistik['total_alumni'] * 100) : 0;
?>
<section class="view active">
  <div class="page-head"><div><h1>Selamat datang, Career Center</h1><p>Ringkasan KarirKu per <?= tanggalIndo(date('Y-m-d')) ?>.</p></div></div>
  <div class="grid g4" style="margin-bottom:18px">
    <a class="stat <?= $statistik['menunggu_verifikasi'] > 0 ? 'alert-stat' : '' ?>" href="<?= url('admin/persetujuan') ?>"><div class="n"><?= (int) $statistik['menunggu_verifikasi'] ?></div><div class="l">Menunggu verifikasi</div></a>
    <a class="stat" href="<?= url('admin/kelola-pengguna') ?>"><div class="n"><?= number_format($statistik['total_mahasiswa']) ?></div><div class="l">Mahasiswa dan alumni</div></a>
    <a class="stat" href="<?= url('admin/monitoring-lowongan') ?>"><div class="n"><?= number_format($statistik['lowongan_aktif']) ?></div><div class="l">Lowongan aktif dari <?= number_format($statistik['total_perusahaan']) ?> perusahaan</div></a>
    <a class="stat" href="<?= url('admin/tracer-karier') ?>"><div class="n" style="color:var(--ok)"><?= $persenBekerja ?>%</div><div class="l">Alumni sudah bekerja</div></a>
  </div>

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
            <tr><td colspan="5" class="muted" style="text-align:center;padding:24px">Tidak ada antrean. Semua sudah diperiksa.</td></tr>
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