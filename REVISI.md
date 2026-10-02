# Daftar Revisi yang Sudah Dikerjakan

Semua poin di bawah sudah diuji dengan menjalankan aplikasinya, bukan hanya
dibaca ulang. Database dibangun ulang dari nol memakai `01-schema.sql` dan
`02-seed.sql`, lalu seluruh halaman untuk tiga peran dibuka satu per satu.

---

## Mahasiswa dan alumni

**1. Tombol tambah skill**

Dulu tab Skills kosong dan tidak ada cara menambah apa pun, karena tabel induk
`skill` memang belum pernah diisi. Sekarang ada 20 skill bawaan, ditambah
formulir "Tambah skill baru". Boleh mengetik beberapa sekaligus dipisah koma,
misalnya `Docker, Tailwind CSS`, dan keduanya langsung masuk. Skill yang sudah
dipilih tampil sebagai chip yang bisa dilepas satu-satu.

**2. Status karier menyesuaikan pilihan**

Formulirnya tidak lagi sama untuk semua status. Begitu status diganti, kolom
isiannya ikut berubah dan kolom yang tidak relevan dinonaktifkan supaya tidak
ikut tersimpan.

| Status dipilih | Yang diminta |
|---|---|
| Bekerja | Nama perusahaan, posisi, level jabatan, tanggal mulai |
| Wirausaha | Nama usaha, peran di usaha, tanggal mulai |
| Studi lanjut | Nama perguruan tinggi, program studi, fakultas, tahap (rencana / diterima / sedang berjalan), tanggal mulai |
| Mencari kerja | Bidang yang diminati, rencana posisi, catatan |
| Belum bekerja | Bidang yang ingin ditekuni, catatan |

Jadi memilih "Belum bekerja" tidak lagi meminta nama perusahaan. Kolom dari
status sebelumnya juga dibersihkan, supaya datanya tidak bercampur.

**3. Tombol Lamar dan error saat submit**

Ada dua masalah terpisah di sini, keduanya sudah diperbaiki.

*Fatal error-nya* berasal dari `Perusahaan::cariById()` yang dipanggil tetapi
belum pernah dibuat. Setelah ditambahkan, seluruh pemanggilan method di
proyek ini dipindai untuk mencari kasus serupa, dan ditemukan satu lagi
(`Perusahaan::perbaruiWhatsapp()`) yang juga sudah dilengkapi.

*Tombol yang sulit diklik* ternyata karena surat pengantar wajib diunggah
ulang setiap kali melamar, padahal berkasnya sudah tersimpan di Profil
Karier. Sekarang kalau kolom unggahannya dibiarkan kosong, surat pengantar
dari profil yang otomatis dipakai. Kalau mau mengirim surat khusus untuk
lowongan tertentu, tinggal unggah seperti biasa. Status KTM juga ditampilkan
di awal formulir, lengkap dengan tautan langsung ke profil kalau belum ada.

---

## Admin Career Center

**1. Nama bisa diklik di Kelola Pengguna**

Nama mahasiswa sekarang berupa tautan, dan ada tombol "Lihat profil" di kolom
aksi. Keduanya membuka halaman profil lengkap: identitas, status karier
beserta rincian sesuai statusnya, pendidikan, pengalaman, sertifikat,
portofolio, skill, bidang minat, dokumen, riwayat lamaran, dan bar
kelengkapan profil.

**2. Filter perusahaan di Rekap Lamaran dihapus**

Betul, filter itu mubazir karena pencariannya sudah mencakup nama perusahaan.
Kotak pencarian sekarang menjadi satu pencarian terpadu yang menelusuri nama
mahasiswa, NIM, nama perusahaan, dan posisi sekaligus. Filter yang tersisa
hanya jurusan, program studi, status, dan rentang tanggal.

**3. Filter angkatan mengikuti jurusan di Tracer Karier**

