<?php
// ===== BACKEND · MODEL · Lamaran (tabel lamaran) =====================

class Lamaran extends Model
{
    protected string $tabel = 'lamaran';

    public const STATUS_FINAL = ['diterima', 'ditolak', 'dibatalkan'];

    /** Bug #6: lamaran final tidak boleh diproses lagi oleh perusahaan. */
    public static function sudahFinal(string $status): bool
    {
        return in_array($status, self::STATUS_FINAL, true);
    }

    // --- Mahasiswa: melamar ------------------------------------------
    public function sudahMelamar(int $mahasiswaId, int $lowonganId): bool
    {
        return Database::fetch(
            'SELECT 1 FROM lamaran WHERE mahasiswa_id = ? AND lowongan_id = ?',
            [$mahasiswaId, $lowonganId]
        ) !== null;
    }

    /**
     * Bug #4: syarat lowongan dicek ulang DI DALAM transaksi dengan baris
     * lowongan dikunci, sehingga lamaran tidak bisa masuk setelah deadline,
     * setelah kuota penuh, atau ketika dua klik datang bersamaan.
     */
    public function ajukan(int $mahasiswaId, int $lowonganId, array $d, array $snapshot, int $penggunaId): int
    {
        return Database::transaksi(function () use ($mahasiswaId, $lowonganId, $d, $snapshot, $penggunaId) {
            $l = Database::fetch(
                'SELECT l.*, pg.status_akun AS status_akun_perusahaan
                   FROM lowongan l JOIN perusahaan pr ON pr.id = l.perusahaan_id JOIN pengguna pg ON pg.id = pr.pengguna_id
                  WHERE l.id = ? FOR UPDATE OF l',
                [$lowonganId]
            );
            if (!$l || !Lowongan::bisaMenerimaLamaran($l)) {
                throw new RuntimeException($l ? Lowongan::alasanTidakMenerima($l) : 'Lowongan tidak ditemukan.');
            }
            if ($this->sudahMelamar($mahasiswaId, $lowonganId)) {
                throw new RuntimeException('Anda sudah pernah melamar lowongan ini.');
            }
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
            return $lamaranId;
        });
    }

    // --- Baca data ---------------------------------------------------
    public function cariDetail(int $id): ?array
    {
        return Database::fetch(
            'SELECT lm.*, l.posisi, l.perusahaan_id, l.kuota, l.terisi, l.status AS status_lowongan,
                    pr.nama_perusahaan, pr.pengguna_id AS perusahaan_pengguna_id,
                    m.nama AS nama_mahasiswa, m.pengguna_id AS mahasiswa_pengguna_id
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
             ORDER BY lm.tanggal_lamar DESC, lm.id DESC',
            [$mahasiswaId]
        );
    }

