<?php
/**
 * Router sederhana
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * Pola URL: ?url=segmen-controller/segmen-method/param1/param2
 * Contoh:
 *   ?url=                       -> beranda publik (tanpa controller)
 *   ?url=auth/masuk             -> AuthController::formMasuk()
 *   ?url=lowongan/detail/12     -> LowonganController::detail(12)
 *   ?url=info-loker/ab12cd34    -> LowonganController::pratinjau('ab12cd34')
 *
 * Segmen controller & method ditulis kebab-case di URL (enak dibaca di
 * address bar), lalu diubah ke PascalCase/camelCase untuk mencari kelas
 * dan method PHP-nya. Middleware (Auth/Role) TIDAK dipanggil di sini,
 * sengaja dipanggil di baris pertama tiap method controller supaya jelas
 * halaman mana yang butuh login/peran apa saat kode dibaca dari atas ke bawah.
 */

class Router
{
    /** Alias untuk URL pendek/khusus yang tidak mengikuti pola controller/method biasa. */
    private array $aliasKhusus = [
        ''            => ['__beranda__', null],
        'beranda'     => ['__beranda__', null],
        'daftar'      => ['AuthController', 'formDaftar'],
        'masuk'       => ['AuthController', 'formMasuk'],
        'keluar'      => ['AuthController', 'keluar'],
        'status-akun' => ['AuthController', 'statusAkun'],
    ];

    public function jalankan(string $url): void
    {
        $url = trim($url, '/');

        // 1. Alias khusus (beranda, daftar, masuk, keluar, status-akun)
        if (isset($this->aliasKhusus[$url])) {
            [$controllerNama, $method] = $this->aliasKhusus[$url];
            if ($controllerNama === '__beranda__') {
                $this->renderBeranda();
                return;
            }
            $this->panggil($controllerNama, $method, []);
            return;
        }

        // 2. Info loker: info-loker/{kode} (kode acak, bukan angka)
        if (preg_match('#^info-loker/([a-f0-9]+)$#', $url, $m)) {
            $this->panggil('LowonganController', 'pratinjau', [$m[1]]);
            return;
        }

        // 3. Pola umum: controller/method/param1/param2/...
        $segmen = $url === '' ? [] : explode('/', $url);
        $controllerSegmen = array_shift($segmen) ?? '';
        $methodSegmen = array_shift($segmen) ?? 'index';

        $controllerNama = $this->keKelas($controllerSegmen) . 'Controller';
        $methodNama = $this->keMethod($methodSegmen);

        // parameter sisanya: angka murni diubah ke int, selain itu tetap string
        $params = array_map(
            fn($p) => ctype_digit($p) ? (int) $p : $p,
            $segmen
        );

        $this->panggil($controllerNama, $methodNama, $params);
    }

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

        // Method yang hanya boleh dipanggil dari dalam kelasnya sendiri tidak
        // boleh bisa dibuka lewat alamat.
        $refleksi = new ReflectionMethod($controller, $methodNama);
        if (!$refleksi->isPublic() || $refleksi->isStatic()) {
            $this->halaman404();
            return;
        }

        // Alamat seperti /lamaran/batalkan tanpa angka id akan membuat PHP
        // melempar ArgumentCountError dan muncul sebagai halaman fatal error.
        // Jadi jumlah parameternya diperiksa dulu, lalu ditampilkan 404 biasa.
        if (count($params) < $refleksi->getNumberOfRequiredParameters()) {
            $this->halaman404();
            return;
        }

        // Parameter berlebih dibuang supaya alamat seperti
        // /mahasiswa/profil/1/2/3 tidak ikut membuat galat.
        $params = array_slice($params, 0, max($refleksi->getNumberOfParameters(), 0));

        // Method yang meminta angka tidak boleh menerima huruf. Tanpa ini,
        // alamat seperti /lowongan/detail/abc melempar TypeError dan muncul
        // sebagai halaman fatal error, bukan 404 biasa.
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

    private function keKelas(string $segmen): string
    {
        // 'kirim-loker' -> 'KirimLoker'
        return str_replace(' ', '', ucwords(str_replace('-', ' ', $segmen)));
    }

    private function keMethod(string $segmen): string
    {
        // 'form-pasang' -> 'formPasang'
        $kelas = $this->keKelas($segmen);
        return lcfirst($kelas);
    }

    /**
     * Beranda publik. Isinya diambil dari database supaya ikut berubah sendiri
     * begitu ada perusahaan baru diverifikasi atau lowongan baru tayang, bukan
     * daftar contoh yang ditulis tangan di view.
     *
     * Dibungkus try/catch karena beranda harus tetap terbuka walau database
     * belum siap, misalnya saat orang pertama kali memasang proyek ini dan
     * belum sempat menjalankan 01-schema.sql.
     */
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
            // Beranda tetap tampil memakai nilai kosong di atas.
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
