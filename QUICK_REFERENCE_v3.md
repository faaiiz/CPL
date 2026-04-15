# 📚 QUICK REFERENCE - OBE CALCULATION ENGINE v3

## 🎯 30-Second Summary

| Aspect | Old (v2) | New (v3) |
|--------|----------|---------|
| **Weight Source** | Hardcoded (16.67 for all) | Database-driven |
| **Missing Values** | Silently default to 0 | ❌ Throw error |
| **Weight Validation** | None | ✅ Configurable with tolerance |
| **CPL Calculation** | Simple average | ✅ Weighted aggregation |
| **Error Handling** | Limited info | ✅ Aggregated with context |
| **Configuration** | None | ✅ OBEValidationConfig |
| **Validation Strictness** | Fixed | ✅ dev/prod/custom |

---

## 🚀 Quick Start (5 minutes)

### 1. Initialize Helper

```dart
// Production setup (strict validation)
final config = OBEValidationConfig.production;
final helper = OBECalculationHelper(validationConfig: config);

// Or development (lenient)
final helper = OBECalculationHelper(
  validationConfig: OBEValidationConfig.development
);
```

### 2. Prepare Data (MUST be from database, NOT hardcoded)

```dart
// Load from database - REQUIRED
final subCpmkBobotMap = 
  await _getSubCpmkBobotMapFromDatabase(matakuliahId);
final cpmkSubCpmkMap = 
  await _getCpmkSubCpmkMapFromDatabase(matakuliahId);
final cplCpmkMap = 
  await _getCPLCpmkMapFromDatabase(matakuliahId);

// Student grades - MUST NOT BE NULL
final nilaiKomponen = {
  'aktivitas': 80.0,  // Required
  'proyek': 85.0,     // Required
  'kuis': 90.0,       // Required
  'tugas': 75.0,      // Required
  'uts': 88.0,        // Required
  'uas': 92.0,        // Required
};
```

### 3. Calculate

```dart
try {
  final result = helper.calculateOBEComplete(
    nilaiKomponen: nilaiKomponen,
    subCpmkBobotMap: subCpmkBobotMap,
    cpmkSubCpmkMap: cpmkSubCpmkMap,
    cplCpmkMap: cplCpmkMap,
  );
  
  if (result['status'] == 'success') {
    print('Sub-CPMK: ${result['sub_cpmk']}');
    print('CPMK: ${result['cpmk']}');
    print('CPL: ${result['cpl']}');
  }
} catch (e) {
  print('Calculation failed: $e');
}
```

---

## 🔑 Key Methods

### Core Calculation

```dart
// Calculate Sub-CPMK from component grades
Map<String, double> calculateSubCPMKValues({
  required Map<String, double> nilaiKomponen,
  required Map<String, Map<String, double>> subCpmkBobotMap,
})

// Calculate CPMK from Sub-CPMK
Map<String, double> calculateCPMKValues({
  required Map<String, double> subCpmkValues,
  required Map<String, Map<String, double>> cpmkSubCpmkMap,
})

// Calculate CPL from CPMK (weighted aggregation)
Map<String, double> calculateCPLValues({
  required Map<String, double> cpmkValues,
  required Map<String, Map<String, double>> cplCpmkMap,
})

// All in one
Map<String, dynamic> calculateOBEComplete({...})
```

### Batch Processing

```dart
// Process all students for a mata kuliah
Future<List<OBECalculationResult>> calculateBatchOBEResultsForMatakuliah({
  required int matakuliahId,
  required int tahunAjaran,
  bool continueOnError = true,
})
```

### Diagnostics

```dart
// Pretty print result
String result.toString()

// Detailed diagnostic report
String result.getDiagnosticReport()

// Component properties
double result.averageSubCPMK
double result.averageCPMK
double result.averageCPL
```

---

## ⚙️ Configuration Options

```dart
// Production (strict everything)
OBEValidationConfig.production

// Development (lenient with warnings)
OBEValidationConfig.development

// Custom
const OBEValidationConfig(
  strictWeightValidation: false,      // ±1% tolerance
  strictValueValidation: true,        // Grade range check
  strictBobotValidation: true,        // Must be in database
  warnOnFallback: true,               // Print warnings
  weightTolerance: 1.0,               // ±1%
)
```

