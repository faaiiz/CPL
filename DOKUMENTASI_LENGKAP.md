# 📋 DOKUMENTASI LENGKAP APLIKASI SISTEM CPL

## 📑 Daftar Isi
1. [Overview Aplikasi](#overview-aplikasi)
2. [Architecture](#architecture)
3. [Database Schema](#database-schema)
4. [Data Models](#data-models)
5. [Services & Business Logic](#services--business-logic)
6. [Screens & Features](#screens--features)
7. [File Structure](#file-structure)
8. [User Flows](#user-flows)

---

## Overview Aplikasi

### Nama Aplikasi
**Sistem CPL (Capaian Pembelajaran Lulusan)** - Aplikasi manajemen pembelajaran untuk institusi pendidikan

### Database
- **Nama Database**: `cpl_app.db`
- **Tipe**: SQLite (sqflite)
- **Version**: 5
- **Lokasi**: Platform-dependent (Android/iOS/Windows)
  - Android: `/data/data/[package_name]/databases/cpl_app.db`
  - Windows: Aplikasi data directory

### Platform Target
- Android
- iOS
- Windows (Desktop)

### Role User
1. **Admin/Ketua Prodi**: Manajemen data, import, dashboard
2. **Mahasiswa**: View nilai, profil CPL

---

## Architecture

### Stack Teknologi
```
┌─────────────────────────────────────┐
│       Flutter UI Layer              │
│  (Screens, Widgets, Navigation)     │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│    Services Layer                   │
│  (Business Logic, Excel Import,     │
│   Template Generation)              │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│    Models Layer                     │
│  (Data Classes, Serialization)      │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│    Database Helper (DatabaseHelper) │
│  (CRUD Operations via SQLite)       │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│    SQLite Database (cpl_app.db)     │
│  (Persistent Data Storage)          │
└─────────────────────────────────────┘
```

### MVC/Direct Service Pattern
- **Views**: Screens di folder `lib/screens/`
- **Models**: Data classes di folder `lib/models/`
- **Controllers**: Services di folder `lib/services/`

---

## Database Schema

### 📊 Tabel-Tabel Utama

#### 1. **users** - Tabel Pengguna
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ username        │ TEXT    │ UNIQUE  │
│ password        │ TEXT    │ -       │
│ role            │ TEXT    │ -       │
│ nama            │ TEXT    │ -       │
│ nim             │ TEXT    │ -       │
│ is_active       │ INTEGER │ DEF: 1  │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

Indeks: UNIQUE (username)
Tujuan: Menyimpan kredensial login pengguna
```

#### 2. **mahasiswa** - Data Mahasiswa
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ nim             │ TEXT    │ UNIQUE  │
│ nama            │ TEXT    │ -       │
│ tahun_masuk     │ INTEGER │ -       │
│ status          │ TEXT    │ DEF: aktif │
│ is_active       │ INTEGER │ DEF: 1  │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

Indeks: UNIQUE (nim)
Tujuan: Master data mahasiswa/siswa
Relasi: 1 mahasiswa → banyak nilai
```

#### 3. **matakuliah** - Mata Kuliah/Course
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ kode            │ TEXT    │ UNIQUE  │
│ nama            │ TEXT    │ -       │
│ semester        │ TEXT    │ -       │
│ jenis           │ TEXT    │ DEF: wajib │
│ sks             │ INTEGER │ (1-6)   │
│ is_active       │ INTEGER │ DEF: 1  │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

Indeks: UNIQUE (kode)
Tujuan: Master data mata kuliah
Contoh: UUW0071 - Aliran Kepercayaan terhadap Tuhan
```

#### 4. **nilai** - Nilai/Grade Mahasiswa
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ mahasiswa_id    │ INTEGER │ FK      │
│ matakuliah_id   │ INTEGER │ FK      │
│ grade_huruf     │ TEXT    │ (A-E)   │
│ nilai_numerik   │ REAL    │ (0-4)   │
│ catatan         │ TEXT    │ NULL    │
│ tahun_ajaran    │ INTEGER │ -       │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: mahasiswa_id → mahasiswa.id
FK: matakuliah_id → matakuliah.id
Indeks: (mahasiswa_id), (matakuliah_id)
UNIQUE: (mahasiswa_id, matakuliah_id, tahun_ajaran)
Tujuan: Track nilai per mahasiswa per mata kuliah
```

#### 5. **cpl_master** - Master CPL (7 CPL Program)
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ kode_cpl        │ TEXT    │ UNIQUE  │
│ deskripsi       │ TEXT    │ -       │
│ nomor           │ TEXT    │ UNIQUE  │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

Contoh Kode: CPL.1, CPL.2, ... CPL.7
Tujuan: 7 Learning Outcomes universitas
```

#### 6. **cpmk** - CPMK (Capaian Pembelajaran Mata Kuliah)
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ matakuliah_id   │ INTEGER │ FK      │
│ kode_cpmk       │ TEXT    │ -       │
│ deskripsi       │ TEXT    │ -       │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: matakuliah_id → matakuliah.id
Indeks: (matakuliah_id)
UNIQUE: (matakuliah_id, kode_cpmk)
Tujuan: Capaian pembelajaran per mata kuliah
Contoh: CPMK.1 (bab 1), CPMK.2 (bab 2), dst
```

#### 7. **sub_cpmk** - Sub-CPMK (Detail CPMK)
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ matakuliah_id   │ INTEGER │ FK      │
│ kode_sub_cpmk   │ TEXT    │ -       │
│ deskripsi       │ TEXT    │ -       │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: matakuliah_id → matakuliah.id
UNIQUE: (matakuliah_id, kode_sub_cpmk)
Tujuan: Detail learning outcomes per bab/minggu
```

#### 8. **rps_detail** - RPS per Minggu
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ matakuliah_id   │ INTEGER │ FK      │
│ minggu_ke       │ INTEGER │ (1-16)  │
│ cpmk_ids        │ TEXT    │ CSV     │
│ sub_cpmk_ids    │ TEXT    │ CSV     │
│ cpl_ids         │ TEXT    │ CSV     │
│ topik           │ TEXT    │ -       │
│ metode_ajar     │ TEXT    │ -       │
│ jenis_penilaian │ TEXT    │ -       │
│ bobot           │ REAL    │ 0-100   │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: matakuliah_id → matakuliah.id
Indeks: (matakuliah_id)
UNIQUE: (matakuliah_id, minggu_ke)
Tujuan: Rencana pembelajaran semester per minggu

CSV Format Contoh:
- cpmk_ids: "1,2,3" (id dari cpmk tabel)
- sub_cpmk_ids: "5,6,7"
- cpl_ids: "1,2"
```

#### 9. **assessment_type** - Jenis Penilaian per Minggu
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ minggu_id       │ INTEGER │ FK      │
│ cpmk_id         │ INTEGER │ FK      │
│ jenis_asessmen  │ TEXT    │ -       │
│ bobot           │ REAL    │ -       │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: minggu_id → rps_detail.id
FK: cpmk_id → cpmk.id
Indeks: (minggu_id)
```

#### 10. **cpmk_cpl_mapping** - Mapping CPMK ke CPL
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ cpmk_id         │ INTEGER │ FK      │
│ cpl_id          │ INTEGER │ FK      │
│ bobot           │ REAL    │ -       │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: cpmk_id → cpmk.id
FK: cpl_id → cpl_master.id
UNIQUE: (cpmk_id, cpl_id)
Tujuan: Mapping antara CPMK dan CPL dengan bobot kontribusi
```

#### 11. **sub_cpmk_nilai** - Nilai per Sub-CPMK Mahasiswa
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ mahasiswa_id    │ INTEGER │ FK      │
│ sub_cpmk_id     │ INTEGER │ FK      │
│ nilai           │ REAL    │ -       │
│ tahun_ajaran    │ INTEGER │ -       │
│ catatan         │ TEXT    │ NULL    │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: mahasiswa_id → mahasiswa.id
FK: sub_cpmk_id → sub_cpmk.id
UNIQUE: (mahasiswa_id, sub_cpmk_id, tahun_ajaran)
Tujuan: Track pencapaian per sub-learning outcome
```

#### 12. **rps_detail_sub_cpmk_bobot** - Link RPS Detail ke Sub-CPMK
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ rps_detail_id   │ INTEGER │ FK      │
│ sub_cpmk_id     │ INTEGER │ FK      │
│ bobot           │ REAL    │ -       │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: rps_detail_id → rps_detail.id
FK: sub_cpmk_id → sub_cpmk.id
UNIQUE: (rps_detail_id, sub_cpmk_id)
Tujuan: Hubungan minggu pembelajaran dengan sub-CPMK dan bobot
```

#### 13. **sub_cpmk_cpmk_mapping** - Link Sub-CPMK ke CPMK
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ sub_cpmk_id     │ INTEGER │ FK      │
│ cpmk_id         │ INTEGER │ FK      │
│ bobot           │ REAL    │ -       │
│ created_at      │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: sub_cpmk_id → sub_cpmk.id
FK: cpmk_id → cpmk.id
UNIQUE: (sub_cpmk_id, cpmk_id)
Tujuan: Mapping detail ke chapter-level learning outcomes
```

#### 14. **rps** - RPS File (Legacy)
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ matakuliah_id   │ INTEGER │ FK      │
│ file_path       │ TEXT    │ -       │
│ file_name       │ TEXT    │ -       │
│ deskripsi       │ TEXT    │ NULL    │
│ cpl_mappings    │ TEXT    │ NULL    │
│ upload_date     │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: matakuliah_id → matakuliah.id
Tujuan: Track uploaded RPS files
```

#### 15. **cpl** - CPL per Mahasiswa
```
┌──────────────────────────────────────┐
│ Column Name      │ Type    │ Notes   │
├──────────────────────────────────────┤
│ id              │ INTEGER │ PK, AI  │
│ mahasiswa_id    │ INTEGER │ FK      │
│ nip_mahasiswa   │ TEXT    │ -       │
│ nama_mahasiswa  │ TEXT    │ -       │
│ ipk             │ REAL    │ -       │
│ status          │ TEXT    │ -       │
│ total_sku       │ INTEGER │ -       │
│ rata_nilai      │ REAL    │ -       │
│ catatan         │ TEXT    │ NULL    │
│ tanggal_hitung  │ TEXT    │ -       │
│ updated_at      │ TEXT    │ NULL    │
└──────────────────────────────────────┘

FK: mahasiswa_id → mahasiswa.id
Tujuan: CPL achievement report per mahasiswa
```

### Data Relationships Diagram

```
users
  ├── Independen (parent dari session)
  
mahasiswa
  ├── 1 → N nilai
  ├── 1 → N cpl (CPL report)
  ├── 1 → N sub_cpmk_nilai

matakuliah
  ├── 1 → N nilai
  ├── 1 → N rps_detail
  ├── 1 → N cpmk
  ├── 1 → N sub_cpmk

cpl_master
  ├── 1 → N cpmk_cpl_mapping

cpmk
  ├── 1 → N assessment_type
  ├── 1 → N cpmk_cpl_mapping
  ├── 1 → N sub_cpmk_cpmk_mapping (reverse)

sub_cpmk
  ├── 1 → N rps_detail_sub_cpmk_bobot
  ├── 1 → N sub_cpmk_nilai
  ├── 1 → N sub_cpmk_cpmk_mapping

rps_detail
  ├── 1 → N assessment_type
  ├── 1 → N rps_detail_sub_cpmk_bobot
```

---

## Data Models

### File Lokasi
`lib/models/` - Folder untuk semua data classes

### 1. UserModel (`user_model.dart`)
```dart
class User {
  int? id;
  String username;
  String password;
  String role;
  String nama;
  String? nim;
  int isActive;
  DateTime createdAt;
  DateTime? updatedAt;
}
```
**Tujuan**: Kredensial dan profil pengguna

### 2. MahasiswaModel (`mahasiswa_model.dart`)
```dart
class Mahasiswa {
  int? id;
  String nim;
  String nama;
  int tahunMasuk;
  String status;
  int isActive;
  DateTime createdAt;
  DateTime? updatedAt;
}
```
**Tujuan**: Data mahasiswa/siswa

### 3. MatakuliahModel (`matakuliah_model.dart`)
```dart
class Matakuliah {
  int? id;
  String kode;      // e.g., "UUW0071"
  String nama;      // e.g., "Aliran Kepercayaan..."
  String semester;
  String jenis;     // "wajib" atau "pilihan"
  int sks;          // 1-6 SKS
  int isActive;
  DateTime createdAt;
  DateTime? updatedAt;
}
```
**Tujuan**: Master data mata kuliah

### 4. NilaiModel (`nilai_model.dart`)
```dart
class Nilai {
  int? id;
  int mahasiswaId;
  int matakuliahId;
  String gradeHuruf;      // A, B, C, D, E
  double nilaiNumerik;    // 0.0 - 4.0
  String? catatan;
  int tahunAjaran;
  DateTime createdAt;
  DateTime? updatedAt;
}
```
**Tujuan**: Track nilai per mahasiswa per mata kuliah

### 5. RPSDetailModel (`rps_detail_model.dart`)
```dart
class RPSDetail {
  int? id;
  int matakuliahId;
  int mingguKe;           // 1-16
  List<int>? cpmkIds;     // CSV as string, parsed to list
  List<int>? subCpmkIds;
  List<int>? cplIds;
  String? topik;
  String? metodeAjar;     // Discovery Learning, Project Based, etc
  String? jenisNilai;     // Aktifitas Partisipatif, Hasil Proyek, Kuis, Tugas
  double? bobot;          // 0-100 %
  DateTime createdAt;
  DateTime? updatedAt;
}
```
**Tujuan**: Rencana pembelajaran per minggu

### 6. CPLMasterModel (`cpl_master_model.dart`)
```dart
class CPLMaster {
  int? id;
  String kodeCpl;     // CPL.1, CPL.2, ..., CPL.7
  String deskripsi;
  String nomor;
  DateTime createdAt;
  DateTime? updatedAt;
}
```
**Tujuan**: 7 Learning Outcomes universitas

### 7. CPMKModel (`cpmk_model.dart`)
```dart
class CPMK {
  int? id;
  int matakuliahId;
  String kodeCpmk;    // CPMK.1, CPMK.2, etc
  String deskripsi;
  DateTime createdAt;
  DateTime? updatedAt;
}
```
**Tujuan**: Course-level learning outcomes

### 8. SubCPMKModel (`sub_cpmk_model.dart`)
```dart
class SubCPMK {
  int? id;
  int matakuliahId;
  String kodeSubCpmk; // SUB-CPMK.1, SUB-CPMK.2, etc
  String deskripsi;
  DateTime createdAt;
  DateTime? updatedAt;
}
```
**Tujuan**: Detailed learning outcomes

### Model Relationships

```
User (sistem)
  ↓
Mahasiswa + Matakuliah
  ↓
RPS Detail (minggu ke)
  ├─ Link ke Sub-CPMK (via rps_detail_sub_cpmk_bobot)
  ├─ Link ke CPMK (via sub_cpmk_cpmk_mapping)
  └─ Link ke CPL (via cpmk_cpl_mapping)
  ↓
Nilai + Sub-CPMK Nilai
  ↓
CPL Report (Mahasiswa achievement)
```

---

## Services & Business Logic

### File Lokasi
`lib/services/` - Folder untuk semua service classes

### 1. DatabaseHelper (`database_helper.dart`)
**Tujuan**: CRUD operations untuk semua tables

**Methods Utama**:
- `insertMahasiswa(Mahasiswa)` → int
- `getAllMahasiswa()` → List<Mahasiswa>
- `insertMatakuliah(Matakuliah)` → int
- `getAllMatakuliah()` → List<Matakuliah>
- `insertNilai(Nilai)` → int
- `getNilaiByMahasiswa(int)` → List<Nilai>
- `insertRPSDetail(RPSDetail)` → int
- `getRPSDetailByMatakuliah(int)` → List<RPSDetail>
- `deleteRPSDetailByMatakuliah(int)` → int [NEW - untuk delete sebelum import]
- `insertCPMK(CPMK)` → int
- `insertSubCPMK(SubCPMK)` → int
- Dan banyak lagi...

### 2. ExcelImportService (`excel_import_service.dart`)
**Tujuan**: Import data dari file Excel

**Methods**:
```dart
importMahasiswaFromExcel(String filePath) 
  → Map<String, dynamic>
  // Return: {success, message, imported, failed, errors}

importMatakuliahFromExcel(String filePath)
  → Map<String, dynamic>

importNilaiFromExcel(String filePath, Matakuliah)
  → Map<String, dynamic>

importCPMKFromExcel(String filePath, Matakuliah)
  → Map<String, dynamic>
```

**Flow**:
1. Read Excel file (xlsx atau csv fallback)
2. Parse rows
3. Validasi data
4. Insert ke database
5. Return result

### 3. RPSExcelService (`rps_excel_service.dart`)
**Tujuan**: Import RPS dari Excel template

**Template Format**:
```
Row 1: Nama Mata Kuliah: [nama]
Row 2: Kode Matakuliah: [kode]
Row 3: (kosong)
Row 4: Header row (10 kolom)
Row 5-20: Data rows (16 minggu)
```

**Kolom Template**:
1. Kode Matakuliah
2. Nama Matakuliah
3. Minggu Ke (1-16)
4. Topik Pembelajaran
5. Metode Ajar
6. Bobot (%)
7. Kode CPMK
8. Kode Sub CPMK
9. Kode CPL
10. Jenis Penilaian (Aktifitas Partisipatif, Hasil Proyek, Kuis, Tugas)

**Key Method**:
```dart
importRPSFromExcel(String filePath, Matakuliah)
  → Map<String, dynamic>
  
  // Validasi:
  // - mingguKe ∈ [1,16]
  // - topik required
  // - metodeAjar in _validLearningMethods
  // - bobot ∈ [0,100]
  // - CPMK, SubCPMK, CPL valid di DB
  // 
  // Flow:
  // 1. Delete RPS lama untuk matakuliah ini
  // 2. Parse Excel
  // 3. Validasi semua row
  // 4. Insert ke rps_detail table
```

### 4. TemplateService (`template_service.dart`)
**Tujuan**: Generate template Excel untuk download

**Key Methods**:
```dart
downloadRPSTemplate({String? matakuliahNama, String? kodeMatkuliah})
  → String? (file path)
  
  // Generate Excel dengan:
  // - Header info (nama, kode matakuliah)
  // - 16 contoh data row
  // - Column widths sudah diatur
  // - File name: RPS_[sanitized_nama_matakuliah].xlsx
  // - Lokasi: ~/Downloads/

downloadTemplate(String templateFileName)
  → String? (CSV template path)
```

**File Naming**:
- RPS template: `RPS_aliran_kepercayaan_terhadap_tuhan_yang_maha_esa.xlsx`
- Sanitasi: hapus special chars, replace space dengan underscore, lowercase

---

## Screens & Features

### File Lokasi
`lib/screens/` - Semua UI screens

### Routing Structure (dari main.dart)

```
/login
  └─ LoginScreen
     ├─ Admin Login → /admin_dashboard
     └─ Student Login → /mahasiswa_dashboard

/admin_dashboard
  └─ AdminDashboardScreen
     ├─ Import Mahasiswa → /mahasiswa_template_import
     ├─ Import Mata Kuliah → /matakuliah_template_import
     ├─ Import Nilai Detail → /nilai_detail_import
     ├─ Import CPMK → /cpmk_template_import
     ├─ Import Sub CPMK → /sub_cpmk_template_import
     ├─ Import CPL → /cpl_template_import
     ├─ Import Nilai Batch → /nilai_batch_import
     ├─ Input RPS → /rps_input
     │  └─ Download Template → ~/Downloads/RPS_[nama].xlsx
     │  └─ Import RPS → /rps_template_import
     ├─ Manajemen CPMK → /cpmk_management
     ├─ Manajemen Sub-CPMK → /sub_cpmk_management
     ├─ Mapping CPMK-CPL → /cpmk_cpl_mapping
     ├─ Report CPMK → /cpmk_report
     └─ Report CPL → /cpl_report

/mahasiswa_dashboard
  └─ MahasiswaDashboardScreen
     ├─ View Nilai
     └─ View CPL Achievement
```

### 1. LoginScreen (`login_screen.dart`)
**Tujuan**: Authentication
**Fitur**:
- Username/password login
- Role-based navigation
- Admin vs Student dashboard

### 2. AdminDashboardScreen (`admin_dashboard_screen.dart`)
**Tujuan**: Central hub untuk admin
**Fitur**:
- Statistics/dashboard
- Quick links ke semua import features
- Navigation ke management screens

**Layout**:
```
┌─────────────────────────────┐
│ Statistics Cards            │
│ - Total Mahasiswa           │
│ - Total Mata Kuliah         │
│ - Other metrics             │
├─────────────────────────────┤
│ Import Data Section         │
│ - Import Mahasiswa          │
│ - Import Mata Kuliah        │
│ - Import Nilai              │
│ - Import CPMK/Sub-CPMK      │
│ - Import RPS                │
├─────────────────────────────┤
│ Management Section          │
│ - Input RPS                 │
│ - Manage CPMK               │
│ - Manage Sub-CPMK           │
│ - Mapping CPMK-CPL          │
├─────────────────────────────┤
│ Reports Section             │
│ - Report CPMK               │
│ - Report CPL                │
└─────────────────────────────┘
```

### 3. RPSInputScreen (`rps_input_screen.dart`)
**Tujuan**: Input & management RPS per minggu per mata kuliah
**Fitur**:
- List mata kuliah dengan bobot indicator
- Bobot highlight:
  - 🟢 Green: 100% (sempurna)
  - 🟠 Orange: >100% (overweight)
  - 🔴 Red: <100% (belum lengkap)
- Click mata kuliah → edit per minggu
- Download template Excel
- Import RPS dari Excel

**Detail Edit Dialog**:
- Minggu Ke (1-16)
- Topik Pembelajaran
- Metode Ajar (dropdown)
- Bobot (%) (0-100)
- Kode CPMK (checkbox/selection)
- Kode Sub-CPMK (checkbox/selection)
- Kode CPL (checkbox/selection)
- Jenis Penilaian (chip selector)

**Bobot Auto-Refresh Logic**:
```dart
// Saat user navigasi ke import:
onPressed: () {
  Navigator.pushNamed(context, '/rps_template_import')
    .then((_) {
      if (mounted) {
        setState(() {
          _rpsCache.clear();  // Clear cache
        });                   // Trigger rebuild → FutureBuilder re-run
      }
    });
}
```

### 4. RPSTemplateImportScreen (`rps_template_import_screen.dart`)
**Tujuan**: Import RPS dari Excel
**Fitur**:
- Dropdown pilih mata kuliah
- Download template button
- File picker (xlsx/csv)
- Process & show results

**Flow**:
1. User pilih mata kuliah
2. Click "Download Template" → Save as ~/Downloads/RPS_[nama].xlsx
3. User edit Excel template (16 rows, 10 columns)
4. Click "Pilih File" → select edited file
5. Click "Import RPS" → call RPSExcelService.importRPSFromExcel()
6. Show success/error messages
7. Return dengan setState() → clear cache → refresh bobot display

### 5. MahasiswaScreen (`mahasiswa_screen.dart`)
**Tujuan**: CRUD mahasiswa
**Fitur**:
- List mahasiswa
- Add/edit/delete mahasiswa
- Search/filter

### 6. MatakuliahScreen (`matakuliah_screen.dart`)
**Tujuan**: CRUD mata kuliah
**Fitur**:
- List mata kuliah
- Add/edit/delete mata kuliah
- Import dari template

### 7. NilaiScreen (`nilai_screen.dart`)
**Tujuan**: CRUD nilai mahasiswa
**Fitur**:
- List nilai per mata kuliah
- Input nilai
- Batch import dari Excel

### 8. ExcelImportScreen (`excel_import_screen.dart`)
**Tujuan**: General Excel import (Mahasiswa, Mata Kuliah, CPMK, etc)
**Fitur**:
- Type selector (mahasiswa, matakuliah, cpmk, dll)
- Download template
- File picker
- Import process

### 9. CPMKManagementScreen (`cpmk_management_screen.dart`)
**Tujuan**: CRUD CPMK per mata kuliah
**Fitur**:
- List CPMK per mata kuliah
- Add/edit/delete CPMK

### 10. SubCPMKManagementScreen (`sub_cpmk_management_screen.dart`)
**Tujuan**: CRUD Sub-CPMK
**Fitur**:
- List Sub-CPMK
- Add/edit/delete Sub-CPMK

### 11. CPMKCPLMappingScreen (`cpmk_cpl_mapping_screen.dart`)
**Tujuan**: Map CPMK ke CPL dengan bobot
**Fitur**:
- Select CPMK → select CPL → input bobot
- Save mapping

### 12. Reports
- **CPMKReportScreen**: Report CPMK achievement
- **CPLReportScreen**: Report CPL achievement per mahasiswa

---

## File Structure

```
lib/
├── main.dart                              # Entry point, routing
├── constants/
│   └── app_constants.dart                 # Colors, spacing, strings
├── models/
│   ├── user_model.dart                    # User
│   ├── mahasiswa_model.dart               # Mahasiswa
│   ├── matakuliah_model.dart              # Matakuliah
│   ├── nilai_model.dart                   # Nilai
│   ├── rps_model.dart                     # RPS (legacy)
│   ├── rps_detail_model.dart              # RPS per minggu
│   ├── cpl_model.dart                     # CPL report
│   ├── cpl_master_model.dart              # CPL master (7 CPLs)
│   ├── cpmk_model.dart                    # CPMK
│   ├── sub_cpmk_model.dart                # Sub-CPMK
│   ├── assessment_type_model.dart         # Assessment type
│   ├── sub_cpmk_nilai_model.dart          # Sub-CPMK nilai
│   ├── cpmk_cpl_mapping_model.dart        # CPMK-CPL mapping
│   ├── rps_detail_sub_cpmk_bobot_model.dart   # RPS-SubCPMK link
│   └── sub_cpmk_cpmk_mapping_model.dart   # Sub-CPMK-CPMK link
├── services/
│   ├── database_helper.dart               # Database CRUD
│   ├── excel_import_service.dart          # Import Excel (general)
│   ├── rps_excel_service.dart             # Import RPS Excel
│   ├── template_service.dart              # Generate templates
│   └── [other services]
├── screens/
│   ├── login_screen.dart                  # Login
│   ├── admin_dashboard_screen.dart        # Admin dashboard
│   ├── rps_input_screen.dart              # RPS input/edit per minggu
│   ├── rps_template_import_screen.dart    # Import RPS
│   ├── mahasiswa_screen.dart              # Mahasiswa CRUD
│   ├── matakuliah_screen.dart             # Matakuliah CRUD
│   ├── nilai_screen.dart                  # Nilai CRUD
│   ├── nilai_detail_import_screen.dart    # Import nilai detail
│   ├── nilai_batch_import_screen.dart     # Batch nilai import
│   ├── mahasiswa_template_import_screen.dart
│   ├── matakuliah_template_import_screen.dart
│   ├── cpmk_template_import_screen.dart
│   ├── sub_cpmk_template_import_screen.dart
│   ├── cpl_template_import_screen.dart
│   ├── cpmk_management_screen.dart        # CPMK CRUD
│   ├── sub_cpmk_management_screen.dart    # Sub-CPMK CRUD
│   ├── cpmk_cpl_mapping_screen.dart       # Mapping UI
│   ├── cpmk_report_screen.dart            # CPMK report
│   ├── cpl_report_screen.dart             # CPL report
│   ├── cpl_calculation_screen.dart        # CPL calculation
│   ├── excel_import_screen.dart           # General import
│   ├── placeholder_screens.dart           # Placeholder screens
│   └── [other screens]
├── widgets/
│   ├── app_bar_widget.dart
│   ├── base_dialog_widget.dart
│   └── [other custom widgets]
├── utils/
│   └── [utility functions]
└── assets/
    ├── templates/
    │   ├── mahasiswa_template.csv
    │   ├── matakuliah_template.csv
    │   └── nilai_template.csv
```

---

## User Flows

### Flow 1: Input RPS (Most Important)

```
Admin Dashboard
  ↓
Click "Input RPS"
  ↓
RPSInputScreen
  ├─ Load mata kuliah list
  └─ Show bobot per mata kuliah
      ├─ Click mata kuliah
      │  ↓
      │  RPSEditDialog (for 16 minggu)
      │  ├─ select minggu
      │  ├─ input topik, metode ajar
      │  ├─ select CPMK/Sub-CPMK/CPL
      │  ├─ select jenis penilaian
      │  ├─ input bobot (%)
      │  └─ save → database
      │
      ├─ Click "Download Template"
      │  ├─ Generate Excel file
      │  └─ Save as ~/Downloads/RPS_[nama_matakuliah].xlsx
      │
      └─ Click "Import RPS"
         ↓
         RPSTemplateImportScreen
         ├─ select mata kuliah
         ├─ Click "Download Template" (optional)
         ├─ Click "Pilih File"
         │  ├─ File picker
         │  └─ select .xlsx dari ~/Downloads/
         │
         └─ Click "Import RPS"
            ├─ Call RPSExcelService.importRPSFromExcel()
            │  ├─ Parse Excel (16 rows, 10 columns)
            │  ├─ Validate each row
            │  │  ├─ mingguKe 1-16 ✓
            │  │  ├─ topik required ✓
            │  │  ├─ metode ajar valid ✓
            │  │  ├─ bobot 0-100 ✓
            │  │  ├─ CPMK/SubCPMK/CPL exist ✓
            │  │  └─ jenis penilaian valid ✓
            │  │
            │  ├─ Delete old RPS data for this mata kuliah
            │  │  (avoid UNIQUE constraint error)
            │  │
            │  └─ Insert 16 rows to rps_detail table
            │
            ├─ Show result dialog
            │  ├─ Success: "16 data RPS berhasil diimpor"
            │  └─ Error: "Import gagal: X baris memiliki error"
            │
            └─ Navigator.pop() → return to RPSInputScreen
               ├─ setState(() { _rpsCache.clear() })
               ├─ FutureBuilder rebuild
               ├─ _calculateTotalBobot() re-run
               └─ Bobot display update: 🟢 Green 100%
                  └─ User sees instant feedback!
```

### Flow 2: Import Nilai Detail

```
Admin Dashboard
  ├─ Click "Import Nilai Detail" (button baru)
  │  ↓
  │  NilaiDetailImportScreen
  │  ├─ Download template
  │  │  └─ Template format: NIM, Kode Mata Kuliah, Nilai
  │  │
  │  ├─ Pick Excel file
  │  ├─ Import → validate & insert
  │  └─ Show result
```

### Flow 3: Regular Import (Mahasiswa, Mata Kuliah, CPMK)

```
Admin Dashboard
  ├─ Click "Import [Type]"
  │  ↓
  │  ExcelImportScreen
  │  ├─ Select type (dropdown)
  │  ├─ Download Template
  │  ├─ Pick file
  │  ├─ Import & validate
  │  └─ Show result
```

### Flow 4: Student Dashboard

```
StudentDashboardScreen
  ├─ Show student info
  ├─ Show nilai per mata kuliah
  └─ Show CPL achievement
     └─ Calculate based on sub_cpmk_nilai & mappings
```

---

## Summary: Key Concepts

| Konsep | Keterangan |
|--------|-----------|
| **Database** | `cpl_app.db` (SQLite), 15 tables |
| **Entry Point** | `main.dart` |
| **Routing** | Named routes, role-based navigation |
| **CRUD** | DatabaseHelper methods |
| **Import** | ExcelImportService & RPSExcelService |
| **Templates** | Excel format, generated dynamically |
| **RPS** | 16 minggu × mata kuliah, with CPMK/CPL mapping |
| **Bobot** | Sum dari 16 minggu, should = 100% |
| **CPL** | 7 learning outcomes (CPL.1 - CPL.7) |
| **CPMK** | Chapter-level per mata kuliah |
| **Sub-CPMK** | Detail learning outcomes |
| **Nilai** | Grade per mahasiswa per mata kuliah |
| **Mapping** | CPMK → CPL, Sub-CPMK → CPMK |

---

**Terakhir Update**: 25 Feb 2026
**Database Version**: 5
**Flutter Target**: Android, iOS, Windows
