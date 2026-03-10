# 🗂️ KEY FILES QUICK REFERENCE - File Locations & Purposes

## SCREENS & UI

### 1. Assessment Outcomes Screen ⭐ (BASE TEMPLATE)
**File:** [lib/screens/assessment_outcomes_screen.dart](lib/screens/assessment_outcomes_screen.dart)
- **Purpose:** Display CPMK & CPL scores for selected student
- **Key Features:**
  - Mahasiswa selection with angkatan filter
  - Tab-based delivery (CPMK scores | CPL scores)
  - Score loading with parallel async calls
- **Key Methods:**
  - `_loadData()` - Initialize data (lines 45-65)
  - `_filterMahasiswaByAngkatan()` - Filter logic (lines 73-82)
  - `_selectMahasiswa()` - Selection handler (lines 84-87)
  - `_loadMahasiswaScores()` - Score loading (lines 89-125)
  - `_getStatusLabel()` - Status mapping (lines 127+)
- **UI Components:**
  - Dropdown for angkatan selection
  - List for mahasiswa selection
  - TabController with 2 tabs
  - Grid/list display of scores
- **Status:** ✅ USE AS TEMPLATE FOR SUB-CPMK SCREEN

---

### 2. CPL Calculation Screen
**File:** [lib/screens/cpl_calculation_screen.dart](lib/screens/cpl_calculation_screen.dart)
- **Purpose:** Trigger calculation of CPL for all students
- **Key Method:** `_calculateAllCPL()` (calls CPLCalculationService)
- **Info:** Button to calculate CPL scores system-wide

---

### 3. CPMK-CPL Mapping Screen
**File:** [lib/screens/cpmk_cpl_mapping_screen.dart](lib/screens/cpmk_cpl_mapping_screen.dart)
- **Purpose:** Configure CPMK→CPL mappings with bobot
- **Key Method:** `_onMatakuliahSelected()` - Load CPMKs & mappings
- **Use Case:** Admin setup of CPL weighting structure

---

## 📊 MODELS & DATA STRUCTURES

### Core Learning Outcome Models

| Model | File | Key Fields | Table Ref |
|-------|------|-----------|-----------|
| **CPL** | [cpl_model.dart](lib/models/cpl_model.dart) | id, mahasiswaId, ipk, status, totalSku | cpl |
| **CPLMaster** | [cpl_master_model.dart](lib/models/cpl_master_model.dart) | id, kodeCPL, deskripsi, nomor (1-7) | cpl_master |
| **CPMK** | [cpmk_model.dart](lib/models/cpmk_model.dart) | id, matakuliahId, kodeCPMK, deskripsi | cpmk |
| **SubCPMK** | [sub_cpmk_model.dart](lib/models/sub_cpmk_model.dart) | id, matakuliahId, kodeSubCPMK, deskripsi | sub_cpmk |

### Mapping Models

| Model | File | Relationship |
|-------|------|--------------|
| **CPMKCPLMapping** | [cpmk_cpl_mapping_model.dart](lib/models/cpmk_cpl_mapping_model.dart) | CPMK ↔️ CPL with bobot |
| **SubCPMKCPMKMapping** | [sub_cpmk_cpmk_mapping_model.dart](lib/models/sub_cpmk_cpmk_mapping_model.dart) | SubCPMK ↔️ CPMK with bobot |

### Student Score Models

| Model | File | Purpose |
|-------|------|---------|
| **NilaiModel** | [nilai_model.dart](lib/models/nilai_model.dart) | Overall course grade |
| **NilaiKomponenModel** | [nilai_komponen_model.dart](lib/models/nilai_komponen_model.dart) | Component breakdown (aktivitas, proyek, kuis, tugas, uts, uas) |

### Other Models

| Model | File | Purpose |
|-------|------|---------|
| **Mahasiswa** | [mahasiswa_model.dart](lib/models/mahasiswa_model.dart) | Student info |
| **Matakuliah** | [matakuliah_model.dart](lib/models/matakuliah_model.dart) | Course info |
| **RPS** | [rps_model.dart](lib/models/rps_model.dart) | Course syllabus |
| **RPSDetail** | [rps_detail_model.dart](lib/models/rps_detail_model.dart) | Weekly lesson plan |

