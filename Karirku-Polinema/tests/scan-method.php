<?php
/**
 * Memuat SEMUA kelas proyek, lalu memeriksa setiap pemanggilan method
 * terhadap daftar method yang benar-benar ada (lewat Reflection).
 * Menangkap kasus seperti Lowongan::perpanjang() yang dipanggil tapi
 * belum pernah dibuat.
 */
$root = dirname(__DIR__);
foreach (['core', 'models', 'services', 'helpers', 'middleware', 'controllers'] as $dir) {
    foreach (glob("$root/app/$dir/*.php") as $f) {
        $isi = file_get_contents($f);
        if (preg_match('/^\s*(abstract\s+)?(class|interface|trait)\s/m', $isi)) {
            require_once $f;
        }
    }
}

/** daftar method milik tiap kelas */
$punya = [];
foreach (get_declared_classes() as $k) {
    $r = new ReflectionClass($k);
    if (!$r->getFileName() || !str_starts_with($r->getFileName(), $root)) continue;
    $punya[$k] = array_map(fn($m) => $m->getName(), $r->getMethods());
}

$cariKelas = function (string $nama) use ($punya) {
    foreach ($punya as $k => $_) if (strcasecmp($k, $nama) === 0) return $k;
    return null;
};

$files = array_merge(
    glob("$root/app/controllers/*.php"), glob("$root/app/models/*.php"),
    glob("$root/app/services/*.php"), glob("$root/app/core/*.php"),
    glob("$root/app/views/*/*.php"), glob("$root/public/*.php")
);

$masalah = 0;
foreach ($files as $f) {
    $src = file_get_contents($f);
    $rel = str_replace("$root/", '', $f);

    // pola 1: (new Kelas(...))->method(   dan   (new Kelas)->method(
    preg_match_all('/\(\s*new\s+(\w+)\s*\([^)]*\)\s*\)\s*->\s*(\w+)\s*\(/', $src, $m, PREG_SET_ORDER);
    // pola 2: Kelas::method(
    preg_match_all('/(?<![\w$>:])([A-Z]\w+)::(\w+)\s*\(/', $src, $m2, PREG_SET_ORDER);

    foreach (array_merge($m, $m2) as $x) {
        [$semua, $kelas, $method] = $x;
        $nyata = $cariKelas($kelas);
        if ($nyata === null) continue;              // kelas luar / bawaan PHP
        if (in_array($method, ['class'], true)) continue;
        if (!in_array($method, $punya[$nyata], true)) {
            $baris = substr_count(substr($src, 0, strpos($src, $semua)), "\n") + 1;
            echo "HILANG  $rel:$baris   $nyata::$method()  dipanggil tapi tidak ada\n";
            $masalah++;
        }
    }

    // pola 3: $variabelModel->method( — tipe variabel diambil dari assignment
    // "= new Kelas(" TERAKHIR sebelum pemanggilan (bukan satu tipe per file),
    // karena $model bisa berisi kelas berbeda di fungsi yang berbeda.
    preg_match_all('/\$(\w+)\s*=\s*new\s+(\w+)\s*\(/', $src, $vm, PREG_SET_ORDER | PREG_OFFSET_CAPTURE);
    preg_match_all('/(\$\w+)\s*->\s*(\w+)\s*\(/', $src, $pm, PREG_SET_ORDER | PREG_OFFSET_CAPTURE);
    foreach ($pm as $p) {
        $var = $p[1][0]; $method = $p[2][0]; $pos = $p[0][1];
        $tipe = null;
        foreach ($vm as $v) {
            if ($v[0][1] < $pos && '$' . $v[1][0] === $var) $tipe = $v[2][0];
        }
        // assignment harus berada di fungsi yang sama: tidak boleh ada "function" di antaranya
        if ($tipe === null) continue;
        $nyata = $cariKelas($tipe);
        if ($nyata === null) continue;
        if (!in_array($method, $punya[$nyata], true)) {
            $baris = substr_count(substr($src, 0, $pos), "\n") + 1;
            echo "HILANG  $rel:$baris   $nyata::{$method}()  dipanggil lewat {$var} tapi tidak ada\n";
            $masalah++;
        }
    }
}
echo "\n" . ($masalah === 0 ? "Semua method yang dipanggil tersedia.\n" : "$masalah pemanggilan ke method yang belum ada.\n");
