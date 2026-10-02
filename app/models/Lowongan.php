<?php
/**
 * Model tabel lowongan
 * PIC   : Atha Rasya Farras (Modul Operator dan Career Center)
 * Status: DIISI.
 */

class Lowongan extends Model
{
    protected string $tabel = 'lowongan';

    public function tutupOtomatisJikaLewatBatas(): void
    {
        Database::execute(
            "UPDATE lowongan SET status = 'ditutup', diperbarui_pada = now()
             WHERE status = 'aktif' AND batas_lamaran < CURRENT_DATE"
        );
    }

    public function buat(int $perusahaanId, array $d): int
    {
        return $this->simpan([
            'perusahaan_id'    => $perusahaanId,
            'bidang_id'        => $d['bidang_id'],
            'posisi'           => $d['posisi'],
            'jenis_pekerjaan'  => $d['jenis_pekerjaan'],
            'sistem_kerja'     => $d['sistem_kerja'],
            'lokasi'           => $d['lokasi'],
            'gaji'             => $d['gaji'] ?: null,
            'kuota'            => $d['kuota'],
            'batas_lamaran'    => $d['batas_lamaran'],
            'deskripsi'        => $d['deskripsi'],
            'kualifikasi'      => $d['kualifikasi'],
            'skill_dibutuhkan' => $d['skill_dibutuhkan'] ?: null,
            'pamflet'          => $d['pamflet'],
            'kode_pratinjau'   => buatKodePratinjau(),
            'status'           => 'aktif',
        ]);
    }

    public function perbarui(int $id, array $d): void
    {
        $this->ubah($id, [
            'bidang_id'        => $d['bidang_id'],
            'posisi'           => $d['posisi'],
            'jenis_pekerjaan'  => $d['jenis_pekerjaan'],
            'sistem_kerja'     => $d['sistem_kerja'],
            'lokasi'           => $d['lokasi'],
            'gaji'             => $d['gaji'] ?: null,
            'kuota'            => $d['kuota'],
            'batas_lamaran'    => $d['batas_lamaran'],
            'deskripsi'        => $d['deskripsi'],
            'kualifikasi'      => $d['kualifikasi'],
            'skill_dibutuhkan' => $d['skill_dibutuhkan'] ?: null,
            'diperbarui_pada'  => date('Y-m-d H:i:s'),
        ]);
    }

    public function perbaruiPamflet(int $id, string $namaFile): void
    {
        $this->ubah($id, ['pamflet' => $namaFile, 'diperbarui_pada' => date('Y-m-d H:i:s')]);
    }

    /* --------------------- jurusan sasaran --------------------- */

    public function jurusanSasaran(int $lowonganId): array
    {
        return Database::fetchAll(
            'SELECT j.id, j.nama FROM lowongan_jurusan lj
             JOIN jurusan j ON j.id = lj.jurusan_id
             WHERE lj.lowongan_id = ? ORDER BY j.nama',
            [$lowonganId]
        );
    }

    public function setJurusanSasaran(int $lowonganId, array $jurusanIds): void
    {
        Database::beginTransaction();
        try {
            Database::execute('DELETE FROM lowongan_jurusan WHERE lowongan_id = ?', [$lowonganId]);
            foreach (array_unique(array_map('intval', $jurusanIds)) as $jurusanId) {
                Database::execute(
                    'INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) VALUES (?, ?)',
                    [$lowonganId, $jurusanId]
                );
            }
            Database::commit();
        } catch (Throwable $e) {
            Database::rollBack();
            throw $e;
        }
    }

    /* --------------------- ambil detail --------------------- */

    public function cariDetail(int $id): ?array
    {
        return Database::fetch(
            'SELECT l.*, pr.nama_perusahaan, pr.logo, pr.kota AS kota_perusahaan,
                    pr.deskripsi AS deskripsi_perusahaan, pr.bidang_usaha, b.nama AS nama_bidang
             FROM lowongan l
             JOIN perusahaan pr ON pr.id = l.perusahaan_id
             JOIN bidang b ON b.id = l.bidang_id
             WHERE l.id = ?',
            [$id]
        );
    }

    public function cariByKodePratinjau(string $kode): ?array
    {
        return Database::fetch(
            'SELECT l.*, pr.nama_perusahaan, pr.logo, b.nama AS nama_bidang
             FROM lowongan l
             JOIN perusahaan pr ON pr.id = l.perusahaan_id
             JOIN bidang b ON b.id = l.bidang_id
             WHERE l.kode_pratinjau = ?',
            [$kode]
        );
    }

