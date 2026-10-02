-- ===========================================================================
-- Migrasi revisi KarirKu Polinema
--
-- KAPAN INI DIJALANKAN
--   Hanya kalau database kamu SUDAH pernah diisi 01-schema.sql versi lama.
--   Kalau kamu membuat database dari nol dengan 01-schema.sql yang baru,
--   kolom di bawah sudah ikut terbuat dan file ini tidak perlu dijalankan.
--
--   Aman dijalankan berulang kali (memakai IF NOT EXISTS).
--
-- ISI PERUBAHAN
--   1. Tabel mahasiswa  : kolom tambahan untuk Status Karier yang isinya
--                         berbeda-beda tergantung status yang dipilih.
--   2. Tabel interview  : kolom tambahan khusus interview luring
--                         (tempat, ruangan, dresscode, yang dibawa, narahubung).
-- ===========================================================================

-- --------------------------------------------------------------------------
-- 1. Status karier yang menyesuaikan pilihan mahasiswa
-- --------------------------------------------------------------------------
ALTER TABLE mahasiswa ADD COLUMN IF NOT EXISTS karier_fakultas       varchar(150);
ALTER TABLE mahasiswa ADD COLUMN IF NOT EXISTS karier_bidang_minat   varchar(255);
ALTER TABLE mahasiswa ADD COLUMN IF NOT EXISTS karier_rencana_posisi varchar(255);
ALTER TABLE mahasiswa ADD COLUMN IF NOT EXISTS karier_tahap_studi    varchar(20);
ALTER TABLE mahasiswa ADD COLUMN IF NOT EXISTS karier_catatan        text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'mahasiswa_karier_tahap_studi_check'
  ) THEN
    ALTER TABLE mahasiswa ADD CONSTRAINT mahasiswa_karier_tahap_studi_check
      CHECK (karier_tahap_studi IS NULL
             OR karier_tahap_studi IN ('rencana','diterima','sedang berjalan'));
  END IF;
END $$;

COMMENT ON COLUMN mahasiswa.karier_fakultas       IS 'Khusus status studi lanjut';
COMMENT ON COLUMN mahasiswa.karier_bidang_minat   IS 'Khusus status mencari kerja dan belum bekerja';
COMMENT ON COLUMN mahasiswa.karier_rencana_posisi IS 'Khusus status mencari kerja';
COMMENT ON COLUMN mahasiswa.karier_tahap_studi    IS 'Khusus studi lanjut: rencana, diterima, sedang berjalan';

-- --------------------------------------------------------------------------
-- 2. Detail interview luring
-- --------------------------------------------------------------------------
ALTER TABLE interview ADD COLUMN IF NOT EXISTS tempat      varchar(255);
ALTER TABLE interview ADD COLUMN IF NOT EXISTS ruangan     varchar(100);
ALTER TABLE interview ADD COLUMN IF NOT EXISTS dresscode   varchar(255);
ALTER TABLE interview ADD COLUMN IF NOT EXISTS yang_dibawa varchar(500);
ALTER TABLE interview ADD COLUMN IF NOT EXISTS narahubung  varchar(255);

COMMENT ON COLUMN interview.tempat      IS 'Khusus mode luring: nama gedung atau alamat';
COMMENT ON COLUMN interview.ruangan     IS 'Khusus mode luring';
COMMENT ON COLUMN interview.dresscode   IS 'Khusus mode luring';
COMMENT ON COLUMN interview.yang_dibawa IS 'Khusus mode luring: berkas yang perlu dibawa pelamar';
COMMENT ON COLUMN interview.narahubung  IS 'Khusus mode luring: nama dan nomor yang dihubungi saat tiba';

-- --------------------------------------------------------------------------
-- 3. Daftar skill awal supaya tab Skills tidak kosong saat pertama dibuka.
--    Mahasiswa tetap bisa menambah skill baru sendiri lewat Profil Karier.
-- --------------------------------------------------------------------------
INSERT INTO skill (nama) VALUES
  ('HTML'), ('CSS'), ('JavaScript'), ('PHP'), ('Laravel'), ('CodeIgniter'),
  ('PostgreSQL'), ('MySQL'), ('Git'), ('Figma'), ('UI/UX Design'),
  ('Python'), ('Java'), ('Microsoft Excel'), ('AutoCAD'), ('SolidWorks'),
  ('Komunikasi'), ('Kerja sama tim'), ('Manajemen waktu'), ('Bahasa Inggris')
