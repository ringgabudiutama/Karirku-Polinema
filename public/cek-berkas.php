<?php
/**
 * Pemeriksa kecocokan database dengan berkas di penyimpanan.
 *
 * Dipakai saat ada tombol berkas yang berakhir di "Berkas tidak ditemukan".
 * Halaman ini membandingkan nama berkas yang tercatat di database dengan isi
 * folder storage/uploads/, lalu menunjukkan mana yang hilang.
 *
 * Penyebab paling sering: folder proyek diganti dengan versi baru, sedangkan
 * berkas yang pernah diunggah masih tertinggal di folder proyek yang lama.
 * Database tetap mencatat namanya, tetapi berkasnya sudah tidak ada di sini.
 *
 * HAPUS berkas ini sebelum aplikasi dipakai sungguhan.
 */

require __DIR__ . '/../app/core/bootstrap.php';

$upload = rtrim((require __DIR__ . '/../app/config/config.php')['upload_dir'], '/');

/* Daftar sumber: dari tabel mana, kolom apa, dan disimpan di folder mana. */
$sumber = [
    ['Foto profil mahasiswa', 'SELECT foto AS berkas, nama AS pemilik FROM mahasiswa WHERE foto IS NOT NULL', ['foto']],
    ['KTM atau ijazah',       'SELECT file_ktm AS berkas, nama AS pemilik FROM mahasiswa WHERE file_ktm IS NOT NULL', ['ktm', 'ijazah']],
    ['Surat pengantar',       'SELECT file_surat_pengantar AS berkas, nama AS pemilik FROM mahasiswa WHERE file_surat_pengantar IS NOT NULL', ['surat_pengantar', 'dokumen_lamaran']],
    ['CV unggahan',           'SELECT file_cv AS berkas, nama AS pemilik FROM mahasiswa WHERE file_cv IS NOT NULL', ['cv']],
    ['Sertifikat dan portofolio', "SELECT pi.file AS berkas, m.nama AS pemilik FROM profil_item pi JOIN mahasiswa m ON m.id = pi.mahasiswa_id WHERE pi.file IS NOT NULL", ['portofolio']],
    ['Logo perusahaan',       'SELECT logo AS berkas, nama_perusahaan AS pemilik FROM perusahaan WHERE logo IS NOT NULL', ['logo']],
    ['Pamflet lowongan',      'SELECT l.pamflet AS berkas, pr.nama_perusahaan AS pemilik FROM lowongan l JOIN perusahaan pr ON pr.id = l.perusahaan_id WHERE l.pamflet IS NOT NULL', ['pamflet']],
    ['Dokumen legalitas',     'SELECT dv.file AS berkas, dv.tipe AS pemilik FROM dokumen_verifikasi dv', ['nib', 'npwp', 'akta', 'domisili', 'ktm', 'ijazah', 'logo']],
    ['Berkas pada lamaran',   'SELECT lm.file_surat_pengantar AS berkas, m.nama AS pemilik FROM lamaran lm JOIN mahasiswa m ON m.id = lm.mahasiswa_id WHERE lm.file_surat_pengantar IS NOT NULL', ['dokumen_lamaran', 'surat_pengantar']],
];

$hasil = [];
$totalCek = 0;
$totalHilang = 0;
$galatDb = '';

try {
    foreach ($sumber as [$label, $sql, $folder]) {
        $baris = Database::fetchAll($sql);
        $hilang = [];
        foreach ($baris as $b) {
            $nama = $b['berkas'];
            if ($nama === null || trim($nama) === '') continue;
            $totalCek++;
            $ketemu = false;
            foreach ($folder as $f) {
                if (is_file($upload . '/' . $f . '/' . basename($nama))) { $ketemu = true; break; }
            }
            if (!$ketemu) {
                $hilang[] = ['berkas' => $nama, 'pemilik' => $b['pemilik'] ?? '-'];
                $totalHilang++;
            }
        }
        $hasil[] = ['label' => $label, 'jumlah' => count($baris), 'hilang' => $hilang, 'folder' => $folder];
    }
} catch (Throwable $e) {
    $galatDb = $e->getMessage();
}

