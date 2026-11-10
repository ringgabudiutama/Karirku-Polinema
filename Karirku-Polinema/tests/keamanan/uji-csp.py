#!/usr/bin/env python3
import re, html, collections, requests
from urllib.parse import urlparse
import os
BASE=os.environ.get('BASE','http://127.0.0.1:8000')
AKUN=[('admin','admin@polinema.ac.id','admin123'),('mahasiswa','mahasiswa@polinema.ac.id','mahasiswa123'),('perusahaan','perusahaan@polinema.ac.id','perusahaan123'),('ringga','ringga.perusahaan@karirku.id','ringga123'),('tamu',None,None)]
LEWATI=re.compile(r'(keluar|logout|unduh|ekspor|export|cetak|\.(css|js|png|jpe?g|gif|svg|ico|pdf|woff2?|map)(\?|$)|/auth/|akun/ganti|hapus|batalkan|tutup|perpanjang|setujui|tolak|ubah-status|terima|nonaktif|kirim-ulang)',re.I)
IZIN_HOST={'fonts.googleapis.com','fonts.gstatic.com','www.google.com','maps.google.com'}
def masuk(e,p):
    s=requests.Session()
    if e:
        t=re.search(r'name="csrf_token" value="([^"]+)"',s.get(BASE+'/masuk',timeout=10).text).group(1)
        r=s.post(BASE+'/auth/proses-masuk',data={'csrf_token':t,'email':e,'password':p},timeout=20); assert '/masuk' not in r.url
    return s
masalah=collections.defaultdict(set); n=0; header_sampel=None; hdr_kurang=collections.Counter()
for peran,e,p in AKUN:
    s=masuk(e,p); antre=collections.deque(['/','/beranda','/mahasiswa/dashboard','/admin/dashboard','/perusahaan/dashboard','/daftar','/masuk','/halaman-tidak-ada']); lihat=set(); k=0
    while antre and k<300:
        u=antre.popleft()
        if u in lihat or LEWATI.search(u): continue
        lihat.add(u)
        try: r=s.get(BASE+u,timeout=15)
        except Exception: continue
        if 'text/html' not in r.headers.get('Content-Type',''): continue
        k+=1; n+=1; t=r.text; h=r.headers
        csp=h.get('Content-Security-Policy','')
        m=re.search(r"'nonce-([^']+)'",csp); nonce=m.group(1) if m else None
        if header_sampel is None: header_sampel=dict(h)
        for nm in ('Content-Security-Policy','X-Frame-Options','X-Content-Type-Options','Referrer-Policy','Permissions-Policy','Cross-Origin-Opener-Policy'):
            if nm not in h: hdr_kurang[nm]+=1
        if 'X-Powered-By' in h: masalah['X-Powered-By bocor'].add(u)
        if "'unsafe-inline'" in re.search(r"script-src[^;]*",csp).group(0) if 'script-src' in csp else True: masalah["script-src mengizinkan unsafe-inline"].add(u)
        for tag in re.findall(r'<script\b[^>]*>',t,flags=re.I):
            if 'src=' in tag.lower() or 'application/json' in tag.lower(): continue
            nn=re.search(r'nonce="([^"]*)"',tag)
            if not nn: masalah['<script> inline TANPA nonce'].add(u)
            elif nn.group(1)!=nonce: masalah['nonce <script> tidak cocok dengan header'].add(u)
        if re.search(r'<[a-z][^>]*\son(?:click|change|submit|input|load|error|mouseover|focus|blur|key\w+)\s*=',t,flags=re.I): masalah['atribut event inline (on*=)'].add(u)
        if re.search(r'(?:href|src|action|formaction)\s*=\s*["\']\s*javascript:',t,flags=re.I): masalah['URL javascript:'].add(u)
        for attr,val in re.findall(r'(?:<link[^>]*href|<script[^>]*src|<img[^>]*src|<iframe[^>]*src|<form[^>]*action|<object[^>]*data|<embed[^>]*src)=["\']([^"\']+)',t,flags=re.I) and []: pass
        for val in re.findall(r'<(?:link|script|img|iframe|object|embed|source)\b[^>]*?(?:href|src|data)=["\'](https?://[^"\']+)',t,flags=re.I):
            host=urlparse(html.unescape(val)).hostname
            if host not in IZIN_HOST and host not in ('127.0.0.1','localhost'): masalah[f'sumber luar di luar daftar izin: {host}'].add(u)
        for fa in re.findall(r'<form\b[^>]*action=["\']([^"\']+)',t,flags=re.I):
            fa=html.unescape(fa)
            if fa.startswith('http') and urlparse(fa).hostname not in ('127.0.0.1','localhost'): masalah['form action ke situs luar'].add(u)
        for href in re.findall(r'href="([^"#]+)"',t):
            href=html.unescape(href)
            if href.startswith('/') and not href.startswith('//'): antre.append(href)
print(f"halaman HTML diperiksa: {n}")
print("header yang hilang di sebagian halaman:", dict(hdr_kurang) or "tidak ada")
print("\nHeader contoh:"); 
for nm in ('Content-Security-Policy','Strict-Transport-Security','Cross-Origin-Opener-Policy','X-Frame-Options','X-Content-Type-Options','Referrer-Policy','Permissions-Policy','X-Powered-By','Server'):
    print(f"  {nm:28s} {str((header_sampel or {}).get(nm,'(tidak ada)'))[:150]}")
print("\nPELANGGARAN:", "tidak ada" if not masalah else "")
for k,v in masalah.items(): print(f"  - {k}: {len(v)} halaman, contoh {sorted(v)[:2]}")
