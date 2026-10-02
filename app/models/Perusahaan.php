<?php
/**
 * Model tabel perusahaan
 * PIC   : Atha Rasya Farras (Modul Operator dan Career Center)
 * Status: DIISI.
 */

class Perusahaan extends Model
{
    protected string $tabel = 'perusahaan';

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

    public function semuaDenganStatus(): array
    {
        return Database::fetchAll(
            'SELECT pr.*, p.email, p.status_akun
             FROM perusahaan pr JOIN pengguna p ON p.id = pr.pengguna_id
             ORDER BY pr.nama_perusahaan'
        );
    }

    /**
     * Ambil satu perusahaan berdasarkan primary key.
     * Dipakai LamaranController saat mengirim notifikasi lamaran masuk.
     */
    public function cariById(int $id): ?array
    {
        return Database::fetch('SELECT * FROM perusahaan WHERE id = ?', [$id]);
    }

    /** Perbarui nomor WhatsApp PIC dari menu Pengaturan Akun. */
    public function perbaruiWhatsapp(int $id, string $whatsapp): void
    {
        Database::execute('UPDATE perusahaan SET whatsapp_pic = ? WHERE id = ?', [$whatsapp, $id]);
    }

    /**
     * Perusahaan terverifikasi untuk bagian "Perusahaan mitra" di beranda.
     * Yang sedang punya lowongan aktif ditampilkan lebih dulu, supaya yang
     * terlihat di halaman depan adalah mitra yang benar-benar sedang merekrut.
     * Sisanya diurutkan dari yang paling baru diverifikasi, sehingga mitra
     * yang baru lolos verifikasi langsung naik ke depan.
     */
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
