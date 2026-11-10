-- =====================================================================
-- KarirKu Polinema · Revisi profil (Oktober 2026, tahap 2)
--  - Pendidikan, pengalaman, dan sertifikat menyimpan data lengkap yang
--    dibutuhkan perusahaan (jenjang, NIM, nomor ijazah, jenis pekerjaan,
--    nomor kredensial, dll.) di kolom detail (JSONB).
--  - Profil Admin: foto, jabatan, dan nomor WhatsApp.
-- Jalankan SETELAH 01-04. Aman dijalankan berulang kali.
-- =====================================================================
DO $cek$
BEGIN
  IF to_regclass('public.profil_item') IS NULL THEN
    RAISE EXCEPTION 'Tabel belum ada. Jalankan 01-04 dulu, atau cukup jalankan 00-INSTAL-ULANG.sql.';
  END IF;
END
$cek$;

ALTER TABLE profil_item ADD COLUMN IF NOT EXISTS detail jsonb NOT NULL DEFAULT '{}'::jsonb;
CREATE INDEX IF NOT EXISTS idx_profil_item_file2 ON profil_item ((detail->>'file2'));

ALTER TABLE admin ADD COLUMN IF NOT EXISTS foto        varchar(255);
ALTER TABLE admin ADD COLUMN IF NOT EXISTS jabatan     varchar(150);
ALTER TABLE admin ADD COLUMN IF NOT EXISTS no_whatsapp varchar(30);
UPDATE admin SET jabatan = 'Admin Career Center' WHERE jabatan IS NULL;

-- ---------------------------------------------------------------------
-- Lengkapi detail item profil data contoh yang masih kosong (revisi tahap 2)
-- ---------------------------------------------------------------------
-- (kolom dibuat di sini juga, jadi aman bila 05 dijalankan sebelum 06)
ALTER TABLE profil_item ADD COLUMN IF NOT EXISTS detail jsonb NOT NULL DEFAULT '{}'::jsonb;
UPDATE profil_item pi SET detail = jsonb_strip_nulls(jsonb_build_object(
    'jenjang', CASE ps.jenjang WHEN 'D-II' THEN 'D2' WHEN 'D-III' THEN 'D3' WHEN 'D-IV' THEN 'D4 / Sarjana Terapan' ELSE 'S2 Terapan' END,
    'fakultas', j.nama, 'nomor_induk', m.nim, 'kota', 'Malang',
    'nilai', replace(to_char(3.20 + (pi.id % 7) * 0.1, 'FM0.00'), '.', ','), 'skala', '4,00',
    'akreditasi', CASE WHEN pi.id % 3 = 0 THEN 'A' ELSE 'Unggul' END))
  FROM mahasiswa m JOIN program_studi ps ON ps.id = m.program_studi_id JOIN jurusan j ON j.id = ps.jurusan_id
 WHERE pi.mahasiswa_id = m.id AND pi.tipe = 'pendidikan' AND pi.detail = '{}'::jsonb AND pi.instansi ILIKE '%Politeknik Negeri Malang%';

UPDATE profil_item pi SET detail = jsonb_build_object(
    'jenjang', CASE WHEN pi.instansi ILIKE '%SMK%' THEN 'SMK' WHEN pi.instansi ILIKE '%MA %' OR pi.instansi ILIKE 'MAN%' THEN 'MA' ELSE 'SMA' END,
    'nomor_induk', '00' || (5000000 + pi.id * 37)::text,
    'kota', COALESCE(NULLIF(regexp_replace(pi.instansi, '^.*\s', ''), ''), 'Malang'),
    'nilai', (82 + pi.id % 13)::text || ',' || (pi.id % 10)::text, 'skala', '100',
    'nomor_ijazah', 'DN-05/' || CASE WHEN pi.instansi ILIKE '%SMK%' THEN 'M-SMK' ELSE 'M-SMA' END || '/K13/' || lpad((pi.id * 131 % 99999)::text, 5, '0'),
    'akreditasi', 'A')
 WHERE pi.tipe = 'pendidikan' AND pi.detail = '{}'::jsonb;

