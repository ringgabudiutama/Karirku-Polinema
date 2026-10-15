<?php
// ===== FRONTEND · MAHASISWA · Lamaran saya ===========================
$page_title = 'Lamaran Saya';
$active_menu = 'lamaran';
require __DIR__ . '/../layouts/app-header.php';

$grup = trim($_GET['status'] ?? 'semua');

$dalamGrup = function (array $a, string $g): bool {
    if ($g === 'semua') return true;
    if ($g === 'proses') return in_array($a['status'], ['diajukan', 'screening', 'interview'], true);
    return $a['status'] === $g;
};
$grupOpsi = [
    'semua'      => 'Semua',
    'proses'     => 'Diproses',
    'diterima'   => 'Diterima',
    'ditolak'    => 'Ditolak',
    'dibatalkan' => 'Dibatalkan',
];
$daftarTampil = array_filter($lamaran, fn($a) => $dalamGrup($a, $grup));
?>
<section class="view active">
  <div class="page-head"><div><h1>Lamaran Saya</h1><p>Pantau setiap lamaran dari diajukan sampai hasil akhir.</p></div></div>

  <!-- ===== Tab status ===== -->
  <div class="tabs" data-tabs="x">
    <?php foreach ($grupOpsi as $key => $label): $jumlahGrup = count(array_filter($lamaran, fn($a) => $dalamGrup($a, $key))); ?>
      <a href="<?= url('lamaran/lamaran-saya?status=' . $key) ?>" class="<?= $grup === $key ? 'active' : '' ?>"><?= e($label) ?><span class="c"><?= $jumlahGrup ?></span></a>
    <?php endforeach; ?>
  </div>

  <?php if (empty($daftarTampil)): ?>
    <div class="panel text-center">
      <h3>Belum ada lamaran di sini</h3>
      <p class="muted">Temukan lowongan yang sesuai dan kirim lamaran pertamamu.</p>
      <a class="btn btn-primary" href="<?= url('lowongan/daftar') ?>">Cari lowongan</a>
    </div>
  <?php else: foreach ($daftarTampil as $a):
      $urutanStep = ['diajukan' => 0, 'screening' => 1, 'interview' => 2];
      $idx = $urutanStep[$a['status']] ?? (in_array($a['status'], ['diterima', 'ditolak'], true) ? 3 : -1);
      $labelStep = ['Diajukan', 'Screening CV', 'Interview', $a['status'] === 'diterima' ? 'Diterima' : ($a['status'] === 'ditolak' ? 'Ditolak' : 'Hasil')];
      $logoUrl = !empty($a['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($a['logo'])) : null;
  ?>
    <article class="app-card">
      <div class="app-card-head">
        <?php if ($logoUrl): ?><img class="avatar" src="<?= e($logoUrl) ?>" alt=""><?php else: ?><span class="avatar avatar-inisial"><?= e(inisial($a['nama_perusahaan'])) ?></span><?php endif; ?>
        <div class="grow"><a href="<?= url('lowongan/detail/' . $a['lowongan_id']) ?>"><b><?= e($a['posisi']) ?></b></a><div class="muted fs-90"><?= e($a['nama_perusahaan']) ?>, dilamar <?= tanggalIndo($a['tanggal_lamar']) ?>, dengan <?= $a['jenis_cv'] === 'unggah' ? 'CV unggahan' : 'CV otomatis' ?></div></div>
        <?= badgeHtml(labelStatusLamaran($a['status'])) ?>
      </div>
      <div class="timeline">
        <?php if ($a['status'] === 'dibatalkan'): ?>
          <div class="tl">Diajukan</div><div class="tl">Screening CV</div><div class="tl">Interview</div><div class="tl">Hasil</div>
        <?php else: foreach ($labelStep as $i => $lbl):
            $kelas = $i <= $idx ? 'done' : '';
            if ($i === 3 && $a['status'] === 'diterima') $kelas = 'done good';
            if ($i === 3 && $a['status'] === 'ditolak') $kelas = 'done bad';
        ?>
          <div class="tl <?= $kelas ?>"><?= e($lbl) ?></div>
        <?php endforeach; endif; ?>
      </div>

      <?php if ($a['status'] === 'interview' && $a['interview_tanggal']): ?>
        <?php
        $rincianInterview = Interview::rincian([
            'tanggal'       => $a['interview_tanggal'],
            'jam'           => $a['interview_jam'],
            'mode'          => $a['interview_mode'],
            'lokasi_tautan' => $a['interview_lokasi'] ?? '',
            'tempat'        => $a['interview_tempat'] ?? '',
            'ruangan'       => $a['interview_ruangan'] ?? '',
            'dresscode'     => $a['interview_dresscode'] ?? '',
            'yang_dibawa'   => $a['interview_yang_dibawa'] ?? '',
            'narahubung'    => $a['interview_narahubung'] ?? '',
            'catatan'       => $a['interview_catatan'] ?? '',
        ]);
        ?>
        <div class="info-box items-start">
          <span data-ic="calendar"></span>
          <span class="flex-1">
            <b>Jadwal interview</b>
            <table class="tabel-info">
              <?php foreach ($rincianInterview as [$label, $isi]): ?>
                <tr>
                  <td><?= e($label) ?></td>
                  <td>
                    <?php if ($label === 'Tautan'): ?>
                      <a href="<?= e($isi) ?>" target="_blank" rel="noopener"><?= e($isi) ?></a>
                    <?php else: ?>
                      <?= e($isi) ?>
                    <?php endif; ?>
                  </td>
                </tr>
              <?php endforeach; ?>
            </table>
          </span>
        </div>
      <?php elseif ($a['status'] === 'diterima'): ?>
        <div class="info-box ok"><span data-ic="checkc"></span><span><b>Selamat, kamu diterima!</b> Status kariermu otomatis diperbarui menjadi Bekerja di <?= e($a['nama_perusahaan']) ?>. <a href="<?= url('mahasiswa/profil') ?>#karier">Lihat status karier</a></span></div>
      <?php elseif ($a['status'] === 'ditolak'): ?>
        <div class="info-box gray"><span data-ic="info"></span><span><b>Catatan perusahaan:</b> <?= e($a['catatan_perusahaan'] ?: '-') ?> <a href="<?= url('lowongan/daftar') ?>">Lihat lowongan serupa</a></span></div>
      <?php elseif ($a['status'] === 'dibatalkan'): ?>
        <div class="info-box gray"><span data-ic="info"></span><span>Kamu membatalkan lamaran ini.</span></div>
      <?php endif; ?>

      <?php if ($a['status'] === 'diajukan'): ?>
        <div class="text-right mt-10">
          <form class="d-inline" method="post" action="<?= url('lamaran/batalkan/' . $a['id']) ?>" onsubmit="return confirm('Batalkan lamaran ini? Lamaran yang dibatalkan tidak bisa dikirim ulang untuk lowongan yang sama.')">
            <?= csrfField() ?>
            <button class="btn btn-sm btn-outline" type="submit">Batalkan lamaran</button>
          </form>
        </div>
      <?php endif; ?>
    </article>
  <?php endforeach; endif; ?>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
