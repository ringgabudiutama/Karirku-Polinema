-- =====================================================================
-- KarirKu Polinema · 08 · Penguatan keamanan database untuk PRODUKSI
--
-- BUKAN bagian instal otomatis. Dijalankan SEKALI oleh pemilik database
-- (mis. postgres) di server, sesudah 01–07 selesai. Aman diulang.
--
--   psql -U postgres -d karirku_polinema -v app_pass='ISI_PASSWORD_PANJANG_ACAK' \
--        [-v max_koneksi=60] -f database/08-hardening-produksi.sql
--
-- max_koneksi (bawaan 60) = batas koneksi bersamaan untuk akun aplikasi. PHP membuka
-- satu koneksi per permintaan, jadi angka ini harus >= jumlah proses PHP-FPM
-- (pm.max_children) dan < max_connections PostgreSQL (bawaan 100). Terlalu kecil:
-- pengunjung ditolak saat ramai. Terlalu besar: server database kehabisan memori.
-- Untuk ribuan pengguna aktif bersamaan, pasang PgBouncer (lihat docs/07).
--
-- Hasilnya: aplikasi memakai akun "karirku_app" yang HANYA boleh baca/tulis data.
-- Kalau penyerang berhasil menyuntikkan SQL lewat celah aplikasi, ia terkurung di
-- akun ini: tidak bisa DROP/ALTER tabel, membuat objek, mengubah arsip riwayat,
-- membaca akun database lain, atau menguasai server database.
-- Aplikasi lalu dijalankan dengan:
--   DB_USER=karirku_app  DB_PASS=<password tadi>  DB_MIGRASI_OTOMATIS=0
-- =====================================================================
\set ON_ERROR_STOP on

-- 0. Pemeriksaan awal: password wajib diberikan dan cukup panjang.
\if :{?app_pass}
\else
  \echo 'GAGAL: beri password lewat  -v app_pass=...'
  \quit
\endif
\if :{?max_koneksi}
\else
  \set max_koneksi 60
\endif
SELECT length(:'app_pass') < 16 AS lemah \gset
\if :lemah
  \echo 'GAGAL: password minimal 16 karakter (disarankan acak, mis. openssl rand -base64 24).'
  \quit
\endif

SET password_encryption = 'scram-sha-256';

-- 1. Akun aplikasi: tanpa hak istimewa apa pun.
SELECT NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'karirku_app') AS belum_ada \gset
\if :belum_ada
  CREATE ROLE karirku_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS
    CONNECTION LIMIT :max_koneksi;
\endif
ALTER ROLE karirku_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS
  CONNECTION LIMIT :max_koneksi;
ALTER ROLE karirku_app PASSWORD :'app_pass';

-- Batas per sesi: kueri yang menggantung atau sengaja dibuat berat (serangan
-- penghabisan sumber daya) dihentikan sendiri oleh database.
ALTER ROLE karirku_app SET statement_timeout = '30s';
ALTER ROLE karirku_app SET lock_timeout = '10s';
ALTER ROLE karirku_app SET idle_in_transaction_session_timeout = '60s';
ALTER ROLE karirku_app SET search_path = public;   -- menutup pembajakan lewat search_path

-- 2. Akses ke database & skema: tertutup untuk umum, terbuka untuk karirku_app.
REVOKE ALL ON DATABASE :"DBNAME" FROM PUBLIC;
GRANT CONNECT ON DATABASE :"DBNAME" TO karirku_app;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO karirku_app;
REVOKE CREATE ON SCHEMA public FROM karirku_app;

-- 3. Hak data: hanya SELECT/INSERT/UPDATE/DELETE. Tanpa TRUNCATE, REFERENCES,
--    TRIGGER, dan tanpa hak mengubah struktur tabel.
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM karirku_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO karirku_app;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM karirku_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO karirku_app;

-- 4. Arsip hanya boleh ditambah, tidak boleh diubah/dihapus oleh aplikasi.
--    (Penghapusan berantai saat lowongan/lamaran dihapus tetap berjalan karena
--    dilakukan PostgreSQL atas nama pemilik tabel.) Pembersihan log email dan
--    data lama dilakukan terjadwal oleh pemilik lewat fn_bersihkan_data_lama().
REVOKE UPDATE, DELETE ON riwayat_lamaran, riwayat_lowongan, log_aktivitas_admin FROM karirku_app;
REVOKE DELETE ON log_email FROM karirku_app;
REVOKE EXECUTE ON FUNCTION fn_bersihkan_data_lama(integer, integer) FROM PUBLIC;

-- 5. Objek baru yang dibuat pemilik (migrasi berikutnya) otomatis dapat hak data.
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO karirku_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO karirku_app;

-- 6. Ringkasan untuk diperiksa mata.
\echo
\echo '=== Akun karirku_app ==='
SELECT rolname, rolsuper AS superuser, rolcreatedb AS buat_db, rolcreaterole AS buat_akun,
       rolreplication AS replikasi, rolconnlimit AS batas_koneksi
  FROM pg_roles WHERE rolname = 'karirku_app';
\echo '=== Hak karirku_app pada tabel (jumlah tabel per jenis hak) ==='
SELECT privilege_type, count(DISTINCT table_name) AS jumlah_tabel
  FROM information_schema.role_table_grants
 WHERE grantee = 'karirku_app' AND table_schema = 'public'
 GROUP BY privilege_type ORDER BY privilege_type;
\echo 'Selesai. Langkah berikut: set DB_USER=karirku_app, DB_PASS, DB_MIGRASI_OTOMATIS=0 di server.'
