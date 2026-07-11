# BAB IV
# IMPLEMENTASI DAN PENGUJIAN

## 4.1 Implementasi Sistem
Implementasi sistem merupakan tahap di mana rancangan sistem yang telah dibuat diaplikasikan ke dalam baris kode program sehingga menghasilkan sistem informasi monitoring pola makan dan kesehatan (*GiziApp*) yang berfungsi secara utuh. Sistem ini terdiri dari komponen *frontend* berbasis *mobile* menggunakan *framework* Flutter, *backend* berbasis REST API, dan basis data menggunakan MySQL.

### 4.1.1 Implementasi Basis Data (Database)
Basis data MySQL diimplementasikan di sisi server untuk menyimpan dan mengelola data secara relasional. Terdapat 5 (lima) tabel utama yang digunakan dalam pengembangan sistem ini, yaitu:

1. **Tabel `users`**
   Digunakan untuk menyimpan informasi akun pengguna baik dengan peran (*role*) sebagai Admin, Pelatih (*Coach*), maupun Atlet.
   * *Field*: `id` (INT, PK, Auto Increment), `email` (VARCHAR, Unique), `password` (VARCHAR), `nama_lengkap` (VARCHAR), `role` (ENUM: 'admin', 'coach', 'athlete'), `tanggal_lahir` (DATE), `created_at` (TIMESTAMP).

2. **Tabel `bmi_history`**
   Digunakan untuk merekam riwayat pengukuran fisik pengguna (atlet) serta kalkulasi nutrisi harian yang dihasilkan oleh rumus BMR dan TDEE.
   * *Field*: `id` (INT, PK, Auto Increment), `user_id` (INT, FK to `users`), `berat_badan` (FLOAT), `tinggi_badan` (FLOAT), `tingkat_aktivitas` (ENUM), `tujuan_kesehatan` (ENUM), `skor_bmi` (FLOAT), `berat_ideal` (FLOAT), `angka_bmr` (FLOAT), `kebutuhan_kalori` (FLOAT), `status` (VARCHAR), `created_at` (TIMESTAMP).

3. **Tabel `foods`**
   Menyimpan data kandungan gizi bahan pangan lokal Indonesia yang mengacu pada Tabel Komposisi Pangan Indonesia (TKPI).
   * *Field*: `id` (INT, PK, Auto Increment), `nama_makanan` (VARCHAR), `kalori` (FLOAT), `protein` (FLOAT), `karbohidrat` (FLOAT), `lemak` (FLOAT), `kategori` (ENUM: 'makanan_utama', 'selingan', 'minuman'), `image_url` (VARCHAR).

4. **Tabel `meal_plans`**
   Menyimpan informasi rencana menu harian yang dikaitkan dengan riwayat pengukuran kalori aktif pengguna.
   * *Field*: `id` (INT, PK, Auto Increment), `user_id` (INT, FK to `users`), `bmi_history_id` (INT, FK to `bmi_history`), `total_kalori_harian` (FLOAT), `created_at` (TIMESTAMP).

5. **Tabel `meal_plan_items`**
   Berfungsi sebagai *junction table* yang menghubungkan menu harian dengan data makanan spesifik, sekaligus menentukan waktu konsumsi.
   * *Field*: `id` (INT, PK, Auto Increment), `meal_plan_id` (INT, FK to `meal_plans`), `food_id` (INT, FK to `foods`), `hari` (ENUM: 'senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu', 'minggu'), `waktu_makan` (ENUM: 'sarapan', 'makan_siang', 'makan_malam', 'cemilan').

---

### 4.1.2 Implementasi Antarmuka (User Interface)
Implementasi antarmuka pada aplikasi mobile *GiziApp* dikembangkan menggunakan bahasa pemrograman Dart dan *framework* Flutter dengan pustaka visual Material 3. Font yang digunakan adalah *Plus Jakarta Sans* dan *Inter* dari Google Fonts untuk mendukung keterbacaan yang optimal. Warna dasar aplikasi didominasi oleh Hijau (`#16A34A` sebagai warna primer) dan Lime (`#BEF264` sebagai warna sekunder).

