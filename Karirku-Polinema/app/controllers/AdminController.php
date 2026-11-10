<?php
// ===== BACKEND · CONTROLLER · Admin (Career Center) ==================

class AdminController extends Controller
{
    // --- Helper ------------------------------------------------------
    private function adminId(): int
    {
        $id = (new Admin())->idDariPenggunaId(Auth::penggunaSaatIni()['id']);
        if ($id === null) {
            Auth::keluar();
            $this->flash('bad', 'Sesi login sudah tidak valid (biasanya karena database baru saja di-reset). Silakan masuk lagi.');
            $this->redirect('masuk');
        }
        return $id;
    }

    private function wajibAdmin(): void
    {
        Auth::wajibAktif();
        Role::wajib('admin');
    }

    // --- Dashboard ---------------------------------------------------
    // [URL] GET /admin/dashboard  →  tampil: views/admin/dashboard.php · peran: admin
    public function dashboard()
    {
        $this->wajibAdmin();

        $this->view('admin/dashboard', [
            'statistik'         => $this->hitungStatistik(),
            'antreanVerifikasi' => (new Pengguna())->antreanVerifikasi(null, '', 5, 0),
            'notifikasi'        => (new Notifikasi())->milikPengguna(Auth::penggunaSaatIni()['id'], 10),
            'lamaranPerBulan'   => $this->lamaranPerBulan(),
        ]);
    }

    private function lamaranPerBulan(int $jumlahBulan = 6): array
    {
        $namaBulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

        $tanggalTerbaru = Database::fetch('SELECT MAX(tanggal_lamar) AS t FROM lamaran')['t'];
        $acuan = $tanggalTerbaru ? strtotime($tanggalTerbaru) : time();

        $hasil = [];
        for ($i = $jumlahBulan - 1; $i >= 0; $i--) {
            $awal = date('Y-m-01', strtotime("first day of -{$i} month", $acuan));
            $akhir = date('Y-m-t', strtotime($awal));
            $jumlah = Database::fetch(
                "SELECT COUNT(*) AS n FROM lamaran WHERE tanggal_lamar >= ?::date AND tanggal_lamar < (?::date + interval '1 day')",
                [$awal, $akhir]
            )['n'];
            $hasil[] = ['label' => $namaBulan[(int) date('n', strtotime($awal))], 'jumlah' => (int) $jumlah];
        }
        return $hasil;
    }

    private function hitungStatistik(): array
    {
        return [
            'menunggu_verifikasi' => Database::fetch("SELECT COUNT(*) AS n FROM pengguna WHERE status_akun = 'menunggu'")['n'],
            'lowongan_menunggu'   => Database::fetch("SELECT COUNT(*) AS n FROM lowongan WHERE status = 'menunggu'")['n'],
            'total_mahasiswa'     => Database::fetch('SELECT COUNT(*) AS n FROM mahasiswa')['n'],
            'total_perusahaan'    => Database::fetch('SELECT COUNT(*) AS n FROM perusahaan')['n'],
            'lowongan_aktif'      => Database::fetch("SELECT COUNT(*) AS n FROM lowongan WHERE status = 'aktif'")['n'],
            'total_lamaran'       => Database::fetch('SELECT COUNT(*) AS n FROM lamaran')['n'],
            'total_alumni'        => Database::fetch("SELECT COUNT(*) AS n FROM mahasiswa WHERE status_mahasiswa = 'alumni'")['n'],
            'alumni_bekerja'      => Database::fetch("SELECT COUNT(*) AS n FROM mahasiswa WHERE status_mahasiswa = 'alumni' AND status_karier = 'bekerja'")['n'],
        ];
    }

    // --- Persetujuan akun --------------------------------------------
    // [URL] GET /admin/persetujuan  →  tampil: views/admin/persetujuan-akun.php · peran: admin
    public function persetujuan()
    {
        $this->wajibAdmin();

        $jurusanId = (int) $this->query_('jurusan_id') ?: null;
        $peran = in_array($this->query_('peran'), ['mahasiswa', 'perusahaan'], true) ? $this->query_('peran') : '';
        $q = $this->query_('q');
        $model = new Pengguna();
        $total = $model->hitungAntreanVerifikasi($jurusanId, $q, $peran);
        [$hal, $per, $offset] = $this->halaman($total);

        $this->view('admin/persetujuan-akun', [
            'antrean'  => $model->antreanVerifikasi($jurusanId, $q, $per, $offset, $peran),
            'jurusan'  => (new Jurusan())->semuaUrut(),
            'filter'   => ['jurusan_id' => $jurusanId, 'q' => $q, 'peran' => $peran],
            'paginasi' => $this->infoPaginasi($total, $hal, $per),
        ]);
    }

    // [URL] GET /admin/detail-pendaftar/{penggunaId}  →  tampil: views/admin/persetujuan-detail.php · peran: admin
    public function detailPendaftar(int $penggunaId)
    {
        $this->wajibAdmin();

        $pengguna = (new Pengguna())->cari($penggunaId);
        if (!$pengguna || $pengguna['role'] === 'admin') {
            $this->halaman404();
        }

        $profil = $pengguna['role'] === 'mahasiswa'
            ? (new Mahasiswa())->cariByPenggunaId($penggunaId)
            : (new Perusahaan())->cariByPenggunaId($penggunaId);

        $this->view('admin/persetujuan-detail', [
            'pengguna' => $pengguna,
            'profil'   => $profil,
            'dokumen'  => (new DokumenVerifikasi())->terbaruPerTipe($penggunaId),
            'riwayat'  => (new VerifikasiAkun())->riwayatUntuk($penggunaId),
        ]);
    }

