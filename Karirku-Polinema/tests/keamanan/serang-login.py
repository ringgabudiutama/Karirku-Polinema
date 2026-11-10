#!/usr/bin/env python3
import re, sys, requests
from requests.adapters import HTTPAdapter
from urllib3.poolmanager import PoolManager
import os
BASE=os.environ.get('BASE','http://127.0.0.1:8000'); BENAR='RahasiaBenar#1'
class DariIP(HTTPAdapter):
    def __init__(self, ip, **kw): self.ip=ip; super().__init__(**kw)
    def init_poolmanager(self, *a, **kw): kw['source_address']=(self.ip,0); self.poolmanager=PoolManager(*a, **kw)
def sesi(ip):
    s=requests.Session(); s.mount('http://', DariIP(ip)); return s
def coba(s, email, pw):
    h=s.get(BASE+'/masuk',timeout=10).text; tok=re.search(r'name="csrf_token" value="([^"]+)"',h).group(1)
    r=s.post(BASE+'/auth/proses-masuk',data={'csrf_token':tok,'email':email,'password':pw},timeout=10)
    t=re.sub(r'<[^>]+>',' ',r.text)
    if 'Terlalu banyak percobaan' in t: return 'TERKUNCI'
    if 'Email atau kata sandi salah' in t: return 'salah'
    return 'MASUK' if '/masuk' not in r.url else '?'
def pertama_terkunci(hasil): return next((i+1 for i,h in enumerate(hasil) if h=='TERKUNCI'),None)

print("1) Penebak: 40 tebakan, SESI BARU tiap percobaan, satu IP (127.0.0.1)")
h=[coba(sesi('127.0.0.1'),'korban2@uji.test',f'tebakan{i}') for i in range(40)]
print("   terkunci mulai tebakan ke-%s | dari IP yang sama, password BENAR -> %s"%(pertama_terkunci(h), coba(sesi('127.0.0.1'),'korban2@uji.test',BENAR)))
print("2) Pemilik akun asli dari IP LAIN (127.0.0.2), password benar -> %s"%coba(sesi('127.0.0.2'),'korban2@uji.test',BENAR))
print("3) Penyerang terdistribusi: 30 tebakan dari 30 IP berbeda ke akun korban3")
h=[coba(sesi(f'127.0.0.{20+i}'),'korban3@uji.test',f'tebakan{i}') for i in range(30)]
print("   terkunci mulai tebakan ke-%s (batas akun = 20)"%pertama_terkunci(h))
print("   pemilik asli (127.0.0.2) saat akun dikunci -> %s   (dampak sampingan: akun yang diserang ikut terkunci 15 menit)"%coba(sesi('127.0.0.2'),'korban3@uji.test',BENAR))
