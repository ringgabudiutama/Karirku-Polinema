<?php
/**
 * Controller induk
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * Semua controller (AuthController, MahasiswaController, dst) mewarisi
 * kelas ini untuk method bantu: view(), redirect(), json(), input(), dan
 * akses data sesi pengguna yang sedang login.
 */

abstract class Controller
{
    /**
     * Render file view dari app/views/, dengan $data diekstrak jadi variabel
     * yang bisa langsung dipakai di dalam file view tersebut.
     *
     * Contoh: $this->view('mahasiswa/dashboard', ['mahasiswa' => $mhs]);
     * akan me-render app/views/mahasiswa/dashboard.php dengan variabel $mahasiswa.
     */
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

    /** Redirect ke URL relatif terhadap base_url aplikasi. */
    protected function redirect(string $path): void
    {
        header('Location: ' . url($path));
        exit;
    }

    /** Kirim respons JSON, dipakai untuk endpoint yang dipanggil lewat fetch()/AJAX. */
    protected function json($data, int $statusCode = 200): void
    {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    /** Ambil satu field dari POST, sudah di-trim. */
    protected function input(string $key, string $default = ''): string
    {
        return trim($_POST[$key] ?? $default);
    }

    /** Ambil satu field dari GET/query string, sudah di-trim. */
    protected function query_(string $key, string $default = ''): string
    {
        return trim($_GET[$key] ?? $default);
    }

    /** Data pengguna yang sedang login (dari sesi), atau null bila belum login. */
    protected function penggunaSaatIni(): ?array
    {
        return $_SESSION['user'] ?? null;
    }

    /** Setel pesan flash yang akan tampil sekali setelah redirect. */
    protected function flash(string $tipe, string $pesan): void
    {
        $_SESSION['flash'] = ['tipe' => $tipe, 'pesan' => $pesan];
    }

    /** Wajibkan request berupa POST dengan token CSRF yang valid, atau hentikan. */
    protected function wajibPost(): void
    {
        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
            http_response_code(405);
            die('Metode tidak diizinkan.');
        }
        csrfVerifikasi();
    }
}