---

## 📊 Data Structures

### Input: nilaiKomponen
```dart
Map<String, double> {
  'aktivitas': 0-100,
  'proyek': 0-100,
  'kuis': 0-100,
  'tugas': 0-100,
  'uts': 0-100,
  'uas': 0-100,
}
```

### Input: subCpmkBobotMap
```dart
Map<String, Map<String, double>> {
  'sub1': {
    'aktivitas': 10.0,
    'proyek': 20.0,
    // ... etc
  }
}
```

### Input: cpmkSubCpmkMap
```dart
Map<String, Map<String, double>> {
  'cpmk1': {
    'sub1': 20.0,
    'sub2': 15.0,
    // ... etc
  }
}
```

### Input: cplCpmkMap (NEW - with weights)
```dart
Map<String, Map<String, double>> {
  'cpl1': {
    'cpmk1': 30.0,    // Weight of cpmk1 in cpl1
    'cpmk2': 35.0,
    'cpmk3': 35.0,
  }
}
```

### Output
```dart
{
  'status': 'success' or 'error',
  'message': 'error message if failed',
  'sub_cpmk': {'sub1': 85.5, ...},
  'cpmk': {'cpmk1': 82.75, ...},
  'cpl': {'cpl1': 81.25, ...}
}
```

---

## 🐛 Error Messages - Quick Guide

| Error | Cause | Fix |
|-------|-------|-----|
| `Total bobot = 0` | No component has weight > 0 | Check RPS Sub-CPMK setup |
| `nilai_komponen not found` | Grade field missing | Fill missing grades in database |
| `Total bobot = 95.5` | Weights don't sum to 100 | Review RPS weights (allow ±1% tolerance) |
| `Bobot not in database` | Missing `sub_cpmk_bobot` table | Create table and populate weights |
| `Grade = 105` | Grade out of range [0,100] | Fix invalid grade entry |
| `Sub-CPMK "sub1" not found` | ID mismatch in mapping | Check database consistency |

---

## 📦 Data Preparation Checklist

Before calling `calculateOBEComplete()`:

- [ ] All student grades populated (no NULL)
- [ ] All grades in range [0, 100]
- [ ] Bobot loaded from database (`sub_cpmk_bobot` table)
- [ ] Sub-CPMK←Component mapping consistent
- [ ] CPMK←SubCPMK mapping consistent (ideally sums to ~100)
- [ ] CPL←CPMK mapping exists with weights (if using CPL)
- [ ] All IDs are strings in format 'sub1', 'cpmk1', 'cpl1'
- [ ] No hardcoded weights (use database)

---

## 🔄 Migration Path

### If you're still on v2:

1. **Create `sub_cpmk_bobot` table** (see DATABASE_SCHEMA_CHANGES.md)
2. **Update code** (see CODE_MIGRATION_GUIDE_v3.md)
3. **Change CPL format** from `List<String>` to `Map<String, double>`
4. **Add error handling** with try-catch
5. **Test** with sample data

### Backward Compatibility:

```dart
// Old API - deprecated but still works
final result = helper.calculateOBECompleteWithListCPL(
  cplCpmkMapList: {'cpl1': ['cpmk1', 'cpmk2']}
);
```

---

## 💾 Database Queries

### Verify Weight Sums
```sql
SELECT matakuliah_id, sub_cpmk_id, SUM(bobot) as total
FROM sub_cpmk_bobot
GROUP BY matakuliah_id, sub_cpmk_id
HAVING SUM(bobot) != 100;  -- Find unbalanced weights
```

### Find Missing Grades
```sql
SELECT mahasiswa_id FROM nilai_komponen
WHERE nilai_aktivitas IS NULL OR nilai_proyek IS NULL
  OR nilai_kuis IS NULL OR nilai_tugas IS NULL
  OR nilai_uts IS NULL OR nilai_uas IS NULL;
```

