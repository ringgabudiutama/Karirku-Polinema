#!/usr/bin/env python3
"""
Membuat DATA DUMMY lowongan yang banyak + gambar pamflet & logo.

Hasil:
  storage/uploads/pamflet/dummy-*.jpg   pamflet unik per lowongan (ilustrasi sesuai bidang)
  storage/uploads/logo/dummy-emblem-*.png logo emblem orisinal per perusahaan (bukan logo merek asli)
  storage/uploads/foto/dummy-foto-*.png  foto profil ilustrasi untuk setiap mahasiswa dummy
  database/05-data-dummy.sql            SQL yang aman dijalankan berulang

Jalankan ulang skrip ini hanya bila ingin membuat ulang data dummy:
  python3 tests/buat-data-dummy.py
"""
import hashlib, json, math, os, random, datetime
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
UP = os.path.join(ROOT, 'storage', 'uploads')
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
FONTB = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
rnd = random.Random(20261028)

def f(size, bold=False):
    return ImageFont.truetype(FONTB if bold else FONT, size)

# ---------------------------------------------------------------- data ----
PERUSAHAAN = [  # nama, bidang utama, kota
    ('PT Nusantara Digital', 'Teknologi Informasi', 'Malang'),
    ('PT Astra Otoparts', 'Manufaktur', 'Jakarta'),
    ('PT Telkom Indonesia', 'Teknologi Informasi', 'Bandung'),
    ('PT Wilmar Nabati Indonesia', 'Kimia', 'Gresik'),
    ('PT Gudang Garam Tbk', 'Manufaktur', 'Kediri'),
    ('PT Pindad', 'Manufaktur', 'Bandung'),
    ('PT Semen Indonesia', 'Konstruksi', 'Gresik'),
    ('PT Bank Mandiri Tbk', 'Keuangan', 'Jakarta'),
    ('PT Pertamina Patra Niaga', 'Kimia', 'Jakarta'),
    ('PT Nestle Indonesia', 'Manufaktur', 'Pasuruan'),
    ('PT Barata Indonesia', 'Manufaktur', 'Gresik'),
    ('PT Nusantara Teknologi Cerdas', 'Teknologi Informasi', 'Malang'),
    ('PT Adhi Karya Tbk', 'Konstruksi', 'Jakarta'),
    ('PT Sinergi Data Nusantara', 'Teknologi Informasi', 'Malang'),
    ('PT Mitra Arsip Nusantara', 'Perdagangan dan Jasa', 'Surabaya'),
    ('PT Energi Listrik Mandiri', 'Kelistrikan', 'Sidoarjo'),
    ('PT Mitra Sejahtera Abadi', 'Perdagangan dan Jasa', 'Malang'),
    ('PT Karya Abadi Teknik', 'Manufaktur', 'Sidoarjo'),
]
TERKAIT = {  # bidang tambahan yang wajar untuk tiap bidang utama
    'Teknologi Informasi': ['Teknologi Informasi', 'Teknologi Informasi', 'Perdagangan dan Jasa'],
    'Manufaktur': ['Manufaktur', 'Manufaktur', 'Kelistrikan', 'Keuangan'],
    'Kimia': ['Kimia', 'Kimia', 'Manufaktur', 'Kelistrikan'],
    'Konstruksi': ['Konstruksi', 'Konstruksi', 'Kelistrikan', 'Keuangan'],
    'Keuangan': ['Keuangan', 'Keuangan', 'Teknologi Informasi', 'Perdagangan dan Jasa'],
    'Perdagangan dan Jasa': ['Perdagangan dan Jasa', 'Keuangan', 'Teknologi Informasi'],
    'Kelistrikan': ['Kelistrikan', 'Kelistrikan', 'Manufaktur', 'Konstruksi'],
}
JURUSAN = {
    'Teknologi Informasi': ['Teknologi Informasi', 'Teknik Elektro'],
    'Manufaktur': ['Teknik Mesin', 'Teknik Elektro'],
    'Kimia': ['Teknik Kimia'],
    'Konstruksi': ['Teknik Sipil'],
    'Keuangan': ['Akuntansi', 'Administrasi Niaga'],
    'Perdagangan dan Jasa': ['Administrasi Niaga', 'Akuntansi'],
    'Kelistrikan': ['Teknik Elektro', 'Teknik Mesin'],
}
POSISI = {
    'Teknologi Informasi': [
        ('Junior Web Developer', 'PHP, Laravel, JavaScript, PostgreSQL', 'Membangun dan memelihara aplikasi web internal maupun klien, bekerja dalam tim agile bersama desainer dan QA.'),
        ('Mobile Developer (Flutter)', 'Flutter, Dart, REST API, Git', 'Mengembangkan aplikasi Android/iOS dari desain hingga rilis ke Play Store dan App Store.'),
        ('UI/UX Designer', 'Figma, UI/UX Design, Prototyping', 'Merancang alur pengguna, wireframe, dan prototipe yang mudah dipakai untuk produk digital perusahaan.'),
        ('Quality Assurance Engineer', 'Testing manual, Postman, Selenium', 'Menyusun skenario uji, menjalankan pengujian fungsional dan regresi, serta mendokumentasikan bug.'),
        ('Data Analyst', 'Python, SQL, Microsoft Excel, Power BI', 'Mengolah data operasional menjadi dashboard dan laporan yang membantu pengambilan keputusan.'),
        ('Network Engineer', 'Mikrotik, Cisco, Jaringan komputer', 'Memasang, memantau, dan merawat jaringan kantor dan pusat data, termasuk penanganan gangguan.'),
        ('IT Support', 'Troubleshooting, Windows, Jaringan dasar', 'Membantu pengguna internal menangani masalah perangkat keras, perangkat lunak, dan jaringan.'),
        ('Backend Developer', 'Node.js, PHP, PostgreSQL, Docker', 'Merancang API dan basis data yang andal, aman, dan siap menangani banyak pengguna.'),
        ('Frontend Developer', 'HTML, CSS, JavaScript, React', 'Mengubah desain menjadi antarmuka web yang cepat, responsif, dan mudah diakses.'),
        ('DevOps Engineer', 'Linux, Docker, CI/CD, Git', 'Mengotomatiskan proses build dan deploy serta menjaga server tetap stabil.'),
    ],
    'Manufaktur': [
        ('Operator CNC', 'CNC, Membaca gambar teknik, K3', 'Mengoperasikan mesin CNC sesuai gambar kerja dan standar mutu produksi.'),
        ('Staf Quality Control', 'Alat ukur, ISO 9001, Microsoft Excel', 'Memeriksa mutu bahan dan produk jadi, mencatat temuan, dan mengusulkan perbaikan.'),
        ('Teknisi Maintenance Mesin', 'Mekanik, Pneumatik, Hidrolik', 'Melakukan perawatan preventif dan perbaikan mesin produksi agar tidak berhenti.'),
        ('Drafter Mekanik', 'AutoCAD, SolidWorks', 'Membuat gambar teknik 2D/3D komponen dan perakitan sesuai kebutuhan produksi.'),
        ('Production Planning Staff', 'PPIC, Microsoft Excel, ERP', 'Menyusun jadwal produksi dan memastikan bahan tersedia tepat waktu.'),
        ('Supervisor Produksi', 'Kepemimpinan, Lean manufacturing, K3', 'Memimpin tim lini produksi agar target kuantitas, mutu, dan keselamatan tercapai.'),
        ('Staf K3', 'K3, ISO 45001, Investigasi kecelakaan', 'Mengawasi penerapan keselamatan dan kesehatan kerja di area pabrik.'),
        ('Welder (Juru Las)', 'Las SMAW, Las GTAW, Membaca gambar', 'Melakukan pengelasan konstruksi dan komponen sesuai prosedur WPS.'),
    ],
    'Kimia': [
        ('Analis Laboratorium', 'Analisis kimia, Titrasi, Spektrofotometri', 'Melakukan analisis bahan baku dan produk di laboratorium sesuai metode standar.'),
        ('Process Engineer', 'Neraca massa, Proses kimia, Microsoft Excel', 'Memantau dan mengoptimalkan proses produksi agar efisien dan sesuai spesifikasi.'),
        ('Operator Proses Produksi', 'Operasi unit proses, K3', 'Menjalankan peralatan proses dan mencatat parameter operasi setiap shift.'),
        ('Staf Pengelolaan Limbah (HSE)', 'IPAL, ISO 14001, K3', 'Mengelola limbah dan memastikan pabrik memenuhi baku mutu lingkungan.'),
        ('Quality Assurance Kimia', 'GMP, ISO 9001, Dokumentasi mutu', 'Menjaga sistem mutu, audit internal, dan dokumentasi produk.'),
    ],
    'Konstruksi': [
        ('Drafter Sipil', 'AutoCAD, Revit, Gambar kerja', 'Menyiapkan gambar kerja struktur dan arsitektur untuk proyek gedung dan jalan.'),
        ('Quantity Surveyor', 'RAB, Microsoft Excel, AutoCAD', 'Menghitung volume pekerjaan dan menyusun rencana anggaran biaya proyek.'),
        ('Site Engineer', 'Manajemen proyek, K3 konstruksi', 'Mengawasi pelaksanaan pekerjaan di lapangan agar sesuai gambar, jadwal, dan mutu.'),
        ('Surveyor Pengukuran', 'Total station, GPS geodetik, AutoCAD', 'Melakukan pengukuran topografi dan stake out di lokasi proyek.'),
        ('Staf Pengendalian Mutu Beton', 'Uji beton, Mix design', 'Menguji material dan beton di lapangan dan laboratorium proyek.'),
        ('Estimator Proyek', 'RAB, Analisa harga satuan', 'Menyusun penawaran harga untuk tender proyek konstruksi.'),
    ],
    'Keuangan': [
        ('Staf Akuntansi', 'Akuntansi keuangan, Microsoft Excel, Accurate', 'Mencatat transaksi, menyusun jurnal, dan membantu laporan keuangan bulanan.'),
        ('Staf Pajak', 'PPh, PPN, e-Faktur', 'Menghitung, melaporkan, dan mengarsipkan kewajiban pajak perusahaan.'),
        ('Customer Service Officer', 'Komunikasi, Pelayanan nasabah', 'Melayani nasabah di kantor cabang secara ramah, cepat, dan tepat.'),
        ('Teller', 'Ketelitian, Pelayanan nasabah', 'Melayani transaksi tunai dan nontunai nasabah sesuai prosedur.'),
        ('Staf Audit Internal', 'Audit, Microsoft Excel, Analisis risiko', 'Memeriksa kepatuhan proses dan pengendalian internal di setiap unit.'),
        ('Account Officer UMKM', 'Analisis kredit, Komunikasi', 'Menganalisis pengajuan kredit usaha mikro dan kecil serta membina debitur.'),
    ],
    'Perdagangan dan Jasa': [
        ('Staf Administrasi', 'Microsoft Office, Kearsipan', 'Mengelola surat-menyurat, arsip, dan administrasi operasional kantor.'),
        ('Digital Marketing Specialist', 'Media sosial, SEO, Canva', 'Merencanakan konten dan kampanye digital untuk menaikkan penjualan.'),
        ('Sales Executive', 'Negosiasi, Komunikasi, Presentasi', 'Mencari pelanggan baru dan menjaga hubungan baik dengan pelanggan lama.'),
        ('Staf Gudang dan Logistik', 'Inventori, Microsoft Excel', 'Mengatur penerimaan, penyimpanan, dan pengiriman barang.'),
        ('Customer Relationship Staff', 'Komunikasi, CRM', 'Menangani pertanyaan dan keluhan pelanggan lewat telepon, email, dan chat.'),
        ('Staf Rekam Arsip Digital', 'Pengarsipan digital, Ketelitian', 'Memindai dan mengindeks dokumen klien ke sistem arsip digital.'),
    ],
    'Kelistrikan': [
        ('Teknisi Listrik', 'Instalasi listrik, PLC, K3 listrik', 'Memasang dan merawat instalasi listrik gedung dan panel distribusi.'),
        ('Teknisi Panel Surya', 'PLTS, Inverter, K3', 'Memasang dan merawat sistem pembangkit listrik tenaga surya atap.'),
        ('Engineer Proteksi Sistem Tenaga', 'Relay proteksi, ETAP', 'Menganalisis dan menyetel sistem proteksi gardu dan jaringan distribusi.'),
        ('Teknisi Instrumentasi', 'PLC, SCADA, Kalibrasi', 'Merawat dan mengkalibrasi instrumen kontrol di area produksi.'),
        ('Drafter Elektrikal', 'AutoCAD Electrical, Single line diagram', 'Membuat gambar instalasi listrik dan diagram satu garis proyek.'),
    ],
}
KUALIF_UMUM = ['Lulusan D3/D4 Politeknik Negeri Malang', 'Fresh graduate dipersilakan melamar', 'Mampu bekerja dalam tim', 'Komunikatif dan teliti',
               'Bersedia bekerja shift', 'Memiliki laptop pribadi', 'IPK minimal 3,00', 'Berpengalaman magang di bidang terkait (nilai tambah)']
