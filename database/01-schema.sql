-- =====================================================================
-- KarirKu Polinema - Skema PostgreSQL
-- Sesuai ERD-KarirKu.png dan EERD-KarirKu.png
-- =====================================================================

-- ------------------------- Referensi -------------------------
CREATE TABLE jurusan (
  id            serial PRIMARY KEY,
  nama          varchar(100) NOT NULL UNIQUE
);

CREATE TABLE program_studi (
  id            serial PRIMARY KEY,
  jurusan_id    integer NOT NULL REFERENCES jurusan(id) ON DELETE RESTRICT,
  nama          varchar(150) NOT NULL,
  jenjang       varchar(10)  NOT NULL CHECK (jenjang IN ('D-II','D-III','D-IV','S2')),
  -- Satu jurusan bisa punya nama program studi yang sama di dua jenjang,
  -- misalnya Teknik Elektronika yang dibuka pada D-III dan D-IV.
  UNIQUE (jurusan_id, nama, jenjang)
);

CREATE TABLE skill (
  id            serial PRIMARY KEY,
  nama          varchar(100) NOT NULL UNIQUE
);

CREATE TABLE bidang (
  id            serial PRIMARY KEY,
  nama          varchar(100) NOT NULL UNIQUE
);

-- ------------------------- Akun dan peran -------------------------
CREATE TABLE pengguna (
  id             serial PRIMARY KEY,
  email          varchar(255) NOT NULL UNIQUE,
  password_hash  varchar(255) NOT NULL,
  role           varchar(20)  NOT NULL CHECK (role IN ('mahasiswa','perusahaan','admin')),
  status_akun    varchar(20)  NOT NULL DEFAULT 'menunggu'
                 CHECK (status_akun IN ('menunggu','perbaikan','ditolak','aktif','nonaktif')),
  dibuat_pada    timestamp NOT NULL DEFAULT now(),
  terakhir_login timestamp
);

CREATE TABLE admin (
  id            serial PRIMARY KEY,
  pengguna_id   integer NOT NULL UNIQUE REFERENCES pengguna(id) ON DELETE CASCADE,
  nama          varchar(255) NOT NULL
);

CREATE TABLE mahasiswa (
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
  -- Kolom di bawah dipakai bergantung pilihan status_karier (lihat Profil Karier):
  --   bekerja       : tempat_kerja, posisi_kerja, level_jabatan, tanggal_mulai_kerja
  --   wirausaha     : tempat_kerja (nama usaha), posisi_kerja, tanggal_mulai_kerja
  --   studi lanjut  : tempat_kerja (nama kampus), karier_fakultas, posisi_kerja
  --                   (program studi), karier_tahap_studi, tanggal_mulai_kerja
  --   mencari kerja : karier_bidang_minat, karier_rencana_posisi
  --   belum bekerja : karier_bidang_minat
  karier_fakultas        varchar(150),
  karier_bidang_minat    varchar(255),
  karier_rencana_posisi  varchar(255),
  karier_tahap_studi     varchar(20) CHECK (karier_tahap_studi IS NULL OR karier_tahap_studi IN ('rencana','diterima','sedang berjalan')),
  karier_catatan         text,
  CHECK (status_mahasiswa = 'aktif' OR tahun_lulus IS NOT NULL)
);

