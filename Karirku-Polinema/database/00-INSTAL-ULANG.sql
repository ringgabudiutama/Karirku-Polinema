-- =====================================================================
-- KarirKu Polinema · INSTAL ULANG LENGKAP (satu file untuk pgAdmin)
--
-- Cara pakai di pgAdmin:
--   1. Klik database karirku_polinema > Tools > Query Tool
--   2. Buka file ini, tekan Execute (F5). Selesai.
--
-- PERHATIAN: SEMUA isi database dihapus lalu dibuat ulang dengan data demo
-- (= gabungan 01-schema + 02-seed + 03-migrasi-revisi + 04-revisi-dosen + 06-revisi-profil
-- + 05-data-dummy + 07-peningkatan-materi-dosen).
-- JANGAN dijalankan di server produksi: file ini berisi data demo dan akun contoh.
-- Untuk database yang datanya ingin DIPERTAHANKAN, jangan pakai file ini;
-- jalankan 03 dan 04 saja (atau biarkan aplikasi memperbaruinya otomatis).
-- File ini dibuat otomatis oleh tests/buat-instal-ulang.py, jangan diedit manual.
-- =====================================================================

DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT USAGE ON SCHEMA public TO public;   -- hanya pakai, TIDAK boleh membuat objek (CREATE) di skema ini
SET TIME ZONE 'Asia/Jakarta';

-- #####################################################################
-- ##### Isi dari 01-schema.sql
-- #####################################################################
-- ===== KarirKu Polinema - Skema PostgreSQL ===============================

-- ----- Referensi ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS jurusan (
  id            serial PRIMARY KEY,
  nama          varchar(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS program_studi (
  id            serial PRIMARY KEY,
  jurusan_id    integer NOT NULL REFERENCES jurusan(id) ON DELETE RESTRICT,
  nama          varchar(150) NOT NULL,
  jenjang       varchar(10)  NOT NULL CHECK (jenjang IN ('D-II','D-III','D-IV','S2')),
  UNIQUE (jurusan_id, nama, jenjang)
);

CREATE TABLE IF NOT EXISTS skill (
  id            serial PRIMARY KEY,
  nama          varchar(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS bidang (
  id            serial PRIMARY KEY,
  nama          varchar(100) NOT NULL UNIQUE
);

-- ----- Akun dan peran ----------------------------------------------------
CREATE TABLE IF NOT EXISTS pengguna (
  id             serial PRIMARY KEY,
  email          varchar(255) NOT NULL UNIQUE,
  password_hash  varchar(255) NOT NULL,
  role           varchar(20)  NOT NULL CHECK (role IN ('mahasiswa','perusahaan','admin')),
  status_akun    varchar(20)  NOT NULL DEFAULT 'menunggu'
                 CHECK (status_akun IN ('menunggu','perbaikan','ditolak','aktif','nonaktif')),
  dibuat_pada    timestamp NOT NULL DEFAULT now(),
  terakhir_login timestamp
);

CREATE TABLE IF NOT EXISTS admin (
  id            serial PRIMARY KEY,
  pengguna_id   integer NOT NULL UNIQUE REFERENCES pengguna(id) ON DELETE CASCADE,
  nama          varchar(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS mahasiswa (
  id                     serial PRIMARY KEY,
  pengguna_id            integer NOT NULL UNIQUE REFERENCES pengguna(id) ON DELETE CASCADE,
  program_studi_id       integer NOT NULL REFERENCES program_studi(id) ON DELETE RESTRICT,
  nama                   varchar(255) NOT NULL,
  nim                    varchar(20)  NOT NULL UNIQUE,
  no_whatsapp            varchar(20)  NOT NULL,
  status_mahasiswa       varchar(20)  NOT NULL CHECK (status_mahasiswa IN ('aktif','alumni')),
  angkatan               integer      NOT NULL,
  tahun_lulus            integer,
  ipk                    numeric(3,2) CHECK (ipk IS NULL OR (ipk >= 0 AND ipk <= 4)),
  domisili               varchar(255),
  tentang                text,
  foto                   varchar(255),
  file_cv                varchar(255),
  file_ktm               varchar(255),
  file_surat_pengantar   varchar(255),
  status_karier          varchar(20) DEFAULT 'belum bekerja'
                         CHECK (status_karier IN ('bekerja','wirausaha','studi lanjut','mencari kerja','belum bekerja')),
  tempat_kerja           varchar(255),
  posisi_kerja           varchar(255),
  level_jabatan          varchar(50),
  tanggal_mulai_kerja    date,
  karier_diperbarui_pada date,
  karier_fakultas        varchar(150),
  karier_bidang_minat    varchar(255),
  karier_rencana_posisi  varchar(255),
  karier_tahap_studi     varchar(20) CHECK (karier_tahap_studi IS NULL OR karier_tahap_studi IN ('rencana','diterima','sedang berjalan')),
  karier_catatan         text,
  CHECK (status_mahasiswa = 'aktif' OR tahun_lulus IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS perusahaan (
  id                serial PRIMARY KEY,
  pengguna_id       integer NOT NULL UNIQUE REFERENCES pengguna(id) ON DELETE CASCADE,
  nama_perusahaan   varchar(255) NOT NULL,
  bidang_usaha      varchar(100) NOT NULL,
  jenis_perusahaan  varchar(50)  NOT NULL,
  alamat            varchar(255) NOT NULL,
  kota              varchar(100) NOT NULL,
  website           varchar(255),
  nama_pic          varchar(255) NOT NULL,
  jabatan_pic       varchar(100) NOT NULL,
  whatsapp_pic      varchar(20)  NOT NULL,
  logo              varchar(255),
  deskripsi         text,
  bukan_outsourcing boolean NOT NULL DEFAULT false
);

-- ----- Verifikasi akun ---------------------------------------------------
CREATE TABLE IF NOT EXISTS dokumen_verifikasi (
  id            serial PRIMARY KEY,
  pengguna_id   integer NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
  tipe          varchar(20) NOT NULL
                CHECK (tipe IN ('ktm','ijazah','nib','npwp','akta','domisili','logo')),
  file          varchar(255) NOT NULL,
  ukuran_kb     integer CHECK (ukuran_kb <= 2048),
  diunggah_pada timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS verifikasi_akun (
  id          serial PRIMARY KEY,
  pengguna_id integer NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
  admin_id    integer NOT NULL REFERENCES admin(id) ON DELETE RESTRICT,
  keputusan   varchar(20) NOT NULL CHECK (keputusan IN ('disetujui','perbaikan','ditolak','nonaktif','aktif')),
  catatan     varchar(500),
  tanggal     timestamp NOT NULL DEFAULT now(),
  CHECK (keputusan = 'disetujui' OR keputusan = 'aktif' OR catatan IS NOT NULL)
);

-- ----- Profil karier -----------------------------------------------------
CREATE TABLE IF NOT EXISTS profil_item (
  id           serial PRIMARY KEY,
  mahasiswa_id integer NOT NULL REFERENCES mahasiswa(id) ON DELETE CASCADE,
  tipe         varchar(20) NOT NULL CHECK (tipe IN ('pendidikan','pengalaman','sertifikat','portofolio')),
  judul        varchar(255) NOT NULL,
  instansi     varchar(255),
  mulai        date,
  selesai      date,
  deskripsi    text,
  file         varchar(255),
  tautan       varchar(255),
  CHECK (selesai IS NULL OR mulai IS NULL OR selesai >= mulai)
);

CREATE TABLE IF NOT EXISTS mahasiswa_skill (
  mahasiswa_id integer NOT NULL REFERENCES mahasiswa(id) ON DELETE CASCADE,
  skill_id     integer NOT NULL REFERENCES skill(id) ON DELETE CASCADE,
  PRIMARY KEY (mahasiswa_id, skill_id)
);

CREATE TABLE IF NOT EXISTS mahasiswa_minat (
  mahasiswa_id integer NOT NULL REFERENCES mahasiswa(id) ON DELETE CASCADE,
  bidang_id    integer NOT NULL REFERENCES bidang(id) ON DELETE CASCADE,
  PRIMARY KEY (mahasiswa_id, bidang_id)
);

-- ----- Lowongan ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS lowongan (
  id               serial PRIMARY KEY,
  perusahaan_id    integer NOT NULL REFERENCES perusahaan(id) ON DELETE CASCADE,
  bidang_id        integer NOT NULL REFERENCES bidang(id) ON DELETE RESTRICT,
  posisi           varchar(255) NOT NULL,
  jenis_pekerjaan  varchar(50)  NOT NULL,
  sistem_kerja     varchar(50)  NOT NULL,
  lokasi           varchar(100) NOT NULL,
  gaji             varchar(100),
  kuota            integer NOT NULL CHECK (kuota >= 1),
  terisi           integer NOT NULL DEFAULT 0 CHECK (terisi >= 0),
  batas_lamaran    date NOT NULL,
  deskripsi        text NOT NULL,
  kualifikasi      text NOT NULL,
  skill_dibutuhkan varchar(500),
  pamflet          varchar(255) NOT NULL,
  kode_pratinjau   varchar(32) NOT NULL UNIQUE,
  status           varchar(20) NOT NULL DEFAULT 'aktif' CHECK (status IN ('aktif','ditutup','nonaktif')),
  alasan_nonaktif  varchar(500),
  dibuat_pada      timestamp NOT NULL DEFAULT now(),
  diperbarui_pada  timestamp NOT NULL DEFAULT now(),
  CHECK (terisi <= kuota)
);

CREATE TABLE IF NOT EXISTS lowongan_jurusan (
  lowongan_id integer NOT NULL REFERENCES lowongan(id) ON DELETE CASCADE,
  jurusan_id  integer NOT NULL REFERENCES jurusan(id) ON DELETE CASCADE,
  PRIMARY KEY (lowongan_id, jurusan_id)
);

CREATE TABLE IF NOT EXISTS lowongan_disimpan (
  mahasiswa_id integer NOT NULL REFERENCES mahasiswa(id) ON DELETE CASCADE,
  lowongan_id  integer NOT NULL REFERENCES lowongan(id) ON DELETE CASCADE,
  dibuat_pada  timestamp NOT NULL DEFAULT now(),
  PRIMARY KEY (mahasiswa_id, lowongan_id)
);

-- ----- Lamaran -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS lamaran (
  id                   serial PRIMARY KEY,
  mahasiswa_id         integer NOT NULL REFERENCES mahasiswa(id) ON DELETE CASCADE,
  lowongan_id          integer NOT NULL REFERENCES lowongan(id) ON DELETE CASCADE,
  tanggal_lamar        timestamp NOT NULL DEFAULT now(),
  status               varchar(20) NOT NULL DEFAULT 'diajukan'
                       CHECK (status IN ('diajukan','screening','interview','diterima','ditolak','dibatalkan')),
  jenis_cv             varchar(20) NOT NULL CHECK (jenis_cv IN ('generate','unggah')),
  file_cv              varchar(255) NOT NULL,
  file_ktm             varchar(255) NOT NULL,
  file_surat_pengantar varchar(255) NOT NULL,
  catatan_pelamar      varchar(1000),
  snapshot_profil      jsonb NOT NULL,
  catatan_perusahaan   varchar(500),
  diperbarui_pada      timestamp NOT NULL DEFAULT now(),
  UNIQUE (mahasiswa_id, lowongan_id)
);

CREATE TABLE IF NOT EXISTS riwayat_lamaran (
  id          serial PRIMARY KEY,
  lamaran_id  integer NOT NULL REFERENCES lamaran(id) ON DELETE CASCADE,
  status      varchar(20) NOT NULL,
  diubah_oleh integer REFERENCES pengguna(id) ON DELETE SET NULL,
  catatan     varchar(500),
  tanggal     timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS interview (
  id            serial PRIMARY KEY,
  lamaran_id    integer NOT NULL UNIQUE REFERENCES lamaran(id) ON DELETE CASCADE,
  tanggal       date NOT NULL,
  jam           time NOT NULL,
  mode          varchar(20) NOT NULL CHECK (mode IN ('daring','luring')),
  lokasi_tautan varchar(255) NOT NULL,
  catatan       varchar(500),
  tempat        varchar(255),
  ruangan       varchar(100),
  dresscode     varchar(255),
  yang_dibawa   varchar(500),
  narahubung    varchar(255)
);

-- ----- Notifikasi dan admin ----------------------------------------------
CREATE TABLE IF NOT EXISTS notifikasi (
  id          serial PRIMARY KEY,
  pengguna_id integer NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
  tipe        varchar(30) NOT NULL,
  judul       varchar(255) NOT NULL,
  pesan       varchar(500) NOT NULL,
  tautan      varchar(255),
  dibaca      boolean NOT NULL DEFAULT false,
  dibuat_pada timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS admin_jurusan_kontak (
  id              serial PRIMARY KEY,
  jurusan_id      integer NOT NULL UNIQUE REFERENCES jurusan(id) ON DELETE CASCADE,
  nama_kontak     varchar(255),
  nomor_wa        varchar(20),
  diperbarui_oleh integer REFERENCES admin(id) ON DELETE SET NULL,
  diperbarui_pada timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pengiriman_loker (
  id          serial PRIMARY KEY,
  lowongan_id integer NOT NULL REFERENCES lowongan(id) ON DELETE CASCADE,
  jurusan_id  integer NOT NULL REFERENCES jurusan(id) ON DELETE CASCADE,
  admin_id    integer NOT NULL REFERENCES admin(id) ON DELETE RESTRICT,
  tanggal     timestamp NOT NULL DEFAULT now(),
  UNIQUE (lowongan_id, jurusan_id)
);

CREATE TABLE IF NOT EXISTS pengaturan (
  id              serial PRIMARY KEY,
  kunci           varchar(100) NOT NULL UNIQUE,
  nilai           text NOT NULL,
  diperbarui_oleh integer REFERENCES admin(id) ON DELETE SET NULL,
  diperbarui_pada timestamp NOT NULL DEFAULT now()
);

-- ----- Indeks pendukung --------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_lowongan_status     ON lowongan (status, batas_lamaran);
CREATE INDEX IF NOT EXISTS idx_lowongan_perusahaan ON lowongan (perusahaan_id);
CREATE INDEX IF NOT EXISTS idx_lamaran_status      ON lamaran (status);
CREATE INDEX IF NOT EXISTS idx_lamaran_lowongan    ON lamaran (lowongan_id);
CREATE INDEX IF NOT EXISTS idx_notifikasi_belum    ON notifikasi (pengguna_id, dibaca);
CREATE INDEX IF NOT EXISTS idx_profil_item_mhs     ON profil_item (mahasiswa_id, tipe);

-- ===== Tambahan: tabel reset kata sandi (fitur Lupa Kata Sandi) =========

CREATE TABLE IF NOT EXISTS reset_kata_sandi (
  id           serial PRIMARY KEY,
  pengguna_id  integer NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
  token_hash   varchar(255) NOT NULL UNIQUE,
  kedaluwarsa  timestamp NOT NULL,
  dipakai_pada timestamp,
  dibuat_pada  timestamp NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reset_kata_sandi_pengguna ON reset_kata_sandi (pengguna_id);

-- #####################################################################
-- ##### Isi dari 02-seed.sql
-- #####################################################################
-- ===== DATA AWAL & DATA UJI KarirKu Polinema ===============================
-- AMAN DIJALANKAN ULANG: kalau database sudah berisi data (tabel jurusan tidak
-- kosong: tabel pengguna sudah berisi), seluruh isi file ini DILEWATI dan tidak menimbulkan error
-- "duplicate key". Untuk mengulang dari nol, pakai database/00-INSTAL-ULANG.sql.
DO $seed_karirku$
BEGIN
  IF to_regclass('public.jurusan') IS NULL THEN
    RAISE EXCEPTION 'Tabel belum ada. Jalankan database/01-schema.sql lebih dulu (atau pakai 00-INSTAL-ULANG.sql).';
  END IF;
  IF EXISTS (SELECT 1 FROM pengguna) THEN
    RAISE NOTICE 'Data awal sudah ada, 02-seed.sql dilewati.';
    RETURN;
  END IF;
  IF EXISTS (SELECT 1 FROM jurusan) THEN
    RAISE EXCEPTION 'Urutan file tertukar: 03 sudah dijalankan sebelum 02. Paling mudah: jalankan database/00-INSTAL-ULANG.sql (membuat ulang semuanya).';
  END IF;
  EXECUTE $isi_seed$

-- ----- Jurusan dan program studi -----------------------------------------
INSERT INTO jurusan (nama) VALUES
  ('Teknik Sipil'),
  ('Teknik Mesin'),
  ('Teknik Elektro'),
  ('Teknik Kimia'),
  ('Teknologi Informasi'),
  ('Akuntansi'),
  ('Administrasi Niaga');

INSERT INTO bidang (nama) VALUES
  ('Teknologi Informasi'), ('Konstruksi'), ('Manufaktur'), ('Kelistrikan'),
  ('Kimia'), ('Keuangan'), ('Perdagangan dan Jasa');

-- ----- Daftar skill awal -------------------------------------------------
INSERT INTO skill (nama) VALUES
  ('HTML'), ('CSS'), ('JavaScript'), ('PHP'), ('Laravel'), ('CodeIgniter'),
  ('PostgreSQL'), ('MySQL'), ('Git'), ('Figma'), ('UI/UX Design'),
  ('Python'), ('Java'), ('Microsoft Excel'), ('AutoCAD'), ('SolidWorks'),
  ('Komunikasi'), ('Kerja sama tim'), ('Manajemen waktu'), ('Bahasa Inggris')
ON CONFLICT (nama) DO NOTHING;

INSERT INTO program_studi (jurusan_id, nama, jenjang)
  -- Teknik Sipil
  SELECT id, 'Teknik Sipil', 'D-III' FROM jurusan WHERE nama = 'Teknik Sipil'
  UNION ALL SELECT id, 'Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air', 'D-III' FROM jurusan WHERE nama = 'Teknik Sipil'
  UNION ALL SELECT id, 'Teknologi Pertambangan', 'D-III' FROM jurusan WHERE nama = 'Teknik Sipil'
  UNION ALL SELECT id, 'Teknologi Rekayasa Konstruksi Jalan dan Jembatan', 'D-IV' FROM jurusan WHERE nama = 'Teknik Sipil'
  UNION ALL SELECT id, 'Manajemen Rekayasa Konstruksi', 'D-IV' FROM jurusan WHERE nama = 'Teknik Sipil'
  -- Teknik Mesin
  UNION ALL SELECT id, 'Teknik Mesin', 'D-III' FROM jurusan WHERE nama = 'Teknik Mesin'
  UNION ALL SELECT id, 'Teknologi Pemeliharaan Pesawat Udara', 'D-III' FROM jurusan WHERE nama = 'Teknik Mesin'
  UNION ALL SELECT id, 'Teknik Mesin Produksi dan Perawatan', 'D-IV' FROM jurusan WHERE nama = 'Teknik Mesin'
  UNION ALL SELECT id, 'Teknik Otomotif Elektronik', 'D-IV' FROM jurusan WHERE nama = 'Teknik Mesin'
  UNION ALL SELECT id, 'Terapan Rekayasa Teknologi Manufaktur', 'S2' FROM jurusan WHERE nama = 'Teknik Mesin'
  -- Teknik Elektro
  UNION ALL SELECT id, 'Teknik Listrik', 'D-III' FROM jurusan WHERE nama = 'Teknik Elektro'
  UNION ALL SELECT id, 'Teknik Elektronika', 'D-III' FROM jurusan WHERE nama = 'Teknik Elektro'
  UNION ALL SELECT id, 'Teknik Telekomunikasi', 'D-III' FROM jurusan WHERE nama = 'Teknik Elektro'
  UNION ALL SELECT id, 'Sistem Kelistrikan', 'D-IV' FROM jurusan WHERE nama = 'Teknik Elektro'
  UNION ALL SELECT id, 'Teknik Elektronika', 'D-IV' FROM jurusan WHERE nama = 'Teknik Elektro'
  UNION ALL SELECT id, 'Jaringan Telekomunikasi Digital', 'D-IV' FROM jurusan WHERE nama = 'Teknik Elektro'
  UNION ALL SELECT id, 'Terapan Teknik Elektro', 'S2' FROM jurusan WHERE nama = 'Teknik Elektro'
  -- Teknik Kimia
  UNION ALL SELECT id, 'Teknik Kimia', 'D-III' FROM jurusan WHERE nama = 'Teknik Kimia'
  UNION ALL SELECT id, 'Teknologi Kimia Industri', 'D-IV' FROM jurusan WHERE nama = 'Teknik Kimia'
  UNION ALL SELECT id, 'Terapan Optimasi Rekayasa Kimia', 'S2' FROM jurusan WHERE nama = 'Teknik Kimia'
  -- Teknologi Informasi
  UNION ALL SELECT id, 'Pengembangan Peranti Lunak Situs', 'D-II' FROM jurusan WHERE nama = 'Teknologi Informasi'
  UNION ALL SELECT id, 'Teknik Informatika', 'D-IV' FROM jurusan WHERE nama = 'Teknologi Informasi'
  UNION ALL SELECT id, 'Sistem Informasi Bisnis', 'D-IV' FROM jurusan WHERE nama = 'Teknologi Informasi'
  UNION ALL SELECT id, 'Terapan Rekayasa Teknologi Informasi', 'S2' FROM jurusan WHERE nama = 'Teknologi Informasi'
  -- Akuntansi
  UNION ALL SELECT id, 'Akuntansi', 'D-III' FROM jurusan WHERE nama = 'Akuntansi'
  UNION ALL SELECT id, 'Akuntansi Manajemen', 'D-IV' FROM jurusan WHERE nama = 'Akuntansi'
  UNION ALL SELECT id, 'Keuangan', 'D-IV' FROM jurusan WHERE nama = 'Akuntansi'
  UNION ALL SELECT id, 'Terapan Sistem Informasi Akuntansi', 'S2' FROM jurusan WHERE nama = 'Akuntansi'
  -- Administrasi Niaga
  UNION ALL SELECT id, 'Administrasi Bisnis', 'D-III' FROM jurusan WHERE nama = 'Administrasi Niaga'
  UNION ALL SELECT id, 'Manajemen Pemasaran Digital', 'D-IV' FROM jurusan WHERE nama = 'Administrasi Niaga'
  UNION ALL SELECT id, 'Pengelolaan Arsip dan Rekaman Informasi', 'D-IV' FROM jurusan WHERE nama = 'Administrasi Niaga'
  UNION ALL SELECT id, 'Bahasa Inggris untuk Komunikasi Bisnis dan Profesional', 'D-IV' FROM jurusan WHERE nama = 'Administrasi Niaga';

-- ----- Akun demo admin (admin@polinema.ac.id / admin123) -----------------
INSERT INTO pengguna (email, password_hash, role, status_akun) VALUES
  ('admin@polinema.ac.id', '$2b$10$LbjPEzhFoNJuATXOvuQerOvwA1y5y0V3pITQKzX.xWqwgYj.icK7a', 'admin', 'aktif');

INSERT INTO admin (pengguna_id, nama)
  SELECT id, 'Admin Career Center' FROM pengguna WHERE email = 'admin@polinema.ac.id';

-- ----- Akun demo mahasiswa (mahasiswa@polinema.ac.id / mahasiswa123) -----
INSERT INTO pengguna (email, password_hash, role, status_akun) VALUES
  ('mahasiswa@polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif');

INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan)
  SELECT p.id, ps.id, 'Budi Santoso', '2241720001', '081234567890', 'aktif', 2022
  FROM pengguna p, program_studi ps
  WHERE p.email = 'mahasiswa@polinema.ac.id' AND ps.nama = 'Teknik Informatika';

-- ----- Akun demo perusahaan (perusahaan@polinema.ac.id / perusahaan123) ----
INSERT INTO pengguna (email, password_hash, role, status_akun) VALUES
  ('perusahaan@polinema.ac.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif');

INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
  SELECT id, 'PT Nusantara Digital', 'Teknologi Informasi', 'Swasta nasional', 'Jl. Soekarno Hatta 10', 'Malang', 'Hendra Wijaya', 'HR Manager', '081298765432', true
  FROM pengguna WHERE email = 'perusahaan@polinema.ac.id';

-- ===== DATA UJI LENGKAP ==================================================

-- ----- 50 akun mahasiswa dan alumni --------------------------------------
INSERT INTO pengguna (email, password_hash, role, status_akun) VALUES
  ('ahmad.pratama@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('siti.nuraini@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('rizky.saputra@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('dewi.lestari@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('bagus.wicaksono@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('nur.hidayah@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('fajar.ramadhan@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('intan.permata@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('yoga.prasetyo@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('laila.rahmawati@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('dimas.santoso@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('ayu.anggraini@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('hendra.wijaya@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('rina.kusuma@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('arif.setiawan@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('mega.maharani@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('teguh.firdaus@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('sari.oktaviani@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('wahyu.nugroho@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('putri.safitri@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('galih.hartono@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('novi.andini@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('irfan.mahendra@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('diah.puspita@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('bayu.gunawan@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('fitri.khoirunnisa@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('reza.siregar@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('anisa.handayani@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('eko.purnomo@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('maya.wulandari@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('satrio.pratama@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('lintang.nuraini@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('gilang.saputra@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('zahra.lestari@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('candra.wicaksono@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('winda.hidayah@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('alfian.ramadhan@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('rahma.permata@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('dani.prasetyo@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('tiara.rahmawati@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('yusuf.santoso@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('melati.anggraini@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('bima.wijaya@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('salsa.kusuma@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('hafiz.setiawan@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('kirana.maharani@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('panji.firdaus@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('vina.oktaviani@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('rangga.nugroho@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif'),
  ('ratna.safitri@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif');

INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp,
    status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, status_karier,
    tempat_kerja, posisi_kerja, level_jabatan, tanggal_mulai_kerja,
    karier_fakultas, karier_bidang_minat, karier_rencana_posisi,
    karier_tahap_studi, karier_catatan, karier_diperbarui_pada,
    file_ktm, file_surat_pengantar)
  SELECT p.id, ps.id, 'Ahmad Pratama', '2441720010', '082228256885', 'aktif', 2024, NULL::int, 3.49, 'Surabaya', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Konstruksi', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-02'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'ahmad.pratama@student.polinema.ac.id' AND ps.nama = 'Teknik Sipil' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT p.id, ps.id, 'Siti Nuraini', '2241720011', '087612375999', 'aktif', 2022, NULL::int, 3.31, 'Pasuruan', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Manufaktur', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-26'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'siti.nuraini@student.polinema.ac.id' AND ps.nama = 'Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT p.id, ps.id, 'Rizky Saputra', '2341720012', '082730449637', 'aktif', 2023, NULL::int, 3.78, 'Kediri', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Kelistrikan', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-06'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'rizky.saputra@student.polinema.ac.id' AND ps.nama = 'Teknologi Pertambangan' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT p.id, ps.id, 'Dewi Lestari', '2241720013', '089896325586', 'aktif', 2022, NULL::int, 3.5, 'Batu', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Kimia', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-27'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'dewi.lestari@student.polinema.ac.id' AND ps.nama = 'Teknologi Rekayasa Konstruksi Jalan dan Jembatan' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT p.id, ps.id, 'Bagus Wicaksono', '2441720014', '089816331413', 'aktif', 2024, NULL::int, 3.64, 'Mojokerto', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Keuangan', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-12'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'bagus.wicaksono@student.polinema.ac.id' AND ps.nama = 'Manajemen Rekayasa Konstruksi' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT p.id, ps.id, 'Nur Hidayah', '2341720015', '088055549284', 'aktif', 2023, NULL::int, 3.11, 'Pasuruan', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Kelistrikan', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-05'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'nur.hidayah@student.polinema.ac.id' AND ps.nama = 'Teknik Mesin' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT p.id, ps.id, 'Fajar Ramadhan', '2241720016', '083793078606', 'aktif', 2022, NULL::int, 3.6, 'Lumajang', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Manufaktur', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-26'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'fajar.ramadhan@student.polinema.ac.id' AND ps.nama = 'Teknologi Pemeliharaan Pesawat Udara' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT p.id, ps.id, 'Intan Permata', '2441720017', '089485621632', 'aktif', 2024, NULL::int, 3.22, 'Gresik', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Keuangan', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-07'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'intan.permata@student.polinema.ac.id' AND ps.nama = 'Teknik Mesin Produksi dan Perawatan' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT p.id, ps.id, 'Yoga Prasetyo', '2341720018', '081364711025', 'aktif', 2023, NULL::int, 3.85, 'Mojokerto', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Konstruksi', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-10'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'yoga.prasetyo@student.polinema.ac.id' AND ps.nama = 'Teknik Otomotif Elektronik' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT p.id, ps.id, 'Laila Rahmawati', '2441720019', '081218722340', 'aktif', 2024, NULL::int, 3.22, 'Batu', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Manufaktur', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-03'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'laila.rahmawati@student.polinema.ac.id' AND ps.nama = 'Teknik Listrik' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Dimas Santoso', '2241720020', '085944444270', 'aktif', 2022, NULL::int, 3.47, 'Tulungagung', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Manufaktur', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-08'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'dimas.santoso@student.polinema.ac.id' AND ps.nama = 'Teknik Elektronika' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Ayu Anggraini', '2441720021', '088798805309', 'aktif', 2024, NULL::int, 3.44, 'Sidoarjo', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Teknologi Informasi', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-22'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'ayu.anggraini@student.polinema.ac.id' AND ps.nama = 'Teknik Telekomunikasi' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Hendra Wijaya', '2241720022', '088651203816', 'aktif', 2022, NULL::int, 3.4, 'Blitar', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Teknologi Informasi', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-04'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'hendra.wijaya@student.polinema.ac.id' AND ps.nama = 'Sistem Kelistrikan' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Rina Kusuma', '2341720023', '083218162469', 'aktif', 2023, NULL::int, 3.39, 'Probolinggo', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Perdagangan dan Jasa', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-24'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'rina.kusuma@student.polinema.ac.id' AND ps.nama = 'Teknik Elektronika' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Arif Setiawan', '2241720024', '085687732324', 'aktif', 2022, NULL::int, 3.24, 'Sidoarjo', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Perdagangan dan Jasa', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-03'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'arif.setiawan@student.polinema.ac.id' AND ps.nama = 'Jaringan Telekomunikasi Digital' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Mega Maharani', '2241720025', '083731425400', 'aktif', 2022, NULL::int, 3.42, 'Pasuruan', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Teknologi Informasi', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-04'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'mega.maharani@student.polinema.ac.id' AND ps.nama = 'Teknik Kimia' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Kimia'
  UNION ALL
  SELECT p.id, ps.id, 'Teguh Firdaus', '2341720026', '085648877587', 'aktif', 2023, NULL::int, 3.75, 'Mojokerto', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Kelistrikan', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-07'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'teguh.firdaus@student.polinema.ac.id' AND ps.nama = 'Teknologi Kimia Industri' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Kimia'
  UNION ALL
  SELECT p.id, ps.id, 'Sari Oktaviani', '2341720027', '082223929788', 'aktif', 2023, NULL::int, 3.33, 'Gresik', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Konstruksi', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-05'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'sari.oktaviani@student.polinema.ac.id' AND ps.nama = 'Pengembangan Peranti Lunak Situs' AND ps.jenjang = 'D-II' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT p.id, ps.id, 'Wahyu Nugroho', '2341720028', '083942530061', 'aktif', 2023, NULL::int, 3.55, 'Malang', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Kelistrikan', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-11'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'wahyu.nugroho@student.polinema.ac.id' AND ps.nama = 'Teknik Informatika' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT p.id, ps.id, 'Putri Safitri', '2441720029', '084423692909', 'aktif', 2024, NULL::int, 3.15, 'Pasuruan', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Teknologi Informasi', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-01'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'putri.safitri@student.polinema.ac.id' AND ps.nama = 'Sistem Informasi Bisnis' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT p.id, ps.id, 'Galih Hartono', '2441720030', '081417027244', 'aktif', 2024, NULL::int, 3.6, 'Probolinggo', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Kimia', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-06'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'galih.hartono@student.polinema.ac.id' AND ps.nama = 'Akuntansi' AND ps.jenjang = 'D-III' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT p.id, ps.id, 'Novi Andini', '2341720031', '081014900465', 'aktif', 2023, NULL::int, 3.44, 'Madiun', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Kimia', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-08'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'novi.andini@student.polinema.ac.id' AND ps.nama = 'Akuntansi Manajemen' AND ps.jenjang = 'D-IV' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT p.id, ps.id, 'Irfan Mahendra', '2341720032', '083667114332', 'aktif', 2023, NULL::int, 3.71, 'Kediri', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Teknologi Informasi', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-10'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'irfan.mahendra@student.polinema.ac.id' AND ps.nama = 'Keuangan' AND ps.jenjang = 'D-IV' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT p.id, ps.id, 'Diah Puspita', '2341720033', '084779594794', 'aktif', 2023, NULL::int, 3.26, 'Sidoarjo', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Perdagangan dan Jasa', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-10'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'diah.puspita@student.polinema.ac.id' AND ps.nama = 'Administrasi Bisnis' AND ps.jenjang = 'D-III' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT p.id, ps.id, 'Bayu Gunawan', '2241720034', '084657507297', 'aktif', 2022, NULL::int, 3.25, 'Pasuruan', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Teknologi Informasi', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-16'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'bayu.gunawan@student.polinema.ac.id' AND ps.nama = 'Manajemen Pemasaran Digital' AND ps.jenjang = 'D-IV' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT p.id, ps.id, 'Fitri Khoirunnisa', '2241720035', '088835961797', 'aktif', 2022, NULL::int, 3.21, 'Surabaya', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Keuangan', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-26'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'fitri.khoirunnisa@student.polinema.ac.id' AND ps.nama = 'Pengelolaan Arsip dan Rekaman Informasi' AND ps.jenjang = 'D-IV' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT p.id, ps.id, 'Reza Siregar', '2241720036', '088970689418', 'aktif', 2022, NULL::int, 3.59, 'Malang', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Keuangan', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-19'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'reza.siregar@student.polinema.ac.id' AND ps.nama = 'Bahasa Inggris untuk Komunikasi Bisnis dan Profesional' AND ps.jenjang = 'D-IV' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT p.id, ps.id, 'Anisa Handayani', '2441720037', '083007637142', 'aktif', 2024, NULL::int, 3.5, 'Madiun', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Konstruksi', NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-06'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'anisa.handayani@student.polinema.ac.id' AND ps.nama = 'Teknik Sipil' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT p.id, ps.id, 'Eko Purnomo', '2041720038', '083878951127', 'alumni', 2020, 2023, 3.76, 'Probolinggo', 'bekerja',
         'PT Sampoerna', 'Staf Produksi', 'Staf', '2023-12-15'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-21'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'eko.purnomo@student.polinema.ac.id' AND ps.nama = 'Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT p.id, ps.id, 'Maya Wulandari', '1941720039', '081974113259', 'alumni', 2019, 2022, 3.69, 'Mojokerto', 'bekerja',
         'PT Gudang Garam', 'Staf Akuntansi', 'Staf', '2022-11-28'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-05'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'maya.wulandari@student.polinema.ac.id' AND ps.nama = 'Teknologi Pertambangan' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT p.id, ps.id, 'Satrio Pratama', '2141720040', '084003235161', 'alumni', 2021, 2025, 3.6, 'Kediri', 'bekerja',
         'PT Gudang Garam', 'Staf Akuntansi', 'Asisten Manajer', '2025-08-05'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-25'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'satrio.pratama@student.polinema.ac.id' AND ps.nama = 'Teknologi Rekayasa Konstruksi Jalan dan Jembatan' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT p.id, ps.id, 'Lintang Nuraini', '2041720041', '081187556371', 'alumni', 2020, 2024, 3.36, 'Surabaya', 'bekerja',
         'PT Pindad', 'Digital Marketing', 'Staf', '2024-12-09'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-24'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'lintang.nuraini@student.polinema.ac.id' AND ps.nama = 'Manajemen Rekayasa Konstruksi' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT p.id, ps.id, 'Gilang Saputra', '2041720042', '081876631101', 'alumni', 2020, 2023, 3.83, 'Gresik', 'bekerja',
         'PT Astra Otoparts', 'Analis Keuangan', 'Staf', '2023-09-21'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-27'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'gilang.saputra@student.polinema.ac.id' AND ps.nama = 'Teknik Mesin' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT p.id, ps.id, 'Zahra Lestari', '2141720043', '085107938456', 'alumni', 2021, 2024, 3.7, 'Blitar', 'bekerja',
         'PT Gudang Garam', 'Digital Marketing', 'Junior', '2024-08-25'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-04'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'zahra.lestari@student.polinema.ac.id' AND ps.nama = 'Teknologi Pemeliharaan Pesawat Udara' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT p.id, ps.id, 'Candra Wicaksono', '2041720044', '088948447808', 'alumni', 2020, 2024, 3.85, 'Tulungagung', 'bekerja',
         'PT Kereta Api Indonesia', 'Staf Produksi', 'Supervisor', '2024-09-04'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-04'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'candra.wicaksono@student.polinema.ac.id' AND ps.nama = 'Teknik Mesin Produksi dan Perawatan' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT p.id, ps.id, 'Winda Hidayah', '1941720045', '081870468526', 'alumni', 2019, 2023, 3.28, 'Probolinggo', 'bekerja',
         'PT Sampoerna', 'Staf Akuntansi', 'Asisten Manajer', '2023-08-27'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-24'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'winda.hidayah@student.polinema.ac.id' AND ps.nama = 'Teknik Otomotif Elektronik' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT p.id, ps.id, 'Alfian Ramadhan', '2141720046', '088585710379', 'alumni', 2021, 2024, 3.55, 'Sidoarjo', 'bekerja',
         'PT Astra Otoparts', 'Network Engineer', 'Staf', '2024-10-24'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-13'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'alfian.ramadhan@student.polinema.ac.id' AND ps.nama = 'Teknik Listrik' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Rahma Permata', '2041720047', '086190432372', 'alumni', 2020, 2023, 3.62, 'Lumajang', 'bekerja',
         'PT Semen Indonesia', 'Staf Akuntansi', 'Staf', '2023-12-01'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-11'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'rahma.permata@student.polinema.ac.id' AND ps.nama = 'Teknik Elektronika' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Dani Prasetyo', '1941720048', '082501583967', 'alumni', 2019, 2022, 3.23, 'Probolinggo', 'bekerja',
         'PT Nestle Indonesia', 'Quality Control', 'Supervisor', '2022-08-06'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-19'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'dani.prasetyo@student.polinema.ac.id' AND ps.nama = 'Teknik Telekomunikasi' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Tiara Rahmawati', '1941720049', '089430752354', 'alumni', 2019, 2023, 3.7, 'Mojokerto', 'bekerja',
         'PT Pindad', 'Analis Keuangan', 'Staf', '2023-08-18'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-22'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'tiara.rahmawati@student.polinema.ac.id' AND ps.nama = 'Sistem Kelistrikan' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Yusuf Santoso', '2041720050', '083555280366', 'alumni', 2020, 2024, 3.15, 'Tulungagung', 'wirausaha',
         'Studio Foto Cahaya', 'Pemilik', NULL::varchar, '2024-10-23'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-15'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'yusuf.santoso@student.polinema.ac.id' AND ps.nama = 'Teknik Elektronika' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Melati Anggraini', '2141720051', '083714242256', 'alumni', 2021, 2025, 3.81, 'Malang', 'wirausaha',
         'Toko Bangunan Sejahtera', 'Pemilik', NULL::varchar, '2025-08-16'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-18'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'melati.anggraini@student.polinema.ac.id' AND ps.nama = 'Jaringan Telekomunikasi Digital' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT p.id, ps.id, 'Bima Wijaya', '2141720052', '083338593824', 'alumni', 2021, 2024, 3.9, 'Mojokerto', 'wirausaha',
         'Konveksi Rajawali', 'Pemilik', NULL::varchar, '2024-09-11'::date, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::text,
         '2026-09-01'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'bima.wijaya@student.polinema.ac.id' AND ps.nama = 'Teknik Kimia' AND ps.jenjang = 'D-III' AND j.nama = 'Teknik Kimia'
  UNION ALL
  SELECT p.id, ps.id, 'Salsa Kusuma', '1941720053', '085871678058', 'alumni', 2019, 2023, 3.64, 'Batu', 'studi lanjut',
         'Universitas Brawijaya', 'Magister Terapan Teknik Mesin', NULL::varchar, '2023-10-09'::date, 'Fakultas Teknologi Industri', NULL::varchar, NULL::varchar, 'diterima', NULL::text,
         '2026-09-26'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'salsa.kusuma@student.polinema.ac.id' AND ps.nama = 'Teknologi Kimia Industri' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknik Kimia'
  UNION ALL
  SELECT p.id, ps.id, 'Hafiz Setiawan', '2141720054', '088308838349', 'alumni', 2021, 2024, 3.8, 'Lumajang', 'studi lanjut',
         'Politeknik Negeri Malang', 'Magister Terapan Teknik Mesin', NULL::varchar, '2024-09-25'::date, 'Fakultas Ekonomi dan Bisnis', NULL::varchar, NULL::varchar, 'sedang berjalan', NULL::text,
         '2026-09-08'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'hafiz.setiawan@student.polinema.ac.id' AND ps.nama = 'Pengembangan Peranti Lunak Situs' AND ps.jenjang = 'D-II' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT p.id, ps.id, 'Kirana Maharani', '2141720055', '085567216450', 'alumni', 2021, 2025, 3.89, 'Sidoarjo', 'studi lanjut',
         'Politeknik Negeri Malang', 'Magister Terapan Teknik Mesin', NULL::varchar, '2025-09-03'::date, 'Fakultas Ekonomi dan Bisnis', NULL::varchar, NULL::varchar, 'diterima', NULL::text,
         '2026-09-22'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'kirana.maharani@student.polinema.ac.id' AND ps.nama = 'Teknik Informatika' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT p.id, ps.id, 'Panji Firdaus', '2041720056', '089342636786', 'alumni', 2020, 2024, 3.71, 'Gresik', 'mencari kerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Manufaktur', 'Network Engineer', NULL::varchar, 'Sedang mengikuti beberapa proses seleksi.',
         '2026-09-22'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'panji.firdaus@student.polinema.ac.id' AND ps.nama = 'Sistem Informasi Bisnis' AND ps.jenjang = 'D-IV' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT p.id, ps.id, 'Vina Oktaviani', '2041720057', '085225310717', 'alumni', 2020, 2023, 3.25, 'Kediri', 'mencari kerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Konstruksi', 'Junior Programmer', NULL::varchar, 'Sedang mengikuti beberapa proses seleksi.',
         '2026-09-03'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'vina.oktaviani@student.polinema.ac.id' AND ps.nama = 'Akuntansi' AND ps.jenjang = 'D-III' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT p.id, ps.id, 'Rangga Nugroho', '2141720058', '087026826518', 'alumni', 2021, 2025, 3.39, 'Pasuruan', 'mencari kerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Keuangan', 'Network Engineer', NULL::varchar, 'Sedang mengikuti beberapa proses seleksi.',
         '2026-09-11'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'rangga.nugroho@student.polinema.ac.id' AND ps.nama = 'Akuntansi Manajemen' AND ps.jenjang = 'D-IV' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT p.id, ps.id, 'Ratna Safitri', '2041720059', '084577802136', 'alumni', 2020, 2024, 3.31, 'Surabaya', 'belum bekerja',
         NULL::varchar, NULL::varchar, NULL::varchar, NULL::date, NULL::varchar, 'Keuangan', NULL::varchar, NULL::varchar, 'Masih menyiapkan diri dan memperkuat portofolio.',
         '2026-09-28'::date, 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'ratna.safitri@student.polinema.ac.id' AND ps.nama = 'Keuangan' AND ps.jenjang = 'D-IV' AND j.nama = 'Akuntansi';

-- ----- Skill dan minat bidang untuk sebagian mahasiswa -------------------
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id)
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720010' AND s.nama = 'Git'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720010' AND s.nama = 'AutoCAD'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720010' AND s.nama = 'Bahasa Inggris'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720010' AND s.nama = 'SolidWorks'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720011' AND s.nama = 'JavaScript'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720011' AND s.nama = 'Python'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720011' AND s.nama = 'HTML'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720011' AND s.nama = 'Kerja sama tim'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720012' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720012' AND s.nama = 'Bahasa Inggris'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720012' AND s.nama = 'SolidWorks'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720012' AND s.nama = 'Kerja sama tim'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720013' AND s.nama = 'HTML'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720013' AND s.nama = 'Microsoft Excel'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720013' AND s.nama = 'PHP'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720013' AND s.nama = 'CSS'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720014' AND s.nama = 'Komunikasi'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720014' AND s.nama = 'CSS'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720014' AND s.nama = 'AutoCAD'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720014' AND s.nama = 'Bahasa Inggris'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720015' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720015' AND s.nama = 'Komunikasi'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720015' AND s.nama = 'HTML'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720015' AND s.nama = 'CSS'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720016' AND s.nama = 'Python'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720016' AND s.nama = 'AutoCAD'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720016' AND s.nama = 'SolidWorks'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720016' AND s.nama = 'Komunikasi'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720017' AND s.nama = 'CSS'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720017' AND s.nama = 'PostgreSQL'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720017' AND s.nama = 'Bahasa Inggris'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720017' AND s.nama = 'Figma'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720018' AND s.nama = 'Python'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720018' AND s.nama = 'Kerja sama tim'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720018' AND s.nama = 'Komunikasi'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720018' AND s.nama = 'JavaScript'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720019' AND s.nama = 'Bahasa Inggris'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720019' AND s.nama = 'JavaScript'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720019' AND s.nama = 'Figma'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720019' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720020' AND s.nama = 'SolidWorks'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720020' AND s.nama = 'JavaScript'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720020' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720020' AND s.nama = 'Kerja sama tim'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720021' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720021' AND s.nama = 'Bahasa Inggris'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720021' AND s.nama = 'Git'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720021' AND s.nama = 'SolidWorks'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720022' AND s.nama = 'Bahasa Inggris'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720022' AND s.nama = 'SolidWorks'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720022' AND s.nama = 'AutoCAD'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720022' AND s.nama = 'HTML'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720023' AND s.nama = 'Microsoft Excel'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720023' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720023' AND s.nama = 'Figma'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720023' AND s.nama = 'JavaScript'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720024' AND s.nama = 'SolidWorks'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720024' AND s.nama = 'PostgreSQL'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720024' AND s.nama = 'Git'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720024' AND s.nama = 'Microsoft Excel'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720025' AND s.nama = 'JavaScript'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720025' AND s.nama = 'Kerja sama tim'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720025' AND s.nama = 'Microsoft Excel'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720025' AND s.nama = 'AutoCAD'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720026' AND s.nama = 'Microsoft Excel'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720026' AND s.nama = 'PHP'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720026' AND s.nama = 'Bahasa Inggris'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720026' AND s.nama = 'Python'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720027' AND s.nama = 'Microsoft Excel'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720027' AND s.nama = 'PHP'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720027' AND s.nama = 'Figma'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720027' AND s.nama = 'JavaScript'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720028' AND s.nama = 'Komunikasi'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720028' AND s.nama = 'SolidWorks'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720028' AND s.nama = 'Git'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720028' AND s.nama = 'Figma'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720029' AND s.nama = 'Git'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720029' AND s.nama = 'PostgreSQL'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720029' AND s.nama = 'PHP'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720029' AND s.nama = 'Figma'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720030' AND s.nama = 'PostgreSQL'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720030' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720030' AND s.nama = 'Kerja sama tim'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720030' AND s.nama = 'Microsoft Excel'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720031' AND s.nama = 'CSS'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720031' AND s.nama = 'Microsoft Excel'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720031' AND s.nama = 'PostgreSQL'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720031' AND s.nama = 'Python'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720032' AND s.nama = 'Kerja sama tim'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720032' AND s.nama = 'Microsoft Excel'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720032' AND s.nama = 'Komunikasi'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720032' AND s.nama = 'HTML'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720033' AND s.nama = 'CSS'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720033' AND s.nama = 'Git'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720033' AND s.nama = 'Bahasa Inggris'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2341720033' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720034' AND s.nama = 'SolidWorks'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720034' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720034' AND s.nama = 'PHP'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720034' AND s.nama = 'Git'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720035' AND s.nama = 'Kerja sama tim'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720035' AND s.nama = 'PHP'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720035' AND s.nama = 'Python'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720035' AND s.nama = 'Git'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720036' AND s.nama = 'HTML'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720036' AND s.nama = 'CSS'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720036' AND s.nama = 'AutoCAD'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2241720036' AND s.nama = 'Microsoft Excel'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720037' AND s.nama = 'HTML'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720037' AND s.nama = 'PostgreSQL'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720037' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2441720037' AND s.nama = 'JavaScript'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2041720038' AND s.nama = 'Komunikasi'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2041720038' AND s.nama = 'HTML'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2041720038' AND s.nama = 'CSS'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '2041720038' AND s.nama = 'AutoCAD'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '1941720039' AND s.nama = 'HTML'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '1941720039' AND s.nama = 'Manajemen waktu'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '1941720039' AND s.nama = 'JavaScript'
  UNION ALL
  SELECT m.id, s.id FROM mahasiswa m, skill s WHERE m.nim = '1941720039' AND s.nama = 'PHP'
  ON CONFLICT DO NOTHING;

INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id)
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720010' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720010' AND b.nama = 'Kimia'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720011' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720011' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720012' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720012' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720013' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720013' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720014' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720014' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720015' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720015' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720016' AND b.nama = 'Kimia'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720016' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720017' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720017' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720018' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720018' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720019' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720019' AND b.nama = 'Kimia'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720020' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720020' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720021' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720021' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720022' AND b.nama = 'Kimia'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720022' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720023' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720023' AND b.nama = 'Kimia'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720024' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720024' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720025' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720025' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720026' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720026' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720027' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720027' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720028' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720028' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720029' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720029' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720030' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720030' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720031' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720031' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720032' AND b.nama = 'Kimia'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720032' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720033' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2341720033' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720034' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720034' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720035' AND b.nama = 'Kimia'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720035' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720036' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2241720036' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720037' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2441720037' AND b.nama = 'Kimia'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2041720038' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '2041720038' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '1941720039' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT m.id, b.id FROM mahasiswa m, bidang b WHERE m.nim = '1941720039' AND b.nama = 'Kelistrikan'
  ON CONFLICT DO NOTHING;

-- ----- Riwayat pendidikan, pengalaman, dan sertifikat --------------------
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, file, tautan)
  SELECT m.id, 'pendidikan', 'Akuntansi', 'SMK Negeri 1 Malang', '2021-07-15'::date, '2024-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720010'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Sinergi Data Nusantara', '2026-01-10'::date, '2026-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720010'
  UNION ALL
  SELECT m.id, 'sertifikat', 'AutoCAD Certified User', 'Lembaga Sertifikasi Profesi', '2026-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720010'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Akuntansi', 'SMK Negeri 4 Malang', '2019-07-15'::date, '2022-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720011'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Wilmar Nabati Indonesia', '2024-01-10'::date, '2024-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720011'
  UNION ALL
  SELECT m.id, 'sertifikat', 'Junior Web Developer BNSP', 'Lembaga Sertifikasi Profesi', '2024-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720011'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMK Negeri 1 Malang', '2020-07-15'::date, '2023-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720012'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Sinergi Data Nusantara', '2025-01-10'::date, '2025-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720012'
  UNION ALL
  SELECT m.id, 'sertifikat', 'AutoCAD Certified User', 'Lembaga Sertifikasi Profesi', '2025-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720012'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMA Negeri 3 Malang', '2019-07-15'::date, '2022-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720013'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Wilmar Nabati Indonesia', '2024-01-10'::date, '2024-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720013'
  UNION ALL
  SELECT m.id, 'sertifikat', 'TOEIC 650', 'Lembaga Sertifikasi Profesi', '2024-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720013'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Komputer dan Jaringan', 'SMA Negeri 1 Kediri', '2021-07-15'::date, '2024-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720014'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Nusantara Teknologi Cerdas', '2026-01-10'::date, '2026-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720014'
  UNION ALL
  SELECT m.id, 'sertifikat', 'K3 Umum Kemnaker', 'Lembaga Sertifikasi Profesi', '2026-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720014'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Komputer dan Jaringan', 'SMA Negeri 3 Malang', '2020-07-15'::date, '2023-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720015'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Wilmar Nabati Indonesia', '2025-01-10'::date, '2025-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720015'
  UNION ALL
  SELECT m.id, 'sertifikat', 'K3 Umum Kemnaker', 'Lembaga Sertifikasi Profesi', '2025-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720015'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Komputer dan Jaringan', 'SMK Negeri 1 Malang', '2019-07-15'::date, '2022-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720016'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Semen Indonesia', '2024-01-10'::date, '2024-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720016'
  UNION ALL
  SELECT m.id, 'sertifikat', 'Junior Web Developer BNSP', 'Lembaga Sertifikasi Profesi', '2024-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720016'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMK Telkom Malang', '2021-07-15'::date, '2024-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720017'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Pindad', '2026-01-10'::date, '2026-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720017'
  UNION ALL
  SELECT m.id, 'sertifikat', 'AutoCAD Certified User', 'Lembaga Sertifikasi Profesi', '2026-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720017'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Bahasa', 'SMK Negeri 4 Malang', '2020-07-15'::date, '2023-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720018'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Adhi Karya Tbk', '2025-01-10'::date, '2025-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720018'
  UNION ALL
  SELECT m.id, 'sertifikat', 'K3 Umum Kemnaker', 'Lembaga Sertifikasi Profesi', '2025-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720018'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Jurusan IPA', 'SMA Negeri 3 Malang', '2021-07-15'::date, '2024-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720019'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Wilmar Nabati Indonesia', '2026-01-10'::date, '2026-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720019'
  UNION ALL
  SELECT m.id, 'sertifikat', 'Junior Web Developer BNSP', 'Lembaga Sertifikasi Profesi', '2026-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720019'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Komputer dan Jaringan', 'SMK Telkom Malang', '2019-07-15'::date, '2022-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720020'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Pertamina Patra Niaga', '2024-01-10'::date, '2024-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720020'
  UNION ALL
  SELECT m.id, 'sertifikat', 'K3 Umum Kemnaker', 'Lembaga Sertifikasi Profesi', '2024-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720020'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMA Negeri 3 Malang', '2021-07-15'::date, '2024-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720021'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Wilmar Nabati Indonesia', '2026-01-10'::date, '2026-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720021'
  UNION ALL
  SELECT m.id, 'sertifikat', 'Junior Web Developer BNSP', 'Lembaga Sertifikasi Profesi', '2026-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720021'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Jurusan IPA', 'SMA Negeri 3 Malang', '2019-07-15'::date, '2022-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720022'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Semen Indonesia', '2024-01-10'::date, '2024-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720022'
  UNION ALL
  SELECT m.id, 'sertifikat', 'TOEIC 650', 'Lembaga Sertifikasi Profesi', '2024-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720022'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Akuntansi', 'SMK Negeri 1 Malang', '2020-07-15'::date, '2023-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720023'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Gudang Garam Tbk', '2025-01-10'::date, '2025-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720023'
  UNION ALL
  SELECT m.id, 'sertifikat', 'AutoCAD Certified User', 'Lembaga Sertifikasi Profesi', '2025-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720023'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMA Negeri 3 Malang', '2019-07-15'::date, '2022-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720024'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Mitra Arsip Nusantara', '2024-01-10'::date, '2024-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720024'
  UNION ALL
  SELECT m.id, 'sertifikat', 'TOEIC 650', 'Lembaga Sertifikasi Profesi', '2024-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720024'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMA Negeri 3 Malang', '2019-07-15'::date, '2022-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720025'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Pertamina Patra Niaga', '2024-01-10'::date, '2024-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720025'
  UNION ALL
  SELECT m.id, 'sertifikat', 'Junior Web Developer BNSP', 'Lembaga Sertifikasi Profesi', '2024-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2241720025'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Jurusan IPA', 'SMK Negeri 4 Malang', '2020-07-15'::date, '2023-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720026'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Astra Otoparts', '2025-01-10'::date, '2025-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720026'
  UNION ALL
  SELECT m.id, 'sertifikat', 'Microsoft Office Specialist', 'Lembaga Sertifikasi Profesi', '2025-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720026'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMK Negeri 4 Malang', '2020-07-15'::date, '2023-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720027'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Gudang Garam Tbk', '2025-01-10'::date, '2025-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720027'
  UNION ALL
  SELECT m.id, 'sertifikat', 'Microsoft Office Specialist', 'Lembaga Sertifikasi Profesi', '2025-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720027'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Akuntansi', 'SMA Negeri 3 Malang', '2020-07-15'::date, '2023-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720028'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Telkom Indonesia', '2025-01-10'::date, '2025-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720028'
  UNION ALL
  SELECT m.id, 'sertifikat', 'AutoCAD Certified User', 'Lembaga Sertifikasi Profesi', '2025-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720028'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Bahasa', 'SMK Telkom Malang', '2021-07-15'::date, '2024-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720029'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Mitra Arsip Nusantara', '2026-01-10'::date, '2026-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720029'
  UNION ALL
  SELECT m.id, 'sertifikat', 'TOEIC 650', 'Lembaga Sertifikasi Profesi', '2026-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720029'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMK Telkom Malang', '2021-07-15'::date, '2024-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720030'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Sinergi Data Nusantara', '2026-01-10'::date, '2026-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720030'
  UNION ALL
  SELECT m.id, 'sertifikat', 'AutoCAD Certified User', 'Lembaga Sertifikasi Profesi', '2026-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2441720030'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMK Negeri 4 Malang', '2020-07-15'::date, '2023-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720031'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Semen Indonesia', '2025-01-10'::date, '2025-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720031'
  UNION ALL
  SELECT m.id, 'sertifikat', 'TOEIC 650', 'Lembaga Sertifikasi Profesi', '2025-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720031'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMA Negeri 3 Malang', '2020-07-15'::date, '2023-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720032'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Bank Mandiri Tbk', '2025-01-10'::date, '2025-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720032'
  UNION ALL
  SELECT m.id, 'sertifikat', 'TOEIC 650', 'Lembaga Sertifikasi Profesi', '2025-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720032'
  UNION ALL
  SELECT m.id, 'pendidikan', 'Teknik Mesin', 'SMA Negeri 3 Malang', '2020-07-15'::date, '2023-06-10'::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720033'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang industri', 'PT Bank Mandiri Tbk', '2025-01-10'::date, '2025-06-30'::date, 'Mengerjakan tugas harian tim dan menyusun laporan kegiatan magang.', NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720033'
  UNION ALL
  SELECT m.id, 'sertifikat', 'TOEIC 650', 'Lembaga Sertifikasi Profesi', '2025-11-20'::date, NULL::date, NULL::text, NULL::varchar, NULL::varchar FROM mahasiswa m WHERE m.nim = '2341720033';

-- ----- 15 akun perusahaan ------------------------------------------------
INSERT INTO pengguna (email, password_hash, role, status_akun) VALUES
  ('hrd@astraotoparts.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@telkomindonesia.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@wilmarnabatiindonesia.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@gudanggaram.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@pindad.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@semenindonesia.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@bankmandiri.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@pertaminapatraniaga.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@nestleindonesia.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@barataindonesia.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@nusantarateknologicerd.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@adhikarya.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@sinergidatanusantara.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@mitraarsipnusantara.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif'),
  ('hrd@energilistrikmandiri.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif');

INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan,
    alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing, deskripsi)
  SELECT id, 'PT Astra Otoparts', 'Manufaktur', 'Swasta nasional', 'Jl. Raya Bekasi KM 27', 'Jakarta', 'Hendra Wijaya', 'HRD Supervisor', '085109110340', true, 'PT Astra Otoparts bergerak di bidang manufaktur dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@astraotoparts.co.id'
  UNION ALL
  SELECT id, 'PT Telkom Indonesia', 'Teknologi Informasi', 'BUMN', 'Jl. Japati 1', 'Bandung', 'Siti Maryam', 'HRD Supervisor', '088278915816', true, 'PT Telkom Indonesia bergerak di bidang teknologi informasi dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@telkomindonesia.co.id'
  UNION ALL
  SELECT id, 'PT Wilmar Nabati Indonesia', 'Kimia', 'Swasta nasional', 'Jl. Kapten Darmo Sugondo', 'Gresik', 'Bambang Setiadi', 'Talent Acquisition', '087717242651', true, 'PT Wilmar Nabati Indonesia bergerak di bidang kimia dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@wilmarnabatiindonesia.co.id'
  UNION ALL
  SELECT id, 'PT Gudang Garam Tbk', 'Manufaktur', 'Swasta nasional', 'Jl. Semampir II/1', 'Kediri', 'Rani Puspitasari', 'HRD Supervisor', '089029743902', true, 'PT Gudang Garam Tbk bergerak di bidang manufaktur dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@gudanggaram.co.id'
  UNION ALL
  SELECT id, 'PT Pindad', 'Manufaktur', 'BUMN', 'Jl. Gatot Subroto 517', 'Bandung', 'Agus Haryanto', 'Recruitment Officer', '089597024900', true, 'PT Pindad bergerak di bidang manufaktur dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@pindad.co.id'
  UNION ALL
  SELECT id, 'PT Semen Indonesia', 'Konstruksi', 'BUMN', 'Jl. Veteran', 'Gresik', 'Dewi Kartika', 'HRD Supervisor', '089640401815', true, 'PT Semen Indonesia bergerak di bidang konstruksi dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@semenindonesia.co.id'
  UNION ALL
  SELECT id, 'PT Bank Mandiri Tbk', 'Keuangan', 'BUMN', 'Jl. Jenderal Gatot Subroto 36', 'Jakarta', 'Yulianto', 'Talent Acquisition', '085387094226', true, 'PT Bank Mandiri Tbk bergerak di bidang keuangan dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@bankmandiri.co.id'
  UNION ALL
  SELECT id, 'PT Pertamina Patra Niaga', 'Kimia', 'BUMN', 'Jl. MH Thamrin 55', 'Jakarta', 'Nadia Rahmi', 'Recruitment Officer', '087454068093', true, 'PT Pertamina Patra Niaga bergerak di bidang kimia dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@pertaminapatraniaga.co.id'
  UNION ALL
  SELECT id, 'PT Nestle Indonesia', 'Manufaktur', 'Swasta asing', 'Jl. Raya Kejayan', 'Pasuruan', 'Pradana Putra', 'HR Manager', '083364416309', true, 'PT Nestle Indonesia bergerak di bidang manufaktur dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@nestleindonesia.co.id'
  UNION ALL
  SELECT id, 'PT Barata Indonesia', 'Manufaktur', 'BUMN', 'Jl. Veteran 241', 'Gresik', 'Lilis Suryani', 'HRD Supervisor', '081549220765', true, 'PT Barata Indonesia bergerak di bidang manufaktur dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@barataindonesia.co.id'
  UNION ALL
  SELECT id, 'PT Nusantara Teknologi Cerdas', 'Teknologi Informasi', 'Startup', 'Jl. Soekarno Hatta 9', 'Malang', 'Fathur Rahman', 'Talent Acquisition', '081829102300', true, 'PT Nusantara Teknologi Cerdas bergerak di bidang teknologi informasi dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@nusantarateknologicerd.co.id'
  UNION ALL
  SELECT id, 'PT Adhi Karya Tbk', 'Konstruksi', 'BUMN', 'Jl. Raya Pasar Minggu KM 18', 'Jakarta', 'Ani Kurnia', 'Talent Acquisition', '083107466247', true, 'PT Adhi Karya Tbk bergerak di bidang konstruksi dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@adhikarya.co.id'
  UNION ALL
  SELECT id, 'PT Sinergi Data Nusantara', 'Teknologi Informasi', 'Swasta nasional', 'Jl. Veteran 12', 'Malang', 'Rudi Hartanto', 'HR Manager', '082647121173', true, 'PT Sinergi Data Nusantara bergerak di bidang teknologi informasi dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@sinergidatanusantara.co.id'
  UNION ALL
  SELECT id, 'PT Mitra Arsip Nusantara', 'Perdagangan dan Jasa', 'Swasta nasional', 'Jl. Basuki Rahmat 22', 'Surabaya', 'Sri Wahyuni', 'Recruitment Officer', '088511178075', true, 'PT Mitra Arsip Nusantara bergerak di bidang perdagangan dan jasa dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@mitraarsipnusantara.co.id'
  UNION ALL
  SELECT id, 'PT Energi Listrik Mandiri', 'Kelistrikan', 'Swasta nasional', 'Jl. Ahmad Yani 88', 'Sidoarjo', 'Joko Susilo', 'HRD Supervisor', '087519950363', true, 'PT Energi Listrik Mandiri bergerak di bidang kelistrikan dan rutin membuka kesempatan bagi lulusan vokasi Politeknik Negeri Malang.'
    FROM pengguna WHERE email = 'hrd@energilistrikmandiri.co.id';

-- ----- 40 lowongan -------------------------------------------------------
INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja,
    lokasi, gaji, kuota, batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan,
    pamflet, kode_pratinjau, status, alasan_nonaktif)
  SELECT pr.id, b.id, 'Junior Web Developer', 'Paruh waktu', 'WFH', 'Jakarta', 'Rp 2.500.000 - Rp 3.500.000', 5, '2026-10-20'::date,
         'Bergabung sebagai Junior Web Developer di PT Astra Otoparts. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'PHP, JavaScript, PostgreSQL', 'contoh-pamflet.jpg', '34db9deffcac44e4c1cb1737a921dce6', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Astra Otoparts' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT pr.id, b.id, 'Network Engineer', 'Tetap', 'WFH', 'Bandung', 'Negosiasi', 5, '2026-10-26'::date,
         'Bergabung sebagai Network Engineer di PT Telkom Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Bandung.', 'Cisco, Mikrotik, TCP/IP', 'contoh-pamflet.jpg', 'eb49b08c0d23169eb1df75fa25191d98', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Telkom Indonesia' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT pr.id, b.id, 'Quality Control Staff', 'Magang', 'WFH', 'Gresik', 'Rp 2.500.000 - Rp 3.500.000', 4, '2026-10-28'::date,
         'Bergabung sebagai Quality Control Staff di PT Wilmar Nabati Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Gresik.', 'Pengendalian mutu, ISO 9001', 'contoh-pamflet.jpg', 'ee10d1437a04c9e38fe430838fe5e4b7', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT pr.id, b.id, 'Site Engineer', 'Kontrak', 'WFH', 'Kediri', 'Rp 4.000.000 - Rp 5.500.000', 3, '2026-12-04'::date,
         'Bergabung sebagai Site Engineer di PT Gudang Garam Tbk. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Kediri.', 'AutoCAD, Pembacaan gambar teknik', 'contoh-pamflet.jpg', 'a2ba4c3d7671cdc6b595a1921165e453', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Gudang Garam Tbk' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT pr.id, b.id, 'Drafter Struktur', 'Paruh waktu', 'WFH', 'Bandung', 'Rp 3.500.000 - Rp 4.500.000', 5, '2026-11-16'::date,
         'Bergabung sebagai Drafter Struktur di PT Pindad. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Bandung.', 'AutoCAD, SketchUp', 'contoh-pamflet.jpg', 'c4a2d4ce8dc6b6270876c772fdadef7f', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pindad' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT pr.id, b.id, 'Teknisi Perawatan Mesin', 'Magang', 'WFH', 'Gresik', 'Rp 3.500.000 - Rp 4.500.000', 3, '2026-12-16'::date,
         'Bergabung sebagai Teknisi Perawatan Mesin di PT Semen Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Gresik.', 'Perawatan preventif, Hidrolik', 'contoh-pamflet.jpg', '96e8f1e947ca10822b65fd8e2ebb5359', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Semen Indonesia' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT pr.id, b.id, 'Operator Instrumentasi', 'Paruh waktu', 'Hybrid', 'Jakarta', 'Rp 2.500.000 - Rp 3.500.000', 4, '2026-12-16'::date,
         'Bergabung sebagai Operator Instrumentasi di PT Bank Mandiri Tbk. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'PLC, SCADA', 'contoh-pamflet.jpg', 'dd443baecc2e40aefe99443a6ca6ba3e', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Bank Mandiri Tbk' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT pr.id, b.id, 'Staf Akuntansi', 'Magang', 'WFH', 'Jakarta', 'Rp 4.000.000 - Rp 5.500.000', 4, '2026-12-30'::date,
         'Bergabung sebagai Staf Akuntansi di PT Pertamina Patra Niaga. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'Microsoft Excel, Accurate', 'contoh-pamflet.jpg', 'db17263bf41995a40498cc73db101a32', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pertamina Patra Niaga' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT pr.id, b.id, 'Analis Keuangan', 'Kontrak', 'Hybrid', 'Pasuruan', 'Rp 3.500.000 - Rp 4.500.000', 5, '2026-12-06'::date,
         'Bergabung sebagai Analis Keuangan di PT Nestle Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Pasuruan.', 'Analisis laporan keuangan, Excel', 'contoh-pamflet.jpg', '88afac51604a28babb6ba3f8d5596ddd', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nestle Indonesia' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT pr.id, b.id, 'Digital Marketing Specialist', 'Magang', 'Hybrid', 'Gresik', 'Rp 5.000.000 - Rp 7.000.000', 5, '2026-11-24'::date,
         'Bergabung sebagai Digital Marketing Specialist di PT Barata Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Gresik.', 'SEO, Meta Ads, Copywriting', 'contoh-pamflet.jpg', '48c4b8b7c7ff48b5a0da8f7cb65ab7f8', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Barata Indonesia' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT pr.id, b.id, 'Staf Administrasi dan Kearsipan', 'Paruh waktu', 'WFH', 'Malang', 'Rp 4.000.000 - Rp 5.500.000', 4, '2026-12-29'::date,
         'Bergabung sebagai Staf Administrasi dan Kearsipan di PT Nusantara Teknologi Cerdas. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Malang.', 'Pengelolaan arsip, Microsoft Office', 'contoh-pamflet.jpg', 'dafa250b19259d23e27fd2a0be3ba049', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT pr.id, b.id, 'Process Engineer', 'Kontrak', 'WFO', 'Jakarta', 'Rp 2.500.000 - Rp 3.500.000', 2, '2026-11-28'::date,
         'Bergabung sebagai Process Engineer di PT Adhi Karya Tbk. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'Neraca massa, Utilitas pabrik', 'contoh-pamflet.jpg', '0d3846637b494f42fd3886c110ac770d', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Adhi Karya Tbk' AND b.nama = 'Kimia'
  UNION ALL
  SELECT pr.id, b.id, 'Junior Programmer', 'Magang', 'Hybrid', 'Malang', 'Rp 5.000.000 - Rp 7.000.000', 4, '2026-11-12'::date,
         'Bergabung sebagai Junior Programmer di PT Sinergi Data Nusantara. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Malang.', 'Java, Git, REST API', 'contoh-pamflet.jpg', '717493520e6cae8b0f662111c949cbc2', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Sinergi Data Nusantara' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT pr.id, b.id, 'Business Analyst', 'Magang', 'WFH', 'Surabaya', 'Rp 2.500.000 - Rp 3.500.000', 1, '2026-11-01'::date,
         'Bergabung sebagai Business Analyst di PT Mitra Arsip Nusantara. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Surabaya.', 'BPMN, SQL, Komunikasi', 'contoh-pamflet.jpg', '6cbd28f43e9817151c4d6bfdc432d149', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Mitra Arsip Nusantara' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT pr.id, b.id, 'Teknisi Kelistrikan', 'Paruh waktu', 'Hybrid', 'Sidoarjo', 'Rp 2.500.000 - Rp 3.500.000', 4, '2026-11-27'::date,
         'Bergabung sebagai Teknisi Kelistrikan di PT Energi Listrik Mandiri. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Sidoarjo.', 'Instalasi listrik, K3', 'contoh-pamflet.jpg', 'f59e7d8f8d1ad5cfa78b3103ab3b99d8', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Energi Listrik Mandiri' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT pr.id, b.id, 'Surveyor Pertambangan', 'Paruh waktu', 'WFO', 'Jakarta', 'Rp 5.000.000 - Rp 7.000.000', 5, '2026-10-14'::date,
         'Bergabung sebagai Surveyor Pertambangan di PT Astra Otoparts. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'Total Station, GPS Geodetik', 'contoh-pamflet.jpg', '49888e6d7753e15a03f5449963d351ed', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Astra Otoparts' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT pr.id, b.id, 'Maintenance Pesawat Udara', 'Kontrak', 'WFH', 'Bandung', 'Rp 3.500.000 - Rp 4.500.000', 5, '2026-11-08'::date,
         'Bergabung sebagai Maintenance Pesawat Udara di PT Telkom Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Bandung.', 'Basic Aircraft Maintenance', 'contoh-pamflet.jpg', '5552a2af1afe7db0bbb947277ddacd90', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Telkom Indonesia' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT pr.id, b.id, 'Teknisi Otomotif Elektronik', 'Magang', 'WFH', 'Gresik', 'Rp 2.500.000 - Rp 3.500.000', 4, '2026-10-23'::date,
         'Bergabung sebagai Teknisi Otomotif Elektronik di PT Wilmar Nabati Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Gresik.', 'ECU, Diagnostik kendaraan', 'contoh-pamflet.jpg', '22c556a92b8eb1efcdba1877319fa3ea', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT pr.id, b.id, 'Staf Pajak', 'Kontrak', 'WFO', 'Kediri', 'Rp 4.000.000 - Rp 5.500.000', 5, '2026-10-22'::date,
         'Bergabung sebagai Staf Pajak di PT Gudang Garam Tbk. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Kediri.', 'PPh, PPN, e-Faktur', 'contoh-pamflet.jpg', 'ddf03368465cc667c4666ba838c08964', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Gudang Garam Tbk' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT pr.id, b.id, 'Customer Relation Officer', 'Kontrak', 'WFO', 'Bandung', 'Rp 5.000.000 - Rp 7.000.000', 1, '2026-12-19'::date,
         'Bergabung sebagai Customer Relation Officer di PT Pindad. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Bandung.', 'Bahasa Inggris, Komunikasi', 'contoh-pamflet.jpg', '24ab048c4168688510e0a5d218dfd89d', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pindad' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT pr.id, b.id, 'Junior Web Developer', 'Magang', 'WFO', 'Gresik', 'Rp 4.000.000 - Rp 5.500.000', 5, '2026-10-23'::date,
         'Bergabung sebagai Junior Web Developer di PT Semen Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Gresik.', 'PHP, JavaScript, PostgreSQL', 'contoh-pamflet.jpg', '0d279688905792ff4c38be5134c4f881', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Semen Indonesia' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT pr.id, b.id, 'Network Engineer', 'Magang', 'WFO', 'Jakarta', 'Rp 3.500.000 - Rp 4.500.000', 1, '2026-11-26'::date,
         'Bergabung sebagai Network Engineer di PT Bank Mandiri Tbk. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'Cisco, Mikrotik, TCP/IP', 'contoh-pamflet.jpg', 'c0c456688a1cf123e41a8eb3e4f17d02', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Bank Mandiri Tbk' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT pr.id, b.id, 'Quality Control Staff', 'Kontrak', 'WFO', 'Jakarta', 'Rp 5.000.000 - Rp 7.000.000', 1, '2026-11-06'::date,
         'Bergabung sebagai Quality Control Staff di PT Pertamina Patra Niaga. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'Pengendalian mutu, ISO 9001', 'contoh-pamflet.jpg', '0cc6f9d0c684490e1c0f03ebf12372fc', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pertamina Patra Niaga' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT pr.id, b.id, 'Site Engineer', 'Tetap', 'WFH', 'Pasuruan', 'Rp 2.500.000 - Rp 3.500.000', 2, '2026-11-24'::date,
         'Bergabung sebagai Site Engineer di PT Nestle Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Pasuruan.', 'AutoCAD, Pembacaan gambar teknik', 'contoh-pamflet.jpg', '6b4246b55d73b196c6699ce77a52e723', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nestle Indonesia' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT pr.id, b.id, 'Drafter Struktur', 'Tetap', 'WFH', 'Gresik', 'Rp 2.500.000 - Rp 3.500.000', 2, '2026-12-04'::date,
         'Bergabung sebagai Drafter Struktur di PT Barata Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Gresik.', 'AutoCAD, SketchUp', 'contoh-pamflet.jpg', 'b8b3cc1dfd95dbd69cabfa4867fdbe4e', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Barata Indonesia' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT pr.id, b.id, 'Teknisi Perawatan Mesin', 'Magang', 'WFH', 'Malang', 'Rp 5.000.000 - Rp 7.000.000', 2, '2026-10-21'::date,
         'Bergabung sebagai Teknisi Perawatan Mesin di PT Nusantara Teknologi Cerdas. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Malang.', 'Perawatan preventif, Hidrolik', 'contoh-pamflet.jpg', '21aff7f6d80ef487db6eeae8998f8583', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT pr.id, b.id, 'Operator Instrumentasi', 'Magang', 'WFH', 'Jakarta', 'Rp 4.000.000 - Rp 5.500.000', 1, '2026-11-06'::date,
         'Bergabung sebagai Operator Instrumentasi di PT Adhi Karya Tbk. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'PLC, SCADA', 'contoh-pamflet.jpg', 'ac52e602c385f9e45b7c7065f207659c', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Adhi Karya Tbk' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT pr.id, b.id, 'Staf Akuntansi', 'Magang', 'WFH', 'Malang', 'Rp 5.000.000 - Rp 7.000.000', 1, '2026-11-25'::date,
         'Bergabung sebagai Staf Akuntansi di PT Sinergi Data Nusantara. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Malang.', 'Microsoft Excel, Accurate', 'contoh-pamflet.jpg', '735cb15ef8cc9704fdf41f0187790dc3', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Sinergi Data Nusantara' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT pr.id, b.id, 'Analis Keuangan', 'Paruh waktu', 'WFO', 'Surabaya', 'Negosiasi', 3, '2026-11-09'::date,
         'Bergabung sebagai Analis Keuangan di PT Mitra Arsip Nusantara. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Surabaya.', 'Analisis laporan keuangan, Excel', 'contoh-pamflet.jpg', '3fb3ce5372194a44f47826693e07b51e', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Mitra Arsip Nusantara' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT pr.id, b.id, 'Digital Marketing Specialist', 'Kontrak', 'Hybrid', 'Sidoarjo', 'Negosiasi', 5, '2026-12-28'::date,
         'Bergabung sebagai Digital Marketing Specialist di PT Energi Listrik Mandiri. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Sidoarjo.', 'SEO, Meta Ads, Copywriting', 'contoh-pamflet.jpg', '3a18c71ba3dd3424b9544d8e2302adbc', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Energi Listrik Mandiri' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT pr.id, b.id, 'Staf Administrasi dan Kearsipan', 'Kontrak', 'Hybrid', 'Jakarta', 'Rp 4.000.000 - Rp 5.500.000', 5, '2026-12-12'::date,
         'Bergabung sebagai Staf Administrasi dan Kearsipan di PT Astra Otoparts. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'Pengelolaan arsip, Microsoft Office', 'contoh-pamflet.jpg', '9c3abb9e6f7c6b9ce6972c2e1eb69e97', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Astra Otoparts' AND b.nama = 'Perdagangan dan Jasa'
  UNION ALL
  SELECT pr.id, b.id, 'Process Engineer', 'Paruh waktu', 'WFO', 'Bandung', 'Rp 5.000.000 - Rp 7.000.000', 4, '2026-11-14'::date,
         'Bergabung sebagai Process Engineer di PT Telkom Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Bandung.', 'Neraca massa, Utilitas pabrik', 'contoh-pamflet.jpg', 'ddc6d284e5975a51867afc97d12b4249', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Telkom Indonesia' AND b.nama = 'Kimia'
  UNION ALL
  SELECT pr.id, b.id, 'Junior Programmer', 'Magang', 'WFO', 'Gresik', 'Rp 3.500.000 - Rp 4.500.000', 5, '2026-11-01'::date,
         'Bergabung sebagai Junior Programmer di PT Wilmar Nabati Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Gresik.', 'Java, Git, REST API', 'contoh-pamflet.jpg', '7c9333b1286878b913541a754e2098fa', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT pr.id, b.id, 'Business Analyst', 'Kontrak', 'WFH', 'Kediri', 'Negosiasi', 2, '2026-12-02'::date,
         'Bergabung sebagai Business Analyst di PT Gudang Garam Tbk. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Kediri.', 'BPMN, SQL, Komunikasi', 'contoh-pamflet.jpg', '4d9ac3d2c55d7aaae4b983994e07fb5e', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Gudang Garam Tbk' AND b.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT pr.id, b.id, 'Teknisi Kelistrikan', 'Magang', 'WFH', 'Bandung', 'Rp 5.000.000 - Rp 7.000.000', 5, '2026-11-15'::date,
         'Bergabung sebagai Teknisi Kelistrikan di PT Pindad. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Bandung.', 'Instalasi listrik, K3', 'contoh-pamflet.jpg', 'b6033c01fb7cb02c9e132ddbe484be16', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pindad' AND b.nama = 'Kelistrikan'
  UNION ALL
  SELECT pr.id, b.id, 'Surveyor Pertambangan', 'Kontrak', 'Hybrid', 'Gresik', 'Rp 2.500.000 - Rp 3.500.000', 4, '2026-12-25'::date,
         'Bergabung sebagai Surveyor Pertambangan di PT Semen Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Gresik.', 'Total Station, GPS Geodetik', 'contoh-pamflet.jpg', 'cb6b50bca7a25cc418da585aea98f568', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Semen Indonesia' AND b.nama = 'Konstruksi'
  UNION ALL
  SELECT pr.id, b.id, 'Maintenance Pesawat Udara', 'Paruh waktu', 'WFO', 'Jakarta', 'Rp 2.500.000 - Rp 3.500.000', 1, '2026-11-04'::date,
         'Bergabung sebagai Maintenance Pesawat Udara di PT Bank Mandiri Tbk. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'Basic Aircraft Maintenance', 'contoh-pamflet.jpg', '7b6031b12a01e7130bf1c56089fdbb6d', 'ditutup', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Bank Mandiri Tbk' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT pr.id, b.id, 'Teknisi Otomotif Elektronik', 'Paruh waktu', 'WFO', 'Jakarta', 'Rp 3.500.000 - Rp 4.500.000', 1, '2026-12-04'::date,
         'Bergabung sebagai Teknisi Otomotif Elektronik di PT Pertamina Patra Niaga. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Jakarta.', 'ECU, Diagnostik kendaraan', 'contoh-pamflet.jpg', '6f8193a326b5e4438a08c87795f57428', 'aktif', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pertamina Patra Niaga' AND b.nama = 'Manufaktur'
  UNION ALL
  SELECT pr.id, b.id, 'Staf Pajak', 'Kontrak', 'WFH', 'Pasuruan', 'Rp 4.000.000 - Rp 5.500.000', 5, '2026-12-27'::date,
         'Bergabung sebagai Staf Pajak di PT Nestle Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Pasuruan.', 'PPh, PPN, e-Faktur', 'contoh-pamflet.jpg', '2a1839109e75dd1f35579d8339042d0b', 'ditutup', NULL::varchar
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nestle Indonesia' AND b.nama = 'Keuangan'
  UNION ALL
  SELECT pr.id, b.id, 'Customer Relation Officer', 'Magang', 'Hybrid', 'Gresik', 'Rp 4.000.000 - Rp 5.500.000', 5, '2026-11-05'::date,
         'Bergabung sebagai Customer Relation Officer di PT Barata Indonesia. Kamu akan terlibat langsung pada pekerjaan harian tim, didampingi mentor, dan mendapat pengalaman kerja nyata sesuai bidang vokasi.', 'Lulusan atau mahasiswa tingkat akhir program vokasi yang relevan. Terbiasa bekerja dalam tim, teliti, dan mau belajar hal baru. Bersedia bekerja di Gresik.', 'Bahasa Inggris, Komunikasi', 'contoh-pamflet.jpg', 'b50459b1cf100959f03a06e111559ae0', 'nonaktif', 'Lowongan tidak sesuai ketentuan Career Center.'
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Barata Indonesia' AND b.nama = 'Perdagangan dan Jasa';

-- ----- Jurusan sasaran tiap lowongan -------------------------------------
INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id)
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '34db9deffcac44e4c1cb1737a921dce6' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'eb49b08c0d23169eb1df75fa25191d98' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'eb49b08c0d23169eb1df75fa25191d98' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'ee10d1437a04c9e38fe430838fe5e4b7' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'ee10d1437a04c9e38fe430838fe5e4b7' AND j.nama = 'Teknik Kimia'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'a2ba4c3d7671cdc6b595a1921165e453' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'c4a2d4ce8dc6b6270876c772fdadef7f' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '96e8f1e947ca10822b65fd8e2ebb5359' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'dd443baecc2e40aefe99443a6ca6ba3e' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'db17263bf41995a40498cc73db101a32' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '88afac51604a28babb6ba3f8d5596ddd' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '48c4b8b7c7ff48b5a0da8f7cb65ab7f8' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'dafa250b19259d23e27fd2a0be3ba049' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '0d3846637b494f42fd3886c110ac770d' AND j.nama = 'Teknik Kimia'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '717493520e6cae8b0f662111c949cbc2' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '6cbd28f43e9817151c4d6bfdc432d149' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '6cbd28f43e9817151c4d6bfdc432d149' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'f59e7d8f8d1ad5cfa78b3103ab3b99d8' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '49888e6d7753e15a03f5449963d351ed' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '5552a2af1afe7db0bbb947277ddacd90' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '22c556a92b8eb1efcdba1877319fa3ea' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '22c556a92b8eb1efcdba1877319fa3ea' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'ddf03368465cc667c4666ba838c08964' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '24ab048c4168688510e0a5d218dfd89d' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '0d279688905792ff4c38be5134c4f881' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'c0c456688a1cf123e41a8eb3e4f17d02' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'c0c456688a1cf123e41a8eb3e4f17d02' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '0cc6f9d0c684490e1c0f03ebf12372fc' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '0cc6f9d0c684490e1c0f03ebf12372fc' AND j.nama = 'Teknik Kimia'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '6b4246b55d73b196c6699ce77a52e723' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'b8b3cc1dfd95dbd69cabfa4867fdbe4e' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '21aff7f6d80ef487db6eeae8998f8583' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'ac52e602c385f9e45b7c7065f207659c' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '735cb15ef8cc9704fdf41f0187790dc3' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '3fb3ce5372194a44f47826693e07b51e' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '3a18c71ba3dd3424b9544d8e2302adbc' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '9c3abb9e6f7c6b9ce6972c2e1eb69e97' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'ddc6d284e5975a51867afc97d12b4249' AND j.nama = 'Teknik Kimia'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '7c9333b1286878b913541a754e2098fa' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '4d9ac3d2c55d7aaae4b983994e07fb5e' AND j.nama = 'Teknologi Informasi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '4d9ac3d2c55d7aaae4b983994e07fb5e' AND j.nama = 'Administrasi Niaga'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'b6033c01fb7cb02c9e132ddbe484be16' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'cb6b50bca7a25cc418da585aea98f568' AND j.nama = 'Teknik Sipil'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '7b6031b12a01e7130bf1c56089fdbb6d' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '6f8193a326b5e4438a08c87795f57428' AND j.nama = 'Teknik Mesin'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '6f8193a326b5e4438a08c87795f57428' AND j.nama = 'Teknik Elektro'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = '2a1839109e75dd1f35579d8339042d0b' AND j.nama = 'Akuntansi'
  UNION ALL
  SELECT l.id, j.id FROM lowongan l, jurusan j WHERE l.kode_pratinjau = 'b50459b1cf100959f03a06e111559ae0' AND j.nama = 'Administrasi Niaga'
  ON CONFLICT DO NOTHING;

-- ----- 30 lamaran dengan status bervariasi -------------------------------
INSERT INTO lamaran (mahasiswa_id, lowongan_id, tanggal_lamar, status, jenis_cv,
    file_cv, file_ktm, file_surat_pengantar, catatan_pelamar, snapshot_profil, catatan_perusahaan)
  SELECT m.id, l.id, '2026-09-08'::timestamp, 'diajukan', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya tertarik karena posisi ini sesuai dengan tugas akhir saya.', '{"nama":"Ahmad Pratama","nim":"2441720010","prodi":"Teknik Sipil","jenjang":"D-III","jurusan":"Teknik Sipil","angkatan":2024,"ipk":3.49}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2441720010' AND l.kode_pratinjau = 'cb6b50bca7a25cc418da585aea98f568'
  UNION ALL
  SELECT m.id, l.id, '2026-09-12'::timestamp, 'diterima', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Mohon dipertimbangkan, saya siap mulai setelah yudisium.', '{"nama":"Siti Nuraini","nim":"2241720011","prodi":"Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air","jenjang":"D-III","jurusan":"Teknik Sipil","angkatan":2022,"ipk":3.31}'::jsonb, 'Selamat, kamu diterima. Tim kami akan menghubungi untuk proses berikutnya.'
    FROM mahasiswa m, lowongan l WHERE m.nim = '2241720011' AND l.kode_pratinjau = 'cb6b50bca7a25cc418da585aea98f568'
  UNION ALL
  SELECT m.id, l.id, '2026-09-14'::timestamp, 'diajukan', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya tertarik karena posisi ini sesuai dengan tugas akhir saya.', '{"nama":"Rizky Saputra","nim":"2341720012","prodi":"Teknologi Pertambangan","jenjang":"D-III","jurusan":"Teknik Sipil","angkatan":2023,"ipk":3.78}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2341720012' AND l.kode_pratinjau = '49888e6d7753e15a03f5449963d351ed'
  UNION ALL
  SELECT m.id, l.id, '2026-09-07'::timestamp, 'diajukan', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Dewi Lestari","nim":"2241720013","prodi":"Teknologi Rekayasa Konstruksi Jalan dan Jembatan","jenjang":"D-IV","jurusan":"Teknik Sipil","angkatan":2022,"ipk":3.5}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2241720013' AND l.kode_pratinjau = 'cb6b50bca7a25cc418da585aea98f568'
  UNION ALL
  SELECT m.id, l.id, '2026-09-24'::timestamp, 'dibatalkan', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Bagus Wicaksono","nim":"2441720014","prodi":"Manajemen Rekayasa Konstruksi","jenjang":"D-IV","jurusan":"Teknik Sipil","angkatan":2024,"ipk":3.64}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2441720014' AND l.kode_pratinjau = 'a2ba4c3d7671cdc6b595a1921165e453'
  UNION ALL
  SELECT m.id, l.id, '2026-09-26'::timestamp, 'interview', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Nur Hidayah","nim":"2341720015","prodi":"Teknik Mesin","jenjang":"D-III","jurusan":"Teknik Mesin","angkatan":2023,"ipk":3.11}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2341720015' AND l.kode_pratinjau = '0cc6f9d0c684490e1c0f03ebf12372fc'
  UNION ALL
  SELECT m.id, l.id, '2026-09-04'::timestamp, 'diterima', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Fajar Ramadhan","nim":"2241720016","prodi":"Teknologi Pemeliharaan Pesawat Udara","jenjang":"D-III","jurusan":"Teknik Mesin","angkatan":2022,"ipk":3.6}'::jsonb, 'Selamat, kamu diterima. Tim kami akan menghubungi untuk proses berikutnya.'
    FROM mahasiswa m, lowongan l WHERE m.nim = '2241720016' AND l.kode_pratinjau = '5552a2af1afe7db0bbb947277ddacd90'
  UNION ALL
  SELECT m.id, l.id, '2026-09-17'::timestamp, 'diterima', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Intan Permata","nim":"2441720017","prodi":"Teknik Mesin Produksi dan Perawatan","jenjang":"D-IV","jurusan":"Teknik Mesin","angkatan":2024,"ipk":3.22}'::jsonb, 'Selamat, kamu diterima. Tim kami akan menghubungi untuk proses berikutnya.'
    FROM mahasiswa m, lowongan l WHERE m.nim = '2441720017' AND l.kode_pratinjau = '0cc6f9d0c684490e1c0f03ebf12372fc'
  UNION ALL
  SELECT m.id, l.id, '2026-09-26'::timestamp, 'ditolak', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Mohon dipertimbangkan, saya siap mulai setelah yudisium.', '{"nama":"Yoga Prasetyo","nim":"2341720018","prodi":"Teknik Otomotif Elektronik","jenjang":"D-IV","jurusan":"Teknik Mesin","angkatan":2023,"ipk":3.85}'::jsonb, 'Terima kasih sudah melamar. Kualifikasi belum sesuai kebutuhan posisi ini.'
    FROM mahasiswa m, lowongan l WHERE m.nim = '2341720018' AND l.kode_pratinjau = '6f8193a326b5e4438a08c87795f57428'
  UNION ALL
  SELECT m.id, l.id, '2026-09-19'::timestamp, 'ditolak', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Mohon dipertimbangkan, saya siap mulai setelah yudisium.', '{"nama":"Laila Rahmawati","nim":"2441720019","prodi":"Teknik Listrik","jenjang":"D-III","jurusan":"Teknik Elektro","angkatan":2024,"ipk":3.22}'::jsonb, 'Terima kasih sudah melamar. Kualifikasi belum sesuai kebutuhan posisi ini.'
    FROM mahasiswa m, lowongan l WHERE m.nim = '2441720019' AND l.kode_pratinjau = 'b6033c01fb7cb02c9e132ddbe484be16'
  UNION ALL
  SELECT m.id, l.id, '2026-09-08'::timestamp, 'diterima', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya pernah magang di bidang yang serupa selama enam bulan.', '{"nama":"Dimas Santoso","nim":"2241720020","prodi":"Teknik Elektronika","jenjang":"D-III","jurusan":"Teknik Elektro","angkatan":2022,"ipk":3.47}'::jsonb, 'Selamat, kamu diterima. Tim kami akan menghubungi untuk proses berikutnya.'
    FROM mahasiswa m, lowongan l WHERE m.nim = '2241720020' AND l.kode_pratinjau = '22c556a92b8eb1efcdba1877319fa3ea'
  UNION ALL
  SELECT m.id, l.id, '2026-09-27'::timestamp, 'screening', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Mohon dipertimbangkan, saya siap mulai setelah yudisium.', '{"nama":"Ayu Anggraini","nim":"2441720021","prodi":"Teknik Telekomunikasi","jenjang":"D-III","jurusan":"Teknik Elektro","angkatan":2024,"ipk":3.44}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2441720021' AND l.kode_pratinjau = 'c0c456688a1cf123e41a8eb3e4f17d02'
  UNION ALL
  SELECT m.id, l.id, '2026-09-16'::timestamp, 'screening', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Mohon dipertimbangkan, saya siap mulai setelah yudisium.', '{"nama":"Hendra Wijaya","nim":"2241720022","prodi":"Sistem Kelistrikan","jenjang":"D-IV","jurusan":"Teknik Elektro","angkatan":2022,"ipk":3.4}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2241720022' AND l.kode_pratinjau = 'ac52e602c385f9e45b7c7065f207659c'
  UNION ALL
  SELECT m.id, l.id, '2026-09-12'::timestamp, 'screening', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Mohon dipertimbangkan, saya siap mulai setelah yudisium.', '{"nama":"Rina Kusuma","nim":"2341720023","prodi":"Teknik Elektronika","jenjang":"D-IV","jurusan":"Teknik Elektro","angkatan":2023,"ipk":3.39}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2341720023' AND l.kode_pratinjau = 'eb49b08c0d23169eb1df75fa25191d98'
  UNION ALL
  SELECT m.id, l.id, '2026-09-22'::timestamp, 'diajukan', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Arif Setiawan","nim":"2241720024","prodi":"Jaringan Telekomunikasi Digital","jenjang":"D-IV","jurusan":"Teknik Elektro","angkatan":2022,"ipk":3.24}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2241720024' AND l.kode_pratinjau = 'ac52e602c385f9e45b7c7065f207659c'
  UNION ALL
  SELECT m.id, l.id, '2026-09-15'::timestamp, 'interview', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya tertarik karena posisi ini sesuai dengan tugas akhir saya.', '{"nama":"Mega Maharani","nim":"2241720025","prodi":"Teknik Kimia","jenjang":"D-III","jurusan":"Teknik Kimia","angkatan":2022,"ipk":3.42}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2241720025' AND l.kode_pratinjau = 'ee10d1437a04c9e38fe430838fe5e4b7'
  UNION ALL
  SELECT m.id, l.id, '2026-09-15'::timestamp, 'dibatalkan', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya pernah magang di bidang yang serupa selama enam bulan.', '{"nama":"Teguh Firdaus","nim":"2341720026","prodi":"Teknologi Kimia Industri","jenjang":"D-IV","jurusan":"Teknik Kimia","angkatan":2023,"ipk":3.75}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2341720026' AND l.kode_pratinjau = '0d3846637b494f42fd3886c110ac770d'
  UNION ALL
  SELECT m.id, l.id, '2026-09-24'::timestamp, 'interview', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Sari Oktaviani","nim":"2341720027","prodi":"Pengembangan Peranti Lunak Situs","jenjang":"D-II","jurusan":"Teknologi Informasi","angkatan":2023,"ipk":3.33}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2341720027' AND l.kode_pratinjau = '0d279688905792ff4c38be5134c4f881'
  UNION ALL
  SELECT m.id, l.id, '2026-09-01'::timestamp, 'diajukan', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya tertarik karena posisi ini sesuai dengan tugas akhir saya.', '{"nama":"Wahyu Nugroho","nim":"2341720028","prodi":"Teknik Informatika","jenjang":"D-IV","jurusan":"Teknologi Informasi","angkatan":2023,"ipk":3.55}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2341720028' AND l.kode_pratinjau = '7c9333b1286878b913541a754e2098fa'
  UNION ALL
  SELECT m.id, l.id, '2026-09-12'::timestamp, 'screening', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya tertarik karena posisi ini sesuai dengan tugas akhir saya.', '{"nama":"Putri Safitri","nim":"2441720029","prodi":"Sistem Informasi Bisnis","jenjang":"D-IV","jurusan":"Teknologi Informasi","angkatan":2024,"ipk":3.15}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2441720029' AND l.kode_pratinjau = '0d279688905792ff4c38be5134c4f881'
  UNION ALL
  SELECT m.id, l.id, '2026-09-02'::timestamp, 'diterima', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya pernah magang di bidang yang serupa selama enam bulan.', '{"nama":"Galih Hartono","nim":"2441720030","prodi":"Akuntansi","jenjang":"D-III","jurusan":"Akuntansi","angkatan":2024,"ipk":3.6}'::jsonb, 'Selamat, kamu diterima. Tim kami akan menghubungi untuk proses berikutnya.'
    FROM mahasiswa m, lowongan l WHERE m.nim = '2441720030' AND l.kode_pratinjau = '88afac51604a28babb6ba3f8d5596ddd'
  UNION ALL
  SELECT m.id, l.id, '2026-09-27'::timestamp, 'screening', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya pernah magang di bidang yang serupa selama enam bulan.', '{"nama":"Novi Andini","nim":"2341720031","prodi":"Akuntansi Manajemen","jenjang":"D-IV","jurusan":"Akuntansi","angkatan":2023,"ipk":3.44}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2341720031' AND l.kode_pratinjau = '88afac51604a28babb6ba3f8d5596ddd'
  UNION ALL
  SELECT m.id, l.id, '2026-09-19'::timestamp, 'ditolak', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Irfan Mahendra","nim":"2341720032","prodi":"Keuangan","jenjang":"D-IV","jurusan":"Akuntansi","angkatan":2023,"ipk":3.71}'::jsonb, 'Terima kasih sudah melamar. Kualifikasi belum sesuai kebutuhan posisi ini.'
    FROM mahasiswa m, lowongan l WHERE m.nim = '2341720032' AND l.kode_pratinjau = 'db17263bf41995a40498cc73db101a32'
  UNION ALL
  SELECT m.id, l.id, '2026-09-25'::timestamp, 'interview', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Diah Puspita","nim":"2341720033","prodi":"Administrasi Bisnis","jenjang":"D-III","jurusan":"Administrasi Niaga","angkatan":2023,"ipk":3.26}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2341720033' AND l.kode_pratinjau = '4d9ac3d2c55d7aaae4b983994e07fb5e'
  UNION ALL
  SELECT m.id, l.id, '2026-09-03'::timestamp, 'ditolak', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya tertarik karena posisi ini sesuai dengan tugas akhir saya.', '{"nama":"Bayu Gunawan","nim":"2241720034","prodi":"Manajemen Pemasaran Digital","jenjang":"D-IV","jurusan":"Administrasi Niaga","angkatan":2022,"ipk":3.25}'::jsonb, 'Terima kasih sudah melamar. Kualifikasi belum sesuai kebutuhan posisi ini.'
    FROM mahasiswa m, lowongan l WHERE m.nim = '2241720034' AND l.kode_pratinjau = '24ab048c4168688510e0a5d218dfd89d'
  UNION ALL
  SELECT m.id, l.id, '2026-09-27'::timestamp, 'diajukan', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Fitri Khoirunnisa","nim":"2241720035","prodi":"Pengelolaan Arsip dan Rekaman Informasi","jenjang":"D-IV","jurusan":"Administrasi Niaga","angkatan":2022,"ipk":3.21}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2241720035' AND l.kode_pratinjau = 'dafa250b19259d23e27fd2a0be3ba049'
  UNION ALL
  SELECT m.id, l.id, '2026-09-28'::timestamp, 'interview', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', NULL::varchar, '{"nama":"Reza Siregar","nim":"2241720036","prodi":"Bahasa Inggris untuk Komunikasi Bisnis dan Profesional","jenjang":"D-IV","jurusan":"Administrasi Niaga","angkatan":2022,"ipk":3.59}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2241720036' AND l.kode_pratinjau = 'dafa250b19259d23e27fd2a0be3ba049'
  UNION ALL
  SELECT m.id, l.id, '2026-09-20'::timestamp, 'interview', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya tertarik karena posisi ini sesuai dengan tugas akhir saya.', '{"nama":"Anisa Handayani","nim":"2441720037","prodi":"Teknik Sipil","jenjang":"D-III","jurusan":"Teknik Sipil","angkatan":2024,"ipk":3.5}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2441720037' AND l.kode_pratinjau = 'c4a2d4ce8dc6b6270876c772fdadef7f'
  UNION ALL
  SELECT m.id, l.id, '2026-09-08'::timestamp, 'screening', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Saya tertarik karena posisi ini sesuai dengan tugas akhir saya.', '{"nama":"Eko Purnomo","nim":"2041720038","prodi":"Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air","jenjang":"D-III","jurusan":"Teknik Sipil","angkatan":2020,"ipk":3.76}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '2041720038' AND l.kode_pratinjau = 'b8b3cc1dfd95dbd69cabfa4867fdbe4e'
  UNION ALL
  SELECT m.id, l.id, '2026-09-01'::timestamp, 'diajukan', 'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf',
         'contoh-surat-pengantar.pdf', 'Mohon dipertimbangkan, saya siap mulai setelah yudisium.', '{"nama":"Maya Wulandari","nim":"1941720039","prodi":"Teknologi Pertambangan","jenjang":"D-III","jurusan":"Teknik Sipil","angkatan":2019,"ipk":3.69}'::jsonb, NULL::varchar
    FROM mahasiswa m, lowongan l WHERE m.nim = '1941720039' AND l.kode_pratinjau = 'a2ba4c3d7671cdc6b595a1921165e453';

-- ----- Riwayat perubahan status lamaran ----------------------------------
INSERT INTO riwayat_lamaran (lamaran_id, status, catatan, diubah_oleh, tanggal)
  SELECT la.id, 'diajukan', 'Lamaran dikirim oleh pelamar.', m.pengguna_id, la.tanggal_lamar
    FROM lamaran la JOIN mahasiswa m ON m.id = la.mahasiswa_id;
INSERT INTO riwayat_lamaran (lamaran_id, status, catatan, diubah_oleh, tanggal)
  SELECT la.id, la.status, 'Status diperbarui oleh perusahaan.', pr.pengguna_id,
         la.tanggal_lamar + interval '3 days'
    FROM lamaran la JOIN lowongan lo ON lo.id = la.lowongan_id
         JOIN perusahaan pr ON pr.id = lo.perusahaan_id
   WHERE la.status <> 'diajukan';

-- ----- Jadwal interview --------------------------------------------------
INSERT INTO interview (lamaran_id, tanggal, jam, mode, lokasi_tautan, tempat, ruangan,
    dresscode, yang_dibawa, narahubung, catatan)
  SELECT la.id, '2026-10-19'::date, '11:00'::time, 'luring', 'Kantor Pusat, Jl. MH Thamrin 55', 'Kantor Pusat PT Pertamina Patra Niaga', 'Ruang Interview A', 'Kemeja putih, bawahan hitam, bersepatu formal', 'Kartu identitas, berkas CV cetak, transkrip nilai, dan pulpen', 'Nadia Rahmi (087454068093)', 'Mohon hadir 20 menit sebelum jadwal untuk registrasi.'
    FROM lamaran la JOIN mahasiswa m ON m.id = la.mahasiswa_id
         JOIN lowongan lo ON lo.id = la.lowongan_id
   WHERE m.nim = '2341720015' AND lo.kode_pratinjau = '0cc6f9d0c684490e1c0f03ebf12372fc'
  UNION ALL
  SELECT la.id, '2026-10-14'::date, '08:00'::time, 'daring', 'https://meet.google.com/hvy-dpa-ydu', NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, 'Pastikan kamera dan mikrofon aktif, siapkan jaringan yang stabil.'
    FROM lamaran la JOIN mahasiswa m ON m.id = la.mahasiswa_id
         JOIN lowongan lo ON lo.id = la.lowongan_id
   WHERE m.nim = '2241720025' AND lo.kode_pratinjau = 'ee10d1437a04c9e38fe430838fe5e4b7'
  UNION ALL
  SELECT la.id, '2026-10-14'::date, '11:00'::time, 'luring', 'Kantor Pusat, Jl. Veteran', 'Kantor Pusat PT Semen Indonesia', 'Ruang HRD Lantai 3', 'Kemeja putih, bawahan hitam, bersepatu formal', 'Kartu identitas, berkas CV cetak, transkrip nilai, dan pulpen', 'Dewi Kartika (089640401815)', 'Mohon hadir 20 menit sebelum jadwal untuk registrasi.'
    FROM lamaran la JOIN mahasiswa m ON m.id = la.mahasiswa_id
         JOIN lowongan lo ON lo.id = la.lowongan_id
   WHERE m.nim = '2341720027' AND lo.kode_pratinjau = '0d279688905792ff4c38be5134c4f881'
  UNION ALL
  SELECT la.id, '2026-10-20'::date, '11:00'::time, 'daring', 'https://meet.google.com/reh-frc-mrw', NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, 'Pastikan kamera dan mikrofon aktif, siapkan jaringan yang stabil.'
    FROM lamaran la JOIN mahasiswa m ON m.id = la.mahasiswa_id
         JOIN lowongan lo ON lo.id = la.lowongan_id
   WHERE m.nim = '2341720033' AND lo.kode_pratinjau = '4d9ac3d2c55d7aaae4b983994e07fb5e'
  UNION ALL
  SELECT la.id, '2026-10-23'::date, '08:00'::time, 'luring', 'Kantor Pusat, Jl. Soekarno Hatta 9', 'Kantor Pusat PT Nusantara Teknologi Cerdas', 'Ruang HRD Lantai 3', 'Kemeja putih, bawahan hitam, bersepatu formal', 'Kartu identitas, berkas CV cetak, transkrip nilai, dan pulpen', 'Fathur Rahman (081829102300)', 'Mohon hadir 20 menit sebelum jadwal untuk registrasi.'
    FROM lamaran la JOIN mahasiswa m ON m.id = la.mahasiswa_id
         JOIN lowongan lo ON lo.id = la.lowongan_id
   WHERE m.nim = '2241720036' AND lo.kode_pratinjau = 'dafa250b19259d23e27fd2a0be3ba049'
  UNION ALL
  SELECT la.id, '2026-10-23'::date, '08:00'::time, 'daring', 'https://meet.google.com/uhn-gmz-zvi', NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, NULL::varchar, 'Pastikan kamera dan mikrofon aktif, siapkan jaringan yang stabil.'
    FROM lamaran la JOIN mahasiswa m ON m.id = la.mahasiswa_id
         JOIN lowongan lo ON lo.id = la.lowongan_id
   WHERE m.nim = '2441720037' AND lo.kode_pratinjau = 'c4a2d4ce8dc6b6270876c772fdadef7f';

-- ----- Lowongan yang disimpan mahasiswa ----------------------------------
INSERT INTO lowongan_disimpan (mahasiswa_id, lowongan_id)
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2141720040' AND l.kode_pratinjau = '88afac51604a28babb6ba3f8d5596ddd'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2141720040' AND l.kode_pratinjau = '9c3abb9e6f7c6b9ce6972c2e1eb69e97'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2441720010' AND l.kode_pratinjau = '6cbd28f43e9817151c4d6bfdc432d149'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2441720010' AND l.kode_pratinjau = 'cb6b50bca7a25cc418da585aea98f568'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2041720050' AND l.kode_pratinjau = 'eb49b08c0d23169eb1df75fa25191d98'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2041720050' AND l.kode_pratinjau = '735cb15ef8cc9704fdf41f0187790dc3'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '1941720048' AND l.kode_pratinjau = '0d279688905792ff4c38be5134c4f881'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '1941720048' AND l.kode_pratinjau = 'f59e7d8f8d1ad5cfa78b3103ab3b99d8'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2341720026' AND l.kode_pratinjau = '0d279688905792ff4c38be5134c4f881'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2341720026' AND l.kode_pratinjau = '24ab048c4168688510e0a5d218dfd89d'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2441720019' AND l.kode_pratinjau = '717493520e6cae8b0f662111c949cbc2'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2441720019' AND l.kode_pratinjau = 'db17263bf41995a40498cc73db101a32'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2241720036' AND l.kode_pratinjau = '22c556a92b8eb1efcdba1877319fa3ea'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2241720036' AND l.kode_pratinjau = 'db17263bf41995a40498cc73db101a32'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2241720024' AND l.kode_pratinjau = 'a2ba4c3d7671cdc6b595a1921165e453'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2241720024' AND l.kode_pratinjau = '48c4b8b7c7ff48b5a0da8f7cb65ab7f8'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '1941720045' AND l.kode_pratinjau = '6f8193a326b5e4438a08c87795f57428'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '1941720045' AND l.kode_pratinjau = '21aff7f6d80ef487db6eeae8998f8583'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2341720015' AND l.kode_pratinjau = '7c9333b1286878b913541a754e2098fa'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2341720015' AND l.kode_pratinjau = '96e8f1e947ca10822b65fd8e2ebb5359'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2441720021' AND l.kode_pratinjau = 'f59e7d8f8d1ad5cfa78b3103ab3b99d8'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2441720021' AND l.kode_pratinjau = '24ab048c4168688510e0a5d218dfd89d'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2141720054' AND l.kode_pratinjau = '4d9ac3d2c55d7aaae4b983994e07fb5e'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2141720054' AND l.kode_pratinjau = 'dafa250b19259d23e27fd2a0be3ba049'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2241720035' AND l.kode_pratinjau = 'b8b3cc1dfd95dbd69cabfa4867fdbe4e'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2241720035' AND l.kode_pratinjau = '6f8193a326b5e4438a08c87795f57428'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2041720056' AND l.kode_pratinjau = 'db17263bf41995a40498cc73db101a32'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2041720056' AND l.kode_pratinjau = 'ac52e602c385f9e45b7c7065f207659c'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2241720025' AND l.kode_pratinjau = '22c556a92b8eb1efcdba1877319fa3ea'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2241720025' AND l.kode_pratinjau = '5552a2af1afe7db0bbb947277ddacd90'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2141720058' AND l.kode_pratinjau = '6b4246b55d73b196c6699ce77a52e723'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2141720058' AND l.kode_pratinjau = 'b6033c01fb7cb02c9e132ddbe484be16'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2141720051' AND l.kode_pratinjau = '3fb3ce5372194a44f47826693e07b51e'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2141720051' AND l.kode_pratinjau = '735cb15ef8cc9704fdf41f0187790dc3'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2241720020' AND l.kode_pratinjau = '6f8193a326b5e4438a08c87795f57428'
  UNION ALL
  SELECT m.id, l.id FROM mahasiswa m, lowongan l WHERE m.nim = '2241720020' AND l.kode_pratinjau = 'ee10d1437a04c9e38fe430838fe5e4b7'
  ON CONFLICT DO NOTHING;

-- ----- Hitung ulang kolom terisi -----------------------------------------
UPDATE lowongan l
   SET terisi = LEAST(l.kuota, (
         SELECT count(*) FROM lamaran la
          WHERE la.lowongan_id = l.id AND la.status = 'diterima'));

-- ===== ISI UNTUK TIGA AKUN DEMO ==========================================

-- ----- 1. Lowongan untuk perusahaan demo ---------------------------------
UPDATE lowongan SET perusahaan_id = (
         SELECT pr.id FROM perusahaan pr JOIN pengguna p ON p.id = pr.pengguna_id
          WHERE p.email = 'perusahaan@polinema.ac.id')
 WHERE id IN (
   SELECT l.id FROM lowongan l
     LEFT JOIN lamaran la ON la.lowongan_id = l.id
    WHERE l.status = 'aktif'
    GROUP BY l.id
    ORDER BY count(la.id) DESC, l.id
    LIMIT 5);

-- ----- 2. Lamaran untuk mahasiswa demo -----------------------------------
WITH budi AS (
  SELECT m.id FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
   WHERE p.email = 'mahasiswa@polinema.ac.id'
), sasaran AS (
  SELECT l.id,
         row_number() OVER (
           ORDER BY (pr.pengguna_id = (SELECT id FROM pengguna
                                        WHERE email = 'perusahaan@polinema.ac.id')) DESC,
                    l.id
         ) AS urut
    FROM lowongan l
    JOIN perusahaan pr ON pr.id = l.perusahaan_id
    JOIN lowongan_jurusan lj ON lj.lowongan_id = l.id
    JOIN jurusan j ON j.id = lj.jurusan_id
   WHERE l.status = 'aktif' AND j.nama = 'Teknologi Informasi'
     AND l.id NOT IN (SELECT lowongan_id FROM lamaran WHERE mahasiswa_id = (SELECT id FROM budi))
   ORDER BY 2
   LIMIT 4
)
INSERT INTO lamaran (mahasiswa_id, lowongan_id, tanggal_lamar, status, jenis_cv,
    file_cv, file_ktm, file_surat_pengantar, catatan_pelamar, snapshot_profil, catatan_perusahaan)
SELECT (SELECT id FROM budi), s.id,
       '2026-09-20'::date + (s.urut)::int,
       (ARRAY['diajukan','screening','interview','diterima'])[s.urut],
       'generate', 'cv-sistem.pdf', 'contoh-ktm.pdf', 'contoh-surat-pengantar.pdf',
       (ARRAY[
         'Saya tertarik karena posisi ini sejalan dengan proyek akhir saya.',
         'Saya sudah terbiasa memakai PHP dan PostgreSQL sejak semester tiga.',
         'Mohon dipertimbangkan, saya bisa mulai setelah semester ini selesai.',
         'Terima kasih atas kesempatannya.'])[s.urut],
       jsonb_build_object('nama','Budi Santoso','nim','2241720001',
         'prodi','Teknik Informatika','jenjang','D-IV',
         'jurusan','Teknologi Informasi','angkatan',2022,'ipk',3.61),
       CASE s.urut WHEN 4 THEN 'Selamat, kamu diterima. Tim kami akan menghubungi lewat WhatsApp.' END
  FROM sasaran s
 ON CONFLICT DO NOTHING;

-- ----- 3. Interview luring untuk mahasiswa demo --------------------------
INSERT INTO interview (lamaran_id, tanggal, jam, mode, lokasi_tautan, tempat, ruangan,
    dresscode, yang_dibawa, narahubung, catatan)
SELECT la.id, '2026-10-14'::date, '09:00'::time, 'luring',
       'Kantor Pusat PT Nusantara Digital, Jl. Soekarno Hatta 10, Malang',
       'Kantor Pusat PT Nusantara Digital',
       'Ruang Meeting 2, Lantai 3',
       'Kemeja putih lengan panjang, bawahan hitam, bersepatu formal',
       'Kartu identitas, CV cetak dua lembar, transkrip nilai, dan pulpen',
       'Hendra Wijaya (081298765432)',
       'Mohon hadir 20 menit lebih awal untuk registrasi di lobi.'
  FROM lamaran la
  JOIN mahasiswa m ON m.id = la.mahasiswa_id
  JOIN pengguna p ON p.id = m.pengguna_id
 WHERE p.email = 'mahasiswa@polinema.ac.id' AND la.status = 'interview'
 ON CONFLICT (lamaran_id) DO NOTHING;

-- ----- 4. Profil mahasiswa demo ------------------------------------------
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id)
  SELECT m.id, s.id FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id, skill s
   WHERE p.email = 'mahasiswa@polinema.ac.id'
     AND s.nama IN ('PHP','JavaScript','PostgreSQL','Git','Figma','Kerja sama tim')
 ON CONFLICT DO NOTHING;

INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id)
  SELECT m.id, b.id FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id, bidang b
   WHERE p.email = 'mahasiswa@polinema.ac.id'
     AND b.nama IN ('Teknologi Informasi','Perdagangan dan Jasa')
 ON CONFLICT DO NOTHING;

INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan)
  SELECT m.id, 'pendidikan', 'Teknik Komputer dan Jaringan', 'SMK Negeri 4 Malang',
         '2019-07-15'::date, '2022-06-10'::date, NULL, NULL
    FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
   WHERE p.email = 'mahasiswa@polinema.ac.id'
  UNION ALL
  SELECT m.id, 'pengalaman', 'Magang Web Developer', 'PT Sinergi Data Nusantara',
         '2025-01-13'::date, '2025-06-27'::date,
         'Membangun modul laporan pada aplikasi internal memakai PHP dan PostgreSQL.', NULL
    FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
   WHERE p.email = 'mahasiswa@polinema.ac.id'
  UNION ALL
  SELECT m.id, 'sertifikat', 'Junior Web Developer BNSP', 'Lembaga Sertifikasi Profesi',
         '2025-11-20'::date, NULL, NULL, NULL
    FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
   WHERE p.email = 'mahasiswa@polinema.ac.id'
  UNION ALL
  SELECT m.id, 'portofolio', 'Aplikasi Pencatat Keuangan Warung', NULL,
         NULL::date, NULL::date, 'Proyek mandiri berbasis web untuk mencatat penjualan harian.',
         'https://github.com'
    FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
   WHERE p.email = 'mahasiswa@polinema.ac.id';

UPDATE mahasiswa SET ipk = 3.61, domisili = 'Malang',
       tentang = 'Mahasiswa tingkat akhir D-IV Teknik Informatika, terbiasa mengerjakan aplikasi web dengan PHP dan PostgreSQL. Sedang mencari kesempatan magang atau kerja di bidang pengembangan perangkat lunak.',
       file_ktm = 'contoh-ktm.pdf', file_surat_pengantar = 'contoh-surat-pengantar.pdf',
       status_karier = 'mencari kerja', karier_bidang_minat = 'Teknologi Informasi',
       karier_rencana_posisi = 'Junior Web Developer',
       karier_catatan = 'Sedang mengikuti beberapa proses seleksi.',
       karier_diperbarui_pada = '2026-09-20'
 WHERE pengguna_id = (SELECT id FROM pengguna WHERE email = 'mahasiswa@polinema.ac.id');

-- ----- 5. Akun yang menunggu verifikasi ----------------------------------
INSERT INTO pengguna (email, password_hash, role, status_akun) VALUES
  ('calon.mahasiswa@student.polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu'),
  ('hrd@mitrasejahtera.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu'),
  ('hrd@karyaabadi.co.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'perbaikan');

INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp,
    status_mahasiswa, angkatan, ipk, domisili, file_ktm)
  SELECT p.id, ps.id, 'Nabila Ramadhani', '2341720099', '081355512345', 'aktif', 2023, 3.48, 'Blitar', 'contoh-ktm.pdf'
    FROM pengguna p, program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
   WHERE p.email = 'calon.mahasiswa@student.polinema.ac.id'
     AND ps.nama = 'Sistem Informasi Bisnis' AND j.nama = 'Teknologi Informasi';

INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan,
    alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
  SELECT id, 'PT Mitra Sejahtera Abadi', 'Perdagangan dan Jasa', 'Swasta nasional',
         'Jl. Raya Langsep 45', 'Malang', 'Dian Permana', 'HR Officer', '081377788899', true
    FROM pengguna WHERE email = 'hrd@mitrasejahtera.co.id'
  UNION ALL
  SELECT id, 'PT Karya Abadi Teknik', 'Manufaktur', 'Swasta nasional',
         'Jl. Industri Raya 7', 'Sidoarjo', 'Samsul Arifin', 'Manajer SDM', '081344455566', true
    FROM pengguna WHERE email = 'hrd@karyaabadi.co.id';

-- ----- Hitung ulang kolom terisi -----------------------------------------
UPDATE lowongan l
   SET terisi = LEAST(l.kuota, (
         SELECT count(*) FROM lamaran la
          WHERE la.lowongan_id = l.id AND la.status = 'diterima'));

-- ===== NOTIFIKASI ========================================================

-- ----- Untuk mahasiswa demo ----------------------------------------------
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

-- ----- Untuk perusahaan demo ---------------------------------------------
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

-- ----- Untuk admin -------------------------------------------------------
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

-- ===== BERKAS CONTOH PADA DATA UJI =======================================

-- ----- Foto profil dan logo ----------------------------------------------
UPDATE mahasiswa SET foto = 'contoh-foto.jpg' WHERE id % 3 = 0
    OR pengguna_id = (SELECT id FROM pengguna WHERE email = 'mahasiswa@polinema.ac.id');
UPDATE perusahaan SET logo = 'contoh-logo.jpg';

-- ----- Sertifikat dan portofolio -----------------------------------------
UPDATE profil_item SET file = 'contoh-sertifikat.pdf' WHERE tipe = 'sertifikat';
UPDATE profil_item SET file = 'contoh-portofolio.pdf' WHERE tipe = 'portofolio';

-- ----- KTM dan ijazah ----------------------------------------------------
UPDATE mahasiswa SET file_ktm = 'ktm-' || nim || '.pdf' WHERE status_mahasiswa = 'aktif';
UPDATE mahasiswa SET file_ktm = 'ijazah-' || nim || '.pdf' WHERE status_mahasiswa = 'alumni';
UPDATE mahasiswa SET file_surat_pengantar = 'surat-' || nim || '.pdf';

-- ----- Surat pengantar lamaran -------------------------------------------
UPDATE lamaran la SET file_surat_pengantar = m.file_surat_pengantar, file_ktm = m.file_ktm
  FROM mahasiswa m WHERE m.id = la.mahasiswa_id;

-- ----- Dokumen legalitas perusahaan --------------------------------------
INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb)
  SELECT pr.pengguna_id, t.tipe, t.tipe || '-pt' || pr.id || '.pdf', 2
    FROM perusahaan pr
    CROSS JOIN (VALUES ('nib'), ('npwp'), ('akta'), ('domisili')) AS t(tipe);

-- ----- Dokumen mahasiswa yang menunggu verifikasi ------------------------
INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb)
  SELECT m.pengguna_id, 'ktm', m.file_ktm, 2
    FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
   WHERE p.status_akun = 'menunggu';

$isi_seed$;
  RAISE NOTICE 'Data awal berhasil dimasukkan.';
END
$seed_karirku$;

-- #####################################################################
-- ##### Isi dari 03-migrasi-revisi.sql
-- #####################################################################
-- ===== Migrasi revisi KarirKu Polinema ===================================

DO $cek$
BEGIN
  IF to_regclass('public.lowongan') IS NULL THEN
    RAISE EXCEPTION 'Tabel belum ada. Jalankan 01-schema.sql dan 02-seed.sql dulu, atau cukup jalankan 00-INSTAL-ULANG.sql.';
  END IF;
END
$cek$;

-- ----- 1. Status karier yang menyesuaikan pilihan mahasiswa --------------
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

-- ----- 2. Detail interview luring ----------------------------------------
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

-- ----- 3. Daftar skill awal ----------------------------------------------
INSERT INTO skill (nama) VALUES
  ('HTML'), ('CSS'), ('JavaScript'), ('PHP'), ('Laravel'), ('CodeIgniter'),
  ('PostgreSQL'), ('MySQL'), ('Git'), ('Figma'), ('UI/UX Design'),
  ('Python'), ('Java'), ('Microsoft Excel'), ('AutoCAD'), ('SolidWorks'),
  ('Komunikasi'), ('Kerja sama tim'), ('Manajemen waktu'), ('Bahasa Inggris')
ON CONFLICT (nama) DO NOTHING;

-- ----- 4. Jenjang S2 Terapan ---------------------------------------------
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

-- ----- 5. Nama program studi dibersihkan dari awalan jenjang -------------
UPDATE program_studi
   SET nama = btrim(regexp_replace(nama, '^(D-?I{1,3}V?|D[234]|S[123])\s+', ''))
 WHERE nama ~ '^(D-?I{1,3}V?|D[234]|S[123])\s';

-- ----- 6. Kunci unik program studi per jenjang ---------------------------
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

-- ===== 7. JURUSAN DAN PROGRAM STUDI RESMI POLINEMA =======================

-- ----- Tabel sementara daftar resmi --------------------------------------
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

-- ----- 7a. Jurusan yang belum ada ditambahkan ----------------------------
INSERT INTO jurusan (nama)
  SELECT DISTINCT jurusan FROM prodi_resmi
 ON CONFLICT (nama) DO NOTHING;

-- ----- 7b. Program studi resmi ditambahkan -------------------------------
INSERT INTO program_studi (jurusan_id, nama, jenjang)
  SELECT j.id, pr.nama, pr.jenjang
    FROM prodi_resmi pr JOIN jurusan j ON j.nama = pr.jurusan
 ON CONFLICT DO NOTHING;

-- ----- 7c. Pindahkan mahasiswa ke prodi resmi ----------------------------
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

-- ----- 7d. Hapus prodi di luar daftar resmi ------------------------------
DELETE FROM program_studi ps
 USING jurusan j
 WHERE j.id = ps.jurusan_id
   AND NOT EXISTS (
         SELECT 1 FROM prodi_resmi pr
          WHERE pr.jurusan = j.nama AND pr.nama = ps.nama AND pr.jenjang = ps.jenjang
       )
   AND NOT EXISTS (SELECT 1 FROM mahasiswa m WHERE m.program_studi_id = ps.id);

DROP TABLE prodi_resmi;

-- ===== 8. ISI NOTIFIKASI UNTUK TIGA AKUN DEMO ============================
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

-- ===== 9. BERKAS CONTOH UNTUK DATABASE YANG SUDAH ADA ====================

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

-- ----- Dokumen legalitas perusahaan --------------------------------------
INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb)
  SELECT pr.pengguna_id, t.tipe, 'contoh-' || t.tipe || '.pdf', 2
    FROM perusahaan pr
    CROSS JOIN (VALUES ('nib'), ('npwp'), ('akta'), ('domisili')) AS t(tipe)
   WHERE NOT EXISTS (
     SELECT 1 FROM dokumen_verifikasi dv
      WHERE dv.pengguna_id = pr.pengguna_id AND dv.tipe = t.tipe
   );

-- #####################################################################
-- ##### Isi dari 04-revisi-dosen.sql
-- #####################################################################
-- =====================================================================
-- KarirKu Polinema · Migrasi revisi dosen (Oktober 2026)
-- Jalankan SETELAH 01-schema.sql, 02-seed.sql, dan 03-migrasi-revisi.sql.
-- Aman dijalankan berulang kali (IF NOT EXISTS / DROP CONSTRAINT IF EXISTS).
-- Semua perubahan bersifat MENAMBAH: tidak ada tabel atau kolom lama yang
-- dihapus atau diganti nama, sehingga data lama tetap utuh.
-- =====================================================================

DO $cek$
BEGIN
  IF to_regclass('public.lowongan') IS NULL THEN
    RAISE EXCEPTION 'Tabel belum ada. Jalankan 01-schema.sql dan 02-seed.sql dulu, atau cukup jalankan 00-INSTAL-ULANG.sql.';
  END IF;
END
$cek$;

BEGIN;

-- ----- M. Persetujuan lowongan oleh Admin -----------------------------
-- Status baru: menunggu (belum ditinjau), revisi (diminta perbaikan),
-- ditolak (final). Lowongan lama yang sudah tayang tetap 'aktif'.
ALTER TABLE lowongan DROP CONSTRAINT IF EXISTS lowongan_status_check;
ALTER TABLE lowongan ADD CONSTRAINT lowongan_status_check
  CHECK (status IN ('menunggu','revisi','ditolak','aktif','ditutup','nonaktif'));
ALTER TABLE lowongan ALTER COLUMN status SET DEFAULT 'menunggu';
ALTER TABLE lowongan ADD COLUMN IF NOT EXISTS catatan_admin   varchar(500);
ALTER TABLE lowongan ADD COLUMN IF NOT EXISTS disetujui_pada  timestamp;
ALTER TABLE lowongan ADD COLUMN IF NOT EXISTS disetujui_oleh  integer REFERENCES admin(id) ON DELETE SET NULL;
ALTER TABLE lowongan ADD COLUMN IF NOT EXISTS diajukan_pada   timestamp NOT NULL DEFAULT now();
COMMENT ON COLUMN lowongan.catatan_admin IS 'Alasan minta revisi atau tolak dari Admin (terakhir)';

-- Lowongan lama yang sudah tayang dianggap sudah disetujui.
UPDATE lowongan SET disetujui_pada = COALESCE(disetujui_pada, dibuat_pada)
 WHERE status IN ('aktif','ditutup','nonaktif') AND disetujui_pada IS NULL;

-- Riwayat status lowongan: siapa, kapan, aksi apa, alasan apa.
CREATE TABLE IF NOT EXISTS riwayat_lowongan (
  id           serial PRIMARY KEY,
  lowongan_id  integer NOT NULL REFERENCES lowongan(id) ON DELETE CASCADE,
  status       varchar(20) NOT NULL,
  aksi         varchar(30) NOT NULL,
  catatan      varchar(500),
  oleh         integer REFERENCES pengguna(id) ON DELETE SET NULL,
  tanggal      timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_riwayat_lowongan ON riwayat_lowongan (lowongan_id, tanggal);

-- ----- B. Log email ---------------------------------------------------
CREATE TABLE IF NOT EXISTS log_email (
  id             serial PRIMARY KEY,
  tujuan         varchar(255) NOT NULL,
  subjek         varchar(255) NOT NULL,
  jenis          varchar(40)  NOT NULL,
  isi_html       text,                       -- NULL untuk email rahasia (reset sandi)
  status         varchar(20)  NOT NULL CHECK (status IN ('terkirim','gagal','log')),
  keterangan     varchar(500),
  percobaan      integer NOT NULL DEFAULT 1,
  dibuat_pada    timestamp NOT NULL DEFAULT now(),
  diperbarui_pada timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_log_email_waktu ON log_email (dibuat_pada DESC);

-- ----- J & L. Sesi, "Ingat saya", reset sandi oleh Admin --------------
ALTER TABLE pengguna ADD COLUMN IF NOT EXISTS versi_sesi        integer NOT NULL DEFAULT 1;
ALTER TABLE pengguna ADD COLUMN IF NOT EXISTS wajib_ganti_sandi boolean NOT NULL DEFAULT false;
COMMENT ON COLUMN pengguna.versi_sesi IS 'Dinaikkan saat sandi diganti/akun dinonaktifkan: semua sesi lama otomatis keluar';

CREATE TABLE IF NOT EXISTS token_ingat (
  id             serial PRIMARY KEY,
  pengguna_id    integer NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
  selector       varchar(32) NOT NULL UNIQUE,
  validator_hash varchar(64) NOT NULL,
  kedaluwarsa    timestamp NOT NULL,
  dibuat_pada    timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_token_ingat_pengguna ON token_ingat (pengguna_id);

CREATE TABLE IF NOT EXISTS log_aktivitas_admin (
  id                 serial PRIMARY KEY,
  admin_id           integer REFERENCES admin(id) ON DELETE SET NULL,
  aksi               varchar(50) NOT NULL,
  target_pengguna_id integer REFERENCES pengguna(id) ON DELETE SET NULL,
  keterangan         varchar(500),
  alamat_ip          varchar(45),
  tanggal            timestamp NOT NULL DEFAULT now()
);

-- ----- F. Alamat ------------------------------------------------------
ALTER TABLE mahasiswa  ADD COLUMN IF NOT EXISTS alamat   varchar(255);
ALTER TABLE mahasiswa  ADD COLUMN IF NOT EXISTS provinsi varchar(60);
ALTER TABLE mahasiswa  ADD COLUMN IF NOT EXISTS kode_pos varchar(5);
ALTER TABLE perusahaan ADD COLUMN IF NOT EXISTS provinsi varchar(60);
ALTER TABLE perusahaan ADD COLUMN IF NOT EXISTS kode_pos varchar(5);
COMMENT ON COLUMN mahasiswa.domisili IS 'Kota/kabupaten domisili (dipakai juga sebagai kota pada alamat)';

-- ----- K. Template alasan penolakan (bisa diubah di Pengaturan) -------
INSERT INTO pengaturan (kunci, nilai) VALUES
 ('daftar_alasan_penolakan',
  'Dokumen KTM/ijazah tidak terbaca, mohon unggah ulang dengan foto yang jelas.
NIM tidak sesuai dengan dokumen yang diunggah.
Dokumen legalitas (NIB/NPWP/akta) tidak lengkap atau sudah tidak berlaku.
Nama perusahaan berbeda dengan nama pada dokumen legalitas.
Perusahaan terindikasi outsourcing atau penyalur tenaga kerja.'),
 ('daftar_alasan_lowongan',
  'Pamflet tidak terbaca atau tidak sesuai dengan isi lowongan.
Deskripsi pekerjaan terlalu singkat, mohon jelaskan tanggung jawab utama.
Kualifikasi belum dicantumkan dengan jelas.
Gaji atau sistem kerja perlu diperjelas.
Lowongan terindikasi meminta biaya kepada pelamar.')
ON CONFLICT (kunci) DO NOTHING;

-- ----- Data demo: dua lowongan menunggu persetujuan --------------------
-- Supaya halaman Persetujuan Lowongan tidak kosong saat demo.
UPDATE lowongan SET status = 'menunggu', disetujui_pada = NULL, diajukan_pada = now() - interval '1 day'
 WHERE id IN (SELECT id FROM lowongan WHERE status = 'aktif' ORDER BY id DESC LIMIT 2)
   AND NOT EXISTS (SELECT 1 FROM lowongan WHERE status = 'menunggu')
   AND NOT EXISTS (SELECT 1 FROM riwayat_lowongan);

INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
SELECT l.id, 'aktif', 'disetujui', 'Data awal: lowongan sudah tayang sebelum fitur persetujuan.', NULL, l.disetujui_pada
  FROM lowongan l
 WHERE l.disetujui_pada IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM riwayat_lowongan r WHERE r.lowongan_id = l.id);

INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
SELECT l.id, 'menunggu', 'diajukan', 'Lowongan diajukan dan menunggu persetujuan Admin.', pr.pengguna_id, l.diajukan_pada
  FROM lowongan l JOIN perusahaan pr ON pr.id = l.perusahaan_id
 WHERE l.status = 'menunggu'
   AND NOT EXISTS (SELECT 1 FROM riwayat_lowongan r WHERE r.lowongan_id = l.id);

COMMIT;

-- #####################################################################
-- ##### Isi dari 06-revisi-profil.sql
-- #####################################################################
-- =====================================================================
-- KarirKu Polinema · Revisi profil (Oktober 2026, tahap 2)
--  - Pendidikan, pengalaman, dan sertifikat menyimpan data lengkap yang
--    dibutuhkan perusahaan (jenjang, NIM, nomor ijazah, jenis pekerjaan,
--    nomor kredensial, dll.) di kolom detail (JSONB).
--  - Profil Admin: foto, jabatan, dan nomor WhatsApp.
-- Jalankan SETELAH 01-04. Aman dijalankan berulang kali.
-- =====================================================================
DO $cek$
BEGIN
  IF to_regclass('public.profil_item') IS NULL THEN
    RAISE EXCEPTION 'Tabel belum ada. Jalankan 01-04 dulu, atau cukup jalankan 00-INSTAL-ULANG.sql.';
  END IF;
END
$cek$;

ALTER TABLE profil_item ADD COLUMN IF NOT EXISTS detail jsonb NOT NULL DEFAULT '{}'::jsonb;
CREATE INDEX IF NOT EXISTS idx_profil_item_file2 ON profil_item ((detail->>'file2'));

ALTER TABLE admin ADD COLUMN IF NOT EXISTS foto        varchar(255);
ALTER TABLE admin ADD COLUMN IF NOT EXISTS jabatan     varchar(150);
ALTER TABLE admin ADD COLUMN IF NOT EXISTS no_whatsapp varchar(30);
UPDATE admin SET jabatan = 'Admin Career Center' WHERE jabatan IS NULL;

-- ---------------------------------------------------------------------
-- Lengkapi detail item profil data contoh yang masih kosong (revisi tahap 2)
-- ---------------------------------------------------------------------
-- (kolom dibuat di sini juga, jadi aman bila 05 dijalankan sebelum 06)
ALTER TABLE profil_item ADD COLUMN IF NOT EXISTS detail jsonb NOT NULL DEFAULT '{}'::jsonb;
UPDATE profil_item pi SET detail = jsonb_strip_nulls(jsonb_build_object(
    'jenjang', CASE ps.jenjang WHEN 'D-II' THEN 'D2' WHEN 'D-III' THEN 'D3' WHEN 'D-IV' THEN 'D4 / Sarjana Terapan' ELSE 'S2 Terapan' END,
    'fakultas', j.nama, 'nomor_induk', m.nim, 'kota', 'Malang',
    'nilai', replace(to_char(3.20 + (pi.id % 7) * 0.1, 'FM0.00'), '.', ','), 'skala', '4,00',
    'akreditasi', CASE WHEN pi.id % 3 = 0 THEN 'A' ELSE 'Unggul' END))
  FROM mahasiswa m JOIN program_studi ps ON ps.id = m.program_studi_id JOIN jurusan j ON j.id = ps.jurusan_id
 WHERE pi.mahasiswa_id = m.id AND pi.tipe = 'pendidikan' AND pi.detail = '{}'::jsonb AND pi.instansi ILIKE '%Politeknik Negeri Malang%';

UPDATE profil_item pi SET detail = jsonb_build_object(
    'jenjang', CASE WHEN pi.instansi ILIKE '%SMK%' THEN 'SMK' WHEN pi.instansi ILIKE '%MA %' OR pi.instansi ILIKE 'MAN%' THEN 'MA' ELSE 'SMA' END,
    'nomor_induk', '00' || (5000000 + pi.id * 37)::text,
    'kota', COALESCE(NULLIF(regexp_replace(pi.instansi, '^.*\s', ''), ''), 'Malang'),
    'nilai', (82 + pi.id % 13)::text || ',' || (pi.id % 10)::text, 'skala', '100',
    'nomor_ijazah', 'DN-05/' || CASE WHEN pi.instansi ILIKE '%SMK%' THEN 'M-SMK' ELSE 'M-SMA' END || '/K13/' || lpad((pi.id * 131 % 99999)::text, 5, '0'),
    'akreditasi', 'A')
 WHERE pi.tipe = 'pendidikan' AND pi.detail = '{}'::jsonb;

UPDATE profil_item pi SET detail = jsonb_build_object(
    'jenis', CASE WHEN pi.judul ILIKE '%magang%' OR pi.judul ILIKE '%intern%' OR pi.judul ILIKE '%PKL%' THEN 'Magang / PKL'
                  WHEN pi.judul ILIKE '%asisten%' OR pi.judul ILIKE '%ketua%' OR pi.judul ILIKE '%anggota%' OR pi.judul ILIKE '%pengurus%' THEN 'Organisasi'
                  WHEN pi.judul ILIKE '%panitia%' OR pi.judul ILIKE '%koordinator%' THEN 'Kepanitiaan'
                  WHEN pi.judul ILIKE '%freelance%' THEN 'Freelance'
                  ELSE (ARRAY['Magang / PKL','Proyek','Kerja paruh waktu'])[1 + pi.id % 3] END,
    'bidang', (ARRAY['Teknologi Informasi','Operasional','Administrasi','Produksi','Pemasaran'])[1 + pi.id % 5],
    'lokasi', CASE WHEN pi.instansi ILIKE '%Polinema%' OR pi.instansi ILIKE '%Politeknik Negeri Malang%' THEN 'Malang' ELSE (ARRAY['Malang','Surabaya','Sidoarjo','Pasuruan','Jakarta'])[1 + pi.id % 5] END,
    'sistem', (ARRAY['Di kantor (WFO)','Hybrid','Di kantor (WFO)','Jarak jauh (WFH)'])[1 + pi.id % 4],
    'pencapaian', (ARRAY['Menyelesaikan seluruh target tugas tepat waktu dan mendapat nilai sangat baik dari pembimbing.',
                         'Membantu mempercepat penyusunan laporan bulanan sekitar 30%.',
                         'Mendampingi lebih dari 40 peserta dan menyusun modul pendukung.',
                         'Menyelesaikan 10+ fitur/pekerjaan yang dipakai tim setiap hari.'])[1 + pi.id % 4],
    'tools', (ARRAY['PHP, PostgreSQL, Git','Microsoft Excel, Google Sheets','Figma, Canva','AutoCAD, Microsoft Office','Python, Power BI'])[1 + pi.id % 5],
    'referensi_nama', (ARRAY['Hendra Wijaya (Supervisor)','Rina Kartika (HR)','Dr. Agus Salim (Pembimbing)','Dewi Lestari (Manajer)'])[1 + pi.id % 4])
 WHERE pi.tipe = 'pengalaman' AND pi.detail = '{}'::jsonb;

UPDATE profil_item pi SET detail = jsonb_build_object(
    'jenis', CASE WHEN pi.judul ILIKE '%BNSP%' OR pi.instansi ILIKE '%LSP%' OR pi.instansi ILIKE '%Sertifikasi Profesi%' THEN 'Sertifikasi kompetensi (BNSP/LSP)'
                  WHEN pi.judul ILIKE '%TOEFL%' OR pi.judul ILIKE '%TOEIC%' OR pi.judul ILIKE '%IELTS%' OR pi.judul ILIKE '%bahasa%' OR pi.judul ILIKE '%English%' THEN 'Kemampuan bahasa'
                  WHEN pi.judul ILIKE '%juara%' OR pi.judul ILIKE '%lomba%' THEN 'Lomba / penghargaan'
                  WHEN pi.judul ILIKE '%seminar%' OR pi.judul ILIKE '%workshop%' THEN 'Seminar / workshop'
                  WHEN pi.instansi ILIKE '%Cisco%' OR pi.instansi ILIKE '%Google%' OR pi.instansi ILIKE '%Microsoft%' OR pi.instansi ILIKE '%AWS%' OR pi.instansi ILIKE '%Oracle%' THEN 'Sertifikasi profesional / internasional'
                  ELSE 'Pelatihan / kursus' END,
    'nomor', upper(substr(md5(pi.id::text || pi.judul), 1, 4)) || '-' || to_char(COALESCE(pi.mulai, DATE '2025-01-01'), 'YYYY') || '-' || lpad((pi.id * 97 % 100000)::text, 5, '0'),
    'skor', CASE WHEN pi.judul ILIKE '%TOEFL%' THEN (480 + pi.id % 90)::text WHEN pi.judul ILIKE '%TOEIC%' THEN (650 + pi.id % 250)::text ELSE 'Kompeten' END)
 WHERE pi.tipe = 'sertifikat' AND pi.detail = '{}'::jsonb;

-- #####################################################################
-- ##### Isi dari 05-data-dummy.sql
-- #####################################################################
-- =====================================================================
-- KarirKu Polinema · DATA DUMMY tambahan (lowongan banyak + pamflet + logo)
-- Dibuat oleh tests/buat-data-dummy.py. Gambar ada di storage/uploads/pamflet
-- (dummy-*.jpg), storage/uploads/logo (dummy-emblem-*.png), storage/uploads/foto (dummy-foto-*.png).
-- AMAN DIJALANKAN BERULANG: lowongan dummy hanya ditambahkan sekali.
-- Jalankan SETELAH 01-04 (sudah termasuk di 00-INSTAL-ULANG.sql).
-- =====================================================================
DO $cek$
BEGIN
  IF to_regclass('public.riwayat_lowongan') IS NULL THEN
    RAISE EXCEPTION 'Jalankan 01-schema, 02-seed, 03 dan 04 dulu (atau cukup 00-INSTAL-ULANG.sql).';
  END IF;
END
$cek$;

BEGIN;

UPDATE perusahaan SET logo = 'dummy-emblem-01.png' WHERE nama_perusahaan = 'PT Nusantara Digital' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-02.png' WHERE nama_perusahaan = 'PT Astra Otoparts' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-03.png' WHERE nama_perusahaan = 'PT Telkom Indonesia' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-04.png' WHERE nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-05.png' WHERE nama_perusahaan = 'PT Gudang Garam Tbk' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-06.png' WHERE nama_perusahaan = 'PT Pindad' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-07.png' WHERE nama_perusahaan = 'PT Semen Indonesia' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-08.png' WHERE nama_perusahaan = 'PT Bank Mandiri Tbk' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-09.png' WHERE nama_perusahaan = 'PT Pertamina Patra Niaga' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-10.png' WHERE nama_perusahaan = 'PT Nestle Indonesia' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-11.png' WHERE nama_perusahaan = 'PT Barata Indonesia' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-12.png' WHERE nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-13.png' WHERE nama_perusahaan = 'PT Adhi Karya Tbk' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-14.png' WHERE nama_perusahaan = 'PT Sinergi Data Nusantara' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-15.png' WHERE nama_perusahaan = 'PT Mitra Arsip Nusantara' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-16.png' WHERE nama_perusahaan = 'PT Energi Listrik Mandiri' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-17.png' WHERE nama_perusahaan = 'PT Mitra Sejahtera Abadi' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'dummy-emblem-18.png' WHERE nama_perusahaan = 'PT Karya Abadi Teknik' AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');

DO $dummy$
BEGIN
  IF EXISTS (SELECT 1 FROM lowongan WHERE pamflet LIKE 'dummy-%') THEN
    RAISE NOTICE 'Lowongan dummy sudah ada, dilewati.';
    RETURN;
  END IF;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Rekam Arsip Digital', 'full_time', 'wfo', 'Malang', 'Rp4,5-12 juta', 1, 0,
      '2026-12-25', 'Memindai dan mengindeks dokumen klien ke sistem arsip digital. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Pengarsipan digital
- IPK minimal 3,00
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Pengarsipan digital, Ketelitian', 'dummy-dba1ff1019686d7e786c.jpg', 'dba1ff1019686d7e786cee3262683b12', 'aktif',
      '2026-10-18'::timestamp + time '09:00', '2026-10-18'::timestamp + time '09:00', '2026-10-18'::timestamp + time '09:00',
      '2026-10-18'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Digital' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'dba1ff1019686d7e786cee3262683b12' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'dba1ff1019686d7e786cee3262683b12' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Sales Executive', 'magang', 'wfo', 'Malang', 'Uang saku Rp1.500.000', 8, 0,
      '2027-01-03', 'Mencari pelanggan baru dan menjaga hubungan baik dengan pelanggan lama. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Negosiasi
- Memiliki laptop pribadi
- IPK minimal 3,00
- Bersedia bekerja shift', 'Negosiasi, Komunikasi, Presentasi', 'dummy-9f9cba747e23eabcd185.jpg', '9f9cba747e23eabcd185dc57b6aa2c36', 'aktif',
      '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00',
      '2026-10-21'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Digital' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '9f9cba747e23eabcd185dc57b6aa2c36' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '9f9cba747e23eabcd185dc57b6aa2c36' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Backend Developer', 'full_time', 'wfh', 'Malang', 'Rp4,5-12 juta', 2, 0,
      '2027-02-15', 'Merancang API dan basis data yang andal, aman, dan siap menangani banyak pengguna. Penempatan di Malang.', '- Fresh graduate dipersilakan melamar
- Menguasai Node.js
- Komunikatif dan teliti
- Bersedia bekerja shift
- IPK minimal 3,00', 'Node.js, PHP, PostgreSQL, Docker', 'dummy-20c9e7066c918299eb31.jpg', '20c9e7066c918299eb317936c421239b', 'aktif',
      '2026-10-24'::timestamp + time '09:00', '2026-10-24'::timestamp + time '09:00', '2026-10-24'::timestamp + time '09:00',
      '2026-10-24'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Digital' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '20c9e7066c918299eb317936c421239b' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '20c9e7066c918299eb317936c421239b' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Frontend Developer', 'magang', 'hybrid', 'Malang', 'Uang saku Rp1.500.000', 2, 0,
      '2026-12-21', 'Mengubah desain menjadi antarmuka web yang cepat, responsif, dan mudah diakses. Penempatan di Malang.', '- Fresh graduate dipersilakan melamar
- Menguasai HTML
- Memiliki laptop pribadi
- Komunikatif dan teliti
- Mampu bekerja dalam tim', 'HTML, CSS, JavaScript, React', 'dummy-6c858fba9b777f372ee3.jpg', '6c858fba9b777f372ee3f7d349980ebe', 'aktif',
      '2026-10-15'::timestamp + time '09:00', '2026-10-15'::timestamp + time '09:00', '2026-10-15'::timestamp + time '09:00',
      '2026-10-15'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Digital' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '6c858fba9b777f372ee3f7d349980ebe' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '6c858fba9b777f372ee3f7d349980ebe' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Staf Administrasi', 'magang', 'wfo', 'Malang', '', 5, 0,
      '2026-12-01', 'Mengelola surat-menyurat, arsip, dan administrasi operasional kantor. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Microsoft Office
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)
- Bersedia bekerja shift', 'Microsoft Office, Kearsipan', 'dummy-f187f9965ad5541d6413.jpg', 'f187f9965ad5541d641334c81148905f', 'aktif',
      '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00',
      '2026-10-19'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Digital' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'f187f9965ad5541d641334c81148905f' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'f187f9965ad5541d641334c81148905f' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf K3', 'full_time', 'wfo', 'Jakarta', 'Rp6-7 juta', 8, 0,
      '2026-12-11', 'Mengawasi penerapan keselamatan dan kesehatan kerja di area pabrik. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai K3
- Komunikatif dan teliti
- Berpengalaman magang di bidang terkait (nilai tambah)
- Memiliki laptop pribadi', 'K3, ISO 45001, Investigasi kecelakaan', 'dummy-f93f149a8e754ece83ac.jpg', 'f93f149a8e754ece83ac4322771735e0', 'aktif',
      '2026-10-13'::timestamp + time '09:00', '2026-10-13'::timestamp + time '09:00', '2026-10-13'::timestamp + time '09:00',
      '2026-10-13'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Astra Otoparts' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'f93f149a8e754ece83ac4322771735e0' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'f93f149a8e754ece83ac4322771735e0' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Teknisi Maintenance Mesin', 'full_time', 'wfo', 'Jakarta', 'Rp6-8 juta', 3, 0,
      '2026-11-24', 'Melakukan perawatan preventif dan perbaikan mesin produksi agar tidak berhenti. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai Mekanik
- Memiliki laptop pribadi
- Mampu bekerja dalam tim
- Bersedia bekerja shift', 'Mekanik, Pneumatik, Hidrolik', 'dummy-2e3c1e8e8311d4a9fc61.jpg', '2e3c1e8e8311d4a9fc613efe173dbce7', 'aktif',
      '2026-10-10'::timestamp + time '09:00', '2026-10-10'::timestamp + time '09:00', '2026-10-10'::timestamp + time '09:00',
      '2026-10-10'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Astra Otoparts' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '2e3c1e8e8311d4a9fc613efe173dbce7' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '2e3c1e8e8311d4a9fc613efe173dbce7' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Supervisor Produksi', 'full_time', 'wfo', 'Jakarta', 'Rp5-10 juta', 8, 0,
      '2027-01-22', 'Memimpin tim lini produksi agar target kuantitas, mutu, dan keselamatan tercapai. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai Kepemimpinan
- Memiliki laptop pribadi
- IPK minimal 3,00
- Komunikatif dan teliti', 'Kepemimpinan, Lean manufacturing, K3', 'dummy-bafc15f989f1dbf03024.jpg', 'bafc15f989f1dbf0302404e5d261903c', 'aktif',
      '2026-10-16'::timestamp + time '09:00', '2026-10-16'::timestamp + time '09:00', '2026-10-16'::timestamp + time '09:00',
      '2026-10-16'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Astra Otoparts' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'bafc15f989f1dbf0302404e5d261903c' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'bafc15f989f1dbf0302404e5d261903c' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Account Officer UMKM', 'full_time', 'wfo', 'Surabaya', 'Rp5,5-8 juta', 10, 0,
      '2026-12-13', 'Menganalisis pengajuan kredit usaha mikro dan kecil serta membina debitur. Penempatan di Surabaya.', '- Fresh graduate dipersilakan melamar
- Menguasai Analisis kredit
- IPK minimal 3,00
- Memiliki laptop pribadi
- Komunikatif dan teliti', 'Analisis kredit, Komunikasi', 'dummy-c2a7f3d1b5685d943860.jpg', 'c2a7f3d1b5685d943860e5e34c9cf6b3', 'aktif',
      '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00',
      '2026-10-27'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Astra Otoparts' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'c2a7f3d1b5685d943860e5e34c9cf6b3' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'c2a7f3d1b5685d943860e5e34c9cf6b3' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Customer Service Officer', 'full_time', 'wfo', 'Jakarta', 'Rp8-12 juta', 2, 0,
      '2027-01-02', 'Melayani nasabah di kantor cabang secara ramah, cepat, dan tepat. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Komunikasi
- Mampu bekerja dalam tim
- Memiliki laptop pribadi
- Bersedia bekerja shift', 'Komunikasi, Pelayanan nasabah', 'dummy-71ed8738cf56b80eb555.jpg', '71ed8738cf56b80eb555394ee30d9b74', 'aktif',
      '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00',
      '2026-10-27'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Astra Otoparts' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '71ed8738cf56b80eb555394ee30d9b74' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '71ed8738cf56b80eb555394ee30d9b74' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Pajak', 'full_time', 'wfo', 'Jakarta', 'Rp6-12 juta', 8, 0,
      '2026-12-18', 'Menghitung, melaporkan, dan mengarsipkan kewajiban pajak perusahaan. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai PPh
- Mampu bekerja dalam tim
- Bersedia bekerja shift
- IPK minimal 3,00', 'PPh, PPN, e-Faktur', 'dummy-6fad22f6dbfd9633601f.jpg', '6fad22f6dbfd9633601f56d13ed39a4b', 'aktif',
      '2026-10-25'::timestamp + time '09:00', '2026-10-25'::timestamp + time '09:00', '2026-10-25'::timestamp + time '09:00',
      '2026-10-25'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Astra Otoparts' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '6fad22f6dbfd9633601f56d13ed39a4b' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '6fad22f6dbfd9633601f56d13ed39a4b' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Staf Akuntansi', 'magang', 'wfo', 'Jakarta', 'Uang saku Rp1.500.000', 4, 0,
      '2027-01-31', 'Mencatat transaksi, menyusun jurnal, dan membantu laporan keuangan bulanan. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Akuntansi keuangan
- Komunikatif dan teliti
- Memiliki laptop pribadi
- Bersedia bekerja shift', 'Akuntansi keuangan, Microsoft Excel, Accurate', 'dummy-cd46baccdd80f938d24b.jpg', 'cd46baccdd80f938d24b348ce169d415', 'aktif',
      '2026-10-22'::timestamp + time '09:00', '2026-10-22'::timestamp + time '09:00', '2026-10-22'::timestamp + time '09:00',
      '2026-10-22'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Astra Otoparts' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'cd46baccdd80f938d24b348ce169d415' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'cd46baccdd80f938d24b348ce169d415' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Administrasi', 'full_time', 'wfo', 'Bandung', 'Rp7-8 juta', 2, 0,
      '2027-02-15', 'Mengelola surat-menyurat, arsip, dan administrasi operasional kantor. Penempatan di Bandung.', '- Fresh graduate dipersilakan melamar
- Menguasai Microsoft Office
- Berpengalaman magang di bidang terkait (nilai tambah)
- Komunikatif dan teliti
- IPK minimal 3,00', 'Microsoft Office, Kearsipan', 'dummy-863b4c194117ac246f95.jpg', '863b4c194117ac246f9564d564c2487f', 'aktif',
      '2026-10-09'::timestamp + time '09:00', '2026-10-09'::timestamp + time '09:00', '2026-10-09'::timestamp + time '09:00',
      '2026-10-09'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Telkom Indonesia' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '863b4c194117ac246f9564d564c2487f' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '863b4c194117ac246f9564d564c2487f' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Rekam Arsip Digital', 'full_time', 'wfo', 'Bandung', 'Rp4-12 juta', 2, 0,
      '2026-12-26', 'Memindai dan mengindeks dokumen klien ke sistem arsip digital. Penempatan di Bandung.', '- Fresh graduate dipersilakan melamar
- Menguasai Pengarsipan digital
- IPK minimal 3,00
- Komunikatif dan teliti
- Memiliki laptop pribadi', 'Pengarsipan digital, Ketelitian', 'dummy-844f7221d75a2b270f14.jpg', '844f7221d75a2b270f14cad18b442afa', 'aktif',
      '2026-10-03'::timestamp + time '09:00', '2026-10-03'::timestamp + time '09:00', '2026-10-03'::timestamp + time '09:00',
      '2026-10-03'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Telkom Indonesia' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '844f7221d75a2b270f14cad18b442afa' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '844f7221d75a2b270f14cad18b442afa' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Staf Gudang dan Logistik', 'magang', 'wfo', 'Bandung', '', 2, 0,
      '2026-12-14', 'Mengatur penerimaan, penyimpanan, dan pengiriman barang. Penempatan di Bandung.', '- Fresh graduate dipersilakan melamar
- Menguasai Inventori
- IPK minimal 3,00
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Inventori, Microsoft Excel', 'dummy-28ea48d8099eaa320988.jpg', '28ea48d8099eaa3209882f77fc47aa88', 'menunggu',
      '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Telkom Indonesia' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '28ea48d8099eaa3209882f77fc47aa88' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '28ea48d8099eaa3209882f77fc47aa88' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Sales Executive', 'magang', 'wfo', 'Bandung', 'Uang saku Rp1.500.000', 10, 0,
      '2027-01-02', 'Mencari pelanggan baru dan menjaga hubungan baik dengan pelanggan lama. Penempatan di Bandung.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Negosiasi
- Bersedia bekerja shift
- IPK minimal 3,00
- Memiliki laptop pribadi', 'Negosiasi, Komunikasi, Presentasi', 'dummy-285f372e13dd05d15b3a.jpg', '285f372e13dd05d15b3a09652c5de4d3', 'aktif',
      '2026-09-30'::timestamp + time '09:00', '2026-09-30'::timestamp + time '09:00', '2026-09-30'::timestamp + time '09:00',
      '2026-09-30'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Telkom Indonesia' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '285f372e13dd05d15b3a09652c5de4d3' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '285f372e13dd05d15b3a09652c5de4d3' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Digital Marketing Specialist', 'full_time', 'wfo', 'Bandung', 'Rp4,5-9 juta', 3, 0,
      '2026-12-07', 'Merencanakan konten dan kampanye digital untuk menaikkan penjualan. Penempatan di Bandung.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Media sosial
- Berpengalaman magang di bidang terkait (nilai tambah)
- Mampu bekerja dalam tim
- IPK minimal 3,00', 'Media sosial, SEO, Canva', 'dummy-7b8bc14b44fe44fcec31.jpg', '7b8bc14b44fe44fcec3159801bfb8c27', 'aktif',
      '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00',
      '2026-10-06'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Telkom Indonesia' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '7b8bc14b44fe44fcec3159801bfb8c27' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '7b8bc14b44fe44fcec3159801bfb8c27' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'IT Support', 'kontrak', 'wfo', 'Bandung', 'Rp4,5-8 juta', 5, 0,
      '2027-01-06', 'Membantu pengguna internal menangani masalah perangkat keras, perangkat lunak, dan jaringan. Penempatan di Bandung.', '- Fresh graduate dipersilakan melamar
- Menguasai Troubleshooting
- Mampu bekerja dalam tim
- Komunikatif dan teliti
- Bersedia bekerja shift', 'Troubleshooting, Windows, Jaringan dasar', 'dummy-0494ac14f0c541aa44f4.jpg', '0494ac14f0c541aa44f46aaf3d524040', 'aktif',
      '2026-10-03'::timestamp + time '09:00', '2026-10-03'::timestamp + time '09:00', '2026-10-03'::timestamp + time '09:00',
      '2026-10-03'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Telkom Indonesia' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '0494ac14f0c541aa44f46aaf3d524040' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '0494ac14f0c541aa44f46aaf3d524040' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Operator Proses Produksi', 'full_time', 'wfo', 'Gresik', 'Rp5-10 juta', 1, 0,
      '2026-12-29', 'Menjalankan peralatan proses dan mencatat parameter operasi setiap shift. Penempatan di Gresik.', '- Fresh graduate dipersilakan melamar
- Menguasai Operasi unit proses
- IPK minimal 3,00
- Komunikatif dan teliti
- Mampu bekerja dalam tim', 'Operasi unit proses, K3', 'dummy-7c3bc657ae40d6e9aa7f.jpg', '7c3bc657ae40d6e9aa7f96dff6e373b8', 'aktif',
      '2026-10-25'::timestamp + time '09:00', '2026-10-25'::timestamp + time '09:00', '2026-10-25'::timestamp + time '09:00',
      '2026-10-25'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND b.nama = 'Kimia'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '7c3bc657ae40d6e9aa7f96dff6e373b8' AND jr.nama = 'Teknik Kimia' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Teknisi Panel Surya', 'part_time', 'wfo', 'Gresik', 'Rp5-10 juta', 3, 0,
      '2027-01-06', 'Memasang dan merawat sistem pembangkit listrik tenaga surya atap. Penempatan di Gresik.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai PLTS
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)
- Mampu bekerja dalam tim', 'PLTS, Inverter, K3', 'dummy-ebba9c301218af1da7ac.jpg', 'ebba9c301218af1da7aceefccd383a69', 'aktif',
      '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00',
      '2026-10-19'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'ebba9c301218af1da7aceefccd383a69' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'ebba9c301218af1da7aceefccd383a69' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf K3', 'full_time', 'wfo', 'Gresik', 'Rp5-12 juta', 8, 0,
      '2026-11-28', 'Mengawasi penerapan keselamatan dan kesehatan kerja di area pabrik. Penempatan di Gresik.', '- Fresh graduate dipersilakan melamar
- Menguasai K3
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)
- IPK minimal 3,00', 'K3, ISO 45001, Investigasi kecelakaan', 'dummy-da1dbd3530724e0d71ab.jpg', 'da1dbd3530724e0d71ab6185388f70d9', 'aktif',
      '2026-10-05'::timestamp + time '09:00', '2026-10-05'::timestamp + time '09:00', '2026-10-05'::timestamp + time '09:00',
      '2026-10-05'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'da1dbd3530724e0d71ab6185388f70d9' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'da1dbd3530724e0d71ab6185388f70d9' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Drafter Mekanik', 'full_time', 'wfo', 'Gresik', 'Rp5-7 juta', 4, 0,
      '2026-12-25', 'Membuat gambar teknik 2D/3D komponen dan perakitan sesuai kebutuhan produksi. Penempatan di Gresik.', '- Fresh graduate dipersilakan melamar
- Menguasai AutoCAD
- Mampu bekerja dalam tim
- IPK minimal 3,00
- Komunikatif dan teliti', 'AutoCAD, SolidWorks', 'dummy-cc05d34493094b2bdac0.jpg', 'cc05d34493094b2bdac0fb5a58db8dd6', 'aktif',
      '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00',
      '2026-10-06'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'cc05d34493094b2bdac0fb5a58db8dd6' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'cc05d34493094b2bdac0fb5a58db8dd6' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Process Engineer', 'full_time', 'wfo', 'Sidoarjo', 'Rp5-10 juta', 8, 0,
      '2026-12-06', 'Memantau dan mengoptimalkan proses produksi agar efisien dan sesuai spesifikasi. Penempatan di Sidoarjo.', '- Fresh graduate dipersilakan melamar
- Menguasai Neraca massa
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)
- Komunikatif dan teliti', 'Neraca massa, Proses kimia, Microsoft Excel', 'dummy-74fa81393438bd0a2a72.jpg', '74fa81393438bd0a2a721befdd42a3a3', 'aktif',
      '2026-09-27'::timestamp + time '09:00', '2026-09-27'::timestamp + time '09:00', '2026-09-27'::timestamp + time '09:00',
      '2026-09-27'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND b.nama = 'Kimia'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '74fa81393438bd0a2a721befdd42a3a3' AND jr.nama = 'Teknik Kimia' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Analis Laboratorium', 'part_time', 'wfo', 'Bandung', 'Rp8-9 juta', 8, 0,
      '2026-10-25', 'Melakukan analisis bahan baku dan produk di laboratorium sesuai metode standar. Penempatan di Bandung.', '- Fresh graduate dipersilakan melamar
- Menguasai Analisis kimia
- Berpengalaman magang di bidang terkait (nilai tambah)
- IPK minimal 3,00
- Komunikatif dan teliti', 'Analisis kimia, Titrasi, Spektrofotometri', 'dummy-8b1beb77a3e63f4d8e2f.jpg', '8b1beb77a3e63f4d8e2fff3facbd9a65', 'ditutup',
      '2026-10-14'::timestamp + time '09:00', '2026-10-14'::timestamp + time '09:00', '2026-10-14'::timestamp + time '09:00',
      '2026-10-14'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND b.nama = 'Kimia'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '8b1beb77a3e63f4d8e2fff3facbd9a65' AND jr.nama = 'Teknik Kimia' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Staf Pengelolaan Limbah (HSE)', 'magang', 'wfo', 'Gresik', '', 2, 0,
      '2027-01-24', 'Mengelola limbah dan memastikan pabrik memenuhi baku mutu lingkungan. Penempatan di Gresik.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai IPAL
- IPK minimal 3,00
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)', 'IPAL, ISO 14001, K3', 'dummy-bcfc2618cc391b41a58d.jpg', 'bcfc2618cc391b41a58defff5c5aac67', 'aktif',
      '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00',
      '2026-10-21'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Wilmar Nabati Indonesia' AND b.nama = 'Kimia'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'bcfc2618cc391b41a58defff5c5aac67' AND jr.nama = 'Teknik Kimia' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Quality Control', 'full_time', 'wfo', 'Sidoarjo', 'Rp5,5-9 juta', 2, 0,
      '2027-01-15', 'Memeriksa mutu bahan dan produk jadi, mencatat temuan, dan mengusulkan perbaikan. Penempatan di Sidoarjo.', '- Fresh graduate dipersilakan melamar
- Menguasai Alat ukur
- Bersedia bekerja shift
- IPK minimal 3,00
- Mampu bekerja dalam tim', 'Alat ukur, ISO 9001, Microsoft Excel', 'dummy-52f90237ce8371960753.jpg', '52f90237ce8371960753c83a3ecca2db', 'aktif',
      '2026-10-02'::timestamp + time '09:00', '2026-10-02'::timestamp + time '09:00', '2026-10-02'::timestamp + time '09:00',
      '2026-10-02'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Gudang Garam Tbk' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '52f90237ce8371960753c83a3ecca2db' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '52f90237ce8371960753c83a3ecca2db' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Staf K3', 'magang', 'wfo', 'Kediri', 'Uang saku Rp1.500.000', 2, 0,
      '2027-01-21', 'Mengawasi penerapan keselamatan dan kesehatan kerja di area pabrik. Penempatan di Kediri.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai K3
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)
- Mampu bekerja dalam tim', 'K3, ISO 45001, Investigasi kecelakaan', 'dummy-792e361ccc209c0dad60.jpg', '792e361ccc209c0dad60929e64860fc9', 'aktif',
      '2026-10-09'::timestamp + time '09:00', '2026-10-09'::timestamp + time '09:00', '2026-10-09'::timestamp + time '09:00',
      '2026-10-09'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Gudang Garam Tbk' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '792e361ccc209c0dad60929e64860fc9' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '792e361ccc209c0dad60929e64860fc9' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Teknisi Panel Surya', 'full_time', 'wfo', 'Kediri', 'Rp4-12 juta', 3, 0,
      '2026-10-23', 'Memasang dan merawat sistem pembangkit listrik tenaga surya atap. Penempatan di Kediri.', '- Fresh graduate dipersilakan melamar
- Menguasai PLTS
- Berpengalaman magang di bidang terkait (nilai tambah)
- Komunikatif dan teliti
- IPK minimal 3,00', 'PLTS, Inverter, K3', 'dummy-d7f212630060b32d9d96.jpg', 'd7f212630060b32d9d96217ee4fd80e3', 'ditutup',
      '2026-09-26'::timestamp + time '09:00', '2026-09-26'::timestamp + time '09:00', '2026-09-26'::timestamp + time '09:00',
      '2026-09-26'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Gudang Garam Tbk' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'd7f212630060b32d9d96217ee4fd80e3' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'd7f212630060b32d9d96217ee4fd80e3' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Teller', 'kontrak', 'wfo', 'Kediri', 'Rp5-12 juta', 3, 0,
      '2026-12-14', 'Melayani transaksi tunai dan nontunai nasabah sesuai prosedur. Penempatan di Kediri.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Ketelitian
- Memiliki laptop pribadi
- Mampu bekerja dalam tim
- Komunikatif dan teliti', 'Ketelitian, Pelayanan nasabah', 'dummy-aeff16ae194a3e132d06.jpg', 'aeff16ae194a3e132d061dd977dd7026', 'menunggu',
      '2026-10-24'::timestamp + time '09:00', '2026-10-24'::timestamp + time '09:00', '2026-10-24'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Gudang Garam Tbk' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'aeff16ae194a3e132d061dd977dd7026' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'aeff16ae194a3e132d061dd977dd7026' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Engineer Proteksi Sistem Tenaga', 'full_time', 'wfo', 'Surabaya', 'Rp7-9 juta', 4, 0,
      '2026-12-20', 'Menganalisis dan menyetel sistem proteksi gardu dan jaringan distribusi. Penempatan di Surabaya.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Relay proteksi
- Komunikatif dan teliti
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Relay proteksi, ETAP', 'dummy-107122b752854be50fdb.jpg', '107122b752854be50fdb6bb699419631', 'aktif',
      '2026-09-26'::timestamp + time '09:00', '2026-09-26'::timestamp + time '09:00', '2026-09-26'::timestamp + time '09:00',
      '2026-09-26'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Gudang Garam Tbk' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '107122b752854be50fdb6bb699419631' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '107122b752854be50fdb6bb699419631' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Production Planning Staff', 'full_time', 'wfo', 'Kediri', 'Rp7-12 juta', 2, 0,
      '2027-02-04', 'Menyusun jadwal produksi dan memastikan bahan tersedia tepat waktu. Penempatan di Kediri.', '- Fresh graduate dipersilakan melamar
- Menguasai PPIC
- Bersedia bekerja shift
- IPK minimal 3,00
- Mampu bekerja dalam tim', 'PPIC, Microsoft Excel, ERP', 'dummy-4248173633306528e306.jpg', '4248173633306528e30677a9318dfeb0', 'aktif',
      '2026-10-01'::timestamp + time '09:00', '2026-10-01'::timestamp + time '09:00', '2026-10-01'::timestamp + time '09:00',
      '2026-10-01'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Gudang Garam Tbk' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '4248173633306528e30677a9318dfeb0' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '4248173633306528e30677a9318dfeb0' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Account Officer UMKM', 'magang', 'wfo', 'Bandung', '', 3, 0,
      '2027-02-03', 'Menganalisis pengajuan kredit usaha mikro dan kecil serta membina debitur. Penempatan di Bandung.', '- Fresh graduate dipersilakan melamar
- Menguasai Analisis kredit
- Komunikatif dan teliti
- Berpengalaman magang di bidang terkait (nilai tambah)
- Bersedia bekerja shift', 'Analisis kredit, Komunikasi', 'dummy-f5dbbc9929d70e5160e2.jpg', 'f5dbbc9929d70e5160e2746a7a2b98c3', 'aktif',
      '2026-10-18'::timestamp + time '09:00', '2026-10-18'::timestamp + time '09:00', '2026-10-18'::timestamp + time '09:00',
      '2026-10-18'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pindad' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'f5dbbc9929d70e5160e2746a7a2b98c3' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'f5dbbc9929d70e5160e2746a7a2b98c3' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Quality Control', 'part_time', 'wfo', 'Bandung', 'Rp6-8 juta', 5, 0,
      '2027-01-24', 'Memeriksa mutu bahan dan produk jadi, mencatat temuan, dan mengusulkan perbaikan. Penempatan di Bandung.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Alat ukur
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)
- Komunikatif dan teliti', 'Alat ukur, ISO 9001, Microsoft Excel', 'dummy-3e1e2f3e4847a41accb6.jpg', '3e1e2f3e4847a41accb6d9bc5599e7a2', 'aktif',
      '2026-10-15'::timestamp + time '09:00', '2026-10-15'::timestamp + time '09:00', '2026-10-15'::timestamp + time '09:00',
      '2026-10-15'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pindad' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '3e1e2f3e4847a41accb6d9bc5599e7a2' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '3e1e2f3e4847a41accb6d9bc5599e7a2' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Customer Service Officer', 'magang', 'wfo', 'Bandung', 'Uang saku Rp1.500.000', 3, 0,
      '2026-10-11', 'Melayani nasabah di kantor cabang secara ramah, cepat, dan tepat. Penempatan di Bandung.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Komunikasi
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)
- Memiliki laptop pribadi', 'Komunikasi, Pelayanan nasabah', 'dummy-c7d772c7598cdd9f2083.jpg', 'c7d772c7598cdd9f2083987f41b362e6', 'ditutup',
      '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00',
      '2026-10-27'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pindad' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'c7d772c7598cdd9f2083987f41b362e6' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'c7d772c7598cdd9f2083987f41b362e6' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Welder (Juru Las)', 'magang', 'wfo', 'Bandung', 'Uang saku Rp1.500.000', 10, 0,
      '2026-12-10', 'Melakukan pengelasan konstruksi dan komponen sesuai prosedur WPS. Penempatan di Bandung.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Las SMAW
- Bersedia bekerja shift
- Mampu bekerja dalam tim
- Memiliki laptop pribadi', 'Las SMAW, Las GTAW, Membaca gambar', 'dummy-d559eb2e7a420c0b7d55.jpg', 'd559eb2e7a420c0b7d558a81b0bd4beb', 'aktif',
      '2026-09-29'::timestamp + time '09:00', '2026-09-29'::timestamp + time '09:00', '2026-09-29'::timestamp + time '09:00',
      '2026-09-29'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pindad' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'd559eb2e7a420c0b7d558a81b0bd4beb' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'd559eb2e7a420c0b7d558a81b0bd4beb' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Production Planning Staff', 'full_time', 'wfo', 'Bandung', 'Rp5-12 juta', 2, 0,
      '2026-12-11', 'Menyusun jadwal produksi dan memastikan bahan tersedia tepat waktu. Penempatan di Bandung.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai PPIC
- Komunikatif dan teliti
- Berpengalaman magang di bidang terkait (nilai tambah)
- IPK minimal 3,00', 'PPIC, Microsoft Excel, ERP', 'dummy-30b880791f3723944f19.jpg', '30b880791f3723944f192a191ae7ad00', 'aktif',
      '2026-10-05'::timestamp + time '09:00', '2026-10-05'::timestamp + time '09:00', '2026-10-05'::timestamp + time '09:00',
      '2026-10-05'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pindad' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '30b880791f3723944f192a191ae7ad00' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '30b880791f3723944f192a191ae7ad00' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Site Engineer', 'full_time', 'wfo', 'Gresik', 'Rp4-12 juta', 3, 0,
      '2027-02-08', 'Mengawasi pelaksanaan pekerjaan di lapangan agar sesuai gambar, jadwal, dan mutu. Penempatan di Gresik.', '- Fresh graduate dipersilakan melamar
- Menguasai Manajemen proyek
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)
- Komunikatif dan teliti', 'Manajemen proyek, K3 konstruksi', 'dummy-8a95dd480e8b232015e8.jpg', '8a95dd480e8b232015e8cfb3e021d76d', 'aktif',
      '2026-09-28'::timestamp + time '09:00', '2026-09-28'::timestamp + time '09:00', '2026-09-28'::timestamp + time '09:00',
      '2026-09-28'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Semen Indonesia' AND b.nama = 'Konstruksi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '8a95dd480e8b232015e8cfb3e021d76d' AND jr.nama = 'Teknik Sipil' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Engineer Proteksi Sistem Tenaga', 'kontrak', 'wfo', 'Gresik', 'Rp8-7 juta', 10, 0,
      '2026-12-24', 'Menganalisis dan menyetel sistem proteksi gardu dan jaringan distribusi. Penempatan di Gresik.', '- Fresh graduate dipersilakan melamar
- Menguasai Relay proteksi
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)
- Komunikatif dan teliti', 'Relay proteksi, ETAP', 'dummy-cdda47c6c4fe1dc949a1.jpg', 'cdda47c6c4fe1dc949a1182c6b39a059', 'aktif',
      '2026-10-22'::timestamp + time '09:00', '2026-10-22'::timestamp + time '09:00', '2026-10-22'::timestamp + time '09:00',
      '2026-10-22'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Semen Indonesia' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'cdda47c6c4fe1dc949a1182c6b39a059' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'cdda47c6c4fe1dc949a1182c6b39a059' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Teknisi Listrik', 'full_time', 'wfo', 'Bandung', 'Rp8-7 juta', 10, 0,
      '2027-02-05', 'Memasang dan merawat instalasi listrik gedung dan panel distribusi. Penempatan di Bandung.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Instalasi listrik
- Komunikatif dan teliti
- Memiliki laptop pribadi
- IPK minimal 3,00', 'Instalasi listrik, PLC, K3 listrik', 'dummy-b196e4b6ae55bb6b3c5c.jpg', 'b196e4b6ae55bb6b3c5c872dff092820', 'aktif',
      '2026-10-08'::timestamp + time '09:00', '2026-10-08'::timestamp + time '09:00', '2026-10-08'::timestamp + time '09:00',
      '2026-10-08'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Semen Indonesia' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'b196e4b6ae55bb6b3c5c872dff092820' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'b196e4b6ae55bb6b3c5c872dff092820' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Quantity Surveyor', 'kontrak', 'wfo', 'Gresik', 'Rp7-7 juta', 8, 0,
      '2027-01-06', 'Menghitung volume pekerjaan dan menyusun rencana anggaran biaya proyek. Penempatan di Gresik.', '- Fresh graduate dipersilakan melamar
- Menguasai RAB
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)
- Mampu bekerja dalam tim', 'RAB, Microsoft Excel, AutoCAD', 'dummy-19c2d47855d1003d8db2.jpg', '19c2d47855d1003d8db2d317cd11a82f', 'aktif',
      '2026-10-20'::timestamp + time '09:00', '2026-10-20'::timestamp + time '09:00', '2026-10-20'::timestamp + time '09:00',
      '2026-10-20'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Semen Indonesia' AND b.nama = 'Konstruksi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '19c2d47855d1003d8db2d317cd11a82f' AND jr.nama = 'Teknik Sipil' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Drafter Sipil', 'full_time', 'wfo', 'Gresik', 'Rp4,5-9 juta', 4, 0,
      '2026-12-25', 'Menyiapkan gambar kerja struktur dan arsitektur untuk proyek gedung dan jalan. Penempatan di Gresik.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai AutoCAD
- Memiliki laptop pribadi
- Mampu bekerja dalam tim
- Komunikatif dan teliti', 'AutoCAD, Revit, Gambar kerja', 'dummy-472eb8820dd9dd70dedd.jpg', '472eb8820dd9dd70dedd46be23efaecf', 'aktif',
      '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00',
      '2026-10-21'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Semen Indonesia' AND b.nama = 'Konstruksi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '472eb8820dd9dd70dedd46be23efaecf' AND jr.nama = 'Teknik Sipil' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Surveyor Pengukuran', 'full_time', 'wfo', 'Gresik', 'Rp4-9 juta', 3, 0,
      '2027-01-19', 'Melakukan pengukuran topografi dan stake out di lokasi proyek. Penempatan di Gresik.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Total station
- Mampu bekerja dalam tim
- Bersedia bekerja shift
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Total station, GPS geodetik, AutoCAD', 'dummy-9715913b950b61ec8892.jpg', '9715913b950b61ec889202ef71123a4e', 'aktif',
      '2026-09-29'::timestamp + time '09:00', '2026-09-29'::timestamp + time '09:00', '2026-09-29'::timestamp + time '09:00',
      '2026-09-29'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Semen Indonesia' AND b.nama = 'Konstruksi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '9715913b950b61ec889202ef71123a4e' AND jr.nama = 'Teknik Sipil' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Audit Internal', 'full_time', 'wfo', 'Jakarta', 'Rp4,5-9 juta', 1, 0,
      '2026-12-12', 'Memeriksa kepatuhan proses dan pengendalian internal di setiap unit. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Audit
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)
- Bersedia bekerja shift', 'Audit, Microsoft Excel, Analisis risiko', 'dummy-80a235ee22fdd5ee1aea.jpg', '80a235ee22fdd5ee1aea53809655b0b6', 'aktif',
      '2026-09-30'::timestamp + time '09:00', '2026-09-30'::timestamp + time '09:00', '2026-09-30'::timestamp + time '09:00',
      '2026-09-30'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Bank Mandiri Tbk' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '80a235ee22fdd5ee1aea53809655b0b6' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '80a235ee22fdd5ee1aea53809655b0b6' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Data Analyst', 'full_time', 'hybrid', 'Surabaya', 'Rp6-12 juta', 5, 0,
      '2026-11-29', 'Mengolah data operasional menjadi dashboard dan laporan yang membantu pengambilan keputusan. Penempatan di Surabaya.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Python
- Komunikatif dan teliti
- IPK minimal 3,00
- Mampu bekerja dalam tim', 'Python, SQL, Microsoft Excel, Power BI', 'dummy-07bb92a457395d70f370.jpg', '07bb92a457395d70f370819f48f367c9', 'aktif',
      '2026-10-15'::timestamp + time '09:00', '2026-10-15'::timestamp + time '09:00', '2026-10-15'::timestamp + time '09:00',
      '2026-10-15'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Bank Mandiri Tbk' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '07bb92a457395d70f370819f48f367c9' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '07bb92a457395d70f370819f48f367c9' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Customer Service Officer', 'full_time', 'wfo', 'Jakarta', 'Rp4,5-9 juta', 2, 0,
      '2027-01-14', 'Melayani nasabah di kantor cabang secara ramah, cepat, dan tepat. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai Komunikasi
- Memiliki laptop pribadi
- Komunikatif dan teliti
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Komunikasi, Pelayanan nasabah', 'dummy-fccda893d0bf311eeba0.jpg', 'fccda893d0bf311eeba05bb526e55f10', 'aktif',
      '2026-10-12'::timestamp + time '09:00', '2026-10-12'::timestamp + time '09:00', '2026-10-12'::timestamp + time '09:00',
      '2026-10-12'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Bank Mandiri Tbk' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'fccda893d0bf311eeba05bb526e55f10' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'fccda893d0bf311eeba05bb526e55f10' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Frontend Developer', 'magang', 'wfh', 'Jakarta', 'Uang saku Rp1.500.000', 4, 0,
      '2027-01-20', 'Mengubah desain menjadi antarmuka web yang cepat, responsif, dan mudah diakses. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai HTML
- Mampu bekerja dalam tim
- Bersedia bekerja shift
- Berpengalaman magang di bidang terkait (nilai tambah)', 'HTML, CSS, JavaScript, React', 'dummy-d872d683fc77e3c6a0df.jpg', 'd872d683fc77e3c6a0dfad8213ecdec1', 'aktif',
      '2026-10-23'::timestamp + time '09:00', '2026-10-23'::timestamp + time '09:00', '2026-10-23'::timestamp + time '09:00',
      '2026-10-23'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Bank Mandiri Tbk' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'd872d683fc77e3c6a0dfad8213ecdec1' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'd872d683fc77e3c6a0dfad8213ecdec1' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Staf Akuntansi', 'magang', 'wfo', 'Jakarta', 'Uang saku Rp1.500.000', 2, 0,
      '2026-11-22', 'Mencatat transaksi, menyusun jurnal, dan membantu laporan keuangan bulanan. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai Akuntansi keuangan
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)
- Komunikatif dan teliti', 'Akuntansi keuangan, Microsoft Excel, Accurate', 'dummy-7fad171603506c215842.jpg', '7fad171603506c2158427147e82f1ff6', 'menunggu',
      '2026-10-11'::timestamp + time '09:00', '2026-10-11'::timestamp + time '09:00', '2026-10-11'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Bank Mandiri Tbk' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '7fad171603506c2158427147e82f1ff6' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '7fad171603506c2158427147e82f1ff6' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Account Officer UMKM', 'full_time', 'wfo', 'Jakarta', 'Rp4-8 juta', 8, 0,
      '2027-01-07', 'Menganalisis pengajuan kredit usaha mikro dan kecil serta membina debitur. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai Analisis kredit
- Berpengalaman magang di bidang terkait (nilai tambah)
- IPK minimal 3,00
- Bersedia bekerja shift', 'Analisis kredit, Komunikasi', 'dummy-592a4b4e4c6e995cda46.jpg', '592a4b4e4c6e995cda4658f9ba5e258d', 'menunggu',
      '2026-09-26'::timestamp + time '09:00', '2026-09-26'::timestamp + time '09:00', '2026-09-26'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Bank Mandiri Tbk' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '592a4b4e4c6e995cda4658f9ba5e258d' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '592a4b4e4c6e995cda4658f9ba5e258d' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Process Engineer', 'kontrak', 'wfo', 'Jakarta', 'Rp4-9 juta', 3, 0,
      '2027-01-31', 'Memantau dan mengoptimalkan proses produksi agar efisien dan sesuai spesifikasi. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai Neraca massa
- IPK minimal 3,00
- Komunikatif dan teliti
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Neraca massa, Proses kimia, Microsoft Excel', 'dummy-0472971ddd7e5f08bcad.jpg', '0472971ddd7e5f08bcad37f2bf57cfd0', 'aktif',
      '2026-10-20'::timestamp + time '09:00', '2026-10-20'::timestamp + time '09:00', '2026-10-20'::timestamp + time '09:00',
      '2026-10-20'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pertamina Patra Niaga' AND b.nama = 'Kimia'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '0472971ddd7e5f08bcad37f2bf57cfd0' AND jr.nama = 'Teknik Kimia' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Operator CNC', 'magang', 'wfo', 'Jakarta', 'Uang saku Rp1.500.000', 3, 0,
      '2026-12-16', 'Mengoperasikan mesin CNC sesuai gambar kerja dan standar mutu produksi. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai CNC
- Bersedia bekerja shift
- Mampu bekerja dalam tim
- IPK minimal 3,00', 'CNC, Membaca gambar teknik, K3', 'dummy-a672517ead6cc5b4d480.jpg', 'a672517ead6cc5b4d480411b7aa66a8a', 'aktif',
      '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00',
      '2026-10-06'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pertamina Patra Niaga' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'a672517ead6cc5b4d480411b7aa66a8a' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'a672517ead6cc5b4d480411b7aa66a8a' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Analis Laboratorium', 'kontrak', 'wfo', 'Jakarta', 'Rp8-8 juta', 10, 0,
      '2026-10-26', 'Melakukan analisis bahan baku dan produk di laboratorium sesuai metode standar. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Analisis kimia
- IPK minimal 3,00
- Bersedia bekerja shift
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Analisis kimia, Titrasi, Spektrofotometri', 'dummy-6960d6b3ffe7589e947e.jpg', '6960d6b3ffe7589e947ee1216e75a80c', 'ditutup',
      '2026-10-10'::timestamp + time '09:00', '2026-10-10'::timestamp + time '09:00', '2026-10-10'::timestamp + time '09:00',
      '2026-10-10'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pertamina Patra Niaga' AND b.nama = 'Kimia'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '6960d6b3ffe7589e947ee1216e75a80c' AND jr.nama = 'Teknik Kimia' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Operator Proses Produksi', 'part_time', 'wfo', 'Jakarta', 'Rp4-12 juta', 1, 0,
      '2027-01-31', 'Menjalankan peralatan proses dan mencatat parameter operasi setiap shift. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Operasi unit proses
- Bersedia bekerja shift
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Operasi unit proses, K3', 'dummy-adb6f607fb418f45b848.jpg', 'adb6f607fb418f45b848f9b453b843c6', 'aktif',
      '2026-10-10'::timestamp + time '09:00', '2026-10-10'::timestamp + time '09:00', '2026-10-10'::timestamp + time '09:00',
      '2026-10-10'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pertamina Patra Niaga' AND b.nama = 'Kimia'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'adb6f607fb418f45b848f9b453b843c6' AND jr.nama = 'Teknik Kimia' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Engineer Proteksi Sistem Tenaga', 'part_time', 'wfo', 'Jakarta', 'Rp7-10 juta', 5, 0,
      '2027-01-28', 'Menganalisis dan menyetel sistem proteksi gardu dan jaringan distribusi. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Relay proteksi
- Komunikatif dan teliti
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Relay proteksi, ETAP', 'dummy-9f31cf433b3ba339143d.jpg', '9f31cf433b3ba339143da829ab931d7a', 'aktif',
      '2026-10-14'::timestamp + time '09:00', '2026-10-14'::timestamp + time '09:00', '2026-10-14'::timestamp + time '09:00',
      '2026-10-14'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pertamina Patra Niaga' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '9f31cf433b3ba339143da829ab931d7a' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '9f31cf433b3ba339143da829ab931d7a' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf K3', 'kontrak', 'wfo', 'Jakarta', 'Rp7-12 juta', 4, 0,
      '2026-12-16', 'Mengawasi penerapan keselamatan dan kesehatan kerja di area pabrik. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai K3
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)
- Komunikatif dan teliti', 'K3, ISO 45001, Investigasi kecelakaan', 'dummy-8974f452b1f03b6500b8.jpg', '8974f452b1f03b6500b87bf6e3edd4b7', 'menunggu',
      '2026-09-29'::timestamp + time '09:00', '2026-09-29'::timestamp + time '09:00', '2026-09-29'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pertamina Patra Niaga' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '8974f452b1f03b6500b87bf6e3edd4b7' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '8974f452b1f03b6500b87bf6e3edd4b7' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Production Planning Staff', 'magang', 'wfo', 'Jakarta', 'Uang saku Rp1.500.000', 2, 0,
      '2027-01-14', 'Menyusun jadwal produksi dan memastikan bahan tersedia tepat waktu. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai PPIC
- Bersedia bekerja shift
- IPK minimal 3,00
- Komunikatif dan teliti', 'PPIC, Microsoft Excel, ERP', 'dummy-bc02a88082165c305c94.jpg', 'bc02a88082165c305c9403accb2e34a8', 'aktif',
      '2026-09-27'::timestamp + time '09:00', '2026-09-27'::timestamp + time '09:00', '2026-09-27'::timestamp + time '09:00',
      '2026-09-27'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Pertamina Patra Niaga' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'bc02a88082165c305c9403accb2e34a8' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'bc02a88082165c305c9403accb2e34a8' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf K3', 'kontrak', 'wfo', 'Pasuruan', 'Rp7-12 juta', 10, 0,
      '2026-12-20', 'Mengawasi penerapan keselamatan dan kesehatan kerja di area pabrik. Penempatan di Pasuruan.', '- Fresh graduate dipersilakan melamar
- Menguasai K3
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)
- Memiliki laptop pribadi', 'K3, ISO 45001, Investigasi kecelakaan', 'dummy-07abb02117fcc7776c9e.jpg', '07abb02117fcc7776c9eb6775561d23f', 'menunggu',
      '2026-09-29'::timestamp + time '09:00', '2026-09-29'::timestamp + time '09:00', '2026-09-29'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nestle Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '07abb02117fcc7776c9eb6775561d23f' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '07abb02117fcc7776c9eb6775561d23f' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Supervisor Produksi', 'full_time', 'wfo', 'Pasuruan', 'Rp6-10 juta', 8, 0,
      '2026-12-12', 'Memimpin tim lini produksi agar target kuantitas, mutu, dan keselamatan tercapai. Penempatan di Pasuruan.', '- Fresh graduate dipersilakan melamar
- Menguasai Kepemimpinan
- IPK minimal 3,00
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Kepemimpinan, Lean manufacturing, K3', 'dummy-989a89ff30fe95b2edd0.jpg', '989a89ff30fe95b2edd09f30ec6e4ff0', 'aktif',
      '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00',
      '2026-10-21'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nestle Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '989a89ff30fe95b2edd09f30ec6e4ff0' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '989a89ff30fe95b2edd09f30ec6e4ff0' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Operator CNC', 'full_time', 'wfo', 'Jakarta', 'Rp5,5-10 juta', 2, 0,
      '2026-12-11', 'Mengoperasikan mesin CNC sesuai gambar kerja dan standar mutu produksi. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai CNC
- Bersedia bekerja shift
- Mampu bekerja dalam tim
- Komunikatif dan teliti', 'CNC, Membaca gambar teknik, K3', 'dummy-afc2e355c79aa4106db1.jpg', 'afc2e355c79aa4106db1577016555244', 'aktif',
      '2026-10-13'::timestamp + time '09:00', '2026-10-13'::timestamp + time '09:00', '2026-10-13'::timestamp + time '09:00',
      '2026-10-13'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nestle Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'afc2e355c79aa4106db1577016555244' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'afc2e355c79aa4106db1577016555244' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Production Planning Staff', 'kontrak', 'wfo', 'Pasuruan', 'Rp4-9 juta', 10, 0,
      '2026-11-29', 'Menyusun jadwal produksi dan memastikan bahan tersedia tepat waktu. Penempatan di Pasuruan.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai PPIC
- Berpengalaman magang di bidang terkait (nilai tambah)
- Memiliki laptop pribadi
- Mampu bekerja dalam tim', 'PPIC, Microsoft Excel, ERP', 'dummy-661d5f7945f693b4dbd6.jpg', '661d5f7945f693b4dbd6faf9c6b47841', 'aktif',
      '2026-09-27'::timestamp + time '09:00', '2026-09-27'::timestamp + time '09:00', '2026-09-27'::timestamp + time '09:00',
      '2026-09-27'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nestle Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '661d5f7945f693b4dbd6faf9c6b47841' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '661d5f7945f693b4dbd6faf9c6b47841' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Audit Internal', 'full_time', 'wfo', 'Pasuruan', 'Rp4,5-12 juta', 2, 0,
      '2026-11-28', 'Memeriksa kepatuhan proses dan pengendalian internal di setiap unit. Penempatan di Pasuruan.', '- Fresh graduate dipersilakan melamar
- Menguasai Audit
- Berpengalaman magang di bidang terkait (nilai tambah)
- Memiliki laptop pribadi
- Mampu bekerja dalam tim', 'Audit, Microsoft Excel, Analisis risiko', 'dummy-23ff332269a95b3d81ff.jpg', '23ff332269a95b3d81ff2842e9671df7', 'aktif',
      '2026-09-25'::timestamp + time '09:00', '2026-09-25'::timestamp + time '09:00', '2026-09-25'::timestamp + time '09:00',
      '2026-09-25'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nestle Indonesia' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '23ff332269a95b3d81ff2842e9671df7' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '23ff332269a95b3d81ff2842e9671df7' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Akuntansi', 'kontrak', 'wfo', 'Pasuruan', 'Rp4-10 juta', 1, 0,
      '2026-10-22', 'Mencatat transaksi, menyusun jurnal, dan membantu laporan keuangan bulanan. Penempatan di Pasuruan.', '- Fresh graduate dipersilakan melamar
- Menguasai Akuntansi keuangan
- Komunikatif dan teliti
- Berpengalaman magang di bidang terkait (nilai tambah)
- Bersedia bekerja shift', 'Akuntansi keuangan, Microsoft Excel, Accurate', 'dummy-e3e55339a5575a37aa72.jpg', 'e3e55339a5575a37aa724a8626db1aa4', 'ditutup',
      '2026-10-22'::timestamp + time '09:00', '2026-10-22'::timestamp + time '09:00', '2026-10-22'::timestamp + time '09:00',
      '2026-10-22'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nestle Indonesia' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'e3e55339a5575a37aa724a8626db1aa4' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'e3e55339a5575a37aa724a8626db1aa4' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Supervisor Produksi', 'full_time', 'wfo', 'Gresik', 'Rp6-9 juta', 8, 0,
      '2027-01-12', 'Memimpin tim lini produksi agar target kuantitas, mutu, dan keselamatan tercapai. Penempatan di Gresik.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Kepemimpinan
- Bersedia bekerja shift
- Berpengalaman magang di bidang terkait (nilai tambah)
- Memiliki laptop pribadi', 'Kepemimpinan, Lean manufacturing, K3', 'dummy-4acde91cd96b2aa9e5a6.jpg', '4acde91cd96b2aa9e5a63797aff44300', 'aktif',
      '2026-09-24'::timestamp + time '09:00', '2026-09-24'::timestamp + time '09:00', '2026-09-24'::timestamp + time '09:00',
      '2026-09-24'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Barata Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '4acde91cd96b2aa9e5a63797aff44300' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '4acde91cd96b2aa9e5a63797aff44300' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Production Planning Staff', 'full_time', 'wfo', 'Sidoarjo', 'Rp6-10 juta', 10, 0,
      '2026-12-11', 'Menyusun jadwal produksi dan memastikan bahan tersedia tepat waktu. Penempatan di Sidoarjo.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai PPIC
- Berpengalaman magang di bidang terkait (nilai tambah)
- Mampu bekerja dalam tim
- Komunikatif dan teliti', 'PPIC, Microsoft Excel, ERP', 'dummy-8b2b1d6315cbd3298cf1.jpg', '8b2b1d6315cbd3298cf1cf611b467b87', 'aktif',
      '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00',
      '2026-10-06'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Barata Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '8b2b1d6315cbd3298cf1cf611b467b87' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '8b2b1d6315cbd3298cf1cf611b467b87' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Staf Quality Control', 'magang', 'wfo', 'Malang', '', 3, 0,
      '2027-01-20', 'Memeriksa mutu bahan dan produk jadi, mencatat temuan, dan mengusulkan perbaikan. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Alat ukur
- Berpengalaman magang di bidang terkait (nilai tambah)
- Mampu bekerja dalam tim
- IPK minimal 3,00', 'Alat ukur, ISO 9001, Microsoft Excel', 'dummy-9542068e35e6bbffb426.jpg', '9542068e35e6bbffb4262aa26fd95c2c', 'aktif',
      '2026-10-02'::timestamp + time '09:00', '2026-10-02'::timestamp + time '09:00', '2026-10-02'::timestamp + time '09:00',
      '2026-10-02'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Barata Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '9542068e35e6bbffb4262aa26fd95c2c' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '9542068e35e6bbffb4262aa26fd95c2c' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Drafter Mekanik', 'kontrak', 'wfo', 'Gresik', 'Rp8-7 juta', 2, 0,
      '2026-12-13', 'Membuat gambar teknik 2D/3D komponen dan perakitan sesuai kebutuhan produksi. Penempatan di Gresik.', '- Fresh graduate dipersilakan melamar
- Menguasai AutoCAD
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)
- IPK minimal 3,00', 'AutoCAD, SolidWorks', 'dummy-ef44af0505608946c95d.jpg', 'ef44af0505608946c95d69ed34ef1d3e', 'aktif',
      '2026-09-25'::timestamp + time '09:00', '2026-09-25'::timestamp + time '09:00', '2026-09-25'::timestamp + time '09:00',
      '2026-09-25'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Barata Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'ef44af0505608946c95d69ed34ef1d3e' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'ef44af0505608946c95d69ed34ef1d3e' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf K3', 'full_time', 'wfo', 'Gresik', 'Rp6-10 juta', 2, 0,
      '2027-02-11', 'Mengawasi penerapan keselamatan dan kesehatan kerja di area pabrik. Penempatan di Gresik.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai K3
- Bersedia bekerja shift
- Memiliki laptop pribadi
- Mampu bekerja dalam tim', 'K3, ISO 45001, Investigasi kecelakaan', 'dummy-5f3f4192e098076fe25c.jpg', '5f3f4192e098076fe25c9679973cd2f4', 'aktif',
      '2026-10-23'::timestamp + time '09:00', '2026-10-23'::timestamp + time '09:00', '2026-10-23'::timestamp + time '09:00',
      '2026-10-23'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Barata Indonesia' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '5f3f4192e098076fe25c9679973cd2f4' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '5f3f4192e098076fe25c9679973cd2f4' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Junior Web Developer', 'full_time', 'wfh', 'Malang', 'Rp8-12 juta', 1, 0,
      '2027-02-06', 'Membangun dan memelihara aplikasi web internal maupun klien, bekerja dalam tim agile bersama desainer dan QA. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai PHP
- Berpengalaman magang di bidang terkait (nilai tambah)
- IPK minimal 3,00
- Mampu bekerja dalam tim', 'PHP, Laravel, JavaScript, PostgreSQL', 'dummy-13917111ccab5afe4c57.jpg', '13917111ccab5afe4c5744d557b0109f', 'aktif',
      '2026-10-03'::timestamp + time '09:00', '2026-10-03'::timestamp + time '09:00', '2026-10-03'::timestamp + time '09:00',
      '2026-10-03'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '13917111ccab5afe4c5744d557b0109f' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '13917111ccab5afe4c5744d557b0109f' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'IT Support', 'full_time', 'wfh', 'Malang', 'Rp4-9 juta', 1, 0,
      '2027-01-20', 'Membantu pengguna internal menangani masalah perangkat keras, perangkat lunak, dan jaringan. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Troubleshooting
- Berpengalaman magang di bidang terkait (nilai tambah)
- IPK minimal 3,00
- Bersedia bekerja shift', 'Troubleshooting, Windows, Jaringan dasar', 'dummy-9bbf11b97833658df25a.jpg', '9bbf11b97833658df25ad42a2f4b42f0', 'aktif',
      '2026-10-14'::timestamp + time '09:00', '2026-10-14'::timestamp + time '09:00', '2026-10-14'::timestamp + time '09:00',
      '2026-10-14'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '9bbf11b97833658df25ad42a2f4b42f0' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '9bbf11b97833658df25ad42a2f4b42f0' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Backend Developer', 'kontrak', 'wfo', 'Malang', 'Rp4,5-8 juta', 5, 0,
      '2026-10-21', 'Merancang API dan basis data yang andal, aman, dan siap menangani banyak pengguna. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Node.js
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)
- Memiliki laptop pribadi', 'Node.js, PHP, PostgreSQL, Docker', 'dummy-fddfd06e6943f1bb524b.jpg', 'fddfd06e6943f1bb524b49d0af7f02a9', 'ditutup',
      '2026-10-14'::timestamp + time '09:00', '2026-10-14'::timestamp + time '09:00', '2026-10-14'::timestamp + time '09:00',
      '2026-10-14'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'fddfd06e6943f1bb524b49d0af7f02a9' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'fddfd06e6943f1bb524b49d0af7f02a9' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Network Engineer', 'magang', 'wfo', 'Malang', '', 3, 0,
      '2026-11-25', 'Memasang, memantau, dan merawat jaringan kantor dan pusat data, termasuk penanganan gangguan. Penempatan di Malang.', '- Fresh graduate dipersilakan melamar
- Menguasai Mikrotik
- Mampu bekerja dalam tim
- Bersedia bekerja shift
- Memiliki laptop pribadi', 'Mikrotik, Cisco, Jaringan komputer', 'dummy-a9bd5baf82244d44b566.jpg', 'a9bd5baf82244d44b566bb84e02cfcbc', 'aktif',
      '2026-10-16'::timestamp + time '09:00', '2026-10-16'::timestamp + time '09:00', '2026-10-16'::timestamp + time '09:00',
      '2026-10-16'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'a9bd5baf82244d44b566bb84e02cfcbc' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'a9bd5baf82244d44b566bb84e02cfcbc' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Customer Relationship Staff', 'full_time', 'wfo', 'Malang', 'Rp4-8 juta', 3, 0,
      '2027-01-24', 'Menangani pertanyaan dan keluhan pelanggan lewat telepon, email, dan chat. Penempatan di Malang.', '- Fresh graduate dipersilakan melamar
- Menguasai Komunikasi
- Memiliki laptop pribadi
- IPK minimal 3,00
- Bersedia bekerja shift', 'Komunikasi, CRM', 'dummy-cbe5d317286ad74d3a80.jpg', 'cbe5d317286ad74d3a80edc4914941cc', 'menunggu',
      '2026-10-16'::timestamp + time '09:00', '2026-10-16'::timestamp + time '09:00', '2026-10-16'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'cbe5d317286ad74d3a80edc4914941cc' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'cbe5d317286ad74d3a80edc4914941cc' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Quality Assurance Engineer', 'kontrak', 'wfh', 'Malang', 'Rp5,5-9 juta', 1, 0,
      '2026-12-20', 'Menyusun skenario uji, menjalankan pengujian fungsional dan regresi, serta mendokumentasikan bug. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Testing manual
- Mampu bekerja dalam tim
- Bersedia bekerja shift
- Komunikatif dan teliti', 'Testing manual, Postman, Selenium', 'dummy-d8789babeed699234f4b.jpg', 'd8789babeed699234f4b744efd32f0e0', 'aktif',
      '2026-10-10'::timestamp + time '09:00', '2026-10-10'::timestamp + time '09:00', '2026-10-10'::timestamp + time '09:00',
      '2026-10-10'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'd8789babeed699234f4b744efd32f0e0' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'd8789babeed699234f4b744efd32f0e0' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'DevOps Engineer', 'full_time', 'wfh', 'Malang', 'Rp8-8 juta', 2, 0,
      '2027-02-14', 'Mengotomatiskan proses build dan deploy serta menjaga server tetap stabil. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Linux
- Mampu bekerja dalam tim
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Linux, Docker, CI/CD, Git', 'dummy-3c8affe9d095fc100a2c.jpg', '3c8affe9d095fc100a2c2543524e9b08', 'aktif',
      '2026-10-08'::timestamp + time '09:00', '2026-10-08'::timestamp + time '09:00', '2026-10-08'::timestamp + time '09:00',
      '2026-10-08'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '3c8affe9d095fc100a2c2543524e9b08' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '3c8affe9d095fc100a2c2543524e9b08' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Digital Marketing Specialist', 'full_time', 'wfo', 'Malang', 'Rp6-8 juta', 2, 0,
      '2026-10-08', 'Merencanakan konten dan kampanye digital untuk menaikkan penjualan. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Media sosial
- Bersedia bekerja shift
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Media sosial, SEO, Canva', 'dummy-de272a5b62088ec85234.jpg', 'de272a5b62088ec852341d8aae5986ed', 'ditutup',
      '2026-09-28'::timestamp + time '09:00', '2026-09-28'::timestamp + time '09:00', '2026-09-28'::timestamp + time '09:00',
      '2026-09-28'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Nusantara Teknologi Cerdas' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'de272a5b62088ec852341d8aae5986ed' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'de272a5b62088ec852341d8aae5986ed' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Quantity Surveyor', 'full_time', 'wfo', 'Jakarta', 'Rp4,5-10 juta', 2, 0,
      '2027-02-02', 'Menghitung volume pekerjaan dan menyusun rencana anggaran biaya proyek. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai RAB
- Mampu bekerja dalam tim
- Memiliki laptop pribadi
- IPK minimal 3,00', 'RAB, Microsoft Excel, AutoCAD', 'dummy-8f6fabba492599046413.jpg', '8f6fabba492599046413709bf53456c5', 'aktif',
      '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00',
      '2026-10-27'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Adhi Karya Tbk' AND b.nama = 'Konstruksi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '8f6fabba492599046413709bf53456c5' AND jr.nama = 'Teknik Sipil' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Surveyor Pengukuran', 'full_time', 'wfo', 'Jakarta', 'Rp5-10 juta', 2, 0,
      '2026-12-11', 'Melakukan pengukuran topografi dan stake out di lokasi proyek. Penempatan di Jakarta.', '- Fresh graduate dipersilakan melamar
- Menguasai Total station
- Berpengalaman magang di bidang terkait (nilai tambah)
- Bersedia bekerja shift
- IPK minimal 3,00', 'Total station, GPS geodetik, AutoCAD', 'dummy-c6eaf70d241962d8f18e.jpg', 'c6eaf70d241962d8f18e4e031170fb10', 'aktif',
      '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00',
      '2026-10-21'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Adhi Karya Tbk' AND b.nama = 'Konstruksi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'c6eaf70d241962d8f18e4e031170fb10' AND jr.nama = 'Teknik Sipil' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Teknisi Panel Surya', 'magang', 'wfo', 'Jakarta', 'Uang saku Rp1.500.000', 4, 0,
      '2026-10-20', 'Memasang dan merawat sistem pembangkit listrik tenaga surya atap. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai PLTS
- Memiliki laptop pribadi
- Komunikatif dan teliti
- Bersedia bekerja shift', 'PLTS, Inverter, K3', 'dummy-ee757c126250fd1714ff.jpg', 'ee757c126250fd1714ff8a85449ed945', 'ditutup',
      '2026-10-15'::timestamp + time '09:00', '2026-10-15'::timestamp + time '09:00', '2026-10-15'::timestamp + time '09:00',
      '2026-10-15'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Adhi Karya Tbk' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'ee757c126250fd1714ff8a85449ed945' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'ee757c126250fd1714ff8a85449ed945' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Teknisi Instrumentasi', 'full_time', 'wfo', 'Jakarta', 'Rp4,5-12 juta', 2, 0,
      '2027-02-10', 'Merawat dan mengkalibrasi instrumen kontrol di area produksi. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai PLC
- Memiliki laptop pribadi
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)', 'PLC, SCADA, Kalibrasi', 'dummy-da9603e549ad5f93153f.jpg', 'da9603e549ad5f93153f6685d4f30e8b', 'aktif',
      '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00',
      '2026-10-19'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Adhi Karya Tbk' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'da9603e549ad5f93153f6685d4f30e8b' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'da9603e549ad5f93153f6685d4f30e8b' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Drafter Elektrikal', 'full_time', 'wfo', 'Jakarta', 'Rp4,5-7 juta', 3, 0,
      '2027-02-14', 'Membuat gambar instalasi listrik dan diagram satu garis proyek. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai AutoCAD Electrical
- Bersedia bekerja shift
- Berpengalaman magang di bidang terkait (nilai tambah)
- IPK minimal 3,00', 'AutoCAD Electrical, Single line diagram', 'dummy-3647b1a62ea158273f88.jpg', '3647b1a62ea158273f88de1361f04a1f', 'aktif',
      '2026-10-22'::timestamp + time '09:00', '2026-10-22'::timestamp + time '09:00', '2026-10-22'::timestamp + time '09:00',
      '2026-10-22'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Adhi Karya Tbk' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '3647b1a62ea158273f88de1361f04a1f' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '3647b1a62ea158273f88de1361f04a1f' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Junior Web Developer', 'kontrak', 'hybrid', 'Malang', 'Rp6-9 juta', 3, 0,
      '2027-02-12', 'Membangun dan memelihara aplikasi web internal maupun klien, bekerja dalam tim agile bersama desainer dan QA. Penempatan di Malang.', '- Fresh graduate dipersilakan melamar
- Menguasai PHP
- Mampu bekerja dalam tim
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)', 'PHP, Laravel, JavaScript, PostgreSQL', 'dummy-0048b7f089491e8290c6.jpg', '0048b7f089491e8290c6c65453bbc65a', 'menunggu',
      '2026-09-27'::timestamp + time '09:00', '2026-09-27'::timestamp + time '09:00', '2026-09-27'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Sinergi Data Nusantara' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '0048b7f089491e8290c6c65453bbc65a' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '0048b7f089491e8290c6c65453bbc65a' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Backend Developer', 'full_time', 'wfo', 'Malang', 'Rp6-10 juta', 8, 0,
      '2027-01-16', 'Merancang API dan basis data yang andal, aman, dan siap menangani banyak pengguna. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Node.js
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)
- Mampu bekerja dalam tim', 'Node.js, PHP, PostgreSQL, Docker', 'dummy-3c30e73f072fca0ad93f.jpg', '3c30e73f072fca0ad93fe0000e782f15', 'aktif',
      '2026-10-07'::timestamp + time '09:00', '2026-10-07'::timestamp + time '09:00', '2026-10-07'::timestamp + time '09:00',
      '2026-10-07'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Sinergi Data Nusantara' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '3c30e73f072fca0ad93fe0000e782f15' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '3c30e73f072fca0ad93fe0000e782f15' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'UI/UX Designer', 'full_time', 'wfo', 'Malang', 'Rp5-7 juta', 2, 0,
      '2026-10-13', 'Merancang alur pengguna, wireframe, dan prototipe yang mudah dipakai untuk produk digital perusahaan. Penempatan di Malang.', '- Fresh graduate dipersilakan melamar
- Menguasai Figma
- Mampu bekerja dalam tim
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Figma, UI/UX Design, Prototyping', 'dummy-b5813b1cb3ccb4a511e5.jpg', 'b5813b1cb3ccb4a511e57494a21cb7fc', 'ditutup',
      '2026-10-20'::timestamp + time '09:00', '2026-10-20'::timestamp + time '09:00', '2026-10-20'::timestamp + time '09:00',
      '2026-10-20'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Sinergi Data Nusantara' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'b5813b1cb3ccb4a511e57494a21cb7fc' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'b5813b1cb3ccb4a511e57494a21cb7fc' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Rekam Arsip Digital', 'kontrak', 'wfo', 'Malang', 'Rp7-10 juta', 8, 0,
      '2027-01-11', 'Memindai dan mengindeks dokumen klien ke sistem arsip digital. Penempatan di Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Pengarsipan digital
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)
- Mampu bekerja dalam tim', 'Pengarsipan digital, Ketelitian', 'dummy-fa72e008b56da127ba4e.jpg', 'fa72e008b56da127ba4ea960c1bf0595', 'aktif',
      '2026-10-01'::timestamp + time '09:00', '2026-10-01'::timestamp + time '09:00', '2026-10-01'::timestamp + time '09:00',
      '2026-10-01'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Sinergi Data Nusantara' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'fa72e008b56da127ba4ea960c1bf0595' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'fa72e008b56da127ba4ea960c1bf0595' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'IT Support', 'full_time', 'wfo', 'Surabaya', 'Rp4-9 juta', 8, 0,
      '2026-12-29', 'Membantu pengguna internal menangani masalah perangkat keras, perangkat lunak, dan jaringan. Penempatan di Surabaya.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Troubleshooting
- IPK minimal 3,00
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Troubleshooting, Windows, Jaringan dasar', 'dummy-d8bf40a478569ad976e2.jpg', 'd8bf40a478569ad976e27b81eb50f3aa', 'aktif',
      '2026-10-24'::timestamp + time '09:00', '2026-10-24'::timestamp + time '09:00', '2026-10-24'::timestamp + time '09:00',
      '2026-10-24'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Sinergi Data Nusantara' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'd8bf40a478569ad976e27b81eb50f3aa' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'd8bf40a478569ad976e27b81eb50f3aa' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Sales Executive', 'kontrak', 'wfo', 'Malang', 'Rp4,5-8 juta', 4, 0,
      '2026-10-21', 'Mencari pelanggan baru dan menjaga hubungan baik dengan pelanggan lama. Penempatan di Malang.', '- Fresh graduate dipersilakan melamar
- Menguasai Negosiasi
- Komunikatif dan teliti
- Berpengalaman magang di bidang terkait (nilai tambah)
- Bersedia bekerja shift', 'Negosiasi, Komunikasi, Presentasi', 'dummy-8048effa1209ee153760.jpg', '8048effa1209ee1537601693af40c544', 'ditutup',
      '2026-10-09'::timestamp + time '09:00', '2026-10-09'::timestamp + time '09:00', '2026-10-09'::timestamp + time '09:00',
      '2026-10-09'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Sinergi Data Nusantara' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '8048effa1209ee1537601693af40c544' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '8048effa1209ee1537601693af40c544' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Frontend Developer', 'full_time', 'wfo', 'Sidoarjo', 'Rp6-10 juta', 4, 0,
      '2027-01-31', 'Mengubah desain menjadi antarmuka web yang cepat, responsif, dan mudah diakses. Penempatan di Sidoarjo.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai HTML
- Memiliki laptop pribadi
- Mampu bekerja dalam tim
- IPK minimal 3,00', 'HTML, CSS, JavaScript, React', 'dummy-51a29d123f2bcd4fcaac.jpg', '51a29d123f2bcd4fcaace23c8b12413b', 'aktif',
      '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00', '2026-10-27'::timestamp + time '09:00',
      '2026-10-27'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Sinergi Data Nusantara' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '51a29d123f2bcd4fcaace23c8b12413b' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '51a29d123f2bcd4fcaace23c8b12413b' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Magang Staf Administrasi', 'magang', 'wfo', 'Surabaya', 'Uang saku Rp1.500.000', 1, 0,
      '2027-01-28', 'Mengelola surat-menyurat, arsip, dan administrasi operasional kantor. Penempatan di Surabaya.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Microsoft Office
- Memiliki laptop pribadi
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Microsoft Office, Kearsipan', 'dummy-f416348c39204fb3f3d7.jpg', 'f416348c39204fb3f3d7179bd947c5ea', 'aktif',
      '2026-09-28'::timestamp + time '09:00', '2026-09-28'::timestamp + time '09:00', '2026-09-28'::timestamp + time '09:00',
      '2026-09-28'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Sinergi Data Nusantara' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'f416348c39204fb3f3d7179bd947c5ea' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'f416348c39204fb3f3d7179bd947c5ea' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'IT Support', 'full_time', 'wfo', 'Jakarta', 'Rp5,5-10 juta', 10, 0,
      '2027-01-01', 'Membantu pengguna internal menangani masalah perangkat keras, perangkat lunak, dan jaringan. Penempatan di Jakarta.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Troubleshooting
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)
- IPK minimal 3,00', 'Troubleshooting, Windows, Jaringan dasar', 'dummy-1e0badcba35a0a4e6b66.jpg', '1e0badcba35a0a4e6b66f03f5a4f228f', 'menunggu',
      '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Mitra Arsip Nusantara' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '1e0badcba35a0a4e6b66f03f5a4f228f' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '1e0badcba35a0a4e6b66f03f5a4f228f' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Customer Relationship Staff', 'full_time', 'wfo', 'Surabaya', 'Rp5,5-8 juta', 3, 0,
      '2027-02-04', 'Menangani pertanyaan dan keluhan pelanggan lewat telepon, email, dan chat. Penempatan di Surabaya.', '- Fresh graduate dipersilakan melamar
- Menguasai Komunikasi
- Berpengalaman magang di bidang terkait (nilai tambah)
- Komunikatif dan teliti
- Memiliki laptop pribadi', 'Komunikasi, CRM', 'dummy-1f3b241a7149355318ce.jpg', '1f3b241a7149355318ce96dd51d8bb3a', 'aktif',
      '2026-10-02'::timestamp + time '09:00', '2026-10-02'::timestamp + time '09:00', '2026-10-02'::timestamp + time '09:00',
      '2026-10-02'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Mitra Arsip Nusantara' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '1f3b241a7149355318ce96dd51d8bb3a' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '1f3b241a7149355318ce96dd51d8bb3a' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Quality Assurance Engineer', 'full_time', 'wfh', 'Surabaya', 'Rp5,5-9 juta', 2, 0,
      '2027-01-06', 'Menyusun skenario uji, menjalankan pengujian fungsional dan regresi, serta mendokumentasikan bug. Penempatan di Surabaya.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Testing manual
- Berpengalaman magang di bidang terkait (nilai tambah)
- Memiliki laptop pribadi
- Mampu bekerja dalam tim', 'Testing manual, Postman, Selenium', 'dummy-c766a85036c9fa6922bd.jpg', 'c766a85036c9fa6922bd358e0f7143c9', 'aktif',
      '2026-09-24'::timestamp + time '09:00', '2026-09-24'::timestamp + time '09:00', '2026-09-24'::timestamp + time '09:00',
      '2026-09-24'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Mitra Arsip Nusantara' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'c766a85036c9fa6922bd358e0f7143c9' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'c766a85036c9fa6922bd358e0f7143c9' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Frontend Developer', 'part_time', 'hybrid', 'Surabaya', 'Rp6-8 juta', 3, 0,
      '2026-12-26', 'Mengubah desain menjadi antarmuka web yang cepat, responsif, dan mudah diakses. Penempatan di Surabaya.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai HTML
- IPK minimal 3,00
- Komunikatif dan teliti
- Mampu bekerja dalam tim', 'HTML, CSS, JavaScript, React', 'dummy-b9e5a462ef875131fc70.jpg', 'b9e5a462ef875131fc704831f4013d67', 'menunggu',
      '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00', '2026-10-06'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Mitra Arsip Nusantara' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'b9e5a462ef875131fc704831f4013d67' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'b9e5a462ef875131fc704831f4013d67' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Mobile Developer (Flutter)', 'kontrak', 'wfo', 'Surabaya', 'Rp4-7 juta', 2, 0,
      '2027-01-09', 'Mengembangkan aplikasi Android/iOS dari desain hingga rilis ke Play Store dan App Store. Penempatan di Surabaya.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Flutter
- Bersedia bekerja shift
- IPK minimal 3,00
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Flutter, Dart, REST API, Git', 'dummy-f4d9e31bf17d86de63f1.jpg', 'f4d9e31bf17d86de63f10f6c412d9c9d', 'aktif',
      '2026-10-07'::timestamp + time '09:00', '2026-10-07'::timestamp + time '09:00', '2026-10-07'::timestamp + time '09:00',
      '2026-10-07'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Mitra Arsip Nusantara' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'f4d9e31bf17d86de63f10f6c412d9c9d' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'f4d9e31bf17d86de63f10f6c412d9c9d' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Digital Marketing Specialist', 'kontrak', 'wfo', 'Surabaya', 'Rp4-9 juta', 2, 0,
      '2027-01-12', 'Merencanakan konten dan kampanye digital untuk menaikkan penjualan. Penempatan di Surabaya.', '- Fresh graduate dipersilakan melamar
- Menguasai Media sosial
- IPK minimal 3,00
- Komunikatif dan teliti
- Mampu bekerja dalam tim', 'Media sosial, SEO, Canva', 'dummy-07909daa683c419bd90e.jpg', '07909daa683c419bd90e4c40232e64bf', 'aktif',
      '2026-10-07'::timestamp + time '09:00', '2026-10-07'::timestamp + time '09:00', '2026-10-07'::timestamp + time '09:00',
      '2026-10-07'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Mitra Arsip Nusantara' AND b.nama = 'Perdagangan dan Jasa'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '07909daa683c419bd90e4c40232e64bf' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '07909daa683c419bd90e4c40232e64bf' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Network Engineer', 'full_time', 'wfo', 'Surabaya', 'Rp4-8 juta', 5, 0,
      '2027-01-15', 'Memasang, memantau, dan merawat jaringan kantor dan pusat data, termasuk penanganan gangguan. Penempatan di Surabaya.', '- Fresh graduate dipersilakan melamar
- Menguasai Mikrotik
- Bersedia bekerja shift
- Komunikatif dan teliti
- Berpengalaman magang di bidang terkait (nilai tambah)', 'Mikrotik, Cisco, Jaringan komputer', 'dummy-a97d63ffc355ab84f0db.jpg', 'a97d63ffc355ab84f0db4a1b98d726e5', 'aktif',
      '2026-09-29'::timestamp + time '09:00', '2026-09-29'::timestamp + time '09:00', '2026-09-29'::timestamp + time '09:00',
      '2026-09-29'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Mitra Arsip Nusantara' AND b.nama = 'Teknologi Informasi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'a97d63ffc355ab84f0db4a1b98d726e5' AND jr.nama = 'Teknologi Informasi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = 'a97d63ffc355ab84f0db4a1b98d726e5' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Staf Pajak', 'kontrak', 'wfo', 'Surabaya', 'Rp5-7 juta', 2, 0,
      '2026-12-04', 'Menghitung, melaporkan, dan mengarsipkan kewajiban pajak perusahaan. Penempatan di Surabaya.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai PPh
- Mampu bekerja dalam tim
- Memiliki laptop pribadi
- Berpengalaman magang di bidang terkait (nilai tambah)', 'PPh, PPN, e-Faktur', 'dummy-96309ac8ece2e263ceab.jpg', '96309ac8ece2e263ceab1cae7eb61ace', 'aktif',
      '2026-10-09'::timestamp + time '09:00', '2026-10-09'::timestamp + time '09:00', '2026-10-09'::timestamp + time '09:00',
      '2026-10-09'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Mitra Arsip Nusantara' AND b.nama = 'Keuangan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '96309ac8ece2e263ceab1cae7eb61ace' AND jr.nama = 'Akuntansi' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '96309ac8ece2e263ceab1cae7eb61ace' AND jr.nama = 'Administrasi Niaga' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Drafter Elektrikal', 'full_time', 'wfo', 'Sidoarjo', 'Rp4,5-10 juta', 3, 0,
      '2027-01-28', 'Membuat gambar instalasi listrik dan diagram satu garis proyek. Penempatan di Sidoarjo.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai AutoCAD Electrical
- Komunikatif dan teliti
- IPK minimal 3,00
- Mampu bekerja dalam tim', 'AutoCAD Electrical, Single line diagram', 'dummy-52a942932c2c4587fa32.jpg', '52a942932c2c4587fa32fd272a8a798a', 'aktif',
      '2026-09-25'::timestamp + time '09:00', '2026-09-25'::timestamp + time '09:00', '2026-09-25'::timestamp + time '09:00',
      '2026-09-25'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Energi Listrik Mandiri' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '52a942932c2c4587fa32fd272a8a798a' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '52a942932c2c4587fa32fd272a8a798a' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Welder (Juru Las)', 'full_time', 'wfo', 'Sidoarjo', 'Rp8-8 juta', 2, 0,
      '2027-01-30', 'Melakukan pengelasan konstruksi dan komponen sesuai prosedur WPS. Penempatan di Sidoarjo.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Las SMAW
- Mampu bekerja dalam tim
- Komunikatif dan teliti
- IPK minimal 3,00', 'Las SMAW, Las GTAW, Membaca gambar', 'dummy-26fc740f68b14c904a16.jpg', '26fc740f68b14c904a160936c611a816', 'aktif',
      '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00',
      '2026-10-19'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Energi Listrik Mandiri' AND b.nama = 'Manufaktur'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '26fc740f68b14c904a160936c611a816' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '26fc740f68b14c904a160936c611a816' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Quantity Surveyor', 'kontrak', 'wfo', 'Sidoarjo', 'Rp8-10 juta', 3, 0,
      '2026-12-08', 'Menghitung volume pekerjaan dan menyusun rencana anggaran biaya proyek. Penempatan di Sidoarjo.', '- Fresh graduate dipersilakan melamar
- Menguasai RAB
- Mampu bekerja dalam tim
- Berpengalaman magang di bidang terkait (nilai tambah)
- Bersedia bekerja shift', 'RAB, Microsoft Excel, AutoCAD', 'dummy-2e6a733edfc60719cd9a.jpg', '2e6a733edfc60719cd9a7980cdec2d75', 'aktif',
      '2026-09-23'::timestamp + time '09:00', '2026-09-23'::timestamp + time '09:00', '2026-09-23'::timestamp + time '09:00',
      '2026-09-23'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Energi Listrik Mandiri' AND b.nama = 'Konstruksi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '2e6a733edfc60719cd9a7980cdec2d75' AND jr.nama = 'Teknik Sipil' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Teknisi Listrik', 'full_time', 'wfo', 'Sidoarjo', 'Rp7-8 juta', 4, 0,
      '2027-02-13', 'Memasang dan merawat instalasi listrik gedung dan panel distribusi. Penempatan di Sidoarjo.', '- Fresh graduate dipersilakan melamar
- Menguasai Instalasi listrik
- IPK minimal 3,00
- Memiliki laptop pribadi
- Bersedia bekerja shift', 'Instalasi listrik, PLC, K3 listrik', 'dummy-2640ed7c76f7c27fb2f0.jpg', '2640ed7c76f7c27fb2f09fd582165ce0', 'menunggu',
      '2026-10-05'::timestamp + time '09:00', '2026-10-05'::timestamp + time '09:00', '2026-10-05'::timestamp + time '09:00',
      NULL, NULL
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Energi Listrik Mandiri' AND b.nama = 'Kelistrikan'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '2640ed7c76f7c27fb2f09fd582165ce0' AND jr.nama = 'Teknik Elektro' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '2640ed7c76f7c27fb2f09fd582165ce0' AND jr.nama = 'Teknik Mesin' ON CONFLICT DO NOTHING;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, 'Estimator Proyek', 'kontrak', 'wfo', 'Malang', 'Rp8-12 juta', 10, 0,
      '2027-02-04', 'Menyusun penawaran harga untuk tender proyek konstruksi. Penempatan di Malang.', '- Fresh graduate dipersilakan melamar
- Menguasai RAB
- Berpengalaman magang di bidang terkait (nilai tambah)
- Bersedia bekerja shift
- IPK minimal 3,00', 'RAB, Analisa harga satuan', 'dummy-553838440538a98d1fda.jpg', '553838440538a98d1fda4671cb9efb37', 'aktif',
      '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00',
      '2026-10-19'::timestamp + time '14:00', (SELECT id FROM admin ORDER BY id LIMIT 1)
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = 'PT Energi Listrik Mandiri' AND b.nama = 'Konstruksi'
    ON CONFLICT DO NOTHING;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = '553838440538a98d1fda4671cb9efb37' AND jr.nama = 'Teknik Sipil' ON CONFLICT DO NOTHING;
  -- Riwayat persetujuan untuk lowongan dummy
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    SELECT l.id, 'menunggu', 'diajukan', 'Lowongan diajukan perusahaan.', pr.pengguna_id, l.diajukan_pada
    FROM lowongan l JOIN perusahaan pr ON pr.id = l.perusahaan_id WHERE l.pamflet LIKE 'dummy-%';
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    SELECT l.id, 'aktif', 'disetujui', 'Disetujui dan ditayangkan.', (SELECT pengguna_id FROM admin ORDER BY id LIMIT 1), l.disetujui_pada
    FROM lowongan l WHERE l.pamflet LIKE 'dummy-%' AND l.disetujui_pada IS NOT NULL;
  RAISE NOTICE 'Lowongan dummy berhasil ditambahkan.';
END
$dummy$;

-- Lowongan bawaan (02-seed) yang masih memakai pamflet contoh diberi pamflet bergambar.
-- Batas lamaran lowongan bawaan yang sudah lewat padahal masih 'aktif' digeser ke depan,
-- supaya data demo tidak langsung tertutup otomatis.
UPDATE lowongan SET batas_lamaran = CURRENT_DATE + ((id % 45) + 15)
 WHERE status = 'aktif' AND batas_lamaran < CURRENT_DATE AND pamflet NOT LIKE 'dummy-%';

UPDATE lowongan SET pamflet = 'dummy-seed-2d25ec90f9f7a672.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Junior Web Developer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Astra Otoparts');
UPDATE lowongan SET pamflet = 'dummy-seed-37b6d7dd736c60d4.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Network Engineer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Telkom Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-419942d5443a751b.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Quality Control Staff' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Wilmar Nabati Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-7a608096d8f6b014.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Site Engineer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Nusantara Digital');
UPDATE lowongan SET pamflet = 'dummy-seed-918ddd3c17415b64.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Drafter Struktur' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Pindad');
UPDATE lowongan SET pamflet = 'dummy-seed-8468c1da968bcecc.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Teknisi Perawatan Mesin' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Semen Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-947535bc900f9ab0.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Operator Instrumentasi' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Bank Mandiri Tbk');
UPDATE lowongan SET pamflet = 'dummy-seed-47abe83d4de7ad34.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Staf Akuntansi' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Pertamina Patra Niaga');
UPDATE lowongan SET pamflet = 'dummy-seed-a55df6cd55119d2e.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Analis Keuangan' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Nusantara Digital');
UPDATE lowongan SET pamflet = 'dummy-seed-34fcbe6b1f72b1bf.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Digital Marketing Specialist' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Barata Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-de74f2fd8e7d12d1.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Staf Administrasi dan Kearsipan' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Nusantara Digital');
UPDATE lowongan SET pamflet = 'dummy-seed-f6795450b5498373.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Process Engineer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Adhi Karya Tbk');
UPDATE lowongan SET pamflet = 'dummy-seed-e94c44dfc5145caa.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Junior Programmer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Sinergi Data Nusantara');
UPDATE lowongan SET pamflet = 'dummy-seed-0e59dfef52317d8a.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Business Analyst' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Mitra Arsip Nusantara');
UPDATE lowongan SET pamflet = 'dummy-seed-031e0b70c6cfc70d.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Teknisi Kelistrikan' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Energi Listrik Mandiri');
UPDATE lowongan SET pamflet = 'dummy-seed-4366aee704cfd764.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Surveyor Pertambangan' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Astra Otoparts');
UPDATE lowongan SET pamflet = 'dummy-seed-3b17825396e536bc.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Maintenance Pesawat Udara' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Telkom Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-6d206fae011ed6c8.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Teknisi Otomotif Elektronik' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Wilmar Nabati Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-d38172f4e454d237.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Staf Pajak' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Gudang Garam Tbk');
UPDATE lowongan SET pamflet = 'dummy-seed-a59bdccbcdd79241.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Customer Relation Officer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Pindad');
UPDATE lowongan SET pamflet = 'dummy-seed-0c8b39b6bd6feeb8.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Junior Web Developer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Nusantara Digital');
UPDATE lowongan SET pamflet = 'dummy-seed-a564bdee071af04f.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Network Engineer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Bank Mandiri Tbk');
UPDATE lowongan SET pamflet = 'dummy-seed-449dc0733c0e9f6a.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Quality Control Staff' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Pertamina Patra Niaga');
UPDATE lowongan SET pamflet = 'dummy-seed-a6d2d4eb2ea0602d.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Site Engineer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Nestle Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-e9e387a6e9cb445b.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Drafter Struktur' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Barata Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-7392e515f1587e16.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Teknisi Perawatan Mesin' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Nusantara Teknologi Cerdas');
UPDATE lowongan SET pamflet = 'dummy-seed-9f76aa2636e25ec6.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Operator Instrumentasi' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Adhi Karya Tbk');
UPDATE lowongan SET pamflet = 'dummy-seed-cc9db75b6a24f3d5.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Staf Akuntansi' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Sinergi Data Nusantara');
UPDATE lowongan SET pamflet = 'dummy-seed-b1858883e88c0983.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Analis Keuangan' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Mitra Arsip Nusantara');
UPDATE lowongan SET pamflet = 'dummy-seed-926aa68a5dc25d28.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Digital Marketing Specialist' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Energi Listrik Mandiri');
UPDATE lowongan SET pamflet = 'dummy-seed-a87bf186bc091ec1.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Staf Administrasi dan Kearsipan' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Astra Otoparts');
UPDATE lowongan SET pamflet = 'dummy-seed-9aaca6661b90a0a4.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Process Engineer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Telkom Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-03800e5e1726fb92.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Junior Programmer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Wilmar Nabati Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-d5d88782d48c30d0.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Business Analyst' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Gudang Garam Tbk');
UPDATE lowongan SET pamflet = 'dummy-seed-6fc037451ac8aa54.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Teknisi Kelistrikan' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Pindad');
UPDATE lowongan SET pamflet = 'dummy-seed-3e6ae0d1b7d129c4.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Surveyor Pertambangan' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Nusantara Digital');
UPDATE lowongan SET pamflet = 'dummy-seed-b39b0dc27f1852bb.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Maintenance Pesawat Udara' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Bank Mandiri Tbk');
UPDATE lowongan SET pamflet = 'dummy-seed-516c58a080a07449.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Teknisi Otomotif Elektronik' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Pertamina Patra Niaga');
UPDATE lowongan SET pamflet = 'dummy-seed-91f36a9336389a37.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Staf Pajak' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Nestle Indonesia');
UPDATE lowongan SET pamflet = 'dummy-seed-e2eaa0e721768815.jpg' WHERE pamflet LIKE 'contoh-%' AND posisi = 'Customer Relation Officer' AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = 'PT Barata Indonesia');

-- ---------------------------------------------------------------------
-- Akun perusahaan milik pemilik proyek: ringga.perusahaan@karirku.id / sandi: ringga123
-- (GANTI kata sandinya setelah masuk). Lowongan + pelamar sudah terisi,
-- supaya daftar pelamar & detail pelamar langsung bisa dicoba.
-- ---------------------------------------------------------------------
-- Perbaikan dari versi sebelumnya: perusahaan dummy "PT Ringga Karya Digital" yang
-- terlanjur menempel pada akun BUKAN perusahaan (mis. akun mahasiswa ringga@gmail.com
-- yang sudah ada) dilepas lagi. Akun aslinya tidak diubah; hanya data dummy itu dihapus.
DELETE FROM perusahaan pr USING pengguna p
 WHERE p.id = pr.pengguna_id AND pr.nama_perusahaan = 'PT Ringga Karya Digital' AND p.role <> 'perusahaan';
DELETE FROM perusahaan pr USING pengguna p
 WHERE p.id = pr.pengguna_id AND pr.nama_perusahaan = 'PT Ringga Karya Digital' AND p.email = 'ringga@gmail.com'
   AND p.password_hash = '$2y$10$eVUAkMLdK3vn7WeAv8zDWuY3V27l45B3Ts/d.1D65gN8DJSEfUmIq';
DELETE FROM pengguna p WHERE p.email = 'ringga@gmail.com' AND p.role = 'perusahaan'
   AND p.password_hash = '$2y$10$eVUAkMLdK3vn7WeAv8zDWuY3V27l45B3Ts/d.1D65gN8DJSEfUmIq'
   AND NOT EXISTS (SELECT 1 FROM perusahaan x WHERE x.pengguna_id = p.id);

UPDATE perusahaan SET logo = 'dummy-emblem-19.png' WHERE nama_perusahaan = 'PT Ringga Karya Digital' AND (logo IS NULL OR logo LIKE 'dummy-logo-%');

INSERT INTO pengguna (email, password_hash, role, status_akun)
  VALUES ('ringga.perusahaan@karirku.id', '$2y$10$eVUAkMLdK3vn7WeAv8zDWuY3V27l45B3Ts/d.1D65gN8DJSEfUmIq', 'perusahaan', 'aktif')
  ON CONFLICT (email) DO NOTHING;
INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, website, nama_pic, jabatan_pic,
                        whatsapp_pic, logo, deskripsi, bukan_outsourcing, provinsi, kode_pos)
  SELECT p.id, 'PT Ringga Karya Digital', 'Teknologi Informasi', 'Swasta nasional', 'Jl. Soekarno Hatta No. 9', 'Kota Malang', 'https://contoh.id',
         'Ringga Budi Utama', 'CEO', '081234567800', 'dummy-emblem-19.png',
         'Perusahaan pengembang aplikasi web dan mobile untuk UMKM dan instansi di Jawa Timur.', true, 'Jawa Timur', '65141'
  FROM pengguna p WHERE p.email = 'ringga.perusahaan@karirku.id' AND p.role = 'perusahaan'
    AND NOT EXISTS (SELECT 1 FROM perusahaan x WHERE x.pengguna_id = p.id);

DO $ringga$
DECLARE
  v_pr int; v_low int; v_mhs record; v_lam int; v_i int := 0; v_status text; v_tgl timestamp; v_admin int;
BEGIN
  SELECT pr.id INTO v_pr FROM perusahaan pr JOIN pengguna p ON p.id = pr.pengguna_id WHERE p.email = 'ringga.perusahaan@karirku.id';
  IF v_pr IS NULL OR EXISTS (SELECT 1 FROM lowongan WHERE perusahaan_id = v_pr) THEN
    RAISE NOTICE 'Data akun Ringga sudah ada, dilewati.';
    RETURN;
  END IF;
  SELECT pengguna_id INTO v_admin FROM admin ORDER BY id LIMIT 1;
  PERFORM setseed(0.27);
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi, batas_lamaran,
      deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada, diajukan_pada, disetujui_pada, disetujui_oleh)
    VALUES (v_pr, (SELECT id FROM bidang WHERE nama = 'Teknologi Informasi'), 'Junior Web Developer', 'full_time', 'hybrid', 'Malang',
      'Rp5-8 juta', 3, 0, '2026-11-27',
      'Membangun dan memelihara aplikasi web internal maupun klien, bekerja dalam tim agile bersama desainer dan QA. Penempatan di kantor Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai PHP
- Komunikatif dan teliti
- Mampu bekerja dalam tim', 'PHP, Laravel, JavaScript, PostgreSQL', 'dummy-6f7f0d95f69ef0105f66.jpg', '6f7f0d95f69ef0105f66df53c0f8677f', 'aktif',
      '2026-10-16'::timestamp + time '09:00', '2026-10-16'::timestamp + time '09:00', '2026-10-16'::timestamp + time '09:00',
      '2026-10-16'::timestamp + time '13:00', (SELECT id FROM admin ORDER BY id LIMIT 1))
    RETURNING id INTO v_low;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT v_low, id FROM jurusan WHERE nama IN ('Teknologi Informasi', 'Teknik Elektro');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'menunggu', 'diajukan', 'Lowongan diajukan perusahaan.', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), '2026-10-16'::timestamp + time '09:00');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'aktif', 'disetujui', 'Disetujui dan ditayangkan.', v_admin, '2026-10-16'::timestamp + time '13:00');
  -- Pelamar: mahasiswa/alumni aktif dipilih acak, status seleksi bervariasi
  FOR v_mhs IN
    SELECT m.*, p.email, ps.nama AS nama_prodi, ps.jenjang, j.nama AS nama_jurusan
      FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
      JOIN program_studi ps ON ps.id = m.program_studi_id JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE p.status_akun = 'aktif' AND m.file_ktm IS NOT NULL ORDER BY random() LIMIT 5
  LOOP
    v_i := v_i + 1;
    v_status := (ARRAY['diajukan','screening','screening','interview','interview','diterima','ditolak','diajukan'])[1 + (v_i % 8)];
    IF v_status = 'diterima' AND (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') >= 3 THEN v_status := 'interview'; END IF;
    v_tgl := '2026-10-16'::timestamp + ((v_i % 9) || ' days')::interval + ((8 + v_i % 9) || ' hours')::interval;
    INSERT INTO lamaran (mahasiswa_id, lowongan_id, tanggal_lamar, status, jenis_cv, file_cv, file_ktm, file_surat_pengantar, catatan_pelamar, snapshot_profil,
                         catatan_perusahaan, diperbarui_pada)
      VALUES (v_mhs.id, v_low, v_tgl, v_status, 'generate', COALESCE(v_mhs.file_cv, 'cv-sistem.pdf'), v_mhs.file_ktm, COALESCE(v_mhs.file_surat_pengantar, v_mhs.file_ktm),
        'Perkenalkan, saya ' || v_mhs.nama || ', ' || v_mhs.jenjang || ' ' || v_mhs.nama_prodi || '. Saya tertarik melamar posisi Junior Web Developer dan siap mengikuti seluruh proses seleksi.',
        json_build_object('nama', v_mhs.nama, 'nim', v_mhs.nim, 'email', v_mhs.email, 'no_whatsapp', v_mhs.no_whatsapp,
          'prodi', v_mhs.nama_prodi, 'jenjang', v_mhs.jenjang, 'jurusan', v_mhs.nama_jurusan, 'angkatan', v_mhs.angkatan,
          'status_mahasiswa', v_mhs.status_mahasiswa, 'tahun_lulus', v_mhs.tahun_lulus, 'ipk', v_mhs.ipk, 'domisili', v_mhs.domisili,
          'alamat', v_mhs.alamat, 'provinsi', v_mhs.provinsi,
          'skill', COALESCE((SELECT json_agg(s.nama ORDER BY s.nama) FROM mahasiswa_skill ms JOIN skill s ON s.id = ms.skill_id WHERE ms.mahasiswa_id = v_mhs.id), '[]'::json),
          'jenis_cv', 'generate', 'diambil_pada', to_char(v_tgl, 'YYYY-MM-DD HH24:MI:SS'))::jsonb,
        CASE WHEN v_status = 'ditolak' THEN 'Terima kasih, ' || v_mhs.nama || ', atas lamaran Anda. Saat ini kualifikasi Anda belum sesuai dengan kebutuhan kami.' END,
        v_tgl + interval '2 days')
      ON CONFLICT DO NOTHING RETURNING id INTO v_lam;
    CONTINUE WHEN v_lam IS NULL;
    INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal) VALUES (v_lam, 'diajukan', v_mhs.pengguna_id, 'Lamaran dikirim.', v_tgl);
    IF v_status <> 'diajukan' THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'screening', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'CV sedang ditinjau perusahaan.', v_tgl + interval '1 day');
    END IF;
    IF v_status IN ('interview', 'diterima') THEN
      INSERT INTO interview (lamaran_id, tanggal, jam, mode, lokasi_tautan, catatan, tempat, ruangan, dresscode, yang_dibawa, narahubung)
        VALUES (v_lam, CURRENT_DATE + (2 + v_i % 6), '09:00', CASE WHEN v_i % 2 = 0 THEN 'daring' ELSE 'luring' END,
          CASE WHEN v_i % 2 = 0 THEN 'https://meet.google.com/abc-defg-hij' ELSE 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END, 'Mohon hadir 10 menit sebelum jadwal.',
          CASE WHEN v_i % 2 = 1 THEN 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END,
          CASE WHEN v_i % 2 = 1 THEN 'Lantai 2, Ruang Meeting' END, 'Rapi dan sopan (kemeja berkerah)', 'KTM/KTP, CV cetak, portofolio',
          'Ringga Budi Utama (CEO), 081234567800');
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'interview', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'Dijadwalkan interview.', v_tgl + interval '2 days');
    END IF;
    IF v_status IN ('diterima', 'ditolak') THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, v_status, (SELECT pengguna_id FROM perusahaan WHERE id = v_pr),
                CASE WHEN v_status = 'ditolak' THEN 'Kualifikasi belum sesuai.' ELSE 'Selamat, Anda diterima.' END, v_tgl + interval '3 days');
    END IF;
  END LOOP;
  UPDATE lowongan SET terisi = (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') WHERE id = v_low;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi, batas_lamaran,
      deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada, diajukan_pada, disetujui_pada, disetujui_oleh)
    VALUES (v_pr, (SELECT id FROM bidang WHERE nama = 'Teknologi Informasi'), 'UI/UX Designer', 'full_time', 'wfo', 'Malang',
      'Rp5-8 juta', 2, 0, '2026-12-06',
      'Merancang alur pengguna, wireframe, dan prototipe yang mudah dipakai untuk produk digital perusahaan. Penempatan di kantor Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Figma
- Komunikatif dan teliti
- Mampu bekerja dalam tim', 'Figma, UI/UX Design, Prototyping', 'dummy-a1bf50eebbabc001708b.jpg', 'a1bf50eebbabc001708ba83a21bea423', 'aktif',
      '2026-10-17'::timestamp + time '09:00', '2026-10-17'::timestamp + time '09:00', '2026-10-17'::timestamp + time '09:00',
      '2026-10-17'::timestamp + time '13:00', (SELECT id FROM admin ORDER BY id LIMIT 1))
    RETURNING id INTO v_low;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT v_low, id FROM jurusan WHERE nama IN ('Teknologi Informasi', 'Teknik Elektro');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'menunggu', 'diajukan', 'Lowongan diajukan perusahaan.', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), '2026-10-17'::timestamp + time '09:00');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'aktif', 'disetujui', 'Disetujui dan ditayangkan.', v_admin, '2026-10-17'::timestamp + time '13:00');
  -- Pelamar: mahasiswa/alumni aktif dipilih acak, status seleksi bervariasi
  FOR v_mhs IN
    SELECT m.*, p.email, ps.nama AS nama_prodi, ps.jenjang, j.nama AS nama_jurusan
      FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
      JOIN program_studi ps ON ps.id = m.program_studi_id JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE p.status_akun = 'aktif' AND m.file_ktm IS NOT NULL ORDER BY random() LIMIT 8
  LOOP
    v_i := v_i + 1;
    v_status := (ARRAY['diajukan','screening','screening','interview','interview','diterima','ditolak','diajukan'])[1 + (v_i % 8)];
    IF v_status = 'diterima' AND (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') >= 2 THEN v_status := 'interview'; END IF;
    v_tgl := '2026-10-17'::timestamp + ((v_i % 9) || ' days')::interval + ((8 + v_i % 9) || ' hours')::interval;
    INSERT INTO lamaran (mahasiswa_id, lowongan_id, tanggal_lamar, status, jenis_cv, file_cv, file_ktm, file_surat_pengantar, catatan_pelamar, snapshot_profil,
                         catatan_perusahaan, diperbarui_pada)
      VALUES (v_mhs.id, v_low, v_tgl, v_status, 'generate', COALESCE(v_mhs.file_cv, 'cv-sistem.pdf'), v_mhs.file_ktm, COALESCE(v_mhs.file_surat_pengantar, v_mhs.file_ktm),
        'Perkenalkan, saya ' || v_mhs.nama || ', ' || v_mhs.jenjang || ' ' || v_mhs.nama_prodi || '. Saya tertarik melamar posisi UI/UX Designer dan siap mengikuti seluruh proses seleksi.',
        json_build_object('nama', v_mhs.nama, 'nim', v_mhs.nim, 'email', v_mhs.email, 'no_whatsapp', v_mhs.no_whatsapp,
          'prodi', v_mhs.nama_prodi, 'jenjang', v_mhs.jenjang, 'jurusan', v_mhs.nama_jurusan, 'angkatan', v_mhs.angkatan,
          'status_mahasiswa', v_mhs.status_mahasiswa, 'tahun_lulus', v_mhs.tahun_lulus, 'ipk', v_mhs.ipk, 'domisili', v_mhs.domisili,
          'alamat', v_mhs.alamat, 'provinsi', v_mhs.provinsi,
          'skill', COALESCE((SELECT json_agg(s.nama ORDER BY s.nama) FROM mahasiswa_skill ms JOIN skill s ON s.id = ms.skill_id WHERE ms.mahasiswa_id = v_mhs.id), '[]'::json),
          'jenis_cv', 'generate', 'diambil_pada', to_char(v_tgl, 'YYYY-MM-DD HH24:MI:SS'))::jsonb,
        CASE WHEN v_status = 'ditolak' THEN 'Terima kasih, ' || v_mhs.nama || ', atas lamaran Anda. Saat ini kualifikasi Anda belum sesuai dengan kebutuhan kami.' END,
        v_tgl + interval '2 days')
      ON CONFLICT DO NOTHING RETURNING id INTO v_lam;
    CONTINUE WHEN v_lam IS NULL;
    INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal) VALUES (v_lam, 'diajukan', v_mhs.pengguna_id, 'Lamaran dikirim.', v_tgl);
    IF v_status <> 'diajukan' THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'screening', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'CV sedang ditinjau perusahaan.', v_tgl + interval '1 day');
    END IF;
    IF v_status IN ('interview', 'diterima') THEN
      INSERT INTO interview (lamaran_id, tanggal, jam, mode, lokasi_tautan, catatan, tempat, ruangan, dresscode, yang_dibawa, narahubung)
        VALUES (v_lam, CURRENT_DATE + (2 + v_i % 6), '09:00', CASE WHEN v_i % 2 = 0 THEN 'daring' ELSE 'luring' END,
          CASE WHEN v_i % 2 = 0 THEN 'https://meet.google.com/abc-defg-hij' ELSE 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END, 'Mohon hadir 10 menit sebelum jadwal.',
          CASE WHEN v_i % 2 = 1 THEN 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END,
          CASE WHEN v_i % 2 = 1 THEN 'Lantai 2, Ruang Meeting' END, 'Rapi dan sopan (kemeja berkerah)', 'KTM/KTP, CV cetak, portofolio',
          'Ringga Budi Utama (CEO), 081234567800');
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'interview', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'Dijadwalkan interview.', v_tgl + interval '2 days');
    END IF;
    IF v_status IN ('diterima', 'ditolak') THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, v_status, (SELECT pengguna_id FROM perusahaan WHERE id = v_pr),
                CASE WHEN v_status = 'ditolak' THEN 'Kualifikasi belum sesuai.' ELSE 'Selamat, Anda diterima.' END, v_tgl + interval '3 days');
    END IF;
  END LOOP;
  UPDATE lowongan SET terisi = (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') WHERE id = v_low;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi, batas_lamaran,
      deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada, diajukan_pada, disetujui_pada, disetujui_oleh)
    VALUES (v_pr, (SELECT id FROM bidang WHERE nama = 'Teknologi Informasi'), 'Data Analyst', 'kontrak', 'hybrid', 'Malang',
      'Rp5-8 juta', 2, 0, '2026-12-15',
      'Mengolah data operasional menjadi dashboard dan laporan yang membantu pengambilan keputusan. Penempatan di kantor Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Python
- Komunikatif dan teliti
- Mampu bekerja dalam tim', 'Python, SQL, Microsoft Excel, Power BI', 'dummy-4469ea5bdc079f6a1d85.jpg', '4469ea5bdc079f6a1d853fa54dd2dd42', 'aktif',
      '2026-10-18'::timestamp + time '09:00', '2026-10-18'::timestamp + time '09:00', '2026-10-18'::timestamp + time '09:00',
      '2026-10-18'::timestamp + time '13:00', (SELECT id FROM admin ORDER BY id LIMIT 1))
    RETURNING id INTO v_low;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT v_low, id FROM jurusan WHERE nama IN ('Teknologi Informasi', 'Teknik Elektro');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'menunggu', 'diajukan', 'Lowongan diajukan perusahaan.', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), '2026-10-18'::timestamp + time '09:00');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'aktif', 'disetujui', 'Disetujui dan ditayangkan.', v_admin, '2026-10-18'::timestamp + time '13:00');
  -- Pelamar: mahasiswa/alumni aktif dipilih acak, status seleksi bervariasi
  FOR v_mhs IN
    SELECT m.*, p.email, ps.nama AS nama_prodi, ps.jenjang, j.nama AS nama_jurusan
      FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
      JOIN program_studi ps ON ps.id = m.program_studi_id JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE p.status_akun = 'aktif' AND m.file_ktm IS NOT NULL ORDER BY random() LIMIT 6
  LOOP
    v_i := v_i + 1;
    v_status := (ARRAY['diajukan','screening','screening','interview','interview','diterima','ditolak','diajukan'])[1 + (v_i % 8)];
    IF v_status = 'diterima' AND (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') >= 2 THEN v_status := 'interview'; END IF;
    v_tgl := '2026-10-18'::timestamp + ((v_i % 9) || ' days')::interval + ((8 + v_i % 9) || ' hours')::interval;
    INSERT INTO lamaran (mahasiswa_id, lowongan_id, tanggal_lamar, status, jenis_cv, file_cv, file_ktm, file_surat_pengantar, catatan_pelamar, snapshot_profil,
                         catatan_perusahaan, diperbarui_pada)
      VALUES (v_mhs.id, v_low, v_tgl, v_status, 'generate', COALESCE(v_mhs.file_cv, 'cv-sistem.pdf'), v_mhs.file_ktm, COALESCE(v_mhs.file_surat_pengantar, v_mhs.file_ktm),
        'Perkenalkan, saya ' || v_mhs.nama || ', ' || v_mhs.jenjang || ' ' || v_mhs.nama_prodi || '. Saya tertarik melamar posisi Data Analyst dan siap mengikuti seluruh proses seleksi.',
        json_build_object('nama', v_mhs.nama, 'nim', v_mhs.nim, 'email', v_mhs.email, 'no_whatsapp', v_mhs.no_whatsapp,
          'prodi', v_mhs.nama_prodi, 'jenjang', v_mhs.jenjang, 'jurusan', v_mhs.nama_jurusan, 'angkatan', v_mhs.angkatan,
          'status_mahasiswa', v_mhs.status_mahasiswa, 'tahun_lulus', v_mhs.tahun_lulus, 'ipk', v_mhs.ipk, 'domisili', v_mhs.domisili,
          'alamat', v_mhs.alamat, 'provinsi', v_mhs.provinsi,
          'skill', COALESCE((SELECT json_agg(s.nama ORDER BY s.nama) FROM mahasiswa_skill ms JOIN skill s ON s.id = ms.skill_id WHERE ms.mahasiswa_id = v_mhs.id), '[]'::json),
          'jenis_cv', 'generate', 'diambil_pada', to_char(v_tgl, 'YYYY-MM-DD HH24:MI:SS'))::jsonb,
        CASE WHEN v_status = 'ditolak' THEN 'Terima kasih, ' || v_mhs.nama || ', atas lamaran Anda. Saat ini kualifikasi Anda belum sesuai dengan kebutuhan kami.' END,
        v_tgl + interval '2 days')
      ON CONFLICT DO NOTHING RETURNING id INTO v_lam;
    CONTINUE WHEN v_lam IS NULL;
    INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal) VALUES (v_lam, 'diajukan', v_mhs.pengguna_id, 'Lamaran dikirim.', v_tgl);
    IF v_status <> 'diajukan' THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'screening', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'CV sedang ditinjau perusahaan.', v_tgl + interval '1 day');
    END IF;
    IF v_status IN ('interview', 'diterima') THEN
      INSERT INTO interview (lamaran_id, tanggal, jam, mode, lokasi_tautan, catatan, tempat, ruangan, dresscode, yang_dibawa, narahubung)
        VALUES (v_lam, CURRENT_DATE + (2 + v_i % 6), '09:00', CASE WHEN v_i % 2 = 0 THEN 'daring' ELSE 'luring' END,
          CASE WHEN v_i % 2 = 0 THEN 'https://meet.google.com/abc-defg-hij' ELSE 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END, 'Mohon hadir 10 menit sebelum jadwal.',
          CASE WHEN v_i % 2 = 1 THEN 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END,
          CASE WHEN v_i % 2 = 1 THEN 'Lantai 2, Ruang Meeting' END, 'Rapi dan sopan (kemeja berkerah)', 'KTM/KTP, CV cetak, portofolio',
          'Ringga Budi Utama (CEO), 081234567800');
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'interview', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'Dijadwalkan interview.', v_tgl + interval '2 days');
    END IF;
    IF v_status IN ('diterima', 'ditolak') THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, v_status, (SELECT pengguna_id FROM perusahaan WHERE id = v_pr),
                CASE WHEN v_status = 'ditolak' THEN 'Kualifikasi belum sesuai.' ELSE 'Selamat, Anda diterima.' END, v_tgl + interval '3 days');
    END IF;
  END LOOP;
  UPDATE lowongan SET terisi = (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') WHERE id = v_low;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi, batas_lamaran,
      deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada, diajukan_pada, disetujui_pada, disetujui_oleh)
    VALUES (v_pr, (SELECT id FROM bidang WHERE nama = 'Perdagangan dan Jasa'), 'Magang Digital Marketing Specialist', 'magang', 'wfo', 'Malang',
      'Uang saku Rp1.500.000', 4, 0, '2026-12-24',
      'Merencanakan konten dan kampanye digital untuk menaikkan penjualan. Penempatan di kantor Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Media sosial
- Komunikatif dan teliti
- Mampu bekerja dalam tim', 'Media sosial, SEO, Canva', 'dummy-bfdb448376f74ccf6edf.jpg', 'bfdb448376f74ccf6edf18cec33f3303', 'aktif',
      '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00', '2026-10-19'::timestamp + time '09:00',
      '2026-10-19'::timestamp + time '13:00', (SELECT id FROM admin ORDER BY id LIMIT 1))
    RETURNING id INTO v_low;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT v_low, id FROM jurusan WHERE nama IN ('Administrasi Niaga', 'Akuntansi');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'menunggu', 'diajukan', 'Lowongan diajukan perusahaan.', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), '2026-10-19'::timestamp + time '09:00');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'aktif', 'disetujui', 'Disetujui dan ditayangkan.', v_admin, '2026-10-19'::timestamp + time '13:00');
  -- Pelamar: mahasiswa/alumni aktif dipilih acak, status seleksi bervariasi
  FOR v_mhs IN
    SELECT m.*, p.email, ps.nama AS nama_prodi, ps.jenjang, j.nama AS nama_jurusan
      FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
      JOIN program_studi ps ON ps.id = m.program_studi_id JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE p.status_akun = 'aktif' AND m.file_ktm IS NOT NULL ORDER BY random() LIMIT 9
  LOOP
    v_i := v_i + 1;
    v_status := (ARRAY['diajukan','screening','screening','interview','interview','diterima','ditolak','diajukan'])[1 + (v_i % 8)];
    IF v_status = 'diterima' AND (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') >= 4 THEN v_status := 'interview'; END IF;
    v_tgl := '2026-10-19'::timestamp + ((v_i % 9) || ' days')::interval + ((8 + v_i % 9) || ' hours')::interval;
    INSERT INTO lamaran (mahasiswa_id, lowongan_id, tanggal_lamar, status, jenis_cv, file_cv, file_ktm, file_surat_pengantar, catatan_pelamar, snapshot_profil,
                         catatan_perusahaan, diperbarui_pada)
      VALUES (v_mhs.id, v_low, v_tgl, v_status, 'generate', COALESCE(v_mhs.file_cv, 'cv-sistem.pdf'), v_mhs.file_ktm, COALESCE(v_mhs.file_surat_pengantar, v_mhs.file_ktm),
        'Perkenalkan, saya ' || v_mhs.nama || ', ' || v_mhs.jenjang || ' ' || v_mhs.nama_prodi || '. Saya tertarik melamar posisi Magang Digital Marketing Specialist dan siap mengikuti seluruh proses seleksi.',
        json_build_object('nama', v_mhs.nama, 'nim', v_mhs.nim, 'email', v_mhs.email, 'no_whatsapp', v_mhs.no_whatsapp,
          'prodi', v_mhs.nama_prodi, 'jenjang', v_mhs.jenjang, 'jurusan', v_mhs.nama_jurusan, 'angkatan', v_mhs.angkatan,
          'status_mahasiswa', v_mhs.status_mahasiswa, 'tahun_lulus', v_mhs.tahun_lulus, 'ipk', v_mhs.ipk, 'domisili', v_mhs.domisili,
          'alamat', v_mhs.alamat, 'provinsi', v_mhs.provinsi,
          'skill', COALESCE((SELECT json_agg(s.nama ORDER BY s.nama) FROM mahasiswa_skill ms JOIN skill s ON s.id = ms.skill_id WHERE ms.mahasiswa_id = v_mhs.id), '[]'::json),
          'jenis_cv', 'generate', 'diambil_pada', to_char(v_tgl, 'YYYY-MM-DD HH24:MI:SS'))::jsonb,
        CASE WHEN v_status = 'ditolak' THEN 'Terima kasih, ' || v_mhs.nama || ', atas lamaran Anda. Saat ini kualifikasi Anda belum sesuai dengan kebutuhan kami.' END,
        v_tgl + interval '2 days')
      ON CONFLICT DO NOTHING RETURNING id INTO v_lam;
    CONTINUE WHEN v_lam IS NULL;
    INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal) VALUES (v_lam, 'diajukan', v_mhs.pengguna_id, 'Lamaran dikirim.', v_tgl);
    IF v_status <> 'diajukan' THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'screening', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'CV sedang ditinjau perusahaan.', v_tgl + interval '1 day');
    END IF;
    IF v_status IN ('interview', 'diterima') THEN
      INSERT INTO interview (lamaran_id, tanggal, jam, mode, lokasi_tautan, catatan, tempat, ruangan, dresscode, yang_dibawa, narahubung)
        VALUES (v_lam, CURRENT_DATE + (2 + v_i % 6), '09:00', CASE WHEN v_i % 2 = 0 THEN 'daring' ELSE 'luring' END,
          CASE WHEN v_i % 2 = 0 THEN 'https://meet.google.com/abc-defg-hij' ELSE 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END, 'Mohon hadir 10 menit sebelum jadwal.',
          CASE WHEN v_i % 2 = 1 THEN 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END,
          CASE WHEN v_i % 2 = 1 THEN 'Lantai 2, Ruang Meeting' END, 'Rapi dan sopan (kemeja berkerah)', 'KTM/KTP, CV cetak, portofolio',
          'Ringga Budi Utama (CEO), 081234567800');
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'interview', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'Dijadwalkan interview.', v_tgl + interval '2 days');
    END IF;
    IF v_status IN ('diterima', 'ditolak') THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, v_status, (SELECT pengguna_id FROM perusahaan WHERE id = v_pr),
                CASE WHEN v_status = 'ditolak' THEN 'Kualifikasi belum sesuai.' ELSE 'Selamat, Anda diterima.' END, v_tgl + interval '3 days');
    END IF;
  END LOOP;
  UPDATE lowongan SET terisi = (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') WHERE id = v_low;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi, batas_lamaran,
      deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada, diajukan_pada, disetujui_pada, disetujui_oleh)
    VALUES (v_pr, (SELECT id FROM bidang WHERE nama = 'Keuangan'), 'Staf Akuntansi', 'full_time', 'wfo', 'Malang',
      'Rp5-8 juta', 1, 0, '2027-01-02',
      'Mencatat transaksi, menyusun jurnal, dan membantu laporan keuangan bulanan. Penempatan di kantor Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Akuntansi keuangan
- Komunikatif dan teliti
- Mampu bekerja dalam tim', 'Akuntansi keuangan, Microsoft Excel, Accurate', 'dummy-5c173295d377908d776a.jpg', '5c173295d377908d776af5891ebce671', 'aktif',
      '2026-10-20'::timestamp + time '09:00', '2026-10-20'::timestamp + time '09:00', '2026-10-20'::timestamp + time '09:00',
      '2026-10-20'::timestamp + time '13:00', (SELECT id FROM admin ORDER BY id LIMIT 1))
    RETURNING id INTO v_low;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT v_low, id FROM jurusan WHERE nama IN ('Akuntansi', 'Administrasi Niaga');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'menunggu', 'diajukan', 'Lowongan diajukan perusahaan.', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), '2026-10-20'::timestamp + time '09:00');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'aktif', 'disetujui', 'Disetujui dan ditayangkan.', v_admin, '2026-10-20'::timestamp + time '13:00');
  -- Pelamar: mahasiswa/alumni aktif dipilih acak, status seleksi bervariasi
  FOR v_mhs IN
    SELECT m.*, p.email, ps.nama AS nama_prodi, ps.jenjang, j.nama AS nama_jurusan
      FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
      JOIN program_studi ps ON ps.id = m.program_studi_id JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE p.status_akun = 'aktif' AND m.file_ktm IS NOT NULL ORDER BY random() LIMIT 7
  LOOP
    v_i := v_i + 1;
    v_status := (ARRAY['diajukan','screening','screening','interview','interview','diterima','ditolak','diajukan'])[1 + (v_i % 8)];
    IF v_status = 'diterima' AND (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') >= 1 THEN v_status := 'interview'; END IF;
    v_tgl := '2026-10-20'::timestamp + ((v_i % 9) || ' days')::interval + ((8 + v_i % 9) || ' hours')::interval;
    INSERT INTO lamaran (mahasiswa_id, lowongan_id, tanggal_lamar, status, jenis_cv, file_cv, file_ktm, file_surat_pengantar, catatan_pelamar, snapshot_profil,
                         catatan_perusahaan, diperbarui_pada)
      VALUES (v_mhs.id, v_low, v_tgl, v_status, 'generate', COALESCE(v_mhs.file_cv, 'cv-sistem.pdf'), v_mhs.file_ktm, COALESCE(v_mhs.file_surat_pengantar, v_mhs.file_ktm),
        'Perkenalkan, saya ' || v_mhs.nama || ', ' || v_mhs.jenjang || ' ' || v_mhs.nama_prodi || '. Saya tertarik melamar posisi Staf Akuntansi dan siap mengikuti seluruh proses seleksi.',
        json_build_object('nama', v_mhs.nama, 'nim', v_mhs.nim, 'email', v_mhs.email, 'no_whatsapp', v_mhs.no_whatsapp,
          'prodi', v_mhs.nama_prodi, 'jenjang', v_mhs.jenjang, 'jurusan', v_mhs.nama_jurusan, 'angkatan', v_mhs.angkatan,
          'status_mahasiswa', v_mhs.status_mahasiswa, 'tahun_lulus', v_mhs.tahun_lulus, 'ipk', v_mhs.ipk, 'domisili', v_mhs.domisili,
          'alamat', v_mhs.alamat, 'provinsi', v_mhs.provinsi,
          'skill', COALESCE((SELECT json_agg(s.nama ORDER BY s.nama) FROM mahasiswa_skill ms JOIN skill s ON s.id = ms.skill_id WHERE ms.mahasiswa_id = v_mhs.id), '[]'::json),
          'jenis_cv', 'generate', 'diambil_pada', to_char(v_tgl, 'YYYY-MM-DD HH24:MI:SS'))::jsonb,
        CASE WHEN v_status = 'ditolak' THEN 'Terima kasih, ' || v_mhs.nama || ', atas lamaran Anda. Saat ini kualifikasi Anda belum sesuai dengan kebutuhan kami.' END,
        v_tgl + interval '2 days')
      ON CONFLICT DO NOTHING RETURNING id INTO v_lam;
    CONTINUE WHEN v_lam IS NULL;
    INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal) VALUES (v_lam, 'diajukan', v_mhs.pengguna_id, 'Lamaran dikirim.', v_tgl);
    IF v_status <> 'diajukan' THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'screening', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'CV sedang ditinjau perusahaan.', v_tgl + interval '1 day');
    END IF;
    IF v_status IN ('interview', 'diterima') THEN
      INSERT INTO interview (lamaran_id, tanggal, jam, mode, lokasi_tautan, catatan, tempat, ruangan, dresscode, yang_dibawa, narahubung)
        VALUES (v_lam, CURRENT_DATE + (2 + v_i % 6), '09:00', CASE WHEN v_i % 2 = 0 THEN 'daring' ELSE 'luring' END,
          CASE WHEN v_i % 2 = 0 THEN 'https://meet.google.com/abc-defg-hij' ELSE 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END, 'Mohon hadir 10 menit sebelum jadwal.',
          CASE WHEN v_i % 2 = 1 THEN 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END,
          CASE WHEN v_i % 2 = 1 THEN 'Lantai 2, Ruang Meeting' END, 'Rapi dan sopan (kemeja berkerah)', 'KTM/KTP, CV cetak, portofolio',
          'Ringga Budi Utama (CEO), 081234567800');
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'interview', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'Dijadwalkan interview.', v_tgl + interval '2 days');
    END IF;
    IF v_status IN ('diterima', 'ditolak') THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, v_status, (SELECT pengguna_id FROM perusahaan WHERE id = v_pr),
                CASE WHEN v_status = 'ditolak' THEN 'Kualifikasi belum sesuai.' ELSE 'Selamat, Anda diterima.' END, v_tgl + interval '3 days');
    END IF;
  END LOOP;
  UPDATE lowongan SET terisi = (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') WHERE id = v_low;
  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi, batas_lamaran,
      deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada, diajukan_pada, disetujui_pada, disetujui_oleh)
    VALUES (v_pr, (SELECT id FROM bidang WHERE nama = 'Teknologi Informasi'), 'Backend Developer', 'full_time', 'wfh', 'Malang',
      'Rp5-8 juta', 2, 0, '2027-01-11',
      'Merancang API dan basis data yang andal, aman, dan siap menangani banyak pengguna. Penempatan di kantor Malang.', '- Lulusan D3/D4 Politeknik Negeri Malang
- Menguasai Node.js
- Komunikatif dan teliti
- Mampu bekerja dalam tim', 'Node.js, PHP, PostgreSQL, Docker', 'dummy-03769a2e1a68787772fa.jpg', '03769a2e1a68787772fab38bbab4806f', 'menunggu',
      '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00', '2026-10-21'::timestamp + time '09:00',
      NULL, NULL)
    RETURNING id INTO v_low;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT v_low, id FROM jurusan WHERE nama IN ('Teknologi Informasi', 'Teknik Elektro');
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'menunggu', 'diajukan', 'Lowongan diajukan perusahaan.', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), '2026-10-21'::timestamp + time '09:00');
  RAISE NOTICE 'Akun ringga.perusahaan@karirku.id berisi lowongan dan pelamar berhasil dibuat.';
END
$ringga$;


-- ---------------------------------------------------------------------
-- Profil lengkap untuk SEMUA mahasiswa/alumni dummy: foto, tentang, alamat,
-- pendidikan, pengalaman, sertifikat, portofolio, skill, dan bidang minat.
-- Hanya mengisi yang masih KOSONG, jadi isian yang sudah ada tidak ditimpa.
-- ---------------------------------------------------------------------
INSERT INTO skill (nama) VALUES ('AutoCAD'), ('Bahasa Inggris'), ('CSS'), ('Figma'), ('Git'), ('HTML'), ('JavaScript'), ('Kerja sama tim'), ('Komunikasi'), ('Laravel'), ('Manajemen waktu'), ('Microsoft Excel'), ('PHP'), ('PostgreSQL'), ('Python'), ('SolidWorks'), ('UI/UX Design') ON CONFLICT (nama) DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720001.png' WHERE nim = '2241720001' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Teknik Informatika Politeknik Negeri Malang angkatan 2022. Senang membangun aplikasi web yang rapi dan mudah dipakai. Terbiasa bekerja dalam tim dengan Git dan metode agile.' WHERE nim = '2241720001' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Diponegoro No. 178, RT 04/RW 12', provinsi = 'Jawa Timur', kode_pos = '65141' WHERE nim = '2241720001' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720001'), 'pendidikan', 'D-IV Teknik Informatika', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknologi Informasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720001') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknik Informatika') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720001'), 'pendidikan', 'Rekayasa Perangkat Lunak', 'SMK Negeri 4 Malang', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720001') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'pendidikan' AND x.judul = 'Rekayasa Perangkat Lunak') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720001'), 'pengalaman', 'Asisten Laboratorium Pemrograman', 'Politeknik Negeri Malang', '2024-02-03', '2024-06-28', 'Mendampingi praktikum pemrograman web untuk mahasiswa semester 1.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720001') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Pemrograman') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720001'), 'pengalaman', 'Magang Web Developer', 'PT Sinergi Data Nusantara', '2023-02-03', '2023-06-28', 'Membuat fitur dashboard admin dengan Laravel dan PostgreSQL.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720001') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Web Developer') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720001'), 'sertifikat', 'Junior Web Developer (BNSP)', 'LSP Politeknik Negeri Malang', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720001') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'sertifikat' AND x.judul = 'Junior Web Developer (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720001'), 'sertifikat', 'Dicoding: Belajar Dasar Pemrograman Web', 'Dicoding Indonesia', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720001') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'sertifikat' AND x.judul = 'Dicoding: Belajar Dasar Pemrograman Web') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720001'), 'portofolio', 'Aplikasi Kasir UMKM Berbasis Web', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/kasir-umkm', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720001') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'portofolio' AND x.judul = 'Aplikasi Kasir UMKM Berbasis Web') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720001.pdf' WHERE nim = '2241720001' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720001'), s.id FROM skill s WHERE s.nama IN ('Git', 'UI/UX Design', 'PHP', 'JavaScript', 'PostgreSQL', 'Python') AND (SELECT id FROM mahasiswa WHERE nim = '2241720001') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720001'), b.id FROM bidang b WHERE b.nama IN ('Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2241720001') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720001')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2441720010.png' WHERE nim = '2441720010' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Teknik Sipil Politeknik Negeri Malang angkatan 2024. Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.' WHERE nim = '2441720010' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Sumbersari No. 93, RT 06/RW 02', provinsi = 'Jawa Timur', kode_pos = '60111' WHERE nim = '2441720010' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720010'), 'pendidikan', 'D-III Teknik Sipil', 'Politeknik Negeri Malang', '2024-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Sipil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720010') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Sipil') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720010'), 'pendidikan', 'Desain Pemodelan dan Informasi Bangunan', 'SMK Negeri 1 Singosari', '2021-07-15', '2024-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720010') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'pendidikan' AND x.judul = 'Desain Pemodelan dan Informasi Bangunan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720010'), 'pengalaman', 'Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', '2025-02-03', '2025-06-28', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720010') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Pengawas Lapangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720010'), 'pengalaman', 'Drafter Paruh Waktu', 'CV Arta Konstruksi', '2024-02-03', '2024-06-28', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720010') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'pengalaman' AND x.judul = 'Drafter Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720010'), 'sertifikat', 'AutoCAD Certified User', 'Autodesk', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720010') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'sertifikat' AND x.judul = 'AutoCAD Certified User') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720010'), 'sertifikat', 'Ahli Muda Teknik Jalan (SKK)', 'LPJK', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720010') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'sertifikat' AND x.judul = 'Ahli Muda Teknik Jalan (SKK)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720010'), 'portofolio', 'Desain Struktur Gedung 3 Lantai', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-struktur', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720010') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'portofolio' AND x.judul = 'Desain Struktur Gedung 3 Lantai') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2441720010.pdf' WHERE nim = '2441720010' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720010'), s.id FROM skill s WHERE s.nama IN ('Komunikasi', 'AutoCAD', 'Kerja sama tim', 'Microsoft Excel', 'Manajemen waktu') AND (SELECT id FROM mahasiswa WHERE nim = '2441720010') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720010'), b.id FROM bidang b WHERE b.nama IN ('Konstruksi') AND (SELECT id FROM mahasiswa WHERE nim = '2441720010') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720010')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720011.png' WHERE nim = '2241720011' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air Politeknik Negeri Malang angkatan 2022. Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.' WHERE nim = '2241720011' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Sumbersari No. 153, RT 08/RW 04', provinsi = 'Jawa Timur', kode_pos = '67111' WHERE nim = '2241720011' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720011'), 'pendidikan', 'D-III Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Sipil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720011') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720011'), 'pendidikan', 'Desain Pemodelan dan Informasi Bangunan', 'SMK Negeri 1 Singosari', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720011') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'pendidikan' AND x.judul = 'Desain Pemodelan dan Informasi Bangunan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720011'), 'pengalaman', 'Drafter Paruh Waktu', 'CV Arta Konstruksi', '2024-02-03', '2024-06-28', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720011') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'pengalaman' AND x.judul = 'Drafter Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720011'), 'pengalaman', 'Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', '2023-02-03', '2023-06-28', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720011') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Pengawas Lapangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720011'), 'sertifikat', 'AutoCAD Certified User', 'Autodesk', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720011') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'sertifikat' AND x.judul = 'AutoCAD Certified User') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720011'), 'sertifikat', 'Ahli Muda Teknik Jalan (SKK)', 'LPJK', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720011') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'sertifikat' AND x.judul = 'Ahli Muda Teknik Jalan (SKK)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720011'), 'portofolio', 'Desain Struktur Gedung 3 Lantai', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-struktur', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720011') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'portofolio' AND x.judul = 'Desain Struktur Gedung 3 Lantai') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720011.pdf' WHERE nim = '2241720011' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720011'), s.id FROM skill s WHERE s.nama IN ('Kerja sama tim', 'Microsoft Excel', 'AutoCAD', 'Komunikasi', 'Manajemen waktu') AND (SELECT id FROM mahasiswa WHERE nim = '2241720011') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720011'), b.id FROM bidang b WHERE b.nama IN ('Konstruksi') AND (SELECT id FROM mahasiswa WHERE nim = '2241720011') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720011')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720012.png' WHERE nim = '2341720012' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Teknologi Pertambangan Politeknik Negeri Malang angkatan 2023. Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.' WHERE nim = '2341720012' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Kertoraharjo No. 97, RT 07/RW 05', provinsi = 'Jawa Timur', kode_pos = '64111' WHERE nim = '2341720012' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720012'), 'pendidikan', 'D-III Teknologi Pertambangan', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Sipil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720012') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknologi Pertambangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720012'), 'pendidikan', 'Desain Pemodelan dan Informasi Bangunan', 'SMK Negeri 1 Singosari', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720012') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'pendidikan' AND x.judul = 'Desain Pemodelan dan Informasi Bangunan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720012'), 'pengalaman', 'Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', '2025-02-03', '2025-06-28', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720012') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Pengawas Lapangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720012'), 'pengalaman', 'Drafter Paruh Waktu', 'CV Arta Konstruksi', '2024-02-03', '2024-06-28', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720012') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'pengalaman' AND x.judul = 'Drafter Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720012'), 'sertifikat', 'AutoCAD Certified User', 'Autodesk', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720012') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'sertifikat' AND x.judul = 'AutoCAD Certified User') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720012'), 'sertifikat', 'Ahli Muda Teknik Jalan (SKK)', 'LPJK', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720012') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'sertifikat' AND x.judul = 'Ahli Muda Teknik Jalan (SKK)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720012'), 'portofolio', 'Desain Struktur Gedung 3 Lantai', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-struktur', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720012') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'portofolio' AND x.judul = 'Desain Struktur Gedung 3 Lantai') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720012.pdf' WHERE nim = '2341720012' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720012'), s.id FROM skill s WHERE s.nama IN ('Microsoft Excel', 'Komunikasi', 'Manajemen waktu', 'AutoCAD', 'Kerja sama tim') AND (SELECT id FROM mahasiswa WHERE nim = '2341720012') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720012'), b.id FROM bidang b WHERE b.nama IN ('Konstruksi') AND (SELECT id FROM mahasiswa WHERE nim = '2341720012') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720012')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720013.png' WHERE nim = '2241720013' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Teknologi Rekayasa Konstruksi Jalan dan Jembatan Politeknik Negeri Malang angkatan 2022. Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.' WHERE nim = '2241720013' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Gajayana No. 157, RT 04/RW 06', provinsi = 'Jawa Timur', kode_pos = '65311' WHERE nim = '2241720013' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720013'), 'pendidikan', 'D-IV Teknologi Rekayasa Konstruksi Jalan dan Jembatan', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Sipil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720013') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknologi Rekayasa Konstruksi Jalan dan Jembatan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720013'), 'pendidikan', 'Desain Pemodelan dan Informasi Bangunan', 'SMK Negeri 1 Singosari', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720013') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'pendidikan' AND x.judul = 'Desain Pemodelan dan Informasi Bangunan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720013'), 'pengalaman', 'Drafter Paruh Waktu', 'CV Arta Konstruksi', '2024-02-03', '2024-06-28', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720013') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'pengalaman' AND x.judul = 'Drafter Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720013'), 'pengalaman', 'Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', '2023-02-03', '2023-06-28', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720013') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Pengawas Lapangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720013'), 'sertifikat', 'Ahli Muda Teknik Jalan (SKK)', 'LPJK', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720013') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'sertifikat' AND x.judul = 'Ahli Muda Teknik Jalan (SKK)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720013'), 'sertifikat', 'AutoCAD Certified User', 'Autodesk', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720013') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'sertifikat' AND x.judul = 'AutoCAD Certified User') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720013'), 'portofolio', 'Desain Struktur Gedung 3 Lantai', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-struktur', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720013') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'portofolio' AND x.judul = 'Desain Struktur Gedung 3 Lantai') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720013.pdf' WHERE nim = '2241720013' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720013'), s.id FROM skill s WHERE s.nama IN ('Microsoft Excel', 'AutoCAD', 'Manajemen waktu', 'Komunikasi') AND (SELECT id FROM mahasiswa WHERE nim = '2241720013') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720013'), b.id FROM bidang b WHERE b.nama IN ('Konstruksi') AND (SELECT id FROM mahasiswa WHERE nim = '2241720013') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720013')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2441720014.png' WHERE nim = '2441720014' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Manajemen Rekayasa Konstruksi Politeknik Negeri Malang angkatan 2024. Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.' WHERE nim = '2441720014' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Pahlawan No. 156, RT 08/RW 05', provinsi = 'Jawa Timur', kode_pos = '61311' WHERE nim = '2441720014' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720014'), 'pendidikan', 'D-IV Manajemen Rekayasa Konstruksi', 'Politeknik Negeri Malang', '2024-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Sipil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720014') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Manajemen Rekayasa Konstruksi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720014'), 'pendidikan', 'Desain Pemodelan dan Informasi Bangunan', 'SMK Negeri 1 Singosari', '2021-07-15', '2024-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720014') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'pendidikan' AND x.judul = 'Desain Pemodelan dan Informasi Bangunan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720014'), 'pengalaman', 'Drafter Paruh Waktu', 'CV Arta Konstruksi', '2025-02-03', '2025-06-28', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720014') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'pengalaman' AND x.judul = 'Drafter Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720014'), 'pengalaman', 'Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', '2024-02-03', '2024-06-28', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720014') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Pengawas Lapangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720014'), 'sertifikat', 'AutoCAD Certified User', 'Autodesk', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720014') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'sertifikat' AND x.judul = 'AutoCAD Certified User') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720014'), 'sertifikat', 'Ahli Muda Teknik Jalan (SKK)', 'LPJK', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720014') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'sertifikat' AND x.judul = 'Ahli Muda Teknik Jalan (SKK)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720014'), 'portofolio', 'Desain Struktur Gedung 3 Lantai', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-struktur', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720014') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'portofolio' AND x.judul = 'Desain Struktur Gedung 3 Lantai') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2441720014.pdf' WHERE nim = '2441720014' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720014'), s.id FROM skill s WHERE s.nama IN ('Manajemen waktu', 'AutoCAD', 'Kerja sama tim', 'Komunikasi') AND (SELECT id FROM mahasiswa WHERE nim = '2441720014') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720014'), b.id FROM bidang b WHERE b.nama IN ('Konstruksi') AND (SELECT id FROM mahasiswa WHERE nim = '2441720014') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720014')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720015.png' WHERE nim = '2341720015' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Teknik Mesin Politeknik Negeri Malang angkatan 2023. Menyukai dunia manufaktur dan perawatan mesin. Terbiasa membaca gambar teknik dan bekerja sesuai SOP K3.' WHERE nim = '2341720015' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Kawi No. 53, RT 09/RW 01', provinsi = 'Jawa Timur', kode_pos = '67111' WHERE nim = '2341720015' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720015'), 'pendidikan', 'D-III Teknik Mesin', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Mesin.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720015') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Mesin') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720015'), 'pendidikan', 'Teknik Pemesinan', 'SMK Negeri 6 Malang', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720015') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Pemesinan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720015'), 'pengalaman', 'Magang Maintenance Mesin', 'PT Barata Indonesia', '2025-02-03', '2025-06-28', 'Melakukan perawatan preventif mesin bubut dan frais.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720015') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Maintenance Mesin') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720015'), 'pengalaman', 'Asisten Bengkel Praktik', 'Politeknik Negeri Malang', '2024-02-03', '2024-06-28', 'Menyiapkan alat dan bahan praktikum pemesinan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720015') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Bengkel Praktik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720015'), 'sertifikat', 'Operator Mesin CNC (BNSP)', 'LSP Logam dan Mesin', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720015') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'sertifikat' AND x.judul = 'Operator Mesin CNC (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720015'), 'sertifikat', 'K3 Umum', 'Kemnaker RI', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720015') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'sertifikat' AND x.judul = 'K3 Umum') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720015'), 'portofolio', 'Rancang Bangun Alat Pengupas Kopi', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-alat', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720015') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'portofolio' AND x.judul = 'Rancang Bangun Alat Pengupas Kopi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720015.pdf' WHERE nim = '2341720015' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720015'), s.id FROM skill s WHERE s.nama IN ('AutoCAD', 'Microsoft Excel', 'Manajemen waktu', 'SolidWorks') AND (SELECT id FROM mahasiswa WHERE nim = '2341720015') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720015'), b.id FROM bidang b WHERE b.nama IN ('Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '2341720015') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720015')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720016.png' WHERE nim = '2241720016' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Teknologi Pemeliharaan Pesawat Udara Politeknik Negeri Malang angkatan 2022. Menyukai dunia manufaktur dan perawatan mesin. Terbiasa membaca gambar teknik dan bekerja sesuai SOP K3.' WHERE nim = '2241720016' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Merdeka No. 23, RT 06/RW 11', provinsi = 'Jawa Timur', kode_pos = '67311' WHERE nim = '2241720016' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720016'), 'pendidikan', 'D-III Teknologi Pemeliharaan Pesawat Udara', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Mesin.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720016') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknologi Pemeliharaan Pesawat Udara') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720016'), 'pendidikan', 'Teknik Pemesinan', 'SMK Negeri 6 Malang', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720016') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Pemesinan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720016'), 'pengalaman', 'Magang Maintenance Mesin', 'PT Barata Indonesia', '2024-02-03', '2024-06-28', 'Melakukan perawatan preventif mesin bubut dan frais.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720016') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Maintenance Mesin') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720016'), 'pengalaman', 'Asisten Bengkel Praktik', 'Politeknik Negeri Malang', '2023-02-03', '2023-06-28', 'Menyiapkan alat dan bahan praktikum pemesinan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720016') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Bengkel Praktik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720016'), 'sertifikat', 'K3 Umum', 'Kemnaker RI', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720016') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'sertifikat' AND x.judul = 'K3 Umum') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720016'), 'sertifikat', 'Operator Mesin CNC (BNSP)', 'LSP Logam dan Mesin', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720016') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'sertifikat' AND x.judul = 'Operator Mesin CNC (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720016'), 'portofolio', 'Rancang Bangun Alat Pengupas Kopi', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-alat', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720016') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'portofolio' AND x.judul = 'Rancang Bangun Alat Pengupas Kopi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720016.pdf' WHERE nim = '2241720016' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720016'), s.id FROM skill s WHERE s.nama IN ('Manajemen waktu', 'Kerja sama tim', 'Microsoft Excel', 'SolidWorks', 'AutoCAD') AND (SELECT id FROM mahasiswa WHERE nim = '2241720016') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720016'), b.id FROM bidang b WHERE b.nama IN ('Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '2241720016') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720016')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2441720017.png' WHERE nim = '2441720017' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Teknik Mesin Produksi dan Perawatan Politeknik Negeri Malang angkatan 2024. Menyukai dunia manufaktur dan perawatan mesin. Terbiasa membaca gambar teknik dan bekerja sesuai SOP K3.' WHERE nim = '2441720017' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Panglima Sudirman No. 90, RT 06/RW 05', provinsi = 'Jawa Timur', kode_pos = '61111' WHERE nim = '2441720017' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720017'), 'pendidikan', 'D-IV Teknik Mesin Produksi dan Perawatan', 'Politeknik Negeri Malang', '2024-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Mesin.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720017') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknik Mesin Produksi dan Perawatan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720017'), 'pendidikan', 'Teknik Pemesinan', 'SMK Negeri 6 Malang', '2021-07-15', '2024-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720017') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Pemesinan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720017'), 'pengalaman', 'Magang Maintenance Mesin', 'PT Barata Indonesia', '2025-02-03', '2025-06-28', 'Melakukan perawatan preventif mesin bubut dan frais.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720017') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Maintenance Mesin') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720017'), 'pengalaman', 'Asisten Bengkel Praktik', 'Politeknik Negeri Malang', '2024-02-03', '2024-06-28', 'Menyiapkan alat dan bahan praktikum pemesinan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720017') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Bengkel Praktik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720017'), 'sertifikat', 'Operator Mesin CNC (BNSP)', 'LSP Logam dan Mesin', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720017') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'sertifikat' AND x.judul = 'Operator Mesin CNC (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720017'), 'sertifikat', 'K3 Umum', 'Kemnaker RI', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720017') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'sertifikat' AND x.judul = 'K3 Umum') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720017'), 'portofolio', 'Rancang Bangun Alat Pengupas Kopi', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-alat', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720017') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'portofolio' AND x.judul = 'Rancang Bangun Alat Pengupas Kopi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2441720017.pdf' WHERE nim = '2441720017' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720017'), s.id FROM skill s WHERE s.nama IN ('Manajemen waktu', 'Microsoft Excel', 'AutoCAD', 'Kerja sama tim') AND (SELECT id FROM mahasiswa WHERE nim = '2441720017') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720017'), b.id FROM bidang b WHERE b.nama IN ('Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '2441720017') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720017')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720018.png' WHERE nim = '2341720018' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Teknik Otomotif Elektronik Politeknik Negeri Malang angkatan 2023. Menyukai dunia manufaktur dan perawatan mesin. Terbiasa membaca gambar teknik dan bekerja sesuai SOP K3.' WHERE nim = '2341720018' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Diponegoro No. 146, RT 09/RW 04', provinsi = 'Jawa Timur', kode_pos = '61311' WHERE nim = '2341720018' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720018'), 'pendidikan', 'D-IV Teknik Otomotif Elektronik', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Mesin.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720018') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknik Otomotif Elektronik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720018'), 'pendidikan', 'Teknik Pemesinan', 'SMK Negeri 6 Malang', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720018') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Pemesinan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720018'), 'pengalaman', 'Magang Maintenance Mesin', 'PT Barata Indonesia', '2025-02-03', '2025-06-28', 'Melakukan perawatan preventif mesin bubut dan frais.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720018') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Maintenance Mesin') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720018'), 'pengalaman', 'Asisten Bengkel Praktik', 'Politeknik Negeri Malang', '2024-02-03', '2024-06-28', 'Menyiapkan alat dan bahan praktikum pemesinan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720018') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Bengkel Praktik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720018'), 'sertifikat', 'Operator Mesin CNC (BNSP)', 'LSP Logam dan Mesin', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720018') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'sertifikat' AND x.judul = 'Operator Mesin CNC (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720018'), 'sertifikat', 'K3 Umum', 'Kemnaker RI', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720018') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'sertifikat' AND x.judul = 'K3 Umum') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720018'), 'portofolio', 'Rancang Bangun Alat Pengupas Kopi', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-alat', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720018') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'portofolio' AND x.judul = 'Rancang Bangun Alat Pengupas Kopi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720018.pdf' WHERE nim = '2341720018' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720018'), s.id FROM skill s WHERE s.nama IN ('AutoCAD', 'Kerja sama tim', 'Manajemen waktu', 'SolidWorks', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '2341720018') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720018'), b.id FROM bidang b WHERE b.nama IN ('Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '2341720018') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720018')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2441720019.png' WHERE nim = '2441720019' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Teknik Listrik Politeknik Negeri Malang angkatan 2024. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '2441720019' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Sumbersari No. 164, RT 01/RW 07', provinsi = 'Jawa Timur', kode_pos = '65311' WHERE nim = '2441720019' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720019'), 'pendidikan', 'D-III Teknik Listrik', 'Politeknik Negeri Malang', '2024-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720019') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720019'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2021-07-15', '2024-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720019') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720019'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2025-02-03', '2025-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720019') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720019'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2024-02-03', '2024-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720019') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720019'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720019') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720019'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720019') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720019'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720019') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2441720019.pdf' WHERE nim = '2441720019' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720019'), s.id FROM skill s WHERE s.nama IN ('Microsoft Excel', 'Komunikasi', 'Kerja sama tim', 'AutoCAD', 'Python') AND (SELECT id FROM mahasiswa WHERE nim = '2441720019') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720019'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2441720019') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720019')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720020.png' WHERE nim = '2241720020' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Teknik Elektronika Politeknik Negeri Malang angkatan 2022. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '2241720020' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Ijen No. 123, RT 07/RW 08', provinsi = 'Jawa Timur', kode_pos = '66211' WHERE nim = '2241720020' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720020'), 'pendidikan', 'D-III Teknik Elektronika', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720020') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Elektronika') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720020'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720020') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720020'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2024-02-03', '2024-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720020') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720020'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2023-02-03', '2023-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720020') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720020'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720020') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720020'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720020') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720020'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720020') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720020.pdf' WHERE nim = '2241720020' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720020'), s.id FROM skill s WHERE s.nama IN ('AutoCAD', 'Kerja sama tim', 'Python', 'Microsoft Excel', 'Komunikasi') AND (SELECT id FROM mahasiswa WHERE nim = '2241720020') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720020'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2241720020') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720020')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2441720021.png' WHERE nim = '2441720021' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Teknik Telekomunikasi Politeknik Negeri Malang angkatan 2024. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '2441720021' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Sumbersari No. 54, RT 06/RW 05', provinsi = 'Jawa Timur', kode_pos = '61211' WHERE nim = '2441720021' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720021'), 'pendidikan', 'D-III Teknik Telekomunikasi', 'Politeknik Negeri Malang', '2024-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720021') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Telekomunikasi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720021'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2021-07-15', '2024-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720021') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720021'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2025-02-03', '2025-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720021') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720021'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2024-02-03', '2024-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720021') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720021'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720021') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720021'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720021') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720021'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720021') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2441720021.pdf' WHERE nim = '2441720021' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720021'), s.id FROM skill s WHERE s.nama IN ('Microsoft Excel', 'Python', 'Kerja sama tim', 'Komunikasi', 'AutoCAD') AND (SELECT id FROM mahasiswa WHERE nim = '2441720021') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720021'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2441720021') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720021')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720022.png' WHERE nim = '2241720022' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Sistem Kelistrikan Politeknik Negeri Malang angkatan 2022. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '2241720022' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Kawi No. 152, RT 02/RW 10', provinsi = 'Jawa Timur', kode_pos = '66111' WHERE nim = '2241720022' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720022'), 'pendidikan', 'D-IV Sistem Kelistrikan', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720022') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Sistem Kelistrikan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720022'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720022') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720022'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2024-02-03', '2024-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720022') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720022'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2023-02-03', '2023-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720022') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720022'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720022') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720022'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720022') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720022'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720022') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720022.pdf' WHERE nim = '2241720022' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720022'), s.id FROM skill s WHERE s.nama IN ('Komunikasi', 'Microsoft Excel', 'Python', 'Kerja sama tim') AND (SELECT id FROM mahasiswa WHERE nim = '2241720022') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720022'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2241720022') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720022')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720023.png' WHERE nim = '2341720023' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Teknik Elektronika Politeknik Negeri Malang angkatan 2023. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '2341720023' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Panglima Sudirman No. 99, RT 05/RW 04', provinsi = 'Jawa Timur', kode_pos = '67211' WHERE nim = '2341720023' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720023'), 'pendidikan', 'D-IV Teknik Elektronika', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720023') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknik Elektronika') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720023'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720023') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720023'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2025-02-03', '2025-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720023') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720023'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2024-02-03', '2024-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720023') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720023'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720023') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720023'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720023') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720023'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720023') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720023.pdf' WHERE nim = '2341720023' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720023'), s.id FROM skill s WHERE s.nama IN ('Kerja sama tim', 'Microsoft Excel', 'AutoCAD', 'Python', 'Komunikasi') AND (SELECT id FROM mahasiswa WHERE nim = '2341720023') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720023'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2341720023') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720023')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720024.png' WHERE nim = '2241720024' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Jaringan Telekomunikasi Digital Politeknik Negeri Malang angkatan 2022. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '2241720024' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Soekarno Hatta No. 135, RT 08/RW 02', provinsi = 'Jawa Timur', kode_pos = '61211' WHERE nim = '2241720024' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720024'), 'pendidikan', 'D-IV Jaringan Telekomunikasi Digital', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720024') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Jaringan Telekomunikasi Digital') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720024'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720024') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720024'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2024-02-03', '2024-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720024') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720024'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2023-02-03', '2023-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720024') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720024'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720024') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720024'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720024') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720024'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720024') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720024.pdf' WHERE nim = '2241720024' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720024'), s.id FROM skill s WHERE s.nama IN ('Kerja sama tim', 'Komunikasi', 'AutoCAD', 'Python', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '2241720024') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720024'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2241720024') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720024')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720025.png' WHERE nim = '2241720025' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Teknik Kimia Politeknik Negeri Malang angkatan 2022. Teliti dan disiplin di laboratorium. Tertarik pada pengendalian mutu dan pengelolaan lingkungan industri.' WHERE nim = '2241720025' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Diponegoro No. 115, RT 02/RW 05', provinsi = 'Jawa Timur', kode_pos = '67111' WHERE nim = '2241720025' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720025'), 'pendidikan', 'D-III Teknik Kimia', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Kimia.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720025') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Kimia') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720025'), 'pendidikan', 'IPA', 'SMA Negeri 3 Malang', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720025') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'pendidikan' AND x.judul = 'IPA') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720025'), 'pengalaman', 'Magang Analis Laboratorium', 'PT Wilmar Nabati Indonesia', '2024-02-03', '2024-06-28', 'Menganalisis kadar asam lemak bebas dan kadar air bahan baku.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720025') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Analis Laboratorium') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720025'), 'pengalaman', 'Asisten Laboratorium Kimia Analitik', 'Politeknik Negeri Malang', '2023-02-03', '2023-06-28', 'Menyiapkan larutan standar dan membimbing praktikum.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720025') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Kimia Analitik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720025'), 'sertifikat', 'ISO 14001 Awareness', 'Lembaga Pelatihan Mutu', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720025') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'sertifikat' AND x.judul = 'ISO 14001 Awareness') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720025'), 'sertifikat', 'Analis Kimia Muda (BNSP)', 'LSP Kimia', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720025') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'sertifikat' AND x.judul = 'Analis Kimia Muda (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720025'), 'portofolio', 'Pengolahan Limbah Cair Tahu Skala Lab', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-limbah', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720025') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'portofolio' AND x.judul = 'Pengolahan Limbah Cair Tahu Skala Lab') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720025.pdf' WHERE nim = '2241720025' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720025'), s.id FROM skill s WHERE s.nama IN ('Manajemen waktu', 'Bahasa Inggris', 'Komunikasi', 'Kerja sama tim') AND (SELECT id FROM mahasiswa WHERE nim = '2241720025') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720025'), b.id FROM bidang b WHERE b.nama IN ('Kimia', 'Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '2241720025') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720025')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720026.png' WHERE nim = '2341720026' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Teknologi Kimia Industri Politeknik Negeri Malang angkatan 2023. Teliti dan disiplin di laboratorium. Tertarik pada pengendalian mutu dan pengelolaan lingkungan industri.' WHERE nim = '2341720026' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Panglima Sudirman No. 147, RT 04/RW 01', provinsi = 'Jawa Timur', kode_pos = '61311' WHERE nim = '2341720026' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720026'), 'pendidikan', 'D-IV Teknologi Kimia Industri', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Kimia.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720026') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknologi Kimia Industri') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720026'), 'pendidikan', 'IPA', 'SMA Negeri 3 Malang', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720026') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'pendidikan' AND x.judul = 'IPA') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720026'), 'pengalaman', 'Asisten Laboratorium Kimia Analitik', 'Politeknik Negeri Malang', '2025-02-03', '2025-06-28', 'Menyiapkan larutan standar dan membimbing praktikum.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720026') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Kimia Analitik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720026'), 'pengalaman', 'Magang Analis Laboratorium', 'PT Wilmar Nabati Indonesia', '2024-02-03', '2024-06-28', 'Menganalisis kadar asam lemak bebas dan kadar air bahan baku.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720026') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Analis Laboratorium') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720026'), 'sertifikat', 'Analis Kimia Muda (BNSP)', 'LSP Kimia', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720026') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'sertifikat' AND x.judul = 'Analis Kimia Muda (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720026'), 'sertifikat', 'ISO 14001 Awareness', 'Lembaga Pelatihan Mutu', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720026') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'sertifikat' AND x.judul = 'ISO 14001 Awareness') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720026'), 'portofolio', 'Pengolahan Limbah Cair Tahu Skala Lab', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-limbah', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720026') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'portofolio' AND x.judul = 'Pengolahan Limbah Cair Tahu Skala Lab') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720026.pdf' WHERE nim = '2341720026' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720026'), s.id FROM skill s WHERE s.nama IN ('Manajemen waktu', 'Kerja sama tim', 'Bahasa Inggris', 'Microsoft Excel', 'Komunikasi') AND (SELECT id FROM mahasiswa WHERE nim = '2341720026') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720026'), b.id FROM bidang b WHERE b.nama IN ('Kimia', 'Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '2341720026') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720026')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720027.png' WHERE nim = '2341720027' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-II Pengembangan Peranti Lunak Situs Politeknik Negeri Malang angkatan 2023. Senang membangun aplikasi web yang rapi dan mudah dipakai. Terbiasa bekerja dalam tim dengan Git dan metode agile.' WHERE nim = '2341720027' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Ahmad Yani No. 179, RT 07/RW 11', provinsi = 'Jawa Timur', kode_pos = '61111' WHERE nim = '2341720027' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720027'), 'pendidikan', 'D-II Pengembangan Peranti Lunak Situs', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknologi Informasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720027') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'pendidikan' AND x.judul = 'D-II Pengembangan Peranti Lunak Situs') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720027'), 'pendidikan', 'Rekayasa Perangkat Lunak', 'SMK Negeri 4 Malang', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720027') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'pendidikan' AND x.judul = 'Rekayasa Perangkat Lunak') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720027'), 'pengalaman', 'Asisten Laboratorium Pemrograman', 'Politeknik Negeri Malang', '2025-02-03', '2025-06-28', 'Mendampingi praktikum pemrograman web untuk mahasiswa semester 1.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720027') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Pemrograman') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720027'), 'pengalaman', 'Freelance Frontend Developer', 'Proyek UMKM', '2024-02-03', '2024-06-28', 'Membuat landing page responsif untuk 4 usaha kecil di Malang.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720027') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'pengalaman' AND x.judul = 'Freelance Frontend Developer') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720027'), 'sertifikat', 'Google UX Design Certificate', 'Coursera', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720027') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'sertifikat' AND x.judul = 'Google UX Design Certificate') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720027'), 'sertifikat', 'Junior Web Developer (BNSP)', 'LSP Politeknik Negeri Malang', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720027') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'sertifikat' AND x.judul = 'Junior Web Developer (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720027'), 'portofolio', 'Sistem Informasi Perpustakaan', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/perpus', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720027') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Informasi Perpustakaan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720027.pdf' WHERE nim = '2341720027' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720027'), s.id FROM skill s WHERE s.nama IN ('Git', 'JavaScript', 'PostgreSQL', 'CSS') AND (SELECT id FROM mahasiswa WHERE nim = '2341720027') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720027'), b.id FROM bidang b WHERE b.nama IN ('Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2341720027') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720027')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720028.png' WHERE nim = '2341720028' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Teknik Informatika Politeknik Negeri Malang angkatan 2023. Senang membangun aplikasi web yang rapi dan mudah dipakai. Terbiasa bekerja dalam tim dengan Git dan metode agile.' WHERE nim = '2341720028' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Panglima Sudirman No. 139, RT 02/RW 08', provinsi = 'Jawa Timur', kode_pos = '65141' WHERE nim = '2341720028' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720028'), 'pendidikan', 'D-IV Teknik Informatika', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknologi Informasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720028') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknik Informatika') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720028'), 'pendidikan', 'Rekayasa Perangkat Lunak', 'SMK Negeri 4 Malang', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720028') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'pendidikan' AND x.judul = 'Rekayasa Perangkat Lunak') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720028'), 'pengalaman', 'Magang Web Developer', 'PT Sinergi Data Nusantara', '2025-02-03', '2025-06-28', 'Membuat fitur dashboard admin dengan Laravel dan PostgreSQL.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720028') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Web Developer') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720028'), 'pengalaman', 'Freelance Frontend Developer', 'Proyek UMKM', '2024-02-03', '2024-06-28', 'Membuat landing page responsif untuk 4 usaha kecil di Malang.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720028') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'pengalaman' AND x.judul = 'Freelance Frontend Developer') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720028'), 'sertifikat', 'Dicoding: Belajar Dasar Pemrograman Web', 'Dicoding Indonesia', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720028') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'sertifikat' AND x.judul = 'Dicoding: Belajar Dasar Pemrograman Web') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720028'), 'sertifikat', 'Junior Web Developer (BNSP)', 'LSP Politeknik Negeri Malang', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720028') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'sertifikat' AND x.judul = 'Junior Web Developer (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720028'), 'portofolio', 'Aplikasi Kasir UMKM Berbasis Web', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/kasir-umkm', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720028') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'portofolio' AND x.judul = 'Aplikasi Kasir UMKM Berbasis Web') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720028.pdf' WHERE nim = '2341720028' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720028'), s.id FROM skill s WHERE s.nama IN ('Git', 'HTML', 'Python', 'JavaScript') AND (SELECT id FROM mahasiswa WHERE nim = '2341720028') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720028'), b.id FROM bidang b WHERE b.nama IN ('Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2341720028') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720028')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2441720029.png' WHERE nim = '2441720029' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Sistem Informasi Bisnis Politeknik Negeri Malang angkatan 2024. Senang membangun aplikasi web yang rapi dan mudah dipakai. Terbiasa bekerja dalam tim dengan Git dan metode agile.' WHERE nim = '2441720029' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Panglima Sudirman No. 160, RT 09/RW 08', provinsi = 'Jawa Timur', kode_pos = '67111' WHERE nim = '2441720029' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720029'), 'pendidikan', 'D-IV Sistem Informasi Bisnis', 'Politeknik Negeri Malang', '2024-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknologi Informasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720029') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Sistem Informasi Bisnis') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720029'), 'pendidikan', 'Rekayasa Perangkat Lunak', 'SMK Negeri 4 Malang', '2021-07-15', '2024-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720029') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'pendidikan' AND x.judul = 'Rekayasa Perangkat Lunak') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720029'), 'pengalaman', 'Magang Web Developer', 'PT Sinergi Data Nusantara', '2025-02-03', '2025-06-28', 'Membuat fitur dashboard admin dengan Laravel dan PostgreSQL.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720029') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Web Developer') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720029'), 'pengalaman', 'Asisten Laboratorium Pemrograman', 'Politeknik Negeri Malang', '2024-02-03', '2024-06-28', 'Mendampingi praktikum pemrograman web untuk mahasiswa semester 1.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720029') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Pemrograman') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720029'), 'sertifikat', 'Dicoding: Belajar Dasar Pemrograman Web', 'Dicoding Indonesia', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720029') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'sertifikat' AND x.judul = 'Dicoding: Belajar Dasar Pemrograman Web') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720029'), 'sertifikat', 'Google UX Design Certificate', 'Coursera', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720029') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'sertifikat' AND x.judul = 'Google UX Design Certificate') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720029'), 'portofolio', 'Aplikasi Kasir UMKM Berbasis Web', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/kasir-umkm', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720029') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'portofolio' AND x.judul = 'Aplikasi Kasir UMKM Berbasis Web') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2441720029.pdf' WHERE nim = '2441720029' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720029'), s.id FROM skill s WHERE s.nama IN ('PHP', 'Laravel', 'PostgreSQL', 'Figma') AND (SELECT id FROM mahasiswa WHERE nim = '2441720029') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720029'), b.id FROM bidang b WHERE b.nama IN ('Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2441720029') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720029')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2441720030.png' WHERE nim = '2441720030' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Akuntansi Politeknik Negeri Malang angkatan 2024. Teliti dengan angka dan terbiasa menyusun laporan keuangan. Siap belajar sistem akuntansi perusahaan.' WHERE nim = '2441720030' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Ijen No. 115, RT 05/RW 11', provinsi = 'Jawa Timur', kode_pos = '67211' WHERE nim = '2441720030' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720030'), 'pendidikan', 'D-III Akuntansi', 'Politeknik Negeri Malang', '2024-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Akuntansi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720030') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Akuntansi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720030'), 'pendidikan', 'Akuntansi dan Keuangan Lembaga', 'SMK Negeri 1 Malang', '2021-07-15', '2024-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720030') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'pendidikan' AND x.judul = 'Akuntansi dan Keuangan Lembaga') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720030'), 'pengalaman', 'Magang Staf Akuntansi', 'PT Bank Mandiri Tbk', '2025-02-03', '2025-06-28', 'Membantu rekonsiliasi bank dan penyusunan laporan harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720030') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Staf Akuntansi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720030'), 'pengalaman', 'Bendahara Himpunan Mahasiswa', 'Himpunan Mahasiswa Akuntansi', '2024-02-03', '2024-06-28', 'Mengelola kas dan laporan pertanggungjawaban kegiatan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720030') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'pengalaman' AND x.judul = 'Bendahara Himpunan Mahasiswa') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720030'), 'sertifikat', 'Microsoft Office Specialist: Excel', 'Microsoft', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720030') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'sertifikat' AND x.judul = 'Microsoft Office Specialist: Excel') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720030'), 'sertifikat', 'Brevet Pajak A dan B', 'IAI Wilayah Jawa Timur', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720030') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'sertifikat' AND x.judul = 'Brevet Pajak A dan B') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720030'), 'portofolio', 'Laporan Keuangan UMKM Kopi Lokal', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-laporan', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720030') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'portofolio' AND x.judul = 'Laporan Keuangan UMKM Kopi Lokal') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2441720030.pdf' WHERE nim = '2441720030' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720030'), s.id FROM skill s WHERE s.nama IN ('Microsoft Excel', 'Bahasa Inggris', 'Manajemen waktu', 'Komunikasi', 'Kerja sama tim') AND (SELECT id FROM mahasiswa WHERE nim = '2441720030') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720030'), b.id FROM bidang b WHERE b.nama IN ('Keuangan') AND (SELECT id FROM mahasiswa WHERE nim = '2441720030') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720030')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720031.png' WHERE nim = '2341720031' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Akuntansi Manajemen Politeknik Negeri Malang angkatan 2023. Teliti dengan angka dan terbiasa menyusun laporan keuangan. Siap belajar sistem akuntansi perusahaan.' WHERE nim = '2341720031' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Gajayana No. 117, RT 09/RW 07', provinsi = 'Jawa Timur', kode_pos = '63111' WHERE nim = '2341720031' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720031'), 'pendidikan', 'D-IV Akuntansi Manajemen', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Akuntansi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720031') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Akuntansi Manajemen') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720031'), 'pendidikan', 'Akuntansi dan Keuangan Lembaga', 'SMK Negeri 1 Malang', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720031') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'pendidikan' AND x.judul = 'Akuntansi dan Keuangan Lembaga') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720031'), 'pengalaman', 'Bendahara Himpunan Mahasiswa', 'Himpunan Mahasiswa Akuntansi', '2025-02-03', '2025-06-28', 'Mengelola kas dan laporan pertanggungjawaban kegiatan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720031') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'pengalaman' AND x.judul = 'Bendahara Himpunan Mahasiswa') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720031'), 'pengalaman', 'Magang Staf Akuntansi', 'PT Bank Mandiri Tbk', '2024-02-03', '2024-06-28', 'Membantu rekonsiliasi bank dan penyusunan laporan harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720031') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Staf Akuntansi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720031'), 'sertifikat', 'Microsoft Office Specialist: Excel', 'Microsoft', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720031') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'sertifikat' AND x.judul = 'Microsoft Office Specialist: Excel') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720031'), 'sertifikat', 'Brevet Pajak A dan B', 'IAI Wilayah Jawa Timur', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720031') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'sertifikat' AND x.judul = 'Brevet Pajak A dan B') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720031'), 'portofolio', 'Laporan Keuangan UMKM Kopi Lokal', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-laporan', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720031') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'portofolio' AND x.judul = 'Laporan Keuangan UMKM Kopi Lokal') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720031.pdf' WHERE nim = '2341720031' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720031'), s.id FROM skill s WHERE s.nama IN ('Manajemen waktu', 'Bahasa Inggris', 'Komunikasi', 'Kerja sama tim') AND (SELECT id FROM mahasiswa WHERE nim = '2341720031') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720031'), b.id FROM bidang b WHERE b.nama IN ('Keuangan') AND (SELECT id FROM mahasiswa WHERE nim = '2341720031') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720031')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720032.png' WHERE nim = '2341720032' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Keuangan Politeknik Negeri Malang angkatan 2023. Teliti dengan angka dan terbiasa menyusun laporan keuangan. Siap belajar sistem akuntansi perusahaan.' WHERE nim = '2341720032' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Diponegoro No. 120, RT 08/RW 05', provinsi = 'Jawa Timur', kode_pos = '64111' WHERE nim = '2341720032' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720032'), 'pendidikan', 'D-IV Keuangan', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Akuntansi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720032') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Keuangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720032'), 'pendidikan', 'Akuntansi dan Keuangan Lembaga', 'SMK Negeri 1 Malang', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720032') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'pendidikan' AND x.judul = 'Akuntansi dan Keuangan Lembaga') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720032'), 'pengalaman', 'Bendahara Himpunan Mahasiswa', 'Himpunan Mahasiswa Akuntansi', '2025-02-03', '2025-06-28', 'Mengelola kas dan laporan pertanggungjawaban kegiatan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720032') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'pengalaman' AND x.judul = 'Bendahara Himpunan Mahasiswa') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720032'), 'pengalaman', 'Magang Staf Akuntansi', 'PT Bank Mandiri Tbk', '2024-02-03', '2024-06-28', 'Membantu rekonsiliasi bank dan penyusunan laporan harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720032') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Staf Akuntansi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720032'), 'sertifikat', 'Brevet Pajak A dan B', 'IAI Wilayah Jawa Timur', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720032') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'sertifikat' AND x.judul = 'Brevet Pajak A dan B') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720032'), 'sertifikat', 'Microsoft Office Specialist: Excel', 'Microsoft', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720032') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'sertifikat' AND x.judul = 'Microsoft Office Specialist: Excel') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720032'), 'portofolio', 'Laporan Keuangan UMKM Kopi Lokal', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-laporan', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720032') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'portofolio' AND x.judul = 'Laporan Keuangan UMKM Kopi Lokal') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720032.pdf' WHERE nim = '2341720032' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720032'), s.id FROM skill s WHERE s.nama IN ('Kerja sama tim', 'Komunikasi', 'Manajemen waktu', 'Bahasa Inggris') AND (SELECT id FROM mahasiswa WHERE nim = '2341720032') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720032'), b.id FROM bidang b WHERE b.nama IN ('Keuangan') AND (SELECT id FROM mahasiswa WHERE nim = '2341720032') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720032')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720033.png' WHERE nim = '2341720033' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Administrasi Bisnis Politeknik Negeri Malang angkatan 2023. Komunikatif dan rapi dalam administrasi. Tertarik pada pemasaran digital dan pelayanan pelanggan.' WHERE nim = '2341720033' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Ahmad Yani No. 31, RT 08/RW 04', provinsi = 'Jawa Timur', kode_pos = '61211' WHERE nim = '2341720033' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720033'), 'pendidikan', 'D-III Administrasi Bisnis', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Administrasi Niaga.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720033') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Administrasi Bisnis') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720033'), 'pendidikan', 'IPS', 'SMA Negeri 5 Malang', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720033') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'pendidikan' AND x.judul = 'IPS') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720033'), 'pengalaman', 'Admin Media Sosial', 'Usaha Kuliner Keluarga', '2025-02-03', '2025-06-28', 'Membuat konten dan menaikkan pengikut Instagram dua kali lipat.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720033') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'pengalaman' AND x.judul = 'Admin Media Sosial') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720033'), 'pengalaman', 'Magang Staf Administrasi', 'PT Mitra Arsip Nusantara', '2024-02-03', '2024-06-28', 'Mengelola arsip digital dan surat-menyurat perusahaan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720033') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Staf Administrasi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720033'), 'sertifikat', 'Digital Marketing Fundamental', 'Google Digital Garage', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720033') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'sertifikat' AND x.judul = 'Digital Marketing Fundamental') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720033'), 'sertifikat', 'TOEIC 750', 'ETS', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720033') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'sertifikat' AND x.judul = 'TOEIC 750') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720033'), 'portofolio', 'Kampanye Pemasaran Digital Produk UMKM', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-kampanye', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720033') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'portofolio' AND x.judul = 'Kampanye Pemasaran Digital Produk UMKM') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720033.pdf' WHERE nim = '2341720033' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720033'), s.id FROM skill s WHERE s.nama IN ('Bahasa Inggris', 'Kerja sama tim', 'Microsoft Excel', 'Figma', 'Komunikasi') AND (SELECT id FROM mahasiswa WHERE nim = '2341720033') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720033'), b.id FROM bidang b WHERE b.nama IN ('Perdagangan dan Jasa', 'Keuangan') AND (SELECT id FROM mahasiswa WHERE nim = '2341720033') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720033')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720034.png' WHERE nim = '2241720034' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Manajemen Pemasaran Digital Politeknik Negeri Malang angkatan 2022. Komunikatif dan rapi dalam administrasi. Tertarik pada pemasaran digital dan pelayanan pelanggan.' WHERE nim = '2241720034' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Sumbersari No. 172, RT 08/RW 04', provinsi = 'Jawa Timur', kode_pos = '67111' WHERE nim = '2241720034' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720034'), 'pendidikan', 'D-IV Manajemen Pemasaran Digital', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Administrasi Niaga.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720034') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Manajemen Pemasaran Digital') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720034'), 'pendidikan', 'IPS', 'SMA Negeri 5 Malang', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720034') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'pendidikan' AND x.judul = 'IPS') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720034'), 'pengalaman', 'Magang Staf Administrasi', 'PT Mitra Arsip Nusantara', '2024-02-03', '2024-06-28', 'Mengelola arsip digital dan surat-menyurat perusahaan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720034') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Staf Administrasi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720034'), 'pengalaman', 'Admin Media Sosial', 'Usaha Kuliner Keluarga', '2023-02-03', '2023-06-28', 'Membuat konten dan menaikkan pengikut Instagram dua kali lipat.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720034') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'pengalaman' AND x.judul = 'Admin Media Sosial') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720034'), 'sertifikat', 'TOEIC 750', 'ETS', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720034') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'sertifikat' AND x.judul = 'TOEIC 750') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720034'), 'sertifikat', 'Digital Marketing Fundamental', 'Google Digital Garage', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720034') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'sertifikat' AND x.judul = 'Digital Marketing Fundamental') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720034'), 'portofolio', 'Kampanye Pemasaran Digital Produk UMKM', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-kampanye', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720034') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'portofolio' AND x.judul = 'Kampanye Pemasaran Digital Produk UMKM') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720034.pdf' WHERE nim = '2241720034' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720034'), s.id FROM skill s WHERE s.nama IN ('Kerja sama tim', 'Microsoft Excel', 'Figma', 'Komunikasi', 'Bahasa Inggris') AND (SELECT id FROM mahasiswa WHERE nim = '2241720034') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720034'), b.id FROM bidang b WHERE b.nama IN ('Perdagangan dan Jasa', 'Keuangan') AND (SELECT id FROM mahasiswa WHERE nim = '2241720034') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720034')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720035.png' WHERE nim = '2241720035' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Pengelolaan Arsip dan Rekaman Informasi Politeknik Negeri Malang angkatan 2022. Komunikatif dan rapi dalam administrasi. Tertarik pada pemasaran digital dan pelayanan pelanggan.' WHERE nim = '2241720035' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Panglima Sudirman No. 3, RT 04/RW 04', provinsi = 'Jawa Timur', kode_pos = '60111' WHERE nim = '2241720035' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720035'), 'pendidikan', 'D-IV Pengelolaan Arsip dan Rekaman Informasi', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Administrasi Niaga.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720035') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Pengelolaan Arsip dan Rekaman Informasi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720035'), 'pendidikan', 'IPS', 'SMA Negeri 5 Malang', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720035') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'pendidikan' AND x.judul = 'IPS') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720035'), 'pengalaman', 'Magang Staf Administrasi', 'PT Mitra Arsip Nusantara', '2024-02-03', '2024-06-28', 'Mengelola arsip digital dan surat-menyurat perusahaan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720035') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Staf Administrasi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720035'), 'pengalaman', 'Admin Media Sosial', 'Usaha Kuliner Keluarga', '2023-02-03', '2023-06-28', 'Membuat konten dan menaikkan pengikut Instagram dua kali lipat.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720035') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'pengalaman' AND x.judul = 'Admin Media Sosial') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720035'), 'sertifikat', 'TOEIC 750', 'ETS', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720035') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'sertifikat' AND x.judul = 'TOEIC 750') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720035'), 'sertifikat', 'Digital Marketing Fundamental', 'Google Digital Garage', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720035') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'sertifikat' AND x.judul = 'Digital Marketing Fundamental') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720035'), 'portofolio', 'Kampanye Pemasaran Digital Produk UMKM', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-kampanye', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720035') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'portofolio' AND x.judul = 'Kampanye Pemasaran Digital Produk UMKM') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720035.pdf' WHERE nim = '2241720035' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720035'), s.id FROM skill s WHERE s.nama IN ('Figma', 'Komunikasi', 'Bahasa Inggris', 'Kerja sama tim') AND (SELECT id FROM mahasiswa WHERE nim = '2241720035') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720035'), b.id FROM bidang b WHERE b.nama IN ('Perdagangan dan Jasa', 'Keuangan') AND (SELECT id FROM mahasiswa WHERE nim = '2241720035') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720035')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2241720036.png' WHERE nim = '2241720036' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Bahasa Inggris untuk Komunikasi Bisnis dan Profesional Politeknik Negeri Malang angkatan 2022. Komunikatif dan rapi dalam administrasi. Tertarik pada pemasaran digital dan pelayanan pelanggan.' WHERE nim = '2241720036' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Soekarno Hatta No. 175, RT 05/RW 07', provinsi = 'Jawa Timur', kode_pos = '65141' WHERE nim = '2241720036' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720036'), 'pendidikan', 'D-IV Bahasa Inggris untuk Komunikasi Bisnis dan Profesional', 'Politeknik Negeri Malang', '2022-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Administrasi Niaga.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720036') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Bahasa Inggris untuk Komunikasi Bisnis dan Profesional') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720036'), 'pendidikan', 'IPS', 'SMA Negeri 5 Malang', '2019-07-15', '2022-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720036') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'pendidikan' AND x.judul = 'IPS') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720036'), 'pengalaman', 'Admin Media Sosial', 'Usaha Kuliner Keluarga', '2024-02-03', '2024-06-28', 'Membuat konten dan menaikkan pengikut Instagram dua kali lipat.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720036') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'pengalaman' AND x.judul = 'Admin Media Sosial') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720036'), 'pengalaman', 'Magang Staf Administrasi', 'PT Mitra Arsip Nusantara', '2023-02-03', '2023-06-28', 'Mengelola arsip digital dan surat-menyurat perusahaan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720036') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Staf Administrasi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720036'), 'sertifikat', 'TOEIC 750', 'ETS', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720036') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'sertifikat' AND x.judul = 'TOEIC 750') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720036'), 'sertifikat', 'Digital Marketing Fundamental', 'Google Digital Garage', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720036') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'sertifikat' AND x.judul = 'Digital Marketing Fundamental') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720036'), 'portofolio', 'Kampanye Pemasaran Digital Produk UMKM', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-kampanye', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2241720036') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'portofolio' AND x.judul = 'Kampanye Pemasaran Digital Produk UMKM') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2241720036.pdf' WHERE nim = '2241720036' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720036'), s.id FROM skill s WHERE s.nama IN ('Microsoft Excel', 'Kerja sama tim', 'Komunikasi', 'Figma', 'Bahasa Inggris') AND (SELECT id FROM mahasiswa WHERE nim = '2241720036') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2241720036'), b.id FROM bidang b WHERE b.nama IN ('Perdagangan dan Jasa', 'Keuangan') AND (SELECT id FROM mahasiswa WHERE nim = '2241720036') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2241720036')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2441720037.png' WHERE nim = '2441720037' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-III Teknik Sipil Politeknik Negeri Malang angkatan 2024. Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.' WHERE nim = '2441720037' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Gajayana No. 114, RT 07/RW 07', provinsi = 'Jawa Timur', kode_pos = '63111' WHERE nim = '2441720037' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720037'), 'pendidikan', 'D-III Teknik Sipil', 'Politeknik Negeri Malang', '2024-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Sipil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720037') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Sipil') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720037'), 'pendidikan', 'Desain Pemodelan dan Informasi Bangunan', 'SMK Negeri 1 Singosari', '2021-07-15', '2024-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720037') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'pendidikan' AND x.judul = 'Desain Pemodelan dan Informasi Bangunan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720037'), 'pengalaman', 'Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', '2025-02-03', '2025-06-28', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720037') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Pengawas Lapangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720037'), 'pengalaman', 'Drafter Paruh Waktu', 'CV Arta Konstruksi', '2024-02-03', '2024-06-28', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720037') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'pengalaman' AND x.judul = 'Drafter Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720037'), 'sertifikat', 'AutoCAD Certified User', 'Autodesk', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720037') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'sertifikat' AND x.judul = 'AutoCAD Certified User') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720037'), 'sertifikat', 'Ahli Muda Teknik Jalan (SKK)', 'LPJK', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720037') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'sertifikat' AND x.judul = 'Ahli Muda Teknik Jalan (SKK)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720037'), 'portofolio', 'Desain Struktur Gedung 3 Lantai', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-struktur', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2441720037') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'portofolio' AND x.judul = 'Desain Struktur Gedung 3 Lantai') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2441720037.pdf' WHERE nim = '2441720037' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720037'), s.id FROM skill s WHERE s.nama IN ('Komunikasi', 'Manajemen waktu', 'AutoCAD', 'Microsoft Excel', 'Kerja sama tim') AND (SELECT id FROM mahasiswa WHERE nim = '2441720037') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2441720037'), b.id FROM bidang b WHERE b.nama IN ('Konstruksi') AND (SELECT id FROM mahasiswa WHERE nim = '2441720037') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2441720037')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2041720038.png' WHERE nim = '2041720038' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-III Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air Politeknik Negeri Malang angkatan 2020. Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.' WHERE nim = '2041720038' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Veteran No. 53, RT 05/RW 11', provinsi = 'Jawa Timur', kode_pos = '67211' WHERE nim = '2041720038' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720038'), 'pendidikan', 'D-III Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air', 'Politeknik Negeri Malang', '2020-08-25', '2023-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Sipil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720038') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknologi Konstruksi Jalan, Jembatan, dan Bangunan Air') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720038'), 'pendidikan', 'Desain Pemodelan dan Informasi Bangunan', 'SMK Negeri 1 Singosari', '2017-07-15', '2020-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720038') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'pendidikan' AND x.judul = 'Desain Pemodelan dan Informasi Bangunan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720038'), 'pengalaman', 'Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', '2022-02-03', '2022-06-28', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720038') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Pengawas Lapangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720038'), 'pengalaman', 'Drafter Paruh Waktu', 'CV Arta Konstruksi', '2021-02-03', '2021-06-28', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720038') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'pengalaman' AND x.judul = 'Drafter Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720038'), 'sertifikat', 'AutoCAD Certified User', 'Autodesk', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720038') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'sertifikat' AND x.judul = 'AutoCAD Certified User') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720038'), 'sertifikat', 'Ahli Muda Teknik Jalan (SKK)', 'LPJK', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720038') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'sertifikat' AND x.judul = 'Ahli Muda Teknik Jalan (SKK)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720038'), 'portofolio', 'Desain Struktur Gedung 3 Lantai', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-struktur', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720038') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'portofolio' AND x.judul = 'Desain Struktur Gedung 3 Lantai') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2041720038.pdf' WHERE nim = '2041720038' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720038'), s.id FROM skill s WHERE s.nama IN ('Kerja sama tim', 'Manajemen waktu', 'AutoCAD', 'Microsoft Excel', 'Komunikasi') AND (SELECT id FROM mahasiswa WHERE nim = '2041720038') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720038'), b.id FROM bidang b WHERE b.nama IN ('Konstruksi') AND (SELECT id FROM mahasiswa WHERE nim = '2041720038') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720038')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-1941720039.png' WHERE nim = '1941720039' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-III Teknologi Pertambangan Politeknik Negeri Malang angkatan 2019. Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.' WHERE nim = '1941720039' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Gajayana No. 121, RT 09/RW 03', provinsi = 'Jawa Timur', kode_pos = '61311' WHERE nim = '1941720039' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720039'), 'pendidikan', 'D-III Teknologi Pertambangan', 'Politeknik Negeri Malang', '2019-08-25', '2022-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Sipil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720039') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknologi Pertambangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720039'), 'pendidikan', 'Desain Pemodelan dan Informasi Bangunan', 'SMK Negeri 1 Singosari', '2016-07-15', '2019-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720039') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'pendidikan' AND x.judul = 'Desain Pemodelan dan Informasi Bangunan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720039'), 'pengalaman', 'Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', '2021-02-03', '2021-06-28', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720039') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Pengawas Lapangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720039'), 'pengalaman', 'Drafter Paruh Waktu', 'CV Arta Konstruksi', '2020-02-03', '2020-06-28', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720039') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'pengalaman' AND x.judul = 'Drafter Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720039'), 'sertifikat', 'Ahli Muda Teknik Jalan (SKK)', 'LPJK', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720039') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'sertifikat' AND x.judul = 'Ahli Muda Teknik Jalan (SKK)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720039'), 'sertifikat', 'AutoCAD Certified User', 'Autodesk', '2020-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720039') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'sertifikat' AND x.judul = 'AutoCAD Certified User') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720039'), 'portofolio', 'Desain Struktur Gedung 3 Lantai', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-struktur', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720039') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'portofolio' AND x.judul = 'Desain Struktur Gedung 3 Lantai') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-1941720039.pdf' WHERE nim = '1941720039' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720039'), s.id FROM skill s WHERE s.nama IN ('Manajemen waktu', 'Komunikasi', 'AutoCAD', 'Kerja sama tim', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '1941720039') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720039'), b.id FROM bidang b WHERE b.nama IN ('Konstruksi') AND (SELECT id FROM mahasiswa WHERE nim = '1941720039') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720039')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2141720040.png' WHERE nim = '2141720040' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Teknologi Rekayasa Konstruksi Jalan dan Jembatan Politeknik Negeri Malang angkatan 2021. Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.' WHERE nim = '2141720040' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Merdeka No. 28, RT 07/RW 03', provinsi = 'Jawa Timur', kode_pos = '64111' WHERE nim = '2141720040' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720040'), 'pendidikan', 'D-IV Teknologi Rekayasa Konstruksi Jalan dan Jembatan', 'Politeknik Negeri Malang', '2021-08-25', '2025-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Sipil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720040') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknologi Rekayasa Konstruksi Jalan dan Jembatan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720040'), 'pendidikan', 'Desain Pemodelan dan Informasi Bangunan', 'SMK Negeri 1 Singosari', '2018-07-15', '2021-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720040') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'pendidikan' AND x.judul = 'Desain Pemodelan dan Informasi Bangunan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720040'), 'pengalaman', 'Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', '2023-02-03', '2023-06-28', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720040') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Pengawas Lapangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720040'), 'pengalaman', 'Drafter Paruh Waktu', 'CV Arta Konstruksi', '2022-02-03', '2022-06-28', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720040') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'pengalaman' AND x.judul = 'Drafter Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720040'), 'sertifikat', 'Ahli Muda Teknik Jalan (SKK)', 'LPJK', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720040') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'sertifikat' AND x.judul = 'Ahli Muda Teknik Jalan (SKK)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720040'), 'sertifikat', 'AutoCAD Certified User', 'Autodesk', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720040') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'sertifikat' AND x.judul = 'AutoCAD Certified User') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720040'), 'portofolio', 'Desain Struktur Gedung 3 Lantai', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-struktur', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720040') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'portofolio' AND x.judul = 'Desain Struktur Gedung 3 Lantai') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2141720040.pdf' WHERE nim = '2141720040' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720040'), s.id FROM skill s WHERE s.nama IN ('Kerja sama tim', 'Komunikasi', 'Manajemen waktu', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '2141720040') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720040'), b.id FROM bidang b WHERE b.nama IN ('Konstruksi') AND (SELECT id FROM mahasiswa WHERE nim = '2141720040') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720040')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2041720041.png' WHERE nim = '2041720041' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Manajemen Rekayasa Konstruksi Politeknik Negeri Malang angkatan 2020. Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.' WHERE nim = '2041720041' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Ijen No. 16, RT 09/RW 02', provinsi = 'Jawa Timur', kode_pos = '60111' WHERE nim = '2041720041' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720041'), 'pendidikan', 'D-IV Manajemen Rekayasa Konstruksi', 'Politeknik Negeri Malang', '2020-08-25', '2024-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Sipil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720041') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Manajemen Rekayasa Konstruksi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720041'), 'pendidikan', 'Desain Pemodelan dan Informasi Bangunan', 'SMK Negeri 1 Singosari', '2017-07-15', '2020-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720041') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'pendidikan' AND x.judul = 'Desain Pemodelan dan Informasi Bangunan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720041'), 'pengalaman', 'Drafter Paruh Waktu', 'CV Arta Konstruksi', '2022-02-03', '2022-06-28', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720041') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'pengalaman' AND x.judul = 'Drafter Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720041'), 'pengalaman', 'Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', '2021-02-03', '2021-06-28', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720041') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Pengawas Lapangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720041'), 'sertifikat', 'AutoCAD Certified User', 'Autodesk', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720041') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'sertifikat' AND x.judul = 'AutoCAD Certified User') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720041'), 'sertifikat', 'Ahli Muda Teknik Jalan (SKK)', 'LPJK', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720041') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'sertifikat' AND x.judul = 'Ahli Muda Teknik Jalan (SKK)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720041'), 'portofolio', 'Desain Struktur Gedung 3 Lantai', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-struktur', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720041') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'portofolio' AND x.judul = 'Desain Struktur Gedung 3 Lantai') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2041720041.pdf' WHERE nim = '2041720041' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720041'), s.id FROM skill s WHERE s.nama IN ('Microsoft Excel', 'AutoCAD', 'Manajemen waktu', 'Komunikasi', 'Kerja sama tim') AND (SELECT id FROM mahasiswa WHERE nim = '2041720041') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720041'), b.id FROM bidang b WHERE b.nama IN ('Konstruksi') AND (SELECT id FROM mahasiswa WHERE nim = '2041720041') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720041')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2041720042.png' WHERE nim = '2041720042' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-III Teknik Mesin Politeknik Negeri Malang angkatan 2020. Menyukai dunia manufaktur dan perawatan mesin. Terbiasa membaca gambar teknik dan bekerja sesuai SOP K3.' WHERE nim = '2041720042' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Soekarno Hatta No. 68, RT 06/RW 02', provinsi = 'Jawa Timur', kode_pos = '61111' WHERE nim = '2041720042' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720042'), 'pendidikan', 'D-III Teknik Mesin', 'Politeknik Negeri Malang', '2020-08-25', '2023-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Mesin.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720042') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Mesin') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720042'), 'pendidikan', 'Teknik Pemesinan', 'SMK Negeri 6 Malang', '2017-07-15', '2020-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720042') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Pemesinan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720042'), 'pengalaman', 'Magang Maintenance Mesin', 'PT Barata Indonesia', '2022-02-03', '2022-06-28', 'Melakukan perawatan preventif mesin bubut dan frais.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720042') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Maintenance Mesin') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720042'), 'pengalaman', 'Asisten Bengkel Praktik', 'Politeknik Negeri Malang', '2021-02-03', '2021-06-28', 'Menyiapkan alat dan bahan praktikum pemesinan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720042') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Bengkel Praktik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720042'), 'sertifikat', 'K3 Umum', 'Kemnaker RI', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720042') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'sertifikat' AND x.judul = 'K3 Umum') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720042'), 'sertifikat', 'Operator Mesin CNC (BNSP)', 'LSP Logam dan Mesin', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720042') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'sertifikat' AND x.judul = 'Operator Mesin CNC (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720042'), 'portofolio', 'Rancang Bangun Alat Pengupas Kopi', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-alat', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720042') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'portofolio' AND x.judul = 'Rancang Bangun Alat Pengupas Kopi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2041720042.pdf' WHERE nim = '2041720042' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720042'), s.id FROM skill s WHERE s.nama IN ('Manajemen waktu', 'AutoCAD', 'Microsoft Excel', 'Kerja sama tim', 'SolidWorks') AND (SELECT id FROM mahasiswa WHERE nim = '2041720042') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720042'), b.id FROM bidang b WHERE b.nama IN ('Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '2041720042') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720042')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2141720043.png' WHERE nim = '2141720043' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-III Teknologi Pemeliharaan Pesawat Udara Politeknik Negeri Malang angkatan 2021. Menyukai dunia manufaktur dan perawatan mesin. Terbiasa membaca gambar teknik dan bekerja sesuai SOP K3.' WHERE nim = '2141720043' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Pahlawan No. 10, RT 05/RW 12', provinsi = 'Jawa Timur', kode_pos = '66111' WHERE nim = '2141720043' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720043'), 'pendidikan', 'D-III Teknologi Pemeliharaan Pesawat Udara', 'Politeknik Negeri Malang', '2021-08-25', '2024-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Mesin.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720043') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknologi Pemeliharaan Pesawat Udara') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720043'), 'pendidikan', 'Teknik Pemesinan', 'SMK Negeri 6 Malang', '2018-07-15', '2021-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720043') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Pemesinan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720043'), 'pengalaman', 'Asisten Bengkel Praktik', 'Politeknik Negeri Malang', '2023-02-03', '2023-06-28', 'Menyiapkan alat dan bahan praktikum pemesinan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720043') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Bengkel Praktik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720043'), 'pengalaman', 'Magang Maintenance Mesin', 'PT Barata Indonesia', '2022-02-03', '2022-06-28', 'Melakukan perawatan preventif mesin bubut dan frais.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720043') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Maintenance Mesin') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720043'), 'sertifikat', 'Operator Mesin CNC (BNSP)', 'LSP Logam dan Mesin', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720043') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'sertifikat' AND x.judul = 'Operator Mesin CNC (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720043'), 'sertifikat', 'K3 Umum', 'Kemnaker RI', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720043') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'sertifikat' AND x.judul = 'K3 Umum') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720043'), 'portofolio', 'Rancang Bangun Alat Pengupas Kopi', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-alat', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720043') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'portofolio' AND x.judul = 'Rancang Bangun Alat Pengupas Kopi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2141720043.pdf' WHERE nim = '2141720043' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720043'), s.id FROM skill s WHERE s.nama IN ('Kerja sama tim', 'Microsoft Excel', 'Manajemen waktu', 'SolidWorks', 'AutoCAD') AND (SELECT id FROM mahasiswa WHERE nim = '2141720043') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720043'), b.id FROM bidang b WHERE b.nama IN ('Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '2141720043') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720043')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2041720044.png' WHERE nim = '2041720044' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Teknik Mesin Produksi dan Perawatan Politeknik Negeri Malang angkatan 2020. Menyukai dunia manufaktur dan perawatan mesin. Terbiasa membaca gambar teknik dan bekerja sesuai SOP K3.' WHERE nim = '2041720044' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Ahmad Yani No. 125, RT 01/RW 09', provinsi = 'Jawa Timur', kode_pos = '66211' WHERE nim = '2041720044' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720044'), 'pendidikan', 'D-IV Teknik Mesin Produksi dan Perawatan', 'Politeknik Negeri Malang', '2020-08-25', '2024-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Mesin.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720044') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknik Mesin Produksi dan Perawatan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720044'), 'pendidikan', 'Teknik Pemesinan', 'SMK Negeri 6 Malang', '2017-07-15', '2020-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720044') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Pemesinan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720044'), 'pengalaman', 'Asisten Bengkel Praktik', 'Politeknik Negeri Malang', '2022-02-03', '2022-06-28', 'Menyiapkan alat dan bahan praktikum pemesinan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720044') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Bengkel Praktik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720044'), 'pengalaman', 'Magang Maintenance Mesin', 'PT Barata Indonesia', '2021-02-03', '2021-06-28', 'Melakukan perawatan preventif mesin bubut dan frais.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720044') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Maintenance Mesin') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720044'), 'sertifikat', 'K3 Umum', 'Kemnaker RI', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720044') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'sertifikat' AND x.judul = 'K3 Umum') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720044'), 'sertifikat', 'Operator Mesin CNC (BNSP)', 'LSP Logam dan Mesin', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720044') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'sertifikat' AND x.judul = 'Operator Mesin CNC (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720044'), 'portofolio', 'Rancang Bangun Alat Pengupas Kopi', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-alat', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720044') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'portofolio' AND x.judul = 'Rancang Bangun Alat Pengupas Kopi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2041720044.pdf' WHERE nim = '2041720044' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720044'), s.id FROM skill s WHERE s.nama IN ('Kerja sama tim', 'SolidWorks', 'Microsoft Excel', 'AutoCAD') AND (SELECT id FROM mahasiswa WHERE nim = '2041720044') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720044'), b.id FROM bidang b WHERE b.nama IN ('Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '2041720044') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720044')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-1941720045.png' WHERE nim = '1941720045' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Teknik Otomotif Elektronik Politeknik Negeri Malang angkatan 2019. Menyukai dunia manufaktur dan perawatan mesin. Terbiasa membaca gambar teknik dan bekerja sesuai SOP K3.' WHERE nim = '1941720045' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Panglima Sudirman No. 179, RT 02/RW 06', provinsi = 'Jawa Timur', kode_pos = '67211' WHERE nim = '1941720045' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720045'), 'pendidikan', 'D-IV Teknik Otomotif Elektronik', 'Politeknik Negeri Malang', '2019-08-25', '2023-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Mesin.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720045') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknik Otomotif Elektronik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720045'), 'pendidikan', 'Teknik Pemesinan', 'SMK Negeri 6 Malang', '2016-07-15', '2019-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720045') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Pemesinan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720045'), 'pengalaman', 'Magang Maintenance Mesin', 'PT Barata Indonesia', '2021-02-03', '2021-06-28', 'Melakukan perawatan preventif mesin bubut dan frais.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720045') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Maintenance Mesin') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720045'), 'pengalaman', 'Asisten Bengkel Praktik', 'Politeknik Negeri Malang', '2020-02-03', '2020-06-28', 'Menyiapkan alat dan bahan praktikum pemesinan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720045') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Bengkel Praktik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720045'), 'sertifikat', 'K3 Umum', 'Kemnaker RI', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720045') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'sertifikat' AND x.judul = 'K3 Umum') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720045'), 'sertifikat', 'Operator Mesin CNC (BNSP)', 'LSP Logam dan Mesin', '2020-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720045') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'sertifikat' AND x.judul = 'Operator Mesin CNC (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720045'), 'portofolio', 'Rancang Bangun Alat Pengupas Kopi', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-alat', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720045') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'portofolio' AND x.judul = 'Rancang Bangun Alat Pengupas Kopi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-1941720045.pdf' WHERE nim = '1941720045' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720045'), s.id FROM skill s WHERE s.nama IN ('Microsoft Excel', 'Manajemen waktu', 'Kerja sama tim', 'SolidWorks') AND (SELECT id FROM mahasiswa WHERE nim = '1941720045') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720045'), b.id FROM bidang b WHERE b.nama IN ('Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '1941720045') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720045')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2141720046.png' WHERE nim = '2141720046' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-III Teknik Listrik Politeknik Negeri Malang angkatan 2021. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '2141720046' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Merdeka No. 3, RT 06/RW 10', provinsi = 'Jawa Timur', kode_pos = '61211' WHERE nim = '2141720046' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720046'), 'pendidikan', 'D-III Teknik Listrik', 'Politeknik Negeri Malang', '2021-08-25', '2024-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720046') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720046'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2018-07-15', '2021-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720046') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720046'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2023-02-03', '2023-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720046') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720046'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2022-02-03', '2022-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720046') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720046'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720046') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720046'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720046') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720046'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720046') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2141720046.pdf' WHERE nim = '2141720046' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720046'), s.id FROM skill s WHERE s.nama IN ('AutoCAD', 'Komunikasi', 'Python', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '2141720046') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720046'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2141720046') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720046')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2041720047.png' WHERE nim = '2041720047' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-III Teknik Elektronika Politeknik Negeri Malang angkatan 2020. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '2041720047' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Kertoraharjo No. 71, RT 01/RW 03', provinsi = 'Jawa Timur', kode_pos = '67311' WHERE nim = '2041720047' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720047'), 'pendidikan', 'D-III Teknik Elektronika', 'Politeknik Negeri Malang', '2020-08-25', '2023-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720047') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Elektronika') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720047'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2017-07-15', '2020-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720047') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720047'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2022-02-03', '2022-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720047') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720047'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2021-02-03', '2021-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720047') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720047'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720047') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720047'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720047') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720047'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720047') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2041720047.pdf' WHERE nim = '2041720047' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720047'), s.id FROM skill s WHERE s.nama IN ('Komunikasi', 'Microsoft Excel', 'Kerja sama tim', 'Python') AND (SELECT id FROM mahasiswa WHERE nim = '2041720047') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720047'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2041720047') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720047')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-1941720048.png' WHERE nim = '1941720048' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-III Teknik Telekomunikasi Politeknik Negeri Malang angkatan 2019. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '1941720048' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Panglima Sudirman No. 156, RT 08/RW 09', provinsi = 'Jawa Timur', kode_pos = '67211' WHERE nim = '1941720048' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720048'), 'pendidikan', 'D-III Teknik Telekomunikasi', 'Politeknik Negeri Malang', '2019-08-25', '2022-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720048') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Telekomunikasi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720048'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2016-07-15', '2019-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720048') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720048'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2021-02-03', '2021-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720048') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720048'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2020-02-03', '2020-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720048') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720048'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720048') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720048'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2020-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720048') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720048'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720048') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-1941720048.pdf' WHERE nim = '1941720048' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720048'), s.id FROM skill s WHERE s.nama IN ('Komunikasi', 'Kerja sama tim', 'Microsoft Excel', 'Python') AND (SELECT id FROM mahasiswa WHERE nim = '1941720048') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720048'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '1941720048') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720048')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-1941720049.png' WHERE nim = '1941720049' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Sistem Kelistrikan Politeknik Negeri Malang angkatan 2019. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '1941720049' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Soekarno Hatta No. 149, RT 09/RW 08', provinsi = 'Jawa Timur', kode_pos = '61311' WHERE nim = '1941720049' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720049'), 'pendidikan', 'D-IV Sistem Kelistrikan', 'Politeknik Negeri Malang', '2019-08-25', '2023-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720049') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Sistem Kelistrikan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720049'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2016-07-15', '2019-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720049') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720049'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2021-02-03', '2021-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720049') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720049'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2020-02-03', '2020-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720049') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720049'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720049') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720049'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2020-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720049') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720049'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720049') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-1941720049.pdf' WHERE nim = '1941720049' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720049'), s.id FROM skill s WHERE s.nama IN ('Komunikasi', 'AutoCAD', 'Python', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '1941720049') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720049'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '1941720049') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720049')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2041720050.png' WHERE nim = '2041720050' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Teknik Elektronika Politeknik Negeri Malang angkatan 2020. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '2041720050' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Veteran No. 85, RT 09/RW 03', provinsi = 'Jawa Timur', kode_pos = '66211' WHERE nim = '2041720050' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720050'), 'pendidikan', 'D-IV Teknik Elektronika', 'Politeknik Negeri Malang', '2020-08-25', '2024-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720050') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknik Elektronika') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720050'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2017-07-15', '2020-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720050') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720050'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2022-02-03', '2022-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720050') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720050'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2021-02-03', '2021-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720050') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720050'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720050') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720050'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720050') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720050'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720050') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2041720050.pdf' WHERE nim = '2041720050' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720050'), s.id FROM skill s WHERE s.nama IN ('Microsoft Excel', 'Kerja sama tim', 'Komunikasi', 'Python') AND (SELECT id FROM mahasiswa WHERE nim = '2041720050') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720050'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2041720050') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720050')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2141720051.png' WHERE nim = '2141720051' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Jaringan Telekomunikasi Digital Politeknik Negeri Malang angkatan 2021. Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.' WHERE nim = '2141720051' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Ahmad Yani No. 51, RT 03/RW 12', provinsi = 'Jawa Timur', kode_pos = '65141' WHERE nim = '2141720051' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720051'), 'pendidikan', 'D-IV Jaringan Telekomunikasi Digital', 'Politeknik Negeri Malang', '2021-08-25', '2025-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Elektro.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720051') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Jaringan Telekomunikasi Digital') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720051'), 'pendidikan', 'Teknik Instalasi Tenaga Listrik', 'SMK Negeri 5 Malang', '2018-07-15', '2021-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720051') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'pendidikan' AND x.judul = 'Teknik Instalasi Tenaga Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720051'), 'pengalaman', 'Teknisi Paruh Waktu', 'CV Sinar Elektrik', '2023-02-03', '2023-06-28', 'Memperbaiki instalasi listrik rumah dan gedung kecil.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720051') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'pengalaman' AND x.judul = 'Teknisi Paruh Waktu') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720051'), 'pengalaman', 'Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', '2022-02-03', '2022-06-28', 'Membantu pemasangan panel distribusi dan pengujian instalasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720051') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Teknisi Listrik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720051'), 'sertifikat', 'Dasar PLC Siemens', 'Siemens Learning', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720051') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'sertifikat' AND x.judul = 'Dasar PLC Siemens') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720051'), 'sertifikat', 'Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720051') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'sertifikat' AND x.judul = 'Teknisi Instalasi Listrik (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720051'), 'portofolio', 'Sistem Monitoring Daya Berbasis IoT', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/iot-daya', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720051') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Monitoring Daya Berbasis IoT') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2141720051.pdf' WHERE nim = '2141720051' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720051'), s.id FROM skill s WHERE s.nama IN ('AutoCAD', 'Python', 'Komunikasi', 'Kerja sama tim', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '2141720051') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720051'), b.id FROM bidang b WHERE b.nama IN ('Kelistrikan', 'Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2141720051') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720051')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2141720052.png' WHERE nim = '2141720052' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-III Teknik Kimia Politeknik Negeri Malang angkatan 2021. Teliti dan disiplin di laboratorium. Tertarik pada pengendalian mutu dan pengelolaan lingkungan industri.' WHERE nim = '2141720052' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Soekarno Hatta No. 131, RT 03/RW 06', provinsi = 'Jawa Timur', kode_pos = '61311' WHERE nim = '2141720052' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720052'), 'pendidikan', 'D-III Teknik Kimia', 'Politeknik Negeri Malang', '2021-08-25', '2024-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Kimia.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720052') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Teknik Kimia') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720052'), 'pendidikan', 'IPA', 'SMA Negeri 3 Malang', '2018-07-15', '2021-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720052') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'pendidikan' AND x.judul = 'IPA') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720052'), 'pengalaman', 'Asisten Laboratorium Kimia Analitik', 'Politeknik Negeri Malang', '2023-02-03', '2023-06-28', 'Menyiapkan larutan standar dan membimbing praktikum.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720052') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Kimia Analitik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720052'), 'pengalaman', 'Magang Analis Laboratorium', 'PT Wilmar Nabati Indonesia', '2022-02-03', '2022-06-28', 'Menganalisis kadar asam lemak bebas dan kadar air bahan baku.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720052') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Analis Laboratorium') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720052'), 'sertifikat', 'Analis Kimia Muda (BNSP)', 'LSP Kimia', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720052') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'sertifikat' AND x.judul = 'Analis Kimia Muda (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720052'), 'sertifikat', 'ISO 14001 Awareness', 'Lembaga Pelatihan Mutu', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720052') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'sertifikat' AND x.judul = 'ISO 14001 Awareness') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720052'), 'portofolio', 'Pengolahan Limbah Cair Tahu Skala Lab', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-limbah', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720052') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'portofolio' AND x.judul = 'Pengolahan Limbah Cair Tahu Skala Lab') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2141720052.pdf' WHERE nim = '2141720052' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720052'), s.id FROM skill s WHERE s.nama IN ('Microsoft Excel', 'Komunikasi', 'Manajemen waktu', 'Bahasa Inggris') AND (SELECT id FROM mahasiswa WHERE nim = '2141720052') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720052'), b.id FROM bidang b WHERE b.nama IN ('Kimia', 'Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '2141720052') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720052')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-1941720053.png' WHERE nim = '1941720053' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Teknologi Kimia Industri Politeknik Negeri Malang angkatan 2019. Teliti dan disiplin di laboratorium. Tertarik pada pengendalian mutu dan pengelolaan lingkungan industri.' WHERE nim = '1941720053' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Sumbersari No. 133, RT 05/RW 01', provinsi = 'Jawa Timur', kode_pos = '65311' WHERE nim = '1941720053' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720053'), 'pendidikan', 'D-IV Teknologi Kimia Industri', 'Politeknik Negeri Malang', '2019-08-25', '2023-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknik Kimia.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720053') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknologi Kimia Industri') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720053'), 'pendidikan', 'IPA', 'SMA Negeri 3 Malang', '2016-07-15', '2019-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720053') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'pendidikan' AND x.judul = 'IPA') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720053'), 'pengalaman', 'Magang Analis Laboratorium', 'PT Wilmar Nabati Indonesia', '2021-02-03', '2021-06-28', 'Menganalisis kadar asam lemak bebas dan kadar air bahan baku.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720053') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Analis Laboratorium') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720053'), 'pengalaman', 'Asisten Laboratorium Kimia Analitik', 'Politeknik Negeri Malang', '2020-02-03', '2020-06-28', 'Menyiapkan larutan standar dan membimbing praktikum.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720053') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Kimia Analitik') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720053'), 'sertifikat', 'Analis Kimia Muda (BNSP)', 'LSP Kimia', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720053') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'sertifikat' AND x.judul = 'Analis Kimia Muda (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720053'), 'sertifikat', 'ISO 14001 Awareness', 'Lembaga Pelatihan Mutu', '2020-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720053') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'sertifikat' AND x.judul = 'ISO 14001 Awareness') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720053'), 'portofolio', 'Pengolahan Limbah Cair Tahu Skala Lab', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-limbah', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '1941720053') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'portofolio' AND x.judul = 'Pengolahan Limbah Cair Tahu Skala Lab') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-1941720053.pdf' WHERE nim = '1941720053' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720053'), s.id FROM skill s WHERE s.nama IN ('Manajemen waktu', 'Kerja sama tim', 'Bahasa Inggris', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '1941720053') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '1941720053'), b.id FROM bidang b WHERE b.nama IN ('Kimia', 'Manufaktur') AND (SELECT id FROM mahasiswa WHERE nim = '1941720053') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '1941720053')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2141720054.png' WHERE nim = '2141720054' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-II Pengembangan Peranti Lunak Situs Politeknik Negeri Malang angkatan 2021. Senang membangun aplikasi web yang rapi dan mudah dipakai. Terbiasa bekerja dalam tim dengan Git dan metode agile.' WHERE nim = '2141720054' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Diponegoro No. 156, RT 05/RW 07', provinsi = 'Jawa Timur', kode_pos = '67311' WHERE nim = '2141720054' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720054'), 'pendidikan', 'D-II Pengembangan Peranti Lunak Situs', 'Politeknik Negeri Malang', '2021-08-25', '2024-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknologi Informasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720054') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'pendidikan' AND x.judul = 'D-II Pengembangan Peranti Lunak Situs') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720054'), 'pendidikan', 'Rekayasa Perangkat Lunak', 'SMK Negeri 4 Malang', '2018-07-15', '2021-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720054') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'pendidikan' AND x.judul = 'Rekayasa Perangkat Lunak') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720054'), 'pengalaman', 'Asisten Laboratorium Pemrograman', 'Politeknik Negeri Malang', '2023-02-03', '2023-06-28', 'Mendampingi praktikum pemrograman web untuk mahasiswa semester 1.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720054') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Pemrograman') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720054'), 'pengalaman', 'Freelance Frontend Developer', 'Proyek UMKM', '2022-02-03', '2022-06-28', 'Membuat landing page responsif untuk 4 usaha kecil di Malang.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720054') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'pengalaman' AND x.judul = 'Freelance Frontend Developer') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720054'), 'sertifikat', 'Google UX Design Certificate', 'Coursera', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720054') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'sertifikat' AND x.judul = 'Google UX Design Certificate') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720054'), 'sertifikat', 'Junior Web Developer (BNSP)', 'LSP Politeknik Negeri Malang', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720054') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'sertifikat' AND x.judul = 'Junior Web Developer (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720054'), 'portofolio', 'Aplikasi Kasir UMKM Berbasis Web', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/kasir-umkm', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720054') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'portofolio' AND x.judul = 'Aplikasi Kasir UMKM Berbasis Web') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2141720054.pdf' WHERE nim = '2141720054' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720054'), s.id FROM skill s WHERE s.nama IN ('Figma', 'HTML', 'Laravel', 'PostgreSQL', 'UI/UX Design', 'Git') AND (SELECT id FROM mahasiswa WHERE nim = '2141720054') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720054'), b.id FROM bidang b WHERE b.nama IN ('Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2141720054') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720054')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2141720055.png' WHERE nim = '2141720055' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Teknik Informatika Politeknik Negeri Malang angkatan 2021. Senang membangun aplikasi web yang rapi dan mudah dipakai. Terbiasa bekerja dalam tim dengan Git dan metode agile.' WHERE nim = '2141720055' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Soekarno Hatta No. 171, RT 05/RW 02', provinsi = 'Jawa Timur', kode_pos = '61211' WHERE nim = '2141720055' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720055'), 'pendidikan', 'D-IV Teknik Informatika', 'Politeknik Negeri Malang', '2021-08-25', '2025-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknologi Informasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720055') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Teknik Informatika') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720055'), 'pendidikan', 'Rekayasa Perangkat Lunak', 'SMK Negeri 4 Malang', '2018-07-15', '2021-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720055') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'pendidikan' AND x.judul = 'Rekayasa Perangkat Lunak') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720055'), 'pengalaman', 'Magang Web Developer', 'PT Sinergi Data Nusantara', '2023-02-03', '2023-06-28', 'Membuat fitur dashboard admin dengan Laravel dan PostgreSQL.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720055') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Web Developer') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720055'), 'pengalaman', 'Asisten Laboratorium Pemrograman', 'Politeknik Negeri Malang', '2022-02-03', '2022-06-28', 'Mendampingi praktikum pemrograman web untuk mahasiswa semester 1.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720055') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Pemrograman') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720055'), 'sertifikat', 'Junior Web Developer (BNSP)', 'LSP Politeknik Negeri Malang', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720055') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'sertifikat' AND x.judul = 'Junior Web Developer (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720055'), 'sertifikat', 'Dicoding: Belajar Dasar Pemrograman Web', 'Dicoding Indonesia', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720055') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'sertifikat' AND x.judul = 'Dicoding: Belajar Dasar Pemrograman Web') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720055'), 'portofolio', 'Sistem Informasi Perpustakaan', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/perpus', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720055') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Informasi Perpustakaan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2141720055.pdf' WHERE nim = '2141720055' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720055'), s.id FROM skill s WHERE s.nama IN ('HTML', 'JavaScript', 'CSS', 'Figma') AND (SELECT id FROM mahasiswa WHERE nim = '2141720055') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720055'), b.id FROM bidang b WHERE b.nama IN ('Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2141720055') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720055')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2041720056.png' WHERE nim = '2041720056' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Sistem Informasi Bisnis Politeknik Negeri Malang angkatan 2020. Senang membangun aplikasi web yang rapi dan mudah dipakai. Terbiasa bekerja dalam tim dengan Git dan metode agile.' WHERE nim = '2041720056' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Ahmad Yani No. 14, RT 08/RW 09', provinsi = 'Jawa Timur', kode_pos = '61111' WHERE nim = '2041720056' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720056'), 'pendidikan', 'D-IV Sistem Informasi Bisnis', 'Politeknik Negeri Malang', '2020-08-25', '2024-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknologi Informasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720056') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Sistem Informasi Bisnis') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720056'), 'pendidikan', 'Rekayasa Perangkat Lunak', 'SMK Negeri 4 Malang', '2017-07-15', '2020-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720056') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'pendidikan' AND x.judul = 'Rekayasa Perangkat Lunak') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720056'), 'pengalaman', 'Freelance Frontend Developer', 'Proyek UMKM', '2022-02-03', '2022-06-28', 'Membuat landing page responsif untuk 4 usaha kecil di Malang.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720056') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'pengalaman' AND x.judul = 'Freelance Frontend Developer') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720056'), 'pengalaman', 'Asisten Laboratorium Pemrograman', 'Politeknik Negeri Malang', '2021-02-03', '2021-06-28', 'Mendampingi praktikum pemrograman web untuk mahasiswa semester 1.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720056') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Pemrograman') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720056'), 'sertifikat', 'Junior Web Developer (BNSP)', 'LSP Politeknik Negeri Malang', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720056') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'sertifikat' AND x.judul = 'Junior Web Developer (BNSP)') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720056'), 'sertifikat', 'Google UX Design Certificate', 'Coursera', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720056') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'sertifikat' AND x.judul = 'Google UX Design Certificate') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720056'), 'portofolio', 'Sistem Informasi Perpustakaan', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/perpus', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720056') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Informasi Perpustakaan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2041720056.pdf' WHERE nim = '2041720056' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720056'), s.id FROM skill s WHERE s.nama IN ('Laravel', 'PHP', 'JavaScript', 'Git', 'Python') AND (SELECT id FROM mahasiswa WHERE nim = '2041720056') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720056'), b.id FROM bidang b WHERE b.nama IN ('Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2041720056') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720056')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2041720057.png' WHERE nim = '2041720057' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-III Akuntansi Politeknik Negeri Malang angkatan 2020. Teliti dengan angka dan terbiasa menyusun laporan keuangan. Siap belajar sistem akuntansi perusahaan.' WHERE nim = '2041720057' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Sumbersari No. 59, RT 04/RW 12', provinsi = 'Jawa Timur', kode_pos = '64111' WHERE nim = '2041720057' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720057'), 'pendidikan', 'D-III Akuntansi', 'Politeknik Negeri Malang', '2020-08-25', '2023-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Akuntansi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720057') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'pendidikan' AND x.judul = 'D-III Akuntansi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720057'), 'pendidikan', 'Akuntansi dan Keuangan Lembaga', 'SMK Negeri 1 Malang', '2017-07-15', '2020-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720057') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'pendidikan' AND x.judul = 'Akuntansi dan Keuangan Lembaga') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720057'), 'pengalaman', 'Bendahara Himpunan Mahasiswa', 'Himpunan Mahasiswa Akuntansi', '2022-02-03', '2022-06-28', 'Mengelola kas dan laporan pertanggungjawaban kegiatan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720057') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'pengalaman' AND x.judul = 'Bendahara Himpunan Mahasiswa') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720057'), 'pengalaman', 'Magang Staf Akuntansi', 'PT Bank Mandiri Tbk', '2021-02-03', '2021-06-28', 'Membantu rekonsiliasi bank dan penyusunan laporan harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720057') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Staf Akuntansi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720057'), 'sertifikat', 'Microsoft Office Specialist: Excel', 'Microsoft', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720057') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'sertifikat' AND x.judul = 'Microsoft Office Specialist: Excel') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720057'), 'sertifikat', 'Brevet Pajak A dan B', 'IAI Wilayah Jawa Timur', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720057') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'sertifikat' AND x.judul = 'Brevet Pajak A dan B') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720057'), 'portofolio', 'Laporan Keuangan UMKM Kopi Lokal', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-laporan', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720057') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'portofolio' AND x.judul = 'Laporan Keuangan UMKM Kopi Lokal') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2041720057.pdf' WHERE nim = '2041720057' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720057'), s.id FROM skill s WHERE s.nama IN ('Bahasa Inggris', 'Kerja sama tim', 'Manajemen waktu', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '2041720057') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720057'), b.id FROM bidang b WHERE b.nama IN ('Keuangan') AND (SELECT id FROM mahasiswa WHERE nim = '2041720057') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720057')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2141720058.png' WHERE nim = '2141720058' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Akuntansi Manajemen Politeknik Negeri Malang angkatan 2021. Teliti dengan angka dan terbiasa menyusun laporan keuangan. Siap belajar sistem akuntansi perusahaan.' WHERE nim = '2141720058' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Kawi No. 30, RT 06/RW 12', provinsi = 'Jawa Timur', kode_pos = '67111' WHERE nim = '2141720058' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720058'), 'pendidikan', 'D-IV Akuntansi Manajemen', 'Politeknik Negeri Malang', '2021-08-25', '2025-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Akuntansi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720058') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Akuntansi Manajemen') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720058'), 'pendidikan', 'Akuntansi dan Keuangan Lembaga', 'SMK Negeri 1 Malang', '2018-07-15', '2021-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720058') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'pendidikan' AND x.judul = 'Akuntansi dan Keuangan Lembaga') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720058'), 'pengalaman', 'Bendahara Himpunan Mahasiswa', 'Himpunan Mahasiswa Akuntansi', '2023-02-03', '2023-06-28', 'Mengelola kas dan laporan pertanggungjawaban kegiatan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720058') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'pengalaman' AND x.judul = 'Bendahara Himpunan Mahasiswa') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720058'), 'pengalaman', 'Magang Staf Akuntansi', 'PT Bank Mandiri Tbk', '2022-02-03', '2022-06-28', 'Membantu rekonsiliasi bank dan penyusunan laporan harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720058') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Staf Akuntansi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720058'), 'sertifikat', 'Microsoft Office Specialist: Excel', 'Microsoft', '2023-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720058') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'sertifikat' AND x.judul = 'Microsoft Office Specialist: Excel') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720058'), 'sertifikat', 'Brevet Pajak A dan B', 'IAI Wilayah Jawa Timur', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720058') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'sertifikat' AND x.judul = 'Brevet Pajak A dan B') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720058'), 'portofolio', 'Laporan Keuangan UMKM Kopi Lokal', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-laporan', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2141720058') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'portofolio' AND x.judul = 'Laporan Keuangan UMKM Kopi Lokal') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2141720058.pdf' WHERE nim = '2141720058' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720058'), s.id FROM skill s WHERE s.nama IN ('Manajemen waktu', 'Komunikasi', 'Kerja sama tim', 'Bahasa Inggris', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '2141720058') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2141720058'), b.id FROM bidang b WHERE b.nama IN ('Keuangan') AND (SELECT id FROM mahasiswa WHERE nim = '2141720058') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2141720058')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2041720059.png' WHERE nim = '2041720059' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Alumni D-IV Keuangan Politeknik Negeri Malang angkatan 2020. Teliti dengan angka dan terbiasa menyusun laporan keuangan. Siap belajar sistem akuntansi perusahaan.' WHERE nim = '2041720059' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Kertoraharjo No. 59, RT 03/RW 07', provinsi = 'Jawa Timur', kode_pos = '60111' WHERE nim = '2041720059' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720059'), 'pendidikan', 'D-IV Keuangan', 'Politeknik Negeri Malang', '2020-08-25', '2024-08-30', 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Akuntansi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720059') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Keuangan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720059'), 'pendidikan', 'Akuntansi dan Keuangan Lembaga', 'SMK Negeri 1 Malang', '2017-07-15', '2020-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720059') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'pendidikan' AND x.judul = 'Akuntansi dan Keuangan Lembaga') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720059'), 'pengalaman', 'Bendahara Himpunan Mahasiswa', 'Himpunan Mahasiswa Akuntansi', '2022-02-03', '2022-06-28', 'Mengelola kas dan laporan pertanggungjawaban kegiatan.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720059') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'pengalaman' AND x.judul = 'Bendahara Himpunan Mahasiswa') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720059'), 'pengalaman', 'Magang Staf Akuntansi', 'PT Bank Mandiri Tbk', '2021-02-03', '2021-06-28', 'Membantu rekonsiliasi bank dan penyusunan laporan harian.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720059') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'pengalaman' AND x.judul = 'Magang Staf Akuntansi') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720059'), 'sertifikat', 'Brevet Pajak A dan B', 'IAI Wilayah Jawa Timur', '2022-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720059') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'sertifikat' AND x.judul = 'Brevet Pajak A dan B') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720059'), 'sertifikat', 'Microsoft Office Specialist: Excel', 'Microsoft', '2021-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720059') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'sertifikat' AND x.judul = 'Microsoft Office Specialist: Excel') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720059'), 'portofolio', 'Laporan Keuangan UMKM Kopi Lokal', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://drive.google.com/contoh-laporan', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2041720059') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'portofolio' AND x.judul = 'Laporan Keuangan UMKM Kopi Lokal') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2041720059.pdf' WHERE nim = '2041720059' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720059'), s.id FROM skill s WHERE s.nama IN ('Kerja sama tim', 'Manajemen waktu', 'Bahasa Inggris', 'Komunikasi', 'Microsoft Excel') AND (SELECT id FROM mahasiswa WHERE nim = '2041720059') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2041720059'), b.id FROM bidang b WHERE b.nama IN ('Keuangan') AND (SELECT id FROM mahasiswa WHERE nim = '2041720059') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2041720059')) ON CONFLICT DO NOTHING;
UPDATE mahasiswa SET foto = 'dummy-foto-2341720099.png' WHERE nim = '2341720099' AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');
UPDATE mahasiswa SET tentang = 'Mahasiswa D-IV Sistem Informasi Bisnis Politeknik Negeri Malang angkatan 2023. Senang membangun aplikasi web yang rapi dan mudah dipakai. Terbiasa bekerja dalam tim dengan Git dan metode agile.' WHERE nim = '2341720099' AND coalesce(trim(tentang), '') = '';
UPDATE mahasiswa SET alamat = 'Jl. Veteran No. 63, RT 02/RW 05', provinsi = 'Jawa Timur', kode_pos = '66111' WHERE nim = '2341720099' AND coalesce(alamat, '') = '';
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720099'), 'pendidikan', 'D-IV Sistem Informasi Bisnis', 'Politeknik Negeri Malang', '2023-08-25', NULL, 'IPK sementara di atas 3,00. Aktif di kegiatan jurusan Teknologi Informasi.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720099') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'pendidikan' AND x.judul = 'D-IV Sistem Informasi Bisnis') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720099'), 'pendidikan', 'Rekayasa Perangkat Lunak', 'SMK Negeri 4 Malang', '2020-07-15', '2023-05-30', 'Lulus dengan nilai rata-rata baik.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720099') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'pendidikan' AND x.judul = 'Rekayasa Perangkat Lunak') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'pendidikan') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720099'), 'pengalaman', 'Freelance Frontend Developer', 'Proyek UMKM', '2025-02-03', '2025-06-28', 'Membuat landing page responsif untuk 4 usaha kecil di Malang.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720099') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'pengalaman' AND x.judul = 'Freelance Frontend Developer') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720099'), 'pengalaman', 'Asisten Laboratorium Pemrograman', 'Politeknik Negeri Malang', '2024-02-03', '2024-06-28', 'Mendampingi praktikum pemrograman web untuk mahasiswa semester 1.', NULL, NULL WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720099') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'pengalaman' AND x.judul = 'Asisten Laboratorium Pemrograman') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'pengalaman') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720099'), 'sertifikat', 'Dicoding: Belajar Dasar Pemrograman Web', 'Dicoding Indonesia', '2025-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720099') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'sertifikat' AND x.judul = 'Dicoding: Belajar Dasar Pemrograman Web') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720099'), 'sertifikat', 'Google UX Design Certificate', 'Coursera', '2024-11-20', NULL, NULL, NULL, 'contoh-sertifikat.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720099') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'sertifikat' AND x.judul = 'Google UX Design Certificate') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'sertifikat') < 2;
INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720099'), 'portofolio', 'Sistem Informasi Perpustakaan', NULL, NULL, NULL, 'Proyek mandiri/tugas akhir.', 'https://github.com/contoh/perpus', 'contoh-portofolio.pdf' WHERE (SELECT id FROM mahasiswa WHERE nim = '2341720099') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'portofolio' AND x.judul = 'Sistem Informasi Perpustakaan') AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099') AND x.tipe = 'portofolio') < 2;
UPDATE mahasiswa SET file_cv = 'dummy-cv-2341720099.pdf' WHERE nim = '2341720099' AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');
INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720099'), s.id FROM skill s WHERE s.nama IN ('PHP', 'UI/UX Design', 'Figma', 'JavaScript', 'HTML') AND (SELECT id FROM mahasiswa WHERE nim = '2341720099') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099')) ON CONFLICT DO NOTHING;
INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT (SELECT id FROM mahasiswa WHERE nim = '2341720099'), b.id FROM bidang b WHERE b.nama IN ('Teknologi Informasi') AND (SELECT id FROM mahasiswa WHERE nim = '2341720099') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2341720099')) ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- Lengkapi detail item profil data contoh yang masih kosong (revisi tahap 2)
-- ---------------------------------------------------------------------
-- (kolom dibuat di sini juga, jadi aman bila 05 dijalankan sebelum 06)
ALTER TABLE profil_item ADD COLUMN IF NOT EXISTS detail jsonb NOT NULL DEFAULT '{}'::jsonb;
UPDATE profil_item pi SET detail = jsonb_strip_nulls(jsonb_build_object(
    'jenjang', CASE ps.jenjang WHEN 'D-II' THEN 'D2' WHEN 'D-III' THEN 'D3' WHEN 'D-IV' THEN 'D4 / Sarjana Terapan' ELSE 'S2 Terapan' END,
    'fakultas', j.nama, 'nomor_induk', m.nim, 'kota', 'Malang',
    'nilai', replace(to_char(3.20 + (pi.id % 7) * 0.1, 'FM0.00'), '.', ','), 'skala', '4,00',
    'akreditasi', CASE WHEN pi.id % 3 = 0 THEN 'A' ELSE 'Unggul' END))
  FROM mahasiswa m JOIN program_studi ps ON ps.id = m.program_studi_id JOIN jurusan j ON j.id = ps.jurusan_id
 WHERE pi.mahasiswa_id = m.id AND pi.tipe = 'pendidikan' AND pi.detail = '{}'::jsonb AND pi.instansi ILIKE '%Politeknik Negeri Malang%';

UPDATE profil_item pi SET detail = jsonb_build_object(
    'jenjang', CASE WHEN pi.instansi ILIKE '%SMK%' THEN 'SMK' WHEN pi.instansi ILIKE '%MA %' OR pi.instansi ILIKE 'MAN%' THEN 'MA' ELSE 'SMA' END,
    'nomor_induk', '00' || (5000000 + pi.id * 37)::text,
    'kota', COALESCE(NULLIF(regexp_replace(pi.instansi, '^.*\s', ''), ''), 'Malang'),
    'nilai', (82 + pi.id % 13)::text || ',' || (pi.id % 10)::text, 'skala', '100',
    'nomor_ijazah', 'DN-05/' || CASE WHEN pi.instansi ILIKE '%SMK%' THEN 'M-SMK' ELSE 'M-SMA' END || '/K13/' || lpad((pi.id * 131 % 99999)::text, 5, '0'),
    'akreditasi', 'A')
 WHERE pi.tipe = 'pendidikan' AND pi.detail = '{}'::jsonb;

UPDATE profil_item pi SET detail = jsonb_build_object(
    'jenis', CASE WHEN pi.judul ILIKE '%magang%' OR pi.judul ILIKE '%intern%' OR pi.judul ILIKE '%PKL%' THEN 'Magang / PKL'
                  WHEN pi.judul ILIKE '%asisten%' OR pi.judul ILIKE '%ketua%' OR pi.judul ILIKE '%anggota%' OR pi.judul ILIKE '%pengurus%' THEN 'Organisasi'
                  WHEN pi.judul ILIKE '%panitia%' OR pi.judul ILIKE '%koordinator%' THEN 'Kepanitiaan'
                  WHEN pi.judul ILIKE '%freelance%' THEN 'Freelance'
                  ELSE (ARRAY['Magang / PKL','Proyek','Kerja paruh waktu'])[1 + pi.id % 3] END,
    'bidang', (ARRAY['Teknologi Informasi','Operasional','Administrasi','Produksi','Pemasaran'])[1 + pi.id % 5],
    'lokasi', CASE WHEN pi.instansi ILIKE '%Polinema%' OR pi.instansi ILIKE '%Politeknik Negeri Malang%' THEN 'Malang' ELSE (ARRAY['Malang','Surabaya','Sidoarjo','Pasuruan','Jakarta'])[1 + pi.id % 5] END,
    'sistem', (ARRAY['Di kantor (WFO)','Hybrid','Di kantor (WFO)','Jarak jauh (WFH)'])[1 + pi.id % 4],
    'pencapaian', (ARRAY['Menyelesaikan seluruh target tugas tepat waktu dan mendapat nilai sangat baik dari pembimbing.',
                         'Membantu mempercepat penyusunan laporan bulanan sekitar 30%.',
                         'Mendampingi lebih dari 40 peserta dan menyusun modul pendukung.',
                         'Menyelesaikan 10+ fitur/pekerjaan yang dipakai tim setiap hari.'])[1 + pi.id % 4],
    'tools', (ARRAY['PHP, PostgreSQL, Git','Microsoft Excel, Google Sheets','Figma, Canva','AutoCAD, Microsoft Office','Python, Power BI'])[1 + pi.id % 5],
    'referensi_nama', (ARRAY['Hendra Wijaya (Supervisor)','Rina Kartika (HR)','Dr. Agus Salim (Pembimbing)','Dewi Lestari (Manajer)'])[1 + pi.id % 4])
 WHERE pi.tipe = 'pengalaman' AND pi.detail = '{}'::jsonb;

UPDATE profil_item pi SET detail = jsonb_build_object(
    'jenis', CASE WHEN pi.judul ILIKE '%BNSP%' OR pi.instansi ILIKE '%LSP%' OR pi.instansi ILIKE '%Sertifikasi Profesi%' THEN 'Sertifikasi kompetensi (BNSP/LSP)'
                  WHEN pi.judul ILIKE '%TOEFL%' OR pi.judul ILIKE '%TOEIC%' OR pi.judul ILIKE '%IELTS%' OR pi.judul ILIKE '%bahasa%' OR pi.judul ILIKE '%English%' THEN 'Kemampuan bahasa'
                  WHEN pi.judul ILIKE '%juara%' OR pi.judul ILIKE '%lomba%' THEN 'Lomba / penghargaan'
                  WHEN pi.judul ILIKE '%seminar%' OR pi.judul ILIKE '%workshop%' THEN 'Seminar / workshop'
                  WHEN pi.instansi ILIKE '%Cisco%' OR pi.instansi ILIKE '%Google%' OR pi.instansi ILIKE '%Microsoft%' OR pi.instansi ILIKE '%AWS%' OR pi.instansi ILIKE '%Oracle%' THEN 'Sertifikasi profesional / internasional'
                  ELSE 'Pelatihan / kursus' END,
    'nomor', upper(substr(md5(pi.id::text || pi.judul), 1, 4)) || '-' || to_char(COALESCE(pi.mulai, DATE '2025-01-01'), 'YYYY') || '-' || lpad((pi.id * 97 % 100000)::text, 5, '0'),
    'skor', CASE WHEN pi.judul ILIKE '%TOEFL%' THEN (480 + pi.id % 90)::text WHEN pi.judul ILIKE '%TOEIC%' THEN (650 + pi.id % 250)::text ELSE 'Kompeten' END)
 WHERE pi.tipe = 'sertifikat' AND pi.detail = '{}'::jsonb;

COMMIT;

-- #####################################################################
-- ##### Isi dari 07-peningkatan-materi-dosen.sql
-- #####################################################################
-- =====================================================================
-- KarirKu Polinema · 07 · Penerapan materi Advanced Database (PostgreSQL)
--
-- Jalankan SESUDAH 01–06. Aman dijalankan berulang (idempoten).
-- Aplikasi menjalankannya otomatis bersama migrasi lain (lihat Database.php).
--
--   Bab 3  SQL Tingkat Lanjut  -> A. View v_rekap_lamaran
--   Bab 5  Index & Optimasi    -> B. Index kolom foreign key
--   Bab 6  Pemrograman 1       -> F. Function + exception handling (retensi data)
--   Bab 7  Pemrograman 2       -> D. Trigger (penjaga status, arsip riwayat)
--   Bab 10 Full-Text Search    -> C. search_vector + GIN + trigger pemelihara
--
-- Tujuan jangka panjang (hosting, data bertambah bertahun-tahun):
--   - kueri tetap cepat saat tabel besar (index, GIN),
--   - aturan penting dijaga di database, bukan hanya di PHP, sehingga tetap
--     berlaku walau ada bug aplikasi atau SQL dijalankan langsung.
-- =====================================================================

-- ---------------------------------------------------------------------
-- A. BAB 3 · View: satu definisi untuk join rekap lamaran (6 tabel)
--    Dipakai Lamaran::rekapAdmin / ringkasanRekap / rekapPerPerusahaan.
--    CREATE OR REPLACE agar hak akses (GRANT) yang sudah diberikan tidak hilang.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_rekap_lamaran AS
SELECT lm.id, lm.mahasiswa_id, lm.lowongan_id, lm.tanggal_lamar, lm.status,
       lm.jenis_cv, lm.file_cv, lm.file_ktm, lm.file_surat_pengantar,
       lm.catatan_pelamar, lm.snapshot_profil, lm.catatan_perusahaan, lm.diperbarui_pada,
       l.posisi, l.perusahaan_id, pr.nama_perusahaan,
       m.nama AS nama_mahasiswa, m.nim, m.angkatan,
       ps.id AS prodi_id, ps.nama AS nama_prodi, ps.jenjang,
       j.id AS jurusan_id, j.nama AS nama_jurusan
  FROM lamaran lm
  JOIN lowongan l       ON l.id  = lm.lowongan_id
  JOIN perusahaan pr    ON pr.id = l.perusahaan_id
  JOIN mahasiswa m      ON m.id  = lm.mahasiswa_id
  JOIN program_studi ps ON ps.id = m.program_studi_id
  JOIN jurusan j        ON j.id  = ps.jurusan_id;

COMMENT ON VIEW v_rekap_lamaran IS
  'Lamaran + lowongan + perusahaan + mahasiswa + prodi + jurusan (bahan rekap admin dan PDF).';

-- ---------------------------------------------------------------------
-- B. BAB 5 · Index untuk kolom foreign key
--    PostgreSQL TIDAK membuat index otomatis untuk FK. Tanpa index, JOIN dan
--    ON DELETE CASCADE / SET NULL membaca seluruh tabel anak (Seq Scan).
--    Trade-off: tiap index menambah sedikit biaya tulis, jadi hanya dipasang
--    pada tabel yang akan terus bertambah. Sengaja DILEWATI (tabel kecil, kolom
--    jarang dipakai): verifikasi_akun.admin_id, pengiriman_loker.admin_id,
--    admin_jurusan_kontak.diperbarui_oleh, pengaturan.diperbarui_oleh.
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_mahasiswa_prodi          ON mahasiswa (program_studi_id);
CREATE INDEX IF NOT EXISTS idx_dokumen_verifikasi_user  ON dokumen_verifikasi (pengguna_id);
CREATE INDEX IF NOT EXISTS idx_verifikasi_akun_user     ON verifikasi_akun (pengguna_id);
CREATE INDEX IF NOT EXISTS idx_mahasiswa_skill_skill    ON mahasiswa_skill (skill_id);
CREATE INDEX IF NOT EXISTS idx_mahasiswa_minat_bidang   ON mahasiswa_minat (bidang_id);
CREATE INDEX IF NOT EXISTS idx_lowongan_bidang          ON lowongan (bidang_id);
CREATE INDEX IF NOT EXISTS idx_lowongan_jurusan_jurusan ON lowongan_jurusan (jurusan_id);
CREATE INDEX IF NOT EXISTS idx_lowongan_disimpan_low    ON lowongan_disimpan (lowongan_id);
CREATE INDEX IF NOT EXISTS idx_riwayat_lamaran_lamaran  ON riwayat_lamaran (lamaran_id, tanggal);
CREATE INDEX IF NOT EXISTS idx_riwayat_lamaran_oleh     ON riwayat_lamaran (diubah_oleh);
CREATE INDEX IF NOT EXISTS idx_pengiriman_loker_jurusan ON pengiriman_loker (jurusan_id);
CREATE INDEX IF NOT EXISTS idx_riwayat_lowongan_oleh    ON riwayat_lowongan (oleh);
CREATE INDEX IF NOT EXISTS idx_log_admin_admin          ON log_aktivitas_admin (admin_id);
CREATE INDEX IF NOT EXISTS idx_log_admin_target         ON log_aktivitas_admin (target_pengguna_id);

-- Index komposit (lowongan_id, status) melayani COUNT per status pada kartu
-- "Lowongan Saya" dan sekaligus menggantikan index satu kolom lowongan_id
-- (index yang tumpang tindih hanya memperlambat INSERT/UPDATE).
CREATE INDEX IF NOT EXISTS idx_lamaran_lowongan_status ON lamaran (lowongan_id, status);
DROP INDEX IF EXISTS idx_lamaran_lowongan;

-- Halaman rekap admin selalu mengurutkan lamaran dari yang terbaru dan hanya
-- menampilkan 10 baris. Tanpa index ini PostgreSQL menggabung dan mengurutkan
-- SELURUH lamaran dulu. Uji pada 60 ribu lamaran: 92 ms -> 0,8 ms.
CREATE INDEX IF NOT EXISTS idx_lamaran_tanggal ON lamaran (tanggal_lamar DESC, id DESC);

-- ---------------------------------------------------------------------
-- C. BAB 10 · Full-Text Search (pengganti ILIKE '%kata%' pada pencarian lowongan)
--    ILIKE '%kata%' membaca semua baris dan tidak bisa memakai index biasa;
--    FTS memakai index GIN, paham bentuk kata (stemming), dan bisa diberi bobot.
--
--    Konfigurasi 'karirku_cari' = salinan konfigurasi 'indonesian' bila tersedia
--    di PostgreSQL ini, kalau tidak, salinan 'simple' (tanpa stemming). Seluruh
--    SQL dan PHP hanya menyebut 'karirku_cari', jadi mudah diganti di satu tempat.
-- ---------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_ts_config c JOIN pg_namespace n ON n.oid = c.cfgnamespace
                  WHERE c.cfgname = 'karirku_cari' AND n.nspname = 'public') THEN
    IF EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'indonesian') THEN
      EXECUTE 'CREATE TEXT SEARCH CONFIGURATION public.karirku_cari (COPY = pg_catalog.indonesian)';
    ELSE
      EXECUTE 'CREATE TEXT SEARCH CONFIGURATION public.karirku_cari (COPY = pg_catalog.simple)';
      RAISE NOTICE 'Konfigurasi teks ''indonesian'' tidak ada di PostgreSQL ini; memakai ''simple'' (tanpa stemming).';
    END IF;
  END IF;
END $$;

ALTER TABLE lowongan ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Bobot: posisi A (paling penting), perusahaan & skill B, lokasi C, uraian D.
CREATE OR REPLACE FUNCTION fn_lowongan_vektor(
  p_posisi text, p_perusahaan text, p_skill text, p_lokasi text,
  p_deskripsi text, p_kualifikasi text
) RETURNS tsvector
LANGUAGE sql IMMUTABLE AS $$
  SELECT setweight(to_tsvector('public.karirku_cari'::regconfig, coalesce(p_posisi, '')), 'A')
      || setweight(to_tsvector('public.karirku_cari'::regconfig, coalesce(p_perusahaan, '')), 'B')
      || setweight(to_tsvector('public.karirku_cari'::regconfig, coalesce(p_skill, '')), 'B')
      || setweight(to_tsvector('public.karirku_cari'::regconfig, coalesce(p_lokasi, '')), 'C')
      || setweight(to_tsvector('public.karirku_cari'::regconfig,
                   coalesce(p_deskripsi, '') || ' ' || coalesce(p_kualifikasi, '')), 'D');
$$;

-- Trigger (Bab 7): vektor selalu mengikuti isi lowongan, tanpa perlu diingat PHP.
CREATE OR REPLACE FUNCTION fn_trg_lowongan_vektor() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.search_vector := fn_lowongan_vektor(
    NEW.posisi,
    (SELECT nama_perusahaan FROM perusahaan WHERE id = NEW.perusahaan_id),
    NEW.skill_dibutuhkan, NEW.lokasi, NEW.deskripsi, NEW.kualifikasi);
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_lowongan_vektor ON lowongan;
CREATE TRIGGER trg_lowongan_vektor
  BEFORE INSERT OR UPDATE OF posisi, perusahaan_id, skill_dibutuhkan, lokasi, deskripsi, kualifikasi
  ON lowongan FOR EACH ROW EXECUTE FUNCTION fn_trg_lowongan_vektor();

-- Perusahaan ganti nama -> vektor semua lowongannya ikut diperbarui.
CREATE OR REPLACE FUNCTION fn_trg_perusahaan_nama() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.nama_perusahaan IS DISTINCT FROM OLD.nama_perusahaan THEN
    UPDATE lowongan l
       SET search_vector = fn_lowongan_vektor(l.posisi, NEW.nama_perusahaan, l.skill_dibutuhkan,
                                              l.lokasi, l.deskripsi, l.kualifikasi)
     WHERE l.perusahaan_id = NEW.id;
  END IF;
  RETURN NULL;
END $$;

DROP TRIGGER IF EXISTS trg_perusahaan_nama ON perusahaan;
CREATE TRIGGER trg_perusahaan_nama
  AFTER UPDATE OF nama_perusahaan ON perusahaan
  FOR EACH ROW EXECUTE FUNCTION fn_trg_perusahaan_nama();

-- Isi vektor untuk lowongan yang sudah ada (hanya yang masih kosong).
UPDATE lowongan l
   SET search_vector = fn_lowongan_vektor(l.posisi, pr.nama_perusahaan, l.skill_dibutuhkan,
                                          l.lokasi, l.deskripsi, l.kualifikasi)
  FROM perusahaan pr
 WHERE pr.id = l.perusahaan_id AND l.search_vector IS NULL;

ALTER TABLE lowongan ALTER COLUMN search_vector SET NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lowongan_cari ON lowongan USING gin (search_vector);

-- ---------------------------------------------------------------------
-- D. BAB 7 · Trigger penjaga integritas lamaran
--    Aturan ini sudah ada di PHP (Lamaran::kunciBelumFinal). Dipasang juga di
--    database sebagai lapis kedua: tetap berlaku bila ada bug aplikasi, celah
--    SQL injection, atau perubahan manual lewat pgAdmin.
-- ---------------------------------------------------------------------

-- D1. Status final tidak boleh berubah, dan status tidak boleh mundur.
CREATE OR REPLACE FUNCTION fn_lamaran_jaga_status() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  rank_lama integer;
  rank_baru integer;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  IF OLD.status IN ('diterima', 'ditolak', 'dibatalkan') THEN
    RAISE EXCEPTION 'Lamaran % sudah berstatus final (%) dan tidak boleh diubah menjadi %.',
      OLD.id, OLD.status, NEW.status
      USING ERRCODE = 'check_violation';
  END IF;

  rank_lama := CASE OLD.status WHEN 'diajukan' THEN 1 WHEN 'screening' THEN 2 WHEN 'interview' THEN 3 ELSE 4 END;
  rank_baru := CASE NEW.status WHEN 'diajukan' THEN 1 WHEN 'screening' THEN 2 WHEN 'interview' THEN 3 ELSE 4 END;
  IF rank_baru < rank_lama THEN
    RAISE EXCEPTION 'Status lamaran % tidak boleh mundur dari % ke %.', OLD.id, OLD.status, NEW.status
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_lamaran_jaga_status ON lamaran;
CREATE TRIGGER trg_lamaran_jaga_status
  BEFORE UPDATE OF status ON lamaran
  FOR EACH ROW EXECUTE FUNCTION fn_lamaran_jaga_status();

-- D2. Setiap status lamaran WAJIB punya catatan riwayat.
--     Aplikasi tetap mencatat riwayat sendiri (lengkap dengan pelaku dan catatan).
--     Trigger ini DITUNDA sampai COMMIT (constraint trigger), jadi hanya menambah
--     catatan bila sampai akhir transaksi riwayat itu belum ada, misalnya status
--     diubah lewat pgAdmin. Tidak pernah menggandakan catatan dari aplikasi.
CREATE OR REPLACE FUNCTION fn_lamaran_pastikan_riwayat() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM lamaran WHERE id = NEW.id) THEN   -- baris bisa saja sudah dihapus
    INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan)
    SELECT NEW.id, NEW.status, NULL, 'Dicatat otomatis oleh database.'
     WHERE NOT EXISTS (SELECT 1 FROM riwayat_lamaran r
                        WHERE r.lamaran_id = NEW.id AND r.status = NEW.status);
  END IF;
  RETURN NULL;
END $$;

DROP TRIGGER IF EXISTS trg_lamaran_pastikan_riwayat ON lamaran;
CREATE CONSTRAINT TRIGGER trg_lamaran_pastikan_riwayat
  AFTER INSERT OR UPDATE OF status ON lamaran
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION fn_lamaran_pastikan_riwayat();

-- D3. Riwayat adalah arsip: isinya tidak boleh diubah. Pengecualian: kolom
--     diubah_oleh boleh menjadi NULL (aksi ON DELETE SET NULL saat akun dihapus).
CREATE OR REPLACE FUNCTION fn_riwayat_lamaran_tetap() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.lamaran_id IS DISTINCT FROM OLD.lamaran_id
     OR NEW.status  IS DISTINCT FROM OLD.status
     OR NEW.catatan IS DISTINCT FROM OLD.catatan
     OR NEW.tanggal IS DISTINCT FROM OLD.tanggal
     OR (NEW.diubah_oleh IS DISTINCT FROM OLD.diubah_oleh AND NEW.diubah_oleh IS NOT NULL) THEN
    RAISE EXCEPTION 'Riwayat lamaran adalah arsip dan tidak boleh diubah (id %).', OLD.id
      USING ERRCODE = 'restrict_violation';
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_riwayat_lamaran_tetap ON riwayat_lamaran;
CREATE TRIGGER trg_riwayat_lamaran_tetap
  BEFORE UPDATE ON riwayat_lamaran
  FOR EACH ROW EXECUTE FUNCTION fn_riwayat_lamaran_tetap();

-- ---------------------------------------------------------------------
-- E. Pembatas percobaan login (sebelumnya disimpan di SESI, sehingga penebak
--    password cukup membuang cookie untuk mengulang dari nol). Kini dihitung di
--    database per (email + alamat IP) dan per email. Kunci di-hash SHA-256:
--    tabel ini tidak menyimpan email atau IP mentah.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS percobaan_login (
  kunci          varchar(64)  PRIMARY KEY,
  jumlah         integer      NOT NULL DEFAULT 0 CHECK (jumlah >= 0),
  waktu_terakhir timestamptz  NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_percobaan_login_waktu ON percobaan_login (waktu_terakhir);

-- ---------------------------------------------------------------------
-- F. BAB 6 · Function + exception handling: retensi data lama
--    Tabel berikut terus bertambah dan sebagian berisi data pribadi (alamat
--    email, isi email). Tanpa pembersihan, ukurannya membengkak tiap tahun.
--    Bukan data inti: riwayat lamaran/lowongan dan log admin TIDAK dihapus.
--    Jalankan berkala sebagai pemilik database (cron), mis. sebulan sekali:
--        SELECT * FROM fn_bersihkan_data_lama();
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_bersihkan_data_lama(
  p_hari_log_email integer DEFAULT 180,
  p_hari_notifikasi integer DEFAULT 365
) RETURNS TABLE (tabel text, baris_dihapus bigint)
LANGUAGE plpgsql AS $$
DECLARE
  n bigint;
BEGIN
  IF p_hari_log_email < 30 OR p_hari_notifikasi < 30 THEN
    RAISE EXCEPTION 'Batas retensi minimal 30 hari (diberikan: % dan %).', p_hari_log_email, p_hari_notifikasi
      USING ERRCODE = 'invalid_parameter_value';
  END IF;

  DELETE FROM log_email WHERE dibuat_pada < now() - make_interval(days => p_hari_log_email);
  GET DIAGNOSTICS n = ROW_COUNT;  tabel := 'log_email';         baris_dihapus := n; RETURN NEXT;

  DELETE FROM notifikasi WHERE dibaca AND dibuat_pada < now() - make_interval(days => p_hari_notifikasi);
  GET DIAGNOSTICS n = ROW_COUNT;  tabel := 'notifikasi';        baris_dihapus := n; RETURN NEXT;

  DELETE FROM token_ingat WHERE kedaluwarsa < now();
  GET DIAGNOSTICS n = ROW_COUNT;  tabel := 'token_ingat';       baris_dihapus := n; RETURN NEXT;

  DELETE FROM reset_kata_sandi WHERE kedaluwarsa < now() - interval '7 days';
  GET DIAGNOSTICS n = ROW_COUNT;  tabel := 'reset_kata_sandi';  baris_dihapus := n; RETURN NEXT;

  DELETE FROM percobaan_login WHERE waktu_terakhir < now() - interval '1 day';
  GET DIAGNOSTICS n = ROW_COUNT;  tabel := 'percobaan_login';   baris_dihapus := n; RETURN NEXT;
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE EXCEPTION 'Akun database ini tidak berhak menghapus data. Jalankan fungsi ini sebagai pemilik database.'
      USING ERRCODE = 'insufficient_privilege';
END $$;

COMMENT ON FUNCTION fn_bersihkan_data_lama(integer, integer) IS
  'Hapus log email, notifikasi terbaca, token dan catatan percobaan login lama. Jalankan berkala sebagai pemilik database.';
