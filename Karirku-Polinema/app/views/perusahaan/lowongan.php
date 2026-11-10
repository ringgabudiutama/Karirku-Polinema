<?php
// ===== FRONTEND · PERUSAHAAN · Lowongan saya =========================
$page_title = 'Lowongan Saya';
$active_menu = 'lowongan';
require __DIR__ . '/../layouts/app-header.php';

$grupOpsi = ['semua' => 'Semua', 'menunggu' => 'Menunggu', 'revisi' => 'Perlu revisi', 'aktif' => 'Aktif',
             'ditutup' => 'Ditutup', 'ditolak' => 'Ditolak', 'nonaktif' => 'Dinonaktifkan'];
$keteranganStatus = [
    'menunggu' => 'Menunggu persetujuan Admin Career Center. Belum tampil untuk pelamar.',
    'revisi'   => 'Admin meminta revisi. Perbaiki lalu ajukan ulang.',
    'ditolak'  => 'Ditolak final oleh Admin.',
    'aktif'    => 'Tayang untuk mahasiswa dan alumni Polinema.',
    'ditutup'  => 'Tidak menerima lamaran baru. Bisa diperpanjang.',
    'nonaktif' => 'Dinonaktifkan Admin.',
];
$besok = date('Y-m-d', strtotime('+1 day'));
$maksTanggal = date('Y-m-d', strtotime('+6 months'));
?>
<section class="view active">
  <?= kepalaKembali('perusahaan/dashboard', [['Dashboard', 'perusahaan/dashboard'], ['Lowongan saya']]) ?>
  <div class="page-head"><div><h1>Lowongan Saya</h1><p>Lowongan baru atau yang isinya diubah akan ditinjau Admin Career Center sebelum tayang.</p></div><a class="btn btn-primary" href="<?= url('lowongan/form-pasang') ?>"><span data-ic="plus"></span>Pasang lowongan</a></div>
  <div class="panel">
    <!-- ===== Tab status ===== -->
    <div class="tabs tabs-gulir">
      <?php foreach ($grupOpsi as $key => $label): if ($key !== 'semua' && empty($jumlah[$key]) && $grup !== $key) continue; ?>
        <a href="<?= url('perusahaan/lowongan?status=' . $key) ?>" class="<?= $grup === $key ? 'active' : '' ?>"><?= e($label) ?><span class="c"><?= (int) ($jumlah[$key] ?? 0) ?></span></a>
      <?php endforeach; ?>
    </div>

    <!-- ===== Daftar lowongan (kartu responsif: 1 tombol utama + menu Kelola) ===== -->
    <?php if (empty($lowongan)): ?>
      <div class="kosong-kotak mt-16"><span data-ic="briefcase"></span><p>Belum ada lowongan di kelompok ini.</p>
        <a class="btn btn-primary btn-sm" href="<?= url('lowongan/form-pasang') ?>"><span data-ic="plus"></span>Pasang lowongan</a></div>
    <?php else: ?>
    <div class="lw-list">
      <?php foreach ($lowongan as $l):
        $id = (int) $l['id'];
        $tayang = in_array($l['status'], Lowongan::STATUS_TAYANG, true);
        $bisaEdit = !in_array($l['status'], ['ditolak', 'nonaktif'], true);
        // Tombol utama dipilih sesuai status, sisanya masuk menu "Kelola".
        if ($l['status'] === 'revisi') {
            $utama = ['href' => url('lowongan/form-pasang/' . $id), 'ikon' => 'edit', 'label' => 'Perbaiki & ajukan'];
        } elseif ((int) $l['jumlah_pelamar'] > 0) {
            $utama = ['href' => url('perusahaan/pelamar?lowongan_id=' . $id), 'ikon' => 'users', 'label' => 'Lihat pelamar'];
        } elseif ($bisaEdit) {
            $utama = ['href' => url('lowongan/form-pasang/' . $id), 'ikon' => 'edit', 'label' => 'Edit'];
        } else {
            $utama = ['href' => url('lowongan/form-pasang?salin=' . $id), 'ikon' => 'copy', 'label' => 'Salin jadi baru'];
        } ?>
      <article class="lw-item" data-status="<?= e($l['status']) ?>">
        <div class="lw-media"><?= $l['pamflet'] ? pamfletHtml($l['pamflet'], 'thumb', 'Pamflet ' . $l['posisi']) : '<span class="pamflet-kosong pamflet-thumb lw-tanpa"><span data-ic="image"></span><small>Tanpa pamflet</small></span>' ?></div>
        <div class="lw-isi">
          <div class="lw-judul">
            <h3><?= e($l['posisi']) ?></h3>
            <?= statusLowonganHtml($l['status']) ?>
          </div>
          <div class="lw-meta">
            <span class="lw-chip"><span data-ic="briefcase"></span><?= e($l['nama_bidang']) ?></span>
            <span class="lw-chip"><span data-ic="building"></span><?= e(labelJenisKerja($l['jenis_pekerjaan'], $l['sistem_kerja'])) ?></span>
            <?= batasLowonganHtml($l['batas_lamaran'], $l['status']) ?>
          </div>
          <p class="lw-ket"><?= e($keteranganStatus[$l['status']] ?? '') ?></p>
          <?php if (in_array($l['status'], ['revisi', 'ditolak'], true) && $l['catatan_admin']): ?><div class="lw-catatan"><span data-ic="alert"></span><div><b>Catatan Admin:</b> <?= e($l['catatan_admin']) ?></div></div><?php endif; ?>
          <?php if ($l['status'] === 'nonaktif' && $l['alasan_nonaktif']): ?><div class="lw-catatan"><span data-ic="ban"></span><div><b>Alasan dinonaktifkan:</b> <?= e($l['alasan_nonaktif']) ?></div></div><?php endif; ?>
        </div>
        <div class="lw-angka">
          <a class="lw-pelamar" href="<?= url('perusahaan/pelamar?lowongan_id=' . $id) ?>" title="Lihat semua pelamar">
            <b><?= (int) $l['jumlah_pelamar'] ?></b><span>pelamar</span>
            <?php if ((int) $l['jumlah_baru'] > 0): ?><em><?= (int) $l['jumlah_baru'] ?> baru</em><?php endif; ?>
          </a>
          <?= kuotaLowonganHtml((int) $l['terisi'], (int) $l['kuota']) ?>
        </div>
        <div class="lw-aksi">
          <a class="btn btn-sm btn-primary" href="<?= e($utama['href']) ?>"><span data-ic="<?= $utama['ikon'] ?>"></span><?= e($utama['label']) ?></a>
          <details class="menu-aksi">
            <summary class="btn btn-sm btn-outline" aria-label="Aksi lain untuk <?= e($l['posisi']) ?>">Kelola<span data-ic="chevron"></span></summary>
            <div class="menu-aksi-isi" role="menu">
              <?php if ($tayang): ?><a role="menuitem" href="<?= url('info-loker/' . $l['kode_pratinjau']) ?>" target="_blank" rel="noopener"><span data-ic="eye"></span>Lihat seperti pelamar</a><?php endif; ?>
              <a role="menuitem" href="<?= url('perusahaan/pelamar?lowongan_id=' . $id) ?>"><span data-ic="users"></span>Kelola pelamar</a>
              <?php if ($bisaEdit): ?><a role="menuitem" href="<?= url('lowongan/form-pasang/' . $id) ?>"><span data-ic="edit"></span><?= $l['status'] === 'revisi' ? 'Perbaiki & ajukan ulang' : 'Edit lowongan' ?></a><?php endif; ?>
              <a role="menuitem" href="<?= url('lowongan/form-pasang?salin=' . $id) ?>" title="Buat lowongan baru dengan isian yang sama"><span data-ic="copy"></span>Salin jadi lowongan baru</a>
              <?php if ($tayang): ?><button role="menuitem" type="button" data-open="mPanjang<?= $id ?>"><span data-ic="refresh"></span>Perpanjang batas / kuota</button><?php endif; ?>
              <?php if ($l['status'] === 'aktif'): ?>
                <form method="post" action="<?= url('lowongan/tutup/' . $id) ?>" data-konfirmasi="Tutup lowongan &ldquo;<?= e($l['posisi']) ?>&rdquo;? Lamaran yang sudah masuk tetap bisa diproses.">
                  <?= csrfField() ?><button role="menuitem" class="bahaya" type="submit"><span data-ic="lock"></span>Tutup lowongan</button>
                </form>
              <?php endif; ?>
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