    // [URL] POST /admin/putuskan/{penggunaId}  →  simpan lalu kembali ke /admin/persetujuan · peran: admin
    public function putuskan(int $penggunaId)
    {
        $this->wajibPost();
        $this->wajibAdmin();

        $keputusan = $this->input('keputusan');
        $catatan = $this->input('catatan');
        $kembali = 'admin/detail-pendaftar/' . $penggunaId;

        if (!in_array($keputusan, ['disetujui', 'perbaikan', 'ditolak'], true)) {
            $this->flash('bad', 'Pilih keputusan: setujui, minta perbaikan, atau tolak.');
            $this->redirect($kembali);
        }
        // Revisi K: alasan wajib untuk minta perbaikan / tolak, minimal cukup jelas.
        if ($keputusan !== 'disetujui' && mb_strlen($catatan) < 10) {
            $this->flash('bad', 'Alasan wajib diisi (minimal 10 karakter) untuk keputusan Minta Perbaikan atau Tolak, supaya pendaftar tahu apa yang harus dilakukan.');
            $this->redirect($kembali);
        }
        if (mb_strlen($catatan) > 500) {
            $this->flash('bad', 'Alasan maksimal 500 karakter.');
            $this->redirect($kembali);
        }

        try {
            (new VerifikasiAkun())->putuskan($penggunaId, $this->adminId(), $keputusan, $catatan ?: null);
        } catch (InvalidArgumentException $e) {
            $this->flash('bad', $e->getMessage());
            $this->redirect($kembali);
        }

        $pengguna = (new Pengguna())->cari($penggunaId);
        NotifikasiService::statusAkunBerubah($penggunaId, $pengguna['email'], $keputusan, $catatan ?: null);

        $label = ['disetujui' => 'disetujui', 'perbaikan' => 'diminta perbaikan', 'ditolak' => 'ditolak'][$keputusan];
        $this->flash(MailService::$terakhir && MailService::$terakhir['status'] === 'gagal' ? 'warn' : 'ok',
            'Akun ' . $pengguna['email'] . ' berhasil ' . $label . '.' . NotifikasiService::keteranganEmail());
        $this->redirect('admin/persetujuan');
    }

    // --- Persetujuan lowongan (revisi M) -----------------------------
    // [URL] GET /admin/persetujuan-lowongan  →  tampil: views/admin/persetujuan-lowongan.php · peran: admin
    public function persetujuanLowongan()
    {
        $this->wajibAdmin();

        $status = in_array($this->query_('status'), ['menunggu', 'revisi', 'ditolak'], true) ? $this->query_('status') : 'menunggu';
        $filter = ['status' => $status, 'q' => $this->query_('q')];
        $model = new Lowongan();
        $total = $model->hitungDenganFilter($filter);
        [$hal, $per, $offset] = $this->halaman($total);

        $this->view('admin/persetujuan-lowongan', [
            'lowongan' => $model->semuaDenganFilter($filter, $per, $offset),
            'filter'   => $filter,
            'jumlah'   => [
                'menunggu' => $model->hitungDenganFilter(['status' => 'menunggu']),
                'revisi'   => $model->hitungDenganFilter(['status' => 'revisi']),
                'ditolak'  => $model->hitungDenganFilter(['status' => 'ditolak']),
            ],
            'paginasi' => $this->infoPaginasi($total, $hal, $per),
        ]);
    }

    // [URL] GET /admin/detail-lowongan/{id}  →  tampil: views/admin/lowongan-detail.php · peran: admin
    public function detailLowongan(int $id)
    {
        $this->wajibAdmin();
        $model = new Lowongan();
        $lowongan = $model->cariDetail($id);
        if (!$lowongan) {
            $this->halaman404();
        }
        $this->view('admin/lowongan-detail', [
            'lowongan'       => $lowongan,
            'jurusanSasaran' => $model->jurusanSasaran($id),
            'riwayat'        => $model->riwayat($id),
            'perusahaan'     => (new Perusahaan())->cariLengkap((int) $lowongan['perusahaan_id']),
        ]);
    }

    // [URL] POST /admin/putuskan-lowongan/{id}  →  simpan lalu kembali ke /admin/persetujuan-lowongan · peran: admin
    public function putuskanLowongan(int $id)
    {
        $this->wajibPost();
        $this->wajibAdmin();

        $keputusan = $this->input('keputusan');
        $alasan = $this->input('alasan');
        $kembali = 'admin/detail-lowongan/' . $id;

        if (!in_array($keputusan, ['disetujui', 'revisi', 'ditolak'], true)) {
            $this->flash('bad', 'Pilih keputusan: setujui, minta revisi, atau tolak final.');
            $this->redirect($kembali);
        }
        if ($keputusan !== 'disetujui' && mb_strlen($alasan) < 10) {
            $this->flash('bad', 'Alasan wajib diisi (minimal 10 karakter) untuk Minta Revisi atau Tolak, supaya perusahaan tahu apa yang harus diperbaiki.');
            $this->redirect($kembali);
        }
        if (mb_strlen($alasan) > 500) {
            $this->flash('bad', 'Alasan maksimal 500 karakter.');
            $this->redirect($kembali);
        }

        $model = new Lowongan();
        try {
            $statusAkhir = $model->putuskan($id, $this->adminId(), (int) Auth::penggunaSaatIni()['id'], $keputusan, $alasan ?: null);
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
            $this->redirect($kembali);
        }

        $l = $model->cariDetail($id);
        $jenisKabar = $keputusan === 'disetujui' ? ($statusAkhir === 'ditutup' ? 'ditutup' : 'disetujui') : $keputusan;
        NotifikasiService::statusLowonganUntukPerusahaan(
            (int) $l['perusahaan_pengguna_id'], $l['email_perusahaan'], $jenisKabar, $l['posisi'], $alasan ?: null
        );
        $infoEmail = NotifikasiService::keteranganEmail();
        $emailGagal = MailService::$terakhir && MailService::$terakhir['status'] === 'gagal';
        if ($statusAkhir === 'aktif') {
            NotifikasiService::lowonganBaruSesuaiMinat($id, $l['posisi'], $l['nama_perusahaan'], (int) $l['bidang_id']);
        }

        $pesan = [
            'aktif'   => 'Lowongan disetujui dan sekarang tayang untuk mahasiswa dan alumni.',
            'ditutup' => 'Lowongan disetujui, tetapi langsung berstatus Ditutup karena batas lamaran sudah lewat atau kuota penuh.',
            'revisi'  => 'Permintaan revisi terkirim ke perusahaan.',
            'ditolak' => 'Lowongan ditolak final.',
        ][$statusAkhir] ?? 'Keputusan tersimpan.';
        $this->flash($emailGagal ? 'warn' : 'ok', $pesan . $infoEmail);
        $this->redirect('admin/persetujuan-lowongan');
    }

