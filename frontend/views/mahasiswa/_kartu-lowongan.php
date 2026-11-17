<?php
// ===== FRONTEND · MAHASISWA · Komponen kartu lowongan (dipakai ulang) ====
$sudahDisimpan = $l['sudah_disimpan'] ?? ($sudahDisimpan ?? false);
$tutup = $l['status'] !== 'aktif';
$sisa = sisaHari($l['batas_lamaran']);
$pamfletUrl = !empty($l['pamflet']) ? url('unduh.php?tipe=pamflet&file=' . urlencode($l['pamflet'])) : url('assets/img/hero-1.jpg');
?>
<?= hpKartuLowongan($l, (bool) $sudahDisimpan) ?>
<article class="job hanya-laptop">
  <a href="<?= url('lowongan/detail/' . $l['id']) ?>"><?php if (pamfletPdf($l['pamflet'] ?? null)): ?><span class="thumb pamflet-ikon-pdf">PDF</span><?php else: ?><img class="thumb" src="<?= e($pamfletUrl) ?>" alt="Pamflet <?= e($l['posisi']) ?>" loading="lazy"><?php endif; ?></a>
  <div>
    <h3><a href="<?= url('lowongan/detail/' . $l['id']) ?>"><?= e($l['posisi']) ?></a></h3>
    <div class="person gap-6"><span class="muted"><?= e($l['nama_perusahaan']) ?></span> <span class="d-inline-flex text-ok" title="Mitra terverifikasi"><span data-ic="shield"></span></span></div>
    <div class="meta">
      <span><span data-ic="pin"></span><?= e($l['lokasi']) ?></span>
      <span><span data-ic="briefcase"></span><?= e(ucwords(str_replace('_', ' ', $l['jenis_pekerjaan']))) ?></span>
      <span><span data-ic="calendar"></span>Batas <?= tanggalIndo($l['batas_lamaran']) ?></span>
    </div>
    <div class="d-flex flex-wrap gap-6 mt-8">
      <span class="tag"><?= e($l['nama_bidang'] ?? '') ?></span>
      <?php if ($sisa <= 3 && !$tutup): ?><span class="tag tag-urgent">Segera ditutup</span><?php endif; ?>
      <?php if ($tutup): ?><?= badgeHtml(labelStatusLowongan($l['status'])) ?><?php endif; ?>
    </div>
  </div>
  <div class="job-actions">
    <form class="d-inline" method="post" action="<?= url('lowongan/simpan/' . $l['id']) ?>">
      <?= csrfField() ?>
      <input type="hidden" name="kembali" value="<?= e(Auth::pathSaatIni()) ?>">
      <button class="btn btn-sm btn-outline save-btn <?= $sudahDisimpan ? 'saved' : '' ?>" type="submit"><span data-ic="bookmark"></span><?= $sudahDisimpan ? 'Disimpan' : 'Simpan' ?></button>
    </form>
    <a class="btn btn-sm btn-primary" href="<?= url('lowongan/detail/' . $l['id']) ?>">Lihat detail</a>
  </div>
</article>