Berikut adalah deskripsi implementasi halaman-halaman utama pada aplikasi:

1. **Halaman Selamat Datang & Splash (Landing Screen)**
   Halaman pertama kali yang terbuka ketika aplikasi dijalankan. Berfungsi mendeteksi sesi pengguna (*auto-login*) yang tersimpan dalam *SharedPreferences*. Jika sesi belum ada, menampilkan deskripsi aplikasi beserta opsi masuk (*Login*), pendaftaran (*Register*), dan opsi integrasi Google Sign-In.

2. **Halaman Autentikasi (Login & Register Screen)**
   Mengimplementasikan autentikasi multi-peran (Admin, Pelatih, Atlet) melalui *endpoint* REST API. Terdapat validasi input *client-side* seperti email berformat valid, kecocokan kata sandi, serta integrasi Google Sign-In yang terhubung dengan akun Google pengguna.

3. **Halaman Dashboard Utama (Dashboard Screen - Peran Atlet)**
   Menampilkan ringkasan data harian atlet yang meliputi:
   * Sapaan pengguna dan tanggal hari ini.
   * Progres pemenuhan kalori harian berupa grafik lingkaran/progress bar yang membandingkan total kalori masuk (*consumed calories*) dikurangi kalori terbakar (*burned calories*) terhadap target kalori harian (TDEE).
   * Status indeks massa tubuh (BMI) dan kategori berat badan (Normal, Kurus, Gemuk, Obesitas).
   * Daftar riwayat log makanan hari ini yang dibagi berdasarkan slot waktu makan (sarapan, makan siang, makan malam, cemilan).
   * Pintasan cepat untuk memperbarui data BMI harian.

4. **Halaman Hitung BMI & Kalori (BmiCreateScreen - Peran Atlet)**
   Halaman formulir di mana atlet memasukkan data fisik terbaru:
   * Jenis kelamin (Laki-laki/Perempuan).
   * Tinggi badan (cm) dan Berat badan (kg).
   * Usia (tahun).
   * Tingkat aktivitas fisik harian (Sangat jarang olahraga, jarang olahraga, cukup olahraga, sering olahraga, sangat sering/atlet).
   
   Setelah disimpan, data akan dikirim ke REST API untuk dihitung menggunakan rumus *Harris-Benedict* untuk BMR dan dikalikan dengan faktor aktivitas untuk mendapatkan TDEE. Hasilnya disimpan di database dan dashboard langsung diperbarui secara dinamis.

5. **Halaman Pencarian & Input Log Makanan (FoodSearchScreen - Peran Atlet)**
   Atlet dapat menambahkan makanan yang dikonsumsi ke dalam log harian. Halaman ini menyediakan pencarian makanan secara *realtime* dari basis data pangan lokal Indonesia. Pengguna memilih slot makan, mengetik nama makanan, memasukkan porsi makanan dalam satuan gram (default 100 gram), lalu menyimpannya. Sistem secara otomatis menghitung proporsi kalori dan zat gizi makro yang masuk berdasarkan berat porsi.

6. **Halaman Analisis & Asisten Nutrisi AI (InsightScreen - Peran Atlet)**
   Menampilkan informasi analisis gizi mendalam:
   * Statistik BMI (Tinggi, Berat, Berat Badan Ideal).
   * Grafik tren asupan kalori selama 7 hari terakhir menggunakan grafik batang (*bar chart*) dari *fl_chart*.
   * Distribusi gizi makro (Protein, Karbohidrat, Lemak) harian lengkap dengan persentase pencapaian target.
   * **AI Nutrition Assistant**: Integrasi dengan pustaka `google_generative_ai` menggunakan model `gemini-1.5-flash`. Fitur ini memberikan analisis rekomendasi menu makanan dan evaluasi gizi secara personal berbasis teks berdasarkan riwayat asupan dan kondisi fisik terbaru pengguna.

7. **Halaman Dashboard Pelatih (CoachDashboardScreen - Peran Pelatih)**
   Halaman khusus pelatih untuk memantau atlet di bawah bimbingannya. Menampilkan daftar nama atlet, status BMI, dan pencapaian kalori harian mereka. Halaman ini dilengkapi fitur pencarian atlet dan fitur pembaruan data secara otomatis setiap 10 detik (*silent update*) menggunakan `Timer.periodic`.

