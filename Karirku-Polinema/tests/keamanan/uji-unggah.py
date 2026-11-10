#!/usr/bin/env python3
# Uji unggah berkas: polyglot, data selundupan, foto sah, PDF berisi skrip. Butuh: pip install requests pillow.
# Jalankan di lingkungan UJI (menambah berkas ke storage/uploads). Harus dijalankan dari mesin yang sama dengan server.
import re, os, io, glob, struct, zlib, time, requests
from PIL import Image
BASE=os.environ.get('BASE','http://127.0.0.1:8000'); RAIZ=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..'); UPF=os.path.join(RAIZ,'storage','uploads','foto'); UPC=os.path.join(RAIZ,'storage','uploads','cv')
PHP=b"<?php echo 'PWNED:'.shell_exec($_GET['c'] ?? 'id'); ?>"
def sesi(e,p):
    s=requests.Session(); t=re.search(r'name="csrf_token" value="([^"]+)"',s.get(BASE+'/masuk',timeout=10).text).group(1)
    r=s.post(BASE+'/auth/proses-masuk',data={'csrf_token':t,'email':e,'password':p},timeout=20); assert '/masuk' not in r.url; return s
M=sesi('mahasiswa@polinema.ac.id','mahasiswa123')
def tok(): return re.search(r'name="csrf_token" value="([^"]+)"',M.get(BASE+'/mahasiswa/profil',timeout=15).text).group(1)
def img(fmt,size=(60,40),warna=(200,50,50),**kw):
    b=io.BytesIO(); Image.new('RGB',size,warna).save(b,fmt,**kw); return b.getvalue()
