<?php
// ===== BACKEND · MODEL · Lowongan (tabel lowongan) ===================
//
// Alur status (revisi M):
//   menunggu --setujui--> aktif   (atau langsung ditutup bila deadline lewat / kuota penuh)
//   menunggu --minta revisi--> revisi --perusahaan ajukan ulang--> menunggu
//   menunggu --tolak final--> ditolak (tidak bisa diajukan ulang)
//   aktif --tutup/deadline/kuota penuh--> ditutup --perpanjang--> aktif
//   aktif/ditutup --Admin nonaktifkan--> nonaktif
//   aktif --perusahaan mengubah ISI--> menunggu (persetujuan ulang)
// Hanya aktif & ditutup yang pernah lolos peninjauan dan boleh dilihat publik.

class Lowongan extends Model
{
    protected string $tabel = 'lowongan';

    public const STATUS_TAYANG = ['aktif', 'ditutup'];

    /** Syarat SQL: akun perusahaan pemilik lowongan masih aktif (bug #5). */
    private const SYARAT_PERUSAHAAN_AKTIF =
        "EXISTS (SELECT 1 FROM pengguna pg WHERE pg.id = pr.pengguna_id AND pg.status_akun = 'aktif')";

    // --- Status otomatis ---------------------------------------------
    public function tutupOtomatisJikaLewatBatas(): void
    {
        $tutup = Database::fetchAll(
            "UPDATE lowongan SET status = 'ditutup', diperbarui_pada = now()
             WHERE status = 'aktif' AND (batas_lamaran < CURRENT_DATE OR terisi >= kuota)
             RETURNING id"
        );
        foreach ($tutup as $t) {
            $this->catatRiwayat((int) $t['id'], 'ditutup', 'ditutup_otomatis', 'Ditutup otomatis: batas lamaran lewat atau kuota penuh.', null);
        }
    }

    // --- Riwayat ------------------------------------------------------
    public function catatRiwayat(int $id, string $status, string $aksi, ?string $catatan, ?int $olehPenggunaId): void
    {
        Database::execute(
            'INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh) VALUES (?, ?, ?, ?, ?)',
            [$id, $status, $aksi, $catatan !== null ? mb_substr($catatan, 0, 500) : null, $olehPenggunaId]
        );
    }

    public function riwayat(int $id): array
    {
        $label = [
            'diajukan' => 'Diajukan untuk ditinjau', 'diajukan_ulang' => 'Diajukan ulang setelah revisi',
            'diubah_tayang' => 'Isi diubah, perlu persetujuan ulang', 'disetujui' => 'Disetujui Admin',
            'revisi' => 'Admin meminta revisi', 'ditolak' => 'Ditolak Admin (final)', 'ditutup' => 'Ditutup perusahaan',
            'ditutup_otomatis' => 'Ditutup otomatis', 'diperpanjang' => 'Diperpanjang', 'nonaktif' => 'Dinonaktifkan Admin',
        ];
        $baris = Database::fetchAll(
            "SELECT r.*, COALESCE(a.nama, pr.nama_perusahaan, p.email) AS nama_oleh, p.role AS peran_oleh
               FROM riwayat_lowongan r
               LEFT JOIN pengguna p ON p.id = r.oleh
               LEFT JOIN admin a ON a.pengguna_id = p.id
               LEFT JOIN perusahaan pr ON pr.pengguna_id = p.id
              WHERE r.lowongan_id = ? ORDER BY r.tanggal DESC, r.id DESC",
            [$id]
        );
        return array_map(fn($r) => [
            'tanggal' => $r['tanggal'],
            'judul'   => $label[$r['aksi']] ?? ucfirst($r['aksi']),
            'oleh'    => $r['nama_oleh'] ? ($r['peran_oleh'] === 'admin' ? 'Admin: ' : '') . $r['nama_oleh'] : 'Sistem',
            'catatan' => $r['catatan'],
        ], $baris);
    }

