<?php
/**
 * Pipeline lamaran
 * PIC   : Muhamad Nafi' Hanif (Modul Mahasiswa dan Alumni)
 * Status: KERANGKA KOSONG, belum diisi logika.
 *
 * Yang harus dikerjakan:
 *   - Kirim lamaran beserta pilihan CV, KTM, dan surat pengantar.
 *   - Simpan snapshot profil saat melamar.
 *   - Batalkan lamaran selama status masih diajukan.
 *   - Ubah status oleh perusahaan dan simpan jadwal interview.
 *   - Transaksi pembaruan otomatis saat pelamar diterima, lihat bagian bawah database/01-schema.sql.
 */

class LamaranController extends Controller
{
    public function kirim(int $lowonganId) {}
    public function lamaranSaya() {}
    public function batalkan(int $id) {}
    public function detailPelamar(int $id) {}
    public function ubahStatus(int $id) {}
    public function terima(int $id) {}
}
