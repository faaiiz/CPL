# 🧪 Quick Test: Fisika Matematika I Bobot Implementation

## Overview
Test the new bobot komponen feature with the exact Fisika Matematika I example from user requirement.

## User's Example
**Mata Kuliah**: Fisika Matematika I (4 Sub-CPMK total)

**SUB-CPMK 1 Bobot Configuration**:
- Aktivitas: 4
- Proyek: 8
- Kuis: 0
- Tugas: 2
- UTS: 10
- UAS: 0
- **Total**: 24

**Student**: Vita Juwita (has nilai_komponen)
**Nilai Komponen**: [87.5, 87.5, 87.5, 87.5, 60, 90] (aktivitas, proyek, kuis, tugas, uts, uas)

### Expected Calculation
```
Nilai SUB-CPMK 1 = (4/24 × 87.5) + (8/24 × 87.5) + (2/24 × 87.5) + (10/24 × 60)
                 = 14.583 + 29.167 + 7.292 + 25
                 = 76.042 ≈ 76.04  ✅ NOT 83.33!
```

## Implementation Steps

### Step 1: Get Matakuliah ID for Fisika Matematika I
```dart
final mk = await dbHelper.getMatakuliahByNama('Fisika Matematika I');
final matakuliahId = mk!.id;  // e.g., 5
```

### Step 2: Get Sub-CPMK IDs
```dart
final subCpmks = await dbHelper.getSubCPMKByMatakuliah(matakuliahId);
final subCpmk1 = subCpmks.firstWhere((s) => s.kodeSubCpmk.contains('1'));
final subCpmk1Id = subCpmk1.id;  // e.g., 12
```

### Step 3: Save Bobot Configuration (ONE TIME)
```dart
// Save bobot for SUB-CPMK 1
await dbHelper.saveSubCPMKKomponenBobot(
  matakuliahId: matakuliahId,  // 5
  subCpmkId: subCpmk1Id,       // 12
  komponenBobots: [4, 8, 0, 2, 10, 0],  // aktivitas, proyek, kuis, tugas, uts, uas
);

// Save bobot untuk Sub-CPMK 2, 3, 4 (dari user specification)
await dbHelper.saveSubCPMKKomponenBobotBatch(
  matakuliahId: matakuliahId,
  bobotData: {
    subCpmk1Id: [4, 8, 0, 2, 10, 0],
    subCpmk2Id: [5, 5, 0, 2, 8, 0],  // Different bobot for SUB-CPMK 2
    subCpmk3Id: [3, 3, 4, 4, 8, 0],  // Different bobot for SUB-CPMK 3
    subCpmk4Id: [2, 2, 2, 2, 7, 5],  // Different bobot for SUB-CPMK 4
  },
);
```

### Step 4: Verify Bobot Saved
```dart
// Load to verify
final savedBobot = await dbHelper.getSubCPMKKomponenBobot(matakuliahId);
print('Saved bobot: $savedBobot');
// Expected: {12: [4, 8, 0, 2, 10, 0], 13: [5, 5, 0, 2, 8, 0], ...}
```

### Step 5: Insert Nilai Komponen for Vita Juwita
```dart
final mahasiswa = await dbHelper.getMahasiswaByNim('Vita Juwita');
const tahunAjaran = 2024;

await dbHelper.insertNilaiKomponen(
  mahasiswaId: mahasiswa!.id,
  matakuliahId: matakuliahId,
  nilaiAktivitas: 87.5,
  nilaiProyek: 87.5,
  nilaiKuis: 87.5,
  nilaiTugas: 87.5,
  nilaiUTS: 60,
  nilaiUAS: 90,
  tahunAjaran: tahunAjaran,
);
```

### Step 6: Calculate Sub-CPMK Values
```dart
// This will use the new bobot table via getBobotMatrixForMatakuliah()
final result = await calculationHelper.calculateSubCPMKValuesOptimized(
  mahasiswaId: mahasiswa!.id,
  matakuliahId: matakuliahId,
  tahunAjaran: tahunAjaran,
);

// Expected Sub-CPMK 1 nilai: 76.04 (NOT 83.33)
print('Sub-CPMK 1 Nilai: ${result.subCPMKValues[subCpmk1Id]}');  // Should be ~76.04

// Verify via database
final savedResult = await dbHelper.getCPLCalculationResult(
  mahasiswa!.id,
  matakuliahId,
  tahunAjaran,
);
print('Saved DB: ${savedResult}');
```

