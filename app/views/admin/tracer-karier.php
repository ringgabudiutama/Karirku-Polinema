<?php
/**
 * View: admin/tracer-karier
 * Dipanggil oleh: AdminController::tracerKarier()
 * Variabel: $alumni, $ringkasanStatus, $sebaranBidang, $pembaruanTerbaru, $jurusan, $filter
 */
$page_title = 'Tracer Karier';
$active_menu = 'tracer';
require __DIR__ . '/../layouts/app-header.php';

$totalAlumni = array_sum(array_column($ringkasanStatus, 'jumlah'));
$warnaStatus = ['bekerja' => 'var(--navy)', 'wirausaha' => 'var(--blue)', 'studi lanjut' => '#7FA6E8', 'mencari kerja' => '#C3D5F3', 'belum bekerja' => '#E1E8F3'];
$labelStatus = ['bekerja' => 'Bekerja', 'wirausaha' => 'Wirausaha', 'studi lanjut' => 'Studi lanjut', 'mencari kerja' => 'Mencari kerja', 'belum bekerja' => 'Belum bekerja'];

$bidangCount = [];
$levelCount = [];
foreach ($alumni as $a) {
    if (!empty($a['tempat_kerja'])) {
        $bidangCount['Bekerja: ' . $a['tempat_kerja']] = ($bidangCount['Bekerja: ' . $a['tempat_kerja']] ?? 0) + 1;
    }
    if (!empty($a['level_jabatan'])) {
        $levelCount[$a['level_jabatan']] = ($levelCount[$a['level_jabatan']] ?? 0) + 1;
    }
}
arsort($levelCount);
/* Daftar angkatan datang dari controller dan sudah disaring mengikuti jurusan
   yang sedang dipilih. Tidak diambil dari $alumni, karena begitu satu angkatan
   dipilih, isi $alumni menyusut sehingga pilihan lain ikut hilang. */
$angkatanTerpakai = $angkatan ?? array_unique(array_column($alumni, 'angkatan'));
?>
<section class="view active">
  <?php
/* Label dipakai di beberapa tempat, supaya Admin selalu tahu kelompok mana
   yang sedang ditampilkan. */
$statusDipilih = $filter['status_mahasiswa'] ?? 'alumni';
$labelKelompok = ['alumni' => 'alumni', 'aktif' => 'mahasiswa aktif',
                  'semua'  => 'mahasiswa dan alumni'][$statusDipilih] ?? 'alumni';
