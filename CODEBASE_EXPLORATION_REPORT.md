# 🔍 CPL/CPMK Codebase Exploration Report
**Date:** March 6, 2026  
**Purpose:** Understand structure for Measurement Screen Implementation

---

## 📍 1. SCREENS LOCATIONS

### Main CPL/CPMK Screens

| Screen | File Path | Purpose | Key Methods |
|--------|-----------|---------|-------------|
| **Hitung CPL** | [lib/screens/cpl_calculation_screen.dart](lib/screens/cpl_calculation_screen.dart) | Calculate CPL for all students | `calculateCPLForAllMahasiswa()` |
| **Assessment Outcomes** | [lib/screens/assessment_outcomes_screen.dart](lib/screens/assessment_outcomes_screen.dart) | View CPMK & CPL scores | `loadCPMKForMahasiswa()`, `loadCPLForMahasiswa()` |
| **CPMK-CPL Mapping** | [lib/screens/cpmk_cpl_mapping_screen.dart](lib/screens/cpmk_cpl_mapping_screen.dart) | Setup CPMK→CPL mapping | `getMappingByCPL()`, `getMappingByCPMK()` |
| **CPL Report** | [lib/screens/cpl_report_screen.dart](lib/screens/cpl_report_screen.dart) | CPL Statistics Report | - |
| **CPL Master** | [lib/screens/cpl_master_screen.dart](lib/screens/cpl_master_screen.dart) | Manage 7 CPLs | `getAllCPLMaster()` |

### 🎯 Assessment Outcomes is the BASE PATTERN for Measurement Screen
- **Structure:** Mahasiswa Selection → Tab View (2 tabs) → Score Display
- **Data Loading:** Parallel async loading of CPMK & CPL data
- **UI Pattern:** Can be used as template for Sub-CPMK measurement screen

---

## 🗄️ 2. DATABASE STRUCTURE FOR CPMK-CPL RELATIONSHIP

### A. Core Hierarchy Tables

```
HIERARCHY:
┌─────────────────────────────────────────────┐
│         CPL_MASTER (7 CPLs)                │
│  CPL.1, CPL.2, CPL.3, CPL.4, CPL.5, CPL.6, CPL.7
└─────────────────────────────────────────────┘
              ↑ (one-to-many)
              │ via CPMK_CPL_MAPPING (bobot: 0-100)
              │
┌─────────────────────────────────────────────┐
│         CPMK (multiple per Matakuliah)     │
│  CPMK.1, CPMK.2, CPMK.3, CPMK.4, ...      │
└─────────────────────────────────────────────┘
              ↑ (one-to-many)
              │ via SUB_CPMK_CPMK_MAPPING (bobot: 0-100)
              │
┌─────────────────────────────────────────────┐
│    SUB_CPMK (weekly learning objectives)   │
│  Details at week-level (minggu_ke)         │
└─────────────────────────────────────────────┘
```

### B. Key Mapping Tables

#### 1. **cpmk_cpl_mapping** (Links CPMK → CPL)
```sql
CREATE TABLE cpmk_cpl_mapping (
  id INTEGER PRIMARY KEY,
  cpmk_id INTEGER NOT NULL,        -- Reference to CPMK
  cpl_id INTEGER NOT NULL,         -- Reference to CPL_MASTER
  bobot REAL NOT NULL,             -- 0-100% (CPMK contribution to CPL)
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(cpmk_id, cpl_id)
);
```
**Purpose:** Define which CPMKs contribute to which CPLs and by how much

#### 2. **sub_cpmk_cpmk_mapping** (Links SubCPMK → CPMK)
```sql
CREATE TABLE sub_cpmk_cpmk_mapping (
  id INTEGER PRIMARY KEY,
  sub_cpmk_id INTEGER NOT NULL,   -- Reference to SUB_CPMK
  cpmk_id INTEGER NOT NULL,       -- Reference to CPMK
  bobot REAL NOT NULL,            -- 0-100% (SubCPMK contribution to CPMK)
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(sub_cpmk_id, cpmk_id)
);
```
**Purpose:** Define which SubCPMKs contribute to which CPMKs

#### 3. **rps_detail_sub_cpmk_bobot** (Weekly SubCPMK Bobot)
```sql
CREATE TABLE rps_detail_sub_cpmk_bobot (
  id INTEGER PRIMARY KEY,
  rps_detail_id INTEGER NOT NULL, -- Reference to RPS_DETAIL (week)
  sub_cpmk_id INTEGER NOT NULL,   -- Reference to SUB_CPMK
  bobot REAL NOT NULL,            -- Bobot for component calculation
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(rps_detail_id, sub_cpmk_id)
);
```
**Purpose:** Store how SubCPMK components are weighted in calculation