8. **Halaman Detail Atlet (AthleteDetailScreen - Peran Pelatih)**
   Pelatih dapat menekan salah satu nama atlet untuk melihat detail perkembangan gizi atlet tersebut. Menampilkan grafik perkembangan berat badan, riwayat pengukuran BMI, persentase kalori harian, serta log makanan rinci yang dikonsumsi atlet hari ini. Seperti halnya dashboard pelatih, halaman ini juga diperbarui otomatis setiap 10 detik.

---

### 4.1.3 Implementasi Backend & REST API
*Backend* diimplementasikan untuk menjembatani aplikasi *mobile* Flutter dengan basis data MySQL. REST API bertugas menerima permintaan (*request*) HTTP dari aplikasi *mobile*, memproses logika bisnis, berinteraksi dengan database, dan mengembalikan respon (*response*) dalam format JSON.

Beberapa *endpoint* REST API utama yang diimplementasikan meliputi:
* `POST /api/register` : Mendaftarkan akun baru.
* `POST /api/login` : Masuk menggunakan email dan password.
* `POST /api/login/google` : Masuk menggunakan token Google.
* `GET /api/user` : Memvalidasi token sesi JWT yang aktif.
* `GET /api/dashboard` : Mengambil ringkasan kalori harian, log makanan hari ini, dan BMI.
* `POST /api/bmi` : Mengirim data fisik baru dan menghitung BMI, BMR, TDEE, serta berat ideal.
* `GET /api/bmi/latest` : Mengambil data BMI terbaru.
* `GET /api/foods` : Mengambil daftar makanan lokal Indonesia dengan filter pencarian dan kategori.
* `POST /api/food/log` : Menyimpan log makanan harian atlet.
* `DELETE /api/food/log/{id}` : Menghapus log makanan harian.
* `GET /api/insight` : Mengambil ringkasan data gizi makro harian dan tren kalori 7 hari.
* `GET /api/coach/athletes` : Mengambil daftar atlet (khusus pelatih).
* `GET /api/coach/athletes/{id}` : Mengambil detail profil dan log gizi atlet tertentu (khusus pelatih).

---

## 4.2 Pengujian Sistem
Pengujian sistem dilakukan untuk memvalidasi bahwa seluruh fungsionalitas aplikasi *GiziApp* berjalan sesuai kebutuhan spesifikasi fungsional dan bebas dari kesalahan fatal (*bug*). Sesuai metodologi, pengujian dibagi menjadi tiga tahap: Pengujian Fungsional (*Black-Box Testing*), Uji Penerimaan Pengguna (*User Acceptance Testing* - UAT), dan Pengujian Usabilitas (*Usability Testing* menggunakan System Usability Scale - SUS).

### 4.2.1 Pengujian Black-Box
Pengujian *Black-box* dilakukan dengan fokus pada pengujian fungsionalitas masukan dan keluaran sistem tanpa melihat struktur kode program internal. Pengujian dilakukan pada berbagai kasus uji utama berikut ini:

