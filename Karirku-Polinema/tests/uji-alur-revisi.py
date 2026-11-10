#!/usr/bin/env python3
"""
Uji alur revisi dosen (A-M) dari ujung ke ujung lewat HTTP sungguhan.
Butuh: server di http://127.0.0.1:8000, database baru dimuat (01-04), pip requests.
Jalankan: python3 tests/uji-alur-revisi.py
Catatan: skrip ini MENGUBAH data (membuat lowongan, lamaran, reset sandi). Muat ulang
database sesudahnya bila ingin kembali ke data demo awal.
"""
import os, re, sys, datetime, subprocess
import requests

B = os.environ.get('APP_URL', 'http://127.0.0.1:8000')
DB = dict(host=os.environ.get('DB_HOST', '127.0.0.1'), user=os.environ.get('DB_USER', 'postgres'),
          pw=os.environ.get('DB_PASS', 'postgres'), name=os.environ.get('DB_NAME', 'karirku_polinema'))
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAGAL = []

def sql(q):
    env = dict(os.environ, PGPASSWORD=DB['pw'])
    return subprocess.run(['psql', '-h', DB['host'], '-U', DB['user'], '-d', DB['name'], '-tAc', q],
                          capture_output=True, text=True, env=env).stdout.strip()

def cek(label, kondisi, info=''):
    print(('  ok     ' if kondisi else '  GAGAL  ') + label + ('' if kondisi else '  -> ' + str(info)[:300]))
    if not kondisi: GAGAL.append(label)

def token(s, path):
    r = s.get(B + '/' + path)
    m = re.search(r'name="csrf_token" value="([^"]+)"', r.text)
    return (m.group(1) if m else ''), r

def masuk(email, pw, ingat=False):
    s = requests.Session()
    t, _ = token(s, 'masuk')
    d = {'csrf_token': t, 'email': email, 'password': pw}
    if ingat: d['ingat_saya'] = '1'
    r = s.post(B + '/auth/proses-masuk', data=d)
    return s, r

def post(s, halaman, url, data, files=None):
    t, _ = token(s, halaman)
    data = dict(data, csrf_token=t)
    return s.post(B + '/' + url, data=data, files=files)

def flash(r):
    m = re.search(r'class="alert alert-(ok|bad|warn|info)[^"]*"[^>]*>(.*?)</div>', r.text, re.S)
    return (m.group(1), re.sub(r'<[^>]+>', ' ', m.group(2)).strip()) if m else (None, '')

besok = (datetime.date.today() + datetime.timedelta(days=20)).isoformat()
pamflet = os.path.join(ROOT, 'public/assets/img/hero-1.jpg')

print('=== J. Cookie & header keamanan ===')
r = requests.get(B + '/masuk')
ck = r.headers.get('Set-Cookie', '')
cek('cookie sesi HttpOnly', 'httponly' in ck.lower(), ck)
cek('cookie sesi SameSite=Lax', 'samesite=lax' in ck.lower(), ck)
cek('X-Frame-Options', r.headers.get('X-Frame-Options') == 'SAMEORIGIN')
cek('X-Content-Type-Options', r.headers.get('X-Content-Type-Options') == 'nosniff')

print('=== B. Masuk, kembali ke halaman tujuan, Ingat saya ===')
s = requests.Session()
r = s.get(B + '/admin/rekap-lamaran?angkatan=2022', allow_redirects=True)
cek('tamu ke halaman admin dialihkan ke masuk', '/masuk' in r.url, r.url)
t = re.search(r'name="csrf_token" value="([^"]+)"', r.text).group(1)
r = s.post(B + '/auth/proses-masuk', data={'csrf_token': t, 'email': 'admin@polinema.ac.id', 'password': 'admin123'})
cek('sesudah masuk kembali ke halaman tujuan', 'rekap-lamaran' in r.url and 'angkatan=2022' in r.url, r.url)
cek('halaman admin no-store', 'no-store' in r.headers.get('Cache-Control', ''), r.headers.get('Cache-Control'))
admin = s

m, r = masuk('mahasiswa@polinema.ac.id', 'mahasiswa123', ingat=True)
cek('cookie Ingat saya terpasang', any(c.name == 'karirku_ingat' for c in m.cookies))
s2 = requests.Session()
s2.cookies.set('karirku_ingat', m.cookies.get('karirku_ingat'))
r = s2.get(B + '/mahasiswa/dashboard')
cek('Ingat saya: sesi baru tetap masuk tanpa password', r.status_code == 200 and '/masuk' not in r.url, r.url)

