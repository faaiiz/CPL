# 📊 CPMK & CPL Storage and Retrieval Guide

## Overview

This guide documents how calculated CPMK and CPL scores are stored to the database and retrieved by the assessment outcomes screen.

---

## 1. DATABASE TABLE: `cpl_hasil_perhitungan`

### Table Definition

**File:** [lib/services/database_helper.dart](lib/services/database_helper.dart#L559)

```dart
CREATE TABLE cpl_hasil_perhitungan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  mahasiswa_id INTEGER NOT NULL,
  matakuliah_id INTEGER NOT NULL,
  tahun_ajaran INTEGER NOT NULL,
  sub_cpmk_values TEXT NOT NULL,        -- JSON format: "1:25.5|2:30.2|3:28.8"
  cpmk_values TEXT NOT NULL,            -- JSON format: "1:78.3|2:82.1"
  cpl_values TEXT NOT NULL,             -- JSON format: "1:85.5|2:88.2|3:80.1"
  sub_cpmk_bobots TEXT,                 -- Optional bobot matrix
  average_sub_cpmk_nilai REAL NOT NULL, -- Cached average for fast access
  average_cpmk_nilai REAL NOT NULL,     -- Cached average for fast access
  average_cpl_nilai REAL NOT NULL,      -- Cached average for fast access
  calculated_at TEXT NOT NULL,
  updated_at TEXT,
  FOREIGN KEY(mahasiswa_id) REFERENCES mahasiswa(id),
  FOREIGN KEY(matakuliah_id) REFERENCES matakuliah(id),
  UNIQUE(mahasiswa_id, matakuliah_id, tahun_ajaran)
);

-- Indexes for fast queries
CREATE INDEX idx_cpl_results_mk ON cpl_hasil_perhitungan(matakuliah_id, tahun_ajaran);
CREATE INDEX idx_cpl_results_mhs ON cpl_hasil_perhitungan(mahasiswa_id);
```

### Key Points
- ✅ **String Format Storage**: Map values serialized as `ID:VALUE|ID:VALUE` pairs
- ✅ **Three Main Value Columns**: `sub_cpmk_values`, `cpmk_values`, `cpl_values`
- ✅ **Denormalized Averages**: `average_sub_cpmk_nilai`, `average_cpmk_nilai`, `average_cpl_nilai` for quick display
- ✅ **Unique Constraint**: Prevents duplicate calculations for same (mahasiswa, matakuliah, tahun_ajaran)
- ✅ **Indexed Queries**: Fast lookups by (matakuliah_id, tahun_ajaran) or by mahasiswa_id

---

## 2. SAVING CALCULATED VALUES TO DATABASE

### Method: `saveCPLCalculationResults()`

**File:** [lib/services/database_helper.dart](lib/services/database_helper.dart#L1667)

```dart
/// Digunakan saat user klik "Hitung CPL" untuk menyimpan hasil permanen
Future<void> saveCPLCalculationResults(List<dynamic> results) async {
  final db = await database;
  final batch = db.batch();
  final now = DateTime.now().toIso8601String();

  try {
    for (final result in results) {
      // result adalah OBECalculationResult
      // Konversi Map ke String format untuk disimpan
      final subCpmkValuesJson = _mapToJson(result.subCPMKValues);
      final cpmkValuesJson = _mapToJson(result.cpmkValues);
      final cplValuesJson = _mapToJson(result.cplValues);
      final subCpmkBobotcsJson = result.subCpmkBobots != null 
          ? _mapToJson(result.subCpmkBobots!) 
          : '';

      batch.insert(
        tableCPLResults,
        {
          'mahasiswa_id': result.mahasiswaId,
          'matakuliah_id': result.matakuliahId,
          'tahun_ajaran': result.tahunAjaran,
          'sub_cpmk_values': subCpmkValuesJson,
          'cpmk_values': cpmkValuesJson,
          'cpl_values': cplValuesJson,
          'sub_cpmk_bobots': subCpmkBobotcsJson,
          'average_sub_cpmk_nilai': result.averageSubCPMKNilai,
          'average_cpmk_nilai': result.averageCPMKNilai,
          'average_cpl_nilai': result.averageCPLNilai,
          'calculated_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
    print('✅ CPL results saved for ${results.length} mahasiswa');
  } catch (e) {
    print('❌ Error saving CPL results: $e');
    rethrow;
  }
}
```

### Helper Method: `_mapToJson()`

**File:** [lib/services/database_helper.dart](lib/services/database_helper.dart#L1662)

```dart
/// Serialize Map<int, double> to string format: "1:25.5|2:30.2|3:28.8"
String _mapToJson(Map<int, double> data) {
  return data.entries.map((e) => '${e.key}:${e.value}').join('|');
}
```

### Usage Example

```dart
// After calculating OBE results
final results = await _obeHelper.calculateBatchOBEResultsForMatakuliah(
  matakuliahId: matakuliahId,
  tahunAjaran: tahunAjaran,
);

// Save to database
await _dbHelper.saveCPLCalculationResults(results);
```

---

## 3. RETRIEVING CALCULATED VALUES FROM DATABASE

### Method 1: Get All Results for a Mata Kuliah

**File:** [lib/services/database_helper.dart](lib/services/database_helper.dart#L1714)

```dart
/// Get hasil perhitungan CPL untuk semua mahasiswa di matakuliah tertentu
/// Returns List<Map> dari database (tanpa recalculate)
Future<List<Map<String, dynamic>>> getCPLCalculationResults(
  int matakuliahId, 
  int tahunAjaran
) async {
  final db = await database;
  
  try {
    final results = await db.query(
      tableCPLResults,
      where: 'matakuliah_id = ? AND tahun_ajaran = ?',
      whereArgs: [matakuliahId, tahunAjaran],
      orderBy: 'mahasiswa_id ASC',
    );
    
    return results;
  } catch (e) {
    print('Error getting CPL results: $e');
    return [];
  }
}
```

### Method 2: Get Results for Single Student

**File:** [lib/services/database_helper.dart](lib/services/database_helper.dart#L1731)

```dart
/// Get individual CPL result untuk satu mahasiswa
Future<Map<String, dynamic>?> getCPLCalculationResult(
  int mahasiswaId, 
  int matakuliahId, 
  int tahunAjaran
) async {
  final db = await database;
  
  try {
    final results = await db.query(
      tableCPLResults,
      where: 'mahasiswa_id = ? AND matakuliah_id = ? AND tahun_ajaran = ?',
      whereArgs: [mahasiswaId, matakuliahId, tahunAjaran],
    );
    
    return results.isNotEmpty ? results.first : null;
  } catch (e) {
    print('Error getting individual CPL result: $e');
    return null;
  }
}
```

---

## 4. ASSESSMENT OUTCOMES SCREEN: RETRIEVING PRE-CALCULATED VALUES

**File:** [lib/screens/assessment_outcomes_screen.dart](lib/screens/assessment_outcomes_screen.dart#L280)

### Dual-Path Strategy

The assessment outcomes screen uses a two-step approach:

#### Step 1: Try to Load from Database (if already calculated)

```dart
// Get saved result from database
final savedResult = await _dbHelper.getCPLCalculationResult(
  mahasiswaId,
  matakuliahId,
  tahunAjaran,
);

OBECalculationResult? mahasiswaResult;

if (savedResult != null) {
  // 🎯 Use PERMANENT results from database
  print('📦 Memuat hasil CPL dari database untuk MK $matakuliahId');
  
  // Convert database row to OBECalculationResult format
  final subCpmkValues = _convertToStringKeyMap(_parseJsonMapValue(savedResult['sub_cpmk_values'] ?? ''));
  final cpmkValues = _convertToStringKeyMap(_parseJsonMapValue(savedResult['cpmk_values'] ?? ''));
  final cplValues = _convertToStringKeyMap(_parseJsonMapValue(savedResult['cpl_values'] ?? ''));
  final subCpmkBobots = _parseJsonMapValue(savedResult['sub_cpmk_bobots'] ?? '');
  
  mahasiswaResult = OBECalculationResult(
    mahasiswaId: mahasiswaId,
    matakuliahId: matakuliahId,
    tahunAjaran: tahunAjaran,
    subCpmkValues: subCpmkValues,
    cpmkValues: cpmkValues,
    cplValues: cplValues,
    subCpmkBobots: subCpmkBobots.isNotEmpty ? subCpmkBobots.cast<int, double>() : null,
  );
} else {
  // Step 2: If not in database, calculate fresh
  print('🔄 Menghitung CPL untuk MK $matakuliahId (tidak ada di database)');
  
  final results = await _obeHelper.calculateBatchOBEResultsForMatakuliah(
    matakuliahId: matakuliahId,
    tahunAjaran: tahunAjaran,
  );
  
  // Find result for this student
  mahasiswaResult = results.firstWhere(
    (r) => r.mahasiswaId == mahasiswaId,
    orElse: () => OBECalculationResult.error('Hasil tidak ditemukan'),
  );
}
```

### Helper Methods: Parse & Convert

**File:** [lib/screens/assessment_outcomes_screen.dart](lib/screens/assessment_outcomes_screen.dart#L1189)

```dart
/// Parse JSON string from database to Map<int, double>
/// Format: "1:25.5|2:30.2|3:28.8" → {1: 25.5, 2: 30.2, 3: 28.8}
Map<int, double> _parseJsonMapValue(String jsonString) {
  if (jsonString.isEmpty) return {};
  
  try {
    final result = <int, double>{};
    final pairs = jsonString.split('|');
    
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final id = int.parse(parts[0]);
        final value = double.parse(parts[1]);
        result[id] = value;
      }
    }
    
    return result;
  } catch (e) {
    print('❌ Error parsing JSON map: $e');
    return {};
  }
}

/// Convert Map<int, double> to Map<String, double>
Map<String, double> _convertToStringKeyMap(Map<int, double> intMap) {
  final result = <String, double>{};
  for (final entry in intMap.entries) {
    result[entry.key.toString()] = entry.value;
  }
  return result;
}
```

---

## 5. OBECalculationResult MODEL

**File:** [lib/services/obe_calculation_helper.dart](lib/services/obe_calculation_helper.dart#L1826)

```dart
class OBECalculationResult {
  final bool success;
  final String? errorMessage;
  final Map<String, double> subCpmkValues;      // String keys for new format
  final Map<String, double> cpmkValues;         // String keys for new format
  final Map<String, double> cplValues;          // String keys for new format
  
  // Legacy fields untuk backward compatibility
  final int? mahasiswaId;
  final int? matakuliahId;
  final int? tahunAjaran;
  final Map<int, double>? subCpmkBobots;

  OBECalculationResult({
    bool? success,
    this.errorMessage,
    this.subCpmkValues = const {},
    this.cpmkValues = const {},
    this.cplValues = const {},
    this.mahasiswaId,
    this.matakuliahId,
    this.tahunAjaran,
    this.subCpmkBobots,
  }) : success = success ?? true;

  /// Rata-rata Sub-CPMK (rounded to 2 decimals)
  double get averageSubCPMK {
    if (subCpmkValues.isEmpty) return 0.0;
    final sum = subCpmkValues.values.fold<double>(0.0, (a, b) => a + b);
    return (sum / subCpmkValues.length * 100).round() / 100;
  }

  /// Rata-rata CPMK (rounded to 2 decimals)
  double get averageCPMK {
    if (cpmkValues.isEmpty) return 0.0;
    final sum = cpmkValues.values.fold<double>(0.0, (a, b) => a + b);
    return (sum / cpmkValues.length * 100).round() / 100;
  }

  /// Rata-rata CPL (rounded to 2 decimals)
  double get averageCPL {
    if (cplValues.isEmpty) return 0.0;
    final sum = cplValues.values.fold<double>(0.0, (a, b) => a + b);
    return (sum / cplValues.length * 100).round() / 100;
  }

  // Legacy getters for backward compatibility
  double get averageSubCPMKNilai => averageSubCPMK;
  double get averageCPMKNilai => averageCPMK;
  double get averageCPLNilai => averageCPL;

  /// Factory constructors
  factory OBECalculationResult.error(String message) {
    return OBECalculationResult(
      success: false,
      errorMessage: message,
    );
  }

  factory OBECalculationResult.success({
    required Map<String, double> subCpmkValues,
    required Map<String, double> cpmkValues,
    Map<String, double> cplValues = const {},
  }) {
    return OBECalculationResult(
      success: true,
      subCpmkValues: subCpmkValues,
      cpmkValues: cpmkValues,
      cplValues: cplValues,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': success ? 'success' : 'error',
      'message': errorMessage,
      'sub_cpmk': subCpmkValues,
      'cpmk': cpmkValues,
      'cpl': cplValues,
    };
  }
}
```

---

## 6. BATCH CALCULATION: HOW VALUES ARE CALCULATED & STORED

**File:** [lib/services/obe_calculation_helper.dart](lib/services/obe_calculation_helper.dart#L731)

### Complete Batch Calculation Flow

```dart
Future<List<OBECalculationResult>> calculateBatchOBEResultsForMatakuliah({
  required int matakuliahId,
  required int tahunAjaran,
  bool continueOnError = true,
}) async {
  try {
    final results = <OBECalculationResult>[];
    final errors = <int, String>{};

    // STEP 1: Get all nilai_komponen for this mata kuliah
    final allNilaiKomponen = await _dbHelper.getAllNilaiKomponen(
      matakuliahId: matakuliahId,
      tahunAjaran: tahunAjaran,
    );

    // STEP 2: Load bobot data (one-time)
    final subCpmkBobotMap = await _dbHelper.getRPSDetailSubCPMKBobot(matakuliahId);
    final cpmkSubCpmkMap = await _dbHelper.getCPMKSubCPMKMapping();
    final cplCpmkMap = await _dbHelper.getAllCPLCPMKMappings();

    // STEP 3: Process each student
    for (final nilaiData in allNilaiKomponen) {
      final mahasiswaId = nilaiData['mahasiswa_id'] as int;
      
      try {
        // Convert database row to calculation format
        final nilaiMap = <String, double>{
          'aktivitas': ((nilaiData['nilai_aktivitas'] ?? 0) as num).toDouble(),
          'proyek': ((nilaiData['nilai_proyek'] ?? 0) as num).toDouble(),
          'kuis': ((nilaiData['nilai_kuis'] ?? 0) as num).toDouble(),
          'tugas': ((nilaiData['nilai_tugas'] ?? 0) as num).toDouble(),
          'uts': ((nilaiData['nilai_uts'] ?? 0) as num).toDouble(),
          'uas': ((nilaiData['nilai_uas'] ?? 0) as num).toDouble(),
        };

        // STEP 4: Calculate OBE values
        final calculationResult = calculateOBEComplete(
          nilaiKomponen: nilaiMap,
          subCpmkBobotMap: subCpmkBobotMap,
          cpmkSubCpmkMap: cpmkSubCpmkMap,
          cplCpmkMap: cplCpmkMap,
        );

        // STEP 5: Create result object
        final obeResult = OBECalculationResult(
          mahasiswaId: mahasiswaId,
          matakuliahId: matakuliahId,
          tahunAjaran: tahunAjaran,
          subCpmkValues: (calculationResult['sub_cpmk'] as Map<String, dynamic>)
              .cast<String, double>(),
          cpmkValues: (calculationResult['cpmk'] as Map<String, dynamic>)
              .cast<String, double>(),
          cplValues: (calculationResult['cpl'] as Map<String, dynamic>?)
                  ?.cast<String, double>() ?? {},
          success: true,
        );

        results.add(obeResult);
      } catch (e) {
        errors[mahasiswaId] = e.toString();
        if (!continueOnError) rethrow;
      }
    }

    return results;
  } catch (e) {
    print('Error in batch calculation: $e');
    rethrow;
  }
}
```

---

## 7. COMPLETE DATA FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────┐
│                    CALCULATION PHASE                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Admin clicks "Hitung CPL"                                 │
│         ↓                                                    │
│  calculateBatchOBEResultsForMatakuliah()                   │
│    - Load nilai_komponen from database                     │
│    - Load bobot mappings from database                     │
│    - Calculate Sub-CPMK, CPMK, CPL values                 │
│    - Return List<OBECalculationResult>                     │
│         ↓                                                    │
│  saveCPLCalculationResults(results)                        │
│    - Serialize Map values to "ID:VALUE|..." format        │
│    - INSERT INTO cpl_hasil_perhitungan                     │
│         ↓                                                    │
│  ✅ Data saved to database                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  RETRIEVAL PHASE                            │
│            (Assessment Outcomes Screen)                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User selects mahasiswa and mata kuliah                    │
│         ↓                                                    │
│  getCPLCalculationResult(mahasiswaId, mkId, taId)         │
│    - Query cpl_hasil_perhitungan table                     │
│    - Returns Map with serialized values                    │
│         ↓                                                    │
│  IF EXISTS:                                                │
│    _parseJsonMapValue() → "1:78.3|2:82.1" → {1:78.3, ...}│
│    _convertToStringKeyMap() → {"1":78.3, "2":82.1, ...}   │
│    OBECalculationResult constructed from database row      │
│  ELSE:                                                     │
│    calculateBatchOBEResultsForMatakuliah() [dynamic calc]  │
│         ↓                                                    │
│  Display in assessment_outcomes_screen UI                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. KEY DESIGN DECISIONS

### ✅ Persistent Storage Benefits
- **Performance**: Avoid recalculation for already-computed results
- **Consistency**: Same values shown in multiple screens (admin dashboard, assessment outcomes)
- **Audit Trail**: `calculated_at` timestamp tracks when calculation was done
- **Scalability**: Indexed queries for fast retrieval of large datasets

### ✅ String Serialization Format
- **Reason**: SQLite doesn't have native JSON type in older versions
- **Format**: `ID:VALUE|ID:VALUE|...` (e.g., `1:78.3|2:82.1|3:85.5`)
- **Parsing**: Simple split/parse logic without external dependencies
- **Performance**: Fast to serialize and deserialize

### ✅ Cached Averages
- **Columns**: `average_sub_cpmk_nilai`, `average_cpmk_nilai`, `average_cpl_nilai`
- **Reason**: Quick UI display without recalculating averages
- **Consistency**: Calculated same way as in OBECalculationResult.averageX properties

### ✅ Unique Constraint
- **Purpose**: Prevent duplicate storage of same (mahasiswa, matakuliah, tahun_ajaran)
- **Behavior**: `ConflictAlgorithm.replace` in batch.insert() updates existing row if present
- **Result**: Always have latest calculation for each student-course combination

---

## 9. RELATED KEY FILES

| File | Purpose |
|------|---------|
| [lib/services/database_helper.dart](lib/services/database_helper.dart#L39) | Database table definitions & CRUD operations |
| [lib/services/obe_calculation_helper.dart](lib/services/obe_calculation_helper.dart#L731) | Calculation engine & batch processing |
| [lib/screens/assessment_outcomes_screen.dart](lib/screens/assessment_outcomes_screen.dart#L280) | Pre-calculated value retrieval & display |
| [lib/screens/admin_dashboard_screen.dart](lib/screens/admin_dashboard_screen.dart#L1553) | Trigger batch calculation & storage |

---

**Last Updated:** April 15, 2026  
**Version:** 1.0
