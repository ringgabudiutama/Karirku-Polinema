<?php
// ===== FRONTEND · ADMIN · Detail pendaftar & keputusan ===============
$page_title = 'Detail Pendaftar';
$active_menu = 'persetujuan';
require __DIR__ . '/../layouts/app-header.php';

$nama = $pengguna['role'] === 'mahasiswa' ? ($profil['nama'] ?? '-') : ($profil['nama_perusahaan'] ?? '-');
$sub = $pengguna['role'] === 'mahasiswa'
    ? ($profil['jenjang'] . ' ' . $profil['nama_prodi'] . ', ' . ($profil['status_mahasiswa'] === 'alumni' ? 'alumni ' . $profil['tahun_lulus'] : 'angkatan ' . $profil['angkatan']))
    : ($profil['bidang_usaha'] . ', ' . $profil['kota']);

$dataDiri = $pengguna['role'] === 'mahasiswa'
    ? [
        ['NIM', $profil['nim']], ['Email', $pengguna['email']], ['WhatsApp', $profil['no_whatsapp']],
        ['Jurusan', $profil['nama_jurusan']], ['Program studi', $profil['jenjang'] . ' ' . $profil['nama_prodi']],
        ['Angkatan', (string) $profil['angkatan']], ['Status', $profil['status_mahasiswa'] === 'alumni' ? 'Alumni' : 'Mahasiswa aktif'],
        ['Tahun lulus', $profil['tahun_lulus'] ? (string) $profil['tahun_lulus'] : '-'],
    ]
    : [
        ['Email', $pengguna['email']], ['Bidang usaha', $profil['bidang_usaha']], ['Jenis perusahaan', $profil['jenis_perusahaan']],
        ['Alamat', $profil['alamat'] . ', ' . $profil['kota']], ['Website', $profil['website'] ?: '-'],
        ['Nama PIC', $profil['nama_pic']], ['Jabatan PIC', $profil['jabatan_pic'] ?: '-'], ['WhatsApp PIC', $profil['whatsapp_pic']],
        ['Bukan outsourcing', $profil['bukan_outsourcing'] ? 'Dicentang oleh pendaftar' : '-'],
    ];

