<?php
// ===== BACKEND · CONTROLLER · Auth (masuk, daftar, sandi) ============

class AuthController extends Controller
{
    // --- Masuk (login) -----------------------------------------------
    // [URL] GET /masuk  →  tampil: views/publik/masuk.php
    public function formMasuk()
    {
        if (Auth::sudahLogin()) {
            $this->arahkanSesuaiPeran();
            return;
        }
        $this->view('publik/masuk', ['emailSebelumnya' => $_SESSION['_masuk_email'] ?? '']);
        unset($_SESSION['_masuk_email']);
    }

    // [URL] POST /auth/proses-masuk  →  simpan lalu kembali ke /masuk
    public function prosesMasuk()
    {
        $this->wajibPost();

        $email = $this->input('email');
        $password = $this->input('password');
        $_SESSION['_masuk_email'] = $email;

        if ($email === '' || $password === '') {
            $this->flash('bad', 'Email dan kata sandi wajib diisi.');
            $this->redirect('masuk');
        }

        if (loginTerlaluBanyakGagal($email)) {
            $this->flash('bad', 'Terlalu banyak percobaan gagal. Coba lagi dalam 15 menit.');
            $this->redirect('masuk');
        }

        $penggunaModel = new Pengguna();
        $pengguna = $penggunaModel->cariByEmail($email);

        if (!cocokkanPasswordAtauPalsu($password, $pengguna['password_hash'] ?? null)) {
            catatLoginGagal($email);
            $this->flash('bad', 'Email atau kata sandi salah.');
            $this->redirect('masuk');
        }

        if ($pengguna['status_akun'] === 'nonaktif') {
            $this->flash('bad', 'Akun ini telah dinonaktifkan Admin. Hubungi Career Center untuk info lebih lanjut.');
            $this->redirect('masuk');
        }

        resetLoginGagal($email);
        // Revisi B & J: "Ingat saya" menyimpan token acak (bukan kata sandi) di cookie.
        Auth::loginkan($pengguna, isset($_POST['ingat_saya']));
        $penggunaModel->perbaruiTerakhirLogin((int) $pengguna['id']);
        unset($_SESSION['_masuk_email']);

        if ($pengguna['status_akun'] !== 'aktif') {
            $this->redirect('status-akun');
        }
        if (!empty($_SESSION['user']['wajib_ganti_sandi'])) {
            $this->redirect('akun/ganti-sandi-wajib');
        }

        if ($pengguna['role'] === 'mahasiswa') {
            $mhs = (new Mahasiswa())->cariByPenggunaId((int) $pengguna['id']);
            if ($mhs) {
                NotifikasiService::ingatkanLowonganDisimpanHampirTutup((int) $pengguna['id'], (int) $mhs['id']);
            }
        }

        // Revisi B: kembali ke halaman yang tadi ingin dibuka sebelum diminta masuk.
        $tujuan = $_SESSION['tujuan_setelah_login'] ?? '';
        unset($_SESSION['tujuan_setelah_login']);
        $awalanPeran = ['mahasiswa' => ['mahasiswa/', 'lowongan/', 'lamaran/lamaran-saya', 'lamaran/kirim/', 'notifikasi/'],
                        'perusahaan' => ['perusahaan/', 'lowongan/form-pasang', 'lamaran/detail-pelamar/', 'notifikasi/'],
                        'admin' => ['admin/', 'kirim-loker', 'notifikasi/']][$pengguna['role']] ?? [];
        $tujuan = jalurInternalAman($tujuan, '');
        foreach ($awalanPeran as $awalan) {
            if ($tujuan !== '' && str_starts_with($tujuan, $awalan)) {
                $this->redirect($tujuan);
            }
        }

        $this->arahkanSesuaiPeran();
    }

    private function arahkanSesuaiPeran(): void
    {
        $role = Auth::penggunaSaatIni()['role'];
        $tujuan = $role === 'mahasiswa' ? 'mahasiswa/dashboard' : ($role === 'perusahaan' ? 'perusahaan/dashboard' : 'admin/dashboard');
        $this->redirect($tujuan);
    }

    // --- Daftar (registrasi) -----------------------------------------
    // [URL] GET /daftar  →  tampil: views/publik/daftar.php
    public function formDaftar()
    {
        if (Auth::sudahLogin()) {
            $this->arahkanSesuaiPeran();
            return;
        }
        $this->view('publik/daftar', [
            'jurusan'       => (new Jurusan())->semuaUrut(),
            'prodi'         => (new ProgramStudi())->semuaDenganJurusan(),
            'peranTerpilih' => in_array($this->query_('peran'), ['mahasiswa', 'perusahaan'], true) ? $this->query_('peran') : null,
        ]);
    }