    // --- Tulis data --------------------------------------------------
    public function buat(int $perusahaanId, array $d, int $olehPenggunaId): int
    {
        return Database::transaksi(function () use ($perusahaanId, $d, $olehPenggunaId) {
            $id = $this->simpan([
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
                'status'           => 'menunggu',
            ]);
            $this->catatRiwayat($id, 'menunggu', 'diajukan', 'Lowongan diajukan dan menunggu persetujuan Admin.', $olehPenggunaId);
            return $id;
        });
    }

    /**
     * Simpan perubahan isi. Mengembalikan status setelah disimpan.
     *  - revisi  -> menunggu (diajukan ulang)
     *  - aktif/ditutup dengan ISI berubah -> menunggu (persetujuan ulang)
     *  - ditolak/nonaktif tidak boleh diubah (dicegah di controller)
     */
    public function perbarui(int $id, array $d, int $olehPenggunaId, ?string $pamfletBaru = null): string
    {
        return Database::transaksi(function () use ($id, $d, $olehPenggunaId, $pamfletBaru) {
            $lama = Database::fetch('SELECT * FROM lowongan WHERE id = ? FOR UPDATE', [$id]);
            $kolomIsi = ['bidang_id', 'posisi', 'jenis_pekerjaan', 'sistem_kerja', 'lokasi', 'gaji', 'kuota',
                         'batas_lamaran', 'deskripsi', 'kualifikasi', 'skill_dibutuhkan'];
            $baru = [
                'bidang_id' => $d['bidang_id'], 'posisi' => $d['posisi'], 'jenis_pekerjaan' => $d['jenis_pekerjaan'],
                'sistem_kerja' => $d['sistem_kerja'], 'lokasi' => $d['lokasi'], 'gaji' => $d['gaji'] ?: null,
                'kuota' => $d['kuota'], 'batas_lamaran' => $d['batas_lamaran'], 'deskripsi' => $d['deskripsi'],
                'kualifikasi' => $d['kualifikasi'], 'skill_dibutuhkan' => $d['skill_dibutuhkan'] ?: null,
            ];
            $berubah = $pamfletBaru !== null;
            foreach ($kolomIsi as $k) {
                if ((string) ($lama[$k] ?? '') !== (string) ($baru[$k] ?? '')) {
                    $berubah = true;
                }
            }

            $status = $lama['status'];
            $aksi = null;
            if ($status === 'revisi') {
                $status = 'menunggu';
                $aksi = 'diajukan_ulang';
            } elseif (in_array($status, self::STATUS_TAYANG, true) && $berubah) {
                $status = 'menunggu';
                $aksi = 'diubah_tayang';
            }

            $baru['status'] = $status;
            $baru['diperbarui_pada'] = date('Y-m-d H:i:s');
            if ($pamfletBaru !== null) {
                $baru['pamflet'] = $pamfletBaru;
            }
            if ($aksi) {
                $baru['diajukan_pada'] = date('Y-m-d H:i:s');
            }
            $this->ubah($id, $baru);

            if ($aksi) {
                $this->catatRiwayat($id, $status, $aksi, $aksi === 'diubah_tayang'
                    ? 'Perusahaan mengubah isi lowongan yang sudah tayang. Lowongan disembunyikan sampai disetujui ulang.'
                    : 'Perusahaan memperbaiki lowongan sesuai catatan revisi.', $olehPenggunaId);
            }
            return $status;
        });
    }

