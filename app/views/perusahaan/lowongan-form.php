<?php
// ===== FRONTEND · PERUSAHAAN · Form pasang / edit lowongan ===========
$edit = $lowongan !== null;
$page_title = $edit ? 'Edit Lowongan' : 'Pasang Lowongan';
$active_menu = 'lowongan';
require __DIR__ . '/../layouts/app-header.php';

$jenisPekerjaanOpsi = ['full_time' => 'Penuh waktu', 'part_time' => 'Paruh waktu', 'kontrak' => 'Kontrak', 'magang' => 'Magang', 'freelance' => 'Freelance'];
$sistemKerjaOpsi = ['wfo' => 'Di kantor (WFO)', 'hybrid' => 'Hybrid', 'wfh' => 'Jarak jauh (WFH)'];
// Revisi G: nilai dari isian sebelumnya (bila validasi gagal) diutamakan.
$sumberIsi = $edit ? $lowongan : ($bawaan ?? []);   // lowongan baru: isian otomatis dari profil / lowongan lama
$g = fn($k, $d = '') => e((string) old($k, $sumberIsi[$k] ?? $d));
$status = $lowongan['status'] ?? null;
$tayang = in_array($status, Lowongan::STATUS_TAYANG, true);
$draftKey = 'lowongan-' . ($edit ? (int) $lowongan['id'] : 'baru');
?>
<section class="view active">
  <div class="kepala-halaman">
    <div class="crumb"><a href="<?= url('perusahaan/lowongan') ?>">Lowongan Saya</a> <span>/</span> <span><?= $edit ? 'Edit lowongan' : 'Pasang lowongan' ?></span></div>
    <?= tombolKembali('perusahaan/lowongan') ?>
  </div>
  <div class="page-head"><div><h1><?= $edit ? 'Edit lowongan' : 'Pasang lowongan' ?> <?= $edit ? badgeHtml(labelStatusLowongan($status)) : '' ?></h1>
    <p>Lowongan ditinjau Admin Career Center sebelum tayang. Anda akan mendapat notifikasi dan email setelah ditinjau.</p></div></div>

  <?php if ($status === 'revisi' && !empty($lowongan['catatan_admin'])): ?>
    <div class="alert alert-warn"><span data-ic="alert"></span><span><b>Admin meminta revisi:</b> <?= nl2br(e($lowongan['catatan_admin'])) ?><br>Perbaiki bagian tersebut lalu tekan <b>Ajukan ulang</b>.</span></div>
  <?php elseif ($tayang): ?>
    <div class="alert alert-info"><span data-ic="info"></span><span>Lowongan ini sedang tayang. Bila Anda mengubah <b>isi</b> lowongan (posisi, deskripsi, kualifikasi, kuota, tanggal, pamflet, dan lainnya), lowongan akan disembunyikan sementara sampai disetujui ulang Admin. Untuk sekadar menambah tanggal atau kuota, pakai tombol <b>Perpanjang</b> di Lowongan Saya (tanpa persetujuan ulang).</span></div>
  <?php elseif ($status === 'menunggu'): ?>
    <div class="alert alert-info"><span data-ic="hourglass"></span><span>Lowongan sedang menunggu persetujuan Admin. Perubahan yang Anda simpan akan ikut ditinjau.</span></div>
  <?php endif; ?>

  <?php if (!$edit && !empty($daftarSalin)): ?>
    <form class="panel salin-lowongan" method="get" action="<?= url('lowongan/form-pasang') ?>">
      <label for="salinDari"><span data-ic="copy"></span> <b>Isi otomatis dari lowongan sebelumnya</b> <span class="muted fs-88">(semua isian disalin kecuali pamflet dan tanggal)</span></label>
      <div class="d-flex gap-8 flex-wrap">
        <select class="input grow" id="salinDari" name="salin">
          <option value="">Mulai dari kosong (diisi dari profil perusahaan)</option>
          <?php foreach ($daftarSalin as $ds): ?><option value="<?= (int) $ds['id'] ?>" <?= (int) ($_GET['salin'] ?? 0) === (int) $ds['id'] ? 'selected' : '' ?>><?= e($ds['posisi']) ?> · <?= e(labelStatusLowongan($ds['status'])[0]) ?> · <?= tanggalIndo($ds['dibuat_pada']) ?></option><?php endforeach; ?>
        </select>
        <button class="btn btn-outline" type="submit">Pakai</button>
      </div>
      <?php if (!empty($bawaan['_salin'])): ?><p class="hint m-0">Disalin dari “<?= e($bawaan['_salin']) ?>”. Periksa lalu ganti yang perlu, pilih pamflet, dan ajukan.</p><?php else: ?><p class="hint m-0">Lokasi, bidang, dan batas lamaran (30 hari) sudah diisi otomatis dari profil perusahaan.</p><?php endif; ?>
    </form>
  <?php endif; ?>

  <form class="grid g-side items-start" method="post" action="<?= url('lowongan/proses-pasang') ?>" enctype="multipart/form-data" data-draft="<?= e($draftKey) ?>" data-jaga novalidate>
    <?= csrfField() ?>
    <input type="hidden" name="id" value="<?= $edit ? (int) $lowongan['id'] : '' ?>">

    <div class="panel">
      <div class="row2">
        <div class="field"><label for="fPosisi">Posisi <span class="text-bad">*</span></label><input class="input" id="fPosisi" name="posisi" required maxlength="255" placeholder="Misalnya Web Developer" value="<?= $g('posisi') ?>"></div>
        <div class="field"><label for="fBidang">Bidang <span class="text-bad">*</span></label>
          <select class="input" id="fBidang" name="bidang_id" required>
            <option value="">Pilih bidang</option>
            <?php foreach ($bidang as $b): ?><option value="<?= (int) $b['id'] ?>" <?= (string) old('bidang_id', $sumberIsi['bidang_id'] ?? '') === (string) $b['id'] ? 'selected' : '' ?>><?= e($b['nama']) ?></option><?php endforeach; ?>
          </select>
        </div>
        <div class="field"><label for="fJenis">Jenis pekerjaan</label>
          <select class="input" id="fJenis" name="jenis_pekerjaan" required>
            <?php foreach ($jenisPekerjaanOpsi as $k => $v): ?><option value="<?= $k ?>" <?= $g('jenis_pekerjaan') === $k ? 'selected' : '' ?>><?= e($v) ?></option><?php endforeach; ?>
          </select>
        </div>
        <div class="field"><label for="fSistem">Sistem kerja</label>
          <select class="input" id="fSistem" name="sistem_kerja" required>
            <?php foreach ($sistemKerjaOpsi as $k => $v): ?><option value="<?= $k ?>" <?= $g('sistem_kerja') === $k ? 'selected' : '' ?>><?= e($v) ?></option><?php endforeach; ?>
          </select>
        </div>
        <div class="field"><label for="fLokasi">Lokasi <span class="text-bad">*</span></label><input class="input" id="fLokasi" name="lokasi" required maxlength="100" value="<?= $g('lokasi', 'Malang') ?>"></div>
        <div class="field"><label for="fGaji">Gaji <span class="muted">(opsional)</span></label><input class="input" id="fGaji" name="gaji" maxlength="100" placeholder="Rp5-7 juta" value="<?= $g('gaji') ?>"></div>
        <div class="field"><label for="fKuota">Kuota diterima <span class="text-bad">*</span></label><input class="input" id="fKuota" type="number" name="kuota" min="<?= max(1, (int) ($lowongan['terisi'] ?? 0)) ?>" max="1000" required value="<?= $g('kuota', '1') ?>"><div class="hint">Lowongan otomatis ditutup saat kuota terpenuhi.</div></div>
        <div class="field"><label for="fBatas">Batas lamaran <span class="text-bad">*</span></label><input class="input" id="fBatas" type="date" name="batas_lamaran" required <?= $edit ? '' : 'min="' . e(date('Y-m-d')) . '"' ?> value="<?= $g('batas_lamaran') ?>"></div>
      </div>
      <div class="field"><label>Jurusan sasaran <span class="text-bad">*</span></label>
        <div class="chips">
          <?php foreach ($jurusan as $j): $dicentang = in_array((int) $j['id'], $jurusanTerpilih, true); ?>
            <label class="chip pickable"><input type="checkbox" name="jurusan_id[]" value="<?= (int) $j['id'] ?>" <?= $dicentang ? 'checked' : '' ?>><?= e($j['nama']) ?></label>
          <?php endforeach; ?>
        </div>
        <div class="hint">Pilih minimal satu jurusan. Centang semua bila lowongan terbuka untuk semua jurusan. Dipakai Career Center saat meneruskan info ke admin jurusan.</div>
      </div>
      <div class="field"><label for="fDesk">Deskripsi pekerjaan <span class="text-bad">*</span></label><textarea class="input" id="fDesk" name="deskripsi" rows="4" required placeholder="Tanggung jawab utama posisi ini"><?= $g('deskripsi') ?></textarea></div>
      <div class="field"><label for="fKual">Kualifikasi <span class="text-bad">*</span></label><textarea class="input" id="fKual" name="kualifikasi" rows="4" required placeholder="Satu kualifikasi per baris"><?= $g('kualifikasi') ?></textarea></div>
      <div class="field"><label for="fSkill">Skill yang dibutuhkan <span class="muted">(opsional)</span></label><input class="input" id="fSkill" name="skill_dibutuhkan" maxlength="500" placeholder="Pisahkan dengan koma, misalnya PHP, Laravel, Git" value="<?= $g('skill_dibutuhkan') ?>"></div>
    </div>

    <!-- ===== Kolom kanan: pamflet (revisi C) & simpan ===== -->
    <div class="sticky">
      <div class="panel">
        <h3>Pamflet lowongan <?= $edit ? '' : '<span class="text-bad">*</span>' ?></h3>
        <p class="muted fs-88">JPG, PNG, atau PDF, maksimal <?= (int) round($maksKb / 1024) ?> MB. Ukuran persegi atau 4:5 paling pas untuk WhatsApp dan Instagram.</p>
        <?php if ($edit && !empty($lowongan['pamflet'])): ?>
          <div class="pamflet-lama" data-pamflet-lama>
            <span class="pratinjau-label">Pamflet saat ini</span>
            <?= pamfletHtml($lowongan['pamflet'], 'besar', 'Pamflet saat ini') ?>
          </div>
        <?php endif; ?>
        <div class="pratinjau" id="pratinjauPamflet" aria-live="polite"></div>
        <label class="upload"><input type="file" name="pamflet" id="inputPamflet" accept=".jpg,.jpeg,.png,.pdf,image/jpeg,image/png,application/pdf"
               data-pratinjau="pratinjauPamflet" data-maks-kb="<?= (int) $maksKb ?>" data-tipe="jpg,jpeg,png,pdf" <?= $edit ? '' : 'required' ?>>
          <span data-ic="image"></span><div><b><?= $edit ? 'Ganti pamflet' : 'Pilih pamflet' ?></b><small class="d-block muted">Pratinjau muncul sebelum disimpan</small></div></label>
        <div class="pratinjau-pesan" id="pesanPamflet"></div>
        <?php if ($edit): ?><p class="hint">Bila tidak memilih file baru, pamflet lama tetap dipakai.</p><?php endif; ?>
        <button class="btn btn-primary w-100 mt-12" type="submit" data-proses="Menyimpan...">
          <?= !$edit ? 'Ajukan lowongan' : ($status === 'revisi' ? 'Ajukan ulang' : 'Simpan perubahan') ?></button>
        <a class="btn btn-link d-block w-100 text-center" href="<?= url('perusahaan/lowongan') ?>" data-kembali>Batal</a>
        <p class="draft-status" data-draft-status></p>
      </div>
      <?php if ($edit): ?>
      <div class="panel mt-16">
        <h3>Riwayat status</h3>
        <?= riwayatHtml($riwayat) ?>
      </div>
      <?php endif; ?>
    </div>
  </form>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