    // [URL] POST /auth/proses-daftar  →  simpan lalu kembali ke /daftar?peran=
    public function prosesDaftar()
    {
        $this->wajibPost();
        $peran = $this->input('peran');

        // Batas pendaftaran per IP: 60 per jam (longgar untuk jaringan kampus bersama; menahan pembuatan akun massal).
        if (batasLaju('daftar-ip', ipKlien(), 60, 60)) {
            http_response_code(429);
            $this->flash('bad', 'Terlalu banyak pendaftaran dari jaringan ini. Coba lagi dalam satu jam.');
            $this->redirect('daftar');
        }

        try {
            if ($peran === 'mahasiswa') {
                $this->daftarMahasiswa();
            } elseif ($peran === 'perusahaan') {
                $this->daftarPerusahaan();
            } else {
                throw new RuntimeException('Peran pendaftaran tidak dikenal.');
            }
        } catch (RuntimeException $e) {
            // Kata sandi yang sudah benar tidak perlu diketik ulang: simpan HASH-nya saja di sesi.
            $p = $this->input('password');
            if (validasiPassword($p) && $p === $this->input('konfirmasi_password') && validasiEmail($this->input('email'))) {
                $_SESSION['_daftar_sandi'] = ['hash' => buatHashPassword($p), 'email' => $this->input('email'), 'waktu' => time()];
            }
            $this->flash('bad', $e->getMessage());
            $this->redirect('daftar?peran=' . urlencode($peran));
        }
        unset($_SESSION['_daftar_sandi']);
    }

    private function daftarMahasiswa(): void
    {
        $email = $this->input('email');
        $password = $this->input('password');
        $konfirmasi = $this->input('konfirmasi_password');
        $nama = $this->input('nama');
        $nim = $this->input('nim');
        $noWa = $this->input('no_whatsapp');
        $programStudiId = (int) $this->input('program_studi_id');
        $statusMhs = $this->input('status_mahasiswa');
        $angkatan = (int) $this->input('angkatan');
        $tahunLulus = $this->input('tahun_lulus');

        $this->validasiUmumAkun($email, $password, $konfirmasi);
        if (!validasiWajibIsi($nama) || mb_strlen($nama) > 255) {
            throw new RuntimeException('Nama lengkap wajib diisi.');
        }
        if (!(new ProgramStudi())->cari($programStudiId)) {
            throw new RuntimeException('Pilih jurusan dan program studi.');
        }
        $tahunIni = (int) date('Y');
        if ($angkatan < $tahunIni - 15 || $angkatan > $tahunIni) {
            throw new RuntimeException('Tahun angkatan tidak valid.');
        }
        if (!validasiNim($nim)) {
            throw new RuntimeException('Format NIM tidak valid.');
        }
        if (!validasiWhatsapp($noWa)) {
            throw new RuntimeException('Format nomor WhatsApp tidak valid.');
        }
        if (!in_array($statusMhs, ['aktif', 'alumni'], true)) {
            throw new RuntimeException('Status mahasiswa/alumni wajib dipilih.');
        }
        if ($statusMhs === 'alumni' && $tahunLulus === '') {
            throw new RuntimeException('Tahun lulus wajib diisi untuk alumni.');
        }
        if ((new Pengguna())->emailSudahDipakai($email)) {
            throw new RuntimeException('Email sudah terdaftar. Silakan masuk atau gunakan email lain.');
        }
        if ((new Mahasiswa())->nimSudahDipakai($nim)) {
            throw new RuntimeException('NIM sudah terdaftar sebelumnya.');
        }
        if (!isset($_POST['setuju_syarat'])) {
            throw new RuntimeException('Anda harus menyetujui syarat dan ketentuan.');
        }

        $tipeDokWajib = $statusMhs === 'alumni' ? 'ijazah' : 'ktm';
        try {
            $dok = UploadService::simpan('file_dokumen', $tipeDokWajib, ['pdf', 'jpg', 'jpeg', 'png']);
        } catch (RuntimeException $e) {
            throw new RuntimeException('Dokumen ' . strtoupper($tipeDokWajib) . ': ' . $e->getMessage());
        }

        Database::beginTransaction();
        try {
            $penggunaId = (new Pengguna())->buat($email, $password, 'mahasiswa', $this->hashSandiTersimpan);
            $mahasiswaId = (new Mahasiswa())->buat([
                'pengguna_id'      => $penggunaId,
                'program_studi_id' => $programStudiId,
                'nama'             => $nama,
                'nim'              => $nim,
                'no_whatsapp'      => $noWa,
                'status_mahasiswa' => $statusMhs,
                'angkatan'         => $angkatan,
                'tahun_lulus'      => $statusMhs === 'alumni' ? $tahunLulus : '',
            ]);
            (new DokumenVerifikasi())->tambah($penggunaId, $tipeDokWajib, $dok['nama'], $dok['ukuran_kb']);
            Database::commit();
        } catch (Throwable $e) {
            Database::rollBack();
            throw new RuntimeException('Gagal menyimpan pendaftaran. Silakan coba lagi.');
        }

        $pengguna = (new Pengguna())->cari($penggunaId);
        NotifikasiService::registrasiBerhasil($pengguna, $pengguna['no_pendaftaran'] ?? ('PENG-' . $penggunaId));
        NotifikasiService::pendaftarBaruUntukAdmin($nama, 'mahasiswa');

        Auth::loginkan($pengguna);
        unset($_SESSION['_daftar_sandi']);
        $this->flash('ok', 'Pendaftaran berhasil dikirim. Silakan pantau statusnya di bawah ini.');
        $this->redirect('status-akun');
    }

