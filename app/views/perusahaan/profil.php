<?php
/**
 * View: perusahaan/profil
 * Dipanggil oleh: PerusahaanController::profil()
 * Variabel: $perusahaan
 */
$page_title = 'Profil Perusahaan';
$active_menu = 'profil';
require __DIR__ . '/../layouts/app-header.php';
$logoUrl = !empty($perusahaan['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($perusahaan['logo'])) : null;
?>
<section class="view active">
  <div class="page-head"><div><h1>Profil perusahaan</h1><p>Profil ini tampil di setiap detail lowongan dan halaman info loker.</p></div></div>
  <form class="panel" method="post" action="<?= url('perusahaan/simpan-profil') ?>" enctype="multipart/form-data">
    <?= csrfField() ?>
    <div class="profile-head" style="margin-bottom:20px">
      <?php if ($logoUrl): ?><img src="<?= e($logoUrl) ?>" alt="" style="width:96px;height:96px;border-radius:18px;object-fit:cover"><?php else: ?>
        <span class="logo-sq" style="background:var(--navy);width:96px;height:96px;font-size:1.8rem;border-radius:18px"><?= e(inisial($perusahaan['nama_perusahaan'])) ?></span>
      <?php endif; ?>
      <div class="grow"><h2 style="margin:0"><?= e($perusahaan['nama_perusahaan']) ?> <span class="verified" data-ic="check">Mitra terverifikasi</span></h2></div>
      <label class="btn btn-outline btn-sm">Ganti logo<input type="file" name="logo" hidden accept="image/*" onchange="this.form.submit()"></label>
    </div>
    <div class="row2">
      <div class="field"><label>Nama perusahaan</label><input class="input" name="nama_perusahaan" value="<?= e($perusahaan['nama_perusahaan']) ?>" required></div>
      <div class="field"><label>Bidang usaha</label><input class="input" name="bidang_usaha" value="<?= e($perusahaan['bidang_usaha']) ?>" required></div>
      <div class="field"><label>Jenis perusahaan</label>
        <select class="input" name="jenis_perusahaan">
          <?php foreach (['Swasta Nasional', 'BUMN / BUMD', 'Multinasional', 'Startup', 'UMKM'] as $j): ?>
            <option <?= $perusahaan['jenis_perusahaan'] === $j ? 'selected' : '' ?>><?= e($j) ?></option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="field"><label>Alamat</label><input class="input" name="alamat" value="<?= e($perusahaan['alamat']) ?>" required></div>
      <div class="field"><label>Kota</label><input class="input" name="kota" value="<?= e($perusahaan['kota']) ?>" required></div>
      <div class="field"><label>Website</label><input class="input" name="website" value="<?= e($perusahaan['website'] ?? '') ?>"></div>
      <div class="field"><label>Nama PIC</label><input class="input" name="nama_pic" value="<?= e($perusahaan['nama_pic']) ?>" required></div>
      <div class="field"><label>Jabatan PIC</label><input class="input" name="jabatan_pic" value="<?= e($perusahaan['jabatan_pic'] ?? '') ?>"></div>
      <div class="field">
        <label>WhatsApp PIC <span class="wajib">*</span></label>
        <input class="input" name="whatsapp_pic" value="<?= e($perusahaan['whatsapp_pic'] ?? '') ?>"
               placeholder="081234567890" required>
        <small class="muted">Dipakai Career Center dan pelamar untuk menghubungi perusahaan.</small>
      </div>
    </div>
    <div class="field"><label>Deskripsi</label><textarea class="input" name="deskripsi" rows="4"><?= e($perusahaan['deskripsi'] ?? '') ?></textarea></div>
    <button class="btn btn-primary" type="submit">Simpan profil</button>
  </form>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