    public function milikPerusahaan(int $perusahaanId): array
    {
        return Database::fetchAll(
            'SELECT l.*, b.nama AS nama_bidang,
                    (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = l.id) AS jumlah_pelamar
             FROM lowongan l JOIN bidang b ON b.id = l.bidang_id
             WHERE l.perusahaan_id = ? ORDER BY l.dibuat_pada DESC',
            [$perusahaanId]
        );
    }

    /** Daftar nilai lokasi unik dari lowongan aktif, untuk mengisi dropdown "Semua lokasi". */
    public function lokasiUnik(): array
    {
        return array_column(Database::fetchAll(
            "SELECT DISTINCT lokasi FROM lowongan
             WHERE status = 'aktif' AND batas_lamaran >= CURRENT_DATE
             ORDER BY lokasi"
        ), 'lokasi');
    }

    /* --------------------- pencarian mahasiswa/alumni --------------------- */

    /**
     * Sebelumnya bernama cari(array $filter, ...) -- bentrok dengan
     * Model::cari(int $id): ?array milik induknya (dipakai di tempat lain,
     * mis. AdminController::nonaktifkanLowongan()). Sekarang diberi nama
     * sendiri biar gak bentrok.
     */
    public function cariDenganFilter(array $filter, int $limit = 20, int $offset = 0): array
    {
        [$where, $params] = $this->klausaFilter($filter);
        $urutan = ($filter['urutan'] ?? '') === 'batas_lamaran' ? 'l.batas_lamaran ASC' : 'l.dibuat_pada DESC';

        $sql = 'SELECT l.*, pr.nama_perusahaan, pr.logo, b.nama AS nama_bidang
                FROM lowongan l
                JOIN perusahaan pr ON pr.id = l.perusahaan_id
                JOIN bidang b ON b.id = l.bidang_id
                WHERE ' . implode(' AND ', $where) . "
                ORDER BY {$urutan}
                LIMIT ? OFFSET ?";
        $params[] = $limit;
        $params[] = $offset;
        return Database::fetchAll($sql, $params);
    }

    public function hitungCari(array $filter): int
    {
        [$where, $params] = $this->klausaFilter($filter);
        $sql = 'SELECT COUNT(*) AS jumlah FROM lowongan l
                JOIN perusahaan pr ON pr.id = l.perusahaan_id
                WHERE ' . implode(' AND ', $where);
        $baris = Database::fetch($sql, $params);
        return (int) ($baris['jumlah'] ?? 0);
    }

