<?php
// ===== FRONTEND · MAHASISWA · Detail lowongan ========================
$page_title = 'Detail lowongan';
$active_menu = 'lowongan';
$hp_tanpa_bar = true;   // HP: kepala bergambar sendiri (blok .hp)
require __DIR__ . '/../layouts/app-header.php';

$tutup = !$bisaMelamar;
$pamfletUrl = pamfletUrl($lowongan['pamflet']);
$logoUrl = !empty($lowongan['logo']) ? url('unduh.php?tipe=logo&file=' . urlencode($lowongan['logo'])) : null;
// --- Data untuk tampilan HP ---
$skillButuh = array_values(array_filter(array_map('trim', preg_split('/[,;\n]+/', (string) ($lowongan['skill_dibutuhkan'] ?? '')))));
$skillSaya = !empty($mhsShell['id']) ? array_map(fn($x) => mb_strtolower($x['nama']), (new Skill())->milikMahasiswa((int) $mhsShell['id'])) : [];
$skillPunya = array_values(array_filter($skillButuh, fn($x) => in_array(mb_strtolower($x), $skillSaya, true)));
$skillBelum = array_values(array_diff($skillButuh, $skillPunya));
$persenCocok = $skillButuh ? (int) round(100 * count($skillPunya) / count($skillButuh)) : 0;
[$tenggatHp, $mendesakHp] = hpTenggat($lowongan['batas_lamaran']);
$sisaKuota = max(0, (int) $lowongan['kuota'] - (int) $lowongan['terisi']);
?>
<!-- ===== Tampilan HP (model UI: Detail lowongan) ===== -->
<section class="hp m-detail" aria-label="Detail lowongan">
  <div class="m-detail-latar" style="background:<?= hpWarna($lowongan['nama_perusahaan']) ?>"></div>
  <header class="m-detail-bar">
    <a class="m-ib m-kaca" href="<?= url('lowongan/daftar') ?>" data-kembali aria-label="Kembali"><?= hpIk('back', 22, 2.1) ?></a>
    <span style="flex:1"></span>
    <button class="m-ib m-kaca" type="button" data-bagikan="<?= e($lowongan['posisi'] . ' · ' . $lowongan['nama_perusahaan']) ?>" aria-label="Bagikan"><?= hpIk('share', 20) ?></button>
    <form method="post" action="<?= url('lowongan/simpan/' . $lowongan['id']) ?>"><?= csrfField() ?><input type="hidden" name="kembali" value="<?= e(Auth::pathSaatIni()) ?>">
      <button class="m-ib m-kaca" type="submit" aria-label="<?= $sudahDisimpan ? 'Hapus dari disimpan' : 'Simpan lowongan' ?>"><?= hpIk('bookmark', 20, 1.9, $sudahDisimpan ? 'currentColor' : 'none') ?></button></form>
  </header>

  <div class="m-card m-lift" style="padding:18px 18px 16px;position:relative">
    <div style="margin-top:-46px"><?= hpLogo($lowongan['nama_perusahaan'], $lowongan['logo'] ?? null, 62) ?></div>
    <h1 class="m-serif" style="margin:12px 0 4px;font-size:25px;line-height:1.15;font-weight:600;color:#0a2656"><?= e($lowongan['posisi']) ?></h1>
    <a href="<?= url('mitra/' . $lowongan['perusahaan_id']) ?>" style="display:flex;align-items:center;gap:5px;color:#33435c;font-size:14px;font-weight:600"><?= e($lowongan['nama_perusahaan']) ?><span class="m-vf"><?= hpIk('verified', 16) ?></span></a>
    <div class="m-meta"><span class="m-tag"><?= hpIk('pin', 13, 2) ?><?= e($lowongan['lokasi']) ?></span><span class="m-tag"><?= e(hpJenis($lowongan['jenis_pekerjaan'])) ?></span><?php if ($lowongan['sistem_kerja']): ?><span class="m-tag"><?= e($lowongan['sistem_kerja']) ?></span><?php endif; ?></div>
    <div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));margin-top:14px;padding-top:14px;border-top:1px solid #eef2f7;text-align:center">
      <div><div style="font-weight:800;font-size:14px"><?= e(hpGaji($lowongan['gaji'])) ?></div><div class="m-muted" style="font-size:11.5px;font-weight:600">Gaji / bln</div></div>
      <div style="border-left:1px solid #eef2f7;border-right:1px solid #eef2f7"><div style="font-weight:800;font-size:14px<?= $mendesakHp ? ';color:#b54708' : '' ?>"><?= e(preg_replace('/^Tutup /', '', $tenggatHp)) ?></div><div class="m-muted" style="font-size:11.5px;font-weight:600">Batas <?= e(tanggalIndo($lowongan['batas_lamaran'])) ?></div></div>
      <div><div style="font-weight:800;font-size:14px"><?= $sisaKuota ?> dari <?= (int) $lowongan['kuota'] ?></div><div class="m-muted" style="font-size:11.5px;font-weight:600">Kuota tersisa</div></div>
    </div>
  </div>

  <?php if ($skillButuh): ?>
  <div class="m-card" style="padding:14px 16px;display:flex;align-items:center;gap:14px">
    <div style="width:52px;height:52px;border-radius:50%;background:conic-gradient(<?= $persenCocok >= 50 ? '#1f9254' : '#f2b233' ?> 0 <?= $persenCocok ?>%,#e4eaf3 0);display:grid;place-items:center;flex:none"><div style="width:42px;height:42px;border-radius:50%;background:#fff;display:grid;place-items:center;font-weight:800;font-size:13px;color:<?= $persenCocok >= 50 ? '#17663a' : '#8a5a00' ?>"><?= count($skillPunya) ?>/<?= count($skillButuh) ?></div></div>
    <div style="flex:1;min-width:0"><b style="font-size:14px"><?= $persenCocok >= 67 ? 'Skill kamu cocok' : ($persenCocok >= 34 ? 'Skill kamu cukup cocok' : 'Skill kamu belum banyak cocok') ?></b>
      <div class="m-muted m-small"><?= $skillPunya ? 'Punya: ' . e(implode(', ', $skillPunya)) : 'Belum ada yang cocok' ?><?= $skillBelum ? ' · Belum: ' . e(implode(', ', $skillBelum)) : '' ?></div></div>
  </div>
  <?php endif; ?>

  <div class="m-tab">
    <input type="radio" name="tabDetail" id="tdDes" checked><input type="radio" name="tabDetail" id="tdKua"><input type="radio" name="tabDetail" id="tdPer">
    <div class="m-tab-bar"><label for="tdDes">Deskripsi</label><label for="tdKua">Kualifikasi</label><label for="tdPer">Perusahaan</label></div>
    <div class="m-tab-isi m-tab-des"><p><?= nl2br(e($lowongan['deskripsi'])) ?></p></div>
    <div class="m-tab-isi m-tab-kua"><p><?= nl2br(e($lowongan['kualifikasi'])) ?></p>
      <?php if ($skillButuh): ?><div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:12px"><?php foreach ($skillButuh as $sk): ?><span class="m-tag m-blue"><?= e($sk) ?></span><?php endforeach; ?></div><?php endif; ?>
      <p class="m-muted" style="margin-top:12px;font-size:13px">Jurusan sasaran: <?= e(implode(', ', array_column($jurusanSasaran, 'nama')) ?: 'Semua jurusan') ?></p></div>
    <div class="m-tab-isi m-tab-per"><p><?= e($lowongan['deskripsi_perusahaan'] ?: ($lowongan['nama_perusahaan'] . ' berkantor di ' . $lowongan['kota_perusahaan'] . '.')) ?></p>
      <a class="m-btn m-btn-o m-btn-s" style="margin-top:12px" href="<?= url('mitra/' . $lowongan['perusahaan_id']) ?>">Lihat profil perusahaan</a></div>
  </div>

  <?php if ($pamfletUrl): ?>
  <a class="m-card" href="<?= e($pamfletUrl) ?>" target="_blank" rel="noopener" style="display:flex;align-items:center;gap:12px;padding:10px;color:#122036">
    <span style="width:52px;height:52px;border-radius:10px;background:linear-gradient(135deg,#1a3f8f,#0a2656);display:grid;place-items:center;color:#9fb8e6;flex:none"><?= hpIk('image', 22) ?></span>
    <span style="flex:1"><b style="font-size:14px">Lihat pamflet lowongan</b><span class="m-muted" style="display:block;font-size:12.5px">Dari perusahaan</span></span><span class="m-rc"><?= hpIk('chev', 19, 2) ?></span></a>
  <?php endif; ?>

  <div class="m-aksi-bawah">
    <?php if ($sudahMelamar): ?>
      <a class="m-btn m-btn-o" style="flex:1" href="<?= url('lamaran/lamaran-saya') ?>"><?= hpIk('checkc', 19, 2) ?>Sudah melamar · Lihat lamaran</a>
    <?php elseif ($tutup): ?>
      <span class="m-btn m-btn-o" style="flex:1;color:#8a5a00;box-shadow:0 0 0 1.5px #f3e0ae inset;white-space:normal;text-align:center;font-size:13px"><?= e($alasanTutup) ?></span>
    <?php elseif (!$profilLengkap): ?>
      <a class="m-btn m-btn-p" style="flex:1" href="<?= url('mahasiswa/profil') ?>">Lengkapi CV &amp; KTM untuk melamar</a>
    <?php else: ?>
      <a class="m-btn m-btn-p" style="flex:1" href="<?= url('lamaran/kirim/' . $lowongan['id']) ?>">Lamar sekarang</a>
    <?php endif; ?>
  </div>
