<?php
/**
 * View: publik/beranda
 * Dipanggil langsung oleh Router::renderBeranda() (tanpa controller) saat
 * URL kosong ("/") atau "beranda". Karena tanpa controller, variabel di
 * sini dihitung langsung di dalam view lewat kelas Auth (aman dipakai,
 * bootstrap.php sudah dimuat lebih dulu oleh public/index.php).
 */
$sudahLogin = Auth::sudahLogin();
$hrefDashboard = '#';
if ($sudahLogin) {
    $r = Auth::penggunaSaatIni()['role'];
    $hrefDashboard = url($r . '/dashboard');
}
?>
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>KarirKu Polinema | Pusat Karier Politeknik Negeri Malang</title>
<meta name="description" content="Pusat karier mahasiswa dan alumni Politeknik Negeri Malang. Lowongan dari perusahaan mitra terverifikasi Career Center.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Onest:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<?= url('assets/css/style.css') ?>">
</head>
<body>

<header class="nav">
  <div class="container nav-inner">
    <a class="brand" href="<?= url('beranda') ?>" aria-label="KarirKu Polinema, ke beranda">
      <span class="brand-mark">
        <img src="<?= url('assets/img/logo-polinema.png') ?>" alt="Logo KarirKu Polinema">
      </span>
      <span>KarirKu Polinema<small>Career Center Politeknik Negeri Malang</small></span>
    </a>
    <button class="nav-toggle" aria-label="Buka menu" aria-expanded="false" data-ic="menu"></button>
    <ul class="nav-links">
      <li><a href="#beranda">Beranda</a></li>
      <li class="dropdown">
        <button aria-expanded="false">Tentang <span data-ic="chevron"></span></button>
        <div class="dropdown-menu">
          <a href="#tentang">Tentang KarirKu</a>
          <a href="#visi">Visi dan misi Polinema</a>
          <a href="#kontak">Career Center</a>
        </div>
      </li>
      <li><a href="#alur">Alur</a></li>
      <li><a href="#mitra">Mitra</a></li>
      <li><a href="#faq">FAQ</a></li>
      <li><a href="#kontak">Kontak</a></li>
    </ul>
    <div class="nav-actions">
      <?php if ($sudahLogin): ?>
        <a class="btn btn-sm btn-reg" href="<?= $hrefDashboard ?>">Ke Dashboard</a>
      <?php else: ?>
        <a class="btn btn-sm btn-login" href="<?= url('masuk') ?>">Masuk</a>
        <a class="btn btn-sm btn-reg" href="<?= url('daftar') ?>">Daftar</a>
      <?php endif; ?>
    </div>
  </div>
</header>

