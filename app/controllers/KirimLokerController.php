<?php
/**
 * Kirim info loker ke admin jurusan via WhatsApp
 * PIC   : Aqillah (UI/UX, Frontend, dan Integrasi)
 * Status: LOGIKA BACKEND DIISI. Views masih perlu ditimpa dengan desain asli.
 *
 * Tautan wa.me HANYA bisa mengisi teks (lihat komentar di WhatsappService),
 * jadi pamflet disampaikan lewat gambar pratinjau tautan (meta Open Graph di
 * view info-loker), tombol unduh pamflet, dan tombol salin pamflet -- ketiganya
 * dirender di app/views/admin/kirim-loker.php dan publik/info-loker.php,
 * bukan di controller ini.
 */

class KirimLokerController extends Controller
{
    /** Template default kalau admin belum pernah mengisi/menyimpan template WA sendiri di menu Pengaturan. Dipakai juga oleh views/admin/pengaturan.php supaya kotak "Isi pesan" tidak kosong. */
    public const TEMPLATE_WA_DEFAULT = "Info Loker KarirKu Polinema\n"
        . "Posisi: {posisi}\n"
        . "Perusahaan: {perusahaan}\n"
        . "Lokasi: {lokasi}\n"
        . "Batas lamaran: {deadline}\n"
        . "Lihat pamflet dan detail: {tautan}\n"
        . "Untuk melamar, masuk ke KarirKu dengan akun mahasiswa atau alumni.";

    /**
     * View: admin/kirim-loker. Variabel: $lowongan (daftar lowongan aktif
     * untuk dipilih di dropdown), $lowonganDipilih (detail lowongan yang
     * sedang dilihat pratinjaunya, null kalau belum ada yang dipilih),
     * $jurusan, $kontak (peta jurusan_id => baris admin_jurusan_kontak),
     * $sudahDikirim (array jurusan_id yang tombolnya harus berubah jadi
     * "Terkirim"), $jurusanSasaran (array jurusan_id yang dipilih perusahaan
     * saat memasang lowongan -- tombolnya diberi label "Disarankan untuk
     * lowongan ini" lewat class .jur.suggest di view), $tautanPratinjau,
     * $templatePesan (mentah, placeholder
     * {jurusan}/{perusahaan}/dst BELUM diganti -- penggantian dilakukan di
     * view per baris jurusan lewat WhatsappService::susunPesan()).
     */
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

    /**
     * Dipanggil lewat tombol admin jurusan di halaman Kirim Loker ke Jurusan.
     * Sengaja diakses lewat <a href> biasa (BUKAN form POST) supaya klik
     * tombol langsung membuka tab WhatsApp baru (target="_blank" di view),
     * sambil tetap tercatat sebagai "Terkirim" lewat redirect ini sebelum
     * membuka WhatsApp. Method GET untuk aksi yang mengubah data memang
     * bukan praktik terbaik REST, tapi ini satu-satunya cara wa.me bisa
     * dibuka di tab baru dari satu klik tanpa JavaScript tambahan.
     */
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

    /** Simpan/perbarui nomor WhatsApp & nama kontak SEMUA admin jurusan sekaligus (satu tombol "Simpan kontak" di menu Pengaturan, bukan per baris). */
    public function simpanKontak()
    {
        $this->wajibPost();
        Auth::wajibAktif();
        Role::wajib('admin');

        // Field dikirim sebagai larik nama_kontak[jurusan_id] / nomor_wa[jurusan_id]
        // dari satu form yang membungkus seluruh tabel, jadi diambil langsung
        // dari $_POST (bukan $this->input(), yang bertipe string tunggal).
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
                continue; // baris kosong, tidak diapa-apakan
            }
            if ($nomor !== '' && !WhatsappService::nomorValid($nomor)) {
                $adaFormatSalah = true;
                continue; // baris ini dilewati, baris lain tetap disimpan
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