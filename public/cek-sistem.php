<?php
/**
 * Halaman pengecek kesiapan sistem
 * Buka di browser: http://localhost/.../cek-sistem.php
 *
 * Dipakai saat pertama kali memasang proyek di komputer baru, untuk
 * memastikan PHP, ekstensi PostgreSQL, koneksi database, isi tabel, dan
 * izin folder sudah benar SEBELUM membuka aplikasinya.
 *
 * HAPUS ATAU BLOKIR file ini sebelum dipakai sungguhan / di-deploy publik.
 */

$hasil = [];
function cek(string $nama, bool $ok, string $pesanOk, string $pesanGagal, string $solusi = ''): array
{
    return compact('nama', 'ok', 'pesanOk', 'pesanGagal', 'solusi');
}

/* 1. Versi PHP */
$hasil[] = cek(
    'Versi PHP',
    version_compare(PHP_VERSION, '8.0', '>='),
    'PHP ' . PHP_VERSION,
    'PHP ' . PHP_VERSION . ' terlalu lama',
    'Proyek ini butuh PHP 8.0 ke atas. Perbarui PHP atau pakai XAMPP versi terbaru.'
);

/* 2. Ekstensi pdo_pgsql */
$hasil[] = cek(
    'Ekstensi pdo_pgsql',
    extension_loaded('pdo_pgsql'),
    'Aktif',
    'Belum aktif',
    'Buka php.ini, hapus tanda titik koma di depan baris extension=pdo_pgsql dan extension=pgsql, lalu restart Apache.'
);

/* 3. File konfigurasi */
$cfgPath = __DIR__ . '/../app/config/config.php';
$dbPath  = __DIR__ . '/../app/config/database.php';
$adaCfg  = is_file($cfgPath) && is_file($dbPath);
$hasil[] = cek('File konfigurasi', $adaCfg, 'Ditemukan', 'Tidak ditemukan', 'Pastikan folder app/config/ ikut ter-ekstrak.');

$cfg = $adaCfg ? require $cfgPath : [];
$db  = $adaCfg ? require $dbPath : [];

