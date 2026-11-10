<?php
// ===== FRONTEND · MAHASISWA · Pengaturan akun ========================
$page_title = 'Pengaturan Akun';
$active_menu = 'pengaturan';
require __DIR__ . '/../layouts/app-header.php';
?>
<section class="view active">
  <?= kepalaKembali('mahasiswa/dashboard', [['Dashboard', 'mahasiswa/dashboard'], ['Pengaturan akun']]) ?>
  <div class="page-head"><div><h1>Pengaturan akun</h1><p>Kontak, alamat, dan keamanan akun.</p></div></div>

  <div class="grid g2 items-start">
    <div>
      <form class="panel" method="post" action="<?= url('mahasiswa/simpan-pengaturan-akun') ?>" data-jaga>
        <?= csrfField() ?><input type="hidden" name="aksi" value="kontak">
        <h3>Kontak akun</h3>
        <div class="field"><label for="kEmail">Email (untuk masuk)</label><input class="input" id="kEmail" name="email" type="email" value="<?= e((string) old('email', $pengguna['email'])) ?>" required></div>
        <div class="field"><label for="kWa">Nomor WhatsApp</label><input class="input" id="kWa" name="no_whatsapp" placeholder="08xxxxxxxxxx" value="<?= e((string) old('no_whatsapp', $mahasiswa['no_whatsapp'] ?? '')) ?>" required></div>
        <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Simpan kontak</button>
      </form>
      <?php
        $aksiAlamat = url('mahasiswa/simpan-pengaturan-akun');
        $dataAlamat = ['alamat' => $mahasiswa['alamat'] ?? '', 'kota' => $mahasiswa['domisili'] ?? '',
                       'provinsi' => $mahasiswa['provinsi'] ?? '', 'kode_pos' => $mahasiswa['kode_pos'] ?? ''];
        $labelKota = 'Kota/kabupaten domisili';
        $alamatWajib = false;
        $petunjukAlamat = 'Alamat tempat tinggal saat ini. Ikut terkirim otomatis ke perusahaan saat Anda melamar.';
        require __DIR__ . '/../layouts/_form-alamat.php';
      ?>
    </div>

    <form class="panel" id="keamanan" method="post" action="<?= url('mahasiswa/simpan-pengaturan-akun') ?>">
      <?= csrfField() ?><input type="hidden" name="aksi" value="password">
      <h3>Ganti kata sandi</h3>
      <p class="muted fs-88 mt-0">Setelah diganti, semua sesi di perangkat lain otomatis dikeluarkan.</p>
      <div class="field"><label for="sLama">Kata sandi lama</label><div class="pw"><input class="input" id="sLama" name="password_lama" type="password" autocomplete="current-password" required><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div></div>
      <div class="field"><label for="sBaru">Kata sandi baru</label><div class="pw"><input class="input" id="sBaru" data-panduan-sandi name="password_baru" type="password" autocomplete="new-password" required minlength="8"><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div><div class="hint">Minimal 8 karakter.</div></div>
      <div class="field"><label for="sUlang">Ulangi kata sandi baru</label><div class="pw"><input class="input" id="sUlang" name="konfirmasi_password" type="password" autocomplete="new-password" required minlength="8"><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div></div>
      <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Ganti kata sandi</button>
    </form>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
