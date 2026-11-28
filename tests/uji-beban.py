#!/usr/bin/env python3
"""
Uji kecepatan dan beban sederhana KarirKu.
  1. Waktu respons tiap halaman utama per peran (20 kali, ambil median & p95).
  2. Beban bersamaan: N pengguna membuka halaman acak berulang kali.
Pemakaian: python3 tests/uji-beban.py [URL_DASAR] [JUMLAH_PENGGUNA] [DETIK]
"""
import re, sys, time, random, statistics, threading
import requests

B = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:8000'
N = int(sys.argv[2]) if len(sys.argv) > 2 else 20
DETIK = int(sys.argv[3]) if len(sys.argv) > 3 else 30

AKUN = {
    'admin': ('admin@polinema.ac.id', 'admin123', ['admin/dashboard', 'admin/persetujuan', 'admin/persetujuan?hal=2',
              'admin/kelola-pengguna', 'admin/monitoring-lowongan', 'admin/rekap-lamaran', 'admin/tracer-karier',
              'admin/persetujuan-lowongan', 'admin/detail-pendaftar/150']),
    'mahasiswa': ('mahasiswa@polinema.ac.id', 'mahasiswa123', ['mahasiswa/dashboard', 'lowongan/daftar',
                  'lowongan/daftar?q=data', 'lowongan/detail/1', 'lamaran/lamaran-saya', 'mahasiswa/disimpan', 'mahasiswa/profil']),
    'perusahaan': ('perusahaan@polinema.ac.id', 'perusahaan123', ['perusahaan/dashboard', 'perusahaan/lowongan',
                   'perusahaan/pelamar']),
    'menunggu': ('calon.mahasiswa@student.polinema.ac.id', 'mahasiswa123', ['status-akun']),
    'tamu': (None, None, ['', 'lowongan/daftar', 'mitra/1', 'masuk', 'daftar']),
}

def masuk(email, sandi):
    s = requests.Session()
    if email:
        r = s.get(f'{B}/masuk')
        t = re.search(r'name="csrf_token" value="([^"]+)"', r.text).group(1)
        r = s.post(f'{B}/auth/proses-masuk', data={'csrf_token': t, 'email': email, 'password': sandi})
    return s

sesi = {k: masuk(v[0], v[1]) for k, v in AKUN.items()}

print('== 1. Waktu respons per halaman (20 kali) ==')
print(f'{"peran":<11}{"halaman":<34}{"kode":>5}{"median":>9}{"p95":>9}{"ukuran":>9}')
semua = []
for k, (_, _, hal) in AKUN.items():
    for h in hal:
        t = []
        for _ in range(20):
            a = time.perf_counter(); r = sesi[k].get(f'{B}/{h}', allow_redirects=False); t.append((time.perf_counter() - a) * 1000)
        t.sort(); semua += t
        tanda = '' if r.status_code == 200 else '  <-- periksa'
        print(f'{k:<11}{"/" + h:<34}{r.status_code:>5}{statistics.median(t):>7.0f}ms{t[int(len(t) * .95) - 1]:>7.0f}ms{len(r.content) / 1024:>7.0f}KB{tanda}')

print(f'\n== 2. Beban bersamaan: {N} pengguna selama {DETIK} detik ==')
hasil, galat = [], []
kunci = threading.Lock()
akhir = time.time() + DETIK
def pekerja(i):
    k = random.Random(i).choice([x for x in AKUN if x != 'menunggu'])
    s = masuk(AKUN[k][0], AKUN[k][1])
    rnd = random.Random(i * 7)
    while time.time() < akhir:
        h = rnd.choice(AKUN[k][2])
        a = time.perf_counter()
        try:
            r = s.get(f'{B}/{h}', timeout=30, allow_redirects=False)
            ms = (time.perf_counter() - a) * 1000
            with kunci:
                hasil.append(ms)
                if r.status_code >= 400 or 'Fatal error' in r.text or 'SQLSTATE' in r.text:
                    galat.append((h, r.status_code))
        except Exception as e:
            with kunci: galat.append((h, str(e)[:60]))
th = [threading.Thread(target=pekerja, args=(i,)) for i in range(N)]
mulai = time.time()
[t.start() for t in th]; [t.join() for t in th]
dur = time.time() - mulai
hasil.sort()
print(f'permintaan selesai : {len(hasil)} ({len(hasil) / dur:.1f} per detik)')
print(f'waktu respons      : median {statistics.median(hasil):.0f} ms, p95 {hasil[int(len(hasil) * .95)]:.0f} ms, terlama {hasil[-1]:.0f} ms')
print(f'galat / gagal      : {len(galat)}' + (f'  contoh: {galat[:3]}' if galat else ''))