### C. Student Score Tables

#### 1. **nilai_komponen** (Component Score Breakdown)
```sql
CREATE TABLE nilai_komponen (
  id INTEGER PRIMARY KEY,
  mahasiswa_id INTEGER NOT NULL,    -- Student ID
  matakuliah_id INTEGER NOT NULL,   -- Course ID
  nilai_aktivitas REAL DEFAULT 0,
  nilai_proyek REAL DEFAULT 0,
  nilai_kuis REAL DEFAULT 0,
  nilai_tugas REAL DEFAULT 0,
  nilai_uts REAL DEFAULT 0,         -- Midterm
  nilai_uas REAL DEFAULT 0,         -- Final exam
  tahun_ajaran INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(mahasiswa_id, matakuliah_id, tahun_ajaran)
);
```
**Purpose:** Store detailed component scores for OBE calculation  
**Import Source:** Excel template (PANDUAN_IMPORT_NILAI_DETAIL.md)

#### 2. **sub_cpmk_nilai** (SubCPMK Individual Scores)
```sql
CREATE TABLE sub_cpmk_nilai (
  id INTEGER PRIMARY KEY,
  mahasiswa_id INTEGER NOT NULL,
  sub_cpmk_id INTEGER NOT NULL,
  nilai REAL NOT NULL,
  tahun_ajaran INTEGER NOT NULL,
  catatan TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(mahasiswa_id, sub_cpmk_id, tahun_ajaran)
);
```
**Purpose:** Store calculated SubCPMK scores per student

---

## 📊 3. CPMK-CPL CALCULATION LOGIC

### Current OBE Calculation Engine

**File:** [lib/services/cpmk_cpl_calculation_service.dart](lib/services/cpmk_cpl_calculation_service.dart)

#### A. CPMK Score Calculation ⭐ MAIN FLOW
**Method:** `calculateCPMKForMahasiswa(cpmkId, mahasiswaId)` (lines 244-369)

```
INPUT:
  - cpmkId: CPMK to calculate
  - mahasiswaId: Student ID

EXECUTION (6-Step OBE Process):
├─ Step 1: Find latest tahun_ajaran for student in course
├─ Step 2: Get component scores from nilai_komponen table
│          [aktivitas, proyek, kuis, tugas, uts, uas]
├─ Step 3: Extract component value array
├─ Step 4: Get bobot matrix for SubCPMK
├─ Step 5: Calculate SubCPMK values using OBE formula:
│          SubCPMK_value = Σ(component_value × bobot[i]) / Σ(bobot)
│
└─ Step 6: Calculate CPMK using SubCPMK bobot:
           CPMK_score = Σ(SubCPMK_value × bobot) / TotalBobot

OUTPUT:
  - Returns: double (0-100 scale)
  - Returns: null if data missing
```

#### B. CPL Score Calculation
**Method:** `calculateCPLForMahasiswa(cplId, mahasiswaId)` (lines 390-426)

```
FLOW:
1. Get CPMK_CPL_MAPPING rows for this CPL
2. For each contributing CPMK:
   ├─ Call calculateCPMKForMahasiswa() → CPMK_score
   └─ weight: CPMK_score × (bobot / 100)
3. CPL_score = Σ(weighted_CPMK) / (totalBobot / 100)

EXAMPLE:
  CPL.1 requires CPMK.1 (40%) + CPMK.2 (35%) + CPMK.3 (25%)
  If CPMK.1=85, CPMK.2=75, CPMK.3=80
  CPL.1 = (85×0.40 + 75×0.35 + 80×0.25) / 1.0
       = (34 + 26.25 + 20) / 1.0 = 80.25
```

#### C. Data Loading Methods (For UI Display)

**Method:** `loadCPMKForMahasiswa(mahasiswaId)` (lines 477-556)
```
Returns: List<Map<String, dynamic>>
  [
    {'id': 1, 'kode': 'CPMK.1', 'deskripsi': '...', 'score': 85.5},
    {'id': 2, 'kode': 'CPMK.2', 'deskripsi': '...', 'score': 78.2},
    ...
  ]
```

