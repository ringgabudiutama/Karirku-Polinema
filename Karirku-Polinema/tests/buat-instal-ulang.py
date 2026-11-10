#!/usr/bin/env python3
"""Menyusun database/00-INSTAL-ULANG.sql dari 01..07. Jalankan ulang setiap kali 01..04 diubah."""
import os
D = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'database')
top = open(os.path.join(D, '00-INSTAL-ULANG.sql')).read().split('-- #####', 1)[0]
parts = []
for f in ['01-schema.sql', '02-seed.sql', '03-migrasi-revisi.sql', '04-revisi-dosen.sql', '06-revisi-profil.sql', '05-data-dummy.sql', '07-peningkatan-materi-dosen.sql']:
    parts.append(f"\n-- #####################################################################\n-- ##### Isi dari {f}\n-- #####################################################################\n" + open(os.path.join(D, f)).read())
open(os.path.join(D, '00-INSTAL-ULANG.sql'), 'w').write(top.rstrip('\n') + '\n' + ''.join(parts))
print('00-INSTAL-ULANG.sql diperbarui')
