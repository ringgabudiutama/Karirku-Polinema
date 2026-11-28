-- =====================================================================
-- KarirKu Polinema · 10 · DATA DUMMY 100 PENDAFTAR (untuk pengujian)
--
-- Isi: 60 mahasiswa/alumni + 40 perusahaan dengan status beragam:
--   50 menunggu verifikasi, 15 perlu perbaikan, 10 ditolak, 25 aktif.
-- Tanggal daftar menyebar dalam 30 hari terakhir. Setelah data masuk,
-- nomor pendaftaran SEMUA akun diurutkan ulang menurut tanggal daftar
-- (PENG-2026-0001, PENG-2026-0002, ...).
--
-- Kata sandi: mahasiswa dummy = mahasiswa123, perusahaan dummy = perusahaan123.
-- Email dummy berakhiran @dummy.polinema.test / @dummy-perusahaan.test.
--
-- HANYA UNTUK DATABASE UJI/DEMO. Jangan dijalankan di database yang sudah
-- dipakai pendaftar sungguhan, karena nomor pendaftaran diurutkan ulang.
-- Butuh file 09-nomor-pendaftaran.sql sudah dijalankan.
-- Aman dijalankan berulang (data dummy tidak dobel).
--
-- Menghapus semua data dummy ini:
--   DELETE FROM pengguna WHERE email LIKE '%@dummy.polinema.test' OR email LIKE '%@dummy-perusahaan.test';
--   SELECT urutkan_no_pendaftaran();
-- File ini dibuat oleh tests/buat-dummy-pendaftar.py.
-- =====================================================================

DO $dummy_pendaftar$
DECLARE
  v_admin integer := (SELECT id FROM admin ORDER BY id LIMIT 1);
  v_id    integer;
