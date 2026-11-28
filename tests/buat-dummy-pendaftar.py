#!/usr/bin/env python3
"""
Membuat database/10-data-dummy-pendaftar.sql: 100 akun pendaftar dummy
(60 mahasiswa/alumni + 40 perusahaan) dengan status verifikasi beragam,
untuk menguji antrean Persetujuan Akun, halaman Status akun, dan nomor
pendaftaran berurutan.

Jalankan ulang hanya bila ingin membuat ulang file SQL-nya:
  python3 tests/buat-dummy-pendaftar.py
"""
import os, random

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'database', '10-data-dummy-pendaftar.sql')
rnd = random.Random(20261117)

HASH_MHS = '$2b$10$5OLeCYv6YBC5QqR0Qf7C0OnpEMBOtcioLNFMQfuOkzW5ymJJ3D/0.'   # mahasiswa123
HASH_PRS = '$2b$10$E8ouzEPuzpc9moztG.PYkuQhsjQMZlDEeOXxRGjIjvgArT3ojj7My'   # perusahaan123

DEPAN = ['Adi', 'Agus', 'Aisyah', 'Alya', 'Andi', 'Anisa', 'Ardi', 'Arif', 'Ayu', 'Bagas', 'Bayu', 'Bella', 'Bima',
         'Citra', 'Dafa', 'Dewi', 'Dimas', 'Dina', 'Eka', 'Fajar', 'Farah', 'Fikri', 'Gilang', 'Hana', 'Hendra',
         'Indah', 'Intan', 'Irfan', 'Joko', 'Kevin', 'Laila', 'Lutfi', 'Maya', 'Nadia', 'Naufal', 'Nina', 'Putri',
         'Raka', 'Rani', 'Reza', 'Rizky', 'Salsa', 'Sari', 'Satria', 'Tiara', 'Tono', 'Vina', 'Wahyu', 'Yoga', 'Zahra']
BELAKANG = ['Pratama', 'Saputra', 'Wijaya', 'Lestari', 'Hidayat', 'Rahmawati', 'Kurniawan', 'Permata', 'Santoso',
            'Nugroho', 'Wulandari', 'Setiawan', 'Maharani', 'Firmansyah', 'Utami', 'Ramadhan', 'Anggraini',
            'Prasetyo', 'Safitri', 'Hakim', 'Puspita', 'Gunawan', 'Fitriani', 'Syahputra', 'Amalia']
KOTA = ['Malang', 'Batu', 'Blitar', 'Kediri', 'Pasuruan', 'Probolinggo', 'Surabaya', 'Sidoarjo', 'Lumajang', 'Jember',
        'Tulungagung', 'Mojokerto', 'Madiun', 'Banyuwangi']
PRODI = [  # jurusan, prodi, jenjang  (S2 tidak dipakai untuk pendaftar dummy)
    ('Administrasi Niaga', 'Administrasi Bisnis', 'D-III'), ('Administrasi Niaga', 'Manajemen Pemasaran Digital', 'D-IV'),
    ('Akuntansi', 'Akuntansi', 'D-III'), ('Akuntansi', 'Akuntansi Manajemen', 'D-IV'), ('Akuntansi', 'Keuangan', 'D-IV'),
    ('Teknik Elektro', 'Teknik Listrik', 'D-III'), ('Teknik Elektro', 'Jaringan Telekomunikasi Digital', 'D-IV'),
    ('Teknik Elektro', 'Teknik Elektronika', 'D-IV'), ('Teknik Kimia', 'Teknologi Kimia Industri', 'D-IV'),
    ('Teknik Mesin', 'Teknik Mesin', 'D-III'), ('Teknik Mesin', 'Teknik Otomotif Elektronik', 'D-IV'),
    ('Teknik Sipil', 'Teknik Sipil', 'D-III'), ('Teknik Sipil', 'Manajemen Rekayasa Konstruksi', 'D-IV'),
    ('Teknologi Informasi', 'Teknik Informatika', 'D-IV'), ('Teknologi Informasi', 'Sistem Informasi Bisnis', 'D-IV'),
    ('Teknologi Informasi', 'Pengembangan Peranti Lunak Situs', 'D-II'),
]
PT_DEPAN = ['Cahaya', 'Mitra', 'Sinar', 'Karya', 'Prima', 'Bumi', 'Global', 'Nusa', 'Daya', 'Citra', 'Mega', 'Sentosa',
            'Inti', 'Artha', 'Tirta', 'Surya', 'Bina', 'Graha', 'Dwi', 'Tri']
