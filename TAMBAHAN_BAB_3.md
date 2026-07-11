# TAMBAHAN UNTUK BAB III
# ANALISIS DAN PERANCANGAN

Berdasarkan contoh format Tugas Akhir yang disetujui di Jurusan Teknologi Informasi Politeknik Negeri Padang, berikut adalah bagian-bagian penting yang perlu ditambahkan pada **Bab III** Anda agar lengkap dan memenuhi standar kelulusan sidang:

---

## 3.2 Rancangan Struktur Sistem yang Akan Dibangun
Sistem Informasi Monitoring Pola Makan dan Kesehatan (*GiziApp*) dirancang menggunakan arsitektur *client-server* untuk memisahkan fungsi antarmuka pengguna dengan pemrosesan logika bisnis dan penyimpanan data secara terpusat. Struktur sistem ini terdiri dari dua komponen utama:

1. **Aplikasi Mobile (Client Side)**
   Dibangun menggunakan *framework* Flutter dan dijalankan pada perangkat *mobile* (Android/iOS). Sisi klien ini bertanggung jawab untuk:
   * Menyediakan antarmuka pengguna (*user interface*) yang responsif.
   * Menangkap input data fisik atlet (tinggi, berat, usia, tingkat aktivitas).
   * Melakukan pencarian bahan makanan lokal Indonesia dan menyusun log konsumsi.
   * Mengirimkan permintaan HTTP (*HTTP Request*) dalam format JSON ke server REST API.
   * Menampilkan visualisasi data berupa grafik tren kalori dan ringkasan nutrisi makro.
   * Menyediakan antarmuka Asisten Gizi AI (Gemini AI) untuk rekomendasi menu secara personal.

2. **REST API & MySQL Database (Server Side)**
   Sisi server bertindak sebagai penyedia layanan data terpusat (*backend*) yang bertugas:
   * Mengelola autentikasi pengguna dengan enkripsi dan validasi token JWT.
   * Melakukan perhitungan matematis untuk BMI, BMR (kalkulasi *Harris-Benedict*), berat badan ideal, dan target kalori (TDEE).
   * Memproses permintaan query database untuk menampilkan data makanan atau riwayat gizi.
   * Menyimpan semua informasi relasional pada database MySQL secara aman dan konsisten.

---

## 3.3.2.1 Deskripsi Aktor (Tabel Tambahan setelah Gambar Use Case)
Untuk menjelaskan peran masing-masing pengguna yang terlibat dalam sistem, berikut adalah deskripsi detail aktor pada sistem *GiziApp*:

### Tabel 3.1 Deskripsi Aktor
| No | Aktor | Deskripsi |
|---|---|---|
| 1 | **Atlet (User)** | Pengguna akhir yang memiliki akses untuk mengisi data fisik, menghitung BMI/BMR/TDEE, mencatat asupan makanan dan aktivitas fisik harian, melihat grafik perkembangan gizi, dan berkonsultasi dengan Asisten Gizi AI. |
| 2 | **Pelatih (Coach)** | Pengguna yang memiliki hak akses untuk memantau data kesehatan atlet di bawah bimbingannya secara *realtime*, melihat riwayat BMI, serta memantau susunan rencana menu harian atlet tanpa dapat mengubah data fisik atlet. |
| 3 | **Admin** | Pengelola sistem yang memiliki hak akses penuh untuk melakukan manajemen basis data bahan pangan lokal Indonesia (tambah, ubah, dan hapus data makanan beserta nilai gizinya). |

---

## 3.3.2.2 Deskripsi Use Case (Tabel Tambahan setelah Use Case Diagram)
Tabel ini menjabarkan rincian setiap fungsionalitas (*use case*) yang digambarkan pada Use Case Diagram:

