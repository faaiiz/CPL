# 🔄 CODE MIGRATION GUIDE - OBE CALCULATION ENGINE v3

## Before & After Examples

Complete examples showing how to migrate from v2 (old) to v3 (new).

---

## ✅ Example 1: Basic Sub-CPMK Calculation

### ❌ OLD CODE (v2)

```dart
final helper = OBECalculationHelper();

final result = helper.calculateSubCPMKValues(
  nilaiKomponen: {
    'aktivitas': 80.0,
    'proyek': 85.0,
    'kuis': 90.0,
    'tugas': 75.0,
    'uts': 88.0,
    'uas': 92.0,
  },
  subCpmkBobotMap: {
    'sub1': {
      'aktivitas': 100.0 / 6.0,  // ❌ Hardcoded equal distribution
      'proyek': 100.0 / 6.0,
      'kuis': 100.0 / 6.0,
      'tugas': 100.0 / 6.0,
      'uts': 100.0 / 6.0,
      'uas': 100.0 / 6.0,
    }
  },
);

print('Sub-CPMK 1: ${result['sub1']}'); // 85.0 (simple average)
```

### ✅ NEW CODE (v3)

```dart
// With production-grade validation
final config = OBEValidationConfig.production;
final helper = OBECalculationHelper(validationConfig: config);

// Load bobot from database (not hardcoded)
final subCpmkBobotMap = await _getSubCpmkBobotMapFromDatabase(matakuliahId);

final result = helper.calculateSubCPMKValues(
  nilaiKomponen: {
    'aktivitas': 80.0,
    'proyek': 85.0,
    'kuis': 90.0,
    'tugas': 75.0,
    'uts': 88.0,
    'uas': 92.0,
  },
  subCpmkBobotMap: subCpmkBobotMap, // ✅ From database
);

// Result now has proper validation
if (result.isNotEmpty) {
  print('Sub-CPMK 1: ${result['sub1']}'); // Validated and weighted
}
```

**Key Changes**:
- Bobot loaded from database (not hardcoded)
- Weights are data-driven
- Validation enabled by default

---

## ✅ Example 2: Complete OBE Calculation

### ❌ OLD CODE (v2) - CPL as List

```dart
final result = helper.calculateOBEComplete(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobotMap,
  cpmkSubCpmkMap: cpmkSubCpmkMap,
  cplCpmkMap: {
    'cpl1': ['cpmk1', 'cpmk2', 'cpmk3'],  // ❌ Simple list
    'cpl2': ['cpmk4', 'cpmk5', 'cpmk6'],
  }
);

// CPL calculated as simple average
// If CPMK values are [80, 90, 70], CPL = (80+90+70)/3 = 80
// But what if importance is [50%, 35%, 15%]? ❌ WRONG
```

### ✅ NEW CODE (v3) - CPL with Weights

```dart
final result = helper.calculateOBEComplete(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobotMap,
  cpmkSubCpmkMap: cpmkSubCpmkMap,
  cplCpmkMap: {
    'cpl1': {
      'cpmk1': 50.0,  // ✅ Weighted aggregation
      'cpmk2': 35.0,
      'cpmk3': 15.0,
    },
    'cpl2': {
      'cpmk4': 40.0,
      'cpmk5': 60.0,
    }
  }
);

// CPL now calculated with weights
// If CPMK values are [80, 90, 70] with weights [50, 35, 15]:
// CPL = (80*50 + 90*35 + 70*15) / (50+35+15) = (4000+3150+1050)/100 = 82.0 ✓
```

**Key Changes**:
- CPL map changed from `List<String>` to `Map<String, double>`
- CPL now uses weighted aggregation (OBE compliant)
- Better semantic representation of importance

---

## ✅ Example 3: Error Handling

### ❌ OLD CODE (v2) - Missing Values Silently Default to 0

```dart
// Student grade missing for 'aktivitas'
final nilaiKomponen = {
  // 'aktivitas': missing  ← Silent default to 0.0
  'proyek': 85.0,
  'kuis': 90.0,
  'tugas': 75.0,
  'uts': 88.0,
  'uas': 92.0,
};

final result = helper.calculateSubCPMKValues(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobotMap,
);

// Result: aktivitas counted as 0.0 ❌ WRONG GRADE
// No error, no warning - just silently wrong
```