<main>
<section class="hero" id="beranda" aria-roledescription="carousel" aria-label="Sorotan KarirKu">
  <div class="hero-slide active"><img src="<?= url('assets/img/hero-1.jpg') ?>" alt="Mahasiswa Politeknik Negeri Malang di kampus"></div>
  <div class="hero-slide"><img src="<?= url('assets/img/hero-2.jpg') ?>" alt="Wisuda lulusan Politeknik Negeri Malang"></div>
  <div class="hero-slide"><img src="<?= url('assets/img/hero-3.jpg') ?>" alt="Praktik mahasiswa di laboratorium"></div>
  <div class="hero-slide"><img src="<?= url('assets/img/hero-4.jpg') ?>" alt="Kerja sama Polinema dengan mitra industri"></div>
  <div class="hero-shade"></div>
  <div class="hero-pattern"></div>

  <div class="container hero-content">
    <div class="hero-text">
      <span class="hero-kicker">Pendidikan vokasi, siap kerja</span>
      <h1>Lulusan vokasi Polinema, siap masuk industri</h1>
      <p>KarirKu mempertemukan mahasiswa dan alumni Politeknik Negeri Malang dengan perusahaan mitra yang membutuhkan keterampilan terapan, dalam satu tempat yang dikelola Career Center.</p>
      <div class="hero-cta">
        <a class="btn btn-white" href="<?= url('daftar') ?>">Daftar sekarang</a>
        <a class="btn btn-ghost-light" href="#alur">Lihat alurnya</a>
      </div>
    </div>
    <div class="hero-text" hidden>
      <span class="hero-kicker">Visi Politeknik Negeri Malang</span>
      <h1>Vokasi unggul dalam persaingan global</h1>
      <p>Keterampilan yang diasah lewat praktik, proyek, dan kerja sama industri diarahkan menjadi karier nyata bagi setiap lulusan.</p>
      <div class="hero-cta">
        <a class="btn btn-white" href="#visi">Baca visi dan misi</a>
        <a class="btn btn-ghost-light" href="<?= url('masuk') ?>">Masuk</a>
      </div>
    </div>
    <div class="hero-text" hidden>
      <span class="hero-kicker">Link and match</span>
      <h1>Satu pintu lowongan dari mitra terverifikasi</h1>
      <p>Setiap perusahaan diperiksa Career Center sebelum bisa memasang lowongan. Kamu melamar dengan tenang dan memantau prosesnya sampai selesai.</p>
      <div class="hero-cta">
        <a class="btn btn-white" href="<?= url('daftar') ?>">Buat akun mahasiswa</a>
        <a class="btn btn-ghost-light" href="<?= url('daftar?peran=perusahaan') ?>">Daftar sebagai perusahaan</a>
      </div>
    </div>
    <div class="hero-text" hidden>
      <span class="hero-kicker">Tetap terhubung dengan kampus</span>
      <h1>Karier alumni tercatat, kampus terus belajar</h1>
      <p>Saat kamu diterima kerja, data karier ikut tercatat otomatis. Career Center memakainya untuk memperkuat kurikulum dan kerja sama industri.</p>
      <div class="hero-cta">
        <a class="btn btn-white" href="#tentang">Tentang KarirKu</a>
        <a class="btn btn-ghost-light" href="#faq">Pertanyaan umum</a>
      </div>
    </div>
  </div>

  <div class="hero-tabs">
    <div class="container" role="tablist">
      <button class="hero-tab active" role="tab"><span class="bar"></span>Lulusan vokasi siap industri</button>
      <button class="hero-tab" role="tab"><span class="bar"></span>Vokasi unggul, bersaing global</button>
      <button class="hero-tab" role="tab"><span class="bar"></span>Lowongan dari mitra terverifikasi</button>
      <button class="hero-tab" role="tab"><span class="bar"></span>Karier alumni tercatat otomatis</button>
    </div>
  </div>
</section>

<section class="sec" id="tentang">
  <div class="container about">
    <div>
      <h2>Tentang KarirKu</h2>
      <p class="muted">KarirKu Polinema adalah sistem karier resmi yang dikelola Career Center Politeknik Negeri Malang. Sistem ini lahir dari satu masalah sederhana: info lowongan tersebar di Instagram, grup, dan flyer, sehingga banyak mahasiswa dan alumni tertinggal.</p>
      <p class="muted">Sekarang lowongan, lamaran, dan data karier berada di satu tempat. Khusus untuk mahasiswa dan alumni Polinema, serta perusahaan yang sudah diverifikasi.</p>
      <div class="visi" id="visi">
        <span>Visi Politeknik Negeri Malang</span>
        <q>Menjadi lembaga pendidikan tinggi vokasi yang unggul dalam persaingan global.</q>
      </div>
      <ul class="misi">
        <li><span data-ic="graduation"></span><span>Pendidikan vokasi yang berkualitas, inovatif, dan sesuai kebutuhan industri, pemerintah, dan masyarakat.</span></li>
        <li><span data-ic="trending"></span><span>Mendorong pembelajaran sepanjang hayat dan tumbuhnya jiwa kewirausahaan.</span></li>
        <li><span data-ic="handshake"></span><span>Kerja sama yang saling menguntungkan dengan berbagai pihak, di dalam maupun luar negeri.</span></li>
      </ul>
    </div>
    <div class="about-photo"><img src="<?= url('assets/img/about.jpg') ?>" alt="Kegiatan mahasiswa Politeknik Negeri Malang"></div>
  </div>