**Method:** `loadCPLForMahasiswa(mahasiswaId)` (lines 559-604)
```
Returns: List<Map<String, dynamic>>
  [
    {'id': 1, 'kodeCPL': 'CPL.1', 'deskripsi': '...', 'score': 80.25},
    {'id': 2, 'kodeCPL': 'CPL.2', 'deskripsi': '...', 'score': 75.60},
    ...
  ]
```

---

## 📋 4. MODEL FILES STRUCTURE

### A. Core Models

| Model | File | Key Fields | Relationships |
|-------|------|-----------|-----------------|
| **CPL** | [cpl_model.dart](lib/models/cpl_model.dart) | id, mahasiswaId, ipk, status, totalSku | → Mahasiswa |
| **CPLMaster** | [cpl_master_model.dart](lib/models/cpl_master_model.dart) | id, kodeCPL (CPL.1-7), deskripsi | ← CPMK via mapping |
| **CPMK** | [cpmk_model.dart](lib/models/cpmk_model.dart) | id, matakuliahId, kodeCPMK, deskripsi | ← CPLMaster, ← SubCPMK |
| **SubCPMK** | [sub_cpmk_model.dart](lib/models/sub_cpmk_model.dart) | id, matakuliahId, kodeSubCPMK, deskripsi | → CPMK |

### B. Mapping Models

| Model | File | Purpose |
|-------|------|---------|
| **CPMKCPLMapping** | [cpmk_cpl_mapping_model.dart](lib/models/cpmk_cpl_mapping_model.dart) | Links CPMK→CPL with bobot |
| **SubCPMKCPMKMapping** | [sub_cpmk_cpmk_mapping_model.dart](lib/models/sub_cpmk_cpmk_mapping_model.dart) | Links SubCPMK→CPMK with bobot |

### C. Student Score Models

| Model | File | Purpose |
|-------|------|---------|
| **NilaiModel** | [nilai_model.dart](lib/models/nilai_model.dart) | Overall grade (grade_huruf, nilai_numerik) |
| **NilaiKomponenModel** | [nilai_komponen_model.dart](lib/models/nilai_komponen_model.dart) | Component breakdown (aktivitas, proyek, kuis, tugas, uts, uas) |

---

## 🔧 5. SERVICE LAYER

### A. Main Services

#### **CPMKCPLCalculationService** [cpmk_cpl_calculation_service.dart](lib/services/cpmk_cpl_calculation_service.dart)
```dart
// Core Calculation Methods
✓ calculateCPMKForMahasiswa(cpmkId, mahasiswaId) → double
✓ calculateCPLForMahasiswa(cplId, mahasiswaId) → double
✓ calculateCPLScore(cplId) → double (system-level)
✓ calculateCPMKScoreForCourse(cpmkId, matakuliahId) → double

// Data Loading Methods
✓ loadCPMKForMahasiswa(mahasiswaId) → List<Map>
✓ loadCPLForMahasiswa(mahasiswaId) → List<Map>

// Helper Methods
✓ _normalizeToScale0_100(nilai) → double
✓ _getSubCpmkToCpmkBobot(matakuliahId) → Map<int, double>

// OBE Methods
✓ calculateCPMKUsingComponentScores() → double
```

#### **CPLCalculationService** [cpl_calculation_service.dart](lib/services/cpl_calculation_service.dart)
```dart
✓ calculateCPLForMahasiswa(mahasiswaId) → CPL?
✓ calculateCPLForAllMahasiswa() → List<CPL>
✓ calculateIPK() → double
```

#### **DatabaseHelper** [database_helper.dart](lib/services/database_helper.dart)
```dart
// Model Queries
✓ getAllCPMK() → List<CPMK>
✓ getCPMKByMatakuliah(matakuliahId) → List<CPMK>
✓ getCPMKById(cpmkId) → CPMK?
✓ getAllSubCPMK() → List<SubCPMK>
✓ getSubCPMKByMatakuliah(matakuliahId) → List<SubCPMK>
✓ getAllCPLMaster() → List<CPLMaster>

// Mapping Queries
✓ getMappingByCPL(cplId) → List<CPMKCPLMapping>
✓ getMappingByCPMK(cpmkId) → List<CPMKCPLMapping>
✓ getSubCPMKMapping(subCpmkId) → List<SubCPMKCPMKMapping>

// Score/Data Queries
✓ getNilaiKomponen(mahasiswaId, matakuliahId, tahunAjaran) → Map?
✓ getBobotMatrixForMatakuliah(matakuliahId) → Map?
✓ getSubCPMKToCPMKBobotMapping(matakuliahId) → Map<int, List<double>>

// Persistence
✓ insertCPMK(cpmk) → int
✓ updateCPMK(cpmk) → int
✓ deleteCPMK(id) → int
```

