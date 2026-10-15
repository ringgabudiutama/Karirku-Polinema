<?php
// ===== BACKEND · MODEL · Lamaran (tabel lamaran) =====================

class Lamaran extends Model
{
    protected string $tabel = 'lamaran';

    // --- Mahasiswa: melamar ------------------------------------------
    public function sudahMelamar(int $mahasiswaId, int $lowonganId): bool
    {
        return Database::fetch(
            'SELECT 1 FROM lamaran WHERE mahasiswa_id = ? AND lowongan_id = ?',
            [$mahasiswaId, $lowonganId]
        ) !== null;
    }

    public function ajukan(int $mahasiswaId, int $lowonganId, array $d, array $snapshot, int $penggunaId): int
    {
        Database::beginTransaction();
        try {
            $lamaranId = $this->simpan([
                'mahasiswa_id'         => $mahasiswaId,
                'lowongan_id'          => $lowonganId,
                'status'               => 'diajukan',
                'jenis_cv'             => $d['jenis_cv'],
                'file_cv'              => $d['file_cv'],
                'file_ktm'             => $d['file_ktm'],
                'file_surat_pengantar' => $d['file_surat_pengantar'],
                'catatan_pelamar'      => $d['catatan_pelamar'] ?: null,
                'snapshot_profil'      => json_encode($snapshot, JSON_UNESCAPED_UNICODE),
            ]);

            (new RiwayatLamaran())->catat($lamaranId, 'diajukan', $penggunaId, 'Lamaran diajukan oleh pelamar.');

            Database::commit();
            return $lamaranId;
        } catch (Throwable $e) {
            Database::rollBack();
            throw $e;
        }
    }

    // --- Baca data ---------------------------------------------------
    public function cariDetail(int $id): ?array
    {
        return Database::fetch(
            'SELECT lm.*, l.posisi, l.perusahaan_id, l.kuota, l.terisi,
                    pr.nama_perusahaan, m.nama AS nama_mahasiswa, m.pengguna_id AS mahasiswa_pengguna_id
             FROM lamaran lm
             JOIN lowongan l ON l.id = lm.lowongan_id
             JOIN perusahaan pr ON pr.id = l.perusahaan_id
             JOIN mahasiswa m ON m.id = lm.mahasiswa_id
             WHERE lm.id = ?',
            [$id]
        );
    }

    public function milikMahasiswa(int $mahasiswaId): array
    {
        return Database::fetchAll(
            'SELECT lm.*, l.posisi, l.batas_lamaran, pr.nama_perusahaan, pr.logo,
                    iv.tanggal AS interview_tanggal, iv.jam AS interview_jam,
                    iv.mode AS interview_mode, iv.lokasi_tautan AS interview_lokasi,
                    iv.tempat AS interview_tempat, iv.ruangan AS interview_ruangan,
                    iv.dresscode AS interview_dresscode, iv.yang_dibawa AS interview_yang_dibawa,
                    iv.narahubung AS interview_narahubung, iv.catatan AS interview_catatan
             FROM lamaran lm
             JOIN lowongan l ON l.id = lm.lowongan_id
             JOIN perusahaan pr ON pr.id = l.perusahaan_id
             LEFT JOIN interview iv ON iv.lamaran_id = lm.id
             WHERE lm.mahasiswa_id = ?
             ORDER BY lm.tanggal_lamar DESC',
            [$mahasiswaId]
        );
    }

    public function untukLowongan(int $lowonganId, ?string $statusFilter = null): array
    {
        $sql = 'SELECT lm.*, m.nama AS nama_mahasiswa, m.foto, m.status_mahasiswa,
                       ps.nama AS nama_prodi, j.nama AS nama_jurusan
                FROM lamaran lm
                JOIN mahasiswa m ON m.id = lm.mahasiswa_id
                JOIN program_studi ps ON ps.id = m.program_studi_id
                JOIN jurusan j ON j.id = ps.jurusan_id
                WHERE lm.lowongan_id = ?';
        $params = [$lowonganId];
        if ($statusFilter) {
            $sql .= ' AND lm.status = ?';
            $params[] = $statusFilter;
        }
        $sql .= ' ORDER BY lm.tanggal_lamar DESC';
        return Database::fetchAll($sql, $params);
    }

