<?php
/**
 * View: admin/persetujuan-akun
 * Dipanggil oleh: AdminController::persetujuan()
 * Variabel: $antrean, $jurusan, $filter
 */
$page_title = 'Persetujuan Akun';
$active_menu = 'persetujuan';
require __DIR__ . '/../layouts/app-header.php';

$grup = trim($_GET['peran'] ?? 'semua');
$tampil = array_filter($antrean, fn($a) => $grup === 'semua' || $a['role'] === $grup);
?>
<section class="view active">
  <div class="page-head"><div><h1>Persetujuan akun</h1><p>Periksa data dan dokumen pendaftar. Target selesai maksimal 2 hari kerja.</p></div></div>
  <div class="panel">
    <div class="tabs">
      <a href="<?= url('admin/persetujuan') ?>" class="<?= $grup === 'semua' ? 'active' : '' ?>" style="text-decoration:none">Semua<span class="c"><?= count($antrean) ?></span></a>
      <a href="<?= url('admin/persetujuan?peran=mahasiswa') ?>" class="<?= $grup === 'mahasiswa' ? 'active' : '' ?>" style="text-decoration:none">Mahasiswa/Alumni<span class="c"><?= count(array_filter($antrean, fn($a) => $a['role'] === 'mahasiswa')) ?></span></a>
      <a href="<?= url('admin/persetujuan?peran=perusahaan') ?>" class="<?= $grup === 'perusahaan' ? 'active' : '' ?>" style="text-decoration:none">Perusahaan<span class="c"><?= count(array_filter($antrean, fn($a) => $a['role'] === 'perusahaan')) ?></span></a>
    </div>
    <form class="filters" method="get" action="<?= url('admin/persetujuan') ?>">
      <input type="hidden" name="peran" value="<?= e($grup) ?>">
      <input class="input grow" type="text" id="cariPendaftar" placeholder="Cari nama pendaftar" autocomplete="off">
      <select class="input jur-filter" name="jurusan_id" onchange="this.form.submit()">
        <option value="">Semua jurusan</option>
        <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
      </select>
      <select class="input" id="urutkanPendaftar">
        <option value="lama">Paling lama menunggu</option>
        <option value="baru">Paling baru mendaftar</option>
      </select>
    </form>
    <div class="table-wrap"><table class="t" id="tabelPendaftar">
      <tr><th>Pendaftar</th><th>Tanggal daftar</th><th>Lama menunggu</th><th>Jenis</th><th></th></tr>
      <?php if (empty($tampil)): ?>
        <tr><td colspan="5" class="muted" style="text-align:center;padding:30px">Tidak ada pendaftar menunggu.</td></tr>
      <?php else: foreach ($tampil as $q):
          $hari = (int) floor((time() - strtotime($q['dibuat_pada'])) / 86400);
          $jenisBaru = empty($q['jumlah_perbaikan']);
      ?>
        <tr data-nama="<?= e(mb_strtolower($q['nama'])) ?>" data-waktu="<?= (int) strtotime($q['dibuat_pada']) ?>">
          <td><b><?= e($q['nama']) ?></b><?php if ($q['nama_jurusan']): ?><br><small class="muted"><?= e($q['nama_jurusan']) ?>, <?= $q['role'] === 'mahasiswa' ? 'Mahasiswa/Alumni' : 'Perusahaan' ?></small><?php else: ?><br><small class="muted"><?= $q['role'] === 'mahasiswa' ? 'Mahasiswa/Alumni' : 'Perusahaan' ?></small><?php endif; ?></td>
          <td><?= tanggalIndo($q['dibuat_pada']) ?></td>
          <td class="<?= $hari <= 0 ? 'wait-g' : ($hari > 2 ? 'wait-r' : 'wait-y') ?>"><?= $hari <= 0 ? 'Hari ini' : $hari . ' hari' ?></td>
          <td><span class="pill <?= $jenisBaru ? 'p-diajukan' : 'p-perbaikan' ?>"><?= $jenisBaru ? 'Baru' : 'Kiriman ulang' ?></span></td>
          <td><a class="btn btn-sm btn-primary" href="<?= url('admin/detail-pendaftar/' . $q['pengguna_id']) ?>">Periksa</a></td>
        </tr>
      <?php endforeach; endif; ?>
    </table></div>
  </div>
</section>
<script>
(function(){
  var cari = document.getElementById('cariPendaftar');
  var urut = document.getElementById('urutkanPendaftar');
  var tabel = document.getElementById('tabelPendaftar');
  if (!tabel) return;
  function terapkan(){
    var kata = (cari.value || '').trim().toLowerCase();
    var baris = Array.prototype.slice.call(tabel.querySelectorAll('tr[data-nama]'));
    baris.forEach(function(tr){
      tr.style.display = tr.dataset.nama.indexOf(kata) === -1 ? 'none' : '';
    });
    baris.sort(function(a, b){
      var wa = parseInt(a.dataset.waktu, 10), wb = parseInt(b.dataset.waktu, 10);
      return urut.value === 'baru' ? wb - wa : wa - wb;
    }).forEach(function(tr){ tabel.appendChild(tr); });
  }
  cari.addEventListener('input', terapkan);
  urut.addEventListener('change', terapkan);
})();
</script>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
