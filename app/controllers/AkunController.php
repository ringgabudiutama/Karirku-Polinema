<?php
// ===== BACKEND · CONTROLLER · Akun (ganti sandi wajib, revisi L) =====
// Setelah Admin mengatur KATA SANDI SEMENTARA, pengguna diarahkan ke sini
// setiap kali membuka halaman apa pun sampai sandinya diganti sendiri.

class AkunController extends Controller
{
    // [URL] GET /akun/ganti-sandi-wajib  →  tampil: views/publik/ganti-sandi-wajib.php
    public function gantiSandiWajib()
    {
        Auth::wajibLogin();
        if (empty($_SESSION['user']['wajib_ganti_sandi'])) {
            $this->redirect(Auth::penggunaSaatIni()['role'] . '/dashboard');
        }
        $this->view('publik/ganti-sandi-wajib');
    }

    // [URL] POST /akun/simpan-sandi-wajib  →  simpan lalu kembali ke /akun/ganti-sandi-wajib
    public function simpanSandiWajib()
    {
        $this->wajibPost();
        Auth::wajibLogin();
        $user = Auth::penggunaSaatIni();
        $pengguna = (new Pengguna())->cari($user['id']);

        $sementara = $this->input('password_lama');
        $baru = $this->input('password_baru');
        $konfirmasi = $this->input('konfirmasi_password');

        if (!cocokkanPassword($sementara, $pengguna['password_hash'])) {
            $this->flash('bad', 'Kata sandi sementara tidak sesuai.');
        } elseif (!validasiPassword($baru)) {
            $this->flash('bad', PESAN_PASSWORD);
        } elseif ($baru !== $konfirmasi) {
            $this->flash('bad', 'Konfirmasi kata sandi baru tidak cocok.');
        } elseif (cocokkanPassword($baru, $pengguna['password_hash'])) {
            $this->flash('bad', 'Kata sandi baru harus berbeda dari kata sandi sementara.');
        } else {
            Auth::gantiSandiDanCabutSesi((int) $user['id'], $baru, false, true);
            $this->flash('ok', 'Kata sandi baru tersimpan. Semua sesi lama di perangkat lain sudah dikeluarkan.');
            $this->redirect($user['role'] . '/dashboard');
        }
        $this->redirect('akun/ganti-sandi-wajib');
    }
}
