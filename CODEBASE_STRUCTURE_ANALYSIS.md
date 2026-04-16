# Codebase Structure Analysis: CPMK & SUB-CPMK Calculation System

**Last Updated:** April 15, 2026  
**Analysis Scope:** Complete calculation flow from component values → Sub-CPMK → CPMK → CPL

---

## 1. DATA STRUCTURES & MODELS

### 1.1 CPMK Model
**File:** [lib/models/cpmk_model.dart](lib/models/cpmk_model.dart)
```dart
class CPMK {
  final int? id;
  final int matakuliahId;
  final String kodeCPMK;        // CPMK.1, CPMK.2, etc
  final String deskripsi;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```
- **Purpose:** Represents Course-Level Learning Outcomes (Program Level)
- **Storage:** `cpmk` table in database
- **Key Fields:** ID, reference to course, code, description

### 1.2 SubCPMK Model
**File:** [lib/models/sub_cpmk_model.dart](lib/models/sub_cpmk_model.dart)
```dart
class SubCPMK {
  final int? id;
  final int matakuliahId;
  final String kodeSubCPMK;     // SUB-CPMK.1, SUB-CPMK.2, etc
  final String deskripsi;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```
- **Purpose:** Represents Sub-Course Learning Outcomes (Week/Session Level)
- **Storage:** `sub_cpmk` table in database
- **Key Fields:** ID, reference to course, code, description

### 1.3 NilaiKomponen Model (Component Scores)
**File:** [lib/models/nilai_komponen_model.dart](lib/models/nilai_komponen_model.dart)
```dart
class NilaiKomponen {
  final int? id;
  final int mahasiswaId;
  final int matakuliahId;
  final double nilaiAktivitas;    // Scale 0-100
  final double nilaiProyek;       // Scale 0-100
  final double nilaiKuis;         // Scale 0-100
  final double nilaiTugas;        // Scale 0-100
  final double nilaiUTS;          // Scale 0-100
  final double nilaiUAS;          // Scale 0-100
  final int tahunAjaran;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```
- **Purpose:** Stores individual component scores for each student per course
- **Storage:** `nilai_komponen` table in database
- **Components:** aktivitas, proyek, kuis, tugas, uts, uas (all scale 0-100)
- **Default Weights** (in `calculateFinalGrade()` method):
  - Aktivitas: 10%
  - Tugas: 10%
  - Proyek: 15%
  - Kuis: 15%
  - UTS: 25%
  - UAS: 25%

### 1.4 SubCPMKNilai Model
**File:** [lib/models/sub_cpmk_nilai_model.dart](lib/models/sub_cpmk_nilai_model.dart)
```dart
class SubCPMKNilai {
  final int? id;
  final int mahasiswaId;
  final int subCpmkId;
  final double nilai;             // The calculated Sub-CPMK score
  final int tahunAjaran;
  final String? catatan;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```
- **Purpose:** Stores calculated Sub-CPMK values per student per Sub-CPMK
- **Storage:** `sub_cpmk_nilai` table in database

### 1.5 Weight/Bobot Models

#### a) RPSDetailSubCPMKBobot
**File:** [lib/models/rps_detail_sub_cpmk_bobot_model.dart](lib/models/rps_detail_sub_cpmk_bobot_model.dart)
```dart
class RPSDetailSubCPMKBobot {
  final int? id;
  final int rpsDetailId;
  final int subCpmkId;
  final double bobot;             // Weight in % for this week
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```
- **Purpose:** Links RPS Detail (weekly plan) to Sub-CPMK with weight percentage
- **Storage:** `rps_detail_sub_cpmk_bobot` table
- **Usage:** Defines how each Sub-CPMK is weighted in specific course weeks

#### b) SubCPMKCPMKMapping
**File:** [lib/models/sub_cpmk_cpmk_mapping_model.dart](lib/models/sub_cpmk_cpmk_mapping_model.dart)
```dart
class SubCPMKCPMKMapping {
  final int? id;
  final int subCpmkId;
  final int cpmkId;
  final double bobot;             // Weight of Sub-CPMK toward CPMK (%)
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```
- **Purpose:** Maps Sub-CPMK values to CPMK with weight contribution
- **Storage:** `sub_cpmk_cpmk_mapping` table
- **Formula Usage:** `CPMK = Σ(Sub-CPMK_i × bobot_i) / Σ(bobot_i)`
- **Example:** Sub-CPMK 1 contributes 14.5% to CPMK 4

