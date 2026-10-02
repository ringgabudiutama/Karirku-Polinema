<?php
/**
 * View: admin/rekap-lamaran
 * Dipanggil oleh: AdminController::rekapLamaran()
 * Variabel: $lamaran, $perusahaan, $jurusan, $prodi, $angkatan, $bulan, $filter
 */
$page_title = 'Rekap Lamaran';
$active_menu = 'rekap';
require __DIR__ . '/../layouts/app-header.php';

$totalLamaran = count($lamaran);
$diproses = count(array_filter($lamaran, fn($l) => in_array($l['status'], ['diajukan', 'screening', 'interview'], true)));
$diterima = count(array_filter($lamaran, fn($l) => $l['status'] === 'diterima'));
$ditolakBatal = count(array_filter($lamaran, fn($l) => in_array($l['status'], ['ditolak', 'dibatalkan'], true)));

$perPerusahaan = [];
foreach ($lamaran as $l) {
    $k = $l['nama_perusahaan'];
    $perPerusahaan[$k]['pelamar'] = ($perPerusahaan[$k]['pelamar'] ?? 0) + 1;
    $perPerusahaan[$k]['diterima'] = ($perPerusahaan[$k]['diterima'] ?? 0) + ($l['status'] === 'diterima' ? 1 : 0);
}
arsort($perPerusahaan);
?>
<section class="view active">
  <div class="page-head"><div><h1>Rekap lamaran</h1><p>Seluruh lamaran dari semua perusahaan. Hanya untuk dilihat.</p></div>
    <a class="btn btn-primary" href="<?= url('admin/unduh-rekap-lamaran?' . http_build_query($filter)) ?>" target="_blank"><span data-ic="download"></span>Unduh PDF</a>
  </div>
  <div class="grid g4" style="margin-bottom:18px">
    <div class="stat"><div class="n"><?= number_format($totalLamaran) ?></div><div class="l">Total lamaran</div></div>
    <div class="stat"><div class="n"><?= number_format($diproses) ?></div><div class="l">Sedang diproses</div></div>
    <div class="stat"><div class="n" style="color:var(--ok)"><?= number_format($diterima) ?></div><div class="l">Diterima</div></div>
    <div class="stat"><div class="n" style="color:var(--bad)"><?= number_format($ditolakBatal) ?></div><div class="l">Ditolak atau dibatalkan</div></div>
  </div>
  <div class="grid g-side" style="align-items:start">
    <div class="panel">
      <form class="filters" method="get" action="<?= url('admin/rekap-lamaran') ?>" id="formFilterLamaran">
        <div style="flex-basis:100%;display:flex;gap:8px;margin-bottom:6px">
          <input class="input" type="search" name="q" id="cariLamaran" style="flex:1"
                 value="<?= e($filter['q'] ?? '') ?>"
                 placeholder="Cari nama pelamar, NIM, perusahaan, atau posisi" autocomplete="off">
          <button class="btn btn-primary" type="submit">Cari</button>
          <?php if (!empty($filter['q'])): ?>
            <a class="btn btn-outline" href="<?= url('admin/rekap-lamaran') ?>">Hapus</a>
          <?php endif; ?>
        </div>
        <select class="input" name="status" onchange="this.form.submit()">
          <option value="">Semua status</option>
          <option value="diajukan" <?= $filter['status'] === 'diajukan' ? 'selected' : '' ?>>Diajukan</option>
          <option value="screening" <?= $filter['status'] === 'screening' ? 'selected' : '' ?>>Screening CV</option>
          <option value="interview" <?= $filter['status'] === 'interview' ? 'selected' : '' ?>>Interview</option>
          <option value="diterima" <?= $filter['status'] === 'diterima' ? 'selected' : '' ?>>Diterima</option>
          <option value="ditolak" <?= $filter['status'] === 'ditolak' ? 'selected' : '' ?>>Ditolak</option>
        </select>
        <select class="input" name="jurusan_id" id="filterJurusan" onchange="ubahJurusan()">
          <option value="">Semua jurusan</option>
          <?php foreach ($jurusan as $j): ?><option value="<?= (int) $j['id'] ?>" <?= (string) $filter['jurusan_id'] === (string) $j['id'] ? 'selected' : '' ?>><?= e($j['nama']) ?></option><?php endforeach; ?>
        </select>
        <div style="flex-basis:100%;height:0"></div>
        <select class="input" name="prodi_id" id="filterProdi" onchange="this.form.submit()">
          <option value="">Semua prodi</option>
          <?php foreach ($prodi as $ps): ?><option value="<?= (int) $ps['id'] ?>" data-jurusan="<?= (int) $ps['jurusan_id'] ?>" <?= (string) $filter['prodi_id'] === (string) $ps['id'] ? 'selected' : '' ?>><?= e(trim(($ps['jenjang'] ?? '') . ' ' . $ps['nama'])) ?></option><?php endforeach; ?>
        </select>
        <select class="input" name="angkatan" onchange="this.form.submit()">
          <option value="">Semua angkatan</option>
          <?php foreach ($angkatan as $ang): ?><option value="<?= (int) $ang ?>" <?= (string) $filter['angkatan'] === (string) $ang ? 'selected' : '' ?>>Angkatan <?= (int) $ang ?></option><?php endforeach; ?>
        </select>
        <select class="input" name="bulan" onchange="this.form.submit()">
          <option value="">Semua bulan</option>
          <?php foreach ($bulan as $b): ?><option value="<?= e($b['nilai']) ?>" <?= (string) $filter['bulan'] === (string) $b['nilai'] ? 'selected' : '' ?>><?= e($b['label']) ?></option><?php endforeach; ?>
        </select>
        <a class="btn btn-sm btn-outline" href="<?= url('admin/rekap-lamaran') ?>">Reset Filter</a>
      </form>
      <div class="table-wrap"><table class="t" id="tabelLamaran">
        <tr><th>Tanggal</th><th>Pelamar</th><th>Prodi</th><th>Angkatan</th><th>Perusahaan</th><th>Posisi</th><th>Status</th><th>Diperbarui</th></tr>
        <?php if (empty($lamaran)): ?><tr><td colspan="8" class="muted" style="text-align:center;padding:30px">Tidak ada data.</td></tr><?php endif; ?>
        <?php foreach (array_slice($lamaran, 0, 200) as $l): ?>
          <tr data-cari="<?= e(mb_strtolower($l['nama_mahasiswa'] . ' ' . $l['nama_perusahaan'] . ' ' . $l['posisi'])) ?>">
            <td><?= tanggalIndo($l['tanggal_lamar']) ?></td>
            <td><?= e($l['nama_mahasiswa']) ?></td>
            <td><?= e($l['nama_prodi']) ?><br><small class="muted"><?= e($l['nama_jurusan']) ?></small></td>
            <td><?= (int) $l['angkatan'] ?></td>
            <td><?= e($l['nama_perusahaan']) ?></td>
            <td><?= e($l['posisi']) ?></td>
            <td><?= badgeHtml(labelStatusLamaran($l['status'])) ?></td>
            <td><?= tanggalIndo($l['diperbarui_pada']) ?></td>
          </tr>
        <?php endforeach; ?>
        <tr id="barisKosongCari" class="muted" hidden><td colspan="8" style="text-align:center;padding:30px">Tidak ada hasil yang cocok dengan pencarian.</td></tr>
      </table></div>
      <?php if (count($lamaran) > 200): ?><p class="muted" style="font-size:.85rem;margin-top:10px">Menampilkan 200 dari <?= count($lamaran) ?> baris. Unduh PDF untuk data lengkap.</p><?php endif; ?>
    </div>
    <div class="panel">
      <h3>Per perusahaan</h3>
      <table class="t"><tr><th>Perusahaan</th><th>Pelamar</th><th>Diterima</th></tr>
        <?php foreach (array_slice($perPerusahaan, 0, 8, true) as $nama => $d): ?>
          <tr><td><?= e($nama) ?></td><td><?= $d['pelamar'] ?></td><td><?= $d['diterima'] ?></td></tr>
        <?php endforeach; ?>
      </table>
    </div>
  </div>
