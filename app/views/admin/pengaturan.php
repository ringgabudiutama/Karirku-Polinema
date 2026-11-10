<?php
// ===== FRONTEND · ADMIN · Pengaturan =================================
$page_title = 'Pengaturan';
$active_menu = 'pengaturan';
require __DIR__ . '/../layouts/app-header.php';
$g = fn($k, $d = '') => e($pengaturan[$k] ?? $d);
$labelStatusEmail = ['terkirim' => ['Terkirim', 'aktif'], 'gagal' => ['Gagal', 'ditolak'], 'log' => ['Hanya dicatat', 'menunggu']];
$labelJenisEmail = ['registrasi' => 'Pendaftaran', 'status_akun' => 'Status akun', 'status_lowongan' => 'Status lowongan',
                    'reset_sandi' => 'Reset sandi', 'reset_sandi_admin' => 'Reset oleh admin', 'uji' => 'Email uji'];
$labelAksiAdmin = ['nonaktifkan_akun' => 'Menonaktifkan akun', 'aktifkan_akun' => 'Mengaktifkan akun',
                   'kirim_tautan_reset' => 'Mengirim tautan reset sandi', 'atur_sandi_sementara' => 'Mengatur sandi sementara', 'ubah_profil_admin' => 'Memperbarui profil admin'];
