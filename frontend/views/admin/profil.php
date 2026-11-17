<?php
// ===== FRONTEND · ADMIN · Profil admin (revisi tahap 2) ==============
$page_title = 'Profil Saya';
$active_menu = 'profil-admin';
require __DIR__ . '/../layouts/app-header.php';

$fotoAdmin = !empty($admin['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($admin['foto'])) : url('assets/img/avatar-1.jpg');
$labelAksi = ['nonaktifkan_akun' => 'Menonaktifkan akun', 'aktifkan_akun' => 'Mengaktifkan akun',
              'kirim_tautan_reset' => 'Mengirim tautan reset sandi', 'atur_sandi_sementara' => 'Mengatur sandi sementara',
              'ubah_profil_admin' => 'Memperbarui profil admin'];
$waTampil = $admin['no_whatsapp'] ?? '';
?>
<section class="view active">
  <?= kepalaKembali('admin/dashboard', [['Dashboard', 'admin/dashboard'], ['Profil saya']]) ?>
  <div class="page-head"><div><h1>Profil Saya</h1><p>Data admin ini tampil di topbar dan di riwayat aktivitas Career Center.</p></div></div>

  <div class="layout-profil-admin">
    <!-- ===== Kartu ringkas ===== -->
    <aside class="panel admin-kartu">
      <div class="avatar-edit admin-avatar">
        <img class="avatar-lg" src="<?= e($fotoAdmin) ?>" alt="Foto profil <?= e($admin['nama']) ?>">
        <form method="post" action="<?= url('admin/simpan-profil') ?>" enctype="multipart/form-data">
          <?= csrfField() ?><input type="hidden" name="aksi" value="foto">
          <label title="Ganti foto"><input type="file" name="foto" accept=".jpg,.jpeg,.png" data-kirim-otomatis data-label="Foto profil admin" data-maks-kb="2048" data-sekarang="<?= e($fotoAdmin) ?>"><span data-ic="image"></span></label>
        </form>
      </div>
      <h2 class="m-0"><?= e($admin['nama']) ?></h2>
      <p class="muted m-0"><?= e($admin['jabatan'] ?: 'Admin Career Center') ?></p>
      <span class="pill p-aktif mt-8">Admin aktif</span>
      <dl class="admin-info">
        <div><dt><span data-ic="mail"></span>Email login</dt><dd><?= e($pengguna['email']) ?></dd></div>
        <div><dt><span data-ic="whatsapp"></span>WhatsApp</dt><dd><?= $waTampil ? e($waTampil) : '<span class="muted">Belum diisi</span>' ?></dd></div>
        <div><dt><span data-ic="calendar"></span>Bergabung</dt><dd><?= tanggalIndo(substr((string) ($pengguna['dibuat_pada'] ?? ''), 0, 10)) ?></dd></div>
      </dl>
      <div class="admin-statistik">
        <a href="<?= url('admin/persetujuan') ?>"><b><?= (int) $statistik['akun_menunggu'] ?></b><small>Akun menunggu</small></a>
        <a href="<?= url('admin/persetujuan-lowongan') ?>"><b><?= (int) $statistik['lowongan_menunggu'] ?></b><small>Lowongan menunggu</small></a>
        <div><b><?= (int) $statistik['aksi'] ?></b><small>Aksi tercatat</small></div>
      </div>
      <?php if (!empty($admin['foto'])): ?>
        <form method="post" action="<?= url('admin/simpan-profil') ?>" data-konfirmasi="Hapus foto profil dan kembali ke avatar bawaan?">
          <?= csrfField() ?><input type="hidden" name="aksi" value="hapus_foto">
          <button class="btn btn-link btn-sm text-bad" type="submit"><span data-ic="trash"></span>Hapus foto</button>
        </form>
      <?php endif; ?>
    </aside>

    <div class="stack-16">
      <!-- ===== Form ubah profil ===== -->
      <form class="panel" method="post" action="<?= url('admin/simpan-profil') ?>" data-jaga id="formProfilAdmin">
        <?= csrfField() ?>
        <h3 class="mt-0">Ubah profil</h3>
        <div class="form-grid">
          <div class="field"><label for="apNama">Nama lengkap *</label><input class="input" id="apNama" name="nama" required minlength="3" maxlength="255" value="<?= e((string) old('nama', $admin['nama'])) ?>"></div>
          <div class="field"><label for="apJabatan">Jabatan</label><input class="input" id="apJabatan" name="jabatan" maxlength="150" placeholder="Contoh: Staf Career Center" value="<?= e((string) old('jabatan', $admin['jabatan'] ?? '')) ?>"></div>
          <div class="field"><label for="apWa">Nomor WhatsApp</label><input class="input" id="apWa" name="no_whatsapp" inputmode="tel" maxlength="20" placeholder="081234567890" data-ingatkan="Nomor ini dipakai sebagai kontak Career Center, jadi sebaiknya diisi dan disimpan sebelum Anda pindah halaman." value="<?= e((string) old('no_whatsapp', $waTampil)) ?>"><div class="hint">Dipakai sebagai kontak Career Center. Sebaiknya diisi.</div></div>
          <div class="field"><label for="apEmail">Email login *</label><input class="input" id="apEmail" type="email" name="email" required value="<?= e((string) old('email', $pengguna['email'])) ?>" data-email-lama="<?= e($pengguna['email']) ?>"><div class="hint">Mengganti email berarti masuk berikutnya memakai email baru.</div></div>
          <div class="field span-2" id="apSandiWrap" hidden><label for="apSandi">Kata sandi saat ini *</label><div class="pw"><input class="input" id="apSandi" type="password" name="password_konfirmasi" autocomplete="current-password"><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div><div class="hint">Wajib diisi karena Anda mengganti email login.</div></div>
        </div>
        <div class="item-aksi">
          <button class="btn btn-primary" type="submit" data-proses="Menyimpan..."><span data-ic="check"></span>Simpan profil</button>
          <a class="btn btn-outline" href="<?= url('admin/pengaturan#akun') ?>"><span data-ic="lock"></span>Ganti kata sandi</a>
        </div>
      </form>

      <!-- ===== Aktivitas saya ===== -->
      <div class="panel">
        <h3 class="mt-0">Aktivitas saya terbaru</h3>
        <?php if (empty($aktivitas)): ?>
          <p class="muted m-0">Belum ada aktivitas yang tercatat.</p>
        <?php else: ?>
          <?= riwayatHtml(array_map(fn($a) => [
              'tanggal' => $a['tanggal'], 'judul' => ($labelAksi[$a['aksi']] ?? $a['aksi']) . ($a['email_target'] && $a['aksi'] !== 'ubah_profil_admin' ? ': ' . $a['email_target'] : ''),
              'oleh' => $admin['nama'], 'catatan' => $a['keterangan'],
          ], $aktivitas)) ?>
        <?php endif; ?>
      </div>
    </div>
  </div>
</section>
<script nonce="<?= cspNonce() ?>">
// Kolom kata sandi hanya muncul (dan wajib) bila email login diubah.
(function () {
  var em = document.getElementById('apEmail'), w = document.getElementById('apSandiWrap'), pw = document.getElementById('apSandi');
  if (!em || !w) return;
  function cek() { var beda = em.value.trim().toLowerCase() !== (em.dataset.emailLama || '').toLowerCase(); w.hidden = !beda; pw.required = beda; }
  em.addEventListener('input', cek); cek();
})();
</script>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>