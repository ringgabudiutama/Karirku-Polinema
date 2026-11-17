<?php
/* ===== FRONTEND · KOMPONEN · Formulir alamat (revisi F) =====
   Variabel: $aksiAlamat (URL tujuan), $dataAlamat (alamat, kota, provinsi, kode_pos),
             $labelKota, $alamatWajib (bool), $petunjukAlamat (teks). */
$nilaiAlamat = fn($k) => e((string) old($k, $dataAlamat[$k] ?? ''));
?>
<form class="panel" id="alamat" method="post" action="<?= $aksiAlamat ?>" data-draft="alamat" data-jaga novalidate>
  <?= csrfField() ?><input type="hidden" name="aksi" value="alamat">
  <script type="application/json" id="petaKotaProvinsi"><?= json_encode(PETA_KOTA_PROVINSI, JSON_HEX_TAG | JSON_UNESCAPED_UNICODE) ?></script>
  <h3>Alamat</h3>
  <p class="muted fs-88 mt-0"><?= e($petunjukAlamat) ?></p>
  <div class="field"><label for="almJalan">Alamat lengkap <?= $alamatWajib ? '<span class="text-bad">*</span>' : '<span class="muted">(opsional)</span>' ?></label>
    <textarea class="input" id="almJalan" name="alamat" rows="2" maxlength="255" <?= $alamatWajib ? 'required' : '' ?> placeholder="Nama jalan, nomor, RT/RW, kelurahan, kecamatan"><?= $nilaiAlamat('alamat') ?></textarea></div>
  <div class="row2">
    <div class="field"><label for="almKota"><?= e($labelKota) ?> <span class="text-bad">*</span></label>
      <input class="input" id="almKota" name="kota" maxlength="100" required value="<?= $nilaiAlamat('kota') ?>" placeholder="Kota Malang" list="daftarKota" autocomplete="off" data-isi-provinsi="almProv">
      <datalist id="daftarKota"><?php foreach (array_keys(PETA_KOTA_PROVINSI) as $kt): ?><option value="<?= e($kt) ?>"><?php endforeach; ?></datalist>
      <div class="hint">Ketik lalu pilih dari daftar; provinsi terisi otomatis.</div></div>
    <div class="field"><label for="almProv">Provinsi</label>
      <select class="input" id="almProv" name="provinsi"><?= opsiProvinsi((string) old('provinsi', $dataAlamat['provinsi'] ?? '')) ?></select></div>
    <div class="field"><label for="almPos">Kode pos</label>
      <input class="input" id="almPos" name="kode_pos" inputmode="numeric" pattern="\d{5}" maxlength="5" value="<?= $nilaiAlamat('kode_pos') ?>" placeholder="65141">
      <div class="hint">5 digit angka.</div></div>
  </div>
  <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Simpan alamat</button>
</form>
