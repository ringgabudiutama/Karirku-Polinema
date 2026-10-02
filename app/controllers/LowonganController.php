<?php
/**
 * Daftar, detail, dan pengelolaan lowongan
 * PIC   : Atha Rasya Farras (Modul Operator dan Career Center)
 * Status: LOGIKA BACKEND DIISI. Views masih perlu ditimpa dengan desain asli.
 */

class LowonganController extends Controller
{
    /**
     * View: mahasiswa/lowongan. Variabel: $lowongan (hasil halaman ini),
     * $total, $halaman, $totalHalaman, $filter (nilai filter yang sedang
     * dipakai, untuk mengisi ulang form), $jurusan, $bidang (untuk <select>).
     */
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
        $halaman = max(1, (int) $this->query_('halaman', '1'));
        $perHalaman = 10;

        $lowonganModel = new Lowongan();
        $total = $lowonganModel->hitungCari($filter);
        $daftar = $lowonganModel->cariDenganFilter($filter, $perHalaman, ($halaman - 1) * $perHalaman);

        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $disimpanModel = new LowonganDisimpan();
        foreach ($daftar as &$l) {
            $l['sudah_disimpan'] = $mhs ? $disimpanModel->sudahDisimpan((int) $mhs['id'], (int) $l['id']) : false;
        }
        unset($l);

