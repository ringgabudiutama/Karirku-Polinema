<?php
/**
 * Pemeriksa sesi login
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * Dipanggil di baris PERTAMA setiap method controller yang butuh login,
 * contoh: MahasiswaController::dashboard() { Auth::wajibLogin(); ... }
 */

class Auth
{
    /** Hentikan request dan lempar ke Masuk kalau belum login sama sekali. */
    public static function wajibLogin(): void
    {
        if (empty($_SESSION['user'])) {
            header('Location: ' . url('masuk'));
            exit;
        }
    }

    /**
     * Sama seperti wajibLogin(), TAPI juga mensyaratkan status_akun = 'aktif'.
     * Akun berstatus menunggu/perbaikan/ditolak/nonaktif dilempar ke
     * Halaman Status Akun, bukan ke halaman yang dituju.
     * Inilah yang membuat "menu lain terkunci selama akun belum aktif".
     */
    public static function wajibAktif(): void
    {
        self::wajibLogin();
        if ($_SESSION['user']['status_akun'] !== 'aktif') {
            header('Location: ' . url('status-akun'));
            exit;
        }
    }

    public static function penggunaSaatIni(): ?array
    {
        return $_SESSION['user'] ?? null;
    }

    public static function sudahLogin(): bool
    {
        return !empty($_SESSION['user']);
    }

    public static function loginkan(array $pengguna): void
    {
        // regenerasi id sesi supaya tidak rentan session fixation
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

    /** Panggil setelah keputusan admin berubah supaya sesi ikut segar tanpa perlu logout manual. */
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
