#!/bin/bash
S=/tmp/claude-0/-home-claude/34c7d75d-6ec8-5e75-91f4-7f39653d6878/scratchpad
B=http://127.0.0.1:8000
export PGHOST=/tmp PGUSER=postgres
DB="psql -tAq -d karirku_polinema -c"
GAGAL=0

login() { rm -f "$3"; T=$(curl -s -c "$3" "$B/masuk" | grep -oP 'name="csrf_token" value="\K[^"]+' | head -1)
  curl -s -b "$3" -c "$3" -o /dev/null -d "csrf_token=$T" --data-urlencode "email=$1" --data-urlencode "password=$2" "$B/auth/proses-masuk"; }
tok() { curl -s -b "$1" -c "$1" "$B/$2" | grep -oP 'name="csrf_token" value="\K[^"]+' | head -1; }

uji() { # $1 label  $2 jar  $3 halaman-token  $4 url  $5.. field
  local label=$1 jar=$2 hal=$3 url=$4; shift 4
  T=$(tok "$jar" "$hal")
  args=(-d "csrf_token=$T"); for kv in "$@"; do args+=(--data-urlencode "$kv"); done
  out=$(curl -s -b "$jar" -c "$jar" -w "\nKODE:%{http_code}" -X POST "$B/$url" "${args[@]}")
  kode=$(echo "$out" | tail -1 | cut -d: -f2); isi=$(echo "$out" | head -n -1)
  if echo "$isi" | grep -qiE "Fatal error|Uncaught|SQLSTATE|Check violation|Warning:"; then
    echo "  GAGAL  $label  [$kode]"
    echo "$isi" | strip_tags 2>/dev/null | head -1
    echo "$isi" | sed 's/<[^>]*>//g' | grep -oiE "(Fatal error|Uncaught)[^\\n]{0,130}" | head -1 | sed 's/^/         /'
    GAGAL=$((GAGAL+1))
  else
    echo "  ok     $label  [$kode] ditolak dengan pesan biasa"
  fi
}

login mahasiswa@polinema.ac.id mahasiswa123 $S/jc-mhs
login perusahaan@polinema.ac.id perusahaan123 $S/jc-pt
login admin@polinema.ac.id admin123 $S/jc-adm

echo "=== mahasiswa.status_karier ==="
uji "status kosong"   $S/jc-mhs mahasiswa/profil mahasiswa/status-karier "status_karier="
uji "status asing"    $S/jc-mhs mahasiswa/profil mahasiswa/status-karier "status_karier=ngawur"
echo "=== mahasiswa.karier_tahap_studi ==="
uji "tahap studi asing" $S/jc-mhs mahasiswa/profil mahasiswa/status-karier "status_karier=studi lanjut" "tempat_kerja=ITS" "posisi_kerja=Magister" "karier_tahap_studi=ngawur"
echo "=== mahasiswa.ipk (0..4) ==="
uji "ipk 9.9"         $S/jc-mhs mahasiswa/profil mahasiswa/simpan-profil "aksi=data_diri" "nama=Budi Santoso" "no_whatsapp=081234567890" "ipk=9.9" "domisili=Malang" "tentang=x"
uji "ipk minus"       $S/jc-mhs mahasiswa/profil mahasiswa/simpan-profil "aksi=data_diri" "nama=Budi Santoso" "no_whatsapp=081234567890" "ipk=-3" "domisili=Malang" "tentang=x"
echo "=== profil_item.tipe ==="
uji "tipe asing"      $S/jc-mhs mahasiswa/profil mahasiswa/simpan-profil "aksi=item_tambah" "tipe=ngawur" "judul=Uji" "instansi=X"
echo "=== profil_item: selesai < mulai ==="
uji "tanggal terbalik" $S/jc-mhs mahasiswa/profil mahasiswa/simpan-profil "aksi=item_tambah" "tipe=pendidikan" "judul=Uji" "instansi=X" "mulai=2026-01-01" "selesai=2020-01-01"
echo "=== lamaran.jenis_cv ==="
LOW=$($DB "SELECT l.id FROM lowongan l JOIN lowongan_jurusan lj ON lj.lowongan_id=l.id JOIN jurusan j ON j.id=lj.jurusan_id WHERE l.status='aktif' AND j.nama='Teknologi Informasi' AND l.id NOT IN (SELECT lowongan_id FROM lamaran la JOIN mahasiswa m ON m.id=la.mahasiswa_id JOIN pengguna p ON p.id=m.pengguna_id WHERE p.email='mahasiswa@polinema.ac.id') ORDER BY l.id LIMIT 1")
uji "jenis_cv asing"  $S/jc-mhs "lamaran/kirim/$LOW" "lamaran/kirim/$LOW" "jenis_cv=ngawur" "catatan_pelamar=x"
echo "=== interview.mode ==="
PEL=$($DB "SELECT la.id FROM lamaran la JOIN lowongan l ON l.id=la.lowongan_id JOIN perusahaan pr ON pr.id=l.perusahaan_id JOIN pengguna p ON p.id=pr.pengguna_id WHERE p.email='perusahaan@polinema.ac.id' AND la.status<>'diterima' ORDER BY la.id LIMIT 1")
uji "mode asing"      $S/jc-pt "lamaran/detail-pelamar/$PEL" "lamaran/ubah-status/$PEL" "aksi=jadwal_interview" "mode=ngawur" "tanggal=2026-11-10" "jam=09:00" "lokasi_tautan=https://x.test/a"
uji "aksi asing"      $S/jc-pt "lamaran/detail-pelamar/$PEL" "lamaran/ubah-status/$PEL" "aksi=ngawur"
echo "=== lowongan.kuota (>=1) dan status ==="
uji "kuota 0"         $S/jc-pt perusahaan/profil lowongan/proses-pasang "posisi=Uji" "bidang_id=1" "jenis_pekerjaan=Magang" "sistem_kerja=WFO" "lokasi=Malang" "kuota=0" "batas_lamaran=2026-12-01" "deskripsi=x" "kualifikasi=y"
uji "kuota minus"     $S/jc-pt perusahaan/profil lowongan/proses-pasang "posisi=Uji" "bidang_id=1" "jenis_pekerjaan=Magang" "sistem_kerja=WFO" "lokasi=Malang" "kuota=-5" "batas_lamaran=2026-12-01" "deskripsi=x" "kualifikasi=y"
echo "=== verifikasi_akun.keputusan ==="
CAL=$($DB "SELECT id FROM pengguna WHERE status_akun='menunggu' ORDER BY id LIMIT 1")
uji "keputusan asing" $S/jc-adm "admin/detail-pendaftar/$CAL" "admin/putuskan/$CAL" "keputusan=ngawur"
uji "tolak tanpa catatan" $S/jc-adm "admin/detail-pendaftar/$CAL" "admin/putuskan/$CAL" "keputusan=ditolak" "catatan="

echo
[ "$GAGAL" = 0 ] && echo "SEMUA NILAI SALAH DITOLAK DENGAN PESAN BIASA." || echo "TOTAL FATAL ERROR: $GAGAL"
