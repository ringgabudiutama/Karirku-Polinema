-- Data uji KarirKu Polinema
-- PIC: M. Ubaidillah (Backend dan Database)
-- Jalankan setelah 01-schema.sql
--
-- Target data uji sesuai kriteria keberhasilan proposal:
--   50 akun mahasiswa dan alumni, 15 akun perusahaan, 40 lowongan, 30 lamaran
--   dengan variasi status.

-- ---------------------------------------------------------------------------
-- Jurusan dan program studi, mengikuti daftar resmi Politeknik Negeri Malang.
-- Kolom nama program studi TIDAK memuat jenjang, karena jenjang disimpan di
-- kolomnya sendiri dan tampilan menggabungkan keduanya ("D-IV Teknik
-- Informatika"). Kalau jenjang ikut ditulis di nama, labelnya jadi ganda.
-- ---------------------------------------------------------------------------
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

-- Daftar skill awal. Mahasiswa tetap bisa menambah skill baru sendiri
-- lewat Profil Karier > tab Skills.
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

-- Akun admin Career Center (email: admin@polinema.ac.id, password: admin123)
INSERT INTO pengguna (email, password_hash, role, status_akun) VALUES
  ('admin@polinema.ac.id', '$2b$10$LbjPEzhFoNJuATXOvuQerOvwA1y5y0V3pITQKzX.xWqwgYj.icK7a', 'admin', 'aktif');

INSERT INTO admin (pengguna_id, nama)
  SELECT id, 'Admin Career Center' FROM pengguna WHERE email = 'admin@polinema.ac.id';

-- Akun uji mahasiswa aktif (email: mahasiswa@polinema.ac.id, password: mahasiswa123)
INSERT INTO pengguna (email, password_hash, role, status_akun) VALUES
  ('mahasiswa@polinema.ac.id', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif');

INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan)
  SELECT p.id, ps.id, 'Budi Santoso', '2241720001', '081234567890', 'aktif', 2022
  FROM pengguna p, program_studi ps
  WHERE p.email = 'mahasiswa@polinema.ac.id' AND ps.nama = 'Teknik Informatika';

-- Akun uji perusahaan aktif (email: perusahaan@polinema.ac.id, password: perusahaan123)
INSERT INTO pengguna (email, password_hash, role, status_akun) VALUES
  ('perusahaan@polinema.ac.id', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif');

INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
  SELECT id, 'PT Nusantara Digital', 'Teknologi Informasi', 'Swasta nasional', 'Jl. Soekarno Hatta 10', 'Malang', 'Hendra Wijaya', 'HR Manager', '081298765432', true
  FROM pengguna WHERE email = 'perusahaan@polinema.ac.id';

-- ===========================================================================
-- DATA UJI LENGKAP
-- Jumlahnya mengikuti kriteria keberhasilan pada proposal:
--   50 akun mahasiswa dan alumni, 15 akun perusahaan, 40 lowongan,
--   dan 30 lamaran dengan status yang bervariasi.
--
-- Semua akun mahasiswa memakai kata sandi: mahasiswa123
-- Semua akun perusahaan memakai kata sandi: perusahaan123
--
-- Bagian ini dihasilkan ulang lewat skrip, jadi isinya konsisten:
-- jurusan pada lowongan selalu cocok dengan jurusan pelamarnya, dan
-- lamaran berstatus interview selalu punya jadwal interview.
-- ===========================================================================

-- 50 akun mahasiswa dan alumni ------------------------------------------
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

-- Skill dan minat bidang untuk sebagian mahasiswa -----------------------
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

-- Riwayat pendidikan, pengalaman, dan sertifikat -----------------------
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

-- 15 akun perusahaan ---------------------------------------------------
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

-- 40 lowongan ---------------------------------------------------------
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

-- Jurusan sasaran tiap lowongan
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

-- 30 lamaran dengan status bervariasi ----------------------------------
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

-- Riwayat perubahan status lamaran
INSERT INTO riwayat_lamaran (lamaran_id, status, catatan, diubah_oleh, tanggal)
  SELECT la.id, 'diajukan', 'Lamaran dikirim oleh pelamar.', m.pengguna_id, la.tanggal_lamar
    FROM lamaran la JOIN mahasiswa m ON m.id = la.mahasiswa_id;
INSERT INTO riwayat_lamaran (lamaran_id, status, catatan, diubah_oleh, tanggal)
  SELECT la.id, la.status, 'Status diperbarui oleh perusahaan.', pr.pengguna_id,
         la.tanggal_lamar + interval '3 days'
    FROM lamaran la JOIN lowongan lo ON lo.id = la.lowongan_id
         JOIN perusahaan pr ON pr.id = lo.perusahaan_id
   WHERE la.status <> 'diajukan';

-- Jadwal interview: luring memakai kolom tempat, ruangan, dresscode,
-- yang dibawa, dan narahubung. Daring hanya memakai tautan meeting.
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

-- Lowongan yang disimpan mahasiswa -------------------------------------
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

-- Hitung ulang kolom terisi pada lowongan supaya cocok dengan lamaran diterima
UPDATE lowongan l
   SET terisi = LEAST(l.kuota, (
         SELECT count(*) FROM lamaran la
          WHERE la.lowongan_id = l.id AND la.status = 'diterima'));

-- ===========================================================================
-- ISI UNTUK TIGA AKUN DEMO
--
-- Tanpa bagian ini, akun demo bisa masuk tetapi halamannya kosong: perusahaan
-- demo belum punya lowongan, dan mahasiswa demo belum punya lamaran. Jadi
-- sebagian data di atas dipindahkan ke akun demo supaya begitu login semua
-- menu langsung ada isinya dan siap dipakai saat presentasi.
-- ===========================================================================

-- 1. Lima lowongan yang paling banyak pelamarnya dipindah ke perusahaan demo.
--    Lamaran dan interview-nya ikut pindah karena mengacu ke lowongan.
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

-- 2. Mahasiswa demo (Budi Santoso) diberi empat lamaran dengan status berbeda,
--    supaya halaman "Lamaran saya" langsung memperlihatkan semua tahap.
WITH budi AS (
  SELECT m.id FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
   WHERE p.email = 'mahasiswa@polinema.ac.id'
), sasaran AS (
  -- Lowongan milik perusahaan demo didahulukan, supaya saat login sebagai
  -- perusahaan demo, mahasiswa demo memang terlihat di daftar pelamarnya.
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

-- 3. Satu interview luring untuk lamaran Budi yang berstatus interview,
--    lengkap dengan tempat, ruangan, dresscode, bawaan, dan narahubung.
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

-- 4. Skill, minat, dan riwayat untuk mahasiswa demo supaya profilnya terisi.
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

-- 5. Beberapa akun yang masih menunggu verifikasi, supaya menu Persetujuan
--    di sisi admin ada isinya saat didemokan.
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

-- Hitung ulang kolom terisi sekali lagi setelah lamaran akun demo masuk.
UPDATE lowongan l
   SET terisi = LEAST(l.kuota, (
         SELECT count(*) FROM lamaran la
          WHERE la.lowongan_id = l.id AND la.status = 'diterima'));

-- ===========================================================================
-- NOTIFIKASI
--
-- Diisi supaya lonceng dan halaman Notifikasi ada isinya saat didemokan, dan
-- supaya tautan "tandai dibaca" benar-benar bisa diuji.
--
-- Kolom tautan HARUS berisi alamat yang benar-benar ada. Alamat halaman
-- notifikasi adalah 'notifikasi/semua' untuk semua peran, bukan
-- 'mahasiswa/notifikasi'.
-- ===========================================================================

-- Untuk mahasiswa demo
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

-- Untuk perusahaan demo
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

-- Untuk admin
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

-- ===========================================================================
-- BERKAS CONTOH PADA DATA UJI
--
-- Nama berkas di bawah menunjuk ke berkas yang benar-benar ada di
-- storage/uploads/. Tanpa ini, tombol seperti "Lihat file" pada sertifikat
-- atau "Lihat" pada dokumen legalitas akan berakhir di halaman
-- "Berkas tidak ditemukan" saat didemokan.
-- ===========================================================================

-- PENTING: nama berkas dibuat BERBEDA untuk tiap orang, memakai NIM atau
-- nomor perusahaan. Kalau semua memakai satu nama yang sama, pemeriksaan hak
-- akses di unduh.php tidak bisa membedakan pemiliknya, sehingga berkas orang
-- lain ikut terbuka. Berkasnya sudah tersedia di storage/uploads/.

-- Foto profil dan logo
UPDATE mahasiswa SET foto = 'contoh-foto.jpg' WHERE id % 3 = 0
    OR pengguna_id = (SELECT id FROM pengguna WHERE email = 'mahasiswa@polinema.ac.id');
UPDATE perusahaan SET logo = 'contoh-logo.jpg';

-- Sertifikat dan portofolio ikut punya berkas, bukan hanya judul
UPDATE profil_item SET file = 'contoh-sertifikat.pdf' WHERE tipe = 'sertifikat';
UPDATE profil_item SET file = 'contoh-portofolio.pdf' WHERE tipe = 'portofolio';

-- KTM untuk mahasiswa aktif, ijazah untuk alumni, masing-masing satu berkas
UPDATE mahasiswa SET file_ktm = 'ktm-' || nim || '.pdf' WHERE status_mahasiswa = 'aktif';
UPDATE mahasiswa SET file_ktm = 'ijazah-' || nim || '.pdf' WHERE status_mahasiswa = 'alumni';
UPDATE mahasiswa SET file_surat_pengantar = 'surat-' || nim || '.pdf';

-- Surat pengantar pada tiap lamaran mengikuti milik pelamarnya
UPDATE lamaran la SET file_surat_pengantar = m.file_surat_pengantar, file_ktm = m.file_ktm
  FROM mahasiswa m WHERE m.id = la.mahasiswa_id;

-- Dokumen legalitas perusahaan, dipakai Admin saat memverifikasi
INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb)
  SELECT pr.pengguna_id, t.tipe, t.tipe || '-pt' || pr.id || '.pdf', 2
    FROM perusahaan pr
    CROSS JOIN (VALUES ('nib'), ('npwp'), ('akta'), ('domisili')) AS t(tipe);

-- Dokumen mahasiswa yang menunggu verifikasi, supaya Admin bisa meninjaunya
INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb)
  SELECT m.pengguna_id, 'ktm', m.file_ktm, 2
    FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
   WHERE p.status_akun = 'menunggu';
