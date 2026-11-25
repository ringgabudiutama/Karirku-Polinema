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
   'user'       => 'emailkamu@gmail.com',
'dari_email' => 'emailkamu@gmail.com',
'pass'       => 'ISI_APP_PASSWORD_DI_SINI',
];
