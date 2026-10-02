<?php
/**
 * View: mahasiswa/dashboard
 * Dipanggil oleh: MahasiswaController::dashboard()
 * Variabel: $mahasiswa, $kelengkapan, $lamaranAktif, $jumlahDisimpan,
 *           $rekomendasi, $lamaranTerbaru, $perluUpdateKarier
 */
$page_title = 'Dashboard';
$active_menu = 'dashboard';
require __DIR__ . '/../layouts/app-header.php';

$fotoUrl = !empty($mahasiswa['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($mahasiswa['foto'])) : url('assets/img/avatar-1.jpg');
?>
<section class="view active">
  <?php if ($perluUpdateKarier): ?>
    <div class="alert alert-warn" style="margin-bottom:16px">
      <span data-ic="info"></span>
      <span>Status kariermu belum diperbarui lebih dari 6 bulan. <a href="<?= url('mahasiswa/profil') ?>#karier">Perbarui sekarang</a> supaya data tracer alumni tetap akurat.</span>
    </div>
  <?php endif; ?>

  <div class="welcome">
    <div class="hero-pattern"></div>
    <img src="<?= e($fotoUrl) ?>" alt="">
    <div style="position:relative">
      <h1>Halo, <?= e($mahasiswa['nama']) ?></h1>
      <p><?= e($mahasiswa['jenjang'] . ' ' . $mahasiswa['nama_prodi']) ?>, angkatan <?= e((string) $mahasiswa['angkatan']) ?>
        <span class="verified" data-ic="check">Terverifikasi</span>
      </p>
    </div>
  </div>

  <div class="grid g4" style="margin-bottom:18px">
    <a class="stat" href="<?= url('lamaran/lamaran-saya') ?>"><div class="n"><?= (int) $lamaranAktif ?></div><div class="l">Lamaran sedang diproses</div></a>
    <a class="stat" href="<?= url('mahasiswa/disimpan') ?>"><div class="n"><?= (int) $jumlahDisimpan ?></div><div class="l">Lowongan disimpan</div></a>
    <a class="stat" href="<?= url('lowongan/daftar') ?>"><div class="n"><?= count($rekomendasi) ?></div><div class="l">Lowongan baru sesuai minat</div></a>
    <a class="stat" href="<?= url('mahasiswa/profil') ?>">
      <div class="n" style="color:<?= $mahasiswa['status_karier'] === 'bekerja' ? 'var(--ok)' : 'inherit' ?>"><?= e(ucfirst($mahasiswa['status_karier'] ?? 'belum bekerja')) ?></div>
      <div class="l"><?= e($mahasiswa['tempat_kerja'] ?: 'Status karier') ?></div>
    </a>
  </div>

  <div class="grid g-side">
    <div>
      <div class="panel">
        <div class="panel-head"><h2>Rekomendasi untukmu</h2><a href="<?= url('lowongan/daftar') ?>">Lihat semua</a></div>
        <div class="jobs">
          <?php if (empty($rekomendasi)): ?>
            <p class="muted" style="padding:20px 0">Belum ada rekomendasi. Lengkapi bidang minat di Profil Karier supaya kami bisa menyarankan lowongan yang cocok.</p>
          <?php else: foreach ($rekomendasi as $l): include __DIR__ . '/_kartu-lowongan.php'; endforeach; endif; ?>
        </div>
      </div>
      <div class="panel">
        <div class="panel-head"><h2>Lamaran terbaru</h2><a href="<?= url('lamaran/lamaran-saya') ?>">Lihat semua</a></div>
        <div class="table-wrap">
          <table class="t">
            <tr><th>Posisi</th><th>Perusahaan</th><th>Status</th></tr>
            <?php if (empty($lamaranTerbaru)): ?>
              <tr><td colspan="3" class="muted" style="text-align:center;padding:18px">Belum ada lamaran.</td></tr>
            <?php else: foreach ($lamaranTerbaru as $a): ?>
              <tr>
                <td><a href="<?= url('lamaran/lamaran-saya') ?>"><b><?= e($a['posisi']) ?></b></a></td>
                <td><?= e($a['nama_perusahaan']) ?></td>
                <td><?= badgeHtml(labelStatusLamaran($a['status'])) ?></td>
              </tr>
            <?php endforeach; endif; ?>
          </table>
        </div>
      </div>
    </div>
    <div>
      <div class="panel">
        <h3>Kelengkapan profil</h3>
        <div style="display:flex;justify-content:space-between;font-size:.9rem;margin-bottom:6px"><span class="muted"><?= $kelengkapan >= 80 ? 'Hampir selesai' : 'Terus lengkapi' ?></span><b><?= (int) $kelengkapan ?>%</b></div>
        <div class="progress"><i style="width:<?= (int) $kelengkapan ?>%"></i></div>
        <ul class="checklist">
          <li><span class="<?= !empty($mahasiswa['foto']) ? 'ok' : 'no' ?>" data-ic="checkc"></span><a href="<?= url('mahasiswa/profil') ?>">Foto profil</a></li>
          <li><span class="<?= !empty($mahasiswa['tentang']) ? 'ok' : 'no' ?>" data-ic="checkc"></span><a href="<?= url('mahasiswa/profil') ?>">Data diri</a></li>
          <li><span class="<?= !empty($mahasiswa['file_ktm']) ? 'ok' : 'no' ?>" data-ic="checkc"></span><a href="<?= url('mahasiswa/profil') ?>">Dokumen KTM/ijazah</a></li>
          <li><span class="<?= !empty($mahasiswa['file_cv']) ? 'ok' : 'no' ?>" data-ic="checkc"></span><a href="<?= url('mahasiswa/profil') ?>">CV tersedia</a></li>
        </ul>
      </div>
      <div class="panel">
        <h3>Segera ditutup</h3>
        <ul class="activity">
          <?php $adaSegeraTutup = false; foreach ($rekomendasi as $l): if (sisaHari($l['batas_lamaran']) <= 3 && sisaHari($l['batas_lamaran']) >= 0): $adaSegeraTutup = true; ?>
            <li><span class="list-ic" data-ic="clock"></span><span><a href="<?= url('lowongan/detail/' . $l['id']) ?>"><b><?= e($l['posisi']) ?></b></a><small><?= e($l['nama_perusahaan']) ?>, tersisa <?= sisaHari($l['batas_lamaran']) ?> hari</small></span></li>
          <?php endif; endforeach; if (!$adaSegeraTutup): ?>
            <li class="muted" style="padding:6px 0">Tidak ada lowongan yang segera ditutup.</li>
          <?php endif; ?>
        </ul>
      </div>
    </div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