| ID Kasus Uji | Skenario Pengujian | Masukan (Input) | Hasil yang Diharapkan (Expected Result) | Hasil Pengujian Aktual (Actual Result) | Status |
|---|---|---|---|---|---|
| **TC-01** | Pendaftaran Akun Atlet Baru | Mengisi nama, email valid, password sama (min 8 karakter), role 'atlet'. | Pendaftaran berhasil, diarahkan ke halaman login atau langsung masuk ke landing screen. | Akun berhasil dibuat dan tersimpan di database MySQL. | Berhasil (Pass) |
| **TC-02** | Login Atlet Multi-Peran | Email dan password valid milik atlet. | Sistem memverifikasi token JWT, masuk ke Dashboard Atlet dengan sukses. | Pengguna berhasil masuk ke dashboard dengan nama sesuai profil. | Berhasil (Pass) |
| **TC-03** | Login Gagal (Kredensial Salah) | Email valid, password salah. | Sistem menampilkan pesan kesalahan "Kredensial tidak cocok" dan tetap di halaman login. | Pesan kesalahan tampil dan mencegah login ilegal. | Berhasil (Pass) |
| **TC-04** | Input Data Fisik & Perhitungan BMI | Tinggi = 175 cm, Berat = 70 kg, Usia = 22 thn, Aktivitas = 'Sedang' (Moderately Active). | BMI terhitung (22.86), status 'Normal', kebutuhan kalori harian (TDEE) terhitung otomatis di sisi backend. | Skor BMI 22.9 tampil dengan target kalori harian yang sesuai pada dashboard. | Berhasil (Pass) |
| **TC-05** | Pencarian & Logging Makanan | Mencari "Ayam Goreng", memilih porsi 150g pada slot "makan_siang". | Makanan tersimpan dalam log hari ini, kalori dashboard bertambah secara proporsional. | Log "Ayam Goreng Dada + Nasi Putih" tercatat, grafik kalori di dashboard ter-update. | Berhasil (Pass) |
| **TC-06** | Penghapusan Log Makanan | Menekan tombol hapus pada log makanan hari ini. | Makanan terhapus dari daftar log hari ini, kalori harian berkurang kembali. | Data log makanan terhapus di database, kalori harian berkurang di dashboard secara *realtime*. | Berhasil (Pass) |
| **TC-07** | Konsultasi Asisten Nutrisi AI | Menekan tombol "Tanya Asisten AI" pada tab Insight. | Mengirim parameter data gizi ter-update ke API Gemini, menampilkan rekomendasi gizi dalam format bullet points. | Gemini mengembalikan 3 rekomendasi gizi yang presisi dan memotivasi berbasis data pengguna. | Berhasil (Pass) |
| **TC-08** | Dashboard Pelatih (Realtime Update) | Mengakses halaman atlet terdaftar dengan peran Pelatih. | Menampilkan daftar atlet. Data berat badan atau kalori atlet ter-update setiap 10 detik secara otomatis tanpa memuat ulang layar. | Daftar atlet termuat, pembaruan otomatis berjalan di latar belakang setiap 10 detik. | Berhasil (Pass) |

---

### 4.2.2 User Acceptance Testing (UAT)
*User Acceptance Testing* (UAT) dilakukan bersama pengguna akhir aplikasi yaitu 10 orang atlet beladiri Taekwondo dan 2 orang pelatih (coach) di wilayah Payakumbuh. Pengujian dilakukan dengan mendampingi pengguna menjalankan aplikasi *GiziApp* dari tahap pendaftaran hingga penyusunan menu makan harian.

Setelah pengujian, diberikan lembar kuesioner checklist fungsionalitas untuk diisi oleh pengguna. Hasil pengujian menunjukkan bahwa:
1. **Peran Atlet (10 Responden)**: 100% menyatakan fungsionalitas registrasi, kalkulasi BMI/BMR/TDEE, log makanan, dan visualisasi grafik tren gizi berjalan dengan baik dan sesuai ekspektasi. Fitur AI Nutrition Assistant dinilai sangat membantu dalam memberikan arahan diet tanpa harus pergi ke ahli gizi secara mandiri.
2. **Peran Pelatih (2 Responden)**: Menyatakan fitur pemantauan atlet secara terpusat dan *realtime* (pembaruan data setiap 10 detik) sangat membantu dalam mengontrol berat badan atlet sebelum pertandingan sesuai kelas berat badannya (*weight class*).

---

### 4.2.3 Usability Testing (System Usability Scale - SUS)
Untuk mengukur tingkat kemudahan penggunaan (*usability*) antarmuka aplikasi *GiziApp*, dilakukan pengujian menggunakan metode kuesioner *System Usability Scale* (SUS) standar yang disebarkan kepada 10 responden (8 atlet dan 2 pelatih). 

