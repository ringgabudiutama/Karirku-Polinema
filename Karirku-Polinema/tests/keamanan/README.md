# Uji keamanan aplikasi web (bisa diulang)

Skrip ini dipakai saat audit keamanan. Jalankan **hanya di lingkungan uji** dengan data demo
(`00-INSTAL-ULANG.sql`), tidak pernah di server produksi: sebagian skrip mengubah data.
Syarat: Python 3 + `pip install requests pillow`, aplikasi berjalan (mis. `./jalankan.sh`), dan akun demo
bawaan (admin, mahasiswa, perusahaan). Ubah alamat dengan `BASE=http://127.0.0.1:8000`.

| Skrip | Yang diuji | Hasil yang diharapkan |
|---|---|---|
| `uji-csp.py` | Semua halaman sebagai tiap peran: header keamanan ada, setiap `<script>` inline ber-nonce yang cocok, tidak ada `on*=` atau `javascript:`, tidak ada sumber luar di luar daftar izin | `PELANGGARAN: tidak ada` |
| `uji-akses-peran.py` | Paksa buka semua alamat sebagai tamu, mahasiswa, perusahaan, admin (GET dan POST) | tidak ada `/admin/*` yang terbuka untuk non-admin (lihat `akses-matriks.txt`) |
| `kanari-xss.sql` + `telusur-xss.py` | Menanam teks berbahaya di semua kolom teks, lalu menelusuri halaman mencari yang tampil tanpa di-escape | `BOCOR mentah di HTML: 0` |
| `uji-unggah.py` | Foto/PDF berbahaya: polyglot berisi kode, data selundupan di ujung/komentar/metadata, bom piksel, PDF berisi JavaScript/Launch, plus foto sah (orientasi EXIF, transparansi PNG, foto 12 MP) yang tidak boleh rusak | `RINGKASAN: 23 lulus dari 23` |
| `serang-login.py` | Tebakan password dengan sesi baru tiap percobaan dan dari banyak IP | terkunci mulai tebakan ke-6 (satu IP) dan ke-21 (banyak IP) |

Cara memakai uji XSS "kanari":

```bash
psql -U postgres -d karirku_polinema -f tests/keamanan/kanari-xss.sql   # menanam kanari (ubah data demo!)
python3 tests/keamanan/telusur-xss.py                                      # menelusuri; hasil di xss-hasil.json
# setelah selesai, pulihkan data: psql ... -f database/00-INSTAL-ULANG.sql
```

`serang-login.py` memerlukan dua akun uji (`korban2@uji.test`, `korban3@uji.test`, password
`RahasiaBenar#1`) dan memakai alamat 127.0.0.x berbeda untuk meniru banyak IP (Linux/macOS).

Aturan saat menambah fitur supaya hasil di atas tetap bersih:

- `<script>` inline wajib `<script nonce="<?= cspNonce() ?>">`; jangan memakai `onclick=`, `onchange=`, atau
  `javascript:`. Pakai `data-auto-submit`, `data-href`, `data-konfirmasi`, `data-kembali` (ditangani `app.js`).
- URL dari pengguna yang dijadikan `href` lewat `tautanAman()`, dan divalidasi `urlHttpValid()` saat disimpan
  (bukan `FILTER_VALIDATE_URL` saja).
- Data PHP ke JavaScript lewat `jsonAman()`.
- Pembatas percobaan memakai `batasLaju()` (database), bukan `$_SESSION`.
