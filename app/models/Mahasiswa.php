<?php
/**
 * Model tabel mahasiswa
 * PIC   : Muhamad Nafi' Hanif (Modul Mahasiswa dan Alumni)
 * Status: DIISI.
 */

class Mahasiswa extends Model
{
    protected string $tabel = 'mahasiswa';

    public function buat(array $d): int
    {
        return $this->simpan([
            'pengguna_id'      => $d['pengguna_id'],
            'program_studi_id' => $d['program_studi_id'],
            'nama'             => $d['nama'],
            'nim'              => $d['nim'],
            'no_whatsapp'      => $d['no_whatsapp'],
            'status_mahasiswa' => $d['status_mahasiswa'],
            'angkatan'         => $d['angkatan'],
            'tahun_lulus'      => $d['tahun_lulus'] !== '' ? $d['tahun_lulus'] : null,
        ]);
    }

    public function nimSudahDipakai(string $nim): bool
    {
        return $this->satuBerdasarkan('nim', $nim) !== null;
    }

    public function cariByPenggunaId(int $penggunaId): ?array
    {
        return Database::fetch(
            'SELECT m.*, ps.nama AS nama_prodi, ps.jenjang, j.id AS jurusan_id, j.nama AS nama_jurusan, p.email
             FROM mahasiswa m
             JOIN program_studi ps ON ps.id = m.program_studi_id
             JOIN jurusan j ON j.id = ps.jurusan_id
             JOIN pengguna p ON p.id = m.pengguna_id
             WHERE m.pengguna_id = ?',
            [$penggunaId]
        );
    }

    public function cariLengkap(int $id): ?array
    {
        return Database::fetch(
            'SELECT m.*, ps.nama AS nama_prodi, ps.jenjang, j.id AS jurusan_id, j.nama AS nama_jurusan, p.email
             FROM mahasiswa m
             JOIN program_studi ps ON ps.id = m.program_studi_id
             JOIN jurusan j ON j.id = ps.jurusan_id
             JOIN pengguna p ON p.id = m.pengguna_id
             WHERE m.id = ?',
            [$id]
        );
    }

    public function perbaruiProfil(int $id, array $d): void
    {
        $this->ubah($id, [
            'nama'        => $d['nama'],
            'no_whatsapp' => $d['no_whatsapp'],
            'domisili'    => $d['domisili'] ?: null,
            'tentang'     => $d['tentang'] ?: null,
            'ipk'         => $d['ipk'] !== '' ? $d['ipk'] : null,
        ]);
    }

    public function perbaruiFoto(int $id, string $namaFile): void
    {
        $this->ubah($id, ['foto' => $namaFile]);
    }

    public function perbaruiCv(int $id, string $namaFile): void
    {
        $this->ubah($id, ['file_cv' => $namaFile]);
    }

    public function perbaruiKtm(int $id, string $namaFile): void
    {
        $this->ubah($id, ['file_ktm' => $namaFile]);
    }

    public function perbaruiSuratPengantar(int $id, string $namaFile): void
    {
        $this->ubah($id, ['file_surat_pengantar' => $namaFile]);
    }

