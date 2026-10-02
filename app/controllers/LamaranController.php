<?php
/**
 * Pipeline lamaran
 * PIC   : Muhamad Nafi' Hanif (Modul Mahasiswa dan Alumni)
 * Status: LOGIKA BACKEND DIISI. Transaksi penerimaan pelamar ada di
 *         app/models/Lamaran.php::terima(), controller ini hanya memanggilnya.
 */

class LamaranController extends Controller
{
    /**
     * View: mahasiswa/lamaran-form. GET menampilkan form pilih CV + unggah
     * dokumen, POST (form yang sama, method=post) memprosesnya.
     * Variabel utk GET: $lowongan, $mahasiswa.
     */
    public function kirim(int $lowonganId)
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $lowongan = (new Lowongan())->cariDetail($lowonganId);

        if (!$lowongan || $lowongan['status'] !== 'aktif') {
            $this->flash('bad', 'Lowongan ini sudah tidak menerima lamaran.');
            $this->redirect('lowongan/detail/' . $lowonganId);
        }
        if ((new Lamaran())->sudahMelamar((int) $mhs['id'], $lowonganId)) {
            $this->flash('bad', 'Anda sudah pernah melamar lowongan ini.');
            $this->redirect('lowongan/detail/' . $lowonganId);
        }

