<?php
// ===== BACKEND · MIDDLEWARE · Auth (cek login, sesi, "Ingat saya") ===

class Auth
{
    private const COOKIE_INGAT = 'karirku_ingat';

    // --- Penjaga akses -----------------------------------------------
    public static function wajibLogin(): void
    {
        if (empty($_SESSION['user'])) {
            // Revisi B: setelah masuk, pengguna dikembalikan ke halaman tujuan.
            if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'GET') {
                $_SESSION['tujuan_setelah_login'] = self::pathSaatIni();
            }
            if (empty($_SESSION['flash'])) {
                $_SESSION['flash'] = ['tipe' => 'warn', 'pesan' => 'Silakan masuk terlebih dahulu untuk membuka halaman itu.'];
            }
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
        // Revisi L: kata sandi sementara dari Admin wajib diganti dulu.
        if (!empty($_SESSION['user']['wajib_ganti_sandi'])) {
            header('Location: ' . url('akun/ganti-sandi-wajib'));
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

    /** Path internal yang sedang dibuka (tanpa base_url), misalnya "lowongan/detail/3". */
    public static function pathSaatIni(): string
    {
        global $config;
        $uri = (string) ($_SERVER['REQUEST_URI'] ?? '/');
        $base = rtrim((string) $config['base_url'], '/');
        if ($base !== '' && str_starts_with($uri, $base)) {
            $uri = substr($uri, strlen($base));
        }
        return ltrim($uri, '/');
    }

    // --- Login & logout ----------------------------------------------
    public static function loginkan(array $pengguna, bool $ingatSaya = false): void
    {
        session_regenerate_id(true);           // cegah session fixation
        $_SESSION['user'] = [
            'id'                => (int) $pengguna['id'],
            'email'             => $pengguna['email'],
            'role'              => $pengguna['role'],
            'status_akun'       => $pengguna['status_akun'],
            'versi_sesi'        => (int) ($pengguna['versi_sesi'] ?? 1),
            'wajib_ganti_sandi' => !empty($pengguna['wajib_ganti_sandi']) && $pengguna['wajib_ganti_sandi'] !== 'f',
        ];
        $_SESSION['aktivitas_terakhir'] = time();
        csrfGantiToken();
        if ($ingatSaya) {
            self::buatTokenIngat((int) $pengguna['id']);
        }
    }

    public static function keluar(): void
    {
        self::hapusTokenIngatSaatIni();
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $p = session_get_cookie_params();
            setcookie(session_name(), '', [
                'expires' => time() - 42000, 'path' => $p['path'], 'domain' => $p['domain'],
                'secure' => $p['secure'], 'httponly' => true, 'samesite' => 'Lax',
            ]);
        }
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_destroy();
        }
        session_start();                        // sesi baru yang bersih untuk pesan flash
        session_regenerate_id(true);
    }

    // --- Penjaga sesi tiap request (dipanggil dari bootstrap) ---------
    public static function jagaSesi(): void
    {
        global $config;

        if (empty($_SESSION['user'])) {
            self::coba_masukDariCookie();
            return;
        }

        // Halaman berlogin tidak boleh disimpan di cache browser/proxy,
        // supaya tombol Back setelah Keluar tidak menampilkan data lama.
        if (!headers_sent()) {
            header('Cache-Control: no-store, no-cache, must-revalidate, private');
            header('Pragma: no-cache');
        }

        // 1. Idle timeout.
        $batas = (int) ($config['sesi_menit'] ?? 120) * 60;
        $terakhir = (int) ($_SESSION['aktivitas_terakhir'] ?? time());
        if (time() - $terakhir > $batas && empty($_COOKIE[self::COOKIE_INGAT])) {
            self::keluar();
            $_SESSION['flash'] = ['tipe' => 'warn', 'pesan' => 'Sesi Anda berakhir karena tidak ada aktivitas selama ' . ($batas / 60) . ' menit. Silakan masuk lagi.'];
            return;
        }
        $_SESSION['aktivitas_terakhir'] = time();

        // 2. Sinkron status & versi sesi dengan database.
        try {
            $baris = Database::fetch(
                'SELECT status_akun, versi_sesi, wajib_ganti_sandi FROM pengguna WHERE id = ?',
                [$_SESSION['user']['id']]
            );
        } catch (Throwable $e) {
            return; // database belum siap: biarkan halaman menampilkan pesan koneksi
        }
        if (!$baris) {
            self::keluar();
            $_SESSION['flash'] = ['tipe' => 'bad', 'pesan' => 'Akun tidak ditemukan. Silakan masuk lagi.'];
            return;
        }
        if ((int) $baris['versi_sesi'] !== (int) ($_SESSION['user']['versi_sesi'] ?? 1)) {
            self::keluar();
            $_SESSION['flash'] = ['tipe' => 'warn', 'pesan' => 'Kata sandi atau status akun Anda baru saja diubah, sehingga semua sesi lama dikeluarkan. Silakan masuk lagi.'];
            return;
        }
        if ($baris['status_akun'] === 'nonaktif') {
            self::keluar();
            $_SESSION['flash'] = ['tipe' => 'bad', 'pesan' => 'Akun ini telah dinonaktifkan Admin. Hubungi Career Center untuk info lebih lanjut.'];
            return;
        }
        $_SESSION['user']['status_akun'] = $baris['status_akun'];
        $_SESSION['user']['wajib_ganti_sandi'] = (bool) $baris['wajib_ganti_sandi'];
    }