    /**
     * Simpan status karier. Kolom yang diisi berbeda-beda tergantung status,
     * dan kolom milik status lain sengaja dikosongkan supaya tidak ada sisa
     * data yang menyesatkan (misal nama perusahaan masih tersimpan padahal
     * mahasiswa sudah mengubah statusnya jadi "belum bekerja").
     */
    public function perbaruiStatusKarier(int $id, array $d): void
    {
        $status = $d['status_karier'];

        // Semua kolom dinolkan dulu, lalu diisi ulang sesuai status terpilih.
        $isi = [
            'status_karier'          => $status,
            'tempat_kerja'           => null,
            'posisi_kerja'           => null,
            'level_jabatan'          => null,
            'tanggal_mulai_kerja'    => null,
            'karier_fakultas'        => null,
            'karier_bidang_minat'    => null,
            'karier_rencana_posisi'  => null,
            'karier_tahap_studi'     => null,
            'karier_catatan'         => ($d['karier_catatan'] ?? '') ?: null,
            'karier_diperbarui_pada' => date('Y-m-d'),
        ];

        $ambil = static fn(array $src, string $k) => ($src[$k] ?? '') !== '' ? $src[$k] : null;

        switch ($status) {
            case 'bekerja':
                $isi['tempat_kerja']        = $ambil($d, 'tempat_kerja');
                $isi['posisi_kerja']        = $ambil($d, 'posisi_kerja');
                $isi['level_jabatan']       = $ambil($d, 'level_jabatan');
                $isi['tanggal_mulai_kerja'] = $ambil($d, 'tanggal_mulai_kerja');
                break;

            case 'wirausaha':
                $isi['tempat_kerja']        = $ambil($d, 'tempat_kerja');   // nama usaha
                $isi['posisi_kerja']        = $ambil($d, 'posisi_kerja');   // peran di usaha
                $isi['tanggal_mulai_kerja'] = $ambil($d, 'tanggal_mulai_kerja');
                break;

            case 'studi lanjut':
                $isi['tempat_kerja']        = $ambil($d, 'tempat_kerja');   // nama kampus
                $isi['karier_fakultas']     = $ambil($d, 'karier_fakultas');
                $isi['posisi_kerja']        = $ambil($d, 'posisi_kerja');   // program studi
                $isi['karier_tahap_studi']  = $ambil($d, 'karier_tahap_studi');
                $isi['tanggal_mulai_kerja'] = $ambil($d, 'tanggal_mulai_kerja');
                break;

            case 'mencari kerja':
                $isi['karier_bidang_minat']   = $ambil($d, 'karier_bidang_minat');
                $isi['karier_rencana_posisi'] = $ambil($d, 'karier_rencana_posisi');
                break;

            case 'belum bekerja':
            default:
                $isi['karier_bidang_minat'] = $ambil($d, 'karier_bidang_minat');
                break;
        }

        $this->ubah($id, $isi);
    }

    /**
     * Ringkasan status karier dalam satu kalimat, dipakai di tabel Admin dan
     * halaman Tracer Karier supaya isinya menyesuaikan status masing-masing.
     */
    public static function ringkasanKarier(array $m): string
    {
        $status = $m['status_karier'] ?? '';
        $gabung = static fn(array $bagian) => implode(', ', array_filter($bagian, static fn($x) => (string) $x !== ''));

        switch ($status) {
            case 'bekerja':
                return $gabung([$m['posisi_kerja'] ?? '', $m['tempat_kerja'] ?? '']) ?: 'Bekerja';
            case 'wirausaha':
                return $gabung([$m['posisi_kerja'] ?? '', $m['tempat_kerja'] ?? '']) ?: 'Wirausaha';
            case 'studi lanjut':
                $tahap = $m['karier_tahap_studi'] ?? '';
                $inti  = $gabung([$m['posisi_kerja'] ?? '', $m['karier_fakultas'] ?? '', $m['tempat_kerja'] ?? '']);
                return $inti === '' ? 'Studi lanjut' : $inti . ($tahap ? ' (' . $tahap . ')' : '');
            case 'mencari kerja':
                return $gabung([$m['karier_rencana_posisi'] ?? '', $m['karier_bidang_minat'] ?? '']) ?: 'Mencari kerja';
            case 'belum bekerja':
                return ($m['karier_bidang_minat'] ?? '') !== ''
                    ? 'Minat: ' . $m['karier_bidang_minat']
                    : 'Belum bekerja';
        }
        return '-';
    }

    /** Dipanggil otomatis dari Lamaran::terima() saat pelamar dinyatakan diterima. */
    public function tandaiDiterimaKerja(int $id, string $namaPerusahaan, string $posisi): void
    {
        $this->ubah($id, [
            'status_karier'          => 'bekerja',
            'tempat_kerja'           => $namaPerusahaan,
            'posisi_kerja'           => $posisi,
            'tanggal_mulai_kerja'    => date('Y-m-d'),
            'karier_diperbarui_pada' => date('Y-m-d'),
        ]);
    }

    /** Persentase kelengkapan profil untuk bilah progres di Dashboard. */
    public function kelengkapanProfil(array $mhs, int $jumlahProfilItem, int $jumlahSkill): int
    {
        $total = 6;
        $terisi = 0;
        if (!empty($mhs['foto'])) $terisi++;
        if (!empty($mhs['tentang'])) $terisi++;
        if (!empty($mhs['file_ktm'])) $terisi++;
        if (!empty($mhs['file_cv'])) $terisi++;
        if ($jumlahProfilItem > 0) $terisi++;
        if ($jumlahSkill > 0) $terisi++;
        return (int) round($terisi / $total * 100);
    }

