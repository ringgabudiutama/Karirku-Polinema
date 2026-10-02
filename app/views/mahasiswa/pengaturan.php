<?php
/**
 * View: mahasiswa/pengaturan (route: mahasiswa/pengaturan-akun)
 * Dipanggil oleh: MahasiswaController::pengaturanAkun()
 * Variabel: $pengguna, $mahasiswa
 */
$page_title = 'Pengaturan Akun';
$active_menu = 'pengaturan';
require __DIR__ . '/../layouts/app-header.php';
?>
<section class="view active">
  <div class="page-head"><div><h1>Pengaturan akun</h1></div></div>

  <div class="grid g2" style="align-items:start">
    <form class="panel" method="post" action="<?= url('mahasiswa/simpan-pengaturan-akun') ?>">
      <?= csrfField() ?><input type="hidden" name="aksi" value="kontak">
      <h3>Kontak akun</h3>
      <div class="field"><label>Email</label><input class="input" name="email" type="email" value="<?= e($pengguna['email']) ?>" required></div>
      <div class="field"><label>Nomor WhatsApp</label><input class="input" name="no_whatsapp" placeholder="08xxxxxxxxxx" value="<?= e($mahasiswa['no_whatsapp'] ?? '') ?>" required></div>
      <button class="btn btn-primary">Simpan kontak</button>
    </form>

    <form class="panel" method="post" action="<?= url('mahasiswa/simpan-pengaturan-akun') ?>">
      <?= csrfField() ?><input type="hidden" name="aksi" value="password">
      <h3>Ganti kata sandi</h3>
      <div class="field"><label>Kata sandi lama</label><div class="pw"><input class="input" name="password_lama" type="password" required><button type="button" data-ic="eye"></button></div></div>
      <div class="field"><label>Kata sandi baru</label><div class="pw"><input class="input" name="password_baru" type="password" required minlength="8"><button type="button" data-ic="eye"></button></div></div>
      <div class="field"><label>Ulangi kata sandi baru</label><div class="pw"><input class="input" name="konfirmasi_password" type="password" required><button type="button" data-ic="eye"></button></div></div>
      <button class="btn btn-primary">Ganti kata sandi</button>
    </form>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>