<?php
// ===== BACKEND · CONTROLLER · Mahasiswa ==============================

class MahasiswaController extends Controller
{
    // --- Helper ------------------------------------------------------
    private function mahasiswaSaya(): array
    {
        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        if (!$mhs) {
            http_response_code(500);
            die('Data mahasiswa tidak ditemukan untuk akun ini. Hubungi Admin.');
        }
        return $mhs;
    }

    // --- Dashboard ---------------------------------------------------
    public function dashboard()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = $this->mahasiswaSaya();
        $profilItemModel = new ProfilItem();
        $skillModel = new Skill();
        $lamaranModel = new Lamaran();

        $jumlahProfilItem = $profilItemModel->hitungMilik((int) $mhs['id']);
        $jumlahSkill = count($skillModel->milikMahasiswa((int) $mhs['id']));
        $semuaLamaran = $lamaranModel->milikMahasiswa((int) $mhs['id']);

        $this->view('mahasiswa/dashboard', [
            'mahasiswa'          => $mhs,
            'kelengkapan'        => (new Mahasiswa())->kelengkapanProfil($mhs, $jumlahProfilItem, $jumlahSkill),
            'lamaranAktif'       => count(array_filter($semuaLamaran, fn($l) => !in_array($l['status'], ['ditolak', 'dibatalkan'], true))),
            'jumlahDisimpan'     => (new LowonganDisimpan())->hitungMilik((int) $mhs['id']),
            'rekomendasi'        => (new Lowongan())->rekomendasiUntuk((int) $mhs['id']),
            'lamaranTerbaru'     => array_slice($semuaLamaran, 0, 5),
            'perluUpdateKarier'  => NotifikasiService::perluPembaruanKarier($mhs),
        ]);
    }

    // --- Lowongan disimpan -------------------------------------------
    public function disimpan()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = $this->mahasiswaSaya();
        $daftar = (new LowonganDisimpan())->daftarMilik((int) $mhs['id']);
        usort($daftar, fn($a, $b) => strtotime($a['batas_lamaran']) <=> strtotime($b['batas_lamaran']));

        foreach ($daftar as &$l) {
            $l['sudah_disimpan'] = true;
        }
        unset($l);

        $this->view('mahasiswa/disimpan', ['lowongan' => $daftar]);
    }

    // --- Profil karier -----------------------------------------------
    public function profil()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = $this->mahasiswaSaya();
        $profilItemModel = new ProfilItem();
        $skillModel = new Skill();

        $jumlahProfilItem = $profilItemModel->hitungMilik((int) $mhs['id']);
        $skillTerpilih = $skillModel->milikMahasiswa((int) $mhs['id']);

        $this->view('mahasiswa/profil', [
            'mahasiswa'     => $mhs,
            'kelengkapan'   => (new Mahasiswa())->kelengkapanProfil($mhs, $jumlahProfilItem, count($skillTerpilih)),
            'pendidikan'    => $profilItemModel->milikMahasiswa((int) $mhs['id'], 'pendidikan'),
            'pengalaman'    => $profilItemModel->milikMahasiswa((int) $mhs['id'], 'pengalaman'),
            'sertifikat'    => $profilItemModel->milikMahasiswa((int) $mhs['id'], 'sertifikat'),
            'portofolio'    => $profilItemModel->milikMahasiswa((int) $mhs['id'], 'portofolio'),
            'skillTerpilih' => $skillTerpilih,
            'skillSaya'     => $skillTerpilih,
            'semuaSkill'    => $skillModel->semuaUrut(),
            'minatTerpilih' => (new Bidang())->minatMahasiswa((int) $mhs['id']),
            'semuaBidang'   => (new Bidang())->semuaUrut(),
        ]);
    }

    public function simpanProfil()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = $this->mahasiswaSaya();
        $mahasiswaId = (int) $mhs['id'];
        $aksi = $this->input('aksi');

        try {
            switch ($aksi) {
                case 'data_diri':
                    (new Mahasiswa())->perbaruiProfil($mahasiswaId, [
                        'nama'        => $this->input('nama'),
                        'no_whatsapp' => $this->input('no_whatsapp'),
                        'domisili'    => $this->input('domisili'),
                        'tentang'     => $this->input('tentang'),
                        'ipk'         => $this->input('ipk'),
                    ]);
                    $this->flash('ok', 'Data diri berhasil diperbarui.');
                    break;

                case 'foto':
                    $foto = UploadService::simpan('foto', 'foto', ['jpg', 'jpeg', 'png']);
                    (new Mahasiswa())->perbaruiFoto($mahasiswaId, $foto['nama']);
                    $this->flash('ok', 'Foto profil berhasil diperbarui.');
                    break;

                case 'dokumen':
                    $tipeKtm = $mhs['status_mahasiswa'] === 'alumni' ? 'ijazah' : 'ktm';
                    if (!empty($_FILES['file_ktm']['name'])) {
                        $f = UploadService::simpan('file_ktm', $tipeKtm, ['pdf', 'jpg', 'jpeg', 'png']);
                        (new Mahasiswa())->perbaruiKtm($mahasiswaId, $f['nama']);
                        (new DokumenVerifikasi())->tambah(Auth::penggunaSaatIni()['id'], $tipeKtm, $f['nama'], $f['ukuran_kb']);
                    }
                    if (!empty($_FILES['file_surat_pengantar']['name'])) {
                        $f = UploadService::simpan('file_surat_pengantar', 'surat_pengantar', ['pdf']);
                        (new Mahasiswa())->perbaruiSuratPengantar($mahasiswaId, $f['nama']);
                    }
                    $this->flash('ok', 'Dokumen berhasil diperbarui.');
                    break;

                case 'item_tambah':
                    (new ProfilItem())->tambah($mahasiswaId, [
                        'tipe'      => $this->input('tipe'),
                        'judul'     => $this->input('judul'),
                        'instansi'  => $this->input('instansi'),
                        'mulai'     => $this->input('mulai'),
                        'selesai'   => $this->input('selesai'),
                        'deskripsi' => $this->input('deskripsi'),
                        'tautan'    => $this->input('tautan'),
                        'file'      => !empty($_FILES['file']['name'])
                            ? UploadService::simpan('file', 'portofolio', ['pdf', 'jpg', 'jpeg', 'png'])['nama']
                            : null,
                    ]);
                    $this->flash('ok', 'Item berhasil ditambahkan.');
                    break;

                case 'item_hapus':
                    (new ProfilItem())->hapusMilik((int) $this->input('id'), $mahasiswaId);
                    $this->flash('ok', 'Item berhasil dihapus.');
                    break;

                case 'skill':
                    (new Skill())->setUntukMahasiswa($mahasiswaId, $_POST['skill_id'] ?? []);
                    $this->flash('ok', 'Skill berhasil diperbarui.');
                    break;

                case 'skill_baru':
                    $skillModel = new Skill();
                    $ditambah = [];
                    foreach (explode(',', (string) $this->input('skill_nama')) as $nama) {
                        $skillId = $skillModel->cariAtauBuat($nama);
                        if ($skillId !== null) {
                            $skillModel->tambahkanKeMahasiswa($mahasiswaId, $skillId);
                            $ditambah[] = trim($nama);
                        }
                    }
                    if ($ditambah) {
                        $this->flash('ok', 'Skill ditambahkan: ' . implode(', ', $ditambah) . '.');
                    } else {
                        $this->flash('bad', 'Nama skill tidak boleh kosong dan maksimal 100 karakter.');
                    }
                    break;

                case 'skill_hapus':
                    (new Skill())->lepasDariMahasiswa($mahasiswaId, (int) $this->input('skill_id'));
                    $this->flash('ok', 'Skill dihapus dari profil.');
                    break;

                case 'minat':
                    (new Bidang())->setMinatMahasiswa($mahasiswaId, $_POST['bidang_id'] ?? []);
                    $this->flash('ok', 'Bidang minat berhasil diperbarui. Rekomendasi lowongan ikut diperbarui.');
                    break;

                default:
                    $this->flash('bad', 'Aksi tidak dikenal.');
            }
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
        }

        $this->redirect('mahasiswa/profil');
    }

    // --- CV ----------------------------------------------------------
    public function generateCv()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = $this->mahasiswaSaya();
        $profilItemModel = new ProfilItem();

        PdfService::cv(
            $mhs,
            $profilItemModel->milikMahasiswa((int) $mhs['id'], 'pendidikan'),
            $profilItemModel->milikMahasiswa((int) $mhs['id'], 'pengalaman'),
            $profilItemModel->milikMahasiswa((int) $mhs['id'], 'sertifikat'),
            $profilItemModel->milikMahasiswa((int) $mhs['id'], 'portofolio'),
            (new Skill())->milikMahasiswa((int) $mhs['id'])
        );
    }

    public function unggahCv()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = $this->mahasiswaSaya();
        try {
            $f = UploadService::simpan('file_cv', 'cv', ['pdf']);
            (new Mahasiswa())->perbaruiCv((int) $mhs['id'], $f['nama']);
            $this->flash('ok', 'CV berhasil diunggah.');
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
        }
        $this->redirect('mahasiswa/profil');
    }

    // --- Status karier (tracer) --------------------------------------
    public function statusKarier()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs    = $this->mahasiswaSaya();
        $status = $this->input('status_karier');

        $statusDikenal = ['bekerja', 'wirausaha', 'studi lanjut', 'mencari kerja', 'belum bekerja'];
        if (!in_array($status, $statusDikenal, true)) {
            $this->flash('bad', 'Pilih dulu status kariermu sebelum menyimpan.');
            $this->redirect('mahasiswa/profil');
            return;
        }

        $tahap = $this->input('karier_tahap_studi');
        if (!in_array($tahap, ['rencana', 'diterima', 'sedang berjalan'], true)) {
            $tahap = null;
        }

        $data = [
            'status_karier'         => $status,
            'tempat_kerja'          => $this->input('tempat_kerja'),
            'posisi_kerja'          => $this->input('posisi_kerja'),
            'level_jabatan'         => $this->input('level_jabatan'),
            'tanggal_mulai_kerja'   => $this->input('tanggal_mulai_kerja'),
            'karier_fakultas'       => $this->input('karier_fakultas'),
            'karier_bidang_minat'   => $this->input('karier_bidang_minat'),
            'karier_rencana_posisi' => $this->input('karier_rencana_posisi'),
            'karier_tahap_studi'    => $tahap,
            'karier_catatan'        => $this->input('karier_catatan'),
        ];

        $wajib = [
            'bekerja'      => ['tempat_kerja' => 'Nama perusahaan', 'posisi_kerja' => 'Posisi'],
            'wirausaha'    => ['tempat_kerja' => 'Nama usaha', 'posisi_kerja' => 'Peran kamu di usaha'],
            'studi lanjut' => ['tempat_kerja' => 'Nama perguruan tinggi', 'posisi_kerja' => 'Program studi'],
        ][$status] ?? [];

        foreach ($wajib as $field => $label) {
            if (trim((string) $data[$field]) === '') {
                $this->flash('bad', $label . ' wajib diisi untuk status "' . $status . '".');
                $this->redirect('mahasiswa/profil');
                return;
            }
        }

        (new Mahasiswa())->perbaruiStatusKarier((int) $mhs['id'], $data);
        $this->flash('ok', 'Status karier berhasil diperbarui.');
        $this->redirect('mahasiswa/profil');
    }

    // --- Pengaturan akun ---------------------------------------------
    public function pengaturanAkun()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');
        $this->view('mahasiswa/pengaturan', [
            'pengguna'  => (new Pengguna())->cari(Auth::penggunaSaatIni()['id']),
            'mahasiswa' => $this->mahasiswaSaya(),
        ]);
    }

    public function simpanPengaturanAkun()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $user = Auth::penggunaSaatIni();
        $penggunaModel = new Pengguna();
        $aksi = $this->input('aksi');

        if ($aksi === 'kontak') {
            $emailBaru = $this->input('email');
            $noWa = $this->input('no_whatsapp');

            if (!validasiEmail($emailBaru)) {
                $this->flash('bad', 'Format email tidak valid.');
            } elseif ($penggunaModel->emailSudahDipakai($emailBaru) && $emailBaru !== $user['email']) {
                $this->flash('bad', 'Email sudah dipakai akun lain.');
            } elseif (!validasiWhatsapp($noWa)) {
                $this->flash('bad', 'Format nomor WhatsApp tidak valid.');
            } else {
                $penggunaModel->gantiEmail($user['id'], $emailBaru);
                $_SESSION['user']['email'] = $emailBaru;

                $mhs = $this->mahasiswaSaya();
                (new Mahasiswa())->perbaruiProfil((int) $mhs['id'], array_merge($mhs, ['no_whatsapp' => $noWa]));

                $this->flash('ok', 'Kontak akun berhasil diperbarui.');
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

        $this->redirect('mahasiswa/pengaturan-akun');
    }
}