print('=== G. CSRF kedaluwarsa tidak memunculkan halaman error ===')
r = m.post(B + '/mahasiswa/simpan-pengaturan-akun', data={'csrf_token': 'salah', 'aksi': 'kontak', 'no_whatsapp': '081234'},
           headers={'Referer': B + '/mahasiswa/pengaturan-akun'})
cek('token salah -> kembali ke formulir dengan pesan', r.status_code == 200 and 'pengaturan-akun' in r.url and flash(r)[0] == 'warn', (r.status_code, r.url, flash(r)))

print('=== H. Paginasi ===')
r = admin.get(B + '/admin/monitoring-lowongan')
cek('monitoring menampilkan maksimal 10 baris', r.text.count('admin/detail-lowongan/') <= 20 and 'paginasi-info' in r.text)
r = admin.get(B + '/admin/monitoring-lowongan?halaman=999')
cek('halaman di luar jangkauan dialihkan', 'halaman=999' not in r.url, r.url)

print('=== M. Lowongan baru menunggu persetujuan ===')
pt, _ = masuk('perusahaan@polinema.ac.id', 'perusahaan123')
bidang = sql("select id from bidang order by id limit 1")
jur = sql("select id from jurusan order by id limit 1")
data = {'posisi': 'Uji Alur Revisi', 'bidang_id': bidang, 'jenis_pekerjaan': 'full_time', 'sistem_kerja': 'wfo',
        'lokasi': 'Malang', 'gaji': '', 'kuota': '2', 'batas_lamaran': besok, 'deskripsi': 'Deskripsi uji.',
        'kualifikasi': '- D4\n- Teliti', 'skill_dibutuhkan': 'PHP', 'jurusan_id[]': jur}
r = post(pt, 'lowongan/form-pasang', 'lowongan/proses-pasang', data)
cek('tanpa pamflet ditolak + isian lama dipulihkan', flash(r)[0] == 'bad' and 'Uji Alur Revisi' in r.text, flash(r))
r = post(pt, 'lowongan/form-pasang', 'lowongan/proses-pasang', data, files={'pamflet': ('a.txt', b'bukan gambar', 'text/plain')})
cek('pamflet format salah ditolak server', flash(r)[0] == 'bad', flash(r))
with open(pamflet, 'rb') as f:
    r = post(pt, 'lowongan/form-pasang', 'lowongan/proses-pasang', data, files={'pamflet': ('pamflet.jpg', f, 'image/jpeg')})
lid = sql("select id from lowongan where posisi='Uji Alur Revisi'")
cek('lowongan dibuat berstatus menunggu', sql(f"select status from lowongan where id={lid}") == 'menunggu')
kode = sql(f"select kode_pratinjau from lowongan where id={lid}")
cek('lowongan menunggu 404 untuk publik', requests.get(B + '/info-loker/' + kode).status_code == 404)
cek('lowongan menunggu 404 untuk mahasiswa', m.get(B + f'/lowongan/detail/{lid}').status_code == 404)
cek('admin mendapat notifikasi', int(sql(f"select count(*) from notifikasi n join pengguna p on p.id=n.pengguna_id where p.role='admin' and n.tautan like '%detail-lowongan/{lid}%'") or 0) >= 1)