    private function daftarPerusahaan(): void
    {
        $email = $this->input('email');
        $password = $this->input('password');
        $konfirmasi = $this->input('konfirmasi_password');
        $namaPerusahaan = $this->input('nama_perusahaan');
        $bidangUsaha = $this->input('bidang_usaha');
        $jenisPerusahaan = $this->input('jenis_perusahaan');
        $alamat = $this->input('alamat');
        $kota = $this->input('kota');
        $website = $this->input('website');
        $namaPic = $this->input('nama_pic');
        $jabatanPic = $this->input('jabatan_pic');
        $whatsappPic = $this->input('whatsapp_pic');

        $this->validasiUmumAkun($email, $password, $konfirmasi);
        foreach (['Nama perusahaan' => $namaPerusahaan, 'Bidang usaha' => $bidangUsaha, 'Alamat kantor' => $alamat, 'Kota' => $kota, 'Nama PIC' => $namaPic] as $label => $nilai) {
            if (!validasiWajibIsi($nilai)) {
                throw new RuntimeException($label . ' wajib diisi.');
            }
        }
        if (!in_array($jenisPerusahaan, PerusahaanController::JENIS_PERUSAHAAN, true)) {
            throw new RuntimeException('Pilih jenis perusahaan.');
        }
        if ($jabatanPic === '') {
            $jabatanPic = '-';
        }
        if (!validasiWhatsapp($whatsappPic)) {
            throw new RuntimeException('Format nomor WhatsApp PIC tidak valid.');
        }
        if ((new Pengguna())->emailSudahDipakai($email)) {
            throw new RuntimeException('Email sudah terdaftar. Silakan masuk atau gunakan email lain.');
        }
        if (!isset($_POST['bukan_outsourcing'])) {
            throw new RuntimeException('Anda harus menyatakan bahwa perusahaan ini bukan perusahaan outsourcing.');
        }
        if (!isset($_POST['setuju_syarat'])) {
            throw new RuntimeException('Anda harus menyetujui syarat dan ketentuan.');
        }

        try {
            $nib = UploadService::simpan('file_nib', 'nib', ['pdf', 'jpg', 'jpeg', 'png']);
            $npwp = UploadService::simpan('file_npwp', 'npwp', ['pdf', 'jpg', 'jpeg', 'png']);
            $akta = UploadService::simpan('file_akta', 'akta', ['pdf', 'jpg', 'jpeg', 'png']);
        } catch (RuntimeException $e) {
            throw new RuntimeException('Dokumen legalitas: ' . $e->getMessage());
        }
        $domisili = null;
        $logo = null;
        try {
            if (!empty($_FILES['file_domisili']['name'])) {
                $domisili = UploadService::simpan('file_domisili', 'domisili', ['pdf', 'jpg', 'jpeg', 'png']);
            }
            if (!empty($_FILES['file_logo']['name'])) {
                $logo = UploadService::simpan('file_logo', 'logo', ['jpg', 'jpeg', 'png']);
            }
        } catch (RuntimeException $e) {
            throw new RuntimeException('Dokumen opsional: ' . $e->getMessage());
        }

        Database::beginTransaction();
        try {
            $penggunaId = (new Pengguna())->buat($email, $password, 'perusahaan', $this->hashSandiTersimpan);
            (new Perusahaan())->buat([
                'pengguna_id'      => $penggunaId,
                'nama_perusahaan'  => $namaPerusahaan,
                'bidang_usaha'     => $bidangUsaha,
                'jenis_perusahaan' => $jenisPerusahaan,
                'alamat'           => $alamat,
                'kota'             => $kota,
                'website'          => $website,
                'nama_pic'         => $namaPic,
                'jabatan_pic'      => $jabatanPic,
                'whatsapp_pic'     => $whatsappPic,
            ]);
            $dokModel = new DokumenVerifikasi();
            $dokModel->tambah($penggunaId, 'nib', $nib['nama'], $nib['ukuran_kb']);
            $dokModel->tambah($penggunaId, 'npwp', $npwp['nama'], $npwp['ukuran_kb']);
            $dokModel->tambah($penggunaId, 'akta', $akta['nama'], $akta['ukuran_kb']);
            if ($domisili) $dokModel->tambah($penggunaId, 'domisili', $domisili['nama'], $domisili['ukuran_kb']);
            if ($logo) {
                $dokModel->tambah($penggunaId, 'logo', $logo['nama'], $logo['ukuran_kb']);
                Database::execute('UPDATE perusahaan SET logo = ? WHERE pengguna_id = ?', [$logo['nama'], $penggunaId]);
            }
            Database::commit();
        } catch (Throwable $e) {
            Database::rollBack();
            throw new RuntimeException('Gagal menyimpan pendaftaran. Silakan coba lagi.');
        }

        $pengguna = (new Pengguna())->cari($penggunaId);
        NotifikasiService::registrasiBerhasil($pengguna, $pengguna['no_pendaftaran'] ?? ('PENG-' . $penggunaId));
        NotifikasiService::pendaftarBaruUntukAdmin($namaPerusahaan, 'perusahaan');

        Auth::loginkan($pengguna);
        unset($_SESSION['_daftar_sandi']);
        $this->flash('ok', 'Pendaftaran berhasil dikirim. Silakan pantau statusnya di bawah ini.');
        $this->redirect('status-akun');
    }

