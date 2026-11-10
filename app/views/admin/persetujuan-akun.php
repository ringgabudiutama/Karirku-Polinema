<?php
// ===== FRONTEND · ADMIN · Persetujuan akun (antrean) =================
$page_title = 'Persetujuan Akun';
$active_menu = 'persetujuan';
require __DIR__ . '/../layouts/app-header.php';

$grup = $filter['peran'] ?: 'semua';
$tautanTab = fn($peran) => url('admin/persetujuan?' . http_build_query(array_filter(['peran' => $peran, 'q' => $filter['q'], 'jurusan_id' => $filter['jurusan_id']])));
?>
<section class="view active">
  <?= kepalaKembali('admin/dashboard', [['Dashboard', 'admin/dashboard'], ['Persetujuan akun']]) ?>
  <div class="page-head"><div><h1>Persetujuan akun</h1><p>Periksa data dan dokumen pendaftar. Target selesai maksimal 2 hari kerja. Paling lama menunggu tampil paling atas.</p></div></div>
  <div class="panel">
    <!-- ===== Tab & filter (pencarian di server, ikut pagination) ===== -->
    <div class="tabs">
      <a href="<?= $tautanTab('') ?>" class="<?= $grup === 'semua' ? 'active' : '' ?>">Semua</a>
      <a href="<?= $tautanTab('mahasiswa') ?>" class="<?= $grup === 'mahasiswa' ? 'active' : '' ?>">Mahasiswa/Alumni</a>
      <a href="<?= $tautanTab('perusahaan') ?>" class="<?= $grup === 'perusahaan' ? 'active' : '' ?>">Perusahaan</a>
    </div>
    <form class="filters" method="get" action="<?= url('admin/persetujuan') ?>">
      <?php if ($filter['peran']): ?><input type="hidden" name="peran" value="<?= e($filter['peran']) ?>"><?php endif; ?>
      <input class="input grow" type="search" name="q" value="<?= e($filter['q']) ?>" placeholder="Cari nama, NIM, atau email" aria-label="Cari pendaftar">
      <select class="input jur-filter" name="jurusan_id" aria-label="Jurusan">
        <option value="">Semua jurusan</option>
        <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
      </select>
      <button class="btn btn-primary" type="submit"><span data-ic="search"></span>Cari</button>
      <?php if ($filter['q'] || $filter['jurusan_id']): ?><a class="btn btn-link" href="<?= url('admin/persetujuan' . ($filter['peran'] ? '?peran=' . urlencode($filter['peran']) : '')) ?>">Hapus filter</a><?php endif; ?>
    </form>
    <!-- ===== Tabel pendaftar ===== -->
    <div class="table-wrap"><table class="t">
      <tr><th>Pendaftar</th><th>Tanggal daftar</th><th>Lama menunggu</th><th>Jenis</th><th></th></tr>
      <?php if (empty($antrean)): ?>
        <tr><td colspan="5" class="muted kosong">Tidak ada pendaftar menunggu dengan filter ini.</td></tr>
      <?php else: foreach ($antrean as $q):
          $hari = (int) floor((time() - strtotime($q['dibuat_pada'])) / 86400);
          $jenisBaru = empty($q['pernah_perbaikan']);
      ?>
        <tr>
          <td><b><?= e($q['nama']) ?></b><br><small class="muted"><?= $q['role'] === 'mahasiswa' ? 'Mahasiswa/Alumni' : 'Perusahaan' ?><?= $q['nim'] ? ' &middot; ' . e($q['nim']) : '' ?><?= $q['nama_jurusan'] ? ' &middot; ' . e($q['nama_jurusan']) : '' ?></small></td>
          <td><?= tanggalWaktuIndo($q['dibuat_pada']) ?></td>
          <td class="<?= $hari <= 0 ? 'wait-g' : ($hari > 2 ? 'wait-r' : 'wait-y') ?>"><?= $hari <= 0 ? 'Hari ini' : $hari . ' hari' ?></td>
          <td><span class="pill <?= $jenisBaru ? 'p-diajukan' : 'p-perbaikan' ?>"><?= $jenisBaru ? 'Baru' : 'Kiriman ulang' ?></span></td>
          <td><a class="btn btn-sm btn-primary" href="<?= url('admin/detail-pendaftar/' . $q['pengguna_id']) ?>">Periksa</a></td>
        </tr>
      <?php endforeach; endif; ?>
    </table></div>
    <?= paginasiHtml($paginasi, 'pendaftar') ?>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