#### c) CPMKCPLMapping
**File:** [lib/models/cpmk_cpl_mapping_model.dart](lib/models/cpmk_cpl_mapping_model.dart)
```dart
class CPMKCPLMapping {
  final int? id;
  final int cpmkId;
  final int cplId;
  final double bobot;             // Weight of CPMK toward CPL (%)
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```
- **Purpose:** Maps CPMK values to CPL with weight contribution
- **Storage:** `cpmk_cpl_mapping` table
- **Formula Usage:** `CPL = Σ(CPMK_i × bobot_i) / Σ(bobot_i)`

---

## 2. CALCULATION SERVICES

### 2.1 OBE Calculation Helper (MAIN ENGINE)
**File:** [lib/services/obe_calculation_helper.dart](lib/services/obe_calculation_helper.dart)

**Version:** v3 (Refactored with validation config)

#### Core Methods:

**A. Sub-CPMK Calculation**
```dart
Map<String, double> calculateSubCPMKValues({
  required Map<String, double> nilaiKomponen,
  required Map<String, Map<String, double>> subCpmkBobotMap,
})
```
- **Input:** 
  - `nilaiKomponen`: {aktivitas: 87.5, proyek: 87.5, kuis: 60, ...}
  - `subCpmkBobotMap`: {"sub1": {aktivitas: 6, proyek: 2.5, ...}, ...}
- **Formula:** `Sub-CPMK_i = Σ(nilai_komponen_j × bobot_ij) / total_bobot_i`
- **Example:** 
  ```
  Sub-CPMK 276 = (87.5×6 + 87.5×2.5 + 60×6) / 14.5 = 76.12
  ```
- **Output:** `{"sub1": 76.12, "sub2": 72.50, ...}`
- **Validation:**
  - Only components with bobot > 0 are calculated
  - Total bobot must be > 0
  - All component values must exist (no missing values)
  - Rounds to 2 decimals

**B. CPMK Calculation**
```dart
Map<String, double> calculateCPMKValues({
  required Map<String, double> subCpmkValues,
  required Map<String, Map<String, double>> cpmkSubCpmkMap,
})
```
- **Input:**
  - `subCpmkValues`: Calculated Sub-CPMK values from Step A
  - `cpmkSubCpmkMap`: {"cpmk1": {"sub1": 14.5, "sub2": 11, ...}, ...}
- **Formula:** `CPMK = Σ(Sub-CPMK_i × bobot_total_i) / Σ(bobot_total_i)`
- **Example:**
  ```
  CPMK 4 = ((76.12×14.5) + (72.50×11) + ... + (89.17×12)) / 100 = 81.25
  ```
- **Output:** `{"cpmk1": 81.25, "cpmk2": 85.50}`
- **Validation:**
  - Bobot total must > 0
  - Sub-CPMK values must exist
  - Rounds to 2 decimals

**C. CPL Calculation**
```dart
Map<String, double> calculateCPLValues({
  required Map<String, double> cpmkValues,
  required Map<String, Map<String, double>> cplCpmkMap,
  bool useEqualWeightFallback = true,
})
```
- **Input:**
  - `cpmkValues`: Calculated CPMK values from Step B
  - `cplCpmkMap`: {"cpl1": {"cpmk1": 30, "cpmk2": 35, ...}, ...}
- **Formula:** `CPL = Σ(CPMK_i × bobot_cpmk_i) / Σ(bobot_cpmk_i)` (weighted average)
- **Output:** `{"cpl1": 80.50, "cpl2": 85.75}`
- **Fallback:** If no bobot available, uses equal weight (simple average)
- **Validation:**
  - CPMK values must exist
  - Rounds to 2 decimals

**D. Complete All-in-One Calculation**
```dart
Map<String, dynamic> calculateOBEComplete({
  required Map<String, double> nilaiKomponen,
  required Map<String, Map<String, double>> subCpmkBobotMap,
  required Map<String, Map<String, double>> cpmkSubCpmkMap,
  Map<String, Map<String, double>>? cplCpmkMap,
})
```
- **Returns:**
  ```dart
  {
    "sub_cpmk": {"sub1": 76.12, ...},
    "cpmk": {"cpmk1": 81.25, ...},
    "cpl": {"cpl1": 80.50, ...}
  }
  ```