PT_BELAKANG = ['Teknologi', 'Solusi', 'Mandiri', 'Persada', 'Utama', 'Abadi', 'Digital', 'Industri', 'Konstruksi',
               'Energi', 'Logistik', 'Kreasi', 'Niaga', 'Rekayasa', 'Data']
BIDANG = ['Teknologi Informasi', 'Manufaktur', 'Konstruksi', 'Keuangan', 'Kimia', 'Kelistrikan', 'Perdagangan dan Jasa']
JENIS = ['Swasta nasional', 'Swasta nasional', 'Swasta nasional', 'Swasta asing', 'BUMN', 'Startup']
JABATAN = ['HR Officer', 'HR Manager', 'Manajer SDM', 'Talent Acquisition', 'Recruitment Specialist', 'Direktur']
CATATAN_PERBAIKAN = ['Foto KTM buram, mohon unggah ulang dengan jelas.', 'NIM tidak sesuai dengan KTM yang diunggah.',
                     'Dokumen NIB kedaluwarsa, mohon unggah NIB terbaru.', 'Nomor WhatsApp PIC tidak dapat dihubungi, mohon periksa kembali.',
                     'Alamat perusahaan belum lengkap (kecamatan dan kode pos).', 'Ijazah/SKL belum dilegalisir.']
CATATAN_TOLAK = ['Perusahaan terindikasi outsourcing tanpa izin resmi.', 'Data pendaftar tidak ditemukan di sistem akademik Polinema.',
                 'Dokumen legalitas tidak sesuai dengan nama perusahaan.', 'Pendaftaran ganda, akun lain dengan NIM yang sama sudah aktif.']

def q(s):
    return "'" + str(s).replace("'", "''") + "'"

# --- susun 100 pendaftar dengan status ---------------------------------
status_mhs = ['menunggu'] * 30 + ['perbaikan'] * 9 + ['ditolak'] * 6 + ['aktif'] * 15
status_prs = ['menunggu'] * 20 + ['perbaikan'] * 6 + ['ditolak'] * 4 + ['aktif'] * 10
orang = [('mahasiswa', s) for s in status_mhs] + [('perusahaan', s) for s in status_prs]
rnd.shuffle(orang)
# Tanggal daftar menyebar dalam 30 hari terakhir, urut naik (nomor urut mengikuti tanggal).
# Yang "menunggu" ditaruh di bagian akhir (6 hari terakhir) agar lama menunggunya wajar.
orang.sort(key=lambda o: {'aktif': 0, 'ditolak': 1, 'perbaikan': 1, 'menunggu': 2}[o[1]] + rnd.random() * 0.9)
# menit sebelum sekarang: yang sudah diputuskan 30 sampai 6 hari lalu, yang menunggu 6 hari terakhir
n_tunggu = sum(1 for o in orang if o[1] == 'menunggu')
menit = (sorted(rnd.sample(range(6 * 24 * 60, 30 * 24 * 60), len(orang) - n_tunggu), reverse=True)
         + sorted(rnd.sample(range(30, 6 * 24 * 60), n_tunggu), reverse=True))

nim_dipakai, email_dipakai, pt_dipakai = set(), set(), set()
baris = []
for i, ((role, status), mnt) in enumerate(zip(orang, menit), 1):
    if role == 'mahasiswa':
        nama = f'{rnd.choice(DEPAN)} {rnd.choice(BELAKANG)}'
        jur, prodi, jenjang = rnd.choice(PRODI)
        alumni = rnd.random() < 0.3
        angkatan = rnd.choice([2019, 2020, 2021]) if alumni else rnd.choice([2022, 2023, 2024, 2025])
        while True:
            nim = f'{angkatan % 100:02d}9{rnd.randint(1000000, 9999999)}'
            if nim not in nim_dipakai: nim_dipakai.add(nim); break
        email = f"{nama.lower().replace(' ', '.')}.{nim[-4:]}@dummy.polinema.test"
        baris.append(dict(role=role, status=status, mnt=mnt, email=email, nama=nama, jur=jur, prodi=prodi, jenjang=jenjang,
                          nim=nim, wa=f'08{rnd.randint(1100000000, 9999999999)}', smhs='alumni' if alumni else 'aktif',
                          angkatan=angkatan, lulus=(angkatan + (3 if jenjang == 'D-III' else 4)) if alumni else None,
                          ipk=round(rnd.uniform(2.8, 3.95), 2), kota=rnd.choice(KOTA)))
    else:
        while True:
            nama = f'PT {rnd.choice(PT_DEPAN)} {rnd.choice(PT_BELAKANG)} {rnd.choice(["Indonesia", "Nusantara", "Jaya", "Sejahtera", "Raya"])}'
            if nama not in pt_dipakai: pt_dipakai.add(nama); break
        slug = ''.join(w[0] for w in nama.split()[1:]).lower() + str(i)
        email = f'hrd.{slug}@dummy-perusahaan.test'
        baris.append(dict(role=role, status=status, mnt=mnt, email=email, nama=nama, bidang=rnd.choice(BIDANG),
                          jenis=rnd.choice(JENIS), kota=rnd.choice(KOTA), alamat=f'Jl. {rnd.choice(["Soekarno Hatta", "Ahmad Yani", "Veteran", "Ijen", "Raya Tlogomas", "Industri Raya", "Gatot Subroto"])} No. {rnd.randint(1, 250)}',
                          pic=f'{rnd.choice(DEPAN)} {rnd.choice(BELAKANG)}', jabatan=rnd.choice(JABATAN),
                          wa=f'08{rnd.randint(1100000000, 9999999999)}'))

