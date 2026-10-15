<?php
// ===== BACKEND · CONTROLLER · Auth (masuk, daftar, sandi) ============

class AuthController extends Controller
{
    // --- Masuk (login) -----------------------------------------------
    public function formMasuk()
    {
        if (Auth::sudahLogin()) {
            $this->arahkanSesuaiPeran();
            return;
        }
        $this->view('publik/masuk', ['emailSebelumnya' => $_SESSION['_masuk_email'] ?? '']);
        unset($_SESSION['_masuk_email']);
    }

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

        if (!$pengguna || !cocokkanPassword($password, $pengguna['password_hash'])) {
            catatLoginGagal($email);
            $this->flash('bad', 'Email atau kata sandi salah.');
            $this->redirect('masuk');
        }

        if ($pengguna['status_akun'] === 'nonaktif') {
            $this->flash('bad', 'Akun ini telah dinonaktifkan Admin. Hubungi Career Center untuk info lebih lanjut.');
            $this->redirect('masuk');
        }

        resetLoginGagal($email);
        Auth::loginkan($pengguna);
        $penggunaModel->perbaruiTerakhirLogin((int) $pengguna['id']);
        unset($_SESSION['_masuk_email']);

        if ($pengguna['status_akun'] !== 'aktif') {
            $this->redirect('status-akun');
        }

        if ($pengguna['role'] === 'mahasiswa') {
            $mhs = (new Mahasiswa())->cariByPenggunaId((int) $pengguna['id']);
            if ($mhs) {
                NotifikasiService::ingatkanLowonganDisimpanHampirTutup((int) $pengguna['id'], (int) $mhs['id']);
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
    public function formDaftar()
    {
        if (Auth::sudahLogin()) {
            $this->arahkanSesuaiPeran();
            return;
        }
        $this->view('publik/daftar', [
            'jurusan'       => (new Jurusan())->semuaUrut(),
            'prodi'         => (new ProgramStudi())->semuaDenganJurusan(),
            'peranTerpilih' => $this->query_('peran') ?: null,
        ]);
    }

    public function prosesDaftar()
    {
        $this->wajibPost();
        $peran = $this->input('peran');

        try {
            if ($peran === 'mahasiswa') {
                $this->daftarMahasiswa();
            } elseif ($peran === 'perusahaan') {
                $this->daftarPerusahaan();
            } else {
                throw new RuntimeException('Peran pendaftaran tidak dikenal.');
            }
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
            $this->redirect('daftar?peran=' . e($peran));
        }
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
            $penggunaId = (new Pengguna())->buat($email, $password, 'mahasiswa');
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
            $penggunaId = (new Pengguna())->buat($email, $password, 'perusahaan');
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
        $this->flash('ok', 'Pendaftaran berhasil dikirim. Silakan pantau statusnya di bawah ini.');
        $this->redirect('status-akun');
    }

    private function validasiUmumAkun(string $email, string $password, string $konfirmasi): void
    {
        if (!validasiEmail($email)) {
            throw new RuntimeException('Format email tidak valid.');
        }
        if (!validasiPassword($password)) {
            throw new RuntimeException('Kata sandi minimal 8 karakter.');
        }
        if ($password !== $konfirmasi) {
            throw new RuntimeException('Konfirmasi kata sandi tidak cocok.');
        }
    }

    // --- Status akun & perbaikan berkas ------------------------------
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
    public function lupaSandi()
    {
        $this->view('publik/lupa-sandi', ['tersedia' => (new Pengguna())->fiturResetTersedia()]);
    }

    public function prosesLupaSandi()
    {
        $this->wajibPost();
        $email = $this->input('email');
        $penggunaModel = new Pengguna();

        if (!$penggunaModel->fiturResetTersedia()) {
            $this->flash('bad', 'Fitur reset kata sandi belum aktif. Jalankan database/03-tambahan-reset-password.sql terlebih dahulu.');
            $this->redirect('lupa-sandi');
        }

        $pengguna = $penggunaModel->cariByEmail($email);
        if ($pengguna) {
            $token = $penggunaModel->buatTokenReset((int) $pengguna['id']);
            $tautan = url('auth/reset-sandi/' . $token);
            MailService::kirimResetKataSandi($pengguna['email'], $tautan);
        }

        $this->flash('ok', 'Kalau email tersebut terdaftar, tautan reset kata sandi sudah kami kirim. Cek juga folder Spam.');
        $this->redirect('masuk');
    }

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
            $this->flash('bad', 'Kata sandi minimal 8 karakter dan konfirmasi harus cocok.');
            $this->redirect('auth/reset-sandi/' . $token);
        }

        $penggunaModel->gantiPassword((int) $reset['pengguna_id'], $password);
        $penggunaModel->tandaiResetDipakai((int) $reset['id']);

        $this->flash('ok', 'Kata sandi berhasil diganti. Silakan masuk dengan kata sandi baru.');
        $this->redirect('masuk');
    }

    // --- Keluar (logout) ---------------------------------------------
    public function keluar()
    {
        Auth::keluar();
        $this->redirect('beranda');
    }
}