BEGIN
  IF EXISTS (SELECT 1 FROM pengguna WHERE email LIKE '%@dummy.polinema.test') THEN
    RAISE NOTICE 'Data dummy pendaftar sudah ada, dilewati.';
    RETURN;
  END IF;

  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('aisyah.pratama.6905@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '41891 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Aisyah Pratama', '2598266905', '085626569522', 'aktif', 2025, NULL, 3.57, 'Banyuwangi', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Jaringan Telekomunikasi Digital' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '41891 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '41891 minutes')::timestamp + interval '9 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('alya.firmansyah.5536@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '41854 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Alya Firmansyah', '2099415536', '089415863665', 'alumni', 2020, 2024, 3.38, 'Surabaya', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknologi Informasi' AND ps.nama = 'Pengembangan Peranti Lunak Situs' AND ps.jenjang = 'D-II' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '41854 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '41854 minutes')::timestamp + interval '39 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.adi3@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif', (now() - interval '41132 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Artha Digital Indonesia', 'Kelistrikan', 'BUMN', 'Jl. Raya Tlogomas No. 186', 'Batu', 'Alya Rahmawati', 'Manajer SDM', '084649375288', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '41132 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '41132 minutes')::timestamp + interval '26 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hendra.nugroho.9376@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '40867 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Hendra Nugroho', '2592569376', '081541925273', 'aktif', 2025, NULL, 3.82, 'Madiun', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Jaringan Telekomunikasi Digital' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '40867 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '40867 minutes')::timestamp + interval '4 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('andi.ramadhan.8623@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '40670 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Andi Ramadhan', '2293958623', '087298962446', 'aktif', 2022, NULL, 3.6, 'Malang', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Teknik Listrik' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '40670 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '40670 minutes')::timestamp + interval '40 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.dkr6@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif', (now() - interval '40607 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Daya Kreasi Raya', 'Konstruksi', 'Startup', 'Jl. Raya Tlogomas No. 23', 'Pasuruan', 'Bayu Safitri', 'HR Officer', '087351273033', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '40607 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '40607 minutes')::timestamp + interval '5 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.bar7@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif', (now() - interval '40051 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Bina Abadi Raya', 'Teknologi Informasi', 'Swasta nasional', 'Jl. Soekarno Hatta No. 250', 'Banyuwangi', 'Sari Hidayat', 'HR Officer', '082215732645', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '40051 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '40051 minutes')::timestamp + interval '7 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('bella.hakim.3110@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '38481 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Bella Hakim', '2494933110', '083248725769', 'aktif', 2024, NULL, 3.83, 'Lumajang', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Kimia' AND ps.nama = 'Teknologi Kimia Industri' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '38481 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '38481 minutes')::timestamp + interval '21 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('yoga.pratama.8810@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '38153 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Yoga Pratama', '2499508810', '088828708353', 'aktif', 2024, NULL, 3.58, 'Lumajang', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Administrasi Niaga' AND ps.nama = 'Manajemen Pemasaran Digital' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '38153 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '38153 minutes')::timestamp + interval '4 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.asj10@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif', (now() - interval '38090 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Artha Solusi Jaya', 'Manufaktur', 'Swasta nasional', 'Jl. Gatot Subroto No. 218', 'Blitar', 'Naufal Maharani', 'Talent Acquisition', '082430429076', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '38090 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '38090 minutes')::timestamp + interval '12 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.pij11@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif', (now() - interval '36903 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Prima Industri Jaya', 'Teknologi Informasi', 'Swasta nasional', 'Jl. Ijen No. 28', 'Banyuwangi', 'Tono Wulandari', 'Talent Acquisition', '089381999764', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '36903 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '36903 minutes')::timestamp + interval '22 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('zahra.firmansyah.5879@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '36471 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Zahra Firmansyah', '2491565879', '082889243074', 'aktif', 2024, NULL, 2.84, 'Mojokerto', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '36471 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '36471 minutes')::timestamp + interval '26 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.sdr13@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif', (now() - interval '34520 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Sentosa Digital Raya', 'Konstruksi', 'Swasta asing', 'Jl. Industri Raya No. 112', 'Lumajang', 'Maya Puspita', 'Talent Acquisition', '086544994399', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '34520 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '34520 minutes')::timestamp + interval '8 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.nkj14@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif', (now() - interval '33312 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Nusa Konstruksi Jaya', 'Kimia', 'Swasta nasional', 'Jl. Raya Tlogomas No. 94', 'Probolinggo', 'Naufal Utami', 'HR Officer', '083048559347', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '33312 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '33312 minutes')::timestamp + interval '33 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hana.safitri.3641@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '32611 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Hana Safitri', '2593403641', '085380243090', 'aktif', 2025, NULL, 3.02, 'Surabaya', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Mesin' AND ps.nama = 'Teknik Mesin' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '32611 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '32611 minutes')::timestamp + interval '12 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('agus.syahputra.8857@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '32590 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Agus Syahputra', '2191728857', '083392466027', 'alumni', 2021, 2025, 2.8, 'Pasuruan', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Teknik Elektronika' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '32590 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '32590 minutes')::timestamp + interval '4 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('gilang.gunawan.1274@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '30587 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Gilang Gunawan', '2198741274', '088273164081', 'alumni', 2021, 2025, 3.17, 'Pasuruan', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Mesin' AND ps.nama = 'Teknik Otomotif Elektronik' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '30587 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '30587 minutes')::timestamp + interval '31 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('nina.firmansyah.0136@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '30448 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Nina Firmansyah', '2193160136', '084368127996', 'alumni', 2021, 2025, 3.48, 'Blitar', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknologi Informasi' AND ps.nama = 'Sistem Informasi Bisnis' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '30448 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '30448 minutes')::timestamp + interval '36 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('tono.nugroho.3799@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '30429 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Tono Nugroho', '2292053799', '087050215401', 'aktif', 2022, NULL, 3.11, 'Blitar', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Teknik Elektronika' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '30429 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '30429 minutes')::timestamp + interval '19 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.nui20@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif', (now() - interval '30376 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Nusa Utama Indonesia', 'Manufaktur', 'Startup', 'Jl. Industri Raya No. 85', 'Mojokerto', 'Dimas Amalia', 'Manajer SDM', '083784599081', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '30376 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '30376 minutes')::timestamp + interval '5 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.ads21@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif', (now() - interval '29431 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Artha Data Sejahtera', 'Perdagangan dan Jasa', 'Startup', 'Jl. Ahmad Yani No. 213', 'Malang', 'Agus Prasetyo', 'Talent Acquisition', '085757184271', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '29431 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '29431 minutes')::timestamp + interval '12 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('ayu.setiawan.1350@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '29429 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Ayu Setiawan', '2296111350', '083356796645', 'aktif', 2022, NULL, 2.91, 'Malang', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi Manajemen' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '29429 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '29429 minutes')::timestamp + interval '20 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('dafa.setiawan.1906@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '29283 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Dafa Setiawan', '2593291906', '085963974873', 'aktif', 2025, NULL, 3.85, 'Probolinggo', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Sipil' AND ps.nama = 'Teknik Sipil' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '29283 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '29283 minutes')::timestamp + interval '36 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('tiara.gunawan.7933@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'aktif', (now() - interval '28930 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Tiara Gunawan', '2495177933', '083926927636', 'aktif', 2024, NULL, 2.89, 'Pasuruan', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Sipil' AND ps.nama = 'Manajemen Rekayasa Konstruksi' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '28930 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '28930 minutes')::timestamp + interval '35 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.sss25@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'aktif', (now() - interval '28403 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Sentosa Solusi Sejahtera', 'Kelistrikan', 'Swasta nasional', 'Jl. Raya Tlogomas No. 73', 'Blitar', 'Bayu Saputra', 'Direktur', '081417543930', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '28403 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, (now() - interval '28403 minutes')::timestamp + interval '11 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.bds26@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'ditolak', (now() - interval '27779 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Bina Data Sejahtera', 'Kelistrikan', 'Startup', 'Jl. Soekarno Hatta No. 111', 'Pasuruan', 'Hendra Pratama', 'Direktur', '084491238629', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '27779 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', 'Pendaftaran ganda, akun lain dengan NIM yang sama sudah aktif.', LEAST(now()::timestamp, (now() - interval '27779 minutes')::timestamp + interval '10 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.dps27@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'ditolak', (now() - interval '26912 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Dwi Persada Sejahtera', 'Teknologi Informasi', 'BUMN', 'Jl. Industri Raya No. 119', 'Lumajang', 'Rizky Nugroho', 'HR Manager', '081603107824', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '26912 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', 'Data pendaftar tidak ditemukan di sistem akademik Polinema.', LEAST(now()::timestamp, (now() - interval '26912 minutes')::timestamp + interval '22 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('rizky.puspita.1575@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'perbaikan', (now() - interval '26740 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Rizky Puspita', '2297331575', '084640373192', 'aktif', 2022, NULL, 3.35, 'Pasuruan', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Mesin' AND ps.nama = 'Teknik Otomotif Elektronik' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '26740 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Nomor WhatsApp PIC tidak dapat dihubungi, mohon periksa kembali.', LEAST(now()::timestamp, (now() - interval '26740 minutes')::timestamp + interval '26 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.kdj29@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'perbaikan', (now() - interval '26724 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Karya Data Jaya', 'Manufaktur', 'Startup', 'Jl. Ahmad Yani No. 130', 'Mojokerto', 'Dafa Utami', 'Direktur', '088853027911', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '26724 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Alamat perusahaan belum lengkap (kecamatan dan kode pos).', LEAST(now()::timestamp, (now() - interval '26724 minutes')::timestamp + interval '30 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.cmr30@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'perbaikan', (now() - interval '26122 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Citra Mandiri Raya', 'Konstruksi', 'Swasta nasional', 'Jl. Ijen No. 20', 'Pasuruan', 'Fajar Prasetyo', 'Direktur', '088476194593', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '26122 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Ijazah/SKL belum dilegalisir.', LEAST(now()::timestamp, (now() - interval '26122 minutes')::timestamp + interval '38 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('bayu.gunawan.4443@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'ditolak', (now() - interval '25584 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Bayu Gunawan', '2493384443', '083860725423', 'aktif', 2024, NULL, 3.5, 'Madiun', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Administrasi Niaga' AND ps.nama = 'Administrasi Bisnis' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '25584 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', 'Data pendaftar tidak ditemukan di sistem akademik Polinema.', LEAST(now()::timestamp, (now() - interval '25584 minutes')::timestamp + interval '10 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('fajar.amalia.6065@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'ditolak', (now() - interval '25309 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Fajar Amalia', '2199036065', '087166795237', 'alumni', 2021, 2024, 3.84, 'Malang', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Mesin' AND ps.nama = 'Teknik Mesin' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '25309 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', 'Pendaftaran ganda, akun lain dengan NIM yang sama sudah aktif.', LEAST(now()::timestamp, (now() - interval '25309 minutes')::timestamp + interval '40 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('yoga.saputra.5340@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'perbaikan', (now() - interval '25080 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Yoga Saputra', '2496865340', '087538431673', 'aktif', 2024, NULL, 3.57, 'Banyuwangi', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi Manajemen' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '25080 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Dokumen NIB kedaluwarsa, mohon unggah NIB terbaru.', LEAST(now()::timestamp, (now() - interval '25080 minutes')::timestamp + interval '5 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('intan.amalia.1229@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'perbaikan', (now() - interval '24575 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Intan Amalia', '2196741229', '082712819810', 'alumni', 2021, 2025, 3.94, 'Banyuwangi', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Administrasi Niaga' AND ps.nama = 'Manajemen Pemasaran Digital' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '24575 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Ijazah/SKL belum dilegalisir.', LEAST(now()::timestamp, (now() - interval '24575 minutes')::timestamp + interval '37 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('citra.maharani.8858@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'ditolak', (now() - interval '24075 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Citra Maharani', '2292778858', '082936935295', 'aktif', 2022, NULL, 3.7, 'Probolinggo', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi Manajemen' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '24075 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', 'Perusahaan terindikasi outsourcing tanpa izin resmi.', LEAST(now()::timestamp, (now() - interval '24075 minutes')::timestamp + interval '14 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('sari.fitriani.8363@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'perbaikan', (now() - interval '23984 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Sari Fitriani', '1991808363', '084761358770', 'alumni', 2019, 2023, 2.89, 'Lumajang', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknologi Informasi' AND ps.nama = 'Pengembangan Peranti Lunak Situs' AND ps.jenjang = 'D-II' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '23984 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Alamat perusahaan belum lengkap (kecamatan dan kode pos).', LEAST(now()::timestamp, (now() - interval '23984 minutes')::timestamp + interval '10 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('adi.wijaya.3168@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'ditolak', (now() - interval '22975 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Adi Wijaya', '2392903168', '088949914419', 'aktif', 2023, NULL, 3.78, 'Surabaya', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '22975 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', 'Pendaftaran ganda, akun lain dengan NIM yang sama sudah aktif.', LEAST(now()::timestamp, (now() - interval '22975 minutes')::timestamp + interval '16 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('agus.rahmawati.9831@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'perbaikan', (now() - interval '20441 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Agus Rahmawati', '2098699831', '086197523188', 'alumni', 2020, 2024, 2.99, 'Blitar', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Teknik Elektronika' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '20441 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Ijazah/SKL belum dilegalisir.', LEAST(now()::timestamp, (now() - interval '20441 minutes')::timestamp + interval '15 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('agus.wulandari.6957@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'perbaikan', (now() - interval '17770 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Agus Wulandari', '2594746957', '083578739787', 'aktif', 2025, NULL, 3.89, 'Probolinggo', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Kimia' AND ps.nama = 'Teknologi Kimia Industri' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '17770 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Foto KTM buram, mohon unggah ulang dengan jelas.', LEAST(now()::timestamp, (now() - interval '17770 minutes')::timestamp + interval '11 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.duj40@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'perbaikan', (now() - interval '16441 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Dwi Utama Jaya', 'Keuangan', 'Startup', 'Jl. Industri Raya No. 80', 'Malang', 'Bayu Saputra', 'Recruitment Specialist', '082151269858', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '16441 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Dokumen NIB kedaluwarsa, mohon unggah NIB terbaru.', LEAST(now()::timestamp, (now() - interval '16441 minutes')::timestamp + interval '29 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.dpr41@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'ditolak', (now() - interval '16307 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Dwi Persada Raya', 'Kimia', 'Swasta nasional', 'Jl. Soekarno Hatta No. 21', 'Malang', 'Indah Safitri', 'Direktur', '086045828363', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '16307 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', 'Perusahaan terindikasi outsourcing tanpa izin resmi.', LEAST(now()::timestamp, (now() - interval '16307 minutes')::timestamp + interval '11 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('arif.anggraini.3299@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'ditolak', (now() - interval '15422 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Arif Anggraini', '2496123299', '081395575718', 'aktif', 2024, NULL, 3.22, 'Pasuruan', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi Manajemen' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '15422 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', 'Data pendaftar tidak ditemukan di sistem akademik Polinema.', LEAST(now()::timestamp, (now() - interval '15422 minutes')::timestamp + interval '15 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.pmj43@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'perbaikan', (now() - interval '15261 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Prima Mandiri Jaya', 'Kimia', 'Swasta nasional', 'Jl. Soekarno Hatta No. 11', 'Batu', 'Dafa Amalia', 'HR Manager', '086822793084', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '15261 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Alamat perusahaan belum lengkap (kecamatan dan kode pos).', LEAST(now()::timestamp, (now() - interval '15261 minutes')::timestamp + interval '25 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('andi.hidayat.0357@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'ditolak', (now() - interval '14036 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Andi Hidayat', '2295300357', '086993641088', 'aktif', 2022, NULL, 2.86, 'Sidoarjo', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Jaringan Telekomunikasi Digital' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '14036 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', 'Pendaftaran ganda, akun lain dengan NIM yang sama sudah aktif.', LEAST(now()::timestamp, (now() - interval '14036 minutes')::timestamp + interval '29 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('putri.hidayat.7990@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'perbaikan', (now() - interval '13996 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Putri Hidayat', '2595987990', '081214380122', 'aktif', 2025, NULL, 3.04, 'Surabaya', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Keuangan' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '13996 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'NIM tidak sesuai dengan KTM yang diunggah.', LEAST(now()::timestamp, (now() - interval '13996 minutes')::timestamp + interval '27 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('adi.wijaya.5239@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'perbaikan', (now() - interval '11686 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Adi Wijaya', '2395625239', '081777440975', 'aktif', 2023, NULL, 3.13, 'Kediri', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknologi Informasi' AND ps.nama = 'Sistem Informasi Bisnis' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '11686 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Alamat perusahaan belum lengkap (kecamatan dan kode pos).', LEAST(now()::timestamp, (now() - interval '11686 minutes')::timestamp + interval '18 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hana.wulandari.8186@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'perbaikan', (now() - interval '10287 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Hana Wulandari', '2096488186', '082306634502', 'alumni', 2020, 2024, 3.88, 'Blitar', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Kimia' AND ps.nama = 'Teknologi Kimia Industri' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '10287 minutes')::timestamp);
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Foto KTM buram, mohon unggah ulang dengan jelas.', LEAST(now()::timestamp, (now() - interval '10287 minutes')::timestamp + interval '5 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.gns48@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'perbaikan', (now() - interval '9180 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Graha Niaga Sejahtera', 'Perdagangan dan Jasa', 'BUMN', 'Jl. Ijen No. 125', 'Surabaya', 'Bima Amalia', 'Manajer SDM', '083195811059', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '9180 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Dokumen NIB kedaluwarsa, mohon unggah NIB terbaru.', LEAST(now()::timestamp, (now() - interval '9180 minutes')::timestamp + interval '34 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.mkj49@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'perbaikan', (now() - interval '9122 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Mitra Konstruksi Jaya', 'Kelistrikan', 'Startup', 'Jl. Gatot Subroto No. 121', 'Surabaya', 'Reza Hakim', 'HR Officer', '087445200701', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '9122 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', 'Ijazah/SKL belum dilegalisir.', LEAST(now()::timestamp, (now() - interval '9122 minutes')::timestamp + interval '11 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.grj50@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'ditolak', (now() - interval '9085 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Global Rekayasa Jaya', 'Teknologi Informasi', 'Swasta nasional', 'Jl. Industri Raya No. 125', 'Probolinggo', 'Agus Setiawan', 'Manajer SDM', '086541590046', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '9085 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', 'Perusahaan terindikasi outsourcing tanpa izin resmi.', LEAST(now()::timestamp, (now() - interval '9085 minutes')::timestamp + interval '12 hours'));
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('dina.prasetyo.0562@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '8346 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Dina Prasetyo', '2291830562', '087085965199', 'aktif', 2022, NULL, 2.94, 'Malang', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Administrasi Niaga' AND ps.nama = 'Manajemen Pemasaran Digital' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '8346 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.bsn52@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '8294 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Bumi Solusi Nusantara', 'Kelistrikan', 'BUMN', 'Jl. Gatot Subroto No. 26', 'Kediri', 'Fikri Anggraini', 'Manajer SDM', '088881878308', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '8294 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hendra.amalia.0703@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '8135 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Hendra Amalia', '2198070703', '088284786655', 'alumni', 2021, 2024, 3.46, 'Probolinggo', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '8135 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('gilang.firmansyah.3378@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '8023 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Gilang Firmansyah', '2496533378', '083608478070', 'aktif', 2024, NULL, 3.86, 'Lumajang', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Administrasi Niaga' AND ps.nama = 'Manajemen Pemasaran Digital' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '8023 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('gilang.wulandari.5469@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '8012 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Gilang Wulandari', '2494205469', '082255998416', 'aktif', 2024, NULL, 3.49, 'Blitar', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknologi Informasi' AND ps.nama = 'Pengembangan Peranti Lunak Situs' AND ps.jenjang = 'D-II' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '8012 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('indah.pratama.1442@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '7995 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Indah Pratama', '1995281442', '082817467886', 'alumni', 2019, 2022, 3.44, 'Blitar', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '7995 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('dimas.lestari.5516@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '7932 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Dimas Lestari', '2599675516', '087977403186', 'aktif', 2025, NULL, 3.27, 'Mojokerto', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknologi Informasi' AND ps.nama = 'Sistem Informasi Bisnis' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '7932 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.cmi58@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '7691 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Cahaya Mandiri Indonesia', 'Kelistrikan', 'BUMN', 'Jl. Ahmad Yani No. 68', 'Probolinggo', 'Alya Lestari', 'Recruitment Specialist', '084534911595', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '7691 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.mas59@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '7401 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Mega Abadi Sejahtera', 'Kelistrikan', 'Swasta asing', 'Jl. Raya Tlogomas No. 24', 'Batu', 'Naufal Hidayat', 'Manajer SDM', '082186238607', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '7401 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.dds60@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '7371 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Dwi Digital Sejahtera', 'Keuangan', 'Swasta nasional', 'Jl. Gatot Subroto No. 87', 'Jember', 'Dimas Utami', 'HR Manager', '084898514697', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '7371 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('bagas.wijaya.6488@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '7302 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Bagas Wijaya', '2592546488', '081919446003', 'aktif', 2025, NULL, 3.36, 'Tulungagung', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Teknik Elektronika' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '7302 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.sli62@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '7257 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Sentosa Logistik Indonesia', 'Perdagangan dan Jasa', 'Startup', 'Jl. Veteran No. 25', 'Jember', 'Rizky Amalia', 'HR Officer', '086722053114', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '7257 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('zahra.pratama.4876@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '7015 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Zahra Pratama', '2394874876', '083701129124', 'aktif', 2023, NULL, 3.3, 'Blitar', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Administrasi Niaga' AND ps.nama = 'Manajemen Pemasaran Digital' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '7015 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('sari.hidayat.0629@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '6647 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Sari Hidayat', '2195510629', '085475644889', 'alumni', 2021, 2025, 3.57, 'Kediri', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Teknik Elektronika' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '6647 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('citra.saputra.0707@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '6005 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Citra Saputra', '2192580707', '087798314544', 'alumni', 2021, 2025, 3.63, 'Pasuruan', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknologi Informasi' AND ps.nama = 'Pengembangan Peranti Lunak Situs' AND ps.jenjang = 'D-II' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '6005 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('wahyu.hakim.8428@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '5742 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Wahyu Hakim', '2098808428', '088362732575', 'alumni', 2020, 2024, 3.64, 'Tulungagung', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Teknik Elektronika' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '5742 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('citra.pratama.7065@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '5643 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Citra Pratama', '2392477065', '084240893072', 'aktif', 2023, NULL, 3.04, 'Probolinggo', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Mesin' AND ps.nama = 'Teknik Otomotif Elektronik' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '5643 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('zahra.firmansyah.7654@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '4745 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Zahra Firmansyah', '2497207654', '083233425542', 'aktif', 2024, NULL, 3.11, 'Lumajang', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknologi Informasi' AND ps.nama = 'Sistem Informasi Bisnis' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '4745 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.nli69@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '4707 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Nusa Logistik Indonesia', 'Perdagangan dan Jasa', 'BUMN', 'Jl. Soekarno Hatta No. 188', 'Madiun', 'Raka Prasetyo', 'Direktur', '085458905850', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '4707 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.gdi70@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '4535 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Global Data Indonesia', 'Teknologi Informasi', 'Swasta nasional', 'Jl. Ahmad Yani No. 184', 'Tulungagung', 'Bayu Safitri', 'Manajer SDM', '088683798534', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '4535 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('salsa.nugroho.9496@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '4484 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Salsa Nugroho', '2394709496', '087224752728', 'aktif', 2023, NULL, 3.76, 'Surabaya', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Sipil' AND ps.nama = 'Teknik Sipil' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '4484 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.sdr72@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '4396 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Sinar Digital Raya', 'Teknologi Informasi', 'Swasta nasional', 'Jl. Industri Raya No. 4', 'Sidoarjo', 'Rani Hakim', 'Direktur', '086163269860', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '4396 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('gilang.setiawan.4583@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '4376 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Gilang Setiawan', '2393854583', '088624629466', 'aktif', 2023, NULL, 3.68, 'Tulungagung', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Mesin' AND ps.nama = 'Teknik Mesin' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '4376 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('nadia.utami.3897@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '4328 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Nadia Utami', '2094563897', '089045629262', 'alumni', 2020, 2024, 3.71, 'Pasuruan', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknologi Informasi' AND ps.nama = 'Sistem Informasi Bisnis' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '4328 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('farah.saputra.3753@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '4214 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Farah Saputra', '2292913753', '084478006210', 'aktif', 2022, NULL, 2.97, 'Sidoarjo', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknologi Informasi' AND ps.nama = 'Pengembangan Peranti Lunak Situs' AND ps.jenjang = 'D-II' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '4214 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('wahyu.wijaya.6312@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '4194 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Wahyu Wijaya', '2495246312', '089466313661', 'aktif', 2024, NULL, 3.61, 'Sidoarjo', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Administrasi Niaga' AND ps.nama = 'Administrasi Bisnis' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '4194 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('ardi.nugroho.2760@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '4065 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Ardi Nugroho', '2593352760', '084034059668', 'aktif', 2025, NULL, 3.67, 'Probolinggo', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Sipil' AND ps.nama = 'Teknik Sipil' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '4065 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.dpj78@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '3989 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Daya Persada Jaya', 'Keuangan', 'BUMN', 'Jl. Ijen No. 168', 'Mojokerto', 'Reza Permata', 'HR Manager', '085808176013', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '3989 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('dewi.nugroho.8754@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '3882 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Dewi Nugroho', '2297528754', '081588902185', 'aktif', 2022, NULL, 2.92, 'Tulungagung', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '3882 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.cti80@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '3871 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Cahaya Teknologi Indonesia', 'Konstruksi', 'Swasta asing', 'Jl. Industri Raya No. 191', 'Kediri', 'Andi Nugroho', 'Manajer SDM', '082740014995', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '3871 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.ddi81@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '3546 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Dwi Digital Indonesia', 'Kimia', 'Swasta nasional', 'Jl. Ahmad Yani No. 73', 'Surabaya', 'Joko Anggraini', 'Direktur', '088666954219', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '3546 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('tiara.utami.6098@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '3540 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Tiara Utami', '2295966098', '086111251183', 'aktif', 2022, NULL, 2.85, 'Probolinggo', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Mesin' AND ps.nama = 'Teknik Mesin' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '3540 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.cns83@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '3371 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Citra Niaga Sejahtera', 'Perdagangan dan Jasa', 'BUMN', 'Jl. Ahmad Yani No. 44', 'Jember', 'Aisyah Ramadhan', 'Talent Acquisition', '083435848486', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '3371 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.bnn84@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '3361 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Bina Niaga Nusantara', 'Kelistrikan', 'BUMN', 'Jl. Industri Raya No. 95', 'Kediri', 'Hana Wijaya', 'HR Manager', '089358245274', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '3361 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('andi.wijaya.0272@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '3243 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Andi Wijaya', '2498450272', '081120481204', 'aktif', 2024, NULL, 3.67, 'Probolinggo', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Elektro' AND ps.nama = 'Jaringan Telekomunikasi Digital' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '3243 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('ayu.gunawan.1494@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '2784 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Ayu Gunawan', '1998861494', '083720709459', 'alumni', 2019, 2022, 3.85, 'Tulungagung', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '2784 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('dewi.lestari.0905@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '2659 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Dewi Lestari', '2593530905', '086392649951', 'aktif', 2025, NULL, 2.88, 'Mojokerto', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '2659 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.mrj88@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '2532 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Mitra Rekayasa Jaya', 'Konstruksi', 'Swasta nasional', 'Jl. Ijen No. 237', 'Tulungagung', 'Kevin Permata', 'Direktur', '083575000727', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '2532 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('reza.setiawan.7882@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '2272 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Reza Setiawan', '1993107882', '082665945259', 'alumni', 2019, 2022, 3.02, 'Sidoarjo', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '2272 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('lutfi.utami.5664@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '2267 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Lutfi Utami', '2099765664', '086236258864', 'alumni', 2020, 2024, 3.45, 'Sidoarjo', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Keuangan' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '2267 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.tkj91@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '1863 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Tirta Konstruksi Jaya', 'Perdagangan dan Jasa', 'Swasta nasional', 'Jl. Ijen No. 60', 'Kediri', 'Kevin Pratama', 'HR Manager', '081521578158', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '1863 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.crr92@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '1792 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Citra Rekayasa Raya', 'Kelistrikan', 'Swasta nasional', 'Jl. Soekarno Hatta No. 199', 'Lumajang', 'Aisyah Pratama', 'Manajer SDM', '089554726971', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '1792 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.san93@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '1526 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Sinar Abadi Nusantara', 'Kimia', 'Swasta nasional', 'Jl. Ahmad Yani No. 160', 'Surabaya', 'Bella Syahputra', 'Manajer SDM', '086834181703', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '1526 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('bayu.rahmawati.4541@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '1330 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Bayu Rahmawati', '2091234541', '088543715973', 'alumni', 2020, 2024, 3.27, 'Banyuwangi', 'contoh-ijazah.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Administrasi Niaga' AND ps.nama = 'Manajemen Pemasaran Digital' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ijazah', 'contoh-ijazah.pdf', 2, (now() - interval '1330 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('dimas.wijaya.5984@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '1263 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Dimas Wijaya', '2492315984', '081631315199', 'aktif', 2024, NULL, 3.61, 'Blitar', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Sipil' AND ps.nama = 'Teknik Sipil' AND ps.jenjang = 'D-III' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '1263 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.mlr96@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '822 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Mitra Logistik Raya', 'Manufaktur', 'BUMN', 'Jl. Veteran No. 78', 'Kediri', 'Citra Kurniawan', 'HR Officer', '083924143948', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '822 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.psi97@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '818 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Prima Solusi Indonesia', 'Perdagangan dan Jasa', 'Startup', 'Jl. Raya Tlogomas No. 112', 'Kediri', 'Putri Nugroho', 'HR Officer', '084090530514', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '818 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('anisa.amalia.0925@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '517 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Anisa Amalia', '2496160925', '087385836703', 'aktif', 2024, NULL, 3.6, 'Banyuwangi', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Akuntansi' AND ps.nama = 'Akuntansi Manajemen' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '517 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('fajar.kurniawan.7824@dummy.polinema.test', '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.', 'mahasiswa', 'menunggu', (now() - interval '475 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)
    SELECT v_id, ps.id, 'Fajar Kurniawan', '2491567824', '082285344569', 'aktif', 2024, NULL, 3.41, 'Mojokerto', 'contoh-ktm.pdf'
      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE j.nama = 'Teknik Sipil' AND ps.nama = 'Manajemen Rekayasa Konstruksi' AND ps.jenjang = 'D-IV' LIMIT 1;
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, 'ktm', 'contoh-ktm.pdf', 2, (now() - interval '475 minutes')::timestamp);
  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)
    VALUES ('hrd.ski100@dummy-perusahaan.test', '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My', 'perusahaan', 'menunggu', (now() - interval '91 minutes')::timestamp) RETURNING id INTO v_id;
  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)
    VALUES (v_id, 'PT Surya Konstruksi Indonesia', 'Perdagangan dan Jasa', 'Startup', 'Jl. Raya Tlogomas No. 157', 'Sidoarjo', 'Bima Saputra', 'Direktur', '086178181535', true);
  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)
    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, (now() - interval '91 minutes')::timestamp FROM unnest(ARRAY['nib','npwp','akta']) AS t;

  PERFORM urutkan_no_pendaftaran();
  RAISE NOTICE '100 pendaftar dummy dimasukkan, nomor pendaftaran diurutkan ulang.';
END
$dummy_pendaftar$;
