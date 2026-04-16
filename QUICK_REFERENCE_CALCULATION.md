# QUICK REFERENCE: CPMK Calculation Files & Methods

## Calculation Pipeline

**Component Scores → Sub-CPMK → CPMK → CPL**

---

## Core Calculation Methods

### 1️⃣ SUB-CPMK CALCULATION
**Service:** [obe_calculation_helper.dart](lib/services/obe_calculation_helper.dart)  
**Method:** `calculateSubCPMKValues()`  
**Formula:** `Sub-CPMK = Σ(nilai_komponen × bobot) / Σ(bobot)`

```dart
final subCpmkValues = helper.calculateSubCPMKValues(
  nilaiKomponen: {
    'aktivitas': 87.5,
    'proyek': 87.5,
    'kuis': 60.0,
    'tugas': 77.5,
    'uts': 85.0,
    'uas': 95.0,
  },
  subCpmkBobotMap: {
    'sub1': {'aktivitas': 6, 'proyek': 2.5, 'kuis': 6, ...},
    'sub2': {'aktivitas': 5, 'tugas': 6, ...},
  },
);
// Output: {'sub1': 76.12, 'sub2': 73.64, ...}
```

---

### 2️⃣ CPMK CALCULATION
**Service:** [obe_calculation_helper.dart](lib/services/obe_calculation_helper.dart)  
**Method:** `calculateCPMKValues()`  
**Formula:** `CPMK = Σ(Sub-CPMK × bobot) / Σ(bobot)`

```dart
final cpmkValues = helper.calculateCPMKValues(
  subCpmkValues: {'sub1': 76.12, 'sub2': 73.64, ...},
  cpmkSubCpmkMap: {
    'cpmk1': {'sub1': 20, 'sub2': 15, ...},
    'cpmk4': {'sub1': 14.5, 'sub2': 11, ...},
  },
);
// Output: {'cpmk1': 82.75, 'cpmk4': 81.25, ...}
```

---

### 3️⃣ CPL CALCULATION (Optional)
**Service:** [obe_calculation_helper.dart](lib/services/obe_calculation_helper.dart)  
**Method:** `calculateCPLValues()`  
**Formula:** `CPL = Σ(CPMK × bobot) / Σ(bobot)`

```dart
final cplValues = helper.calculateCPLValues(
  cpmkValues: {'cpmk1': 82.75, 'cpmk4': 81.25, ...},
  cplCpmkMap: {
    'cpl1': {'cpmk1': 30, 'cpmk2': 35, ...},
    'cpl3': {'cpmk1': 25, 'cpmk4': 20, ...},
  },
);
// Output: {'cpl1': 80.50, 'cpl3': 85.75, ...}
```

---

### 4️⃣ ALL-IN-ONE CALCULATION
**Service:** [obe_calculation_helper.dart](lib/services/obe_calculation_helper.dart)  
**Method:** `calculateOBEComplete()`

```dart
final result = helper.calculateOBEComplete(
  nilaiKomponen: {...},       // Step 1 input
  subCpmkBobotMap: {...},     // Step 2 bobot
  cpmkSubCpmkMap: {...},      // Step 3 bobot
  cplCpmkMap: {...},          // Step 4 bobot (optional)
);
// Output: {'sub_cpmk': {...}, 'cpmk': {...}, 'cpl': {...}}
```

---

## Key Data Models

| Model | Purpose | Key Fields |
|-------|---------|-----------|
| **CPMK** | Course learning outcomes | id, matakuliahId, kodeCPMK, deskripsi |
| **SubCPMK** | Sub-course outcomes | id, matakuliahId, kodeSubCPMK, deskripsi |
| **NilaiKomponen** | Component scores (6) | mahasiswaId, nilaiAktivitas, nilaiProyek, nilaiKuis, nilaiTugas, nilaiUTS, nilaiUAS |
| **SubCPMKNilai** | Calculated Sub-CPMK | mahasiswaId, subCpmkId, nilai (result) |
| **RPSDetailSubCPMKBobot** | Weekly Sub-CPMK weight | rpsDetailId, subCpmkId, bobot (%) |
| **SubCPMKCPMKMapping** | Sub-CPMK→CPMK weight | subCpmkId, cpmkId, bobot (%) |
| **CPMKCPLMapping** | CPMK→CPL weight | cpmkId, cplId, bobot (%) |

---

## Database Queries

### Get Component Scores
```dart
final nilaiKomponen = await dbHelper.getNilaiKomponen(
  mahasiswaId: 1,
  matakuliahId: 5,
  tahunAjaran: 2024,
);
// Returns: {nilai_aktivitas, nilai_proyek, nilai_kuis, ...}
```

### Get Bobot Data
```dart
// Sub-CPMK→Component bobot (for specific week in RPS)
final bobotList = await dbHelper.getRPSDetailSubCPMKBobot(rpsDetailId);

// Sub-CPMK→CPMK mapping with weights
final mappings = await dbHelper.getCPMKSubCPMKMapping(cpmkId);

// CPMK→CPL mapping
final mappings = await dbHelper.getMappingByCPL(cplId);
```

### Save Results
```dart
await dbHelper.saveCPLCalculationResults([
  {
    mahasiswaId: 1,
    matakuliahId: 5,
    tahunAjaran: 2024,
    subCpmkValues: {...},
    cpmkValues: {...},
    cplValues: {...},
    averageSubCpmkNilai: 75.5,
    averageCpmkNilai: 80.25,
    averageCplNilai: 82.0,
  }
]);
```