    /** Hash kata sandi dari percobaan pendaftaran sebelumnya yang gagal (revisi G). */
    private ?string $hashSandiTersimpan = null;

    /** Data sandi pendaftaran yang tersimpan di sesi (hanya HASH, bukan teks asli), maks. 2 jam. */
    public static function sandiDaftarTersimpan(string $email): bool
    {
        $s = $_SESSION['_daftar_sandi'] ?? null;
        return $s && time() - (int) $s['waktu'] < 7200 && strcasecmp($s['email'], trim($email)) === 0 && $email !== '';
    }

    private function validasiUmumAkun(string $email, string $password, string $konfirmasi): void
    {
        if (!validasiEmail($email)) {
            throw new RuntimeException('Format email tidak valid.');
        }
        if ($password === '' && $konfirmasi === '' && self::sandiDaftarTersimpan($email)) {
            $this->hashSandiTersimpan = $_SESSION['_daftar_sandi']['hash'];
            return;
        }
        if (!validasiPassword($password)) {
            throw new RuntimeException(PESAN_PASSWORD);
        }
        if ($password !== $konfirmasi) {
            throw new RuntimeException('Konfirmasi kata sandi tidak cocok.');
        }
    }

    // --- Status akun & perbaikan berkas ------------------------------
    // [URL] GET /status-akun  →  tampil: views/publik/status-akun.php
    public function statusAkun()
    {
        Auth::wajibLogin();
        $user = Auth::penggunaSaatIni();
        $pengguna = (new Pengguna())->cari($user['id']);
        $profil = $user['role'] === 'mahasiswa'
            ? (new Mahasiswa())->cariByPenggunaId($user['id'])
            : ($user['role'] === 'perusahaan' ? (new Perusahaan())->cariByPenggunaId($user['id']) : null);

        $this->view('publik/status-akun', [
            'pengguna' => $pengguna,
            'profil'   => $profil,
            'riwayat'  => (new VerifikasiAkun())->riwayatUntuk($user['id']),
            'dokumen'  => (new DokumenVerifikasi())->terbaruPerTipe($user['id']),
        ]);
    }