    // --- Perusahaan: daftar pelamar (revisi H & I) ---------------------
    private function klausaPerusahaan(int $perusahaanId, array $filter): array
    {
        $where = ['l.perusahaan_id = ?'];
        $params = [$perusahaanId];
        if (!empty($filter['lowongan_id'])) {
            $where[] = 'lm.lowongan_id = ?';
            $params[] = (int) $filter['lowongan_id'];
        }
        if (!empty($filter['status'])) {
            $where[] = 'lm.status = ?';
            $params[] = $filter['status'];
        }
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'j.id = ?';
            $params[] = (int) $filter['jurusan_id'];
        }
        if (!empty($filter['angkatan'])) {
            $where[] = 'm.angkatan = ?';
            $params[] = (int) $filter['angkatan'];
        }
        if (!empty($filter['keyword'])) {
            $where[] = '(m.nama ILIKE ? OR m.nim ILIKE ? OR l.posisi ILIKE ?)';
            $cari = '%' . $filter['keyword'] . '%';
            array_push($params, $cari, $cari, $cari);
        }
        [$w, $p] = self::klausaTanggal($filter);
        return [array_merge($where, $w), array_merge($params, $p)];
    }

    public function untukPerusahaan(int $perusahaanId, array $filter = [], int $limit = 0, int $offset = 0): array
    {
        [$where, $params] = $this->klausaPerusahaan($perusahaanId, $filter);
        $sql = 'SELECT lm.*, l.posisi, m.nama AS nama_mahasiswa, m.nim, m.foto, m.angkatan,
                       ps.nama AS nama_prodi, j.nama AS nama_jurusan
                FROM lamaran lm
                JOIN lowongan l ON l.id = lm.lowongan_id
                JOIN mahasiswa m ON m.id = lm.mahasiswa_id
                JOIN program_studi ps ON ps.id = m.program_studi_id
                JOIN jurusan j ON j.id = ps.jurusan_id
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY lm.tanggal_lamar DESC, lm.id DESC';
        if ($limit > 0) {
            $sql .= ' LIMIT ? OFFSET ?';
            $params[] = $limit;
            $params[] = $offset;
        }
        return Database::fetchAll($sql, $params);
    }

    public function hitungUntukPerusahaan(int $perusahaanId, array $filter = []): int
    {
        [$where, $params] = $this->klausaPerusahaan($perusahaanId, $filter);
        return (int) Database::fetch(
            'SELECT COUNT(*) AS n FROM lamaran lm
               JOIN lowongan l ON l.id = lm.lowongan_id
               JOIN mahasiswa m ON m.id = lm.mahasiswa_id
               JOIN program_studi ps ON ps.id = m.program_studi_id
               JOIN jurusan j ON j.id = ps.jurusan_id
              WHERE ' . implode(' AND ', $where),
            $params
        )['n'];
    }

    public function angkatanPelamarPerusahaan(int $perusahaanId): array
    {
        return array_column(Database::fetchAll(
            'SELECT DISTINCT m.angkatan FROM lamaran lm JOIN lowongan l ON l.id = lm.lowongan_id
               JOIN mahasiswa m ON m.id = lm.mahasiswa_id WHERE l.perusahaan_id = ? ORDER BY m.angkatan DESC',
            [$perusahaanId]
        ), 'angkatan');
    }

    // --- Ubah status lamaran -----------------------------------------
    public function batalkan(int $id, int $mahasiswaId, int $penggunaId): bool
    {
        return Database::transaksi(function () use ($id, $mahasiswaId, $penggunaId) {
            $baris = Database::fetch('SELECT status FROM lamaran WHERE id = ? AND mahasiswa_id = ? FOR UPDATE', [$id, $mahasiswaId]);
            if (!$baris || $baris['status'] !== 'diajukan') {
                return false;
            }
            $this->ubah($id, ['status' => 'dibatalkan', 'diperbarui_pada' => date('Y-m-d H:i:s')]);
            (new RiwayatLamaran())->catat($id, 'dibatalkan', $penggunaId, 'Dibatalkan oleh pelamar.');
            return true;
        });
    }

    /**
     * Saat perusahaan pertama kali membuka lamaran, status menjadi Screening.
     * Mengembalikan true HANYA sekali (saat benar-benar berubah), supaya
     * notifikasi ke pelamar tidak dobel walau halaman di-refresh (bug #7).
     */
    public function tandaiScreeningJikaBelum(int $id, int $penggunaId): bool
    {
        return Database::transaksi(function () use ($id, $penggunaId) {
            $baris = Database::fetch('SELECT status FROM lamaran WHERE id = ? FOR UPDATE', [$id]);
            if (!$baris || $baris['status'] !== 'diajukan') {
                return false;
            }
            $this->ubah($id, ['status' => 'screening', 'diperbarui_pada' => date('Y-m-d H:i:s')]);
            (new RiwayatLamaran())->catat($id, 'screening', $penggunaId, 'CV mulai ditinjau perusahaan.');
            return true;
        });
    }

    /** Kunci baris lamaran & pastikan belum final. */
    private function kunciBelumFinal(int $id): array
    {
        $baris = Database::fetch('SELECT * FROM lamaran WHERE id = ? FOR UPDATE', [$id]);
        if (!$baris) {
            throw new RuntimeException('Lamaran tidak ditemukan.');
        }
        if (self::sudahFinal($baris['status'])) {
            throw new RuntimeException('Lamaran ini sudah berstatus ' . labelStatusLamaran($baris['status'])[0]
                . ', jadi tidak bisa diproses lagi.');
        }
        return $baris;
    }

    public function jadwalkanInterview(int $lamaranId, int $penggunaId, array $d): bool
    {
        return Database::transaksi(function () use ($lamaranId, $penggunaId, $d) {
            $baris = $this->kunciBelumFinal($lamaranId);
            $sudahAda = (new Interview())->untukLamaran($lamaranId) !== null;
            (new Interview())->jadwalkan($lamaranId, $d);
            $this->ubah($lamaranId, ['status' => 'interview', 'diperbarui_pada' => date('Y-m-d H:i:s')]);
            (new RiwayatLamaran())->catat(
                $lamaranId, 'interview', $penggunaId,
                ($sudahAda ? 'Jadwal interview diubah: ' : 'Interview dijadwalkan: ') . tanggalIndo($d['tanggal']) . ' ' . substr($d['jam'], 0, 5)
                . ' (' . $d['mode'] . ')'
            );
            return $sudahAda || $baris['status'] === 'interview';
        });
    }

    public function tolak(int $lamaranId, int $penggunaId, string $catatan): void
    {
        Database::transaksi(function () use ($lamaranId, $penggunaId, $catatan) {
            $this->kunciBelumFinal($lamaranId);
            $this->ubah($lamaranId, [
                'status'             => 'ditolak',
                'catatan_perusahaan' => mb_substr($catatan, 0, 500),
                'diperbarui_pada'    => date('Y-m-d H:i:s'),
            ]);
            (new RiwayatLamaran())->catat($lamaranId, 'ditolak', $penggunaId, mb_substr($catatan, 0, 500));
        });
        // Notifikasi dikirim oleh controller lewat NotifikasiService (tidak dobel).
    }

    public function terima(int $lamaranId, int $penggunaId): void
    {
        Database::transaksi(function () use ($lamaranId, $penggunaId) {
            $this->kunciBelumFinal($lamaranId);
            $lamaran = $this->cariDetail($lamaranId);
            $l = Database::fetch('SELECT terisi, kuota FROM lowongan WHERE id = ? FOR UPDATE', [$lamaran['lowongan_id']]);
            if ((int) $l['terisi'] >= (int) $l['kuota']) {
                throw new RuntimeException('Kuota lowongan ini sudah penuh. Naikkan kuota lewat tombol Perpanjang di Lowongan Saya bila ingin menerima pelamar lagi.');
            }
            $this->ubah($lamaranId, ['status' => 'diterima', 'diperbarui_pada' => date('Y-m-d H:i:s')]);
            (new RiwayatLamaran())->catat($lamaranId, 'diterima', $penggunaId, 'Pelamar dinyatakan diterima.');
            (new Mahasiswa())->tandaiDiterimaKerja((int) $lamaran['mahasiswa_id'], $lamaran['nama_perusahaan'], $lamaran['posisi']);
            (new Lowongan())->tambahTerisi((int) $lamaran['lowongan_id']);
        });
    }

    // --- Rekap admin (revisi I) --------------------------------------
    /**
     * Rentang tanggal lamar (WIB), inklusif: "sampai 31 Okt" berarti
     * sampai 31 Okt pukul 23.59.59. Bila terbalik, otomatis ditukar.
     */
    public static function rapikanRentang(string $dari, string $sampai): array
    {
        $dari = validasiTanggal($dari) ? $dari : '';
        $sampai = validasiTanggal($sampai) ? $sampai : '';
        if ($dari !== '' && $sampai !== '' && $dari > $sampai) {
            [$dari, $sampai] = [$sampai, $dari];
        }
        return [$dari, $sampai];
    }

    private static function klausaTanggal(array $filter): array
    {
        $where = [];
        $params = [];
        [$dari, $sampai] = self::rapikanRentang((string) ($filter['tanggal_dari'] ?? ''), (string) ($filter['tanggal_sampai'] ?? ''));
        if ($dari !== '') {
            $where[] = 'lm.tanggal_lamar >= ?::date';
            $params[] = $dari;
        }
        if ($sampai !== '') {
            $where[] = "lm.tanggal_lamar < (?::date + interval '1 day')";
            $params[] = $sampai;
        }
        return [$where, $params];
    }

    private function klausaRekap(array $filter): array
    {
        $where = ['1=1'];
        $params = [];
        if (!empty($filter['q'])) {
            $where[] = '(lm.nama_mahasiswa ILIKE ? OR lm.nama_perusahaan ILIKE ? OR lm.posisi ILIKE ? OR lm.nim ILIKE ?)';
            $cari = '%' . trim($filter['q']) . '%';
            array_push($params, $cari, $cari, $cari, $cari);
        }
        if (!empty($filter['perusahaan_id'])) {
            $where[] = 'lm.perusahaan_id = ?';
            $params[] = (int) $filter['perusahaan_id'];
        }
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'lm.jurusan_id = ?';
            $params[] = (int) $filter['jurusan_id'];
        }
        if (!empty($filter['prodi_id'])) {
            $where[] = 'lm.prodi_id = ?';
            $params[] = (int) $filter['prodi_id'];
        }
        if (!empty($filter['angkatan'])) {
            $where[] = 'lm.angkatan = ?';
            $params[] = (int) $filter['angkatan'];
        }
        if (!empty($filter['mahasiswa_id'])) {
            $where[] = 'lm.mahasiswa_id = ?';
            $params[] = (int) $filter['mahasiswa_id'];
        }
        if (!empty($filter['status'])) {
            $where[] = 'lm.status = ?';     // bug #2: kolom dikualifikasi (lamaran.status, bukan lowongan.status)
            $params[] = $filter['status'];
        }
        [$w, $p] = self::klausaTanggal($filter);
        return [array_merge($where, $w), array_merge($params, $p)];
    }

    /** Bab 3: join 6 tabel didefinisikan sekali sebagai VIEW (database/07-...sql). */
    private const FROM_REKAP = ' FROM v_rekap_lamaran lm ';

    /** $limit 0 = semua baris (untuk PDF). */
    public function rekapAdmin(array $filter = [], int $limit = 0, int $offset = 0): array
    {
        [$where, $params] = $this->klausaRekap($filter);
        $sql = 'SELECT lm.*'
             . self::FROM_REKAP . 'WHERE ' . implode(' AND ', $where) . '
                ORDER BY lm.tanggal_lamar DESC, lm.id DESC';
        if ($limit > 0) {
            $sql .= ' LIMIT ? OFFSET ?';
            $params[] = $limit;
            $params[] = $offset;
        }
        return Database::fetchAll($sql, $params);
    }

    /** Ringkasan dihitung dari SELURUH data terfilter, bukan hanya halaman yang tampil. */
    public function ringkasanRekap(array $filter = []): array
    {
        [$where, $params] = $this->klausaRekap($filter);
        $r = Database::fetch(
            "SELECT COUNT(*) AS total,
                    COUNT(*) FILTER (WHERE lm.status = 'diajukan')   AS diajukan,
                    COUNT(*) FILTER (WHERE lm.status = 'screening')  AS screening,
                    COUNT(*) FILTER (WHERE lm.status = 'interview')  AS interview,
                    COUNT(*) FILTER (WHERE lm.status = 'diterima')   AS diterima,
                    COUNT(*) FILTER (WHERE lm.status = 'ditolak')    AS ditolak,
                    COUNT(*) FILTER (WHERE lm.status = 'dibatalkan') AS dibatalkan,
                    COUNT(DISTINCT lm.mahasiswa_id) AS pelamar_unik,
                    COUNT(DISTINCT lm.perusahaan_id) AS perusahaan_unik"
            . self::FROM_REKAP . 'WHERE ' . implode(' AND ', $where),
            $params
        );
        return array_map('intval', $r ?: []);
    }

    public function rekapPerPerusahaan(array $filter = []): array
    {
        [$where, $params] = $this->klausaRekap($filter);
        return Database::fetchAll(
            "SELECT lm.perusahaan_id AS id, lm.nama_perusahaan, COUNT(*) AS total,
                    COUNT(*) FILTER (WHERE lm.status = 'diterima') AS diterima,
                    COUNT(*) FILTER (WHERE lm.status = 'ditolak')  AS ditolak,
                    COUNT(*) FILTER (WHERE lm.status IN ('diajukan','screening','interview')) AS diproses"
            . self::FROM_REKAP . 'WHERE ' . implode(' AND ', $where) . '
              GROUP BY lm.perusahaan_id, lm.nama_perusahaan ORDER BY total DESC, lm.nama_perusahaan',
            $params
        );
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