UPDATE profil_item pi SET detail = jsonb_build_object(
    'jenis', CASE WHEN pi.judul ILIKE '%magang%' OR pi.judul ILIKE '%intern%' OR pi.judul ILIKE '%PKL%' THEN 'Magang / PKL'
                  WHEN pi.judul ILIKE '%asisten%' OR pi.judul ILIKE '%ketua%' OR pi.judul ILIKE '%anggota%' OR pi.judul ILIKE '%pengurus%' THEN 'Organisasi'
                  WHEN pi.judul ILIKE '%panitia%' OR pi.judul ILIKE '%koordinator%' THEN 'Kepanitiaan'
                  WHEN pi.judul ILIKE '%freelance%' THEN 'Freelance'
                  ELSE (ARRAY['Magang / PKL','Proyek','Kerja paruh waktu'])[1 + pi.id % 3] END,
    'bidang', (ARRAY['Teknologi Informasi','Operasional','Administrasi','Produksi','Pemasaran'])[1 + pi.id % 5],
    'lokasi', CASE WHEN pi.instansi ILIKE '%Polinema%' OR pi.instansi ILIKE '%Politeknik Negeri Malang%' THEN 'Malang' ELSE (ARRAY['Malang','Surabaya','Sidoarjo','Pasuruan','Jakarta'])[1 + pi.id % 5] END,
    'sistem', (ARRAY['Di kantor (WFO)','Hybrid','Di kantor (WFO)','Jarak jauh (WFH)'])[1 + pi.id % 4],
    'pencapaian', (ARRAY['Menyelesaikan seluruh target tugas tepat waktu dan mendapat nilai sangat baik dari pembimbing.',
                         'Membantu mempercepat penyusunan laporan bulanan sekitar 30%.',
                         'Mendampingi lebih dari 40 peserta dan menyusun modul pendukung.',
                         'Menyelesaikan 10+ fitur/pekerjaan yang dipakai tim setiap hari.'])[1 + pi.id % 4],
    'tools', (ARRAY['PHP, PostgreSQL, Git','Microsoft Excel, Google Sheets','Figma, Canva','AutoCAD, Microsoft Office','Python, Power BI'])[1 + pi.id % 5],
    'referensi_nama', (ARRAY['Hendra Wijaya (Supervisor)','Rina Kartika (HR)','Dr. Agus Salim (Pembimbing)','Dewi Lestari (Manajer)'])[1 + pi.id % 4])
 WHERE pi.tipe = 'pengalaman' AND pi.detail = '{}'::jsonb;

UPDATE profil_item pi SET detail = jsonb_build_object(
    'jenis', CASE WHEN pi.judul ILIKE '%BNSP%' OR pi.instansi ILIKE '%LSP%' OR pi.instansi ILIKE '%Sertifikasi Profesi%' THEN 'Sertifikasi kompetensi (BNSP/LSP)'
                  WHEN pi.judul ILIKE '%TOEFL%' OR pi.judul ILIKE '%TOEIC%' OR pi.judul ILIKE '%IELTS%' OR pi.judul ILIKE '%bahasa%' OR pi.judul ILIKE '%English%' THEN 'Kemampuan bahasa'
                  WHEN pi.judul ILIKE '%juara%' OR pi.judul ILIKE '%lomba%' THEN 'Lomba / penghargaan'
                  WHEN pi.judul ILIKE '%seminar%' OR pi.judul ILIKE '%workshop%' THEN 'Seminar / workshop'
                  WHEN pi.instansi ILIKE '%Cisco%' OR pi.instansi ILIKE '%Google%' OR pi.instansi ILIKE '%Microsoft%' OR pi.instansi ILIKE '%AWS%' OR pi.instansi ILIKE '%Oracle%' THEN 'Sertifikasi profesional / internasional'
                  ELSE 'Pelatihan / kursus' END,
    'nomor', upper(substr(md5(pi.id::text || pi.judul), 1, 4)) || '-' || to_char(COALESCE(pi.mulai, DATE '2025-01-01'), 'YYYY') || '-' || lpad((pi.id * 97 % 100000)::text, 5, '0'),
    'skor', CASE WHEN pi.judul ILIKE '%TOEFL%' THEN (480 + pi.id % 90)::text WHEN pi.judul ILIKE '%TOEIC%' THEN (650 + pi.id % 250)::text ELSE 'Kompeten' END)
 WHERE pi.tipe = 'sertifikat' AND pi.detail = '{}'::jsonb;