---

## 📐 6. ASSESSMENT OUTCOMES SCREEN - THE TEMPLATE

**File:** [lib/screens/assessment_outcomes_screen.dart](lib/screens/assessment_outcomes_screen.dart)

### Structure & Flow

```
INITIALIZATION:
├─ Load all mahasiswa
├─ Load all CPL Masters
├─ Load all CPMK
├─ Extract unique angkatan years
└─ Initialize TabController (2 tabs)

USER INTERACTION:
├─ Select Angkatan (from dropdown)
│  └─ Filter mahasiswa by tahun_masuk
├─ Select Mahasiswa (from filtered list)
│  └─ Call _loadMahasiswaScores()
│     ├─ _calculationService.loadCPMKForMahasiswa()
│     ├─ _calculationService.loadCPLForMahasiswa()
│     └─ Update _cpmkScores & _cplScores maps
└─ Display scores in tabbed view

UI COMPONENTS:
├─ Top: Angkatan dropdown filter
├─ Middle: Mahasiswa selection list
├─ Bottom: Tab View
│  ├─ Tab 1: CPMK Scores (grid/list)
│  └─ Tab 2: CPL Scores (grid/list)
└─ Each score row shows:
   ├─ Code (CPMK.1 / CPL.1)
   ├─ Description
   ├─ Score (numeric)
   └─ Status badge (color-coded)
```

### Key UI Methods
- `_loadData()` - Initialize with DB data
- `_filterMahasiswaByAngkatan(int)` - Filter students
- `_selectMahasiswa(Mahasiswa)` - Select & load scores
- `_loadMahasiswaScores(Mahasiswa)` - Async load CPMK & CPL
- `_getStatusLabel(double?)` - Map score to status text

### State Variables
```dart
List<Mahasiswa> _allMahasiswa;
List<Mahasiswa> _filteredMahasiswa;
List<int> _angkatanList;
int? _selectedAngkatan;
Mahasiswa? _selectedMahasiswa;

TabController _tabController;
List<CPMK> _cpmkList;
List<CPLMaster> _cplList;
Map<int, double?> _cpmkScores;  // cpmkId → score
Map<int, double?> _cplScores;   // cplId → score
bool _isLoading;
```

---

## 🏗️ 7. WHAT NEEDS TO BE MODIFIED FOR SUB-CPMK MEASUREMENT

### A. New Service Methods Needed

```dart
// In CPMKCPLCalculationService
Future<double?> calculateSubCPMKForMahasiswa(
  int subCpmkId, int mahasiswaId
) async {
  // Extract Step 5 from calculateCPMKForMahasiswa
  // Calculate SubCPMK value directly using component scores
}

Future<List<Map<String, dynamic>>> loadSubCPMKForMahasiswa(
  int mahasiswaId
) async {
  // Similar to loadCPMKForMahasiswa
  // Returns: [{'id', 'kode', 'deskripsi', 'score'}, ...]
}
```

### B. New Screen Needed (or extend existing)

```dart
// Option 1: Create new sub_cpmk_measurement_screen.dart
// - Similar structure to assessment_outcomes_screen
// - 3 tabs: SubCPMK, CPMK (aggregated), CPL (aggregated)

// Option 2: Extend assessment_outcomes_screen.dart
// - Add 3rd tab for SubCPMK detail view
// - Show drill-down: SubCPMK → CPMK → CPL
```

### C. Data Models (Already Exist!)
✅ SubCPMK model - EXISTS
✅ Database tables - EXIST
✅ Database methods - MAY NEED ONE: `getSubCPMKByMatakuliah()`
✅ Mapping methods - EXIST

### D. Database Helper Methods to Verify/Add
```dart
// Verify these exist:
✓ getSubCPMKByMatakuliah(matakuliahId) → List<SubCPMK>
✓ getSubCPMKMappingByCPMK(cpmkId) → List<SubCPMKCPMKMapping>
✓ getRPSDetailBobot(rpsDetailId) → Map<int, double>

// May need to add:
? getSubCPMKNilaiForMahasiswa(mahasiswaId) → List<SubCPMKNilai>
```

### E. Models - All Present
✅ SubCPMK model file exists
✅ SubCPMKValue tracking table exists (sub_cpmk_nilai)
✅ SubCPMKCPMKMapping exists
✅ RPS Detail Sub-CPMK Bobot exists

