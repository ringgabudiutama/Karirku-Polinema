#!/bin/bash
# Alamat yang salah ketik atau dikarang tidak boleh memunculkan halaman
# fatal error PHP. Harus 404 atau 302 yang rapi.
B=http://127.0.0.1:8000
GAGAL=0
ALAMAT=(
  "lamaran/batalkan" "lamaran/batalkan/" "lamaran/batalkan/abc" "lamaran/batalkan/9e9"
  "admin/profil-mahasiswa" "admin/profil-mahasiswa/xyz" "admin/putuskan" "admin/putuskan/abc"
  "lowongan/detail" "lowongan/detail/abc" "lowongan/detail/0" "lowongan/simpan/abc"
  "notifikasi/tandai-dibaca" "notifikasi/tandai-dibaca/--" "kirim-loker/kirim" "kirim-loker/kirim/1"
  "auth/reset-sandi" "info-loker/tidakada" "info-loker/" "mahasiswa/profil/1/2/3"
  "controller/tidakada" "admin" "perusahaan" "mahasiswa" "halaman/ngawur/sekali"
  "lamaran/detail-pelamar/-5" "admin/nonaktifkan-pengguna/999999"
)
for u in "${ALAMAT[@]}"; do
  out=$(curl -s -w "\nKODE:%{http_code}" "$B/$u")
  kode=$(echo "$out" | tail -1 | cut -d: -f2)
  if echo "$out" | grep -qiE "fatal error|uncaught|TypeError|ArgumentCountError|ValueError|Warning:|Notice:"; then
    echo "  GAGAL  /$u  [$kode]"
    echo "$out" | sed 's/<[^>]*>//g' | grep -oiE "(fatal error|uncaught|TypeError|ArgumentCountError)[^\\n]{0,110}" | head -1 | sed 's/^/         /'
    GAGAL=$((GAGAL+1))
  else
    echo "  ok     /$u  [$kode]"
  fi
done
echo
[ "$GAGAL" = 0 ] && echo "SEMUA ALAMAT CACAT DITANGANI RAPI." || echo "TOTAL FATAL ERROR: $GAGAL"
