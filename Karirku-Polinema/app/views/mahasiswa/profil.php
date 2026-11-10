<?php
// ===== FRONTEND · MAHASISWA · Profil karier ==========================
$page_title = 'Profil Karier';
$active_menu = 'profil';
require __DIR__ . '/../layouts/app-header.php';

$fotoUrl = !empty($mahasiswa['foto']) ? url('unduh.php?tipe=foto&file=' . urlencode($mahasiswa['foto'])) : url('assets/img/avatar-1.jpg');
$skillIdTerpilih = array_column($skillTerpilih, 'id');
$minatIdTerpilih = array_column($minatTerpilih, 'id');

$labelStatusKarier = ['bekerja' => 'Bekerja', 'wirausaha' => 'Wirausaha', 'studi lanjut' => 'Studi lanjut', 'mencari kerja' => 'Mencari kerja', 'belum bekerja' => 'Belum bekerja'];
$labelLevelJabatan = ['magang' => 'Magang', 'staf' => 'Staf / junior', 'supervisor' => 'Supervisor', 'manajer' => 'Manajer', 'direksi' => 'Direksi', 'lainnya' => 'Lainnya'];

function tanggalPendekAman(?string $t): string { return $t ? tanggalIndo($t) : ''; }

// Auto input pendidikan Polinema dari data akun (NIM, jurusan, prodi, angkatan, IPK).
$adaPolinema = (bool) array_filter($pendidikan, fn($p) => stripos((string) $p['instansi'], 'Politeknik Negeri Malang') !== false);
$jenjangPeta = ['D-II' => 'D2', 'D-III' => 'D3', 'D-IV' => 'D4 / Sarjana Terapan', 'S2' => 'S2 Terapan', 'S2 Terapan' => 'S2 Terapan', 'D-I' => 'D1'];
$bawaanPolinema = [
    'jenjang' => $jenjangPeta[$mahasiswa['jenjang'] ?? ''] ?? '',
    'instansi' => 'Politeknik Negeri Malang',
    'judul' => trim(($mahasiswa['jenjang'] ?? '') . ' ' . ($mahasiswa['nama_prodi'] ?? '')),
    'fakultas' => 'Jurusan ' . ($mahasiswa['nama_jurusan'] ?? ''),
    'nomor_induk' => $mahasiswa['nim'] ?? '',
    'kota' => 'Malang',
    'mulai' => !empty($mahasiswa['angkatan']) ? $mahasiswa['angkatan'] . '-08-25' : '',
    'selesai' => ($mahasiswa['status_mahasiswa'] ?? '') === 'alumni' && !empty($mahasiswa['tahun_lulus']) ? $mahasiswa['tahun_lulus'] . '-08-30' : '',
    'nilai' => $mahasiswa['ipk'] !== null && $mahasiswa['ipk'] !== '' ? str_replace('.', ',', (string) $mahasiswa['ipk']) : '',
    'skala' => '4,00',
];