#### Validation Configuration:
```dart
class OBEValidationConfig {
  final bool strictWeightValidation;          // Default: false
  final bool strictValueValidation;           // Default: false
  final bool warnOnFallback;                  // Default: true
  
  // Production: lenient (warnings only)
  static const OBEValidationConfig production = OBEValidationConfig(...);
  
  // Development: strict (throws errors)
  static const OBEValidationConfig development = OBEValidationConfig(...);
}
```

---

### 2.2 Academic Calculation Service
**File:** [lib/services/academic_calculation_service.dart](lib/services/academic_calculation_service.dart)

#### Key Methods:

**A. Calculate Sub-CPMK Value**
```dart
Future<double?> calculateSubCPMKValue(
  int mahasiswaId,
  int subCpmkId,
  int tahunAjaran,
) → double?
```
- **Source:** Fetches from `sub_cpmk_nilai` table
- **Returns:** Pre-calculated Sub-CPMK nilai or null

**B. Calculate CPMK Value**
```dart
Future<double?> calculateCPMKValue(
  int mahasiswaId,
  int cpmkId,
  int tahunAjaran,
) → double?
```
- **Process:**
  1. Get all Sub-CPMK mapped to this CPMK (`sub_cpmk_cpmk_mapping`)
  2. Fetch each Sub-CPMK value from `sub_cpmk_nilai`
  3. Apply bobot: `CPMK = Σ(Sub-CPMK × bobot) / Σ(bobot)`
- **Returns:** Weighted CPMK score or null

**C. Calculate Matakuliah Value**
```dart
Future<double?> calculateMatakuliahValue(
  int mahasiswaId,
  int matakuliahId,
  int tahunAjaran,
) → double?
```
- **Process:**
  1. Get all RPS Detail for this course
  2. For each week, get Sub-CPMK bobot from `rps_detail_sub_cpmk_bobot`
  3. Calculate: `MK = Σ(Sub-CPMK_value × RPS_bobot)`
- **Returns:** Course-level weighted score

**D. Calculate CPL Value**
```dart
Future<double?> calculateCPLValue(
  int mahasiswaId,
  int cplId,
  int tahunAjaran,
) → double?
```
- **Process:**
  1. Get all CPMK mapped to this CPL via `cpmk_cpl_mapping`
  2. Get course (matakuliah) for each CPMK
  3. Calculate weighted average: `CPL = Σ(CPMK × SKS) / Σ(SKS)`
- **Returns:** CPL score for this student

---

### 2.3 CPMK-CPL Calculation Service
**File:** [lib/services/cpmk_cpl_calculation_service.dart](lib/services/cpmk_cpl_calculation_service.dart)

#### Key Methods:

**A. Calculate CPMK for Student**
```dart
Future<double?> calculateCPMKForStudent(
  int cpmkId,
  int mahasiswaId,
) → double?
```
- **Key Feature:** Per-student calculation (not global average)
- **Process:**
  1. Get CPMK and its course
  2. Get nilai for this student in that course only
  3. Normalize to 0-100 scale (if needed)
  4. Return average for this student
- **Note:** Fixes bug where CPMK was calculated across all students

**B. Calculate CPL for Student**
```dart
Future<double?> calculateCPLForStudent(
  int cplId,
  int mahasiswaId,
) → double?
```
- **Process:**
  1. Get all CPMK contributing to this CPL
  2. For each CPMK, calculate student's CPMK score
  3. Weight by SKS: `CPL = Σ(CPMK_score × SKS) / Σ(SKS)`
- **Returns:** CPL score specific to this student

**C. Normalization Helper**
```dart
double _normalizeToScale0_100(double nilai)
```
- If nilai > 4: already in 0-100 scale → use as is
- If nilai ≤ 4: in 0-4 scale → multiply by 25 to convert

---

### 2.4 CPL Calculation Service
**File:** [lib/services/cpl_calculation_service.dart](lib/services/cpl_calculation_service.dart)

#### Purpose:
Legacy service for calculating CPL completion status (not OBE-based)

#### Key Methods:

**A. Calculate CPL for Mahasiswa**
```dart
Future<CPL?> calculateCPLForMahasiswa(int mahasiswaId) → CPL?
```
- **Returns:** CPL object with status (memenuhi_cpl, tidak_memenuhi_cpl, etc.)
- **Criteria:**
  - Minimum IPK: 2.0
  - Minimum average nilai: 2.0
  - Minimum total SKU: 144

**B. IPK Calculation**
```dart
double _calculateIPK(List<Nilai> nilaiList, List<Matakuliah> allMatakuliah)
```
- **Formula:** `IPK = Σ(nilai × SKS) / Σ(SKS)` (weighted average by SKS)

