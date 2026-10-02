<?php
/**
 * View: perusahaan/pengaturan (route: perusahaan/pengaturan-akun)
 * Dipanggil oleh: PerusahaanController::pengaturanAkun()
 * Variabel: $pengguna
 */
$page_title = 'Pengaturan Akun';
$active_menu = 'pengaturan';
require __DIR__ . '/../layouts/app-header.php';
?>
<section class="view active">
  <div class="page-head"><div><h1>Pengaturan akun</h1></div></div>
  <div class="grid g2" style="align-items:start">
    <form class="panel" method="post" action="<?= url('perusahaan/simpan-pengaturan-akun') ?>">
      <?= csrfField() ?><input type="hidden" name="aksi" value="kontak">
      <h3>Kontak</h3>
      <div class="field"><label>Email perusahaan</label><input class="input" name="email" type="email" value="<?= e($pengguna['email']) ?>" required></div>
      <div class="field"><label>WhatsApp PIC</label><input class="input" name="whatsapp_pic" value="<?= e($perusahaan['whatsapp_pic'] ?? '') ?>" required></div>
      <button class="btn btn-primary">Simpan kontak</button>
    </form>
    <form class="panel" method="post" action="<?= url('perusahaan/simpan-pengaturan-akun') ?>">
      <?= csrfField() ?><input type="hidden" name="aksi" value="password">
      <h3>Ganti kata sandi</h3>
      <div class="field"><label>Kata sandi lama</label><input class="input" name="password_lama" type="password" required></div>
      <div class="field"><label>Kata sandi baru</label><input class="input" name="password_baru" type="password" required minlength="8"></div>
      <div class="field"><label>Ulangi kata sandi baru</label><input class="input" name="konfirmasi_password" type="password" required></div>
      <button class="btn btn-primary">Ganti kata sandi</button>
    </form>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