// --- Helper tombol hapus item ---
function tombolHapusItem(int $id): string
{
    return '<form class="d-inline" method="post" action="' . url('mahasiswa/simpan-profil') . '" data-konfirmasi="Hapus item ini?">'
        . csrfField()
        . '<input type="hidden" name="aksi" value="item_hapus"><input type="hidden" name="id" value="' . (int) $id . '">'
        . '<button class="btn btn-sm btn-outline" type="submit">Hapus</button></form>';
}
?>
<section class="view active">
  <?= kepalaKembali('mahasiswa/dashboard', [['Dashboard', 'mahasiswa/dashboard'], ['Profil karier']]) ?>
  <div class="panel">
    <!-- ===== Kepala profil & CV ===== -->
    <div class="profile-head">
      <div class="avatar-edit">
        <img class="avatar-lg" id="avatarImg" src="<?= e($fotoUrl) ?>" alt="Foto profil <?= e($mahasiswa['nama']) ?>">
        <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>" enctype="multipart/form-data" id="fotoForm">
          <?= csrfField() ?><input type="hidden" name="aksi" value="foto">
          <label title="Ganti foto"><input type="file" name="foto" accept=".jpg,.jpeg,.png" data-kirim-otomatis data-label="Foto profil" data-maks-kb="2048" data-sekarang="<?= e($fotoUrl) ?>"><span data-ic="image"></span></label>
        </form>
      </div>
      <div class="grow">
        <h1 class="fs-160 m-0"><?= e($mahasiswa['nama']) ?> <span class="verified" data-ic="check">Terverifikasi</span></h1>
        <p class="muted m-0 mt-2 mb-10">NIM <?= e($mahasiswa['nim']) ?>, <?= e($mahasiswa['jenjang'] . ' ' . $mahasiswa['nama_prodi']) ?>, angkatan <?= e((string) $mahasiswa['angkatan']) ?></p>
        <div class="progress-label"><span class="muted">Kelengkapan profil</span><b><?= (int) $kelengkapan ?>%</b></div>
        <div class="progress"><i style="width:<?= (int) $kelengkapan ?>%"></i></div>
      </div>
    </div>
    <div class="cv-box">
      <div class="cv-opt"><span class="feature-ic" data-ic="wand"></span><div class="grow"><b>CV otomatis</b><div class="muted fs-88">Dibuat dari data profil terbaru</div></div><a class="btn btn-primary btn-sm" href="<?= url('mahasiswa/generate-cv') ?>" target="_blank">Buat &amp; unduh CV</a></div>
      <div class="cv-opt">
        <span class="feature-ic" data-ic="upload"></span><div class="grow"><b>CV unggahan</b><div class="muted fs-88" id="cvName"><?php if (!empty($mahasiswa['file_cv']) && $mahasiswa['file_cv'] !== 'cv-sistem.pdf'): ?>Sudah diunggah · <a href="<?= url('unduh.php?tipe=cv&file=' . urlencode($mahasiswa['file_cv'])) ?>" target="_blank" rel="noopener">Lihat CV</a><?php else: ?>Belum ada CV diunggah<?php endif; ?></div></div>
        <form method="post" action="<?= url('mahasiswa/unggah-cv') ?>" enctype="multipart/form-data" id="cvForm">
          <?= csrfField() ?>
          <label class="btn btn-outline btn-sm"><?= !empty($mahasiswa['file_cv']) ? 'Ganti' : 'Unggah' ?><input type="file" name="file_cv" accept=".pdf" hidden data-kirim-otomatis data-label="CV unggahan (PDF)" data-maks-kb="2048"></label>
        </form>
      </div>
    </div>
  </div>

  <div class="panel">
    <!-- ===== Tab profil ===== -->
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

      <!-- ===== Tab: data diri ===== -->
      <form data-pane="diri" method="post" action="<?= url('mahasiswa/simpan-profil') ?>" data-draft="data-diri" data-jaga>
        <?= csrfField() ?><input type="hidden" name="aksi" value="data_diri">
        <div class="row2">
          <div class="field"><label>Nama lengkap</label><input class="input" name="nama" value="<?= e((string) old('nama', $mahasiswa['nama'])) ?>" required></div>
          <div class="field"><label>Email</label><input class="input" value="<?= e($mahasiswa['email'] ?? Auth::penggunaSaatIni()['email']) ?>" disabled><div class="hint">Ubah email di <a href="<?= url('mahasiswa/pengaturan-akun') ?>">Pengaturan Akun</a>.</div></div>
          <div class="field"><label>Nomor WhatsApp</label><input class="input" name="no_whatsapp" value="<?= e((string) old('no_whatsapp', $mahasiswa['no_whatsapp'])) ?>" required></div>
          <div class="field"><label>Domisili</label><input class="input" value="<?= e(implode(', ', array_filter([$mahasiswa['domisili'] ?? null, $mahasiswa['provinsi'] ?? null])) ?: 'Belum diisi') ?>" disabled><div class="hint">Ubah alamat di <a href="<?= url('mahasiswa/pengaturan-akun#alamat') ?>">Pengaturan Akun</a>.</div></div>
          <div class="field"><label>IPK</label><input class="input" name="ipk" type="number" step="0.01" min="0" max="4" value="<?= e((string) old('ipk', $mahasiswa['ipk'] ?? '')) ?>"></div>
        </div>
        <div class="field"><label>Tentang saya</label><textarea class="input" name="tentang" rows="3" maxlength="2000"><?= e((string) old('tentang', $mahasiswa['tentang'] ?? '')) ?></textarea></div>
        <button class="btn btn-primary" type="submit">Simpan data diri</button>
      </form>

      <!-- ===== Tab: pendidikan ===== -->
      <div data-pane="pendidikan" hidden>
        <p class="muted"><?= e(SKEMA_ITEM['pendidikan']['petunjuk']) ?></p>
        <?php if (!$pendidikan): ?><div class="kosong-kotak"><span data-ic="<?= SKEMA_ITEM['pendidikan']['ikon'] ?>"></span><p>Belum ada data. Klik tombol di bawah untuk menambahkan.</p></div><?php endif; ?>
        <?php foreach ($pendidikan as $it): ?>
          <?= kartuItemHtml($it, 'pendidikan', '<button type="button" class="btn btn-sm btn-outline" data-open="mUbah' . (int) $it['id'] . '"><span data-ic="edit"></span>Ubah</button>' . tombolHapusItem($it['id'])) ?>
        <?php endforeach; ?>
        <div class="d-flex flex-wrap gap-8 mt-12">
          <?php if (!$adaPolinema): ?><button class="btn btn-primary" type="button" data-open="mTambahPolinema"><span data-ic="wand"></span>Tambah pendidikan Polinema (terisi otomatis)</button><?php endif; ?>
          <button class="btn btn-outline" type="button" data-open="mTambahpendidikan"><span data-ic="plus"></span>Tambah pendidikan lain</button>
        </div>
      </div>
      <!-- ===== Tab: skill ===== -->
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
          <?php if ($semuaSkill): ?><button class="btn btn-primary mt-16" type="submit" data-proses="Menyimpan...">Simpan skill</button><?php endif; ?>
        </form>

        <div class="garis-atas mt-22 pt-18">
          <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>">
            <?= csrfField() ?><input type="hidden" name="aksi" value="skill_baru">
            <label class="field-label" for="skillBaru">Tambah skill baru</label>
            <div class="d-flex flex-wrap gap-10 mt-6">
              <input class="input flex-1 min-w-240" id="skillBaru" name="skill_nama"
                     placeholder="Misalnya: Laravel, Tableau, Public Speaking" required maxlength="300">
              <button class="btn btn-primary" type="submit"><span data-ic="plus"></span>Tambah skill</button>
            </div>
            <small class="muted d-block mt-6">Bisa sekaligus beberapa, pisahkan dengan koma.</small>
          </form>
        </div>

        <?php if ($skillSaya): ?>
          <div class="mt-22">
            <label class="field-label">Skill yang sudah ada di profilmu</label>
            <div class="chips mt-8">
              <?php foreach ($skillSaya as $s): ?>
                <span class="chip pr-6"><?= e($s['nama']) ?>
                  <form class="d-inline" method="post" action="<?= url('mahasiswa/simpan-profil') ?>">
                    <?= csrfField() ?>
                    <input type="hidden" name="aksi" value="skill_hapus">
                    <input type="hidden" name="skill_id" value="<?= (int) $s['id'] ?>">
                    <button class="chip-x" type="submit" title="Hapus <?= e($s['nama']) ?>"
                           >&times;</button>
                  </form>
                </span>
              <?php endforeach; ?>
            </div>
          </div>
        <?php endif; ?>
      </div>

      <!-- ===== Tab: pengalaman ===== -->
      <div data-pane="pengalaman" hidden>
        <p class="muted"><?= e(SKEMA_ITEM['pengalaman']['petunjuk']) ?></p>
        <?php if (!$pengalaman): ?><div class="kosong-kotak"><span data-ic="<?= SKEMA_ITEM['pengalaman']['ikon'] ?>"></span><p>Belum ada data. Klik tombol di bawah untuk menambahkan.</p></div><?php endif; ?>
        <?php foreach ($pengalaman as $it): ?>
          <?= kartuItemHtml($it, 'pengalaman', '<button type="button" class="btn btn-sm btn-outline" data-open="mUbah' . (int) $it['id'] . '"><span data-ic="edit"></span>Ubah</button>' . tombolHapusItem($it['id'])) ?>
        <?php endforeach; ?>
        <button class="btn btn-outline mt-12" type="button" data-open="mTambahpengalaman"><span data-ic="plus"></span>Tambah pengalaman</button>
      </div>

      <!-- ===== Tab: sertifikat ===== -->
      <div data-pane="sertifikat" hidden>
        <p class="muted"><?= e(SKEMA_ITEM['sertifikat']['petunjuk']) ?></p>
        <?php if (!$sertifikat): ?><div class="kosong-kotak"><span data-ic="<?= SKEMA_ITEM['sertifikat']['ikon'] ?>"></span><p>Belum ada data. Klik tombol di bawah untuk menambahkan.</p></div><?php endif; ?>
        <?php foreach ($sertifikat as $it): ?>
          <?= kartuItemHtml($it, 'sertifikat', '<button type="button" class="btn btn-sm btn-outline" data-open="mUbah' . (int) $it['id'] . '"><span data-ic="edit"></span>Ubah</button>' . tombolHapusItem($it['id'])) ?>
        <?php endforeach; ?>
        <button class="btn btn-outline mt-12" type="button" data-open="mTambahsertifikat"><span data-ic="plus"></span>Tambah sertifikat</button>
      </div>

      <!-- ===== Tab: portofolio ===== -->
      <div data-pane="portofolio" hidden>
        <p class="muted">Tautan ini ikut terkirim otomatis setiap kali kamu melamar.</p>
        <?php foreach ($portofolio as $it): ?>
          <div class="list-item"><span class="list-ic" data-ic="link"></span>
            <div class="grow"><b><?= e($it['judul']) ?></b><div><a href="<?= e(tautanAman($it['tautan'])) ?>" target="_blank" rel="noopener noreferrer"><?= e($it['tautan']) ?></a></div></div>
            <?= tombolHapusItem($it['id']) ?>
          </div>
        <?php endforeach; ?>
        <form class="form-portofolio" method="post" action="<?= url('mahasiswa/simpan-profil') ?>">
          <?= csrfField() ?><input type="hidden" name="aksi" value="item_tambah"><input type="hidden" name="tipe" value="portofolio">
          <select class="input" name="judul"><option>GitHub</option><option>Behance</option><option>Google Drive</option><option>Website pribadi</option><option>LinkedIn</option></select>
          <input class="input" name="tautan" type="url" placeholder="https://" required>
          <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Tambah</button>
        </form>
      </div>

      <!-- ===== Tab: dokumen ===== -->
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
        <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Simpan dokumen</button>
      </form>

      <!-- ===== Tab: bidang minat ===== -->
      <div data-pane="minat" hidden>
        <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>">
          <?= csrfField() ?><input type="hidden" name="aksi" value="minat">
          <p class="muted">Kamu akan menerima notifikasi saat ada lowongan baru di bidang ini.</p>
          <div class="chips mb-16">
            <?php foreach ($semuaBidang as $b): $dicentang = in_array($b['id'], $minatIdTerpilih, true); ?>
              <label class="chip pickable"><input type="checkbox" name="bidang_id[]" value="<?= (int) $b['id'] ?>" <?= $dicentang ? 'checked' : '' ?>><?= e($b['nama']) ?></label>
            <?php endforeach; ?>
          </div>
          <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Simpan minat</button>
        </form>
      </div>

      <?php
        // Revisi G + auto input: isian karier = isian gagal sebelumnya > data tersimpan > lamaran yang diterima.
        $kOto = $karierOtomatis ?? null;
        $kIsi = $mahasiswa;
        if ($kOto && trim((string) ($mahasiswa['tempat_kerja'] ?? '')) === '') {
            $kIsi['tempat_kerja'] = $kOto['nama_perusahaan'];
            $kIsi['posisi_kerja'] = $kOto['posisi'];
            $kIsi['tanggal_mulai_kerja'] = $kOto['tanggal_diterima'];
            if (in_array($mahasiswa['status_karier'] ?? '', ['', 'mencari kerja', 'belum bekerja'], true)) $kIsi['status_karier'] = 'bekerja';
        }
        $kv = fn(string $k) => e((string) old($k, $kIsi[$k] ?? ''));
      ?>
      <!-- ===== Tab: status karier ===== -->
      <form data-pane="karier" hidden method="post" action="<?= url('mahasiswa/status-karier') ?>">
        <?= csrfField() ?>
        <?php if ($kOto && trim((string) ($mahasiswa['tempat_kerja'] ?? '')) === ''): ?>
          <div class="alert alert-info"><span data-ic="wand"></span><span>Terisi otomatis dari lamaran yang diterima: <b><?= e($kOto['posisi']) ?></b> di <b><?= e($kOto['nama_perusahaan']) ?></b>. Periksa lalu simpan.</span></div>
        <?php endif; ?>
        <?php if (!empty($mahasiswa['karier_diperbarui_pada'])): ?>
          <div class="alert alert-ok"><span data-ic="checkc"></span><span>Terakhir diperbarui <?= tanggalIndo($mahasiswa['karier_diperbarui_pada']) ?>.</span></div>
        <?php endif; ?>

        <p class="muted">Pilih status yang paling sesuai. Kolom isian di bawahnya akan menyesuaikan sendiri, jadi kamu tidak perlu mengisi nama perusahaan kalau memang belum bekerja.</p>

        <div class="field max-w-340">
          <label for="statusKarier">Status karier saat ini</label>
          <select class="input" id="statusKarier" name="status_karier">
            <?php foreach ($labelStatusKarier as $val => $lbl): ?>
              <option value="<?= e($val) ?>" <?= (string) old('status_karier', $kIsi['status_karier'] ?? '') === $val ? 'selected' : '' ?>><?= e($lbl) ?></option>
            <?php endforeach; ?>
          </select>
        </div>

        <div data-karier="bekerja" hidden>
          <div class="row2">
            <div class="field"><label>Nama perusahaan <span class="wajib">*</span></label><input class="input" name="tempat_kerja" value="<?= $kv('tempat_kerja') ?>" placeholder="PT Nusantara Digital"></div>
            <div class="field"><label>Posisi <span class="wajib">*</span></label><input class="input" name="posisi_kerja" value="<?= $kv('posisi_kerja') ?>" placeholder="Web Developer"></div>
            <div class="field"><label>Level jabatan</label>
              <select class="input" name="level_jabatan">
                <option value="">Pilih level</option>
                <?php foreach ($labelLevelJabatan as $val => $lbl): ?><option value="<?= e($val) ?>" <?= (string) old('level_jabatan', $kIsi['level_jabatan'] ?? '') === $val ? 'selected' : '' ?>><?= e($lbl) ?></option><?php endforeach; ?>
              </select>
            </div>
            <div class="field"><label>Tanggal mulai bekerja</label><input class="input" type="date" name="tanggal_mulai_kerja" value="<?= $kv('tanggal_mulai_kerja') ?>"></div>
          </div>
        </div>

        <div data-karier="wirausaha" hidden>
          <div class="row2">
            <div class="field"><label>Nama usaha <span class="wajib">*</span></label><input class="input" name="tempat_kerja" value="<?= $kv('tempat_kerja') ?>" placeholder="Kopi Kenangan Malang"></div>
            <div class="field"><label>Peran kamu di usaha <span class="wajib">*</span></label><input class="input" name="posisi_kerja" value="<?= $kv('posisi_kerja') ?>" placeholder="Pemilik, Co-founder"></div>
            <div class="field"><label>Tanggal mulai usaha</label><input class="input" type="date" name="tanggal_mulai_kerja" value="<?= $kv('tanggal_mulai_kerja') ?>"></div>
            <div class="field"><label>Bidang usaha</label><input class="input" name="karier_bidang_minat" value="<?= $kv('karier_bidang_minat') ?>" placeholder="Kuliner, Jasa desain"></div>
          </div>
        </div>

        <div data-karier="studi lanjut" hidden>
          <div class="field max-w-340">
            <label>Tahap saat ini</label>
            <select class="input" name="karier_tahap_studi">
              <?php foreach (['rencana' => 'Masih rencana', 'diterima' => 'Sudah diterima', 'sedang berjalan' => 'Sedang berkuliah'] as $val => $lbl): ?>
                <option value="<?= e($val) ?>" <?= (string) old('karier_tahap_studi', $kIsi['karier_tahap_studi'] ?? '') === $val ? 'selected' : '' ?>><?= e($lbl) ?></option>
              <?php endforeach; ?>
            </select>
          </div>
          <div class="row2">
            <div class="field"><label>Nama perguruan tinggi <span class="wajib">*</span></label><input class="input" name="tempat_kerja" value="<?= $kv('tempat_kerja') ?>" placeholder="Universitas Brawijaya"></div>
            <div class="field"><label>Fakultas</label><input class="input" name="karier_fakultas" value="<?= $kv('karier_fakultas') ?>" placeholder="Fakultas Ilmu Komputer"></div>
            <div class="field"><label>Program studi <span class="wajib">*</span></label><input class="input" name="posisi_kerja" value="<?= $kv('posisi_kerja') ?>" placeholder="S1 Teknik Informatika"></div>
            <div class="field"><label>Perkiraan tanggal mulai</label><input class="input" type="date" name="tanggal_mulai_kerja" value="<?= $kv('tanggal_mulai_kerja') ?>"></div>
          </div>
        </div>

        <div data-karier="mencari kerja" hidden>
          <div class="row2">
            <div class="field"><label>Bidang karier yang diminati</label><input class="input" name="karier_bidang_minat" value="<?= $kv('karier_bidang_minat') ?>" placeholder="Teknologi Informasi, Konstruksi"></div>
            <div class="field"><label>Posisi yang dituju</label><input class="input" name="karier_rencana_posisi" value="<?= $kv('karier_rencana_posisi') ?>" placeholder="Frontend Developer, QA Engineer"></div>
          </div>
          <div class="alert alert-info"><span data-ic="info"></span><span>Bidang yang kamu isi di sini membantu Career Center melihat kebutuhan lulusan. Untuk rekomendasi lowongan, isi juga tab <b>Bidang minat</b>.</span></div>
        </div>

        <div data-karier="belum bekerja" hidden>
          <div class="field">
            <label>Bidang yang ingin kamu tekuni ke depan</label>
            <input class="input" name="karier_bidang_minat" value="<?= $kv('karier_bidang_minat') ?>" placeholder="Misalnya: Jaringan komputer, Akuntansi, Desain grafis">
            <small class="muted">Boleh dikosongkan kalau belum tahu. Status ini tidak memerlukan data perusahaan.</small>
          </div>
        </div>

        <div class="field">
          <label>Catatan tambahan <span class="muted">(opsional)</span></label>
          <textarea class="input" name="karier_catatan" rows="2" placeholder="Hal lain yang ingin kamu sampaikan ke Career Center"><?= $kv('karier_catatan') ?></textarea>
        </div>

        <button class="btn btn-primary" type="submit" data-proses="Menyimpan...">Simpan status karier</button>
      </form>

      <script nonce="<?= cspNonce() ?>">
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
      document.getElementById('statusKarier').addEventListener('change', function () { gantiFormKarier(this.value); });
      </script>

    </div>
  </div>
