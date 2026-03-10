# RPS Template Excel Import Feature

## Overview
Fitur baru ini memungkinkan import data RPS (Rencana Pembelajaran Semester) secara massal melalui file Excel template, dengan otomatis memverifikasi kode dan nama mata kuliah sesuai database.

## Lokasi Feature
- **Menu**: Tersedia di halaman "Input RPS" dengan tombol upload Excel di AppBar
- **Route**: `/rps_template_import`
- **File Implementasi**:
  - Service: `lib/services/rps_excel_service.dart`
  - Screen: `lib/screens/rps_template_import_screen.dart`
  - Database: Added method `getCPMKByKode()` in `database_helper.dart`

## Cara Penggunaan

### 1. Akses Fitur
- Buka menu "Input RPS" dari dashboard
- Klik tombol upload Excel (icon ⬆) di AppBar

### 2. Download Template
- Pilih mata kuliah yang ingin diisi RPSnya
- Klik "Download Template Excel"
- Template akan diunduh dalam format CSV yang bisa dibuka dengan Excel/Spreadsheet

### 3. Struktur Template Excel
Format Excel template memiliki kolom-kolom berikut:

```
Kolom A: Kode Matakuliah (auto-filled, untuk verifikasi)
Kolom B: Nama Matakuliah (auto-filled, untuk verifikasi)
Kolom C: Minggu Ke (1-16)
Kolom D: Topik Pembelajaran
Kolom E: Metode Ajar (lihat daftar di bawah)
Kolom F: Bobot (%) (0-100)
Kolom G: Kode CPMK (pisahkan dengan semicolon ;)
         Contoh: CPMK.1;CPMK.2;CPMK.3
Kolom H: Kode Sub CPMK (pisahkan dengan semicolon ;)
         Contoh: SUB-CPMK.1;SUB-CPMK.2
Kolom I: Kode CPL (pisahkan dengan semicolon ;)
         Contoh: CPL.1;CPL.2
```

### 4. Metode Ajar yang Valid
- Case Based Learning
- Project Based Learning
- Small Group Discussion
- Discovery Learning
- Contextual Learning
- Contextual Instruction
- Cooperative Learning
- Collaborative Learning

### 5. Proses Import
1. Isi template minimal untuk 14 minggu pembelajaran
2. Pilih file Excel yang sudah diisi
3. Klik "Import RPS"
4. Sistem akan:
   - Memvalidasi setiap baris data
   - Memverifikasi kode dan nama mata kuliah
   - Memverifikasi CPMK, Sub CPMK, dan CPL ada di database
   - Menampilkan daftar error jika ada
   - Import data ke database jika semua valid

## Validasi Data

### Error yang Akan Ditampilkan:
- Mata kuliah tidak ditemukan di database
- Nama mata kuliah tidak sesuai
- Minggu ke di luar range 1-16
- Topik pembelajaran kosong
- Metode ajar tidak valid atau kosong
- Bobot bukan angka atau di luar 0-100
- CPMK/Sub CPMK/CPL tidak ditemukan di database

### Contoh Error Message:
```
Baris 5: Bobot harus berupa angka antara 0-100
Baris 8: CPMK dengan kode "CPMK.99" tidak ditemukan
Baris 10: Sub CPMK dengan kode "SUB.1" tidak ditemukan untuk mata kuliah ini
```

## Fitur Database Helper Baru

### Metode Ditambahkan:
```dart
Future<CPMK?> getCPMKByKode(String kode) async
```
- Mencari CPMK berdasarkan kode
- Digunakan untuk validasi import CPMK dari template

## Contoh Penggunaan Template

### Data Minggu 1:
```
TAK101       | Teknik Algoritma Komputer | 1 | Pengenalan Algoritma | Case Based Learning | 7 | CPMK.1;CPMK.2 | SUB-CPMK.1 | CPL.1;CPL.2
```

### Data Minggu 2:
```
TAK101       | Teknik Algoritma Komputer | 2 | Kompleksitas Algoritma | Project Based Learning | 7 | CPMK.1 | SUB-CPMK.2 | CPL.1
```

## Catatan Penting

1. **Kode dan Nama Harus Sesuai**: Sistem akan menolak jika kode mata kuliah tidak ditemukan atau nama tidak sesuai dengan database
2. **Semicolon Separator**: Gunakan semicolon (;) untuk memisahkan multiple codes, tidak gunakan koma
3. **Case Sensitive**: Kode CPMK/Sub CPMK/CPL harus sesuai persis dengan database (case sensitive)
4. **Empty Cells**: Jika CPMK/Sub CPMK/CPL kosong pada minggu tertentu, biarkan sel kosong (jangan isi apapun)
5. **Bobot Total**: Import tidak memvalidasi total bobot (bisa dilakukan validasi manual setelah import)

## Troubleshooting

**Q: "Mata kuliah dengan kode XXX tidak ditemukan"**
A: Pastikan kode mata kuliah sudah dibuat di menu "Matakuliah" dan kodenya sesuai di template

**Q: "Nama mata kuliah tidak sesuai dengan database"**
A: Nama di template harus exactly match dengan yang ada di database (termasuk spasi dan capitalization)

**Q: "CPMK/Sub CPMK tidak ditemukan"**
A: Pastikan sudah membuat CPMK/Sub CPMK terlebih dahulu di menu "Kelola CPMK" atau "Input SUB CPMK"

**Q: Error formatting Excel**
A: Gunakan format CSV atau Excel standard. Jika menggunakan Excel modern, export terlebih dahulu ke CSV sebelum diimport