    // --- Kelola pengguna ---------------------------------------------
    // [URL] GET /admin/kelola-pengguna  →  tampil: views/admin/kelola-pengguna.php · peran: admin
    public function kelolaPengguna()
    {
        $this->wajibAdmin();

        $tab = $this->query_('tab') === 'perusahaan' ? 'perusahaan' : 'mahasiswa';
        $filter = [
            'jurusan_id'       => $this->query_('jurusan_id'),
            'status_akun'      => $this->query_('status_akun'),
            'status_mahasiswa' => $this->query_('status_mahasiswa'),
            'keyword'          => $this->query_('q'),
        ];

        $mhsModel = new Mahasiswa();
        $prshModel = new Perusahaan();
        $totalMhs = $mhsModel->hitungDenganFilter($filter);
        $totalPrsh = $prshModel->hitungDenganStatus($filter['keyword'], $filter['status_akun']);
        [$hal, $per, $offset] = $this->halaman($tab === 'mahasiswa' ? $totalMhs : $totalPrsh);

        $this->view('admin/kelola-pengguna', [
            'tab'        => $tab,
            'mahasiswa'  => $tab === 'mahasiswa' ? $mhsModel->semuaDenganFilter($filter, $per, $offset) : [],
            'perusahaan' => $tab === 'perusahaan' ? $prshModel->semuaDenganStatus($filter['keyword'], $filter['status_akun'], $per, $offset) : [],
            'totalMhs'   => $totalMhs,
            'totalPrsh'  => $totalPrsh,
            'jurusan'    => (new Jurusan())->semuaUrut(),
            'filter'     => $filter,
            'paginasi'   => $this->infoPaginasi($tab === 'mahasiswa' ? $totalMhs : $totalPrsh, $hal, $per),
        ]);
    }

    private function kembaliKelola(): string
    {
        return jalurInternalAman($this->input('kembali'), 'admin/kelola-pengguna');
    }

    // [URL] POST /admin/nonaktifkan-pengguna/{penggunaId}  →  proses · peran: admin
    public function nonaktifkanPengguna(int $penggunaId)
    {
        $this->wajibPost();
        $this->wajibAdmin();

        $alasan = $this->input('alasan');
        if (mb_strlen($alasan) < 10) {
            $this->flash('bad', 'Alasan menonaktifkan akun wajib diisi (minimal 10 karakter).');
            $this->redirect($this->kembaliKelola());
        }

        try {
            (new VerifikasiAkun())->putuskan($penggunaId, $this->adminId(), 'nonaktif', $alasan);
        } catch (InvalidArgumentException $e) {
            $this->flash('bad', $e->getMessage());
            $this->redirect($this->kembaliKelola());
        }
        $pengguna = (new Pengguna())->cari($penggunaId);
        NotifikasiService::statusAktivasiBerubah($penggunaId, $pengguna['email'], true, $alasan);
        $this->catatAktivitasAdmin('nonaktifkan_akun', $penggunaId, $alasan);

        $this->flash('ok', 'Akun berhasil dinonaktifkan dan semua sesi login-nya sudah dikeluarkan.'
            . ($pengguna['role'] === 'perusahaan' ? ' Lowongan perusahaan ini otomatis disembunyikan dari pelamar.' : '')
            . NotifikasiService::keteranganEmail());
        $this->redirect($this->kembaliKelola());
    }

    // [URL] POST /admin/aktifkan-pengguna/{penggunaId}  →  proses · peran: admin
    public function aktifkanPengguna(int $penggunaId)
    {
        $this->wajibPost();
        $this->wajibAdmin();

        try {
            // Bug #9: hanya akun berstatus nonaktif yang bisa diaktifkan kembali.
            (new VerifikasiAkun())->putuskan($penggunaId, $this->adminId(), 'aktif', 'Akun diaktifkan kembali oleh Admin.');
        } catch (InvalidArgumentException $e) {
            $this->flash('bad', $e->getMessage() . ' Akun yang belum diverifikasi diproses lewat menu Persetujuan Akun.');
            $this->redirect($this->kembaliKelola());
        }
        $pengguna = (new Pengguna())->cari($penggunaId);
        NotifikasiService::statusAktivasiBerubah($penggunaId, $pengguna['email'], false, null);
        $this->catatAktivitasAdmin('aktifkan_akun', $penggunaId, 'Akun diaktifkan kembali.');

        $this->flash('ok', 'Akun berhasil diaktifkan kembali.' . NotifikasiService::keteranganEmail());
        $this->redirect($this->kembaliKelola());
    }