    private function klausaFilter(array $filter): array
    {
        $where = ["l.status = 'aktif'", 'l.batas_lamaran >= CURRENT_DATE'];
        $params = [];
        if (!empty($filter['keyword'])) {
            $where[] = '(l.posisi ILIKE ? OR pr.nama_perusahaan ILIKE ?)';
            $params[] = '%' . $filter['keyword'] . '%';
            $params[] = '%' . $filter['keyword'] . '%';
        }
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'EXISTS (SELECT 1 FROM lowongan_jurusan lj WHERE lj.lowongan_id = l.id AND lj.jurusan_id = ?)';
            $params[] = $filter['jurusan_id'];
        }
        if (!empty($filter['bidang_id'])) {
            $where[] = 'l.bidang_id = ?';
            $params[] = $filter['bidang_id'];
        }
        if (!empty($filter['lokasi'])) {
            $where[] = 'l.lokasi = ?';
            $params[] = $filter['lokasi'];
        }
        if (!empty($filter['jenis_pekerjaan'])) {
            $where[] = 'l.jenis_pekerjaan = ?';
            $params[] = $filter['jenis_pekerjaan'];
        }
        return [$where, $params];
    }

    public function rekomendasiUntuk(int $mahasiswaId, int $limit = 5): array
    {
        return Database::fetchAll(
            "SELECT DISTINCT l.*, pr.nama_perusahaan, pr.logo
             FROM lowongan l
             JOIN perusahaan pr ON pr.id = l.perusahaan_id
             JOIN mahasiswa_minat mm ON mm.bidang_id = l.bidang_id
             WHERE mm.mahasiswa_id = ? AND l.status = 'aktif' AND l.batas_lamaran >= CURRENT_DATE
             ORDER BY l.dibuat_pada DESC LIMIT " . (int) $limit,
            [$mahasiswaId]
        );
    }

    /* --------------------- perubahan kuota & status --------------------- */

    public function tambahTerisi(int $id): void
    {
        Database::execute(
            "UPDATE lowongan SET
                terisi = terisi + 1,
                status = CASE WHEN terisi + 1 >= kuota THEN 'ditutup' ELSE status END,
                diperbarui_pada = now()
             WHERE id = ?",
            [$id]
        );
    }

    public function tutupManual(int $id): void
    {
        $this->ubah($id, ['status' => 'ditutup', 'diperbarui_pada' => date('Y-m-d H:i:s')]);
    }

    /**
     * Membuka kembali lowongan yang sudah ditutup, dengan batas lamaran baru.
     * Status dikembalikan ke aktif supaya lowongannya tayang lagi dan bisa
     * menerima lamaran. Kolom alasan_nonaktif ikut dikosongkan, karena
     * lowongan ini sudah tidak dalam keadaan ditutup maupun dinonaktifkan.
     */
    public function perpanjang(int $id, string $batasLamaranBaru): void
    {
        $this->ubah($id, [
            'status'          => 'aktif',
            'batas_lamaran'   => $batasLamaranBaru,
            'alasan_nonaktif' => null,
            'diperbarui_pada' => date('Y-m-d H:i:s'),
        ]);
    }

    public function nonaktifkan(int $id, string $alasan): void
    {
        $this->ubah($id, [
            'status'          => 'nonaktif',
            'alasan_nonaktif' => $alasan,
            'diperbarui_pada' => date('Y-m-d H:i:s'),
        ]);
    }

    /* --------------------- untuk Admin: Monitoring & Kirim Loker --------------------- */

    public function semuaDenganFilter(array $filter = []): array
    {
        $where = ['1=1'];
        $params = [];
        if (!empty($filter['status'])) {
            $where[] = 'l.status = ?';
            $params[] = $filter['status'];
        }
        if (!empty($filter['bidang_id'])) {
            $where[] = 'l.bidang_id = ?';
            $params[] = $filter['bidang_id'];
        }
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'EXISTS (SELECT 1 FROM lowongan_jurusan lj WHERE lj.lowongan_id = l.id AND lj.jurusan_id = ?)';
            $params[] = $filter['jurusan_id'];
        }
        $sql = 'SELECT l.*, pr.nama_perusahaan, b.nama AS nama_bidang
                FROM lowongan l
                JOIN perusahaan pr ON pr.id = l.perusahaan_id
                JOIN bidang b ON b.id = l.bidang_id
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY l.dibuat_pada DESC';
        return Database::fetchAll($sql, $params);
    }

    /** Lowongan aktif yang bisa dipilih di halaman Kirim Loker ke Jurusan. */
    public function aktifUntukDikirim(): array
    {
        return Database::fetchAll(
            "SELECT l.*, pr.nama_perusahaan
             FROM lowongan l JOIN perusahaan pr ON pr.id = l.perusahaan_id
             WHERE l.status = 'aktif' AND l.batas_lamaran >= CURRENT_DATE
             ORDER BY l.dibuat_pada DESC"
        );
    }

    /**
     * Lowongan terbaru yang masih menerima lamaran, untuk ditampilkan di
     * beranda publik. Tidak memerlukan login, jadi kolom yang diambil hanya
     * yang memang boleh dilihat umum.
     */
    public function terbaruUntukPublik(int $batas = 6): array
    {
        return Database::fetchAll(
            "SELECT l.id, l.posisi, l.jenis_pekerjaan, l.sistem_kerja, l.lokasi,
                    l.batas_lamaran, l.kode_pratinjau,
                    pr.nama_perusahaan, pr.logo,
                    string_agg(DISTINCT j.nama, ', ' ORDER BY j.nama) AS jurusan_sasaran
               FROM lowongan l
               JOIN perusahaan pr ON pr.id = l.perusahaan_id
               JOIN pengguna p ON p.id = pr.pengguna_id
               LEFT JOIN lowongan_jurusan lj ON lj.lowongan_id = l.id
               LEFT JOIN jurusan j ON j.id = lj.jurusan_id
              WHERE l.status = 'aktif'
                AND l.batas_lamaran >= CURRENT_DATE
                AND p.status_akun = 'aktif'
              GROUP BY l.id, pr.nama_perusahaan, pr.logo
              ORDER BY l.dibuat_pada DESC, l.id DESC
              LIMIT ?",
            [$batas]
        );
    }
}
