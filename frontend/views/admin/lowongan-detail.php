<?php
// ===== FRONTEND · ADMIN · Detail lowongan & keputusan (revisi M) ======
$page_title = 'Tinjau Lowongan';
$active_menu = $lowongan['status'] === 'menunggu' || in_array($lowongan['status'], ['revisi', 'ditolak'], true) ? 'persetujuan-lowongan' : 'monitoring';
require __DIR__ . '/../layouts/app-header.php';

$jenisLabel = ['full_time' => 'Penuh waktu', 'part_time' => 'Paruh waktu', 'kontrak' => 'Kontrak', 'magang' => 'Magang', 'freelance' => 'Freelance'];
$sistemLabel = ['wfo' => 'Di kantor (WFO)', 'hybrid' => 'Hybrid', 'wfh' => 'Jarak jauh (WFH)'];
$induk = $active_menu === 'monitoring' ? 'admin/monitoring-lowongan' : 'admin/persetujuan-lowongan?status=' . ($lowongan['status'] === 'menunggu' ? 'menunggu' : $lowongan['status']);
$lewat = strtotime($lowongan['batas_lamaran']) < strtotime('today');
?>
<section class="view active">
  <div class="kepala-halaman">
    <div class="crumb"><a href="<?= url($induk) ?>"><?= $active_menu === 'monitoring' ? 'Monitoring Lowongan' : 'Persetujuan Lowongan' ?></a> <span>/</span> <span><?= e($lowongan['posisi']) ?></span></div>
    <?= tombolKembali($induk) ?>
  </div>

  <div class="grid g-side items-start">
    <div>
      <div class="panel">
        <div class="d-flex justify-between items-start flex-wrap gap-10">
          <div><h1 class="fs-160 m-0"><?= e($lowongan['posisi']) ?></h1>
            <p class="muted m-0 mt-2"><a href="<?= url('admin/profil-perusahaan/' . $lowongan['perusahaan_id']) ?>"><?= e($lowongan['nama_perusahaan']) ?></a> &middot; <?= e($lowongan['nama_bidang']) ?></p></div>
          <?= badgeHtml(labelStatusLowongan($lowongan['status'])) ?>
        </div>
        <?php if ($lowongan['status_akun_perusahaan'] !== 'aktif'): ?>
          <div class="alert alert-warn mt-12"><span data-ic="alert"></span><span>Akun perusahaan ini berstatus <b><?= e(labelStatusAkun($lowongan['status_akun_perusahaan'])[0]) ?></b>, jadi lowongannya tidak tampil untuk pelamar walaupun disetujui.</span></div>
        <?php endif; ?>
        <dl class="dl mt-12">
          <dt>Jenis pekerjaan</dt><dd><?= e($jenisLabel[$lowongan['jenis_pekerjaan']] ?? $lowongan['jenis_pekerjaan']) ?></dd>
          <dt>Sistem kerja</dt><dd><?= e($sistemLabel[$lowongan['sistem_kerja']] ?? $lowongan['sistem_kerja']) ?></dd>
          <dt>Lokasi</dt><dd><?= e($lowongan['lokasi']) ?></dd>
          <dt>Gaji</dt><dd><?= e($lowongan['gaji'] ?: 'Tidak dicantumkan') ?></dd>
          <dt>Kuota</dt><dd><?= (int) $lowongan['kuota'] ?> orang (diterima <?= (int) $lowongan['terisi'] ?>)</dd>
          <dt>Batas lamaran</dt><dd><?= tanggalIndo($lowongan['batas_lamaran']) ?><?= $lewat ? ' <span class="pill p-ditolak">sudah lewat</span>' : '' ?></dd>
          <dt>Jurusan sasaran</dt><dd><?= e(implode(', ', array_column($jurusanSasaran, 'nama')) ?: '-') ?></dd>
          <dt>Skill</dt><dd><?= e($lowongan['skill_dibutuhkan'] ?: '-') ?></dd>
          <dt>Pelamar</dt><dd><?= (int) $lowongan['jumlah_pelamar'] ?></dd>
        </dl>
      </div>
      <div class="panel"><h3>Deskripsi pekerjaan</h3><p><?= nl2br(e($lowongan['deskripsi'])) ?></p>
        <h3>Kualifikasi</h3><p class="m-0"><?= nl2br(e($lowongan['kualifikasi'])) ?></p></div>
      <div class="panel"><h3>Pamflet</h3><?= pamfletHtml($lowongan['pamflet'], 'besar', 'Pamflet ' . $lowongan['posisi']) ?></div>
    </div>

    <div class="sticky">
      <div class="panel">
        <h3>Keputusan</h3>
        <?php if ($lowongan['status'] === 'menunggu'): ?>
          <form method="post" action="<?= url('admin/putuskan-lowongan/' . $lowongan['id']) ?>" data-jaga>
            <?= csrfField() ?>
            <?php if ($lewat): ?><div class="alert alert-warn"><span data-ic="info"></span><span>Batas lamaran sudah lewat. Bila disetujui, lowongan langsung berstatus Ditutup; perusahaan bisa memperpanjangnya.</span></div><?php endif; ?>
            <div class="field"><label for="alasanLowongan">Alasan / catatan <span class="muted">(wajib untuk Minta Revisi dan Tolak, min. 10 karakter)</span></label>
              <?= chipsAlasan('daftar_alasan_lowongan', 'alasanLowongan') ?>
              <textarea class="input" id="alasanLowongan" name="alasan" rows="4" maxlength="500" placeholder="Jelaskan bagian yang perlu diperbaiki atau alasan penolakan"><?= e((string) old('alasan', '')) ?></textarea></div>
            <div class="d-grid gap-8">
              <button class="btn btn-ok" type="submit" name="keputusan" value="disetujui" data-proses="Menyimpan..." data-konfirmasi="Setujui dan tayangkan lowongan ini?">Setujui &amp; tayangkan</button>
              <button class="btn btn-warn" type="submit" name="keputusan" value="revisi" data-wajib-alasan="alasanLowongan" data-proses="Menyimpan...">Minta revisi</button>
              <button class="btn btn-outline btn-outline-bad" type="submit" name="keputusan" value="ditolak" data-wajib-alasan="alasanLowongan" data-proses="Menyimpan..." data-konfirmasi="Tolak lowongan ini secara final? Perusahaan tidak bisa mengajukan ulang lowongan ini.">Tolak final</button>
            </div>
            <p class="hint mt-8"><b>Minta revisi</b>: perusahaan memperbaiki lalu mengajukan ulang. <b>Tolak final</b>: lowongan tidak bisa diajukan ulang.</p>
          </form>
        <?php else: ?>
          <div class="alert alert-info"><span data-ic="info"></span><span>Lowongan berstatus <b><?= e(labelStatusLowongan($lowongan['status'])[0]) ?></b>.
            <?= $lowongan['status'] === 'revisi' ? 'Menunggu perusahaan memperbaiki dan mengajukan ulang.' : '' ?>
            <?= in_array($lowongan['status'], Lowongan::STATUS_TAYANG, true) ? 'Untuk menonaktifkan, gunakan tombol di bawah atau menu Monitoring Lowongan.' : '' ?></span></div>
          <?php if ($lowongan['catatan_admin']): ?><p class="fs-90"><b>Catatan Admin:</b> <?= nl2br(e($lowongan['catatan_admin'])) ?></p><?php endif; ?>
          <?php if (in_array($lowongan['status'], Lowongan::STATUS_TAYANG, true)): ?>
            <a class="btn btn-outline w-100 mb-8" href="<?= url('info-loker/' . $lowongan['kode_pratinjau']) ?>" target="_blank" rel="noopener">Lihat halaman info loker</a>
            <button class="btn btn-outline btn-outline-bad w-100" type="button" data-open="mNonDetail">Nonaktifkan lowongan</button>
          <?php endif; ?>
        <?php endif; ?>
      </div>
      <div class="panel"><h3>Riwayat status</h3><?= riwayatHtml($riwayat) ?></div>
    </div>
  </div>