---

## 🔧 SERVICES & BUSINESS LOGIC

### 1. CPMKCPLCalculationService ⭐ (MAIN CALCULATION ENGINE)
**File:** [lib/services/cpmk_cpl_calculation_service.dart](lib/services/cpmk_cpl_calculation_service.dart)

#### Core Calculation Methods
```dart
// PRIMARY METHODS (used for measurement screen)
Future<double?> calculateCPMKForMahasiswa(int cpmkId, int mahasiswaId)
  └─ Lines 244-369: 6-step OBE calculation
  └─ Returns: CPMK score (0-100) or null
  └─ Uses: component scores, bobot matrix, RPS detail bobot

Future<double?> calculateCPLForMahasiswa(int cplId, int mahasiswaId)
  └─ Lines 390-426: Weighted CPMK average
  └─ Returns: CPL score (0-100) or null
  └─ Uses: CPMK scores, CPMK-CPL mapping bobot

// DATA LOADING METHODS (for UI)
Future<List<Map<String, dynamic>>> loadCPMKForMahasiswa(int mahasiswaId)
  └─ Lines 477-556: Load all CPMK with scores
  └─ Returns: [{id, kode, deskripsi, score}, ...]

Future<List<Map<String, dynamic>>> loadCPLForMahasiswa(int mahasiswaId)
  └─ Lines 559-604: Load all CPL with scores
  └─ Returns: [{id, kodeCPL, deskripsi, score}, ...]

// HELPER METHODS
Future<Map<int, double>> _getSubCpmkToCpmkBobot(int matakuliahId)
  └─ Get Sub-CPMK→CPMK weighting matrix
  └─ Returns: {subCpmkId: bobot, ...}

double _normalizeToScale0_100(double nilai)
  └─ Convert 0-4 scale to 0-100 scale
  └─ Formula: nilai > 4 ? nilai : nilai * 25
```

#### Alternative Methods (for reference/fallback)
```dart
Future<double?> calculateCPMKForMahasiswaSimple() - Line 367
Future<double?> calculateCPLForMahasiswaSimple() - Line 435
Future<double?> calculateCPMKUsingComponentScores() - Line 606
```

---

### 2. CPLCalculationService
**File:** [lib/services/cpl_calculation_service.dart](lib/services/cpl_calculation_service.dart)

#### Key Methods
```dart
Future<CPL?> calculateCPLForMahasiswa(int mahasiswaId)
  └─ Line 19: Calculate CPL object (status: belum_lulus|memenuhi|tidak_memenuhi)
  └─ Uses: IPK, rata-rata nilai, total SKU
  └─ Minimum requirements: IPK≥2.0, rata_nilai≥2.0, SKU≥144

Future<List<CPL>> calculateCPLForAllMahasiswa()
  └─ Line 78: Batch calculation for all students
  └─ Saves results to database
```

---

### 3. DatabaseHelper ⭐ (DATABASE ACCESS LAYER)
**File:** [lib/services/database_helper.dart](lib/services/database_helper.dart)

#### Model Queries
```dart
// CPL Queries
Future<List<CPLMaster>> getAllCPLMaster() - Get 7 CPLs
Future<CPLMaster?> getCPLMasterById(int id)

// CPMK Queries
Future<List<CPMK>> getAllCPMK()
Future<List<CPMK>> getCPMKByMatakuliah(int matakuliahId)
Future<CPMK?> getCPMKById(int id)

// SubCPMK Queries
Future<List<SubCPMK>> getAllSubCPMK()
Future<List<SubCPMK>> getSubCPMKByMatakuliah(int matakuliahId)
Future<SubCPMK?> getSubCPMKById(int id)
```