### ✅ NEW CODE (v3) - Missing Values Throw Error

```dart
final nilaiKomponen = {
  // 'aktivitas': missing
  'proyek': 85.0,
  'kuis': 90.0,
  'tugas': 75.0,
  'uts': 88.0,
  'uas': 92.0,
};

try {
  final result = helper.calculateSubCPMKValues(
    nilaiKomponen: nilaiKomponen,
    subCpmkBobotMap: subCpmkBobotMap,
  );
} catch (e) {
  print(e); // ✅ Clear error
  // ❌ Sub-CPMK "sub1": Nilai komponen "aktivitas" tidak ditemukan 
  //    (tidak boleh missing, harus ada atau 0.0 explicitly set)
}
```

**Key Changes**:
- Missing values throw explicit error
- Developer must fix missing data (not silently wrong)
- Clear guidance on what's missing

---

## ✅ Example 4: Batch Processing with Error Aggregation

### ❌ OLD CODE (v2) - Limited Error Info

```dart
final results = await helper.calculateBatchOBEResultsForMatakuliah(
  matakuliahId: 1,
  tahunAjaran: 2024,
);

print('Batch completed: ${results.length} mahasiswa processed');

// If some failed:
// ⚠️ Perhitungan gagal untuk mahasiswa 1001: ...
// ⚠️ Perhitungan gagal untuk mahasiswa 1003: ...
// ✅ Batch calculation completed: 118 mahasiswa processed

// ❌ Hard to tell: which ones failed? why? total failed count?
```

### ✅ NEW CODE (v3) - Detailed Error Summary

```dart
final results = await helper.calculateBatchOBEResultsForMatakuliah(
  matakuliahId: 1,
  tahunAjaran: 2024,
  continueOnError: true,  // ✅ Configurable error handling
);

// Generates clean summary:
// ============================================================
// 📊 BATCH CALCULATION SUMMARY
// ============================================================
// Total Mahasiswa: 120
// Success: 115
// Failed: 5
//
// ❌ Failed Mahasiswa:
//    1001: Nilai komponen "aktivitas" tidak ditemukan
//    1003: Nilai komponen "tugas" tidak ditemukan
//    1045: Sub-CPMK total bobot = 0 (harus > 0)
//    1067: CPMK "cpmk3" Sub-CPMK "sub5" tidak ditemukan dalam values
//    1089: Nilai komponen "proyek" = 105 (diluar range 0-100)
// ============================================================

// Easy to see: 5 failed, exact reason for each
```

**Key Changes**:
- Error aggregation with clear summary
- Error counts and categorization
- Actionable error messages

---

## ✅ Example 5: Validation Configuration

### ❌ OLD CODE (v2) - No Configuration

```dart
final helper = OBECalculationHelper();

// No way to control:
// - What happens when weights don't sum to 100?
// - What happens when values are out of range?
// - How strict should validation be?

// Just gets exceptions at runtime
```

### ✅ NEW CODE (v3) - Configurable Validation

```dart
// Production: Strict validation everywhere
final prodConfig = OBEValidationConfig.production;
final prodHelper = OBECalculationHelper(validationConfig: prodConfig);

// Development: Lenient with warnings
final devConfig = OBEValidationConfig.development;
final devHelper = OBECalculationHelper(validationConfig: devConfig);

// Custom: Mix and match
const customConfig = OBEValidationConfig(
  strictWeightValidation: true,      // Fail if weights ≠ 100
  strictValueValidation: true,       // Fail if grade out of range
  strictBobotValidation: false,      // Warn only if bobot missing
  warnOnFallback: true,              // Print warnings for fallbacks
  weightTolerance: 2.0,              // Allow ±2% weight variance
);

final customHelper = OBECalculationHelper(validationConfig: customConfig);

// Behavior adapts to environment
```

**Key Changes**:
- Validation is configurable
- Different modes for dev/prod
- Clear tolerance settings

---

## ✅ Example 6: Weight Validation

### ❌ OLD CODE (v2) - No Weight Checking