Pilihan angkatan tidak lagi berisi semua angkatan yang ada. Begitu jurusan
dipilih, daftar angkatannya diambil ulang khusus dari jurusan itu, dan
program studinya ikut menyesuaikan.

---

## Perusahaan

**1. Lihat hasil lowongan**

Di Lowongan Saya sekarang ada tombol "Lihat" di samping Edit. Tombol itu
membuka halaman pratinjau publik, persis seperti yang dilihat mahasiswa
ketika tautan lowongannya dibagikan.

**2. Sambutan dashboard**

"Selamat bekerja" diganti menjadi "Halo".

**3. Interview luring dan daring dibedakan**

Formulir penjadwalan berubah mengikuti mode yang dipilih.

- **Daring**: tautan meeting (wajib, divalidasi harus terisi).
- **Luring**: nama tempat atau alamat (wajib), ruangan atau lantai, pakaian,
  berkas yang perlu dibawa, dan narahubung saat tiba.

Kolom mode yang tidak terpakai dikosongkan di database, jadi tidak ada sisa
data dari mode sebelumnya. Di sisi mahasiswa, rincian interview juga
ditampilkan berbeda: mode daring menampilkan tautan yang bisa diklik, mode
luring menampilkan tempat, ruangan, pakaian, bawaan, dan narahubung.

---

## Tambahan di luar daftar revisi

**Jurusan dan program studi sesuai Polinema.** Tujuh jurusan dengan 32
program studi, mulai dari D-II, D-III, D-IV, sampai S2 Terapan. Nama program
studi disimpan tanpa awalan jenjang, karena tampilannya sudah menggabungkan
jenjang dan nama. Sebelumnya tersimpan sebagai "D-III Teknik Sipil" sehingga
terbaca ganda menjadi "D-III D-III Teknik Sipil".

Kunci unik tabel program studi juga diperbaiki. Satu jurusan boleh punya nama
program studi yang sama di dua jenjang, misalnya Teknik Elektronika yang
dibuka pada D-III dan D-IV.

**Data uji lengkap.** Seed sekarang berisi 51 akun mahasiswa dan alumni, 16
perusahaan, 40 lowongan, 34 lamaran dengan status bervariasi, 7 jadwal
interview, serta riwayat pendidikan, pengalaman, sertifikat, skill, dan
bidang minat. Tiga akun demo juga sudah diisi: perusahaan demo punya lowongan
beserta pelamarnya, dan mahasiswa demo punya lamaran di empat tahap berbeda
termasuk satu jadwal interview luring. Jadi begitu login, tidak ada halaman
yang kosong saat didemokan.

**Beranda.** Bagian kontak memakai data Career Center yang sebenarnya,
beserta peta Polinema yang bisa langsung dibuka di Google Maps.

**CV otomatis.** Bisa dibuat dan diunduh dari Profil Karier. Kalau Composer
belum dipasang, CV tetap keluar sebagai halaman A4 rapi dengan tombol
"Simpan sebagai PDF", jadi tidak ada fitur yang mati.

**Profil perusahaan tidak bisa disimpan.** Formulirnya tidak punya kolom
WhatsApp PIC sama sekali, padahal kolom itu NOT NULL di database. Begitu
tombol Simpan ditekan, PHP mengirim nilai kosong dan PostgreSQL menolaknya
dengan fatal error. Sekarang kolomnya ada di formulir, divalidasi formatnya,
dan ditolak dengan pesan biasa kalau dikosongkan, bukan halaman error.

Setelah itu seluruh formulir POST di aplikasi dikirim satu per satu secara
otomatis memakai persis field yang dirender masing-masing view, untuk
memastikan tidak ada kasus serupa. Hasilnya 114 formulir, tidak ada yang
menghasilkan warning, fatal error, maupun pelanggaran constraint.

**Beranda tersambung ke database.** Bagian "Perusahaan mitra" dulu berisi
enam nama contoh yang ditulis tangan di view. Sekarang diambil dari tabel
perusahaan yang status akunnya aktif, jadi begitu admin menyetujui pendaftar
baru, perusahaan itu langsung muncul di halaman depan tanpa mengubah kode.
Yang sedang punya lowongan aktif tampil lebih dulu, sisanya diurutkan dari
yang paling baru diverifikasi.

