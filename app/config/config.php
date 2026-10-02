<?php
/**
 * Konfigurasi umum aplikasi
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 */

return [
    'nama_aplikasi' => 'KarirKu Polinema',
    // PENTING, sesuaikan dengan cara kamu menjalankan (lihat PANDUAN-JALANKAN.md):
    //   ''                          -> pakai jalankan.bat / php -S, atau public/ jadi
    //                                  document root Apache. Ini pengaturan sekarang.
    //   '/karirku-polinema/public'  -> folder disalin ke htdocs XAMPP dan diakses lewat
    //                                  http://localhost/karirku-polinema/public/
    // Kalau ragu, buka /cek-sistem.php di browser. Halaman itu menyebutkan
    // nilai yang benar untuk komputermu.
    'base_url'      => '',
    'zona_waktu'    => 'Asia/Jakarta',
    'upload_dir'    => __DIR__ . '/../../storage/uploads',
    'max_upload_kb' => 2048,
    'sesi_nama'     => 'karirku_sid',
    'max_percobaan_login' => 5,
    'blokir_menit'        => 15,
    'jumlah_admin_jurusan' => 7,
    'debug' => true, // set false sebelum demo/produksi
    'email' => [
        'host' => '', 'port' => 587, 'user' => '', 'pass' => '',
        'dari_nama' => 'KarirKu Polinema', 'dari_email' => 'noreply@karirku.polinema.ac.id',
    ],
];