WARNA = {
    'Teknologi Informasi': ((22, 72, 168), (12, 38, 96)),
    'Manufaktur': ((178, 34, 34), (96, 18, 18)),
    'Kimia': ((109, 40, 152), (58, 20, 86)),
    'Konstruksi': ((196, 112, 18), (110, 58, 6)),
    'Keuangan': ((20, 108, 92), (8, 58, 50)),
    'Perdagangan dan Jasa': ((30, 112, 176), (12, 60, 104)),
    'Kelistrikan': ((222, 160, 20), (122, 76, 6)),
}
JENIS_LABEL = {'full_time': 'Penuh waktu', 'kontrak': 'Kontrak', 'magang': 'Magang', 'part_time': 'Paruh waktu'}
SISTEM_LABEL = {'wfo': 'WFO', 'hybrid': 'Hybrid', 'wfh': 'WFH'}

# ---------------------------------------------------------- ilustrasi ----
def ilustrasi(d, box, bidang, aksen):
    """Gambar ilustrasi sederhana bertema bidang di dalam kotak (x0,y0,x1,y1)."""
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    putih = (255, 255, 255)
    pudar = (255, 255, 255, 60)
    if bidang == 'Teknologi Informasi':
        d.rounded_rectangle((cx - 170, cy - 105, cx + 170, cy + 95), 14, fill=(255, 255, 255), outline=aksen, width=6)
        d.rectangle((cx - 150, cy - 85, cx + 150, cy + 75), fill=(18, 28, 52))
        for i, w in enumerate([180, 120, 220, 90, 160, 140]):
            col = [(97, 218, 251), (255, 200, 87), (152, 230, 140), (255, 140, 160)][i % 4]
            d.rounded_rectangle((cx - 130 + (i % 3) * 18, cy - 70 + i * 22, cx - 130 + (i % 3) * 18 + w, cy - 58 + i * 22), 5, fill=col)
        d.polygon([(cx - 210, cy + 95), (cx + 210, cy + 95), (cx + 240, cy + 120), (cx - 240, cy + 120)], fill=putih)
    elif bidang == 'Manufaktur':
        def roda(gx, gy, r, n):
            pts = []
            for k in range(n * 2):
                a = math.pi * k / n
                rr = r if k % 2 == 0 else r * 0.8
                pts.append((gx + rr * math.cos(a), gy + rr * math.sin(a)))
            d.polygon(pts, fill=putih)
            d.ellipse((gx - r * 0.35, gy - r * 0.35, gx + r * 0.35, gy + r * 0.35), fill=aksen)
        roda(cx - 70, cy - 10, 105, 12)
        roda(cx + 105, cy + 55, 70, 10)
        roda(cx + 120, cy - 85, 48, 8)
    elif bidang == 'Kimia':
        d.polygon([(cx - 40, cy - 120), (cx + 40, cy - 120), (cx + 40, cy - 40), (cx + 120, cy + 110), (cx - 120, cy + 110), (cx - 40, cy - 40)], fill=putih)
        d.polygon([(cx - 70, cy + 20), (cx + 70, cy + 20), (cx + 110, cy + 100), (cx - 110, cy + 100)], fill=(120, 220, 200))
        d.rectangle((cx - 52, cy - 135, cx + 52, cy - 118), fill=putih)
        for bx, by, br in [(cx - 30, cy + 55, 12), (cx + 20, cy + 40, 9), (cx + 45, cy + 75, 7), (cx - 10, cy - 5, 8)]:
            d.ellipse((bx - br, by - br, bx + br, by + br), outline=aksen, width=4)
        d.ellipse((cx + 130, cy - 120, cx + 190, cy - 60), outline=putih, width=6)
        d.ellipse((cx - 190, cy - 90, cx - 145, cy - 45), outline=putih, width=6)
    elif bidang == 'Konstruksi':
        d.rectangle((cx - 150, cy - 130, cx - 135, cy + 120), fill=putih)
        d.rectangle((cx - 150, cy - 130, cx + 170, cy - 115), fill=putih)
        for k in range(8):
            d.line((cx - 135 + k * 38, cy - 115, cx - 116 + k * 38, cy - 130), fill=aksen, width=4)
        d.line((cx + 120, cy - 115, cx + 120, cy - 40), fill=putih, width=4)
        d.rectangle((cx + 100, cy - 40, cx + 140, cy - 20), fill=putih)
        for lv in range(4):
            d.rectangle((cx - 60, cy + 80 - lv * 45, cx + 90, cy + 118 - lv * 45), outline=putih, width=5)
            for c in range(3):
                d.rectangle((cx - 45 + c * 48, cy + 90 - lv * 45, cx - 20 + c * 48, cy + 108 - lv * 45), fill=putih)
    elif bidang == 'Keuangan':
        tinggi = [70, 110, 90, 150, 190]
        for k, t in enumerate(tinggi):
            d.rounded_rectangle((cx - 170 + k * 62, cy + 110 - t, cx - 125 + k * 62, cy + 110), 6, fill=putih)
        d.line([(cx - 160, cy + 20), (cx - 90, cy - 20), (cx - 30, cy + 0), (cx + 40, cy - 60), (cx + 120, cy - 110)], fill=(255, 214, 90), width=10)
        d.polygon([(cx + 120, cy - 135), (cx + 150, cy - 100), (cx + 105, cy - 95)], fill=(255, 214, 90))
        for k in range(3):
            d.ellipse((cx + 110 + k * 8, cy + 40 - k * 22, cx + 190 + k * 8, cy + 70 - k * 22), fill=(255, 214, 90), outline=aksen, width=3)
    elif bidang == 'Perdagangan dan Jasa':
        d.polygon([(cx - 170, cy - 40), (cx + 170, cy - 40), (cx + 140, cy - 110), (cx - 140, cy - 110)], fill=putih)
        for k in range(6):
            d.pieslice((cx - 170 + k * 57, cy - 75, cx - 113 + k * 57, cy - 5), 0, 180, fill=putih if k % 2 else (255, 214, 90))
        d.rectangle((cx - 150, cy - 40, cx + 150, cy + 115), outline=putih, width=6)
        d.rectangle((cx - 40, cy + 20, cx + 40, cy + 115), fill=putih)
        for bx in (cx - 125, cx + 65):
            d.rectangle((bx, cy + 0, bx + 60, cy + 55), fill=putih)
    else:  # Kelistrikan
        d.polygon([(cx + 30, cy - 140), (cx - 90, cy + 20), (cx - 5, cy + 20), (cx - 40, cy + 140), (cx + 100, cy - 30), (cx + 15, cy - 30)], fill=(255, 230, 120))
        for k in range(-1, 2):
            d.line((cx + k * 150, cy - 120, cx + k * 150, cy + 130), fill=putih, width=5)
            d.line((cx + k * 150 - 40, cy - 100, cx + k * 150 + 40, cy - 100), fill=putih, width=5)
        d.arc((cx - 150, cy - 160, cx + 150, cy - 40), 20, 160, fill=putih, width=3)

