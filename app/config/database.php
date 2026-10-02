<?php
/**
 * Koneksi PostgreSQL
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * Nilai di bawah bisa ditimpa lewat environment variable saat deploy,
 * supaya kata sandi asli tidak pernah ikut ter-commit ke Git.
 */

return [
    'host' => getenv('DB_HOST') ?: '127.0.0.1',
    'port' => getenv('DB_PORT') ?: 5432,
    'nama' => getenv('DB_NAME') ?: 'karirku_polinema',
    'user' => getenv('DB_USER') ?: 'postgres',
    'pass' => getenv('DB_PASS') ?: 'Ringga27',
];
