<?php
// ===== BACKEND · MODEL · ProfilItem (tabel profil_item) ==============

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

    public function cariMilik(int $id, int $mahasiswaId): ?array
    {
        return Database::fetch('SELECT * FROM profil_item WHERE id = ? AND mahasiswa_id = ?', [$id, $mahasiswaId]);
    }

    /** Tambah item lengkap (revisi tahap 2): kolom tabel + detail JSONB. */
    public function tambahLengkap(int $mahasiswaId, string $tipe, array $kolom, array $detail): int
    {
        $data = ['mahasiswa_id' => $mahasiswaId, 'tipe' => $tipe];
        foreach (KOLOM_ITEM as $k) $data[$k] = $kolom[$k] ?? null;
        $id = $this->simpan($data);
        Database::execute('UPDATE profil_item SET detail = ?::jsonb WHERE id = ?', [json_encode($detail ?: new stdClass(), JSON_UNESCAPED_UNICODE), $id]);
        return $id;
    }

    public function ubahLengkap(int $id, int $mahasiswaId, array $kolom, array $detail): void
    {
        $set = []; $par = [];
        foreach (KOLOM_ITEM as $k) {
            if (array_key_exists($k, $kolom)) { $set[] = "$k = ?"; $par[] = $kolom[$k]; }
        }
        $set[] = 'detail = ?::jsonb'; $par[] = json_encode($detail ?: new stdClass(), JSON_UNESCAPED_UNICODE);
        $par[] = $id; $par[] = $mahasiswaId;
        Database::execute('UPDATE profil_item SET ' . implode(', ', $set) . ' WHERE id = ? AND mahasiswa_id = ?', $par);
    }

    public function hapusMilik(int $id, int $mahasiswaId): bool
    {
        $lama = $this->cariMilik($id, $mahasiswaId);
        if ($lama) {
            UploadService::hapus('portofolio', $lama['file'] ?? null);
            UploadService::hapus('portofolio', detailItem($lama)['file2'] ?? null);
        }
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