    /** Dipertahankan untuk kode lama; sinkronisasi kini otomatis di jagaSesi(). */
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

    // --- Ganti sandi & cabut sesi (revisi J & L) ----------------------
    /**
     * Ganti kata sandi lalu keluarkan SEMUA sesi lain dan hapus token
     * "Ingat saya". Sesi yang sedang dipakai tetap masuk bila $tetapMasuk.
     */
    public static function gantiSandiDanCabutSesi(int $penggunaId, string $sandiBaru, bool $wajibGanti = false, bool $tetapMasuk = true): void
    {
        Database::execute(
            'UPDATE pengguna SET password_hash = ?, versi_sesi = versi_sesi + 1, wajib_ganti_sandi = ? WHERE id = ?',
            [buatHashPassword($sandiBaru), $wajibGanti ? 'true' : 'false', $penggunaId]
        );
        Database::execute('DELETE FROM token_ingat WHERE pengguna_id = ?', [$penggunaId]);

        if ($tetapMasuk && !empty($_SESSION['user']) && (int) $_SESSION['user']['id'] === $penggunaId) {
            $versi = Database::fetch('SELECT versi_sesi FROM pengguna WHERE id = ?', [$penggunaId]);
            session_regenerate_id(true);
            $_SESSION['user']['versi_sesi'] = (int) ($versi['versi_sesi'] ?? 1);
            $_SESSION['user']['wajib_ganti_sandi'] = $wajibGanti;
        }
    }

    /** Keluarkan semua sesi milik pengguna (dipakai saat akun dinonaktifkan). */
    public static function cabutSemuaSesi(int $penggunaId): void
    {
        Database::execute('UPDATE pengguna SET versi_sesi = versi_sesi + 1 WHERE id = ?', [$penggunaId]);
        Database::execute('DELETE FROM token_ingat WHERE pengguna_id = ?', [$penggunaId]);
    }

    // --- "Ingat saya" (revisi B & J) ----------------------------------
    // Cookie berisi selector:validator acak, BUKAN kata sandi. Database hanya
    // menyimpan hash validator, jadi kebocoran tabel tidak bisa dipakai login.
    private static function buatTokenIngat(int $penggunaId): void
    {
        global $config;
        $hari = (int) ($config['ingat_saya_hari'] ?? 30);
        $selector = bin2hex(random_bytes(12));
        $validator = bin2hex(random_bytes(32));
        Database::execute(
            "INSERT INTO token_ingat (pengguna_id, selector, validator_hash, kedaluwarsa)
             VALUES (?, ?, ?, now() + (? || ' days')::interval)",
            [$penggunaId, $selector, hash('sha256', $validator), (string) $hari]
        );
        self::setCookieIngat($selector . ':' . $validator, time() + $hari * 86400);
    }

    private static function setCookieIngat(string $nilai, int $kedaluwarsa): void
    {
        if (headers_sent()) {
            return;
        }
        setcookie(self::COOKIE_INGAT, $nilai, [
            'expires' => $kedaluwarsa, 'path' => '/', 'secure' => koneksiHttps(),
            'httponly' => true, 'samesite' => 'Lax',
        ]);
    }

    private static function hapusTokenIngatSaatIni(): void
    {
        $nilai = (string) ($_COOKIE[self::COOKIE_INGAT] ?? '');
        if ($nilai !== '' && str_contains($nilai, ':')) {
            [$selector] = explode(':', $nilai, 2);
            try {
                Database::execute('DELETE FROM token_ingat WHERE selector = ?', [$selector]);
            } catch (Throwable $e) {
            }
        }
        unset($_COOKIE[self::COOKIE_INGAT]);
        self::setCookieIngat('', time() - 3600);
    }

    private static function coba_masukDariCookie(): void
    {
        $nilai = (string) ($_COOKIE[self::COOKIE_INGAT] ?? '');
        if ($nilai === '' || !preg_match('/^[a-f0-9]{24}:[a-f0-9]{64}$/', $nilai)) {
            if ($nilai !== '') {
                self::setCookieIngat('', time() - 3600);
            }
            return;
        }
        [$selector, $validator] = explode(':', $nilai, 2);
        try {
            $token = Database::fetch(
                'SELECT t.*, p.id AS pid, p.email, p.role, p.status_akun, p.versi_sesi, p.wajib_ganti_sandi
                   FROM token_ingat t JOIN pengguna p ON p.id = t.pengguna_id
                  WHERE t.selector = ? AND t.kedaluwarsa > now()',
                [$selector]
            );
        } catch (Throwable $e) {
            return;
        }
        if (!$token || !hash_equals($token['validator_hash'], hash('sha256', $validator))
            || $token['status_akun'] === 'nonaktif') {
            if ($token) {
                Database::execute('DELETE FROM token_ingat WHERE id = ?', [$token['id']]);
            }
            self::setCookieIngat('', time() - 3600);
            return;
        }

        // Token sekali pakai: diganti token baru setiap kali dipakai.
        Database::execute('DELETE FROM token_ingat WHERE id = ?', [$token['id']]);
        self::loginkan([
            'id' => $token['pid'], 'email' => $token['email'], 'role' => $token['role'],
            'status_akun' => $token['status_akun'], 'versi_sesi' => $token['versi_sesi'],
            'wajib_ganti_sandi' => $token['wajib_ganti_sandi'],
        ], true);
    }
}
