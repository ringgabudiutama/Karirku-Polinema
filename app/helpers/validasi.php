<?php
/**
 * Kumpulan fungsi validasi
 * PIC   : Aqillah (UI/UX, Frontend, dan Integrasi)
 * Status: DIISI (silakan sesuaikan pesannya kalau mau nuansa lain).
 */

function validasiEmail(string $email): bool
{
    return (bool) filter_var($email, FILTER_VALIDATE_EMAIL);
}

/** NIM Polinema: angka saja, panjang wajar 8-20 digit (beberapa prodi format NIM-nya beda panjang). */
function validasiNim(string $nim): bool
{
    return (bool) preg_match('/^\d{8,20}$/', $nim);
}

/** Nomor WhatsApp Indonesia: boleh diawali 08 atau 62, angka saja, 9-15 digit. */
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

/** Dipakai saat Ditolak/Minta Perbaikan/Nonaktifkan: catatan alasan wajib diisi. */
function validasiWajibIsi(string $nilai): bool
{
    return trim($nilai) !== '';
}

function validasiRentangAngka($nilai, float $min, float $max): bool
{
    return is_numeric($nilai) && $nilai >= $min && $nilai <= $max;
}

/** Tipe file dari nama file (huruf kecil, tanpa titik), contoh: 'pdf', 'jpg'. */
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