### Tabel 3.2 Deskripsi Use Case
| No | Use Case | Deskripsi | Aktor yang Terlibat |
|---|---|---|---|
| 1 | **Melakukan Registrasi** | Proses pendaftaran akun baru ke dalam sistem dengan memilih peran (Atlet/Pelatih). | Atlet, Pelatih |
| 2 | **Melakukan Login** | Pengguna memasukkan email dan password untuk divalidasi oleh sistem agar dapat masuk ke aplikasi. | Atlet, Pelatih, Admin |
| 3 | **Mengelola Data Fisik** | Atlet memasukkan tinggi badan, berat badan, usia, jenis kelamin, dan aktivitas fisik untuk disimpan ke dalam sistem. | Atlet |
| 4 | **Menghitung BMI & Target Kalori** | Sistem secara otomatis menghitung skor BMI, kategori status berat badan, angka BMR, dan kebutuhan kalori harian (TDEE). | Atlet (Sistem) |
| 5 | **Mencatat Makanan (Log Food)** | Atlet mencari bahan makanan lokal dan mencatat porsinya berdasarkan waktu makan (sarapan, siang, malam, selingan). | Atlet |
| 6 | **Mencatat Aktivitas Fisik** | Atlet mencatat latihan/olahraga yang dilakukan beserta durasinya untuk menghitung kalori yang terbakar. | Atlet |
| 7 | **Melihat Insight** | Atlet melihat ringkasan visual berupa grafik tren kalori mingguan dan distribusi zat gizi makro (karbohidrat, protein, lemak). | Atlet |
| 8 | **Melihat Rekomendasi AI** | Atlet meminta analisis gizi pintar dan saran menu harian berbasis teks dari Gemini AI. | Atlet |
| 9 | **Memantau Daftar Atlet** | Pelatih melihat daftar seluruh atlet bimbingannya beserta status BMI harian mereka yang diperbarui otomatis setiap 10 detik. | Pelatih |
| 10 | **Memeriksa Detail Atlet** | Pelatih melihat riwayat BMI, progres kalori harian, dan rincian log makanan atlet tertentu. | Pelatih |
| 11 | **Mengelola Data Makanan** | Admin menambah, mengedit, atau menghapus item makanan beserta nilai gizinya pada database pangan lokal. | Admin |

---

## 3.4.1 Perancangan Struktur Tabel Database (Detail untuk Sub-bab 3.4)
Rancangan fisik tabel database MySQL untuk menyimpan seluruh data terelasi sistem informasi *GiziApp* dijabarkan sebagai berikut:

### 1. Tabel `users`
* **Nama Tabel**: `users`
* **Primary Key**: `id`
* **Keterangan**: Menyimpan informasi autentikasi akun pengguna sistem.

| No | Nama Field | Tipe Data | Size | Keterangan |
|---|---|---|---|---|
| 1 | `id` | INT | - | Primary Key, Auto Increment. ID unik pengguna. |
| 2 | `email` | VARCHAR | 100 | Email unik pengguna untuk login. |
| 3 | `password` | VARCHAR | 255 | Kata sandi akun yang dienkripsi (hash). |
| 4 | `nama_lengkap` | VARCHAR | 100 | Nama lengkap pengguna. |
| 5 | `role` | ENUM | - | Peran akses pengguna ('admin', 'coach', 'athlete'). |
| 6 | `tanggal_lahir` | DATE | - | Tanggal lahir pengguna untuk perhitungan usia. |
| 7 | `created_at` | TIMESTAMP | - | Waktu pembuatan akun. |

### 2. Tabel `bmi_history`
* **Nama Tabel**: `bmi_history`
* **Primary Key**: `id`
* **Keterangan**: Menyimpan riwayat pengukuran data fisik dan kalkulasi kalori harian atlet.

