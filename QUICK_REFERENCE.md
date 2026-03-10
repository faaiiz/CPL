# 🎯 Academic Calculation System - Quick Reference

## Database Tables Summary

| Table | Purpose | Key Fields | Unique Constraint |
|-------|---------|-----------|-------------------|
| `sub_cpmk_nilai` | Track Sub-CPMK scores | mahasiswa_id, sub_cpmk_id, nilai, tahun_ajaran | (mahasiswa_id, sub_cpmk_id, tahun_ajaran) |
| `rps_detail_sub_cpmk_bobot` | RPS week bobot distribution | rps_detail_id, sub_cpmk_id, bobot | (rps_detail_id, sub_cpmk_id) |
| `sub_cpmk_cpmk_mapping` | Sub-CPMK → CPMK contribution | sub_cpmk_id, cpmk_id, bobot | (sub_cpmk_id, cpmk_id) |

---

## Calculation Methods

```dart
// 1. Get Sub-CPMK value
double? nilaiSubCpmk = await service.calculateSubCPMKValue(
  mahasiswaId: 1, subCpmkId: 5, tahunAjaran: 2024
);

// 2. Calculate CPMK (weighted by mapping bobot)
double? nilaiCPMK = await service.calculateCPMKValue(
  mahasiswaId: 1, cpmkId: 1, tahunAjaran: 2024
);

// 3. Calculate Course value (weighted by RPS bobot)
double? nilaiMK = await service.calculateMatakuliahValue(
  mahasiswaId: 1, matakuliahId: 10, tahunAjaran: 2024
);

// 4. Calculate CPL (weighted by SKS)
double? nilaiCPL = await service.calculateCPLValue(
  mahasiswaId: 1, cplId: 1, tahunAjaran: 2024
);

// 5. Get full student report
Map<String, dynamic> report = await service.generateStudentReport(
  mahasiswaId: 1, tahunAjaran: 2024
);

// 6. Check data completeness before calculating
Map<String, dynamic> check = await service.checkDataCompleteness(
  mahasiswaId: 1, tahunAjaran: 2024
);
```

---

## CRUD Operations

### Insert Operations
```dart
// Create Sub-CPMK Nilai
SubCPMKNilai nilai = SubCPMKNilai(
  mahasiswaId: 1, subCpmkId: 5, nilai: 85.0, tahunAjaran: 2024,
  createdAt: DateTime.now(),
);
await dbHelper.insertSubCPMKNilai(nilai);

// Create RPS Detail Sub-CPMK Bobot
RPSDetailSubCPMKBobot bobot = RPSDetailSubCPMKBobot(
  rpsDetailId: 1, subCpmkId: 5, bobot: 40.0,
  createdAt: DateTime.now(),
);
await dbHelper.insertRPSDetailSubCPMKBobot(bobot);

// Create Sub-CPMK CPMK Mapping
SubCPMKCPMKMapping mapping = SubCPMKCPMKMapping(
  subCpmkId: 5, cpmkId: 1, bobot: 50.0,
  createdAt: DateTime.now(),
);
await dbHelper.insertSubCPMKCPMKMapping(mapping);
```

### Query Operations
```dart
// Get single nilai
SubCPMKNilai? nilai = await dbHelper.getSubCPMKNilai(1, 5, 2024);

// Get all nilai for mahasiswa
List<SubCPMKNilai> nilaiList = await dbHelper.getSubCPMKNilaiByMahasiswa(1, 2024);

// Get bobot for minggu
List<RPSDetailSubCPMKBobot> bobotList = await dbHelper.getRPSDetailSubCPMKBobot(1);

// Get mapping for Sub-CPMK
List<SubCPMKCPMKMapping> mappings = await dbHelper.getSubCPMKCPMKMapping(5);

// Get mapping for CPMK
List<SubCPMKCPMKMapping> subCpmks = await dbHelper.getCPMKSubCPMKMapping(1);
```

### Update Operations
```dart
nilai.nilai = 90.0;
await dbHelper.updateSubCPMKNilai(nilai);

bobot.bobot = 45.0;
await dbHelper.updateRPSDetailSubCPMKBobot(bobot);

mapping.bobot = 60.0;
await dbHelper.updateSubCPMKCPMKMapping(mapping);
```

