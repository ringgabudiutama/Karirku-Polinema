-- Data uji KarirKu Polinema
-- PIC: M. Ubaidillah (Backend dan Database)
-- Jalankan setelah 01-schema.sql
--
-- Target data uji sesuai kriteria keberhasilan proposal:
--   50 akun mahasiswa dan alumni, 15 akun perusahaan, 40 lowongan, 30 lamaran
--   dengan variasi status.

INSERT INTO jurusan (nama) VALUES
  ('Teknik Sipil'), ('Teknik Mesin'), ('Teknik Elektro'), ('Teknik Kimia'),
  ('Akuntansi'), ('Administrasi Niaga'), ('Teknologi Informasi');

INSERT INTO bidang (nama) VALUES
  ('Teknologi Informasi'), ('Konstruksi'), ('Manufaktur'), ('Kelistrikan'),
  ('Kimia'), ('Keuangan'), ('Perdagangan dan Jasa');

-- TODO: program_studi per jurusan
-- TODO: akun admin Career Center
-- TODO: 50 mahasiswa dan alumni
-- TODO: 15 perusahaan beserta dokumen legalitas
-- TODO: 40 lowongan beserta jurusan sasaran
-- TODO: 30 lamaran dengan variasi status