ON CONFLICT (nama) DO NOTHING;

-- --------------------------------------------------------------------------
-- 4. Jenjang S2 Terapan (Magister Terapan) ikut didaftarkan, karena Polinema
--    juga membuka program pascasarjana. Tanpa ini, baris S2 di 02-seed.sql
--    ditolak oleh CHECK lama yang hanya mengizinkan D-II, D-III, dan D-IV.
-- --------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'program_studi_jenjang_check'
  ) THEN
    ALTER TABLE program_studi DROP CONSTRAINT program_studi_jenjang_check;
  END IF;
  ALTER TABLE program_studi ADD CONSTRAINT program_studi_jenjang_check
    CHECK (jenjang IN ('D-II','D-III','D-IV','S2'));
END $$;

-- --------------------------------------------------------------------------
-- 5. Nama program studi dibersihkan dari awalan jenjang.
--    Tampilan menggabungkan jenjang + nama, jadi "D-III Teknik Sipil" pada
--    kolom nama membuat labelnya terbaca ganda: "D-III D-III Teknik Sipil".
-- --------------------------------------------------------------------------
UPDATE program_studi
   SET nama = btrim(regexp_replace(nama, '^(D-?I{1,3}V?|D[234]|S[123])\s+', ''))
 WHERE nama ~ '^(D-?I{1,3}V?|D[234]|S[123])\s';

-- --------------------------------------------------------------------------
-- 6. Satu jurusan boleh punya nama program studi yang sama di dua jenjang,
--    misalnya Teknik Elektronika pada D-III dan D-IV. Kunci unik lama hanya
--    memakai (jurusan_id, nama) sehingga salah satunya tertolak.
-- --------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'program_studi_jurusan_id_nama_key'
  ) THEN
    ALTER TABLE program_studi DROP CONSTRAINT program_studi_jurusan_id_nama_key;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'program_studi_jurusan_id_nama_jenjang_key'
  ) THEN
    ALTER TABLE program_studi
      ADD CONSTRAINT program_studi_jurusan_id_nama_jenjang_key
      UNIQUE (jurusan_id, nama, jenjang);
  END IF;
END $$;

-- ===========================================================================
-- 7. JURUSAN DAN PROGRAM STUDI DISAMAKAN DENGAN DAFTAR RESMI POLINEMA
--
--    Bagian ini yang membuat pilihan di halaman pendaftaran ikut berubah.
--    Aman untuk database yang sudah berisi data: mahasiswa yang sudah
--    terdaftar tidak dihapus, hanya dipindahkan ke program studi resmi
--    yang paling cocok bila program studi lamanya tidak ada di daftar.
-- ===========================================================================