<!-- ===== Modal perpanjang (revisi D) ===== -->
<?php foreach ($lowongan as $l): if (!in_array($l['status'], Lowongan::STATUS_TAYANG, true)) continue;
    $kuotaMin = (int) $l['terisi'] + 1;
    $kuotaSaran = max((int) $l['kuota'], $kuotaMin);
    // Auto input: batas lama + 30 hari (atau hari ini + 30 bila sudah lewat), tidak lebih dari 6 bulan.
    $tglSaran = min($maksTanggal, max($besok, date('Y-m-d', strtotime('+30 days')), date('Y-m-d', strtotime($l['batas_lamaran'] . ' +30 days')))); ?>
<div class="modal" id="mPanjang<?= (int) $l['id'] ?>" role="dialog" aria-modal="true" aria-labelledby="jPanjang<?= (int) $l['id'] ?>">
  <div class="modal-box">
    <div class="modal-head"><h3 id="jPanjang<?= (int) $l['id'] ?>">Perpanjang lowongan</h3><button class="close" data-close aria-label="Tutup" data-ic="x"></button></div>
    <form method="post" action="<?= url('lowongan/perpanjang/' . $l['id']) ?>">
      <?= csrfField() ?>
      <div class="modal-body">
        <p class="m-0 mb-12"><b><?= e($l['posisi']) ?></b> akan aktif kembali untuk pelamar baru. Isi lowongan tidak berubah, jadi tidak perlu persetujuan ulang. Admin akan menerima pemberitahuan.</p>
        <div class="kotak-data fs-90">
          Batas saat ini: <b><?= tanggalIndo($l['batas_lamaran']) ?></b> &middot; Diterima: <b><?= (int) $l['terisi'] ?>/<?= (int) $l['kuota'] ?></b>
          <?php if ((int) $l['terisi'] >= (int) $l['kuota']): ?><br><span class="text-bad">Kuota sudah penuh, jadi kuota baru harus dinaikkan agar ada pelamar yang bisa diterima.</span><?php endif; ?>
        </div>
        <div class="row2">
          <div class="field"><label for="pb<?= (int) $l['id'] ?>">Batas lamaran baru</label>
            <input class="input" id="pb<?= (int) $l['id'] ?>" type="date" name="batas_lamaran" min="<?= e(date('Y-m-d')) ?>" max="<?= e($maksTanggal) ?>" value="<?= e($tglSaran) ?>" required>
            <div class="hint">Paling lambat 6 bulan dari hari ini.</div></div>
          <div class="field"><label for="pk<?= (int) $l['id'] ?>">Kuota diterima</label>
            <input class="input" id="pk<?= (int) $l['id'] ?>" type="number" name="kuota" min="<?= $kuotaMin ?>" max="1000" value="<?= $kuotaSaran ?>" required>
            <div class="hint">Minimal <?= $kuotaMin ?> (sudah diterima <?= (int) $l['terisi'] ?>).</div></div>
        </div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Batal</button><button type="submit" class="btn btn-primary" data-proses="Menyimpan...">Perpanjang</button></div>
    </form>
  </div>
</div>
<?php endforeach; ?>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