#### Mapping Queries
```dart
// CPMK-CPL Mapping
Future<List<CPMKCPLMapping>> getMappingByCPL(int cplId)
Future<List<CPMKCPLMapping>> getMappingByCPMK(int cpmkId)

// Sub-CPMK Mapping
Future<List<SubCPMKCPMKMapping>> getSubCPMKMapping(int subCpmkId)
Future<List<SubCPMKCPMKMapping>> getSubCPMKMappingByCPMK(int cpmkId)
```

#### Score/Data Queries
```dart
// Component Scores
Future<Map<String, dynamic>?> getNilaiKomponen(
  {required int mahasiswaId,
   required int matakuliahId,
   required int tahunAjaran})
└─ Returns: {aktivitas, hasil_proyek, kuis, tugas, uts, uas}
└─ Table: nilai_komponen

// Bobot Matrix
Future<Map<int, List<double>>?> getBobotMatrixForMatakuliah(
  {required int matakuliahId})
└─ Returns: {subCpmkId: [bobot_array_of_6], ...}
└─ Table: rps_detail_sub_cpmk_bobot

// Other Score Methods
Future<Map<int, double>> getSubCPMKToCPMKBobotMapping(int matakuliahId)
```

#### Persistence Methods
```dart
// Insert
Future<int> insertCPL(CPL cpl)
Future<int> insertCPMK(CPMK cpmk)
Future<int> insertSubCPMK(SubCPMK subCpmk)

// Update
Future<int> updateCPL(CPL cpl)
Future<int> updateCPMK(CPMK cpmk)

// Delete
Future<int> deleteCPL(int id)
Future<int> deleteCPMK(int id)
```

---

## 📋 DATABASE SCHEMA & TABLE DEFINITIONS

**Database File:** [lib/services/database_helper.dart](lib/services/database_helper.dart)

### Core Tables

#### cpl_master Table (Lines in DB creation method)
```
CREATE TABLE cpl_master (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kode_cpl TEXT UNIQUE NOT NULL,      -- CPL.1, CPL.2, ... CPL.7
  deskripsi TEXT NOT NULL,
  nomor TEXT UNIQUE NOT NULL,         -- 1-7
  created_at TEXT NOT NULL,
  updated_at TEXT
)
```

#### cpmk Table
```
CREATE TABLE cpmk (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  matakuliah_id INTEGER NOT NULL,
  kode_cpmk TEXT NOT NULL,            -- CPMK.1, CPMK.2, etc
  deskripsi TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(matakuliah_id, kode_cpmk)
)
```

#### sub_cpmk Table
```
CREATE TABLE sub_cpmk (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  matakuliah_id INTEGER NOT NULL,
  kode_sub_cpmk TEXT NOT NULL,        -- SUB-CPMK.1, SUB-CPMK.2
  deskripsi TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(matakuliah_id, kode_sub_cpmk)
)
```

### Mapping Tables

#### cpmk_cpl_mapping Table
```
CREATE TABLE cpmk_cpl_mapping (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cpmk_id INTEGER NOT NULL,
  cpl_id INTEGER NOT NULL,
  bobot REAL NOT NULL,                -- 0-100%
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(cpmk_id, cpl_id)
)
```

#### sub_cpmk_cpmk_mapping Table
```
CREATE TABLE sub_cpmk_cpmk_mapping (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sub_cpmk_id INTEGER NOT NULL,
  cpmk_id INTEGER NOT NULL,
  bobot REAL NOT NULL,                -- 0-100%
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(sub_cpmk_id, cpmk_id)
)
```

#### rps_detail_sub_cpmk_bobot Table
```
CREATE TABLE rps_detail_sub_cpmk_bobot (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rps_detail_id INTEGER NOT NULL,
  sub_cpmk_id INTEGER NOT NULL,
  bobot REAL NOT NULL,                -- Bobot for OBE calculation
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(rps_detail_id, sub_cpmk_id)
)
```

### Student Score Tables

#### nilai_komponen Table
```
CREATE TABLE nilai_komponen (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  mahasiswa_id INTEGER NOT NULL,
  matakuliah_id INTEGER NOT NULL,
  nilai_aktivitas REAL DEFAULT 0,
  nilai_proyek REAL DEFAULT 0,
  nilai_kuis REAL DEFAULT 0,
  nilai_tugas REAL DEFAULT 0,
  nilai_uts REAL DEFAULT 0,
  nilai_uas REAL DEFAULT 0,
  tahun_ajaran INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(mahasiswa_id, matakuliah_id, tahun_ajaran)
)
```

