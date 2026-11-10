<?php
// ===== FRONTEND · ADMIN · Kelola pengguna ============================
$page_title = 'Kelola Pengguna';
$active_menu = 'pengguna';
require __DIR__ . '/../layouts/app-header.php';
$kembali = Auth::pathSaatIni();
$adaFilter = array_filter($filter, fn($v) => $v !== '');

/** Tombol aksi akun sesuai status (bug #9: Aktifkan hanya untuk akun nonaktif). */
$tombolAksi = function (array $u) {
    $id = (int) $u['pengguna_id'];
    $html = '';
    if ($u['status_akun'] === 'nonaktif') {
        $html .= '<form class="d-inline" method="post" action="' . url('admin/aktifkan-pengguna/' . $id) . '" data-konfirmasi="Aktifkan kembali akun ini?">'
            . csrfField() . '<input type="hidden" name="kembali" value="' . e(Auth::pathSaatIni()) . '"><button class="btn btn-sm btn-outline" type="submit" data-proses="...">Aktifkan</button></form>';
    } elseif ($u['status_akun'] === 'aktif') {
        $html .= '<button class="btn btn-sm btn-outline btn-outline-bad" type="button" data-open="mSuspend' . $id . '">Nonaktifkan</button>';
    } else {
        $html .= '<a class="btn btn-sm btn-outline" href="' . url('admin/detail-pendaftar/' . $id) . '">Periksa pendaftaran</a>';
    }
    $html .= '<button class="btn btn-sm btn-link" type="button" data-open="mReset' . $id . '">Reset sandi</button>';
    return $html;
};
$tautanTab = fn($t) => url('admin/kelola-pengguna?' . http_build_query(array_filter(['tab' => $t, 'q' => $filter['keyword'], 'status_akun' => $filter['status_akun']])));
?>
<section class="view active">
  <?= kepalaKembali('admin/dashboard', [['Dashboard', 'admin/dashboard'], ['Kelola pengguna']]) ?>
  <div class="page-head"><div><h1>Kelola pengguna</h1><p>Lihat profil, nonaktifkan akun yang melanggar ketentuan, atau bantu reset kata sandi. Pengguna diberi tahu lewat notifikasi dan email.</p></div></div>
  <div class="panel">
    <div class="tabs">
      <a href="<?= $tautanTab('mahasiswa') ?>" class="<?= $tab === 'mahasiswa' ? 'active' : '' ?>">Mahasiswa dan alumni<span class="c"><?= (int) $totalMhs ?></span></a>
      <a href="<?= $tautanTab('perusahaan') ?>" class="<?= $tab === 'perusahaan' ? 'active' : '' ?>">Perusahaan<span class="c"><?= (int) $totalPrsh ?></span></a>
    </div>

    <!-- ===== Filter (dicari di database, ikut pagination) ===== -->
    <form class="filters" method="get" action="<?= url('admin/kelola-pengguna') ?>">
      <input type="hidden" name="tab" value="<?= e($tab) ?>">
      <input class="input grow" name="q" type="search" placeholder="<?= $tab === 'mahasiswa' ? 'Cari nama, NIM, atau email' : 'Cari nama perusahaan, email, atau kota' ?>" value="<?= e($filter['keyword']) ?>" aria-label="Cari pengguna">
      <?php if ($tab === 'mahasiswa'): ?>
      <select class="input jur-filter" name="jurusan_id" aria-label="Jurusan">
        <option value="">Semua jurusan</option>
        <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
      </select>
      <select class="input" name="status_mahasiswa" aria-label="Status mahasiswa">
        <option value="">Mahasiswa &amp; alumni</option>
        <option value="aktif" <?= $filter['status_mahasiswa'] === 'aktif' ? 'selected' : '' ?>>Mahasiswa aktif</option>
        <option value="alumni" <?= $filter['status_mahasiswa'] === 'alumni' ? 'selected' : '' ?>>Alumni</option>
      </select>
      <?php endif; ?>
      <select class="input" name="status_akun" aria-label="Status akun">
        <option value="">Semua status akun</option>
        <?php foreach (['aktif' => 'Aktif', 'nonaktif' => 'Dinonaktifkan', 'menunggu' => 'Menunggu verifikasi', 'perbaikan' => 'Perlu perbaikan', 'ditolak' => 'Ditolak'] as $k => $v): ?>
          <option value="<?= $k ?>" <?= $filter['status_akun'] === $k ? 'selected' : '' ?>><?= e($v) ?></option>
        <?php endforeach; ?>
      </select>
      <button class="btn btn-primary" type="submit"><span data-ic="search"></span>Terapkan</button>
      <?php if ($adaFilter): ?><a class="btn btn-link" href="<?= url('admin/kelola-pengguna?tab=' . $tab) ?>">Hapus filter</a><?php endif; ?>
    </form>

    <?php if ($tab === 'mahasiswa'): ?>
      <div class="table-wrap"><table class="t">
        <tr><th>Nama</th><th>NIM</th><th>Jurusan</th><th>Status akun</th><th>Aksi</th></tr>
        <?php if (empty($mahasiswa)): ?><tr><td colspan="5" class="muted kosong">Tidak ada data dengan filter ini.</td></tr><?php endif; ?>
        <?php foreach ($mahasiswa as $m): ?>
          <tr>
            <td><a href="<?= url('admin/profil-mahasiswa/' . $m['id']) ?>" title="Lihat profil karier lengkap"><b><?= e($m['nama']) ?></b></a>
              <br><small class="muted"><?= e($m['email']) ?> &middot; <?= $m['status_mahasiswa'] === 'alumni' ? 'Alumni' : 'Mahasiswa' ?></small></td>
            <td><?= e($m['nim']) ?></td>
            <td><?= e($m['nama_jurusan']) ?></td>
            <td><?= badgeHtml(labelStatusAkun($m['status_akun'])) ?></td>
            <td class="aksi-sel"><a class="btn btn-sm btn-outline" href="<?= url('admin/profil-mahasiswa/' . $m['id']) ?>">Lihat profil</a><?= $tombolAksi($m) ?></td>
          </tr>
        <?php endforeach; ?>
      </table></div>
    <?php else: ?>
      <div class="table-wrap"><table class="t">
        <tr><th>Perusahaan</th><th>Bidang</th><th>Kota</th><th>Lowongan</th><th>Status akun</th><th>Aksi</th></tr>
        <?php if (empty($perusahaan)): ?><tr><td colspan="6" class="muted kosong">Tidak ada data dengan filter ini.</td></tr><?php endif; ?>
        <?php foreach ($perusahaan as $p): ?>
          <tr>
            <td><a href="<?= url('admin/profil-perusahaan/' . $p['id']) ?>"><b><?= e($p['nama_perusahaan']) ?></b></a><br><small class="muted"><?= e($p['email']) ?></small></td>
            <td><?= e($p['bidang_usaha']) ?></td>
            <td><?= e($p['kota']) ?></td>
            <td><?= (int) $p['jumlah_lowongan'] ?></td>
            <td><?= badgeHtml(labelStatusAkun($p['status_akun'])) ?></td>
            <td class="aksi-sel"><a class="btn btn-sm btn-outline" href="<?= url('admin/profil-perusahaan/' . $p['id']) ?>">Lihat profil</a><?= $tombolAksi($p) ?></td>
          </tr>
        <?php endforeach; ?>
      </table></div>
    <?php endif; ?>
    <?= paginasiHtml($paginasi, $tab === 'mahasiswa' ? 'mahasiswa/alumni' : 'perusahaan') ?>
  </div>
</section>

<?php foreach (array_merge($mahasiswa, $perusahaan) as $u) { require __DIR__ . '/_modal-akun.php'; } ?>

<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