        if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
            csrfVerifikasi();
            $this->prosesKirim($lowonganId, $mhs, $lowongan);
            return;
        }

        $this->view('mahasiswa/lamaran-form', ['lowongan' => $lowongan, 'mahasiswa' => $mhs]);
    }

    private function prosesKirim(int $lowonganId, array $mhs, array $lowongan): void
    {
        $mahasiswaId = (int) $mhs['id'];
        // Hanya dua nilai yang dikenal database. Kiriman lain diperlakukan
        // sebagai CV otomatis, supaya tidak berakhir jadi halaman fatal error.
        $jenisCv = $this->input('jenis_cv');
        if (!in_array($jenisCv, ['generate', 'unggah'], true)) {
            $jenisCv = 'generate';
        }
        $catatan = $this->input('catatan_pelamar');

        // KTM (atau ijazah untuk alumni) diambil OTOMATIS dari profil, sesuai proposal.
        if (empty($mhs['file_ktm'])) {
            $this->flash('bad', 'Lengkapi dokumen KTM/ijazah di Profil Karier sebelum melamar.');
            $this->redirect('lowongan/detail/' . $lowonganId);
        }
        if (empty($mhs['file_cv']) && $jenisCv === 'unggah') {
            $this->flash('bad', 'Anda memilih unggah CV sendiri, tapi belum ada CV di profil. Unggah dulu di Profil Karier.');
            $this->redirect('lowongan/detail/' . $lowonganId);
        }

        $fileCv = $jenisCv === 'unggah' ? $mhs['file_cv'] : null;
        if ($jenisCv === 'generate') {
            // Untuk kesederhanaan: pakai file_cv yang tersimpan bila ada, atau tandai '-'
            // agar kolom NOT NULL tetap terisi. CV yang sesungguhnya dibuat on-the-fly
            // lewat MahasiswaController::generateCv() dan bisa diunduh kapan pun.
            $fileCv = $mhs['file_cv'] ?: 'cv-otomatis.pdf';
        }

        // Surat pengantar. Mahasiswa boleh mengunggah berkas khusus untuk lowongan
        // ini, misalnya surat yang menyebut nama perusahaannya. Kalau tidak
        // mengunggah apa pun, surat pengantar yang sudah ada di Profil Karier
        // yang dipakai, supaya tidak perlu mengunggah berkas sama berulang kali.
        $adaUnggahan = isset($_FILES['file_surat_pengantar'])
            && ($_FILES['file_surat_pengantar']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE;

        if ($adaUnggahan) {
            try {
                $hasilUnggah = UploadService::simpan('file_surat_pengantar', 'dokumen_lamaran', ['pdf']);
                $suratPengantar = $hasilUnggah['nama'];
            } catch (RuntimeException $e) {
                $this->flash('bad', 'Surat pengantar: ' . $e->getMessage());
                $this->redirect('lamaran/kirim/' . $lowonganId);
            }
        } elseif (!empty($mhs['file_surat_pengantar'])) {
            $suratPengantar = $mhs['file_surat_pengantar'];
        } else {
            $this->flash('bad', 'Belum ada surat pengantar. Unggah di formulir ini, atau simpan sekali saja di Profil Karier supaya otomatis terpakai untuk lamaran berikutnya.');
            $this->redirect('lamaran/kirim/' . $lowonganId);
        }

        $snapshot = [
            'nama'         => $mhs['nama'],
            'nim'          => $mhs['nim'],
            'prodi'        => $mhs['nama_prodi'],
            'jurusan'      => $mhs['nama_jurusan'],
            'angkatan'     => $mhs['angkatan'],
            'no_whatsapp'  => $mhs['no_whatsapp'],
            'ipk'          => $mhs['ipk'],
        ];

        $lamaranModel = new Lamaran();
        $lamaranId = $lamaranModel->ajukan($mahasiswaId, $lowonganId, [
            'jenis_cv'             => $jenisCv,
            'file_cv'              => $fileCv,
            'file_ktm'             => $mhs['file_ktm'],
            'file_surat_pengantar' => $suratPengantar,
            'catatan_pelamar'      => $catatan,
        ], $snapshot, Auth::penggunaSaatIni()['id']);

        // 9. Notifikasi lamaran baru masuk -> perusahaan
        $prsh = (new Perusahaan())->cariById($lowongan['perusahaan_id'] ?? 0) ?? Database::fetch(
            'SELECT * FROM perusahaan WHERE id = ?', [$lowongan['perusahaan_id']]
        );
        if ($prsh) {
            NotifikasiService::lamaranMasukUntukPerusahaan(
                (int) $prsh['pengguna_id'], $mhs['nama'], $lowongan['posisi'], $lowonganId
            );
        }

        $this->flash('ok', 'Lamaran berhasil dikirim. Pantau statusnya di Lamaran Saya.');
        $this->redirect('lamaran/lamaran-saya');
    }

    /** View: mahasiswa/lamaran. Variabel: $lamaran (semua milik mahasiswa, dengan status & jadwal interview). */
    public function lamaranSaya()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $this->view('mahasiswa/lamaran', ['lamaran' => (new Lamaran())->milikMahasiswa((int) $mhs['id'])]);
    }

    public function batalkan(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $lamaranModel = new Lamaran();
        $lamaran = $lamaranModel->cariDetail($id);

        $berhasil = $lamaranModel->batalkan($id, (int) $mhs['id'], Auth::penggunaSaatIni()['id']);
        if ($berhasil) {
            if ($lamaran) {
                $prsh = Database::fetch('SELECT pengguna_id FROM perusahaan WHERE id = ?', [$lamaran['perusahaan_id']]);
                if ($prsh) {
                    NotifikasiService::lamaranDibatalkanUntukPerusahaan((int) $prsh['pengguna_id'], $mhs['nama'], $lamaran['posisi']);
                }
            }
            $this->flash('ok', 'Lamaran berhasil dibatalkan.');
        } else {
            $this->flash('bad', 'Lamaran hanya bisa dibatalkan selama masih berstatus Diajukan.');
        }
        $this->redirect('lamaran/lamaran-saya');
    }

    /**
     * View: perusahaan/pelamar-detail. Variabel: $lamaran, $mahasiswa (profil
     * lengkap si pelamar termasuk relasi skill/profil_item untuk ditampilkan),
     * $riwayat, $interview.
     * Membuka halaman ini otomatis memindahkan status 'diajukan' -> 'screening'.
     */
    public function detailPelamar(int $id)
    {
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $lamaranModel = new Lamaran();
        $lamaran = $lamaranModel->cariDetail($id);
        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);

        if (!$lamaran || (int) $lamaran['perusahaan_id'] !== (int) $prsh['id']) {
            http_response_code(403);
            die('Anda tidak berhak melihat lamaran ini.');
        }

        $lamaranModel->tandaiScreeningJikaBelum($id, Auth::penggunaSaatIni()['id']);
        $lamaran = $lamaranModel->cariDetail($id); // ambil ulang, status mungkin baru berubah

        $mahasiswa = (new Mahasiswa())->cariLengkap((int) $lamaran['mahasiswa_id']);

        $this->view('perusahaan/pelamar-detail', [
            'lamaran'    => $lamaran,
            'mahasiswa'  => $mahasiswa,
            'profilItem' => (new ProfilItem())->milikMahasiswa((int) $lamaran['mahasiswa_id']),
            'skill'      => (new Skill())->milikMahasiswa((int) $lamaran['mahasiswa_id']),
            'riwayat'    => (new RiwayatLamaran())->untukLamaran($id),
            'interview'  => (new Interview())->untukLamaran($id),
        ]);
    }

    /**
     * Satu action untuk beberapa aksi seleksi dari halaman Detail Pelamar,
     * dibedakan lewat field tersembunyi "aksi": jadwal_interview | tolak.
     * (Untuk aksi "terima", lihat LamaranController::terima() -- dipisah
     * karena efeknya lebih besar, jadi enak diaudit terpisah di kode.)
     */
    public function ubahStatus(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $lamaranModel = new Lamaran();
        $lamaran = $lamaranModel->cariDetail($id);
        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        if (!$lamaran || (int) $lamaran['perusahaan_id'] !== (int) $prsh['id']) {
            http_response_code(403);
            die('Anda tidak berhak mengubah lamaran ini.');
        }

        $aksi = $this->input('aksi');
        $penggunaId = Auth::penggunaSaatIni()['id'];

        if ($aksi === 'jadwal_interview') {
            $tanggal = $this->input('tanggal');
            $jam     = $this->input('jam');
            $mode    = $this->input('mode');

            if (!validasiWajibIsi($tanggal) || !validasiWajibIsi($jam) || !validasiWajibIsi($mode)) {
                $this->flash('bad', 'Tanggal, jam, dan mode interview wajib diisi.');
                $this->redirect('lamaran/detail-pelamar/' . $id);
            }
            if (!in_array($mode, ['daring', 'luring'], true)) {
                $this->flash('bad', 'Mode interview harus daring atau luring.');
                $this->redirect('lamaran/detail-pelamar/' . $id);
            }

            // Field wajib berbeda antara daring dan luring. Interview daring
            // butuh tautan meeting; interview luring butuh alamat tempat, dan
            // sebaiknya disertai ruangan, dresscode, serta berkas yang dibawa
            // supaya pelamar tidak perlu bertanya lagi lewat WhatsApp.
            $data = [
                'tanggal' => $tanggal,
                'jam'     => $jam,
                'mode'    => $mode,
                'catatan' => $this->input('catatan'),
            ];

            if ($mode === 'daring') {
                $tautan = trim((string) $this->input('lokasi_tautan'));
                if (!validasiWajibIsi($tautan)) {
                    $this->flash('bad', 'Interview daring wajib menyertakan tautan meeting (Zoom, Google Meet, dan sejenisnya).');
                    $this->redirect('lamaran/detail-pelamar/' . $id);
                }
                $data['lokasi_tautan'] = $tautan;
            } else {
                $tempat = trim((string) $this->input('tempat'));
                if (!validasiWajibIsi($tempat)) {
                    $this->flash('bad', 'Interview luring wajib menyertakan alamat atau nama tempat.');
                    $this->redirect('lamaran/detail-pelamar/' . $id);
                }
                $data['tempat']        = $tempat;
                $data['ruangan']       = $this->input('ruangan');
                $data['dresscode']     = $this->input('dresscode');
                $data['yang_dibawa']   = $this->input('yang_dibawa');
                $data['narahubung']    = $this->input('narahubung');
                $data['lokasi_tautan'] = $tempat; // kolom lama tetap terisi
            }

            $lamaranModel->jadwalkanInterview($id, $penggunaId, $data);
            NotifikasiService::statusLamaranBerubah((int) $lamaran['mahasiswa_pengguna_id'], $lamaran['posisi'], 'interview');
            $this->flash('ok', 'Jadwal interview berhasil disimpan.');
        } elseif ($aksi === 'tolak') {
            $catatan = $this->input('catatan_perusahaan');
            if (!validasiWajibIsi($catatan)) {
                $this->flash('bad', 'Catatan alasan penolakan wajib diisi.');
                $this->redirect('lamaran/detail-pelamar/' . $id);
            }
            $lamaranModel->tolak($id, $penggunaId, $catatan);
            NotifikasiService::statusLamaranBerubah((int) $lamaran['mahasiswa_pengguna_id'], $lamaran['posisi'], 'ditolak', $catatan);
            $this->flash('ok', 'Pelamar berhasil ditolak.');
        } else {
            $this->flash('bad', 'Aksi tidak dikenal.');
        }

        $this->redirect('lamaran/detail-pelamar/' . $id);
    }

    /**
     * Terima pelamar. Method terpisah (bukan lewat ubahStatus) karena ini
     * memicu transaksi 3-pihak lewat Lamaran::terima() -- lihat komentar di
     * app/models/Lamaran.php.
     */
    public function terima(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        $lamaranModel = new Lamaran();
        $lamaran = $lamaranModel->cariDetail($id);
        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        if (!$lamaran || (int) $lamaran['perusahaan_id'] !== (int) $prsh['id']) {
            http_response_code(403);
            die('Anda tidak berhak mengubah lamaran ini.');
        }

        $kuotaSebelumPenuh = (int) $lamaran['terisi'] + 1 >= (int) $lamaran['kuota'];

        try {
            $lamaranModel->terima($id, Auth::penggunaSaatIni()['id']);
        } catch (Throwable $e) {
            $this->flash('bad', 'Gagal memproses penerimaan pelamar. Silakan coba lagi.');
            $this->redirect('lamaran/detail-pelamar/' . $id);
        }

        // 11. Notifikasi ke pelamar, perusahaan, dan admin.
        NotifikasiService::pelamarDiterima(
            (int) $lamaran['mahasiswa_pengguna_id'],
            (int) $prsh['pengguna_id'],
            $lamaran['posisi'],
            $lamaran['nama_perusahaan'],
            $lamaran['nama_mahasiswa']
        );
        // 12. Kalau kuota baru saja penuh, beri tahu perusahaan bahwa lowongan otomatis ditutup.
        if ($kuotaSebelumPenuh) {
            NotifikasiService::kuotaTerpenuhi((int) $prsh['pengguna_id'], $lamaran['posisi']);
        }

        $this->flash('ok', 'Pelamar berhasil diterima. Status karier dan kuota lowongan sudah diperbarui otomatis.');
        $this->redirect('lamaran/detail-pelamar/' . $id);
    }
}
