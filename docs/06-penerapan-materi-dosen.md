# Penerapan materi dosen (Advanced Database, PostgreSQL) pada KarirKu

Dosen meminta database memakai materi kuliah yang **penting dan berguna** saja. Dokumen
ini menunjukkan bab mana yang dipakai, di file mana, dan cara membuktikannya saat
presentasi. Semua perubahan ada di `database/07-peningkatan-materi-dosen.sql`
(dan `08-hardening-produksi.sql` untuk akun terbatas).

## Ringkasan

| Bab | Topik | Sudah ada sejak awal | Ditambahkan sekarang |
|---|---|---|---|
| 2 | SQL Dasar | tabel, PK/FK, `CHECK`, `UNIQUE`, `SERIAL` | akun database terbatas, `GRANT`/`REVOKE`, bukan superuser (`08`) |
| 3 | SQL Lanjut | `JOIN`, `GROUP BY`, `EXISTS`, `FILTER` | **View** `v_rekap_lamaran` |
| 5 | Index & Optimasi | 8 index (komposit, ekspresi JSONB) | **14 index kolom FK**, index komposit `(lowongan_id, status)`, index urutan `(tanggal_lamar DESC, id DESC)` untuk rekap admin, bukti `EXPLAIN ANALYZE` |
| 6 | Pemrograman 1 | tidak ada | **Function** PL/pgSQL + `RAISE EXCEPTION` + penanganan galat |
| 7 | Pemrograman 2 | tidak ada | **5 trigger** (pemelihara vektor, penjaga status, arsip riwayat) |
| 8 | Transaction & Concurrency | `BEGIN/COMMIT`, `FOR UPDATE`, advisory lock | (sudah cukup, tidak diubah) |
| 10 | Full-Text Search & JSONB | JSONB (`snapshot_profil`, `detail`) | **FTS** `tsvector` + GIN + `setweight` + `ts_rank` |
| 11 | Backup-Restore & Migrasi | `00-INSTAL-ULANG.sql`, migrasi idempoten | **Backup harian/mingguan/bulanan**, uji pulih (`scripts/`) |

Sengaja **tidak** dipakai karena tidak berguna untuk proyek ini: Bab 1 (hanya pengenalan dan
instalasi), `pgloader` (tidak ada migrasi dari MySQL), CTE (tidak ada kueri yang butuh),
dan index GIN pada JSONB (tidak ada kueri `@>`/`->>` pada kolom itu, jadi index tidak
akan terpakai).

## Bab 3: View

`v_rekap_lamaran` menyatukan join 6 tabel (lamaran, lowongan, perusahaan, mahasiswa, prodi,
jurusan). Dipakai oleh `Lamaran::rekapAdmin`, `ringkasanRekap`, dan `rekapPerPerusahaan`,
yang sebelumnya menyalin join yang sama. Hasilnya diverifikasi identik: 22 dari 22
keluaran rekap sama persis sebelum dan sesudah.

```sql
SELECT status, count(*) FROM v_rekap_lamaran GROUP BY status;
```

## Bab 5: Index

PostgreSQL tidak membuat index otomatis untuk foreign key. Tanpa index, `JOIN` dan
`ON DELETE CASCADE` membaca seluruh tabel anak. Trade-off (materi bab ini): tiap index
menambah biaya tulis, jadi hanya dipasang pada tabel yang terus bertambah; 4 kolom di
tabel kecil sengaja dilewati (tertulis di komentar `07`). Index lama `idx_lamaran_lowongan`
dihapus karena sudah tercakup index komposit baru (index tumpang tindih memperlambat tulis).

Index `idx_lamaran_tanggal` mempercepat halaman rekap admin (selalu urut terbaru, tampil 10 baris):
92 ms menjadi 0,8 ms pada 60 ribu lamaran. Tanpa index, PostgreSQL menggabung dan mengurutkan semua lamaran dulu.

**Demo bukti** (aman, memakai tabel sementara): `psql -d karirku_polinema -f database/demo-bukti-kecepatan.sql`

| Kueri | Tanpa | Dengan |
|---|---|---|
| Cari kata di 100 ribu lowongan: `ILIKE '%kata%'` vs FTS + GIN | 121 ms (Seq Scan) | 0,04 ms (Bitmap Index Scan) |
| Riwayat 1 lamaran di 600 ribu baris: FK tanpa vs dengan index | 40,8 ms (Seq Scan) | 0,05 ms (Index Scan) |