/* 4. Koneksi database */
$pdo = null;
$errDb = '';
if ($adaCfg && extension_loaded('pdo_pgsql')) {
    try {
        $dsn = sprintf('pgsql:host=%s;port=%s;dbname=%s', $db['host'], $db['port'], $db['nama']);
        $pdo = new PDO($dsn, $db['user'], $db['pass'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    } catch (PDOException $e) {
        $errDb = $e->getMessage();
    }
}
$hasil[] = cek(
    'Koneksi PostgreSQL',
    $pdo !== null,
    'Tersambung ke database "' . ($db['nama'] ?? '?') . '" di ' . ($db['host'] ?? '?') . ':' . ($db['port'] ?? '?'),
    'Gagal: ' . $errDb,
    'Periksa app/config/database.php: nama database, user, dan password. Pastikan juga service PostgreSQL sudah berjalan.'
);

/* 5. Tabel sudah dibuat */
$jumlahTabel = 0;
if ($pdo) {
    $jumlahTabel = (int) $pdo->query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")->fetchColumn();
}
$hasil[] = cek(
    'Tabel database',
    $jumlahTabel >= 20,
    $jumlahTabel . ' tabel ditemukan',
    $jumlahTabel . ' tabel (harusnya 24)',
    'Jalankan database/01-schema.sql lalu database/02-seed.sql di database ini.'
);

/* 6. Data awal */
$jumlahAkun = 0;
if ($pdo && $jumlahTabel >= 20) {
    try {
        $jumlahAkun = (int) $pdo->query('SELECT COUNT(*) FROM pengguna')->fetchColumn();
    } catch (PDOException $e) {
        $jumlahAkun = 0;
    }
}
$hasil[] = cek(
    'Data awal (seed)',
    $jumlahAkun > 0,
    $jumlahAkun . ' akun siap dipakai',
    'Tabel pengguna masih kosong',
    'Jalankan database/02-seed.sql supaya akun demo admin, mahasiswa, dan perusahaan terbuat.'
);

/* 7. Folder unggahan bisa ditulis */
$uploadDir = __DIR__ . '/../storage/uploads';
$hasil[] = cek(
    'Folder storage/uploads',
    is_dir($uploadDir) && is_writable($uploadDir),
    'Bisa ditulis',
    'Tidak bisa ditulis',
    'Klik kanan folder storage, Properties, hilangkan centang Read-only. Di Linux/Mac: chmod -R 775 storage'
);

/* 8. base_url cocok dengan lokasi file */
$basePerkiraan = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'])), '/');
$baseTersimpan = rtrim($cfg['base_url'] ?? '', '/');
$hasil[] = cek(
    'Pengaturan base_url',
    $baseTersimpan === $basePerkiraan,
    "Sudah cocok ('" . ($baseTersimpan ?: '(kosong)') . "')",
    "Tersimpan '" . ($baseTersimpan ?: '(kosong)') . "' tapi seharusnya '" . ($basePerkiraan ?: '(kosong)') . "'",
    "Buka app/config/config.php, ubah baris 'base_url' menjadi '" . $basePerkiraan . "'"
);

/* 9. mod_rewrite (hanya relevan bila lewat Apache) */
$pakaiApache = stripos($_SERVER['SERVER_SOFTWARE'] ?? '', 'apache') !== false;
if ($pakaiApache) {
    $rewriteOn = function_exists('apache_get_modules') ? in_array('mod_rewrite', apache_get_modules(), true) : true;
    $hasil[] = cek(
        'Apache mod_rewrite',
        $rewriteOn,
        'Aktif',
        'Belum aktif',
        'Buka httpd.conf, hapus tanda pagar di depan LoadModule rewrite_module modules/mod_rewrite.so, lalu restart Apache.'
    );
}

$semuaOk = true;
foreach ($hasil as $h) {
    if (!$h['ok']) { $semuaOk = false; break; }
}
$linkMasuk = ($baseTersimpan === $basePerkiraan ? $baseTersimpan : $basePerkiraan) . '/masuk';
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cek Sistem | KarirKu Polinema</title>
<style>
  :root{--navy:#0A2656;--blue:#1D5BC6;--ok:#067647;--okbg:#ECFDF3;--bad:#D92D20;--badbg:#FEF3F2;--line:#E4E7EC;--muted:#667085}
  *{box-sizing:border-box}
  body{margin:0;padding:40px 20px;background:#F5F7FA;color:#1A2233;
       font-family:system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;line-height:1.55}
  .kotak{max-width:820px;margin:0 auto;background:#fff;border:1px solid var(--line);border-radius:16px;overflow:hidden}
  .kepala{background:var(--navy);color:#fff;padding:28px 32px}
  .kepala h1{margin:0 0 6px;font-size:1.5rem}
  .kepala p{margin:0;opacity:.85;font-size:.95rem}
  .ringkas{padding:18px 32px;font-weight:600}
  .ringkas.ya{background:var(--okbg);color:var(--ok)}
  .ringkas.tidak{background:var(--badbg);color:var(--bad)}
  table{width:100%;border-collapse:collapse}
  td{padding:14px 32px;border-top:1px solid var(--line);vertical-align:top}
  td.status{width:70px;font-weight:700}
  .ya{color:var(--ok)} .tidak{color:var(--bad)}
  .nama{font-weight:600}
  .pesan{color:var(--muted);font-size:.92rem}
  .solusi{margin-top:8px;padding:10px 12px;background:#FFFAEB;border-left:3px solid #B54708;
          border-radius:4px;font-size:.9rem;color:#7A2E0E}
  .kaki{padding:24px 32px;border-top:1px solid var(--line);font-size:.92rem;color:var(--muted)}
  .tombol{display:inline-block;margin-top:10px;background:var(--blue);color:#fff;text-decoration:none;
          padding:11px 22px;border-radius:999px;font-weight:600}
  code{background:#F2F4F7;padding:2px 6px;border-radius:4px;font-size:.9em}
</style>
</head>
<body>
<div class="kotak">
  <div class="kepala">
    <h1>Cek Kesiapan Sistem</h1>
    <p>KarirKu Polinema &mdash; pastikan semua baris hijau sebelum membuka aplikasi</p>
  </div>

  <div class="ringkas <?= $semuaOk ? 'ya' : 'tidak' ?>">
    <?= $semuaOk
        ? 'Semua siap. Aplikasi bisa dibuka sekarang.'
        : 'Masih ada yang perlu diperbaiki. Lihat baris merah di bawah.' ?>
  </div>

  <table>
    <?php foreach ($hasil as $h): ?>
    <tr>
      <td class="status <?= $h['ok'] ? 'ya' : 'tidak' ?>"><?= $h['ok'] ? 'OK' : 'GAGAL' ?></td>
      <td>
        <div class="nama"><?= htmlspecialchars($h['nama']) ?></div>
        <div class="pesan"><?= htmlspecialchars($h['ok'] ? $h['pesanOk'] : $h['pesanGagal']) ?></div>
        <?php if (!$h['ok'] && $h['solusi']): ?>
          <div class="solusi"><b>Cara memperbaiki:</b> <?= htmlspecialchars($h['solusi']) ?></div>
        <?php endif; ?>
      </td>
    </tr>
    <?php endforeach; ?>
  </table>

  <div class="kaki">
    <?php if ($semuaOk): ?>
      Akun demo: <code>admin@polinema.ac.id</code> / <code>admin123</code>,
      <code>mahasiswa@polinema.ac.id</code> / <code>mahasiswa123</code>,
      <code>perusahaan@polinema.ac.id</code> / <code>perusahaan123</code>.
      <br><a class="tombol" href="<?= htmlspecialchars($linkMasuk) ?>">Buka halaman Masuk</a>
    <?php else: ?>
      Perbaiki dulu baris merah di atas, lalu muat ulang halaman ini (F5).
    <?php endif; ?>
    <p style="margin:14px 0 0">Hapus file <code>cek-sistem.php</code> sebelum aplikasi dipakai sungguhan.</p>
  </div>
</div>
</body>
</html>