    // [URL] POST /auth/kirim-perbaikan  →  simpan lalu kembali ke /status-akun
    public function kirimPerbaikan()
    {
        $this->wajibPost();
        Auth::wajibLogin();
        $user = Auth::penggunaSaatIni();

        $pengguna = (new Pengguna())->cari($user['id']);
        if ($pengguna['status_akun'] !== 'perbaikan') {
            $this->flash('bad', 'Akun ini tidak sedang dalam status perlu perbaikan.');
            $this->redirect('status-akun');
        }

        $petaTipe = [
            'file_ktm' => 'ktm', 'file_ijazah' => 'ijazah', 'file_nib' => 'nib',
            'file_npwp' => 'npwp', 'file_akta' => 'akta', 'file_domisili' => 'domisili', 'file_logo' => 'logo',
        ];
        $dokModel = new DokumenVerifikasi();
        $adaDiunggah = false;
        foreach ($petaTipe as $field => $tipe) {
            if (!empty($_FILES[$field]['name'])) {
                try {
                    $dok = UploadService::simpan($field, $tipe, $tipe === 'logo' ? ['jpg', 'jpeg', 'png'] : ['pdf', 'jpg', 'jpeg', 'png']);
                    $dokModel->tambah($user['id'], $tipe, $dok['nama'], $dok['ukuran_kb']);
                    $adaDiunggah = true;
                } catch (RuntimeException $e) {
                    $this->flash('bad', $e->getMessage());
                    $this->redirect('status-akun');
                }
            }
        }

        if (!$adaDiunggah) {
            $this->flash('bad', 'Unggah minimal satu dokumen perbaikan.');
            $this->redirect('status-akun');
        }

        (new Pengguna())->ubahStatusAkun($user['id'], 'menunggu');
        Auth::segarkanStatusAkun();
        NotifikasiService::pendaftarBaruUntukAdmin(
            (new Pengguna())->namaTampilan($user['id'], $user['role']),
            $user['role']
        );

        $this->flash('ok', 'Data perbaikan berhasil dikirim. Menunggu verifikasi ulang Admin.');
        $this->redirect('status-akun');
    }

    // --- Lupa & reset kata sandi -------------------------------------
    // [URL] GET /auth/lupa-sandi  →  tampil: views/publik/lupa-sandi.php
    public function lupaSandi()
    {
        $this->view('publik/lupa-sandi', ['tersedia' => (new Pengguna())->fiturResetTersedia()]);
    }

    // [URL] POST /auth/proses-lupa-sandi  →  simpan lalu kembali ke /auth/lupa-sandi
    public function prosesLupaSandi()
    {
        $this->wajibPost();
        $email = $this->input('email');
        $penggunaModel = new Pengguna();

        if (!validasiEmail($email)) {
            $this->flash('bad', 'Format email tidak valid.');
            $this->redirect('auth/lupa-sandi');
        }
        if (!$penggunaModel->fiturResetTersedia()) {
            $this->flash('bad', 'Fitur reset kata sandi belum aktif di database. Hubungi Career Center.');
            $this->redirect('auth/lupa-sandi');
        }
        // Revisi B: jujur bila server belum bisa mengirim email sama sekali.
        // Pesan ini sama untuk semua alamat, jadi tidak membocorkan email terdaftar.
        if (!MailService::siapKirim()) {
            $this->flash('bad', 'Pengiriman email dari sistem belum aktif, sehingga tautan reset tidak bisa dikirim. '
                . 'Hubungi Admin Career Center agar kata sandi Anda diatur ulang secara langsung.');
            $this->redirect('auth/lupa-sandi');
        }

        // Batas permintaan dihitung di DATABASE (bukan sesi): membuang cookie tidak mengulang hitungan.
        // Per alamat email: 3 per 15 menit (mencegah membanjiri satu korban dengan email).
        // Per IP: 30 per 15 menit (longgar, karena satu jaringan kampus bisa dipakai banyak orang).
        if (batasLaju('reset-email', $email, 3, 15) || batasLaju('reset-ip', ipKlien(), 30, 15)) {
            http_response_code(429);
            $this->flash('bad', 'Terlalu banyak permintaan reset. Tunggu 15 menit lalu coba lagi.');
            $this->redirect('auth/lupa-sandi');
        }

        $pengguna = $penggunaModel->cariByEmail($email);
        if ($pengguna && $pengguna['status_akun'] !== 'nonaktif') {
            $token = $penggunaModel->buatTokenReset((int) $pengguna['id']);
            // Tautan lengkap (https://...), karena dibuka dari aplikasi email.
            $tujuan = (string) $pengguna['email'];
            $tautan = urlAbsolut('auth/reset-sandi/' . $token);
            // Email dikirim SETELAH jawaban sampai ke pengunjung. Mengirim di dalam permintaan membuat
            // email terdaftar lebih lambat (± 1 detik) daripada email tak terdaftar, dan selisih itu
            // membocorkan siapa yang punya akun. (Di PHP-FPM jawaban dilepas dulu; di server dev PHP
            // bawaan tetap berurutan.) Solusi lebih besar: antrean kirim lewat cron.
            register_shutdown_function(static function () use ($tujuan, $tautan): void {
                // Lepas kunci sesi lebih dulu: kalau tidak, halaman berikutnya milik pengunjung yang sama
                // ikut menunggu sampai email selesai terkirim.
                if (session_status() === PHP_SESSION_ACTIVE) {
                    session_write_close();
                }
                if (function_exists('fastcgi_finish_request')) {
                    fastcgi_finish_request();
                }
                try {
                    MailService::kirimResetKataSandi($tujuan, $tautan);
                } catch (Throwable $e) {
                    error_log('[KarirKu] Gagal kirim email reset: ' . $e->getMessage());
                }
            });
        }

        $this->flash('ok', 'Kalau email tersebut terdaftar, tautan reset kata sandi sudah kami kirim dan berlaku 60 menit. Cek juga folder Spam.');
        $this->redirect('masuk');
    }

