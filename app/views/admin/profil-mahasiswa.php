<?php
// ===== FRONTEND · ADMIN · Profil lengkap mahasiswa ===================
$page_title  = 'Profil ' . $mhs['nama'];
$active_menu = 'pengguna';
require __DIR__ . '/../layouts/app-header.php';

$fotoUrl = !empty($mhs['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($mhs['foto'])) : null;

$labelStatusKarier = [
    'bekerja' => 'Bekerja', 'wirausaha' => 'Wirausaha', 'studi lanjut' => 'Studi lanjut',
    'mencari kerja' => 'Mencari kerja', 'belum bekerja' => 'Belum bekerja',
];
$statusKarier = $mhs['status_karier'] ?? '';

$detailKarier = [];
switch ($statusKarier) {
    case 'bekerja':
        $detailKarier = [
            ['Perusahaan', $mhs['tempat_kerja']], ['Posisi', $mhs['posisi_kerja']],
            ['Level jabatan', $mhs['level_jabatan']], ['Mulai bekerja', $mhs['tanggal_mulai_kerja'] ? tanggalIndo($mhs['tanggal_mulai_kerja']) : ''],
        ];
        break;
    case 'wirausaha':
        $detailKarier = [
            ['Nama usaha', $mhs['tempat_kerja']], ['Peran', $mhs['posisi_kerja']],
            ['Bidang usaha', $mhs['karier_bidang_minat']], ['Mulai usaha', $mhs['tanggal_mulai_kerja'] ? tanggalIndo($mhs['tanggal_mulai_kerja']) : ''],
        ];
        break;
    case 'studi lanjut':
        $detailKarier = [
            ['Perguruan tinggi', $mhs['tempat_kerja']], ['Fakultas', $mhs['karier_fakultas']],
            ['Program studi', $mhs['posisi_kerja']], ['Tahap', $mhs['karier_tahap_studi']],
            ['Perkiraan mulai', $mhs['tanggal_mulai_kerja'] ? tanggalIndo($mhs['tanggal_mulai_kerja']) : ''],
        ];
        break;
    case 'mencari kerja':
        $detailKarier = [
            ['Bidang diminati', $mhs['karier_bidang_minat']], ['Posisi yang dituju', $mhs['karier_rencana_posisi']],
        ];
        break;
    case 'belum bekerja':
        $detailKarier = [['Bidang yang diminati', $mhs['karier_bidang_minat']]];
        break;
}
if (!empty($mhs['karier_catatan'])) {
    $detailKarier[] = ['Catatan', $mhs['karier_catatan']];
}
$detailKarier = array_filter($detailKarier, static fn($b) => trim((string) $b[1]) !== '');

?>
<section class="view active">
  <div class="kepala-halaman">
    <div class="crumb"><a href="<?= url('admin/kelola-pengguna') ?>">Kelola Pengguna</a> <span>/</span> <span><?= e($mhs['nama']) ?></span></div>
    <?= tombolKembali('admin/kelola-pengguna') ?>
  </div>

  <div class="page-head">
    <div>
      <h1><?= e($mhs['nama']) ?></h1>
      <p><?= e($mhs['jenjang'] . ' ' . $mhs['nama_prodi']) ?>, <?= e($mhs['nama_jurusan']) ?></p>
    </div>
    <div class="d-flex flex-wrap gap-10">
      <?= badgeHtml(labelStatusAkun($mhs['status_akun'])) ?>
      <?php if ($mhs['status_akun'] === 'aktif'): ?><button class="btn btn-sm btn-outline btn-outline-bad" type="button" data-open="mSuspend<?= (int) $mhs['pengguna_id'] ?>">Nonaktifkan</button>
      <?php elseif ($mhs['status_akun'] === 'nonaktif'): ?><form class="d-inline" method="post" action="<?= url('admin/aktifkan-pengguna/' . $mhs['pengguna_id']) ?>" data-konfirmasi="Aktifkan kembali akun ini?"><?= csrfField() ?><input type="hidden" name="kembali" value="<?= e(Auth::pathSaatIni()) ?>"><button class="btn btn-sm btn-outline" type="submit">Aktifkan</button></form><?php endif; ?>
      <button class="btn btn-sm btn-outline" type="button" data-open="mReset<?= (int) $mhs['pengguna_id'] ?>"><span data-ic="lock"></span>Reset kata sandi</button>
    </div>
  </div>

  <!-- ===== Kolom kiri: identitas, karier, riwayat ===== -->
  <div class="grid g-side items-start">

    <div>
      <div class="panel">
        <div class="person items-center mb-16">
          <?php if ($fotoUrl): ?>
            <img class="avatar-64" src="<?= e($fotoUrl) ?>" alt="Foto <?= e($mhs['nama']) ?>">
          <?php else: ?>
            <span class="avatar-inisial avatar-64 fs-120"><?= e(inisial($mhs['nama'])) ?></span>
          <?php endif; ?>
          <div>
            <b class="fs-110"><?= e($mhs['nama']) ?></b>
            <small>NIM <?= e($mhs['nim']) ?><?= $mhs['ipk'] ? ' &middot; IPK ' . e($mhs['ipk']) : '' ?></small>
          </div>
          <span class="ml-auto"><?= badgeHtml(labelStatusAkun($mhs['status_akun'])) ?></span>
        </div>

        <dl class="dl">
          <dt>Email</dt><dd><?= e($mhs['email']) ?></dd>
          <dt>WhatsApp</dt><dd><?= e($mhs['no_whatsapp']) ?></dd>
          <dt>Jurusan</dt><dd><?= e($mhs['nama_jurusan']) ?></dd>
          <dt>Program studi</dt><dd><?= e($mhs['jenjang'] . ' ' . $mhs['nama_prodi']) ?></dd>
          <dt>Angkatan</dt><dd><?= e((string) $mhs['angkatan']) ?></dd>
          <dt>Status</dt><dd><?= $mhs['status_mahasiswa'] === 'alumni' ? 'Alumni, lulus ' . e((string) $mhs['tahun_lulus']) : 'Mahasiswa aktif' ?></dd>
          <dt>Alamat</dt><dd><?= e(implode(', ', array_filter([$mhs['alamat'] ?? null, $mhs['domisili'] ?? null, $mhs['provinsi'] ?? null, $mhs['kode_pos'] ?? null])) ?: '-') ?></dd>
          <?php if (!empty($mhs['tentang'])): ?><dt>Tentang</dt><dd><?= nl2br(e($mhs['tentang'])) ?></dd><?php endif; ?>
        </dl>
      </div>

      <div class="panel">
        <div class="panel-head">
          <h3>Status karier</h3>
          <?php if ($statusKarier): ?>
            <span class="pill <?= $statusKarier === 'bekerja' ? 'p-aktif' : 'p-diajukan' ?>"><?= e($labelStatusKarier[$statusKarier] ?? $statusKarier) ?></span>
          <?php endif; ?>
        </div>
        <?php if (!$statusKarier): ?>
          <p class="muted">Mahasiswa belum mengisi status karier.</p>
        <?php elseif (!$detailKarier): ?>
          <p class="muted">Status terisi <b><?= e($labelStatusKarier[$statusKarier] ?? $statusKarier) ?></b> tanpa rincian tambahan.</p>
        <?php else: ?>
          <dl class="dl">
            <?php foreach ($detailKarier as [$k, $v]): ?><dt><?= e($k) ?></dt><dd><?= e($v) ?></dd><?php endforeach; ?>
          </dl>
        <?php endif; ?>
        <?php if (!empty($mhs['karier_diperbarui_pada'])): ?>
          <small class="muted">Diperbarui <?= tanggalIndo($mhs['karier_diperbarui_pada']) ?></small>
        <?php endif; ?>
      </div>

      <div class="panel">
        <h3>Pendidikan</h3>
        <?php if (!$pendidikan): ?><p class="muted">Belum diisi.</p><?php endif; ?>
        <?php foreach ($pendidikan as $it): ?><?= kartuItemHtml($it, 'pendidikan') ?><?php endforeach; ?>
      </div>

      <div class="panel">
        <h3>Pengalaman</h3>
        <?php if (!$pengalaman): ?><p class="muted">Belum diisi.</p><?php endif; ?>
        <?php foreach ($pengalaman as $it): ?><?= kartuItemHtml($it, 'pengalaman') ?><?php endforeach; ?>
      </div>

      <div class="panel">
        <h3>Sertifikat</h3>
        <?php if (!$sertifikat): ?><p class="muted">Belum diisi.</p><?php endif; ?>
        <?php foreach ($sertifikat as $it): ?><?= kartuItemHtml($it, 'sertifikat') ?><?php endforeach; ?>
      </div>

      <div class="panel">
        <h3>Riwayat lamaran</h3>
        <?php if (!$lamaran): ?>
          <p class="muted">Mahasiswa ini belum pernah melamar lowongan.</p>
        <?php else: ?>
          <div class="table-wrap">
            <table class="t">
              <tr><th>Tanggal</th><th>Posisi</th><th>Perusahaan</th><th>Status</th></tr>
              <?php foreach ($lamaran as $lm): ?>
                <tr>
                  <td><?= e(tanggalIndo($lm['tanggal_lamar'])) ?></td>
                  <td><b><?= e($lm['posisi']) ?></b></td>
                  <td><?= e($lm['nama_perusahaan']) ?></td>
                  <td><?= badgeHtml(labelStatusLamaran($lm['status'])) ?></td>
                </tr>
              <?php endforeach; ?>
            </table>
          </div>
        <?php endif; ?>
      </div>
    </div>

    <!-- ===== Kolom kanan: kelengkapan, dokumen, skill ===== -->
    <div>
      <div class="panel">
        <h3>Kelengkapan profil</h3>
        <div class="progress-label">
          <span class="muted">Terisi</span><b><?= (int) $kelengkapan ?>%</b>
        </div>
        <div class="progress"><i style="width:<?= (int) $kelengkapan ?>%"></i></div>
      </div>

      <div class="panel">
        <h3>Dokumen</h3>
        <div class="list-item"><span class="list-ic" data-ic="file"></span>
          <div class="grow"><b><?= $mhs['status_mahasiswa'] === 'alumni' ? 'Ijazah atau SKL' : 'KTM' ?></b>
            <div class="muted"><?= $mhs['file_ktm'] ? 'Tersimpan' : 'Belum diunggah' ?></div>
          </div>
          <?php if (berkasAda($mhs['file_ktm'] ?? null, 'ktm', 'ijazah')): ?>
            <a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=ktm&file=' . urlencode($mhs['file_ktm'])) ?>" target="_blank">Lihat</a>
          <?php elseif (!empty($mhs['file_ktm'])): ?>
            <span class="muted fs-85">Berkas tidak ditemukan</span>
          <?php endif; ?>
        </div>
        <div class="list-item"><span class="list-ic" data-ic="file"></span>
          <div class="grow"><b>CV unggahan</b><div class="muted"><?= $mhs['file_cv'] ? 'Tersimpan' : 'Belum diunggah' ?></div></div>
          <?php if ($mhs['file_cv']): ?><a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=cv&file=' . urlencode($mhs['file_cv'])) ?>" target="_blank">Lihat</a><?php endif; ?>
        </div>
      </div>

      <div class="panel">
        <h3>Skill</h3>
        <?php if (!$skill): ?><p class="muted">Belum diisi.</p><?php else: ?>
          <div class="chips">
            <?php foreach ($skill as $s): ?><span class="chip"><?= e($s['nama']) ?></span><?php endforeach; ?>
          </div>
        <?php endif; ?>
      </div>

      <div class="panel">
        <h3>Bidang minat</h3>
        <?php if (!$minat): ?><p class="muted">Belum diisi.</p><?php else: ?>
          <div class="chips">
            <?php foreach ($minat as $b): ?><span class="chip"><?= e($b['nama']) ?></span><?php endforeach; ?>
          </div>
        <?php endif; ?>
      </div>

      <div class="panel">
        <h3>Portofolio</h3>
        <?php if (!$portofolio): ?><p class="muted">Belum diisi.</p><?php endif; ?>
        <?php foreach ($portofolio as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="link"></span>
            <div class="grow"><b><?= e($it['judul']) ?></b>
              <?php if ($it['tautan']): ?><div><a href="<?= e(tautanAman($it['tautan'])) ?>" target="_blank" rel="noopener noreferrer"><?= e($it['tautan']) ?></a></div><?php endif; ?>
            </div>
          </div>
        <?php endforeach; ?>
      </div>
      <div class="panel">
        <h3>Riwayat status akun</h3>
        <?php $labelKeputusanAkun = ['disetujui' => 'Disetujui', 'perbaikan' => 'Diminta perbaikan', 'ditolak' => 'Ditolak', 'nonaktif' => 'Dinonaktifkan', 'aktif' => 'Diaktifkan kembali']; ?>
        <?= riwayatHtml(array_map(fn($r) => ['tanggal' => $r['tanggal'], 'judul' => $labelKeputusanAkun[$r['keputusan']] ?? $r['keputusan'],
            'oleh' => 'Admin: ' . $r['nama_admin'], 'catatan' => $r['catatan']], $riwayatAkun)) ?>
      </div>
    </div>
  </div>
</section>
<?php $u = $mhs; $kembali = Auth::pathSaatIni(); require __DIR__ . '/_modal-akun.php'; ?>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
