<?php
/**
 * View: mahasiswa/lowongan-detail
 * Dipanggil oleh: LowonganController::detail($id)
 * Variabel: $lowongan, $jurusanSasaran, $sudahDisimpan, $sudahMelamar, $profilLengkap
 */
$page_title = 'Detail lowongan';
$active_menu = 'lowongan';
require __DIR__ . '/../layouts/app-header.php';

$tutup = $lowongan['status'] !== 'aktif';
$pamfletUrl = url('unduh.php?tipe=pamflet&file=' . urlencode($lowongan['pamflet']));
$logoUrl = !empty($lowongan['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($lowongan['logo'])) : null;
?>
<section class="view active">
  <div class="crumb"><a href="<?= url('lowongan/daftar') ?>">Lowongan</a> <span>/</span> <span><?= e($lowongan['posisi']) ?></span></div>

  <div class="detail">
    <div>
      <div class="poster">
        <img src="<?= e($pamfletUrl) ?>" alt="Pamflet <?= e($lowongan['posisi']) ?>">
        <div class="actions"><a class="btn btn-outline btn-sm" style="flex:1" href="<?= e($pamfletUrl) ?>" download><span data-ic="download"></span>Unduh pamflet</a></div>
      </div>
    </div>
    <div>
      <div class="panel">
        <div class="person" style="margin-bottom:12px">
          <?php if ($logoUrl): ?><img class="avatar" src="<?= e($logoUrl) ?>" alt=""><?php else: ?>
            <span class="avatar" style="display:inline-flex;align-items:center;justify-content:center;background:var(--blue-soft);color:var(--navy);font-weight:700"><?= e(inisial($lowongan['nama_perusahaan'])) ?></span>
          <?php endif; ?>
          <div><b><?= e($lowongan['nama_perusahaan']) ?></b><small style="color:var(--ok)">Mitra terverifikasi Career Center</small></div>
        </div>
        <h1 style="font-size:1.9rem;margin-bottom:4px"><?= e($lowongan['posisi']) ?></h1>
        <div class="meta">
          <span><span data-ic="pin"></span><?= e($lowongan['lokasi']) ?></span>
          <span><span data-ic="briefcase"></span><?= e(ucwords(str_replace('_', ' ', $lowongan['jenis_pekerjaan']))) ?></span>
          <span><span data-ic="calendar"></span>Batas <?= tanggalIndo($lowongan['batas_lamaran']) ?></span>
        </div>
        <div class="kv">
          <div><small>Sistem kerja</small><b><?= e(strtoupper($lowongan['sistem_kerja'])) ?></b></div>
          <div><small>Gaji</small><b><?= $lowongan['gaji'] ? e($lowongan['gaji']) : 'Dirundingkan' ?></b></div>
          <div><small>Kuota</small><b><?= (int) $lowongan['kuota'] ?> orang, sisa <?= max(0, (int) $lowongan['kuota'] - (int) $lowongan['terisi']) ?></b></div>
          <div><small>Jurusan sasaran</small><b><?= e(implode(', ', array_column($jurusanSasaran, 'nama')) ?: 'Semua jurusan') ?></b></div>
        </div>

        <div style="display:flex;gap:10px;flex-wrap:wrap;align-items:center">
          <?php if ($sudahMelamar): ?>
            <div class="alert alert-info" style="margin:0"><span data-ic="checkc"></span><span>Kamu sudah melamar lowongan ini. <a href="<?= url('lamaran/lamaran-saya') ?>">Lihat lamaran</a></span></div>
          <?php elseif ($tutup): ?>
            <div class="alert alert-warn" style="margin:0"><span data-ic="info"></span><span>Lowongan ini sudah ditutup<?= $lowongan['status'] === 'ditutup' && (int) $lowongan['terisi'] >= (int) $lowongan['kuota'] ? ' karena kuota terpenuhi.' : '.' ?></span></div>
          <?php elseif (!$profilLengkap): ?>
            <div class="alert alert-warn" style="margin:0"><span data-ic="info"></span><span>Lengkapi KTM/ijazah dan CV di <a href="<?= url('mahasiswa/profil') ?>">Profil Karier</a> sebelum bisa melamar.</span></div>
          <?php else: ?>
            <a class="btn btn-primary" style="padding:12px 28px" href="<?= url('lamaran/kirim/' . $lowongan['id']) ?>">Lamar sekarang</a>
          <?php endif; ?>

          <form method="post" action="<?= url('lowongan/simpan/' . $lowongan['id']) ?>" style="display:inline">
            <?= csrfField() ?>
            <input type="hidden" name="kembali" value="<?= e($_SERVER['REQUEST_URI'] ?? '') ?>">
            <button class="btn btn-outline save-btn <?= $sudahDisimpan ? 'saved' : '' ?>" type="submit"><span data-ic="bookmark"></span><?= $sudahDisimpan ? 'Disimpan' : 'Simpan' ?></button>
          </form>
        </div>
      </div>

      <div class="panel">
        <h3>Deskripsi pekerjaan</h3>
        <p><?= nl2br(e($lowongan['deskripsi'])) ?></p>
        <h3>Kualifikasi</h3>
        <p><?= nl2br(e($lowongan['kualifikasi'])) ?></p>
        <?php if (!empty($lowongan['skill_dibutuhkan'])): ?>
          <h3>Skill yang dibutuhkan</h3>
          <p><?= e($lowongan['skill_dibutuhkan']) ?></p>
        <?php endif; ?>
        <h3>Tentang perusahaan</h3>
        <p class="muted"><?= e($lowongan['deskripsi_perusahaan'] ?: ($lowongan['nama_perusahaan'] . ' berkantor di ' . $lowongan['kota_perusahaan'] . ' dan telah bermitra dengan Career Center Politeknik Negeri Malang.')) ?></p>
      </div>
    </div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
