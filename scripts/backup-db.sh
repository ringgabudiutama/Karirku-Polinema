#!/usr/bin/env bash
# =====================================================================
# KarirKu Polinema · Backup database + berkas unggahan
#   HARIAN   : setiap hari, simpan 14 terakhir
#   MINGGUAN : setiap hari Minggu, simpan 8 terakhir
#   BULANAN  : setiap tanggal 1, simpan 24 terakhir
#
# Cukup satu jadwal cron harian; skrip sendiri memutuskan apakah hari ini juga
# jatah mingguan/bulanan. Contoh: scripts/karirku-backup.cron
#
# Yang dicadangkan:
#   1. database  -> karirku_polinema_<waktu>.dump   (pg_dump format custom)
#   2. berkas    -> uploads_<waktu>.tar.gz          (KTM, ijazah, CV, pamflet)
#   3. sidik jari-> SHA256_<waktu>.txt              (untuk memeriksa berkas tidak rusak)
# Database tanpa berkas unggahan TIDAK cukup: tabel hanya menyimpan nama berkas.
#
# Pemakaian:
#   backup-db.sh                 # otomatis (harian, + mingguan bila Minggu, + bulanan bila tgl 1)
#   backup-db.sh harian|mingguan|bulanan   # paksa satu jenis
#
# Pengaturan (variabel lingkungan atau /etc/karirku/backup.env atau scripts/backup.env):
#   BACKUP_DIR=/var/backups/karirku   lokasi simpan (di DISK/SERVER LAIN lebih baik)
#   PGHOST PGPORT PGUSER PGDATABASE   koneksi standar PostgreSQL (password lewat ~/.pgpass,
#                                     JANGAN ditulis di skrip). Tanpa PGUSER: pakai akun OS
#                                     yang menjalankan cron (cocok bila dijalankan sebagai postgres).
#   UPLOAD_DIR=<proyek>/storage/uploads
#   KEEP_HARIAN=14 KEEP_MINGGUAN=8 KEEP_BULANAN=24
#   BACKUP_GPG_PENERIMA=<email/ID kunci>   bila diisi, hasil dienkripsi (disarankan; berisi data pribadi)
# =====================================================================
set -Eeuo pipefail
umask 077

SKRIP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROYEK_DIR="$(dirname "$SKRIP_DIR")"
# shellcheck disable=SC1091
[ -f /etc/karirku/backup.env ] && source /etc/karirku/backup.env
# shellcheck disable=SC1091
[ -f "$SKRIP_DIR/backup.env" ] && source "$SKRIP_DIR/backup.env"

BACKUP_DIR="${BACKUP_DIR:-/var/backups/karirku}"
export PGDATABASE="${PGDATABASE:-${DB_NAME:-karirku_polinema}}"
UPLOAD_DIR="${UPLOAD_DIR:-$PROYEK_DIR/storage/uploads}"
KEEP_HARIAN="${KEEP_HARIAN:-14}"
KEEP_MINGGUAN="${KEEP_MINGGUAN:-8}"
KEEP_BULANAN="${KEEP_BULANAN:-24}"
GPG_PENERIMA="${BACKUP_GPG_PENERIMA:-}"
MODE="${1:-otomatis}"

# BACKUP_TANGGAL (YYYY-MM-DD) hanya untuk pengujian jadwal mingguan/bulanan.
TANGGAL="${BACKUP_TANGGAL:-$(date +%F)}"
HARI_KE="$(date -d "$TANGGAL" +%u)"          # 7 = Minggu
TGL_BULAN="${TANGGAL:8:2}"
STEMPEL="${TANGGAL}_$(date +%H%M)"

mkdir -p -m 700 "$BACKUP_DIR"/{harian,mingguan,bulanan}
LOG="$BACKUP_DIR/backup.log"