---

## 3. DATABASE OPERATIONS

### 3.1 Key Database Queries
**File:** [lib/services/database_helper.dart](lib/services/database_helper.dart)

#### Sub-CPMK Related:
- `getSubCPMKByMatakuliah(matakuliahId)` → List<SubCPMK>
  - Gets all Sub-CPMK for a course
  - Ordered by code

#### RPS & Bobot Related:
- `getRPSDetailByMatakuliah(matakuliahId)` → List<RPSDetail>
  - Gets all weekly plans for a course
- `getRPSDetailSubCPMKBobot(rpsDetailId)` → List<Map>
  - Gets Sub-CPMK weight distribution for a specific week
- `getRPSDetailSubCPMKBobotSingle(rpsDetailId, subCpmkId)` → Map?
  - Gets single bobot entry

#### Mapping Related:
- `getCPMKSubCPMKMapping(cpmkId)` → List<Map>
  - Gets all Sub-CPMK → CPMK mappings
- `getMappingByCPL(cplId)` → List<CPMKCPLMapping>
  - Gets all CPMK → CPL mappings

#### Component Values:
- `getNilaiKomponen(mahasiswaId, matakuliahId, tahunAjaran)` → Map?
  - Gets component scores (aktivitas, proyek, kuis, tugas, uts, uas)
- `getNilaiKomponenByMahasiswa(mahasiswaId, tahunAjaran)` → List<Map>
  - Gets all component scores for a student across all courses

#### Sub-CPMK Values:
- `getSubCPMKNilai(mahasiswaId, subCpmkId, tahunAjaran)` → Map?
  - Gets calculated Sub-CPMK value
- `getSubCPMKNilaiByMahasiswa(mahasiswaId, tahunAjaran)` → List<Map>
  - Gets all Sub-CPMK values for a student

#### CPL Results (Persistent Storage):
- `saveCPLCalculationResults(List<dynamic> results)` → void
  - Saves calculation results to `cpl_hasil_perhitungan` table