### Delete Operations
```dart
await dbHelper.deleteSubCPMKNilai(nilaiId);
await dbHelper.deleteRPSDetailSubCPMKBobot(bobotId);
await dbHelper.deleteSubCPMKCPMKMapping(mappingId);

// Delete all bobot for a minggu
await dbHelper.deleteRPSDetailSubCPMKBobotByRPSDetail(rpsDetailId);

// Delete all nilai for mahasiswa
await dbHelper.deleteSubCPMKNilaiByMahasiswa(mahasiswaId);
```

---

## Formulas (Locked - Do NOT Change)

### Sub-CPMK Value
```
Nilai = value from sub_cpmk_nilai table
```

### CPMK Value
```
= Σ(Nilai_SubCPMK × bobot_mapping) / Σ bobot_mapping
```

### Course Value
```
= Σ(Nilai_SubCPMK × bobot_rps_minggu) / 100
```

### CPL Value
```
= Σ(Nilai_CPMK × SKS) / Σ SKS
```

---

## Data Flow

```
1. Input Sub-CPMK Nilai
   └─→ sub_cpmk_nilai table

2. Setup RPS Bobot (per minggu)
   └─→ rps_detail_sub_cpmk_bobot table

3. Setup CPMK Mapping
   └─→ sub_cpmk_cpmk_mapping table

4. Calculate CPMK
   └─→ uses sub_cpmk_nilai + sub_cpmk_cpmk_mapping

5. Calculate Course Value
   └─→ uses sub_cpmk_nilai + rps_detail_sub_cpmk_bobot

6. Calculate CPL
   └─→ uses CPMK values + SKS from matakuliah
```

---

## Key Constraints

| Constraint | Value | Notes |
|-----------|-------|-------|
| Total RPS Bobot (16 weeks) | 100% | All weeks combined |
| Sub-CPMK Bobot per week | 100% | All Sub-CPMK in week |
| Report Completeness | Required | Check before calculating |
| Return type on null data | `null` | Service returns null if data missing |

---

## Files

| File | Purpose |
|------|---------|
| `lib/services/database_helper.dart` | Database operations |
| `lib/services/academic_calculation_service.dart` | Calculation logic |
| `lib/models/sub_cpmk_nilai_model.dart` | Model for Sub-CPMK values |
| `lib/models/rps_detail_sub_cpmk_bobot_model.dart` | Model for RPS bobot |
| `lib/models/sub_cpmk_cpmk_mapping_model.dart` | Model for CPMK mapping |

---

## Import Statements

```dart
import 'package:cpl/services/database_helper.dart';
import 'package:cpl/services/academic_calculation_service.dart';
import 'package:cpl/models/sub_cpmk_nilai_model.dart';
import 'package:cpl/models/rps_detail_sub_cpmk_bobot_model.dart';
import 'package:cpl/models/sub_cpmk_cpmk_mapping_model.dart';
```

---

## Common Use Cases

### ✅ Check if mahasiswa can be graded
```dart
final check = await service.checkDataCompleteness(mahasiswaId, tahunAjaran);
if (check['complete']) {
  // Ready to calculate
} else {
  print('Missing: $check');
}
```

### ✅ Get student grades at all levels
```dart
final report = await service.generateStudentReport(mahasiswaId, tahunAjaran);
// report['subCPMK'] - detailed Sub-CPMK values
// report['cpmk'] - calculated CPMK values
// report['cpl'] - calculated CPL values
// report['summary'] - averages
```

### ✅ Update a single Sub-CPMK grade
```dart
var nilai = await dbHelper.getSubCPMKNilai(mahasiswaId, subCpmkId, tahunAjaran);
nilai.nilai = 92.0;
await dbHelper.updateSubCPMKNilai(nilai);
```

### ✅ Setup bobot for new RPS mingguan
```dart
// For each Sub-CPMK in minggu:
final subCpmks = [5, 6]; // Sub-CPMK IDs
final bobot = [40, 60]; // % each

for (int i = 0; i < subCpmks.length; i++) {
  await dbHelper.insertRPSDetailSubCPMKBobot(
    RPSDetailSubCPMKBobot(
      rpsDetailId: rpsDetailId,
      subCpmkId: subCpmks[i],
      bobot: bobot[i],
      createdAt: DateTime.now(),
    ),
  );
}
```

---

## Status

✅ **All components implemented and tested**
- Database tables created with migrations
- Model classes with serialization
- CRUD operations fully functional
- Calculation service ready for use
- No compilation errors

⏳ **Next steps**
- [ ] Create RPS input UI for bobot management
- [ ] Create Sub-CPMK CPMK mapping UI
- [ ] Create Sub-CPMK nilai input screen
- [ ] Create results view screen
- [ ] Integration testing with real data