def tulis_bungkus(d, teks, font, lebar_maks, x, y, fill, jarak=8, maks_baris=3):
    kata, baris, cur = teks.split(), [], ''
    for k in kata:
        uji = (cur + ' ' + k).strip()
        if d.textlength(uji, font=font) <= lebar_maks:
            cur = uji
        else:
            baris.append(cur); cur = k
    baris.append(cur)
    for b in baris[:maks_baris]:
        d.text((x, y), b, font=font, fill=fill)
        y += font.size + jarak
    return y

def inisial(nama):
    kata = [k for k in nama.replace('PT ', '').replace('Tbk', '').split() if k[0].isalpha()]
    return (kata[0][0] + (kata[1][0] if len(kata) > 1 else '')).upper()

def buat_logo(nama, bidang, path, urut=0):
    """Logo emblem ORISINAL (bukan tiruan logo merek asli): kombinasi bentuk & warna unik per perusahaan."""
    idx = urut
    palet = [((22, 72, 168), (64, 160, 255)), ((178, 34, 34), (255, 120, 80)), ((109, 40, 152), (210, 120, 255)),
             ((196, 112, 18), (255, 200, 60)), ((20, 108, 92), (60, 210, 160)), ((30, 112, 176), (90, 210, 230)),
             ((222, 160, 20), (255, 230, 110)), ((40, 48, 72), (110, 130, 180)), ((0, 128, 128), (120, 220, 200))]
    w1, w2 = palet[(idx * 5) % len(palet)]
    S = 512
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    bg = Image.new('RGBA', (S, S))
    db = ImageDraw.Draw(bg)
    for y in range(S):
        t = y / S
        db.line((0, y, S, y), fill=tuple(int(w1[i] * (1 - t) + w2[i] * t) for i in range(3)) + (255,))
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((16, 16, S - 16, S - 16), 110, fill=255)
    im.paste(bg, (0, 0), mask)
    d = ImageDraw.Draw(im)
    W = (255, 255, 255, 255)
    W2 = (255, 255, 255, 150)
    c = S // 2
    bentuk = idx % 12
    if bentuk == 0:      # tiga chevron
        for k in range(3):
            y = 150 + k * 80
            d.line([(140, y), (c, y + 80), (S - 140, y)], fill=W if k != 1 else W2, width=44, joint='curve')
    elif bentuk == 1:    # heksagon berlubang
        pts = [(c + 170 * math.cos(math.pi / 3 * k + math.pi / 6), c + 170 * math.sin(math.pi / 3 * k + math.pi / 6)) for k in range(6)]
        d.polygon(pts, fill=W)
        pts2 = [(c + 80 * math.cos(math.pi / 3 * k + math.pi / 6), c + 80 * math.sin(math.pi / 3 * k + math.pi / 6)) for k in range(6)]
        d.polygon(pts2, fill=w1 + (255,))
    elif bentuk == 2:    # planet bercincin
        d.ellipse((c - 95, c - 95, c + 95, c + 95), fill=W)
        d.ellipse((70, c - 50, S - 70, c + 50), outline=W2, width=22)
        d.ellipse((c - 95, c - 95, c + 95, c + 95), outline=w1 + (255,), width=10)
    elif bentuk == 3:    # daun
        pts = []
        for k in range(0, 181, 6):
            t = math.radians(k)
            pts.append((c + 170 * math.cos(t) * 1.0 - 0, c - 120 * math.sin(t)))
        for k in range(180, 361, 6):
            t = math.radians(k)
            pts.append((c + 170 * math.cos(t), c - 120 * math.sin(t) * 0.0 + 0))
        daun = [(c + (x - c) * 0.8 - (y - c) * 0.6, c + (x - c) * 0.6 + (y - c) * 0.8) for x, y in pts]
        d.polygon(daun, fill=W)
        d.line([(c - 105, c + 80), (c + 105, c - 80)], fill=w1 + (255,), width=12)
    elif bentuk == 4:    # gunung
        d.polygon([(90, 380), (220, 160), (330, 330), (380, 260), (S - 90, 380)], fill=W)
        d.polygon([(220, 160), (255, 220), (185, 220)], fill=w2 + (255,))
    elif bentuk == 5:    # gelombang
        for k in range(3):
            pts = [(x, 200 + k * 70 + 30 * math.sin((x - 90) / 50)) for x in range(90, S - 89, 6)]
            d.line(pts, fill=W if k != 1 else W2, width=34, joint='curve')
    elif bentuk == 6:    # bintang segi delapan
        pts = []
        for k in range(16):
            r = 180 if k % 2 == 0 else 95
            a = math.pi / 8 * k
            pts.append((c + r * math.cos(a), c + r * math.sin(a)))
        d.polygon(pts, fill=W)
        d.ellipse((c - 45, c - 45, c + 45, c + 45), fill=w1 + (255,))
    elif bentuk == 7:    # roda gigi
        pts = []
        for k in range(24):
            r = 180 if k % 2 == 0 else 145
            pts.append((c + r * math.cos(math.pi / 12 * k), c + r * math.sin(math.pi / 12 * k)))
        d.polygon(pts, fill=W)
        d.ellipse((c - 70, c - 70, c + 70, c + 70), fill=w1 + (255,))
    elif bentuk == 8:    # petir dalam lingkaran
        d.ellipse((96, 96, S - 96, S - 96), outline=W, width=26)
        d.polygon([(285, 140), (190, 280), (255, 280), (225, 380), (330, 225), (265, 225)], fill=W)
    elif bentuk == 9:    # tetes
        d.ellipse((150, 220, 362, 432), fill=W)
        d.polygon([(c, 90), (160, 300), (352, 300)], fill=W)
        d.ellipse((205, 300, 255, 350), fill=w2 + (255,))
    elif bentuk == 10:   # blok bertumpuk
        for k, (x, y, w) in enumerate([(130, 300, 250), (170, 220, 170), (210, 140, 90)]):
            d.rounded_rectangle((x, y, x + w, y + 70), 16, fill=W if k % 2 == 0 else W2)
    else:                # cincin bertaut
        d.ellipse((110, 160, 300, 350), outline=W, width=34)
        d.ellipse((212, 160, 402, 350), outline=W2, width=34)
    im = im.resize((256, 256), Image.LANCZOS)
    out = Image.new('RGB', (256, 256), (255, 255, 255))
    out.paste(im, (0, 0), im)
    out.save(path, 'PNG')