Ditambahkan juga bagian "Lowongan terbaru" di bawahnya: enam lowongan yang
masih menerima lamaran, lengkap dengan perusahaan, lokasi, jenis pekerjaan,
batas lamaran, dan jurusan sasarannya. Kartunya bisa diklik ke halaman
pratinjau lowongan yang bisa dibuka tanpa login. Kalimat di atasnya
menyebutkan jumlah lowongan dan perusahaan yang sebenarnya, dihitung
langsung dari database.

Bagian ini dibungkus pengaman, jadi beranda tetap terbuka walau database
belum siap, misalnya saat orang pertama kali memasang proyek ini.

**Tombol Perpanjang lowongan fatal error.** `Lowongan::perpanjang()` dipanggil
controller tetapi method-nya tidak pernah dibuat di model. Sekarang ada:
status dikembalikan ke aktif, batas lamaran diganti dengan tanggal baru, dan
alasan nonaktif dikosongkan.

Setelah itu seluruh kode dipindai ulang dengan Reflection untuk mencari
pemanggilan method yang belum ada di mana pun. Hasilnya nol.

**Nilai di luar daftar tidak lagi memunculkan halaman error.** Beberapa kolom
dibatasi CHECK di database. Kalau kiriman formulir berisi nilai di luar
daftar, PostgreSQL menolaknya dan PHP menampilkannya sebagai fatal error.
Tiga tempat diperbaiki agar menolak dengan pesan biasa:

- Status karier kosong atau tidak dikenal.
- Tahap studi lanjut di luar rencana, diterima, dan sedang berjalan.
- Jenis CV di luar CV otomatis dan CV unggahan.

**Perbaikan lain yang ditemukan saat pengujian.**

- `app/services/WhatsappService.php` ternyata berisi class yang sama dua kali
  sehingga file-nya tidak bisa di-parse PHP. Salinan gandanya dihapus.
- `Mahasiswa::cariByPenggunaId()` tidak mengambil kolom email, sehingga baris
  email di CV selalu kosong. Sekarang ikut diambil.
- Deprecation PHP 8.4 pada `Database::lastInsertId()` sudah dibereskan.

---

**Tampilan ponsel dirombak.** Semua halaman diperiksa pada lebar 390px dan
diperbaiki sampai tidak ada satu pun yang perlu digeser ke samping.

- **Tabel berubah jadi kartu.** Dulu tabel di menu admin dan perusahaan
  dipaksa selebar 700px lalu diberi tulisan "geser ke samping", sehingga
  kolom NIM, jurusan, status, dan tombol aksi tidak terlihat di ponsel.
  Sekarang tiap baris menjadi satu kartu: nama di atas sebagai judul, sisa
  kolom di bawahnya berpasangan label dan isi, tombol aksi melebar penuh.
  Label kolomnya diambil otomatis dari baris judul tabel lewat satu skrip di
  `app.js`, jadi tabel yang nanti dibuat tim ikut rapi tanpa perlu diubah.
  Di layar 1025px ke atas tampilannya tetap tabel biasa seperti sebelumnya.
- **Kartu angka dua kolom**, bukan satu per baris, supaya ringkasan dashboard
  terbaca sekali pandang.
- **Filter dua kolom.** Di halaman lowongan dulu ada lima dropdown bertumpuk
  memenuhi layar sebelum daftarnya terlihat.
- **Kartu lamaran** tidak lagi berdesakan: badge status turun ke bawah supaya
  judul lowongan punya lebar penuh.
- **Kotak CV** tombolnya melebar penuh dan tidak lagi terdorong keluar layar.
- **Strip tab** digeser mulus tanpa batang gulir, dengan bayangan tipis di
  tepi kanan sebagai tanda masih ada tab lain.
