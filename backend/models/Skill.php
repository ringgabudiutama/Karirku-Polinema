<?php
// ===== BACKEND · MODEL · Skill (tabel skill) =========================

class Skill extends Model
{
    protected string $tabel = 'skill';

    // --- Baca data ---------------------------------------------------
    public function semuaUrut(): array
    {
        return Database::fetchAll('SELECT * FROM skill ORDER BY nama');
    }

    public function milikMahasiswa(int $mahasiswaId): array
    {
        return Database::fetchAll(
            'SELECT s.id, s.nama FROM mahasiswa_skill ms
             JOIN skill s ON s.id = ms.skill_id
             WHERE ms.mahasiswa_id = ? ORDER BY s.nama',
            [$mahasiswaId]
        );
    }

    // --- Tulis data --------------------------------------------------
    public function setUntukMahasiswa(int $mahasiswaId, array $skillIds): void
    {
        Database::beginTransaction();
        try {
            Database::execute('DELETE FROM mahasiswa_skill WHERE mahasiswa_id = ?', [$mahasiswaId]);
            foreach (array_unique(array_map('intval', $skillIds)) as $skillId) {
                Database::execute(
                    'INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) VALUES (?, ?)',
                    [$mahasiswaId, $skillId]
                );
            }
            Database::commit();
        } catch (Throwable $e) {
            Database::rollBack();
            throw $e;
        }
    }

    public function cariAtauBuat(string $nama): ?int
    {
        $nama = trim(preg_replace('/\s+/', ' ', $nama));
        if ($nama === '' || mb_strlen($nama) > 100) {
            return null;
        }

        $ada = Database::fetch('SELECT id FROM skill WHERE lower(nama) = lower(?)', [$nama]);
        if ($ada) {
            return (int) $ada['id'];
        }

        Database::execute('INSERT INTO skill (nama) VALUES (?)', [$nama]);
        $baru = Database::fetch('SELECT id FROM skill WHERE lower(nama) = lower(?)', [$nama]);
        return $baru ? (int) $baru['id'] : null;
    }

    public function tambahkanKeMahasiswa(int $mahasiswaId, int $skillId): void
    {
        Database::execute(
            'INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) VALUES (?, ?)
             ON CONFLICT (mahasiswa_id, skill_id) DO NOTHING',
            [$mahasiswaId, $skillId]
        );
    }

    public function lepasDariMahasiswa(int $mahasiswaId, int $skillId): void
    {
        Database::execute(
            'DELETE FROM mahasiswa_skill WHERE mahasiswa_id = ? AND skill_id = ?',
            [$mahasiswaId, $skillId]
        );
    }
}
