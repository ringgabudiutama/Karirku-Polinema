<?php
/* ===== FRONTEND · ADMIN · Modal aksi akun (nonaktifkan & reset sandi) =====
   Variabel: $u (pengguna_id, status_akun, email, nama/nama_perusahaan, perusahaan?), $kembali (path). */
$idU = (int) $u['pengguna_id'];
$namaU = $u['nama'] ?? $u['nama_perusahaan'] ?? $u['email'];
$emailAktif = MailService::siapKirim();   // tanpa SMTP, tautan reset tidak mungkin sampai
?>
<?php if ($u['status_akun'] === 'aktif'): ?>
<div class="modal" id="mSuspend<?= $idU ?>" role="dialog" aria-modal="true" aria-labelledby="jSus<?= $idU ?>">
  <div class="modal-box">
    <div class="modal-head"><h3 id="jSus<?= $idU ?>">Nonaktifkan akun?</h3><button class="close" data-close aria-label="Tutup" data-ic="x"></button></div>
    <form method="post" action="<?= url('admin/nonaktifkan-pengguna/' . $idU) ?>">
      <?= csrfField() ?><input type="hidden" name="kembali" value="<?= e($kembali) ?>">
      <div class="modal-body">
        <p><b><?= e($namaU) ?></b> tidak bisa masuk, semua sesi login-nya langsung dikeluarkan, dan ia menerima email pemberitahuan beserta alasannya.<?= !empty($u['nama_perusahaan']) ? ' Lowongan milik perusahaan ini ikut disembunyikan dari pelamar.' : '' ?></p>
        <div class="field"><label for="alSus<?= $idU ?>">Alasan</label><?= chipsAlasan('daftar_alasan_penolakan', 'alSus' . $idU) ?>
          <textarea class="input" id="alSus<?= $idU ?>" name="alasan" rows="3" minlength="10" maxlength="500" required placeholder="Tulis alasan yang jelas (min. 10 karakter)"></textarea></div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Batal</button><button type="submit" class="btn btn-danger" data-proses="Memproses...">Nonaktifkan</button></div>
    </form>
  </div>
</div>
<?php endif; ?>

<!-- Revisi L: reset kata sandi oleh Admin -->
<div class="modal" id="mReset<?= $idU ?>" role="dialog" aria-modal="true" aria-labelledby="jRes<?= $idU ?>">
  <div class="modal-box">
    <div class="modal-head"><h3 id="jRes<?= $idU ?>">Reset kata sandi</h3><button class="close" data-close aria-label="Tutup" data-ic="x"></button></div>
    <form method="post" action="<?= url('admin/reset-sandi-pengguna/' . $idU) ?>" autocomplete="off">
      <?= csrfField() ?><input type="hidden" name="kembali" value="<?= e($kembali) ?>">
      <div class="modal-body">
        <p class="m-0 mb-12">Akun: <b><?= e($namaU) ?></b> (<?= e($u['email']) ?>). Lakukan hanya atas permintaan pemilik akun yang identitasnya sudah dicek.</p>
        <label class="radio-card<?= $emailAktif ? '' : ' is-disabled' ?>"><input type="radio" name="cara" value="tautan" <?= $emailAktif ? 'checked' : 'disabled' ?> data-tampilkan="#sem<?= $idU ?>" data-sembunyi="1">
          <span><b>Kirim tautan reset ke email</b> (disarankan)<br><span class="muted fs-88"><?= $emailAktif ? 'Pengguna membuat sandi sendiri lewat tautan yang berlaku 60 menit.' : 'Belum bisa dipakai: email sistem (SMTP) belum diatur di Pengaturan.' ?></span></span></label>
        <label class="radio-card"><input type="radio" name="cara" value="sementara" <?= $emailAktif ? '' : 'checked' ?> data-tampilkan="#sem<?= $idU ?>">
          <span><b>Atur kata sandi sementara</b><br><span class="muted fs-88">Untuk pengguna yang tidak bisa membuka emailnya. Wajib diganti saat masuk; semua sesi lamanya dikeluarkan.</span></span></label>
        <div class="field" id="sem<?= $idU ?>" <?= $emailAktif ? 'hidden' : '' ?>><label for="ps<?= $idU ?>">Kata sandi sementara</label>
          <div class="d-flex gap-8"><input class="input grow" id="ps<?= $idU ?>" name="password_sementara" type="text" minlength="8" autocomplete="new-password" placeholder="Min. 8 karakter, huruf dan angka" value="<?= e(sandiSementaraAcak()) ?>" <?= $emailAktif ? '' : 'required' ?>>
          <button type="button" class="btn btn-outline btn-sm" data-sandi-acak="ps<?= $idU ?>" title="Buat sandi acak baru"><span data-ic="refresh"></span></button></div>
          <div class="hint">Sampaikan ke pemilik akun lewat jalur resmi, bukan grup. Sandi ini tidak dicatat di log.</div></div>
        <div class="field"><label for="pa<?= $idU ?>">Konfirmasi dengan kata sandi Admin Anda</label>
          <input class="input" id="pa<?= $idU ?>" name="password_admin" type="password" autocomplete="current-password" required></div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Batal</button><button type="submit" class="btn btn-primary" data-proses="Memproses...">Reset kata sandi</button></div>
    </form>
  </div>
</div>
