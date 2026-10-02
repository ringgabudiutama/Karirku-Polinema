<?php
/**
 * View: admin/kelola-pengguna
 * Dipanggil oleh: AdminController::kelolaPengguna()
 * Variabel: $mahasiswa, $perusahaan, $jurusan, $filter
 */
$page_title = 'Kelola Pengguna';
$active_menu = 'pengguna';
require __DIR__ . '/../layouts/app-header.php';
$tabAktif = trim($_GET['tab'] ?? 'm');
?>
<section class="view active">
  <div class="page-head"><div><h1>Kelola pengguna</h1><p>Nonaktifkan akun yang melanggar ketentuan. Pengguna diberi tahu lewat email.</p></div></div>
  <div class="panel">
    <div class="tabs" data-tabs="uPanes">
      <button class="<?= $tabAktif === 'm' ? 'active' : '' ?>" data-tab="m">Mahasiswa dan alumni</button>
      <button class="<?= $tabAktif === 'p' ? 'active' : '' ?>" data-tab="p">Perusahaan</button>
    </div>

    <form class="filters" method="get" action="<?= url('admin/kelola-pengguna') ?>">
      <input class="input grow" name="q" type="search" placeholder="Cari nama, NIM, atau email" value="<?= e($filter['keyword']) ?>">
      <select class="input jur-filter" name="jurusan_id" onchange="this.form.submit()">
        <option value="">Semua jurusan</option>
        <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="status_akun" onchange="this.form.submit()">
        <option value="">Semua status</option>
        <option value="aktif" <?= $filter['status_akun'] === 'aktif' ? 'selected' : '' ?>>Aktif</option>
        <option value="nonaktif" <?= $filter['status_akun'] === 'nonaktif' ? 'selected' : '' ?>>Dinonaktifkan</option>
      </select>
      <noscript><button class="btn btn-outline" type="submit">Terapkan</button></noscript>
    </form>

    <div id="uPanes">
      <div class="table-wrap" data-pane="m" <?= $tabAktif !== 'm' ? 'hidden' : '' ?>>
        <table class="t">
          <tr><th>Nama</th><th>NIM</th><th>Jurusan</th><th>Status</th><th></th></tr>
          <?php if (empty($mahasiswa)): ?><tr><td colspan="5" class="muted" style="text-align:center;padding:30px">Tidak ada data.</td></tr><?php endif; ?>
          <?php foreach ($mahasiswa as $m): ?>
            <tr>
              <td>
                <a href="<?= url('admin/profil-mahasiswa/' . $m['id']) ?>" title="Lihat profil karier lengkap">
                  <b><?= e($m['nama']) ?></b>
                </a>
                <br><small class="muted"><?= e($m['email']) ?></small>
              </td>
              <td><?= e($m['nim']) ?></td>
              <td><?= e($m['nama_jurusan']) ?></td>
              <td><?= badgeHtml(labelStatusAkun($m['status_akun'])) ?></td>
              <td style="white-space:nowrap">
                <a class="btn btn-sm btn-outline" href="<?= url('admin/profil-mahasiswa/' . $m['id']) ?>">Lihat profil</a>
                <?php if ($m['status_akun'] === 'nonaktif'): ?>
                  <form method="post" action="<?= url('admin/aktifkan-pengguna/' . $m['pengguna_id']) ?>" style="display:inline"><?= csrfField() ?><button class="btn btn-sm btn-outline" type="submit">Aktifkan</button></form>
                <?php else: ?>
                  <button class="btn btn-sm btn-outline" type="button" style="color:var(--bad);border-color:var(--bad)" data-open="mSuspend<?= (int) $m['pengguna_id'] ?>">Nonaktifkan</button>
                <?php endif; ?>
              </td>
            </tr>
          <?php endforeach; ?>
        </table>
      </div>
      <div class="table-wrap" data-pane="p" <?= $tabAktif !== 'p' ? 'hidden' : '' ?>>
        <table class="t">
          <tr><th>Perusahaan</th><th>Bidang</th><th>Kota</th><th>Status</th><th></th></tr>
          <?php if (empty($perusahaan)): ?><tr><td colspan="5" class="muted" style="text-align:center;padding:30px">Tidak ada data.</td></tr><?php endif; ?>
          <?php foreach ($perusahaan as $p): ?>
            <tr>
              <td><b><?= e($p['nama_perusahaan']) ?></b><br><small class="muted"><?= e($p['email']) ?></small></td>
              <td><?= e($p['bidang_usaha']) ?></td>
              <td><?= e($p['kota']) ?></td>
              <td><?= badgeHtml(labelStatusAkun($p['status_akun'])) ?></td>
              <td>
                <?php if ($p['status_akun'] === 'nonaktif'): ?>
                  <form method="post" action="<?= url('admin/aktifkan-pengguna/' . $p['pengguna_id']) ?>" style="display:inline"><?= csrfField() ?><button class="btn btn-sm btn-outline" type="submit">Aktifkan</button></form>
                <?php else: ?>
                  <button class="btn btn-sm btn-outline" type="button" style="color:var(--bad);border-color:var(--bad)" data-open="mSuspend<?= (int) $p['pengguna_id'] ?>">Nonaktifkan</button>
                <?php endif; ?>
              </td>
            </tr>
          <?php endforeach; ?>
        </table>
      </div>
    </div>
  </div>
</section>

<?php foreach (array_merge($mahasiswa, $perusahaan) as $u): if ($u['status_akun'] === 'nonaktif') continue; ?>
<div class="modal" id="mSuspend<?= (int) $u['pengguna_id'] ?>" role="dialog" aria-modal="true">
  <div class="modal-box">
    <div class="modal-head"><h3>Nonaktifkan akun?</h3><button class="close" data-close aria-label="Tutup" data-ic="x"></button></div>
    <form method="post" action="<?= url('admin/nonaktifkan-pengguna/' . $u['pengguna_id']) ?>">
      <?= csrfField() ?>
      <div class="modal-body">
        <p>Pengguna tidak bisa masuk dan menerima email pemberitahuan.<?= isset($u['nim']) ? '' : ' Lowongan milik perusahaan ini ikut disembunyikan.' ?></p>
        <div class="field"><label>Alasan</label><textarea class="input" name="alasan" rows="3" required placeholder="Tulis alasan yang jelas"></textarea></div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Batal</button><button type="submit" class="btn btn-danger">Nonaktifkan</button></div>
    </form>
  </div>
</div>
<?php endforeach; ?>

<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
