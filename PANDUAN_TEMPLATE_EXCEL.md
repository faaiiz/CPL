# Panduan Template Excel Untuk Import Data

## Fitur Template Download

Aplikasi CPL sekarang menyediakan file template Excel yang dapat diunduh langsung dari menu Import. Fitur ini memudahkan Anda memastikan format data sesuai dengan yang dibutuhkan sistem.

## Cara Menggunakan

### 1. Membuka Menu Import
- Buka aplikasi CPL
- Klik menu **Import** pada dashboard admin
- Pilih tipe data yang ingin diimport (Mahasiswa, Matakuliah, atau Nilai)

### 2. Mengunduh Template
- Pada halaman Import, terdapat tombol **"Unduh Template [Tipe Data]"** 
- Klik tombol untuk mengunduh template dalam format Excel (.xlsx)
- File akan otomatis diunduh ke folder **Downloads** di perangkat Anda

### 3. Format File Template

#### Template Mahasiswa
| Kolom | Deskripsi | Format |
|-------|-----------|---------|
| A | NIM | Teks, harus unik |
| B | Nama | Teks, nama lengkap mahasiswa |
| C | Tahun Masuk | Angka tahun (contoh: 2022, 2023) |
| D | Status | aktif, lulus, cuti, atau drop |

**Contoh Data:**
```
NIM,Nama,Tahun Masuk,Status
22001,Budi Santoso,2022,aktif
22002,Siti Nurhaliza,2022,aktif
22003,Ahmad Wijaya,2023,aktif
```

#### Template Matakuliah
| Kolom | Deskripsi | Format |
|-------|-----------|---------|
| A | Kode | Teks, kode unik matakuliah |
| B | Nama | Teks, nama lengkap matakuliah |
| C | Semester | Angka 1-8 |
| D | Jenis | wajib atau pilihan |
| E | SKS | Angka (2, 3, 4, dst) |

**Contoh Data:**
```
Kode,Nama,Semester,Jenis,SKS
MAT101,Matematika Dasar,1,wajib,3
FIS101,Fisika Dasar,1,wajib,3
PEM101,Pemrograman Dasar,1,wajib,3
```

#### Template Nilai
| Kolom | Deskripsi | Format |
|-------|-----------|---------|
| A | NIM | Teks, NIM mahasiswa (harus sudah terdaftar) |
| B | Nama Mahasiswa | Teks, nama mahasiswa |
| C | Kode Matakuliah | Teks, kode matakuliah (harus sudah terdaftar) |
| D | Nama Matakuliah | Teks, nama matakuliah |
| E | Grade | A, B, C, D, atau E |
| F | Nilai Numerik | Angka desimal (4.0 untuk A, 3.0 untuk B, dst) |
| G | Tahun Ajaran | Format: tahun/tahunberikutnya (contoh: 2024/2025) |

**Contoh Data:**
```
NIM,Nama Mahasiswa,Kode Matakuliah,Nama Matakuliah,Grade,Nilai Numerik,Tahun Ajaran
22001,Ahmad Rizki,MAT101,Matematika Dasar,A,4.0,2024/2025
22002,Budi Santoso,MAT101,Matematika Dasar,B,3.0,2024/2025
22003,Citra Dewi,FIS101,Fisika Dasar,A,4.0,2024/2025
```

## Petunjuk Penting

### Sebelum Membuat File Data
1. **Unduh template terlebih dahulu** - Jangan membuat file dari nol
2. **Gunakan template yang sesuai** - Pastikan format header tidak berubah
3. **Perhatikan tipe data** - Kolom dengan tipe angka harus berisi angka, bukan teks

### Saat Mengisi Data
- ✅ **Boleh:** Menambah baris data sesuai kebutuhan
- ✅ **Boleh:** Menggunakan nama, deskripsi dalam bahasa Indonesia
- ❌ **Jangan:** Mengubah nama header kolom
- ❌ **Jangan:** Menghapus kolom apa pun
- ❌ **Jangan:** Mengubah urutan kolom
- ❌ **Jangan:** Menggunakan format yang tidak sesuai

### Validasi Data Khusus

#### Mahasiswa
- NIM harus unik (tidak boleh duplikat)
- Tahun Masuk harus berupa angka tahun (2020-2025)
- Status hanya boleh: aktif, lulus, cuti, drop

#### Matakuliah  
- Kode matakuliah harus unik (tidak boleh duplikat)
- Semester harus berupa angka 1-8
- Jenis hanya boleh: wajib atau pilihan
- SKS harus berupa angka (2, 3, 4, 6)

#### Nilai
- NIM dan Kode Matakuliah **harus sudah terdaftar** di sistem
- Grade hanya boleh: A, B, C, D, E
- Nilai Numerik harus sesuai Grade:
  - A = 4.0
  - B = 3.0
  - C = 2.0
  - D = 1.0
  - E = 0.0
- Tahun Ajaran format: YYYY/YYYY (contoh: 2024/2025)

## Langkah Import

1. **Download Template** → Unduh file template sesuai jenis data
2. **Edit Template** → Buka dengan Excel/LibreOffice dan isi data Anda
3. **Konfirmasi Format** → Pastikan semua kolom dan data sudah sesuai
4. **Upload File** → Klik "Pilih File" dan pilih file Excel yang sudah siap
5. **Preview Hasil** → Sistem akan menampilkan preview data yang akan diimport
6. **Klik Import** → Tekan tombol "Import Data" untuk menyelesaikan proses

## Troubleshooting

### Gagal Download Template
- Pastikan aplikasi memiliki akses ke folder Downloads
- Cek koneksi internet
- Coba unduh kembali

### File Tidak Terbaca
- Pastikan format file .xlsx (Excel 2007+)
- Jangan gunakan format .xls lama
- Jangan ubah nama file template

### Error Saat Import
- Periksa format data sesuai panduan di atas
- Pastikan tidak ada baris kosong di data Anda
- Verifikasi bahwa NIM/Kode Matakuliah sudah terdaftar (untuk Nilai)
- Periksa bahwa setiap kolom memiliki data yang benar

## Tips Efisiensi

1. **Gunakan Drag-Fill Excel** - Untuk data yang berurutan atau terulang
2. **Format Data Consistency** - Pastikan format sama untuk semua baris
3. **Verifikasi Sebelum Upload** - Review data 2-3 kali sebelum import
4. **Simpan Backup** - Simpan file asli sebelum upload

---

**Versi:** 1.0  
**Terakhir Diupdate:** 20 Februari 2026
