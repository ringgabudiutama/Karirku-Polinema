@echo off
REM ============================================================
REM  KarirKu Polinema - jalankan tanpa Apache (mode pengembangan)
REM  Klik dua kali file ini, lalu buka http://localhost:8000
REM ============================================================
cd /d "%~dp0"

where php >nul 2>nul
if errorlevel 1 (
  echo.
  echo  PHP belum terdeteksi di PATH.
  echo  Kalau pakai XAMPP, jalankan perintah ini sebagai gantinya:
  echo.
  echo     C:\xampp\php\php.exe -S localhost:8000 -t public server-dev.php
  echo.
  pause
  exit /b 1
)

echo.
echo  Server berjalan. Buka di browser:
echo.
echo     http://localhost:8000/cek-sistem.php   (cek kesiapan dulu)
echo     http://localhost:8000/masuk            (halaman login)
echo.
echo  Tekan Ctrl+C untuk menghentikan server.
echo.
php -S localhost:8000 -t public server-dev.php
pause
