<?php
// ===== BACKEND · CONTROLLER · Mitra (publik, revisi A) ================
// Halaman detail perusahaan mitra yang bisa dibuka dari beranda sebelum login.

class MitraController extends Controller
{
    // [URL] GET /mitra/{id}  →  tampil: views/publik/mitra-detail.php
    public function detail(int $id)
    {
        $mitra = (new Perusahaan())->mitraPublik($id);
        if (!$mitra) {
            $this->halaman404();
        }
        (new Lowongan())->tutupOtomatisJikaLewatBatas();
        $this->view('publik/mitra-detail', [
            'mitra'    => $mitra,
            'lowongan' => (new Lowongan())->tayangMilikPerusahaan($id),
        ]);
    }
}