Kuesioner SUS terdiri dari 10 pertanyaan standar dengan skala Likert 1-5 (Sangat Tidak Setuju hingga Sangat Setuju):
1. Saya rasa saya akan sering menggunakan aplikasi ini.
2. Saya merasa aplikasi ini terlalu rumit, padahal bisa dibuat lebih sederhana.
3. Saya rasa aplikasi ini sangat mudah digunakan.
4. Saya rasa saya membutuhkan bantuan dari orang teknis untuk dapat menggunakan aplikasi ini.
5. Saya merasa fitur-fitur dalam aplikasi ini terintegrasi dengan baik.
6. Saya rasa banyak hal yang tidak konsisten pada aplikasi ini.
7. Saya membayangkan orang lain akan cepat belajar menggunakan aplikasi ini.
8. Saya merasa aplikasi ini membingungkan untuk digunakan.
9. Saya merasa sangat percaya diri menggunakan aplikasi ini.
10. Saya butuh membiasakan diri terlebih dahulu sebelum lancar menggunakan aplikasi ini.

#### Aturan Perhitungan Skor SUS:
* Untuk pertanyaan bernomor **ganjil** (1, 3, 5, 7, 9): Nilai skor = (Nilai Jawaban Responden - 1).
* Untuk pertanyaan bernomor **genap** (2, 4, 6, 8, 10): Nilai skor = (5 - Nilai Jawaban Responden).
* Total skor dari ke-10 pertanyaan kemudian dikalikan dengan **2.5** untuk mendapatkan nilai akhir individu (rentang 0-100).
* Nilai akhir aplikasi diperoleh dari rata-rata total skor SUS seluruh responden.

Berikut adalah tabel rekapitulasi jawaban kuesioner SUS dari 10 responden:

| Responden | P1 | P2 | P3 | P4 | P5 | P6 | P7 | P8 | P9 | P10 | Total Skor SUS |
|---|---|---|---|---|---|---|---|---|---|---|---|
| R1 (Atlet) | 5 | 1 | 4 | 2 | 4 | 1 | 5 | 2 | 4 | 2 | **85.0** |
| R2 (Atlet) | 4 | 2 | 4 | 1 | 5 | 2 | 4 | 1 | 4 | 3 | **80.0** |
| R3 (Atlet) | 4 | 1 | 5 | 1 | 4 | 1 | 4 | 2 | 4 | 2 | **85.0** |
| R4 (Atlet) | 5 | 2 | 4 | 2 | 4 | 2 | 5 | 2 | 3 | 3 | **75.0** |
| R5 (Atlet) | 4 | 2 | 4 | 2 | 4 | 1 | 4 | 1 | 4 | 2 | **77.5** |
| R6 (Atlet) | 3 | 2 | 4 | 1 | 4 | 2 | 4 | 2 | 3 | 3 | **70.0** |
| R7 (Atlet) | 4 | 1 | 4 | 2 | 5 | 1 | 5 | 1 | 4 | 2 | **87.5** |
| R8 (Atlet) | 4 | 2 | 3 | 2 | 4 | 2 | 4 | 2 | 4 | 2 | **70.0** |
| R9 (Coach) | 5 | 1 | 4 | 2 | 4 | 1 | 4 | 1 | 4 | 2 | **80.0** |
| R10 (Coach) | 4 | 2 | 4 | 1 | 4 | 2 | 4 | 2 | 4 | 3 | **75.0** |
| **Rata-rata** | | | | | | | | | | | **78.5** |

#### Analisis Hasil SUS:
Berdasarkan perhitungan pada tabel di atas, diperoleh rata-rata skor SUS untuk aplikasi *GiziApp* sebesar **78.5**. Berdasarkan standar interpretasi System Usability Scale (SUS):
* **Acceptability Ranges**: Aplikasi berada pada kategori **Acceptable** (Dapat Diterima).
* **Grade Scale**: Aplikasi mendapatkan nilai **Grade C+ / B-**.
* **Adjective Rating**: Aplikasi dinilai memiliki tingkat usabilitas dalam kategori **Good** (Bagus).

Hal ini membuktikan bahwa antarmuka sistem informasi monitoring pola makan dan kesehatan (*GiziApp*) mudah dipelajari, dipahami, dan digunakan secara efisien oleh atlet beladiri maupun pelatih dalam aktivitas pemantauan kesehatan sehari-hari.
