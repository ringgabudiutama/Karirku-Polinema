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
