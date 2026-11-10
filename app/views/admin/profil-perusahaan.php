<?php
// ===== FRONTEND · ADMIN · Profil perusahaan ===========================
$page_title  = 'Profil ' . $prsh['nama_perusahaan'];
$active_menu = 'pengguna';
require __DIR__ . '/../layouts/app-header.php';
$logoUrl = !empty($prsh['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($prsh['logo'])) : null;
$labelDokumen = ['nib' => 'NIB', 'npwp' => 'NPWP perusahaan', 'akta' => 'Akta pendirian', 'domisili' => 'Surat keterangan domisili', 'logo' => 'Logo perusahaan'];
$labelKeputusanAkun = ['disetujui' => 'Disetujui', 'perbaikan' => 'Diminta perbaikan', 'ditolak' => 'Ditolak', 'nonaktif' => 'Dinonaktifkan', 'aktif' => 'Diaktifkan kembali'];
?>
<section class="view active">
  <div class="kepala-halaman">
    <div class="crumb"><a href="<?= url('admin/kelola-pengguna?tab=perusahaan') ?>">Kelola Pengguna</a> <span>/</span> <span><?= e($prsh['nama_perusahaan']) ?></span></div>
    <?= tombolKembali('admin/kelola-pengguna?tab=perusahaan') ?>
  </div>
  <div class="page-head">
    <div class="person">
      <?php if ($logoUrl): ?><img class="avatar-64" src="<?= e($logoUrl) ?>" alt=""><?php else: ?><span class="avatar-inisial avatar-64 fs-120"><?= e(inisial($prsh['nama_perusahaan'])) ?></span><?php endif; ?>
      <div><h1 class="m-0"><?= e($prsh['nama_perusahaan']) ?></h1><p class="m-0"><?= e($prsh['bidang_usaha']) ?> &middot; <?= e($prsh['kota']) ?></p></div>
    </div>
    <div class="d-flex flex-wrap gap-10">
      <?= badgeHtml(labelStatusAkun($prsh['status_akun'])) ?>
      <?php if ($prsh['status_akun'] === 'aktif'): ?><button class="btn btn-sm btn-outline btn-outline-bad" type="button" data-open="mSuspend<?= (int) $prsh['pengguna_id'] ?>">Nonaktifkan</button>
      <?php elseif ($prsh['status_akun'] === 'nonaktif'): ?><form class="d-inline" method="post" action="<?= url('admin/aktifkan-pengguna/' . $prsh['pengguna_id']) ?>" data-konfirmasi="Aktifkan kembali akun ini?"><?= csrfField() ?><input type="hidden" name="kembali" value="<?= e(Auth::pathSaatIni()) ?>"><button class="btn btn-sm btn-outline" type="submit">Aktifkan</button></form><?php endif; ?>
      <button class="btn btn-sm btn-outline" type="button" data-open="mReset<?= (int) $prsh['pengguna_id'] ?>"><span data-ic="lock"></span>Reset kata sandi</button>
    </div>
  </div>

  <div class="grid g-side items-start">
    <div>
      <div class="panel"><h3>Data perusahaan</h3>
        <dl class="dl">
          <dt>Email akun</dt><dd><?= e($prsh['email']) ?></dd>
          <dt>Jenis</dt><dd><?= e($prsh['jenis_perusahaan']) ?></dd>
          <dt>Alamat</dt><dd><?= e(implode(', ', array_filter([$prsh['alamat'], $prsh['kota'], $prsh['provinsi'] ?? null, $prsh['kode_pos'] ?? null]))) ?></dd>
          <dt>Website</dt><dd><?= $prsh['website'] ? '<a href="' . e(preg_match('#^https?://#i', $prsh['website']) ? $prsh['website'] : 'https://' . $prsh['website']) . '" target="_blank" rel="noopener">' . e($prsh['website']) . '</a>' : '-' ?></dd>
          <dt>PIC</dt><dd><?= e($prsh['nama_pic']) ?> (<?= e($prsh['jabatan_pic']) ?>)</dd>
          <dt>WhatsApp PIC</dt><dd><?= e($prsh['whatsapp_pic']) ?></dd>
          <dt>Bukan outsourcing</dt><dd><?= $prsh['bukan_outsourcing'] ? 'Ya (dinyatakan saat mendaftar)' : '-' ?></dd>
          <dt>Deskripsi</dt><dd><?= nl2br(e($prsh['deskripsi'] ?: '-')) ?></dd>
        </dl>
      </div>
      <div class="panel"><h3>Lowongan (<?= count($lowongan) ?>)</h3>
        <div class="table-wrap"><table class="t">
          <tr><th>Posisi</th><th>Status</th><th>Pelamar</th><th>Batas</th></tr>
          <?php if (!$lowongan): ?><tr><td colspan="4" class="muted kosong">Belum ada lowongan.</td></tr><?php endif; ?>
          <?php foreach ($lowongan as $l): ?>
            <tr><td><a href="<?= url('admin/detail-lowongan/' . $l['id']) ?>"><b><?= e($l['posisi']) ?></b></a></td><td><?= badgeHtml(labelStatusLowongan($l['status'])) ?></td><td><?= (int) $l['jumlah_pelamar'] ?></td><td><?= tanggalIndo($l['batas_lamaran']) ?></td></tr>
          <?php endforeach; ?>
        </table></div>
      </div>
    </div>
    <div>
      <div class="panel"><h3>Dokumen legalitas</h3>
        <?php if (!$dokumen): ?><p class="muted">Belum ada dokumen.</p><?php endif; ?>
        <?php foreach ($dokumen as $d): ?>
          <div class="list-item"><span class="list-ic" data-ic="file"></span><div class="grow"><b><?= e($labelDokumen[$d['tipe']] ?? strtoupper($d['tipe'])) ?></b><div class="muted fs-85"><?= tanggalIndo($d['diunggah_pada']) ?></div></div>
            <a class="btn btn-sm btn-outline" href="<?= e(url('unduh.php?tipe=' . urlencode($d['tipe']) . '&file=' . urlencode($d['file']))) ?>" target="_blank" rel="noopener">Lihat</a></div>
        <?php endforeach; ?>
      </div>
      <div class="panel"><h3>Riwayat status akun</h3>
        <?= riwayatHtml(array_map(fn($r) => ['tanggal' => $r['tanggal'], 'judul' => $labelKeputusanAkun[$r['keputusan']] ?? $r['keputusan'],
            'oleh' => 'Admin: ' . $r['nama_admin'], 'catatan' => $r['catatan']], $riwayatAkun)) ?>
      </div>
    </div>
  </div>
</section>
<?php $u = $prsh; $kembali = Auth::pathSaatIni(); require __DIR__ . '/_modal-akun.php'; ?>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