    // [URL] POST /admin/reset-sandi-pengguna/{penggunaId}  →  proses · peran: admin
    /**
     * Revisi L: reset kata sandi pengguna oleh Admin.
     *  - 'tautan'   : kirim tautan reset ke email pengguna (disarankan);
     *  - 'sementara': Admin menetapkan sandi sementara. Wajib konfirmasi sandi
     *                 Admin, sandi di-hash, pengguna WAJIB menggantinya saat masuk,
     *                 semua sesi lama dikeluarkan. Sandi tidak pernah dicatat.
     */
    public function resetSandiPengguna(int $penggunaId)
    {
        $this->wajibPost();
        $this->wajibAdmin();
        $kembali = $this->kembaliKelola();

        $target = (new Pengguna())->cari($penggunaId);
        if (!$target || $target['role'] === 'admin') {
            $this->flash('bad', 'Reset kata sandi hanya untuk akun mahasiswa/alumni dan perusahaan.');
            $this->redirect($kembali);
        }

        $admin = (new Pengguna())->cari((int) Auth::penggunaSaatIni()['id']);
        if (!cocokkanPassword($this->input('password_admin'), $admin['password_hash'])) {
            $this->flash('bad', 'Kata sandi Admin tidak sesuai. Reset dibatalkan.');
            $this->redirect($kembali);
        }

        $cara = $this->input('cara');
        if ($cara === 'tautan') {
            if (!MailService::siapKirim()) {
                $this->flash('bad', 'Email sistem belum aktif (SMTP belum diisi), jadi tautan reset tidak bisa dikirim. Gunakan opsi kata sandi sementara.');
                $this->redirect($kembali);
            }
            $token = (new Pengguna())->buatTokenReset($penggunaId);
            $terkirim = MailService::kirimResetKataSandi($target['email'], urlAbsolut('auth/reset-sandi/' . $token));
            $this->catatAktivitasAdmin('kirim_tautan_reset', $penggunaId, 'Tautan reset kata sandi dikirim ke ' . $target['email'] . ($terkirim ? '' : ' (GAGAL terkirim)'));
            $this->flash($terkirim ? 'ok' : 'bad', $terkirim
                ? 'Tautan reset kata sandi terkirim ke ' . $target['email'] . ' (berlaku 60 menit).'
                : 'Tautan reset GAGAL dikirim: ' . (MailService::$terakhir['keterangan'] ?? 'kesalahan SMTP') . '. Coba lagi atau gunakan kata sandi sementara.');
            $this->redirect($kembali);
        }

        if ($cara !== 'sementara') {
            $this->flash('bad', 'Pilih cara reset kata sandi.');
            $this->redirect($kembali);
        }
        $sementara = $this->input('password_sementara');
        if (!validasiPassword($sementara) || !preg_match('/[A-Za-z]/', $sementara) || !preg_match('/\d/', $sementara)) {
            $this->flash('bad', 'Kata sandi sementara minimal 8 karakter, berisi huruf serta angka, dan tidak terlalu umum.');
            $this->redirect($kembali);
        }

        Auth::gantiSandiDanCabutSesi($penggunaId, $sementara, true, false);
        $this->catatAktivitasAdmin('atur_sandi_sementara', $penggunaId, 'Kata sandi sementara diatur untuk ' . $target['email'] . '. Pengguna wajib menggantinya saat masuk.');
        (new Notifikasi())->buat($penggunaId, 'keamanan', 'Kata sandi diatur ulang Admin', 'Ganti kata sandi sementara Anda dengan kata sandi baru.', null);
        MailService::kirimSandiDiresetAdmin($target['email']);

        $this->flash('ok', 'Kata sandi sementara untuk ' . $target['email'] . ' sudah disimpan. Sampaikan kepada pemilik akun melalui jalur resmi; '
            . 'ia wajib menggantinya saat masuk. Semua sesi lamanya sudah dikeluarkan.');
        $this->redirect($kembali);
    }

    // [URL] GET /admin/profil-mahasiswa/{mahasiswaId}  →  tampil: views/admin/profil-mahasiswa.php · peran: admin
    public function profilMahasiswa(int $mahasiswaId)
    {
        $this->wajibAdmin();

        $mahasiswaModel = new Mahasiswa();
        $mhs = $mahasiswaModel->profilLengkapUntukAdmin($mahasiswaId);
        if (!$mhs) {
            $this->halaman404();
        }

        $profilItem = new ProfilItem();
        $skill      = (new Skill())->milikMahasiswa($mahasiswaId);

        $this->view('admin/profil-mahasiswa', [
            'mhs'         => $mhs,
            'pendidikan'  => $profilItem->milikMahasiswa($mahasiswaId, 'pendidikan'),
            'pengalaman'  => $profilItem->milikMahasiswa($mahasiswaId, 'pengalaman'),
            'sertifikat'  => $profilItem->milikMahasiswa($mahasiswaId, 'sertifikat'),
            'portofolio'  => $profilItem->milikMahasiswa($mahasiswaId, 'portofolio'),
            'skill'       => $skill,
            'minat'       => (new Bidang())->minatMahasiswa($mahasiswaId),
            'lamaran'     => (new Lamaran())->rekapAdmin(['mahasiswa_id' => $mahasiswaId]),
            'riwayatAkun' => (new VerifikasiAkun())->riwayatUntuk((int) $mhs['pengguna_id']),
            'kelengkapan' => $mahasiswaModel->kelengkapanProfil(
                $mhs,
                count($profilItem->milikMahasiswa($mahasiswaId, 'pendidikan'))
                    + count($profilItem->milikMahasiswa($mahasiswaId, 'pengalaman')),
                count($skill)
            ),
        ]);
    }

