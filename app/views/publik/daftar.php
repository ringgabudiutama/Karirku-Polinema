<?php
/**
 * View: publik/daftar
 * Dipanggil oleh: AuthController::formDaftar()
 * Variabel tersedia: $jurusan, $prodi, $peranTerpilih
 */
$f = flashAmbil();

// Kelompokkan prodi per jurusan_id untuk dropdown bertingkat di JS.
$prodiPerJurusan = [];
foreach ($prodi as $p) {
    $prodiPerJurusan[$p['jurusan_id']][] = $p;
}

$tahunSekarang = (int) date('Y');
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Daftar | KarirKu Polinema</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<?= url('assets/css/style.css') ?>">
</head>
<body>
<header class="simple-top">
  <div class="container">
    <a class="brand" href="<?= url('beranda') ?>"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu Polinema</span></a>
    <span style="margin-left:auto" class="muted">Sudah punya akun? <a href="<?= url('masuk') ?>"><b>Masuk</b></a></span>
  </div>
</header>

<main class="auth-main" style="align-items:flex-start;padding-top:40px;background:var(--sky);min-height:calc(100vh - 68px)">
  <div class="auth-box wide">

    <?php if ($f): ?>
      <div class="alert alert-<?= $f['tipe'] === 'ok' ? 'ok' : 'bad' ?>"><span data-ic="alert"></span><span><?= e($f['pesan']) ?></span></div>
    <?php endif; ?>

    <!-- Step 0: pilih peran -->
    <section id="s0" <?= $peranTerpilih ? 'hidden' : '' ?>>
      <a class="back" href="<?= url('beranda') ?>"><span data-ic="left"></span>Kembali ke beranda</a>
      <h1 style="font-size:2rem">Daftar ke KarirKu</h1>
      <p class="muted">Pilih peranmu. Data yang diminta berbeda untuk setiap peran.</p>
      <div class="role-cards">
        <button type="button" class="role-card" data-role="mahasiswa"><span class="feature-ic" data-ic="graduation"></span><b>Mahasiswa atau alumni</b><span>Khusus civitas Politeknik Negeri Malang. Cari dan lamar lowongan.</span></button>
        <button type="button" class="role-card" data-role="perusahaan"><span class="feature-ic" data-ic="building"></span><b>Perusahaan</b><span>Pasang lowongan dan rekrut lulusan vokasi Polinema.</span></button>
      </div>
      <button type="button" class="btn btn-primary" id="startBtn" disabled style="width:100%;padding:13px">Lanjut</button>
    </section>

    <!-- Form -->
    <section id="sForm" <?= $peranTerpilih ? '' : 'hidden' ?>>
      <button type="button" class="back btn-link" id="changeRole" style="padding:0"><span data-ic="left"></span>Ganti peran</button>
      <h1 style="font-size:1.8rem" id="formTitle">Daftar sebagai mahasiswa atau alumni</h1>
      <div class="stepper" aria-label="Langkah pendaftaran">
        <div class="s on" data-s="1"><i>1</i><span>Akun</span></div><div class="ln"></div>
        <div class="s" data-s="2"><i>2</i><span id="st2">Data diri</span></div><div class="ln"></div>
        <div class="s" data-s="3"><i>3</i><span>Dokumen</span></div>
      </div>
      <div class="panel">
        <form id="regForm" method="post" action="<?= url('auth/proses-daftar') ?>" enctype="multipart/form-data" novalidate>
          <?= csrfField() ?>
          <input type="hidden" name="peran" id="peranInput" value="<?= e($peranTerpilih ?: '') ?>">

          <!-- langkah 1 -->
          <div data-step="1">
            <div class="field mhs-only"><label for="nama">Nama lengkap</label><input class="input" id="nama" name="nama" required placeholder="Sesuai KTM atau ijazah"><div class="err">Nama lengkap wajib diisi.</div></div>
            <div class="field"><label for="remail" id="lblEmail">Email</label><input class="input" id="remail" name="email" type="email" required placeholder="nama@email.com"><div class="err">Masukkan email yang valid.</div><div class="hint">Info status akun dikirim ke email ini.</div></div>
            <div class="field mhs-only"><label for="wa">Nomor WhatsApp</label><input class="input" id="wa" name="no_whatsapp" inputmode="tel" required placeholder="08xxxxxxxxxx"><div class="err">Nomor WhatsApp wajib diisi.</div></div>
            <div class="row2">
              <div class="field"><label for="p1">Kata sandi</label><div class="pw"><input class="input" id="p1" name="password" type="password" required minlength="8" placeholder="Minimal 8 karakter"><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div><div class="err">Kata sandi minimal 8 karakter.</div></div>
              <div class="field"><label for="p2">Ulangi kata sandi</label><div class="pw"><input class="input" id="p2" name="konfirmasi_password" type="password" required placeholder="Ketik ulang"><button type="button" aria-label="Tampilkan kata sandi" data-ic="eye"></button></div><div class="err">Kata sandi belum sama.</div></div>
            </div>
          </div>

          <!-- langkah 2 mahasiswa -->
          <div data-step="2" class="mhs-only" hidden>
            <div class="row2">
              <div class="field"><label for="nim">NIM</label><input class="input" id="nim" name="nim" required inputmode="numeric" placeholder="8-20 digit"><div class="err">NIM harus 8-20 digit angka.</div></div>
              <div class="field"><label for="status">Status</label><select class="input" id="status" name="status_mahasiswa"><option value="aktif">Mahasiswa aktif</option><option value="alumni">Alumni</option></select></div>
            </div>
            <div class="row2">
              <div class="field"><label for="jur">Jurusan</label>
                <select class="input" id="jur" required>
                  <option value="">Pilih jurusan</option>
                  <?php foreach ($jurusan as $j): ?>
                    <option value="<?= (int) $j['id'] ?>"><?= e($j['nama']) ?></option>
                  <?php endforeach; ?>
                </select>
                <div class="err">Pilih jurusan.</div>
              </div>
              <div class="field"><label for="prodi">Program studi</label>
                <select class="input" id="prodi" name="program_studi_id" required><option value="">Pilih jurusan dulu</option></select>
                <div class="err">Pilih program studi.</div>
              </div>
            </div>
            <div class="row2">
              <div class="field"><label for="angk">Angkatan</label>
                <select class="input" id="angk" name="angkatan">
                  <?php for ($y = $tahunSekarang; $y >= $tahunSekarang - 10; $y--): ?>
                    <option value="<?= $y ?>"><?= $y ?></option>
                  <?php endfor; ?>
                </select>
              </div>
              <div class="field" id="lulusField" hidden><label for="lulus">Tahun lulus</label>
                <select class="input" id="lulus" name="tahun_lulus">
                  <?php for ($y = $tahunSekarang + 1; $y >= $tahunSekarang - 10; $y--): ?>
                    <option value="<?= $y ?>"><?= $y ?></option>
                  <?php endfor; ?>
                </select>
              </div>
            </div>
          </div>

          <!-- langkah 2 perusahaan -->
          <div data-step="2" class="pt-only" hidden>
            <div class="field"><label for="ptnama">Nama perusahaan</label><input class="input" id="ptnama" name="nama_perusahaan" required placeholder="PT Contoh Sejahtera"><div class="err">Nama perusahaan wajib diisi.</div></div>
            <div class="row2">
              <div class="field"><label for="bidang">Bidang usaha</label><input class="input" id="bidang" name="bidang_usaha" required placeholder="Contoh: Teknologi Informasi"><div class="err">Bidang usaha wajib diisi.</div></div>
              <div class="field"><label for="jenis">Jenis perusahaan</label>
                <select class="input" id="jenis" name="jenis_perusahaan">
                  <option>Swasta Nasional</option><option>BUMN / BUMD</option><option>Multinasional</option><option>Startup</option><option>UMKM</option>
                </select>
              </div>
            </div>
            <div class="row2">
              <div class="field"><label for="alamat">Alamat kantor</label><input class="input" id="alamat" name="alamat" required placeholder="Jalan, nomor"><div class="err">Alamat wajib diisi.</div></div>
              <div class="field"><label for="kota">Kota</label><input class="input" id="kota" name="kota" required placeholder="Contoh: Malang"><div class="err">Kota wajib diisi.</div></div>
            </div>
            <div class="row2">
              <div class="field"><label for="web">Website <span class="muted">(opsional)</span></label><input class="input" id="web" name="website" placeholder="https://"></div>
              <div class="field"><label for="pic">Nama PIC</label><input class="input" id="pic" name="nama_pic" required placeholder="Penanggung jawab rekrutmen"><div class="err">Nama PIC wajib diisi.</div></div>
            </div>
            <div class="row2">
              <div class="field"><label for="jab">Jabatan PIC</label><input class="input" id="jab" name="jabatan_pic" placeholder="HR Manager"></div>
              <div class="field"><label for="picwa">WhatsApp PIC</label><input class="input" id="picwa" name="whatsapp_pic" required inputmode="tel" placeholder="08xxxxxxxxxx"><div class="err">Nomor WhatsApp PIC wajib diisi.</div></div>
            </div>
          </div>

          <!-- langkah 3 -->
          <div data-step="3" hidden>
            <div class="field mhs-only">
              <label id="docLabel">Unggah KTM</label>
              <label class="upload"><input type="file" id="doc" name="file_dokumen" accept=".pdf,.jpg,.jpeg,.png"><span data-ic="upload"></span><div><b>Pilih file</b> atau seret ke sini</div><div class="hint">PDF, JPG, atau PNG. Maksimal 2 MB.</div></label>
              <div class="err">Dokumen wajib diunggah.</div>
            </div>
            <div class="pt-only">
              <h3>Dokumen legalitas perusahaan</h3>
              <p class="muted" style="font-size:.9rem">PDF, JPG, atau PNG. Maksimal 2 MB per file.</p>
              <div class="row2">
                <div class="field"><label>NIB <span style="color:var(--bad)">*</span></label>
                  <label class="upload"><input type="file" id="docpt" name="file_nib" data-req accept=".pdf,.jpg,.jpeg,.png"><span data-ic="upload"></span><div><b>Pilih file NIB</b></div></label>
                  <div class="err">NIB wajib diunggah.</div></div>
                <div class="field"><label>NPWP perusahaan <span style="color:var(--bad)">*</span></label>
                  <label class="upload"><input type="file" id="docnpwp" name="file_npwp" data-req accept=".pdf,.jpg,.jpeg,.png"><span data-ic="upload"></span><div><b>Pilih file NPWP</b></div></label>
                  <div class="err">NPWP perusahaan wajib diunggah.</div></div>
                <div class="field"><label>Akta pendirian <span style="color:var(--bad)">*</span></label>
                  <label class="upload"><input type="file" id="docakta" name="file_akta" data-req accept=".pdf,.jpg,.jpeg,.png"><span data-ic="upload"></span><div><b>Pilih file akta</b></div></label>
                  <div class="err">Akta pendirian wajib diunggah.</div></div>
                <div class="field"><label>Surat keterangan domisili <span class="muted">(opsional)</span></label>
                  <label class="upload"><input type="file" name="file_domisili" accept=".pdf,.jpg,.jpeg,.png"><span data-ic="upload"></span><div><b>Pilih file</b></div></label></div>
              </div>
              <div class="field"><label>Logo perusahaan <span class="muted">(opsional)</span></label><label class="upload"><input type="file" name="file_logo" accept=".jpg,.jpeg,.png"><span data-ic="image"></span><div><b>Pilih logo</b></div><div class="hint">PNG atau JPG persegi.</div></label></div>
              <div class="field"><label class="check"><input type="checkbox" id="noOut" name="bukan_outsourcing" value="1"> Saya menyatakan perusahaan ini bukan perusahaan outsourcing.</label><div class="err">Pernyataan ini wajib dicentang.</div></div>
            </div>
            <h3 style="margin-top:8px">Periksa datamu</h3>
            <div class="summary"><dl id="sumList"></dl></div>
            <div class="field" style="margin-top:14px"><label class="check"><input type="checkbox" id="agree" name="setuju_syarat" value="1"> Saya menyetujui syarat penggunaan dan kebijakan privasi KarirKu Polinema.</label><div class="err">Setujui syarat penggunaan untuk melanjutkan.</div></div>
          </div>

          <div style="display:flex;justify-content:space-between;gap:12px;margin-top:10px">
            <button type="button" class="btn btn-outline" id="prevBtn">Kembali</button>
            <button type="submit" class="btn btn-primary" id="nextBtn">Lanjut</button>
          </div>
        </form>
      </div>
    </section>
  </div>
