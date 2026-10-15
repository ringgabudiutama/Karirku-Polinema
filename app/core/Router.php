<?php
// ===== BACKEND · CORE · Router (URL -> controller) ===================

class Router
{
    private array $aliasKhusus = [
        ''            => ['__beranda__', null],
        'beranda'     => ['__beranda__', null],
        'daftar'      => ['AuthController', 'formDaftar'],
        'masuk'       => ['AuthController', 'formMasuk'],
        'keluar'      => ['AuthController', 'keluar'],
        'status-akun' => ['AuthController', 'statusAkun'],
    ];

    // --- Pencocokan URL ----------------------------------------------
    public function jalankan(string $url): void
    {
        $url = trim($url, '/');

        if (isset($this->aliasKhusus[$url])) {
            [$controllerNama, $method] = $this->aliasKhusus[$url];
            if ($controllerNama === '__beranda__') {
                $this->renderBeranda();
                return;
            }
            $this->panggil($controllerNama, $method, []);
            return;
        }

        if (preg_match('#^info-loker/([a-f0-9]+)$#', $url, $m)) {
            $this->panggil('LowonganController', 'pratinjau', [$m[1]]);
            return;
        }

        $segmen = $url === '' ? [] : explode('/', $url);
        $controllerSegmen = array_shift($segmen) ?? '';
        $methodSegmen = array_shift($segmen) ?? 'index';

        $controllerNama = $this->keKelas($controllerSegmen) . 'Controller';
        $methodNama = $this->keMethod($methodSegmen);

        $params = array_map(
            fn($p) => ctype_digit($p) ? (int) $p : $p,
            $segmen
        );

        $this->panggil($controllerNama, $methodNama, $params);
    }

    // --- Pemanggil controller ----------------------------------------
    private function panggil(string $controllerNama, string $methodNama, array $params): void
    {
        if (!class_exists($controllerNama, false) && !$this->muatKelas($controllerNama)) {
            $this->halaman404();
            return;
        }

        $controller = new $controllerNama();
        if (!method_exists($controller, $methodNama)) {
            $this->halaman404();
            return;
        }

        $refleksi = new ReflectionMethod($controller, $methodNama);
        if (!$refleksi->isPublic() || $refleksi->isStatic()) {
            $this->halaman404();
            return;
        }

        if (count($params) < $refleksi->getNumberOfRequiredParameters()) {
            $this->halaman404();
            return;
        }

        $params = array_slice($params, 0, max($refleksi->getNumberOfParameters(), 0));

        foreach ($refleksi->getParameters() as $i => $parameter) {
            if (!array_key_exists($i, $params)) {
                break;
            }
            $tipe = $parameter->getType();
            if ($tipe instanceof ReflectionNamedType && $tipe->getName() === 'int'
                && !is_int($params[$i])) {
                $this->halaman404();
                return;
            }
        }

        call_user_func_array([$controller, $methodNama], $params);
    }

    private function muatKelas(string $controllerNama): bool
    {
        $file = __DIR__ . '/../controllers/' . $controllerNama . '.php';
        if (!is_file($file)) {
            return false;
        }
        require_once $file;
        return class_exists($controllerNama, false);
    }

    // --- Konversi nama -----------------------------------------------
    private function keKelas(string $segmen): string
    {
        return str_replace(' ', '', ucwords(str_replace('-', ' ', $segmen)));
    }

    private function keMethod(string $segmen): string
    {
        $kelas = $this->keKelas($segmen);
        return lcfirst($kelas);
    }

    // --- Halaman khusus ----------------------------------------------
    private function renderBeranda(): void
    {
        $mitra = [];
        $lowonganTerbaru = [];
        $statistik = ['perusahaan' => 0, 'lowongan' => 0, 'mahasiswa' => 0];

        try {
            $mitra = (new Perusahaan())->mitraTerverifikasi(18);
            $lowonganTerbaru = (new Lowongan())->terbaruUntukPublik(6);
            $statistik = Database::fetch(
                "SELECT
                   (SELECT count(*) FROM perusahaan pr JOIN pengguna p ON p.id = pr.pengguna_id
                     WHERE p.status_akun = 'aktif')                                   AS perusahaan,
                   (SELECT count(*) FROM lowongan
                     WHERE status = 'aktif' AND batas_lamaran >= CURRENT_DATE)        AS lowongan,
                   (SELECT count(*) FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
                     WHERE p.status_akun = 'aktif')                                   AS mahasiswa"
            ) ?: $statistik;
        } catch (Throwable $e) {
        }

        require __DIR__ . '/../views/publik/beranda.php';
    }

    private function halaman404(): void
    {
        http_response_code(404);
        $file = __DIR__ . '/../views/publik/404.php';
        if (is_file($file)) {
            require $file;
        } else {
            echo '<h1>404</h1><p>Halaman tidak ditemukan.</p>';
        }
    }
}
