<?php
// ===== BACKEND · HELPER · Item profil: pendidikan, pengalaman, sertifikat (revisi tahap 2) =====
// Satu definisi kolom untuk: formulir tambah/ubah, validasi server, tampilan di profil,
// detail pelamar (perusahaan), profil mahasiswa (admin), dan CV otomatis.
//
// Kolom 'kolom' => disimpan di kolom tabel profil_item (judul, instansi, mulai, selesai,
// deskripsi, tautan, file). Selain itu disimpan di profil_item.detail (JSONB).

const SKEMA_ITEM = [
    'pendidikan' => [
        'judul_tab' => 'Pendidikan', 'ikon' => 'graduation',
        'petunjuk' => 'Isi lengkap seperti yang diminta HRD: jenjang, institusi, program studi, nomor induk, nilai akhir, nomor ijazah, dan berkasnya.',
        'field' => [
            ['jenjang', 'Jenjang', 'select', true, ['SMA', 'SMK', 'MA', 'D1', 'D2', 'D3', 'D4 / Sarjana Terapan', 'S1', 'S2', 'S2 Terapan', 'S3']],
            ['instansi', 'Nama sekolah / perguruan tinggi', 'text', true, 'Politeknik Negeri Malang'],
            ['judul', 'Program studi / jurusan sekolah', 'text', true, 'D-IV Teknik Informatika'],
            ['fakultas', 'Jurusan / fakultas', 'text', false, 'Teknologi Informasi'],
            ['nomor_induk', 'NIM / NIS / NISN', 'text', false, '2241720001'],
            ['kota', 'Kota', 'text', false, 'Malang'],
            ['mulai', 'Tanggal masuk', 'date', true, ''],
            ['selesai', 'Tanggal lulus', 'date', false, 'Kosongkan bila masih kuliah/sekolah'],
            ['nilai', 'IPK / nilai akhir', 'text', false, '3,65'],
            ['skala', 'Skala nilai', 'select', false, ['4,00', '100']],
            ['nomor_ijazah', 'Nomor ijazah / SKL', 'text', false, 'Isi bila sudah lulus'],
            ['akreditasi', 'Akreditasi program studi', 'select', false, ['Unggul', 'A', 'Baik Sekali', 'B', 'Baik', 'C', 'Belum terakreditasi']],
            ['deskripsi', 'Prestasi, organisasi, atau judul tugas akhir', 'textarea', false, 'Contoh: Juara 2 Gemastik 2025; Ketua Himpunan; TA: Sistem Informasi Karier'],
            ['file', 'Scan ijazah / SKL', 'file', false, 'PDF, JPG, atau PNG maks. 2 MB'],
            ['file2', 'Transkrip nilai', 'file', false, 'PDF, JPG, atau PNG maks. 2 MB'],
        ],
    ],
    'pengalaman' => [
        'judul_tab' => 'Pengalaman', 'ikon' => 'briefcase',
        'petunjuk' => 'Tulis seperti di CV profesional: jenis, posisi, tempat, periode, tugas, pencapaian terukur, tools, dan referensi.',
        'field' => [
            ['jenis', 'Jenis pengalaman', 'select', true, ['Magang / PKL', 'Kerja penuh waktu', 'Kerja paruh waktu', 'Kontrak', 'Freelance', 'Proyek', 'Organisasi', 'Kepanitiaan', 'Relawan']],
            ['judul', 'Posisi / jabatan', 'text', true, 'Magang Frontend Developer'],
            ['instansi', 'Nama perusahaan / organisasi', 'text', true, 'PT Sinergi Data Nusantara'],
            ['bidang', 'Bidang / departemen', 'text', false, 'IT, Produksi, Keuangan, Pemasaran'],
            ['lokasi', 'Lokasi', 'text', false, 'Malang'],
            ['sistem', 'Sistem kerja', 'select', false, ['Di kantor (WFO)', 'Hybrid', 'Jarak jauh (WFH)']],
            ['mulai', 'Tanggal mulai', 'date', true, ''],
            ['selesai', 'Tanggal selesai', 'date', false, 'Kosongkan bila masih berjalan'],
            ['deskripsi', 'Tugas dan tanggung jawab', 'textarea', true, 'Contoh: Membuat halaman dashboard admin dengan Laravel; memperbaiki bug dari tim QA.'],
            ['pencapaian', 'Pencapaian / hasil kerja', 'textarea', false, 'Contoh: Mempercepat laporan bulanan 40%; menyelesaikan 12 fitur dalam 3 bulan.'],
            ['tools', 'Skill / tools yang dipakai', 'text', false, 'Laravel, PostgreSQL, Figma, Excel'],
            ['referensi_nama', 'Nama atasan / referensi', 'text', false, 'Hendra Wijaya (HR Manager)'],
            ['referensi_kontak', 'Kontak referensi', 'text', false, 'Email atau nomor WhatsApp'],
            ['file', 'Surat keterangan / paklaring', 'file', false, 'Opsional. PDF, JPG, atau PNG maks. 2 MB'],
        ],
    ],
    'sertifikat' => [
        'judul_tab' => 'Sertifikat', 'ikon' => 'shield',
        'petunjuk' => 'Cantumkan nomor kredensial dan tautan verifikasi agar perusahaan bisa mengecek keasliannya.',
        'field' => [
            ['jenis', 'Jenis sertifikat', 'select', true, ['Sertifikasi kompetensi (BNSP/LSP)', 'Sertifikasi profesional / internasional', 'Pelatihan / kursus', 'Kemampuan bahasa', 'Seminar / workshop', 'Lomba / penghargaan']],
            ['judul', 'Nama sertifikat', 'text', true, 'Junior Web Developer'],
            ['instansi', 'Lembaga penerbit', 'text', true, 'LSP Politeknik Negeri Malang'],
            ['nomor', 'Nomor / ID kredensial', 'text', false, '62090 2513 3 0001234 2025'],
            ['mulai', 'Tanggal terbit', 'date', true, ''],
            ['selesai', 'Berlaku sampai', 'date', false, 'Kosongkan bila berlaku seumur hidup'],
            ['skor', 'Skor / nilai / peringkat', 'text', false, 'Contoh: TOEFL ITP 550, Kompeten, Juara 1'],
            ['tautan', 'Tautan verifikasi', 'url', false, 'https://'],
            ['deskripsi', 'Kompetensi yang diuji / keterangan', 'textarea', false, 'Contoh: Merancang dan membangun aplikasi web sesuai SKKNI.'],
            ['file', 'File sertifikat', 'file', true, 'PDF, JPG, atau PNG maks. 2 MB'],
        ],
    ],
];
const KOLOM_ITEM = ['judul', 'instansi', 'mulai', 'selesai', 'deskripsi', 'tautan', 'file'];

