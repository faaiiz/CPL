# Panduan Fitur Batch Import Nilai

## Deskripsi Fitur

Fitur **Batch Import Nilai** memungkinkan Anda untuk mengimport multiple file nilai dalam satu tahun ajaran yang sama sekaligus. Ini sangat berguna ketika Anda memiliki data nilai dari beberapa mata kuliah yang perlu diimport untuk satu tahun akademik.

## Keunggulan Batch Import

- ✅ **Mengimport multiple files sekaligus** - Tidak perlu satu per satu
- ✅ **Tahun ajaran terpadu** - Semua file diimport untuk tahun yang sama
- ✅ **Progress tracking** - Melihat progress real-time saat import
- ✅ **Error reporting detail** - Laporan error per file
- ✅ **Flexible format** - Support format detail maupun sederhana

## Cara Penggunaan

### 1. Akses Fitur
- Buka halaman **Input Nilai**
- Klik tombol **Cloud Upload** (☁) di pojok kanan atas
- Akan masuk ke halaman **Batch Import Nilai**

### 2. Pilih Tahun Ajaran
- Gunakan dropdown untuk memilih tahun ajaran (misal: 2024)
- **Penting:** Semua file akan diimport untuk tahun yang sama

### 3. Pilih File
- Klik area upload atau tombol **"Klik untuk menambah file"**
- Pilih 1 atau lebih file Excel (.xlsx) atau CSV
- File dapat ditambahkan secara bertahap

### 4. Kelola File
- Lihat daftar file yang dipilih
- Hapus file individual dengan tombol ✕
- Hapus semua file dengan tombol **"Hapus Semua"**

### 5. Mulai Import
- Klik tombol **"Mulai Import Batch"**
- Monitor progress dan pesan proses

## Format File yang Didukung

### Format Detail (Rekomendasi)
**Kolom:** NIM | Nama | Aktivitas | Tugas | Kuis | UTS | UAS

```
NIM       | Nama Mahasiswa  | Aktivitas | Tugas | Kuis | UTS | UAS
2401001   | Ahmad Hidayat   | 80        | 85    | 75   | 70  | 80
2401002   | Budi Santoso    | 90        | 88    | 85   | 80  | 88
```

**Sistem akan otomatis menghitung:**
- Nilai Akhir = (Aktivitas×10% + Tugas×20% + Kuis×20% + UTS×25% + UAS×25%)
- Grade otomatis: A (≥85), B (≥70), C (≥60), D (≥45), E (<45)

### Format Sederhana
**Kolom:** NIM | Nama | Grade/Nilai

```
NIM       | Nama Mahasiswa  | Grade    atau    Nilai
2401001   | Ahmad Hidayat   | A        atau    85
2401002   | Budi Santoso    | B        atau    75
```

- **Grade**: Harus A, B, C, D, atau E
- **Nilai Numerik**: 0-100

## Informasi yang Ditampilkan

### Selama Import
- **Progress bar** - Menunjukkan kemajuan upload
- **Status file** - File yang sedang diproses

### Setelah Import
- **Statistik keseluruhan:**
  - Total file diproses
  - Total nilai berhasil
  - Total nilai gagal

- **Detail per file:**
  - Nama file
  - Status (✓ Berhasil / ⚠ Gagal)
  - Jumlah nilai berhasil
  - Jumlah nilai gagal

- **Error log:**
  - Daftar error yang terjadi
  - Nomor baris yang bermasalah
  - Deskripsi masalah

## Tips & Trik

### ✓ Best Practices
1. **Siapkan template terlebih dahulu** - Download template dari fitur Individual Import untuk referensi format
2. **Validasi data sebelum import** - Pastikan semua NIM dan nilai valid
3. **Gunakan format detail** - Lebih informatif daripada format sederhana
4. **Batch file berdasarkan kategori** - Misal: file untuk semester ganjil atau genap tertentu
5. **Simpan error log** - Gunakan untuk koreksi dan import ulang

### ⚠ Hal yang Perlu Diperhatikan
1. **File harus .xlsx atau .csv** - Format lain tidak didukung
2. **Header harus ada** - File harus mempunyai baris header
3. **Kolom harus lengkap** - Semua kolom wajib ada
4. **Nilai harus valid** - Grade A-E atau numerik 0-100
5. **NIM tidak boleh kosong** - Setiap baris harus punya NIM

## Troubleshooting

### Masalah: "File kosong"
- Pastikan file Excel sudah mempunyai data
- Cek apakah sheet Excel terbuka dengan benar

### Masalah: "NIM dan Nama harus diisi"
- Pastikan kolom NIM (kolom A) tidak kosong
- Pastikan kolom Nama (kolom B) tidak kosong

### Masalah: "Nilai harus berupa angka"
- Gunakan format numerik untuk nilai (0-100)
- Jangan gunakan simbol atau text selain grade A-E

### Masalah: "Tahun Ajaran harus berupa angka"
- Input hanya tahun (misal: 2024, bukan 2024/2025)

### Masalah: File tidak bisa dipilih
- Pastikan file .xlsx atau .csv (bukan .xls atau format lain)
- Periksa file tidak sedang dibuka aplikasi lain

## Contoh Workflow Lengkap

1. **Siapkan data nilai dari 3 mata kuliah:**
   - nilai_mk1_2024.xlsx (Algoritma & Pemrograman)
   - nilai_mk2_2024.xlsx (Struktur Data)
   - nilai_mk3_2024.xlsx (Database)

2. **Buka Batch Import Nilai**

3. **Pilih Tahun Ajaran 2024**

4. **Pilih ketiga file sekaligus**

5. **Klik "Mulai Import Batch"**

6. **Tunggu hingga selesai (~10-30 detik tergantung jumlah data)**

7. **Cek hasil:**
   - Dari 150 nilai (50 per file)
   - Misal: 145 berhasil, 5 gagal
   - Perbaiki 5 error dan import ulang

## FAQ

**Q: Apakah bisa import file yang sudah pernah diimport?**
A: Sistem akan mendeteksi duplikat dan mencegah double entry

**Q: Berapa banyak file maksimal bisa diimport sekaligus?**
A: Tidak ada batasan, tapi rekomendasi 5-10 file untuk kecepatan optimal

**Q: File mana yang diproses duluan?**
A: Sesuai urutan dipilih (urutan dalam daftar file)

**Q: Apakah data akan terimport jika ada 1 file error?**
A: Ya, hanya file yang error yang tidak terimpor, file lain tetap diproses

**Q: Bisakah export kembali hasil import?**
A: Gunakan fitur Export di halaman Nilai untuk export data

## Kontribusi & Feedback

Jika menemukan bug atau punya saran perbaikan, silakan laporkan melalui issue tracker aplikasi.
