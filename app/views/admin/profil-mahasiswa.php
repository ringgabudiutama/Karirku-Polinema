<?php
/**
 * View: admin/profil-mahasiswa
 * Dipanggil oleh: AdminController::profilMahasiswa($mahasiswaId)
 * Variabel: $mhs, $pendidikan, $pengalaman, $sertifikat, $portofolio,
 *           $skill, $minat, $lamaran, $kelengkapan
 *
 * Halaman ini HANYA BACA. Admin memakainya untuk memeriksa profil karier
 * seorang mahasiswa dari menu Kelola Pengguna, tanpa bisa mengubah datanya.
 */
$page_title  = 'Profil ' . $mhs['nama'];
$active_menu = 'pengguna';
require __DIR__ . '/../layouts/app-header.php';

$fotoUrl = !empty($mhs['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($mhs['foto'])) : null;

$labelStatusKarier = [
    'bekerja' => 'Bekerja', 'wirausaha' => 'Wirausaha', 'studi lanjut' => 'Studi lanjut',
    'mencari kerja' => 'Mencari kerja', 'belum bekerja' => 'Belum bekerja',
];
$statusKarier = $mhs['status_karier'] ?? '';

/* Baris detail karier ikut berubah mengikuti status, sama seperti di form
   milik mahasiswa, supaya Admin tidak melihat kolom kosong yang tidak relevan. */
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
  <div class="crumb"><a href="<?= url('admin/kelola-pengguna') ?>">Kelola Pengguna</a> <span>/</span> <span><?= e($mhs['nama']) ?></span></div>

  <div class="page-head">
    <div>
      <h1><?= e($mhs['nama']) ?></h1>
      <p><?= e($mhs['jenjang'] . ' ' . $mhs['nama_prodi']) ?>, <?= e($mhs['nama_jurusan']) ?></p>
    </div>
    <div style="display:flex;gap:10px">
      <a class="btn btn-outline" href="<?= url('admin/kelola-pengguna') ?>">Kembali</a>
    </div>
  </div>

  <div class="grid g-side" style="align-items:start">

    <!-- ================= KOLOM KIRI ================= -->
    <div>
      <!-- Identitas -->
      <div class="panel">
        <div class="person" style="align-items:center;margin-bottom:16px">
          <?php if ($fotoUrl): ?>
            <img src="<?= e($fotoUrl) ?>" alt="Foto <?= e($mhs['nama']) ?>" style="width:64px;height:64px;border-radius:50%;object-fit:cover">
          <?php else: ?>
            <span style="display:inline-flex;align-items:center;justify-content:center;background:var(--blue-soft);color:var(--navy);font-weight:700;width:64px;height:64px;border-radius:50%;font-size:1.2rem"><?= e(inisial($mhs['nama'])) ?></span>
          <?php endif; ?>
          <div>
            <b style="font-size:1.1rem"><?= e($mhs['nama']) ?></b>
            <small>NIM <?= e($mhs['nim']) ?><?= $mhs['ipk'] ? ' &middot; IPK ' . e($mhs['ipk']) : '' ?></small>
          </div>
          <span style="margin-left:auto"><?= badgeHtml(labelStatusAkun($mhs['status_akun'])) ?></span>
        </div>

        <dl class="dl">
          <dt>Email</dt><dd><?= e($mhs['email']) ?></dd>
          <dt>WhatsApp</dt><dd><?= e($mhs['no_whatsapp']) ?></dd>
          <dt>Jurusan</dt><dd><?= e($mhs['nama_jurusan']) ?></dd>
          <dt>Program studi</dt><dd><?= e($mhs['jenjang'] . ' ' . $mhs['nama_prodi']) ?></dd>
          <dt>Angkatan</dt><dd><?= e((string) $mhs['angkatan']) ?></dd>
          <dt>Status</dt><dd><?= $mhs['status_mahasiswa'] === 'alumni' ? 'Alumni, lulus ' . e((string) $mhs['tahun_lulus']) : 'Mahasiswa aktif' ?></dd>
          <dt>Domisili</dt><dd><?= e($mhs['domisili'] ?: '-') ?></dd>
          <?php if (!empty($mhs['tentang'])): ?><dt>Tentang</dt><dd><?= nl2br(e($mhs['tentang'])) ?></dd><?php endif; ?>
        </dl>
      </div>

      <!-- Status karier -->
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

      <!-- Pendidikan -->
      <div class="panel">
        <h3>Pendidikan</h3>
        <?php if (!$pendidikan): ?><p class="muted">Belum diisi.</p><?php endif; ?>
        <?php foreach ($pendidikan as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="graduation"></span>
            <div class="grow"><b><?= e($it['judul']) ?></b>
              <div class="muted"><?= e($it['instansi']) ?><?= $it['mulai'] ? ', ' . e(tanggalIndo($it['mulai'])) . ' sampai ' . ($it['selesai'] ? e(tanggalIndo($it['selesai'])) : 'sekarang') : '' ?></div>
              <?php if ($it['deskripsi']): ?><p style="margin:6px 0 0"><?= nl2br(e($it['deskripsi'])) ?></p><?php endif; ?>
            </div>
          </div>
        <?php endforeach; ?>
      </div>

      <!-- Pengalaman -->
      <div class="panel">
        <h3>Pengalaman</h3>
        <?php if (!$pengalaman): ?><p class="muted">Belum diisi.</p><?php endif; ?>
        <?php foreach ($pengalaman as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="briefcase"></span>
            <div class="grow"><b><?= e($it['judul']) ?></b>
              <div class="muted"><?= e($it['instansi']) ?><?= $it['mulai'] ? ', ' . e(tanggalIndo($it['mulai'])) . ' sampai ' . ($it['selesai'] ? e(tanggalIndo($it['selesai'])) : 'sekarang') : '' ?></div>
              <?php if ($it['deskripsi']): ?><p style="margin:6px 0 0"><?= nl2br(e($it['deskripsi'])) ?></p><?php endif; ?>
            </div>
          </div>
        <?php endforeach; ?>
      </div>

      <!-- Sertifikat -->
      <div class="panel">
        <h3>Sertifikat</h3>
        <?php if (!$sertifikat): ?><p class="muted">Belum diisi.</p><?php endif; ?>
        <?php foreach ($sertifikat as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="shield"></span>
            <div class="grow"><b><?= e($it['judul']) ?></b><div class="muted"><?= e($it['instansi'] ?: '') ?><?= $it['mulai'] ? ' &middot; ' . e(tanggalIndo($it['mulai'])) : '' ?></div></div>
            <?php if ($it['file']): ?><a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=portofolio&file=' . urlencode($it['file'])) ?>" target="_blank">Lihat file</a><?php endif; ?>
          </div>
        <?php endforeach; ?>
      </div>

      <!-- Riwayat lamaran -->
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

    <!-- ================= KOLOM KANAN ================= -->
    <div>
      <div class="panel">
        <h3>Kelengkapan profil</h3>
        <div style="display:flex;justify-content:space-between;font-size:.9rem;margin-bottom:6px">
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
            <span class="muted" style="font-size:.85rem">Berkas tidak ditemukan</span>
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
              <?php if ($it['tautan']): ?><div><a href="<?= e($it['tautan']) ?>" target="_blank" rel="noopener"><?= e($it['tautan']) ?></a></div><?php endif; ?>
            </div>
          </div>
        <?php endforeach; ?>
      </div>
    </div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