    // [URL] GET /admin/profil-perusahaan/{perusahaanId}  →  tampil: views/admin/profil-perusahaan.php · peran: admin
    public function profilPerusahaan(int $perusahaanId)
    {
        $this->wajibAdmin();
        $prsh = (new Perusahaan())->cariLengkap($perusahaanId);
        if (!$prsh) {
            $this->halaman404();
        }
        $this->view('admin/profil-perusahaan', [
            'prsh'        => $prsh,
            'lowongan'    => (new Lowongan())->milikPerusahaan($perusahaanId),
            'dokumen'     => (new DokumenVerifikasi())->terbaruPerTipe((int) $prsh['pengguna_id']),
            'riwayatAkun' => (new VerifikasiAkun())->riwayatUntuk((int) $prsh['pengguna_id']),
        ]);
    }

    // --- Monitoring lowongan -----------------------------------------
    private function filterMonitoring(): array
    {
        return [
            'status'     => $this->query_('status'),
            'bidang_id'  => $this->query_('bidang_id'),
            'jurusan_id' => $this->query_('jurusan_id'),
            'q'          => $this->query_('q'),
        ];
    }

    // [URL] GET /admin/monitoring-lowongan  →  tampil: views/admin/monitoring-lowongan.php · peran: admin
    public function monitoringLowongan()
    {
        $this->wajibAdmin();

        (new Lowongan())->tutupOtomatisJikaLewatBatas();
        $filter = $this->filterMonitoring();
        $model = new Lowongan();
        $total = $model->hitungDenganFilter($filter);
        [$hal, $per, $offset] = $this->halaman($total);

        $this->view('admin/monitoring-lowongan', [
            'lowongan' => $model->semuaDenganFilter($filter, $per, $offset),
            'jumlahStatus' => $model->hitungPerStatusAdmin($filter),
            'bidang'   => (new Bidang())->semuaUrut(),
            'jurusan'  => (new Jurusan())->semuaUrut(),
            'filter'   => $filter,
            'paginasi' => $this->infoPaginasi($total, $hal, $per),
        ]);
    }

    // [URL] POST /admin/nonaktifkan-lowongan/{id}  →  proses · peran: admin
    public function nonaktifkanLowongan(int $id)
    {
        $this->wajibPost();
        $this->wajibAdmin();
        $kembali = jalurInternalAman($this->input('kembali'), 'admin/monitoring-lowongan');

        $alasan = $this->input('alasan');
        if (mb_strlen($alasan) < 10) {
            $this->flash('bad', 'Alasan menonaktifkan lowongan wajib diisi (minimal 10 karakter).');
            $this->redirect($kembali);
        }

        $model = new Lowongan();
        if (!$model->nonaktifkan($id, $alasan, (int) Auth::penggunaSaatIni()['id'])) {
            $this->flash('bad', 'Lowongan ini tidak sedang tayang, jadi tidak bisa dinonaktifkan.');
            $this->redirect($kembali);
        }
        $l = $model->cariDetail($id);
        NotifikasiService::lowonganDinonaktifkanAdmin((int) $l['perusahaan_pengguna_id'], $l['posisi'], $alasan, $l['email_perusahaan']);

        $this->flash('ok', 'Lowongan berhasil dinonaktifkan.' . NotifikasiService::keteranganEmail());
        $this->redirect($kembali);
    }

    // [URL] GET /admin/unduh-rekap-lowongan  →  proses · peran: admin
    public function unduhRekapLowongan()
    {
        $this->wajibAdmin();
        $filter = $this->filterMonitoring();
        PdfService::rekapLowongan((new Lowongan())->semuaDenganFilter($filter), $this->labelFilter($filter, 'lowongan'));
    }

    // --- Rekap lamaran (revisi I) ------------------------------------
    private function filterRekap(): array
    {
        [$dari, $sampai] = Lamaran::rapikanRentang($this->query_('tanggal_dari'), $this->query_('tanggal_sampai'));
        return [
            'q'              => $this->query_('q'),
            'jurusan_id'     => $this->query_('jurusan_id'),
            'prodi_id'       => $this->query_('prodi_id'),
            'angkatan'       => $this->query_('angkatan'),
            'status'         => $this->query_('status'),
            'tanggal_dari'   => $dari,
            'tanggal_sampai' => $sampai,
        ];
    }

    /** Daftar filter aktif dalam bahasa manusia (untuk layar & PDF). */
    private function labelFilter(array $f, string $jenis = 'lamaran'): array
    {
        $label = [];
        if (!empty($f['q'])) $label[] = 'Kata kunci: "' . $f['q'] . '"';
        if (!empty($f['jurusan_id']) && ($j = (new Jurusan())->cari((int) $f['jurusan_id']))) $label[] = 'Jurusan: ' . $j['nama'];
        if (!empty($f['prodi_id']) && ($p = (new ProgramStudi())->cari((int) $f['prodi_id']))) $label[] = 'Prodi: ' . $p['jenjang'] . ' ' . $p['nama'];
        if (!empty($f['angkatan'])) $label[] = 'Angkatan: ' . (int) $f['angkatan'];
        if (!empty($f['status'])) $label[] = 'Status: ' . ($jenis === 'lamaran' ? labelStatusLamaran($f['status'])[0] : labelStatusLowongan($f['status'])[0]);
        if (!empty($f['bidang_id']) && ($b = (new Bidang())->cari((int) $f['bidang_id']))) $label[] = 'Bidang: ' . $b['nama'];
        if (!empty($f['tanggal_dari']) || !empty($f['tanggal_sampai'])) {
            $label[] = 'Tanggal lamar: ' . (!empty($f['tanggal_dari']) ? tanggalIndo($f['tanggal_dari']) : 'awal')
                . ' s.d. ' . (!empty($f['tanggal_sampai']) ? tanggalIndo($f['tanggal_sampai']) : 'sekarang');
        }
        return $label;
    }

