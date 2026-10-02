<?php
/**
 * View: perusahaan/lowongan
 * Dipanggil oleh: PerusahaanController::lowongan()
 * Variabel: $lowongan
 */
$page_title = 'Lowongan Saya';
$active_menu = 'lowongan';
require __DIR__ . '/../layouts/app-header.php';

$grup = trim($_GET['status'] ?? 'semua');
$grupOpsi = ['semua' => 'Semua', 'aktif' => 'Aktif', 'ditutup' => 'Ditutup'];
$tampil = array_filter($lowongan, fn($l) => $grup === 'semua' || $l['status'] === $grup);
?>
<section class="view active">
  <div class="page-head"><div><h1>Lowongan Saya</h1><p>Lowongan langsung tayang untuk mahasiswa dan alumni Polinema yang sudah masuk.</p></div><a class="btn btn-primary" href="<?= url('lowongan/form-pasang') ?>"><span data-ic="plus"></span>Pasang lowongan</a></div>
  <div class="panel">
    <div class="tabs">
      <?php foreach ($grupOpsi as $key => $label): $jumlahGrup = count(array_filter($lowongan, fn($l) => $key === 'semua' || $l['status'] === $key)); ?>
        <a href="<?= url('perusahaan/lowongan?status=' . $key) ?>" class="<?= $grup === $key ? 'active' : '' ?>" style="text-decoration:none"><?= e($label) ?><span class="c"><?= $jumlahGrup ?></span></a>
      <?php endforeach; ?>
    </div>
    <div class="table-wrap"><table class="t">
      <tr><th>Lowongan</th><th>Status</th><th>Pelamar</th><th>Kuota diterima</th><th>Batas</th><th></th></tr>
      <?php if (empty($tampil)): ?>
        <tr><td colspan="6" class="muted" style="text-align:center;padding:30px">Belum ada lowongan di kelompok ini.</td></tr>
      <?php else: foreach ($tampil as $l):
          $pamfletUrl = !empty($l['pamflet']) ? url('unduh.php?tipe=pamflet&file=' . urlencode($l['pamflet'])) : url('assets/img/hero-1.jpg');
      ?>
        <tr>
          <td><div class="person"><img src="<?= e($pamfletUrl) ?>" alt="" style="border-radius:5px;width:36px;height:45px;object-fit:cover"><div><b><?= e($l['posisi']) ?></b><small><?= $l['status'] === 'nonaktif' ? e($l['alasan_nonaktif'] ?: 'Dinonaktifkan Admin') : 'Tayang untuk civitas Polinema' ?></small></div></div></td>
          <td><?= badgeHtml(labelStatusLowongan($l['status'])) ?></td>
          <td><a href="<?= url('perusahaan/pelamar?lowongan_id=' . $l['id']) ?>"><?= (int) $l['jumlah_pelamar'] ?> pelamar</a></td>
          <td><?= (int) $l['terisi'] ?>/<?= (int) $l['kuota'] ?></td>
          <td><?= tanggalIndo($l['batas_lamaran']) ?></td>
          <td style="white-space:nowrap">
            <!-- "Lihat" membuka halaman Info Loker persis seperti yang dilihat
                 mahasiswa dan admin jurusan, jadi perusahaan bisa memeriksa
                 hasil lowongannya sendiri sebelum disebarkan. -->
            <a class="btn btn-sm btn-primary" href="<?= url('info-loker/' . $l['kode_pratinjau']) ?>" target="_blank" rel="noopener">Lihat</a>
            <a class="btn btn-sm btn-outline" href="<?= url('lowongan/form-pasang/' . $l['id']) ?>">Edit</a>
            <?php if ($l['status'] === 'aktif'): ?>
              <form method="post" action="<?= url('lowongan/tutup/' . $l['id']) ?>" style="display:inline" onsubmit="return confirm('Tutup lowongan ini? Lamaran yang sudah masuk tetap bisa diproses.')">
                <?= csrfField() ?><button class="btn btn-sm btn-link" type="submit">Tutup</button>
              </form>
            <?php elseif ($l['status'] === 'ditutup'): $tglBaru = date('Y-m-d', strtotime('+30 days')); ?>
              <form method="post" action="<?= url('lowongan/perpanjang/' . $l['id']) ?>" style="display:inline" onsubmit="return confirm('Perpanjang lowongan ini 30 hari dan aktifkan kembali untuk pelamar baru?')">
                <?= csrfField() ?><input type="hidden" name="batas_lamaran" value="<?= e($tglBaru) ?>"><button class="btn btn-sm btn-link" type="submit">Perpanjang</button>
              </form>
            <?php endif; ?>
          </td>
        </tr>
      <?php endforeach; endif; ?>
    </table></div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>