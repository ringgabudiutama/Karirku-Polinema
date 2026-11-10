<?php
// ===== FRONTEND · PERUSAHAAN · Pengaturan akun =======================
$page_title = 'Pengaturan Akun';
$active_menu = 'pengaturan';
require __DIR__ . '/../layouts/app-header.php';
?>
<section class="view active">
  <?= kepalaKembali('perusahaan/dashboard', [['Dashboard', 'perusahaan/dashboard'], ['Pengaturan akun']]) ?>
  <div class="page-head"><div><h1>Pengaturan akun</h1><p>Kontak, alamat perusahaan, dan keamanan akun.</p></div></div>
  <div class="grid g2 items-start">
    <div>
      <form class="panel" method="post" action="<?= url('perusahaan/simpan-pengaturan-akun') ?>" data-jaga>
        <?= csrfField() ?><input type="hidden" name="aksi" value="kontak">
        <h3>Kontak</h3>
        <div class="field"><label for="kEmail">Email perusahaan (untuk masuk)</label><input class="input" id="kEmail" name="email" type="email" value="<?= e((string) old('email', $pengguna['email'])) ?>" required></div>
        <div class="field"><label for="kWa">WhatsApp PIC</label><input class="input" id="kWa" name="whatsapp_pic" value="<?= e((string) old('whatsapp_pic', $perusahaan['whatsapp_pic'] ?? '')) ?>" required placeholder="081234567890"></div>
        <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Simpan kontak</button>
      </form>
      <?php
        $aksiAlamat = url('perusahaan/simpan-pengaturan-akun');
        $dataAlamat = $perusahaan;
        $labelKota = 'Kota/kabupaten';
        $alamatWajib = true;
        $petunjukAlamat = 'Alamat kantor yang tampil di profil perusahaan dan halaman mitra.';
        require __DIR__ . '/../layouts/_form-alamat.php';
      ?>
    </div>
    <form class="panel" id="keamanan" method="post" action="<?= url('perusahaan/simpan-pengaturan-akun') ?>">
      <?= csrfField() ?><input type="hidden" name="aksi" value="password">
      <h3>Ganti kata sandi</h3>
      <p class="muted fs-88 mt-0">Setelah diganti, semua sesi di perangkat lain otomatis dikeluarkan.</p>
      <div class="field"><label for="sLama">Kata sandi lama</label><div class="pw"><input class="input" id="sLama" name="password_lama" type="password" autocomplete="current-password" required><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div></div>
      <div class="field"><label for="sBaru">Kata sandi baru</label><div class="pw"><input class="input" id="sBaru" data-panduan-sandi name="password_baru" type="password" autocomplete="new-password" required minlength="8"><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div><div class="hint">Minimal 8 karakter.</div></div>
      <div class="field"><label for="sUlang">Ulangi kata sandi baru</label><input class="input" id="sUlang" name="konfirmasi_password" type="password" autocomplete="new-password" required minlength="8"></div>
      <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Ganti kata sandi</button>
    </form>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
