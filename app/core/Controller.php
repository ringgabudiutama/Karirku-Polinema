<?php
// ===== BACKEND · CORE · Controller induk =============================

abstract class Controller
{
    // --- Render view & redirect --------------------------------------
    protected function view(string $nama, array $data = []): void
    {
        extract($data, EXTR_SKIP);
        $path = __DIR__ . '/../views/' . $nama . '.php';

        if (!is_file($path)) {
            http_response_code(500);
            if ((require __DIR__ . '/../config/config.php')['debug']) {
                die("View tidak ditemukan: {$nama} (dicari di {$path})");
            }
            die('Terjadi gangguan pada server.');
        }

        require $path;
    }

    protected function redirect(string $path): void
    {
        header('Location: ' . url($path));
        exit;
    }

    protected function json($data, int $statusCode = 200): void
    {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    // --- Input request -----------------------------------------------
    protected function input(string $key, string $default = ''): string
    {
        return trim($_POST[$key] ?? $default);
    }

    protected function query_(string $key, string $default = ''): string
    {
        return trim($_GET[$key] ?? $default);
    }

    // --- Sesi & keamanan ---------------------------------------------
    protected function penggunaSaatIni(): ?array
    {
        return $_SESSION['user'] ?? null;
    }

    protected function flash(string $tipe, string $pesan): void
    {
        $_SESSION['flash'] = ['tipe' => $tipe, 'pesan' => $pesan];
    }

    protected function wajibPost(): void
    {
        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
            http_response_code(405);
            die('Metode tidak diizinkan.');
        }
        csrfVerifikasi();
    }
}