    // [URL] GET /admin/rekap-lamaran  →  tampil: views/admin/rekap-lamaran.php · peran: admin
    public function rekapLamaran()
    {
        $this->wajibAdmin();

        $filter = $this->filterRekap();
        $lamaranModel = new Lamaran();
        $ringkasan = $lamaranModel->ringkasanRekap($filter);
        [$hal, $per, $offset] = $this->halaman($ringkasan['total'] ?? 0);

        $mahasiswaModel = new Mahasiswa();
        $this->view('admin/rekap-lamaran', [
            'lamaran'       => $lamaranModel->rekapAdmin($filter, $per, $offset),
            'ringkasan'     => $ringkasan,
            'perPerusahaan' => $lamaranModel->rekapPerPerusahaan($filter),
            'jurusan'       => (new Jurusan())->semuaUrut(),
            'prodi'         => $mahasiswaModel->prodiDiJurusan($filter['jurusan_id']),
            'angkatan'      => $mahasiswaModel->semuaAngkatan($filter['jurusan_id']),
            'filter'        => $filter,
            'labelFilter'   => $this->labelFilter($filter),
            'paginasi'      => $this->infoPaginasi($ringkasan['total'] ?? 0, $hal, $per),
        ]);
    }

    // [URL] GET /admin/unduh-rekap-lamaran  →  proses · peran: admin
    public function unduhRekapLamaran()
    {
        $this->wajibAdmin();
        $filter = $this->filterRekap();
        $model = new Lamaran();
        PdfService::rekapLamaran($model->rekapAdmin($filter), $this->labelFilter($filter), $model->ringkasanRekap($filter), $model->rekapPerPerusahaan($filter));
    }

    // --- Tracer karier -----------------------------------------------
    private function filterTracer(): array
    {
        $status = $this->query_('status_mahasiswa');
        if (!in_array($status, ['alumni', 'aktif', 'semua'], true)) {
            $status = 'alumni';
        }
        return [
            'jurusan_id'       => $this->query_('jurusan_id'),
            'angkatan'         => $this->query_('angkatan'),
            'status_mahasiswa' => $status,
            'status_karier'    => $this->query_('status_karier'),
            'keyword'          => $this->query_('q'),
        ];
    }

    // [URL] GET /admin/tracer-karier  →  tampil: views/admin/tracer-karier.php · peran: admin
    public function tracerKarier()
    {
        $this->wajibAdmin();

        $filter = $this->filterTracer();
        $filterQuery = array_merge($filter, ['status_mahasiswa' => $filter['status_mahasiswa'] === 'semua' ? null : $filter['status_mahasiswa']]);
        $mahasiswaModel = new Mahasiswa();
        $total = $mahasiswaModel->hitungDenganFilter($filterQuery);
        [$hal, $per, $offset] = $this->halaman($total);

        $this->view('admin/tracer-karier', [
            'alumni'           => $mahasiswaModel->semuaDenganFilter($filterQuery, $per, $offset),
            'ringkasanStatus'  => $mahasiswaModel->ringkasanStatusKarier($filter),
            'sebaranBidang'    => $mahasiswaModel->sebaranBidangKerja($filter),
            'levelJabatan'     => $mahasiswaModel->sebaranLevelJabatan($filter),
            'pembaruanTerbaru' => $mahasiswaModel->pembaruanTerbaru($filter, 6),
            'jurusan'          => (new Jurusan())->semuaUrut(),
            'angkatan'         => $mahasiswaModel->semuaAngkatan($filter['jurusan_id']),
            'filter'           => $filter,
            'paginasi'         => $this->infoPaginasi($total, $hal, $per),
        ]);
    }

    // [URL] GET /admin/unduh-tracer-karier  →  proses · peran: admin
    public function unduhTracerKarier()
    {
        $this->wajibAdmin();
        $filter = $this->filterTracer();
        PdfService::tracerKarier((new Mahasiswa())->semuaDenganFilter(
            array_merge($filter, ['status_mahasiswa' => $filter['status_mahasiswa'] === 'semua' ? null : $filter['status_mahasiswa']])
        ));
    }

