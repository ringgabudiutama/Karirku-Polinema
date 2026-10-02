<?php
/**
 * Ikon lonceng notifikasi
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 * Dipakai oleh Mahasiswa, Perusahaan, dan Admin. Admin tetap juga melihat
 * ringkasan aktivitas terbaru di Dashboard, tapi sekarang punya halaman dan
 * lonceng notifikasi sendiri seperti dua peran lainnya.
 */

class NotifikasiController extends Controller
{
    /** View: mahasiswa/notifikasi, perusahaan/notifikasi, ATAU admin/notifikasi (dipilih otomatis sesuai peran). */
    public function semua()
    {
        Auth::wajibAktif();
        Role::wajib('mahasiswa', 'perusahaan', 'admin');

        $user = Auth::penggunaSaatIni();
        $view = $user['role'] . '/notifikasi';
        $this->view($view, ['notifikasi' => (new Notifikasi())->milikPengguna($user['id'])]);
    }

    /**
     * Halaman daftar notifikasi. Alamatnya SATU untuk semua peran, yaitu
     * 'notifikasi/semua'. Yang berbeda hanya view yang dipakai, dipilih
     * otomatis di method semua() di atas.
     */
    private const HALAMAN_NOTIFIKASI = 'notifikasi/semua';

    public function tandaiDibaca(int $id)
    {
        Auth::wajibAktif();
        $notifModel = new Notifikasi();
        $notifModel->tandaiDibaca($id, Auth::penggunaSaatIni()['id']);

        // Notifikasi boleh menyimpan tautan tujuan, misalnya ke detail lamaran.
        // Tautan itu diperiksa dulu: kalau kosong atau mengarah ke alamat yang
        // tidak dikenal, pengguna dikembalikan ke daftar notifikasi, bukan
        // dilempar ke halaman 404.
        $tautan = Database::fetch('SELECT tautan FROM notifikasi WHERE id = ?', [$id])['tautan'] ?? null;
        $this->redirect($this->tujuanAman($tautan));
    }

    public function tandaiSemuaDibaca()
    {
        Auth::wajibAktif();
        (new Notifikasi())->tandaiSemuaDibaca(Auth::penggunaSaatIni()['id']);
        $this->redirect(self::HALAMAN_NOTIFIKASI);
    }

    /**
     * Mengembalikan tautan hanya kalau controller dan method-nya benar-benar
     * ada. Selain itu dikembalikan ke halaman notifikasi.
     */
    private function tujuanAman(?string $tautan): string
    {
        $tautan = trim((string) $tautan, " /\t\n\r");
        if ($tautan === '') {
            return self::HALAMAN_NOTIFIKASI;
        }
        // Tolak alamat ke situs lain, hanya boleh alamat di dalam aplikasi.
        if (preg_match('#^[a-z]+://#i', $tautan) || str_starts_with($tautan, '//')) {
            return self::HALAMAN_NOTIFIKASI;
        }

        $segmen = explode('/', strtok($tautan, '?'));
        $cSegmen = $segmen[0] ?? '';
        $mSegmen = $segmen[1] ?? 'index';

        // Alamat khusus yang tidak mengikuti pola controller/method.
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