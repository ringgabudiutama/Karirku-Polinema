<?php
/**
 * Pelayan file unggahan (dokumen, foto, logo, pamflet, CV, sertifikat)
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * Semua file disimpan di storage/uploads/ yang berada DI LUAR folder public/,
 * supaya tidak bisa dibuka langsung lewat URL (proposal Bagian 6.4). Berkas
 * ini satu-satunya pintu untuk membukanya, dan memeriksa hak akses dulu.
 *
 * Pemakaian: unduh.php?tipe=foto&file=abcd1234.jpg
 *
 * ATURAN AKSES
 *
 *   Publik, tanpa login:
 *     pamflet  - harus tampil di halaman info loker yang memang tanpa login
 *     logo     - logo perusahaan tampil di banyak halaman
 *
 *   Milik mahasiswa (ktm, ijazah, cv, foto, surat_pengantar,
 *   dokumen_lamaran, portofolio) boleh dibuka oleh:
 *     - mahasiswa pemiliknya sendiri
 *     - admin Career Center
 *     - perusahaan yang menerima lamaran dari mahasiswa itu
 *
 *   Milik perusahaan (nib, npwp, akta, domisili) boleh dibuka oleh:
 *     - perusahaan pemiliknya sendiri
 *     - admin Career Center
 *
 * Halaman galat sengaja dibuat rapi dan memberi jalan keluar, bukan tulisan
 * polos, karena pengguna bisa sampai ke sini dari tombol di halaman biasa.
 */

require __DIR__ . '/../app/core/bootstrap.php';

/* --------------------------------------------------------------------------
   Halaman galat yang rapi
   -------------------------------------------------------------------------- */
function galatBerkas(int $kode, string $judul, string $pesan, string $saran = ''): void
{
    http_response_code($kode);
    $kembali = url('beranda');
    $peran = null;
    if (class_exists('Auth')) {
        $u = Auth::penggunaSaatIni();
        $peran = $u['role'] ?? null;
    }
    $tujuan = [
        'mahasiswa'  => ['mahasiswa/dashboard', 'Kembali ke dashboard'],
        'perusahaan' => ['perusahaan/dashboard', 'Kembali ke dashboard'],
        'admin'      => ['admin/dashboard', 'Kembali ke dashboard'],
    ][$peran] ?? ['beranda', 'Kembali ke beranda'];
    ?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= e($judul) ?> | KarirKu Polinema</title>
<link rel="stylesheet" href="<?= url('assets/css/style.css') ?>">
</head>
<body style="display:flex;align-items:center;justify-content:center;min-height:100vh;background:var(--sky);padding:24px">
  <div style="max-width:460px;text-align:center">
    <h1 style="font-size:2.6rem;margin-bottom:2px"><?= (int) $kode ?></h1>
    <h3 style="margin-bottom:8px"><?= e($judul) ?></h3>
    <p class="muted"><?= e($pesan) ?></p>
    <?php if ($saran): ?><p class="muted" style="font-size:.9rem"><?= e($saran) ?></p><?php endif; ?>
    <div style="margin-top:18px;display:flex;gap:10px;justify-content:center;flex-wrap:wrap">
      <a class="btn btn-primary" href="<?= url($tujuan[0]) ?>"><?= e($tujuan[1]) ?></a>
      <a class="btn btn-outline" href="javascript:history.back()">Halaman sebelumnya</a>
    </div>
  </div>
</body>
</html>
    <?php
    exit;
}

$tipe = $_GET['tipe'] ?? '';
$file = basename($_GET['file'] ?? '');   // basename() mencegah path traversal

$tipePublik = ['pamflet', 'logo'];
$tipeMahasiswa = ['foto', 'cv', 'ktm', 'ijazah', 'surat_pengantar', 'dokumen_lamaran', 'portofolio'];
$tipePerusahaan = ['nib', 'npwp', 'akta', 'domisili'];
$tipeValid = array_merge($tipePublik, $tipeMahasiswa, $tipePerusahaan);