print('=== K. Alasan wajib & revisi ===')
r = post(admin, f'admin/detail-lowongan/{lid}', f'admin/putuskan-lowongan/{lid}', {'keputusan': 'revisi', 'alasan': 'kurang'})
cek('revisi dengan alasan < 10 karakter ditolak', sql(f"select status from lowongan where id={lid}") == 'menunggu', flash(r))
r = post(admin, f'admin/detail-lowongan/{lid}', f'admin/putuskan-lowongan/{lid}', {'keputusan': 'revisi', 'alasan': 'Gaji dan deskripsi perlu diperjelas.'})
cek('revisi tersimpan', sql(f"select status from lowongan where id={lid}") == 'revisi', flash(r))
cek('email status lowongan tercatat di log_email', int(sql("select count(*) from log_email where subjek ilike '%lowongan%'") or 0) >= 1)
r = post(pt, f'lowongan/form-pasang/{lid}', 'lowongan/proses-pasang', dict(data, id=lid, gaji='5-6 juta'))
cek('perbaikan perusahaan -> kembali menunggu', sql(f"select status from lowongan where id={lid}") == 'menunggu', flash(r))
r = post(admin, f'admin/detail-lowongan/{lid}', f'admin/putuskan-lowongan/{lid}', {'keputusan': 'disetujui', 'alasan': ''})
cek('disetujui -> aktif', sql(f"select status from lowongan where id={lid}") == 'aktif', flash(r))
cek('setelah disetujui tampil untuk publik', requests.get(B + '/info-loker/' + kode).status_code == 200)
cek('riwayat lowongan lengkap (>=4 entri)', int(sql(f"select count(*) from riwayat_lowongan where lowongan_id={lid}")) >= 4)
r = post(pt, f'lowongan/form-pasang/{lid}', 'lowongan/proses-pasang', dict(data, id=lid, gaji='5-6 juta', posisi='Uji Alur Revisi (ubah)'))
cek('mengubah lowongan tayang -> perlu persetujuan ulang', sql(f"select status from lowongan where id={lid}") == 'menunggu', flash(r))
post(admin, f'admin/detail-lowongan/{lid}', f'admin/putuskan-lowongan/{lid}', {'keputusan': 'disetujui', 'alasan': ''})

print('=== D. Perpanjang ===')
baru = (datetime.date.today() + datetime.timedelta(days=60)).isoformat()
r = post(pt, 'perusahaan/lowongan', f'lowongan/perpanjang/{lid}', {'batas_lamaran': baru, 'kuota': '0'})
cek('kuota 0 ditolak', flash(r)[0] == 'bad', flash(r))
lewat = (datetime.date.today() + datetime.timedelta(days=400)).isoformat()
r = post(pt, 'perusahaan/lowongan', f'lowongan/perpanjang/{lid}', {'batas_lamaran': lewat, 'kuota': '3'})
cek('lebih dari 6 bulan ditolak', flash(r)[0] == 'bad', flash(r))
r = post(pt, 'perusahaan/lowongan', f'lowongan/perpanjang/{lid}', {'batas_lamaran': baru, 'kuota': '3'})
cek('perpanjang tersimpan', sql(f"select batas_lamaran||'/'||kuota from lowongan where id={lid}") == f'{baru}/3', flash(r))

print('=== E. Lamaran terisi otomatis + snapshot ===')
r = m.get(B + f'/lamaran/kirim/{lid}')
nama = sql("select nama_lengkap from mahasiswa m join pengguna p on p.id=m.pengguna_id where p.email='mahasiswa@polinema.ac.id'")
cek('formulir lamaran menampilkan data profil', nama in r.text)
r = post(m, f'lamaran/kirim/{lid}', f'lamaran/kirim/{lid}', {'jenis_cv': 'generate', 'catatan_pelamar': 'Siap.'})
cek('tanpa centang "data benar" ditolak', int(sql(f"select count(*) from lamaran where lowongan_id={lid}")) == 0, flash(r))
r = post(m, f'lamaran/kirim/{lid}', f'lamaran/kirim/{lid}', {'jenis_cv': 'generate', 'catatan_pelamar': 'Siap.', 'data_benar': '1'})
cek('lamaran terkirim', int(sql(f"select count(*) from lamaran where lowongan_id={lid}")) == 1, flash(r))
cek('snapshot profil tersimpan', nama in sql(f"select coalesce(snapshot_profil::text,'') from lamaran where lowongan_id={lid}"))
r = post(m, f'lowongan/detail/{lid}', f'lamaran/kirim/{lid}', {'jenis_cv': 'generate', 'data_benar': '1'})
cek('melamar dua kali ditolak', int(sql(f"select count(*) from lamaran where lowongan_id={lid}")) == 1)

print('=== F. Alamat terstruktur ===')
r = post(m, 'mahasiswa/pengaturan-akun', 'mahasiswa/simpan-pengaturan-akun', {'aksi': 'alamat', 'alamat': 'Jl. Soekarno Hatta 9', 'kota': 'Kota Malang', 'provinsi': 'Provinsi Ngawur', 'kode_pos': '65141'})
cek('provinsi di luar daftar ditolak', flash(r)[0] == 'bad', flash(r))
r = post(m, 'mahasiswa/pengaturan-akun', 'mahasiswa/simpan-pengaturan-akun', {'aksi': 'alamat', 'alamat': 'Jl. Soekarno Hatta 9', 'kota': 'Kota Malang', 'provinsi': 'Jawa Timur', 'kode_pos': '65141'})
cek('alamat lengkap tersimpan', sql("select provinsi||'/'||kode_pos from mahasiswa m join pengguna p on p.id=m.pengguna_id where p.email='mahasiswa@polinema.ac.id'") == 'Jawa Timur/65141', flash(r))