### Check Mappings
```sql
SELECT COUNT(*) FROM sub_cpmk_bobot WHERE matakuliah_id = ?;
SELECT COUNT(*) FROM cpmk_sub_cpmk WHERE cpmk_id IN (...);
SELECT COUNT(*) FROM cpl_cpmk WHERE cpl_id IN (...);
```

---

## 🧪 Unit Test Template

```dart
import 'package:test/test.dart';
import 'your_package/obe_calculation_helper.dart';

void main() {
  late OBECalculationHelper helper;
  
  setUp(() {
    helper = OBECalculationHelper(
      validationConfig: OBEValidationConfig.development
    );
  });

  test('Sub-CPMK calculation with normalized weights', () {
    final result = helper.calculateSubCPMKValues(
      nilaiKomponen: {
        'aktivitas': 80,
        'proyek': 90,
        'kuis': 85,
        'tugas': 75,
        'uts': 88,
        'uas': 92,
      },
      subCpmkBobotMap: {
        'sub1': {
          'aktivitas': 20,
          'proyek': 30,
          'kuis': 20,
          'tugas': 10,
          'uts': 10,
          'uas': 10,  // Total: 100 ✓
        }
      },
    );
    
    expect(result, isNotEmpty);
    expect(result['sub1'], greaterThan(80));
    expect(result['sub1'], lessThan(92));
  });

  test('Throws error on missing component value', () {
    expect(
      () => helper.calculateSubCPMKValues(
        nilaiKomponen: { 'aktivitas': 80 },  // Missing others
        subCpmkBobotMap: { 'sub1': { 'aktivitas': 50, 'proyek': 50 } },
      ),
      throwsException,
    );
  });

  test('CPL weighted aggregation', () {
    final result = helper.calculateCPLValues(
      cpmkValues: { 'cpmk1': 80, 'cpmk2': 90 },
      cplCpmkMap: {
        'cpl1': { 'cpmk1': 100, 'cpmk2': 0 }  // All weight to cpmk1
      },
    );
    
    expect(result['cpl1'], closeTo(80.0, 0.1));  // Should be ~80
  });
}
```

---

## 📈 Performance Notes

- Batch processing: ~50-100ms per student (depends on database)
- Single calculation: <5ms (pure computation)
- Database queries dominate time (use indexes on foreign keys)
- Parallel processing: Can process multiple students in parallel if using connection pool

---

## 🔐 Security Considerations

- Input validation: All values checked for range [0, 100]
- SQL injection: Use parameterized queries for database access
- User permissions: Ensure students can only see their own data
- Audit logging: Consider logging all calculations for compliance

---

## 🎓 OBE Best Practices

1. **Regular RPS Update**: Review weights every semester
2. **Data Quality**: Ensure all grades entered before calculation
3. **Validation**: Run weight sum checks before batch processing
4. **Documentation**: Keep record of weight changes for accreditation
5. **Testing**: Compare against manual spreadsheet calculations
6. **Monitoring**: Track calculation failures and patterns

---

## 📞 Support Matrix

| Issue | Check | Reference |
|-------|-------|-----------|
| Hardcoded weights | Update to database-driven | OBE_REFACTORING_SUMMARY_v3.md |
| Missing values | Add NOT NULL check | CODE_MIGRATION_GUIDE_v3.md |
| Weight validation | Review tolerance settings | OBE_REFACTORING_SUMMARY_v3.md |
| CPL calculation | Update map format | CODE_MIGRATION_GUIDE_v3.md |
| Database schema | Create required tables | DATABASE_SCHEMA_CHANGES.md |
| Error handling | Add try-catch blocks | CODE_MIGRATION_GUIDE_v3.md |

---

## 🎯 Success Metrics

✅ Implementation is successful when:

- [ ] All unit tests pass
- [ ] Weight sums validated in database
- [ ] Calculations match manual verification
- [ ] Error messages are clear and actionable
- [ ] Batch processing completes without errors
- [ ] No hardcoded weights in codebase
- [ ] Diagnostic reports show detailed output
- [ ] Team is comfortable with new validation rules

---

**Version**: 3.0  
**Status**: ✅ Production Ready  
**Last Updated**: April 14, 2026

