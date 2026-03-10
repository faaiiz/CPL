# Dokumentasi Perubahan: Single Matakuliah Nilai Import

## Ringkasan Perubahan

Fitur batch import nilai telah diefisienkan menjadi single matakuliah import yang lebih sederhana dan user-friendly.

### Alasan Perubahan
- **Workflow lebih sederhana**: User fokus pada satu matakuliah per sesi
- **Template yang akurat**: Template disesuaikan dengan kode dan nama matakuliah yang dipilih
- **Pengalaman pengguna lebih baik**: Antarmuka lebih intuitif dan mudah dipahami
- **Error handling lebih baik**: Lebih mudah untuk mengidentifikasi masalah dengan data spesifik matakuliah

## Fitur Auto

### Sebelum (Batch Import)
```
Tahun Ajaran → Multiple Files Selection → Import Semua Sekaligus
```

### Sesudah (Single Matakuliah Import)
```
Tahun Ajaran → Pilih Matakuliah → Download Template (Spesifik)
    → Pilih File → Import ke Matakuliah Tertentu
```

## Perubahan Teknis

### File yang Dimodifikasi
- **`lib/screens/nilai_batch_import_screen.dart`** (DIREFACTOR)
  - Mengubah dari `NilaiBatchImportService` ke `ExcelImportService`
  - Menambahkan dropdown pemilihan matakuliah
  - Mengubah file picker dari multiple ke single file
  - Memanggil `downloadNilaiSingleMatakuliahTemplate()` untuk template spesifik matakuliah

### Services yang Digunakan
- `ExcelImportService.importNilaiDetailFromExcel()` - Import nilai detail dengan filter matakuliah
- `TemplateService.downloadNilaiSingleMatakuliahTemplate()` - Download template untuk matakuliah spesifik
- `DatabaseHelper.getAllMatakuliah()` - Fetch list matakuliah untuk dropdown

### State Variables Baru
```dart
List<Matakuliah> _matakuliahList = [];        // List matakuliah dari DB
int? _selectedMatakuliahId;                   // ID matakuliah dipilih
Matakuliah? _selectedMatakuliah;              // Object matakuliah dipilih
String? _selectedFilePath;                    // Path file dipilih (single)
String? _selectedFileName;                    // Nama file dipilih
bool _isLoadingMatakuliah = false;            // Loading state untuk fetch matakuliah
```

## Workflow Pengguna

### Step 1: Load Aplikasi
- Aplikasi otomatis meload list matakuliah dari database
- Dropdown matakuliah ditampilkan dengan format: `KODE - NAMA`

### Step 2: Pilih Tahun Ajaran
- User memilih tahun akademik (2020-2031)
- Default: tahun terbaru

### Step 3: Pilih Matakuliah
- User memilih satu matakuliah dari dropdown
- Diperlukan sebelum download template

### Step 4: Download Template
- User klik "Download Template Excel"
- Template otomatis berisi:
  - Kode Matakuliah
  - Nama Matakuliah
  - Tahun Ajaran
  - Header kolom: NIM | Nama Mahasiswa | Aktivitas | Hasil Proyek | Kuis | Tugas | UTS | UAS

### Step 5: Isi Data di Excel
- User membuka template di Excel/LibreOffice
- Isi data nilai mahasiswa sesuai format
- Simpan file

### Step 6: Import File
- User klik "Klik untuk memilih file"
- Pilih file Excel yang sudah diisi
- File ditampilkan dengan option untuk di-remove
- Klik "Mulai Import" untuk memulai proses

### Step 7: Lihat Hasil
- Progress indicator menunjukkan status
- Hasil import menampilkan:
  - Status (Berhasil/Gagal)
  - Jumlah nilai berhasil diimport
  - Jumlah nilai gagal
  - Error log (sampel 20 error pertama)

## Format File Excel yang Diterima

### Kolom yang Wajib
1. **NIM** - ID mahasiswa (dari database)
2. **Nama Mahasiswa** - Nama lengkap mahasiswa
3. **Aktivitas Partisipatif** - Nilai 0-100
4. **Hasil Proyek** - Nilai 0-100
5. **Kuis** - Nilai 0-100
6. **Tugas** - Nilai 0-100
7. **UTS** - Nilai 0-100
8. **UAS** - Nilai 0-100

### Catatan
- Semua nilai harus numerik (0-100)
- NIM dan Nama harus ada (tidak boleh kosong)
- Sistem akan otomatis menyimpan ke database

## Keuntungan Perubahan

✅ **Lebih Mudah Digunakan**
- Workflow yang jelas dan terurut
- Tidak perlu memilih multiple file

✅ **Template Akurat**
- Template disesuaikan dengan matakuliah yang dipilih
- Informasi matakuliah tertanam di template

✅ **Fokus Per Matakuliah**
- User dapat import nilai per matakuliah secara terpisah
- Lebih mudah menangani error per matakuliah

✅ **Better Error Handling**
- Error log lebih spesifik
- Memudahkan debugging

## Backward Compatibility

- Screen route `/nilai_batch_import` tetap sama
- Class name `NilaiBatchImportScreen` tetap sama
- `NilaiBatchImportService` masih tersedia untuk keperluan lain
- Tidak ada breaking changes untuk navigasi atau routing

## Testing Checklist

- [ ] Aplikasi dapat load list matakuliah dari database
- [ ] Dropdown matakuliah menampilkan data dengan format `KODE - NAMA`
- [ ] Download template bekerja untuk matakuliah yang dipilih
- [ ] File picker dapat memilih file Excel/CSV
- [ ] Import hanya menerima file Excel/CSV
- [ ] Hasil import menampilkan jumlah berhasil/gagal
- [ ] Error log menampilkan error detail jika ada
- [ ] Data nilai tersimpan di database dengan benar

## Notes untuk Developer

1. **Matakuliah Loading**: List matakuliah di-load di `initState()`. Jika matakuliah belum ada di database, user akan melihat pesan "Tidak ada matakuliah ditemukan".

2. **Template Generation**: Template dibuat dengan `TemplateService.downloadNilaiSingleMatakuliahTemplate()` yang menggunakan `excel` package.

3. **Import Service**: Menggunakan `ExcelImportService.importNilaiDetailFromExcel()` dengan parameter `matakuliahFilter` untuk validasi extra.

4. **Error Handling**: Semua error ditangani dengan ScaffoldMessenger untuk memberikan feedback yang jelas kepada user.

## Deprecation Notice

- ❌ `_pickMultipleFiles()` - DIHAPUS
- ❌ `_clearAllFiles()` - DIHAPUS
- ✅ `_pickFile()` - BARU (mengganti multiple selection)
- ❌ Multiple file state variables - DIHAPUS
- ✅ Single file state variables - BARU
