<?php
/**
 * View: publik/status-akun
 * Dipanggil oleh: AuthController::statusAkun()
 * Variabel tersedia: $pengguna, $profil (mahasiswa atau perusahaan), $riwayat, $dokumen
 */
$f = flashAmbil();
$role = $pengguna['role'];
$status = $pengguna['status_akun'];
$nama = $role === 'mahasiswa' ? ($profil['nama'] ?? $pengguna['email']) : ($role === 'perusahaan' ? ($profil['nama_perusahaan'] ?? $pengguna['email']) : $pengguna['email']);

$petaBanner = [
    'menunggu'  => ['alert-warn', 'hourglass', 'Akunmu sedang diverifikasi', 'Nomor pendaftaran ' . e($pengguna['no_pendaftaran'] ?? '-') . '. Career Center memeriksa datamu paling lama 2 hari kerja. Kami kirim email saat ada hasil.'],
    'perbaikan' => ['alert-warn', 'alert', 'Datamu perlu diperbaiki', 'Lihat catatan Admin di bawah, lalu kirim ulang dokumen yang diminta.'],
    'ditolak'   => ['alert-bad', 'ban', 'Pendaftaran tidak disetujui', 'Lihat alasan penolakan di bawah. Kalau menurutmu ini keliru, hubungi Career Center.'],
    'aktif'     => ['alert-ok', 'checkc', 'Selamat, akunmu sudah aktif', 'Akunmu disetujui Career Center. Semua menu sekarang terbuka.'],
    'nonaktif'  => ['alert-bad', 'ban', 'Akun dinonaktifkan', 'Hubungi Career Center untuk informasi lebih lanjut.'],
];
[$bannerKelas, $bannerIkon, $bannerJudul, $bannerTeks] = $petaBanner[$status] ?? ['alert-info', 'info', 'Status akun', ''];

$catatanTerbaru = null;
foreach ($riwayat as $r) {
    if (in_array($r['keputusan'], ['perbaikan', 'ditolak'], true)) {
        $catatanTerbaru = $r;
    }
}

$dashboardUrl = $role === 'mahasiswa' ? 'mahasiswa/dashboard' : ($role === 'perusahaan' ? 'perusahaan/dashboard' : 'admin/dashboard');

$menuTerkunci = $role === 'mahasiswa'
    ? ['Dashboard', 'Lowongan', 'Disimpan', 'Lamaran Saya', 'Profil Karier']
    : ['Dashboard', 'Lowongan Saya', 'Pelamar', 'Profil Perusahaan'];

$jumlahNotif = jumlahNotifBelumDibaca($pengguna['id']);
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Status Akun | KarirKu Polinema</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<?= url('assets/css/style.css') ?>">
</head>
<body style="background:var(--sky)">
<header class="simple-top">
  <div class="container">
    <a class="brand" href="<?= url('beranda') ?>"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu Polinema</span></a>
    <div class="top-right">
      <div class="wrap-rel">
        <button class="icon-btn" aria-label="Notifikasi" data-pop="popN" data-ic="bell"><?php if ($jumlahNotif > 0): ?><span class="dot"><?= $jumlahNotif ?></span><?php endif; ?></button>
        <div class="pop" id="popN">
          <div class="pop-head">Notifikasi</div>
          <?php foreach (notifTerbaru($pengguna['id'], 5) as $n): ?>
            <a class="item <?= $n['dibaca'] ? '' : 'unread' ?>" href="#"><span class="list-ic" data-ic="hourglass"></span><span><b><?= e($n['judul']) ?></b><br><small class="muted"><?= e($n['pesan']) ?></small></span></a>
          <?php endforeach; ?>
        </div>
      </div>
      <a class="btn btn-sm btn-outline" href="<?= url('keluar') ?>"><span data-ic="logout"></span>Keluar</a>
    </div>
  </div>
</header>

