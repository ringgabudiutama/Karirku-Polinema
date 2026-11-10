<?php
// ===== BACKEND · CONTROLLER · Perusahaan =============================

class PerusahaanController extends Controller
{
    public const JENIS_PERUSAHAAN = ['Swasta Nasional', 'BUMN / BUMD', 'Multinasional', 'Startup', 'UMKM'];

    // --- Helper ------------------------------------------------------
    private function perusahaanSaya(): array
    {
        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        if (!$prsh) {
            http_response_code(500);
            $judul = 'Data perusahaan tidak ditemukan';
            $pesan = 'Akun ini belum terhubung dengan data perusahaan. Hubungi Admin Career Center.';
            require __DIR__ . '/../views/publik/galat.php';
            exit;
        }
        return $prsh;
    }

    private function wajibPerusahaan(): void
    {
        Auth::wajibAktif();
        Role::wajib('perusahaan');
    }

    // --- Dashboard ---------------------------------------------------
    // [URL] GET /perusahaan/dashboard  →  tampil: views/perusahaan/dashboard.php · peran: perusahaan
    public function dashboard()
    {
        $this->wajibPerusahaan();

        $prsh = $this->perusahaanSaya();
        (new Lowongan())->tutupOtomatisJikaLewatBatas();
        $lowonganModel = new Lowongan();
        $jumlah = $lowonganModel->hitungPerStatusPerusahaan((int) $prsh['id']);
        $lamaranModel = new Lamaran();
        $idPrsh = (int) $prsh['id'];

        $this->view('perusahaan/dashboard', [
            'perusahaan'         => $prsh,
            'lowonganAktif'      => $jumlah['aktif'] ?? 0,
            'lowonganMenunggu'   => ($jumlah['menunggu'] ?? 0) + ($jumlah['revisi'] ?? 0),
            'pelamarBaru'        => $lamaranModel->hitungUntukPerusahaan($idPrsh, ['status' => 'diajukan']),
            'interviewTerjadwal' => $lamaranModel->hitungUntukPerusahaan($idPrsh, ['status' => 'interview']),
            'pelamarDiterima'    => $lamaranModel->hitungUntukPerusahaan($idPrsh, ['status' => 'diterima']),
            'lowonganSaya'       => $lowonganModel->milikPerusahaan($idPrsh, '', 5, 0),
            'pelamarTerbaru'     => $lamaranModel->untukPerusahaan($idPrsh, [], 5, 0),
        ]);
    }

    // --- Lowongan & pelamar ------------------------------------------
    // [URL] GET /perusahaan/lowongan  →  tampil: views/perusahaan/lowongan.php · peran: perusahaan
    public function lowongan()
    {
        $this->wajibPerusahaan();

        $prsh = $this->perusahaanSaya();
        $model = new Lowongan();
        $model->tutupOtomatisJikaLewatBatas();

        $grup = $this->query_('status', 'semua');
        $jumlah = $model->hitungPerStatusPerusahaan((int) $prsh['id']);
        $grupValid = ['semua', 'menunggu', 'revisi', 'aktif', 'ditutup', 'ditolak', 'nonaktif'];
        if (!in_array($grup, $grupValid, true)) {
            $grup = 'semua';
        }
        [$hal, $per, $offset] = $this->halaman($jumlah[$grup] ?? 0);

        $this->view('perusahaan/lowongan', [
            'lowongan' => $model->milikPerusahaan((int) $prsh['id'], $grup, $per, $offset),
            'grup'     => $grup,
            'jumlah'   => $jumlah,
            'paginasi' => $this->infoPaginasi($jumlah[$grup] ?? 0, $hal, $per),
        ]);
    }

