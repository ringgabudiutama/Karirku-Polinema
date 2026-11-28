-- =====================================================================
-- KarirKu Polinema · 09 · Nomor pendaftaran berurutan
--
-- Setiap akun mahasiswa/alumni dan perusahaan mendapat nomor pendaftaran
-- sesuai urutan mendaftar, misalnya PENG-2026-0001, PENG-2026-0002, ...
--   * akun lama diberi nomor menurut urutan tanggal daftar (lalu id);
--   * akun baru otomatis mendapat nomor berikutnya lewat trigger;
--   * akun admin tidak diberi nomor.
-- Aman dijalankan berulang: nomor yang sudah ada tidak diubah.
-- =====================================================================

ALTER TABLE pengguna ADD COLUMN IF NOT EXISTS no_pendaftaran varchar(20);
CREATE UNIQUE INDEX IF NOT EXISTS uq_pengguna_no_pendaftaran ON pengguna (no_pendaftaran);
CREATE SEQUENCE IF NOT EXISTS seq_no_pendaftaran;

-- Format nomor: PENG-<tahun daftar>-<urutan 4 digit>
CREATE OR REPLACE FUNCTION format_no_pendaftaran(p_urut bigint, p_tanggal timestamp)
RETURNS varchar LANGUAGE sql IMMUTABLE AS $$
  SELECT 'PENG-' || to_char(p_tanggal, 'YYYY') || '-' || lpad(p_urut::text, 4, '0');
$$;

-- Memberi nomor ke SEMUA akun non-admin menurut urutan daftar, lalu
-- menyetel urutan berikutnya. Dipakai sekali saat kolom baru dibuat dan
-- oleh file data dummy (database uji). Jangan dipanggil di database produksi
-- yang nomornya sudah dikirim ke pendaftar.
CREATE OR REPLACE FUNCTION urutkan_no_pendaftaran() RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE
  v_jumlah integer;
BEGIN
  UPDATE pengguna SET no_pendaftaran = NULL WHERE no_pendaftaran IS NOT NULL;
  WITH urut AS (
    SELECT id, dibuat_pada, row_number() OVER (ORDER BY dibuat_pada, id) AS n
      FROM pengguna
     WHERE role <> 'admin'
  )
  UPDATE pengguna p
     SET no_pendaftaran = format_no_pendaftaran(u.n, u.dibuat_pada)
    FROM urut u
   WHERE u.id = p.id;
  GET DIAGNOSTICS v_jumlah = ROW_COUNT;
  PERFORM setval('seq_no_pendaftaran', GREATEST(v_jumlah, 1), v_jumlah > 0);
  RETURN v_jumlah;
END;
$$;

-- Akun baru: ambil nomor berikutnya.
CREATE OR REPLACE FUNCTION trg_isi_no_pendaftaran() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.role <> 'admin' AND NEW.no_pendaftaran IS NULL THEN
    NEW.no_pendaftaran := format_no_pendaftaran(nextval('seq_no_pendaftaran'), COALESCE(NEW.dibuat_pada, now()::timestamp));
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_pengguna_no_pendaftaran ON pengguna;
CREATE TRIGGER trg_pengguna_no_pendaftaran
  BEFORE INSERT ON pengguna
  FOR EACH ROW EXECUTE FUNCTION trg_isi_no_pendaftaran();

-- Pertama kali dijalankan: beri nomor ke akun yang sudah ada.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pengguna WHERE role <> 'admin' AND no_pendaftaran IS NULL)
     AND NOT EXISTS (SELECT 1 FROM pengguna WHERE no_pendaftaran IS NOT NULL) THEN
    PERFORM urutkan_no_pendaftaran();
  ELSIF EXISTS (SELECT 1 FROM pengguna WHERE role <> 'admin' AND no_pendaftaran IS NULL) THEN
    -- Sebagian sudah bernomor: lanjutkan urutan untuk yang belum.
    PERFORM setval('seq_no_pendaftaran',
                   GREATEST((SELECT max(split_part(no_pendaftaran, '-', 3)::int) FROM pengguna WHERE no_pendaftaran IS NOT NULL), 1));
    UPDATE pengguna p
       SET no_pendaftaran = format_no_pendaftaran(nextval('seq_no_pendaftaran'), p.dibuat_pada)
      FROM (SELECT id FROM pengguna WHERE role <> 'admin' AND no_pendaftaran IS NULL ORDER BY dibuat_pada, id) s
     WHERE s.id = p.id;
  END IF;
END
$$;