-- Daftar resmi dipakai berulang di beberapa langkah, jadi disimpan sementara.
-- Tabelnya dihapus lagi di akhir bagian ini.
DROP TABLE IF EXISTS prodi_resmi;
CREATE TEMP TABLE prodi_resmi (jurusan text, nama text, jenjang text);
INSERT INTO prodi_resmi (jurusan, nama, jenjang) VALUES
    ('Teknik Sipil', 'Teknik Sipil', 'D-III'),
    ('Teknik Sipil', 'Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air', 'D-III'),
    ('Teknik Sipil', 'Teknologi Pertambangan', 'D-III'),
    ('Teknik Sipil', 'Teknologi Rekayasa Konstruksi Jalan dan Jembatan', 'D-IV'),
    ('Teknik Sipil', 'Manajemen Rekayasa Konstruksi', 'D-IV'),
    ('Teknik Mesin', 'Teknik Mesin', 'D-III'),
    ('Teknik Mesin', 'Teknologi Pemeliharaan Pesawat Udara', 'D-III'),
    ('Teknik Mesin', 'Teknik Mesin Produksi dan Perawatan', 'D-IV'),
    ('Teknik Mesin', 'Teknik Otomotif Elektronik', 'D-IV'),
    ('Teknik Mesin', 'Terapan Rekayasa Teknologi Manufaktur', 'S2'),
    ('Teknik Elektro', 'Teknik Listrik', 'D-III'),
    ('Teknik Elektro', 'Teknik Elektronika', 'D-III'),
    ('Teknik Elektro', 'Teknik Telekomunikasi', 'D-III'),
    ('Teknik Elektro', 'Sistem Kelistrikan', 'D-IV'),
    ('Teknik Elektro', 'Teknik Elektronika', 'D-IV'),
    ('Teknik Elektro', 'Jaringan Telekomunikasi Digital', 'D-IV'),
    ('Teknik Elektro', 'Terapan Teknik Elektro', 'S2'),
    ('Teknik Kimia', 'Teknik Kimia', 'D-III'),
    ('Teknik Kimia', 'Teknologi Kimia Industri', 'D-IV'),
    ('Teknik Kimia', 'Terapan Optimasi Rekayasa Kimia', 'S2'),
    ('Teknologi Informasi', 'Pengembangan Peranti Lunak Situs', 'D-II'),
    ('Teknologi Informasi', 'Teknik Informatika', 'D-IV'),
    ('Teknologi Informasi', 'Sistem Informasi Bisnis', 'D-IV'),
    ('Teknologi Informasi', 'Terapan Rekayasa Teknologi Informasi', 'S2'),
    ('Akuntansi', 'Akuntansi', 'D-III'),
    ('Akuntansi', 'Akuntansi Manajemen', 'D-IV'),
    ('Akuntansi', 'Keuangan', 'D-IV'),
    ('Akuntansi', 'Terapan Sistem Informasi Akuntansi', 'S2'),
    ('Administrasi Niaga', 'Administrasi Bisnis', 'D-III'),
    ('Administrasi Niaga', 'Manajemen Pemasaran Digital', 'D-IV'),
    ('Administrasi Niaga', 'Pengelolaan Arsip dan Rekaman Informasi', 'D-IV'),
    ('Administrasi Niaga', 'Bahasa Inggris untuk Komunikasi Bisnis dan Profesional', 'D-IV');

-- 7a. Jurusan yang belum ada ditambahkan.
INSERT INTO jurusan (nama)
  SELECT DISTINCT jurusan FROM prodi_resmi
 ON CONFLICT (nama) DO NOTHING;

-- 7b. Program studi resmi ditambahkan. Yang sudah ada dilewati, sehingga
--     mahasiswa yang menempel padanya tetap aman.
INSERT INTO program_studi (jurusan_id, nama, jenjang)
  SELECT j.id, pr.nama, pr.jenjang
    FROM prodi_resmi pr JOIN jurusan j ON j.nama = pr.jurusan
 ON CONFLICT DO NOTHING;

-- 7c. Mahasiswa yang masih menempel pada program studi di luar daftar resmi
--     dipindahkan ke program studi resmi di jurusan yang sama: yang namanya
--     sama kalau ada, kalau tidak ada diambil yang pertama di jurusan itu.
UPDATE mahasiswa m
   SET program_studi_id = pengganti.id
  FROM program_studi lama
       JOIN jurusan j ON j.id = lama.jurusan_id
       LEFT JOIN LATERAL (
         SELECT ps.id
           FROM program_studi ps
           JOIN prodi_resmi pr
             ON pr.jurusan = j.nama AND pr.nama = ps.nama AND pr.jenjang = ps.jenjang
          WHERE ps.jurusan_id = j.id
          ORDER BY (ps.nama = lama.nama) DESC, ps.jenjang, ps.nama
          LIMIT 1
       ) AS pengganti ON true
 WHERE m.program_studi_id = lama.id
   AND pengganti.id IS NOT NULL
   AND pengganti.id <> lama.id
   AND NOT EXISTS (
         SELECT 1 FROM prodi_resmi pr
          WHERE pr.jurusan = j.nama AND pr.nama = lama.nama AND pr.jenjang = lama.jenjang
       );

