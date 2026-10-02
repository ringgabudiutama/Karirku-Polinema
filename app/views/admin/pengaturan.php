<?php
/**
 * View: admin/pengaturan
 * Dipanggil oleh: AdminController::pengaturan()
 * Variabel: $pengaturan, $kontakJurusan, $pengguna
 */
$page_title = 'Pengaturan';
$active_menu = 'pengaturan';
require __DIR__ . '/../layouts/app-header.php';
$g = fn($k, $d = '') => e($pengaturan[$k] ?? $d);
$alasanDefault = "NIM tidak ditemukan di SIAKAD\nDokumen tidak terbaca\nPerusahaan outsourcing\nData tidak sesuai dokumen\nLegalitas tidak valid";
?>
<section class="view active">
  <div class="page-head"><div><h1>Pengaturan</h1></div></div>
  <div class="panel">
    <div class="tabs" data-tabs="sPanes" id="sTabs">
      <button class="active" data-tab="kontak">Kontak admin jurusan</button>
      <button data-tab="wa">Template WhatsApp</button>
      <button data-tab="email">Template email</button>
      <button data-tab="alasan">Alasan penolakan</button>
      <button data-tab="akun">Akun admin</button>
    </div>
    <div id="sPanes">

      <div data-pane="kontak">
        <p class="muted">Nomor ini dipakai tombol di menu Kirim Loker ke Jurusan. Gunakan format 62, tanpa spasi.</p>
        <form method="post" action="<?= url('kirim-loker/simpan-kontak') ?>">
          <?= csrfField() ?>
          <div class="table-wrap"><table class="t">
            <tr><th>Jurusan</th><th>Nama admin</th><th>Nomor WhatsApp</th></tr>
            <?php foreach ($kontakJurusan as $k): ?>
              <tr>
                <td><?= e($k['nama_jurusan']) ?></td>
                <td><input class="input" name="nama_kontak[<?= (int) $k['jurusan_id'] ?>]" value="<?= e($k['nama_kontak'] ?? '') ?>" placeholder="Nama admin jurusan"></td>
                <td><input class="input" name="nomor_wa[<?= (int) $k['jurusan_id'] ?>]" value="<?= e($k['nomor_wa'] ?? '') ?>" placeholder="628xxxxxxxxxx"></td>
              </tr>
            <?php endforeach; ?>
          </table></div>
          <button class="btn btn-primary" type="submit" style="margin-top:14px">Simpan kontak</button>
        </form>
      </div>

      <form data-pane="wa" hidden method="post" action="<?= url('admin/simpan-pengaturan') ?>">
        <?= csrfField() ?>
        <div class="field"><label>Isi pesan</label><textarea class="input" name="template_wa_loker" rows="6"><?= $g('template_wa_loker', KirimLokerController::TEMPLATE_WA_DEFAULT) ?></textarea><div class="hint">Kata dalam kurung kurawal diganti otomatis.</div></div>
        <button class="btn btn-primary">Simpan template</button>
      </form>

      <form data-pane="email" hidden method="post" action="<?= url('admin/simpan-pengaturan') ?>" id="formEmail">
        <?= csrfField() ?>
        <div class="row2">
          <div class="field"><label>Nama pengirim</label><input class="input" name="smtp_nama_pengirim" value="<?= $g('smtp_nama_pengirim', 'KarirKu Polinema') ?>"></div>
          <div class="field"><label>Alamat pengirim</label><input class="input" name="smtp_alamat_pengirim" value="<?= $g('smtp_alamat_pengirim', 'karirku@polinema.ac.id') ?>"></div>
        </div>
        <div class="field">
          <label>Pilih template</label>
          <select class="input" id="pilihTemplateEmail">
            <option value="disetujui">Pendaftaran diterima</option>
            <option value="perbaikan">Data perlu diperbaiki</option>
            <option value="ditolak">Pendaftaran ditolak</option>
          </select>
        </div>
        <div class="field">
          <label>Subjek</label>
          <input class="input" id="subjekEmailTampil">
        </div>
        <?php foreach (MailService::SUBJEK_DEFAULT as $kunciTpl => $subjekBawaan): ?>
          <input type="hidden" name="template_email_subjek_<?= $kunciTpl ?>" id="subjekEmail_<?= $kunciTpl ?>" value="<?= $g('template_email_subjek_' . $kunciTpl, $subjekBawaan) ?>">
        <?php endforeach; ?>
        <button class="btn btn-primary">Simpan template</button>
      </form>

      <form data-pane="alasan" hidden method="post" action="<?= url('admin/simpan-pengaturan') ?>" id="formAlasan">
        <?= csrfField() ?>
        <div class="chips" id="chipAlasan">
          <?php foreach (array_filter(array_map('trim', explode("\n", $g('daftar_alasan_penolakan', $alasanDefault)))) as $alasan): ?>
            <span class="chip" data-nilai="<?= e($alasan) ?>"><?= e($alasan) ?><button type="button" aria-label="Hapus alasan">&times;</button></span>
          <?php endforeach; ?>
        </div>
        <div class="field" style="display:flex;gap:8px;align-items:flex-end;margin-top:14px;max-width:480px">
          <input class="input" id="alasanBaruInput" placeholder="Tambah alasan baru">
          <button class="btn btn-primary" type="button" id="btnTambahAlasan" style="flex:none">Tambah</button>
        </div>
        <textarea name="daftar_alasan_penolakan" id="alasanHidden" hidden><?= $g('daftar_alasan_penolakan', $alasanDefault) ?></textarea>
      </form>

      <form data-pane="akun" hidden method="post" action="<?= url('admin/ganti-password') ?>" style="max-width:420px">
        <?= csrfField() ?>
        <div class="field"><label>Kata sandi lama</label><input class="input" name="password_lama" type="password" required></div>
        <div class="field"><label>Kata sandi baru</label><input class="input" name="password_baru" type="password" required minlength="8"></div>
        <div class="field"><label>Ulangi kata sandi baru</label><input class="input" name="konfirmasi_password" type="password" required></div>
        <button class="btn btn-primary">Ganti kata sandi</button>
      </form>

    </div>
  </div>
