<?php
// ===== BACKEND · MIDDLEWARE · Role (cek peran) =======================

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