catat() { printf '%s  %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG" >&2; }

gagal() {
  catat "GAGAL pada baris $1 (kode $2). Cadangan hari ini TIDAK lengkap."
  echo "GAGAL $(date '+%F %T')" > "$BACKUP_DIR/STATUS"
  rm -f "$BACKUP_DIR"/harian/*.tmp
  exit 1
}
trap 'gagal $LINENO $?' ERR

# Cegah dua backup berjalan bersamaan.
exec 9>"$BACKUP_DIR/.kunci"
flock -n 9 || { catat "Backup lain masih berjalan; dilewati."; exit 0; }

command -v pg_dump >/dev/null    || { catat "pg_dump tidak ditemukan (pasang postgresql-client)."; exit 1; }
command -v pg_restore >/dev/null || { catat "pg_restore tidak ditemukan."; exit 1; }

case "$MODE" in
  otomatis|harian|mingguan|bulanan) ;;
  *) echo "Pemakaian: $0 [otomatis|harian|mingguan|bulanan]" >&2; exit 2 ;;
esac

# --- 1. Buat cadangan lengkap di folder harian ------------------------
buat_cadangan() {
  local folder="$BACKUP_DIR/harian"
  local dump="$folder/${PGDATABASE}_${STEMPEL}.dump"
  local arsip="$folder/uploads_${STEMPEL}.tar.gz"
  local sidik="$folder/SHA256_${STEMPEL}.txt"

  catat "Mulai backup database '$PGDATABASE' ..."
  pg_dump --format=custom --compress=6 --no-owner --no-privileges --file="$dump.tmp"
  pg_restore --list "$dump.tmp" > /dev/null          # pastikan berkas bisa dibaca
  mv "$dump.tmp" "$dump"

  if [ -d "$UPLOAD_DIR" ]; then
    tar -C "$(dirname "$UPLOAD_DIR")" -czf "$arsip.tmp" "$(basename "$UPLOAD_DIR")"
    tar -tzf "$arsip.tmp" > /dev/null
    mv "$arsip.tmp" "$arsip"
  else
    catat "PERINGATAN: folder berkas unggahan '$UPLOAD_DIR' tidak ada; hanya database yang dicadangkan."
  fi

  if [ -n "$GPG_PENERIMA" ]; then
    command -v gpg >/dev/null || { catat "BACKUP_GPG_PENERIMA diisi tetapi gpg tidak ada."; exit 1; }
    local f
    for f in "$dump" "$arsip"; do
      [ -f "$f" ] || continue
      gpg --batch --yes --trust-model always --encrypt --recipient "$GPG_PENERIMA" --output "$f.gpg" "$f"
      rm -f "$f"
    done
  fi

  ( cd "$folder" && sha256sum ./*"_${STEMPEL}".* 2>/dev/null | grep -v "SHA256_" > "$sidik" )
  catat "Selesai: $(du -ch "$folder"/*"_${STEMPEL}".* 2>/dev/null | tail -1 | cut -f1) tersimpan ($STEMPEL)."
}

# --- 2. Salin ke mingguan/bulanan (hard link: tidak memakan ruang dobel) ---
salin_ke() {
  local tujuan="$BACKUP_DIR/$1" f
  for f in "$BACKUP_DIR"/harian/*_"${STEMPEL}".*; do
    [ -e "$f" ] || continue
    ln -f "$f" "$tujuan/" 2>/dev/null || cp -p "$f" "$tujuan/"
  done
  catat "Disalin ke $1."
}

# --- 3. Pangkas: simpan N stempel terbaru per folder ------------------
pangkas() {
  local folder="$BACKUP_DIR/$1" simpan="$2" stempel
  mapfile -t basi < <(
    find "$folder" -maxdepth 1 -type f -name "${PGDATABASE}_*.dump*" -printf '%f\n' \
      | sed -E "s/^${PGDATABASE}_([0-9-]+_[0-9]+)\.dump.*/\1/" | sort -ru | tail -n +"$((simpan + 1))"
  )
  for stempel in "${basi[@]:-}"; do
    [ -n "$stempel" ] || continue
    find "$folder" -maxdepth 1 -type f -name "*_${stempel}.*" -delete
    catat "Dihapus dari $1 (melewati batas $simpan): $stempel"
  done
}

# --- Jalankan ----------------------------------------------------------
buat_cadangan
if [ "$MODE" = "mingguan" ] || { [ "$MODE" = "otomatis" ] && [ "$HARI_KE" = "7" ]; }; then salin_ke mingguan; fi
if [ "$MODE" = "bulanan" ]  || { [ "$MODE" = "otomatis" ] && [ "$TGL_BULAN" = "01" ]; }; then salin_ke bulanan; fi
pangkas harian   "$KEEP_HARIAN"
pangkas mingguan "$KEEP_MINGGUAN"
pangkas bulanan  "$KEEP_BULANAN"

echo "OK $(date '+%F %T') $STEMPEL" > "$BACKUP_DIR/STATUS"
catat "Backup OK. Ingat: salin juga ke tempat LAIN (aturan 3-2-1), dan uji pulih berkala (restore-db.sh --uji)."