    // [URL] GET /perusahaan/pelamar  →  tampil: views/perusahaan/pelamar.php · peran: perusahaan
    public function pelamar()
    {
        $this->wajibPerusahaan();

        $prsh = $this->perusahaanSaya();
        [$dari, $sampai] = Lamaran::rapikanRentang($this->query_('tanggal_dari'), $this->query_('tanggal_sampai'));
        $filter = [
            'keyword'        => $this->query_('q'),
            'lowongan_id'    => $this->query_('lowongan_id'),
            'status'         => $this->query_('status'),
            'jurusan_id'     => $this->query_('jurusan_id'),
            'angkatan'       => $this->query_('angkatan'),
            'tanggal_dari'   => $dari,
            'tanggal_sampai' => $sampai,
        ];

        $model = new Lamaran();
        $total = $model->hitungUntukPerusahaan((int) $prsh['id'], $filter);
        [$hal, $per, $offset] = $this->halaman($total);

        $this->view('perusahaan/pelamar', [
            'pelamar'      => $model->untukPerusahaan((int) $prsh['id'], $filter, $per, $offset),
            'lowonganSaya' => (new Lowongan())->milikPerusahaan((int) $prsh['id']),
            'jurusan'      => (new Jurusan())->semuaUrut(),
            'angkatan'     => $model->angkatanPelamarPerusahaan((int) $prsh['id']),
            'filter'       => $filter,
            'paginasi'     => $this->infoPaginasi($total, $hal, $per),
        ]);
    }

    // --- Profil perusahaan -------------------------------------------
    // [URL] GET /perusahaan/profil  →  tampil: views/perusahaan/profil.php · peran: perusahaan
    public function profil()
    {
        $this->wajibPerusahaan();
        $this->view('perusahaan/profil', ['perusahaan' => $this->perusahaanSaya()]);
    }