- **Area sentuh** tombol di dalam kartu dinaikkan supaya nyaman ditekan jari.

Diperiksa pada lebar 360, 390, 430, 540, 640, 768, 820, 900, 1024, 1280, dan
1440 piksel.

**Berkas contoh untuk data uji.** Seed menyebut pamflet, KTM, surat pengantar,
dan CV, tetapi berkasnya tidak pernah ada sehingga gambar pamflet tampil
rusak di daftar lowongan. Sekarang berkasnya disertakan: pamflet contoh
bergaya poster dengan komposisi di tengah supaya tetap rapi ketika dipotong
jadi thumbnail maupun banner lebar, serta empat PDF contoh.

**Tandai notifikasi dibaca berakhir di halaman 404.** Tautannya sudah benar,
yang salah tujuan redirect di controller: `role . '/notifikasi'` menghasilkan
`mahasiswa/notifikasi`, padahal alamat halaman notifikasi adalah
`notifikasi/semua` untuk semua peran. Sekarang tujuannya tetap, dan tautan
yang tersimpan di notifikasi diperiksa dulu sebelum dipakai, jadi notifikasi
dengan tautan kosong atau mengarah ke alamat yang tidak dikenal mengembalikan
pengguna ke daftar notifikasi, bukan ke halaman 404.

Tabel notifikasi juga diisi di seed, karena sebelumnya kosong sehingga
loncengnya tidak ada isinya saat didemokan.

**Status karier mahasiswa aktif tidak muncul di Tracer Karier.** Semua query
tracer menyaring keras `status_mahasiswa = 'alumni'`, jadi pembaruan dari
mahasiswa yang masih aktif tidak pernah terlihat Admin.

Tracer memang ditujukan untuk alumni, dan angka seperti "55% alumni sudah
bekerja" akan berubah arti kalau mahasiswa aktif ikut dihitung. Karena itu
pilihan bawaannya tetap Alumni, tetapi ditambahkan filter **Alumni saja,
Mahasiswa aktif saja, Mahasiswa dan alumni**. Judul panel dan laporan PDF
ikut menyesuaikan pilihan, dan muncul keterangan di atas halaman kalau yang
ditampilkan bukan alumni, supaya angkanya tidak salah dibaca.

**Peran lain tidak lagi berakhir di halaman 403 yang buntu.** Tautan "Lihat
semua lowongan" di beranda menyesuaikan peran yang sedang login, dan halaman
403 menawarkan dashboard milik peran itu, bukan hanya tombol kembali ke
beranda.

**Tombol berkas tidak bisa diklik.** Beberapa masalah sekaligus:

- Sertifikat dan portofolio pelamar tidak pernah boleh dibuka perusahaan,
  padahal justru itu yang perlu dilihat saat menyeleksi. Sekarang diizinkan,
  dengan syarat orangnya memang melamar ke perusahaan itu.
- Halaman profil mahasiswa di sisi Admin memakai jenis berkas `dokumen` yang
  tidak dikenal sistem, jadi selalu ditolak. Diperbaiki menjadi `ktm`.
- Alumni mengunggah ijazah yang tersimpan di folder berbeda dari KTM, tetapi
  semua tautan memakai `tipe=ktm`, jadi berkasnya tidak pernah ketemu.
  Sekarang dicari juga di folder pasangannya.
- Halaman galatnya dulu tulisan polos tanpa jalan keluar. Sekarang rapi dan
  menawarkan kembali ke dashboard sesuai peran.

Berkas contoh untuk seluruh jenis dokumen ikut disertakan, dengan **nama
berbeda untuk tiap orang** memakai NIM atau nomor perusahaan. Kalau semua
memakai satu nama yang sama, pemeriksaan hak akses tidak bisa membedakan
pemiliknya sehingga berkas orang lain ikut terbuka.

