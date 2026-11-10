<?php
// ===== BACKEND · CONTROLLER · Lamaran ================================

class LamaranController extends Controller
{
    // --- Mahasiswa: kirim lamaran ------------------------------------
    // [URL] GET /lamaran/kirim/{lowonganId}  →  tampil: views/mahasiswa/lamaran-form.php · peran: mahasiswa
    public function kirim(int $lowonganId)
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        (new Lowongan())->tutupOtomatisJikaLewatBatas();
        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $lowongan = (new Lowongan())->cariDetailTayang($lowonganId);

        if (!$lowongan) {
            $this->halaman404();
        }
        if (!Lowongan::bisaMenerimaLamaran($lowongan)) {
            $this->flash('bad', Lowongan::alasanTidakMenerima($lowongan));
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

        // Revisi E: data pelamar diambil otomatis dari profil (tidak diketik ulang).
        $this->view('mahasiswa/lamaran-form', [
            'lowongan'  => $lowongan,
            'mahasiswa' => $mhs,
            'skill'     => (new Skill())->milikMahasiswa((int) $mhs['id']),
        ]);
    }

    private function prosesKirim(int $lowonganId, array $mhs, array $lowongan): void
    {
        $mahasiswaId = (int) $mhs['id'];
        $jenisCv = $this->input('jenis_cv');
        if (!in_array($jenisCv, ['generate', 'unggah'], true)) {
            $jenisCv = 'generate';
        }
        $catatan = $this->input('catatan_pelamar');
        if (mb_strlen($catatan) > 1000) {
            $this->flash('bad', 'Pesan untuk perusahaan maksimal 1000 karakter.');
            $this->redirect('lamaran/kirim/' . $lowonganId);
        }
        if (!isset($_POST['data_benar'])) {
            $this->flash('bad', 'Centang pernyataan bahwa data profil Anda sudah benar sebelum mengirim lamaran.');
            $this->redirect('lamaran/kirim/' . $lowonganId);
        }

        if (empty($mhs['file_ktm'])) {
            $this->flash('bad', 'Lengkapi dokumen KTM/ijazah di Profil Karier sebelum melamar.');
            $this->redirect('lamaran/kirim/' . $lowonganId);
        }
        if (empty($mhs['file_cv']) && $jenisCv === 'unggah') {
            $this->flash('bad', 'Anda memilih unggah CV sendiri, tapi belum ada CV di profil. Unggah dulu di Profil Karier atau pilih CV otomatis.');
            $this->redirect('lamaran/kirim/' . $lowonganId);
        }

        $fileCv = $jenisCv === 'unggah' ? $mhs['file_cv'] : ($mhs['file_cv'] ?: 'cv-sistem.pdf');

        $adaUnggahan = ($_FILES['file_surat_pengantar']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE;
        if ($adaUnggahan) {
            try {
                $suratPengantar = UploadService::simpan('file_surat_pengantar', 'dokumen_lamaran', ['pdf'])['nama'];
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

        // Revisi E: salinan lengkap data profil saat melamar. Perusahaan melihat
        // data ini apa adanya walaupun profil kemudian diubah.
        $skill = array_column((new Skill())->milikMahasiswa($mahasiswaId), 'nama');
        $snapshot = [
            'nama'             => $mhs['nama'],
            'nim'              => $mhs['nim'],
            'email'            => $mhs['email'],
            'no_whatsapp'      => $mhs['no_whatsapp'],
            'prodi'            => $mhs['nama_prodi'],
            'jenjang'          => $mhs['jenjang'],
            'jurusan'          => $mhs['nama_jurusan'],
            'angkatan'         => $mhs['angkatan'],
            'status_mahasiswa' => $mhs['status_mahasiswa'],
            'tahun_lulus'      => $mhs['tahun_lulus'],
            'ipk'              => $mhs['ipk'],
            'domisili'         => $mhs['domisili'],
            'alamat'           => $mhs['alamat'] ?? null,
            'provinsi'         => $mhs['provinsi'] ?? null,
            'skill'            => $skill,
            'jenis_cv'         => $jenisCv,
            'diambil_pada'     => date('Y-m-d H:i:s'),
        ];

        try {
            (new Lamaran())->ajukan($mahasiswaId, $lowonganId, [
                'jenis_cv'             => $jenisCv,
                'file_cv'              => $fileCv,
                'file_ktm'             => $mhs['file_ktm'],
                'file_surat_pengantar' => $suratPengantar,
                'catatan_pelamar'      => $catatan,
            ], $snapshot, Auth::penggunaSaatIni()['id']);
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
            $this->redirect('lowongan/detail/' . $lowonganId);
        } catch (PDOException $e) {
            // Klik ganda bersamaan: baris kedua ditolak UNIQUE (mahasiswa, lowongan).
            if ($e->getCode() === '23505') {
                $this->flash('ok', 'Lamaran Anda sudah tercatat sebelumnya. Pantau statusnya di Lamaran Saya.');
                $this->redirect('lamaran/lamaran-saya');
            }
            throw $e;
        }

        NotifikasiService::lamaranMasukUntukPerusahaan(
            (int) $lowongan['perusahaan_pengguna_id'], $mhs['nama'], $lowongan['posisi'], $lowonganId
        );

        $this->flash('ok', 'Lamaran berhasil dikirim. Pantau statusnya di Lamaran Saya.');
        $this->redirect('lamaran/lamaran-saya');
    }

    // --- Mahasiswa: lamaran saya -------------------------------------
    // [URL] GET /lamaran/lamaran-saya  →  tampil: views/mahasiswa/lamaran.php · peran: mahasiswa
    public function lamaranSaya()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $this->view('mahasiswa/lamaran', ['lamaran' => (new Lamaran())->milikMahasiswa((int) $mhs['id'])]);
    }

    // [URL] POST /lamaran/batalkan/{id}  →  simpan lalu kembali ke /lamaran/lamaran-saya · peran: mahasiswa
    public function batalkan(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('mahasiswa');

        $mhs = (new Mahasiswa())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        $lamaranModel = new Lamaran();
        $lamaran = $lamaranModel->cariDetail($id);

        if ($lamaranModel->batalkan($id, (int) $mhs['id'], Auth::penggunaSaatIni()['id'])) {
            if ($lamaran) {
                NotifikasiService::lamaranDibatalkanUntukPerusahaan((int) $lamaran['perusahaan_pengguna_id'], $mhs['nama'], $lamaran['posisi']);
            }
            $this->flash('ok', 'Lamaran berhasil dibatalkan.');
        } else {
            $this->flash('bad', 'Lamaran hanya bisa dibatalkan selama masih berstatus Diajukan (belum dibuka perusahaan).');
        }
        $this->redirect('lamaran/lamaran-saya');
    }

    // --- Perusahaan: proses pelamar ----------------------------------
    private function lamaranMilikPerusahaan(int $id): array
    {
        $lamaran = (new Lamaran())->cariDetail($id);
        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']);
        if (!$lamaran || !$prsh || (int) $lamaran['perusahaan_id'] !== (int) $prsh['id']) {
            $this->halaman403('Lamaran ini ditujukan ke perusahaan lain.');
        }
        return [$lamaran, $prsh];
    }

    // [URL] GET /lamaran/detail-pelamar/{id}  →  tampil: views/perusahaan/pelamar-detail.php · peran: perusahaan
    public function detailPelamar(int $id)
    {
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        [$lamaran] = $this->lamaranMilikPerusahaan($id);
        $lamaranModel = new Lamaran();

        // Bug #7: Screening memberi notifikasi ke pelamar, cukup sekali.
        if ($lamaranModel->tandaiScreeningJikaBelum($id, Auth::penggunaSaatIni()['id'])) {
            NotifikasiService::statusLamaranBerubah((int) $lamaran['mahasiswa_pengguna_id'], $lamaran['posisi'], 'screening');
            $lamaran = $lamaranModel->cariDetail($id);
        }

        $mahasiswaId = (int) $lamaran['mahasiswa_id'];
        $interview = (new Interview())->untukLamaran($id);
        $prsh = (new Perusahaan())->cariByPenggunaId(Auth::penggunaSaatIni()['id']) ?: [];
        $this->view('perusahaan/pelamar-detail', [
            'isianInterview' => self::isianInterviewOtomatis($interview ?: null, $prsh),
            'templateTolak'  => self::templateTolak($lamaran),
            'lamaran'    => $lamaran,
            'snapshot'   => json_decode((string) $lamaran['snapshot_profil'], true) ?: [],
            'mahasiswa'  => (new Mahasiswa())->cariLengkap($mahasiswaId),
            'profilItem' => (new ProfilItem())->milikMahasiswa($mahasiswaId),
            'skill'      => (new Skill())->milikMahasiswa($mahasiswaId),
            'riwayat'    => (new RiwayatLamaran())->untukLamaran($id),
            'interview'  => $interview,
            'sudahFinal' => Lamaran::sudahFinal($lamaran['status']),
        ]);
    }

    // [URL] POST /lamaran/ubah-status/{id}  →  proses · peran: perusahaan
    public function ubahStatus(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        [$lamaran] = $this->lamaranMilikPerusahaan($id);
        $aksi = $this->input('aksi');
        $penggunaId = Auth::penggunaSaatIni()['id'];
        $kembali = 'lamaran/detail-pelamar/' . $id;

        if (Lamaran::sudahFinal($lamaran['status'])) {
            $this->flash('bad', 'Lamaran ini sudah berstatus ' . labelStatusLamaran($lamaran['status'])[0] . ', jadi tidak bisa diproses lagi.');
            $this->redirect($kembali);
        }

        try {
            if ($aksi === 'jadwal_interview') {
                $data = $this->validasiInterview($kembali);
                $diubah = (new Lamaran())->jadwalkanInterview($id, $penggunaId, $data);
                NotifikasiService::statusLamaranBerubah((int) $lamaran['mahasiswa_pengguna_id'], $lamaran['posisi'], 'interview',
                    ($diubah ? 'Jadwal diperbarui: ' : '') . tanggalIndo($data['tanggal']) . ' ' . $data['jam'] . ' WIB');
                $this->flash('ok', $diubah ? 'Jadwal interview berhasil diperbarui dan pelamar sudah diberi tahu.' : 'Jadwal interview berhasil disimpan.');
            } elseif ($aksi === 'tolak') {
                $catatan = $this->input('catatan_perusahaan');
                if (!validasiWajibIsi($catatan) || mb_strlen(trim($catatan)) < 10) {
                    $this->flash('bad', 'Alasan penolakan wajib diisi, minimal 10 karakter, supaya pelamar tahu alasannya. Bisa pakai tombol isi cepat.');
                    $this->redirect($kembali);
                }
                if (mb_strlen($catatan) > 500) {
                    $this->flash('bad', 'Alasan penolakan maksimal 500 karakter.');
                    $this->redirect($kembali);
                }
                (new Lamaran())->tolak($id, $penggunaId, $catatan);
                NotifikasiService::statusLamaranBerubah((int) $lamaran['mahasiswa_pengguna_id'], $lamaran['posisi'], 'ditolak', $catatan);
                $this->flash('ok', 'Pelamar berhasil ditolak.');
            } else {
                $this->flash('bad', 'Aksi tidak dikenal.');
            }
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
        }

        $this->redirect($kembali);
    }

    private function validasiInterview(string $kembali): array
    {
        $tanggal = $this->input('tanggal');
        $jam     = $this->input('jam');
        $mode    = $this->input('mode');
        $galat = [];

        if (!validasiTanggal($tanggal)) {
            $galat[] = 'Tanggal interview wajib diisi.';
        } elseif (strtotime($tanggal) < strtotime('today')) {
            $galat[] = 'Tanggal interview tidak boleh tanggal yang sudah lewat.';
        }
        if (!preg_match('/^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/', $jam)) {
            $galat[] = 'Jam interview wajib diisi (format JJ:MM).';
        }
        if (!in_array($mode, ['daring', 'luring'], true)) {
            $galat[] = 'Pilih mode interview: daring atau luring.';
        }

        $data = ['tanggal' => $tanggal, 'jam' => substr($jam, 0, 5), 'mode' => $mode, 'catatan' => $this->input('catatan')];
        if ($mode === 'daring') {
            $tautan = $this->input('lokasi_tautan');
            if (!filter_var($tautan, FILTER_VALIDATE_URL) || !preg_match('#^https?://#i', $tautan)) {
                $galat[] = 'Interview daring wajib menyertakan tautan meeting yang valid (diawali https://).';
            }
            $data['lokasi_tautan'] = $tautan;
        } elseif ($mode === 'luring') {
            $tempat = $this->input('tempat');
            if (!validasiWajibIsi($tempat)) {
                $galat[] = 'Interview luring wajib menyertakan alamat atau nama tempat.';
            }
            $data += [
                'tempat' => $tempat, 'ruangan' => $this->input('ruangan'), 'dresscode' => $this->input('dresscode'),
                'yang_dibawa' => $this->input('yang_dibawa'), 'narahubung' => $this->input('narahubung'),
                'lokasi_tautan' => $tempat,
            ];
        }
        if ($galat) {
            $this->flash('bad', implode("\n", $galat));
            $this->redirect($kembali . '#interview');
        }
        return $data;
    }

    // [URL] POST /lamaran/terima/{id}  →  simpan lalu kembali ke /lamaran/detail-pelamar/ · peran: perusahaan
    public function terima(int $id)
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('perusahaan');

        [$lamaran, $prsh] = $this->lamaranMilikPerusahaan($id);
        $kuotaJadiPenuh = (int) $lamaran['terisi'] + 1 >= (int) $lamaran['kuota'];

        try {
            (new Lamaran())->terima($id, Auth::penggunaSaatIni()['id']);
        } catch (RuntimeException $e) {
            $this->flash('bad', $e->getMessage());
            $this->redirect('lamaran/detail-pelamar/' . $id);
        }

        NotifikasiService::pelamarDiterima(
            (int) $lamaran['mahasiswa_pengguna_id'],
            (int) $prsh['pengguna_id'],
            $lamaran['posisi'],
            $lamaran['nama_perusahaan'],
            $lamaran['nama_mahasiswa']
        );
        if ($kuotaJadiPenuh) {
            NotifikasiService::kuotaTerpenuhi((int) $prsh['pengguna_id'], $lamaran['posisi']);
        }

        $this->flash('ok', 'Pelamar berhasil diterima. Status karier dan kuota lowongan sudah diperbarui otomatis.');
        $this->redirect('lamaran/detail-pelamar/' . $id);
    }

    /**
     * Isian otomatis formulir interview: memakai jadwal tersimpan bila ada,
     * selain itu diisi dari profil perusahaan (alamat kantor, PIC, WhatsApp PIC).
     * Tanggal yang sudah lewat diganti hari kerja terdekat (H+2), supaya formulir
     * tidak langsung ditolak "tanggal sudah lewat".
     */
    private static function isianInterviewOtomatis(?array $iv, array $prsh): array
    {
        $hariKerja = new DateTime('today +2 days');
        while ((int) $hariKerja->format('N') >= 6) {
            $hariKerja->modify('+1 day');
        }
        $tanggal = $iv['tanggal'] ?? '';
        if ($tanggal === '' || $tanggal < date('Y-m-d')) {
            $tanggal = $hariKerja->format('Y-m-d');
        }
        $alamat = trim(implode(', ', array_filter([
            $prsh['nama_perusahaan'] ?? '', $prsh['alamat'] ?? '', $prsh['kota'] ?? '',
        ])));
        $pic = trim(($prsh['nama_pic'] ?? '') . (!empty($prsh['jabatan_pic']) ? ' (' . $prsh['jabatan_pic'] . ')' : '')
            . (!empty($prsh['whatsapp_pic']) ? ', ' . $prsh['whatsapp_pic'] : ''), ', ');
        $isi = fn(string $k, string $cadangan) => trim((string) ($iv[$k] ?? '')) !== '' ? (string) $iv[$k] : $cadangan;
        return [
            'tanggal'       => $tanggal,
            'jam'           => substr($isi('jam', '09:00'), 0, 5),
            'mode'          => $isi('mode', 'daring'),
            'lokasi_tautan' => ($iv['mode'] ?? '') !== 'luring' ? (string) ($iv['lokasi_tautan'] ?? '') : '',
            'tempat'        => $isi('tempat', $alamat),
            'ruangan'       => $isi('ruangan', ''),
            'dresscode'     => $isi('dresscode', 'Rapi dan sopan (kemeja berkerah, sepatu tertutup)'),
            'yang_dibawa'   => $isi('yang_dibawa', 'KTM/KTP, CV cetak, dan portofolio (bila ada)'),
            'narahubung'    => $isi('narahubung', $pic),
            'catatan'       => $isi('catatan', 'Mohon hadir/bergabung 10 menit sebelum jadwal dan konfirmasi kehadiran ke narahubung.'),
        ];
    }

    /** Pilihan isi cepat alasan penolakan pelamar, sudah memakai nama dan posisinya. */
    private static function templateTolak(array $l): array
    {
        $nama = trim((string) ($l['nama_mahasiswa'] ?? $l['nama'] ?? ''));
        $sapa = $nama !== '' ? 'Terima kasih, ' . $nama . ', atas lamaran Anda' : 'Terima kasih atas lamaran Anda';
        $posisi = (string) ($l['posisi'] ?? 'posisi ini');
        return [
            $sapa . ' untuk posisi ' . $posisi . '. Saat ini kualifikasi Anda belum sesuai dengan kebutuhan kami.',
            $sapa . '. Kami memilih kandidat yang pengalamannya lebih sesuai untuk posisi ' . $posisi . '.',
            $sapa . '. Kuota posisi ' . $posisi . ' sudah terpenuhi. Silakan lamar lowongan kami berikutnya.',
            $sapa . '. Hasil interview belum memenuhi kriteria untuk posisi ' . $posisi . '. Semoga sukses ke depannya.',
        ];
    }
}
