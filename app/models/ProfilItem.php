<?php
/**
 * Model tabel profil_item
 * PIC   : Muhamad Nafi' Hanif (Modul Mahasiswa dan Alumni)
 * Status: DIISI.
 * Menyimpan 4 jenis data dalam satu tabel: pendidikan, pengalaman, sertifikat,
 * portofolio (dibedakan lewat kolom "tipe") supaya CV otomatis bisa disusun
 * dari satu sumber data saja.
 */

class ProfilItem extends Model
{
    protected string $tabel = 'profil_item';

    public function milikMahasiswa(int $mahasiswaId, ?string $tipe = null): array
    {
        if ($tipe) {
            return Database::fetchAll(
                'SELECT * FROM profil_item WHERE mahasiswa_id = ? AND tipe = ?
                 ORDER BY mulai DESC NULLS LAST, id DESC',
                [$mahasiswaId, $tipe]
            );
        }
        return Database::fetchAll(
            'SELECT * FROM profil_item WHERE mahasiswa_id = ?
             ORDER BY tipe, mulai DESC NULLS LAST, id DESC',
            [$mahasiswaId]
        );
    }

    public function tambah(int $mahasiswaId, array $d): int
    {
        return $this->simpan([
            'mahasiswa_id' => $mahasiswaId,
            'tipe'         => $d['tipe'],
            'judul'        => $d['judul'],
            'instansi'     => $d['instansi'] ?: null,
            'mulai'        => $d['mulai'] ?: null,
            'selesai'      => $d['selesai'] ?: null,
            'deskripsi'    => $d['deskripsi'] ?: null,
            'file'         => $d['file'] ?? null,
            'tautan'       => $d['tautan'] ?: null,
        ]);
    }

    /** Hapus HANYA jika item itu benar milik mahasiswa yang sedang login (cegah IDOR). */
    public function hapusMilik(int $id, int $mahasiswaId): bool
    {
        return Database::execute(
            'DELETE FROM profil_item WHERE id = ? AND mahasiswa_id = ?',
            [$id, $mahasiswaId]
        ) > 0;
    }

    public function hitungMilik(int $mahasiswaId): int
    {
        return $this->hitung('mahasiswa_id = ?', [$mahasiswaId]);
    }
}
