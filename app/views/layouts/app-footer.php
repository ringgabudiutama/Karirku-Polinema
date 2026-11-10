<?php /* ===== FRONTEND · LAYOUT · Kerangka dashboard (penutup) ===== */ ?>
</div>
    <!-- ===== Menu bawah: hanya tampil di layar HP (lihat style.css bagian 33) ===== -->
    <nav class="nav-bawah" aria-label="Menu utama">
      <?php foreach ($navBawah as [$kunci, $label, $ikon, $href, $aktifUntuk, $angka]): $aktif = in_array($active_menu, $aktifUntuk, true); ?>
        <?php if ($href === ''): ?>
          <button type="button" class="<?= $aktif ? 'aktif' : '' ?>" data-open="sheetLainnya" aria-haspopup="dialog"><span class="nb-pil" data-ic="<?= $ikon ?>"></span><?= e($label) ?></button>
        <?php else: ?>
          <a href="<?= url($href) ?>" class="<?= $aktif ? 'aktif' : '' ?>"<?= $aktif ? ' aria-current="page"' : '' ?>><span class="nb-pil" data-ic="<?= $ikon ?>"></span><?= e($label) ?><?php if ($angka > 0): ?><span class="nb-angka" aria-label="<?= (int) $angka ?> menunggu"><?= $angka > 99 ? '99+' : (int) $angka ?></span><?php endif; ?></a>
        <?php endif; ?>
      <?php endforeach; ?>
    </nav>
  </div>
</div>
<?php if ($role === 'admin'): ?>
<!-- ===== Sheet "Lainnya" (admin, HP) ===== -->
<div class="modal modal-sheet" id="sheetLainnya" role="dialog" aria-modal="true" aria-labelledby="jLainnya">
  <div class="modal-box">
    <div class="modal-head"><h3 id="jLainnya">Lainnya</h3><button class="close" type="button" data-close aria-label="Tutup" data-ic="x"></button></div>
    <div class="modal-body">
      <div class="ubin-menu">
        <?php foreach ([['pengguna', 'Kelola pengguna', 'users', 'admin/kelola-pengguna'], ['rekap', 'Rekap lamaran', 'clipboard', 'admin/rekap-lamaran'],
                        ['kirim-loker', 'Kirim loker', 'send', 'kirim-loker'], ['tracer', 'Tracer karier', 'chart', 'admin/tracer-karier']] as [$k, $l, $i, $h]): ?>
          <a class="ubin <?= $active_menu === $k ? 'aktif' : '' ?>" href="<?= url($h) ?>"><span data-ic="<?= $i ?>"></span><?= e($l) ?></a>
        <?php endforeach; ?>
      </div>
      <div class="daftar-menu">
        <a href="<?= $hrefProfil ?>"><span data-ic="user"></span>Profil saya</a>
        <a href="<?= $hrefPengaturan ?>"><span data-ic="settings"></span>Pengaturan</a>
        <a href="<?= $hrefNotif ?>"><span data-ic="bell"></span>Notifikasi<?php if ($jumlahNotif > 0): ?> <span class="count"><?= (int) $jumlahNotif ?></span><?php endif; ?></a>
        <form class="logout-form" method="post" action="<?= url('keluar') ?>"><?= csrfField() ?><button type="submit" class="bahaya"><span data-ic="logout"></span>Keluar</button></form>
      </div>
    </div>
  </div>
</div>
<?php endif; ?>
<?= skripPemulihanFormulir() ?>
<script src="<?= asetUrl('assets/js/app.js') ?>"></script>
</body>
</html>
