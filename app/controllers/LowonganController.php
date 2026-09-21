<?php
/**
 * Daftar, detail, dan pengelolaan lowongan
 * PIC   : Atha Rasya Farras (Modul Operator dan Career Center)
 * Status: KERANGKA KOSONG, belum diisi logika.
 *
 * Yang harus dikerjakan:
 *   - Daftar lowongan beserta filter jurusan, bidang, lokasi, dan jenis pekerjaan.
 *   - Detail lowongan dan simpan lowongan.
 *   - Pasang lowongan dengan pamflet wajib dan kuota.
 *   - Hitung status aktif, ditutup, atau dinonaktifkan saat data dibaca.
 *   - Halaman pratinjau info loker memakai kode acak dan tag noindex.
 */

class LowonganController extends Controller
{
    public function daftar() {}
    public function detail(int $id) {}
    public function simpan(int $id) {}
    public function formPasang() {}
    public function prosesPasang() {}
    public function tutup(int $id) {}
    public function pratinjau(string $kode) {}
}
