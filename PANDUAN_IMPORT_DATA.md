# Panduan Import Data Batch

Aplikasi CPL mendukung import data dalam batch (jumlah besar sekaligus) dari file CSV. Fitur ini memudahkan untuk memasukkan data mahasiswa dan matakuliah dalam jumlah banyak.

## Jenis Data yang Bisa Diimport

### 1. Data Mahasiswa
Import data mahasiswa dengan informasi lengkap.

**Format CSV:**
- Kolom A: NIM (Nomor Induk Mahasiswa) - **WAJIB**
- Kolom B: Nama - **WAJIB**
- Kolom C: Tahun Masuk - **WAJIB**

**Contoh:**
```csv
NIM,Nama,Tahun Masuk
22001,Budi Santoso,2022
22002,Siti Nurhaliza,2022
22003,Ahmad Wijaya,2023
```

**Ketentuan:**
- NIM harus unik (tidak boleh ada duplikat)
- Tahun Masuk harus berupa angka (YYYY)
- Jumlah kolom harus sesuai (3 kolom)

---

### 2. Data Matakuliah
Import data matakuliah/mata pelajaran.

**Format CSV:**
- Kolom A: Kode Matakuliah - **WAJIB**
- Kolom B: Nama Matakuliah - **WAJIB**
- Kolom C: Semester - **WAJIB** (1, 2, 3, 4, dll)
- Kolom D: Jenis - **WAJIB** (wajib atau pilihan)
- Kolom E: SKS (Satuan Kredit Semester) - **WAJIB**, nilai 1-6

**Contoh:**
```csv
Kode,Nama,Semester,Jenis,SKS
MAT101,Matematika Dasar,1,wajib,3
FIS101,Fisika Dasar,1,wajib,3
SIM101,Sistem Informasi,3,pilihan,2
ALG101,Algoritma,2,wajib,3
WEB101,Pemrograman Web,3,wajib,3
```

**Ketentuan:**
- Kode Matakuliah harus unik (tidak boleh ada duplikat)
- SKS harus angka antara 1-6
- Semester harus angka positif
- Jenis hanya boleh "wajib" atau "pilihan" (huruf kecil)

---

### 3. Data Nilai (Tidak Tergabung dalam Batch)
Fitur import nilai memerlukan mappging dua data sekaligus (mahasiswa + matakuliah), sehingga:

**Format CSV:**
- Kolom A: NIM Mahasiswa
- Kolom B: Nama Mahasiswa
- Kolom C: Kode Matakuliah
- Kolom D: Nama Matakuliah
- Kolom E: Grade (A, B, C, D, E)
- Kolom F: Tahun Ajaran

---

## Langkah-Langkah Menggunakan Fitur Import

### 1. Buka Halaman Import
- Login dengan akun **Ketua Prodi**
- Di Admin Dashboard, klik **"Import Data"**

### 2. Pilih Jenis Data
- Pilih salah satu:
  - **Mahasiswa** - untuk import data mahasiswa
  - **Matakuliah** - untuk import data matakuliah
  - **Nilai** - untuk import data nilai

### 3. Siapkan File CSV
- Buka template CSV yang disediakan di folder `templates_import/`
  - `mahasiswa_template.csv` - untuk template mahasiswa
  - `matakuliah_template.csv` - untuk template matakuliah
- Isi data sesuai dengan kolom yang sudah ditentukan
- Simpan file dengan format CSV (UTF-8)

### 4. Pilih File
- Klik tombol **"Pilih File"**
- Cari dan pilih file CSV yang sudah disiapkan

### 5. Review Template
- Sistem akan menampilkan format yang benar di bagian **"Format Template Excel"**
- Pastikan data Anda sesuai dengan format yang ditampilkan

### 6. Klik Import
- Klik tombol **"Import Data"** untuk memulai proses
- Tunggu hingga proses selesai

