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