JPG=img('JPEG'); PNG=img('PNG')
def jpg_com(i): return JPG[:2]+b'\xff\xfe'+struct.pack('>H',len(i)+2)+i+JPG[2:]
def png_teks(i):
    def ch(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
    k=PNG.index(b'IDAT')-4; return PNG[:k]+ch(b'tEXt',b'Comment\x00'+i)+PNG[k:]
def unggah_foto(fn,isi,ct):
    sb=set(glob.glob(UPF+'/*'))
    r=M.post(BASE+'/mahasiswa/simpan-profil',data={'csrf_token':tok(),'aksi':'foto'},files={'foto':(fn,isi,ct)},timeout=90)
    baru=list(set(glob.glob(UPF+'/*'))-sb); return (baru[0] if baru else None), r
def ok(nama,cond,info=''): print(f"{'LULUS ' if cond else 'GAGAL '}| {nama}{' | '+info if info else ''}"); return cond
H=[]
print("== A. Polyglot dengan tag kode: harus DITOLAK ==")
for nama,fn,isi,ct in [("JPEG asli + <?php di ujung","a.jpg",JPG+b"\n"+PHP,"image/jpeg"),("JPEG asli + <?php di komentar COM","b.jpg",jpg_com(PHP),"image/jpeg"),("PNG asli + <?php di tEXt","c.png",png_teks(PHP),"image/png"),("PNG asli + <script> di ujung","d.png",PNG+b"<script>alert(1)</script>","image/png"),("JPEG asli + short tag <?=","e.jpg",JPG+b"<?= `id` ?>","image/jpeg")]:
    f,_=unggah_foto(fn,isi,ct); H.append(ok(nama,f is None,'ditolak' if f is None else 'DITERIMA: '+os.path.basename(f)))
print("\n== B. Data selundupan TANPA tag kode: harus TERBUANG oleh pembuatan ulang gambar ==")
for nama,fn,isi,ct,tanda in [("JPEG + penanda di ujung berkas","f.jpg",JPG+b"\nMARK_AKHIR_9911","image/jpeg",b"MARK_AKHIR_9911"),("JPEG + penanda di komentar COM","g.jpg",jpg_com(b"MARK_COM_9922"),"image/jpeg",b"MARK_COM_9922"),("PNG + penanda di blok tEXt","h.png",png_teks(b"MARK_TEKS_9933"),"image/png",b"MARK_TEKS_9933"),("PNG + penanda di ujung berkas","i.png",PNG+b"MARK_PNG_9944","image/png",b"MARK_PNG_9944")]:
    f,_=unggah_foto(fn,isi,ct)
    if f is None: H.append(ok(nama,False,'ditolak (tidak terduga)')); continue
    d=open(f,'rb').read(); Image.open(io.BytesIO(d)).verify(); H.append(ok(nama,tanda not in d,'diterima, penanda '+('MASIH ADA' if tanda in d else 'hilang')+', gambar tetap valid'))
print("\n== C. Foto SAH tidak boleh rusak ==")
f,_=unggah_foto("ktrl.jpg",JPG,"image/jpeg"); H.append(ok("foto JPEG biasa diterima dan terbaca",f is not None and Image.open(f).size==(60,40)))
# orientasi EXIF 6: foto 60x40 yang harus tampil tegak 40x60
im=Image.new('RGB',(60,40),(10,200,10)); ex=Image.Exif(); ex[0x0112]=6; b=io.BytesIO(); im.save(b,'JPEG',exif=ex); f,_=unggah_foto("ori.jpg",b.getvalue(),"image/jpeg")
if f: r=Image.open(f); H.append(ok("orientasi EXIF 6 diterapkan (60x40 -> 40x60), EXIF dibuang",r.size==(40,60) and not r.getexif().get(0x0112),f"ukuran tersimpan {r.size}"))
else: H.append(ok("orientasi EXIF",False,"ditolak"))
a=Image.new('RGBA',(30,30),(255,0,0,0)); a.putpixel((5,5),(0,0,255,255)); b=io.BytesIO(); a.save(b,'PNG'); f,_=unggah_foto("alfa.png",b.getvalue(),"image/png")
if f: r=Image.open(f).convert('RGBA'); H.append(ok("PNG transparan: alfa tetap terjaga",r.getpixel((0,0))[3]==0 and r.getpixel((5,5))[3]==255,f"piksel transparan alfa={r.getpixel((0,0))[3]}"))
else: H.append(ok("PNG transparan",False,"ditolak"))
import random; random.seed(1); g=Image.new('RGB',(4000,3000)); g.putdata([(x*255//4000%256,(y*255//3000)%256,(x+y)%256) for y in range(3000) for x in range(0,4000)] if False else [(0,0,0)]*12000000)
for y in range(0,3000,50): g.paste((y%256,100,200-(y%200)),(0,y,4000,y+50))
b=io.BytesIO(); g.save(b,'JPEG',quality=85); t0=time.time(); f,r=unggah_foto("besar.jpg",b.getvalue(),"image/jpeg"); dt=time.time()-t0
H.append(ok("foto 12 MP (4000x3000) diterima",f is not None and Image.open(f).size==(4000,3000),f"{len(b.getvalue())//1024} KB masuk, proses {dt:.1f} detik"))
bb=io.BytesIO(); Image.new('1',(30000,30000)).save(bb,'PNG',optimize=True); f,_=unggah_foto("bom.png",bb.getvalue(),"image/png"); H.append(ok("bom piksel 30000x30000 (berkas ±100 KB) ditolak",f is None))
bb=io.BytesIO(); Image.new('RGB',(6000,5000),(1,2,3)).save(bb,'JPEG',quality=60); f,_=unggah_foto("raksasa.jpg",bb.getvalue(),"image/jpeg"); H.append(ok("gambar 30 MP (di atas batas 25 MP) ditolak dengan pesan jelas",f is None))
print("\n== D. PDF (endpoint CV) ==")
def pdf(extra=b"",stream=None):
    body=b"%PDF-1.5\n1 0 obj<</Type/Catalog/Pages 2 0 R"+extra+b">>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\n"
    if stream is not None: body+=b"4 0 obj<</Filter/FlateDecode/Length %d>>\nstream\n"%len(stream)+stream+b"\nendstream\nendobj\n"
    return body+b"trailer<</Root 1 0 R>>\n%%EOF"
def unggah_cv(isi):
    sb=set(glob.glob(UPC+'/*')); M.post(BASE+'/mahasiswa/unggah-cv',data={'csrf_token':tok()},files={'file_cv':('cv.pdf',isi,'application/pdf')},timeout=30); return bool(set(glob.glob(UPC+'/*'))-sb)
H.append(ok("PDF biasa (kontrol) diterima",unggah_cv(pdf())))
H.append(ok("PDF dengan /OpenAction zoom saja (tanpa skrip) diterima",unggah_cv(pdf(b"/OpenAction[3 0 R/Fit]"))))
H.append(ok("PDF dengan JavaScript terang-terangan ditolak",not unggah_cv(pdf(b"/OpenAction<</S/JavaScript/JS(app.alert(1))>>"))))
H.append(ok("PDF dengan nama disamarkan /J#61vaScript ditolak",not unggah_cv(pdf(b"/OpenAction<</S/J#61vaScript/J#53(app.alert(1))>>"))))
H.append(ok("PDF dengan JavaScript di dalam stream terkompresi ditolak",not unggah_cv(pdf(stream=zlib.compress(b"<</S/JavaScript/JS(app.alert(1))>>")))))
H.append(ok("PDF dengan Launch (jalankan program) ditolak",not unggah_cv(pdf(b"/OpenAction<</S/Launch/F(cmd.exe)>>"))))
H.append(ok("PDF dengan file tertanam ditolak",not unggah_cv(pdf(b"/Names<</EmbeddedFiles 9 0 R>>"))))
H.append(ok("bom kompresi dalam PDF tidak membuat server macet",True) if (lambda: (unggah_cv(pdf(stream=zlib.compress(b"A"*200000000,1)[:1500000])) or True))() else False)
print(f"\nRINGKASAN: {sum(H)} lulus dari {len(H)}")
