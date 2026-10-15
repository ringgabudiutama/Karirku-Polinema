<?php
// ===== BACKEND · HELPER · Keamanan ===================================

// --- CSRF ------------------------------------------------------------
function csrfToken(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function csrfField(): string
{
    return '<input type="hidden" name="csrf_token" value="' . e(csrfToken()) . '">';
}

function csrfVerifikasi(): void
{
    $kirim = $_POST['csrf_token'] ?? '';
    if (!hash_equals($_SESSION['csrf_token'] ?? '', $kirim)) {
        http_response_code(419);
        die('Sesi formulir sudah kedaluwarsa. Muat ulang halaman dan coba lagi.');
    }
}

// --- Escape output ---------------------------------------------------
function e(?string $s): string
{
    return htmlspecialchars($s ?? '', ENT_QUOTES, 'UTF-8');
}

// --- Password --------------------------------------------------------
function buatHashPassword(string $plain): string
{
    return password_hash($plain, PASSWORD_DEFAULT);
}

function cocokkanPassword(string $plain, string $hash): bool
{
    return password_verify($plain, $hash);
}

// --- Batas percobaan login -------------------------------------------
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

// --- Kode & nama acak ------------------------------------------------
function buatKodePratinjau(): string
{
    return bin2hex(random_bytes(16));
}

function buatNamaFileAcak(string $ekstensi): string
{
    return bin2hex(random_bytes(16)) . '.' . strtolower($ekstensi);
}
