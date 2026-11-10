<?php
// ===== FRONTEND · PERUSAHAAN · Detail pelamar & proses seleksi =======
$page_title = 'Detail Pelamar';
$active_menu = 'pelamar';
require __DIR__ . '/../layouts/app-header.php';

$fotoUrl = !empty($mahasiswa['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($mahasiswa['foto'])) : url('assets/img/avatar-1.jpg');
$selesai = in_array($lamaran['status'], ['diterima', 'ditolak', 'dibatalkan'], true);
$per = fn($tipe) => array_values(array_filter($profilItem, fn($i) => $i['tipe'] === $tipe));
$pendidikan = $per('pendidikan');
$pengalaman = $per('pengalaman');
$sertifikat = $per('sertifikat');
$portofolio = $per('portofolio');
$snapshot = $snapshot ?? (json_decode($lamaran['snapshot_profil'] ?? '{}', true) ?: []);
// Revisi E: bandingkan data saat melamar dengan profil terkini.
$bedaProfil = function (string $kunciSnap, $nilaiKini) use ($snapshot): bool {
    return array_key_exists($kunciSnap, $snapshot) && (string) $snapshot[$kunciSnap] !== (string) $nilaiKini;
};
$kuotaPenuh = (int) $lamaran['terisi'] >= (int) $lamaran['kuota'];

$labelRiwayat = ['diajukan' => 'Lamaran diajukan', 'screening' => 'CV dibuka, status Screening CV', 'interview' => 'Interview dijadwalkan', 'diterima' => 'Pelamar diterima', 'ditolak' => 'Pelamar ditolak', 'dibatalkan' => 'Lamaran dibatalkan pelamar'];
?>
<section class="view active">
  <div class="kepala-halaman">
    <div class="crumb"><a href="<?= url('perusahaan/pelamar') ?>">Pelamar</a> <span>/</span> <span><?= e($mahasiswa['nama']) ?></span></div>
    <?= tombolKembali('perusahaan/pelamar') ?>
  </div>

  <div class="grid g-side items-start">
    <div>
      <div class="panel">
        <!-- ===== Kolom kiri: profil pelamar ===== -->
        <div class="profile-head">
          <img class="avatar-lg" src="<?= e($fotoUrl) ?>" alt="Foto <?= e($mahasiswa['nama']) ?>">
          <div class="grow">
            <h1 class="fs-160 m-0"><?= e($mahasiswa['nama']) ?> <span class="verified" data-ic="check">Terverifikasi</span></h1>
            <p class="muted m-0 mt-2 mb-8"><?= e($mahasiswa['jenjang'] . ' ' . $mahasiswa['nama_prodi']) ?>, angkatan <?= e((string) $mahasiswa['angkatan']) ?>, <?= $mahasiswa['status_mahasiswa'] === 'alumni' ? 'Alumni, lulus ' . e((string) $mahasiswa['tahun_lulus']) : 'Mahasiswa aktif' ?></p>
            <div class="d-flex flex-wrap items-center gap-8"><?= badgeHtml(labelStatusLamaran($lamaran['status'])) ?><span class="muted fs-88">Melamar <?= e($lamaran['posisi']) ?> pada <?= tanggalIndo($lamaran['tanggal_lamar']) ?></span></div>
          </div>
        </div>
      </div>

      <!-- ===== Revisi E: data yang terkirim saat melamar (tidak berubah walau profil diubah) ===== -->
      <div class="panel"><div class="panel-head"><h3>Data saat melamar</h3><small class="muted">Disalin otomatis dari profil pada <?= tanggalWaktuIndo($snapshot['diambil_pada'] ?? $lamaran['tanggal_lamar']) ?></small></div>
        <dl class="dl">
          <dt>Nama</dt><dd><?= e($snapshot['nama'] ?? $mahasiswa['nama']) ?></dd>
          <dt>NIM</dt><dd><?= e($snapshot['nim'] ?? $mahasiswa['nim']) ?></dd>
          <dt>Email</dt><dd><?= e($snapshot['email'] ?? '-') ?></dd>
          <dt>WhatsApp</dt><dd><?= e($snapshot['no_whatsapp'] ?? '-') ?></dd>
          <dt>Program studi</dt><dd><?= e(trim(($snapshot['jenjang'] ?? '') . ' ' . ($snapshot['prodi'] ?? '-'))) ?><?= !empty($snapshot['jurusan']) ? ', ' . e($snapshot['jurusan']) : '' ?></dd>
          <dt>Angkatan</dt><dd><?= e((string) ($snapshot['angkatan'] ?? '-')) ?><?= ($snapshot['status_mahasiswa'] ?? '') === 'alumni' ? ' (alumni, lulus ' . e((string) ($snapshot['tahun_lulus'] ?? '-')) . ')' : '' ?></dd>
          <dt>IPK</dt><dd><?= e((string) ($snapshot['ipk'] ?? '-') ?: '-') ?></dd>
          <dt>Domisili</dt><dd><?= e(implode(', ', array_filter([$snapshot['alamat'] ?? null, $snapshot['domisili'] ?? null, $snapshot['provinsi'] ?? null])) ?: '-') ?></dd>
          <dt>Skill</dt><dd><?= e(!empty($snapshot['skill']) ? implode(', ', (array) $snapshot['skill']) : '-') ?></dd>
        </dl>
      </div>

      <div class="panel"><div class="panel-head"><h3>Profil terkini</h3><small class="muted">Data terbaru di profil pelamar</small></div>
        <dl class="dl">
          <dt>Email</dt><dd><?= e($mahasiswa['email']) ?><?= $bedaProfil('email', $mahasiswa['email']) ? ' <span class="pill p-revisi">berubah</span>' : '' ?></dd>
          <dt>WhatsApp</dt><dd><?= e($mahasiswa['no_whatsapp']) ?><?= $bedaProfil('no_whatsapp', $mahasiswa['no_whatsapp']) ? ' <span class="pill p-revisi">berubah</span>' : '' ?></dd>
          <dt>IPK</dt><dd><?= e((string) ($mahasiswa['ipk'] ?? '-') ?: '-') ?><?= $bedaProfil('ipk', $mahasiswa['ipk']) ? ' <span class="pill p-revisi">berubah</span>' : '' ?></dd>
          <dt>Domisili</dt><dd><?= e(implode(', ', array_filter([$mahasiswa['alamat'] ?? null, $mahasiswa['domisili'] ?? null, $mahasiswa['provinsi'] ?? null])) ?: '-') ?></dd>
          <dt>Tentang</dt><dd><?= nl2br(e($mahasiswa['tentang'] ?: '-')) ?></dd>
        </dl>
      </div>

      <div class="panel"><h3>Pendidikan</h3>
        <dl class="dl"><dt>Kampus</dt><dd>Politeknik Negeri Malang</dd><dt>Program studi</dt><dd><?= e($mahasiswa['nama_prodi']) ?></dd><dt>Angkatan</dt><dd><?= e((string) $mahasiswa['angkatan']) ?></dd><dt>IPK</dt><dd><?= e((string) ($mahasiswa['ipk'] ?? '-')) ?></dd></dl>
        <?php foreach ($pendidikan as $it): ?><?= kartuItemHtml($it, 'pendidikan') ?><?php endforeach; ?>
      </div>

      <div class="panel"><h3>Skills</h3><div class="chips">
        <?php if (empty($skill)): ?><span class="muted">Belum diisi</span><?php endif; ?>
        <?php foreach ($skill as $s): ?><span class="chip"><?= e($s['nama']) ?></span><?php endforeach; ?>
      </div></div>

      <?php if ($pengalaman): ?>
      <div class="panel"><h3>Pengalaman</h3>
        <?php foreach ($pengalaman as $it): ?><?= kartuItemHtml($it, 'pengalaman') ?><?php endforeach; ?>
      </div>
      <?php endif; ?>

      <?php if ($sertifikat): ?>
      <div class="panel"><h3>Sertifikat</h3>
        <?php foreach ($sertifikat as $it): ?><?= kartuItemHtml($it, 'sertifikat') ?><?php endforeach; ?>
      </div>
      <?php endif; ?>

      <?php if ($portofolio): ?>
      <div class="panel"><h3>Portofolio</h3>
        <?php foreach ($portofolio as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="link"></span><div class="grow"><b><?= e($it['judul']) ?></b><div><a href="<?= e(tautanAman($it['tautan'])) ?>" target="_blank" rel="noopener noreferrer"><?= e($it['tautan']) ?></a></div></div></div>
        <?php endforeach; ?>
      </div>
      <?php endif; ?>

      <div class="panel"><div class="panel-head"><h3>CV yang dikirim (<?= $lamaran['jenis_cv'] === 'unggah' ? 'CV unggahan' : 'CV otomatis' ?>)</h3>
          <a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=cv&file=' . urlencode($lamaran['file_cv'])) ?>" target="_blank"><span data-ic="download"></span>Unduh CV</a></div>
        <div class="cv-paper">
          <div class="d-flex items-center gap-12"><img class="avatar-54" src="<?= e($fotoUrl) ?>" alt=""><div><b class="fs-110"><?= e($snapshot['nama'] ?? $mahasiswa['nama']) ?></b><br><span class="muted"><?= e($snapshot['prodi'] ?? $mahasiswa['nama_prodi']) ?></span></div></div>
          <h4>Pendidikan</h4><p class="m-0"><?= e($snapshot['prodi'] ?? $mahasiswa['nama_prodi']) ?>, Politeknik Negeri Malang (IPK <?= e((string) ($snapshot['ipk'] ?? $mahasiswa['ipk'] ?? '-')) ?>)</p>
          <h4>Skills</h4><p class="m-0"><?= e(implode(', ', array_column($skill, 'nama')) ?: '-') ?></p>
        </div>
      </div>

      <div class="panel"><h3>Dokumen pendukung</h3>
        <div class="list-item"><span class="list-ic" data-ic="file"></span><div class="grow"><b><?= $mahasiswa['status_mahasiswa'] === 'alumni' ? 'Ijazah/SKL' : 'KTM' ?></b></div>
          <a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=ktm&file=' . urlencode($lamaran['file_ktm'])) ?>" target="_blank">Lihat</a></div>
        <div class="list-item"><span class="list-ic" data-ic="file"></span><div class="grow"><b>Surat pengantar</b></div>
          <a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=dokumen_lamaran&file=' . urlencode($lamaran['file_surat_pengantar'])) ?>" target="_blank">Lihat</a></div>
      </div>

      <?php if ($lamaran['catatan_pelamar']): ?>
      <div class="panel"><h3>Catatan tambahan pelamar</h3><p class="m-0"><?= nl2br(e($lamaran['catatan_pelamar'])) ?></p></div>
      <?php endif; ?>
    </div>

    <!-- ===== Kolom kanan: proses seleksi ===== -->
    <div class="sticky">
      <div class="panel">
        <h3>Proses seleksi</h3>
        <?php if ($selesai): ?>
          <div class="alert status-final <?= $lamaran['status'] === 'diterima' ? 'alert-ok' : 'alert-bad' ?>">
            <span data-ic="<?= $lamaran['status'] === 'diterima' ? 'checkc' : 'x' ?>"></span>
            <span><?php
              if ($lamaran['status'] === 'diterima') {
                  echo 'Pelamar sudah diterima. Status karier dan data tracer sudah diperbarui otomatis.';
              } elseif ($lamaran['status'] === 'dibatalkan') {
                  echo 'Lamaran ini dibatalkan sendiri oleh pelamarnya, jadi tidak perlu diproses lagi.';
              } else {
                  echo 'Pelamar sudah ditolak.';
                  if (!empty($lamaran['catatan_perusahaan'])) echo ' ' . e($lamaran['catatan_perusahaan']);
              }
            ?></span>
          </div>
        <?php else: ?>
          <form method="post" action="<?= url('lamaran/ubah-status/' . $lamaran['id']) ?>" id="interview" data-jaga>
            <?= csrfField() ?><input type="hidden" name="aksi" value="jadwal_interview">
            <div class="field"><label><?= $interview ? 'Ubah jadwal interview' : 'Jadwalkan interview' ?></label>
              <div class="hint"><?= $interview ? 'Jadwal tersimpan sudah terisi otomatis di bawah. Pelamar diberi tahu bila jadwal diubah.' : 'Sudah terisi otomatis dari profil perusahaan (alamat kantor, PIC, WhatsApp PIC) dan hari kerja terdekat. Tinggal periksa dan simpan.' ?></div></div>
            <div class="row2">
              <div class="field"><label>Tanggal</label><input class="input" type="date" name="tanggal" min="<?= e(date('Y-m-d')) ?>" required value="<?= e((string) old('tanggal', $isianInterview['tanggal'])) ?>"></div>
              <div class="field"><label>Jam (WIB)</label><input class="input" type="time" name="jam" required value="<?= e(substr((string) old('jam', $isianInterview['jam']), 0, 5)) ?>"></div>
            </div>
            <div class="field">
              <label for="modeInterview">Mode</label>
              <select class="input" id="modeInterview" name="mode">
                <option value="daring" <?= old('mode', $isianInterview['mode']) === 'daring' ? 'selected' : '' ?>>Daring (online)</option>
                <option value="luring" <?= old('mode', $isianInterview['mode']) === 'luring' ? 'selected' : '' ?>>Luring (datang langsung)</option>
              </select>
            </div>

            <div data-mode="daring" hidden>
              <div class="field">
                <label>Tautan meeting <span class="wajib">*</span></label>
                <input class="input" name="lokasi_tautan" type="url"
                       value="<?= e((string) old('lokasi_tautan', $isianInterview['lokasi_tautan'])) ?>"
                       placeholder="https://meet.google.com/abc-defg-hij">
                <small class="muted">Zoom, Google Meet, Microsoft Teams, atau sejenisnya.</small>
              </div>
            </div>

            <div data-mode="luring" hidden>
              <div class="field">
                <label>Nama tempat atau alamat <span class="wajib">*</span></label>
                <input class="input" name="tempat" value="<?= e((string) old('tempat', $isianInterview['tempat'])) ?>"
                       placeholder="Kantor PT Nusantara Digital, Jl. Ijen No. 25, Malang">
              </div>
              <div class="field">
                <label>Ruangan atau lantai</label>
                <input class="input" name="ruangan" value="<?= e((string) old('ruangan', $isianInterview['ruangan'])) ?>" placeholder="Lantai 3, Ruang Meeting B">
              </div>
              <div class="field">
                <label>Pakaian</label>
                <input class="input" name="dresscode" value="<?= e((string) old('dresscode', $isianInterview['dresscode'])) ?>" placeholder="Kemeja putih, celana bahan hitam">
              </div>
              <div class="field">
                <label>Berkas yang perlu dibawa</label>
                <input class="input" name="yang_dibawa" value="<?= e((string) old('yang_dibawa', $isianInterview['yang_dibawa'])) ?>"
                       placeholder="CV cetak, fotokopi KTM, portofolio">
              </div>
              <div class="field">
                <label>Narahubung saat tiba</label>
                <input class="input" name="narahubung" value="<?= e((string) old('narahubung', $isianInterview['narahubung'])) ?>"
                       placeholder="Rina (HR), 0812 3456 7890">
              </div>
            </div>
            <div class="field"><label>Catatan untuk pelamar <span class="muted">(opsional)</span></label><textarea class="input" name="catatan" rows="2"><?= e((string) old('catatan', $isianInterview['catatan'])) ?></textarea></div>
            <button class="btn btn-primary w-100" type="submit" data-proses="Menyimpan..."><?= $interview ? 'Simpan perubahan jadwal' : 'Simpan jadwal interview' ?></button>
          </form>

          <script nonce="<?= cspNonce() ?>">
          function gantiModeInterview(mode) {
            document.querySelectorAll('[data-mode]').forEach(function (blok) {
              var aktif = blok.getAttribute('data-mode') === mode;
              blok.hidden = !aktif;
              blok.querySelectorAll('input, textarea, select').forEach(function (el) {
                el.disabled = !aktif;
              });
            });
          }
          gantiModeInterview(document.getElementById('modeInterview').value);
          document.getElementById('modeInterview').addEventListener('change', function () { gantiModeInterview(this.value); });
          </script>

          <form class="mt-10" method="post" action="<?= url('lamaran/ubah-status/' . $lamaran['id']) ?>" data-konfirmasi="Tolak pelamar ini? Catatan alasan akan dikirim ke pelamar dan keputusan ini final.">
            <?= csrfField() ?><input type="hidden" name="aksi" value="tolak">
            <div class="field"><label for="alasanTolak">Atau, tolak pelamar</label>
              <div class="chips-alasan" data-target="alasanTolak"><small class="muted">Isi cepat:</small><?php foreach ($templateTolak as $tt): ?><button type="button" data-alasan="<?= e($tt) ?>"><?= e(ringkas(preg_replace('/^Terima kasih[^.]*\.\s*/', '', $tt), 60)) ?></button><?php endforeach; ?></div>
              <textarea class="input" id="alasanTolak" name="catatan_perusahaan" rows="3" maxlength="500" minlength="10" placeholder="Alasan penolakan (wajib, min. 10 karakter)" required><?= e((string) old('catatan_perusahaan', '')) ?></textarea></div>
            <button class="btn btn-outline w-100 btn-outline-bad" type="submit" data-proses="Memproses...">Tolak pelamar</button>
          </form>

          <div class="garis-atas mt-16 pt-16">
            <?php if ($kuotaPenuh): ?>
              <div class="alert alert-warn"><span data-ic="alert"></span><span>Kuota lowongan sudah penuh (<?= (int) $lamaran['terisi'] ?>/<?= (int) $lamaran['kuota'] ?>). Naikkan kuota lewat <b>Perpanjang</b> di Lowongan Saya untuk menerima pelamar lagi.</span></div>
            <?php else: ?>
            <button class="btn btn-ok w-100" type="button" data-open="mAccept"><span data-ic="check"></span>Terima pelamar</button>
            <?php endif; ?>
          </div>
        <?php endif; ?>

        <h3 class="fs-100 mt-14">Riwayat</h3>
        <ul class="activity">
          <?php foreach ($riwayat as $r): ?>
            <li><span><b><?= e($labelRiwayat[$r['status']] ?? ucfirst($r['status'])) ?></b><small><?= tanggalWaktuIndo($r['tanggal']) ?></small><?php if ($r['catatan']): ?><br><span class="muted fs-85"><?= e($r['catatan']) ?></span><?php endif; ?></span></li>
          <?php endforeach; ?>
        </ul>
      </div>
    </div>
  </div>
</section>

<?php if (!$selesai && !$kuotaPenuh): ?>
<!-- ===== Modal terima pelamar ===== -->
<div class="modal" id="mAccept" role="dialog" aria-modal="true" aria-labelledby="acT">
  <div class="modal-box">
    <div class="modal-head"><h3 id="acT">Terima pelamar ini?</h3><button class="close" data-close aria-label="Tutup" data-ic="x"></button></div>
    <div class="modal-body">
      <p>Setelah kamu menekan Terima, sistem otomatis memperbarui:</p>
      <ul class="checklist">
        <li><span class="ok" data-ic="checkc"></span>Pelamar menerima notifikasi dan status kariernya menjadi Bekerja.</li>
        <li><span class="ok" data-ic="checkc"></span>Sisa kuota lowongan berkurang satu. Jika penuh, lowongan ditutup.</li>
        <li><span class="ok" data-ic="checkc"></span>Rekap lamaran dan data tracer Career Center bertambah.</li>
      </ul>
    </div>
    <div class="modal-foot">
      <button class="btn btn-outline" type="button" data-close>Batal</button>
      <form method="post" action="<?= url('lamaran/terima/' . $lamaran['id']) ?>"><?= csrfField() ?><button class="btn btn-ok" type="submit" data-proses="Memproses...">Terima pelamar</button></form>
    </div>
  </div>
</div>
<?php endif; ?>

<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