/* Berkas yang ada di penyimpanan tetapi tidak tercatat di database */
$yatim = [];
foreach (glob($upload . '/*', GLOB_ONLYDIR) as $dir) {
    foreach (glob($dir . '/*') as $f) {
        if (is_dir($f) || basename($f) === '.gitkeep') continue;
        $yatim[basename($dir)][] = basename($f);
    }
}
$dipakai = [];
if (!$galatDb) {
    foreach ($sumber as [$l, $sql, $fd]) {
        foreach (Database::fetchAll($sql) as $b) {
            if (!empty($b['berkas'])) $dipakai[basename($b['berkas'])] = true;
        }
    }
}
$jumlahYatim = 0;
foreach ($yatim as $folder => $daftar) {
    $yatim[$folder] = array_values(array_filter($daftar, fn($n) => !isset($dipakai[$n])));
    $jumlahYatim += count($yatim[$folder]);
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cek Berkas | KarirKu Polinema</title>
<style>
  :root{--navy:#0A2656;--blue:#1D5BC6;--ok:#067647;--okbg:#ECFDF3;--bad:#D92D20;--badbg:#FEF3F2;--line:#E4E7EC;--muted:#667085}
  *{box-sizing:border-box}
  body{margin:0;padding:40px 20px;background:#F5F7FA;color:#1A2233;
       font-family:system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;line-height:1.55}
  .kotak{max-width:880px;margin:0 auto;background:#fff;border:1px solid var(--line);border-radius:16px;overflow:hidden}
  .kepala{background:var(--navy);color:#fff;padding:28px 32px}
  .kepala h1{margin:0 0 6px;font-size:1.5rem}
  .kepala p{margin:0;opacity:.85;font-size:.95rem}
  .ringkas{padding:18px 32px;font-weight:600}
  .ringkas.ya{background:var(--okbg);color:var(--ok)}
  .ringkas.tidak{background:var(--badbg);color:var(--bad)}
  table{width:100%;border-collapse:collapse}
  td,th{padding:12px 32px;border-top:1px solid var(--line);vertical-align:top;text-align:left}
  th{background:#FAFCFF;font-size:.82rem;color:var(--muted)}
  .jml{text-align:right;white-space:nowrap}
  .ya{color:var(--ok)} .tidak{color:var(--bad);font-weight:600}
  .daftar{margin:8px 0 0;padding-left:18px;font-size:.88rem;color:var(--muted)}
  .daftar code{background:#F2F4F7;padding:1px 5px;border-radius:4px}
  .saran{margin:0;padding:24px 32px;border-top:1px solid var(--line);font-size:.93rem}
  .saran h3{margin:0 0 8px;font-size:1rem}
  .saran ol{margin:0;padding-left:20px}
  .saran li{margin-bottom:6px}
  code{background:#F2F4F7;padding:2px 6px;border-radius:4px;font-size:.9em}
</style>
</head>
<body>
<div class="kotak">
  <div class="kepala">
    <h1>Cek Berkas</h1>
    <p>Membandingkan nama berkas yang tercatat di database dengan isi folder storage/uploads/</p>
  </div>

  <?php if ($galatDb): ?>
    <div class="ringkas tidak">Tidak bisa membaca database: <?= e($galatDb) ?></div>
  <?php else: ?>
    <div class="ringkas <?= $totalHilang === 0 ? 'ya' : 'tidak' ?>">
      <?= $totalHilang === 0
          ? 'Semua ' . $totalCek . ' berkas yang tercatat di database ada di penyimpanan.'
          : $totalHilang . ' dari ' . $totalCek . ' berkas tercatat di database tetapi TIDAK ADA di penyimpanan.' ?>
    </div>

    <table>
      <tr><th>Jenis berkas</th><th class="jml">Tercatat</th><th class="jml">Hilang</th></tr>
      <?php foreach ($hasil as $h): ?>
        <tr>
          <td>
            <?= e($h['label']) ?>
            <div style="font-size:.82rem;color:var(--muted)">folder: <?= e(implode(', ', $h['folder'])) ?></div>
            <?php if ($h['hilang']): ?>
              <ul class="daftar">
                <?php foreach (array_slice($h['hilang'], 0, 8) as $x): ?>
                  <li><code><?= e($x['berkas']) ?></code> &mdash; <?= e($x['pemilik']) ?></li>
                <?php endforeach; ?>
                <?php if (count($h['hilang']) > 8): ?>
                  <li>dan <?= count($h['hilang']) - 8 ?> lainnya</li>
                <?php endif; ?>
              </ul>
            <?php endif; ?>
          </td>
          <td class="jml"><?= $h['jumlah'] ?></td>
          <td class="jml <?= $h['hilang'] ? 'tidak' : 'ya' ?>"><?= count($h['hilang']) ?></td>
        </tr>
      <?php endforeach; ?>
    </table>
  <?php endif; ?>

  <?php if ($jumlahYatim > 0): ?>
    <table>
      <tr><th colspan="3"><?= $jumlahYatim ?> berkas ada di penyimpanan tetapi tidak dipakai data mana pun</th></tr>
      <?php foreach ($yatim as $folder => $daftar): if (!$daftar) continue; ?>
        <tr>
          <td colspan="2"><?= e($folder) ?>
            <ul class="daftar">
              <?php foreach (array_slice($daftar, 0, 5) as $n): ?><li><code><?= e($n) ?></code></li><?php endforeach; ?>
              <?php if (count($daftar) > 5): ?><li>dan <?= count($daftar) - 5 ?> lainnya</li><?php endif; ?>
            </ul>
          </td>
          <td class="jml"><?= count($daftar) ?></td>
        </tr>
      <?php endforeach; ?>
    </table>
  <?php endif; ?>

  <div class="saran">
    <h3>Kalau ada berkas yang hilang</h3>
    <p style="margin:0 0 10px;color:var(--muted)">
      Penyebab paling sering: folder proyek diganti dengan versi baru, sedangkan berkas yang
      pernah diunggah masih tertinggal di folder proyek yang lama. Database tetap mencatat
      namanya, tetapi berkasnya tidak ikut pindah.
    </p>
    <ol>
      <li>Cari folder proyek yang lama di komputermu.</li>
      <li>Salin seluruh isi <code>storage/uploads/</code> dari folder lama ke folder yang sekarang dipakai.</li>
      <li>Muat ulang halaman ini. Angka di kolom Hilang harus menjadi nol.</li>
    </ol>
    <p style="margin:10px 0 0;color:var(--muted)">
      Kalau folder lamanya sudah terhapus, berkasnya memang sudah tidak ada. Minta pemiliknya
      mengunggah ulang lewat Profil Karier, atau bangun ulang database dengan
      <code>01-schema.sql</code> dan <code>02-seed.sql</code> supaya kembali memakai berkas contoh.
    </p>
    <p style="margin:14px 0 0;font-size:.88rem;color:var(--muted)">
      Hapus berkas <code>cek-berkas.php</code> sebelum aplikasi dipakai sungguhan.
    </p>
  </div>
</div>
</body>
</html>