    // [URL] GET /auth/reset-sandi/{token}  →  tampil: views/publik/reset-sandi.php
    public function resetSandi(string $token)
    {
        $penggunaModel = new Pengguna();
        $reset = $penggunaModel->cariResetValid($token);
        if (!$reset) {
            $this->flash('bad', 'Tautan reset kata sandi tidak valid atau sudah kedaluwarsa.');
            $this->redirect('masuk');
        }
        $this->view('publik/reset-sandi', ['token' => $token]);
    }

    // [URL] POST /auth/proses-reset-sandi/{token}  →  simpan lalu kembali ke /masuk
    public function prosesResetSandi(string $token)
    {
        $this->wajibPost();
        $penggunaModel = new Pengguna();
        $reset = $penggunaModel->cariResetValid($token);
        if (!$reset) {
            $this->flash('bad', 'Tautan reset kata sandi tidak valid atau sudah kedaluwarsa.');
            $this->redirect('masuk');
        }

        $password = $this->input('password');
        $konfirmasi = $this->input('konfirmasi_password');
        if (!validasiPassword($password) || $password !== $konfirmasi) {
            $this->flash('bad', validasiPassword($password) ? 'Konfirmasi kata sandi harus sama.' : PESAN_PASSWORD);
            $this->redirect('auth/reset-sandi/' . $token);
        }

        // Revisi J: semua sesi lama & "Ingat saya" dicabut setelah sandi diganti.
        Auth::gantiSandiDanCabutSesi((int) $reset['pengguna_id'], $password, false, false);
        $penggunaModel->tandaiResetDipakai((int) $reset['id']);
        Database::execute('UPDATE reset_kata_sandi SET dipakai_pada = now() WHERE pengguna_id = ? AND dipakai_pada IS NULL',
                          [(int) $reset['pengguna_id']]);

        $this->flash('ok', 'Kata sandi berhasil diganti. Silakan masuk dengan kata sandi baru.');
        $this->redirect('masuk');
    }

    // --- Keluar (logout) ---------------------------------------------
    // [URL] GET /keluar  →  tampil: views/publik/keluar.php
    /** Revisi J: keluar wajib lewat POST + token CSRF (tautan GET bisa dipicu situs lain). */
    public function keluar()
    {
        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'POST') {
            // Dibuka lewat alamat langsung: tampilkan konfirmasi, jangan langsung keluar.
            if (!Auth::sudahLogin()) {
                $this->redirect('masuk');
            }
            $this->view('publik/keluar');
            return;
        }
        csrfVerifikasi();
        Auth::keluar();
        $_SESSION['flash'] = ['tipe' => 'ok', 'pesan' => 'Anda sudah keluar. Sampai jumpa lagi.'];
        $this->redirect('masuk');
    }
}
