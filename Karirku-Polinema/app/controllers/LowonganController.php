<?php
// ===== BACKEND · CONTROLLER · Lowongan ===============================

class LowonganController extends Controller
{
    private const JENIS_PEKERJAAN = ['full_time', 'part_time', 'kontrak', 'magang', 'freelance'];
    private const SISTEM_KERJA = ['wfo', 'hybrid', 'wfh'];
    private const TIPE_PAMFLET = ['jpg', 'jpeg', 'png', 'pdf'];

    // --- Mahasiswa: cari, detail, simpan -----------------------------
    // [URL] GET /lowongan/daftar  →  tampil: views/mahasiswa/lowongan.php · peran: mahasiswa
    public function daftar()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        (new Lowongan())->tutupOtomatisJikaLewatBatas();

        $filter = [
            'keyword'         => $this->query_('q'),
            'jurusan_id'      => $this->query_('jurusan_id'),
            'bidang_id'       => $this->query_('bidang_id'),
            'lokasi'          => $this->query_('lokasi'),
            'jenis_pekerjaan' => $this->query_('jenis_pekerjaan'),
            'urutan'          => $this->query_('urutan'),
        ];

        $lowonganModel = new Lowongan();
        $total = $lowonganModel->hitungCari($filter);
        [$hal, $per, $offset] = $this->halaman($total);
        $daftar = $lowonganModel->cariDenganFilter($filter, $per, $offset);

        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $disimpanModel = new LowonganDisimpan();
        foreach ($daftar as &$l) {
            $l['sudah_disimpan'] = $mhs ? $disimpanModel->sudahDisimpan((int) $mhs['id'], (int) $l['id']) : false;
        }
        unset($l);