---

## 🔄 8. DATA FLOW FOR MEASUREMENT SCREEN

```
┌─────────────────────────────────────────────────────────────────┐
│ User selects Mahasiswa & Angkatan                              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
         ┌────────────▼────────────┐
         │ loadSubCPMKForMahasiswa() │
         │  (NEW METHOD)             │
         └────────────┬─────────────┘
                      │
    ┌─────────────────┴─────────────────┐
    │ For each SubCPMK in matakuliah:   │
    │
    └─────────────────┬─────────────────┘
                      │
        ┌─────────────▼──────────────┐
        │ calculateSubCPMKForMahasiswa() │
        └─────────────┬──────────────┘
                      │
    ┌─────────────────┴──────────────────┐
    │ Step 1: Find tahun_ajaran          │
    │ Step 2: Get component scores       │
    │ Step 3: Get bobot dari RPS Detail  │
    │ Step 4: Calculate:                 │
    │   SubCPMK = Σ(component×bobot)/Σ  │
    │                                    │
    └─────────────────┬──────────────────┘
                      │
         ┌────────────▼─────────────┐
         │ Return SubCPMK scores    │
         │ as List<Map>             │
         └────────────┬─────────────┘
                      │
         ┌────────────▼──────────────────┐
         │ Display in UI with:           │
         │ - Code (SUB-CPMK.1)           │
         │ - Description                 │
         │ - Score                       │
         │ - Status (Achieved/NotYet)    │
         └───────────────────────────────┘
```

---

## ✅ 9. SUMMARY TABLE: FILES & LINE REFERENCES

### Creating Measurement Screen - Checklist

| Item | File | Lines | Status | Notes |
|------|------|-------|--------|-------|
| **Screen Template** | assessment_outcomes_screen.dart | 1-200 | ✅ READY | Use as base pattern |
| **Calculation Logic** | cpmk_cpl_calculation_service.dart | 244-369 | ✅ READY | Extract Step 5 for SubCPMK |
| **Data Loading** | cpmk_cpl_calculation_service.dart | 477-556 | ✅ READY | Copy & modify for SubCPMK |
| **SubCPMK Model** | sub_cpmk_model.dart | 1-50 | ✅ READY | Already exists |
| **Database Methods** | database_helper.dart | 1-500+ | ✅ MOSTLY READY | May need `getSubCPMKByMatakuliah()` |
| **Sub-CPMK Tables** | database_helper.dart | 408-418 | ✅ READY | All tables exist |
| **Mapping Tables** | database_helper.dart | 360-375 | ✅ READY | sub_cpmk_cpmk_mapping exists |

---

## 🎯 10. NEXT STEPS RECOMMENDATION

### Phase 1: Create Sub-CPMK Service Methods
1. Create `calculateSubCPMKForMahasiswa(subCpmkId, mahasiswaId)`
   - Extract Step 5 logic from CPMK calculation
   - Input: SubCPMK ID + Student ID
   - Output: Score (0-100)

2. Create `loadSubCPMKForMahasiswa(mahasiswaId)`
   - Load all SubCPMK with calculated scores
   - Similar to `loadCPMKForMahasiswa()`
   - Output: List<Map> with [id, kode, deskripsi, score]

### Phase 2: Create Measurement Screen
1. Copy `assessment_outcomes_screen.dart` → `sub_cpmk_measurement_screen.dart`
2. Modify to use SubCPMK data instead of CPMK
3. Add hierarchy view: SubCPMK → CPMK → CPL

### Phase 3: Add Navigation
1. Add route to main.dart
2. Add menu button in admin dashboard
3. Add navigation from assessment_outcomes to measurement

---

## 📚 Related Documentation

- [IMPLEMENTASI_FIX_NILAI_KOMPONEN.md](IMPLEMENTASI_FIX_NILAI_KOMPONEN.md) - Component score calculation
- [PANDUAN_IMPORT_NILAI_DETAIL.md](PANDUAN_IMPORT_NILAI_DETAIL.md) - How to import component scores
- [FIX_CPMK_NOT_SHOWING_ASSESSMENT_OUTCOMES.md](FIX_CPMK_NOT_SHOWING_ASSESSMENT_OUTCOMES.md) - Debugging calculation
- [OBE_CALCULATION_ENGINE.md](OBE_CALCULATION_ENGINE.md) - OBE calculation explanation

---

**Report Generated:** March 6, 2026
**Status:** ✅ Complete - Ready for Implementation