- `getCPLCalculationResults(matakuliahId, tahunAjaran)` → List<Map>
  - Retrieves saved calculation results (doesn't recalculate)

---

## 4. DATABASE SCHEMA

### Core Tables for CPMK/Sub-CPMK Calculation:

```
sub_cpmk
├── id (PK)
├── matakuliah_id (FK)
├── kode_sub_cpmk
├── deskripsi
└── timestamps

cpmk
├── id (PK)
├── matakuliah_id (FK)
├── kode_cpmk
├── deskripsi
└── timestamps

nilai_komponen
├── id (PK)
├── mahasiswa_id (FK)
├── matakuliah_id (FK)
├── nilai_aktivitas
├── nilai_proyek
├── nilai_kuis
├── nilai_tugas
├── nilai_uts
├── nilai_uas
├── tahun_ajaran
└── timestamps

sub_cpmk_nilai
├── id (PK)
├── mahasiswa_id (FK)
├── sub_cpmk_id (FK)
├── nilai (calculated Sub-CPMK score)
├── tahun_ajaran
└── timestamps

rps_detail
├── id (PK)
├── matakuliah_id (FK)
├── minggu_ke
├── sub_cpmk_ids (text, comma-separated)
└── timestamps

rps_detail_sub_cpmk_bobot
├── id (PK)
├── rps_detail_id (FK)
├── sub_cpmk_id (FK)
├── bobot (% weight for this week)
└── timestamps

sub_cpmk_cpmk_mapping
├── id (PK)
├── sub_cpmk_id (FK)
├── cpmk_id (FK)
├── bobot (% contribution to CPMK)
└── timestamps

cpmk_cpl_mapping
├── id (PK)
├── cpmk_id (FK)
├── cpl_id (FK)
├── bobot (% contribution to CPL)
└── timestamps

cpl_hasil_perhitungan (v8+)
├── id (PK)
├── mahasiswa_id (FK)
├── matakuliah_id (FK)
├── tahun_ajaran
├── sub_cpmk_values (JSON string)
├── cpmk_values (JSON string)
├── cpl_values (JSON string)
├── average_sub_cpmk_nilai
├── average_cpmk_nilai
├── average_cpl_nilai
└── timestamps
```

---

## 5. DEBUG & TRACE FILES

### 5.1 Debug Files
**Files:**
- [debug_fisika_matematika.dart](debug_fisika_matematika.dart)
  - Opens database and queries: Matakuliah, CPMK, Sub-CPMK, RPS structure
  - Diagnostic output for "Fisika Matematika" course

- [debug_rps_check.dart](debug_rps_check.dart)
  - Checks RPS structure and Sub-CPMK assignments

### 5.2 Fix Scripts
**Files:**
- [fix_mapping.dart](fix_mapping.dart)
  - Fixes Sub-CPMK to CPMK mapping
- [fix_subcpmk_mapping.dart](fix_subcpmk_mapping.dart)
  - Fixes Sub-CPMK mapping issues
- [fix_db_direct.dart](fix_db_direct.dart)
  - Direct database fixes

### 5.3 Test Files
**File:** [test/obe_calculation_test.dart](test/obe_calculation_test.dart)
- Tests `calculateSubCPMKWithMatrix()` method
- Validates calculation accuracy
- Tests error handling

---

## 6. COMPLETE CALCULATION FLOW

### Flow Diagram:
```
┌─────────────────────────────────────────────────────────────┐
│ INPUT: Component Scores (nilai_komponen table)              │
│ - nilaiAktivitas, nilaiProyek, nilaiKuis, nilaiTugas        │
│ - nilaiUTS, nilaiUAS (all scale 0-100)                      │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: FETCH BOBOT DATA                                    │
│ - Sub-CPMK ← Komponen bobot (from rps_detail_sub_cpmk_bobot)│
│ - CPMK ← Sub-CPMK bobot (from sub_cpmk_cpmk_mapping)       │
│ - CPL ← CPMK bobot (from cpmk_cpl_mapping)                 │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: CALCULATE SUB-CPMK                                  │
│ calculateSubCPMKValues()                                     │
│ Formula: Sub-CPMK = Σ(nilai × bobot) / Σ(bobot)            │
│ Output: {"sub1": 76.12, "sub2": 72.50, ...}               │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: CALCULATE CPMK                                      │
│ calculateCPMKValues()                                        │
│ Formula: CPMK = Σ(Sub-CPMK × bobot) / Σ(bobot)            │
│ Output: {"cpmk1": 81.25, "cpmk2": 85.50, ...}            │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 4: CALCULATE CPL (Optional)                            │
│ calculateCPLValues()                                         │
│ Formula: CPL = Σ(CPMK × bobot) / Σ(bobot)                  │
│ Output: {"cpl1": 80.50, "cpl2": 85.75, ...}              │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│ OUTPUT: Calculation Results                                  │
│ - Sub-CPMK values: Stored in sub_cpmk_nilai table          │
│ - CPMK values: Calculated on demand                         │
│ - CPL values: Optional, calculated on demand               │
└─────────────────────────────────────────────────────────────┘
```

### Example Calculation (Fisika Matematika I):

**Input:** Student #1, Course #5 (Fisika Matematika I), Year 2024
```
Nilai Komponen:
- nilaiAktivitas = 87.5
- nilaiProyek = 87.5
- nilaiKuis = 60.0
- nilaiTugas = 77.5
- nilaiUTS = 85.0
- nilaiUAS = 95.0
```

**RPS Bobot Assignment (example):**
```
Sub-CPMK 1 ← Aktivitas (6%) + Proyek (2.5%) + Kuis (6%)
         = (87.5×6 + 87.5×2.5 + 60×6) / 14.5
         = 1103.75 / 14.5
         = 76.12

Sub-CPMK 2 ← Aktivitas (5%) + Tugas (6%)
         = (87.5×5 + 77.5×6) / 11
         = 810 / 11
         = 73.64
```

**CPMK Calculation:**
```
CPMK 4 ← Sub-CPMK 1 (14.5%) + Sub-CPMK 2 (11%) + ... + Sub-CPMK 7 (12%)
       = (76.12×14.5 + 73.64×11 + ... + 89.17×12) / 100
       = 8125.08 / 100
       = 81.25
```

---

## 7. CURRENT DEBUG LOGGING

### Log Points in Code:

**OBECalculationHelper:**
- `calculateSubCPMKValues()`: Logs bobot validation and component values
- `calculateCPMKValues()`: Logs Sub-CPMK aggregation
- `calculateCPLValues()`: Logs CPMK to CPL mapping

**DatabaseHelper:**
- `insertRPSDetail()`: "DEBUG DB: insertRPSDetail - data: ..."
- `updateRPSDetail()`: "DEBUG DB: updateRPSDetail - id=X, data: ..."

**CPMKCPLCalculationService:**
- `_getSubCpmkToCpmkBobot()`: Hardcoded bobot for Kalkulus (needs extension)

---

## 8. KEY FILES SUMMARY TABLE

| Category | File | Purpose | Key Methods |
|----------|------|---------|------------|
| **Models** | cpmk_model.dart | CPMK structure | fromMap(), toMap() |
| | sub_cpmk_model.dart | Sub-CPMK structure | fromMap(), toMap() |
| | nilai_komponen_model.dart | Component scores | getComponentValues(), isValid() |
| | sub_cpmk_nilai_model.dart | Sub-CPMK values | fromMap(), toMap() |
| | rps_detail_sub_cpmk_bobot_model.dart | Weekly bobot | fromMap(), toMap() |
| | sub_cpmk_cpmk_mapping_model.dart | Sub-CPMK→CPMK mapping | fromMap(), toMap() |
| | cpmk_cpl_mapping_model.dart | CPMK→CPL mapping | fromMap(), toMap() |
| **Calculation** | obe_calculation_helper.dart | Main OBE engine | calculateSubCPMKValues(), calculateCPMKValues(), calculateCPLValues(), calculateOBEComplete() |
| | academic_calculation_service.dart | Database-driven calc | calculateSubCPMKValue(), calculateCPMKValue(), calculateMatakuliahValue(), calculateCPLValue() |
| | cpmk_cpl_calculation_service.dart | CPMK/CPL per student | calculateCPMKForStudent(), calculateCPLForStudent() |
| | cpl_calculation_service.dart | CPL status & completion | calculateCPLForMahasiswa(), _calculateIPK() |
| **Database** | database_helper.dart | All CRUD + queries | getNilaiKomponen(), getSubCPMKNilai(), getRPSDetailSubCPMKBobot(), getCPMKSubCPMKMapping(), saveCPLCalculationResults() |
| **Debug** | debug_fisika_matematika.dart | Course structure dump | Main function only |
| | debug_rps_check.dart | RPS structure check | Main function only |
| **Tests** | test/obe_calculation_test.dart | OBE calc validation | Test cases for Sub-CPMK, CPMK, error handling |

---

## 9. IMPORTANT NOTES & INSIGHTS

### 9.1 OBE Compliance:
✅ **Mandatory requirements implemented:**
- All calculations go through Sub-CPMK (no direct CPMK from components)
- Bobot data is fetched from database (not hardcoded)
- Weights are validated (total > 0, must exist)
- Missing component values throw errors
- Results rounded to 2 decimals
- OBEValidationConfig allows flexible validation strategy

### 9.2 Known Limitations:
⚠️ **Current Issues:**
1. **Hardcoded Bobot**: In `cpmk_cpl_calculation_service.dart`, Sub-CPMK→CPMK bobot is hardcoded for Kalkulus course
   - Fix: Implement `_getSubCpmkToCpmkBobot()` to fetch from database
2. **Limited Debug Logging**: Need more trace points in actual calculation methods
3. **No Real-time Validation**: Bobot totals aren't validated until calculation time

### 9.3 Data Flow Issues to Watch:
⚠️ **Critical Pipeline Points:**
1. Component→Sub-CPMK: Requires `rps_detail_sub_cpmk_bobot` to have correct week assignments
2. Sub-CPMK→CPMK: Requires `sub_cpmk_cpmk_mapping` with sum of bobot ≈ 100%
3. CPMK→CPL: Requires `cpmk_cpl_mapping` with correct weight distribution
4. Missing bobot data = null/error at calculation time

### 9.4 Performance Considerations:
- Calculate methods are async (database queries)
- No batch optimization for multiple students
- Consider caching bobot data for repeated calculations
- CPL results table (`cpl_hasil_perhitungan`) provides persistent caching

---

## 10. RECOMMENDED ENHANCEMENTS

### Short-term:
1. ✅ Extend `_getSubCpmkToCpmkBobot()` to fetch from database instead of hardcoding
2. ✅ Add comprehensive debug logging in OBE calculation steps
3. ✅ Implement bobot validation before calculation (not just during)

### Medium-term:
1. Add caching layer for bobot mappings
2. Implement batch calculation for performance
3. Add calculation validation framework
4. Create calculation audit trail

### Long-term:
1. Separate bobot management UI from calculation engine
2. Implement multi-course CPL aggregation
3. Add calculation tuning dashboard
4. Implement historical calculation comparison

---

*End of Analysis*