---

## Component Values (NilaiKomponen)

**6 Component Types (Scale 0-100):**
1. **Aktivitas** (Activity/Participation)
2. **Proyek** (Project)
3. **Kuis** (Quiz)
4. **Tugas** (Assignment)
5. **UTS** (Mid-term Exam)
6. **UAS** (Final Exam)

**Helper Method in Model:**
```dart
NilaiKomponen.getComponentNames()  // ['Aktivitas', 'Proyek', ...]
NilaiKomponen.getComponentValues() // [87.5, 87.5, 60, ...]
```

---

## Bobot/Weight Data

### Structure:
- **Sub-CPMK Bobot** = How components contribute to Sub-CPMK
  - Source: `rps_detail_sub_cpmk_bobot` table (weekly)
  - Format: `{aktivitas: 6, proyek: 2.5, kuis: 6, ...}` (%)
  - Total: ≈ 100% per week per Sub-CPMK

- **CPMK Bobot** = How Sub-CPMKs contribute to CPMK
  - Source: `sub_cpmk_cpmk_mapping` table
  - Format: `{sub1: 14.5, sub2: 11, ..., sub7: 12}` (%)
  - Total: = 100%

- **CPL Bobot** = How CPMKs contribute to CPL
  - Source: `cpmk_cpl_mapping` table
  - Format: `{cpmk1: 30, cpmk2: 35, ...}` (%)
  - Total: = 100%

---

## Validation & Error Handling

### OBEValidationConfig
```dart
// Production mode (lenient)
final config = OBEValidationConfig.production;

// Development mode (strict)
final config = OBEValidationConfig.development;

// Custom
const config = OBEValidationConfig(
  strictWeightValidation: false,
  strictValueValidation: false,
  warnOnFallback: true,
);
```

### Validation Checks
✅ Component values must exist (can't default to 0)  
✅ Total bobot must > 0  
✅ Bobot must be ≈ 100% (tolerance configurable)  
✅ Component values must be 0-100  
✅ Results rounded to 2 decimals  

---

## Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Bobot total ≠ 100 | Wrong RPS setup | Review `rps_detail_sub_cpmk_bobot` entries |
| Null Sub-CPMK value | Missing `sub_cpmk_nilai` entry | Calculate and save first |
| Wrong CPMK calculation | Using wrong bobot | Check `sub_cpmk_cpmk_mapping` table |
| Missing component | No `nilai_komponen` entry | Insert component scores first |

---

## Service Selection Guide

**When to use which service?**

| Use Case | Service | Method |
|----------|---------|--------|
| Calculate all 3 levels at once | OBECalculationHelper | `calculateOBEComplete()` |
| Only calculate Sub-CPMK | OBECalculationHelper | `calculateSubCPMKValues()` |
| Only calculate CPMK | OBECalculationHelper | `calculateCPMKValues()` |
| Get stored Sub-CPMK value | AcademicCalculationService | `calculateSubCPMKValue()` |
| Get stored CPMK value | AcademicCalculationService | `calculateCPMKValue()` |
| Per-student CPMK calculation | CPMKCPLCalculationService | `calculateCPMKForStudent()` |
| CPL completion status | CPLCalculationService | `calculateCPLForMahasiswa()` |

---

## File Locations Reference

```
lib/models/
├── cpmk_model.dart
├── sub_cpmk_model.dart
├── nilai_komponen_model.dart
├── sub_cpmk_nilai_model.dart
├── rps_detail_sub_cpmk_bobot_model.dart
├── sub_cpmk_cpmk_mapping_model.dart
└── cpmk_cpl_mapping_model.dart

lib/services/
├── obe_calculation_helper.dart              ⭐ MAIN Engine
├── academic_calculation_service.dart
├── cpmk_cpl_calculation_service.dart
├── cpl_calculation_service.dart
├── database_helper.dart                     ⭐ All queries
└── obe_calculation_helper_examples.dart     ⭐ Usage examples

test/
└── obe_calculation_test.dart

Root/
├── debug_fisika_matematika.dart
├── debug_rps_check.dart
└── fix_*.dart (various fixes)
```

---

## Example: Complete Student Calculation

```dart
// 1. Get component scores
final nilaiKomponen = await dbHelper.getNilaiKomponen(
  mahasiswaId: 1,
  matakuliahId: 5,
  tahunAjaran: 2024,
);

// 2. Get bobot mappings
final rpsDetails = await dbHelper.getRPSDetailByMatakuliah(5);
Map<String, Map<String, double>> subCpmkBobotMap = {};
for (var rps in rpsDetails) {
  final lebih bobots = await dbHelper.getRPSDetailSubCPMKBobot(rps.id!);
  // Build bobot map...
}

// 3. Get CPMK mappings
final cpmkMappings = await dbHelper.getCPMKSubCPMKMapping(cpmkId);

// 4. Calculate all levels
final helper = OBECalculationHelper(
  validationConfig: OBEValidationConfig.production,
);
final results = helper.calculateOBEComplete(
  nilaiKomponen: nilaiKomponen.cast<String, double>(),
  subCpmkBobotMap: subCpmkBobotMap,
  cpmkSubCpmkMap: cpmkSubCpmkMapData,
  cplCpmkMap: cplCpmkMapData,
);

// 5. Save results
await dbHelper.saveCPLCalculationResults([results]);
```

---

**Last Updated:** April 15, 2026  
**Version:** 1.0
