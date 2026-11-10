<?php
// ===== FRONTEND · MAHASISWA · Dashboard ==============================
$page_title = 'Dashboard';
$active_menu = 'dashboard';
$hp_tanpa_bar = true;   // HP: kepala sapaan sendiri (lihat blok .hp)
require __DIR__ . '/../layouts/app-header.php';

$fotoUrl = !empty($mahasiswa['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($mahasiswa['foto'])) : url('assets/img/avatar-1.jpg');
$labelKarier = ['bekerja' => 'Bekerja', 'wirausaha' => 'Wirausaha', 'studi lanjut' => 'Studi lanjut', 'mencari kerja' => 'Mencari kerja', 'belum bekerja' => 'Belum bekerja'];
$interviewBerikut = null;
foreach ($lamaranTerbaru as $a) {
    if ($a['status'] === 'interview' && !empty($a['interview_tanggal']) && $a['interview_tanggal'] >= date('Y-m-d')) { $interviewBerikut = $a; break; }
}
$blnPendek = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
?>
<!-- ===== Tampilan HP (model UI: Beranda) ===== -->
<section class="hp" aria-label="Beranda">
  <header class="m-kepala">
    <a href="<?= url('mahasiswa/profil') ?>" aria-label="Profil karier"><?= hpAvatar($mahasiswa['nama'], $fotoUrl, 44) ?></a>
    <div class="m-sapa"><span><?= hpSapaan() ?></span><b><?= e($mahasiswa['nama']) ?></b></div>
    <a class="m-ib m-soft" href="<?= $hrefNotif ?>" aria-label="Notifikasi<?= $jumlahNotif ? ', ' . $jumlahNotif . ' belum dibaca' : '' ?>"><?= hpIk('bell', 21) ?><?php if ($jumlahNotif): ?><span class="m-dot"><?= (int) $jumlahNotif ?></span><?php endif; ?></a>
  </header>

  <form class="m-search" method="get" action="<?= url('lowongan/daftar') ?>" role="search">
    <?= hpIk('search', 20) ?><input type="search" name="q" placeholder="Cari posisi atau perusahaan" aria-label="Cari lowongan">
    <a class="m-ib" href="<?= url('lowongan/daftar') ?>" aria-label="Filter lowongan" style="width:40px;height:40px;border-radius:12px;background:#0a2656;color:#fff"><?= hpIk('sliders', 19) ?></a>
  </form>

  <?php if ($perluUpdateKarier): ?>
    <a class="m-card" href="<?= url('mahasiswa/profil') ?>#karier" style="display:flex;gap:12px;align-items:center;padding:13px 14px;color:#6b4500;background:#fffaf0;box-shadow:inset 0 0 0 1px #f3e0ae"><span class="m-ri m-o"><?= hpIk('info', 19) ?></span><span style="flex:1;font-size:13px"><b>Perbarui status karier</b><span style="display:block">Sudah lebih dari 6 bulan sejak terakhir diperbarui.</span></span></a>
  <?php endif; ?>

  <div class="m-hero-kartu">
    <div style="display:flex;justify-content:space-between;align-items:center;position:relative"><span style="font-size:12.5px;color:#b9cbec;font-weight:600">Status karier</span><span class="m-badge" style="background:rgba(255,255,255,.14);color:#fff"><?= hpIk('verified', 13, 2) ?>Terverifikasi</span></div>
    <div class="m-serif" style="font-size:24px;font-weight:600;margin:4px 0 14px;position:relative"><?= e($labelKarier[$mahasiswa['status_karier'] ?? ''] ?? 'Belum diisi') ?></div>
    <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px;position:relative">
      <a class="m-mini" href="<?= url('lamaran/lamaran-saya') ?>"><b><?= (int) $lamaranAktif ?></b><span>Lamaran</span></a>
      <a class="m-mini" href="<?= url('mahasiswa/disimpan') ?>"><b><?= (int) $jumlahDisimpan ?></b><span>Disimpan</span></a>
      <a class="m-mini" href="<?= url('lowongan/daftar') ?>"><b><?= count($rekomendasi) ?></b><span>Sesuai minat</span></a>
    </div>
  </div>

  <?php if ($interviewBerikut): $t = strtotime($interviewBerikut['interview_tanggal']); ?>
    <a class="m-card" href="<?= url('lamaran/lamaran-saya?status=proses') ?>" style="display:flex;gap:12px;align-items:center;padding:13px 14px;color:#122036">
      <span class="m-tanggal"><small><?= $blnPendek[(int) date('n', $t)] ?></small><b><?= date('j', $t) ?></b></span>
      <span style="flex:1;min-width:0"><b style="font-size:14px">Interview · <?= e($interviewBerikut['posisi']) ?></b><span class="m-muted" style="display:block;font-size:12.5px"><?= e($interviewBerikut['nama_perusahaan']) ?><?= !empty($interviewBerikut['interview_jam']) ? ' · ' . e(substr($interviewBerikut['interview_jam'], 0, 5)) : '' ?><?= !empty($interviewBerikut['interview_mode']) ? ' · ' . e(ucfirst($interviewBerikut['interview_mode'])) : '' ?></span></span>
      <span class="m-rc"><?= hpIk('chev', 19, 2) ?></span></a>
  <?php endif; ?>

  <div style="display:flex;flex-direction:column;gap:10px">
    <div class="m-sec"><h2>Rekomendasi untukmu</h2><a href="<?= url('lowongan/daftar') ?>">Lihat semua</a></div>
    <?php if (empty($rekomendasi)): ?>
      <div class="m-card m-muted" style="padding:16px;font-size:13.5px">Belum ada rekomendasi. Isi <a href="<?= url('mahasiswa/profil') ?>">bidang minat</a> di Profil supaya kami bisa menyarankan lowongan.</div>
    <?php else: foreach (array_slice($rekomendasi, 0, 4) as $l): ?>
      <?= hpKartuLowongan($l) ?>
    <?php endforeach; endif; ?>
  </div>
</section>

<section class="view active hanya-laptop">
  <?php if ($perluUpdateKarier): ?>
    <div class="alert alert-warn mb-16">
      <span data-ic="info"></span>
      <span>Status kariermu belum diperbarui lebih dari 6 bulan. <a href="<?= url('mahasiswa/profil') ?>#karier">Perbarui sekarang</a> supaya data tracer alumni tetap akurat.</span>
    </div>
  <?php endif; ?>

  <!-- ===== Sambutan ===== -->
  <div class="welcome">
    <div class="hero-pattern"></div>
    <img src="<?= e($fotoUrl) ?>" alt="">
    <div class="relative">
      <h1>Halo, <?= e($mahasiswa['nama']) ?></h1>
      <p><?= e($mahasiswa['jenjang'] . ' ' . $mahasiswa['nama_prodi']) ?>, angkatan <?= e((string) $mahasiswa['angkatan']) ?>
        <span class="verified" data-ic="check">Terverifikasi</span>
      </p>
    </div>
  </div>

  <!-- ===== Kartu statistik ===== -->
  <div class="grid g4 mb-18">
    <a class="stat" href="<?= url('lamaran/lamaran-saya') ?>"><div class="n"><?= (int) $lamaranAktif ?></div><div class="l">Lamaran sedang diproses</div></a>
    <a class="stat" href="<?= url('mahasiswa/disimpan') ?>"><div class="n"><?= (int) $jumlahDisimpan ?></div><div class="l">Lowongan disimpan</div></a>
    <a class="stat" href="<?= url('lowongan/daftar') ?>"><div class="n"><?= count($rekomendasi) ?></div><div class="l">Lowongan baru sesuai minat</div></a>
    <a class="stat" href="<?= url('mahasiswa/profil') ?>">
      <div class="n <?= $mahasiswa['status_karier'] === 'bekerja' ? 'text-ok' : 'text-inherit' ?>"><?= e(ucfirst($mahasiswa['status_karier'] ?? 'belum bekerja')) ?></div>
      <div class="l"><?= e($mahasiswa['tempat_kerja'] ?: 'Status karier') ?></div>
    </a>
  </div>

  <!-- ===== Rekomendasi & lamaran terbaru ===== -->
  <div class="grid g-side">
    <div>
      <div class="panel">
        <div class="panel-head"><h2>Rekomendasi untukmu</h2><a href="<?= url('lowongan/daftar') ?>">Lihat semua</a></div>
        <div class="jobs">
          <?php if (empty($rekomendasi)): ?>
            <p class="muted py-20">Belum ada rekomendasi. Lengkapi bidang minat di Profil Karier supaya kami bisa menyarankan lowongan yang cocok.</p>
          <?php else: foreach ($rekomendasi as $l): include __DIR__ . '/_kartu-lowongan.php'; endforeach; endif; ?>
        </div>
      </div>
      <div class="panel">
        <div class="panel-head"><h2>Lamaran terbaru</h2><a href="<?= url('lamaran/lamaran-saya') ?>">Lihat semua</a></div>
        <div class="table-wrap">
          <table class="t">
            <tr><th>Posisi</th><th>Perusahaan</th><th>Status</th></tr>
            <?php if (empty($lamaranTerbaru)): ?>
              <tr><td colspan="3" class="muted text-center p-18">Belum ada lamaran.</td></tr>
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
    <!-- ===== Kolom kanan: kelengkapan profil & tenggat ===== -->
    <div>
      <div class="panel">
        <h3>Kelengkapan profil</h3>
        <div class="progress-label"><span class="muted"><?= $kelengkapan >= 80 ? 'Hampir selesai' : 'Terus lengkapi' ?></span><b><?= (int) $kelengkapan ?>%</b></div>
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
            <li class="muted py-6">Tidak ada lowongan yang segera ditutup.</li>
          <?php endif; ?>
        </ul>
      </div>
    </div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
