<?php
/**
 * View: mahasiswa/lamaran-form
 * Dipanggil oleh: LamaranController::kirim($lowonganId) — GET
 * Variabel: $lowongan, $mahasiswa
 */
$page_title = 'Kirim Lamaran';
$active_menu = 'lowongan';
require __DIR__ . '/../layouts/app-header.php';
$logoUrl = !empty($lowongan['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($lowongan['logo'])) : null;
?>
<section class="view active">
  <div class="crumb"><a href="<?= url('lowongan/detail/' . $lowongan['id']) ?>"><?= e($lowongan['posisi']) ?></a> <span>/</span> <span>Kirim lamaran</span></div>

  <div class="panel" style="max-width:640px;margin:0 auto">
    <div class="person" style="margin-bottom:16px">
      <?php if ($logoUrl): ?><img class="avatar" src="<?= e($logoUrl) ?>" alt=""><?php else: ?><span class="avatar" style="display:inline-flex;align-items:center;justify-content:center;background:var(--blue-soft);color:var(--navy);font-weight:700"><?= e(inisial($lowongan['nama_perusahaan'])) ?></span><?php endif; ?>
      <div><b><?= e($lowongan['posisi']) ?></b><small><?= e($lowongan['nama_perusahaan']) ?></small></div>
    </div>

    <?php $ktmAda = !empty($mahasiswa['file_ktm']); $labelKtm = ($mahasiswa['status_mahasiswa'] ?? 'aktif') === 'alumni' ? 'Ijazah atau SKL' : 'KTM'; ?>
    <?php if (!$ktmAda): ?>
      <div class="alert alert-bad">
        <span data-ic="alert"></span>
        <span><b><?= e($labelKtm) ?> belum ada di profilmu.</b><br>
        Lamaran belum bisa dikirim sebelum dokumen ini diunggah.
        <a href="<?= url('mahasiswa/profil') ?>"><b>Unggah sekarang di Profil Karier</b></a>, lalu kembali ke halaman ini.</span>
      </div>
    <?php endif; ?>

    <form method="post" action="<?= url('lamaran/kirim/' . $lowongan['id']) ?>" enctype="multipart/form-data" id="formLamar">
      <?= csrfField() ?>

      <p style="font-weight:600;margin-bottom:8px">Pilih CV yang dikirim</p>
      <label class="radio-card"><input type="radio" name="jenis_cv" value="generate" checked><span><b>CV otomatis</b><br><span class="muted" style="font-size:.88rem">Dibuat dari profil terbaru</span></span></label>
      <label class="radio-card <?= empty($mahasiswa['file_cv']) ? 'disabled' : '' ?>">
        <input type="radio" name="jenis_cv" value="unggah" <?= empty($mahasiswa['file_cv']) ? 'disabled' : '' ?>>
        <span><b>CV unggahan</b><br><span class="muted" style="font-size:.88rem"><?= !empty($mahasiswa['file_cv']) ? 'CV yang sudah kamu unggah di profil' : 'Belum ada CV diunggah, lengkapi di Profil Karier dulu' ?></span></span>
      </label>

      <p style="font-weight:600;margin:16px 0 8px">Dokumen pendukung</p>
      <div class="row2">
        <div class="field">
          <label><?= e($labelKtm) ?> <span class="muted">(otomatis dari profil)</span></label>
          <?php if ($ktmAda): ?>
            <div class="upload" style="pointer-events:none;background:var(--ok-bg);border-color:var(--ok-line)">
              <span data-ic="checkc"></span><div class="name">Sudah tersimpan di profil</div>
              <div class="hint">Ikut terkirim otomatis</div>
            </div>
          <?php else: ?>
            <a class="upload" href="<?= url('mahasiswa/profil') ?>" style="display:block;background:var(--bad-bg);border-color:var(--bad)">
              <span data-ic="alert"></span><div class="name" style="color:var(--bad)">Belum diunggah</div>
              <div class="hint">Klik untuk mengunggah di Profil Karier</div>
            </a>
          <?php endif; ?>
        </div>
        <?php $suratAda = !empty($mahasiswa['file_surat_pengantar']); ?>
        <div class="field">
          <label>Surat pengantar <?= $suratAda ? '<span class="muted">(opsional)</span>' : '<span style="color:var(--bad)">*</span>' ?></label>
          <label class="upload" id="kotakSurat">
            <input type="file" name="file_surat_pengantar" accept="application/pdf,.pdf" id="fileSurat"
                   <?= $suratAda ? '' : 'required' ?>>
            <span data-ic="upload"></span>
            <div id="namaSurat"><b><?= $suratAda ? 'Ganti berkas (boleh dikosongkan)' : 'Pilih berkas PDF' ?></b></div>
            <div class="hint">
              <?= $suratAda
                    ? 'Dibiarkan kosong berarti memakai surat pengantar dari Profil Karier'
                    : 'Format PDF, maksimal 2 MB' ?>
            </div>
          </label>
          <small class="muted" id="galatSurat" style="display:none;color:var(--bad)"></small>
          <?php if (!$suratAda): ?>
            <small class="muted">Sudah punya surat pengantar yang dipakai berulang? Simpan sekali di
              <a href="<?= url('mahasiswa/profil') ?>">Profil Karier</a>, nanti terpakai otomatis.</small>
          <?php endif; ?>
        </div>
      </div>

      <div class="alert alert-info"><span data-ic="link"></span><span>Profil, foto, CV, KTM, surat pengantar, dan tautan portofolio terkirim ke perusahaan dan tercatat di Career Center.</span></div>

      <div class="field"><label for="cover">Catatan tambahan <span class="muted">(opsional)</span></label><textarea class="input" id="cover" name="catatan_pelamar" rows="2" placeholder="Pesan singkat untuk perusahaan"></textarea></div>

      <div style="display:flex;justify-content:flex-end;align-items:center;gap:10px;margin-top:16px;flex-wrap:wrap">
        <?php if (!$ktmAda): ?>
          <small class="muted" style="margin-right:auto">Lengkapi <?= e($labelKtm) ?> dulu untuk mengaktifkan tombol kirim.</small>
        <?php endif; ?>
        <a class="btn btn-outline" href="<?= url('lowongan/detail/' . $lowongan['id']) ?>">Batal</a>
        <button class="btn btn-primary" type="submit" <?= $ktmAda ? '' : 'disabled' ?>>Kirim lamaran</button>
      </div>
    </form>

    <script>
    /* Menampilkan nama berkas yang dipilih dan menolak berkas yang terlalu besar
       atau bukan PDF sejak di browser, supaya pengguna tidak menunggu unggahan
       selesai baru tahu berkasnya ditolak. */
    (function () {
      var input  = document.getElementById('fileSurat');
      var label  = document.getElementById('namaSurat');
      var galat  = document.getElementById('galatSurat');
      var kotak  = document.getElementById('kotakSurat');
      if (!input) return;

      input.addEventListener('change', function () {
        var f = input.files[0];
        galat.style.display = 'none';
        kotak.style.borderColor = '';
        if (!f) { label.innerHTML = '<b>Pilih berkas PDF</b>'; return; }

        if (f.type !== 'application/pdf' && !/\.pdf$/i.test(f.name)) {
          galat.textContent = 'Berkas harus PDF. Berkas "' + f.name + '" tidak bisa dipakai.';
          galat.style.display = 'block';
          kotak.style.borderColor = 'var(--bad)';
          input.value = '';
          label.innerHTML = '<b>Pilih berkas PDF</b>';
          return;
        }
        if (f.size > 2 * 1024 * 1024) {
          galat.textContent = 'Ukuran berkas ' + (f.size / 1048576).toFixed(1) + ' MB, melebihi batas 2 MB.';
          galat.style.display = 'block';
          kotak.style.borderColor = 'var(--bad)';
          input.value = '';
          label.innerHTML = '<b>Pilih berkas PDF</b>';
          return;
        }
        label.innerHTML = '<b>' + f.name + '</b>';
        kotak.style.borderColor = 'var(--ok)';
      });
    })();
    </script>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