</section>

<section class="view active hanya-laptop">
  <div class="kepala-halaman">
    <div class="crumb"><a href="<?= url('lowongan/daftar') ?>">Lowongan</a> <span>/</span> <span><?= e($lowongan['posisi']) ?></span></div>
    <?= tombolKembali('lowongan/daftar') ?>
  </div>

  <div class="detail">
    <div>
      <!-- ===== Pamflet ===== -->
      <div class="poster">
        <?= pamfletHtml($lowongan['pamflet'], 'besar', 'Pamflet ' . $lowongan['posisi']) ?>
        <?php if ($pamfletUrl): ?><div class="actions"><a class="btn btn-outline btn-sm flex-1" href="<?= e($pamfletUrl) ?>" download><span data-ic="download"></span>Unduh pamflet</a></div><?php endif; ?>
      </div>
    </div>
    <div>
      <!-- ===== Ringkasan & tombol lamar ===== -->
      <div class="panel">
        <div class="person mb-12">
          <?php if ($logoUrl): ?><img class="avatar" src="<?= e($logoUrl) ?>" alt=""><?php else: ?>
            <span class="avatar avatar-inisial"><?= e(inisial($lowongan['nama_perusahaan'])) ?></span>
          <?php endif; ?>
          <div><b><a href="<?= url('mitra/' . $lowongan['perusahaan_id']) ?>"><?= e($lowongan['nama_perusahaan']) ?></a></b><small class="text-ok">Mitra terverifikasi Career Center</small></div>
        </div>
        <h1 class="fs-190 mb-4"><?= e($lowongan['posisi']) ?></h1>
        <div class="meta">
          <span><span data-ic="pin"></span><?= e($lowongan['lokasi']) ?></span>
          <span><span data-ic="briefcase"></span><?= e(ucwords(str_replace('_', ' ', $lowongan['jenis_pekerjaan']))) ?></span>
          <span><span data-ic="calendar"></span>Batas <?= tanggalIndo($lowongan['batas_lamaran']) ?></span>
        </div>
        <div class="kv">
          <div><small>Sistem kerja</small><b><?= e(strtoupper($lowongan['sistem_kerja'])) ?></b></div>
          <div><small>Gaji</small><b><?= $lowongan['gaji'] ? e($lowongan['gaji']) : 'Dirundingkan' ?></b></div>
          <div><small>Kuota</small><b><?= (int) $lowongan['kuota'] ?> orang, sisa <?= max(0, (int) $lowongan['kuota'] - (int) $lowongan['terisi']) ?></b></div>
          <div><small>Jurusan sasaran</small><b><?= e(implode(', ', array_column($jurusanSasaran, 'nama')) ?: 'Semua jurusan') ?></b></div>
        </div>

        <div class="d-flex flex-wrap items-center gap-10 aksi-lengket">
          <?php if ($sudahMelamar): ?>
            <div class="alert alert-info m-0"><span data-ic="checkc"></span><span>Kamu sudah melamar lowongan ini. <a href="<?= url('lamaran/lamaran-saya') ?>">Lihat lamaran</a></span></div>
          <?php elseif ($tutup): ?>
            <div class="alert alert-warn m-0"><span data-ic="info"></span><span><?= e($alasanTutup) ?></span></div>
          <?php elseif (!$profilLengkap): ?>
            <div class="alert alert-warn m-0"><span data-ic="info"></span><span>Lengkapi KTM/ijazah dan CV di <a href="<?= url('mahasiswa/profil') ?>">Profil Karier</a> sebelum bisa melamar.</span></div>
          <?php else: ?>
            <a class="btn btn-primary btn-lg" href="<?= url('lamaran/kirim/' . $lowongan['id']) ?>">Lamar sekarang</a>
          <?php endif; ?>

          <form class="d-inline" method="post" action="<?= url('lowongan/simpan/' . $lowongan['id']) ?>">
            <?= csrfField() ?>
            <input type="hidden" name="kembali" value="<?= e(Auth::pathSaatIni()) ?>">
            <button class="btn btn-outline save-btn <?= $sudahDisimpan ? 'saved' : '' ?>" type="submit"><span data-ic="bookmark"></span><?= $sudahDisimpan ? 'Disimpan' : 'Simpan' ?></button>
          </form>
        </div>
      </div>

      <!-- ===== Deskripsi, kualifikasi, perusahaan ===== -->
      <div class="panel">
        <h3>Deskripsi pekerjaan</h3>
        <p><?= nl2br(e($lowongan['deskripsi'])) ?></p>
        <h3>Kualifikasi</h3>
        <p><?= nl2br(e($lowongan['kualifikasi'])) ?></p>
        <?php if (!empty($lowongan['skill_dibutuhkan'])): ?>
          <h3>Skill yang dibutuhkan</h3>
          <p><?= e($lowongan['skill_dibutuhkan']) ?></p>
        <?php endif; ?>
        <h3>Tentang perusahaan</h3>
        <p class="muted"><?= e($lowongan['deskripsi_perusahaan'] ?: ($lowongan['nama_perusahaan'] . ' berkantor di ' . $lowongan['kota_perusahaan'] . ' dan telah bermitra dengan Career Center Politeknik Negeri Malang.')) ?></p>
      </div>
    </div>
  </div>
</section>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>
