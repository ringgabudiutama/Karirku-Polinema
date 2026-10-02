<?php
/**
 * Memanggil SETIAP method publik di semua controller, lewat HTTP, dengan
 * parameter id yang benar-benar ada di database, memakai peran yang sesuai.
 * Inilah yang seharusnya menangkap Lowongan::perpanjang() sejak awal.
 */
$B = 'http://127.0.0.1:8000';
$S = '/tmp/claude-0/-home-claude/34c7d75d-6ec8-5e75-91f4-7f39653d6878/scratchpad';
$root = '/home/claude/rev/Karirku-Polinema';

$pdo = new PDO('pgsql:host=/tmp;dbname=karirku_polinema', 'postgres', '', [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$satu = fn(string $sql) => $pdo->query($sql)->fetchColumn();

$id = [
  'mahasiswa'   => $satu("SELECT m.id FROM mahasiswa m JOIN pengguna p ON p.id=m.pengguna_id WHERE p.email='mahasiswa@polinema.ac.id'"),
  'penggunaMhs' => $satu("SELECT id FROM pengguna WHERE email='mahasiswa@polinema.ac.id'"),
  'pendaftar'   => $satu("SELECT id FROM pengguna WHERE status_akun='menunggu' ORDER BY id LIMIT 1"),
  'lowonganPT'  => $satu("SELECT l.id FROM lowongan l JOIN perusahaan pr ON pr.id=l.perusahaan_id JOIN pengguna p ON p.id=pr.pengguna_id WHERE p.email='perusahaan@polinema.ac.id' ORDER BY l.id LIMIT 1"),
  'lowonganAny' => $satu("SELECT id FROM lowongan WHERE status='aktif' ORDER BY id LIMIT 1"),
  'kode'        => $satu("SELECT kode_pratinjau FROM lowongan ORDER BY id LIMIT 1"),
  'lamaranPT'   => $satu("SELECT la.id FROM lamaran la JOIN lowongan l ON l.id=la.lowongan_id JOIN perusahaan pr ON pr.id=l.perusahaan_id JOIN pengguna p ON p.id=pr.pengguna_id WHERE p.email='perusahaan@polinema.ac.id' ORDER BY la.id LIMIT 1"),
  'lamaranMhs'  => $satu("SELECT la.id FROM lamaran la JOIN mahasiswa m ON m.id=la.mahasiswa_id JOIN pengguna p ON p.id=m.pengguna_id WHERE p.email='mahasiswa@polinema.ac.id' AND la.status='diajukan' ORDER BY la.id LIMIT 1"),
  'notif'       => $satu("SELECT id FROM notifikasi ORDER BY id LIMIT 1") ?: 1,
  'jurusan'     => $satu("SELECT id FROM jurusan ORDER BY id LIMIT 1"),
];

/** peran mana yang boleh membuka controller apa */
$peranUntuk = [
  'AdminController' => 'admin', 'MahasiswaController' => 'mahasiswa',
  'PerusahaanController' => 'perusahaan', 'LowonganController' => 'perusahaan',
  'LamaranController' => 'perusahaan', 'KirimLokerController' => 'admin',
  'NotifikasiController' => 'mahasiswa', 'AuthController' => 'tamu',
];
/** method yang perlu peran berbeda dari default controllernya */
$peranKhusus = [
  'LowonganController::daftar' => 'mahasiswa', 'LowonganController::detail' => 'mahasiswa',
  'LowonganController::simpan' => 'mahasiswa', 'LowonganController::pratinjau' => 'tamu',
  'LamaranController::kirim' => 'mahasiswa', 'LamaranController::lamaranSaya' => 'mahasiswa',
  'LamaranController::batalkan' => 'mahasiswa',
];
/** nilai parameter per method */
$param = [
  'AdminController::detailPendaftar' => [$id['pendaftar']], 'AdminController::putuskan' => [$id['pendaftar']],
  'AdminController::nonaktifkanPengguna' => [$id['penggunaMhs']], 'AdminController::aktifkanPengguna' => [$id['penggunaMhs']],
  'AdminController::profilMahasiswa' => [$id['mahasiswa']], 'AdminController::nonaktifkanLowongan' => [$id['lowonganAny']],
  'LowonganController::detail' => [$id['lowonganAny']], 'LowonganController::simpan' => [$id['lowonganAny']],
  'LowonganController::formPasang' => [0], 'LowonganController::tutup' => [$id['lowonganPT']],
  'LowonganController::perpanjang' => [$id['lowonganPT']], 'LowonganController::pratinjau' => [$id['kode']],
  'LamaranController::kirim' => [$id['lowonganAny']], 'LamaranController::batalkan' => [$id['lamaranMhs']],
  'LamaranController::detailPelamar' => [$id['lamaranPT']], 'LamaranController::ubahStatus' => [$id['lamaranPT']],
  'LamaranController::terima' => [$id['lamaranPT']],
  'NotifikasiController::tandaiDibaca' => [$id['notif']],
  'KirimLokerController::kirim' => [$id['lowonganAny'], $id['jurusan']],
  'AuthController::resetSandi' => ['tokenpalsu'], 'AuthController::prosesResetSandi' => ['tokenpalsu'],
];
/** body POST minimal supaya method tidak berhenti di validasi sebelum menyentuh model */
$body = [
  'LowonganController::perpanjang' => ['batas_lamaran' => date('Y-m-d', strtotime('+30 days'))],
  'LowonganController::tutup' => [],
  'AdminController::putuskan' => ['keputusan' => 'perbaikan', 'catatan' => 'Mohon lengkapi berkas.'],
  'LamaranController::ubahStatus' => ['aksi' => 'jadwal_interview', 'mode' => 'daring',
      'tanggal' => date('Y-m-d', strtotime('+10 days')), 'jam' => '09:00',
      'lokasi_tautan' => 'https://meet.google.com/abc-defg-hij'],
  'LamaranController::terima' => ['catatan_perusahaan' => 'Selamat, kamu diterima.'],
  'AdminController::simpanPengaturan' => ['aksi' => 'template_wa', 'template_pesan_wa' => 'Halo {jurusan}, ada lowongan {posisi}.'],
  'KirimLokerController::simpanKontak' => ['jurusan_id' => $id['jurusan'], 'nama' => 'Admin Jurusan', 'nomor_wa' => '081234567890'],
];
/** method yang sengaja dilewati: mengakhiri sesi atau sudah diuji terpisah */
$lewati = ['AuthController::keluar', 'AuthController::prosesMasuk'];

function req(string $url, ?array $post, string $jar): array {
    $ch = curl_init($url);
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER=>true, CURLOPT_FOLLOWLOCATION=>false,
        CURLOPT_COOKIEJAR=>$jar, CURLOPT_COOKIEFILE=>$jar]);
    if ($post !== null) { curl_setopt($ch,CURLOPT_POST,true); curl_setopt($ch,CURLOPT_POSTFIELDS,http_build_query($post)); }
    $b = curl_exec($ch); $k = curl_getinfo($ch, CURLINFO_HTTP_CODE); curl_close($ch);
    return [$k, (string) $b];
}
function login(string $B, string $e, string $p, string $jar): void {
    @unlink($jar); [, $h] = req("$B/masuk", null, $jar);
    preg_match('/name="csrf_token" value="([^"]+)"/', $h, $m);
    req("$B/auth/proses-masuk", ['csrf_token'=>$m[1],'email'=>$e,'password'=>$p], $jar);
}
/** Ambil token CSRF dari halaman yang memang boleh dibuka peran tersebut. */
function csrf(string $B, string $jar, string $peran): string {
    $halaman = [
        'admin'      => ['admin/pengaturan', 'admin/kelola-pengguna'],
        'mahasiswa'  => ['mahasiswa/profil', 'mahasiswa/pengaturan-akun'],
        'perusahaan' => ['perusahaan/profil', 'perusahaan/lowongan'],
        'tamu'       => ['masuk', 'daftar'],
    ][$peran] ?? ['masuk'];
    foreach ($halaman as $h) {
        [, $isi] = req("$B/$h", null, $jar);
        if (preg_match('/name="csrf_token" value="([^"]+)"/', $isi, $m)) return $m[1];
    }
    return '';
}
$jar = [];
foreach ([['admin','admin@polinema.ac.id','admin123'],['mahasiswa','mahasiswa@polinema.ac.id','mahasiswa123'],
          ['perusahaan','perusahaan@polinema.ac.id','perusahaan123']] as [$n,$e,$p]) {
    $jar[$n] = "$S/jar-rute-$n"; login($B, $e, $p, $jar[$n]);
}
$jar['tamu'] = "$S/jar-rute-tamu"; @unlink($jar['tamu']);

