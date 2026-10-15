<?php
// ===== BACKEND · Pelayan berkas unggahan (dengan cek hak akses) ======

require __DIR__ . '/../app/core/bootstrap.php';

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
<body class="halaman-galat">
  <div class="max-w-460 text-center">
    <h1 class="galat-kode"><?= (int) $kode ?></h1>
    <h3 class="mb-8"><?= e($judul) ?></h3>
    <p class="muted"><?= e($pesan) ?></p>
    <?php if ($saran): ?><p class="muted fs-90"><?= e($saran) ?></p><?php endif; ?>
    <div class="d-flex flex-wrap justify-center gap-10 mt-16">
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
$file = basename($_GET['file'] ?? '');

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

function bolehLihatFilePribadi(string $tipe, string $file, int $penggunaId): bool
{
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

    if ($tipe === 'dokumen_lamaran' || $tipe === 'surat_pengantar') {
        if (Database::fetch(
            'SELECT 1 FROM lamaran lm JOIN mahasiswa m ON m.id = lm.mahasiswa_id
              WHERE m.pengguna_id = ? AND lm.file_surat_pengantar = ?',
            [$penggunaId, $file])) {
            return true;
        }
    }

    if ($tipe === 'portofolio') {
        if (Database::fetch(
            'SELECT 1 FROM profil_item pi JOIN mahasiswa m ON m.id = pi.mahasiswa_id
              WHERE m.pengguna_id = ? AND pi.file = ?',
            [$penggunaId, $file])) {
            return true;
        }
    }

    if (in_array($tipe, ['nib', 'npwp', 'akta', 'domisili'], true)) {
        return (bool) Database::fetch(
            'SELECT 1 FROM dokumen_verifikasi WHERE pengguna_id = ? AND tipe = ? AND file = ?',
            [$penggunaId, $tipe, $file]
        );
    }

    $prsh = Database::fetch('SELECT id FROM perusahaan WHERE pengguna_id = ?', [$penggunaId]);
    if (!$prsh) {
        return false;
    }
    $perusahaanId = (int) $prsh['id'];

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

    if ($tipe === 'foto') {
        return (bool) Database::fetch(
            'SELECT 1 FROM lamaran lm
               JOIN lowongan l ON l.id = lm.lowongan_id
               JOIN mahasiswa m ON m.id = lm.mahasiswa_id
              WHERE l.perusahaan_id = ? AND m.foto = ?',
            [$perusahaanId, $file]
        );
    }

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
