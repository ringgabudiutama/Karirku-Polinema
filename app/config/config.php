<?php
/**
 * Konfigurasi umum aplikasi
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: KERANGKA KOSONG, belum diisi logika.
 *
 * Yang harus dikerjakan:
 *   - Isi nilai sesuai lingkungan masing-masing, jangan commit kata sandi asli.
 *   - Tambahkan konstanta lain bila diperlukan.
 */

return [
    'nama_aplikasi' => 'KarirKu POLINEMA',
    'base_url'      => 'http://localhost/karirku-polinema/public',
    'zona_waktu'    => 'Asia/Jakarta',
    'upload_dir'    => __DIR__ . '/../../storage/uploads',
    'max_upload_kb' => 2048,
    'email' => [
        'host' => '', 'port' => 587, 'user' => '', 'pass' => '',
        'dari_nama' => 'KarirKu POLINEMA', 'dari_email' => '',
    ],
];