-- 7d. Program studi di luar daftar resmi yang sudah tidak dipakai siapa pun
--     dihapus, supaya pilihan di halaman pendaftaran bersih.
DELETE FROM program_studi ps
 USING jurusan j
 WHERE j.id = ps.jurusan_id
   AND NOT EXISTS (
         SELECT 1 FROM prodi_resmi pr
          WHERE pr.jurusan = j.nama AND pr.nama = ps.nama AND pr.jenjang = ps.jenjang
       )
   AND NOT EXISTS (SELECT 1 FROM mahasiswa m WHERE m.program_studi_id = ps.id);

DROP TABLE prodi_resmi;

-- ===========================================================================
-- 8. ISI NOTIFIKASI UNTUK TIGA AKUN DEMO
--
--    Database yang dibuat sebelum pembaruan ini punya tabel notifikasi yang
--    masih kosong, sehingga lonceng dan halaman Notifikasi tidak ada isinya
--    saat didemokan. Bagian ini mengisinya.
--
--    Hanya berjalan kalau akun yang bersangkutan memang belum punya
--    notifikasi, jadi aman dijalankan berulang kali dan tidak menggandakan
--    data yang sudah ada.
-- ===========================================================================
DO $$
DECLARE
  sudah_ada integer;
BEGIN
  SELECT count(*) INTO sudah_ada
    FROM notifikasi n JOIN pengguna p ON p.id = n.pengguna_id
   WHERE p.email IN ('mahasiswa@polinema.ac.id', 'perusahaan@polinema.ac.id', 'admin@polinema.ac.id');

  IF sudah_ada > 0 THEN
    RAISE NOTICE 'Notifikasi akun demo sudah ada (% baris), bagian ini dilewati.', sudah_ada;
    RETURN;
  END IF;


  INSERT INTO notifikasi (pengguna_id, tipe, judul, pesan, tautan, dibaca, dibuat_pada)
    SELECT p.id, 'interview', 'Jadwal interview sudah ditentukan',
           'PT Nusantara Digital menjadwalkan interview luring pada 14 Oktober 2026 pukul 09.00 di Ruang Meeting 2.',
           'lamaran/lamaran-saya', false, now() - interval '2 hours'
      FROM pengguna p WHERE p.email = 'mahasiswa@polinema.ac.id'
    UNION ALL
    SELECT p.id, 'status_lamaran', 'Lamaranmu masuk tahap screening',
           'Lamaran untuk posisi Network Engineer sedang ditinjau perusahaan.',
           'lamaran/lamaran-saya', false, now() - interval '1 day'
      FROM pengguna p WHERE p.email = 'mahasiswa@polinema.ac.id'
    UNION ALL
    SELECT p.id, 'lowongan_baru', 'Lowongan baru sesuai minatmu',
           'Business Analyst di PT Gudang Garam Tbk membuka lowongan untuk jurusanmu.',
           'lowongan/daftar', true, now() - interval '2 days'
      FROM pengguna p WHERE p.email = 'mahasiswa@polinema.ac.id'
    UNION ALL
    SELECT p.id, 'akun', 'Akunmu sudah diverifikasi',
           'Career Center menyetujui pendaftaranmu. Selamat memakai KarirKu.',
           NULL, true, now() - interval '6 days'
      FROM pengguna p WHERE p.email = 'mahasiswa@polinema.ac.id';

  INSERT INTO notifikasi (pengguna_id, tipe, judul, pesan, tautan, dibaca, dibuat_pada)
    SELECT p.id, 'lamaran_masuk', 'Pelamar baru masuk',
           'Ada pelamar baru untuk posisi Junior Web Developer.',
           'perusahaan/pelamar', false, now() - interval '3 hours'
      FROM pengguna p WHERE p.email = 'perusahaan@polinema.ac.id'
    UNION ALL
    SELECT p.id, 'lamaran_masuk', 'Pelamar baru masuk',
           'Ada pelamar baru untuk posisi Network Engineer.',
           'perusahaan/pelamar', false, now() - interval '1 day'
      FROM pengguna p WHERE p.email = 'perusahaan@polinema.ac.id'
    UNION ALL
    SELECT p.id, 'akun', 'Perusahaan terverifikasi',
           'Akun perusahaan kamu sudah disetujui Career Center dan bisa memasang lowongan.',
           'perusahaan/lowongan', true, now() - interval '9 days'
      FROM pengguna p WHERE p.email = 'perusahaan@polinema.ac.id';

  INSERT INTO notifikasi (pengguna_id, tipe, judul, pesan, tautan, dibaca, dibuat_pada)
    SELECT p.id, 'verifikasi', 'Pendaftar baru menunggu verifikasi',
           'Nabila Ramadhani mendaftar sebagai mahasiswa dan menunggu persetujuan.',
           'admin/persetujuan', false, now() - interval '2 hours'
      FROM pengguna p WHERE p.email = 'admin@polinema.ac.id'
    UNION ALL
    SELECT p.id, 'verifikasi', 'Perusahaan baru menunggu verifikasi',
           'PT Mitra Sejahtera Abadi mengirim dokumen legalitas untuk diperiksa.',
           'admin/persetujuan', false, now() - interval '1 day'
      FROM pengguna p WHERE p.email = 'admin@polinema.ac.id'
    UNION ALL
    SELECT p.id, 'lowongan', 'Lowongan baru tayang',
           'PT Nusantara Digital memasang lowongan Junior Web Developer.',
           'admin/monitoring-lowongan', true, now() - interval '3 days'
      FROM pengguna p WHERE p.email = 'admin@polinema.ac.id';