?>
<section class="view active">
  <?= kepalaKembali('admin/dashboard', [['Dashboard', 'admin/dashboard'], ['Pengaturan']]) ?>
  <div class="page-head"><div><h1>Pengaturan</h1><p>Kontak admin jurusan, template pesan, email sistem, alasan penolakan, dan akun admin.</p></div></div>
  <div class="panel">
    <div class="tabs tabs-gulir" data-tabs="sPanes" id="sTabs">
      <button class="active" data-tab="kontak">Kontak admin jurusan</button>
      <button data-tab="wa">Template WhatsApp</button>
      <button data-tab="email">Email</button>
      <button data-tab="alasan">Alasan penolakan</button>
      <button data-tab="akun">Akun admin</button>
    </div>
    <div id="sPanes">

      <!-- ===== Tab: kontak admin jurusan ===== -->
      <div data-pane="kontak">
        <p class="muted">Nomor ini dipakai tombol di menu Kirim Loker ke Jurusan. Gunakan format 62, tanpa spasi.</p>
        <form method="post" action="<?= url('kirim-loker/simpan-kontak') ?>" data-jaga>
          <?= csrfField() ?>
          <div class="table-wrap"><table class="t">
            <tr><th>Jurusan</th><th>Nama admin</th><th>Nomor WhatsApp</th></tr>
            <?php foreach ($kontakJurusan as $k): ?>
              <tr>
                <td><?= e($k['nama_jurusan']) ?></td>
                <td><input class="input" name="nama_kontak[<?= (int) $k['jurusan_id'] ?>]" value="<?= e($k['nama_kontak'] ?? '') ?>" placeholder="Nama admin jurusan" aria-label="Nama admin <?= e($k['nama_jurusan']) ?>" data-ingatkan="Nama dan nomor WhatsApp admin jurusan dipakai tombol di menu Kirim Loker ke Jurusan. Jurusan yang datanya belum lengkap tidak bisa dikirimi loker lewat WhatsApp." data-ingatkan-judul="Kontak admin jurusan belum lengkap" data-ingatkan-nama="<?= e($k['nama_jurusan']) ?>"></td>
                <td><input class="input" name="nomor_wa[<?= (int) $k['jurusan_id'] ?>]" value="<?= e($k['nomor_wa'] ?? '') ?>" placeholder="628xxxxxxxxxx" aria-label="Nomor WhatsApp <?= e($k['nama_jurusan']) ?>" data-ingatkan="Nama dan nomor WhatsApp admin jurusan dipakai tombol di menu Kirim Loker ke Jurusan. Jurusan yang datanya belum lengkap tidak bisa dikirimi loker lewat WhatsApp." data-ingatkan-judul="Kontak admin jurusan belum lengkap" data-ingatkan-nama="<?= e($k['nama_jurusan']) ?>"></td>
              </tr>
            <?php endforeach; ?>
          </table></div>
          <button class="btn btn-primary mt-14" type="submit" data-proses="Menyimpan...">Simpan kontak</button>
        </form>
      </div>

      <!-- ===== Tab: template WhatsApp ===== -->
      <form data-pane="wa" hidden method="post" action="<?= url('admin/simpan-pengaturan') ?>" data-jaga>
        <?= csrfField() ?>
        <div class="field"><label for="tplWa">Isi pesan</label><textarea class="input" id="tplWa" name="template_wa_loker" rows="7"><?= $g('template_wa_loker', KirimLokerController::TEMPLATE_WA_DEFAULT) ?></textarea>
          <div class="hint">Kata dalam kurung kurawal diganti otomatis: {posisi}, {perusahaan}, {lokasi}, {deadline}, {tautan}. Tautan berupa alamat lengkap yang bisa diklik dari WhatsApp.</div></div>
        <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Simpan template</button>
      </form>

      <!-- ===== Tab: email (revisi B) ===== -->
      <div data-pane="email" hidden>
        <div class="grid g2 items-start">
          <div class="kotak-data">
            <h3 class="mt-0">Status pengiriman email</h3>
            <?php if ($statusEmail['siap']): ?>
              <p class="text-ok m-0 mb-8"><b>SMTP terkonfigurasi.</b> Email dikirim lewat <?= e($statusEmail['mesin']) ?>.</p>
            <?php else: ?>
              <p class="text-bad m-0 mb-8"><b>SMTP belum dikonfigurasi.</b> Email TIDAK terkirim; sistem hanya mencatatnya di riwayat di bawah dan di <code>storage/logs/email.log</code>. Pengguna tetap mendapat notifikasi di aplikasi.</p>
            <?php endif; ?>
            <dl class="dl dl-ringkas">
              <dt>Server</dt><dd><?= e($statusEmail['host']) ?>:<?= (int) $statusEmail['port'] ?> (<?= e($statusEmail['enkripsi']) ?>)</dd>
              <dt>Username</dt><dd><?= e($statusEmail['user']) ?></dd>
              <dt>Kata sandi</dt><dd><?= $statusEmail['ada_sandi'] ? 'Terisi (disembunyikan)' : 'Belum diisi' ?></dd>
            </dl>
            <p class="hint">Kredensial SMTP diisi di <code>app/config/config.php</code> atau variabel lingkungan server (SMTP_HOST, SMTP_USER, SMTP_PASS). Untuk Gmail gunakan App Password, bukan sandi akun. Jangan kirim kredensial lewat chat.</p>
            <form method="post" action="<?= url('admin/kirim-email-uji') ?>" class="d-flex flex-wrap gap-8 items-end">
              <?= csrfField() ?>
              <div class="field grow m-0"><label for="emailUji">Kirim email uji ke</label><input class="input" id="emailUji" type="email" name="email_uji" value="<?= e(Auth::penggunaSaatIni()['email']) ?>" required></div>
              <button class="btn btn-primary" type="submit" data-proses="Mengirim..." <?= $statusEmail['siap'] ? '' : 'disabled title="Isi pengaturan SMTP dulu"' ?>>Kirim email uji</button>
            </form>
          </div>

          <form method="post" action="<?= url('admin/simpan-pengaturan') ?>" id="formEmail" data-jaga>
            <?= csrfField() ?>
            <h3 class="mt-0">Pengirim &amp; subjek</h3>
            <div class="row2">
              <div class="field"><label for="namaPengirim">Nama pengirim</label><input class="input" id="namaPengirim" name="smtp_nama_pengirim" data-ingatkan="Nama pengirim tampil di kotak masuk penerima email sistem, jadi sebaiknya jangan dikosongkan." value="<?= $g('smtp_nama_pengirim', 'KarirKu Polinema') ?>"></div>
              <div class="field"><label for="alamatPengirim">Alamat pengirim</label><input class="input" id="alamatPengirim" type="email" name="smtp_alamat_pengirim" data-ingatkan="Alamat pengirim dipakai untuk semua email sistem (persetujuan akun, reset sandi, dll.), jadi sebaiknya jangan dikosongkan." value="<?= $g('smtp_alamat_pengirim', 'karirku@polinema.ac.id') ?>"><div class="hint">Untuk Gmail, samakan dengan akun SMTP.</div></div>
            </div>
            <?php foreach (MailService::SUBJEK_DEFAULT as $kunciTpl => $subjekBawaan): ?>
              <div class="field"><label for="subj<?= $kunciTpl ?>">Subjek email: akun <?= e(['disetujui' => 'disetujui', 'perbaikan' => 'perlu perbaikan', 'ditolak' => 'ditolak'][$kunciTpl]) ?></label>
                <input class="input" id="subj<?= $kunciTpl ?>" name="template_email_subjek_<?= $kunciTpl ?>" value="<?= $g('template_email_subjek_' . $kunciTpl, $subjekBawaan) ?>"></div>
            <?php endforeach; ?>
            <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Simpan</button>
          </form>
        </div>

        <h3 class="mt-20">Riwayat email</h3>
        <form class="filters" method="get" action="<?= url('admin/pengaturan') ?>">
          <select class="input" name="status_email" data-auto-submit aria-label="Status email">
            <option value="">Semua status</option>
            <?php foreach ($labelStatusEmail as $k => [$v]): ?><option value="<?= $k ?>" <?= $statusLog === $k ? 'selected' : '' ?>><?= e($v) ?></option><?php endforeach; ?>
          </select>
          <input type="hidden" name="tab" value="email">
          <noscript><button class="btn btn-outline" type="submit">Terapkan</button></noscript>
        </form>
        <div class="table-wrap"><table class="t">
          <tr><th>Waktu</th><th>Tujuan</th><th>Jenis &amp; subjek</th><th>Status</th><th></th></tr>
          <?php if (!$logEmail): ?><tr><td colspan="5" class="muted kosong">Belum ada email.</td></tr><?php endif; ?>
          <?php foreach ($logEmail as $le): [$labelSt, $kelasSt] = $labelStatusEmail[$le['status']] ?? [$le['status'], 'menunggu']; ?>
            <tr>
              <td><?= tanggalWaktuIndo($le['dibuat_pada']) ?><?php if ((int) $le['percobaan'] > 1): ?><br><small class="muted"><?= (int) $le['percobaan'] ?>x percobaan</small><?php endif; ?></td>
              <td class="pecah-kata"><?= e($le['tujuan']) ?></td>
              <td><small class="muted"><?= e($labelJenisEmail[$le['jenis']] ?? $le['jenis']) ?></small><br><?= e($le['subjek']) ?></td>
              <td><span class="pill p-<?= e($kelasSt) ?>"><?= e($labelSt) ?></span><?php if ($le['keterangan']): ?><br><small class="muted pecah-kata"><?= e(ringkas($le['keterangan'], 120)) ?></small><?php endif; ?></td>
              <td>
                <?php if ($le['status'] !== 'terkirim' && $le['bisa_ulang']): ?>
                  <form method="post" action="<?= url('admin/kirim-ulang-email/' . $le['id']) ?>"><?= csrfField() ?><input type="hidden" name="status_email" value="<?= e($statusLog) ?>">
                    <button class="btn btn-sm btn-outline" type="submit" data-proses="Mengirim..." <?= $statusEmail['siap'] ? '' : 'disabled title="Isi SMTP dulu"' ?>>Kirim ulang</button></form>
                <?php elseif ($le['status'] !== 'terkirim'): ?><small class="muted">Isi rahasia, tidak bisa dikirim ulang</small><?php endif; ?>
              </td>
            </tr>
          <?php endforeach; ?>
        </table></div>
        <?= paginasiHtml($paginasiLog, 'email') ?>
      </div>

      <!-- ===== Tab: alasan penolakan (revisi K) ===== -->
      <form data-pane="alasan" hidden method="post" action="<?= url('admin/simpan-pengaturan') ?>" data-jaga>
        <?= csrfField() ?>
        <p class="muted">Satu alasan per baris. Alasan ini muncul sebagai tombol <b>isi cepat</b> saat Admin menolak/meminta perbaikan akun atau lowongan, lalu masih bisa disunting sebelum dikirim.</p>
        <div class="row2">
          <div class="field"><label for="alasanAkun">Alasan untuk akun (pendaftar &amp; nonaktif akun)</label><textarea class="input" id="alasanAkun" name="daftar_alasan_penolakan" rows="8"><?= $g('daftar_alasan_penolakan') ?></textarea></div>
          <div class="field"><label for="alasanLow">Alasan untuk lowongan (revisi, tolak, nonaktif)</label><textarea class="input" id="alasanLow" name="daftar_alasan_lowongan" rows="8"><?= $g('daftar_alasan_lowongan') ?></textarea></div>
        </div>
        <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Simpan daftar alasan</button>
      </form>

      <!-- ===== Tab: akun admin ===== -->
      <div data-pane="akun" hidden>
        <div class="grid g2 items-start">
          <form method="post" action="<?= url('admin/ganti-password') ?>">
            <?= csrfField() ?>
            <h3 class="mt-0">Ganti kata sandi</h3>
            <div class="field"><label for="aLama">Kata sandi lama</label><div class="pw"><input class="input" id="aLama" name="password_lama" type="password" autocomplete="current-password" required><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div></div>
            <div class="field"><label for="aBaru">Kata sandi baru</label><div class="pw"><input class="input" id="aBaru" data-panduan-sandi name="password_baru" type="password" autocomplete="new-password" required minlength="8"><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div></div>
            <div class="field"><label for="aUlang">Ulangi kata sandi baru</label><input class="input" id="aUlang" name="konfirmasi_password" type="password" autocomplete="new-password" required minlength="8"></div>
            <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Ganti kata sandi</button>
          </form>
          <div>
            <h3 class="mt-0">Aktivitas admin terbaru</h3>
            <?= riwayatHtml(array_map(fn($a) => [
                'tanggal' => $a['tanggal'], 'judul' => ($labelAksiAdmin[$a['aksi']] ?? $a['aksi']) . ($a['email_target'] ? ': ' . $a['email_target'] : ''),
                'oleh' => $a['nama_admin'] ?: 'Admin', 'catatan' => $a['keterangan'],
            ], $aktivitas)) ?>
          </div>
        </div>
      </div>

    </div>
  </div>
</section>
<script nonce="<?= cspNonce() ?>">
// Buka tab Email otomatis saat memfilter/paginasi riwayat email.
(function(){ var p = new URLSearchParams(location.search); if ((p.get('tab') === 'email' || p.has('status_email') || p.has('halaman')) && !location.hash) { history.replaceState(null, '', location.pathname + location.search + '#email'); } })();
</script>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>