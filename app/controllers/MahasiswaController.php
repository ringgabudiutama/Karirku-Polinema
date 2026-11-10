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
    // [URL] GET /mahasiswa/dashboard  →  tampil: views/mahasiswa/dashboard.php · peran: mahasiswa
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
    // [URL] GET /mahasiswa/disimpan  →  tampil: views/mahasiswa/disimpan.php · peran: mahasiswa
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
    // [URL] GET /mahasiswa/profil  →  tampil: views/mahasiswa/profil.php · peran: mahasiswa
    public function profil()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = $this->mahasiswaSaya();
        $profilItemModel = new ProfilItem();
        $skillModel = new Skill();

        $jumlahProfilItem = $profilItemModel->hitungMilik((int) $mhs['id']);
        $skillTerpilih = $skillModel->milikMahasiswa((int) $mhs['id']);

        // Auto input status karier dari lamaran yang DITERIMA (bila kolomnya masih kosong).
        $diterima = Database::fetch(
            "SELECT pr.nama_perusahaan, l.posisi, l.jenis_pekerjaan, COALESCE(
                    (SELECT MAX(r.tanggal) FROM riwayat_lamaran r WHERE r.lamaran_id = lm.id AND r.status = 'diterima'),
                    lm.tanggal_lamar)::date AS tanggal_diterima
               FROM lamaran lm JOIN lowongan l ON l.id = lm.lowongan_id JOIN perusahaan pr ON pr.id = l.perusahaan_id
              WHERE lm.mahasiswa_id = ? AND lm.status = 'diterima' ORDER BY tanggal_diterima DESC LIMIT 1",
            [(int) $mhs['id']]
        );

        $this->view('mahasiswa/profil', [
            'mahasiswa'     => $mhs,
            'karierOtomatis' => $diterima,
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

    // [URL] POST /mahasiswa/simpan-profil  →  simpan lalu kembali ke /mahasiswa/profil · peran: mahasiswa
    public function simpanProfil()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = $this->mahasiswaSaya();
        $mahasiswaId = (int) $mhs['id'];
        $aksi = $this->input('aksi');
        // Revisi: setelah menyimpan, kembali ke tab yang sedang dibuka (bukan selalu Data diri).
        $tabKembali = [
            'data_diri' => 'diri', 'foto' => '', 'dokumen' => 'dokumen', 'skill' => 'skill', 'skill_baru' => 'skill',
            'skill_hapus' => 'skill', 'minat' => 'minat',
        ][$aksi] ?? '';
        if ($aksi === 'item_hapus') {
            $itemHapus = (new ProfilItem())->cariMilik((int) $this->input('id'), $mahasiswaId);
            $tabKembali = $itemHapus['tipe'] ?? '';
        }

        try {
            switch ($aksi) {
                case 'data_diri':
                    $d = [
                        'nama'        => $this->input('nama'),
                        'no_whatsapp' => $this->input('no_whatsapp'),
                        'domisili'    => $mhs['domisili'] ?? '',   // kota diubah di Pengaturan Akun > Alamat (revisi F)
                        'tentang'     => $this->input('tentang'),
                        'ipk'         => str_replace(',', '.', $this->input('ipk')),
                    ];
                    $galat = [];
                    if (!validasiWajibIsi($d['nama']) || mb_strlen($d['nama']) > 255) $galat[] = 'Nama lengkap wajib diisi (maksimal 255 karakter).';
                    if (!validasiWhatsapp($d['no_whatsapp'])) $galat[] = 'Format nomor WhatsApp tidak valid. Contoh: 081234567890.';
                    if ($d['ipk'] !== '' && !validasiRentangAngka($d['ipk'], 0, 4)) $galat[] = 'IPK harus angka 0 sampai 4, misalnya 3.45.';
                    if (mb_strlen($d['tentang']) > 2000) $galat[] = 'Tentang saya maksimal 2000 karakter.';
                    if ($galat) {
                        $this->flash('bad', implode("\n", $galat));
                        break;
                    }
                    (new Mahasiswa())->perbaruiProfil($mahasiswaId, $d);
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
                case 'item_ubah':
                    $tipe = $this->input('tipe');
                    if (!in_array($tipe, ['pendidikan', 'pengalaman', 'sertifikat', 'portofolio'], true)) {
                        $this->flash('bad', 'Jenis data tidak dikenal.');
                        break;
                    }
                    $tabKembali = $tipe;
                    if ($tipe === 'portofolio') {
                        // Portofolio: tautan sederhana (GitHub, Behance, dll.)
                        $tautan = $this->input('tautan');
                        if (!validasiWajibIsi($this->input('judul')) || !urlHttpValid($tautan)) {
                            $this->flash('bad', 'Pilih jenis portofolio dan isi tautan lengkap (diawali https://).');
                            break;
                        }
                        (new ProfilItem())->tambah($mahasiswaId, ['tipe' => 'portofolio', 'judul' => $this->input('judul'), 'instansi' => '',
                            'mulai' => '', 'selesai' => '', 'deskripsi' => $this->input('deskripsi'), 'tautan' => $tautan]);
                        $this->flash('ok', 'Portofolio berhasil ditambahkan.');
                        break;
                    }
                    $model = new ProfilItem();
                    $lama = null;
                    if ($aksi === 'item_ubah') {
                        $lama = $model->cariMilik((int) $this->input('id'), $mahasiswaId);
                        if (!$lama || $lama['tipe'] !== $tipe) {
                            $this->flash('bad', 'Data yang akan diubah tidak ditemukan. Muat ulang halaman.');
                            break;
                        }
                    }
                    [$galatItem, $kolom, $detail] = validasiItem($tipe, $_POST, (bool) $lama, $lama);
                    if ($galatItem) {
                        $this->flash('bad', implode("\n", $galatItem));
                        break;
                    }
                    // Berkas: diunggah setelah validasi; berkas lama diganti/dihapus bila diminta.
                    $berkasLama = [];
                    foreach (['file', 'file2'] as $kf) {
                        $adaFieldIni = in_array($kf, array_column(SKEMA_ITEM[$tipe]['field'], 0), true);
                        if (!$adaFieldIni) continue;
                        $nilaiLama = $lama ? nilaiItem($lama, $kf) : '';
                        $baru = null;
                        if (($_FILES[$kf]['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE) {
                            $baru = UploadService::simpan($kf, 'portofolio', ['pdf', 'jpg', 'jpeg', 'png'])['nama'];
                        }
                        if ($baru !== null || !empty($_POST['hapus_' . $kf])) {
                            if ($nilaiLama !== '') $berkasLama[] = $nilaiLama;
                            $nilaiAkhir = $baru;
                        } else {
                            $nilaiAkhir = $nilaiLama !== '' ? $nilaiLama : null;
                        }
                        if ($kf === 'file') $kolom['file'] = $nilaiAkhir;
                        elseif ($nilaiAkhir) $detail['file2'] = $nilaiAkhir;
                        else unset($detail['file2']);
                    }
                    if ($lama) {
                        $model->ubahLengkap((int) $lama['id'], $mahasiswaId, $kolom, $detail);
                    } else {
                        $model->tambahLengkap($mahasiswaId, $tipe, $kolom, $detail);
                    }
                    foreach ($berkasLama as $bl) UploadService::hapus('portofolio', $bl);
                    $this->flash('ok', ucfirst(SKEMA_ITEM[$tipe]['judul_tab']) . ($lama ? ' berhasil diperbarui.' : ' berhasil ditambahkan.'));
                    break;

                case 'item_hapus':
                    (new ProfilItem())->hapusMilik((int) $this->input('id'), $mahasiswaId);
                    $this->flash('ok', 'Item berhasil dihapus.');
                    break;

                case 'skill':
                    (new Skill())->setUntukMahasiswa($mahasiswaId, (array) ($_POST['skill_id'] ?? []));
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
                    (new Bidang())->setMinatMahasiswa($mahasiswaId, (array) ($_POST['bidang_id'] ?? []));
                    $this->flash('ok', 'Bidang minat berhasil diperbarui. Rekomendasi lowongan ikut diperbarui.');
                    break;

                default:
                    $this->flash('bad', 'Aksi tidak dikenal.');
            }
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
        }

        $this->redirect('mahasiswa/profil' . ($tabKembali ? '#' . $tabKembali : ''));
    }

    // --- CV ----------------------------------------------------------
    // [URL] GET /mahasiswa/generate-cv  →  proses · peran: mahasiswa
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

    // [URL] POST /mahasiswa/unggah-cv  →  simpan lalu kembali ke /mahasiswa/profil · peran: mahasiswa
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
    // [URL] POST /mahasiswa/status-karier  →  simpan lalu kembali ke /mahasiswa/profil#karier · peran: mahasiswa
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
            $this->redirect('mahasiswa/profil#karier');
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
                $this->redirect('mahasiswa/profil#karier');
                return;
            }
        }

        (new Mahasiswa())->perbaruiStatusKarier((int) $mhs['id'], $data);
        $this->flash('ok', 'Status karier berhasil diperbarui.');
        $this->redirect('mahasiswa/profil#karier');
    }

    // --- Pengaturan akun ---------------------------------------------
    // [URL] GET /mahasiswa/pengaturan-akun  →  tampil: views/mahasiswa/pengaturan.php · peran: mahasiswa
    public function pengaturanAkun()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');
        $this->view('mahasiswa/pengaturan', [
            'pengguna'  => (new Pengguna())->cari(Auth::penggunaSaatIni()['id']),
            'mahasiswa' => $this->mahasiswaSaya(),
        ]);
    }

    // [URL] POST /mahasiswa/simpan-pengaturan-akun  →  simpan lalu kembali ke /mahasiswa/pengaturan-akun#alamat · peran: mahasiswa
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
            } elseif ($emailBaru !== $user['email'] && $penggunaModel->emailSudahDipakai($emailBaru)) {
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
        } elseif ($aksi === 'alamat') {
            // Revisi F: alamat domisili mahasiswa. Kolom lama `domisili` tetap
            // dipakai sebagai kota/kabupaten supaya data lama tidak dobel.
            $d = [
                'alamat'   => $this->input('alamat'),
                'kota'     => $this->input('kota'),
                'provinsi' => $this->input('provinsi'),
                'kode_pos' => $this->input('kode_pos'),
            ];
            $galat = validasiAlamat($d, false);
            if ($galat) {
                $this->flash('bad', implode("\n", $galat));
            } else {
                (new Mahasiswa())->perbaruiAlamat((int) $this->mahasiswaSaya()['id'], $d);
                $this->flash('ok', 'Alamat berhasil disimpan.');
            }
            $this->redirect('mahasiswa/pengaturan-akun#alamat');
        } elseif ($aksi === 'password') {
            $this->prosesGantiSandiSendiri('mahasiswa/pengaturan-akun#keamanan');
        } else {
            $this->flash('bad', 'Aksi tidak dikenal.');
        }

        $this->redirect('mahasiswa/pengaturan-akun');
    }
}
