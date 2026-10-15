<?php
// ===== BACKEND · MODEL · Perusahaan (tabel perusahaan) ===============

class Perusahaan extends Model
{
    protected string $tabel = 'perusahaan';

    // --- Registrasi --------------------------------------------------
    public function buat(array $d): int
    {
        return $this->simpan([
            'pengguna_id'       => $d['pengguna_id'],
            'nama_perusahaan'   => $d['nama_perusahaan'],
            'bidang_usaha'      => $d['bidang_usaha'],
            'jenis_perusahaan'  => $d['jenis_perusahaan'],
            'alamat'            => $d['alamat'],
            'kota'              => $d['kota'],
            'website'           => $d['website'] ?: null,
            'nama_pic'          => $d['nama_pic'],
            'jabatan_pic'       => $d['jabatan_pic'],
            'whatsapp_pic'      => $d['whatsapp_pic'],
            'bukan_outsourcing' => true,
        ]);
    }

    // --- Baca data ---------------------------------------------------
    public function cariByPenggunaId(int $penggunaId): ?array
    {
        return Database::fetch(
            'SELECT pr.*, p.email, p.status_akun
             FROM perusahaan pr JOIN pengguna p ON p.id = pr.pengguna_id
             WHERE pr.pengguna_id = ?',
            [$penggunaId]
        );
    }

    public function cariLengkap(int $id): ?array
    {
        return Database::fetch(
            'SELECT pr.*, p.email, p.status_akun
             FROM perusahaan pr JOIN pengguna p ON p.id = pr.pengguna_id
             WHERE pr.id = ?',
            [$id]
        );
    }

    // --- Ubah profil -------------------------------------------------
    public function perbaruiProfil(int $id, array $d): void
    {
        $this->ubah($id, [
            'nama_perusahaan'  => $d['nama_perusahaan'],
            'bidang_usaha'     => $d['bidang_usaha'],
            'jenis_perusahaan' => $d['jenis_perusahaan'],
            'alamat'           => $d['alamat'],
            'kota'             => $d['kota'],
            'website'          => $d['website'] ?: null,
            'nama_pic'         => $d['nama_pic'],
            'jabatan_pic'      => $d['jabatan_pic'],
            'whatsapp_pic'     => $d['whatsapp_pic'],
            'deskripsi'        => $d['deskripsi'] ?: null,
        ]);
    }

    public function perbaruiLogo(int $id, string $namaFile): void
    {
        $this->ubah($id, ['logo' => $namaFile]);
    }

    // --- Admin & publik ----------------------------------------------
    public function semuaDenganStatus(): array
    {
        return Database::fetchAll(
            'SELECT pr.*, p.email, p.status_akun
             FROM perusahaan pr JOIN pengguna p ON p.id = pr.pengguna_id
             ORDER BY pr.nama_perusahaan'
        );
    }

    public function cariById(int $id): ?array
    {
        return Database::fetch('SELECT * FROM perusahaan WHERE id = ?', [$id]);
    }

    public function perbaruiWhatsapp(int $id, string $whatsapp): void
    {
        Database::execute('UPDATE perusahaan SET whatsapp_pic = ? WHERE id = ?', [$whatsapp, $id]);
    }

    public function mitraTerverifikasi(int $batas = 12): array
    {
        return Database::fetchAll(
            "SELECT pr.id, pr.nama_perusahaan, pr.bidang_usaha, pr.kota, pr.logo,
                    count(l.id) FILTER (WHERE l.status = 'aktif'
                                          AND l.batas_lamaran >= CURRENT_DATE) AS lowongan_aktif
               FROM perusahaan pr
               JOIN pengguna p ON p.id = pr.pengguna_id
               LEFT JOIN lowongan l ON l.perusahaan_id = pr.id
              WHERE p.status_akun = 'aktif'
              GROUP BY pr.id
              ORDER BY lowongan_aktif DESC, pr.id DESC
              LIMIT ?",
            [$batas]
        );
    }
}