## Verification Checklist

- [ ] Database migrated to v9 successfully
- [ ] `sub_cpmk_komponen_bobot` table created with data
- [ ] `saveSubCPMKKomponenBobot()` method works
- [ ] `getSubCPMKKomponenBobot()` returns correct bobot map
- [ ] `getBobotMatrixForMatakuliah()` prioritizes new table (PRIORITY 1)
- [ ] `calculateSubCPMKValuesOptimized()` produces 76.04 (not 83.33)
- [ ] CPL Results saved to database with correct nilai

## Test Data to Insert (Optional)
If starting fresh, use this SQL:

```sql
-- Matakuliah
INSERT INTO matakuliah (kode, nama, semester, jenis, sks) 
VALUES ('FI4001', 'Fisika Matematika I', '4', 'wajib', 3);

-- Sub-CPMK (4 total for Fisika Matematika I)
INSERT INTO sub_cpmk (matakuliah_id, kode_sub_cpmk, deskripsi)
VALUES (5, 'SUB-1', 'Persamaan Diferensial Order 1-2');
... (3 more)

-- Mahasiswa
INSERT INTO mahasiswa (nim, nama) VALUES ('XXX', 'Vita Juwita');

-- Nilai Komponen
INSERT INTO nilai_komponen (...) VALUES (...);

-- Bobot Komponen (NEW)
INSERT INTO sub_cpmk_komponen_bobot (matakuliah_id, sub_cpmk_id, komponen_idx, bobot)
VALUES 
  (5, 12, 0, 4),    -- Sub-CPMK 1, Aktivitas=4
  (5, 12, 1, 8),    -- Sub-CPMK 1, Proyek=8
  (5, 12, 2, 0),    -- Sub-CPMK 1, Kuis=0
  (5, 12, 3, 2),    -- Sub-CPMK 1, Tugas=2
  (5, 12, 4, 10),   -- Sub-CPMK 1, UTS=10
  (5, 12, 5, 0);    -- Sub-CPMK 1, UAS=0
```

## Key Files Modified

1. **lib/services/database_helper.dart**
   - ✅ Added `tableSubCPMKKomponenBobot` constant (line ~41)
   - ✅ Created new table in `_createTables()` (line ~435)
   - ✅ Added v9 migration in `_onUpgrade()` (line ~855)
   - ✅ Updated `getBobotMatrixForMatakuliah()` to prioritize new table (PRIORITY 1)
   - ✅ Added `saveSubCPMKKomponenBobot()` method
   - ✅ Added `getSubCPMKKomponenBobot()` method
   - ✅ Added `saveSubCPMKKomponenBobotBatch()` method
   - ✅ Added `getSubCPMKKomponenBobotSingle()` method
   - ✅ Added `deleteSubCPMKKomponenBobot()` method
   - ✅ Added `deleteSubCPMKKomponenBobotByMatakuliah()` method

2. **lib/services/obe_calculation_helper.dart**
   - ✅ Already calls `getBobotMatrixForMatakuliah()` (which now prioritizes new table)
   - ✅ No changes needed - integration automatic!

## Expected Console Output

When running the test, you should see:

```
✅ [getBobotMatrixForMatakuliah] Loaded bobot from sub_cpmk_komponen_bobot table for MK=5
✅ [calculateSubCPMKValuesOptimized] SUB-CPMK 1 nilai: 76.043 (using weighted average)
✅ Saved bobot komponen for Sub-CPMK=12, MK=5
✅ Loaded bobot komponen for MK=5 (4 Sub-CPMK)
✅ CPL results saved for 1 mahasiswa
```

## Troubleshooting

**Issue**: Database still v8, not v9
- Solution: Delete app data and reinstall (migration triggers on next open)

**Issue**: `getSubCPMKKomponenBobot()` returns empty map
- Solution: Check that `saveSubCPMKKomponenBobot()` executed successfully (look for ✅ log)

**Issue**: Still 83.33 instead of 76.04
- Solution: 
  - Check if bobot table has data
  - Verify nilai_komponen table populated correctly
  - Check diagnostic logs in 'calculateSubCPMKValuesOptimized'

## Next Steps

1. Run this test with actual data
2. Verify 76.04 is calculated instead of 83.33
3. Handle remaining 3 Sub-CPMK configurations from user
4. (Optional) Create UI screen for inputting bobot matrix per Sub-CPMK