END $$;

-- ===========================================================================
-- 9. BERKAS CONTOH UNTUK DATABASE YANG SUDAH ADA
--
--    Supaya tombol seperti "Lihat file" pada sertifikat, foto profil, logo
--    perusahaan, dan dokumen legalitas tidak berakhir di halaman
--    "Berkas tidak ditemukan" saat didemokan.
--
--    Memakai nama berkas bersama (contoh-*.pdf) karena berkas itu pasti ada
--    di storage/uploads/ berapa pun isi databasemu. Hanya mengisi yang masih
--    kosong, jadi berkas yang sudah pernah diunggah sungguhan tidak ditimpa,
--    dan aman dijalankan berulang kali.
--
--    Catatan: pada pemasangan dari nol lewat 02-seed.sql, tiap orang mendapat
--    nama berkas sendiri memakai NIM atau nomor perusahaan. Itu lebih mirip
--    keadaan sebenarnya, karena berkas yang diunggah pengguna selalu diberi
--    nama acak yang berbeda.
-- ===========================================================================

UPDATE mahasiswa SET foto = 'contoh-foto.jpg'
 WHERE foto IS NULL AND id % 3 = 0;

UPDATE perusahaan SET logo = 'contoh-logo.jpg'
 WHERE logo IS NULL;

UPDATE profil_item SET file = 'contoh-sertifikat.pdf'
 WHERE tipe = 'sertifikat' AND file IS NULL;

UPDATE profil_item SET file = 'contoh-portofolio.pdf'
 WHERE tipe = 'portofolio' AND file IS NULL AND tautan IS NULL;

UPDATE mahasiswa SET file_ktm = 'contoh-ktm.pdf'
 WHERE file_ktm IS NULL OR btrim(file_ktm) = '';

UPDATE mahasiswa SET file_surat_pengantar = 'contoh-surat-pengantar.pdf'
 WHERE file_surat_pengantar IS NULL OR btrim(file_surat_pengantar) = '';

-- Dokumen legalitas perusahaan, hanya untuk yang belum punya sama sekali
INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb)
  SELECT pr.pengguna_id, t.tipe, 'contoh-' || t.tipe || '.pdf', 2
    FROM perusahaan pr
    CROSS JOIN (VALUES ('nib'), ('npwp'), ('akta'), ('domisili')) AS t(tipe)
   WHERE NOT EXISTS (
     SELECT 1 FROM dokumen_verifikasi dv
      WHERE dv.pengguna_id = pr.pengguna_id AND dv.tipe = t.tipe
   );

-- Selesai.
