#!/usr/bin/env bash
# =====================================================================
# KarirKu Polinema · Pulihkan / uji backup
#
#   restore-db.sh --uji [BERKAS.dump]    UJI PULIH: pulihkan ke database sementara,
#                                        periksa isinya, lalu hapus lagi. Aman, tidak
#                                        menyentuh database asli. Jalankan tiap minggu.
#                                        Tanpa BERKAS: memakai backup harian terbaru.
#   restore-db.sh BERKAS.dump NAMA_DB    pulihkan ke database BARU bernama NAMA_DB.
#   restore-db.sh --timpa BERKAS.dump    GANTI database produksi dengan isi backup
#                                        (hentikan aplikasi dulu; harus mengetik YA).
#
# BERKAS bisa .dump atau .dump.gpg (dekripsi memakai kunci pribadi di server ini).
# Pengaturan koneksi sama dengan backup-db.sh (PGHOST, PGUSER, PGDATABASE, ...).
#
# Setelah memulihkan ke produksi:
#   1. psql -d karirku_polinema -v app_pass='...' -f database/08-hardening-produksi.sql
#      (backup dibuat tanpa hak akses, jadi hak karirku_app dipasang ulang)
#   2. pulihkan berkas unggahan:  tar -xzf uploads_<waktu>.tar.gz -C <folder storage>
# =====================================================================
set -Eeuo pipefail
umask 077

SKRIP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
[ -f /etc/karirku/backup.env ] && source /etc/karirku/backup.env
# shellcheck disable=SC1091
[ -f "$SKRIP_DIR/backup.env" ] && source "$SKRIP_DIR/backup.env"

BACKUP_DIR="${BACKUP_DIR:-/var/backups/karirku}"
DB_ASLI="${PGDATABASE:-${DB_NAME:-karirku_polinema}}"
unset PGDATABASE                      # perintah di bawah menyebut database secara eksplisit
ADMIN_DB="${RESTORE_ADMIN_DB:-postgres}"
TMP=""

catat() { printf '%s  %s\n' "$(date '+%F %T')" "$*" >&2; }
selesai() { [ -n "$TMP" ] && rm -rf "$TMP"; }
trap selesai EXIT

pakai() { sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 2; }

MODE=""; BERKAS=""; DB_TUJUAN=""
case "${1:-}" in
  --uji)   MODE=uji;   BERKAS="${2:-}" ;;
  --timpa) MODE=timpa; BERKAS="${2:-}" ;;
  ""|-h|--help) pakai ;;
  *)       MODE=baru;  BERKAS="$1"; DB_TUJUAN="${2:-}" ;;
esac

if [ "$MODE" = "uji" ] && [ -z "$BERKAS" ]; then
  BERKAS="$(find "$BACKUP_DIR/harian" -maxdepth 1 -type f -name "${DB_ASLI}_*.dump*" 2>/dev/null | sort -r | head -1)"
  [ -n "$BERKAS" ] || { catat "Tidak ada backup harian di $BACKUP_DIR/harian."; exit 1; }
fi
[ -f "$BERKAS" ] || { catat "Berkas tidak ditemukan: '$BERKAS'"; pakai; }
[ "$MODE" != "baru" ] || [ -n "$DB_TUJUAN" ] || pakai

TMP="$(mktemp -d)"

# --- Periksa sidik jari (bila ada) dan dekripsi (bila .gpg) -------------
FOLDER="$(dirname "$BERKAS")"; NAMA="$(basename "$BERKAS")"
STEMPEL="$(printf '%s' "$NAMA" | sed -E 's/^.*_([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4})\.dump.*/\1/')"
SIDIK="$FOLDER/SHA256_${STEMPEL}.txt"
if [ -f "$SIDIK" ]; then
  if ( cd "$FOLDER" && grep -F "$NAMA" "$SIDIK" | sha256sum -c --quiet - ); then
    catat "Sidik jari SHA256 cocok: berkas utuh."
  else
    catat "SIDIK JARI TIDAK COCOK: berkas rusak atau diubah. Dibatalkan."; exit 1
  fi
else
  catat "PERINGATAN: berkas sidik jari tidak ada; keutuhan tidak bisa diperiksa."
fi

SUMBER="$BERKAS"
if [[ "$BERKAS" == *.gpg ]]; then
  SUMBER="$TMP/pulih.dump"
  gpg --batch --yes --decrypt --output "$SUMBER" "$BERKAS"
