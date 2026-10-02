<?php
/**
 * View: mahasiswa/profil
 * Dipanggil oleh: MahasiswaController::profil()
 * Variabel: $mahasiswa, $pendidikan, $pengalaman, $sertifikat, $portofolio,
 *           $skillTerpilih, $semuaSkill, $minatTerpilih, $semuaBidang
 *
 * Catatan: item pendidikan/pengalaman/sertifikat/portofolio bisa Ditambah
 * dan Dihapus dari sini. Untuk versi pertama, item tidak bisa diedit
 * langsung (hapus lalu tambah ulang) supaya tidak perlu JS pengisi form.
 */
$page_title = 'Profil Karier';
$active_menu = 'profil';
require __DIR__ . '/../layouts/app-header.php';

$fotoUrl = !empty($mahasiswa['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($mahasiswa['foto'])) : url('assets/img/avatar-1.jpg');
$skillIdTerpilih = array_column($skillTerpilih, 'id');
$minatIdTerpilih = array_column($minatTerpilih, 'id');

$labelStatusKarier = ['bekerja' => 'Bekerja', 'wirausaha' => 'Wirausaha', 'studi lanjut' => 'Studi lanjut', 'mencari kerja' => 'Mencari kerja', 'belum bekerja' => 'Belum bekerja'];
$labelLevelJabatan = ['magang' => 'Magang', 'staf' => 'Staf / junior', 'supervisor' => 'Supervisor', 'manajer' => 'Manajer', 'direksi' => 'Direksi', 'lainnya' => 'Lainnya'];

function tanggalPendekAman(?string $t): string { return $t ? tanggalIndo($t) : ''; }

/** Tombol hapus kecil untuk item pendidikan/pengalaman/sertifikat/portofolio. */
function tombolHapusItem(int $id): string
{
    return '<form method="post" action="' . url('mahasiswa/simpan-profil') . '" onsubmit="return confirm(\'Hapus item ini?\')" style="display:inline">'
        . csrfField()
        . '<input type="hidden" name="aksi" value="item_hapus"><input type="hidden" name="id" value="' . (int) $id . '">'
        . '<button class="btn btn-sm btn-outline" type="submit">Hapus</button></form>';
}
?>
<section class="view active">
  <div class="panel">
    <div class="profile-head">
      <div class="avatar-edit">
        <img class="avatar-lg" id="avatarImg" src="<?= e($fotoUrl) ?>" alt="Foto profil <?= e($mahasiswa['nama']) ?>">
        <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>" enctype="multipart/form-data" id="fotoForm">
          <?= csrfField() ?><input type="hidden" name="aksi" value="foto">
          <label title="Ganti foto"><input type="file" name="foto" accept="image/*" onchange="document.getElementById('fotoForm').submit()"><span data-ic="image"></span></label>
        </form>
      </div>
      <div class="grow">
        <h1 style="font-size:1.6rem;margin:0"><?= e($mahasiswa['nama']) ?> <span class="verified" data-ic="check">Terverifikasi</span></h1>
        <p class="muted" style="margin:2px 0 10px">NIM <?= e($mahasiswa['nim']) ?>, <?= e($mahasiswa['jenjang'] . ' ' . $mahasiswa['nama_prodi']) ?>, angkatan <?= e((string) $mahasiswa['angkatan']) ?></p>
        <div style="display:flex;justify-content:space-between;font-size:.9rem;margin-bottom:6px"><span class="muted">Kelengkapan profil</span><b><?= (int) $kelengkapan ?>%</b></div>
        <div class="progress"><i style="width:<?= (int) $kelengkapan ?>%"></i></div>
      </div>
    </div>
    <div class="cv-box">
      <div class="cv-opt"><span class="feature-ic" data-ic="wand"></span><div class="grow"><b>CV otomatis</b><div class="muted" style="font-size:.88rem">Dibuat dari data profil terbaru</div></div><a class="btn btn-primary btn-sm" href="<?= url('mahasiswa/generate-cv') ?>" target="_blank">Buat &amp; unduh CV</a></div>
      <div class="cv-opt">
        <span class="feature-ic" data-ic="upload"></span><div class="grow"><b>CV unggahan</b><div class="muted" style="font-size:.88rem" id="cvName"><?= !empty($mahasiswa['file_cv']) ? 'Sudah diunggah' : 'Belum ada CV diunggah' ?></div></div>
        <form method="post" action="<?= url('mahasiswa/unggah-cv') ?>" enctype="multipart/form-data" id="cvForm">
          <?= csrfField() ?>
          <label class="btn btn-outline btn-sm">Ganti<input type="file" name="file_cv" accept=".pdf" hidden onchange="document.getElementById('cvForm').submit()"></label>
        </form>
      </div>
    </div>
  </div>

  <div class="panel">
    <div class="tabs" data-tabs="profPanes" id="profTabs">
      <button class="active" data-tab="diri">Data diri</button>
      <button data-tab="pendidikan">Pendidikan</button>
      <button data-tab="skill">Skills</button>
      <button data-tab="pengalaman">Pengalaman</button>
      <button data-tab="sertifikat">Sertifikat</button>
      <button data-tab="portofolio">Portofolio</button>
      <button data-tab="dokumen">Dokumen</button>
      <button data-tab="minat">Bidang minat</button>
      <button data-tab="karier" id="karier">Status karier</button>
    </div>
    <div id="profPanes">

      <form data-pane="diri" method="post" action="<?= url('mahasiswa/simpan-profil') ?>">
        <?= csrfField() ?><input type="hidden" name="aksi" value="data_diri">
        <div class="row2">
          <div class="field"><label>Nama lengkap</label><input class="input" name="nama" value="<?= e($mahasiswa['nama']) ?>" required></div>
          <div class="field"><label>Email</label><input class="input" value="<?= e($mahasiswa['email'] ?? Auth::penggunaSaatIni()['email']) ?>" disabled><div class="hint">Ubah email di <a href="<?= url('mahasiswa/pengaturan-akun') ?>">Pengaturan Akun</a>.</div></div>
          <div class="field"><label>Nomor WhatsApp</label><input class="input" name="no_whatsapp" value="<?= e($mahasiswa['no_whatsapp']) ?>" required></div>
          <div class="field"><label>Domisili</label><input class="input" name="domisili" value="<?= e($mahasiswa['domisili'] ?? '') ?>"></div>
          <div class="field"><label>IPK</label><input class="input" name="ipk" type="number" step="0.01" min="0" max="4" value="<?= e((string) ($mahasiswa['ipk'] ?? '')) ?>"></div>
        </div>
        <div class="field"><label>Tentang saya</label><textarea class="input" name="tentang" rows="3"><?= e($mahasiswa['tentang'] ?? '') ?></textarea></div>
        <button class="btn btn-primary" type="submit">Simpan data diri</button>
      </form>

      <div data-pane="pendidikan" hidden>
        <?php foreach ($pendidikan as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="graduation"></span>
            <div class="grow"><b><?= e($it['judul']) ?></b><div class="muted"><?= e($it['instansi']) ?>, <?= e(tanggalPendekAman($it['mulai'])) ?> sampai <?= $it['selesai'] ? e(tanggalPendekAman($it['selesai'])) : 'sekarang' ?></div><?php if ($it['deskripsi']): ?><p style="margin:6px 0 0"><?= nl2br(e($it['deskripsi'])) ?></p><?php endif; ?></div>
            <?= tombolHapusItem($it['id']) ?>
          </div>
        <?php endforeach; ?>
        <button class="btn btn-outline" onclick="bukaTambahItem('pendidikan')" style="margin-top:12px" type="button"><span data-ic="plus"></span>Tambah pendidikan</button>
      </div>

      <div data-pane="skill" hidden>
        <p class="muted">Centang skill yang kamu kuasai. Kalau skill kamu belum ada di daftar, tambahkan sendiri lewat kotak di bawah.</p>

        <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>">
          <?= csrfField() ?><input type="hidden" name="aksi" value="skill">
          <div class="chips">
            <?php if (!$semuaSkill): ?>
              <span class="muted">Daftar skill masih kosong. Tambahkan skill pertamamu di kotak bawah.</span>
            <?php endif; ?>
            <?php foreach ($semuaSkill as $s): $dicentang = in_array($s['id'], $skillIdTerpilih, true); ?>
              <label class="chip pickable"><input type="checkbox" name="skill_id[]" value="<?= (int) $s['id'] ?>" <?= $dicentang ? 'checked' : '' ?>><?= e($s['nama']) ?></label>
            <?php endforeach; ?>
          </div>
          <?php if ($semuaSkill): ?><button class="btn btn-primary" style="margin-top:16px">Simpan skill</button><?php endif; ?>
        </form>

        <div style="margin-top:22px;padding-top:18px;border-top:1px solid var(--line)">
          <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>">
            <?= csrfField() ?><input type="hidden" name="aksi" value="skill_baru">
            <label class="field-label" for="skillBaru">Tambah skill baru</label>
            <div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:6px">
              <input class="input" id="skillBaru" name="skill_nama" style="flex:1;min-width:240px"
                     placeholder="Misalnya: Laravel, Tableau, Public Speaking" required maxlength="300">
              <button class="btn btn-primary" type="submit"><span data-ic="plus"></span>Tambah skill</button>
            </div>
            <small class="muted" style="display:block;margin-top:6px">Bisa sekaligus beberapa, pisahkan dengan koma.</small>
          </form>
        </div>

        <?php if ($skillSaya): ?>
          <div style="margin-top:22px">
            <label class="field-label">Skill yang sudah ada di profilmu</label>
            <div class="chips" style="margin-top:8px">
              <?php foreach ($skillSaya as $s): ?>
                <span class="chip" style="padding-right:6px"><?= e($s['nama']) ?>
                  <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>" style="display:inline">
                    <?= csrfField() ?>
                    <input type="hidden" name="aksi" value="skill_hapus">
                    <input type="hidden" name="skill_id" value="<?= (int) $s['id'] ?>">
                    <button type="submit" title="Hapus <?= e($s['nama']) ?>"
                            style="background:none;border:0;cursor:pointer;color:var(--muted);padding:0 4px;font-size:1rem">&times;</button>
                  </form>
                </span>
              <?php endforeach; ?>
            </div>
          </div>
        <?php endif; ?>
      </div>

      <div data-pane="pengalaman" hidden>
        <?php foreach ($pengalaman as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="briefcase"></span>
            <div class="grow"><b><?= e($it['judul']) ?></b><div class="muted"><?= e($it['instansi']) ?>, <?= e(tanggalPendekAman($it['mulai'])) ?> sampai <?= $it['selesai'] ? e(tanggalPendekAman($it['selesai'])) : 'sekarang' ?></div><?php if ($it['deskripsi']): ?><p style="margin:6px 0 0"><?= nl2br(e($it['deskripsi'])) ?></p><?php endif; ?></div>
            <?= tombolHapusItem($it['id']) ?>
          </div>
        <?php endforeach; ?>
        <button class="btn btn-outline" onclick="bukaTambahItem('pengalaman')" style="margin-top:12px" type="button"><span data-ic="plus"></span>Tambah pengalaman</button>
      </div>

      <div data-pane="sertifikat" hidden>
        <?php foreach ($sertifikat as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="shield"></span>
            <div class="grow"><b><?= e($it['judul']) ?></b><div class="muted">Diterbitkan <?= e(tanggalPendekAman($it['mulai'])) ?></div></div>
            <?php if ($it['file']): ?><a class="btn btn-sm btn-outline" href="<?= url('unduh.php?tipe=portofolio&file=' . urlencode($it['file'])) ?>" target="_blank">Lihat file</a><?php endif; ?>
            <?= tombolHapusItem($it['id']) ?>
          </div>
        <?php endforeach; ?>
        <button class="btn btn-outline" onclick="bukaTambahItem('sertifikat')" style="margin-top:12px" type="button"><span data-ic="plus"></span>Tambah sertifikat</button>
      </div>

      <div data-pane="portofolio" hidden>
        <p class="muted">Tautan ini ikut terkirim otomatis setiap kali kamu melamar.</p>
        <?php foreach ($portofolio as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="link"></span>
            <div class="grow"><b><?= e($it['judul']) ?></b><div><a href="<?= e($it['tautan']) ?>" target="_blank" rel="noopener"><?= e($it['tautan']) ?></a></div></div>
            <?= tombolHapusItem($it['id']) ?>
          </div>
        <?php endforeach; ?>
        <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>" style="display:grid;grid-template-columns:180px 1fr auto;gap:8px;margin-top:14px">
          <?= csrfField() ?><input type="hidden" name="aksi" value="item_tambah"><input type="hidden" name="tipe" value="portofolio">
          <select class="input" name="judul"><option>GitHub</option><option>Behance</option><option>Google Drive</option><option>Website pribadi</option><option>LinkedIn</option></select>
          <input class="input" name="tautan" type="url" placeholder="https://" required>
          <button class="btn btn-primary">Tambah</button>
        </form>
      </div>

      <form data-pane="dokumen" hidden method="post" action="<?= url('mahasiswa/simpan-profil') ?>" enctype="multipart/form-data">
        <?= csrfField() ?><input type="hidden" name="aksi" value="dokumen">
        <p class="muted">Dokumen ini otomatis terlampir saat kamu melamar. Surat pengantar bisa diganti setiap kali melamar.</p>
        <?php if ((!empty($mahasiswa['file_ktm']) && !berkasAda($mahasiswa['file_ktm'], 'ktm', 'ijazah'))
               || (!empty($mahasiswa['file_surat_pengantar']) && !berkasAda($mahasiswa['file_surat_pengantar'], 'surat_pengantar', 'dokumen_lamaran'))): ?>
          <div class="alert alert-bad"><span data-ic="alert"></span><span>
            Ada dokumen yang tercatat di sistem tetapi berkasnya tidak ditemukan lagi di penyimpanan.
            Biasanya terjadi kalau folder aplikasi dipindah atau diganti. Unggah ulang di bawah ini.
          </span></div>
        <?php endif; ?>
        <div class="row2">
          <div class="field"><label><?= ($mahasiswa['status_mahasiswa'] ?? 'aktif') === 'alumni' ? 'Ijazah atau SKL' : 'KTM' ?></label>
            <label class="upload"><input type="file" name="file_ktm" accept=".pdf,.jpg,.jpeg,.png"><span data-ic="checkc"></span><div class="name"><?= e(labelBerkas($mahasiswa['file_ktm'] ?? null, 'ktm', 'ijazah')) ?></div><div class="hint">Klik untuk mengganti. PDF, JPG, PNG maks. 2 MB</div></label></div>
          <div class="field"><label>Surat pengantar umum</label>
            <label class="upload"><input type="file" name="file_surat_pengantar" accept=".pdf"><span data-ic="checkc"></span><div class="name"><?= e(labelBerkas($mahasiswa['file_surat_pengantar'] ?? null, 'surat_pengantar', 'dokumen_lamaran')) ?></div><div class="hint">Klik untuk mengganti. PDF maks. 2 MB</div></label></div>
        </div>
        <button class="btn btn-primary">Simpan dokumen</button>
      </form>

      <div data-pane="minat" hidden>
        <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>">
          <?= csrfField() ?><input type="hidden" name="aksi" value="minat">
          <p class="muted">Kamu akan menerima notifikasi saat ada lowongan baru di bidang ini.</p>
          <div class="chips" style="margin-bottom:16px">
            <?php foreach ($semuaBidang as $b): $dicentang = in_array($b['id'], $minatIdTerpilih, true); ?>
              <label class="chip pickable"><input type="checkbox" name="bidang_id[]" value="<?= (int) $b['id'] ?>" <?= $dicentang ? 'checked' : '' ?>><?= e($b['nama']) ?></label>
            <?php endforeach; ?>
          </div>
          <button class="btn btn-primary">Simpan minat</button>
        </form>
      </div>

      <form data-pane="karier" hidden method="post" action="<?= url('mahasiswa/status-karier') ?>">
        <?= csrfField() ?>
        <?php if (!empty($mahasiswa['karier_diperbarui_pada'])): ?>
          <div class="alert alert-ok"><span data-ic="checkc"></span><span>Terakhir diperbarui <?= tanggalIndo($mahasiswa['karier_diperbarui_pada']) ?>.</span></div>
        <?php endif; ?>

        <p class="muted">Pilih status yang paling sesuai. Kolom isian di bawahnya akan menyesuaikan sendiri, jadi kamu tidak perlu mengisi nama perusahaan kalau memang belum bekerja.</p>

        <div class="field" style="max-width:340px">
          <label for="statusKarier">Status karier saat ini</label>
          <select class="input" id="statusKarier" name="status_karier" onchange="gantiFormKarier(this.value)">
            <?php foreach ($labelStatusKarier as $val => $lbl): ?>
              <option value="<?= e($val) ?>" <?= ($mahasiswa['status_karier'] ?? '') === $val ? 'selected' : '' ?>><?= e($lbl) ?></option>
            <?php endforeach; ?>
          </select>
        </div>

        <!-- ================= BEKERJA ================= -->
        <div data-karier="bekerja" hidden>
          <div class="row2">
            <div class="field"><label>Nama perusahaan <span class="wajib">*</span></label><input class="input" name="tempat_kerja" value="<?= e($mahasiswa['tempat_kerja'] ?? '') ?>" placeholder="PT Nusantara Digital"></div>
            <div class="field"><label>Posisi <span class="wajib">*</span></label><input class="input" name="posisi_kerja" value="<?= e($mahasiswa['posisi_kerja'] ?? '') ?>" placeholder="Web Developer"></div>
            <div class="field"><label>Level jabatan</label>
              <select class="input" name="level_jabatan">
                <option value="">Pilih level</option>
                <?php foreach ($labelLevelJabatan as $val => $lbl): ?><option value="<?= e($val) ?>" <?= ($mahasiswa['level_jabatan'] ?? '') === $val ? 'selected' : '' ?>><?= e($lbl) ?></option><?php endforeach; ?>
              </select>
            </div>
            <div class="field"><label>Tanggal mulai bekerja</label><input class="input" type="date" name="tanggal_mulai_kerja" value="<?= e($mahasiswa['tanggal_mulai_kerja'] ?? '') ?>"></div>
          </div>
        </div>

        <!-- ================= WIRAUSAHA ================= -->
        <div data-karier="wirausaha" hidden>
          <div class="row2">
            <div class="field"><label>Nama usaha <span class="wajib">*</span></label><input class="input" name="tempat_kerja" value="<?= e($mahasiswa['tempat_kerja'] ?? '') ?>" placeholder="Kopi Kenangan Malang"></div>
            <div class="field"><label>Peran kamu di usaha <span class="wajib">*</span></label><input class="input" name="posisi_kerja" value="<?= e($mahasiswa['posisi_kerja'] ?? '') ?>" placeholder="Pemilik, Co-founder"></div>
            <div class="field"><label>Tanggal mulai usaha</label><input class="input" type="date" name="tanggal_mulai_kerja" value="<?= e($mahasiswa['tanggal_mulai_kerja'] ?? '') ?>"></div>
            <div class="field"><label>Bidang usaha</label><input class="input" name="karier_bidang_minat" value="<?= e($mahasiswa['karier_bidang_minat'] ?? '') ?>" placeholder="Kuliner, Jasa desain"></div>
          </div>
        </div>

        <!-- ================= STUDI LANJUT ================= -->
        <div data-karier="studi lanjut" hidden>
          <div class="field" style="max-width:340px">
            <label>Tahap saat ini</label>
            <select class="input" name="karier_tahap_studi">
              <?php foreach (['rencana' => 'Masih rencana', 'diterima' => 'Sudah diterima', 'sedang berjalan' => 'Sedang berkuliah'] as $val => $lbl): ?>
                <option value="<?= e($val) ?>" <?= ($mahasiswa['karier_tahap_studi'] ?? '') === $val ? 'selected' : '' ?>><?= e($lbl) ?></option>
              <?php endforeach; ?>
            </select>
          </div>
          <div class="row2">
            <div class="field"><label>Nama perguruan tinggi <span class="wajib">*</span></label><input class="input" name="tempat_kerja" value="<?= e($mahasiswa['tempat_kerja'] ?? '') ?>" placeholder="Universitas Brawijaya"></div>
            <div class="field"><label>Fakultas</label><input class="input" name="karier_fakultas" value="<?= e($mahasiswa['karier_fakultas'] ?? '') ?>" placeholder="Fakultas Ilmu Komputer"></div>
            <div class="field"><label>Program studi <span class="wajib">*</span></label><input class="input" name="posisi_kerja" value="<?= e($mahasiswa['posisi_kerja'] ?? '') ?>" placeholder="S1 Teknik Informatika"></div>
            <div class="field"><label>Perkiraan tanggal mulai</label><input class="input" type="date" name="tanggal_mulai_kerja" value="<?= e($mahasiswa['tanggal_mulai_kerja'] ?? '') ?>"></div>
          </div>
        </div>

        <!-- ================= MENCARI KERJA ================= -->
        <div data-karier="mencari kerja" hidden>
          <div class="row2">
            <div class="field"><label>Bidang karier yang diminati</label><input class="input" name="karier_bidang_minat" value="<?= e($mahasiswa['karier_bidang_minat'] ?? '') ?>" placeholder="Teknologi Informasi, Konstruksi"></div>
            <div class="field"><label>Posisi yang dituju</label><input class="input" name="karier_rencana_posisi" value="<?= e($mahasiswa['karier_rencana_posisi'] ?? '') ?>" placeholder="Frontend Developer, QA Engineer"></div>
          </div>
          <div class="alert alert-info"><span data-ic="info"></span><span>Bidang yang kamu isi di sini membantu Career Center melihat kebutuhan lulusan. Untuk rekomendasi lowongan, isi juga tab <b>Bidang minat</b>.</span></div>
        </div>

        <!-- ================= BELUM BEKERJA ================= -->
        <div data-karier="belum bekerja" hidden>
          <div class="field">
            <label>Bidang yang ingin kamu tekuni ke depan</label>
            <input class="input" name="karier_bidang_minat" value="<?= e($mahasiswa['karier_bidang_minat'] ?? '') ?>" placeholder="Misalnya: Jaringan komputer, Akuntansi, Desain grafis">
            <small class="muted">Boleh dikosongkan kalau belum tahu. Status ini tidak memerlukan data perusahaan.</small>
          </div>
        </div>

        <div class="field">
          <label>Catatan tambahan <span class="muted">(opsional)</span></label>
          <textarea class="input" name="karier_catatan" rows="2" placeholder="Hal lain yang ingin kamu sampaikan ke Career Center"><?= e($mahasiswa['karier_catatan'] ?? '') ?></textarea>
        </div>

        <button class="btn btn-primary">Simpan status karier</button>
      </form>

      <script>
      /* Menampilkan hanya blok isian milik status yang sedang dipilih, sekaligus
         menonaktifkan input milik status lain supaya tidak ikut terkirim
         (kalau ikut terkirim, nama field yang sama bisa saling menimpa). */
      function gantiFormKarier(status) {
        document.querySelectorAll('[data-karier]').forEach(function (blok) {
          var aktif = blok.getAttribute('data-karier') === status;
          blok.hidden = !aktif;
          blok.querySelectorAll('input, select, textarea').forEach(function (el) {
            el.disabled = !aktif;
          });
        });
      }
      gantiFormKarier(document.getElementById('statusKarier').value);
      </script>

    </div>
  </div>
</section>

<!-- Modal: tambah item pendidikan/pengalaman/sertifikat -->
<div class="modal" id="mItem" role="dialog" aria-modal="true" aria-labelledby="iT">
  <div class="modal-box">
    <div class="modal-head"><h3 id="iT">Tambah data</h3><button class="close" data-close aria-label="Tutup" data-ic="x"></button></div>
    <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>" enctype="multipart/form-data">
      <?= csrfField() ?><input type="hidden" name="aksi" value="item_tambah"><input type="hidden" name="tipe" id="itemTipe" value="pendidikan">
      <div class="modal-body">
        <div class="field"><label>Judul atau posisi</label><input class="input" name="judul" required placeholder="Misalnya Magang Frontend Developer"></div>
        <div class="field"><label>Instansi</label><input class="input" name="instansi" placeholder="Nama perusahaan atau sekolah"></div>
        <div class="row2"><div class="field"><label>Mulai</label><input class="input" name="mulai" type="date"></div><div class="field"><label>Selesai <span class="muted">(kosongkan bila masih berjalan)</span></label><input class="input" name="selesai" type="date"></div></div>
        <div class="field"><label>Deskripsi</label><textarea class="input" name="deskripsi" rows="3"></textarea></div>
        <div class="field" id="itemFileField" hidden><label>File pendukung <span class="muted">(opsional)</span></label><label class="upload"><input type="file" name="file" accept=".pdf,.jpg,.jpeg,.png"><span data-ic="upload"></span><div><b>Pilih file</b></div></label></div>
      </div>
      <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Batal</button><button type="submit" class="btn btn-primary">Simpan</button></div>
    </form>
  </div>
</div>

<script>
function bukaTambahItem(tipe) {
  document.getElementById('itemTipe').value = tipe;
  document.getElementById('iT').textContent = tipe === 'pendidikan' ? 'Tambah pendidikan' : (tipe === 'pengalaman' ? 'Tambah pengalaman' : 'Tambah sertifikat');
  document.getElementById('itemFileField').hidden = tipe !== 'sertifikat';
  openModal('mItem');
}
</script>

<?php require __DIR__ . '/../layouts/app-footer.php'; ?>