**Alamat salah ketik tidak lagi memunculkan fatal error.** Alamat seperti
`/lamaran/batalkan` tanpa angka id, atau `/lowongan/detail/abc`, dulu
melempar `ArgumentCountError` dan `TypeError` sebagai halaman fatal error.
Router sekarang memeriksa jumlah dan tipe parameter lebih dulu, lalu
menampilkan halaman 404 biasa. Berlaku untuk semua controller sekaligus.

**Lamaran yang dibatalkan pelamar** tidak lagi menampilkan formulir jadwal
interview di sisi perusahaan.

**Berkas yang hilang dari penyimpanan tidak lagi jadi jalan buntu.** Kalau
folder aplikasi dipindah atau diganti, berkas yang pernah diunggah tertinggal
di folder lama sementara database tetap mencatat namanya. Dulu tombolnya tetap
tampil lalu berakhir di halaman galat.

Sekarang:

- Halaman **cek-berkas.php** membandingkan database dengan isi penyimpanan dan
  menunjukkan berkas mana yang hilang beserta pemiliknya, lengkap dengan cara
  memperbaikinya.
- Di Profil Karier, status dokumen tertulis **Perlu diunggah ulang**, bukan
  "Sudah tersimpan", disertai peringatan di atas formulirnya.
- Tombol "Lihat" dan "Lihat file" di halaman Admin dan Perusahaan tidak lagi
  ditampilkan kalau berkasnya memang tidak ada.

## Pemeriksaan yang dijalankan sebelum ZIP dikirim

Enam lapis, semuanya dari database yang dibangun ulang dari nol:

| Pemeriksaan | Cakupan | Hasil |
|---|---|---|
| Lint PHP | Seluruh file di app dan public | Bersih |
| Scan Reflection | Setiap pemanggilan method dicocokkan dengan method yang benar-benar ada | Nol yang hilang |
| Semua method controller | 63 method dipanggil lewat HTTP dengan id nyata dan peran yang sesuai | Nol error |
| Semua formulir POST | 114 formulir dikirim memakai persis field yang dirender view | Nol error |
| Nilai salah di kolom berCHECK | Kosong dan nilai asing pada status karier, tahap studi, jenis CV, mode interview, tipe item profil, keputusan verifikasi, IPK, kuota | Semua ditolak dengan pesan biasa |
| Semua halaman tiga peran | Admin, mahasiswa, perusahaan, termasuk halaman detail dan unduhan | Bersih |
| Tampilan ponsel | 18 halaman pada lebar 390px, ditambah 11 lebar layar berbeda | Nol halaman yang perlu digeser ke samping |
| Telusur seluruh tautan | 326 alamat ditemukan sendiri dari tautan di tiap halaman, redirect diikuti sampai tujuan akhir | Nol yang berakhir di 404 atau galat |
| Tautan berkas | 93 tombol berkas dibuka, isinya diperiksa benar-benar keluar | Semua terbuka |
| Aturan akses berkas | Berkas pribadi diuji dari peran yang berhak dan yang tidak, termasuk percobaan keluar folder | Semua benar |
| Alamat cacat | 27 alamat salah ketik dan dikarang | Nol fatal error |

## Cara memeriksa sendiri

Login dengan tiga akun demo di `PANDUAN-JALANKAN.md`, lalu:

1. Mahasiswa, Profil Karier, tab Skills. Tambahkan `Docker, Tailwind CSS`.
2. Masih di sana, tab Status karier. Ganti-ganti statusnya, perhatikan kolom
   isiannya ikut berubah.
3. Mahasiswa, Lowongan, pilih satu, klik Lamar, langsung kirim tanpa
   mengunggah apa pun. Lamaran masuk dan perusahaannya dapat notifikasi.
4. Perusahaan, Pelamar, buka satu pelamar, ganti Mode ke Luring. Kolomnya
   berganti. Coba simpan dengan tempat kosong, akan ditolak.
5. Admin, Kelola Pengguna, klik salah satu nama.
6. Admin, Tracer Karier, pilih jurusan, lihat daftar angkatannya ikut berubah.