    // --- Jurusan sasaran ---------------------------------------------
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
        Database::transaksi(function () use ($lowonganId, $jurusanIds) {
            Database::execute('DELETE FROM lowongan_jurusan WHERE lowongan_id = ?', [$lowonganId]);
            foreach (array_unique(array_filter(array_map('intval', $jurusanIds))) as $jurusanId) {
                Database::execute(
                    'INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT ?, id FROM jurusan WHERE id = ?',
                    [$lowonganId, $jurusanId]
                );
            }
        });
    }

    // --- Baca data ---------------------------------------------------
    public function cariDetail(int $id): ?array
    {
        return Database::fetch(
            'SELECT l.*, pr.nama_perusahaan, pr.logo, pr.kota AS kota_perusahaan, pr.pengguna_id AS perusahaan_pengguna_id,
                    pr.deskripsi AS deskripsi_perusahaan, pr.bidang_usaha, b.nama AS nama_bidang,
                    pg.status_akun AS status_akun_perusahaan, pg.email AS email_perusahaan,
                    (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = l.id) AS jumlah_pelamar
             FROM lowongan l
             JOIN perusahaan pr ON pr.id = l.perusahaan_id
             JOIN pengguna pg ON pg.id = pr.pengguna_id
             JOIN bidang b ON b.id = l.bidang_id
             WHERE l.id = ?',
            [$id]
        );
    }

    /** Detail untuk mahasiswa: hanya lowongan yang sudah disetujui & perusahaannya aktif. */
    public function cariDetailTayang(int $id): ?array
    {
        $l = $this->cariDetail($id);
        if (!$l || !in_array($l['status'], self::STATUS_TAYANG, true) || $l['status_akun_perusahaan'] !== 'aktif') {
            return null;
        }
        return $l;
    }

    /** Info loker publik (tautan WA). Belum disetujui / ditolak / nonaktif = 404. */
    public function cariByKodePratinjau(string $kode): ?array
    {
        return Database::fetch(
            "SELECT l.*, pr.id AS perusahaan_id, pr.nama_perusahaan, pr.logo, pr.kota AS kota_perusahaan, b.nama AS nama_bidang
             FROM lowongan l
             JOIN perusahaan pr ON pr.id = l.perusahaan_id
             JOIN bidang b ON b.id = l.bidang_id
             WHERE l.kode_pratinjau = ? AND l.status IN ('aktif','ditutup') AND " . self::SYARAT_PERUSAHAAN_AKTIF,
            [$kode]
        );
    }

    /** Revisi #4: lowongan hanya menerima lamaran bila semua syarat ini terpenuhi. */
    public static function bisaMenerimaLamaran(array $l): bool
    {
        return $l['status'] === 'aktif'
            && strtotime($l['batas_lamaran']) >= strtotime('today')
            && (int) $l['terisi'] < (int) $l['kuota']
            && ($l['status_akun_perusahaan'] ?? 'aktif') === 'aktif';
    }

    public static function alasanTidakMenerima(array $l): string
    {
        if ($l['status'] !== 'aktif') {
            return 'Lowongan ini sudah tidak menerima lamaran.';
        }
        if (strtotime($l['batas_lamaran']) < strtotime('today')) {
            return 'Batas lamaran lowongan ini sudah lewat.';
        }
        if ((int) $l['terisi'] >= (int) $l['kuota']) {
            return 'Kuota lowongan ini sudah terpenuhi.';
        }
        return 'Lowongan ini sedang tidak tersedia.';
    }

    public function milikPerusahaan(int $perusahaanId, string $status = '', int $limit = 0, int $offset = 0): array
    {
        $params = [$perusahaanId];
        $sql = 'SELECT l.*, b.nama AS nama_bidang,
                       (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = l.id) AS jumlah_pelamar,
                       (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = l.id AND status = \'diajukan\') AS jumlah_baru
                FROM lowongan l JOIN bidang b ON b.id = l.bidang_id
                WHERE l.perusahaan_id = ?';
        if ($status !== '' && $status !== 'semua') {
            $sql .= ' AND l.status = ?';
            $params[] = $status;
        }
        $sql .= ' ORDER BY l.dibuat_pada DESC, l.id DESC';
        if ($limit > 0) {
            $sql .= ' LIMIT ? OFFSET ?';
            $params[] = $limit;
            $params[] = $offset;
        }
        return Database::fetchAll($sql, $params);
    }

    public function hitungPerStatusPerusahaan(int $perusahaanId): array
    {
        $hasil = ['semua' => 0];
        foreach (Database::fetchAll('SELECT status, COUNT(*) AS n FROM lowongan WHERE perusahaan_id = ? GROUP BY status', [$perusahaanId]) as $b) {
            $hasil[$b['status']] = (int) $b['n'];
            $hasil['semua'] += (int) $b['n'];
        }
        return $hasil;
    }

    public function lokasiUnik(): array
    {
        return array_column(Database::fetchAll(
            "SELECT DISTINCT l.lokasi FROM lowongan l JOIN perusahaan pr ON pr.id = l.perusahaan_id
             WHERE l.status = 'aktif' AND l.batas_lamaran >= CURRENT_DATE AND " . self::SYARAT_PERUSAHAAN_AKTIF . "
             ORDER BY l.lokasi"
        ), 'lokasi');
    }

    // --- Pencarian & filter (mahasiswa) -------------------------------
    public function cariDenganFilter(array $filter, int $limit = 10, int $offset = 0): array
    {
        [$where, $params] = $this->klausaFilter($filter);
        $urutan = ($filter['urutan'] ?? '') === 'batas_lamaran' ? 'l.batas_lamaran ASC, l.id ASC' : 'l.dibuat_pada DESC, l.id DESC';

        // Ada kata kunci dan urutan tidak dipilih: yang paling relevan dulu (bobot A > B > C > D).
        $relevansi = '';
        if (!empty($filter['keyword']) && ($filter['urutan'] ?? '') === '') {
            [, , $tsquery] = self::klausaCariTeks((string) $filter['keyword']);
            if ($tsquery !== null) {
                $relevansi = "ts_rank(l.search_vector, to_tsquery('public.karirku_cari', ?)) DESC, ";
                $params[] = $tsquery;
            }
        }

        $sql = 'SELECT l.*, pr.nama_perusahaan, pr.logo, b.nama AS nama_bidang
                FROM lowongan l
                JOIN perusahaan pr ON pr.id = l.perusahaan_id
                JOIN bidang b ON b.id = l.bidang_id
                WHERE ' . implode(' AND ', $where) . "
                ORDER BY {$relevansi}{$urutan}
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

    /**
     * Bab 10: pencarian teks (Full-Text Search) memakai kolom lowongan.search_vector
     * + index GIN, menggantikan ILIKE '%kata%' yang membaca seluruh tabel.
     * Mencari di posisi, nama perusahaan, skill, lokasi, dan uraian. Setiap kata
     * dicocokkan sebagai AWALAN ("back" menemukan "backend"). Kata dipecah dulu
     * menjadi huruf/angka saja, sehingga input pengguna tidak bisa menyisipkan
     * operator tsquery. Hasil: [sql, parameter, teks tsquery atau null].
     */
    public static function klausaCariTeks(string $kata): array
    {
        $kata = trim(mb_substr($kata, 0, 100));
        preg_match_all('/[\p{L}\p{N}]+/u', mb_strtolower($kata), $m);
        $token = array_slice($m[0], 0, 8);
        if (!$token) {   // hanya simbol: kembali ke pencocokan teks biasa
            $like = '%' . str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $kata) . '%';
            return ['(l.posisi ILIKE ? OR pr.nama_perusahaan ILIKE ?)', [$like, $like], null];
        }
        $tsquery = implode(' & ', array_map(static fn (string $t): string => $t . ':*', $token));
        return ["l.search_vector @@ to_tsquery('public.karirku_cari', ?)", [$tsquery], $tsquery];
    }

    private function klausaFilter(array $filter): array
    {
        $where = ["l.status = 'aktif'", 'l.batas_lamaran >= CURRENT_DATE', 'l.terisi < l.kuota', self::SYARAT_PERUSAHAAN_AKTIF];
        $params = [];
        if (!empty($filter['keyword'])) {
            [$sqlCari, $paramCari] = self::klausaCariTeks((string) $filter['keyword']);
            $where[] = $sqlCari;
            array_push($params, ...$paramCari);
        }
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'EXISTS (SELECT 1 FROM lowongan_jurusan lj WHERE lj.lowongan_id = l.id AND lj.jurusan_id = ?)';
            $params[] = (int) $filter['jurusan_id'];
        }
        if (!empty($filter['bidang_id'])) {
            $where[] = 'l.bidang_id = ?';
            $params[] = (int) $filter['bidang_id'];
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

    // --- Rekomendasi -------------------------------------------------
    public function rekomendasiUntuk(int $mahasiswaId, int $limit = 5): array
    {
        return Database::fetchAll(
            "SELECT l.*, pr.nama_perusahaan, pr.logo
             FROM lowongan l
             JOIN perusahaan pr ON pr.id = l.perusahaan_id
             WHERE EXISTS (SELECT 1 FROM mahasiswa_minat mm WHERE mm.bidang_id = l.bidang_id AND mm.mahasiswa_id = ?)
               AND l.status = 'aktif' AND l.batas_lamaran >= CURRENT_DATE AND l.terisi < l.kuota
               AND " . self::SYARAT_PERUSAHAAN_AKTIF . "
             ORDER BY l.dibuat_pada DESC, l.id DESC LIMIT " . (int) $limit,
            [$mahasiswaId]
        );
    }

    // --- Kuota & status ----------------------------------------------
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

    public function tutupManual(int $id, int $olehPenggunaId): bool
    {
        return Database::transaksi(function () use ($id, $olehPenggunaId) {
            $l = Database::fetch('SELECT status FROM lowongan WHERE id = ? FOR UPDATE', [$id]);
            if (!$l || $l['status'] !== 'aktif') {
                return false;
            }
            $this->ubah($id, ['status' => 'ditutup', 'diperbarui_pada' => date('Y-m-d H:i:s')]);
            $this->catatRiwayat($id, 'ditutup', 'ditutup', 'Ditutup oleh perusahaan.', $olehPenggunaId);
            return true;
        });
    }

    /**
     * Revisi D: perpanjang lowongan yang sudah disetujui (aktif atau ditutup).
     * Tidak perlu persetujuan ulang karena isinya tidak berubah. Kuota boleh
     * dinaikkan; kuota baru harus lebih besar dari jumlah yang sudah diterima.
     */
    public function perpanjang(int $id, string $batasBaru, int $kuotaBaru, int $olehPenggunaId): void
    {
        Database::transaksi(function () use ($id, $batasBaru, $kuotaBaru, $olehPenggunaId) {
            $l = Database::fetch('SELECT * FROM lowongan WHERE id = ? FOR UPDATE', [$id]);
            if (!$l || !in_array($l['status'], self::STATUS_TAYANG, true)) {
                throw new RuntimeException('Hanya lowongan yang sudah disetujui (aktif atau ditutup) yang bisa diperpanjang.');
            }
            if ($kuotaBaru <= (int) $l['terisi']) {
                throw new RuntimeException('Kuota baru harus lebih besar dari jumlah pelamar yang sudah diterima (' . (int) $l['terisi'] . ').');
            }
            $this->ubah($id, [
                'status'          => 'aktif',
                'batas_lamaran'   => $batasBaru,
                'kuota'           => $kuotaBaru,
                'diperbarui_pada' => date('Y-m-d H:i:s'),
            ]);
            $this->catatRiwayat($id, 'aktif', 'diperpanjang',
                'Batas lamaran: ' . tanggalIndo($l['batas_lamaran']) . ' → ' . tanggalIndo($batasBaru)
                . '; kuota: ' . (int) $l['kuota'] . ' → ' . $kuotaBaru . '.', $olehPenggunaId);
        });
    }

    public function nonaktifkan(int $id, string $alasan, int $olehPenggunaId): bool
    {
        return Database::transaksi(function () use ($id, $alasan, $olehPenggunaId) {
            $l = Database::fetch('SELECT status FROM lowongan WHERE id = ? FOR UPDATE', [$id]);
            if (!$l || !in_array($l['status'], self::STATUS_TAYANG, true)) {
                return false;
            }
            $this->ubah($id, [
                'status'          => 'nonaktif',
                'alasan_nonaktif' => $alasan,
                'diperbarui_pada' => date('Y-m-d H:i:s'),
            ]);
            $this->catatRiwayat($id, 'nonaktif', 'nonaktif', $alasan, $olehPenggunaId);
            return true;
        });
    }

    /**
     * Revisi M: keputusan Admin atas lowongan berstatus menunggu.
     * Baris dikunci (FOR UPDATE) sehingga klik ganda / dua admin bersamaan
     * tidak menghasilkan dua keputusan. Mengembalikan status akhir.
     */
    public function putuskan(int $id, int $adminId, int $adminPenggunaId, string $keputusan, ?string $alasan): string
    {
        return Database::transaksi(function () use ($id, $adminId, $adminPenggunaId, $keputusan, $alasan) {
            $l = Database::fetch('SELECT * FROM lowongan WHERE id = ? FOR UPDATE', [$id]);
            if (!$l) {
                throw new RuntimeException('Lowongan tidak ditemukan.');
            }
            if ($l['status'] !== 'menunggu') {
                throw new RuntimeException('Lowongan ini sudah diputuskan sebelumnya (status: ' . labelStatusLowongan($l['status'])[0] . ').');
            }
            if ($keputusan === 'disetujui') {
                $langsungTutup = strtotime($l['batas_lamaran']) < strtotime('today') || (int) $l['terisi'] >= (int) $l['kuota'];
                $status = $langsungTutup ? 'ditutup' : 'aktif';
                $this->ubah($id, ['status' => $status, 'catatan_admin' => null, 'disetujui_pada' => date('Y-m-d H:i:s'),
                                  'disetujui_oleh' => $adminId, 'diperbarui_pada' => date('Y-m-d H:i:s')]);
                $this->catatRiwayat($id, $status, 'disetujui', $langsungTutup
                    ? 'Disetujui, tetapi langsung berstatus Ditutup karena batas lamaran sudah lewat atau kuota penuh.'
                    : ($alasan ?: null), $adminPenggunaId);
                return $status;
            }
            $status = $keputusan === 'revisi' ? 'revisi' : 'ditolak';
            $this->ubah($id, ['status' => $status, 'catatan_admin' => $alasan, 'diperbarui_pada' => date('Y-m-d H:i:s')]);
            $this->catatRiwayat($id, $status, $status, $alasan, $adminPenggunaId);
            return $status;
        });
    }

    // --- Admin -------------------------------------------------------
    private function klausaAdmin(array $filter): array
    {
        $where = ['1=1'];
        $params = [];
        if (!empty($filter['status'])) {
            $where[] = 'l.status = ?';
            $params[] = $filter['status'];
        }
        if (!empty($filter['bidang_id'])) {
            $where[] = 'l.bidang_id = ?';
            $params[] = (int) $filter['bidang_id'];
        }
        if (!empty($filter['jurusan_id'])) {
            $where[] = 'EXISTS (SELECT 1 FROM lowongan_jurusan lj WHERE lj.lowongan_id = l.id AND lj.jurusan_id = ?)';
            $params[] = (int) $filter['jurusan_id'];
        }
        if (!empty($filter['q'])) {
            [$sqlCari, $paramCari] = self::klausaCariTeks((string) $filter['q']);
            $where[] = $sqlCari;
            array_push($params, ...$paramCari);
        }
        return [$where, $params];
    }

    /** Monitoring & laporan. $limit 0 = semua (untuk PDF). Bug #12: kolom pelamar = jumlah lamaran. */
    public function semuaDenganFilter(array $filter = [], int $limit = 0, int $offset = 0): array
    {
        [$where, $params] = $this->klausaAdmin($filter);
        $sql = 'SELECT l.*, pr.nama_perusahaan, pr.logo, pr.kota AS kota_perusahaan, b.nama AS nama_bidang,
                       (SELECT COUNT(*) FROM lamaran lm WHERE lm.lowongan_id = l.id) AS jumlah_pelamar
                FROM lowongan l
                JOIN perusahaan pr ON pr.id = l.perusahaan_id
                JOIN bidang b ON b.id = l.bidang_id
                WHERE ' . implode(' AND ', $where) . '
                ORDER BY l.dibuat_pada DESC, l.id DESC';
        if ($limit > 0) {
            $sql .= ' LIMIT ? OFFSET ?';
            $params[] = $limit;
            $params[] = $offset;
        }
        return Database::fetchAll($sql, $params);
    }

    /** Jumlah lowongan per status (filter lain tetap berlaku) untuk tab Monitoring. */
    public function hitungPerStatusAdmin(array $filter = []): array
    {
        $filter['status'] = '';
        [$where, $params] = $this->klausaAdmin($filter);
        $baris = Database::fetchAll(
            'SELECT l.status, COUNT(*) AS n FROM lowongan l JOIN perusahaan pr ON pr.id = l.perusahaan_id
              WHERE ' . implode(' AND ', $where) . ' GROUP BY l.status',
            $params
        );
        $hasil = ['' => 0];
        foreach ($baris as $b) { $hasil[$b['status']] = (int) $b['n']; $hasil[''] += (int) $b['n']; }
        return $hasil;
    }

    public function hitungDenganFilter(array $filter = []): int
    {
        [$where, $params] = $this->klausaAdmin($filter);
        return (int) Database::fetch(
            'SELECT COUNT(*) AS n FROM lowongan l JOIN perusahaan pr ON pr.id = l.perusahaan_id WHERE ' . implode(' AND ', $where),
            $params
        )['n'];
    }

    public function aktifUntukDikirim(): array
    {
        return Database::fetchAll(
            "SELECT l.*, pr.nama_perusahaan
             FROM lowongan l JOIN perusahaan pr ON pr.id = l.perusahaan_id
             WHERE l.status = 'aktif' AND l.batas_lamaran >= CURRENT_DATE AND l.terisi < l.kuota
               AND " . self::SYARAT_PERUSAHAAN_AKTIF . "
             ORDER BY l.dibuat_pada DESC, l.id DESC"
        );
    }

    public function terbaruUntukPublik(int $batas = 6): array
    {
        return Database::fetchAll(
            "SELECT l.id, l.posisi, l.jenis_pekerjaan, l.sistem_kerja, l.lokasi,
                    l.batas_lamaran, l.kode_pratinjau, l.pamflet,
                    pr.id AS perusahaan_id, pr.nama_perusahaan, pr.logo,
                    string_agg(DISTINCT j.nama, ', ' ORDER BY j.nama) AS jurusan_sasaran
               FROM lowongan l
               JOIN perusahaan pr ON pr.id = l.perusahaan_id
               JOIN pengguna p ON p.id = pr.pengguna_id
               LEFT JOIN lowongan_jurusan lj ON lj.lowongan_id = l.id
               LEFT JOIN jurusan j ON j.id = lj.jurusan_id
              WHERE l.status = 'aktif'
                AND l.batas_lamaran >= CURRENT_DATE
                AND l.terisi < l.kuota
                AND p.status_akun = 'aktif'
              GROUP BY l.id, pr.id, pr.nama_perusahaan, pr.logo
              ORDER BY l.dibuat_pada DESC, l.id DESC
              LIMIT ?",
            [$batas]
        );
    }

    /** Lowongan aktif satu perusahaan untuk halaman detail mitra publik. */
    public function tayangMilikPerusahaan(int $perusahaanId): array
    {
        return Database::fetchAll(
            "SELECT l.id, l.posisi, l.jenis_pekerjaan, l.sistem_kerja, l.lokasi, l.batas_lamaran, l.kode_pratinjau
               FROM lowongan l
              WHERE l.perusahaan_id = ? AND l.status = 'aktif' AND l.batas_lamaran >= CURRENT_DATE AND l.terisi < l.kuota
              ORDER BY l.batas_lamaran ASC, l.id",
            [$perusahaanId]
        );
    }
}
