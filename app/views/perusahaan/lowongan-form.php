<?php
/**
 * View: perusahaan/lowongan-form
 * Dipanggil oleh: LowonganController::formPasang($id = 0)
 * Variabel: $lowongan (null kalau pasang baru), $jurusanTerpilih, $bidang, $jurusan
 */
$edit = $lowongan !== null;
$page_title = $edit ? 'Edit Lowongan' : 'Pasang Lowongan';
$active_menu = 'lowongan';
require __DIR__ . '/../layouts/app-header.php';

$jenisPekerjaanOpsi = ['full_time' => 'Penuh waktu', 'part_time' => 'Paruh waktu', 'kontrak' => 'Kontrak', 'magang' => 'Magang', 'freelance' => 'Freelance'];
$sistemKerjaOpsi = ['wfo' => 'Di kantor (WFO)', 'hybrid' => 'Hybrid', 'wfh' => 'Jarak jauh (WFH)'];
$g = fn($k, $d = '') => $edit ? e((string) ($lowongan[$k] ?? $d)) : $d;
$pamfletUrl = $edit && !empty($lowongan['pamflet']) ? url('unduh.php?tipe=pamflet&file=' . urlencode($lowongan['pamflet'])) : null;
?>
<section class="view active">
  <div class="crumb"><a href="<?= url('perusahaan/lowongan') ?>">Lowongan Saya</a> <span>/</span> <span><?= $edit ? 'Edit lowongan' : 'Pasang lowongan' ?></span></div>
  <div class="page-head"><div><h1><?= $edit ? 'Edit lowongan' : 'Pasang lowongan' ?></h1><p>Isi data lowongan. Pamflet wajib diunggah sebelum lowongan bisa ditayangkan.</p></div></div>

  <form class="grid g-side" style="align-items:start" method="post" action="<?= url('lowongan/proses-pasang') ?>" enctype="multipart/form-data">
    <?= csrfField() ?>
    <input type="hidden" name="id" value="<?= $edit ? (int) $lowongan['id'] : '' ?>">

    <div class="panel">
      <div class="row2">
        <div class="field"><label>Posisi</label><input class="input" name="posisi" required placeholder="Misalnya Web Developer" value="<?= $g('posisi') ?>"></div>
        <div class="field"><label>Bidang</label>
          <select class="input" name="bidang_id" required>
            <?php foreach ($bidang as $b): ?><option value="<?= (int) $b['id'] ?>" <?= $edit && (int) $lowongan['bidang_id'] === (int) $b['id'] ? 'selected' : '' ?>><?= e($b['nama']) ?></option><?php endforeach; ?>
          </select>
        </div>
        <div class="field"><label>Jenis pekerjaan</label>
          <select class="input" name="jenis_pekerjaan">
            <?php foreach ($jenisPekerjaanOpsi as $k => $v): ?><option value="<?= $k ?>" <?= $g('jenis_pekerjaan') === $k ? 'selected' : '' ?>><?= e($v) ?></option><?php endforeach; ?>
          </select>
        </div>
        <div class="field"><label>Sistem kerja</label>
          <select class="input" name="sistem_kerja">
            <?php foreach ($sistemKerjaOpsi as $k => $v): ?><option value="<?= $k ?>" <?= $g('sistem_kerja') === $k ? 'selected' : '' ?>><?= e($v) ?></option><?php endforeach; ?>
          </select>
        </div>
        <div class="field"><label>Lokasi</label><input class="input" name="lokasi" required value="<?= $g('lokasi', 'Malang') ?>"></div>
        <div class="field"><label>Gaji <span class="muted">(opsional)</span></label><input class="input" name="gaji" placeholder="Rp5-7 juta" value="<?= $g('gaji') ?>"></div>
        <div class="field"><label>Kuota diterima</label><input class="input" type="number" name="kuota" min="1" required value="<?= $g('kuota', '1') ?>"><div class="hint">Lowongan otomatis ditutup saat kuota terpenuhi.</div></div>
        <div class="field"><label>Batas lamaran</label><input class="input" type="date" name="batas_lamaran" required value="<?= $g('batas_lamaran') ?>"></div>
      </div>
      <div class="field"><label>Jurusan sasaran</label>
        <div class="chips">
          <?php foreach ($jurusan as $j): $dicentang = in_array($j['id'], $jurusanTerpilih, true); ?>
            <label class="chip pickable"><input type="checkbox" name="jurusan_id[]" value="<?= (int) $j['id'] ?>" <?= $dicentang ? 'checked' : '' ?>><?= e($j['nama']) ?></label>
          <?php endforeach; ?>
        </div>
        <div class="hint">Dipakai Career Center saat meneruskan info ke admin jurusan. Kosongkan berarti semua jurusan.</div>
      </div>
      <div class="field"><label>Deskripsi pekerjaan</label><textarea class="input" name="deskripsi" rows="4" required placeholder="Tanggung jawab utama posisi ini"><?= $g('deskripsi') ?></textarea></div>
      <div class="field"><label>Kualifikasi</label><textarea class="input" name="kualifikasi" rows="4" required placeholder="Satu kualifikasi per baris"><?= $g('kualifikasi') ?></textarea></div>
      <div class="field"><label>Skill yang dibutuhkan <span class="muted">(opsional)</span></label><input class="input" name="skill_dibutuhkan" placeholder="Pisahkan dengan koma, misalnya PHP, Laravel, Git" value="<?= $g('skill_dibutuhkan') ?>"></div>
    </div>

    <div class="sticky">
      <div class="panel">
        <h3>Pamflet lowongan <?= $edit ? '' : '<span style="color:var(--bad)">*</span>' ?></h3>
        <p class="muted" style="font-size:.88rem">JPG atau PNG, maksimal 2 MB. Ukuran persegi atau 4:5 paling pas untuk WhatsApp dan Instagram.</p>
        <?php if ($pamfletUrl): ?><img src="<?= e($pamfletUrl) ?>" alt="Pamflet saat ini" style="border-radius:8px;margin-bottom:12px;border:1px solid var(--line);max-width:100%"><?php endif; ?>
        <label class="upload"><input type="file" name="pamflet" accept=".jpg,.jpeg,.png" <?= $edit ? '' : 'required' ?>><span data-ic="image"></span><div><b><?= $pamfletUrl ? 'Ganti pamflet' : 'Unggah pamflet' ?></b></div></label>
        <?php if (!$edit): ?><div class="alert alert-warn" style="margin-top:12px"><span data-ic="info"></span><span>Pamflet wajib diunggah sebelum lowongan bisa ditayangkan.</span></div><?php endif; ?>
        <button class="btn btn-primary" style="width:100%;margin-top:12px" type="submit"><?= $edit ? 'Simpan perubahan' : 'Tayangkan lowongan' ?></button>
        <a class="btn btn-link" href="<?= url('perusahaan/lowongan') ?>" style="width:100%;text-align:center;display:block">Batal</a>
      </div>
    </div>
  </form>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