(Diukur di sandbox PostgreSQL 16; angka di komputermu akan berbeda, polanya sama.)

## Bab 6 dan 7: Function dan Trigger

| Trigger / function | Fungsi | Mengapa di database |
|---|---|---|
| `trg_lowongan_vektor` + `fn_lowongan_vektor` | vektor pencarian selalu mengikuti isi lowongan | tidak mungkin lupa memperbarui dari PHP |
| `trg_perusahaan_nama` | perusahaan ganti nama, vektor lowongannya ikut | idem |
| `trg_lamaran_jaga_status` | status final (`diterima`, `ditolak`, `dibatalkan`) tidak bisa diubah; status tidak bisa mundur | lapis kedua selain aturan PHP; tetap berlaku bila ada bug atau SQL injection |
| `trg_lamaran_pastikan_riwayat` | setiap status wajib punya catatan riwayat | *constraint trigger* ditunda sampai `COMMIT`: tidak pernah menggandakan catatan dari aplikasi |
| `trg_riwayat_lamaran_tetap` | riwayat tidak bisa diubah (arsip) | mencegah pemalsuan jejak |
| `fn_bersihkan_data_lama()` | hapus log email, notifikasi terbaca, token kedaluwarsa | data tidak menumpuk selama bertahun-tahun; menolak batas < 30 hari |

Demo penjaga status (ubah `5` ke id lamaran berstatus `diterima`):

```sql
BEGIN;
UPDATE lamaran SET status = 'diajukan' WHERE id = 5;
-- ERROR: Lamaran 5 sudah berstatus final (diterima) dan tidak boleh diubah menjadi diajukan.
ROLLBACK;
```

Sembilan skenario diuji (final, mundur, interview dijadwal ulang, riwayat otomatis,
tidak ganda, arsip, hapus akun, hapus lamaran, tambah-lalu-hapus dalam satu transaksi);
semuanya berperilaku sesuai rancangan.

## Bab 10: Full-Text Search

Pencarian lowongan memakai `lowongan.search_vector` dan index GIN. Bobot: posisi (A),
perusahaan dan skill (B), lokasi (C), deskripsi dan kualifikasi (D). Hasil diurutkan dengan
`ts_rank` bila pengguna tidak memilih "Deadline terdekat". Setiap kata dicocokkan sebagai
awalan ("back" menemukan "backend"); kata dibersihkan menjadi huruf/angka sehingga operator
pencarian tidak bisa disisipkan pengguna.

Konfigurasi teks `karirku_cari` menyalin `indonesian` bila tersedia (PostgreSQL 16 ada),
kalau tidak menyalin `simple`.

Perubahan perilaku yang perlu diketahui: pencarian kini mencakup skill, lokasi, dan
deskripsi (bukan hanya posisi dan nama perusahaan), sehingga hasil bertambah. Pada data
demo tidak ada hasil lama yang hilang ("laravel" 0 jadi 2 hasil, "Jakarta" 0 jadi 27).
Kata yang hanya berupa kata umum bahasa Indonesia (mis. "yang") diabaikan oleh FTS.
Pencarian lowongan di halaman admin ikut memakai FTS. Pencarian yang mencari nama orang,
nama perusahaan, atau NIM (rekap lamaran, daftar pengguna, mahasiswa, perusahaan) tetap
`ILIKE` karena stemming tidak cocok untuk nama.

## Bab 11: Backup, Restore, Migrasi

Lihat `docs/05-panduan-hosting-aman.md` bagian 6. Ringkas: `scripts/backup-db.sh`
(harian, mingguan tiap Minggu, bulanan tiap tanggal 1; database + berkas unggahan;
terenkripsi opsional; sidik jari SHA256) dan `scripts/restore-db.sh --uji` (pulihkan ke
database sementara, periksa, hapus). Migrasi `03`, `04`, `06`, `07` aman diulang
(`IF NOT EXISTS`, `CREATE OR REPLACE`, `DROP ... IF EXISTS`) dan dijalankan otomatis
oleh aplikasi untuk database lama (dimatikan di produksi lewat `DB_MIGRASI_OTOMATIS=0`).
