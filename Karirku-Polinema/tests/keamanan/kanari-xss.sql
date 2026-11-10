\set ON_ERROR_STOP off
DROP TABLE IF EXISTS kanari_uji;
CREATE TABLE kanari_uji (nomor int PRIMARY KEY, tabel text, kolom text);
DO $$
DECLARE r record; n int := 0;
BEGIN
  FOR r IN
    SELECT c.table_name AS t, c.column_name AS k
      FROM information_schema.columns c
      JOIN pg_tables p ON p.tablename = c.table_name AND p.schemaname = 'public'
     WHERE c.table_schema = 'public' AND c.data_type IN ('character varying','text')
       AND c.table_name NOT IN ('kanari_uji','percobaan_login','token_ingat','reset_kata_sandi','pengguna')
       AND c.column_name !~ '^(email|password|.*hash|selector|validator|token|kode.*|status.*|jenis.*|tipe.*|peran|role|file.*|path.*|foto|logo|pamflet|cv|ktm|ijazah|nib|npwp|akta|domisili|surat.*|portofolio|dokumen.*|website|link|url|kunci|search.*|nama_file.*|ekstensi|mime.*|sandi.*)$'
     ORDER BY 1, 2
  LOOP
    n := n + 1;
    BEGIN
      EXECUTE format('UPDATE %I SET %I = %L || id::text || %L', r.t, r.k, '"><i data-x=K' || n || '_', '>');
      INSERT INTO kanari_uji VALUES (n, r.t, r.k);
    EXCEPTION WHEN others THEN NULL;
    END;
  END LOOP;
END $$;
-- nama di tabel pengguna (bukan email) dan catatan riwayat (tabel arsip, hanya bisa INSERT)
INSERT INTO riwayat_lamaran(lamaran_id,status,catatan) SELECT id,status,'"><i data-x=KRIW_'||id||'>' FROM lamaran WHERE status IN ('screening','interview','diterima','ditolak');
INSERT INTO kanari_uji VALUES (9001,'riwayat_lamaran','catatan');
-- kolom JSON (nilai string tingkat atas)
UPDATE lamaran SET snapshot_profil = COALESCE((SELECT jsonb_object_agg(k, CASE WHEN jsonb_typeof(v)='string' THEN to_jsonb('"><i data-x=KSNAP_'||lamaran.id||'>'::text) ELSE v END) FROM jsonb_each(snapshot_profil) AS e(k,v)), snapshot_profil);
INSERT INTO kanari_uji VALUES (9002,'lamaran','snapshot_profil (JSON)');
UPDATE profil_item SET detail = COALESCE((SELECT jsonb_object_agg(k, CASE WHEN jsonb_typeof(v)='string' THEN to_jsonb('"><i data-x=KPI_'||profil_item.id||'>'::text) ELSE v END) FROM jsonb_each(detail) AS e(k,v)), detail) WHERE jsonb_typeof(detail)='object';
INSERT INTO kanari_uji VALUES (9003,'profil_item','detail (JSON)');
SELECT 'kolom teks yang ditanami kanari: ' || count(*) FROM kanari_uji;