/** Nilai satu field dari baris profil_item (kolom tabel atau detail JSON). */
function nilaiItem(?array $item, string $k): string
{
    if (!$item) return '';
    if (in_array($k, KOLOM_ITEM, true)) return (string) ($item[$k] ?? '');
    $d = is_array($item['detail'] ?? null) ? $item['detail'] : (json_decode((string) ($item['detail'] ?? '{}'), true) ?: []);
    return (string) ($d[$k] ?? '');
}

/** Detail JSON sebagai array. */
function detailItem(array $item): array
{
    return is_array($item['detail'] ?? null) ? $item['detail'] : (json_decode((string) ($item['detail'] ?? '{}'), true) ?: []);
}

/** Periode tampil: "Agu 2022 – Jul 2026" / "… – sekarang". */
function periodeItem(array $it, string $tipe): string
{
    $f = fn($t) => $t ? bulanTahunIndo($t) : '';
    if ($tipe === 'sertifikat') {
        $s = $it['mulai'] ? 'Terbit ' . $f($it['mulai']) : '';
        return $s . ($it['selesai'] ? ' · berlaku s.d. ' . $f($it['selesai']) : ($s ? ' · tanpa masa berlaku' : ''));
    }
    if (!$it['mulai']) return '';
    return $f($it['mulai']) . ' – ' . ($it['selesai'] ? $f($it['selesai']) : 'sekarang');
}

function bulanTahunIndo(string $t): string
{
    $b = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    $ts = strtotime($t);
    return $ts ? $b[(int) date('n', $ts) - 1] . ' ' . date('Y', $ts) : '';
}

/**
 * Baris detail untuk ditampilkan (label => nilai), tanpa judul/instansi/periode/deskripsi/berkas.
 * Dipakai di profil, detail pelamar, admin, dan CV.
 */
function detailTampilItem(array $it, string $tipe): array
{
    $hasil = [];
    foreach (SKEMA_ITEM[$tipe]['field'] ?? [] as [$k, $label, $jenis]) {
        if (in_array($k, ['judul', 'instansi', 'mulai', 'selesai', 'deskripsi', 'file', 'file2', 'skala', 'jenis', 'jenjang'], true)) continue;
        $v = trim(nilaiItem($it, $k));
        if ($v === '') continue;
        if ($k === 'nilai') {
            $sk = nilaiItem($it, 'skala');
            $v .= $sk ? ' (skala ' . $sk . ')' : '';
        }
        $hasil[$label] = $v;
    }
    return $hasil;
}

/** Berkas pada item: [label, nama_file] */
function berkasItem(array $it, string $tipe): array
{
    $hasil = [];
    foreach (SKEMA_ITEM[$tipe]['field'] ?? [] as [$k, $label, $jenis]) {
        if ($jenis !== 'file') continue;
        $f = nilaiItem($it, $k);
        if ($f !== '') $hasil[] = [$label, $f];
    }
    return $hasil;
}