# --- tulis SQL -----------------------------------------------------------
L = []
w = L.append
w('''-- =====================================================================
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
''')
for b in baris:
    tgl = f"(now() - interval '{b['mnt']} minutes')::timestamp"
    h = HASH_MHS if b['role'] == 'mahasiswa' else HASH_PRS
    w(f"  INSERT INTO pengguna (email, password_hash, role, status_akun, dibuat_pada)\n"
      f"    VALUES ({q(b['email'])}, {q(h)}, {q(b['role'])}, {q(b['status'])}, {tgl}) RETURNING id INTO v_id;")
    if b['role'] == 'mahasiswa':
        dok = 'ijazah' if b['smhs'] == 'alumni' else 'ktm'
        w(f"  INSERT INTO mahasiswa (pengguna_id, program_studi_id, nama, nim, no_whatsapp, status_mahasiswa, angkatan, tahun_lulus, ipk, domisili, file_ktm)\n"
          f"    SELECT v_id, ps.id, {q(b['nama'])}, {q(b['nim'])}, {q(b['wa'])}, {q(b['smhs'])}, {b['angkatan']}, "
          f"{b['lulus'] if b['lulus'] else 'NULL'}, {b['ipk']}, {q(b['kota'])}, {q('contoh-ijazah.pdf' if b['smhs'] == 'alumni' else 'contoh-ktm.pdf')}\n"
          f"      FROM program_studi ps JOIN jurusan j ON j.id = ps.jurusan_id\n"
          f"     WHERE j.nama = {q(b['jur'])} AND ps.nama = {q(b['prodi'])} AND ps.jenjang = {q(b['jenjang'])} LIMIT 1;")
        w(f"  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada) VALUES (v_id, '{dok}', '{'contoh-ijazah.pdf' if dok == 'ijazah' else 'contoh-ktm.pdf'}', 2, {tgl});")
    else:
        w(f"  INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, nama_pic, jabatan_pic, whatsapp_pic, bukan_outsourcing)\n"
          f"    VALUES (v_id, {q(b['nama'])}, {q(b['bidang'])}, {q(b['jenis'])}, {q(b['alamat'])}, {q(b['kota'])}, {q(b['pic'])}, {q(b['jabatan'])}, {q(b['wa'])}, true);")
        w(f"  INSERT INTO dokumen_verifikasi (pengguna_id, tipe, file, ukuran_kb, diunggah_pada)\n"
          f"    SELECT v_id, t, t || '-pt' || (1 + v_id % 18) || '.pdf', 2, {tgl} FROM unnest(ARRAY['nib','npwp','akta']) AS t;")
    jam = rnd.randint(4, 40)
    if b['status'] == 'aktif':
        w(f"  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, tanggal) VALUES (v_id, v_admin, 'disetujui', LEAST(now()::timestamp, {tgl} + interval '{jam} hours'));")
    elif b['status'] == 'perbaikan':
        w(f"  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'perbaikan', {q(rnd.choice(CATATAN_PERBAIKAN))}, LEAST(now()::timestamp, {tgl} + interval '{jam} hours'));")
    elif b['status'] == 'ditolak':
        w(f"  INSERT INTO verifikasi_akun (pengguna_id, admin_id, keputusan, catatan, tanggal) VALUES (v_id, v_admin, 'ditolak', {q(rnd.choice(CATATAN_TOLAK))}, LEAST(now()::timestamp, {tgl} + interval '{jam} hours'));")
w('''
  PERFORM urutkan_no_pendaftaran();
  RAISE NOTICE '100 pendaftar dummy dimasukkan, nomor pendaftaran diurutkan ulang.';
END
$dummy_pendaftar$;
''')
open(OUT, 'w').write('\n'.join(L))
print('ditulis', OUT, len(baris), 'pendaftar')