        $this->view('mahasiswa/lowongan', [
            'lowongan'     => $daftar,
            'total'        => $total,
            'halaman'      => $hal,
            'totalHalaman' => max(1, (int) ceil($total / $per)),
            'paginasi'     => $this->infoPaginasi($total, $hal, $per),
            'filter'       => $filter,
            'jurusan'      => (new Jurusan())->semuaUrut(),
            'bidang'       => (new Bidang())->semuaUrut(),
            'lokasiOpsi'   => $lowonganModel->lokasiUnik(),
        ]);
    }

    // [URL] GET /lowongan/detail/{id}  →  tampil: views/mahasiswa/lowongan-detail.php · peran: mahasiswa
    public function detail(int $id)
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        (new Lowongan())->tutupOtomatisJikaLewatBatas();
        $lowongan = (new Lowongan())->cariDetailTayang($id);
        if (!$lowongan) {
            $this->halaman404();
        }

        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $mahasiswaId = (int) $mhs['id'];

        $this->view('mahasiswa/lowongan-detail', [
            'lowongan'       => $lowongan,
            'jurusanSasaran' => (new Lowongan())->jurusanSasaran($id),
            'sudahDisimpan'  => (new LowonganDisimpan())->sudahDisimpan($mahasiswaId, $id),
            'sudahMelamar'   => (new Lamaran())->sudahMelamar($mahasiswaId, $id),
            'profilLengkap'  => !empty($mhs['file_cv']) && !empty($mhs['file_ktm']),
            'bisaMelamar'    => Lowongan::bisaMenerimaLamaran($lowongan),
            'alasanTutup'    => Lowongan::alasanTidakMenerima($lowongan),
        ]);
    }

    // [URL] POST /lowongan/simpan/{id}  →  proses · peran: mahasiswa
    public function simpan(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $disimpanModel = new LowonganDisimpan();
        $mahasiswaId = (int) $mhs['id'];

        if ($disimpanModel->sudahDisimpan($mahasiswaId, $id)) {
            $disimpanModel->batalBookmark($mahasiswaId, $id);
            $this->flash('ok', 'Lowongan dibatalkan dari daftar simpan.');
        } elseif ((new Lowongan())->cariDetailTayang($id)) {
            $disimpanModel->simpanBookmark($mahasiswaId, $id);
            $this->flash('ok', 'Lowongan berhasil disimpan.');
        } else {
            $this->flash('bad', 'Lowongan ini tidak tersedia.');
        }

        // Bug #16: tujuan kembali hanya boleh path internal (bukan situs lain).
        $this->redirect(jalurInternalAman($this->input('kembali'), 'lowongan/detail/' . $id));
    }

    // --- Perusahaan: pasang & kelola lowongan ------------------------
    private function lowonganMilikSaya(int $id): array
    {
        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $lowongan = (new Lowongan())->cari($id);
        if (!$lowongan || !$prsh || (int) $lowongan['perusahaan_id'] !== (int) $prsh['id']) {
            $this->halaman403('Lowongan ini milik perusahaan lain, jadi tidak bisa Anda buka atau ubah.');
        }
        return [$lowongan, $prsh];
    }

    // [URL] GET /lowongan/form-pasang/{id}  →  tampil: views/perusahaan/lowongan-form.php · peran: perusahaan
    public function formPasang(int $id = 0)
    {
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $lowongan = null;
        $jurusanTerpilih = [];
        $riwayat = [];

        if ($id) {
            [$lowongan] = $this->lowonganMilikSaya($id);
            if (in_array($lowongan['status'], ['ditolak', 'nonaktif'], true)) {
                $this->flash('bad', $lowongan['status'] === 'ditolak'
                    ? 'Lowongan yang ditolak final tidak bisa diubah atau diajukan ulang. Buat lowongan baru bila diperlukan.'
                    : 'Lowongan yang dinonaktifkan Admin tidak bisa diubah. Hubungi Career Center.');
                $this->redirect('perusahaan/lowongan');
            }
            $jurusanTerpilih = array_column((new Lowongan())->jurusanSasaran($id), 'id');
            $riwayat = (new Lowongan())->riwayat($id);
        }

        // Auto input untuk lowongan BARU: dari lowongan lama (?salin=ID) atau dari profil perusahaan.
        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']) ?: [];
        $bawaan = [];
        $daftarSalin = [];
        if (!$id) {
            $daftarSalin = Database::fetchAll(
                'SELECT id, posisi, status, dibuat_pada FROM lowongan WHERE perusahaan_id = ? ORDER BY dibuat_pada DESC, id DESC LIMIT 30',
                [(int) ($prsh['id'] ?? 0)]
            );
            $salinId = (int) $this->query_('salin', '0');
            $sumber = $salinId ? Database::fetch('SELECT * FROM lowongan WHERE id = ? AND perusahaan_id = ?', [$salinId, (int) ($prsh['id'] ?? 0)]) : null;
            if ($sumber) {
                foreach (['posisi', 'bidang_id', 'jenis_pekerjaan', 'sistem_kerja', 'lokasi', 'gaji', 'kuota', 'deskripsi', 'kualifikasi', 'skill_dibutuhkan'] as $k) {
                    $bawaan[$k] = $sumber[$k];
                }
                $jurusanTerpilih = array_column((new Lowongan())->jurusanSasaran($salinId), 'id');
                $bawaan['_salin'] = $sumber['posisi'];
            } else {
                $bidangCocok = null;
                foreach ((new Bidang())->semuaUrut() as $b) {
                    if (!empty($prsh['bidang_usaha']) && (stripos($prsh['bidang_usaha'], $b['nama']) !== false || stripos($b['nama'], $prsh['bidang_usaha']) !== false)) {
                        $bidangCocok = $b['id'];
                        break;
                    }
                }
                $bawaan = ['lokasi' => $prsh['kota'] ?? '', 'kuota' => 1, 'bidang_id' => $bidangCocok,
                           'jenis_pekerjaan' => 'full_time', 'sistem_kerja' => 'wfo'];
            }
            $bawaan['batas_lamaran'] = date('Y-m-d', strtotime('+30 days'));
        }

        $this->view('perusahaan/lowongan-form', [
            'lowongan'        => $lowongan,
            'bawaan'          => $bawaan,
            'daftarSalin'     => $daftarSalin,
            'jurusanTerpilih' => array_map('intval', adaIsianLama() ? (array) old('jurusan_id', []) : $jurusanTerpilih),
            'bidang'          => (new Bidang())->semuaUrut(),
            'jurusan'         => (new Jurusan())->semuaUrut(),
            'riwayat'         => $riwayat,
            'maksKb'          => (int) ((require __DIR__ . '/../config/config.php')['max_upload_kb']),
        ]);
    }

    // [URL] POST /lowongan/proses-pasang  →  simpan lalu kembali ke /perusahaan/lowongan · peran: perusahaan
    public function prosesPasang()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $id = (int) $this->input('id');
        $kembali = $id ? 'lowongan/form-pasang/' . $id : 'lowongan/form-pasang';
        $lowonganModel = new Lowongan();
        $lama = null;
        if ($id) {
            [$lama] = $this->lowonganMilikSaya($id);
            if (in_array($lama['status'], ['ditolak', 'nonaktif'], true)) {
                $this->flash('bad', 'Lowongan ini tidak bisa diubah lagi.');
                $this->redirect('perusahaan/lowongan');
            }
        }

        $data = [
            'bidang_id'        => (int) $this->input('bidang_id'),
            'posisi'           => $this->input('posisi'),
            'jenis_pekerjaan'  => $this->input('jenis_pekerjaan'),
            'sistem_kerja'     => $this->input('sistem_kerja'),
            'lokasi'           => $this->input('lokasi'),
            'gaji'             => $this->input('gaji'),
            'kuota'            => (int) $this->input('kuota'),
            'batas_lamaran'    => $this->input('batas_lamaran'),
            'deskripsi'        => $this->input('deskripsi'),
            'kualifikasi'      => $this->input('kualifikasi'),
            'skill_dibutuhkan' => $this->input('skill_dibutuhkan'),
        ];
        $jurusanSasaran = array_filter(array_map('intval', (array) ($_POST['jurusan_id'] ?? [])));

        // --- Validasi server (sama dengan pengecekan di browser) ---
        $galat = [];
        if (!validasiWajibIsi($data['posisi']) || mb_strlen($data['posisi']) > 255) $galat[] = 'Posisi wajib diisi (maksimal 255 karakter).';
        if (!(new Bidang())->cari($data['bidang_id'])) $galat[] = 'Pilih bidang pekerjaan.';
        if (!in_array($data['jenis_pekerjaan'], self::JENIS_PEKERJAAN, true)) $galat[] = 'Pilih jenis pekerjaan.';
        if (!in_array($data['sistem_kerja'], self::SISTEM_KERJA, true)) $galat[] = 'Pilih sistem kerja.';
        if (!validasiWajibIsi($data['lokasi']) || mb_strlen($data['lokasi']) > 100) $galat[] = 'Lokasi wajib diisi (maksimal 100 karakter).';
        if (mb_strlen($data['gaji']) > 100) $galat[] = 'Keterangan gaji maksimal 100 karakter.';
        if ($data['kuota'] < 1 || $data['kuota'] > 1000) $galat[] = 'Kuota diterima minimal 1 dan maksimal 1000.';
        if ($lama && $data['kuota'] < (int) $lama['terisi']) $galat[] = 'Kuota tidak boleh lebih kecil dari pelamar yang sudah diterima (' . (int) $lama['terisi'] . ').';
        if (!validasiTanggal($data['batas_lamaran'])) {
            $galat[] = 'Batas lamaran wajib diisi dengan tanggal yang benar.';
        } elseif (strtotime($data['batas_lamaran']) < strtotime('today') && (!$lama || $lama['batas_lamaran'] !== $data['batas_lamaran'])) {
            $galat[] = 'Batas lamaran tidak boleh tanggal yang sudah lewat.';
        }
        if (!validasiWajibIsi($data['deskripsi'])) $galat[] = 'Deskripsi pekerjaan wajib diisi.';
        if (!validasiWajibIsi($data['kualifikasi'])) $galat[] = 'Kualifikasi wajib diisi.';
        if (mb_strlen($data['skill_dibutuhkan']) > 500) $galat[] = 'Skill yang dibutuhkan maksimal 500 karakter.';
        if (!$jurusanSasaran) $galat[] = 'Pilih minimal satu jurusan sasaran.';
        $adaPamfletBaru = ($_FILES['pamflet']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE;
        if (!$id && !$adaPamfletBaru) $galat[] = 'Pamflet wajib diunggah.';

        if ($galat) {
            $this->flash('bad', implode("\n", $galat) . ($adaPamfletBaru ? "\nPamflet yang tadi dipilih sudah diamankan, tidak perlu dipilih ulang." : ''));
            $this->redirect($kembali);
        }

        // Revisi C: berkas diunggah DULU. Bila gagal, data & pamflet lama tidak berubah.
        $pamfletBaru = null;
        if ($adaPamfletBaru) {
            try {
                $pamfletBaru = UploadService::simpan('pamflet', 'pamflet', self::TIPE_PAMFLET)['nama'];
            } catch (RuntimeException $e) {
                $this->flash('bad', 'Pamflet: ' . $e->getMessage() . ($id ? ' Pamflet lama tetap dipakai.' : ''));
                $this->redirect($kembali);
            }
        }

        $penggunaId = (int) Auth::penggunaSaatIni()['id'];
        try {
            if ($id) {
                $status = Database::transaksi(function () use ($lowonganModel, $id, $data, $penggunaId, $pamfletBaru, $jurusanSasaran) {
                    $status = $lowonganModel->perbarui($id, $data, $penggunaId, $pamfletBaru);
                    $lowonganModel->setJurusanSasaran($id, $jurusanSasaran);
                    return $status;
                });
                if ($status === 'menunggu' && $lama['status'] !== 'menunggu') {
                    NotifikasiService::lowonganMenungguUntukAdmin($id, $data['posisi'], $prsh['nama_perusahaan'], $lama['status'] === 'revisi');
                    $this->flash('ok', $lama['status'] === 'revisi'
                        ? 'Perbaikan tersimpan dan lowongan diajukan ulang. Admin akan meninjaunya kembali.'
                        : 'Perubahan tersimpan. Karena isi lowongan berubah, lowongan disembunyikan sementara sampai disetujui ulang Admin.');
                } else {
                    $this->flash('ok', 'Lowongan berhasil diperbarui.');
                }
            } else {
                $data['pamflet'] = $pamfletBaru;
                $lowonganId = Database::transaksi(function () use ($lowonganModel, $prsh, $data, $penggunaId, $jurusanSasaran) {
                    $lowonganId = $lowonganModel->buat((int) $prsh['id'], $data, $penggunaId);
                    $lowonganModel->setJurusanSasaran($lowonganId, $jurusanSasaran);
                    return $lowonganId;
                });
                NotifikasiService::lowonganMenungguUntukAdmin($lowonganId, $data['posisi'], $prsh['nama_perusahaan'], false);
                $this->flash('ok', 'Lowongan berhasil diajukan dan sedang menunggu persetujuan Admin Career Center. '
                    . 'Anda akan mendapat notifikasi dan email setelah ditinjau.');
            }
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
            $this->redirect($kembali);
        }

        $this->redirect('perusahaan/lowongan');
    }

    // [URL] POST /lowongan/tutup/{id}  →  simpan lalu kembali ke /perusahaan/lowongan · peran: perusahaan
    public function tutup(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $this->lowonganMilikSaya($id);
        if ((new Lowongan())->tutupManual($id, (int) Auth::penggunaSaatIni()['id'])) {
            $this->flash('ok', 'Lowongan berhasil ditutup. Lamaran yang sudah masuk tetap bisa diproses.');
        } else {
            $this->flash('bad', 'Hanya lowongan yang sedang aktif yang bisa ditutup.');
        }
        $this->redirect('perusahaan/lowongan');
    }

    // [URL] POST /lowongan/perpanjang/{id}  →  simpan lalu kembali ke /perusahaan/lowongan · peran: perusahaan
    /** Revisi D: perpanjang dengan tanggal & kuota yang dipilih sendiri lewat modal. */
    public function perpanjang(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        [$lowongan, $prsh] = $this->lowonganMilikSaya($id);
        $batasBaru = $this->input('batas_lamaran');
        $kuotaBaru = (int) $this->input('kuota');

        if (!validasiTanggal($batasBaru) || strtotime($batasBaru) < strtotime('today')) {
            $this->flash('bad', 'Batas lamaran baru wajib diisi dan tidak boleh tanggal yang sudah lewat.');
            $this->redirect('perusahaan/lowongan');
        }
        if (strtotime($batasBaru) > strtotime('+6 months')) {
            $this->flash('bad', 'Batas lamaran baru maksimal 6 bulan dari hari ini.');
            $this->redirect('perusahaan/lowongan');
        }
        if ($kuotaBaru < 1 || $kuotaBaru > 1000) {
            $this->flash('bad', 'Kuota minimal 1 dan maksimal 1000.');
            $this->redirect('perusahaan/lowongan');
        }

        try {
            (new Lowongan())->perpanjang($id, $batasBaru, $kuotaBaru, (int) Auth::penggunaSaatIni()['id']);
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
            $this->redirect('perusahaan/lowongan');
        }
        NotifikasiService::lowonganDiperpanjangUntukAdmin($id, $lowongan['posisi'], $prsh['nama_perusahaan'], $batasBaru);
        $this->flash('ok', 'Lowongan diperpanjang sampai ' . tanggalIndo($batasBaru) . ' dengan kuota ' . $kuotaBaru . ' dan aktif kembali untuk pelamar.');
        $this->redirect('perusahaan/lowongan');
    }

    // --- Publik: info loker (tanpa login) ----------------------------
    // [URL] GET /info-loker/{kode}  →  tampil: views/publik/info-loker.php
    public function pratinjau(string $kode)
    {
        (new Lowongan())->tutupOtomatisJikaLewatBatas();
        $lowongan = (new Lowongan())->cariByKodePratinjau($kode);
        if (!$lowongan) {
            $this->halaman404();
        }

        $this->view('publik/info-loker', [
            'lowongan'       => $lowongan,
            'kedaluwarsa'    => !Lowongan::bisaMenerimaLamaran($lowongan),
            'alasanTutup'    => Lowongan::alasanTidakMenerima($lowongan),
            'jurusanSasaran' => (new Lowongan())->jurusanSasaran((int) $lowongan['id']),
        ]);
    }
}
