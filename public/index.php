<?php
// ===== BACKEND · ENTRY POINT (semua request masuk lewat sini) ========

require __DIR__ . '/../app/core/bootstrap.php';

(new Router())->jalankan($_GET['url'] ?? '');
