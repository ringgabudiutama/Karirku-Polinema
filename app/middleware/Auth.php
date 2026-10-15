<?php
// ===== BACKEND · MIDDLEWARE · Auth (cek login) =======================

class Auth
{
    // --- Penjaga akses -----------------------------------------------
    public static function wajibLogin(): void
    {
        if (empty($_SESSION['user'])) {
            header('Location: ' . url('masuk'));
            exit;
        }
    }

    public static function wajibAktif(): void
    {
        self::wajibLogin();
        if ($_SESSION['user']['status_akun'] !== 'aktif') {
            header('Location: ' . url('status-akun'));
            exit;
        }
    }

    // --- Data sesi ---------------------------------------------------
    public static function penggunaSaatIni(): ?array
    {
        return $_SESSION['user'] ?? null;
    }

    public static function sudahLogin(): bool
    {
        return !empty($_SESSION['user']);
    }

    // --- Login & logout ----------------------------------------------
    public static function loginkan(array $pengguna): void
    {
        session_regenerate_id(true);
        $_SESSION['user'] = [
            'id'          => (int) $pengguna['id'],
            'email'       => $pengguna['email'],
            'role'        => $pengguna['role'],
            'status_akun' => $pengguna['status_akun'],
        ];
    }

    public static function keluar(): void
    {
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $p = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000, $p['path'], $p['domain'], $p['secure'], $p['httponly']);
        }
        session_destroy();
    }

    // --- Sinkron status akun -----------------------------------------
    public static function segarkanStatusAkun(): void
    {
        if (empty($_SESSION['user'])) {
            return;
        }
        $baru = Database::fetch('SELECT status_akun FROM pengguna WHERE id = ?', [$_SESSION['user']['id']]);
        if ($baru) {
            $_SESSION['user']['status_akun'] = $baru['status_akun'];
        }
    }
}
