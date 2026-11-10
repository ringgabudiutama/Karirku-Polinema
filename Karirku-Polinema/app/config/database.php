<?php
// ===== BACKEND · KONFIGURASI · Koneksi database ======================
//
// JANGAN menulis password langsung di file ini (file ini ikut ke GitHub/zip).
// Ada dua cara mengisinya:
//   1. Variabel lingkungan: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS  (cocok untuk server hosting)
//   2. File app/config/database.lokal.php  (cocok untuk XAMPP di laptop; file ini
//      diabaikan git dan tidak ikut dikirim). Contoh: database.lokal.contoh.php
//
// Di server produksi pakai akun database terbatas (karirku_app), bukan postgres.
// Panduan lengkap: docs/05-panduan-hosting-aman.md

$dasar = [
    'host' => getenv('DB_HOST') ?: '127.0.0.1',
    'port' => getenv('DB_PORT') ?: 5432,
    'nama' => getenv('DB_NAME') ?: 'karirku_polinema',
    'user' => getenv('DB_USER') ?: 'postgres',
    'pass' => getenv('DB_PASS') ?: 'Ringga27',

    // Pemutakhiran skema otomatis saat aplikasi pertama dibuka (nyaman untuk lokal).
    // Di produksi isi DB_MIGRASI_OTOMATIS=0: migrasi dijalankan manual oleh pemilik
    // database, sehingga akun aplikasi tidak perlu hak mengubah struktur tabel.
    'migrasi_otomatis' => getenv('DB_MIGRASI_OTOMATIS') === false
        ? true
        : filter_var(getenv('DB_MIGRASI_OTOMATIS'), FILTER_VALIDATE_BOOLEAN),

    // Pakai ulang koneksi antar-permintaan (PHP-FPM). Menghemat ~10 ms per halaman
    // (membuka koneksi baru dengan SCRAM itu mahal). Di produksi: DB_PERSISTEN=1 dan
    // pastikan batas koneksi akun aplikasi >= pm.max_children. Mati secara bawaan.
    'persisten' => filter_var(getenv('DB_PERSISTEN'), FILTER_VALIDATE_BOOLEAN),

    // disable | allow | prefer | require | verify-full.
    // Isi 'require' atau 'verify-full' bila database ada di server lain.
    'sslmode' => getenv('DB_SSLMODE') ?: 'prefer',
];

// Satu URL koneksi (Neon, Vercel Postgres, Supabase), mis.
// postgresql://user:pass@ep-xxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
// Versi tanpa pooler didahulukan: aplikasi memakai prepared statement & advisory lock.
foreach (['DATABASE_URL_UNPOOLED', 'POSTGRES_URL_NON_POOLING', 'DATABASE_URL', 'POSTGRES_URL'] as $namaVar) {
    $urlDb = getenv($namaVar);
    if (!$urlDb) {
        continue;
    }
    $u = parse_url($urlDb);
    if (!empty($u['host'])) {
        parse_str($u['query'] ?? '', $q);
        $dasar = array_merge($dasar, [
            'host'    => $u['host'],
            'port'    => $u['port'] ?? 5432,
            'nama'    => ltrim($u['path'] ?? '/postgres', '/'),
            'user'    => rawurldecode($u['user'] ?? ''),
            'pass'    => rawurldecode($u['pass'] ?? ''),
            'sslmode' => $q['sslmode'] ?? 'require',
        ]);
    }
    break;
}

$lokal = __DIR__ . '/database.lokal.php';
return is_file($lokal) ? array_merge($dasar, (array) require $lokal) : $dasar;
