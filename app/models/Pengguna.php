<?php
/**
 * Model tabel pengguna
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 */

class Pengguna extends Model
{
    protected string $tabel = 'pengguna';

    public function cariByEmail(string $email): ?array
    {
        return $this->satuBerdasarkan('email', $email);
    }

    public function emailSudahDipakai(string $email): bool
    {
        return $this->cariByEmail($email) !== null;
    }

    /** Buat akun baru berstatus 'menunggu'. Mengembalikan id pengguna baru. */
    public function buat(string $email, string $passwordPlain, string $role): int
    {
        return $this->simpan([
            'email'         => $email,
            'password_hash' => buatHashPassword($passwordPlain),
            'role'          => $role,
            'status_akun'   => 'menunggu',
        ]);
    }

    public function perbaruiTerakhirLogin(int $id): void
    {
        Database::execute('UPDATE pengguna SET terakhir_login = now() WHERE id = ?', [$id]);
    }

    public function ubahStatusAkun(int $id, string $status): void
    {
        $this->ubah($id, ['status_akun' => $status]);
    }

    public function gantiPassword(int $id, string $passwordBaru): void
    {
        $this->ubah($id, ['password_hash' => buatHashPassword($passwordBaru)]);
    }

    public function gantiEmail(int $id, string $emailBaru): void
    {
        $this->ubah($id, ['email' => $emailBaru]);
    }

    /** Nama tampilan (mahasiswa/perusahaan/admin) untuk satu baris pengguna. */
    public function namaTampilan(int $penggunaId, string $role): string
    {
        $kolom = $role === 'mahasiswa' ? 'nama' : ($role === 'perusahaan' ? 'nama_perusahaan' : 'nama');
        $tabel = $role === 'mahasiswa' ? 'mahasiswa' : ($role === 'perusahaan' ? 'perusahaan' : 'admin');
        $baris = Database::fetch("SELECT {$kolom} AS nama FROM {$tabel} WHERE pengguna_id = ?", [$penggunaId]);
        return $baris['nama'] ?? '(tanpa nama)';
    }

    /* ---------------------------------------------------------------------------
     * LUPA KATA SANDI
     * Butuh tabel reset_kata_sandi dari database/03-tambahan-reset-password.sql.
     * Semua method di bawah membungkus query dengan try/catch: kalau tabel itu
     * belum dijalankan, method mengembalikan null/false alih-alih meledak
     * dengan error SQL yang membingungkan, dan AuthController menampilkan
     * pesan "fitur belum aktif" ke pengguna.
     * ------------------------------------------------------------------------ */

    public function fiturResetTersedia(): bool
    {
        try {
            Database::fetch("SELECT 1 FROM reset_kata_sandi LIMIT 1");
            return true;
        } catch (Throwable $e) {
            return false;
        }
    }

    /** Mengembalikan token ASLI (dikirim lewat email), hash-nya yang disimpan di DB. */
    public function buatTokenReset(int $penggunaId): ?string
    {
        if (!$this->fiturResetTersedia()) {
            return null;
        }
        $token = bin2hex(random_bytes(32));
        Database::execute(
            "INSERT INTO reset_kata_sandi (pengguna_id, token_hash, kedaluwarsa)
             VALUES (?, ?, now() + interval '60 minutes')",
            [$penggunaId, hash('sha256', $token)]
        );
        return $token;
    }

    public function cariResetValid(string $token): ?array
    {
        if (!$this->fiturResetTersedia()) {
            return null;
        }
        return Database::fetch(
            'SELECT * FROM reset_kata_sandi
             WHERE token_hash = ? AND kedaluwarsa > now() AND dipakai_pada IS NULL',
            [hash('sha256', $token)]
        );
    }

    public function tandaiResetDipakai(int $resetId): void
    {
        Database::execute('UPDATE reset_kata_sandi SET dipakai_pada = now() WHERE id = ?', [$resetId]);
    }

    /**
     * Antrean Persetujuan Akun untuk Admin: pendaftar berstatus 'menunggu',
     * lengkap dengan nama tampilan dan jurusan (kalau mahasiswa) supaya bisa
     * difilter. Perusahaan tidak punya jurusan, jadi jurusan_id-nya NULL.
     */
    public function antreanVerifikasi(?int $jurusanId = null): array
    {
        $sql = "SELECT p.id AS pengguna_id, p.email, p.role, p.dibuat_pada,
                       COALESCE(m.nama, pr.nama_perusahaan) AS nama,
                       j.id AS jurusan_id, j.nama AS nama_jurusan
                FROM pengguna p
                LEFT JOIN mahasiswa m ON m.pengguna_id = p.id
                LEFT JOIN perusahaan pr ON pr.pengguna_id = p.id
                LEFT JOIN program_studi ps ON ps.id = m.program_studi_id
                LEFT JOIN jurusan j ON j.id = ps.jurusan_id
                WHERE p.status_akun = 'menunggu'";
        $params = [];
        if ($jurusanId) {
            $sql .= ' AND j.id = ?';
            $params[] = $jurusanId;
        }
        $sql .= ' ORDER BY p.dibuat_pada ASC';
        return Database::fetchAll($sql, $params);
    }
}
