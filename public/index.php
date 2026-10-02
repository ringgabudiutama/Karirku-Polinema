<?php
/**
 * Titik masuk aplikasi (front controller)
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIAKTIFKAN.
 *
 * Semua request (lihat public/.htaccess) diarahkan ke sini, lalu Router
 * yang memutuskan controller dan method mana yang menangani.
 */

require __DIR__ . '/../app/core/bootstrap.php';

(new Router())->jalankan($_GET['url'] ?? '');