</main>

<script src="<?= url('assets/js/app.js') ?>"></script>
<script>
const PRODI_PER_JURUSAN = <?= json_encode($prodiPerJurusan, JSON_UNESCAPED_UNICODE) ?>;
const jurSel = document.getElementById('jur'), prodiSel = document.getElementById('prodi');
jurSel.addEventListener('change', () => {
  prodiSel.innerHTML = '<option value="">Pilih program studi</option>';
  (PRODI_PER_JURUSAN[jurSel.value] || []).forEach(p => prodiSel.add(new Option(p.jenjang + ' ' + p.nama, p.id)));
});
document.getElementById('status').addEventListener('change', e => {
  const al = e.target.value === 'alumni';
  document.getElementById('lulusField').hidden = !al;
  document.getElementById('docLabel').textContent = al ? 'Unggah ijazah atau SKL' : 'Unggah KTM';
});

let role = <?= $peranTerpilih ? json_encode($peranTerpilih) : 'null' ?>, step = 1;
const cards = document.querySelectorAll('.role-card'), startBtn = document.getElementById('startBtn');
function pick(r) { role = r; cards.forEach(c => c.classList.toggle('selected', c.dataset.role === r)); startBtn.disabled = false; }
cards.forEach(c => c.addEventListener('click', () => pick(c.dataset.role)));
if (role) pick(role);

