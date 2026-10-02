<?php
/**
 * View: admin/persetujuan-detail
 * Dipanggil oleh: AdminController::detailPendaftar($penggunaId)
 * Variabel: $pengguna, $profil, $dokumen, $riwayat
 */
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
  <div class="crumb"><a href="<?= url('admin/persetujuan') ?>">Persetujuan Akun</a> <span>/</span> <span><?= e($nama) ?></span></div>
  <div class="grid g-side" style="align-items:start">
    <div>
      <div class="panel">
        <div class="person" style="margin-bottom:14px">
          <span class="avatar" style="display:inline-flex;align-items:center;justify-content:center;background:var(--blue-soft);color:var(--navy);font-weight:700;width:52px;height:52px;border-radius:50%"><?= e(inisial($nama)) ?></span>
          <div><b style="font-size:1.15rem"><?= e($nama) ?></b><small><?= e($sub) ?></small></div>
        </div>
        <?= badgeHtml(labelStatusAkun($pengguna['status_akun'])) ?>
        <span class="muted" style="font-size:.88rem;margin-left:8px">Mendaftar <?= tanggalIndo($pengguna['dibuat_pada']) ?>, no. <?= e($pengguna['no_pendaftaran'] ?? '-') ?></span>
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
            <a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=' . e($d['tipe']) . '&file=' . e($d['file'])) ?>" target="_blank">Lihat</a>
          </div>
        <?php endforeach; ?>
      </div>

      <?php if ($riwayat): ?>
      <div class="panel"><h3>Riwayat keputusan</h3>
        <ul class="activity">
          <?php foreach ($riwayat as $r): ?>
            <li><span class="list-ic" data-ic="<?= in_array($r['keputusan'], ['disetujui', 'aktif']) ? 'checkc' : 'x' ?>"></span><span><b><?= e($labelKeputusan[$r['keputusan']] ?? $r['keputusan']) ?></b><?= e($r['catatan'] ?: '') ?><small>oleh <?= e($r['nama_admin']) ?>, <?= tanggalWaktuIndo($r['tanggal']) ?></small></span></li>
          <?php endforeach; ?>
        </ul>
      </div>
      <?php endif; ?>
    </div>

    <div class="sticky">
      <div class="panel">
        <h3>Keputusan</h3>
        <?php if ($pengguna['status_akun'] !== 'menunggu'): ?>
          <div class="alert alert-info"><span data-ic="info"></span><span>Akun ini sudah berstatus <?= e(labelStatusAkun($pengguna['status_akun'])[0]) ?>. Kamu tetap bisa mengubah keputusannya di bawah.</span></div>
        <?php endif; ?>
        <form method="post" action="<?= url('admin/putuskan/' . $pengguna['id']) ?>" id="formPutuskan">
          <?= csrfField() ?>
          <div class="field"><label>Catatan <span class="muted" id="catWajib">(wajib untuk Minta Perbaikan/Tolak)</span></label><textarea class="input" name="catatan" id="catatanInput" rows="3" placeholder="Jelaskan alasan atau bagian yang perlu diperbaiki"></textarea></div>
          <div style="display:grid;gap:8px">
            <button class="btn btn-ok" type="submit" name="keputusan" value="disetujui">Setujui</button>
            <button class="btn btn-warn" type="submit" name="keputusan" value="perbaikan" onclick="return wajibCatatan()">Minta perbaikan</button>
            <button class="btn btn-outline" style="color:var(--bad);border-color:var(--bad)" type="submit" name="keputusan" value="ditolak" onclick="return wajibCatatan()">Tolak</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</section>
<script>
function wajibCatatan(){ const c=document.getElementById('catatanInput'); if(!c.value.trim()){ alert('Catatan wajib diisi untuk keputusan ini.'); c.focus(); return false; } return true; }
</script>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