/** Kartu item (HTML) untuk halaman profil/detail pelamar/admin. $aksiHtml = tombol tambahan (ubah/hapus). */
function kartuItemHtml(array $it, string $tipe, string $aksiHtml = ''): string
{
    $sk = SKEMA_ITEM[$tipe];
    $lencana = array_filter([nilaiItem($it, 'jenjang'), nilaiItem($it, 'jenis')]);
    $sub = trim($it['instansi'] ?? '');
    if ($tipe === 'pendidikan' && ($fak = nilaiItem($it, 'fakultas'))) $sub .= ' · ' . $fak;
    $html = '<div class="item-kartu"><span class="list-ic" data-ic="' . $sk['ikon'] . '"></span><div class="grow min-w-0">';
    $html .= '<div class="item-kepala"><b>' . e($it['judul']) . '</b>';
    foreach ($lencana as $l) $html .= '<span class="pill p-netral">' . e($l) . '</span>';
    $html .= '</div>';
    if ($sub !== '') $html .= '<div class="muted">' . e($sub) . '</div>';
    if ($p = periodeItem($it, $tipe)) $html .= '<div class="muted fs-88"><span data-ic="calendar"></span> ' . e($p) . '</div>';
    if ($det = detailTampilItem($it, $tipe)) {
        $html .= '<dl class="item-detail">';
        foreach ($det as $k => $v) {
            $isi = urlHttpValid($v) ? '<a href="' . e(tautanAman($v)) . '" target="_blank" rel="noopener noreferrer">' . e($v) . '</a>' : nl2br(e($v));
            $html .= '<div><dt>' . e($k) . '</dt><dd>' . $isi . '</dd></div>';
        }
        $html .= '</dl>';
    }
    if (!empty($it['deskripsi'])) {
        $judulDesk = ['pendidikan' => 'Prestasi / organisasi', 'pengalaman' => 'Tugas & tanggung jawab', 'sertifikat' => 'Keterangan'][$tipe] ?? '';
        $html .= '<div class="item-desk"><small class="muted">' . e($judulDesk) . '</small><p>' . nl2br(e($it['deskripsi'])) . '</p></div>';
    }
    $berkas = berkasItem($it, $tipe);
    if ($berkas || $aksiHtml) {
        $html .= '<div class="item-aksi">';
        foreach ($berkas as [$label, $f]) {
            $html .= '<a class="btn btn-sm btn-outline" href="' . e(url('unduh.php?tipe=portofolio&file=' . urlencode($f))) . '" target="_blank" rel="noopener"><span data-ic="file"></span>' . e($label) . '</a>';
        }
        $html .= $aksiHtml . '</div>';
    }
    return $html . '</div></div>';
}

/**
 * Formulir tambah/ubah item (isi modal). $item null = tambah. $bawaan = nilai awal (auto input).
 */
function formItemHtml(string $tipe, ?array $item = null, array $bawaan = []): string
{
    $sk = SKEMA_ITEM[$tipe];
    $idx = $item ? 'u' . (int) $item['id'] : 'baru' . $tipe;
    $html = '<p class="muted fs-88 m-0 mb-12">' . e($sk['petunjuk']) . '</p><div class="form-grid">';
    foreach ($sk['field'] as [$k, $label, $jenis, $wajib, $opsi]) {
        $id = 'f_' . $idx . '_' . $k;
        $nilai = $item ? nilaiItem($item, $k) : (string) ($bawaan[$k] ?? '');
        $tanda = $wajib && !($jenis === 'file' && $item) ? ' <span class="text-bad">*</span>' : ' <span class="muted fs-85">(opsional)</span>';
        $lebar = in_array($jenis, ['textarea', 'file'], true) || in_array($k, ['instansi', 'judul'], true) ? ' span-2' : '';
        $html .= '<div class="field' . $lebar . '"><label for="' . $id . '">' . e($label) . $tanda . '</label>';
        $req = $wajib && !($jenis === 'file' && $item && $nilai !== '') ? ' required' : '';
        if ($jenis === 'select') {
            $html .= '<select class="input" id="' . $id . '" name="' . $k . '"' . $req . '><option value="">Pilih</option>';
            foreach ($opsi as $o) $html .= '<option' . ($o === $nilai ? ' selected' : '') . '>' . e($o) . '</option>';
            $html .= '</select>';
        } elseif ($jenis === 'textarea') {
            $html .= '<textarea class="input" id="' . $id . '" name="' . $k . '" rows="3" maxlength="2000" placeholder="' . e($opsi) . '"' . $req . '>' . e($nilai) . '</textarea>';
        } elseif ($jenis === 'file') {
            if ($item && $nilai !== '') {
                $html .= '<div class="berkas-ada"><span data-ic="checkc"></span><a href="' . e(url('unduh.php?tipe=portofolio&file=' . urlencode($nilai))) . '" target="_blank" rel="noopener">Lihat berkas saat ini</a>'
                    . '<label class="check-inline fs-85"><input type="checkbox" name="hapus_' . $k . '" value="1"> hapus berkas ini</label></div>';
            }
            $html .= '<label class="upload"><input type="file" id="' . $id . '" name="' . $k . '" accept=".pdf,.jpg,.jpeg,.png" data-pratinjau="pv_' . $id . '" data-tipe="pdf,jpg,jpeg,png" data-maks-kb="2048"' . $req . '>'
                . '<span data-ic="upload"></span><div><b>' . ($item && $nilai !== '' ? 'Ganti berkas' : 'Pilih berkas') . '</b></div><div class="hint">' . e($opsi) . '</div></label>'
                . '<p class="pratinjau-pesan"></p><div class="pratinjau" id="pv_' . $id . '"></div>';
        } else {
            $tipeInput = $jenis === 'date' ? 'date' : ($jenis === 'url' ? 'url' : 'text');
            $ph = $jenis === 'date' ? '' : ' placeholder="' . e($opsi) . '"';
            $html .= '<input class="input" id="' . $id . '" type="' . $tipeInput . '" name="' . $k . '" value="' . e($nilai) . '" maxlength="255"' . $ph . $req . '>';
            if ($jenis === 'date' && $opsi) $html .= '<div class="hint">' . e($opsi) . '</div>';
        }
        $html .= '</div>';
    }
    return $html . '</div>';
}

