<?php
// ===== BACKEND · KONFIGURASI · Koneksi database ======================

return [
    'host' => getenv('DB_HOST') ?: '127.0.0.1',
    'port' => getenv('DB_PORT') ?: 5432,
    'nama' => getenv('DB_NAME') ?: 'karirku_polinema',
    'user' => getenv('DB_USER') ?: 'postgres',
    'pass' => getenv('DB_PASS') ?: 'Ringga27',
];
