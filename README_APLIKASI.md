# Sistem Capaian Pembelajaran Lulusan (CPL)

Aplikasi Flutter untuk mengelola dan menghitung Capaian Pembelajaran Lulusan (CPL) untuk mahasiswa.

## 📋 Fitur Utama

### 1. **Authentication & Authorization**
- Login dengan username dan password
- Dua tipe user: Admin (Ketua Prodi) dan Mahasiswa
- Enkripsi password menggunakan SHA-256
- Inisialisasi admin otomatis (username: `admin`, password: `Admin123`)

### 2. **Manajemen Data Master**
- **Mahasiswa**: Tambah, edit, hapus data mahasiswa (NIM, nama, email, telp, alamat, tahun masuk)
- **Matakuliah**: Kelola daftar matakuliah (kode, nama, SKS, semester, dosen)
- **Nilai**: Input dan edit nilai mahasiswa per matakuliah dengan grade A-E

### 3. **Import Data**
- Import data mahasiswa dari file Excel
- Import nilai mahasiswa dari file Excel
- Validasi data dan error reporting
- Duplikasi checking

### 4. **Upload RPS (Rencana Pembelajaran Semester)**
- Upload file PDF/DOC untuk setiap matakuliah
- Mapping dengan CPL (Learning Outcomes)
- Manajemen dokumen RPS

### 5. **Perhitungan CPL**
- Perhitungan otomatis CPL berdasarkan:
  - **IPK** (60%): Nilai rata-rata tertimbang dengan SKS
  - **Rata-rata Nilai** (40%): Rata-rata nilai numerik
  - **Total SKU**: Jumlah SKU yang diambil
- Kriteria Lulus:
  - IPK ≥ 2.0
  - Rata-rata Nilai ≥ 2.0
  - Total SKU ≥ 144

### 6. **Laporan & Analisis**
- Laporan CPL dengan filter status
- Statistik ketercapaian CPL
- Export data untuk analisis lebih lanjut
- View detail CPL per mahasiswa

### 7. **Dashboard**
- **Admin**: Dashboard dengan menu lengkap untuk semua operasi
- **Mahasiswa**: Melihat nilai dan CPL sendiri (coming soon)

## 🛠️ Tech Stack

- **Framework**: Flutter 3.9.2+
- **Database**: SQLite (lokal)
- **State Management**: Provider
- **File Handling**: file_picker
- **Excel**: excel package
- **PDF**: pdf & printing
- **Encryption**: crypto, bcrypt
- **Date**: intl

## 📁 Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/                  # Data models
│   ├── user_model.dart
│   ├── mahasiswa_model.dart
│   ├── matakuliah_model.dart
│   ├── nilai_model.dart
│   ├── rps_model.dart
│   └── cpl_model.dart
├── services/               # Business logic & database
│   ├── database_helper.dart
│   ├── authentication_service.dart
│   ├── excel_import_service.dart
│   ├── cpl_calculation_service.dart
│   └── rps_upload_service.dart
├── screens/                # UI Screens
│   ├── login_screen.dart
│   ├── admin_dashboard_screen.dart
│   ├── mahasiswa_screen.dart
│   ├── excel_import_screen.dart
│   ├── cpl_calculation_screen.dart
│   ├── cpl_report_screen.dart
│   └── placeholder_screens.dart
├── widgets/               # Reusable widgets
│   └── custom_widgets.dart
├── constants/             # App constants
│   └── app_constants.dart
└── utils/                 # Utility functions
    └── app_utils.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter 3.9.2 atau lebih baru
- Dart SDK
- Android Studio / Xcode (untuk device testing)

### Installation

1. Clone repository
```bash
cd cpl
```

2. Install dependencies
```bash
flutter pub get
```

3. Run aplikasi
```bash
flutter run
```

## 📊 Database Schema

### Users Table
- id (PK)
- username (UNIQUE)
- password (hashed)
- role (admin/mahasiswa)
- nama
- nim (nullable)
- is_active
- created_at, updated_at

### Mahasiswa Table
- id (PK)
- nim (UNIQUE)
- nama
- email, nomor_hp, alamat
- tahun_masuk
- status (aktif/lulus/cuti/drop)
- is_active
- created_at, updated_at

### Matakuliah Table
- id (PK)
- kode (UNIQUE)
- nama
- sks
- semester
- dosen
- deskripsi
- is_active
- created_at, updated_at

### Nilai Table
- id (PK)
- mahasiswa_id (FK)
- matakuliah_id (FK)
- grade_huruf (A-E)
- nilai_numerik (0.0-4.0)
- catatan
- tahun_ajaran
- created_at, updated_at
- UNIQUE(mahasiswa_id, matakuliah_id, tahun_ajaran)

### RPS Table
- id (PK)
- matakuliah_id (FK)
- file_path
- file_name
- deskripsi
- cpl_mappings
- upload_date
- updated_at

### CPL Table
- id (PK)
- mahasiswa_id (FK)
- nip_mahasiswa
- nama_mahasiswa
- ipk
- status (belum_lulus/memenuhi_cpl/tidak_memenuhi_cpl)
- total_sku
- rata_nilai
- catatan
- tanggal_hitung
- updated_at

## 📝 Format File Excel

### Import Nilai
```
NIM | Nama Mahasiswa | Kode Matakuliah | Nama Matakuliah | Grade | Tahun Ajaran
```
- Grade: A, B, C, D, atau E
- Tahun Ajaran: Format angka (2024, 2025, dll)

### Import Mahasiswa
```
NIM | Nama | Email | Nomor HP | Alamat | Tahun Masuk
```
- Semua field kecuali NIM dan Nama bisa kosong
- Tahun Masuk: Format angka (2020, 2021, dll)

## 🔐 Security

### Password Hashing
- Menggunakan SHA-256 untuk hashing password
- Password strength validation (minimal 6 karakter, 1 uppercase, 1 number)

### Database Encryption
- SQLite database disimpan lokal pada device
- Setiap user hanya bisa akses data sesuai role

## 📈 CPL Calculation Formula

```
IPK = Σ(grade_numerik × SKS) / Σ(SKS)

Rata-rata Nilai = Σ(grade_numerik) / jumlah_matakuliah

CPL Score = (IPK × 0.6) + (Rata-rata Nilai × 0.4)

Status:
- LULUS jika: IPK ≥ 2.0 AND Rata-rata ≥ 2.0 AND Total SKU ≥ 144
- TIDAK LULUS sebaliknya
```

## 🎯 Future Enhancements

1. **Mahasiswa Dashboard**
   - View nilai pribadi
   - View CPL pribadi
   - Download transkrip nilai

2. **Advanced Analytics**
   - Grafik distribusi nilai per matakuliah
   - Analisis CPL per program studi (jika ada multiple prodi)
   - Trend analisis per tahun akademik

3. **PDF Export**
   - Export laporan CPL ke PDF
   - Certificate generator untuk mahasiswa yang lulus

4. **Email Notification**
   - Notifikasi kepada mahasiswa tentang CPL mereka
   - Reminder untuk update nilai

5. **API Integration**
   - Sync dengan sistem akademik pusat
   - Integration dengan SIAKAD

## 🐛 Known Issues

- Mahasiswa dashboard belum fully implemented
- Matakuliah form belum fully implemented
- Nilai entry form belum fully implemented
- RPS upload belum fully implemented

## 📞 Support

Untuk pertanyaan atau issues, silakan hubungi tim pengembang.

## 📄 License

This project is licensed under the MIT License.
