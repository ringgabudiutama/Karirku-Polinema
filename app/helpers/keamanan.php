<?php
/**
 * Fungsi keamanan
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 */

/** Bikin/ambil token CSRF untuk sesi berjalan. */
function csrfToken(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

/** Cetak <input hidden> siap pakai di dalam <form>. */
function csrfField(): string
{
    return '<input type="hidden" name="csrf_token" value="' . e(csrfToken()) . '">';
}

/** Panggil di baris pertama setiap penerima POST. Hentikan request kalau token tidak cocok. */
function csrfVerifikasi(): void
{
    $kirim = $_POST['csrf_token'] ?? '';
    if (!hash_equals($_SESSION['csrf_token'] ?? '', $kirim)) {
        http_response_code(419);
        die('Sesi formulir sudah kedaluwarsa. Muat ulang halaman dan coba lagi.');
    }
}

/** Escape output ke HTML. Nama pendek "e" supaya enak dipakai berulang-ulang di view. */
function e(?string $s): string
{
    return htmlspecialchars($s ?? '', ENT_QUOTES, 'UTF-8');
}

function buatHashPassword(string $plain): string
{
    return password_hash($plain, PASSWORD_DEFAULT);
}

function cocokkanPassword(string $plain, string $hash): bool
{
    return password_verify($plain, $hash);
}

/* ------------------------- pembatasan percobaan login -------------------------
 * Tabel percobaan_login TIDAK ada pada database/01-schema.sql versi ini
 * (skema sengaja disederhanakan tim). Supaya pembatasan 5x gagal di proposal
 * tetap berjalan tanpa menambah tabel baru, dipakai session sementara: counter
 * di sisi server, direset begitu login berhasil atau kedaluwarsa 15 menit.
 * Ini CUKUP untuk demo, tapi hilang kalau session pengguna hilang (mis. ganti
 * browser). Kalau nanti mau lebih permanen, tambahkan tabel percobaan_login
 * seperti komentar TODO di database/01-schema.sql.
 * ------------------------------------------------------------------------- */

function loginTerlaluBanyakGagal(string $email): bool
{
    $cfg = require __DIR__ . '/../config/config.php';
    $data = $_SESSION['percobaan_login'][$email] ?? null;
    if (!$data) {
        return false;
    }
    if (time() - $data['waktu'] > $cfg['blokir_menit'] * 60) {
        unset($_SESSION['percobaan_login'][$email]);
        return false;
    }
    return $data['jumlah'] >= $cfg['max_percobaan_login'];
}

function catatLoginGagal(string $email): void
{
    if (!isset($_SESSION['percobaan_login'][$email])) {
        $_SESSION['percobaan_login'][$email] = ['jumlah' => 0, 'waktu' => time()];
    }
    $_SESSION['percobaan_login'][$email]['jumlah']++;
    $_SESSION['percobaan_login'][$email]['waktu'] = time();
}

function resetLoginGagal(string $email): void
{
    unset($_SESSION['percobaan_login'][$email]);
}

/** Kode acak untuk tautan pratinjau info loker (tidak boleh mudah ditebak). */
function buatKodePratinjau(): string
{
    return bin2hex(random_bytes(16));
}

function buatNamaFileAcak(string $ekstensi): string
{
    return bin2hex(random_bytes(16)) . '.' . strtolower($ekstensi);
}
