<?php
// ===== BACKEND · HELPER · Validasi input =============================

// --- Validasi data ---------------------------------------------------
function validasiEmail(string $email): bool
{
    return (bool) filter_var($email, FILTER_VALIDATE_EMAIL);
}

function validasiNim(string $nim): bool
{
    return (bool) preg_match('/^\d{8,20}$/', $nim);
}

function validasiWhatsapp(string $nomor): bool
{
    $bersih = preg_replace('/[\s\-]/', '', $nomor);
    return (bool) preg_match('/^(08|62)\d{8,13}$/', $bersih);
}

function validasiPassword(string $password): bool
{
    return strlen($password) >= 8;
}

function validasiTanggal(string $tanggal, string $format = 'Y-m-d'): bool
{
    $d = DateTime::createFromFormat($format, $tanggal);
    return $d && $d->format($format) === $tanggal;
}

function validasiWajibIsi(string $nilai): bool
{
    return trim($nilai) !== '';
}

function validasiRentangAngka($nilai, float $min, float $max): bool
{
    return is_numeric($nilai) && $nilai >= $min && $nilai <= $max;
}

// --- Validasi berkas -------------------------------------------------
function ekstensiFile(string $namaFile): string
{
    return strtolower(pathinfo($namaFile, PATHINFO_EXTENSION));
}

function validasiTipeFile(string $namaFile, array $tipeDiizinkan): bool
{
    return in_array(ekstensiFile($namaFile), $tipeDiizinkan, true);
}

function validasiUkuranFile(int $ukuranByte, int $maksKb): bool
{
    return ceil($ukuranByte / 1024) <= $maksKb;
}