    /* --------------------- untuk Admin: Kelola Pengguna & Tracer Karier --------------------- */

    public function semuaDenganFilter(array $filter = []): array
    {
        $where = ['1=1'];
        $params = [];
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'j.id = ?';
            $params[] = $filter['jurusan_id'];
        }
        if (!empty($filter['status_akun'])) {
            $where[] = 'p.status_akun = ?';
            $params[] = $filter['status_akun'];
        }
        if (!empty($filter['status_mahasiswa'])) {
            $where[] = 'm.status_mahasiswa = ?';
            $params[] = $filter['status_mahasiswa'];
        }
        if (!empty($filter['angkatan'])) {
            $where[] = 'm.angkatan = ?';
            $params[] = $filter['angkatan'];
        }
        if (!empty($filter['keyword'])) {
            $where[] = '(m.nama ILIKE ? OR m.nim ILIKE ?)';
            $params[] = '%' . $filter['keyword'] . '%';
            $params[] = '%' . $filter['keyword'] . '%';
        }
        $sql = 'SELECT m.*, p.email, p.status_akun, ps.nama AS nama_prodi, j.nama AS nama_jurusan
                FROM mahasiswa m
                JOIN pengguna p ON p.id = m.pengguna_id
                JOIN program_studi ps ON ps.id = m.program_studi_id
                JOIN jurusan j ON j.id = ps.jurusan_id
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY m.nama';
        return Database::fetchAll($sql, $params);
    }

    /** Daftar angkatan yang ada di data mahasiswa, terbaru dulu, untuk <select> filter. */
    /**
     * Daftar angkatan untuk dropdown filter.
     *
     * Kalau $jurusanId diisi, yang dikembalikan hanya angkatan yang benar-benar
     * punya mahasiswa di jurusan tersebut. Tujuannya supaya Admin tidak memilih
     * kombinasi jurusan dan angkatan yang pasti kosong hasilnya.
     */
    public function semuaAngkatan($jurusanId = null): array
    {
        if ($jurusanId !== null && $jurusanId !== '') {
            return array_column(Database::fetchAll(
                'SELECT DISTINCT m.angkatan
                 FROM mahasiswa m
                 JOIN program_studi ps ON ps.id = m.program_studi_id
                 WHERE ps.jurusan_id = ?
                 ORDER BY m.angkatan DESC',
                [(int) $jurusanId]
            ), 'angkatan');
        }

        return array_column(
            Database::fetchAll('SELECT DISTINCT angkatan FROM mahasiswa ORDER BY angkatan DESC'),
            'angkatan'
        );
    }

    /** Program studi yang ada di satu jurusan, untuk filter bertingkat. */
    public function prodiDiJurusan($jurusanId = null): array
    {
        if ($jurusanId !== null && $jurusanId !== '') {
            return Database::fetchAll(
                'SELECT id, nama, jenjang, jurusan_id FROM program_studi WHERE jurusan_id = ? ORDER BY jenjang, nama',
                [(int) $jurusanId]
            );
        }
        return Database::fetchAll('SELECT id, nama, jenjang, jurusan_id FROM program_studi ORDER BY jenjang, nama');
    }

    /**
     * Profil lengkap satu mahasiswa untuk halaman Admin (kelola pengguna ->
     * lihat profil). Menggabungkan data akun, prodi, dan jurusan.
     */
    public function profilLengkapUntukAdmin(int $mahasiswaId): ?array
    {
        return Database::fetch(
            'SELECT m.*, u.email, u.status_akun, u.dibuat_pada, u.terakhir_login,
                    ps.nama AS nama_prodi, ps.jenjang, j.nama AS nama_jurusan, j.id AS jurusan_id
             FROM mahasiswa m
             JOIN pengguna u       ON u.id = m.pengguna_id
             JOIN program_studi ps ON ps.id = m.program_studi_id
             JOIN jurusan j        ON j.id = ps.jurusan_id
             WHERE m.id = ?',
            [$mahasiswaId]
        );
    }

    /**
     * Menyusun syarat status mahasiswa untuk halaman Tracer Karier.
     *
     * Tracer memang dimaksudkan untuk alumni, jadi bawaannya tetap alumni
     * supaya angka seperti "55% alumni sudah bekerja" tidak berubah artinya.
     * Tetapi mahasiswa aktif juga boleh mengisi status kariernya, misalnya
     * yang sudah bekerja paruh waktu atau sudah diterima studi lanjut.
     * Datanya tidak boleh hilang begitu saja, jadi Admin bisa memilih
     * "Mahasiswa aktif" atau "Semua" lewat filter di halaman itu.
     */
    private function syaratStatusMahasiswa(array $filter): ?string
    {
        $pilihan = $filter['status_mahasiswa'] ?? 'alumni';
        if ($pilihan === 'semua') {
            return null;
        }
        if ($pilihan === 'aktif') {
            return "m.status_mahasiswa = 'aktif'";
        }
        return "m.status_mahasiswa = 'alumni'";
    }

    public function ringkasanStatusKarier(array $filter = []): array
    {
        $where = array_filter([$this->syaratStatusMahasiswa($filter)]) ?: ['TRUE'];
        $params = [];
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'j.id = ?';
            $params[] = $filter['jurusan_id'];
        }
        if (!empty($filter['angkatan'])) {
            $where[] = 'm.angkatan = ?';
            $params[] = $filter['angkatan'];
        }
        $sql = "SELECT COALESCE(m.status_karier, 'belum bekerja') AS status_karier, COUNT(*) AS jumlah
                FROM mahasiswa m
                JOIN program_studi ps ON ps.id = m.program_studi_id
                JOIN jurusan j ON j.id = ps.jurusan_id
                WHERE " . implode(' AND ', $where) . '
                GROUP BY status_karier ORDER BY jumlah DESC';
        return Database::fetchAll($sql, $params);
    }

    /** Sebaran bidang perusahaan tempat alumni bekerja (dari lamaran yang diterima), untuk Tracer Karier. */
    public function sebaranBidangKerja(array $filter = []): array
    {
        $where = array_filter([$this->syaratStatusMahasiswa($filter), "la.status = 'diterima'"]);
        $params = [];
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'j.id = ?';
            $params[] = $filter['jurusan_id'];
        }
        if (!empty($filter['angkatan'])) {
            $where[] = 'm.angkatan = ?';
            $params[] = $filter['angkatan'];
        }
        $sql = 'SELECT b.nama AS nama_bidang, COUNT(DISTINCT m.id) AS jumlah
                FROM mahasiswa m
                JOIN program_studi ps ON ps.id = m.program_studi_id
                JOIN jurusan j ON j.id = ps.jurusan_id
                JOIN lamaran la ON la.mahasiswa_id = m.id
                JOIN lowongan lo ON lo.id = la.lowongan_id
                JOIN bidang b ON b.id = lo.bidang_id
                WHERE ' . implode(' AND ', $where) . '
                GROUP BY b.nama ORDER BY jumlah DESC LIMIT 6';
        return Database::fetchAll($sql, $params);
    }

    /** Alumni dengan status karier yang paling baru diperbarui, untuk panel "Pembaruan terbaru" di Tracer Karier. */
    public function pembaruanTerbaru(array $filter = [], int $limit = 6): array
    {
        $where = array_filter([$this->syaratStatusMahasiswa($filter), 'm.karier_diperbarui_pada IS NOT NULL']);
        $params = [];
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'j.id = ?';
            $params[] = $filter['jurusan_id'];
        }
        if (!empty($filter['angkatan'])) {
            $where[] = 'm.angkatan = ?';
            $params[] = $filter['angkatan'];
        }
        $sql = 'SELECT m.id, m.nama, m.angkatan, m.status_karier, m.tempat_kerja, m.posisi_kerja, m.karier_diperbarui_pada,
                       ps.nama AS nama_prodi, ps.jenjang, j.nama AS nama_jurusan,
                       EXISTS (
                         SELECT 1 FROM lamaran la JOIN lowongan lo ON lo.id = la.lowongan_id
                         WHERE la.mahasiswa_id = m.id AND la.status = \'diterima\'
                           AND la.diperbarui_pada::date = m.karier_diperbarui_pada
                       ) AS dari_lamaran
                FROM mahasiswa m
                JOIN program_studi ps ON ps.id = m.program_studi_id
                JOIN jurusan j ON j.id = ps.jurusan_id
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY m.karier_diperbarui_pada DESC, m.id DESC LIMIT ?';
        $params[] = $limit;
        return Database::fetchAll($sql, $params);
    }
}