        $this->view('mahasiswa/lowongan', [
            'lowongan'     => $daftar,
            'total'        => $total,
            'halaman'      => $halaman,
            'totalHalaman' => max(1, (int) ceil($total / $perHalaman)),
            'filter'       => $filter,
            'jurusan'      => (new Jurusan())->semuaUrut(),
            'bidang'       => (new Bidang())->semuaUrut(),
            'lokasiOpsi'   => $lowonganModel->lokasiUnik(),
        ]);
    }

    /**
     * View: mahasiswa/lowongan-detail. Variabel: $lowongan, $jurusanSasaran,
     * $sudahDisimpan, $sudahMelamar, $profilLengkap (bool, syarat boleh melamar).
     */
    public function detail(int $id)
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $lowongan = (new Lowongan())->cariDetail($id);
        if (!$lowongan) {
            http_response_code(404);
            require __DIR__ . '/../views/publik/404.php';
            return;
        }

        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $mahasiswaId = (int) $mhs['id'];

        $syaratLengkap = !empty($mhs['file_cv']) && (!empty($mhs['file_ktm']));

        $this->view('mahasiswa/lowongan-detail', [
            'lowongan'       => $lowongan,
            'jurusanSasaran' => (new Lowongan())->jurusanSasaran($id),
            'sudahDisimpan'  => (new LowonganDisimpan())->sudahDisimpan($mahasiswaId, $id),
            'sudahMelamar'   => (new Lamaran())->sudahMelamar($mahasiswaId, $id),
            'profilLengkap'  => $syaratLengkap,
        ]);
    }

    /** Toggle simpan/batal-simpan lowongan (dipanggil dari tombol bookmark). */
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
        } else {
            $disimpanModel->simpanBookmark($mahasiswaId, $id);
            $this->flash('ok', 'Lowongan berhasil disimpan.');
        }

        $kembali = $this->input('kembali') ?: ('lowongan/detail/' . $id);
        $this->redirect($kembali);
    }

    /**
     * View: perusahaan/lowongan-form. Variabel: $lowongan (null kalau pasang baru,
     * berisi data kalau mode edit), $jurusanTerpilih, $bidang, $jurusan.
     */
    public function formPasang(int $id = 0)
    {
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $lowongan = null;
        $jurusanTerpilih = [];

        if ($id) {
            $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
            $lowonganModel = new Lowongan();
            $lowongan = $lowonganModel->cari($id);
            if (!$lowongan || (int) $lowongan['perusahaan_id'] !== (int) $prsh['id']) {
                http_response_code(403);
                die('Anda tidak berhak mengubah lowongan ini.');
            }
            $jurusanTerpilih = array_column($lowonganModel->jurusanSasaran($id), 'id');
        }

        $this->view('perusahaan/lowongan-form', [
            'lowongan'        => $lowongan,
            'jurusanTerpilih' => $jurusanTerpilih,
            'bidang'          => (new Bidang())->semuaUrut(),
            'jurusan'         => (new Jurusan())->semuaUrut(),
        ]);
    }

    /** Handle create MAUPUN update, dibedakan lewat field tersembunyi "id" (kosong = baru). */
    public function prosesPasang()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $id = (int) $this->input('id');

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
        $jurusanSasaran = $_POST['jurusan_id'] ?? [];

        if ($data['kuota'] < 1) {
            $this->flash('bad', 'Kuota minimal 1.');
            $this->redirect($id ? 'lowongan/form-pasang/' . $id : 'lowongan/form-pasang');
        }
        if (empty($jurusanSasaran)) {
            $this->flash('bad', 'Pilih minimal satu jurusan sasaran.');
            $this->redirect($id ? 'lowongan/form-pasang/' . $id : 'lowongan/form-pasang');
        }

        $lowonganModel = new Lowongan();

        try {
            if ($id) {
                // pastikan lowongan ini benar milik perusahaan yang sedang login
                $existing = $lowonganModel->cari($id);
                if (!$existing || (int) $existing['perusahaan_id'] !== (int) $prsh['id']) {
                    http_response_code(403);
                    die('Anda tidak berhak mengubah lowongan ini.');
                }
                $lowonganModel->perbarui($id, $data);
                if (!empty($_FILES['pamflet']['name'])) {
                    $f = UploadService::simpan('pamflet', 'pamflet', ['jpg', 'jpeg', 'png']);
                    $lowonganModel->perbaruiPamflet($id, $f['nama']);
                }
                $lowonganModel->setJurusanSasaran($id, $jurusanSasaran);
                $this->flash('ok', 'Lowongan berhasil diperbarui.');
            } else {
                // pamflet WAJIB untuk lowongan baru (proposal: "Tombol Tayangkan mati sebelum pamflet diunggah").
                $pamflet = UploadService::simpan('pamflet', 'pamflet', ['jpg', 'jpeg', 'png']);
                $data['pamflet'] = $pamflet['nama'];
                $lowonganId = $lowonganModel->buat((int) $prsh['id'], $data);
                $lowonganModel->setJurusanSasaran($lowonganId, $jurusanSasaran);
                NotifikasiService::lowonganBaruSesuaiMinat($lowonganId, $data['posisi'], $prsh['nama_perusahaan'], $data['bidang_id']);

                $this->flash('ok', 'Lowongan berhasil dipasang dan langsung tayang.');
            }
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
            $this->redirect($id ? 'lowongan/form-pasang/' . $id : 'lowongan/form-pasang');
        }

        $this->redirect('perusahaan/lowongan');
    }

    /** Tutup manual sebelum batas lamar (beda dengan otomatis saat kuota penuh). */
    public function tutup(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $lowonganModel = new Lowongan();
        $lowongan = $lowonganModel->cari($id);

        if (!$lowongan || (int) $lowongan['perusahaan_id'] !== (int) $prsh['id']) {
            http_response_code(403);
            die('Anda tidak berhak menutup lowongan ini.');
        }

        $lowonganModel->tutupManual($id);
        $this->flash('ok', 'Lowongan berhasil ditutup.');
        $this->redirect('perusahaan/lowongan');
    }

    /** Buka kembali lowongan yang sudah ditutup (kuota penuh/manual) dengan batas lamaran baru. */
    public function perpanjang(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $lowonganModel = new Lowongan();
        $lowongan = $lowonganModel->cari($id);

        if (!$lowongan || (int) $lowongan['perusahaan_id'] !== (int) $prsh['id']) {
            http_response_code(403);
            die('Anda tidak berhak memperpanjang lowongan ini.');
        }
        if ($lowongan['status'] !== 'ditutup') {
            $this->flash('bad', 'Hanya lowongan berstatus Ditutup yang bisa diperpanjang.');
            $this->redirect('perusahaan/lowongan');
        }

        $batasBaru = $this->input('batas_lamaran');
        if (!$batasBaru || strtotime($batasBaru) < strtotime('today')) {
            $this->flash('bad', 'Batas lamaran baru wajib diisi dan tidak boleh tanggal yang sudah lewat.');
            $this->redirect('perusahaan/lowongan');
        }

        $lowonganModel->perpanjang($id, $batasBaru);
        $this->flash('ok', 'Lowongan berhasil diperpanjang dan aktif kembali.');
        $this->redirect('perusahaan/lowongan');
    }

    /**
     * View: publik/info-loker. Halaman TANPA LOGIN, dibuka lewat tautan
     * wa.me yang dikirim ke admin jurusan. Kode acak (bukan id angka) supaya
     * tidak mudah ditebak dan tidak diindeks mesin pencari (lihat view:
     * pasang <meta name="robots" content="noindex"> di sana).
     */
    public function pratinjau(string $kode)
    {
        $lowongan = (new Lowongan())->cariByKodePratinjau($kode);
        if (!$lowongan) {
            http_response_code(404);
            require __DIR__ . '/../views/publik/404.php';
            return;
        }

        $kedaluwarsa = strtotime($lowongan['batas_lamaran']) < strtotime('today');

        $this->view('publik/info-loker', [
            'lowongan'    => $lowongan,
            'kedaluwarsa' => $kedaluwarsa,
        ]);
    }
}