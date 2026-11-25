<?php
// Salin file ini menjadi email.lokal.php lalu isi akun pengirim.
// email.lokal.php tidak ikut git maupun zip karena berisi kata sandi.
//
// Gmail: aktifkan Verifikasi 2 Langkah, lalu buat App Password di
// https://myaccount.google.com/apppasswords (16 huruf, tanpa spasi).
return [
    'host'     => 'smtp.gmail.com',
    'port'     => 587,
    'enkripsi' => 'tls',
    'user'     => 'ringgabudiutama819@gmail.com',
    'dari_email' => 'ringgabudiutama819@gmail.com',
    'pass'     => 'wsbimtdmlmtymlnc',
];