?>
<div class="page-head"><div><h1>Tracer karier</h1><p>Data diperbarui otomatis dari lamaran diterima dan status karier yang diisi sendiri.</p></div>
    <a class="btn btn-primary" href="<?= url('admin/unduh-tracer-karier?' . http_build_query($filter)) ?>" target="_blank"><span data-ic="download"></span>Unduh laporan PDF</a>
  </div>
  <form class="filters" method="get" action="<?= url('admin/tracer-karier') ?>">
    <select class="input jur-filter" name="jurusan_id" onchange="this.form.submit()">
      <option value="">Semua jurusan</option>
      <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
    </select>
    <select class="input" name="angkatan" onchange="this.form.submit()">
      <option value=""><?= !empty($filter['jurusan_id']) ? 'Semua angkatan di jurusan ini' : 'Semua angkatan' ?></option>
      <?php foreach ($angkatanTerpakai as $ang): ?><option value="<?= (int) $ang ?>" <?= (string) $filter['angkatan'] === (string) $ang ? 'selected' : '' ?>>Angkatan <?= (int) $ang ?></option><?php endforeach; ?>
    </select>
    <?php
      /* Tracer memang untuk alumni, jadi itu pilihan bawaannya. Mahasiswa aktif
         yang sudah mengisi status karier tetap bisa dilihat lewat pilihan ini,
         supaya datanya tidak tersembunyi. */
      $opsiStatus = ['alumni' => 'Alumni saja', 'aktif' => 'Mahasiswa aktif saja',
                     'semua'  => 'Mahasiswa dan alumni'];
    ?>
    <select class="input" name="status_mahasiswa" onchange="this.form.submit()">
      <?php foreach ($opsiStatus as $nilai => $label): ?>
        <option value="<?= e($nilai) ?>" <?= $statusDipilih === $nilai ? 'selected' : '' ?>><?= e($label) ?></option>
      <?php endforeach; ?>
    </select>
  </form>

  <?php if ($statusDipilih !== 'alumni'): ?>
    <div class="alert alert-info"><span data-ic="info"></span><span>
      Sedang menampilkan <b><?= e($labelKelompok) ?></b>. Angka di bawah ikut berubah mengikuti pilihan ini.
      Kembalikan ke <b>Alumni saja</b> untuk angka tracer resmi.
    </span></div>
  <?php endif; ?>

  <div class="grid g2">
    <div class="panel">
      <h3>Status karier <?= e($labelKelompok) ?></h3>
      <div style="display:flex;gap:28px;align-items:center;flex-wrap:wrap;margin-top:10px">
        <div class="donut"><span><span><b><?= $totalAlumni ?></b><?= $statusDipilih === 'alumni' ? 'alumni' : 'orang' ?></span></span></div>
        <ul class="legend">
          <?php foreach ($ringkasanStatus as $r): $pct = $totalAlumni > 0 ? round($r['jumlah'] / $totalAlumni * 100) : 0; ?>
            <li><i style="background:<?= $warnaStatus[$r['status_karier']] ?? '#ccc' ?>"></i><?= e($labelStatus[$r['status_karier']] ?? ucfirst($r['status_karier'])) ?>, <?= $pct ?>%</li>
          <?php endforeach; ?>
          <?php if (empty($ringkasanStatus)): ?><li class="muted">Belum ada data alumni.</li><?php endif; ?>
        </ul>
      </div>
    </div>
    <div class="panel">
      <h3>Sebaran bidang perusahaan</h3>
      <div class="bars" style="margin-top:14px">
        <?php $maxBidang = $sebaranBidang ? max(array_column($sebaranBidang, 'jumlah')) : 1; foreach ($sebaranBidang as $sb): ?>
          <div class="bar-row"><span><?= e($sb['nama_bidang']) ?></span><div class="bar-track"><i style="width:<?= round($sb['jumlah'] / $maxBidang * 100) ?>%"></i></div><b><?= $sb['jumlah'] ?></b></div>
        <?php endforeach; ?>
        <?php if (empty($sebaranBidang)): ?><p class="muted">Belum ada data.</p><?php endif; ?>
      </div>
    </div>
    <div class="panel">
      <h3>Level jabatan</h3>
      <div class="bars" style="margin-top:14px">
        <?php $maxLevel = $levelCount ? max($levelCount) : 1; foreach ($levelCount as $lv => $jml): ?>
          <div class="bar-row"><span><?= e(ucfirst($lv)) ?></span><div class="bar-track"><i style="width:<?= round($jml / $maxLevel * 100) ?>%"></i></div><b><?= $jml ?></b></div>
        <?php endforeach; ?>
        <?php if (empty($levelCount)): ?><p class="muted">Belum ada data.</p><?php endif; ?>
      </div>
    </div>
    <div class="panel">
      <h3>Pembaruan terbaru</h3>
      <ul class="activity">
        <?php if (empty($pembaruanTerbaru)): ?><li class="muted">Belum ada pembaruan.</li><?php endif; ?>
        <?php foreach ($pembaruanTerbaru as $pb):
            $ket = $labelStatus[$pb['status_karier'] ?? 'belum bekerja'] ?? '-';
            if (!empty($pb['tempat_kerja'])) { $ket .= ' di ' . $pb['tempat_kerja']; }
            if (!empty($pb['posisi_kerja'])) { $ket .= ', ' . $pb['posisi_kerja']; }
            $sumber = $pb['dari_lamaran'] ? 'Otomatis dari lamaran diterima' : 'Diisi sendiri';
        ?>
          <li><span class="list-ic" data-ic="user"></span><span><b><?= e($pb['nama']) ?></b><br><?= e($pb['jenjang'] . ' ' . $pb['nama_prodi']) ?>, angkatan <?= (int) $pb['angkatan'] ?><br><?= e($ket) ?><small><?= e($sumber) ?>, <?= tanggalIndo($pb['karier_diperbarui_pada']) ?></small></span></li>
        <?php endforeach; ?>
      </ul>
    </div>
  </div>

  <div class="panel">
    <div class="panel-head"><h3>Daftar <?= e($labelKelompok) ?></h3></div>
    <div class="table-wrap"><table class="t">
      <tr><th>Nama</th><th>Jurusan</th><th>Angkatan</th><th>Status karier</th><th>Tempat kerja</th><th>Diperbarui</th></tr>
      <?php if (empty($alumni)): ?><tr><td colspan="6" class="muted" style="text-align:center;padding:30px">Tidak ada data.</td></tr><?php endif; ?>
      <?php foreach (array_slice($alumni, 0, 200) as $a): ?>
        <tr>
          <td><?= e($a['nama']) ?></td>
          <td><?= e($a['nama_jurusan']) ?></td>
          <td><?= (int) $a['angkatan'] ?></td>
          <td><?= e($labelStatus[$a['status_karier'] ?? 'belum bekerja'] ?? '-') ?></td>
          <td><?= e($a['tempat_kerja'] ?: '-') ?></td>
          <td><?= $a['karier_diperbarui_pada'] ? tanggalIndo($a['karier_diperbarui_pada']) : '-' ?></td>
        </tr>
      <?php endforeach; ?>
    </table></div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