if ($file === '' || !in_array($tipe, $tipeValid, true)) {
    galatBerkas(400, 'Permintaan berkas tidak dikenal',
        'Jenis berkas yang diminta tidak ada di sistem.',
        'Kalau tombol ini muncul di halaman biasa, laporkan ke Career Center.');
}

if (!in_array($tipe, $tipePublik, true)) {
    Auth::wajibLogin();
    $user = Auth::penggunaSaatIni();

    if ($user['role'] !== 'admin' && !bolehLihatFilePribadi($tipe, $file, (int) $user['id'])) {
        galatBerkas(403, 'Berkas ini bukan untukmu',
            'Berkas pribadi hanya bisa dibuka oleh pemiliknya, Career Center, dan perusahaan yang menerima lamarannya.');
    }
}

/* KTM dan ijazah memakai satu kolom yang sama di database (file_ktm), tetapi
   berkasnya tersimpan di folder berbeda: mahasiswa aktif ke folder ktm,
   alumni ke folder ijazah. Tautan di halaman selalu memakai tipe=ktm, jadi
   kalau tidak ketemu di satu folder, dicari juga di pasangannya. */
$pasangan = ['ktm' => 'ijazah', 'ijazah' => 'ktm',
             'surat_pengantar' => 'dokumen_lamaran', 'dokumen_lamaran' => 'surat_pengantar'];

$path = UploadService::pathLengkap($tipe, $file);
if (!is_file($path) && isset($pasangan[$tipe])) {
    $alternatif = UploadService::pathLengkap($pasangan[$tipe], $file);
    if (is_file($alternatif)) {
        $path = $alternatif;
    }
}
if (!is_file($path)) {
    galatBerkas(404, 'Berkas tidak ditemukan',
        'Datanya tercatat di sistem, tetapi berkasnya tidak ada di penyimpanan.',
        'Biasanya karena berkas belum pernah benar-benar diunggah. Minta pemiliknya mengunggah ulang.');
}

$mime = mime_content_type($path) ?: 'application/octet-stream';
header('Content-Type: ' . $mime);
header('Content-Length: ' . filesize($path));
header('X-Content-Type-Options: nosniff');
header('Content-Disposition: inline; filename="' . $file . '"');
readfile($path);
exit;

/**
 * Memeriksa apakah pengguna yang sedang login boleh membuka berkas ini.
 *
 * Mengembalikan true kalau dia pemiliknya sendiri, atau dia perusahaan yang
 * menerima lamaran dari pemilik berkas itu. Admin tidak lewat sini karena
 * sudah dilewatkan di atas.
 */
