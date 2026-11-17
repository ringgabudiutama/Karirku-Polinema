<?php
// ===== FRONTEND · MAHASISWA · Form kirim lamaran =====================
$page_title = 'Kirim Lamaran';
$active_menu = 'lowongan';
require __DIR__ . '/../layouts/app-header.php';
$logoUrl = !empty($lowongan['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($lowongan['logo'])) : null;
$ktmAda = !empty($mahasiswa['file_ktm']);
$labelKtm = ($mahasiswa['status_mahasiswa'] ?? 'aktif') === 'alumni' ? 'Ijazah atau SKL' : 'KTM';
$suratAda = !empty($mahasiswa['file_surat_pengantar']);
$cvAda = !empty($mahasiswa['file_cv']);
// Auto input: contoh pesan yang sudah memakai nama, prodi, posisi, dan perusahaan.
$skillTeks = isset($skill) && $skill ? implode(', ', array_slice(array_column($skill, 'nama'), 0, 4)) : '';
$prodiTeks = trim(($mahasiswa['jenjang'] ?? '') . ' ' . ($mahasiswa['nama_prodi'] ?? ''));
$templatePesan = [
    'Perkenalkan, saya ' . ($mahasiswa['nama'] ?? '') . ($prodiTeks ? ', ' . (($mahasiswa['status_mahasiswa'] ?? '') === 'alumni' ? 'alumni ' : 'mahasiswa ') . $prodiTeks . ' Politeknik Negeri Malang' : '')
        . '. Saya tertarik melamar posisi ' . $lowongan['posisi'] . ' di ' . $lowongan['nama_perusahaan'] . ' dan siap mengikuti seluruh proses seleksi.',
    $skillTeks ? 'Saya memiliki kemampuan ' . $skillTeks . ' yang relevan dengan posisi ' . $lowongan['posisi'] . '. Terima kasih atas kesempatannya.' : null,
    'Saya bersedia ditempatkan di ' . $lowongan['lokasi'] . ' dan dapat mulai bekerja sesuai kebutuhan perusahaan.',
];
$templatePesan = array_values(array_filter($templatePesan));
$domisili = implode(', ', array_filter([$mahasiswa['alamat'] ?? null, $mahasiswa['domisili'] ?? null, $mahasiswa['provinsi'] ?? null]));
?>
<section class="view active">
  <div class="kepala-halaman">
    <div class="crumb"><a href="<?= url('lowongan/detail/' . $lowongan['id']) ?>"><?= e($lowongan['posisi']) ?></a> <span>/</span> <span>Kirim lamaran</span></div>
    <?= tombolKembali('lowongan/detail/' . $lowongan['id']) ?>
  </div>

  <div class="panel max-w-640 m-0 mx-auto">
    <div class="person mb-16">
      <?php if ($logoUrl): ?><img class="avatar" src="<?= e($logoUrl) ?>" alt=""><?php else: ?><span class="avatar avatar-inisial"><?= e(inisial($lowongan['nama_perusahaan'])) ?></span><?php endif; ?>
      <div><b><?= e($lowongan['posisi']) ?></b><small><?= e($lowongan['nama_perusahaan']) ?> &middot; batas <?= tanggalIndo($lowongan['batas_lamaran']) ?></small></div>
    </div>

    <?php if (!$ktmAda): ?>
      <div class="alert alert-bad">
        <span data-ic="alert"></span>
        <span><b><?= e($labelKtm) ?> belum ada di profilmu.</b><br>
        Lamaran belum bisa dikirim sebelum dokumen ini diunggah.
        <a href="<?= url('mahasiswa/profil') ?>"><b>Unggah sekarang di Profil Karier</b></a>, lalu kembali ke halaman ini.</span>
      </div>
    <?php endif; ?>

    <!-- ===== Revisi E: data pelamar terisi otomatis dari profil ===== -->
    <div class="kotak-data">
      <div class="d-flex justify-between items-center flex-wrap gap-8 mb-8">
        <b>Data pelamar (otomatis dari profil)</b>
        <a class="btn btn-sm btn-outline" href="<?= url('mahasiswa/profil') ?>"><span data-ic="edit"></span>Ubah di profil</a>
      </div>
      <dl class="dl dl-ringkas">
        <dt>Nama</dt><dd><?= e($mahasiswa['nama']) ?></dd>
        <dt>NIM</dt><dd><?= e($mahasiswa['nim']) ?></dd>
        <dt>Email</dt><dd><?= e($mahasiswa['email']) ?></dd>
        <dt>WhatsApp</dt><dd><?= e($mahasiswa['no_whatsapp']) ?></dd>
        <dt>Program studi</dt><dd><?= e($mahasiswa['jenjang'] . ' ' . $mahasiswa['nama_prodi']) ?>, <?= e($mahasiswa['nama_jurusan']) ?></dd>
        <dt>Angkatan</dt><dd><?= (int) $mahasiswa['angkatan'] ?><?= $mahasiswa['status_mahasiswa'] === 'alumni' ? ' (alumni, lulus ' . e((string) $mahasiswa['tahun_lulus']) . ')' : '' ?></dd>
        <dt>IPK</dt><dd><?= $mahasiswa['ipk'] !== null && $mahasiswa['ipk'] !== '' ? e((string) $mahasiswa['ipk']) : '<span class="muted">belum diisi</span>' ?></dd>
        <dt>Domisili</dt><dd><?= $domisili !== '' ? e($domisili) : '<span class="muted">belum diisi</span> <a href="' . url('mahasiswa/pengaturan-akun#alamat') . '">isi alamat</a>' ?></dd>
        <dt>Skill</dt><dd><?= $skill ? e(implode(', ', array_column($skill, 'nama'))) : '<span class="muted">belum diisi</span>' ?></dd>
        <dt><?= e($labelKtm) ?></dt><dd><?= $ktmAda ? '<span class="text-ok">Sudah tersimpan</span>' : '<span class="text-bad">Belum diunggah</span>' ?></dd>
        <dt>CV unggahan</dt><dd><?= $cvAda ? '<span class="text-ok">Sudah tersimpan</span>' : '<span class="muted">Belum ada (CV otomatis tetap bisa dipakai)</span>' ?></dd>
      </dl>
      <p class="hint m-0">Data di atas disalin apa adanya ke lamaran saat dikirim. Bila ada yang salah, perbaiki dulu di profil.</p>
    </div>

    <!-- ===== Form lamaran ===== -->
    <form method="post" action="<?= url('lamaran/kirim/' . $lowongan['id']) ?>" enctype="multipart/form-data" id="formLamar" data-draft="lamaran-<?= (int) $lowongan['id'] ?>" data-jaga>
      <?= csrfField() ?>

      <p class="fw-600 mb-8">Pilih CV yang dikirim</p>
      <?php $jenisCv = (string) old('jenis_cv', 'generate'); ?>
      <label class="radio-card"><input type="radio" name="jenis_cv" value="generate" <?= $jenisCv !== 'unggah' || !$cvAda ? 'checked' : '' ?>><span><b>CV otomatis</b><br><span class="muted fs-88">Dibuat dari profil terbaru. <a href="<?= url('mahasiswa/generate-cv') ?>" target="_blank" rel="noopener">Lihat pratinjau</a></span></span></label>
      <label class="radio-card <?= !$cvAda ? 'disabled' : '' ?>">
        <input type="radio" name="jenis_cv" value="unggah" <?= !$cvAda ? 'disabled' : '' ?> <?= $jenisCv === 'unggah' && $cvAda ? 'checked' : '' ?>>
        <span><b>CV unggahan</b><br><span class="muted fs-88"><?= $cvAda ? 'CV yang sudah kamu unggah di profil' : 'Belum ada CV diunggah, lengkapi di Profil Karier dulu' ?></span></span>
      </label>

      <p class="fw-600 m-0 mt-16 mb-8">Dokumen pendukung</p>
      <div class="row2">
        <div class="field">
          <label><?= e($labelKtm) ?> <span class="muted">(otomatis dari profil)</span></label>
          <?php if ($ktmAda): ?>
            <div class="upload upload-ok"><span data-ic="checkc"></span><div class="name">Sudah tersimpan di profil</div><div class="hint">Ikut terkirim otomatis</div></div>
          <?php else: ?>
            <a class="upload upload-bad" href="<?= url('mahasiswa/profil') ?>"><span data-ic="alert"></span><div class="name text-bad">Belum diunggah</div><div class="hint">Klik untuk mengunggah di Profil Karier</div></a>
          <?php endif; ?>
        </div>
        <div class="field">
          <label for="fileSurat">Surat pengantar <?= $suratAda ? '<span class="muted">(opsional)</span>' : '<span class="text-bad">*</span>' ?></label>
          <div class="pratinjau" id="pratinjauSurat"></div>
          <label class="upload" id="kotakSurat">
            <input type="file" name="file_surat_pengantar" accept="application/pdf,.pdf" id="fileSurat"
                   data-pratinjau="pratinjauSurat" data-maks-kb="2048" data-tipe="pdf" <?= $suratAda ? '' : 'required' ?>>
            <span data-ic="upload"></span>
            <div><b><?= $suratAda ? 'Ganti berkas (boleh dikosongkan)' : 'Pilih berkas PDF' ?></b></div>
            <div class="hint"><?= $suratAda ? 'Dibiarkan kosong berarti memakai surat pengantar dari Profil Karier' : 'Format PDF, maksimal 2 MB' ?></div>
          </label>
          <div class="pratinjau-pesan"></div>
          <?php if (!$suratAda): ?>
            <small class="muted">Sudah punya surat pengantar yang dipakai berulang? Simpan sekali di
              <a href="<?= url('mahasiswa/profil') ?>">Profil Karier</a>, nanti terpakai otomatis.</small>
          <?php endif; ?>
        </div>
      </div>

      <div class="field"><label for="cover">Pesan untuk perusahaan <span class="muted">(opsional)</span></label>
        <div class="chips-alasan" data-target="cover"><small class="muted">Isi cepat:</small><?php foreach ($templatePesan as $tp): ?><button type="button" data-alasan="<?= e($tp) ?>"><?= e(ringkas($tp, 55)) ?></button><?php endforeach; ?></div><textarea class="input" id="cover" name="catatan_pelamar" rows="3" maxlength="1000" placeholder="Pesan singkat untuk perusahaan"><?= e((string) old('catatan_pelamar', '')) ?></textarea></div>

      <label class="check-inline mb-12"><input type="checkbox" name="data_benar" value="1" required <?= old('data_benar') ? 'checked' : '' ?>>
        Saya menyatakan data profil di atas benar dan bersedia data, CV, KTM, dan surat pengantar dikirim ke <?= e($lowongan['nama_perusahaan']) ?> serta tercatat di Career Center.</label>

      <div class="d-flex flex-wrap justify-end items-center gap-10 mt-16">
        <?php if (!$ktmAda): ?>
          <small class="muted mr-auto">Lengkapi <?= e($labelKtm) ?> dulu untuk mengaktifkan tombol kirim.</small>
        <?php endif; ?>
        <a class="btn btn-outline" href="<?= url('lowongan/detail/' . $lowongan['id']) ?>" data-kembali>Batal</a>
        <button class="btn btn-primary" type="submit" data-proses="Mengirim..." <?= $ktmAda ? '' : 'disabled' ?>>Kirim lamaran</button>
      </div>
      <p class="draft-status" data-draft-status></p>
    </form>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