CREATE TABLE perusahaan (
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

-- ------------------------- Verifikasi akun -------------------------
CREATE TABLE dokumen_verifikasi (
  id            serial PRIMARY KEY,
  pengguna_id   integer NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
  tipe          varchar(20) NOT NULL
                CHECK (tipe IN ('ktm','ijazah','nib','npwp','akta','domisili','logo')),
  file          varchar(255) NOT NULL,
  ukuran_kb     integer CHECK (ukuran_kb <= 2048),
  diunggah_pada timestamp NOT NULL DEFAULT now()
);

CREATE TABLE verifikasi_akun (
  id          serial PRIMARY KEY,
  pengguna_id integer NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
  admin_id    integer NOT NULL REFERENCES admin(id) ON DELETE RESTRICT,
  keputusan   varchar(20) NOT NULL CHECK (keputusan IN ('disetujui','perbaikan','ditolak','nonaktif','aktif')),
  catatan     varchar(500),
  tanggal     timestamp NOT NULL DEFAULT now(),
  CHECK (keputusan = 'disetujui' OR keputusan = 'aktif' OR catatan IS NOT NULL)
);

-- ------------------------- Profil karier -------------------------
CREATE TABLE profil_item (
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

CREATE TABLE mahasiswa_skill (
  mahasiswa_id integer NOT NULL REFERENCES mahasiswa(id) ON DELETE CASCADE,
  skill_id     integer NOT NULL REFERENCES skill(id) ON DELETE CASCADE,
  PRIMARY KEY (mahasiswa_id, skill_id)
);

CREATE TABLE mahasiswa_minat (
  mahasiswa_id integer NOT NULL REFERENCES mahasiswa(id) ON DELETE CASCADE,
  bidang_id    integer NOT NULL REFERENCES bidang(id) ON DELETE CASCADE,
  PRIMARY KEY (mahasiswa_id, bidang_id)
);

-- ------------------------- Lowongan -------------------------
CREATE TABLE lowongan (
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

CREATE TABLE lowongan_jurusan (
  lowongan_id integer NOT NULL REFERENCES lowongan(id) ON DELETE CASCADE,
  jurusan_id  integer NOT NULL REFERENCES jurusan(id) ON DELETE CASCADE,
  PRIMARY KEY (lowongan_id, jurusan_id)
);

CREATE TABLE lowongan_disimpan (
  mahasiswa_id integer NOT NULL REFERENCES mahasiswa(id) ON DELETE CASCADE,
  lowongan_id  integer NOT NULL REFERENCES lowongan(id) ON DELETE CASCADE,
  dibuat_pada  timestamp NOT NULL DEFAULT now(),
  PRIMARY KEY (mahasiswa_id, lowongan_id)
);

-- ------------------------- Lamaran -------------------------
CREATE TABLE lamaran (
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

CREATE TABLE riwayat_lamaran (
  id          serial PRIMARY KEY,
  lamaran_id  integer NOT NULL REFERENCES lamaran(id) ON DELETE CASCADE,
  status      varchar(20) NOT NULL,
  diubah_oleh integer REFERENCES pengguna(id) ON DELETE SET NULL,
  catatan     varchar(500),
  tanggal     timestamp NOT NULL DEFAULT now()
);

CREATE TABLE interview (
  id            serial PRIMARY KEY,
  lamaran_id    integer NOT NULL UNIQUE REFERENCES lamaran(id) ON DELETE CASCADE,
  tanggal       date NOT NULL,
  jam           time NOT NULL,
  mode          varchar(20) NOT NULL CHECK (mode IN ('daring','luring')),
  lokasi_tautan varchar(255) NOT NULL,
  catatan       varchar(500),
  -- Diisi hanya bila mode = 'luring'
  tempat        varchar(255),
  ruangan       varchar(100),
  dresscode     varchar(255),
  yang_dibawa   varchar(500),
  narahubung    varchar(255)
);

-- ------------------------- Notifikasi dan admin -------------------------
CREATE TABLE notifikasi (
  id          serial PRIMARY KEY,
  pengguna_id integer NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
  tipe        varchar(30) NOT NULL,
  judul       varchar(255) NOT NULL,
  pesan       varchar(500) NOT NULL,
  tautan      varchar(255),
  dibaca      boolean NOT NULL DEFAULT false,
  dibuat_pada timestamp NOT NULL DEFAULT now()
);

CREATE TABLE admin_jurusan_kontak (
  id              serial PRIMARY KEY,
  jurusan_id      integer NOT NULL UNIQUE REFERENCES jurusan(id) ON DELETE CASCADE,
  nama_kontak     varchar(255),
  nomor_wa        varchar(20),
  diperbarui_oleh integer REFERENCES admin(id) ON DELETE SET NULL,
  diperbarui_pada timestamp NOT NULL DEFAULT now()
);

CREATE TABLE pengiriman_loker (
  id          serial PRIMARY KEY,
  lowongan_id integer NOT NULL REFERENCES lowongan(id) ON DELETE CASCADE,
  jurusan_id  integer NOT NULL REFERENCES jurusan(id) ON DELETE CASCADE,
  admin_id    integer NOT NULL REFERENCES admin(id) ON DELETE RESTRICT,
  tanggal     timestamp NOT NULL DEFAULT now(),
  UNIQUE (lowongan_id, jurusan_id)
);

CREATE TABLE pengaturan (
  id              serial PRIMARY KEY,
  kunci           varchar(100) NOT NULL UNIQUE,
  nilai           text NOT NULL,
  diperbarui_oleh integer REFERENCES admin(id) ON DELETE SET NULL,
  diperbarui_pada timestamp NOT NULL DEFAULT now()
);

-- ------------------------- Indeks pendukung -------------------------
CREATE INDEX idx_lowongan_status     ON lowongan (status, batas_lamaran);
CREATE INDEX idx_lowongan_perusahaan ON lowongan (perusahaan_id);
CREATE INDEX idx_lamaran_status      ON lamaran (status);
CREATE INDEX idx_lamaran_lowongan    ON lamaran (lowongan_id);
CREATE INDEX idx_notifikasi_belum    ON notifikasi (pengguna_id, dibaca);
CREATE INDEX idx_profil_item_mhs     ON profil_item (mahasiswa_id, tipe);

-- ------------------------- Contoh transaksi saat pelamar diterima -------------------------
-- BEGIN;
--   UPDATE lamaran   SET status = 'diterima', diperbarui_pada = now() WHERE id = :lamaran_id;
--   UPDATE lowongan  SET terisi = terisi + 1,
--                        status = CASE WHEN terisi + 1 >= kuota THEN 'ditutup' ELSE status END
--                  WHERE id = :lowongan_id;
--   UPDATE mahasiswa SET status_karier = 'bekerja',
--                        tempat_kerja  = :nama_perusahaan,
--                        posisi_kerja  = :posisi,
--                        tanggal_mulai_kerja = :tanggal_mulai,
--                        karier_diperbarui_pada = current_date
--                  WHERE id = :mahasiswa_id;
--   INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh) VALUES (:lamaran_id, 'diterima', :pengguna_id);
--   INSERT INTO notifikasi (pengguna_id, tipe, judul, pesan, tautan) VALUES (...);
-- COMMIT;

-- =====================================================================
-- KarirKu Polinema - Tambahan opsional: Lupa Kata Sandi
-- PIC   : M. Ubaidillah (Backend dan Database)
-- =====================================================================
-- Kenapa file terpisah, bukan ditambahkan ke 01-schema.sql?
-- Supaya siapa pun yang sudah menjalankan 01-schema.sql dan 02-seed.sql
-- lebih dulu tidak perlu drop database untuk memakai fitur "Lupa Kata
-- Sandi" di AuthController. Tinggal jalankan file ini di atas database
-- yang sudah ada. Kalau tabel ini belum dijalankan, AuthController tetap
-- berjalan normal untuk fitur lain -- hanya menu Lupa Kata Sandi yang
-- akan menampilkan pesan "fitur belum aktif" (lihat AuthController::lupaSandi()).
--
-- Jalankan setelah 01-schema.sql (boleh sebelum/sesudah 02-seed.sql,
-- urutannya tidak masalah karena tabel ini berdiri sendiri).
-- =====================================================================

CREATE TABLE IF NOT EXISTS reset_kata_sandi (
  id           serial PRIMARY KEY,
  pengguna_id  integer NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
  token_hash   varchar(255) NOT NULL UNIQUE,
  kedaluwarsa  timestamp NOT NULL,
  dipakai_pada timestamp,
  dibuat_pada  timestamp NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reset_kata_sandi_pengguna ON reset_kata_sandi (pengguna_id);

