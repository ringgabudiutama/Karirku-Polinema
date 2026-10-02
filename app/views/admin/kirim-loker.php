<?php
/**
 * View: admin/kirim-loker (route: kirim-loker)
 * Dipanggil oleh: KirimLokerController::index()
 * Variabel: $lowongan, $lowonganDipilih, $jurusan, $kontak, $sudahDikirim,
 *           $jurusanSasaran, $tautanPratinjau, $templatePesan
 */
$page_title = 'Kirim Loker ke Jurusan';
$active_menu = 'kirim-loker';
require __DIR__ . '/../layouts/app-header.php';

$jumlahTerkirim = count($sudahDikirim);
$jumlahJurusan = count($jurusan);
$pamfletUrl = $lowonganDipilih ? url('unduh.php?tipe=pamflet&file=' . urlencode($lowonganDipilih['pamflet'])) : null;
?>
<section class="view active">
  <div class="page-head"><div><h1>Kirim loker ke jurusan</h1><p>Pilih lowongan, periksa pesan, lalu klik admin jurusan tujuan. WhatsApp langsung terbuka di tab baru.</p></div></div>
  <div class="grid" style="grid-template-columns:320px 1fr;align-items:start;gap:20px">
    <div class="panel">
      <h3>1. Pilih lowongan aktif</h3>
      <div class="pick">
        <?php foreach ($lowongan as $l): ?>
          <label>
            <input type="radio" name="pilihLowongan" onclick="location.href='<?= url('kirim-loker?lowongan_id=' . $l['id']) ?>'" <?= $lowonganDipilih && (int) $lowonganDipilih['id'] === (int) $l['id'] ? 'checked' : '' ?>>
            <img src="<?= url('unduh.php?tipe=pamflet&file=' . urlencode($l['pamflet'])) ?>" alt="">
            <span><b><?= e($l['posisi']) ?></b><br><small class="muted"><?= e($l['nama_perusahaan']) ?></small></span>
          </label>
        <?php endforeach; ?>
        <?php if (empty($lowongan)): ?><p class="muted">Tidak ada lowongan aktif.</p><?php endif; ?>
      </div>
    </div>

    <div>
      <?php if (!$lowonganDipilih): ?>
        <div class="panel" style="text-align:center;padding:50px"><p class="muted">Pilih salah satu lowongan di sebelah kiri untuk mulai.</p></div>
      <?php else: ?>
        <div class="panel">
          <h3>2. Periksa pamflet dan pesan</h3>
          <div class="grid" style="grid-template-columns:200px 1fr;align-items:start;gap:16px">
            <div>
              <img id="pamfletImg" src="<?= e($pamfletUrl) ?>" alt="Pamflet lowongan" style="border-radius:8px;border:1px solid var(--line);width:100%">
              <button type="button" class="btn btn-sm btn-link" style="width:100%;text-align:center;display:block" id="btnSalinPamflet" data-src="<?= e($pamfletUrl) ?>"><span data-ic="copy"></span>Salin pamflet</button>
              <a class="btn btn-sm btn-link" style="width:100%;text-align:center;display:block" href="<?= e($pamfletUrl) ?>" download><span data-ic="download"></span>Unduh pamflet</a>
            </div>
            <div>
              <div class="msg-preview" id="pesanWa"><?= nl2br(e(WhatsappService::susunPesan($templatePesan, $lowonganDipilih, 'Jurusan', $tautanPratinjau))) ?></div>
              <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:10px">
                <button type="button" class="btn btn-sm btn-outline" id="btnSalinPesan"><span data-ic="copy"></span>Salin pesan</button>
                <a class="btn btn-sm btn-outline" href="<?= e($tautanPratinjau) ?>" target="_blank"><span data-ic="eye"></span>Buka halaman pratinjau</a>
              </div>
              <p class="muted" style="font-size:.85rem;margin-top:12px">Tautan pratinjau bisa dibuka admin jurusan tanpa masuk. Pamflet tampil sebagai gambar pratinjau di WhatsApp.</p>
            </div>
          </div>
        </div>

        <div class="panel">
          <div class="panel-head"><h3>3. Kirim ke admin jurusan</h3><span class="muted" style="font-size:.88rem"><?= $jumlahTerkirim ?> dari <?= $jumlahJurusan ?> terkirim</span></div>
          <div class="jur-grid">
            <?php foreach ($jurusan as $j):
                $k = $kontak[$j['id']] ?? null;
                $terkirim = in_array($j['id'], $sudahDikirim, true);
                $nomorAda = $k && !empty($k['nomor_wa']);
                $disarankan = in_array($j['id'], $jurusanSasaran, true);
            ?>
              <?php if ($terkirim): ?>
                <div class="jur sent"><span class="wa" data-ic="check"></span><span><b>Admin <?= e($j['nama']) ?></b><small>Terkirim</small></span></div>
              <?php elseif ($nomorAda): ?>
                <a class="jur<?= $disarankan ? ' suggest' : '' ?>" href="<?= url('kirim-loker/kirim/' . $lowonganDipilih['id'] . '/' . $j['id']) ?>" target="_blank"><span class="wa" data-ic="whatsapp"></span><span><b>Admin <?= e($j['nama']) ?></b><small><?= $disarankan ? 'Disarankan untuk lowongan ini' : e($k['nama_kontak'] ?: 'Klik untuk kirim') ?></small></span></a>
              <?php else: ?>
                <div class="jur disabled"><span class="wa" data-ic="whatsapp"></span><span><b>Admin <?= e($j['nama']) ?></b><small>Nomor belum diatur, <a href="<?= url('admin/pengaturan#kontak') ?>">isi di sini</a></small></span></div>
              <?php endif; ?>
            <?php endforeach; ?>
          </div>
        </div>
      <?php endif; ?>
    </div>
  </div>
</section>
<script>
(function(){
  var btnPesan = document.getElementById('btnSalinPesan');
  if (btnPesan) {
    btnPesan.addEventListener('click', function(){
      var teks = document.getElementById('pesanWa').innerText;
      navigator.clipboard.writeText(teks).then(function(){
        var asli = btnPesan.innerHTML;
        btnPesan.innerHTML = '<span data-ic="check"></span>Pesan disalin'; hydrateIcons(btnPesan);
        setTimeout(function(){ btnPesan.innerHTML = asli; hydrateIcons(btnPesan); }, 1800);
      }).catch(function(){ alert('Gagal menyalin pesan. Salin manual dari kotak pesan.'); });
    });
  }
  var btnPamflet = document.getElementById('btnSalinPamflet');
  if (btnPamflet) {
    btnPamflet.addEventListener('click', function(){
      fetch(btnPamflet.dataset.src).then(function(r){ return r.blob(); }).then(function(blob){
        return navigator.clipboard.write([new ClipboardItem({ [blob.type]: blob })]);
      }).then(function(){
        var asli = btnPamflet.innerHTML;
        btnPamflet.innerHTML = '<span data-ic="check"></span>Pamflet disalin'; hydrateIcons(btnPamflet);
        setTimeout(function(){ btnPamflet.innerHTML = asli; hydrateIcons(btnPamflet); }, 1800);
      }).catch(function(){ alert('Perangkat/browser ini belum mendukung salin gambar. Gunakan tombol Unduh pamflet.'); });
    });
  }
})();
</script>
<?php require __DIR__ . '/../layouts/app-footer.php'; ?>