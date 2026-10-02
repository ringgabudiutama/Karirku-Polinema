<?php
/**
 * Pemeriksa hak akses peran
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * Dipanggil SETELAH Auth::wajibAktif() di baris kedua method controller,
 * contoh: PerusahaanController::pelamar() {
 *   Auth::wajibAktif();
 *   Role::wajib('perusahaan');
 *   ...
 * }
 */

class Role
{
    public static function wajib(string ...$peran): void
    {
        $user = Auth::penggunaSaatIni();
        if (!$user || !in_array($user['role'], $peran, true)) {
            http_response_code(403);
            require __DIR__ . '/../views/publik/403.php';
            exit;
        }
    }
}