    public function untukPerusahaan(int $perusahaanId, array $filter = []): array
    {
        $where = ['l.perusahaan_id = ?'];
        $params = [$perusahaanId];
        if (!empty($filter['lowongan_id'])) {
            $where[] = 'lm.lowongan_id = ?';
            $params[] = $filter['lowongan_id'];
        }
        if (!empty($filter['status'])) {
            $where[] = 'lm.status = ?';
            $params[] = $filter['status'];
        }
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'j.id = ?';
            $params[] = $filter['jurusan_id'];
        }
        $sql = 'SELECT lm.*, l.posisi, m.nama AS nama_mahasiswa, m.foto,
                       ps.nama AS nama_prodi, j.nama AS nama_jurusan
                FROM lamaran lm
                JOIN lowongan l ON l.id = lm.lowongan_id
                JOIN mahasiswa m ON m.id = lm.mahasiswa_id
                JOIN program_studi ps ON ps.id = m.program_studi_id
                JOIN jurusan j ON j.id = ps.jurusan_id
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY lm.tanggal_lamar DESC';
        return Database::fetchAll($sql, $params);
    }

    // --- Ubah status lamaran -----------------------------------------
    public function batalkan(int $id, int $mahasiswaId, int $penggunaId): bool
    {
        $baris = Database::fetch('SELECT status FROM lamaran WHERE id = ? AND mahasiswa_id = ?', [$id, $mahasiswaId]);
        if (!$baris || $baris['status'] !== 'diajukan') {
            return false;
        }
        Database::beginTransaction();
        try {
            $this->ubah($id, ['status' => 'dibatalkan', 'diperbarui_pada' => date('Y-m-d H:i:s')]);
            (new RiwayatLamaran())->catat($id, 'dibatalkan', $penggunaId, 'Dibatalkan oleh pelamar.');
            Database::commit();
            return true;
        } catch (Throwable $e) {
            Database::rollBack();
            throw $e;
        }
    }

    public function tandaiScreeningJikaBelum(int $id, int $penggunaId): void
    {
        $baris = Database::fetch('SELECT status FROM lamaran WHERE id = ?', [$id]);
        if (!$baris || $baris['status'] !== 'diajukan') {
            return;
        }
        Database::beginTransaction();
        try {
            $this->ubah($id, ['status' => 'screening', 'diperbarui_pada' => date('Y-m-d H:i:s')]);
            (new RiwayatLamaran())->catat($id, 'screening', $penggunaId, 'CV mulai ditinjau perusahaan.');
            Database::commit();
        } catch (Throwable $e) {
            Database::rollBack();
            throw $e;
        }
    }

    public function jadwalkanInterview(int $lamaranId, int $penggunaId, array $d): void
    {
        Database::beginTransaction();
        try {
            (new Interview())->jadwalkan($lamaranId, $d);
            $this->ubah($lamaranId, ['status' => 'interview', 'diperbarui_pada' => date('Y-m-d H:i:s')]);
            (new RiwayatLamaran())->catat(
                $lamaranId, 'interview', $penggunaId,
                'Interview dijadwalkan: ' . $d['tanggal'] . ' ' . $d['jam']
            );
            Database::commit();
        } catch (Throwable $e) {
            Database::rollBack();
            throw $e;
        }
    }

    public function tolak(int $lamaranId, int $penggunaId, string $catatan): void
    {
        Database::beginTransaction();
        try {
            $this->ubah($lamaranId, [
                'status'             => 'ditolak',
                'catatan_perusahaan' => $catatan,
                'diperbarui_pada'    => date('Y-m-d H:i:s'),
            ]);
            (new RiwayatLamaran())->catat($lamaranId, 'ditolak', $penggunaId, $catatan);
            Database::commit();
        } catch (Throwable $e) {
            Database::rollBack();
            throw $e;
        }

        $baris = $this->cariDetail($lamaranId);
        if ($baris) {
            (new Notifikasi())->buat(
                (int) $baris['mahasiswa_pengguna_id'],
                'lamaran_ditolak',
                'Lamaran belum berhasil kali ini',
                'Lamaran Anda untuk ' . $baris['posisi'] . ' di ' . $baris['nama_perusahaan'] . ' ditolak. Alasan: ' . $catatan,
                'lamaran/lamaran-saya'
            );
        }
    }

    public function terima(int $lamaranId, int $penggunaId): void
    {
        $lamaran = $this->cariDetail($lamaranId);
        if (!$lamaran) {
            throw new RuntimeException('Lamaran tidak ditemukan.');
        }

        Database::beginTransaction();
        try {
            $this->ubah($lamaranId, ['status' => 'diterima', 'diperbarui_pada' => date('Y-m-d H:i:s')]);
            (new RiwayatLamaran())->catat($lamaranId, 'diterima', $penggunaId, 'Pelamar dinyatakan diterima.');

            (new Mahasiswa())->tandaiDiterimaKerja(
                (int) $lamaran['mahasiswa_id'],
                $lamaran['nama_perusahaan'],
                $lamaran['posisi']
            );

            (new Lowongan())->tambahTerisi((int) $lamaran['lowongan_id']);

            Database::commit();
        } catch (Throwable $e) {
            Database::rollBack();
            throw $e;
        }

        (new Notifikasi())->buat(
            (int) $lamaran['mahasiswa_pengguna_id'],
            'lamaran_diterima',
            'Selamat! Lamaran Anda diterima',
            'Anda diterima sebagai ' . $lamaran['posisi'] . ' di ' . $lamaran['nama_perusahaan'] . '.',
            'lamaran/lamaran-saya'
        );
    }

    // --- Rekap admin -------------------------------------------------
    public function rekapAdmin(array $filter = []): array
    {
        $where = ['1=1'];
        $params = [];
        if (!empty($filter['q'])) {
            $where[] = '(m.nama ILIKE ? OR pr.nama_perusahaan ILIKE ? OR l.posisi ILIKE ? OR m.nim ILIKE ?)';
            $cari = '%' . trim($filter['q']) . '%';
            array_push($params, $cari, $cari, $cari, $cari);
        }
        if (!empty($filter['perusahaan_id'])) {
            $where[] = 'l.perusahaan_id = ?';
            $params[] = $filter['perusahaan_id'];
        }
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'j.id = ?';
            $params[] = $filter['jurusan_id'];
        }
        if (!empty($filter['prodi_id'])) {
            $where[] = 'ps.id = ?';
            $params[] = $filter['prodi_id'];
        }
        if (!empty($filter['angkatan'])) {
            $where[] = 'm.angkatan = ?';
            $params[] = $filter['angkatan'];
        }
        if (!empty($filter['mahasiswa_id'])) {
            $where[] = 'lm.mahasiswa_id = ?';
            $params[] = $filter['mahasiswa_id'];
        }
        if (!empty($filter['status'])) {
            $where[] = 'lm.status = ?';
            $params[] = $filter['status'];
        }
        if (!empty($filter['bulan'])) {
            $where[] = "to_char(lm.tanggal_lamar, 'YYYY-MM') = ?";
            $params[] = $filter['bulan'];
        }
        $sql = 'SELECT lm.*, l.posisi, pr.nama_perusahaan, m.nama AS nama_mahasiswa, m.angkatan,
                       ps.id AS prodi_id, ps.nama AS nama_prodi, j.nama AS nama_jurusan
                FROM lamaran lm
                JOIN lowongan l ON l.id = lm.lowongan_id
                JOIN perusahaan pr ON pr.id = l.perusahaan_id
                JOIN mahasiswa m ON m.id = lm.mahasiswa_id
                JOIN program_studi ps ON ps.id = m.program_studi_id
                JOIN jurusan j ON j.id = ps.jurusan_id
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY lm.tanggal_lamar DESC';
        return Database::fetchAll($sql, $params);
    }

    public function bulanTersedia(): array
    {
        $namaBulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        $baris = Database::fetchAll(
            "SELECT DISTINCT to_char(tanggal_lamar, 'YYYY-MM') AS bulan
             FROM lamaran ORDER BY bulan DESC"
        );
        $hasil = [];
        foreach ($baris as $b) {
            [$tahun, $bln] = explode('-', $b['bulan']);
            $hasil[] = ['nilai' => $b['bulan'], 'label' => $namaBulan[(int) $bln] . ' ' . $tahun];
        }
        return $hasil;
    }
}
