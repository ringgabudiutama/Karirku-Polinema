<?php
/* ===== FRONTEND · LAYOUT · Pesan satu kali (flash) =====
   Revisi G: bila pesannya berisi beberapa kesalahan (dipisah baris baru),
   ditampilkan sebagai daftar supaya pengguna tahu semua yang perlu diperbaiki. */
$flashShell = flashAmbil();
if ($flashShell):
    $tipeFlash = $flashShell['tipe'] === 'ok' ? 'ok' : ($flashShell['tipe'] === 'warn' ? 'warn' : 'bad');
    $barisFlash = array_values(array_filter(array_map('trim', explode("\n", (string) $flashShell['pesan']))));
?>
  <div class="alert flash alert-<?= $tipeFlash ?>" role="<?= $tipeFlash === 'ok' ? 'status' : 'alert' ?>">
    <span data-ic="<?= $tipeFlash === 'ok' ? 'checkc' : 'alert' ?>"></span>
    <?php if (count($barisFlash) > 1): ?>
      <div><b><?= $tipeFlash === 'bad' ? 'Data belum disimpan. Periksa hal berikut:' : 'Perhatian:' ?></b>
        <ul class="daftar-error"><?php foreach ($barisFlash as $b): ?><li><?= e($b) ?></li><?php endforeach; ?></ul></div>
    <?php else: ?>
      <span><?= e($barisFlash[0] ?? '') ?></span>
    <?php endif; ?>
  </div>
<?php endif; ?>