function keUrl(string $kelas, string $method): string {
    $c = strtolower(preg_replace('/([a-z0-9])([A-Z])/', '$1-$2', preg_replace('/Controller$/', '', $kelas)));
    $m = strtolower(preg_replace('/([a-z0-9])([A-Z])/', '$1-$2', $method));
    return "$c/$m";
}

$pola = '/Fatal error|Parse error|Uncaught|Call to undefined|SQLSTATE|Warning:|Notice:|Deprecated:/i';
$gagal = 0; $jumlah = 0;
foreach (glob("$root/app/controllers/*.php") as $f) {
    $kelas = basename($f, '.php');
    $src = file_get_contents($f);
    preg_match_all('/public function (\w+)\s*\(/', $src, $mm);
    echo "=== $kelas ===\n";
    foreach ($mm[1] as $method) {
        if ($method === '__construct') continue;
        $sig = "$kelas::$method";
        if (in_array($sig, $lewati, true)) { echo "  lewati $sig\n"; continue; }
        $peran = $peranKhusus[$sig] ?? ($peranUntuk[$kelas] ?? 'admin');
        $j = $jar[$peran];
        $url = $B . '/' . keUrl($kelas, $method);
        foreach ($param[$sig] ?? [] as $p) $url .= '/' . rawurlencode((string) $p);

        // coba GET dulu; kalau controller mewajibkan POST, kirim POST
        [$kode, $isi] = req($url, null, $j);
        $butuhPost = str_contains($isi, 'Method Not Allowed') || str_contains($isi, 'wajibPost')
                     || preg_match('/method.*not allowed/i', $isi);
        if ($butuhPost || str_contains($src, "function $method") && preg_match('/function ' . $method . '\s*\([^)]*\)[^{]*\{\s*\$this->wajibPost\(\)/', $src)) {
            $post = array_merge(['csrf_token' => csrf($B, $j, $peran)], $body[$sig] ?? []);
            [$kode, $isi] = req($url, $post, $j);
        }
        $jumlah++;
        if ($kode === 419) {
            echo "  CSRF   $sig  [419] token ditolak, isi method belum teruji\n";
            $gagal++;
            continue;
        }
        if (preg_match($pola, $isi, $g)) {
            echo "  GAGAL  $sig  ->  " . parse_url($url, PHP_URL_PATH) . "  [$kode]\n";
            preg_match('/(Fatal error|Uncaught|Warning|Notice|Deprecated)[^\n<]{0,160}/i', strip_tags($isi), $pesan);
            echo "         " . trim($pesan[0] ?? $g[0]) . "\n";
            $gagal++;
        } else {
            echo "  ok     $sig  [$kode]\n";
        }
    }
}
echo "\n$jumlah method diuji. " . ($gagal === 0 ? "Tidak ada yang error.\n" : "$gagal error.\n");