<main class="container" style="max-width:820px;padding:36px 0 120px">
  <p class="muted" style="margin-bottom:6px">Halo, <?= e($nama) ?></p>
  <h1 style="font-size:1.9rem">Status akun</h1>

  <?php if ($f): ?>
    <div class="alert alert-<?= $f['tipe'] === 'ok' ? 'ok' : 'bad' ?>"><span data-ic="alert"></span><span><?= e($f['pesan']) ?></span></div>
  <?php endif; ?>

  <div class="status-hero alert <?= $bannerKelas ?>">
    <span data-ic="<?= $bannerIkon ?>"></span>
    <div style="flex:1">
      <h2><?= e($bannerJudul) ?></h2>
      <p><?= $bannerTeks ?></p>
      <?php if ($catatanTerbaru): ?>
        <p style="margin-top:8px"><b>Catatan Admin:</b> <?= e($catatanTerbaru['catatan']) ?></p>
      <?php endif; ?>
      <div style="margin-top:14px">
        <?php if ($status === 'perbaikan'): ?>
          <button class="btn btn-warn" data-open="mFix">Perbaiki data</button>
        <?php elseif ($status === 'ditolak' || $status === 'nonaktif'): ?>
          <a class="btn btn-outline" href="<?= url('beranda') ?>#kontak">Hubungi Career Center</a>
        <?php elseif ($status === 'aktif'): ?>
          <a class="btn btn-ok" href="<?= url($dashboardUrl) ?>">Masuk ke dashboard</a>
        <?php endif; ?>
      </div>
    </div>
  </div>

  <div class="grid g2" style="align-items:start">
    <div class="panel">
      <h3>Progres verifikasi</h3>
      <ol class="vtl">
        <li class="done"><span class="b"><span data-ic="check"></span></span><span><b>Pendaftaran dikirim</b><small><?= tanggalWaktuIndo($pengguna['dibuat_pada']) ?></small></span></li>
        <?php foreach ($riwayat as $r):
            $kelasBaris = in_array($r['keputusan'], ['disetujui', 'aktif'], true) ? 'done' : (in_array($r['keputusan'], ['perbaikan', 'ditolak', 'nonaktif'], true) ? 'bad' : '');
            $labelKeputusan = ['disetujui' => 'Disetujui', 'perbaikan' => 'Perlu perbaikan', 'ditolak' => 'Ditolak', 'nonaktif' => 'Dinonaktifkan', 'aktif' => 'Diaktifkan kembali'][$r['keputusan']] ?? $r['keputusan'];
        ?>
          <li class="<?= $kelasBaris ?>"><span class="b"><?= $kelasBaris === 'bad' ? '<span data-ic="x"></span>' : '<span data-ic="check"></span>' ?></span><span><b><?= e($labelKeputusan) ?></b><small><?= tanggalWaktuIndo($r['tanggal']) ?></small></span></li>
        <?php endforeach; ?>
        <?php if ($status === 'menunggu' || $status === 'perbaikan'): ?>
          <li class="now"><span class="b">&hellip;</span><span><b>Akun aktif</b><small>Menunggu</small></span></li>
        <?php endif; ?>
      </ol>
    </div>

    <div class="panel">
      <div class="panel-head"><h3>Data yang kamu kirim</h3><span><?php if ($status === 'perbaikan'): ?><button class="btn btn-sm btn-outline" data-open="mFix">Edit</button><?php endif; ?></span></div>
      <dl class="dl" style="grid-template-columns:120px 1fr">
        <?php if ($role === 'mahasiswa' && $profil): ?>
          <dt>Nama</dt><dd><?= e($profil['nama']) ?></dd>
          <dt>NIM</dt><dd><?= e($profil['nim']) ?></dd>
          <dt>Jurusan</dt><dd><?= e($profil['nama_jurusan']) ?></dd>
          <dt>Prodi</dt><dd><?= e($profil['jenjang'] . ' ' . $profil['nama_prodi']) ?></dd>
          <dt>Angkatan</dt><dd><?= e((string) $profil['angkatan']) ?></dd>
          <dt>Status</dt><dd><?= $profil['status_mahasiswa'] === 'alumni' ? 'Alumni' : 'Mahasiswa aktif' ?></dd>
        <?php elseif ($role === 'perusahaan' && $profil): ?>
          <dt>Perusahaan</dt><dd><?= e($profil['nama_perusahaan']) ?></dd>
          <dt>Bidang</dt><dd><?= e($profil['bidang_usaha']) ?></dd>
          <dt>Alamat</dt><dd><?= e($profil['alamat'] . ', ' . $profil['kota']) ?></dd>
          <dt>PIC</dt><dd><?= e($profil['nama_pic']) ?></dd>
        <?php endif; ?>
        <dt>Email</dt><dd><?= e($pengguna['email']) ?></dd>
        <dt>Dokumen</dt><dd>
          <?php foreach ($dokumen as $d): ?>
            <a href="<?= url('unduh.php?tipe=' . e($d['tipe']) . '&file=' . e($d['file'])) ?>" target="_blank"><?= e(strtoupper($d['tipe'])) ?></a><br>
          <?php endforeach; ?>
          <?php if (empty($dokumen)): ?>-<?php endif; ?>
        </dd>
      </dl>
    </div>
  </div>

  <div class="panel" style="margin-top:18px">
    <h3>Menu yang terbuka setelah akun aktif</h3>
    <div class="lock-list">
      <?php foreach ($menuTerkunci as $m): ?>
        <span style="<?= $status === 'aktif' ? 'background:var(--ok-bg);color:var(--ok)' : '' ?>"><span data-ic="<?= $status === 'aktif' ? 'check' : 'lock' ?>"></span><?= e($m) ?></span>
      <?php endforeach; ?>
    </div>
  </div>