</section>

<section class="sec sec-sky" id="alur">
  <div class="container">
    <div class="sec-head">
      <h2>Cara memakai KarirKu</h2>
      <p>Empat langkah dari daftar sampai diterima kerja. Pilih peranmu untuk melihat alurnya.</p>
    </div>
    <div class="tabs-pill" data-tabs="alur-panes" role="tablist">
      <button class="active" data-tab="mhs">Mahasiswa dan alumni</button>
      <button data-tab="pt">Perusahaan</button>
    </div>
    <div id="alur-panes">
      <div class="steps" data-pane="mhs">
        <div class="step"><div class="step-num">1</div><h3>Daftar dan diverifikasi</h3><p>Isi NIM, prodi, dan unggah KTM atau ijazah. Career Center memeriksa datamu.</p></div>
        <div class="step"><div class="step-num">2</div><h3>Lengkapi profil karier</h3><p>Tambahkan foto, skill, pengalaman, dan portofolio. CV dibuat otomatis dari profilmu.</p></div>
        <div class="step"><div class="step-num">3</div><h3>Cari dan lamar lowongan</h3><p>Saring lowongan sesuai jurusan, simpan yang menarik, lalu kirim lamaran dengan sekali klik.</p></div>
        <div class="step"><div class="step-num">4</div><h3>Pantau sampai diterima</h3><p>Status lamaran dan jadwal interview muncul di notifikasi. Diterima, status kariermu ikut diperbarui.</p></div>
      </div>
      <div class="steps" data-pane="pt" hidden>
        <div class="step"><div class="step-num">1</div><h3>Daftar dan verifikasi legalitas</h3><p>Isi data perusahaan dan PIC, lalu unggah NIB. Perusahaan outsourcing tidak diterima.</p></div>
        <div class="step"><div class="step-num">2</div><h3>Lengkapi profil perusahaan</h3><p>Logo dan deskripsi tampil di setiap lowongan agar pelamar mengenal perusahaanmu.</p></div>
        <div class="step"><div class="step-num">3</div><h3>Pasang lowongan dan pamflet</h3><p>Lowongan langsung tayang. Career Center meneruskan pamfletnya ke admin tiap jurusan.</p></div>
        <div class="step"><div class="step-num">4</div><h3>Seleksi pelamar</h3><p>Lihat profil lengkap, CV, dan portofolio pelamar. Ubah status dan atur jadwal interview.</p></div>
      </div>
    </div>
    <p class="note"><span data-ic="info"></span><span>Verifikasi akun paling lama 2 hari kerja. Kamu akan menerima email dan bisa memantau statusnya setelah masuk.</span></p>
  </div>
</section>

<section class="sec" id="keunggulan">
  <div class="container feature-wrap">
    <div class="big-photo">
      <img src="<?= url('assets/img/hero-3.jpg') ?>" alt="Mahasiswa praktik di laboratorium Polinema">
      <div class="photo-tag"><span class="feature-ic" data-ic="shield"></span><span><b>Dikelola Career Center Polinema</b>Setiap akun diperiksa sebelum aktif</span></div>
    </div>
    <div>
      <div class="sec-head">
        <h2>Dibuat untuk lulusan yang siap kerja</h2>
        <p>Semua fitur dirancang agar keterampilan vokasi cepat bertemu dengan kebutuhan industri.</p>
      </div>
      <div class="feature-list">
        <div class="feature"><span class="feature-ic" data-ic="wand"></span><div><h3>CV jadi dari profilmu</h3><p>Isi profil sekali, unduh CV rapi dalam format PDF. Punya CV sendiri? Unggah juga bisa.</p></div></div>
        <div class="feature"><span class="feature-ic" data-ic="clock"></span><div><h3>Status lamaran selalu jelas</h3><p>Diajukan, screening, interview, sampai hasil akhir. Tidak perlu menebak lagi.</p></div></div>
        <div class="feature"><span class="feature-ic" data-ic="shield"></span><div><h3>Hanya mitra terverifikasi</h3><p>Legalitas perusahaan diperiksa Career Center sehingga lowongan lebih aman.</p></div></div>
        <div class="feature"><span class="feature-ic" data-ic="chart"></span><div><h3>Data karier tercatat otomatis</h3><p>Diterima kerja langsung tercatat sebagai data tracer tanpa survei tambahan.</p></div></div>
      </div>
    </div>
  </div>
