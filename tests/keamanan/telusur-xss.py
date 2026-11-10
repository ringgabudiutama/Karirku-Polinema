#!/usr/bin/env python3
import re, sys, json, html, requests, collections
import os
BASE=os.environ.get('BASE','http://127.0.0.1:8000')
AKUN = [('admin','admin@polinema.ac.id','admin123'),('mahasiswa','mahasiswa@polinema.ac.id','mahasiswa123'),
        ('perusahaan','perusahaan@polinema.ac.id','perusahaan123'),('ringga','ringga.perusahaan@karirku.id','ringga123'),('tamu',None,None)]
LEWATI = re.compile(r'(keluar|logout|unduh|ekspor|export|cetak|\.(css|js|png|jpe?g|gif|svg|ico|pdf|woff2?|map)(\?|$)|/auth/|akun/ganti|hapus|batalkan|tutup|perpanjang|setujui|tolak|ubah-status|terima|nonaktif|kirim-ulang)', re.I)
KANARI = re.compile(r'"><i data-x=(K[A-Z0-9]*?)_?(\d+)_(\d+)>|<i data-x=(K[A-Z0-9_]+)>', re.I)
RAW = re.compile(r'<i data-x=(K[A-Za-z0-9]*?)_(\d+)>')
ESC = re.compile(r'&lt;i data-x=(K[A-Za-z0-9]*?)_(\d+)&gt;')
def nomor(kode):  # K12 -> 12 ; KRIW -> 9001 ; KSNAP -> 9002 ; KPI -> 9003
    if kode.startswith('KRIW'): return 9001
    if kode.startswith('KSNAP'): return 9002
    if kode.startswith('KPI'): return 9003
    return int(kode[1:])
def masuk(email, pw):
    s = requests.Session(); s.headers['User-Agent']='telusur-xss'
    if not email: return s
    h = s.get(BASE+'/masuk', timeout=10).text; tok = re.search(r'name="csrf_token" value="([^"]+)"', h).group(1)
    r = s.post(BASE+'/auth/proses-masuk', data={'csrf_token':tok,'email':email,'password':pw}, timeout=15)
    if '/masuk' in r.url: raise SystemExit(f'login {email} gagal: {r.url}')
    return s
bocor = collections.defaultdict(set); terlihat_aman = collections.defaultdict(set); konteks_script = collections.defaultdict(set)
halaman_total = 0; per_peran = {}
for peran, email, pw in AKUN:
    s = masuk(email, pw); antre = collections.deque(['/', '/beranda', '/mahasiswa/dashboard', '/admin/dashboard', '/perusahaan/dashboard']); lihat=set(); n=0
    while antre and n < 650:
        p = antre.popleft()
        if p in lihat or LEWATI.search(p): continue
        lihat.add(p)
        try: r = s.get(BASE+p, timeout=15, allow_redirects=True)
        except Exception: continue
        if 'text/html' not in r.headers.get('Content-Type',''): continue
        n += 1; t = r.text
        # pisahkan script/komentar
        dalam_script = ' '.join(re.findall(r'<script\b.*?</script>', t, flags=re.S|re.I))
        luar = re.sub(r'<script\b.*?</script>|<!--.*?-->', '', t, flags=re.S|re.I)
        for kode, no in RAW.findall(luar): bocor[nomor(kode)].add((peran, p))
        for kode, no in RAW.findall(dalam_script): konteks_script[nomor(kode)].add((peran, p))
        for kode, no in ESC.findall(t): terlihat_aman[nomor(kode)].add(peran)
        for href in re.findall(r'href="([^"#]+)"', t):
            href = html.unescape(href)
            if href.startswith('/') and not href.startswith('//'): antre.append(href)
    per_peran[peran] = n; halaman_total += n
print('halaman ditelusuri per peran:', per_peran, '| total', halaman_total)
json.dump({'bocor': {k: sorted(v) for k, v in bocor.items()}, 'aman': {k: sorted(v) for k, v in terlihat_aman.items()},
           'script': {k: sorted(v) for k, v in konteks_script.items()}}, open(os.environ.get('HASIL','xss-hasil.json'),'w'))
