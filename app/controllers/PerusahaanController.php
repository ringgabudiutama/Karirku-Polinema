<?php
/**
 * Dashboard dan profil perusahaan
 * PIC   : Atha Rasya Farras (Modul Operator dan Career Center)
 * Status: LOGIKA BACKEND DIISI. Views masih perlu ditimpa dengan desain asli
 *         dari public/perusahaan.html (lihat app/views/PANDUAN-VIEW.md).
 */

class PerusahaanController extends Controller
{
    private function perusahaanSaya(): array
    {
        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        if (!$prsh) {
            http_response_code(500);
            die('Data perusahaan tidak ditemukan untuk akun ini. Hubungi Admin.');
        }
        return $prsh;
    }

    /**
     * View: perusahaan/dashboard. Variabel: $perusahaan, $lowonganAktif,
     * $pelamarBaru (jumlah status diajukan), $interviewTerjadwal, $pelamarDiterima,
     * $lowonganSaya (untuk grafik kuota per lowongan), $pelamarTerbaru (5 terakhir).
     */
    public function dashboard()
    {
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $prsh = $this->perusahaanSaya();
        (new Lowongan())->tutupOtomatisJikaLewatBatas();
        $lowonganSaya = (new Lowongan())->milikPerusahaan((int) $prsh['id']);
        $semuaLamaran = (new Lamaran())->untukPerusahaan((int) $prsh['id']);

        $this->view('perusahaan/dashboard', [
            'perusahaan'         => $prsh,
            'lowonganAktif'      => count(array_filter($lowonganSaya, fn($l) => $l['status'] === 'aktif')),
            'pelamarBaru'        => count(array_filter($semuaLamaran, fn($l) => $l['status'] === 'diajukan')),
            'interviewTerjadwal' => count(array_filter($semuaLamaran, fn($l) => $l['status'] === 'interview')),
            'pelamarDiterima'    => count(array_filter($semuaLamaran, fn($l) => $l['status'] === 'diterima')),
            'lowonganSaya'       => $lowonganSaya,
            'pelamarTerbaru'     => array_slice($semuaLamaran, 0, 5),
        ]);
    }

    /** View: perusahaan/lowongan. Variabel: $lowongan (semua milik perusahaan, dengan jumlah pelamar). */
    public function lowongan()
    {
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $prsh = $this->perusahaanSaya();
        (new Lowongan())->tutupOtomatisJikaLewatBatas();
        $this->view('perusahaan/lowongan', ['lowongan' => (new Lowongan())->milikPerusahaan((int) $prsh['id'])]);
    }

    /**
     * View: perusahaan/pelamar. Variabel: $pelamar, $lowonganSaya (untuk
     * <select> filter), $filter (nilai filter aktif).
     */
    public function pelamar()
    {
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $prsh = $this->perusahaanSaya();
        $filter = [
            'keyword'     => $this->query_('q'),
            'lowongan_id' => $this->query_('lowongan_id'),
            'status'      => $this->query_('status'),
            'jurusan_id'  => $this->query_('jurusan_id'),
        ];

        $this->view('perusahaan/pelamar', [
            'pelamar'      => (new Lamaran())->untukPerusahaan((int) $prsh['id'], $filter),
            'lowonganSaya' => (new Lowongan())->milikPerusahaan((int) $prsh['id']),
            'jurusan'      => (new Jurusan())->semuaUrut(),
            'filter'       => $filter,
        ]);
    }

    /** View: perusahaan/profil. Variabel: $perusahaan. */
    public function profil()
    {
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $this->view('perusahaan/profil', ['perusahaan' => $this->perusahaanSaya()]);
    }

    public function simpanProfil()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $prsh = $this->perusahaanSaya();

        // Nomor WhatsApp PIC wajib ada di database (kolomnya NOT NULL) dan
        // dipakai Career Center maupun pelamar untuk menghubungi perusahaan.
        $whatsapp = trim((string) $this->input('whatsapp_pic'));
        if ($whatsapp === '') {
            $this->flash('bad', 'Nomor WhatsApp PIC wajib diisi.');
            $this->redirect('perusahaan/profil');
        }
        if (!validasiWhatsapp($whatsapp)) {
            $this->flash('bad', 'Format nomor WhatsApp PIC tidak valid. Contoh: 081234567890.');
            $this->redirect('perusahaan/profil');
        }

