-- =====================================================================
-- KarirKu Polinema · Logo perusahaan mitra (data demo) gaya logo datar
-- Mengganti logo demo lama (dummy-emblem-*, contoh-*) dengan logo mitra-XX.png
-- di storage/demo-uploads/logo. Logo yang diunggah perusahaan sendiri TIDAK diubah.
-- AMAN DIJALANKAN BERULANG. Dijalankan otomatis sekali oleh aplikasi.
-- =====================================================================
BEGIN;
UPDATE perusahaan SET logo = 'mitra-01.png' WHERE nama_perusahaan = 'PT Nusantara Digital'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-02.png' WHERE nama_perusahaan = 'PT Astra Otoparts'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-03.png' WHERE nama_perusahaan = 'PT Telkom Indonesia'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-04.png' WHERE nama_perusahaan = 'PT Wilmar Nabati Indonesia'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-05.png' WHERE nama_perusahaan = 'PT Gudang Garam Tbk'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-06.png' WHERE nama_perusahaan = 'PT Pindad'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-07.png' WHERE nama_perusahaan = 'PT Semen Indonesia'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-08.png' WHERE nama_perusahaan = 'PT Bank Mandiri Tbk'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-09.png' WHERE nama_perusahaan = 'PT Pertamina Patra Niaga'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-10.png' WHERE nama_perusahaan = 'PT Nestle Indonesia'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-11.png' WHERE nama_perusahaan = 'PT Barata Indonesia'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-12.png' WHERE nama_perusahaan = 'PT Nusantara Teknologi Cerdas'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-13.png' WHERE nama_perusahaan = 'PT Adhi Karya Tbk'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-14.png' WHERE nama_perusahaan = 'PT Sinergi Data Nusantara'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-15.png' WHERE nama_perusahaan = 'PT Mitra Arsip Nusantara'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-16.png' WHERE nama_perusahaan = 'PT Energi Listrik Mandiri'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-17.png' WHERE nama_perusahaan = 'PT Mitra Sejahtera Abadi'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-18.png' WHERE nama_perusahaan = 'PT Karya Abadi Teknik'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-19.png' WHERE nama_perusahaan = 'PT Ringga Karya Digital'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-20.png' WHERE nama_perusahaan = 'PT Artha Digital Indonesia'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-21.png' WHERE nama_perusahaan = 'PT Daya Kreasi Raya'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-22.png' WHERE nama_perusahaan = 'PT Bina Abadi Raya'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-23.png' WHERE nama_perusahaan = 'PT Artha Solusi Jaya'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-24.png' WHERE nama_perusahaan = 'PT Prima Industri Jaya'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-25.png' WHERE nama_perusahaan = 'PT Sentosa Digital Raya'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-26.png' WHERE nama_perusahaan = 'PT Nusa Konstruksi Jaya'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-27.png' WHERE nama_perusahaan = 'PT Nusa Utama Indonesia'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-28.png' WHERE nama_perusahaan = 'PT Artha Data Sejahtera'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
UPDATE perusahaan SET logo = 'mitra-29.png' WHERE nama_perusahaan = 'PT Sentosa Solusi Sejahtera'
  AND (logo IS NULL OR logo = '' OR logo LIKE 'contoh-%' OR logo LIKE 'dummy-emblem-%' OR logo LIKE 'dummy-logo-%');
INSERT INTO pengaturan (kunci, nilai) VALUES ('data_demo_11', 'ok (dari SQL)') ON CONFLICT (kunci) DO NOTHING;
COMMIT;
