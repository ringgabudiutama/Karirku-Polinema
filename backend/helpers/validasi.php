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

/**
 * Kebijakan kata sandi: 8 sampai 72 byte (bcrypt hanya membaca 72 byte pertama), tidak boleh
 * kata sandi yang sangat umum, tidak boleh kata umum + angka di belakang ("Polinema2026"),
 * dan tidak boleh pola berulang ("12121212", "aaaaaaaa").
 */
function validasiPassword(string $password): bool
{
    $len = strlen($password);
    if ($len < 8 || $len > 72) {
        return false;
    }
    $p = mb_strtolower($password);
    static $umum = [
        'password', 'password1', 'password12', 'password123', 'passw0rd', 'p@ssw0rd', '12345678', '123456789',
        '1234567890', '11111111', '00000000', '87654321', '12341234', '12344321', 'qwertyui', 'qwerty123',
        'qwertyuiop', 'asdfghjk', 'asdfgh123', 'zxcvbnm1', 'iloveyou', 'welcome1', 'admin123', 'admin1234',
        'administrator', 'abc12345', 'abcd1234', 'abcdefgh', 'a1234567', 'aa123456', '1q2w3e4r', '1qaz2wsx',
        'q1w2e3r4', 'qazwsx12', 'letmein1', 'monkey12', 'football', 'superman', 'princess', 'sunshine',
        'whatever', 'trustno1', 'master12', 'samsung1', 'bismillah', 'katasandi', 'kata sandi',
    ];
    static $dasar = [
        'password', 'admin', 'qwerty', 'mahasiswa', 'perusahaan', 'polinema', 'indonesia', 'karirku', 'rahasia',
        'katasandi', 'welcome', 'iloveyou', 'letmein', 'bismillah', 'malang', 'sayang', 'cintaku', 'sandi',
    ];
    if (in_array($p, $umum, true)) {
        return false;
    }
    $inti = preg_replace('/[0-9!@#$%^&*._\-]+$/', '', $p);
    if ($inti !== $p && in_array($inti, $dasar, true) && strlen($p) - strlen($inti) <= 4) {
        return false;                                  // kata umum + sedikit angka di belakang
    }
    if (preg_match('/^(.{1,3})\1+$/su', $p)) {
        return false;                                  // pola berulang
    }
    return true;
}

/** Pesan baku untuk kata sandi yang ditolak. */
const PESAN_PASSWORD = 'Kata sandi 8 sampai 72 karakter dan tidak boleh terlalu umum (contoh yang ditolak: 12345678, password123, polinema2026).';

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

/**
 * Jenis isi berkas (MIME). Memakai ekstensi fileinfo bila aktif; bila tidak
 * (sering mati di XAMPP Windows), dikenali dari beberapa byte awal berkas,
 * jadi aplikasi tidak error "Class finfo not found".
 */
function deteksiMime(string $path): string
{
    if (class_exists('finfo')) {
        $m = (new finfo(FILEINFO_MIME_TYPE))->file($path);
        if ($m) return $m;
    }
    if (function_exists('mime_content_type')) {
        $m = @mime_content_type($path);
        if ($m) return $m;
    }
    $awal = (string) @file_get_contents($path, false, null, 0, 8);
    if (strncmp($awal, '%PDF', 4) === 0) return 'application/pdf';
    if (strncmp($awal, "\xFF\xD8\xFF", 3) === 0) return 'image/jpeg';
    if (strncmp($awal, "\x89PNG", 4) === 0) return 'image/png';
    $info = @getimagesize($path);
    return $info['mime'] ?? 'application/octet-stream';
}

function validasiTipeFile(string $namaFile, array $tipeDiizinkan): bool
{
    return in_array(ekstensiFile($namaFile), $tipeDiizinkan, true);
}

function validasiUkuranFile(int $ukuranByte, int $maksKb): bool
{
    return ceil($ukuranByte / 1024) <= $maksKb;
}

// --- Alamat (revisi F) -----------------------------------------------
/** Mengembalikan daftar pesan galat (kosong = valid). */
function validasiAlamat(array $d, bool $alamatWajib): array
{
    $galat = [];
    if ($alamatWajib && trim((string) $d['alamat']) === '') {
        $galat[] = 'Alamat lengkap wajib diisi.';
    }
    if (mb_strlen((string) $d['alamat']) > 255) {
        $galat[] = 'Alamat maksimal 255 karakter.';
    }
    if (trim((string) $d['kota']) === '' || mb_strlen((string) $d['kota']) > 100) {
        $galat[] = 'Kota/kabupaten wajib diisi (maksimal 100 karakter).';
    }
    if ((string) $d['provinsi'] !== '' && !in_array($d['provinsi'], DAFTAR_PROVINSI, true)) {
        $galat[] = 'Pilih provinsi dari daftar.';
    }
    if ((string) $d['kode_pos'] !== '' && !preg_match('/^\d{5}$/', (string) $d['kode_pos'])) {
        $galat[] = 'Kode pos harus 5 digit angka.';
    }
    return $galat;
}