| No | Nama Field | Tipe Data | Size | Keterangan |
|---|---|---|---|---|
| 1 | `id` | INT | - | Primary Key, Auto Increment. ID unik riwayat. |
| 2 | `user_id` | INT | - | Foreign Key terhubung ke tabel `users`.id. |
| 3 | `berat_badan` | FLOAT | - | Berat badan atlet dalam satuan kilogram (kg). |
| 4 | `tinggi_badan` | FLOAT | - | Tinggi badan atlet dalam satuan sentimeter (cm). |
| 5 | `tingkat_aktivitas` | VARCHAR | 30 | Level aktivitas fisik harian atlet (e.g. sedentary, very_active). |
| 6 | `tujuan_kesehatan` | VARCHAR | 20 | Target berat badan atlet (maintain, lose, gain). |
| 7 | `skor_bmi` | FLOAT | - | Hasil kalkulasi Indeks Massa Tubuh. |
| 8 | `berat_ideal` | FLOAT | - | Berat badan ideal yang disarankan. |
| 9 | `angka_bmr` | FLOAT | - | Basal Metabolic Rate hasil hitung rumus Harris-Benedict. |
| 10 | `kebutuhan_kalori` | FLOAT | - | Target energi harian (TDEE) dalam satuan kilokalori (kkal). |
| 11 | `status` | VARCHAR | 20 | Kategori status gizi (Kurus, Normal, Gemuk, Obesitas). |
| 12 | `created_at` | TIMESTAMP | - | Waktu pencatatan data fisik. |

### 3. Tabel `foods`
* **Nama Tabel**: `foods`
* **Primary Key**: `id`
* **Keterangan**: Menyimpan database kandungan gizi bahan pangan lokal Indonesia.

| No | Nama Field | Tipe Data | Size | Keterangan |
|---|---|---|---|---|
| 1 | `id` | INT | - | Primary Key, Auto Increment. ID unik makanan. |
| 2 | `nama_makanan` | VARCHAR | 100 | Nama makanan/minuman (misal: "Nasi Putih"). |
| 3 | `kalori` | FLOAT | - | Kandungan energi per porsi standar (kkal). |
| 4 | `protein` | FLOAT | - | Kandungan protein per porsi standar (gram). |
| 5 | `karbohidrat` | FLOAT | - | Kandungan karbohidrat per porsi standar (gram). |
| 6 | `lemak` | FLOAT | - | Kandungan lemak per porsi standar (gram). |
| 7 | `kategori` | VARCHAR | 50 | Kategori makanan (makanan_utama, selingan, minuman). |
| 8 | `image_url` | VARCHAR | 255 | Tautan gambar ilustrasi makanan. |

### 4. Tabel `meal_plans`
* **Nama Tabel**: `meal_plans`
* **Primary Key**: `id`
* **Keterangan**: Menyimpan header rencana menu makan harian atlet.

| No | Nama Field | Tipe Data | Size | Keterangan |
|---|---|---|---|---|
| 1 | `id` | INT | - | Primary Key, Auto Increment. ID unik meal plan. |
| 2 | `user_id` | INT | - | Foreign Key terhubung ke tabel `users`.id. |
| 3 | `bmi_history_id` | INT | - | Foreign Key terhubung ke tabel `bmi_history`.id. |
| 4 | `total_kalori_harian`| FLOAT | - | Akumulasi target kalori rencana menu. |
| 5 | `created_at` | TIMESTAMP | - | Tanggal pembuatan rencana menu. |

### 5. Tabel `meal_plan_items`
* **Nama Tabel**: `meal_plan_items`
* **Primary Key**: `id`
* **Keterangan**: Menyimpan detail item makanan yang dijadwalkan pada menu harian.

| No | Nama Field | Tipe Data | Size | Keterangan |
|---|---|---|---|---|
| 1 | `id` | INT | - | Primary Key, Auto Increment. ID unik item. |
| 2 | `meal_plan_id` | INT | - | Foreign Key terhubung ke tabel `meal_plans`.id. |
| 3 | `food_id` | INT | - | Foreign Key terhubung ke tabel `foods`.id. |
| 4 | `hari` | VARCHAR | 10 | Hari pelaksanaan menu (senin s.d. minggu). |
| 5 | `waktu_makan` | VARCHAR | 20 | Waktu konsumsi (sarapan, makan_siang, makan_malam, cemilan). |