</section>
<script>
(function(){
  // Cari langsung mengubah tampilan tabel tanpa reload halaman.
  var cari = document.getElementById('cariLamaran');
  var tabel = document.getElementById('tabelLamaran');
  var kosong = document.getElementById('barisKosongCari');
  if (cari && tabel) {
    cari.addEventListener('input', function(){
      var kata = cari.value.trim().toLowerCase();
      var adaHasil = false;
      tabel.querySelectorAll('tr[data-cari]').forEach(function(tr){
        var cocok = tr.dataset.cari.indexOf(kata) !== -1;
        tr.style.display = cocok ? '' : 'none';
        if (cocok) adaHasil = true;
      });
      if (kosong) kosong.hidden = adaHasil || tabel.querySelectorAll('tr[data-cari]').length === 0;
    });
  }

  // Dropdown Prodi hanya menampilkan prodi milik Jurusan yang dipilih.
  window.ubahJurusan = function(){
    var jurusan = document.getElementById('filterJurusan');
    var prodi = document.getElementById('filterProdi');
    prodi.value = ''; // reset supaya tidak ada kombinasi jurusan+prodi yang tidak sesuai
    saringProdi();
    jurusan.form.submit();
  };
  function saringProdi(){
    var jurusanId = document.getElementById('filterJurusan').value;
    document.querySelectorAll('#filterProdi option[data-jurusan]').forEach(function(opt){
      opt.hidden = jurusanId !== '' && opt.dataset.jurusan !== jurusanId;
    });
  }
  saringProdi();
})();
</script>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>