### 7. Lihat Hasil
- Sistem akan menampilkan:
  - ✅ Jumlah data yang berhasil diimport
  - ❌ Jumlah data yang gagal diimport
  - 📋 Daftar error untuk setiap baris yang problematik

---

## Tips & Trik

### ✅ Cara Membuat File CSV yang Benar

**Menggunakan Microsoft Excel:**
1. Buka Excel
2. Isi data sesuai format yang ditentukan
3. Perhatikan baris pertama adalah header (NIM, Nama, Email, dll)
4. File > Save As > Format: "CSV UTF-8 (Comma Delimited)"
5. Pilih lokasi dan simpan

**Menggunakan Google Sheets:**
1. Buka Google Sheets dan buat sheet baru
2. Isi data sesuai format
3. File > Download > CSV (current sheet)
4. File akan terunduh dalam format CSV

**Menggunakan Text Editor (VS Code, Notepad++):**
1. Ketik data dengan delimiter koma (,)
2. Baris pertama adalah header
3. Simpan dengan extension `.csv`
4. Encoding: UTF-8

---

## Troubleshooting

### ❌ Error: "Baris X: NIM dan Nama harus diisi"
**Solusi:** Pastikan kolom A (NIM) dan B (Nama) tidak kosong untuk setiap baris data.

### ❌ Error: "Baris X: NIM sudah terdaftar"
**Solusi:** Data mahasiswa dengan NIM tersebut sudah ada di database. Gunakan NIM yang berbeda atau skip baris tersebut.

### ❌ Error: "Baris X: Tahun Masuk harus berupa angka"
**Solusi:** Format tahun masuk harus berupa angka (misal: 2022, 2023). Jangan gunakan format lain seperti "Tahun 2022".

### ❌ Error: "Baris X: SKS harus antara 1-6"
**Solusi:** Nilai SKS hanya valid antara 1-6. Periksa kembali kolom C untuk nilai SKS.

### ❌ Error: "Baris X: Grade harus A, B, C, D, atau E"
**Solusi:** Grade hanya menerima nilai A, B, C, D, atau E (huruf kapital). Jangan gunakan nilai numerik atau huruf kecil.

### ❌ File tidak bisa dipilih
**Solusi:** Pastikan file dalam format CSV (.csv) atau Excel (.xlsx, .xls). File tidak boleh dalam format PDF atau bentuk lain.

---

## Kapasitas & Batas

- **Maksimal baris per import:** Tidak terbatas
- **Ukuran file maksimal:** Tergantung ukuran RAM perangkat
- **Rekomendasi:** Import maksimal 1000 baris sekaligus untuk performa optimal

---

## Template File

Template file CSV sudah disediakan di folder:
```
cpl/templates_import/
├── mahasiswa_template.csv
├── matakuliah_template.csv
└── nilai_template.csv (jika ada)
```

Anda bisa mendownload template ini dan langsung mengisinya dengan data Anda.

---

## FAQ

**Q: Apakah bisa import lebih dari 1000 mahasiswa sekaligus?**
A: Ya, bisa. Tidak ada batasan jumlah, tetapi untuk performa terbaik, sebaiknya import maksimal 1000 baris per kali.

**Q: Bagaimana jika ada error di tengah proses?**
A: Sistem akan menampilkan laporan detail tentang baris mana yang error dan alasannya. Anda bisa memperbaiki data tersebut dan mencoba import ulang.

**Q: Apakah data lama akan terhapus saat import?**
A: Tidak. Data lama akan tetap ada. Import hanya menambah data baru (jika NIM/Kode belum ada) atau skip jika sudah ada.

**Q: Format file apa yang didukung?**
A: CSV (.csv) dan Excel (.xlsx, .xls). Untuk hasil terbaik, gunakan format CSV dengan encoding UTF-8.

---

**Dibuat untuk aplikasi CPL Versi 1.0**
Untuk pertanyaan lebih lanjut, hubungi administrator sistem.
