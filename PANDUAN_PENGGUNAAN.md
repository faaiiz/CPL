# Panduan Setup & Penggunaan Sistem CPL

## 📦 Setup Awal

### 1. Instalasi Dependencies
```bash
cd cpl
flutter pub get
```

### 2. Run Aplikasi
```bash
flutter run
```

### 3. Login Pertama Kali
Gunakan akun default admin:
- **Username**: admin
- **Password**: Admin123

## 🎯 Alur Penggunaan

### Phase 1: Setup Data Master

#### 1. Tambah Matakuliah
1. Dari Dashboard Admin, klik "Kelola Matakuliah"
2. Klik tombol "+" untuk tambah matakuliah baru
3. Isi data:
   - Kode (contoh: TI101)
   - Nama Matakuliah
   - SKS (kredit)
   - Semester
   - Nama Dosen (opsional)
4. Simpan

#### 2. Import Data Mahasiswa
1. Klik "Import Excel"
2. Pilih tipe "Mahasiswa"
3. Siapkan file Excel dengan format:
   ```
   NIM | Nama | Email | Nomor HP | Alamat | Tahun Masuk
   1701234001 | Budi Santoso | budi@email.com | 081234567890 | Jl. Merdeka | 2017
   1702234001 | Siti Nurhaliza | siti@email.com | 082234567890 | Jl. Ahmad Yani | 2017
   ```
4. Upload file
5. Sistem akan validasi dan import data

#### 3. Upload RPS Per Matakuliah
1. Klik "Kelola RPS"
2. Pilih matakuliah
3. Upload file PDF/DOC RPS
4. Optional: Input mapping dengan CPL

### Phase 2: Input Nilai Mahasiswa

#### Option A: Input Manual Per Matakuliah
1. Klik "Input Nilai"
2. Pilih matakuliah
3. Pilih tahun ajaran
4. Input nilai untuk setiap mahasiswa (Grade: A/B/C/D/E)
5. Simpan

#### Option B: Import dari Excel
1. Klik "Import Excel"
2. Pilih tipe "Nilai"
3. Siapkan file Excel dengan format:
   ```
   NIM | Nama Mahasiswa | Kode Matakuliah | Nama Matakuliah | Grade | Tahun Ajaran
   1701234001 | Budi Santoso | TI101 | Algoritma | A | 2024
   1702234001 | Siti Nurhaliza | TI101 | Algoritma | B | 2024
   ```
4. Upload dan sistem akan validasi serta import

**Important**: Pastikan NIM dan Kode Matakuliah sudah ada di sistem

### Phase 3: Hitung CPL

1. Klik "Hitung CPL" dari dashboard
2. Review kriteria perhitungan:
   - IPK ≥ 2.0 (Bobot 60%)
   - Rata-rata Nilai ≥ 2.0 (Bobot 40%)
   - Total SKU ≥ 144
3. Klik "Hitung CPL Semua Mahasiswa"
4. Tunggu proses selesai
5. Sistem akan otomatis menentukan status: LULUS atau TIDAK LULUS

### Phase 4: Lihat Laporan

1. Klik "Laporan CPL"
2. Lihat statistik:
   - Total mahasiswa
   - Jumlah yang lulus
   - Jumlah yang tidak lulus
   - Rata-rata IPK
3. Cari mahasiswa spesifik menggunakan search
4. Filter berdasarkan status (Lulus/Tidak Lulus)
5. Klik expand untuk melihat detail CPL per mahasiswa

## 📊 Format Data

### Grade Conversion
| Grade | Nilai Numerik | Deskripsi |
|-------|---------------|-----------|
| A | 4.0 | Excellent |
| B | 3.0 | Good |
| C | 2.0 | Average |
| D | 1.0 | Poor |
| E | 0.0 | Fail |

### IPK Calculation Example
```
Mahasiswa: Budi Santoso

Nilai:
- Algoritma (3 SKS): A (4.0)
- Pemrograman (4 SKS): B (3.0)
- Database (3 SKS): A (4.0)
- Sistem Operasi (3 SKS): C (2.0)

IPK = (4.0×3 + 3.0×4 + 4.0×3 + 2.0×3) / (3+4+3+3)
    = (12 + 12 + 12 + 6) / 13
    = 42 / 13
    = 3.23

Status CPL:
- IPK 3.23 ≥ 2.0 ✓
- Rata-rata Nilai 3.25 ≥ 2.0 ✓
- Total SKU 13 ≥ 144 ✗ (masih tidak cukup)

Result: TIDAK LULUS (belum cukup SKU)
```

## 🔄 Workflow Rekomendasi

### Setiap Semester
1. Pastikan RPS sudah ter-upload untuk semua matakuliah
2. Input nilai untuk semua mahasiswa di akhir semester
3. Jalankan perhitungan CPL
4. Review laporan
5. Export hasil untuk archive

### Setiap Tahun Akademik
1. Validasi data mahasiswa baru
2. Update status mahasiswa (aktif/lulus/cuti/drop)
3. Generate laporan komprehensif
4. Analisis trend CPL

## ⚠️ Tips & Best Practices

### Validasi Data Sebelum Import
- Pastikan NIM format konsisten
- Periksa duplikasi NIM
- Verifikasi Kode Matakuliah
- Periksa format Grade (hanya A-E)

### Pencegahan Kesalahan
1. **Backup reguler**: Backup database sebelum operasi besar
2. **Test import**: Test dengan data sampel dulu
3. **Verify hasil**: Selalu verifikasi hasil import
4. **Double check**: Review nilai sebelum hitung CPL

### Performance Tips
- Untuk 800+ mahasiswa, lakukan import dalam batch
- Hitung CPL pada waktu non-peak hours
- Jangan edit nilai setelah CPL dihitung (hitung ulang jika perlu)

## 🆘 Troubleshooting

### Import Gagal
**Problem**: File Excel tidak ter-import dan ada error
**Solution**:
1. Periksa format kolom (urutannya harus tepat)
2. Pastikan tidak ada merged cells
3. Validasi tipe data (angka harus angka, text harus text)
4. Cek encoding file (gunakan UTF-8)

### CPL Tidak Terhitung
**Problem**: Setelah hitung CPL, data masih kosong
**Solution**:
1. Periksa apakah sudah ada nilai untuk mahasiswa
2. Pastikan minimal ada 1 nilai per mahasiswa
3. Cek apakah mahasiswa status "aktif"

### Password Lupa
**Problem**: Lupa password admin
**Solution**:
1. Reset manual database (hapus file database)
2. Aplikasi akan buat admin baru otomatis
3. Username/Password: admin / Admin123

## 📞 FAQ

**Q: Berapa maksimal mahasiswa yang bisa di-handle?**
A: Sistem sudah teruji untuk 800 mahasiswa, bisa lebih tapi performa mungkin menurun

**Q: Bisa menghapus nilai yang sudah input?**
A: Ya, bisa dari menu Edit/Hapus Nilai, tapi pastikan calculated CPL di-hitung ulang

**Q: Apakah bisa tracking history perubahan nilai?**
A: Belum ada fitur audit trail, tapi semua data menyimpan timestamp created_at dan updated_at

**Q: Bagaimana jika ada mahasiswa yang tidak memiliki nilai untuk semua matakuliah?**
A: CPL tetap akan dihitung berdasarkan nilai yang ada. Pastikan data lengkap untuk hasil akurat.

---

**Last Updated**: February 2026
**Version**: 1.0