/**
 * Validasi + susun data simpan dari $_POST. Mengembalikan [galat[], kolom[], detail[]].
 */
function validasiItem(string $tipe, array $post, bool $ubah, ?array $lama = null): array
{
    $galat = []; $kolom = []; $detail = $lama ? detailItem($lama) : [];
    foreach (SKEMA_ITEM[$tipe]['field'] as [$k, $label, $jenis, $wajib, $opsi]) {
        if ($jenis === 'file') {
            $adaBaru = ($_FILES[$k]['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE;
            $adaLama = $lama && nilaiItem($lama, $k) !== '' && empty($post['hapus_' . $k]);
            if ($wajib && !$adaBaru && !$adaLama) $galat[] = $label . ' wajib diunggah.';
            continue;
        }
        $v = trim((string) ($post[$k] ?? ''));
        if (is_array($post[$k] ?? null)) $v = '';
        if ($wajib && $v === '') { $galat[] = $label . ' wajib diisi.'; continue; }
        if ($v === '') { if (in_array($k, KOLOM_ITEM, true)) $kolom[$k] = null; else unset($detail[$k]); continue; }
        if ($jenis === 'select' && !in_array($v, $opsi, true)) { $galat[] = $label . ' tidak valid.'; continue; }
        if ($jenis === 'date' && !validasiTanggal($v)) { $galat[] = $label . ' tidak valid.'; continue; }
        if ($jenis === 'url' && !urlHttpValid($v)) { $galat[] = $label . ' harus berupa tautan lengkap (diawali https://).'; continue; }
        if (mb_strlen($v) > ($jenis === 'textarea' ? 2000 : 255)) { $galat[] = $label . ' terlalu panjang.'; continue; }
        if ($k === 'nilai') {
            $n = str_replace(',', '.', $v);
            $skala = (string) ($post['skala'] ?? '');
            if (!is_numeric($n) || $n < 0 || $n > ($skala === '100' ? 100 : 4)) { $galat[] = 'IPK / nilai akhir harus angka 0–' . ($skala === '100' ? '100' : '4,00') . '.'; continue; }
        }
        if (in_array($k, KOLOM_ITEM, true)) $kolom[$k] = $v; else $detail[$k] = $v;
    }
    $mulai = $kolom['mulai'] ?? null; $selesai = $kolom['selesai'] ?? null;
    if ($mulai && $selesai && $selesai < $mulai) {
        $galat[] = $tipe === 'sertifikat' ? 'Tanggal "berlaku sampai" tidak boleh sebelum tanggal terbit.' : 'Tanggal selesai/lulus tidak boleh lebih awal dari tanggal mulai/masuk.';
    }
    if ($mulai && $mulai > date('Y-m-d', strtotime('+1 year'))) $galat[] = 'Tanggal mulai terlalu jauh di masa depan.';
    if ($tipe === 'sertifikat' && $mulai && $mulai > date('Y-m-d')) $galat[] = 'Tanggal terbit sertifikat tidak boleh di masa depan.';
    return [$galat, $kolom, $detail];
}