def buat_pamflet(job, perusahaan, bidang, path, logo_path):
    W, H = 800, 1000
    w1, w2 = WARNA[bidang]
    im = Image.new('RGB', (W, H), w1)
    d = ImageDraw.Draw(im)
    for yy in range(H):                     # gradasi
        t = yy / H
        d.line((0, yy, W, yy), fill=tuple(int(w1[i] * (1 - t) + w2[i] * t) for i in range(3)))
    lap = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    dl = ImageDraw.Draw(lap)
    for k in range(9):                      # pola lingkaran halus
        r = rnd.randint(60, 220)
        x, y = rnd.randint(-80, W), rnd.randint(-80, H)
        dl.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, rnd.randint(8, 22)))
    im = Image.alpha_composite(im.convert('RGBA'), lap)
    d = ImageDraw.Draw(im)
    # Kepala: logo + nama perusahaan
    d.rounded_rectangle((0, 0, W, 96), 0, fill=(255, 255, 255))
    lg = Image.open(logo_path).convert('RGBA').resize((64, 64))
    im.paste(lg, (36, 16), lg)
    d.text((116, 26), perusahaan, font=f(26, True), fill=w2)
    d.text((116, 60), bidang + ' · ' + job['lokasi'], font=f(18), fill=(90, 100, 120))
    # Judul
    d.text((40, 128), 'KAMI MEMBUKA', font=f(30, True), fill=(255, 255, 255))
    d.text((40, 164), 'LOWONGAN', font=f(64, True), fill=(255, 222, 110))
    # Panel ilustrasi
    d.rounded_rectangle((40, 258, W - 40, 548), 24, fill=tuple(min(255, c + 30) for c in w2) + (255,))
    ilustrasi(d, (40, 258, W - 40, 548), bidang, w1)
    # Posisi
    d.rounded_rectangle((40, 572, W - 40, 672), 16, fill=(255, 255, 255))
    fp = f(40, True) if d.textlength(job['posisi'], font=f(40, True)) < W - 120 else f(30, True)
    d.text((W // 2, 622), job['posisi'], font=fp, fill=w2, anchor='mm')
    # Kualifikasi
    y = 696
    for b in job['kualifikasi_singkat'][:4]:
        d.ellipse((46, y + 8, 60, y + 22), fill=(255, 222, 110))
        y = tulis_bungkus(d, b, f(22), W - 140, 74, y, (255, 255, 255), 4, 1) + 6
    # Chip jenis & sistem
    cx = 40
    for chip in (JENIS_LABEL[job['jenis']], SISTEM_LABEL[job['sistem']], 'Kuota ' + str(job['kuota']) + ' orang'):
        tw = d.textlength(chip, font=f(20, True))
        d.rounded_rectangle((cx, 852, cx + tw + 32, 892), 20, outline=(255, 255, 255), width=2)
        d.text((cx + 16, 872), chip, font=f(20, True), fill=(255, 255, 255), anchor='lm')
        cx += tw + 46
    # Kaki
    d.rectangle((0, 916, W, H), fill=(10, 22, 52))
    teks_batas = 'Batas lamaran: ' + job['batas_teks'] if job.get('batas_teks') else 'Info batas lamaran di KarirKu Polinema'
    d.text((40, 944), teks_batas, font=f(22, True), fill=(255, 222, 110))
    d.text((40, 974), 'Lamar lewat KarirKu Polinema · Career Center Polinema', font=f(16), fill=(210, 220, 240))
    im.convert('RGB').save(path, 'JPEG', quality=86, optimize=True)

BULAN = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember']
def tgl_indo(t):
    return f'{t.day} {BULAN[t.month - 1]} {t.year}'

def q(s):
    return "'" + str(s).replace("'", "''") + "'"

# ---------------------------------------------------------------- main ----
def main():
    os.makedirs(os.path.join(UP, 'pamflet'), exist_ok=True)
    os.makedirs(os.path.join(UP, 'logo'), exist_ok=True)
    for sub in ('pamflet', 'logo', 'foto', 'cv'):
        os.makedirs(os.path.join(UP, sub), exist_ok=True)
        for f_ in os.listdir(os.path.join(UP, sub)):
            if f_.startswith('dummy-'):
                os.remove(os.path.join(UP, sub, f_))
    hari_ini = datetime.date(2026, 10, 28)
    sql = []
    sql.append("""-- =====================================================================
-- KarirKu Polinema · DATA DUMMY tambahan (lowongan banyak + pamflet + logo)
-- Dibuat oleh tests/buat-data-dummy.py. Gambar ada di storage/uploads/pamflet
-- (dummy-*.jpg), storage/uploads/logo (dummy-emblem-*.png), storage/uploads/foto (dummy-foto-*.png).
-- AMAN DIJALANKAN BERULANG: lowongan dummy hanya ditambahkan sekali.
-- Jalankan SETELAH 01-04 (sudah termasuk di 00-INSTAL-ULANG.sql).
-- =====================================================================
DO $cek$
BEGIN
  IF to_regclass('public.riwayat_lowongan') IS NULL THEN
    RAISE EXCEPTION 'Jalankan 01-schema, 02-seed, 03 dan 04 dulu (atau cukup 00-INSTAL-ULANG.sql).';
  END IF;
END
$cek$;

BEGIN;
""")
    # Logo perusahaan
    logo_file = {}
    for i, (nama, bidang, kota) in enumerate(PERUSAHAAN, 1):
        fn = f'dummy-emblem-{i:02d}.png'
        buat_logo(nama, bidang, os.path.join(UP, 'logo', fn), i - 1)
        logo_file[nama] = fn
        sql.append(f"UPDATE perusahaan SET logo = {q(fn)} WHERE nama_perusahaan = {q(nama)} AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-logo-%');")
    sql.append('')

    # Lowongan dummy
    baris_job = []
    for pi, (nama, bidang_utama, kota) in enumerate(PERUSAHAAN):
        if pi >= 16:          # dua perusahaan terakhir belum aktif: tanpa lowongan
            continue
        jumlah = rnd.randint(5, 8)
        dipakai = set()
        for k in range(jumlah):
            bidang = rnd.choice(TERKAIT[bidang_utama])
            pilihan = [p for p in POSISI[bidang] if p[0] not in dipakai]
            if not pilihan:
                continue
            posisi, skill, desk = rnd.choice(pilihan)
            dipakai.add(posisi)
            jenis = rnd.choices(['full_time', 'kontrak', 'magang', 'part_time'], [6, 3, 3, 1])[0]
            sistem = 'wfo' if bidang not in ('Teknologi Informasi',) else rnd.choice(['wfo', 'hybrid', 'wfh'])
            if jenis == 'magang':
                posisi = 'Magang ' + posisi
            r = rnd.random()
            status = 'aktif' if r < 0.78 else ('ditutup' if r < 0.88 else 'menunggu')
            dibuat = hari_ini - datetime.timedelta(days=rnd.randint(1, 35))
            if status == 'ditutup':
                batas = hari_ini - datetime.timedelta(days=rnd.randint(2, 20))
            else:
                batas = hari_ini + datetime.timedelta(days=rnd.randint(25, 110))
            kuota = rnd.choice([1, 2, 2, 3, 3, 4, 5, 8, 10])
            lokasi = kota if rnd.random() < 0.8 else rnd.choice(['Malang', 'Surabaya', 'Sidoarjo', 'Jakarta', 'Bandung'])
            gaji = '' if jenis == 'magang' and rnd.random() < 0.5 else (
                'Uang saku Rp1.500.000' if jenis == 'magang' else f'Rp{rnd.choice([4,4.5,5,5.5,6,7,8])}-{rnd.choice([7,8,9,10,12])} juta'.replace('.', ','))
            kual = [rnd.choice(KUALIF_UMUM[:2]), 'Menguasai ' + skill.split(',')[0].strip()] + rnd.sample(KUALIF_UMUM[2:], 3)
            jurusan = JURUSAN[bidang]
            kode = hashlib.md5(f'{nama}|{posisi}|{k}'.encode()).hexdigest()
            fn = f'dummy-{kode[:20]}.jpg'
            job = dict(posisi=posisi, lokasi=lokasi, jenis=jenis, sistem=sistem, kuota=kuota,
                       kualifikasi_singkat=kual[:4], batas_teks=tgl_indo(batas))
            buat_pamflet(job, nama, bidang, os.path.join(UP, 'pamflet', fn), os.path.join(UP, 'logo', logo_file[nama]))
            baris_job.append(dict(nama=nama, bidang=bidang, posisi=posisi, jenis=jenis, sistem=sistem, lokasi=lokasi, gaji=gaji,
                                  kuota=kuota, batas=batas, desk=desk + ' Penempatan di ' + lokasi + '.',
                                  kual='\n'.join('- ' + x for x in kual), skill=skill, fn=fn, kode=kode, status=status,
                                  dibuat=dibuat, jurusan=jurusan))

    sql.append("DO $dummy$\nBEGIN\n  IF EXISTS (SELECT 1 FROM lowongan WHERE pamflet LIKE 'dummy-%') THEN\n    RAISE NOTICE 'Lowongan dummy sudah ada, dilewati.';\n    RETURN;\n  END IF;")
    for j in baris_job:
        setuju = j['status'] in ('aktif', 'ditutup')
        sql.append(f"""  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi,
      batas_lamaran, deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada,
      diajukan_pada, disetujui_pada, disetujui_oleh)
    SELECT pr.id, b.id, {q(j['posisi'])}, {q(j['jenis'])}, {q(j['sistem'])}, {q(j['lokasi'])}, {q(j['gaji'])}, {j['kuota']}, 0,
      {q(j['batas'])}, {q(j['desk'])}, {q(j['kual'])}, {q(j['skill'])}, {q(j['fn'])}, {q(j['kode'])}, {q(j['status'])},
      {q(j['dibuat'])}::timestamp + time '09:00', {q(j['dibuat'])}::timestamp + time '09:00', {q(j['dibuat'])}::timestamp + time '09:00',
      {(q(j['dibuat']) + "::timestamp + time '14:00'") if setuju else 'NULL'}, {'(SELECT id FROM admin ORDER BY id LIMIT 1)' if setuju else 'NULL'}
    FROM perusahaan pr, bidang b WHERE pr.nama_perusahaan = {q(j['nama'])} AND b.nama = {q(j['bidang'])}
    ON CONFLICT DO NOTHING;""")
        for jr in j['jurusan']:
            sql.append(f"  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT l.id, jr.id FROM lowongan l, jurusan jr WHERE l.kode_pratinjau = {q(j['kode'])} AND jr.nama = {q(jr)} ON CONFLICT DO NOTHING;")
    sql.append("""  -- Riwayat persetujuan untuk lowongan dummy
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    SELECT l.id, 'menunggu', 'diajukan', 'Lowongan diajukan perusahaan.', pr.pengguna_id, l.diajukan_pada
    FROM lowongan l JOIN perusahaan pr ON pr.id = l.perusahaan_id WHERE l.pamflet LIKE 'dummy-%';
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    SELECT l.id, 'aktif', 'disetujui', 'Disetujui dan ditayangkan.', (SELECT pengguna_id FROM admin ORDER BY id LIMIT 1), l.disetujui_pada
    FROM lowongan l WHERE l.pamflet LIKE 'dummy-%' AND l.disetujui_pada IS NOT NULL;
  RAISE NOTICE 'Lowongan dummy berhasil ditambahkan.';
END
$dummy$;
""")
    # Pamflet untuk lowongan lama (seed) yang masih memakai contoh-pamflet.jpg
    sql.append("-- Lowongan bawaan (02-seed) yang masih memakai pamflet contoh diberi pamflet bergambar.")
    for idx in range(1, 41):
        pass
    sql.append("""-- Batas lamaran lowongan bawaan yang sudah lewat padahal masih 'aktif' digeser ke depan,
-- supaya data demo tidak langsung tertutup otomatis.
UPDATE lowongan SET batas_lamaran = CURRENT_DATE + ((id % 45) + 15)
 WHERE status = 'aktif' AND batas_lamaran < CURRENT_DATE AND pamflet NOT LIKE 'dummy-%';
""")
    # Pamflet seed: dibuat per posisi lama, tanpa tanggal (tanggalnya relatif)
    return sql, baris_job

def pamflet_seed(sql):
    """Pamflet bergambar untuk lowongan di 02-seed.sql (dibaca langsung dari file seed)."""
    import re
    seed = open(os.path.join(ROOT, 'database', '02-seed.sql'), encoding='utf-8').read()
    # Ambil (nama perusahaan, posisi, lokasi) dari blok INSERT lowongan pada seed lewat database bila tersedia.
    try:
        import subprocess
        out = subprocess.run(['psql', '-h', '127.0.0.1', '-U', 'postgres', '-d', 'karirku_polinema', '-tAF', '\t', '-c',
                              "SELECT l.id, pr.nama_perusahaan, b.nama, l.posisi, l.lokasi, l.jenis_pekerjaan, l.sistem_kerja, l.kuota, replace(replace(l.kualifikasi, chr(13), ''), chr(10), ' ;; ') "
                              "FROM lowongan l JOIN perusahaan pr ON pr.id=l.perusahaan_id JOIN bidang b ON b.id=l.bidang_id "
                              "WHERE l.pamflet LIKE 'contoh-%' ORDER BY l.id"],
                             capture_output=True, text=True, env=dict(os.environ, PGPASSWORD=os.environ.get('DB_PASS', 'postgres')))
        rows = [r.split('\t') for r in out.stdout.strip().split('\n') if r.strip()]
    except Exception:
        rows = []
    for r in rows:
        _id, nama, bidang, posisi, lokasi, jenis, sistem, kuota, kual = r
        if nama not in dict((p[0], 1) for p in PERUSAHAAN):
            continue
        logo = os.path.join(UP, 'logo', f'dummy-emblem-{[p[0] for p in PERUSAHAAN].index(nama) + 1:02d}.png')
        kl = [x.strip(' -•*') for x in kual.split(';;') if x.strip(' -•*')] or KUALIF_UMUM[:3]
        fn = 'dummy-seed-' + hashlib.md5(f'{nama}|{posisi}'.encode()).hexdigest()[:16] + '.jpg'
        job = dict(posisi=posisi, lokasi=lokasi, jenis=jenis if jenis in JENIS_LABEL else 'full_time',
                   sistem=sistem if sistem in SISTEM_LABEL else 'wfo', kuota=int(kuota), kualifikasi_singkat=kl[:4], batas_teks=None)
        buat_pamflet(job, nama, bidang if bidang in WARNA else 'Teknologi Informasi', os.path.join(UP, 'pamflet', fn), logo)
        sql.append(f"UPDATE lowongan SET pamflet = {q(fn)} WHERE pamflet LIKE 'contoh-%' AND posisi = {q(posisi)} "
                   f"AND perusahaan_id = (SELECT id FROM perusahaan WHERE nama_perusahaan = {q(nama)});")
    return len(rows)


# ------------------------------------------------- akun perusahaan Ringga ----
RINGGA = ('PT Ringga Karya Digital', 'Teknologi Informasi', 'Malang')
RINGGA_JOBS = [
    ('Junior Web Developer', 'Teknologi Informasi', 'full_time', 'hybrid', 3, 'aktif'),
    ('UI/UX Designer', 'Teknologi Informasi', 'full_time', 'wfo', 2, 'aktif'),
    ('Data Analyst', 'Teknologi Informasi', 'kontrak', 'hybrid', 2, 'aktif'),
    ('Magang Digital Marketing Specialist', 'Perdagangan dan Jasa', 'magang', 'wfo', 4, 'aktif'),
    ('Staf Akuntansi', 'Keuangan', 'full_time', 'wfo', 1, 'aktif'),
    ('Backend Developer', 'Teknologi Informasi', 'full_time', 'wfh', 2, 'menunggu'),
]

def blok_ringga(sql, hari_ini):
    nama, bidang_utama, kota = RINGGA
    logo_fn = 'dummy-emblem-19.png'
    buat_logo(nama, bidang_utama, os.path.join(UP, 'logo', logo_fn), 18)
    sql.append(f"""
-- ---------------------------------------------------------------------
-- Akun perusahaan milik pemilik proyek: ringga.perusahaan@karirku.id / sandi: ringga123
-- (GANTI kata sandinya setelah masuk). Lowongan + pelamar sudah terisi,
-- supaya daftar pelamar & detail pelamar langsung bisa dicoba.
-- ---------------------------------------------------------------------
-- Perbaikan dari versi sebelumnya: perusahaan dummy "PT Ringga Karya Digital" yang
-- terlanjur menempel pada akun BUKAN perusahaan (mis. akun mahasiswa ringga@gmail.com
-- yang sudah ada) dilepas lagi. Akun aslinya tidak diubah; hanya data dummy itu dihapus.
DELETE FROM perusahaan pr USING pengguna p
 WHERE p.id = pr.pengguna_id AND pr.nama_perusahaan = 'PT Ringga Karya Digital' AND p.role <> 'perusahaan';
DELETE FROM perusahaan pr USING pengguna p
 WHERE p.id = pr.pengguna_id AND pr.nama_perusahaan = 'PT Ringga Karya Digital' AND p.email = 'ringga@gmail.com'
   AND p.password_hash = '$2y$10$eVUAkMLdK3vn7WeAv8zDWuY3V27l45B3Ts/d.1D65gN8DJSEfUmIq';
DELETE FROM pengguna p WHERE p.email = 'ringga@gmail.com' AND p.role = 'perusahaan'
   AND p.password_hash = '$2y$10$eVUAkMLdK3vn7WeAv8zDWuY3V27l45B3Ts/d.1D65gN8DJSEfUmIq'
   AND NOT EXISTS (SELECT 1 FROM perusahaan x WHERE x.pengguna_id = p.id);

UPDATE perusahaan SET logo = 'dummy-emblem-19.png' WHERE nama_perusahaan = 'PT Ringga Karya Digital' AND (logo IS NULL OR logo LIKE 'dummy-logo-%');

INSERT INTO pengguna (email, password_hash, role, status_akun)
  VALUES ('ringga.perusahaan@karirku.id', '$2y$10$eVUAkMLdK3vn7WeAv8zDWuY3V27l45B3Ts/d.1D65gN8DJSEfUmIq', 'perusahaan', 'aktif')
  ON CONFLICT (email) DO NOTHING;
INSERT INTO perusahaan (pengguna_id, nama_perusahaan, bidang_usaha, jenis_perusahaan, alamat, kota, website, nama_pic, jabatan_pic,
                        whatsapp_pic, logo, deskripsi, bukan_outsourcing, provinsi, kode_pos)
  SELECT p.id, {q(nama)}, 'Teknologi Informasi', 'Swasta nasional', 'Jl. Soekarno Hatta No. 9', 'Kota Malang', 'https://contoh.id',
         'Ringga Budi Utama', 'CEO', '081234567800', {q(logo_fn)},
         'Perusahaan pengembang aplikasi web dan mobile untuk UMKM dan instansi di Jawa Timur.', true, 'Jawa Timur', '65141'
  FROM pengguna p WHERE p.email = 'ringga.perusahaan@karirku.id' AND p.role = 'perusahaan'
    AND NOT EXISTS (SELECT 1 FROM perusahaan x WHERE x.pengguna_id = p.id);
""")
    sql.append("DO $ringga$\nDECLARE\n  v_pr int; v_low int; v_mhs record; v_lam int; v_i int := 0; v_status text; v_tgl timestamp; v_admin int;\n"
               "BEGIN\n  SELECT pr.id INTO v_pr FROM perusahaan pr JOIN pengguna p ON p.id = pr.pengguna_id WHERE p.email = 'ringga.perusahaan@karirku.id';\n"
               "  IF v_pr IS NULL OR EXISTS (SELECT 1 FROM lowongan WHERE perusahaan_id = v_pr) THEN\n    RAISE NOTICE 'Data akun Ringga sudah ada, dilewati.';\n    RETURN;\n  END IF;\n"
               "  SELECT pengguna_id INTO v_admin FROM admin ORDER BY id LIMIT 1;\n  PERFORM setseed(0.27);")
    for k, (posisi, bidang, jenis, sistem, kuota, status) in enumerate(RINGGA_JOBS):
        dasar = posisi.replace('Magang ', '')
        tpl = next((x for x in POSISI[bidang] if x[0] == dasar), POSISI[bidang][0])
        batas = hari_ini + datetime.timedelta(days=30 + k * 9)
        kual = ['Lulusan D3/D4 Politeknik Negeri Malang', 'Menguasai ' + tpl[1].split(',')[0].strip(), 'Komunikatif dan teliti', 'Mampu bekerja dalam tim']
        kode = hashlib.md5(f'ringga-pt|{posisi}'.encode()).hexdigest()
        fn = f'dummy-{kode[:20]}.jpg'
        buat_pamflet(dict(posisi=posisi, lokasi='Malang', jenis=jenis, sistem=sistem, kuota=kuota, kualifikasi_singkat=kual,
                          batas_teks=tgl_indo(batas)), nama, bidang, os.path.join(UP, 'pamflet', fn), os.path.join(UP, 'logo', logo_fn))
        setuju = status == 'aktif'
        dibuat = hari_ini - datetime.timedelta(days=12 - k)
        sql.append(f"""  INSERT INTO lowongan (perusahaan_id, bidang_id, posisi, jenis_pekerjaan, sistem_kerja, lokasi, gaji, kuota, terisi, batas_lamaran,
      deskripsi, kualifikasi, skill_dibutuhkan, pamflet, kode_pratinjau, status, dibuat_pada, diperbarui_pada, diajukan_pada, disetujui_pada, disetujui_oleh)
    VALUES (v_pr, (SELECT id FROM bidang WHERE nama = {q(bidang)}), {q(posisi)}, {q(jenis)}, {q(sistem)}, 'Malang',
      {q('Uang saku Rp1.500.000' if jenis == 'magang' else 'Rp5-8 juta')}, {kuota}, 0, {q(batas)},
      {q(tpl[2] + ' Penempatan di kantor Malang.')}, {q(chr(10).join('- ' + x for x in kual))}, {q(tpl[1])}, {q(fn)}, {q(kode)}, {q(status)},
      {q(dibuat)}::timestamp + time '09:00', {q(dibuat)}::timestamp + time '09:00', {q(dibuat)}::timestamp + time '09:00',
      {(q(dibuat) + "::timestamp + time '13:00'") if setuju else 'NULL'}, {'(SELECT id FROM admin ORDER BY id LIMIT 1)' if setuju else 'NULL'})
    RETURNING id INTO v_low;
  INSERT INTO lowongan_jurusan (lowongan_id, jurusan_id) SELECT v_low, id FROM jurusan WHERE nama IN ({', '.join(q(j) for j in JURUSAN[bidang])});
  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'menunggu', 'diajukan', 'Lowongan diajukan perusahaan.', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), {q(dibuat)}::timestamp + time '09:00');""")
        if not setuju:
            continue
        sql.append(f"""  INSERT INTO riwayat_lowongan (lowongan_id, status, aksi, catatan, oleh, tanggal)
    VALUES (v_low, 'aktif', 'disetujui', 'Disetujui dan ditayangkan.', v_admin, {q(dibuat)}::timestamp + time '13:00');
  -- Pelamar: mahasiswa/alumni aktif dipilih acak, status seleksi bervariasi
  FOR v_mhs IN
    SELECT m.*, p.email, ps.nama AS nama_prodi, ps.jenjang, j.nama AS nama_jurusan
      FROM mahasiswa m JOIN pengguna p ON p.id = m.pengguna_id
      JOIN program_studi ps ON ps.id = m.program_studi_id JOIN jurusan j ON j.id = ps.jurusan_id
     WHERE p.status_akun = 'aktif' AND m.file_ktm IS NOT NULL ORDER BY random() LIMIT {5 + (k * 3) % 5}
  LOOP
    v_i := v_i + 1;
    v_status := (ARRAY['diajukan','screening','screening','interview','interview','diterima','ditolak','diajukan'])[1 + (v_i % 8)];
    IF v_status = 'diterima' AND (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') >= {kuota} THEN v_status := 'interview'; END IF;
    v_tgl := {q(dibuat)}::timestamp + ((v_i % 9) || ' days')::interval + ((8 + v_i % 9) || ' hours')::interval;
    INSERT INTO lamaran (mahasiswa_id, lowongan_id, tanggal_lamar, status, jenis_cv, file_cv, file_ktm, file_surat_pengantar, catatan_pelamar, snapshot_profil,
                         catatan_perusahaan, diperbarui_pada)
      VALUES (v_mhs.id, v_low, v_tgl, v_status, 'generate', COALESCE(v_mhs.file_cv, 'cv-sistem.pdf'), v_mhs.file_ktm, COALESCE(v_mhs.file_surat_pengantar, v_mhs.file_ktm),
        'Perkenalkan, saya ' || v_mhs.nama || ', ' || v_mhs.jenjang || ' ' || v_mhs.nama_prodi || '. Saya tertarik melamar posisi {posisi.replace("'", "''")} dan siap mengikuti seluruh proses seleksi.',
        json_build_object('nama', v_mhs.nama, 'nim', v_mhs.nim, 'email', v_mhs.email, 'no_whatsapp', v_mhs.no_whatsapp,
          'prodi', v_mhs.nama_prodi, 'jenjang', v_mhs.jenjang, 'jurusan', v_mhs.nama_jurusan, 'angkatan', v_mhs.angkatan,
          'status_mahasiswa', v_mhs.status_mahasiswa, 'tahun_lulus', v_mhs.tahun_lulus, 'ipk', v_mhs.ipk, 'domisili', v_mhs.domisili,
          'alamat', v_mhs.alamat, 'provinsi', v_mhs.provinsi,
          'skill', COALESCE((SELECT json_agg(s.nama ORDER BY s.nama) FROM mahasiswa_skill ms JOIN skill s ON s.id = ms.skill_id WHERE ms.mahasiswa_id = v_mhs.id), '[]'::json),
          'jenis_cv', 'generate', 'diambil_pada', to_char(v_tgl, 'YYYY-MM-DD HH24:MI:SS'))::jsonb,
        CASE WHEN v_status = 'ditolak' THEN 'Terima kasih, ' || v_mhs.nama || ', atas lamaran Anda. Saat ini kualifikasi Anda belum sesuai dengan kebutuhan kami.' END,
        v_tgl + interval '2 days')
      ON CONFLICT DO NOTHING RETURNING id INTO v_lam;
    CONTINUE WHEN v_lam IS NULL;
    INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal) VALUES (v_lam, 'diajukan', v_mhs.pengguna_id, 'Lamaran dikirim.', v_tgl);
    IF v_status <> 'diajukan' THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'screening', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'CV sedang ditinjau perusahaan.', v_tgl + interval '1 day');
    END IF;
    IF v_status IN ('interview', 'diterima') THEN
      INSERT INTO interview (lamaran_id, tanggal, jam, mode, lokasi_tautan, catatan, tempat, ruangan, dresscode, yang_dibawa, narahubung)
        VALUES (v_lam, CURRENT_DATE + (2 + v_i % 6), '09:00', CASE WHEN v_i % 2 = 0 THEN 'daring' ELSE 'luring' END,
          CASE WHEN v_i % 2 = 0 THEN 'https://meet.google.com/abc-defg-hij' ELSE 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END, 'Mohon hadir 10 menit sebelum jadwal.',
          CASE WHEN v_i % 2 = 1 THEN 'PT Ringga Karya Digital, Jl. Soekarno Hatta No. 9, Kota Malang' END,
          CASE WHEN v_i % 2 = 1 THEN 'Lantai 2, Ruang Meeting' END, 'Rapi dan sopan (kemeja berkerah)', 'KTM/KTP, CV cetak, portofolio',
          'Ringga Budi Utama (CEO), 081234567800');
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, 'interview', (SELECT pengguna_id FROM perusahaan WHERE id = v_pr), 'Dijadwalkan interview.', v_tgl + interval '2 days');
    END IF;
    IF v_status IN ('diterima', 'ditolak') THEN
      INSERT INTO riwayat_lamaran (lamaran_id, status, diubah_oleh, catatan, tanggal)
        VALUES (v_lam, v_status, (SELECT pengguna_id FROM perusahaan WHERE id = v_pr),
                CASE WHEN v_status = 'ditolak' THEN 'Kualifikasi belum sesuai.' ELSE 'Selamat, Anda diterima.' END, v_tgl + interval '3 days');
    END IF;
  END LOOP;
  UPDATE lowongan SET terisi = (SELECT COUNT(*) FROM lamaran WHERE lowongan_id = v_low AND status = 'diterima') WHERE id = v_low;""")
    sql.append("  RAISE NOTICE 'Akun ringga.perusahaan@karirku.id berisi lowongan dan pelamar berhasil dibuat.';\nEND\n$ringga$;\n")

# ------------------------------------------------ profil mahasiswa dummy ----
PEREMPUAN = {'siti', 'dewi', 'nur', 'intan', 'laila', 'ayu', 'rina', 'mega', 'sari', 'putri', 'novi', 'diah', 'fitri', 'anisa', 'maya',
             'lintang', 'zahra', 'winda', 'rahma', 'tiara', 'melati', 'salsa', 'kirana', 'vina', 'ratna', 'nabila'}
KULIT = [(241, 200, 160), (224, 172, 128), (198, 140, 96), (170, 112, 74)]
RAMBUT = [(30, 24, 22), (52, 36, 28), (70, 48, 34)]
BAJU = [(37, 99, 235), (190, 52, 85), (22, 128, 104), (124, 58, 237), (217, 119, 6), (14, 116, 144), (51, 65, 85), (190, 24, 93)]
HIJAB = [(30, 64, 120), (150, 40, 80), (20, 110, 100), (110, 60, 160), (180, 110, 40), (60, 60, 70), (200, 150, 160), (90, 120, 60)]
LATAR = [(219, 234, 254), (252, 231, 243), (220, 252, 231), (237, 233, 254), (254, 243, 199), (224, 242, 254), (241, 245, 249)]

def buat_avatar(nama, path, seed):
    r = random.Random(seed)
    cewek = nama.split()[0].lower() in PEREMPUAN
    hijab = cewek and r.random() < 0.65
    S = 512
    im = Image.new('RGB', (S, S), r.choice(LATAR))
    d = ImageDraw.Draw(im)
    kulit, rambut, baju = r.choice(KULIT), r.choice(RAMBUT), r.choice(BAJU)
    # badan + kerah
    d.ellipse((96, 360, 416, 680), fill=baju)
    d.polygon([(206, 372), (256, 440), (306, 372)], fill=(255, 255, 255))
    d.rectangle((226, 330, 286, 392), fill=kulit)              # leher
    if hijab:
        warna_h = r.choice(HIJAB)
        d.ellipse((136, 96, 376, 356), fill=warna_h)          # kepala berbalut
        d.polygon([(150, 260), (362, 260), (400, 430), (112, 430)], fill=warna_h)
        d.ellipse((176, 140, 336, 320), fill=kulit)          # wajah
    else:
        if cewek:
            d.ellipse((150, 110, 362, 330), fill=rambut)
            d.rectangle((150, 220, 362, 400), fill=rambut)   # rambut panjang
        d.ellipse((170, 126, 342, 326), fill=kulit)           # wajah
        if cewek:
            d.chord((160, 108, 352, 250), 180, 360, fill=rambut)
        else:
            gaya = r.randint(0, 2)
            d.chord((160, 100, 352, 240), 180, 360, fill=rambut)
            if gaya == 1:
                d.polygon([(170, 175), (250, 120), (342, 170), (342, 150), (250, 100), (170, 150)], fill=rambut)
            elif gaya == 2:
                d.rectangle((166, 150, 346, 182), fill=rambut)
    # mata, alis, senyum
    for x in (222, 290):
        d.ellipse((x - 11, 222, x + 11, 244), fill=(40, 30, 28))
        d.line((x - 18, 206, x + 16, 202), fill=(60, 40, 30), width=6)
    d.arc((222, 250, 290, 300), 20, 160, fill=(150, 70, 60), width=6)
    if r.random() < 0.15:                                     # kacamata
        for x in (222, 290):
            d.ellipse((x - 26, 210, x + 26, 256), outline=(40, 40, 50), width=5)
        d.line((248, 230, 264, 230), fill=(40, 40, 50), width=5)
    im = im.resize((256, 256), Image.LANCZOS)
    im.save(path, 'PNG')

KODEPOS = {'Malang': '65141', 'Surabaya': '60111', 'Pasuruan': '67111', 'Kediri': '64111', 'Batu': '65311', 'Mojokerto': '61311',
           'Lumajang': '67311', 'Gresik': '61111', 'Tulungagung': '66211', 'Blitar': '66111', 'Sidoarjo': '61211',
           'Probolinggo': '67211', 'Madiun': '63111'}
JALAN = ['Jl. Soekarno Hatta', 'Jl. Veteran', 'Jl. Ijen', 'Jl. Kawi', 'Jl. Merdeka', 'Jl. Diponegoro', 'Jl. Ahmad Yani', 'Jl. Gajayana',
         'Jl. Sumbersari', 'Jl. Kertoraharjo', 'Jl. Pahlawan', 'Jl. Panglima Sudirman']
PROFIL_JURUSAN = {
    'Teknologi Informasi': dict(skill=['HTML', 'CSS', 'JavaScript', 'PHP', 'Laravel', 'PostgreSQL', 'Git', 'Figma', 'Python', 'UI/UX Design'],
        bidang=['Teknologi Informasi'], smk='SMK Negeri 4 Malang · Rekayasa Perangkat Lunak',
        kerja=[('Magang Web Developer', 'PT Sinergi Data Nusantara', 'Membuat fitur dashboard admin dengan Laravel dan PostgreSQL.'),
               ('Asisten Laboratorium Pemrograman', 'Politeknik Negeri Malang', 'Mendampingi praktikum pemrograman web untuk mahasiswa semester 1.'),
               ('Freelance Frontend Developer', 'Proyek UMKM', 'Membuat landing page responsif untuk 4 usaha kecil di Malang.')],
        sert=[('Junior Web Developer (BNSP)', 'LSP Politeknik Negeri Malang'), ('Dicoding: Belajar Dasar Pemrograman Web', 'Dicoding Indonesia'),
              ('Google UX Design Certificate', 'Coursera')],
        porto=[('Aplikasi Kasir UMKM Berbasis Web', 'https://github.com/contoh/kasir-umkm'), ('Sistem Informasi Perpustakaan', 'https://github.com/contoh/perpus')],
        tentang='Senang membangun aplikasi web yang rapi dan mudah dipakai. Terbiasa bekerja dalam tim dengan Git dan metode agile.'),
    'Teknik Sipil': dict(skill=['AutoCAD', 'Microsoft Excel', 'Kerja sama tim', 'Manajemen waktu', 'Komunikasi'],
        bidang=['Konstruksi'], smk='SMK Negeri 1 Singosari · Desain Pemodelan dan Informasi Bangunan',
        kerja=[('Magang Pengawas Lapangan', 'PT Adhi Karya Tbk', 'Membantu pengawasan pekerjaan struktur dan pelaporan progres harian.'),
               ('Drafter Paruh Waktu', 'CV Arta Konstruksi', 'Membuat gambar kerja rumah tinggal dan RAB sederhana.')],
        sert=[('Ahli Muda Teknik Jalan (SKK)', 'LPJK'), ('AutoCAD Certified User', 'Autodesk')],
        porto=[('Desain Struktur Gedung 3 Lantai', 'https://drive.google.com/contoh-struktur')],
        tentang='Tertarik pada perencanaan dan pengawasan proyek konstruksi. Teliti dalam menghitung volume dan anggaran.'),
    'Teknik Mesin': dict(skill=['AutoCAD', 'SolidWorks', 'Microsoft Excel', 'Kerja sama tim', 'Manajemen waktu'],
        bidang=['Manufaktur'], smk='SMK Negeri 6 Malang · Teknik Pemesinan',
        kerja=[('Magang Maintenance Mesin', 'PT Barata Indonesia', 'Melakukan perawatan preventif mesin bubut dan frais.'),
               ('Asisten Bengkel Praktik', 'Politeknik Negeri Malang', 'Menyiapkan alat dan bahan praktikum pemesinan.')],
        sert=[('Operator Mesin CNC (BNSP)', 'LSP Logam dan Mesin'), ('K3 Umum', 'Kemnaker RI')],
        porto=[('Rancang Bangun Alat Pengupas Kopi', 'https://drive.google.com/contoh-alat')],
        tentang='Menyukai dunia manufaktur dan perawatan mesin. Terbiasa membaca gambar teknik dan bekerja sesuai SOP K3.'),
    'Teknik Elektro': dict(skill=['Microsoft Excel', 'AutoCAD', 'Python', 'Kerja sama tim', 'Komunikasi'],
        bidang=['Kelistrikan', 'Teknologi Informasi'], smk='SMK Negeri 5 Malang · Teknik Instalasi Tenaga Listrik',
        kerja=[('Magang Teknisi Listrik', 'PT Energi Listrik Mandiri', 'Membantu pemasangan panel distribusi dan pengujian instalasi.'),
               ('Teknisi Paruh Waktu', 'CV Sinar Elektrik', 'Memperbaiki instalasi listrik rumah dan gedung kecil.')],
        sert=[('Teknisi Instalasi Listrik (BNSP)', 'LSP Ketenagalistrikan'), ('Dasar PLC Siemens', 'Siemens Learning')],
        porto=[('Sistem Monitoring Daya Berbasis IoT', 'https://github.com/contoh/iot-daya')],
        tentang='Tertarik pada sistem kelistrikan dan otomasi. Terbiasa bekerja dengan PLC dan alat ukur listrik.'),
    'Teknik Kimia': dict(skill=['Microsoft Excel', 'Kerja sama tim', 'Manajemen waktu', 'Komunikasi', 'Bahasa Inggris'],
        bidang=['Kimia', 'Manufaktur'], smk='SMA Negeri 3 Malang · IPA',
        kerja=[('Magang Analis Laboratorium', 'PT Wilmar Nabati Indonesia', 'Menganalisis kadar asam lemak bebas dan kadar air bahan baku.'),
               ('Asisten Laboratorium Kimia Analitik', 'Politeknik Negeri Malang', 'Menyiapkan larutan standar dan membimbing praktikum.')],
        sert=[('Analis Kimia Muda (BNSP)', 'LSP Kimia'), ('ISO 14001 Awareness', 'Lembaga Pelatihan Mutu')],
        porto=[('Pengolahan Limbah Cair Tahu Skala Lab', 'https://drive.google.com/contoh-limbah')],
        tentang='Teliti dan disiplin di laboratorium. Tertarik pada pengendalian mutu dan pengelolaan lingkungan industri.'),
    'Akuntansi': dict(skill=['Microsoft Excel', 'Komunikasi', 'Manajemen waktu', 'Kerja sama tim', 'Bahasa Inggris'],
        bidang=['Keuangan'], smk='SMK Negeri 1 Malang · Akuntansi dan Keuangan Lembaga',
        kerja=[('Magang Staf Akuntansi', 'PT Bank Mandiri Tbk', 'Membantu rekonsiliasi bank dan penyusunan laporan harian.'),
               ('Bendahara Himpunan Mahasiswa', 'Himpunan Mahasiswa Akuntansi', 'Mengelola kas dan laporan pertanggungjawaban kegiatan.')],
        sert=[('Brevet Pajak A dan B', 'IAI Wilayah Jawa Timur'), ('Microsoft Office Specialist: Excel', 'Microsoft')],
        porto=[('Laporan Keuangan UMKM Kopi Lokal', 'https://drive.google.com/contoh-laporan')],
        tentang='Teliti dengan angka dan terbiasa menyusun laporan keuangan. Siap belajar sistem akuntansi perusahaan.'),
    'Administrasi Niaga': dict(skill=['Microsoft Excel', 'Komunikasi', 'Bahasa Inggris', 'Kerja sama tim', 'Figma'],
        bidang=['Perdagangan dan Jasa', 'Keuangan'], smk='SMA Negeri 5 Malang · IPS',
        kerja=[('Magang Staf Administrasi', 'PT Mitra Arsip Nusantara', 'Mengelola arsip digital dan surat-menyurat perusahaan.'),
               ('Admin Media Sosial', 'Usaha Kuliner Keluarga', 'Membuat konten dan menaikkan pengikut Instagram dua kali lipat.')],
        sert=[('Digital Marketing Fundamental', 'Google Digital Garage'), ('TOEIC 750', 'ETS')],
        porto=[('Kampanye Pemasaran Digital Produk UMKM', 'https://drive.google.com/contoh-kampanye')],
        tentang='Komunikatif dan rapi dalam administrasi. Tertarik pada pemasaran digital dan pelayanan pelanggan.'),
}

def buat_cv(path, nama, prodi, jurusan, email, wa, ipk, alamat, tentang, pend, kerja, sert, skill, foto, th_kerja):
    """CV satu halaman (A4) dalam PDF untuk mahasiswa dummy."""
    W, H = 1240, 1754
    im = Image.new('RGB', (W, H), (255, 255, 255))
    d = ImageDraw.Draw(im)
    biru = (15, 52, 116)
    d.rectangle((0, 0, W, 300), fill=biru)
    ft = Image.open(foto).convert('RGB').resize((220, 220))
    m = Image.new('L', (220, 220), 0); ImageDraw.Draw(m).ellipse((0, 0, 219, 219), fill=255)
    im.paste(ft, (70, 40), m)
    d.text((330, 70), nama, font=f(56, True), fill=(255, 255, 255))
    d.text((330, 150), prodi, font=f(28), fill=(210, 225, 255))
    d.text((330, 192), 'Politeknik Negeri Malang · Jurusan ' + jurusan, font=f(24), fill=(210, 225, 255))
    y = 340
    d.text((70, y), f'Email: {email}    WhatsApp: {wa}    IPK: {ipk or "-"}', font=f(22), fill=(60, 70, 90)); y += 36
    d.text((70, y), 'Alamat: ' + alamat, font=f(22), fill=(60, 70, 90)); y += 60
    def judul(t):
        nonlocal y
        d.text((70, y), t, font=f(32, True), fill=biru); y += 46
        d.line((70, y, W - 70, y), fill=(200, 210, 230), width=3); y += 20
    judul('Profil')
    y = tulis_bungkus(d, tentang, f(24), W - 140, 70, y, (40, 45, 60), 8, 5) + 24
    judul('Pendidikan')
    for jd, inst, mulai, selesai, desk in pend:
        d.text((70, y), jd, font=f(26, True), fill=(30, 35, 50)); y += 36
        d.text((70, y), f'{inst} · {mulai[:4]} – {selesai[:4] if selesai else "sekarang"}', font=f(22), fill=(90, 100, 120)); y += 44
    judul('Pengalaman')
    for k, (jd, inst, desk) in enumerate(kerja):
        d.text((70, y), f'{jd} — {inst}', font=f(26, True), fill=(30, 35, 50)); y += 36
        d.text((70, y), f'Feb – Jun {th_kerja - k}', font=f(22), fill=(90, 100, 120)); y += 32
        y = tulis_bungkus(d, desk, f(22), W - 140, 70, y, (60, 65, 80), 6, 2) + 18
    judul('Sertifikat')
    for jd, inst in sert:
        d.text((70, y), f'• {jd} ({inst})', font=f(24), fill=(40, 45, 60)); y += 38
    y += 16
    judul('Keahlian')
    x = 70
    for sk in skill:
        tw = d.textlength(sk, font=f(22, True))
        if x + tw + 40 > W - 70:
            x = 70; y += 54
        d.rounded_rectangle((x, y, x + tw + 32, y + 42), 21, fill=(232, 240, 252))
        d.text((x + 16, y + 21), sk, font=f(22, True), fill=biru, anchor='lm')
        x += tw + 46
    d.text((70, H - 70), 'Dibuat dari profil KarirKu Polinema (data dummy untuk demo).', font=f(18), fill=(150, 160, 175))
    im.save(path, 'PDF', resolution=150)

def blok_mahasiswa(sql):
    import subprocess
    out = subprocess.run(['psql', '-h', '127.0.0.1', '-U', 'postgres', '-d', 'karirku_polinema', '-tAF', '\t', '-c',
                          "SELECT m.nim, m.nama, j.nama, ps.jenjang, ps.nama, m.angkatan, m.status_mahasiswa, coalesce(m.tahun_lulus::text,''), coalesce(m.domisili,'Malang'), p.email, coalesce(m.no_whatsapp,''), coalesce(m.ipk::text,'') "
                          "FROM mahasiswa m JOIN program_studi ps ON ps.id = m.program_studi_id JOIN jurusan j ON j.id = ps.jurusan_id "
                          "JOIN pengguna p ON p.id = m.pengguna_id "
                          "WHERE p.email LIKE '%@student.polinema.ac.id' OR p.email = 'mahasiswa@polinema.ac.id' ORDER BY m.id"],
                         capture_output=True, text=True, env=dict(os.environ, PGPASSWORD=os.environ.get('DB_PASS', 'postgres')))
    rows = [r.split('\t') for r in out.stdout.strip().split('\n') if r.strip()]
    sql.append("""
-- ---------------------------------------------------------------------
-- Profil lengkap untuk SEMUA mahasiswa/alumni dummy: foto, tentang, alamat,
-- pendidikan, pengalaman, sertifikat, portofolio, skill, dan bidang minat.
-- Hanya mengisi yang masih KOSONG, jadi isian yang sudah ada tidak ditimpa.
-- ---------------------------------------------------------------------""")
    semua_skill = sorted({sk for p in PROFIL_JURUSAN.values() for sk in p['skill']})
    sql.append("INSERT INTO skill (nama) VALUES " + ', '.join(f'({q(x)})' for x in semua_skill) + " ON CONFLICT (nama) DO NOTHING;")
    for i, (nim, nama, jurusan, jenjang, prodi, angkatan, status, lulus, domisili, email, wa, ipk) in enumerate(rows):
        pj = PROFIL_JURUSAN.get(jurusan, PROFIL_JURUSAN['Teknologi Informasi'])
        r = random.Random(nim)
        fn = f'dummy-foto-{nim}.png'
        buat_avatar(nama, os.path.join(UP, 'foto', fn), nim)
        kota = domisili.replace('Kota ', '').replace('Kabupaten ', '')
        alamat = f"{r.choice(JALAN)} No. {r.randint(2, 180)}, RT {r.randint(1, 9):02d}/RW {r.randint(1, 12):02d}"
        tentang = (('Alumni ' if status == 'alumni' else 'Mahasiswa ') + f'{jenjang} {prodi} Politeknik Negeri Malang angkatan {angkatan}. ' + pj['tentang'])
        W = f"(SELECT id FROM mahasiswa WHERE nim = {q(nim)})"
        sql.append(f"UPDATE mahasiswa SET foto = {q(fn)} WHERE nim = {q(nim)} AND (foto IS NULL OR foto = '' OR foto LIKE 'contoh-%' OR foto LIKE 'dummy-foto-%');")
        sql.append(f"UPDATE mahasiswa SET tentang = {q(tentang)} WHERE nim = {q(nim)} AND coalesce(trim(tentang), '') = '';")
        sql.append(f"UPDATE mahasiswa SET alamat = {q(alamat)}, provinsi = 'Jawa Timur', kode_pos = {q(KODEPOS.get(kota, '65141'))} WHERE nim = {q(nim)} AND coalesce(alamat, '') = '';")
        mulai_kuliah = f'{angkatan}-08-25'
        selesai_kuliah = f'{lulus}-08-30' if status == 'alumni' and lulus else None
        smk_th = int(angkatan)
        pend = [(pj['smk'].split(' · ')[1], pj['smk'].split(' · ')[0], f'{smk_th - 3}-07-15', f'{smk_th}-05-30', 'Lulus dengan nilai rata-rata baik.'),
                (f'{jenjang} {prodi}', 'Politeknik Negeri Malang', mulai_kuliah, selesai_kuliah, f'IPK sementara di atas 3,00. Aktif di kegiatan jurusan {jurusan}.')]
        kerja = r.sample(pj['kerja'], k=min(2, len(pj['kerja'])))
        th_kerja = min(int(angkatan) + 2, 2025)
        sert = r.sample(pj['sert'], k=min(2, len(pj['sert'])))
        porto = r.choice(pj['porto'])

        def item(tipe, judul, instansi, mulai, selesai, desk, tautan=None, file=None):
            sql.append(f"INSERT INTO profil_item (mahasiswa_id, tipe, judul, instansi, mulai, selesai, deskripsi, tautan, file) "
                       f"SELECT {W}, {q(tipe)}, {q(judul)}, {q(instansi) if instansi else 'NULL'}, {q(mulai) if mulai else 'NULL'}, "
                       f"{q(selesai) if selesai else 'NULL'}, {q(desk) if desk else 'NULL'}, {q(tautan) if tautan else 'NULL'}, {q(file) if file else 'NULL'} "
                       f"WHERE {W} IS NOT NULL AND NOT EXISTS (SELECT 1 FROM profil_item x WHERE x.mahasiswa_id = {W} AND x.tipe = {q(tipe)} AND x.judul = {q(judul)}) "
                       f"AND (SELECT count(*) FROM profil_item x WHERE x.mahasiswa_id = {W} AND x.tipe = {q(tipe)}) < 2;")
        for p_ in reversed(pend):          # Polinema dulu, baru SMA/SMK
            item('pendidikan', p_[0], p_[1], p_[2], p_[3], p_[4])
        for k, (judul, inst, desk) in enumerate(kerja):
            item('pengalaman', judul, inst, f'{th_kerja - k}-02-03', f'{th_kerja - k}-06-28', desk)
        for k, (judul, inst) in enumerate(sert):
            item('sertifikat', judul, inst, f'{th_kerja - k}-11-20', None, None, None, 'contoh-sertifikat.pdf')
        item('portofolio', porto[0], None, None, None, 'Proyek mandiri/tugas akhir.', porto[1], 'contoh-portofolio.pdf')
        ambil = r.sample(pj['skill'], k=min(len(pj['skill']), r.randint(4, 6)))
        cv_fn = f'dummy-cv-{nim}.pdf'
        buat_cv(os.path.join(UP, 'cv', cv_fn), nama, f'{jenjang} {prodi}', jurusan, email, wa, ipk, alamat + ', ' + kota, tentang,
                pend, kerja, sert, ambil, os.path.join(UP, 'foto', fn), th_kerja)
        sql.append(f"UPDATE mahasiswa SET file_cv = {q(cv_fn)} WHERE nim = {q(nim)} AND (coalesce(file_cv, '') = '' OR file_cv LIKE 'dummy-cv-%');")
        sql.append(f"INSERT INTO mahasiswa_skill (mahasiswa_id, skill_id) SELECT {W}, s.id FROM skill s WHERE s.nama IN ({', '.join(q(x) for x in ambil)}) "
                   f"AND {W} IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_skill x WHERE x.mahasiswa_id = {W}) ON CONFLICT DO NOTHING;")
        sql.append(f"INSERT INTO mahasiswa_minat (mahasiswa_id, bidang_id) SELECT {W}, b.id FROM bidang b WHERE b.nama IN ({', '.join(q(x) for x in pj['bidang'])}) "
                   f"AND {W} IS NOT NULL AND NOT EXISTS (SELECT 1 FROM mahasiswa_minat x WHERE x.mahasiswa_id = {W}) ON CONFLICT DO NOTHING;")
    return len(rows)

if __name__ == '__main__':
    sql, jobs = main()
    n_seed = pamflet_seed(sql)
    blok_ringga(sql, datetime.date(2026, 10, 28))
    n_mhs = blok_mahasiswa(sql)
    # Revisi tahap 2: detail lengkap item profil (blok yang sama dengan di 06-revisi-profil.sql)
    s06 = open(os.path.join(ROOT, 'database', '06-revisi-profil.sql'), encoding='utf-8').read()
    sql.append(s06[s06.index('-- ---------------------------------------------------------------------\n-- Lengkapi detail'):])
    sql.append('\nCOMMIT;\n')
    open(os.path.join(ROOT, 'database', '05-data-dummy.sql'), 'w', encoding='utf-8').write('\n'.join(sql))
    print(f'{len(jobs)} lowongan dummy + {n_seed} pamflet lowongan bawaan + {len(PERUSAHAAN) + 1} logo + {n_mhs} profil mahasiswa dibuat.')