    // [URL] POST /perusahaan/simpan-profil  →  simpan lalu kembali ke /perusahaan/profil · peran: perusahaan
    public function simpanProfil()
    {
        $this->wajibPost();
        $this->wajibPerusahaan();

        $prsh = $this->perusahaanSaya();
        $data = [
            'nama_perusahaan'  => $this->input('nama_perusahaan'),
            'bidang_usaha'     => $this->input('bidang_usaha'),
            'jenis_perusahaan' => $this->input('jenis_perusahaan'),
            'alamat'           => $prsh['alamat'],
            'kota'             => $prsh['kota'],
            'website'          => $this->input('website'),
            'nama_pic'         => $this->input('nama_pic'),
            'jabatan_pic'      => $this->input('jabatan_pic'),
            'whatsapp_pic'     => $this->input('whatsapp_pic'),
            'deskripsi'        => $this->input('deskripsi'),
        ];

        // Bug #14: nilai lama yang beda huruf besar/kecil ("Swasta nasional")
        // dicocokkan tanpa peduli huruf, jadi tidak berubah diam-diam.
        $jenisCocok = null;
        foreach (array_merge(self::JENIS_PERUSAHAAN, [$prsh['jenis_perusahaan']]) as $opsi) {
            if (mb_strtolower($opsi) === mb_strtolower($data['jenis_perusahaan'])) {
                $jenisCocok = $opsi;
                break;
            }
        }

        $galat = [];
        if (!validasiWajibIsi($data['nama_perusahaan'])) $galat[] = 'Nama perusahaan wajib diisi.';
        if (!validasiWajibIsi($data['bidang_usaha'])) $galat[] = 'Bidang usaha wajib diisi.';
        if ($jenisCocok === null) $galat[] = 'Pilih jenis perusahaan.';
        if (!validasiWajibIsi($data['nama_pic'])) $galat[] = 'Nama PIC wajib diisi.';
        if (!validasiWajibIsi($data['jabatan_pic'])) $galat[] = 'Jabatan PIC wajib diisi.';
        if (!validasiWhatsapp($data['whatsapp_pic'])) $galat[] = 'Format nomor WhatsApp PIC tidak valid. Contoh: 081234567890.';
        if ($data['website'] !== '' && !filter_var(preg_match('#^https?://#i', $data['website']) ? $data['website'] : 'https://' . $data['website'], FILTER_VALIDATE_URL)) {
            $galat[] = 'Alamat website tidak valid.';
        }
        if ($galat) {
            $this->flash('bad', implode("\n", $galat));
            $this->redirect('perusahaan/profil');
        }
        $data['jenis_perusahaan'] = $jenisCocok;

        $logo = null;
        if (($_FILES['logo']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE) {
            try {
                $logo = UploadService::simpan('logo', 'logo', ['jpg', 'jpeg', 'png'])['nama'];
            } catch (RuntimeException $e) {
                $this->flash('bad', 'Logo: ' . $e->getMessage() . ' Data profil belum disimpan; periksa lalu kirim ulang.');
                $this->redirect('perusahaan/profil');
            }
        }

        Database::transaksi(function () use ($prsh, $data, $logo) {
            (new Perusahaan())->perbaruiProfil((int) $prsh['id'], $data);
            if ($logo) {
                (new Perusahaan())->perbaruiLogo((int) $prsh['id'], $logo);
            }
        });

        $this->flash('ok', 'Profil perusahaan berhasil diperbarui.');
        $this->redirect('perusahaan/profil');
    }

    // --- Pengaturan akun ---------------------------------------------
    // [URL] GET /perusahaan/pengaturan-akun  →  tampil: views/perusahaan/pengaturan.php · peran: perusahaan
    public function pengaturanAkun()
    {
        $this->wajibPerusahaan();
        $this->view('perusahaan/pengaturan', [
            'pengguna'   => (new Pengguna())->cari(Auth::penggunaSaatIni()['id']),
            'perusahaan' => $this->perusahaanSaya(),
        ]);
    }

    // [URL] POST /perusahaan/simpan-pengaturan-akun  →  simpan lalu kembali ke /perusahaan/pengaturan-akun · peran: perusahaan
    public function simpanPengaturanAkun()
    {
        $this->wajibPost();
        $this->wajibPerusahaan();

        $user = Auth::penggunaSaatIni();
        $penggunaModel = new Pengguna();
        $aksi = $this->input('aksi');

        if ($aksi === 'kontak') {
            $emailBaru = $this->input('email');
            $whatsappBaru = $this->input('whatsapp_pic');
            if (!validasiEmail($emailBaru)) {
                $this->flash('bad', 'Format email tidak valid.');
            } elseif ($emailBaru !== $user['email'] && $penggunaModel->emailSudahDipakai($emailBaru)) {
                $this->flash('bad', 'Email sudah dipakai akun lain.');
            } elseif (!validasiWhatsapp($whatsappBaru)) {
                $this->flash('bad', 'Format nomor WhatsApp PIC tidak valid. Contoh: 081234567890.');
            } else {
                $penggunaModel->gantiEmail($user['id'], $emailBaru);
                $_SESSION['user']['email'] = $emailBaru;
                (new Perusahaan())->perbaruiWhatsapp((int) $this->perusahaanSaya()['id'], $whatsappBaru);
                $this->flash('ok', 'Kontak berhasil diperbarui.');
            }
        } elseif ($aksi === 'alamat') {
            $this->simpanAlamat();
        } elseif ($aksi === 'password') {
            $this->prosesGantiSandiSendiri('perusahaan/pengaturan-akun#keamanan');
        } else {
            $this->flash('bad', 'Aksi tidak dikenal.');
        }

        $this->redirect('perusahaan/pengaturan-akun' . ($aksi === 'alamat' ? '#alamat' : ''));
    }

    /** Revisi F: alamat perusahaan (alamat, kota, provinsi, kode pos). */
    private function simpanAlamat(): void
    {
        $d = [
            'alamat'   => $this->input('alamat'),
            'kota'     => $this->input('kota'),
            'provinsi' => $this->input('provinsi'),
            'kode_pos' => $this->input('kode_pos'),
        ];
        $galat = validasiAlamat($d, true);
        if ($galat) {
            $this->flash('bad', implode("\n", $galat));
            return;
        }
        (new Perusahaan())->perbaruiAlamat((int) $this->perusahaanSaya()['id'], $d);
        $this->flash('ok', 'Alamat perusahaan berhasil disimpan.');
    }
}
