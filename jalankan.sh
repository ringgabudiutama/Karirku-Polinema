#!/usr/bin/env bash
# KarirKu Polinema - jalankan tanpa Apache (mode pengembangan)
# Pakai: bash jalankan.sh   lalu buka http://localhost:8000
cd "$(dirname "$0")"
echo
echo "  Server berjalan. Buka di browser:"
echo "    http://localhost:8000/cek-sistem.php   (cek kesiapan dulu)"
echo "    http://localhost:8000/masuk            (halaman login)"
echo
echo "  Tekan Ctrl+C untuk menghentikan server."
echo
php -S localhost:8000 -t public server-dev.php
