# Update Tampilan CPL - Identik dengan CPMK

## Ringkasan Perubahan

Telah dilakukan refactoring lengkap pada tampilan CPL (Capaian Pembelajaran Lulusan) agar identik dengan CPMK (Capaian Pembelajaran Mata Kuliah) di file `lib/screens/admin_dashboard_screen.dart`.

## Perubahan Utama

### 1. **Struktur Tabel Terpisah**
   - **Sebelumnya**: CPL dan CPMK ditampilkan dalam satu tabel dengan kolom gabung
   - **Sekarang**: CPMK dan CPL ditampilkan dalam dua tabel terpisah untuk clarity yang lebih baik

### 2. **Summary Cards**
   - Ditambahkan dua kartu ringkasan di atas tabel:
     - Rata-rata CPMK (warna hijau #27AE60)
     - Rata-rata CPL (warna ungu #8E44AD)
   - Summary menghitung rata-rata dari semua nilai per kategori

### 3. **Tabel CPMK** (`_buildCPMKTable`)
   - Menampilkan data untuk setiap mahasiswa
   - Kolom: No, NIM, Nama Mahasiswa, CPMK.1, CPMK.2, dst
   - Header dikelompokkan berdasarkan ID CPMK
   - Warna teks: Hijau (#27AE60)
   - Loading dan error states handling

### 4. **Tabel CPL** (`_buildCPLTable`)
   - Struktur identik dengan tabel CPMK
   - Menampilkan data untuk setiap mahasiswa
   - Kolom: No, NIM, Nama Mahasiswa, CPL.1, CPL.2, dst
   - Header dikelompokkan berdasarkan ID CPL
   - Warna teks: Ungu (#8E44AD)
   - Loading dan error states handling

### 5. **Styling & Layout**
   - Kedua tabel dibungkus dalam Card dengan elevation
   - Header section dengan icon dan judul deskriptif
   - Responsive horizontal scrolling untuk kolom yang banyak
   - Padding dan spacing konsisten menggunakan AppSpacing constants

## Fitur-Fitur Baru

### ✅ Summary Cards
```dart
Rata-rata CPMK: 75.50  |  Rata-rata CPL: 78.25
```

### ✅ Format Header Dinamis
- Kolom secara otomatis dibuat berdasarkan ID unik di data
- Contoh: CPMK.1, CPMK.2, CPMK.3 (jika ada 3 CPMK)
- Contoh: CPL.1, CPL.2 (jika ada 2 CPL)

### ✅ Visual Consistency
- Warna konsisten untuk CPMK (hijau) dan CPL (ungu)
- Icon yang relevan (school untuk CPMK, flag untuk CPL)
- Styling yang identik untuk kedua tabel

### ✅ Robust Error Handling
- Loading state dengan CircularProgressIndicator
- Error state dengan pesan yang jelas
- Empty state jika tidak ada data

## Perubahan Method

### Ditambahkan
- `_buildCPMKTable()` - Widget tabel CPMK dengan header dinamis
- `_buildCPLTable()` - Widget tabel CPL dengan header dinamis

### Dimodifikasi
- `_buildBatchCalculationResults()` - Sekarang menampilkan summary cards + dua tabel terpisah

### Deprecated (masih ada untuk reference)
- `_buildBatchSummaryTable()` - Digantikan oleh dua method baru

## Testing

Telah dikompilasi dengan `dart analyze` tanpa error syntax. Hanya ada beberapa info warning tentang:
- Unused method (`_buildBatchSummaryTable`) - sudah deprecated
- Print statements untuk debugging
- BuildContext across async gaps - sudah ditangani dengan `mounted` checks

## Penggunaan

### Tampilan CPL sekarang menampilkan:
1. **Summary Section**
   - Rata-rata CPMK keseluruhan
   - Rata-rata CPL keseluruhan

2. **Tabel CPMK**
   - Daftar mahasiswa dengan nilai CPMK mereka
   - Kolom per CPMK ID

3. **Tabel CPL**
   - Daftar mahasiswa dengan nilai CPL mereka
   - Kolom per CPL ID

## Kompatibilitas

- ✅ Backward compatible dengan data structure lama
- ✅ Dynamic column generation berdasarkan data aktual
- ✅ Responsive design dengan horizontal scrolling
- ✅ Semua constants menggunakan AppSpacing dan AppColors

## Next Steps (Optional)

Jika diperlukan enhancement lebih lanjut:
- [ ] Export tabel ke Excel
- [ ] Filter/sorting per mahasiswa
- [ ] Comparison view antara CPMK dan CPL
- [ ] Chart/graph untuk visualisasi
