<?php
// ===== FRONTEND · PERUSAHAAN · Profil perusahaan =====================
$page_title = 'Profil Perusahaan';
$active_menu = 'profil';
require __DIR__ . '/../layouts/app-header.php';
$logoUrl = !empty($perusahaan['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($perusahaan['logo'])) : null;
?>
<section class="view active">
  <?= kepalaKembali('perusahaan/dashboard', [['Dashboard', 'perusahaan/dashboard'], ['Profil perusahaan']]) ?>
  <div class="page-head"><div><h1>Profil perusahaan</h1><p>Profil ini tampil di setiap detail lowongan dan halaman info loker.</p></div></div>
  <form class="panel" method="post" action="<?= url('perusahaan/simpan-profil') ?>" enctype="multipart/form-data" data-draft="profil-perusahaan" data-jaga>
    <?= csrfField() ?>
    <div class="profile-head mb-20">
      <?php if ($logoUrl): ?><img class="logo-profil" src="<?= e($logoUrl) ?>" alt=""><?php else: ?>
        <span class="logo-sq logo-profil"><?= e(inisial($perusahaan['nama_perusahaan'])) ?></span>
      <?php endif; ?>
      <div class="grow"><h2 class="m-0"><?= e($perusahaan['nama_perusahaan']) ?> <span class="verified" data-ic="check">Mitra terverifikasi</span></h2></div>
      <label class="btn btn-outline btn-sm"><span data-ic="upload"></span>Ganti logo<input type="file" name="logo" hidden accept=".jpg,.jpeg,.png" data-tipe="jpg,jpeg,png" data-maks-kb="2048" data-kirim-otomatis data-kotak data-label="Logo perusahaan"<?= $logoUrl ? ' data-sekarang="' . e($logoUrl) . '"' : '' ?>></label>
    </div>
    <div class="row2">
      <div class="field"><label>Nama perusahaan</label><input class="input" name="nama_perusahaan" value="<?= e((string) old('nama_perusahaan', $perusahaan['nama_perusahaan'])) ?>" required></div>
      <div class="field"><label>Bidang usaha</label><input class="input" name="bidang_usaha" value="<?= e((string) old('bidang_usaha', $perusahaan['bidang_usaha'])) ?>" required></div>
      <div class="field"><label>Jenis perusahaan</label>
        <select class="input" name="jenis_perusahaan">
          <?php // Bug #14: cocokkan tanpa peduli huruf besar/kecil; nilai lama di luar daftar tetap tampil.
            $jenisKini = (string) old('jenis_perusahaan', $perusahaan['jenis_perusahaan']);
            $opsiJenis = PerusahaanController::JENIS_PERUSAHAAN;
            $adaDiDaftar = false;
            foreach ($opsiJenis as $j) { if (mb_strtolower($j) === mb_strtolower($jenisKini)) { $adaDiDaftar = true; } }
            if (!$adaDiDaftar && $jenisKini !== '') { $opsiJenis[] = $jenisKini; }
            foreach ($opsiJenis as $j): ?>
            <option value="<?= e($j) ?>" <?= mb_strtolower($j) === mb_strtolower($jenisKini) ? 'selected' : '' ?>><?= e($j) ?></option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="field"><label>Alamat</label><div class="kotak-data m-0 fs-90"><?= e(implode(', ', array_filter([$perusahaan['alamat'], $perusahaan['kota'], $perusahaan['provinsi'] ?? null, $perusahaan['kode_pos'] ?? null]))) ?: '-' ?>
        <br><a href="<?= url('perusahaan/pengaturan-akun#alamat') ?>">Ubah alamat di Pengaturan Akun</a></div></div>
      <div class="field"><label>Website</label><input class="input" name="website" value="<?= e((string) old('website', $perusahaan['website'] ?? '')) ?>" placeholder="https://contoh.co.id"></div>
      <div class="field"><label>Nama PIC</label><input class="input" name="nama_pic" value="<?= e((string) old('nama_pic', $perusahaan['nama_pic'])) ?>" required></div>
      <div class="field"><label>Jabatan PIC</label><input class="input" name="jabatan_pic" value="<?= e((string) old('jabatan_pic', $perusahaan['jabatan_pic'] ?? '')) ?>"></div>
      <div class="field">
        <label>WhatsApp PIC <span class="wajib">*</span></label>
        <input class="input" name="whatsapp_pic" value="<?= e((string) old('whatsapp_pic', $perusahaan['whatsapp_pic'] ?? '')) ?>"
               placeholder="081234567890" required>
        <small class="muted">Dipakai Career Center dan pelamar untuk menghubungi perusahaan.</small>
      </div>
    </div>
    <div class="field"><label>Deskripsi</label><textarea class="input" name="deskripsi" rows="4"><?= e((string) old('deskripsi', $perusahaan['deskripsi'] ?? '')) ?></textarea></div>
    <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Simpan profil</button>
  </form>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
