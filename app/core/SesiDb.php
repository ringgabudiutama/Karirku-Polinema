<?php
// ===== BACKEND · CORE · Penyimpanan sesi di PostgreSQL (mode serverless) =====
// Dipakai otomatis di Vercel (lihat bootstrap.php). Di Vercel setiap permintaan bisa
// dilayani server yang berbeda, dan /tmp tidak dibagi antarserver, sehingga sesi
// berbasis berkas membuat pengguna "keluar sendiri". Data sesi disimpan base64
// (aman untuk isi biner) dan kedaluwarsa mengikuti session.gc_maxlifetime.

class SesiDb implements SessionHandlerInterface, SessionUpdateTimestampHandlerInterface
{
    private static bool $tabelSiap = false;

    private function siapkanTabel(): void
    {
        if (self::$tabelSiap) {
            return;
        }
        Database::pdo()->exec('CREATE TABLE IF NOT EXISTS sesi (
            id          varchar(128) PRIMARY KEY,
            data        text NOT NULL DEFAULT \'\',
            diperbarui  timestamptz NOT NULL DEFAULT now()
        )');
        self::$tabelSiap = true;
    }

    public function open(string $path, string $name): bool
    {
        $this->siapkanTabel();
        return true;
    }

    public function close(): bool
    {
        return true;
    }

    public function read(string $id): string|false
    {
        $baris = Database::fetch(
            "SELECT data FROM sesi WHERE id = ? AND diperbarui > now() - make_interval(secs => ?)",
            [$id, (int) ini_get('session.gc_maxlifetime')]
        );
        return $baris ? (string) base64_decode($baris['data']) : '';
    }

    public function write(string $id, string $data): bool
    {
        Database::execute(
            'INSERT INTO sesi (id, data, diperbarui) VALUES (?, ?, now())
             ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, diperbarui = now()',
            [$id, base64_encode($data)]
        );
        return true;
    }

    public function destroy(string $id): bool
    {
        Database::execute('DELETE FROM sesi WHERE id = ?', [$id]);
        return true;
    }

    public function gc(int $max_lifetime): int|false
    {
        return Database::execute("DELETE FROM sesi WHERE diperbarui < now() - make_interval(secs => ?)", [$max_lifetime]);
    }

    // --- Mode ketat (session.use_strict_mode): tolak ID sesi yang tidak dikenal ---
    public function validateId(string $id): bool
    {
        $this->siapkanTabel();
        return (bool) Database::fetch('SELECT 1 FROM sesi WHERE id = ?', [$id]);
    }

    public function updateTimestamp(string $id, string $data): bool
    {
        return $this->write($id, $data);
    }
}
