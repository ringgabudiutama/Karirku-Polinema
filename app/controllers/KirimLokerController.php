<?php
// ===== BACKEND · CONTROLLER · Kirim loker ke jurusan =================

class KirimLokerController extends Controller
{
    // --- Template pesan WA -------------------------------------------
    public const TEMPLATE_WA_DEFAULT = "Info Loker KarirKu Polinema\n"
        . "Posisi: {posisi}\n"
        . "Perusahaan: {perusahaan}\n"
        . "Lokasi: {lokasi}\n"
        . "Batas lamaran: {deadline}\n"
        . "Lihat pamflet dan detail: {tautan}\n"
        . "Untuk melamar, masuk ke KarirKu dengan akun mahasiswa atau alumni.";

    // --- Halaman kirim loker -----------------------------------------
    public function index()
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        $lowonganDipilihId = (int) $this->query_('lowongan_id');
        $lowonganDipilih = null;
        $sudahDikirim = [];
        $jurusanSasaran = [];
        $tautanPratinjau = '';

        $kontak = [];
        foreach ((new AdminJurusanKontak())->semuaDenganJurusan() as $k) {
            $kontak[$k['jurusan_id']] = $k;
        }

        if ($lowonganDipilihId) {
            $lowonganDipilih = (new Lowongan())->cariDetail($lowonganDipilihId);
            if ($lowonganDipilih) {
                $sudahDikirim = (new PengirimanLoker())->jurusanSudahDikirimUntuk($lowonganDipilihId);
                $jurusanSasaran = array_column((new Lowongan())->jurusanSasaran($lowonganDipilihId), 'id');
                $tautanPratinjau = url('info-loker/' . $lowonganDipilih['kode_pratinjau']);
            }
        }

        $this->view('admin/kirim-loker', [
            'lowongan'        => (new Lowongan())->aktifUntukDikirim(),
            'lowonganDipilih' => $lowonganDipilih,
            'jurusan'         => (new Jurusan())->semuaUrut(),
            'kontak'          => $kontak,
            'sudahDikirim'    => $sudahDikirim,
            'jurusanSasaran'  => $jurusanSasaran,
            'tautanPratinjau' => $tautanPratinjau,
            'templatePesan'   => (new Pengaturan())->ambil(
                'template_wa_loker',
                self::TEMPLATE_WA_DEFAULT
            ),
        ]);
    }

    // --- Kirim ke admin jurusan --------------------------------------
    public function kirim(int $lowonganId, int $jurusanId)
    {
        Auth::wajibAktif();
        Role::wajib('admin');

        $lowongan = (new Lowongan())->cariDetail($lowonganId);
        $jurusan = (new Jurusan())->cari($jurusanId);
        $kontak = (new AdminJurusanKontak())->untukJurusan($jurusanId);

        if (!$lowongan || !$jurusan) {
            http_response_code(404);
            require __DIR__ . '/../views/publik/404.php';
            return;
        }
        if (!$kontak || !WhatsappService::nomorValid($kontak['nomor_wa'] ?? null)) {
            $this->flash('bad', 'Nomor WhatsApp admin jurusan ini belum diisi. Lengkapi dulu di menu Pengaturan.');
            $this->redirect('kirim-loker?lowongan_id=' . $lowonganId);
        }

        $adminId = (new Admin())->idDariPenggunaId(Auth::penggunaSaatIni()['id']);
        (new PengirimanLoker())->catat($lowonganId, $jurusanId, $adminId);

        $template = (new Pengaturan())->ambil(
            'template_wa_loker',
            self::TEMPLATE_WA_DEFAULT
        );
        $tautanPratinjau = url('info-loker/' . $lowongan['kode_pratinjau']);
        $pesan = WhatsappService::susunPesan($template, $lowongan, $jurusan['nama'], $tautanPratinjau);
        $tautanWa = WhatsappService::buatTautan($kontak['nomor_wa'], $pesan);

        header('Location: ' . $tautanWa);
        exit;
    }

    // --- Kontak admin jurusan ----------------------------------------
    public function simpanKontak()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('admin');

        $namaKontak = $_POST['nama_kontak'] ?? [];
        $nomorWa = $_POST['nomor_wa'] ?? [];
        $adminId = (new Admin())->idDariPenggunaId(Auth::penggunaSaatIni()['id']);
        $model = new AdminJurusanKontak();

        $adaFormatSalah = false;
        foreach ($nomorWa as $jurusanId => $nomor) {
            $jurusanId = (int) $jurusanId;
            $nomor = trim((string) $nomor);
            $nama = trim((string) ($namaKontak[$jurusanId] ?? ''));

            if ($nomor === '' && $nama === '') {
                continue;
            }
            if ($nomor !== '' && !WhatsappService::nomorValid($nomor)) {
                $adaFormatSalah = true;
                continue;
            }

            $model->simpanKontak($jurusanId, $nama, $nomor !== '' ? WhatsappService::rapikanNomor($nomor) : '', $adminId);
        }

        if ($adaFormatSalah) {
            $this->flash('bad', 'Kontak tersimpan, tapi ada baris dengan format nomor WhatsApp yang tidak valid dan dilewati.');
        } else {
            $this->flash('ok', 'Kontak admin jurusan berhasil disimpan.');
        }
        $this->redirect('admin/pengaturan');
    }
}
