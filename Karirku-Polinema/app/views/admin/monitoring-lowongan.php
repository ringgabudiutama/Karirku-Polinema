<?php
// ===== FRONTEND · ADMIN · Monitoring lowongan ========================
$page_title = 'Monitoring Lowongan';
$active_menu = 'monitoring';
require __DIR__ . '/../layouts/app-header.php';
$statusOpsi = ['' => 'Semua status', 'menunggu' => 'Menunggu persetujuan', 'revisi' => 'Perlu revisi', 'aktif' => 'Aktif',
               'ditutup' => 'Ditutup', 'nonaktif' => 'Dinonaktifkan', 'ditolak' => 'Ditolak'];
$adaFilter = array_filter($filter, fn($v) => $v !== '');
?>
<section class="view active">
  <?= kepalaKembali('admin/dashboard', [['Dashboard', 'admin/dashboard'], ['Monitoring lowongan']]) ?>
  <div class="page-head"><div><h1>Monitoring lowongan</h1><p>Semua lowongan dari seluruh perusahaan mitra.</p></div>
    <a class="btn btn-outline" href="<?= url('admin/unduh-rekap-lowongan?' . http_build_query(array_filter($filter))) ?>" target="_blank" rel="noopener"><span data-ic="download"></span>Unduh laporan PDF</a>
  </div>
  <!-- ===== Ringkasan status (klik untuk memfilter) ===== -->
  <div class="lw-ringkas">
    <?php foreach (['menunggu' => ['hourglass', 'Menunggu'], 'aktif' => ['checkc', 'Aktif tayang'], 'revisi' => ['edit', 'Perlu revisi'], 'ditutup' => ['lock', 'Ditutup'], 'nonaktif' => ['ban', 'Dinonaktifkan'], 'ditolak' => ['x', 'Ditolak']] as $st => [$ik, $lbl]): ?>
      <a class="lw-ringkas-item s-<?= $st ?><?= $filter['status'] === $st ? ' aktif' : '' ?>" href="<?= url('admin/monitoring-lowongan?' . http_build_query(array_filter(['status' => $st] + $filter))) ?>">
        <span class="ik" data-ic="<?= $ik ?>"></span><span><b><?= (int) ($jumlahStatus[$st] ?? 0) ?></b><small><?= e($lbl) ?></small></span>
      </a>
    <?php endforeach; ?>
  </div>
  <div class="panel">
    <!-- ===== Tab status ===== -->
    <div class="tabs tabs-gulir">
      <?php foreach ($statusOpsi as $k => $v): if ($k !== '' && empty($jumlahStatus[$k]) && $filter['status'] !== $k) continue; ?>
        <a class="<?= $filter['status'] === $k ? 'active' : '' ?>" href="<?= url('admin/monitoring-lowongan?' . http_build_query(array_filter(['status' => $k] + $filter))) ?>"><?= e($k === '' ? 'Semua' : $v) ?><span class="c"><?= (int) ($jumlahStatus[$k] ?? 0) ?></span></a>
      <?php endforeach; ?>
    </div>
    <!-- ===== Filter (bug #20: pencarian di server, ikut pagination & PDF) ===== -->
    <form class="filters" method="get" action="<?= url('admin/monitoring-lowongan') ?>">
      <?php if ($filter['status'] !== ''): ?><input type="hidden" name="status" value="<?= e($filter['status']) ?>"><?php endif; ?>
      <input class="input grow" type="search" name="q" value="<?= e($filter['q']) ?>" placeholder="Cari posisi atau perusahaan" aria-label="Cari lowongan">
      <select class="input jur-filter" name="jurusan_id" aria-label="Jurusan">
        <option value="">Semua jurusan</option>
        <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="bidang_id" aria-label="Bidang">
        <option value="">Semua bidang</option>
        <?php foreach ($bidang as $b): ?><option value="<?= (int) $b['id'] ?>" <?= (string) $filter['bidang_id'] === (string) $b['id'] ? 'selected' : '' ?>><?= e($b['nama']) ?></option><?php endforeach; ?>
      </select>
      <button class="btn btn-primary" type="submit"><span data-ic="search"></span>Terapkan</button>
      <?php if ($adaFilter): ?><a class="btn btn-link" href="<?= url('admin/monitoring-lowongan') ?>">Hapus filter</a><?php endif; ?>
    </form>

    <!-- ===== Daftar lowongan ===== -->
    <?php if (empty($lowongan)): ?>
      <div class="kosong-kotak mt-16"><span data-ic="search"></span><p>Tidak ada lowongan dengan filter ini.</p></div>
    <?php else: ?>
    <div class="lw-list">
      <?php foreach ($lowongan as $l): $id = (int) $l['id']; $tayang = in_array($l['status'], Lowongan::STATUS_TAYANG, true); ?>
      <article class="lw-item" data-status="<?= e($l['status']) ?>">
        <div class="lw-media"><?= $l['pamflet'] ? pamfletHtml($l['pamflet'], 'thumb', 'Pamflet ' . $l['posisi']) : '<span class="pamflet-kosong pamflet-thumb lw-tanpa"><span data-ic="image"></span><small>Tanpa pamflet</small></span>' ?></div>
        <div class="lw-isi">
          <div class="lw-judul">
            <h3><a href="<?= url('admin/detail-lowongan/' . $id) ?>"><?= e($l['posisi']) ?></a></h3>
            <?= statusLowonganHtml($l['status']) ?>
          </div>
          <a class="lw-prsh" href="<?= url('admin/profil-perusahaan/' . $l['perusahaan_id']) ?>"><?= logoPerusahaanHtml($l['logo'] ?? null, $l['nama_perusahaan']) ?><span><?= e($l['nama_perusahaan']) ?><?php if (!empty($l['kota_perusahaan'])): ?> <small>&middot; <?= e($l['kota_perusahaan']) ?></small><?php endif; ?></span></a>
          <div class="lw-meta">
            <span class="lw-chip"><span data-ic="briefcase"></span><?= e($l['nama_bidang']) ?></span>
            <span class="lw-chip"><span data-ic="building"></span><?= e(labelJenisKerja($l['jenis_pekerjaan'], $l['sistem_kerja'])) ?></span>
            <?= batasLowonganHtml($l['batas_lamaran'], $l['status']) ?>
            <span class="lw-chip" title="Tanggal diajukan"><span data-ic="clock"></span>Diajukan <?= tanggalIndo(substr((string) $l['dibuat_pada'], 0, 10)) ?></span>
          </div>
          <?php if ($l['status'] === 'nonaktif' && $l['alasan_nonaktif']): ?><div class="lw-catatan"><span data-ic="ban"></span><div><b>Alasan:</b> <?= e(ringkas($l['alasan_nonaktif'], 160)) ?></div></div><?php endif; ?>
          <?php if (in_array($l['status'], ['revisi', 'ditolak'], true) && !empty($l['catatan_admin'])): ?><div class="lw-catatan"><span data-ic="alert"></span><div><b>Catatan ke perusahaan:</b> <?= e(ringkas($l['catatan_admin'], 160)) ?></div></div><?php endif; ?>
        </div>
        <div class="lw-angka">
          <div class="lw-pelamar"><b><?= (int) $l['jumlah_pelamar'] ?></b><span>pelamar</span></div>
          <?= kuotaLowonganHtml((int) $l['terisi'], (int) $l['kuota']) ?>
        </div>
        <div class="lw-aksi">
          <a class="btn btn-sm <?= $l['status'] === 'menunggu' ? 'btn-primary' : 'btn-outline' ?>" href="<?= url('admin/detail-lowongan/' . $id) ?>"><span data-ic="<?= $l['status'] === 'menunggu' ? 'check' : 'eye' ?>"></span><?= $l['status'] === 'menunggu' ? 'Tinjau' : 'Detail' ?></a>
          <details class="menu-aksi">
            <summary class="btn btn-sm btn-outline" aria-label="Aksi lain untuk <?= e($l['posisi']) ?>">Kelola<span data-ic="chevron"></span></summary>
            <div class="menu-aksi-isi" role="menu">
              <a role="menuitem" href="<?= url('admin/detail-lowongan/' . $id) ?>"><span data-ic="file"></span>Detail &amp; riwayat</a>
              <a role="menuitem" href="<?= url('admin/profil-perusahaan/' . $l['perusahaan_id']) ?>"><span data-ic="building"></span>Profil perusahaan</a>
              <?php if ($tayang && !empty($l['kode_pratinjau'])): ?><a role="menuitem" href="<?= url('info-loker/' . $l['kode_pratinjau']) ?>" target="_blank" rel="noopener"><span data-ic="external"></span>Lihat halaman publik</a><?php endif; ?>
              <?php if ($tayang): ?><button role="menuitem" class="bahaya" type="button" data-open="mNon<?= $id ?>"><span data-ic="ban"></span>Nonaktifkan</button><?php endif; ?>
            </div>
          </details>
        </div>
      </article>
      <?php endforeach; ?>
    </div>
    <?php endif; ?>
    <?= paginasiHtml($paginasi, 'lowongan') ?>
  </div>
</section>

<!-- ===== Modal nonaktifkan ===== -->
<?php foreach ($lowongan as $l): if (!in_array($l['status'], Lowongan::STATUS_TAYANG, true)) continue; ?>
<div class="modal" id="mNon<?= (int) $l['id'] ?>" role="dialog" aria-modal="true" aria-labelledby="jNon<?= (int) $l['id'] ?>">
  <div class="modal-box">
    <div class="modal-head"><h3 id="jNon<?= (int) $l['id'] ?>">Nonaktifkan lowongan?</h3><button class="close" data-close aria-label="Tutup" data-ic="x"></button></div>
    <form method="post" action="<?= url('admin/nonaktifkan-lowongan/' . $l['id']) ?>">
      <?= csrfField() ?><input type="hidden" name="kembali" value="<?= e(Auth::pathSaatIni()) ?>">
      <div class="modal-body">
        <p><b><?= e($l['posisi']) ?></b> di <?= e($l['nama_perusahaan']) ?> akan disembunyikan dari pencarian mahasiswa dan alumni. Perusahaan menerima notifikasi dan email beserta alasannya.</p>
        <div class="field"><label for="alasanNon<?= (int) $l['id'] ?>">Alasan</label><?= chipsAlasan('daftar_alasan_lowongan', 'alasanNon' . (int) $l['id']) ?><textarea class="input" id="alasanNon<?= (int) $l['id'] ?>" name="alasan" rows="3" minlength="10" maxlength="500" required placeholder="Tulis alasan yang jelas (min. 10 karakter)"></textarea></div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Batal</button><button type="submit" class="btn btn-danger" data-proses="Memproses...">Nonaktifkan</button></div>
    </form>
  </div>
</div>
<?php endforeach; ?>

<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
