#!/bin/bash
# Memastikan berkas pribadi TETAP tertolak untuk yang tidak berhak.
S=/tmp/claude-0/-home-claude/34c7d75d-6ec8-5e75-91f4-7f39653d6878/scratchpad
B=http://127.0.0.1:8000
export PGHOST=/tmp PGUSER=postgres
DB="psql -tAq -d karirku_polinema -c"
GAGAL=0

login() { rm -f "$3"; T=$(curl -s -c "$3" "$B/masuk" | grep -oP 'name="csrf_token" value="\K[^"]+' | head -1)
  curl -s -b "$3" -c "$3" -o /dev/null -d "csrf_token=$T" --data-urlencode "email=$1" --data-urlencode "password=$2" "$B/auth/proses-masuk"; }

harus() { # $1 jar  $2 url  $3 harapan(buka|tolak)  $4 label
  kode=$(curl -s -b "$1" -o /tmp/hasil-berkas -w "%{http_code}" "$B/$2")
  jenis=$(file -b --mime-type /tmp/hasil-berkas)
  if [ "$3" = "buka" ]; then
    if [ "$kode" = "200" ] && [ "$jenis" != "text/html" ]; then echo "  ok     $4 -> terbuka"
    else echo "  GAGAL  $4 -> seharusnya BISA dibuka, tapi http $kode ($jenis)"; GAGAL=$((GAGAL+1)); fi
  else
    # 302 artinya dialihkan ke halaman masuk, itu juga bentuk penolakan
    if [ "$kode" = "403" ] || [ "$kode" = "404" ] || [ "$kode" = "302" ] || [ "$jenis" = "text/html" ]; then echo "  ok     $4 -> ditolak ($kode)"
    else echo "  BOCOR  $4 -> seharusnya DITOLAK, tapi terbuka (http $kode, $jenis)"; GAGAL=$((GAGAL+1)); fi
  fi
}

login mahasiswa@polinema.ac.id mahasiswa123 $S/ab-mhs
login perusahaan@polinema.ac.id perusahaan123 $S/ab-pt
login admin@polinema.ac.id admin123 $S/ab-adm

# berkas milik mahasiswa LAIN yang tidak pernah melamar ke perusahaan demo
LAIN=$($DB "SELECT m.file_ktm FROM mahasiswa m JOIN pengguna p ON p.id=m.pengguna_id
            WHERE p.email<>'mahasiswa@polinema.ac.id' AND m.file_ktm IS NOT NULL
              AND m.id NOT IN (SELECT la.mahasiswa_id FROM lamaran la JOIN lowongan l ON l.id=la.lowongan_id
                               JOIN perusahaan pr ON pr.id=l.perusahaan_id JOIN pengguna pp ON pp.id=pr.pengguna_id
                               WHERE pp.email='perusahaan@polinema.ac.id') LIMIT 1")
NPWP_SENDIRI=$($DB "SELECT dv.file FROM dokumen_verifikasi dv JOIN pengguna p ON p.id=dv.pengguna_id
                     WHERE dv.tipe='npwp' AND p.email='perusahaan@polinema.ac.id' LIMIT 1")
NPWP_LAIN=$($DB "SELECT dv.file FROM dokumen_verifikasi dv JOIN pengguna p ON p.id=dv.pengguna_id
                  WHERE dv.tipe='npwp' AND p.email<>'perusahaan@polinema.ac.id' LIMIT 1")
KTM_SENDIRI=$($DB "SELECT m.file_ktm FROM mahasiswa m JOIN pengguna p ON p.id=m.pengguna_id
                    WHERE p.email='mahasiswa@polinema.ac.id'")
# KTM milik orang yang MEMANG melamar ke perusahaan demo
KTM_PELAMAR=$($DB "SELECT m.file_ktm FROM lamaran la
                     JOIN lowongan l ON l.id=la.lowongan_id
                     JOIN perusahaan pr ON pr.id=l.perusahaan_id
                     JOIN pengguna pp ON pp.id=pr.pengguna_id
                     JOIN mahasiswa m ON m.id=la.mahasiswa_id
                    WHERE pp.email='perusahaan@polinema.ac.id' LIMIT 1")

echo "=== yang BOLEH dibuka ==="
harus $S/ab-mhs  "unduh.php?tipe=ktm&file=$KTM_SENDIRI"               buka  "mahasiswa buka KTM sendiri"
harus $S/ab-pt   "unduh.php?tipe=ktm&file=$KTM_PELAMAR"               buka  "perusahaan buka KTM pelamarnya"
harus $S/ab-pt   "unduh.php?tipe=portofolio&file=contoh-sertifikat.pdf" buka "perusahaan buka sertifikat pelamar"
harus $S/ab-adm  "unduh.php?tipe=npwp&file=$NPWP_LAIN"                buka  "admin buka NPWP perusahaan"
harus /dev/null  "unduh.php?tipe=pamflet&file=contoh-pamflet.jpg"    buka  "tamu buka pamflet (publik)"
harus /dev/null  "unduh.php?tipe=logo&file=contoh-logo.jpg"          buka  "tamu buka logo (publik)"

echo "=== yang HARUS ditolak ==="
harus /dev/null  "unduh.php?tipe=ktm&file=$KTM_SENDIRI"               tolak "tamu buka KTM"
harus /dev/null  "unduh.php?tipe=npwp&file=$NPWP_LAIN"                tolak "tamu buka NPWP"
harus $S/ab-mhs  "unduh.php?tipe=npwp&file=$NPWP_LAIN"                tolak "mahasiswa buka NPWP perusahaan"
harus $S/ab-pt   "unduh.php?tipe=npwp&file=$NPWP_LAIN"                tolak "perusahaan buka NPWP perusahaan lain"
harus $S/ab-pt   "unduh.php?tipe=npwp&file=$NPWP_SENDIRI"             buka  "perusahaan buka NPWP sendiri"
harus $S/ab-mhs  "unduh.php?tipe=ktm&file=$LAIN"                     tolak "mahasiswa buka KTM mahasiswa lain"
harus $S/ab-pt   "unduh.php?tipe=ktm&file=$LAIN"                     tolak "perusahaan buka KTM bukan pelamarnya"
harus $S/ab-mhs  "unduh.php?tipe=ktm&file=../../../etc/passwd"       tolak "percobaan keluar folder (path traversal)"
harus $S/ab-mhs  "unduh.php?tipe=ngawur&file=contoh-ktm.pdf"         tolak "tipe berkas tidak dikenal"

echo
[ "$GAGAL" = 0 ] && echo "SEMUA ATURAN AKSES BENAR." || echo "TOTAL MASALAH: $GAGAL"