fi
pg_restore --list "$SUMBER" > /dev/null || { catat "Berkas bukan backup PostgreSQL yang sah."; exit 1; }

sql() { psql -X -q -At -v ON_ERROR_STOP=1 "$@"; }
ada_db() { [ "$(sql -d "$ADMIN_DB" -c "SELECT 1 FROM pg_database WHERE datname = '$1'")" = "1" ]; }

pulihkan_ke() {   # $1 = nama database yang SUDAH ada dan kosong
  pg_restore --no-owner --no-privileges --exit-on-error --dbname="$1" "$SUMBER"
}

ringkasan() {     # $1 = database
  sql -d "$1" -c "
    SELECT 'pengguna='         || (SELECT count(*) FROM pengguna)         || '  lowongan='     || (SELECT count(*) FROM lowongan)
        || '  lamaran='        || (SELECT count(*) FROM lamaran)          || '  riwayat='      || (SELECT count(*) FROM riwayat_lamaran)
        || '  trigger='        || (SELECT count(*) FROM pg_trigger WHERE NOT tgisinternal)
        || '  view_rekap='     || (to_regclass('public.v_rekap_lamaran') IS NOT NULL)
        || '  lowongan_tanpa_vektor=' || (SELECT count(*) FROM lowongan WHERE search_vector IS NULL);"
}

case "$MODE" in
  uji)
    TARGET="karirku_ujipulih_$(date +%H%M%S)"
    catat "UJI PULIH: '$NAMA' -> database sementara '$TARGET'"
    sql -d "$ADMIN_DB" -c "CREATE DATABASE \"$TARGET\""
    trap 'sql -d "$ADMIN_DB" -c "DROP DATABASE IF EXISTS \"$TARGET\"" >/dev/null 2>&1 || true; selesai' EXIT
    pulihkan_ke "$TARGET"
    HASIL="$(ringkasan "$TARGET")"
    catat "Isi hasil pulih : $HASIL"
    if ada_db "$DB_ASLI"; then catat "Isi database asli: $(ringkasan "$DB_ASLI")  (boleh beda: data terus bertambah)"; fi
    case "$HASIL" in
      *pengguna=0*|*lowongan=0*) catat "UJI GAGAL: tabel inti kosong."; exit 1 ;;
      *view_rekap=true*lowongan_tanpa_vektor=0*) catat "UJI PULIH BERHASIL. Database sementara dihapus." ;;
      *) catat "UJI GAGAL: struktur tidak lengkap (view/trigger/vektor pencarian)."; exit 1 ;;
    esac
    ;;
  baru)
    ada_db "$DB_TUJUAN" && { catat "Database '$DB_TUJUAN' sudah ada. Pilih nama lain."; exit 1; }
    sql -d "$ADMIN_DB" -c "CREATE DATABASE \"$DB_TUJUAN\""
    pulihkan_ke "$DB_TUJUAN"
    catat "Dipulihkan ke '$DB_TUJUAN': $(ringkasan "$DB_TUJUAN")"
    catat "Langkah berikut: jalankan database/08-hardening-produksi.sql pada database ini, lalu arahkan DB_NAME aplikasi."
    ;;
  timpa)
    catat "PERINGATAN: database '$DB_ASLI' akan DIHAPUS dan diganti isi backup '$NAMA'."
    catat "Pastikan aplikasi sudah dihentikan, dan sudah punya cadangan terbaru."
    read -r -p "Ketik YA (huruf besar) untuk melanjutkan: " JAWAB
    [ "$JAWAB" = "YA" ] || { catat "Dibatalkan."; exit 1; }
    AMAN="$BACKUP_DIR/sebelum-timpa_$(date +%F_%H%M%S).dump"
    ada_db "$DB_ASLI" && { catat "Menyimpan salinan pengaman: $AMAN"; pg_dump --format=custom --no-owner --no-privileges --dbname="$DB_ASLI" --file="$AMAN"; }
    sql -d "$ADMIN_DB" -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_ASLI' AND pid <> pg_backend_pid()" > /dev/null
    sql -d "$ADMIN_DB" -c "DROP DATABASE IF EXISTS \"$DB_ASLI\""
    sql -d "$ADMIN_DB" -c "CREATE DATABASE \"$DB_ASLI\""
    pulihkan_ke "$DB_ASLI"
    catat "Dipulihkan: $(ringkasan "$DB_ASLI")"
    catat "WAJIB: jalankan database/08-hardening-produksi.sql lagi, lalu pulihkan berkas unggahan dan jalankan aplikasi."
    ;;
esac
