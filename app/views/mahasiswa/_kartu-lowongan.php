<?php
/**
 * Partial: kartu lowongan. Include dari dalam foreach, dengan $l (baris
 * lowongan + nama_perusahaan + logo) sudah di-set. $sudahDisimpan opsional.
 */
$sudahDisimpan = $l['sudah_disimpan'] ?? ($sudahDisimpan ?? false);
$tutup = $l['status'] !== 'aktif';
$sisa = sisaHari($l['batas_lamaran']);
$pamfletUrl = !empty($l['pamflet']) ? url('unduh.php?tipe=pamflet&file=' . urlencode($l['pamflet'])) : url('assets/img/hero-1.jpg');
?>
<article class="job">
  <a href="<?= url('lowongan/detail/' . $l['id']) ?>"><img class="thumb" src="<?= e($pamfletUrl) ?>" alt="Pamflet <?= e($l['posisi']) ?>"></a>
  <div>
    <h3><a href="<?= url('lowongan/detail/' . $l['id']) ?>"><?= e($l['posisi']) ?></a></h3>
    <div class="person" style="gap:6px"><span class="muted"><?= e($l['nama_perusahaan']) ?></span> <span title="Mitra terverifikasi" style="color:var(--ok);display:inline-flex"><span data-ic="shield"></span></span></div>
    <div class="meta">
      <span><span data-ic="pin"></span><?= e($l['lokasi']) ?></span>
      <span><span data-ic="briefcase"></span><?= e(ucwords(str_replace('_', ' ', $l['jenis_pekerjaan']))) ?></span>
      <span><span data-ic="calendar"></span>Batas <?= tanggalIndo($l['batas_lamaran']) ?></span>
    </div>
    <div style="margin-top:8px;display:flex;gap:6px;flex-wrap:wrap">
      <span class="tag"><?= e($l['nama_bidang'] ?? '') ?></span>
      <?php if ($sisa <= 3 && !$tutup): ?><span class="tag tag-urgent">Segera ditutup</span><?php endif; ?>
      <?php if ($tutup): ?><?= badgeHtml(labelStatusLowongan($l['status'])) ?><?php endif; ?>
    </div>
  </div>
  <div class="job-actions">
    <form method="post" action="<?= url('lowongan/simpan/' . $l['id']) ?>" style="display:inline">
      <?= csrfField() ?>
      <input type="hidden" name="kembali" value="<?= e($_SERVER['REQUEST_URI'] ?? '') ?>">
      <button class="btn btn-sm btn-outline save-btn <?= $sudahDisimpan ? 'saved' : '' ?>" type="submit"><span data-ic="bookmark"></span><?= $sudahDisimpan ? 'Disimpan' : 'Simpan' ?></button>
    </form>
    <a class="btn btn-sm btn-primary" href="<?= url('lowongan/detail/' . $l['id']) ?>">Lihat detail</a>
  </div>
</article>
