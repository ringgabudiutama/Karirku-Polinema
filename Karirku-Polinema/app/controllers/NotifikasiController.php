<?php
// ===== BACKEND · CONTROLLER · Notifikasi =============================

class NotifikasiController extends Controller
{
    // --- Daftar notifikasi -------------------------------------------
    // [URL] GET /notifikasi/semua  →  tampil: views/umum/notifikasi.php
    public function semua()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa', 'perusahaan', 'admin');

        $user = Auth::penggunaSaatIni();
        $model = new Notifikasi();
        $total = $model->hitungMilik((int) $user['id']);
        [$hal, $per, $offset] = $this->halaman($total);
        $this->view('umum/notifikasi', [
            'notifikasi' => $model->milikPengguna((int) $user['id'], $per, $offset),
            'paginasi'   => $this->infoPaginasi($total, $hal, $per),
        ]);
    }

    // --- Tandai dibaca -----------------------------------------------
    private const HALAMAN_NOTIFIKASI = 'notifikasi/semua';

    // [URL] GET /notifikasi/tandai-dibaca/{id}  →  proses
    public function tandaiDibaca(int $id)
    {
        Auth::wajibAktif();
        $notifModel = new Notifikasi();
        $notifModel->tandaiDibaca($id, Auth::penggunaSaatIni()['id']);

        $tautan = Database::fetch('SELECT tautan FROM notifikasi WHERE id = ?', [$id])['tautan'] ?? null;
        $this->redirect($this->tujuanAman($tautan));
    }

    // [URL] POST /notifikasi/tandai-semua-dibaca  →  proses
    public function tandaiSemuaDibaca()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        (new Notifikasi())->tandaiSemuaDibaca(Auth::penggunaSaatIni()['id']);
        $this->redirect(self::HALAMAN_NOTIFIKASI);
    }

    // --- Helper ------------------------------------------------------
    private function tujuanAman(?string $tautan): string
    {
        $tautan = trim((string) $tautan, " /\t\n\r");
        if ($tautan === '') {
            return self::HALAMAN_NOTIFIKASI;
        }
        if (preg_match('#^[a-z]+://#i', $tautan) || str_starts_with($tautan, '//')) {
            return self::HALAMAN_NOTIFIKASI;
        }

        $segmen = explode('/', strtok($tautan, '?'));
        $cSegmen = $segmen[0] ?? '';
        $mSegmen = $segmen[1] ?? 'index';

        if (in_array($cSegmen, ['beranda', 'masuk', 'daftar', 'status-akun'], true)) {
            return $tautan;
        }
        if (preg_match('#^info-loker/[a-f0-9]+$#', $tautan)) {
            return $tautan;
        }

        $kelas = str_replace(' ', '', ucwords(str_replace('-', ' ', $cSegmen))) . 'Controller';
        $method = lcfirst(str_replace(' ', '', ucwords(str_replace('-', ' ', $mSegmen))));

        $berkas = __DIR__ . '/' . $kelas . '.php';
        if (!is_file($berkas)) {
            return self::HALAMAN_NOTIFIKASI;
        }
        require_once $berkas;
        if (!class_exists($kelas, false) || !method_exists($kelas, $method)) {
            return self::HALAMAN_NOTIFIKASI;
        }
        return $tautan;
    }
}