    // --- Pengaturan --------------------------------------------------
    // [URL] GET /admin/pengaturan  →  tampil: views/admin/pengaturan.php · peran: admin
    public function pengaturan()
    {
        $this->wajibAdmin();

        $statusLog = in_array($this->query_('status_email'), ['terkirim', 'gagal', 'log'], true) ? $this->query_('status_email') : '';
        $totalLog = (int) Database::fetch('SELECT COUNT(*) AS n FROM log_email' . ($statusLog ? ' WHERE status = ?' : ''), $statusLog ? [$statusLog] : [])['n'];
        [$hal, $per, $offset] = $this->halaman($totalLog);
        $logEmail = Database::fetchAll(
            'SELECT id, tujuan, subjek, jenis, status, keterangan, percobaan, dibuat_pada, diperbarui_pada, (isi_html IS NOT NULL) AS bisa_ulang
               FROM log_email' . ($statusLog ? ' WHERE status = ?' : '') . ' ORDER BY dibuat_pada DESC, id DESC LIMIT ? OFFSET ?',
            array_merge($statusLog ? [$statusLog] : [], [$per, $offset])
        );

        $this->view('admin/pengaturan', [
            'pengaturan'    => (new Pengaturan())->semuaSebagaiPeta(),
            'kontakJurusan' => (new AdminJurusanKontak())->semuaDenganJurusan(),
            'pengguna'      => (new Pengguna())->cari(Auth::penggunaSaatIni()['id']),
            'statusEmail'   => MailService::statusKonfigurasi(),
            'logEmail'      => $logEmail,
            'statusLog'     => $statusLog,
            'paginasiLog'   => $this->infoPaginasi($totalLog, $hal, $per),
            'aktivitas'     => Database::fetchAll(
                'SELECT la.*, a.nama AS nama_admin, p.email AS email_target
                   FROM log_aktivitas_admin la LEFT JOIN admin a ON a.id = la.admin_id
                   LEFT JOIN pengguna p ON p.id = la.target_pengguna_id
                  ORDER BY la.tanggal DESC, la.id DESC LIMIT 10'
            ),
        ]);
    }

    // [URL] POST /admin/simpan-pengaturan  →  simpan lalu kembali ke /admin/pengaturan#email · peran: admin
    public function simpanPengaturan()
    {
        $this->wajibPost();
        $this->wajibAdmin();

        $kunciDiizinkan = [
            'template_wa_loker',
            'template_email_subjek_disetujui', 'template_email_subjek_perbaikan', 'template_email_subjek_ditolak',
            'smtp_nama_pengirim', 'smtp_alamat_pengirim',
            'daftar_alasan_penolakan', 'daftar_alasan_lowongan',
        ];
        if (isset($_POST['smtp_alamat_pengirim']) && $this->input('smtp_alamat_pengirim') !== '' && !validasiEmail($this->input('smtp_alamat_pengirim'))) {
            $this->flash('bad', 'Alamat email pengirim tidak valid.');
            $this->redirect('admin/pengaturan#email');
        }
        $pengaturanModel = new Pengaturan();
        foreach ($kunciDiizinkan as $kunci) {
            if (isset($_POST[$kunci])) {
                $pengaturanModel->simpanNilai($kunci, mb_substr($this->input($kunci), 0, 4000), $this->adminId());
            }
        }

        $tabAsal = isset($_POST['daftar_alasan_penolakan']) || isset($_POST['daftar_alasan_lowongan']) ? 'alasan'
            : (isset($_POST['template_wa_loker']) ? 'wa' : 'email');

        $this->flash('ok', 'Pengaturan berhasil disimpan.');
        $this->redirect('admin/pengaturan#' . $tabAsal);
    }

    // [URL] POST /admin/kirim-email-uji  →  simpan lalu kembali ke /admin/pengaturan#email · peran: admin
    public function kirimEmailUji()
    {
        $this->wajibPost();
        $this->wajibAdmin();
        $ke = $this->input('email_uji') ?: Auth::penggunaSaatIni()['email'];
        if (!validasiEmail($ke)) {
            $this->flash('bad', 'Alamat email uji tidak valid.');
            $this->redirect('admin/pengaturan#email');
        }
        $ok = MailService::kirimUji($ke);
        $t = MailService::$terakhir;
        $this->flash($ok ? 'ok' : 'bad', $ok
            ? 'Email uji diterima server SMTP untuk ' . $ke . '. Cek kotak masuk (dan folder Spam).'
            : ($t['status'] === 'log'
                ? 'Email uji TIDAK dikirim karena SMTP belum dikonfigurasi. Isi pengaturan SMTP di app/config/config.php (lihat README).'
                : 'Email uji GAGAL dikirim: ' . $t['keterangan']));
        $this->redirect('admin/pengaturan#email');
    }

    // [URL] POST /admin/kirim-ulang-email/{logId}  →  simpan lalu kembali ke /admin/pengaturan? · peran: admin
    public function kirimUlangEmail(int $logId)
    {
        $this->wajibPost();
        $this->wajibAdmin();
        $log = Database::fetch('SELECT * FROM log_email WHERE id = ?', [$logId]);
        if (!$log || $log['isi_html'] === null) {
            $this->flash('bad', 'Email ini tidak bisa dikirim ulang (isinya rahasia, misalnya tautan reset sandi). Minta pengguna mengulang permintaannya.');
        } elseif ($log['status'] === 'terkirim') {
            $this->flash('ok', 'Email ini sudah terkirim sebelumnya.');
        } else {
            $ok = MailService::kirimUlang($logId);
            $this->flash($ok ? 'ok' : 'bad', $ok ? 'Email berhasil dikirim ulang ke ' . $log['tujuan'] . '.'
                : 'Kirim ulang belum berhasil: ' . (MailService::$terakhir['keterangan'] ?? '-'));
        }
        $this->redirect('admin/pengaturan?' . http_build_query(['status_email' => $this->input('status_email')]) . '#email');
    }

    // [URL] POST /admin/ganti-password  →  proses · peran: admin
    public function gantiPassword()
    {
        $this->wajibPost();
        $this->wajibAdmin();

        $this->prosesGantiSandiSendiri('admin/pengaturan#akun');
    }

