-- Bukti Bab 5 & Bab 10: ILIKE vs Full-Text Search (GIN), dan FK dengan/tanpa index.
-- Memakai TEMP TABLE: tidak mengubah data asli, hilang saat sesi ditutup.
-- Jalankan: psql -d karirku_polinema -f bukti-kecepatan.sql
\timing off
CREATE TEMP TABLE lowongan_uji AS
  SELECT l.id + g*1000 AS id, l.posisi || ' ' || md5((l.id+g*1000)::text) AS posisi, l.deskripsi, l.search_vector
    FROM lowongan l, generate_series(0, 699) g;           -- ± 100.000 baris
INSERT INTO lowongan_uji VALUES (999999999, 'Quantum Backend Engineer', 'uji', to_tsvector('public.karirku_cari','Quantum Backend Engineer'));
CREATE INDEX ON lowongan_uji USING gin (search_vector);
ANALYZE lowongan_uji;
SELECT count(*) AS jumlah_baris_uji FROM lowongan_uji;

\echo '=== 1. ILIKE (cara lama): mencari kata "quantum" ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT id FROM lowongan_uji WHERE posisi ILIKE '%quantum%';
\echo '=== 2. Full-Text Search + GIN (cara baru): kata yang sama ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT id FROM lowongan_uji WHERE search_vector @@ to_tsquery('public.karirku_cari','quantum:*');

CREATE TEMP TABLE riwayat_uji AS
  SELECT g AS id, (g % 100000) + 1 AS lamaran_id, 'diajukan'::text AS status, now() - (g || ' seconds')::interval AS tanggal
    FROM generate_series(1, 600000) g;
ANALYZE riwayat_uji;
\echo '=== 3. Foreign key TANPA index: riwayat satu lamaran (± 600.000 baris) ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT * FROM riwayat_uji WHERE lamaran_id = 777 ORDER BY tanggal;
CREATE INDEX ON riwayat_uji (lamaran_id, tanggal);
ANALYZE riwayat_uji;
\echo '=== 4. Foreign key DENGAN index (lamaran_id, tanggal) ==='
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT * FROM riwayat_uji WHERE lamaran_id = 777 ORDER BY tanggal;
