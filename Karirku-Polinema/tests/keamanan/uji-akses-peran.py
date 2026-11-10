#!/usr/bin/env python3
import re, glob, os, requests, collections
BASE=os.environ.get('BASE','http://127.0.0.1:8000'); D=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','app','controllers')
AKUN={'tamu':None,'mahasiswa':('mahasiswa@polinema.ac.id','mahasiswa123'),'perusahaan':('perusahaan@polinema.ac.id','perusahaan123'),'admin':('admin@polinema.ac.id','admin123')}
def kebab(n): return re.sub(r'(?<!^)(?=[A-Z])','-',n).lower()
rute=[]
for f in sorted(glob.glob(D+'/*Controller.php')):
    c=os.path.basename(f)[:-14]; s=open(f).read()
    for m in re.finditer(r'public function (\w+)\(([^)]*)\)',s):
        n,par=m.group(1),m.group(2).strip()
        if n.startswith('__'): continue
        if n in ('keluar',): continue
        rute.append((c,n,'/%s/%s%s'%(kebab(c),kebab(n),'/1' if par else '')))
def sesi(a):
    s=requests.Session(); s.headers['User-Agent']='uji-akses'
    if a:
        h=s.get(BASE+'/masuk',timeout=10).text; t=re.search(r'name="csrf_token" value="([^"]+)"',h).group(1)
        r=s.post(BASE+'/auth/proses-masuk',data={'csrf_token':t,'email':a[0],'password':a[1]},timeout=20); assert '/masuk' not in r.url,a
    return s
S={k:sesi(v) for k,v in AKUN.items()}
ulang=collections.Counter()
def token(s):
    for p in ('/mahasiswa/profil','/beranda','/masuk'):
        r=s.get(BASE+p,timeout=10,allow_redirects=True); m=re.search(r'name="csrf_token" value="([^"]+)"',r.text)
        if m: return m.group(1)
    return ''
def klas(r):
    if r.status_code==403: return '403'
    if r.status_code in (404,405): return str(r.status_code)
    if 300<=r.status_code<400:
        return '302>masuk' if '/masuk' in r.headers.get('Location','') else '302>'+r.headers.get('Location','').split('/')[-1][:14]
    return str(r.status_code)
def hidup(peran):
    if AKUN[peran] is None: return True
    r=S[peran].get(BASE+'/akun/ganti-sandi-wajib',timeout=10,allow_redirects=False)
    return '/masuk' not in r.headers.get('Location','')
hasil=collections.OrderedDict()
for c,n,u in rute:
    for mode in ('GET','POST'):
        row={}
        for peran,s in S.items():
            if mode=='POST' and peran=='admin': row[peran]='-'; continue
            if not hidup(peran): S[peran]=sesi(AKUN[peran]); ulang[peran]+=1
            try:
                if mode=='GET': r=s.get(BASE+u,timeout=15,allow_redirects=False)
                else: r=s.post(BASE+u,data={'csrf_token':token(s)},timeout=15,allow_redirects=False)
                row[peran]=klas(r)
            except Exception as e: row[peran]='ERR'
        hasil[(c,n,u,mode)]=row
# kebijakan: kontroler admin hanya admin; 'Perusahaan' & 'KirimLoker' dll ditandai bila tamu/mahasiswa lolos 200
print(f"{'METHOD':44s} {'mode':4s} {'tamu':10s} {'mahasiswa':10s} {'perusahaan':10s} {'admin':10s}")
anom=[]
for (c,n,u,mode),row in hasil.items():
    print(f"{u:44s} {mode:4s} {row['tamu']:10s} {row['mahasiswa']:10s} {row['perusahaan']:10s} {row['admin']:10s}")
print('sesi yang harus dibuat ulang selama uji:',dict(ulang))
open(os.environ.get('HASIL','akses-matriks.txt'),'w').write('\n'.join(f"{u}|{mode}|{r['tamu']}|{r['mahasiswa']}|{r['perusahaan']}|{r['admin']}" for (c,n,u,mode),r in hasil.items()))