</section>

<section class="sec sec-sky" id="mitra">
  <div class="container">
    <div class="sec-head">
      <h2>Perusahaan mitra</h2>
      <p>Perusahaan yang sudah terverifikasi dan merekrut lulusan vokasi Polinema.</p>
    </div>
    <?php if (!empty($mitra)): ?>
      <div class="partners">
        <?php foreach ($mitra as $m): ?>
          <?php
            // Huruf awal dipakai kalau perusahaan belum mengunggah logo.
            $tanpaBadan = preg_replace('/^(PT|CV)\s+/i', '', $m['nama_perusahaan']);
            $inisial    = mb_strtoupper(mb_substr($tanpaBadan, 0, 1));
            $aktif      = (int) ($m['lowongan_aktif'] ?? 0);
          ?>
          <div class="partner">
            <span class="ikon">
              <?php if (!empty($m['logo'])): ?>
                <img src="<?= url('unduh.php?tipe=logo&file=' . urlencode($m['logo'])) ?>"
                     alt="Logo <?= e($m['nama_perusahaan']) ?>">
              <?php else: ?>
                <?= e($inisial) ?>
              <?php endif; ?>
            </span>
            <span class="teks">
              <span class="nm" title="<?= e($m['nama_perusahaan']) ?>"><?= e($m['nama_perusahaan']) ?></span>
              <span class="sub">
                <?php if ($aktif > 0): ?>
                  <b><?= $aktif ?> lowongan aktif</b>
                <?php else: ?>
                  <?= e($m['bidang_usaha'] ?: $m['kota']) ?>
                <?php endif; ?>
              </span>
            </span>
          </div>
        <?php endforeach; ?>
        <?php $sisa = (int) ($statistik['perusahaan'] ?? 0) - count($mitra); ?>
        <?php if ($sisa > 0): ?>
          <div class="partner partner-sisa">dan <?= $sisa ?> perusahaan lainnya</div>
        <?php endif; ?>
      </div>
    <?php else: ?>
      <p class="muted">Belum ada perusahaan terverifikasi. Perusahaan yang lolos verifikasi Career Center akan muncul di sini.</p>
    <?php endif; ?>
    <?php if (!empty($lowonganTerbaru)): ?>
      <div class="sec-head" style="margin-top:46px">
        <h2>Lowongan terbaru</h2>
        <p>
          <?= (int) ($statistik['lowongan'] ?? 0) ?> lowongan sedang menerima lamaran dari
          <?= (int) ($statistik['perusahaan'] ?? 0) ?> perusahaan terverifikasi.
          Masuk untuk melihat semuanya dan melamar.
        </p>
      </div>
      <div class="loker-grid">
        <?php foreach ($lowonganTerbaru as $l): ?>
          <a class="loker-kartu" href="<?= url('info-loker/' . $l['kode_pratinjau']) ?>">
            <h3><?= e($l['posisi']) ?></h3>
            <span class="pt"><?= e($l['nama_perusahaan']) ?></span>
            <div class="meta">
              <span><?= e($l['lokasi']) ?></span>
              <span><?= e($l['jenis_pekerjaan']) ?></span>
              <span><?= e($l['sistem_kerja']) ?></span>
            </div>
            <div class="meta">Lamar sebelum <?= e(tanggalIndo($l['batas_lamaran'])) ?></div>
            <?php if (!empty($l['jurusan_sasaran'])): ?>
              <div class="jur">Untuk jurusan <?= e($l['jurusan_sasaran']) ?></div>
            <?php endif; ?>
          </a>
        <?php endforeach; ?>
      </div>
      <div style="text-align:center;margin-bottom:46px">
        <?php
          /* Daftar lowongan hanya untuk mahasiswa. Peran lain diarahkan ke
             halaman yang memang miliknya, supaya tidak berakhir di 403. */
          $peranKini = class_exists('Auth') ? (Auth::penggunaSaatIni()['role'] ?? null) : null;
          [$tujuanLoker, $labelLoker] = [
              'mahasiswa'  => ['lowongan/daftar', 'Lihat semua lowongan'],
              'perusahaan' => ['perusahaan/lowongan', 'Kelola lowongan saya'],
              'admin'      => ['admin/monitoring-lowongan', 'Buka monitoring lowongan'],
          ][$peranKini] ?? ['masuk', 'Masuk untuk melihat semua lowongan'];
        ?>
        <a class="btn btn-outline" href="<?= url($tujuanLoker) ?>"><?= e($labelLoker) ?></a>
      </div>
    <?php endif; ?>

    <div class="cta-band">
      <div class="hero-pattern" style="width:40%;left:auto;right:0"></div>
      <div style="position:relative">
        <h3>Butuh talenta vokasi yang terampil?</h3>
        <p>Daftarkan perusahaan Anda dan rekrut lulusan Politeknik Negeri Malang.</p>
      </div>
      <a class="btn btn-white" href="<?= url('daftar?peran=perusahaan') ?>" style="position:relative">Daftar sebagai perusahaan</a>
    </div>
  </div>