```dart
final subCpmkBobotMap = {
  'sub1': {
    'aktivitas': 16.67,
    'proyek': 16.67,
    'kuis': 16.67,
    'tugas': 16.67,
    'uts': 16.67,
    'uas': 15.50,  // ❌ Total = 99.5, not 100
  }
};

final result = helper.calculateSubCPMKValues(...);
// Result: No warning, silently accepted
// ❌ Weights don't sum properly but calculation proceeds
```

### ✅ NEW CODE (v3) - Weight Validation with Tolerance

```dart
final subCpmkBobotMap = {
  'sub1': {
    'aktivitas': 16.67,
    'proyek': 16.67,
    'kuis': 16.67,
    'tugas': 16.67,
    'uts': 16.67,
    'uas': 15.50,  // Total = 99.5
  }
};

try {
  final result = helper.calculateSubCPMKValues(...);
} catch (e) {
  // If strictWeightValidation=true:
  // ⚠️ Sub-CPMK "sub1": Total bobot = 99.5 (harusnya 100 ± 1)
  // Exception thrown, developer must fix
}

// If strictWeightValidation=false:
// Just prints: ⚠️ Sub-CPMK "sub1": Total bobot = 99.5 ...
// Calculation proceeds with warning
```

**Key Changes**:
- Weight sums are validated
- Configurable tolerance (default ±1%)
- Clear warnings guide RPS update

---

## ✅ Example 7: Database Integration

### ❌ OLD CODE (v2) - Equal Distribution from Code

```dart
// In _getSubCpmkBobotMapFromDatabase():
const equalBobotPerKomponen = 100.0 / 6.0; // Hardcoded here

for (final subCpmkId in subCpmkIds) {
  final bobotMap = <String, double>{};
  for (final komponen in komponenNames) {
    bobotMap[komponen] = _roundToTwoDecimals(equalBobotPerKomponen);
  }
  result[subCpmkId.toString()] = bobotMap;
}

// ❌ Bobot comes from code, not data
// ❌ Not flexible per Sub-CPMK
// ❌ Can't represent varied allocations
```

### ✅ NEW CODE (v3) - Bobot from Database

```dart
// In _getSubCpmkBobotMapFromDatabase():
final subCpmkBobots = 
  await _dbHelper.getSubCPMKComponentBobots(matakuliahId) ?? {};

if (subCpmkBobots.isEmpty) {
  print('⚠️ Bobot not in database, using fallback...');
  
  if (_validationConfig.strictBobotValidation) {
    throw Exception('Bobot must be in database');
  }
  
  // Fallback only if lenient mode
} else {
  for (final subCpmkId in subCpmkIds) {
    final subCpmkIdStr = subCpmkId.toString();
    if (subCpmkBobots.containsKey(subCpmkIdStr)) {
      result[subCpmkIdStr] = subCpmkBobots[subCpmkIdStr]!;
    }
  }
}

// ✅ Bobot from database
// ✅ Flexible per Sub-CPMK and mata kuliah
// ✅ Can represent varied allocations
```

**Database Query**:
```sql
-- Get all bobot for a mata kuliah
SELECT sub_cpmk_id, komponen_type, bobot
FROM sub_cpmk_bobot
WHERE matakuliah_id = ?

-- Example result:
-- sub1: {aktivitas: 10, proyek: 30, kuis: 0, tugas: 20, uts: 20, uas: 20}
-- sub2: {aktivitas: 15, proyek: 15, kuis: 20, tugas: 15, uts: 20, uas: 15}
```

**Key Changes**:
- Bobot now comes from `sub_cpmk_bobot` table
- Flexible per Sub-CPMK configuration
- Clear data source (not hardcoded)

---

## ✅ Example 8: Diagnostic Reports

### ❌ OLD CODE (v2) - Limited Output

```dart
final result = await helper.calculateBatchOBEResultsForMatakuliah(...);
print('Processed ${result.length} mahasiswa');
```

### ✅ NEW CODE (v3) - Detailed Diagnostics

