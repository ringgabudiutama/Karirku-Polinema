<?php
// ===== BACKEND · KONFIGURASI · Aplikasi ==============================

return [
    'nama_aplikasi' => 'KarirKu Polinema',
    'base_url'      => '',
    'zona_waktu'    => 'Asia/Jakarta',
    'upload_dir'    => __DIR__ . '/../../storage/uploads',
    'max_upload_kb' => 2048,
    'sesi_nama'     => 'karirku_sid',
    'max_percobaan_login' => 5,
    'blokir_menit'        => 15,
    'jumlah_admin_jurusan' => 7,
    'debug' => true,
    'email' => [
        'host' => '', 'port' => 587, 'user' => '', 'pass' => '',
        'dari_nama' => 'KarirKu Polinema', 'dari_email' => 'noreply@karirku.polinema.ac.id',
    ],
];