</section>

<section class="sec" id="faq">
  <div class="container">
    <div class="sec-head"><h2>Pertanyaan umum</h2></div>
    <div class="faq">
      <details open><summary>Siapa yang bisa mendaftar?</summary><p>Mahasiswa aktif dan alumni Politeknik Negeri Malang, serta perusahaan yang ingin merekrut. Perusahaan outsourcing tidak dapat mendaftar.</p></details>
      <details><summary>Kenapa lowongan hanya bisa dilihat setelah masuk?</summary><p>KarirKu khusus untuk civitas Polinema. Dengan begitu lowongan dari mitra hanya diterima oleh mahasiswa dan alumni yang sudah diverifikasi.</p></details>
      <details><summary>Berapa lama akun saya diverifikasi?</summary><p>Paling lama 2 hari kerja. Selama menunggu, kamu tetap bisa masuk untuk melihat progres di halaman Status Akun.</p></details>
      <details><summary>Bagaimana saya tahu akun sudah disetujui?</summary><p>Kamu menerima email dari KarirKu Polinema, linimasa di halaman Status Akun berubah hijau, dan saat masuk muncul ucapan selamat datang beserta lencana Terverifikasi.</p></details>
      <details><summary>Apakah ada biaya?</summary><p>Tidak. KarirKu gratis untuk mahasiswa, alumni, dan perusahaan mitra.</p></details>
    </div>
  </div>
</section>

