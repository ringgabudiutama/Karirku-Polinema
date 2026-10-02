<?php
/**
 * View: perusahaan/pelamar-detail
 * Dipanggil oleh: LamaranController::detailPelamar($id)
 * Variabel: $lamaran, $mahasiswa, $profilItem, $skill, $riwayat, $interview
 */
$page_title = 'Detail Pelamar';
$active_menu = 'pelamar';
require __DIR__ . '/../layouts/app-header.php';

$fotoUrl = !empty($mahasiswa['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($mahasiswa['foto'])) : url('assets/img/avatar-1.jpg');
/* Lamaran yang sudah selesai tidak lagi bisa diproses. 'dibatalkan' berarti
   pelamarnya sendiri yang menarik lamaran, jadi ikut dihitung selesai supaya
   perusahaan tidak menjadwalkan interview untuk lamaran yang sudah ditarik. */
$selesai = in_array($lamaran['status'], ['diterima', 'ditolak', 'dibatalkan'], true);
$per = fn($tipe) => array_values(array_filter($profilItem, fn($i) => $i['tipe'] === $tipe));
$pendidikan = $per('pendidikan');
$pengalaman = $per('pengalaman');
$sertifikat = $per('sertifikat');
$portofolio = $per('portofolio');
$snapshot = json_decode($lamaran['snapshot_profil'] ?? '{}', true) ?: [];

$labelRiwayat = ['diajukan' => 'Lamaran diajukan', 'screening' => 'CV dibuka, status Screening CV', 'interview' => 'Interview dijadwalkan', 'diterima' => 'Pelamar diterima', 'ditolak' => 'Pelamar ditolak', 'dibatalkan' => 'Lamaran dibatalkan pelamar'];
?>
<section class="view active">
  <div class="crumb"><a href="<?= url('perusahaan/pelamar') ?>">Pelamar</a> <span>/</span> <span><?= e($mahasiswa['nama']) ?></span></div>

  <div class="grid g-side" style="align-items:start">
    <div>
      <div class="panel">
        <div class="profile-head">
          <img class="avatar-lg" src="<?= e($fotoUrl) ?>" alt="Foto <?= e($mahasiswa['nama']) ?>">
          <div class="grow">
            <h1 style="font-size:1.6rem;margin:0"><?= e($mahasiswa['nama']) ?> <span class="verified" data-ic="check">Terverifikasi</span></h1>
            <p class="muted" style="margin:2px 0 8px"><?= e($mahasiswa['jenjang'] . ' ' . $mahasiswa['nama_prodi']) ?>, angkatan <?= e((string) $mahasiswa['angkatan']) ?>, <?= $mahasiswa['status_mahasiswa'] === 'alumni' ? 'Alumni, lulus ' . e((string) $mahasiswa['tahun_lulus']) : 'Mahasiswa aktif' ?></p>
            <div style="display:flex;gap:8px;flex-wrap:wrap;align-items:center"><?= badgeHtml(labelStatusLamaran($lamaran['status'])) ?><span class="muted" style="font-size:.88rem">Melamar <?= e($lamaran['posisi']) ?> pada <?= tanggalIndo($lamaran['tanggal_lamar']) ?></span></div>
          </div>
        </div>
      </div>

      <div class="panel"><h3>Data diri</h3>
        <dl class="dl"><dt>Email</dt><dd><?= e($mahasiswa['email']) ?></dd><dt>WhatsApp</dt><dd><?= e($mahasiswa['no_whatsapp']) ?></dd><dt>Domisili</dt><dd><?= e($mahasiswa['domisili'] ?: '-') ?></dd><dt>Tentang</dt><dd><?= nl2br(e($mahasiswa['tentang'] ?: '-')) ?></dd></dl>
      </div>

      <div class="panel"><h3>Pendidikan</h3>
        <dl class="dl"><dt>Kampus</dt><dd>Politeknik Negeri Malang</dd><dt>Program studi</dt><dd><?= e($mahasiswa['nama_prodi']) ?></dd><dt>Angkatan</dt><dd><?= e((string) $mahasiswa['angkatan']) ?></dd><dt>IPK</dt><dd><?= e((string) ($mahasiswa['ipk'] ?? '-')) ?></dd></dl>
        <?php foreach ($pendidikan as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="graduation"></span><div class="grow"><b><?= e($it['judul']) ?></b><div class="muted"><?= e($it['instansi']) ?></div></div></div>
        <?php endforeach; ?>
      </div>

      <div class="panel"><h3>Skills</h3><div class="chips">
        <?php if (empty($skill)): ?><span class="muted">Belum diisi</span><?php endif; ?>
        <?php foreach ($skill as $s): ?><span class="chip"><?= e($s['nama']) ?></span><?php endforeach; ?>
      </div></div>

      <?php if ($pengalaman): ?>
      <div class="panel"><h3>Pengalaman</h3>
        <?php foreach ($pengalaman as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="briefcase"></span><div class="grow"><b><?= e($it['judul']) ?></b><div class="muted"><?= e($it['instansi']) ?>, <?= tanggalIndo($it['mulai']) ?> sampai <?= $it['selesai'] ? tanggalIndo($it['selesai']) : 'sekarang' ?></div></div></div>
        <?php endforeach; ?>
      </div>
      <?php endif; ?>

      <?php if ($sertifikat): ?>
      <div class="panel"><h3>Sertifikat</h3>
        <?php foreach ($sertifikat as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="shield"></span><div class="grow"><b><?= e($it['judul']) ?></b><div class="muted"><?= tanggalIndo($it['mulai']) ?></div></div><?php if (berkasAda($it['file'] ?? null, 'portofolio')): ?>
            <a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=portofolio&file=' . urlencode($it['file'])) ?>" target="_blank">Lihat file</a>
          <?php elseif (!empty($it['file'])): ?>
            <span class="muted" style="font-size:.85rem">Berkas tidak ditemukan</span>
          <?php endif; ?></div>
        <?php endforeach; ?>
      </div>
      <?php endif; ?>

      <?php if ($portofolio): ?>
      <div class="panel"><h3>Portofolio</h3>
        <?php foreach ($portofolio as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="link"></span><div class="grow"><b><?= e($it['judul']) ?></b><div><a href="<?= e($it['tautan']) ?>" target="_blank" rel="noopener"><?= e($it['tautan']) ?></a></div></div></div>
        <?php endforeach; ?>
      </div>
      <?php endif; ?>

      <div class="panel"><div class="panel-head"><h3>CV yang dikirim (<?= $lamaran['jenis_cv'] === 'unggah' ? 'CV unggahan' : 'CV otomatis' ?>)</h3>
          <a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=cv&file=' . urlencode($lamaran['file_cv'])) ?>" target="_blank"><span data-ic="download"></span>Unduh CV</a></div>
        <div class="cv-paper">
          <div style="display:flex;gap:12px;align-items:center"><img src="<?= e($fotoUrl) ?>" alt="" style="width:54px;height:54px;border-radius:50%;object-fit:cover"><div><b style="font-size:1.1rem"><?= e($snapshot['nama'] ?? $mahasiswa['nama']) ?></b><br><span class="muted"><?= e($snapshot['prodi'] ?? $mahasiswa['nama_prodi']) ?></span></div></div>
          <h4>Pendidikan</h4><p style="margin:0"><?= e($snapshot['prodi'] ?? $mahasiswa['nama_prodi']) ?>, Politeknik Negeri Malang (IPK <?= e((string) ($snapshot['ipk'] ?? $mahasiswa['ipk'] ?? '-')) ?>)</p>
          <h4>Skills</h4><p style="margin:0"><?= e(implode(', ', array_column($skill, 'nama')) ?: '-') ?></p>
        </div>
      </div>

      <div class="panel"><h3>Dokumen pendukung</h3>
        <div class="list-item"><span class="list-ic" data-ic="file"></span><div class="grow"><b><?= $mahasiswa['status_mahasiswa'] === 'alumni' ? 'Ijazah/SKL' : 'KTM' ?></b></div>
          <a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=ktm&file=' . urlencode($lamaran['file_ktm'])) ?>" target="_blank">Lihat</a></div>
        <div class="list-item"><span class="list-ic" data-ic="file"></span><div class="grow"><b>Surat pengantar</b></div>
          <a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=dokumen_lamaran&file=' . urlencode($lamaran['file_surat_pengantar'])) ?>" target="_blank">Lihat</a></div>
      </div>

      <?php if ($lamaran['catatan_pelamar']): ?>
      <div class="panel"><h3>Catatan tambahan pelamar</h3><p style="margin:0"><?= nl2br(e($lamaran['catatan_pelamar'])) ?></p></div>
      <?php endif; ?>
    </div>

    <div class="sticky">
      <div class="panel">
        <h3>Proses seleksi</h3>
        <?php if ($selesai): ?>
          <div class="alert <?= $lamaran['status'] === 'diterima' ? 'alert-ok' : 'alert-bad' ?>">
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
          <form method="post" action="<?= url('lamaran/ubah-status/' . $lamaran['id']) ?>" id="formInterview">
            <?= csrfField() ?><input type="hidden" name="aksi" value="jadwal_interview">
            <div class="field"><label>Jadwalkan interview</label></div>
            <div class="row2">
              <div class="field"><label>Tanggal</label><input class="input" type="date" name="tanggal" value="<?= e($interview['tanggal'] ?? '') ?>"></div>
              <div class="field"><label>Jam</label><input class="input" type="time" name="jam" value="<?= e(substr($interview['jam'] ?? '', 0, 5)) ?>"></div>
            </div>
            <div class="field">
              <label for="modeInterview">Mode</label>
              <select class="input" id="modeInterview" name="mode" onchange="gantiModeInterview(this.value)">
                <option value="daring" <?= ($interview['mode'] ?? 'daring') === 'daring' ? 'selected' : '' ?>>Daring (online)</option>
                <option value="luring" <?= ($interview['mode'] ?? '') === 'luring' ? 'selected' : '' ?>>Luring (datang langsung)</option>
              </select>
            </div>

            <!-- ============ ISIAN KHUSUS DARING ============ -->
            <div data-mode="daring" hidden>
              <div class="field">
                <label>Tautan meeting <span class="wajib">*</span></label>
                <input class="input" name="lokasi_tautan" type="url"
                       value="<?= ($interview['mode'] ?? '') !== 'luring' ? e($interview['lokasi_tautan'] ?? '') : '' ?>"
                       placeholder="https://meet.google.com/abc-defg-hij">
                <small class="muted">Zoom, Google Meet, Microsoft Teams, atau sejenisnya.</small>
              </div>
            </div>

            <!-- ============ ISIAN KHUSUS LURING ============ -->
            <div data-mode="luring" hidden>
              <div class="field">
                <label>Nama tempat atau alamat <span class="wajib">*</span></label>
                <input class="input" name="tempat" value="<?= e($interview['tempat'] ?? '') ?>"
                       placeholder="Kantor PT Nusantara Digital, Jl. Ijen No. 25, Malang">
              </div>
              <div class="field">
                <label>Ruangan atau lantai</label>
                <input class="input" name="ruangan" value="<?= e($interview['ruangan'] ?? '') ?>" placeholder="Lantai 3, Ruang Meeting B">
              </div>
              <div class="field">
                <label>Pakaian</label>
                <input class="input" name="dresscode" value="<?= e($interview['dresscode'] ?? '') ?>" placeholder="Kemeja putih, celana bahan hitam">
              </div>
              <div class="field">
                <label>Berkas yang perlu dibawa</label>
                <input class="input" name="yang_dibawa" value="<?= e($interview['yang_dibawa'] ?? '') ?>"
                       placeholder="CV cetak, fotokopi KTM, portofolio">
              </div>
              <div class="field">
                <label>Narahubung saat tiba</label>
                <input class="input" name="narahubung" value="<?= e($interview['narahubung'] ?? '') ?>"
                       placeholder="Rina (HR), 0812 3456 7890">
              </div>
            </div>
            <div class="field"><label>Catatan untuk pelamar <span class="muted">(opsional)</span></label><textarea class="input" name="catatan" rows="2"><?= e($interview['catatan'] ?? '') ?></textarea></div>
            <button class="btn btn-primary" style="width:100%" type="submit">Simpan jadwal interview</button>
          </form>

          <script>
          /* Menampilkan hanya isian milik mode yang dipilih. Input mode lain
             ikut dinonaktifkan supaya tidak terkirim dan tidak memicu validasi
             "wajib diisi" untuk field yang sedang tidak terlihat. */
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
          </script>

          <form method="post" action="<?= url('lamaran/ubah-status/' . $lamaran['id']) ?>" onsubmit="return confirm('Tolak pelamar ini? Catatan alasan akan dikirim ke pelamar.')" style="margin-top:10px">
            <?= csrfField() ?><input type="hidden" name="aksi" value="tolak">
            <div class="field"><label>Atau, tolak pelamar</label><textarea class="input" name="catatan_perusahaan" rows="2" placeholder="Alasan penolakan (wajib diisi)" required></textarea></div>
            <button class="btn btn-outline" style="width:100%;color:var(--bad);border-color:var(--bad)" type="submit">Tolak pelamar</button>
          </form>

          <div style="border-top:1px solid var(--line);margin:16px 0 0;padding-top:16px">
            <button class="btn btn-ok" style="width:100%" type="button" data-open="mAccept"><span data-ic="check"></span>Terima pelamar</button>
          </div>
        <?php endif; ?>

        <h3 style="margin-top:14px;font-size:1rem">Riwayat</h3>
        <ul class="activity">
          <?php foreach ($riwayat as $r): ?>
            <li><span><b><?= e($labelRiwayat[$r['status']] ?? ucfirst($r['status'])) ?></b><small><?= tanggalWaktuIndo($r['tanggal']) ?></small><?php if ($r['catatan']): ?><br><span class="muted" style="font-size:.85rem"><?= e($r['catatan']) ?></span><?php endif; ?></span></li>
          <?php endforeach; ?>
        </ul>
      </div>
    </div>
  </div>
</section>

<?php if (!$selesai): ?>
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
      <button class="btn btn-outline" data-close>Batal</button>
      <form method="post" action="<?= url('lamaran/terima/' . $lamaran['id']) ?>"><?= csrfField() ?><button class="btn btn-ok" type="submit">Terima pelamar</button></form>
    </div>
  </div>
</div>
<?php endif; ?>

<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