        (new Perusahaan())->perbaruiProfil((int) $prsh['id'], [
            'nama_perusahaan'  => $this->input('nama_perusahaan'),
            'bidang_usaha'     => $this->input('bidang_usaha'),
            'jenis_perusahaan' => $this->input('jenis_perusahaan'),
            'alamat'           => $this->input('alamat'),
            'kota'             => $this->input('kota'),
            'website'          => $this->input('website'),
            'nama_pic'         => $this->input('nama_pic'),
            'jabatan_pic'      => $this->input('jabatan_pic'),
            'whatsapp_pic'     => $whatsapp,
            'deskripsi'        => $this->input('deskripsi'),
        ]);

        if (!empty($_FILES['logo']['name'])) {
            try {
                $logo = UploadService::simpan('logo', 'logo', ['jpg', 'jpeg', 'png']);
                (new Perusahaan())->perbaruiLogo((int) $prsh['id'], $logo['nama']);
            } catch (RuntimeException $e) {
                $this->flash('bad', 'Logo: ' . $e->getMessage());
                $this->redirect('perusahaan/profil');
            }
        }

        $this->flash('ok', 'Profil perusahaan berhasil diperbarui.');
        $this->redirect('perusahaan/profil');
    }

    /**
     * Pengaturan Akun (ubah email/kata sandi). Logika sama persis dengan
     * MahasiswaController::pengaturanAkun(), sengaja digandakan (bukan lewat
     * trait) supaya URL 'perusahaan/pengaturan-akun' mengikuti pola routing
     * controller/method biasa tanpa pengecualian di Router.
     * View: perusahaan/pengaturan. Variabel: $pengguna.
     */
    public function pengaturanAkun()
    {
        Auth::wajibAktif();
        Role::wajib('perusahaan');
        $this->view('perusahaan/pengaturan', [
            'pengguna'   => (new Pengguna())->cari(Auth::penggunaSaatIni()['id']),
            'perusahaan' => $this->perusahaanSaya(),
        ]);
    }

    public function simpanPengaturanAkun()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $user = Auth::penggunaSaatIni();
        $penggunaModel = new Pengguna();
        $aksi = $this->input('aksi');

        if ($aksi === 'kontak') {
            $emailBaru = $this->input('email');
            $whatsappBaru = $this->input('whatsapp_pic');
            if (!validasiEmail($emailBaru)) {
                $this->flash('bad', 'Format email tidak valid.');
            } elseif ($penggunaModel->emailSudahDipakai($emailBaru) && $emailBaru !== $user['email']) {
                $this->flash('bad', 'Email sudah dipakai akun lain.');
            } elseif (!$whatsappBaru) {
                $this->flash('bad', 'Nomor WhatsApp PIC wajib diisi.');
            } else {
                $penggunaModel->gantiEmail($user['id'], $emailBaru);
                $_SESSION['user']['email'] = $emailBaru;
                $prsh = $this->perusahaanSaya();
                (new Perusahaan())->perbaruiWhatsapp((int) $prsh['id'], $whatsappBaru);
                $this->flash('ok', 'Kontak berhasil diperbarui.');
            }
        } elseif ($aksi === 'password') {
            $lama = $this->input('password_lama');
            $baru = $this->input('password_baru');
            $konfirmasi = $this->input('konfirmasi_password');
            $pengguna = $penggunaModel->cari($user['id']);

            if (!cocokkanPassword($lama, $pengguna['password_hash'])) {
                $this->flash('bad', 'Kata sandi lama tidak sesuai.');
            } elseif (!validasiPassword($baru)) {
                $this->flash('bad', 'Kata sandi baru minimal 8 karakter.');
            } elseif ($baru !== $konfirmasi) {
                $this->flash('bad', 'Konfirmasi kata sandi baru tidak cocok.');
            } else {
                $penggunaModel->gantiPassword($user['id'], $baru);
                $this->flash('ok', 'Kata sandi berhasil diperbarui.');
            }
        }

        $this->redirect('perusahaan/pengaturan-akun');
    }
}