<section class="sec sec-sky" id="kontak">
  <div class="container contact">
    <div>
      <h2>Hubungi Career Center</h2>
      <p class="muted">Ada kendala dengan akun atau lowongan? Hubungi kami lewat email dan media sosial, atau datang langsung ke kantor Career Center.</p>
      <ul class="contact-list">
        <li><span data-ic="pin"></span><span><b>Graha Polinema Lantai 3</b><br>Politeknik Negeri Malang, Jl. Soekarno Hatta No. 9, Malang<br><a href="https://www.google.com/maps/search/?api=1&query=Graha+Polinema+Politeknik+Negeri+Malang" target="_blank" rel="noopener">Buka di Google Maps</a></span></li>
        <li><span data-ic="clock"></span><span><b>Layanan tatap muka</b><br>08.00 sampai 16.00 WIB</span></li>
        <li><span data-ic="mail"></span><span><b>Email</b><br><a href="mailto:jpc@polinema.ac.id">jpc@polinema.ac.id</a></span></li>
        <li><span data-ic="instagram"></span><span><b>Instagram</b><br><a href="https://www.instagram.com/polinemacareercenter/" target="_blank" rel="noopener">@polinemacareercenter</a></span></li>
        <li><span data-ic="facebook"></span><span><b>Facebook</b><br><a href="https://www.facebook.com/lokerjpcpolinema" target="_blank" rel="noopener">lokerjpcpolinema</a></span></li>
      </ul>
    </div>
    <div class="map">
      <iframe src="https://maps.google.com/maps?q=Graha%20Polinema%20Politeknik%20Negeri%20Malang&z=16&output=embed" title="Peta lokasi Graha Polinema, Politeknik Negeri Malang" loading="lazy" referrerpolicy="no-referrer-when-downgrade" allowfullscreen></iframe>
      <a class="map-open" href="https://www.google.com/maps/search/?api=1&query=Graha+Polinema+Politeknik+Negeri+Malang" target="_blank" rel="noopener"><span data-ic="external"></span>Buka di Google Maps</a>
    </div>
  </div>
</section>
</main>

<footer class="footer">
  <div class="container">
    <div class="footer-grid">
      <div>
        <a class="brand" href="<?= url('beranda') ?>" style="color:#fff;margin-bottom:14px"><img class="brand-mark" src="<?= asetUrl('assets/img/logo-polinema.png') ?>" alt="Logo Politeknik Negeri Malang"><span>KarirKu Polinema</span></a>
        <p>Pusat karier mahasiswa dan alumni Politeknik Negeri Malang. Menghubungkan pendidikan vokasi dengan dunia industri.</p>
      </div>
      <div><h4>Jelajahi</h4><ul><li><a href="#tentang">Tentang KarirKu</a></li><li><a href="#alur">Alur penggunaan</a></li><li><a href="#mitra">Mitra</a></li><li><a href="#faq">FAQ</a></li></ul></div>
      <div><h4>Akun</h4><ul><li><a href="<?= url('masuk') ?>">Masuk</a></li><li><a href="<?= url('daftar') ?>">Daftar mahasiswa atau alumni</a></li><li><a href="<?= url('daftar?peran=perusahaan') ?>">Daftar perusahaan</a></li></ul></div>
      <div><h4>Kontak</h4><ul class="footer-contact">
        <li><a href="https://www.google.com/maps/search/?api=1&query=Graha+Polinema+Politeknik+Negeri+Malang" target="_blank" rel="noopener"><span data-ic="pin"></span>Graha Polinema Lantai 3</a></li>
        <li><span class="fc-row"><span data-ic="clock"></span>08.00 sampai 16.00 WIB</span></li>
        <li><a href="mailto:jpc@polinema.ac.id"><span data-ic="mail"></span>jpc@polinema.ac.id</a></li>
        <li><a href="https://www.instagram.com/polinemacareercenter/" target="_blank" rel="noopener"><span data-ic="instagram"></span>polinemacareercenter</a></li>
        <li><a href="https://www.facebook.com/lokerjpcpolinema" target="_blank" rel="noopener"><span data-ic="facebook"></span>lokerjpcpolinema</a></li>
      </ul></div>
    </div>
    <div class="footer-bottom"><span>&copy; <?= date('Y') ?> Career Center Politeknik Negeri Malang</span><span>Proyek PBL D-IV Teknik Informatika</span></div>
  </div>
</footer>

<a class="fab" href="#kontak"><span data-ic="chat"></span>Tanya Career Center</a>

<script src="<?= url('assets/js/app.js') ?>"></script>
</body>
</html>