</main>

<?php if ($status === 'perbaikan'): ?>
<div class="modal" id="mFix" role="dialog" aria-modal="true" aria-labelledby="fxT">
  <div class="modal-box">
    <div class="modal-head"><h3 id="fxT">Perbaiki data</h3><button class="close" data-close aria-label="Tutup" data-ic="x"></button></div>
    <form method="post" action="<?= url('auth/kirim-perbaikan') ?>" enctype="multipart/form-data">
      <?= csrfField() ?>
      <div class="modal-body">
        <?php if ($catatanTerbaru): ?>
          <div class="alert alert-warn"><span data-ic="info"></span><span>Catatan Admin: <?= e($catatanTerbaru['catatan']) ?></span></div>
        <?php endif; ?>
        <?php if ($role === 'mahasiswa'):
            $tipeDok = ($profil['status_mahasiswa'] ?? 'aktif') === 'alumni' ? 'ijazah' : 'ktm';
        ?>
          <div class="field"><label>Unggah ulang <?= $tipeDok === 'ijazah' ? 'ijazah/SKL' : 'KTM' ?></label>
            <label class="upload"><input type="file" name="file_<?= $tipeDok ?>" accept=".pdf,.jpg,.jpeg,.png"><span data-ic="upload"></span><div><b>Pilih file</b></div><div class="hint">PDF, JPG, atau PNG. Maksimal 2 MB.</div></label>
          </div>
        <?php else: ?>
          <div class="field"><label>Unggah ulang NIB</label><label class="upload"><input type="file" name="file_nib" accept=".pdf,.jpg,.jpeg,.png"><span data-ic="upload"></span><div><b>Pilih file</b></div></label></div>
          <div class="field"><label>Unggah ulang NPWP</label><label class="upload"><input type="file" name="file_npwp" accept=".pdf,.jpg,.jpeg,.png"><span data-ic="upload"></span><div><b>Pilih file</b></div></label></div>
          <div class="field"><label>Unggah ulang akta pendirian</label><label class="upload"><input type="file" name="file_akta" accept=".pdf,.jpg,.jpeg,.png"><span data-ic="upload"></span><div><b>Pilih file</b></div></label></div>
        <?php endif; ?>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Batal</button><button type="submit" class="btn btn-primary">Kirim ulang</button></div>
    </form>
  </div>
</div>
<?php endif; ?>

<script src="<?= url('assets/js/app.js') ?>"></script>
</body>
</html>
