<?php
// ===== BACKEND · KONFIGURASI · Aplikasi ==============================
// Nilai rahasia (kata sandi SMTP) sebaiknya diisi lewat variabel lingkungan
// (getenv) atau langsung di file ini pada server, JANGAN dikirim lewat chat.

$konfigurasi = [
    'nama_aplikasi' => 'KarirKu Polinema',

    // Kosongkan bila folder public/ menjadi document root,
    // isi '/karirku-polinema/public' bila lewat subfolder XAMPP.
    'base_url'      => getenv('APP_BASE_URL') ?: '',

    // Alamat lengkap situs untuk tautan di email dan pesan WhatsApp,
    // misalnya 'https://karirku.polinema.ac.id'. Bila kosong, diambil
    // otomatis dari alamat yang sedang dibuka di browser.
    'app_url'       => getenv('APP_URL') ?: '',

    'zona_waktu'    => 'Asia/Jakarta',

    // --- Mode serverless (Vercel) ---
    // Di Vercel folder proyek hanya-baca dan /tmp bisa hilang kapan saja. Maka sesi
    // login disimpan di database (SesiDb) dan setiap berkas unggahan dicerminkan ke
    // tabel berkas_tersimpan (PenyimpananBerkas). Terdeteksi otomatis dari variabel VERCEL.
    'serverless'    => (bool) (getenv('VERCEL') ?: getenv('KARIRKU_SERVERLESS')),

    // Lokasi tulis unggahan. Serverless: /tmp (sementara, isi aslinya di database).
    'upload_dir'    => (getenv('VERCEL') ?: getenv('KARIRKU_SERVERLESS'))
        ? rtrim(sys_get_temp_dir(), '/') . '/karirku/uploads'
        : __DIR__ . '/../../storage/uploads',
    // Berkas data demo (logo, pamflet, foto, dokumen) yang ikut ke GitHub & di-deploy, hanya dibaca.
    'upload_dir_bawaan' => __DIR__ . '/../../storage/demo-uploads',
    'log_dir'       => (getenv('VERCEL') ?: getenv('KARIRKU_SERVERLESS'))
        ? rtrim(sys_get_temp_dir(), '/') . '/karirku/logs'
        : __DIR__ . '/../../storage/logs',
    'max_upload_kb' => 2048,

    // --- Sesi & cookie (revisi J) ---
    'sesi_nama'        => 'karirku_sid',
    'sesi_menit'       => 120,   // keluar otomatis bila tidak ada aktivitas selama ini
    'ingat_saya_hari'  => 30,    // umur cookie "Ingat saya"

    'max_percobaan_login' => 5,
    'blokir_menit'        => 15,
    'jumlah_admin_jurusan' => 7,
    'per_halaman'          => 10, // revisi H: maksimal 10 data per halaman

    // Ubah ke false sebelum demo/produksi agar pesan error teknis tidak tampil.
    // MATI secara bawaan: pesan error rinci (host/nama database, jalur file) tidak boleh tampil ke pengunjung.
    // Untuk pengembangan lokal nyalakan lewat APP_DEBUG=1 (jalankan.sh / jalankan.bat sudah melakukannya).
    'debug' => filter_var(getenv('APP_DEBUG'), FILTER_VALIDATE_BOOLEAN),

    // --- Email ---
    // Akun SMTP diisi di config/email.lokal.php (salin dari email.lokal.contoh.php)
    // atau lewat variabel lingkungan SMTP_HOST, SMTP_USER, SMTP_PASS.
    'email' => [
        'host'       => getenv('SMTP_HOST') ?: '',
        'port'       => (int) (getenv('SMTP_PORT') ?: 587),
        'user'       => getenv('SMTP_USER') ?: '',
        'pass'       => getenv('SMTP_PASS') ?: '',
        'enkripsi'   => getenv('SMTP_ENKRIPSI') ?: 'tls',   // tls (587), ssl (465), atau none (server uji lokal)
        'dari_nama'  => 'KarirKu Polinema',
        'dari_email' => getenv('SMTP_DARI') ?: '',
    ],
];

// Server online: bila SMTP belum diisi lewat Environment Variables, pakai email.produksi.php
// (hanya kalau kata sandinya sudah diisi).
$emailProduksi = __DIR__ . '/email.produksi.php';
if (trim((string) $konfigurasi['email']['host']) === '' && is_file($emailProduksi)) {
    $produksi = (array) require $emailProduksi;
    if (trim((string) ($produksi['pass'] ?? '')) !== '') {
        $konfigurasi['email'] = array_merge($konfigurasi['email'], $produksi);
    }
}

$emailLokal = __DIR__ . '/email.lokal.php';
if (is_file($emailLokal)) {
    $konfigurasi['email'] = array_merge($konfigurasi['email'], (array) require $emailLokal);
}
// Gmail dan kebanyakan penyedia menolak alamat pengirim yang berbeda dari akun login.
if (trim((string) $konfigurasi['email']['dari_email']) === '') {
    $konfigurasi['email']['dari_email'] = $konfigurasi['email']['user'] !== ''
        ? $konfigurasi['email']['user']
        : 'noreply@karirku.polinema.ac.id';
}

return $konfigurasi;
