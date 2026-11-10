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
        // 303: setelah POST, browser selalu membuka tujuan dengan GET
        // (refresh tidak mengirim ulang formulir).
        header('Location: ' . url($path), true, ($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST' ? 303 : 302);
        exit;
    }

    protected function json($data, int $statusCode = 200): void
    {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    protected function halaman404(): void
    {
        http_response_code(404);
        require __DIR__ . '/../views/publik/404.php';
        exit;
    }

    protected function halaman403(string $pesan = ''): void
    {
        http_response_code(403);
        $pesanTambahan = $pesan;
        require __DIR__ . '/../views/publik/403.php';
        exit;
    }

    // --- Input request -----------------------------------------------
    protected function input(string $key, string $default = ''): string
    {
        $v = $_POST[$key] ?? $default;
        return is_array($v) ? $default : trim((string) $v);
    }

    protected function query_(string $key, string $default = ''): string
    {
        $v = $_GET[$key] ?? $default;
        return is_array($v) ? $default : trim((string) $v);
    }

    // --- Pagination (revisi H) ---------------------------------------
    /**
     * Hitung posisi halaman. Mengembalikan [halaman, perHalaman, offset].
     * Nomor halaman di luar batas dialihkan ke halaman terakhir yang ada.
     */
    protected function halaman(int $total, ?int $perHalaman = null): array
    {
        global $config;
        $per = $perHalaman ?? (int) ($config['per_halaman'] ?? 10);
        $totalHalaman = max(1, (int) ceil($total / $per));
        $hal = (int) $this->query_('halaman', '1');
        if ($hal < 1) {
            $hal = 1;
        }
        if ($hal > $totalHalaman) {
            $q = $_GET;
            unset($q['url']);
            $q['halaman'] = $totalHalaman;
            $this->redirect(strtok(Auth::pathSaatIni(), '?') . '?' . http_build_query($q));
        }
        return [$hal, $per, ($hal - 1) * $per];
    }

    /** Data untuk partial layouts/_paginasi.php */
    protected function infoPaginasi(int $total, int $hal, int $per): array
    {
        return [
            'total'        => $total,
            'halaman'      => $hal,
            'perHalaman'   => $per,
            'totalHalaman' => max(1, (int) ceil($total / $per)),
            'dari'         => $total === 0 ? 0 : ($hal - 1) * $per + 1,
            'sampai'       => min($total, $hal * $per),
        ];
    }

    // --- Sesi & keamanan ---------------------------------------------
    protected function penggunaSaatIni(): ?array
    {
        return $_SESSION['user'] ?? null;
    }

    /**
     * Pesan satu kali untuk halaman berikutnya. Untuk pesan gagal pada
     * formulir POST, isian ikut disimpan supaya tidak hilang (revisi G).
     */
    protected function flash(string $tipe, string $pesan): void
    {
        $pesan = implode("\n", array_map('pesanRamah', explode("\n", $pesan)));
        $_SESSION['flash'] = ['tipe' => $tipe, 'pesan' => $pesan];
        if ($tipe === 'bad') {
            simpanIsianLama();
        }
    }

    protected function wajibPost(): void
    {
        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
            http_response_code(405);
            header('Allow: POST');
            $judul = 'Metode tidak diizinkan';
            require __DIR__ . '/../views/publik/galat.php';
            exit;
        }
        csrfVerifikasi();
    }

    /**
     * Ganti kata sandi akun sendiri (dipakai mahasiswa, perusahaan, admin).
     * Sesi lain & "Ingat saya" dicabut; sesi yang sedang dipakai tetap masuk.
     */
    protected function prosesGantiSandiSendiri(string $kembali): void
    {
        $user = Auth::penggunaSaatIni();
        $pengguna = (new Pengguna())->cari($user['id']);
        $lama = $this->input('password_lama');
        $baru = $this->input('password_baru');
        $konfirmasi = $this->input('konfirmasi_password');

        if (!cocokkanPassword($lama, $pengguna['password_hash'])) {
            $this->flash('bad', 'Kata sandi lama tidak sesuai.');
        } elseif (!validasiPassword($baru)) {
            $this->flash('bad', PESAN_PASSWORD);
        } elseif ($baru !== $konfirmasi) {
            $this->flash('bad', 'Konfirmasi kata sandi baru tidak cocok.');
        } else {
            Auth::gantiSandiDanCabutSesi((int) $user['id'], $baru, false, true);
            $this->flash('ok', 'Kata sandi berhasil diperbarui. Sesi di perangkat lain sudah dikeluarkan.');
        }
        $this->redirect($kembali);
    }

    protected function catatAktivitasAdmin(string $aksi, ?int $targetPenggunaId, string $keterangan): void
    {
        $adminId = (new Admin())->idDariPenggunaId((int) Auth::penggunaSaatIni()['id']);
        Database::execute(
            'INSERT INTO log_aktivitas_admin (admin_id, aksi, target_pengguna_id, keterangan, alamat_ip) VALUES (?, ?, ?, ?, ?)',
            [$adminId, $aksi, $targetPenggunaId, mb_substr($keterangan, 0, 500), $_SERVER['REMOTE_ADDR'] ?? null]
        );
    }
}