</section>
<script>
(function(){
  var select = document.getElementById('pilihTemplateEmail');
  var tampil = document.getElementById('subjekEmailTampil');
  if (select && tampil) {
    var ambilHidden = function (key) { return document.getElementById('subjekEmail_' + key); };
    var muat = function (key) { tampil.value = ambilHidden(key).value; };
    var simpanKeHidden = function () { ambilHidden(select.value).value = tampil.value; };

    muat(select.value);
    select.addEventListener('change', function () { muat(select.value); });
    tampil.addEventListener('input', simpanKeHidden);
    document.getElementById('formEmail').addEventListener('submit', simpanKeHidden);
  }
})();
(function(){
  var form = document.getElementById('formAlasan');
  if (!form) return;
  var hidden = document.getElementById('alasanHidden');
  var chipWrap = document.getElementById('chipAlasan');
  var input = document.getElementById('alasanBaruInput');
  var btnTambah = document.getElementById('btnTambahAlasan');

  function daftarSaatIni() {
    return Array.from(chipWrap.querySelectorAll('.chip')).map(function (c) { return c.dataset.nilai; });
  }
  function kirim(daftarBaru) {
    hidden.value = daftarBaru.join('\n');
    form.submit();
  }

  chipWrap.addEventListener('click', function (e) {
    var tombol = e.target.closest('button');
    if (!tombol) return;
    var chip = tombol.closest('.chip');
    var sisa = daftarSaatIni().filter(function (v) { return v !== chip.dataset.nilai; });
    kirim(sisa);
  });

  if (btnTambah) {
    btnTambah.addEventListener('click', function () {
      var nilai = input.value.trim();
      if (!nilai) { input.focus(); return; }
      var daftar = daftarSaatIni();
      if (daftar.indexOf(nilai) === -1) { daftar.push(nilai); }
      kirim(daftar);
    });
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') { e.preventDefault(); btnTambah.click(); }
    });
  }
})();
</script>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>