function bolehLihatFilePribadi(string $tipe, string $file, int $penggunaId): bool
{
    /* ---------- 1. Berkas milik mahasiswa yang sedang login ---------- */
    $kolomMahasiswa = [
        'foto'            => 'foto',
        'cv'              => 'file_cv',
        'ktm'             => 'file_ktm',
        'ijazah'          => 'file_ktm',
        'surat_pengantar' => 'file_surat_pengantar',
    ];
    if (isset($kolomMahasiswa[$tipe])) {
        $kolom = $kolomMahasiswa[$tipe];
        if (Database::fetch("SELECT 1 FROM mahasiswa WHERE pengguna_id = ? AND {$kolom} = ?",
                            [$penggunaId, $file])) {
            return true;
        }
    }

    /* Surat pengantar yang menempel pada satu lamaran tertentu */
    if ($tipe === 'dokumen_lamaran' || $tipe === 'surat_pengantar') {
        if (Database::fetch(
            'SELECT 1 FROM lamaran lm JOIN mahasiswa m ON m.id = lm.mahasiswa_id
              WHERE m.pengguna_id = ? AND lm.file_surat_pengantar = ?',
            [$penggunaId, $file])) {
            return true;
        }
    }

    /* Sertifikat dan portofolio, keduanya tersimpan di profil_item.file */
    if ($tipe === 'portofolio') {
        if (Database::fetch(
            'SELECT 1 FROM profil_item pi JOIN mahasiswa m ON m.id = pi.mahasiswa_id
              WHERE m.pengguna_id = ? AND pi.file = ?',
            [$penggunaId, $file])) {
            return true;
        }
    }

    /* ---------- 2. Dokumen legalitas milik perusahaan sendiri ---------- */
    if (in_array($tipe, ['nib', 'npwp', 'akta', 'domisili'], true)) {
        return (bool) Database::fetch(
            'SELECT 1 FROM dokumen_verifikasi WHERE pengguna_id = ? AND tipe = ? AND file = ?',
            [$penggunaId, $tipe, $file]
        );
    }

    /* ---------- 3. Perusahaan yang meninjau lamaran ---------- */
    $prsh = Database::fetch('SELECT id FROM perusahaan WHERE pengguna_id = ?', [$penggunaId]);
    if (!$prsh) {
        return false;
    }
    $perusahaanId = (int) $prsh['id'];

    /* Berkas yang menempel langsung pada baris lamaran */
    $kolomLamaran = [
        'cv'              => ['file_cv'],
        'ktm'             => ['file_ktm'],
        'ijazah'          => ['file_ktm'],
        'surat_pengantar' => ['file_surat_pengantar'],
        'dokumen_lamaran' => ['file_surat_pengantar'],
    ];
    if (isset($kolomLamaran[$tipe])) {
        $klausa = implode(' OR ', array_map(fn($k) => "lm.{$k} = ?", $kolomLamaran[$tipe]));
        $params = array_merge([$perusahaanId], array_fill(0, count($kolomLamaran[$tipe]), $file));
        if (Database::fetch(
            "SELECT 1 FROM lamaran lm JOIN lowongan l ON l.id = lm.lowongan_id
              WHERE l.perusahaan_id = ? AND ({$klausa})", $params)) {
            return true;
        }
        /* CV otomatis dan dokumen profil tidak selalu tercatat di baris
           lamaran, jadi dicocokkan juga ke profil pelamarnya. */
        $kolomProfil = ['cv' => 'file_cv', 'ktm' => 'file_ktm', 'ijazah' => 'file_ktm',
                        'surat_pengantar' => 'file_surat_pengantar',
                        'dokumen_lamaran' => 'file_surat_pengantar'][$tipe];
        return (bool) Database::fetch(
            "SELECT 1 FROM lamaran lm
               JOIN lowongan l ON l.id = lm.lowongan_id
               JOIN mahasiswa m ON m.id = lm.mahasiswa_id
              WHERE l.perusahaan_id = ? AND m.{$kolomProfil} = ?",
            [$perusahaanId, $file]
        );
    }

    /* Foto profil pelamar */
    if ($tipe === 'foto') {
        return (bool) Database::fetch(
            'SELECT 1 FROM lamaran lm
               JOIN lowongan l ON l.id = lm.lowongan_id
               JOIN mahasiswa m ON m.id = lm.mahasiswa_id
              WHERE l.perusahaan_id = ? AND m.foto = ?',
            [$perusahaanId, $file]
        );
    }

    /* Sertifikat dan portofolio pelamar. Perusahaan memang perlu melihatnya
       saat menyeleksi, sama seperti CV dan KTM. Sebelumnya ini tidak pernah
       diizinkan sehingga tombol "Lihat file" selalu ditolak. */
    if ($tipe === 'portofolio') {
        return (bool) Database::fetch(
            'SELECT 1 FROM lamaran lm
               JOIN lowongan l ON l.id = lm.lowongan_id
               JOIN profil_item pi ON pi.mahasiswa_id = lm.mahasiswa_id
              WHERE l.perusahaan_id = ? AND pi.file = ?',
            [$perusahaanId, $file]
        );
    }

    return false;
}