</section>

<!-- ===== Modal tambah / ubah pendidikan, pengalaman, sertifikat (revisi tahap 2) ===== -->
<?php
$modalItem = function (string $id, string $judul, string $tipe, ?array $item = null, array $bawaan = []) {
    ?>
<div class="modal" id="<?= e($id) ?>" role="dialog" aria-modal="true" aria-labelledby="<?= e($id) ?>T">
  <div class="modal-box lg">
    <div class="modal-head"><h3 id="<?= e($id) ?>T"><?= e($judul) ?></h3><button class="close" type="button" data-close aria-label="Tutup" data-ic="x"></button></div>
    <form method="post" action="<?= url('mahasiswa/simpan-profil') ?>" enctype="multipart/form-data" data-jaga>
      <?= csrfField() ?>
      <input type="hidden" name="aksi" value="<?= $item ? 'item_ubah' : 'item_tambah' ?>"><input type="hidden" name="tipe" value="<?= e($tipe) ?>">
      <?php if ($item): ?><input type="hidden" name="id" value="<?= (int) $item['id'] ?>"><?php endif; ?>
      <div class="modal-body"><?= formItemHtml($tipe, $item, $bawaan) ?></div>
      <div class="modal-foot"><button type="button" class="btn btn-outline" data-close>Batal</button><button type="submit" class="btn btn-primary" data-proses="Menyimpan..."><?= $item ? 'Simpan perubahan' : 'Simpan' ?></button></div>
    </form>
  </div>
</div>
    <?php
};
$modalItem('mTambahPolinema', 'Tambah pendidikan di Polinema', 'pendidikan', null, $bawaanPolinema);
foreach (['pendidikan' => 'Tambah pendidikan', 'pengalaman' => 'Tambah pengalaman', 'sertifikat' => 'Tambah sertifikat'] as $t => $j) {
    $modalItem('mTambah' . $t, $j, $t);
}
foreach (['pendidikan', 'pengalaman', 'sertifikat'] as $t) {
    foreach ($$t as $it) $modalItem('mUbah' . (int) $it['id'], 'Ubah ' . strtolower(SKEMA_ITEM[$t]['judul_tab']), $t, $it);
}
?>

<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