```dart
final results = await helper.calculateBatchOBEResultsForMatakuliah(...);

for (final result in results) {
  if (!result.success) {
    print(result.getDiagnosticReport());
  }
}

// Output:
// ============================================================
// OBE CALCULATION DIAGNOSTIC REPORT
// ============================================================
// Status: ✅ SUCCESS
// Mahasiswa: 1001
// Matakuliah: 1
// Tahun Ajaran: 2024
//
// Sub-CPMK Values: (6 items)
//   sub1: 85.5
//   sub2: 78.25
//   sub3: 82.0
//   sub4: 79.5
//   sub5: 88.0
//   sub6: 81.25
// Average: 82.41
//
// CPMK Values: (3 items)
//   cpmk1: 82.75
//   cpmk2: 80.50
//   cpmk3: 81.25
// Average: 81.5
//
// CPL Values: (2 items)
//   cpl1: 81.75
//   cpl2: 82.0
// Average: 81.88
// ============================================================

// ✅ Full visibility into calculations
```

**Key Changes**:
- `getDiagnosticReport()` method for detailed output
- Shows all intermediate values
- Useful for validation and debugging
- Pretty-printed for easy reading

---

## 🔀 MIGRATION CHECKLIST

### Phase 1: Database Setup
- [ ] Create `sub_cpmk_bobot` table
- [ ] Populate with bobot from RPS
- [ ] Add `bobot` to `cpl_cpmk` if missing
- [ ] Validate weight sums

### Phase 2: Code Updates
- [ ] Update `calculateOBEComplete()` calls
  - [ ] Change CPL map from `List<String>` to `Map<String, double>`
  - [ ] `{'cpl1': ['cpmk1']}` → `{'cpl1': {'cpmk1': 1.0}}`
- [ ] Add `OBEValidationConfig` initialization
  - [ ] Dev: `OBEValidationConfig.development`
  - [ ] Prod: `OBEValidationConfig.production`
- [ ] Update error handling
  - [ ] Try-catch for validation errors
  - [ ] Print diagnostic reports on failure
- [ ] Update batch processing
  - [ ] Check error aggregation
  - [ ] Print summary reports

### Phase 3: Testing
- [ ] Unit tests for each calculation step
- [ ] Integration tests with database
- [ ] Validation error tests (missing values, bad weights)
- [ ] Weight tolerance tests
- [ ] Batch processing tests
- [ ] Compare results against manual calculations

### Phase 4: Deployment
- [ ] Review and test with prod database
- [ ] Train team on error messages
- [ ] Monitor first week for issues
- [ ] Validate against other systems
- [ ] Archive old code as backup

---

## ⚠️ COMMON PITFALLS & SOLUTIONS

### Pitfall 1: Forgetting to Update CPL Map Format

```dart
// ❌ OLD FORMAT - Won't work with v3
cplCpmkMap: {
  'cpl1': ['cpmk1', 'cpmk2'],
}

// ✅ NEW FORMAT
cplCpmkMap: {
  'cpl1': {'cpmk1': 1.0, 'cpmk2': 1.0},  // Equal weight fallback
}
```

### Pitfall 2: Not Loading Bobot from Database

```dart
// ❌ WRONG - Using hardcoded weights
subCpmkBobotMap: {
  'sub1': {'aktivitas': 100/6, 'proyek': 100/6, ...}
}

// ✅ RIGHT - Load from database first
final subCpmkBobotMap = 
  await _getSubCpmkBobotMapFromDatabase(matakuliahId);
```

### Pitfall 3: Ignoring Validation Errors

```dart
// ❌ WRONG - Missing try-catch
final result = helper.calculateSubCPMKValues(...);

// ✅ RIGHT - Handle validation errors
try {
  final result = helper.calculateSubCPMKValues(...);
} catch (e) {
  // Fix missing data, review RPS, etc.
  handleCalculationError(e);
}
```

### Pitfall 4: Using Lenient Config in Production

```dart
// ❌ WRONG
const config = OBEValidationConfig.development;
final helper = OBECalculationHelper(validationConfig: config);

// ✅ RIGHT
const config = OBEValidationConfig.production;
final helper = OBECalculationHelper(validationConfig: config);
```

---

## 📞 SUPPORT

For issues during migration:

1. **Check Database Schema** - Ensure `sub_cpmk_bobot` table exists
2. **Check Weight Sums** - Run validation queries
3. **Check for NULL Grades** - Clean up missing data first
4. **Review Error Messages** - They're very specific now
5. **Check OBEValidationConfig** - Ensure correct mode for environment
6. **Run Diagnostic Reports** - Use `getDiagnosticReport()` for detailed output

---