</section>

<?php if (in_array($lowongan['status'], Lowongan::STATUS_TAYANG, true)): ?>
<div class="modal" id="mNonDetail" role="dialog" aria-modal="true" aria-labelledby="jNonDetail">
  <div class="modal-box">
    <div class="modal-head"><h3 id="jNonDetail">Nonaktifkan lowongan?</h3><button class="close" data-close aria-label="Tutup" data-ic="x"></button></div>
    <form method="post" action="<?= url('admin/nonaktifkan-lowongan/' . $lowongan['id']) ?>">
      <?= csrfField() ?><input type="hidden" name="kembali" value="admin/detail-lowongan/<?= (int) $lowongan['id'] ?>">
      <div class="modal-body">
        <p><b><?= e($lowongan['posisi']) ?></b> akan disembunyikan dari pelamar. Perusahaan menerima notifikasi dan email beserta alasannya.</p>
        <div class="field"><label for="alasanNon">Alasan</label><?= chipsAlasan('daftar_alasan_lowongan', 'alasanNon') ?><textarea class="input" id="alasanNon" name="alasan" rows="3" minlength="10" maxlength="500" required></textarea></div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Batal</button><button type="submit" class="btn btn-danger" data-proses="Memproses...">Nonaktifkan</button></div>
    </form>
  </div>
</div>
<?php endif; ?>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