function terapkanPeran() {
  document.getElementById('peranInput').value = role;
  const pt = role === 'perusahaan';
  document.getElementById('formTitle').textContent = pt ? 'Daftar sebagai perusahaan' : 'Daftar sebagai mahasiswa atau alumni';
  document.getElementById('st2').textContent = pt ? 'Data perusahaan' : 'Data diri';
  document.getElementById('lblEmail').textContent = pt ? 'Email perusahaan' : 'Email';
  document.querySelectorAll('.mhs-only').forEach(e => e.dataset.role = 'mahasiswa');
  document.querySelectorAll('.pt-only').forEach(e => e.dataset.role = 'perusahaan');
}
if (role) terapkanPeran();

startBtn.addEventListener('click', () => {
  document.getElementById('s0').hidden = true; document.getElementById('sForm').hidden = false;
  terapkanPeran();
  step = 1; render();
});
document.getElementById('changeRole').addEventListener('click', () => { document.getElementById('sForm').hidden = true; document.getElementById('s0').hidden = false; });

function render() {
  document.querySelectorAll('[data-step]').forEach(s => { const r = s.dataset.role; s.hidden = s.dataset.step != step || (r && r !== role); });
  document.querySelectorAll('[data-step] [data-role]').forEach(e => e.hidden = e.dataset.role !== role);
  document.querySelectorAll('.stepper .s').forEach(s => { const n = +s.dataset.s; s.classList.toggle('on', n === step); s.classList.toggle('done', n < step); s.querySelector('i').innerHTML = n < step ? ic('check') : n; });
  document.querySelectorAll('.stepper .ln').forEach((l, k) => l.classList.toggle('on', k + 1 < step));
  document.getElementById('prevBtn').style.visibility = step === 1 ? 'hidden' : 'visible';
  document.getElementById('nextBtn').textContent = step === 3 ? 'Kirim pendaftaran' : 'Lanjut';
  if (step === 3) summary();
  window.scrollTo(0, 0);
}
function val(id) { const el = document.getElementById(id); return el ? el.value : ''; }
function summary() {
  const rows = role === 'perusahaan'
    ? [['Perusahaan', val('ptnama')], ['Bidang usaha', val('bidang')], ['Jenis', val('jenis')], ['Alamat', val('alamat') + ', ' + val('kota')], ['PIC', val('pic') + (val('jab') ? ', ' + val('jab') : '')], ['WhatsApp PIC', val('picwa')], ['Email', val('remail')]]
    : [['Nama', val('nama')], ['NIM', val('nim')], ['Program studi', prodiSel.options[prodiSel.selectedIndex] ? prodiSel.options[prodiSel.selectedIndex].text : ''], ['Angkatan', val('angk')], ['Status', val('status') === 'alumni' ? 'Alumni, lulus ' + val('lulus') : 'Mahasiswa aktif'], ['Email', val('remail')], ['WhatsApp', val('wa')]];
  document.getElementById('sumList').innerHTML = rows.map(([k, v]) => `<dt>${k}</dt><dd>${v || '-'}</dd>`).join('');
}
function validate() {
  let ok = true;
  const pane = [...document.querySelectorAll(`[data-step="${step}"]`)].find(p => !p.hidden);
  if (!pane) return true;
  pane.querySelectorAll('.field').forEach(f => {
    if (f.hidden || f.closest('[hidden]')) return;
    const i = f.querySelector('input,select'); if (!i) return;
    let bad = false;
    if (i.required && !i.value.trim()) bad = true;
    if (i.type === 'email' && !/^\S+@\S+\.\S+$/.test(i.value)) bad = true;
    if (i.id === 'nim' && !/^\d{8,20}$/.test(i.value)) bad = true;
    if (i.id === 'p1' && i.value.length < 8) bad = true;
    if (i.id === 'p2' && i.value !== val('p1')) bad = true;
    if (i.type === 'file' && !i.files.length && (i.id === 'doc' || i.hasAttribute('data-req'))) bad = true;
    if (i.type === 'file' && i.files.length && i.files[0].size > 2 * 1024 * 1024) bad = true;
    if (i.type === 'checkbox' && (i.id === 'agree' || i.id === 'noOut') && !i.checked) bad = true;
    f.classList.toggle('has-err', bad); if (bad) ok = false;
  });
  if (!ok) { const first = pane.querySelector('.has-err input,.has-err select'); first && first.focus(); }
  return ok;
}
document.getElementById('prevBtn').addEventListener('click', () => { step--; render(); });
document.getElementById('regForm').addEventListener('submit', e => {
  if (!validate()) { e.preventDefault(); return; }
  if (step < 3) { e.preventDefault(); step++; render(); return; }
  // step === 3 dan lolos validasi -> biarkan form benar-benar ter-submit ke server.
});
if (role) render();
</script>
</body>
</html>
