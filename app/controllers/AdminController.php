<?php
/**
 * Dashboard, verifikasi akun, dan laporan Admin Career Center
 * PIC   : Aqillah (UI/UX, Frontend, dan Integrasi)
 * Status: LOGIKA BACKEND DIISI. Views masih perlu ditimpa dengan desain asli
 *         dari public/admin.html (lihat app/views/PANDUAN-VIEW.md).
 * Catatan: tidak ada login terpisah untuk Admin -- satu form Masuk untuk
 * semua peran (lihat AuthController), peran dikenali otomatis dari akun.
 */

class AdminController extends Controller
{
    /**
     * Ambil id baris tabel admin milik pengguna yang sedang login.
     * Kalau tidak ketemu (sesi basi setelah database di-reset/diisi ulang,
     * atau akun pengguna_id ini memang belum ada di tabel admin), pengguna
     * otomatis dikeluarkan dan diarahkan ke halaman Masuk dengan pesan
     * yang jelas, daripada aplikasi mati dengan layar error putih.
     */
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

    /**
     * View: admin/dashboard. Variabel: $statistik (array angka ringkas),
     * $antreanVerifikasi (5 pendaftar terlama menunggu), $notifikasi (aktivitas terbaru).
     */
    public function dashboard()
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        $this->view('admin/dashboard', [
            'statistik'         => $this->hitungStatistik(),
            'antreanVerifikasi' => array_slice((new Pengguna())->antreanVerifikasi(), 0, 5),
            'notifikasi'        => (new Notifikasi())->milikPengguna(Auth::penggunaSaatIni()['id'], 10),
            'lamaranPerBulan'   => $this->lamaranPerBulan(),
        ]);
    }

    /** 6 bulan terakhir (termasuk bulan berjalan): [['label' => 'Apr', 'jumlah' => 120], ...] untuk grafik Dashboard. */
    private function lamaranPerBulan(int $jumlahBulan = 6): array
    {
        $namaBulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

        // Acuan "bulan sekarang" mengikuti data lamaran PALING BARU di database
        // (bukan tanggal asli server), supaya kalau data terbarunya Sep 2026,
        // grafik otomatis tampil Apr-Sep 2026; kalau terbarunya Agu 2026,
        // grafik tampil Mar-Agu 2026, dst.
        $tanggalTerbaru = Database::fetch('SELECT MAX(tanggal_lamar) AS t FROM lamaran')['t'];
        $acuan = $tanggalTerbaru ? strtotime($tanggalTerbaru) : time();

        $hasil = [];
        for ($i = $jumlahBulan - 1; $i >= 0; $i--) {
            $awal = date('Y-m-01', strtotime("-{$i} month", $acuan));
            $akhir = date('Y-m-t', strtotime("-{$i} month", $acuan));
            $jumlah = Database::fetch(
                'SELECT COUNT(*) AS n FROM lamaran WHERE tanggal_lamar BETWEEN ? AND ?',
                [$awal, $akhir . ' 23:59:59']
            )['n'];
            $hasil[] = ['label' => $namaBulan[(int) date('n', strtotime($awal))], 'jumlah' => (int) $jumlah];
        }
        return $hasil;
    }

    private function hitungStatistik(): array
    {
        return [
            'menunggu_verifikasi' => Database::fetch("SELECT COUNT(*) AS n FROM pengguna WHERE status_akun = 'menunggu'")['n'],
            'total_mahasiswa'     => Database::fetch('SELECT COUNT(*) AS n FROM mahasiswa')['n'],
            'total_perusahaan'    => Database::fetch('SELECT COUNT(*) AS n FROM perusahaan')['n'],
            'lowongan_aktif'      => Database::fetch("SELECT COUNT(*) AS n FROM lowongan WHERE status = 'aktif'")['n'],
            'total_lamaran'       => Database::fetch('SELECT COUNT(*) AS n FROM lamaran')['n'],
            'total_alumni'        => Database::fetch("SELECT COUNT(*) AS n FROM mahasiswa WHERE status_mahasiswa = 'alumni'")['n'],
            'alumni_bekerja'      => Database::fetch("SELECT COUNT(*) AS n FROM mahasiswa WHERE status_mahasiswa = 'alumni' AND status_karier = 'bekerja'")['n'],
        ];
    }

    /**
     * View: admin/persetujuan-akun. Variabel: $antrean (daftar pendaftar
     * menunggu, dengan filter jurusan opsional), $jurusan, $filter.
     */
    public function persetujuan()
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        $jurusanId = (int) $this->query_('jurusan_id') ?: null;
        $this->view('admin/persetujuan-akun', [
            'antrean' => (new Pengguna())->antreanVerifikasi($jurusanId),
            'jurusan' => (new Jurusan())->semuaUrut(),
            'filter'  => ['jurusan_id' => $jurusanId],
        ]);
    }

    /**
     * View: admin/persetujuan-detail. Variabel: $pengguna, $profil (data
     * mahasiswa ATAU perusahaan tergantung role), $dokumen, $riwayat.
     */
    public function detailPendaftar(int $penggunaId)
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        $pengguna = (new Pengguna())->cari($penggunaId);
        if (!$pengguna) {
            http_response_code(404);
            require __DIR__ . '/../views/publik/404.php';
            return;
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

    /** Tiga keputusan dari Halaman Detail Pendaftar: Setujui, Minta Perbaikan, Tolak. */
    public function putuskan(int $penggunaId)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('admin');

        $keputusan = $this->input('keputusan'); // 'disetujui' | 'perbaikan' | 'ditolak'
        $catatan = $this->input('catatan');

        if (!in_array($keputusan, ['disetujui', 'perbaikan', 'ditolak'], true)) {
            $this->flash('bad', 'Keputusan tidak dikenal.');
            $this->redirect('admin/detail-pendaftar/' . $penggunaId);
        }
        if ($keputusan !== 'disetujui' && !validasiWajibIsi($catatan)) {
            $this->flash('bad', 'Catatan wajib diisi untuk keputusan Minta Perbaikan atau Tolak.');
            $this->redirect('admin/detail-pendaftar/' . $penggunaId);
        }

        try {
            (new VerifikasiAkun())->putuskan($penggunaId, $this->adminId(), $keputusan, $catatan ?: null);
        } catch (InvalidArgumentException $e) {
            $this->flash('bad', $e->getMessage());
            $this->redirect('admin/detail-pendaftar/' . $penggunaId);
        }

        $pengguna = (new Pengguna())->cari($penggunaId);
        NotifikasiService::statusAkunBerubah($penggunaId, $pengguna['email'], $keputusan, $catatan ?: null);

        $this->flash('ok', 'Keputusan berhasil disimpan.');
        $this->redirect('admin/persetujuan');
    }

    /**
     * View: admin/kelola-pengguna. Variabel: $mahasiswa, $perusahaan, $jurusan, $filter.
     * (Ditampilkan sebagai dua tab di view: Mahasiswa & Alumni, dan Perusahaan.)
     */
    public function kelolaPengguna()
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        $filter = [
            'jurusan_id'       => $this->query_('jurusan_id'),
            'status_akun'      => $this->query_('status_akun'),
            'status_mahasiswa' => $this->query_('status_mahasiswa'),
            'keyword'          => $this->query_('q'),
        ];

        $this->view('admin/kelola-pengguna', [
            'mahasiswa'  => (new Mahasiswa())->semuaDenganFilter($filter),
            'perusahaan' => (new Perusahaan())->semuaDenganStatus(),
            'jurusan'    => (new Jurusan())->semuaUrut(),
            'filter'     => $filter,
        ]);
    }

    public function nonaktifkanPengguna(int $penggunaId)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('admin');

        $alasan = $this->input('alasan');
        if (!validasiWajibIsi($alasan)) {
            $this->flash('bad', 'Alasan menonaktifkan akun wajib diisi.');
            $this->redirect('admin/kelola-pengguna');
        }

        (new VerifikasiAkun())->putuskan($penggunaId, $this->adminId(), 'nonaktif', $alasan);
        $pengguna = (new Pengguna())->cari($penggunaId);
        NotifikasiService::statusAktivasiBerubah($penggunaId, $pengguna['email'], true, $alasan);

        $this->flash('ok', 'Akun berhasil dinonaktifkan.');
        $this->redirect('admin/kelola-pengguna');
    }

    public function aktifkanPengguna(int $penggunaId)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('admin');

        (new VerifikasiAkun())->putuskan($penggunaId, $this->adminId(), 'aktif', 'Akun diaktifkan kembali oleh Admin.');
        $pengguna = (new Pengguna())->cari($penggunaId);
        NotifikasiService::statusAktivasiBerubah($penggunaId, $pengguna['email'], false, null);

        $this->flash('ok', 'Akun berhasil diaktifkan kembali.');
        $this->redirect('admin/kelola-pengguna');
    }

    /**
     * View: admin/profil-mahasiswa. Dibuka dari Kelola Pengguna dengan
     * mengklik nama mahasiswa. Menampilkan seluruh isi Profil Karier
     * (data diri, pendidikan, skill, pengalaman, sertifikat, portofolio,
     * status karier) plus riwayat lamarannya, semuanya hanya baca.
     *
     * Variabel: $mhs, $pendidikan, $pengalaman, $sertifikat, $portofolio,
     * $skill, $minat, $lamaran, $kelengkapan.
     */
    public function profilMahasiswa(int $mahasiswaId)
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        $mahasiswaModel = new Mahasiswa();
        $mhs = $mahasiswaModel->profilLengkapUntukAdmin($mahasiswaId);
        if (!$mhs) {
            $this->flash('bad', 'Data mahasiswa tidak ditemukan.');
            $this->redirect('admin/kelola-pengguna');
            return;
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
            'kelengkapan' => $mahasiswaModel->kelengkapanProfil(
                $mhs,
                count($profilItem->milikMahasiswa($mahasiswaId, 'pendidikan'))
                    + count($profilItem->milikMahasiswa($mahasiswaId, 'pengalaman')),
                count($skill)
            ),
        ]);
    }

    /**
     * View: admin/monitoring-lowongan. Variabel: $lowongan, $bidang, $jurusan, $filter.
     */
    public function monitoringLowongan()
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        (new Lowongan())->tutupOtomatisJikaLewatBatas();

        $filter = [
            'status'     => $this->query_('status'),
            'bidang_id'  => $this->query_('bidang_id'),
            'jurusan_id' => $this->query_('jurusan_id'),
        ];

        $this->view('admin/monitoring-lowongan', [
            'lowongan' => (new Lowongan())->semuaDenganFilter($filter),
            'bidang'   => (new Bidang())->semuaUrut(),
            'jurusan'  => (new Jurusan())->semuaUrut(),
            'filter'   => $filter,
        ]);
    }

    public function nonaktifkanLowongan(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('admin');

        $alasan = $this->input('alasan');
        if (!validasiWajibIsi($alasan)) {
            $this->flash('bad', 'Alasan menonaktifkan lowongan wajib diisi.');
            $this->redirect('admin/monitoring-lowongan');
        }

        $lowonganModel = new Lowongan();
        $lowongan = $lowonganModel->cari($id);
        $lowonganModel->nonaktifkan($id, $alasan);

        if ($lowongan) {
            $prsh = Database::fetch('SELECT pengguna_id FROM perusahaan WHERE id = ?', [$lowongan['perusahaan_id']]);
            if ($prsh) {
                NotifikasiService::lowonganDinonaktifkanAdmin((int) $prsh['pengguna_id'], $lowongan['posisi'], $alasan);
            }
        }

        $this->flash('ok', 'Lowongan berhasil dinonaktifkan.');
        $this->redirect('admin/monitoring-lowongan');
    }

    /** Laporan PDF: Rekap Lowongan per Perusahaan (unduhan dari Monitoring Lowongan). */
    public function unduhRekapLowongan()
    {
        Auth::wajibAktif();
        Role::wajib('admin');
        PdfService::rekapLowongan((new Lowongan())->semuaDenganFilter([
            'status'     => $this->query_('status'),
            'bidang_id'  => $this->query_('bidang_id'),
            'jurusan_id' => $this->query_('jurusan_id'),
        ]));
    }

    /**
     * View: admin/rekap-lamaran. Variabel: $lamaran, $perusahaan (untuk
     * <select> filter), $jurusan, $prodi, $angkatan, $bulan, $filter.
     */
    public function rekapLamaran()
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        // Filter perusahaan sengaja dihapus: kolom pencarian di halaman ini
        // sudah mencari nama perusahaan, posisi, dan nama pelamar sekaligus,
        // jadi dropdown terpisah hanya menduplikasi fungsi yang sama.
        $filter = [
            'q'          => $this->query_('q'),
            'jurusan_id' => $this->query_('jurusan_id'),
            'prodi_id'   => $this->query_('prodi_id'),
            'angkatan'   => $this->query_('angkatan'),
            'status'     => $this->query_('status'),
            'bulan'      => $this->query_('bulan'),
        ];

        $mahasiswaModel = new Mahasiswa();
        $this->view('admin/rekap-lamaran', [
            'lamaran'  => (new Lamaran())->rekapAdmin($filter),
            'jurusan'  => (new Jurusan())->semuaUrut(),
            // Prodi dan angkatan menyesuaikan jurusan yang sedang dipilih.
            'prodi'    => $mahasiswaModel->prodiDiJurusan($filter['jurusan_id']),
            'angkatan' => $mahasiswaModel->semuaAngkatan($filter['jurusan_id']),
            'bulan'    => (new Lamaran())->bulanTersedia(),
            'filter'   => $filter,
        ]);
    }

    /** Laporan PDF: Rekap Lamaran. */
    public function unduhRekapLamaran()
    {
        Auth::wajibAktif();
        Role::wajib('admin');
        PdfService::rekapLamaran((new Lamaran())->rekapAdmin([
            'q'          => $this->query_('q'),
            'jurusan_id' => $this->query_('jurusan_id'),
            'prodi_id'   => $this->query_('prodi_id'),
            'angkatan'   => $this->query_('angkatan'),
            'status'     => $this->query_('status'),
            'bulan'      => $this->query_('bulan'),
        ]));
    }

    /**
     * View: admin/tracer-karier. Variabel: $alumni (daftar alumni dengan
     * filter), $ringkasanStatus (untuk grafik status karier), $sebaranBidang
     * (untuk panel Sebaran bidang perusahaan), $pembaruanTerbaru (untuk
     * panel Pembaruan terbaru), $jurusan, $filter.
     */
    public function tracerKarier()
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        // Tracer bawaannya menampilkan alumni, karena itu memang maksudnya.
        // Tetapi mahasiswa aktif juga bisa mengisi status karier, jadi Admin
        // bisa memilih "Mahasiswa aktif" atau "Semua" supaya datanya terlihat.
        $status = $this->query_('status_mahasiswa');
        if (!in_array($status, ['alumni', 'aktif', 'semua'], true)) {
            $status = 'alumni';
        }

        $filter = [
            'jurusan_id'       => $this->query_('jurusan_id'),
            'angkatan'         => $this->query_('angkatan'),
            'status_mahasiswa' => $status,
        ];

        $mahasiswaModel = new Mahasiswa();
        $this->view('admin/tracer-karier', [
            'alumni'           => $mahasiswaModel->semuaDenganFilter(array_merge(
                                      $filter,
                                      ['status_mahasiswa' => $status === 'semua' ? null : $status]
                                  )),
            'ringkasanStatus'  => $mahasiswaModel->ringkasanStatusKarier($filter),
            'sebaranBidang'    => $mahasiswaModel->sebaranBidangKerja($filter),
            'pembaruanTerbaru' => $mahasiswaModel->pembaruanTerbaru($filter, 6),
            'jurusan'          => (new Jurusan())->semuaUrut(),
            // Pilihan angkatan hanya yang benar-benar ada di jurusan terpilih,
            // supaya Admin tidak memilih kombinasi yang hasilnya pasti kosong.
            'angkatan'         => $mahasiswaModel->semuaAngkatan($filter['jurusan_id']),
            'filter'           => $filter,
        ]);
    }

    /** Laporan PDF: Tracer Karier. */
    public function unduhTracerKarier()
    {
        Auth::wajibAktif();
        Role::wajib('admin');
        // Laporan mengikuti filter yang sedang dipakai di layar, termasuk
        // pilihan status mahasiswa, supaya isi PDF sama dengan yang dilihat.
        $status = $this->query_('status_mahasiswa');
        if (!in_array($status, ['alumni', 'aktif', 'semua'], true)) {
            $status = 'alumni';
        }
        PdfService::tracerKarier((new Mahasiswa())->semuaDenganFilter([
            'status_mahasiswa' => $status === 'semua' ? null : $status,
            'jurusan_id'       => $this->query_('jurusan_id'),
            'angkatan'         => $this->query_('angkatan'),
        ]));
    }

    /**
     * View: admin/pengaturan. Variabel: $pengaturan (peta kunci => nilai),
     * $kontakJurusan (untuk form nomor WA 7 admin jurusan -- disimpan lewat
     * KirimLokerController::simpanKontak(), bukan di sini), $pengguna
     * (data admin yang sedang login, untuk form ganti kata sandi).
     */
    public function pengaturan()
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        $this->view('admin/pengaturan', [
            'pengaturan'    => (new Pengaturan())->semuaSebagaiPeta(),
            'kontakJurusan' => (new AdminJurusanKontak())->semuaDenganJurusan(),
            'pengguna'      => (new Pengguna())->cari(Auth::penggunaSaatIni()['id']),
        ]);
    }

    /** Simpan template pesan WA/email/alasan penolakan (field bebas kunci=>nilai dari form). */
    public function simpanPengaturan()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('admin');

        $kunciDiizinkan = [
            'template_wa_loker',
            'template_email_subjek_disetujui', 'template_email_subjek_perbaikan', 'template_email_subjek_ditolak',
            'smtp_nama_pengirim', 'smtp_alamat_pengirim',
            'daftar_alasan_penolakan',
        ];
        $pengaturanModel = new Pengaturan();
        foreach ($kunciDiizinkan as $kunci) {
            if (isset($_POST[$kunci])) {
                $pengaturanModel->simpanNilai($kunci, $this->input($kunci), $this->adminId());
            }
        }

        // Supaya setelah redirect admin tetap berada di tab yang barusan
        // diisi (bukan balik ke tab pertama "Kontak admin jurusan").
        if (isset($_POST['daftar_alasan_penolakan'])) {
            $tabAsal = 'alasan';
        } elseif (isset($_POST['template_wa_loker'])) {
            $tabAsal = 'wa';
        } elseif (isset($_POST['smtp_nama_pengirim'])) {
            $tabAsal = 'email';
        } else {
            $tabAsal = 'email';
        }

        $this->flash('ok', 'Pengaturan berhasil disimpan.');
        $this->redirect('admin/pengaturan#' . $tabAsal);
    }

    /** Ganti kata sandi Admin (form terpisah di halaman Pengaturan). */
    public function gantiPassword()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('admin');

        $user = Auth::penggunaSaatIni();
        $penggunaModel = new Pengguna();
        $pengguna = $penggunaModel->cari($user['id']);

        $lama = $this->input('password_lama');
        $baru = $this->input('password_baru');
        $konfirmasi = $this->input('konfirmasi_password');

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

        $this->redirect('admin/pengaturan');
    }
}