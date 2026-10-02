<?php
/**
 * Pembuatan PDF
 * PIC   : M. Ubaidillah (Backend dan Database)
 * Status: DIISI.
 *
 * WAJIB jalankan `composer install` dulu supaya folder vendor/ dan Dompdf
 * tersedia (lihat composer.json). Selama vendor/ belum ada, method di
 * bawah akan menampilkan HTML biasa yang tetap rapi kalau dicetak lewat
 * Ctrl+P (atribut CSS @media print sudah disiapkan di dalam $html),
 * supaya fitur unduh CV / laporan tetap bisa didemokan tanpa Dompdf.
 */

class PdfService
{
    /**
     * Ubah HTML jadi keluaran PDF (kalau Dompdf tersedia) atau HTML siap-cetak
     * (kalau belum). Method ini langsung mencetak ke output dan exit, jadi
     * panggil di baris TERAKHIR sebuah action controller.
     */
    public static function keluarkan(string $html, string $namaFile): void
    {
        if (is_file(__DIR__ . '/../../vendor/autoload.php')) {
            require_once __DIR__ . '/../../vendor/autoload.php';
        }

        if (class_exists('Dompdf\Dompdf')) {
            $dompdf = new \Dompdf\Dompdf(['isRemoteEnabled' => true, 'defaultFont' => 'DejaVu Sans']);
            $dompdf->loadHtml($html);
            $dompdf->setPaper('A4', 'portrait');
            $dompdf->render();
            $dompdf->stream($namaFile, ['Attachment' => false]);
            exit;
        }

        /* Dompdf belum terpasang (folder vendor/ belum ada). Dokumen tetap
           dikeluarkan sebagai halaman A4 yang sudah ditata untuk dicetak, plus
           panel kecil berisi tombol "Simpan sebagai PDF" yang langsung membuka
           dialog cetak browser. Panel itu sendiri tidak ikut tercetak karena
           disembunyikan di @media print. Hasil akhirnya tetap berkas PDF. */
        header('Content-Type: text/html; charset=utf-8');

        $judul = htmlspecialchars(pathinfo($namaFile, PATHINFO_FILENAME), ENT_QUOTES, 'UTF-8');
        $panel = '<style>
            @page { size: A4; margin: 14mm; }
            body { background:#eef1f6; margin:0; }
            .kertas { background:#fff; max-width:210mm; min-height:297mm; margin:22px auto;
                      padding:18mm 16mm; box-shadow:0 8px 28px rgba(16,32,64,.14); box-sizing:border-box; }
            .bar { position:sticky; top:0; z-index:9; display:flex; gap:10px; align-items:center;
                   justify-content:center; flex-wrap:wrap; background:#0A2656; color:#fff;
                   padding:12px 16px; font:500 14px/1.5 system-ui, Segoe UI, Roboto, Arial, sans-serif; }
            .bar button, .bar a { font:600 14px system-ui, Segoe UI, Roboto, Arial, sans-serif;
                   border:0; border-radius:999px; padding:9px 18px; cursor:pointer; text-decoration:none; }
            .bar button { background:#fff; color:#0A2656; }
            .bar a { background:transparent; color:#fff; border:1.5px solid rgba(255,255,255,.6); }
            .bar small { opacity:.85; flex-basis:100%; text-align:center; font-weight:400; }
            @media print { .bar { display:none !important; }
                           body { background:#fff; }
                           .kertas { margin:0; padding:0; box-shadow:none; max-width:none; min-height:0; } }
          </style>
          <div class="bar">
            <button type="button" onclick="window.print()">Simpan sebagai PDF</button>
            <a href="javascript:history.back()">Kembali</a>
            <small>Pada jendela cetak, pilih Destination atau Tujuan: <b>Save as PDF</b>, lalu Save.</small>
          </div>';

        echo '<!doctype html><html lang="id"><head><meta charset="utf-8">'
           . '<meta name="viewport" content="width=device-width, initial-scale=1">'
           . '<title>' . $judul . '</title></head><body>'
           . $panel
           . '<div class="kertas">' . self::isiBody($html) . '</div>'
           . '</body></html>';
        exit;
    }

    /* --------------------- CV Otomatis mahasiswa --------------------- */

    public static function cv(array $mahasiswa, array $pendidikan, array $pengalaman, array $sertifikat, array $portofolio, array $skill): void
    {
        $html = '<html><head><meta charset="utf-8"><style>
            @page { margin: 28px; }
            body{font-family:DejaVu Sans, Arial, sans-serif; font-size:12px; color:#1c2230;}
            h1{font-size:20px;margin:0 0 2px}
            h2{font-size:13px;margin:18px 0 6px;border-bottom:1.5px solid #16305e;padding-bottom:4px;color:#16305e}
            .sub{color:#5b6472;margin:0 0 14px}
            .item{margin-bottom:10px}
            .item b{display:block}
            .item .periode{color:#5b6472;font-size:11px}
            .chip{display:inline-block;background:#eaf0fb;color:#16305e;border-radius:10px;padding:3px 10px;margin:2px 4px 2px 0;font-size:11px}
            </style></head><body>';
        $html .= '<h1>' . e($mahasiswa['nama']) . '</h1>';
        // Hanya bagian yang benar-benar terisi yang ikut dicetak, supaya tidak
        // muncul pemisah titik yang menggantung tanpa isi.
        $identitas = array_filter([
            trim(($mahasiswa['jenjang'] ?? '') . ' ' . ($mahasiswa['nama_prodi'] ?? '')),
            !empty($mahasiswa['nim']) ? 'NIM ' . $mahasiswa['nim'] : '',
            $mahasiswa['domisili'] ?? '',
            $mahasiswa['email'] ?? '',
            $mahasiswa['no_whatsapp'] ?? '',
        ], static fn($x) => trim((string) $x) !== '');
        $html .= '<p class="sub">' . e(implode(' | ', $identitas)) . '</p>';

        if (!empty($mahasiswa['tentang'])) {
            $html .= '<h2>Tentang</h2><p>' . nl2br(e($mahasiswa['tentang'])) . '</p>';
        }

        if ($pendidikan) {
            $html .= '<h2>Pendidikan</h2>';
            foreach ($pendidikan as $p) {
                $html .= self::itemHtml($p);
            }
        }

        if ($pengalaman) {
            $html .= '<h2>Pengalaman</h2>';
            foreach ($pengalaman as $p) {
                $html .= self::itemHtml($p);
            }
        }

        if ($sertifikat) {
            $html .= '<h2>Sertifikat</h2>';
            foreach ($sertifikat as $p) {
                $html .= self::itemHtml($p);
            }
        }

        if ($portofolio) {
            $html .= '<h2>Portofolio</h2>';
            foreach ($portofolio as $p) {
                $html .= self::itemHtml($p);
            }
        }

        if ($skill) {
            $html .= '<h2>Skill</h2><p>';
            foreach ($skill as $s) {
                $html .= '<span class="chip">' . e($s['nama']) . '</span>';
            }
            $html .= '</p>';
        }

        // Status karier ikut ditampilkan supaya CV mencerminkan kondisi terkini.
        if (!empty($mahasiswa['status_karier'])) {
            $ringkas = Mahasiswa::ringkasanKarier($mahasiswa);
            $html .= '<h2>Status karier</h2><p>' . e(ucfirst($mahasiswa['status_karier']));
            if ($ringkas !== '-' && strcasecmp($ringkas, $mahasiswa['status_karier']) !== 0) {
                $html .= ' &mdash; ' . e($ringkas);
            }
            $html .= '</p>';
        }

        // Kalau profil masih kosong, beri penanda supaya mahasiswa sadar
        // CV-nya perlu dilengkapi dulu sebelum dikirim ke perusahaan.
        if (!$pendidikan && !$pengalaman && !$sertifikat && !$portofolio && !$skill) {
            $html .= '<h2>Catatan</h2><p style="color:#8a3a2f">Profil karier masih kosong. '
                   . 'Lengkapi pendidikan, pengalaman, sertifikat, dan skill di menu '
                   . 'Profil Karier supaya CV ini layak dikirim ke perusahaan.</p>';
        }

        $html .= '</body></html>';

        $namaFile = 'CV-' . preg_replace('/\s+/', '-', $mahasiswa['nama']) . '.pdf';
        self::keluarkan($html, $namaFile);
    }

    private static function itemHtml(array $p): string
    {
        $periode = trim(($p['mulai'] ? tanggalIndo($p['mulai']) : '') . ($p['selesai'] ? ' - ' . tanggalIndo($p['selesai']) : ($p['mulai'] ? ' - sekarang' : '')));
        return '<div class="item"><b>' . e($p['judul']) . '</b>'
            . ($p['instansi'] ? e($p['instansi']) . '<br>' : '')
            . ($periode ? '<span class="periode">' . e($periode) . '</span><br>' : '')
            . ($p['deskripsi'] ? nl2br(e($p['deskripsi'])) : '')
            . '</div>';
    }

    /* --------------------- 3 laporan Admin --------------------- */

    public static function rekapLowongan(array $baris): void
    {
        $html = self::headerLaporan('Rekap Lowongan per Perusahaan');
        $html .= '<table><tr><th>Perusahaan</th><th>Posisi</th><th>Bidang</th><th>Kuota</th><th>Terisi</th><th>Status</th><th>Batas Lamar</th></tr>';
        foreach ($baris as $b) {
            $html .= '<tr><td>' . e($b['nama_perusahaan']) . '</td><td>' . e($b['posisi']) . '</td><td>' . e($b['nama_bidang']) . '</td>'
                . '<td>' . e((string) $b['kuota']) . '</td><td>' . e((string) $b['terisi']) . '</td><td>' . e($b['status']) . '</td>'
                . '<td>' . tanggalIndo($b['batas_lamaran']) . '</td></tr>';
        }
        $html .= '</table>' . self::footerLaporan();
        self::keluarkan($html, 'Rekap-Lowongan-per-Perusahaan.pdf');
    }

    public static function rekapLamaran(array $baris): void
    {
        $html = self::headerLaporan('Rekap Lamaran');
        $html .= '<table><tr><th>Mahasiswa</th><th>Prodi</th><th>Angkatan</th><th>Jurusan</th><th>Posisi</th><th>Perusahaan</th><th>Status</th><th>Tanggal Lamar</th></tr>';
        foreach ($baris as $b) {
            $html .= '<tr><td>' . e($b['nama_mahasiswa']) . '</td><td>' . e($b['nama_prodi'] ?? '-') . '</td><td>' . e((string) ($b['angkatan'] ?? '-')) . '</td><td>' . e($b['nama_jurusan']) . '</td><td>' . e($b['posisi']) . '</td>'
                . '<td>' . e($b['nama_perusahaan']) . '</td><td>' . e($b['status']) . '</td><td>' . tanggalIndo($b['tanggal_lamar']) . '</td></tr>';
        }
        $html .= '</table>' . self::footerLaporan();
        self::keluarkan($html, 'Rekap-Lamaran.pdf');
    }

    public static function tracerKarier(array $baris): void
    {
        $html = self::headerLaporan('Laporan Tracer Karier Alumni');
        $html .= '<table><tr><th>Nama</th><th>Jurusan</th><th>Angkatan</th><th>Tahun Lulus</th><th>Status Karier</th><th>Tempat Kerja</th></tr>';
        foreach ($baris as $b) {
            $html .= '<tr><td>' . e($b['nama']) . '</td><td>' . e($b['nama_jurusan']) . '</td><td>' . e((string) $b['angkatan']) . '</td>'
                . '<td>' . e((string) ($b['tahun_lulus'] ?? '-')) . '</td><td>' . e($b['status_karier'] ?? 'belum bekerja') . '</td>'
                . '<td>' . e($b['tempat_kerja'] ?? '-') . '</td></tr>';
        }
        $html .= '</table>' . self::footerLaporan();
        self::keluarkan($html, 'Laporan-Tracer-Karier.pdf');
    }

    private static function headerLaporan(string $judul): string
    {
        return '<html><head><meta charset="utf-8"><style>
            @page { margin: 24px; }
            body{font-family:DejaVu Sans, Arial, sans-serif; font-size:11px; color:#1c2230;}
            h1{font-size:16px;color:#16305e;margin:0 0 2px}
            .sub{color:#5b6472;margin:0 0 16px;font-size:11px}
            table{width:100%;border-collapse:collapse}
            th,td{border:1px solid #dfe3ea;padding:6px 8px;text-align:left}
            th{background:#eaf0fb;color:#16305e}
            </style></head><body>
            <h1>' . e($judul) . '</h1>
            <p class="sub">KarirKu Polinema &middot; Diunduh ' . tanggalWaktuIndo(date('Y-m-d H:i:s')) . '</p>';
    }

    private static function footerLaporan(): string
    {
        return '</body></html>';
    }

    /**
     * Ambil isi di antara <body>...</body> dari HTML dokumen, plus seluruh
     * blok <style> di <head>, supaya bisa disisipkan ke dalam halaman
     * pembungkus tanpa membuat tag <html> bersarang.
     */
    private static function isiBody(string $html): string
    {
        $gaya = '';
        if (preg_match_all('#<style\b[^>]*>.*?</style>#is', $html, $m)) {
            $gaya = implode("\n", $m[0]);
        }
        if (preg_match('#<body\b[^>]*>(.*)</body>#is', $html, $mm)) {
            return $gaya . $mm[1];
        }
        return $html;
    }
}