    // --- Profil admin (revisi tahap 2: admin bisa mengganti profilnya) ---
    // [URL] GET /admin/profil  →  tampil: views/admin/profil.php · peran: admin
    public function profil()
    {
        $this->wajibAdmin();
        $uid = (int) Auth::penggunaSaatIni()['id'];
        $admin = (new Admin())->cariByPenggunaId($uid);
        if (!$admin) {
            // Akun admin lama tanpa baris profil: buat otomatis supaya halaman tetap bisa dibuka.
            Database::execute('INSERT INTO admin (pengguna_id, nama, jabatan) VALUES (?, ?, ?) ON CONFLICT (pengguna_id) DO NOTHING',
                              [$uid, 'Admin Career Center', 'Admin Career Center']);
            $admin = (new Admin())->cariByPenggunaId($uid);
        }
        $this->view('admin/profil', [
            'admin'     => $admin,
            'pengguna'  => (new Pengguna())->cari($uid),
            'aktivitas' => Database::fetchAll(
                'SELECT la.*, p.email AS email_target FROM log_aktivitas_admin la
                   LEFT JOIN pengguna p ON p.id = la.target_pengguna_id
                  WHERE la.admin_id = ? ORDER BY la.tanggal DESC, la.id DESC LIMIT 8',
                [(int) $admin['id']]
            ),
            'statistik' => Database::fetch(
                "SELECT (SELECT COUNT(*) FROM log_aktivitas_admin WHERE admin_id = ?) AS aksi,
                        (SELECT COUNT(*) FROM pengguna WHERE status_akun = 'menunggu') AS akun_menunggu,
                        (SELECT COUNT(*) FROM lowongan WHERE status = 'menunggu') AS lowongan_menunggu",
                [(int) $admin['id']]
            ),
        ]);
    }

    // [URL] POST /admin/simpan-profil  →  simpan lalu kembali ke /admin/profil · peran: admin
    public function simpanProfil()
    {
        $this->wajibPost();
        $this->wajibAdmin();
        $uid = (int) Auth::penggunaSaatIni()['id'];
        $admin = (new Admin())->cariByPenggunaId($uid);
        $pengguna = (new Pengguna())->cari($uid);
        if (!$admin || !$pengguna) {
            $this->flash('bad', 'Data admin tidak ditemukan. Muat ulang halaman lalu coba lagi.');
            $this->redirect('admin/profil');
        }

        // Ganti / hapus foto saja (dari tombol kamera, sudah dikonfirmasi di browser)
        if ($this->input('aksi') === 'foto') {
            if (($_FILES['foto']['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) {
                $this->flash('bad', 'Pilih foto terlebih dahulu.');
                $this->redirect('admin/profil');
            }
            try {
                $foto = UploadService::simpan('foto', 'foto', ['jpg', 'jpeg', 'png'])['nama'];
            } catch (RuntimeException $e) {
                $this->flash('bad', 'Foto: ' . $e->getMessage());
                $this->redirect('admin/profil');
            }
            Database::execute('UPDATE admin SET foto = ? WHERE id = ?', [$foto, (int) $admin['id']]);
            UploadService::hapus('foto', $admin['foto'] ?? null);
            $this->flash('ok', 'Foto profil berhasil diganti.');
            $this->redirect('admin/profil');
        }
        if ($this->input('aksi') === 'hapus_foto') {
            Database::execute('UPDATE admin SET foto = NULL WHERE id = ?', [(int) $admin['id']]);
            UploadService::hapus('foto', $admin['foto'] ?? null);
            $this->flash('ok', 'Foto profil dihapus. Avatar bawaan dipakai kembali.');
            $this->redirect('admin/profil');
        }

        $nama = trim($this->input('nama'));
        $jabatan = trim($this->input('jabatan'));
        $wa = preg_replace('/[\s\-]/', '', $this->input('no_whatsapp'));
        $email = mb_strtolower(trim($this->input('email')));
        $galat = [];
        if (mb_strlen($nama) < 3 || mb_strlen($nama) > 255) $galat[] = 'Nama lengkap wajib diisi (3–255 karakter).';
        if (mb_strlen($jabatan) > 150) $galat[] = 'Jabatan maksimal 150 karakter.';
        if ($wa !== '' && !validasiWhatsapp($wa)) $galat[] = 'Format nomor WhatsApp tidak valid. Contoh: 081234567890.';
        if (!validasiEmail($email)) $galat[] = 'Format email tidak valid.';
        $gantiEmail = $email !== mb_strtolower($pengguna['email']);
        if ($gantiEmail) {
            $lain = (new Pengguna())->cariByEmail($email);
            if ($lain && (int) $lain['id'] !== $uid) $galat[] = 'Email ' . $email . ' sudah dipakai akun lain.';
            if (!cocokkanPassword($this->input('password_konfirmasi'), $pengguna['password_hash'])) {
                $galat[] = 'Untuk mengganti email login, masukkan kata sandi saat ini dengan benar.';
            }
        }
        if ($galat) {
            $this->flash('bad', implode("\n", $galat));
            $this->redirect('admin/profil');
        }

        Database::transaksi(function () use ($admin, $uid, $nama, $jabatan, $wa, $email, $gantiEmail) {
            Database::execute('UPDATE admin SET nama = ?, jabatan = ?, no_whatsapp = ? WHERE id = ?',
                              [$nama, $jabatan !== '' ? $jabatan : null, $wa !== '' ? $wa : null, (int) $admin['id']]);
            if ($gantiEmail) {
                Database::execute('UPDATE pengguna SET email = ? WHERE id = ?', [$email, $uid]);
                $_SESSION['user']['email'] = $email;
            }
        });
        $this->catatAktivitasAdmin('ubah_profil_admin', $uid, 'Memperbarui profil admin' . ($gantiEmail ? ' (email login diganti)' : '') . '.');
        $this->flash('ok', 'Profil admin berhasil disimpan.' . ($gantiEmail ? ' Mulai sekarang masuk memakai email ' . $email . '.' : ''));
        $this->redirect('admin/profil');
    }
}