#### sub_cpmk_nilai Table (for storing SubCPMK results)
```
CREATE TABLE sub_cpmk_nilai (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  mahasiswa_id INTEGER NOT NULL,
  sub_cpmk_id INTEGER NOT NULL,
  nilai REAL NOT NULL,
  tahun_ajaran INTEGER NOT NULL,
  catatan TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(mahasiswa_id, sub_cpmk_id, tahun_ajaran)
)
```

---

## 📄 RELATED DOCUMENTATION FILES

| File | Purpose |
|------|---------|
| [CODEBASE_EXPLORATION_REPORT.md](CODEBASE_EXPLORATION_REPORT.md) | **YOU ARE HERE** - Comprehensive exploration |
| [CALCULATION_FLOW_DIAGRAMS.md](CALCULATION_FLOW_DIAGRAMS.md) | Visual diagrams, formulas, and data flow |
| [OBE_CALCULATION_ENGINE.md](OBE_CALCULATION_ENGINE.md) | Details of OBE calculation methodology |
| [PANDUAN_IMPORT_NILAI_DETAIL.md](PANDUAN_IMPORT_NILAI_DETAIL.md) | How to import component scores |
| [IMPLEMENTASI_FIX_NILAI_KOMPONEN.md](IMPLEMENTASI_FIX_NILAI_KOMPONEN.md) | Implementation of component score fixes |
| [FIX_CPMK_NOT_SHOWING_ASSESSMENT_OUTCOMES.md](FIX_CPMK_NOT_SHOWING_ASSESSMENT_OUTCOMES.md) | Debugging calculation issues |
| [QUICK_START_BATCH_IMPORT.md](QUICK_START_BATCH_IMPORT.md) | Quick guide for batch import |

---

## 🎯 QUICK REFERENCE: WHAT TO USE WHEN

### To Display Mahasiswa Scores:
```
1. Use: assessment_outcomes_screen.dart (EXISTING TEMPLATE) ✅
2. Call: CPMKCPLCalculationService.loadCPMKForMahasiswa()
3. Call: CPMKCPLCalculationService.loadCPLForMahasiswa()
4. Display in tabbed view with status indicators
```

### To Calculate CPL:
```
1. Use: CPLCalculationService.calculateCPLForMahasiswa() OR
2. Use: CPLCalculationService.calculateCPLForAllMahasiswa()
3. Save CPL object to database
```

### To Calculate CPMK:
```
1. Use: CPMKCPLCalculationService.calculateCPMKForMahasiswa()
2. Input: cpmkId + mahasiswaId
3. Output: Double score (0-100)
```

### To Get Mappings:
```
1. Use: DatabaseHelper.getMappingByCPL() for CPMK→CPL
2. Use: DatabaseHelper.getMappingByCPMK() for CPL←CPMK
3. Use: DatabaseHelper.getSubCPMKMapping() for SubCPMK→CPMK
```

### To Get Bobot Matrix:
```
1. Use: DatabaseHelper.getBobotMatrixForMatakuliah()
2. Returns: Map<int, List<double>> with component weights
3. Use in calculation formulas
```

---

## 🔗 Import Statements for Common Uses

```dart
// For Display (use assessment_outcomes_screen pattern)
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/mahasiswa_model.dart';
import '../models/cpmk_model.dart';
import '../models/cpl_master_model.dart';
import '../services/database_helper.dart';
import '../services/cpmk_cpl_calculation_service.dart';

// For Calculation Service
import '../services/cpmk_cpl_calculation_service.dart';
final _calculationService = CPMKCPLCalculationService();

// For Database Access
import '../services/database_helper.dart';
final _dbHelper = DatabaseHelper();
```

---

**Version:** 1.0  
**Last Updated:** March 6, 2026  
**Status:** ✅ Quick Reference Complete