print('=== I. Rekap filter angkatan + tanggal ===')
hari = datetime.date.today().isoformat()
r = admin.get(B + f'/admin/rekap-lamaran?tanggal_dari={hari}&tanggal_sampai={hari}')
cek('lamaran hari ini ikut (tanggal akhir inklusif)', 'Uji Alur Revisi' in r.text)
r = admin.get(B + '/admin/unduh-rekap-lamaran?tanggal_dari=' + hari + '&tanggal_sampai=' + hari)
cek('PDF rekap memakai filter yang sama', r.status_code == 200 and ('Uji Alur Revisi' in r.text or r.headers.get('Content-Type', '').startswith('application/pdf')))

print('=== L. Reset sandi oleh admin ===')
uid = sql("select id from pengguna where email='mahasiswa@polinema.ac.id'")
r = post(admin, f'admin/profil-mahasiswa/{sql("select id from mahasiswa where pengguna_id=" + uid)}', f'admin/reset-sandi-pengguna/{uid}',
         {'cara': 'sementara', 'password_admin': 'salah123', 'password_sementara': 'Sementara123'})
cek('password admin salah -> ditolak', sql(f"select wajib_ganti_sandi from pengguna where id={uid}") == 'f', flash(r))
r = post(admin, f'admin/profil-mahasiswa/{sql("select id from mahasiswa where pengguna_id=" + uid)}', f'admin/reset-sandi-pengguna/{uid}',
         {'cara': 'sementara', 'password_admin': 'admin123', 'password_sementara': 'Sementara123'})
cek('reset sandi sementara tersimpan + wajib ganti', sql(f"select wajib_ganti_sandi from pengguna where id={uid}") == 't', flash(r))
r = m.get(B + '/mahasiswa/dashboard')
cek('sesi lama mahasiswa dicabut', '/masuk' in r.url, r.url)
r = s2.get(B + '/mahasiswa/dashboard')
cek('token Ingat saya ikut dicabut', '/masuk' in r.url, r.url)
m3, r = masuk('mahasiswa@polinema.ac.id', 'Sementara123')
cek('masuk dengan sandi sementara -> diarahkan ganti sandi', 'ganti-sandi-wajib' in r.url, r.url)
r = post(m3, 'akun/ganti-sandi-wajib', 'akun/simpan-sandi-wajib', {'password_lama': 'Sementara123', 'password_baru': 'mahasiswa123', 'konfirmasi_password': 'mahasiswa123'})
cek('setelah ganti sandi bisa ke dashboard', sql(f"select wajib_ganti_sandi from pengguna where id={uid}") == 'f' and 'ganti-sandi' not in r.url, (r.url, flash(r)))
cek('aktivitas admin tercatat', int(sql(f"select count(*) from log_aktivitas_admin where target_pengguna_id={uid}")) >= 1)

print('=== B. Status email jujur ===')
r = admin.get(B + '/admin/pengaturan#email')
cek('halaman pengaturan menampilkan status email', 'log_email' in r.text or 'Riwayat email' in r.text or 'SMTP' in r.text)
cek('kata sandi SMTP tidak bocor ke halaman', not re.search(r'name="smtp_pass[^"]*"[^>]*value="[^"]+"', r.text) and (not os.environ.get('SMTP_PASS') or os.environ['SMTP_PASS'] not in r.text))

print('=== J. Keluar hanya lewat POST ===')
r = admin.get(B + '/auth/keluar')
cek('GET keluar tidak langsung mengeluarkan', admin.get(B + '/admin/dashboard').url.endswith('/admin/dashboard'))
r = post(admin, 'admin/dashboard', 'auth/keluar', {})
cek('POST keluar mengeluarkan', '/masuk' in admin.get(B + '/admin/dashboard').url)

print()
print('TOTAL GAGAL:', len(GAGAL))
sys.exit(1 if GAGAL else 0)