$labelDokumen = ['ktm' => 'KTM', 'ijazah' => 'Ijazah/SKL', 'nib' => 'NIB', 'npwp' => 'NPWP perusahaan', 'akta' => 'Akta pendirian', 'domisili' => 'Surat keterangan domisili', 'logo' => 'Logo perusahaan'];
$labelKeputusan = ['disetujui' => 'Disetujui', 'perbaikan' => 'Minta perbaikan', 'ditolak' => 'Ditolak', 'nonaktif' => 'Dinonaktifkan', 'aktif' => 'Diaktifkan kembali'];
?>
<section class="view active">
  <div class="kepala-halaman">
    <div class="crumb"><a href="<?= url('admin/persetujuan') ?>">Persetujuan Akun</a> <span>/</span> <span><?= e($nama) ?></span></div>
    <?= tombolKembali('admin/persetujuan') ?>
  </div>
  <!-- ===== Kolom kiri: data & dokumen ===== -->
  <div class="grid g-side items-start">
    <div>
      <div class="panel">
        <div class="person mb-14">
          <span class="avatar avatar-inisial avatar-52"><?= e(inisial($nama)) ?></span>
          <div><b class="fs-115"><?= e($nama) ?></b><small><?= e($sub) ?></small></div>
        </div>
        <?= badgeHtml(labelStatusAkun($pengguna['status_akun'])) ?>
        <span class="muted fs-88 ml-8">Mendaftar <?= tanggalIndo($pengguna['dibuat_pada']) ?>, no. <?= e($pengguna['no_pendaftaran'] ?? '-') ?></span>
      </div>

      <div class="panel"><h3>Data pendaftaran</h3>
        <dl class="dl">
          <?php foreach ($dataDiri as [$k, $v]): ?><dt><?= e($k) ?></dt><dd><?= e($v) ?></dd><?php endforeach; ?>
        </dl>
      </div>

      <div class="panel"><h3>Dokumen</h3>
        <?php if (empty($dokumen)): ?><p class="muted">Belum ada dokumen diunggah.</p><?php endif; ?>
        <?php foreach ($dokumen as $d): ?>
          <div class="list-item"><span class="list-ic" data-ic="file"></span>
            <div class="grow"><b><?= e($labelDokumen[$d['tipe']] ?? strtoupper($d['tipe'])) ?></b><div class="muted"><?= number_format($d['ukuran_kb']) ?> KB, diunggah <?= tanggalIndo($d['diunggah_pada']) ?></div></div>
            <a class="btn btn-sm btn-outline" href="<?= e(url('unduh.php?tipe=' . urlencode($d['tipe']) . '&file=' . urlencode($d['file']))) ?>" target="_blank" rel="noopener">Lihat</a>
          </div>
        <?php endforeach; ?>
      </div>

      <?php if ($riwayat): ?>
      <div class="panel"><h3>Riwayat keputusan</h3>
        <ul class="activity">
          <?php foreach ($riwayat as $r): ?>
            <li><span class="list-ic" data-ic="<?= in_array($r['keputusan'], ['disetujui', 'aktif']) ? 'checkc' : 'x' ?>"></span><span><b><?= e($labelKeputusan[$r['keputusan']] ?? $r['keputusan']) ?></b><?php if ($r['catatan']): ?><br><span class="fs-90"><?= nl2br(e($r['catatan'])) ?></span><?php endif; ?><small>oleh <?= e($r['nama_admin']) ?>, <?= tanggalWaktuIndo($r['tanggal']) ?></small></span></li>
          <?php endforeach; ?>
        </ul>
      </div>
      <?php endif; ?>
    </div>

    <!-- ===== Kolom kanan: keputusan ===== -->
    <div class="sticky">
      <div class="panel">
        <h3>Keputusan</h3>
        <?php if ($pengguna['status_akun'] !== 'menunggu'): ?>
          <!-- Bug #8: keputusan hanya untuk akun yang masih menunggu, supaya tidak tercatat/terkirim dua kali. -->
          <div class="alert alert-info"><span data-ic="info"></span><span>Akun ini sudah berstatus <b><?= e(labelStatusAkun($pengguna['status_akun'])[0]) ?></b>.
            <?= $pengguna['status_akun'] === 'perbaikan' ? 'Formulir keputusan muncul lagi setelah pendaftar mengirim perbaikan.' : '' ?>
            <?= in_array($pengguna['status_akun'], ['aktif', 'nonaktif'], true) ? 'Untuk menonaktifkan, mengaktifkan kembali, atau reset kata sandi, gunakan menu Kelola Pengguna.' : '' ?></span></div>
        <?php else: ?>
        <form method="post" action="<?= url('admin/putuskan/' . $pengguna['id']) ?>" id="formPutuskan" data-jaga>
          <?= csrfField() ?>
          <div class="field"><label for="catatanInput">Alasan / catatan <span class="muted">(wajib untuk Minta Perbaikan dan Tolak, min. 10 karakter)</span></label>
            <?= chipsAlasan('daftar_alasan_penolakan', 'catatanInput') ?>
            <textarea class="input" name="catatan" id="catatanInput" rows="4" maxlength="500" placeholder="Jelaskan alasan atau bagian yang perlu diperbaiki"><?= e((string) old('catatan', '')) ?></textarea>
            <div class="hint">Alasan dikirim ke pendaftar lewat notifikasi dan email, serta tersimpan di riwayat.</div></div>
          <div class="d-grid gap-8">
            <button class="btn btn-ok" type="submit" name="keputusan" value="disetujui" data-proses="Menyimpan..." data-konfirmasi="Setujui akun ini? Pendaftar langsung bisa memakai semua fitur.">Setujui</button>
            <button class="btn btn-warn" type="submit" name="keputusan" value="perbaikan" data-wajib-alasan="catatanInput" data-proses="Menyimpan...">Minta perbaikan</button>
            <button class="btn btn-outline btn-outline-bad" type="submit" name="keputusan" value="ditolak" data-wajib-alasan="catatanInput" data-proses="Menyimpan..." data-konfirmasi="Tolak pendaftaran ini secara final?">Tolak</button>
          </div>
          <p class="hint mt-8"><b>Minta perbaikan</b>: pendaftar bisa mengunggah ulang dokumen. <b>Tolak</b>: keputusan final.</p>
        </form>
        <?php endif; ?>
      </div>
    </div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
