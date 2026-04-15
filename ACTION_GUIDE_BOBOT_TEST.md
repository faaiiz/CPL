# ⚡ ACTION GUIDE: Test Fisika Matematika I Bobot Fix

## ✅ Implementation Complete
All code is ready. You just need to provide the bobot data and test!

## 📊 What You Need to Provide

**For each Sub-CPMK in Fisika Matematika I**, provide 6 numbers in this order:
```
[Aktivitas, Proyek, Kuis, Tugas, UTS, UAS]
```

**You provided SUB-CPMK 1**:
```
[4, 8, 0, 2, 10, 0]
```

**Still need SUB-CPMK 2, 3, 4**:
```
SUB-CPMK 2: [?, ?, ?, ?, ?, ?]
SUB-CPMK 3: [?, ?, ?, ?, ?, ?]
SUB-CPMK 4: [?, ?, ?, ?, ?, ?]
```

## 🚀 Quick Test (5 minutes)

### 1. Get Database IDs
Open your app and run in terminal/debug console:
```dart
// Get Matakuliah ID
final mk = await dbHelper.getMatakuliahByNama('Fisika Matematika I');
print('Matakuliah ID: ${mk!.id}');  // Note this, e.g., 5

// Get Sub-CPMK IDs
final subCpmks = await dbHelper.getSubCPMKByMatakuliah(mk.id);
for (final sub in subCpmks) {
  print('${sub.kodeSubCpmk}: ID=${sub.id}');
}
// Expected output:
// SUB-1: ID=12
// SUB-2: ID=13
// SUB-3: ID=14
// SUB-4: ID=15
```

### 2. Save Bobot
```dart
final mkId = 5;  // From step 1
await dbHelper.saveSubCPMKKomponenBobotBatch(
  matakuliahId: mkId,
  bobotData: {
    12: [4, 8, 0, 2, 10, 0],        // SUB-1 (provided)
    13: [?, ?, ?, ?, ?, ?],         // SUB-2 (you provide)
    14: [?, ?, ?, ?, ?, ?],         // SUB-3 (you provide)
    15: [?, ?, ?, ?, ?, ?],         // SUB-4 (you provide)
  },
);
// Check console for: ✅ Saved bobot komponen for Sub-CPMK=...
```

### 3. Enter Student Data
```dart
// Insert Vita Juwita's nilai komponen
await dbHelper.insertNilaiKomponen(
  mahasiswaId: vitaId,              // Your Vita's ID
  matakuliahId: 5,                  // Fisika Matematika I
  nilaiAktivitas: 87.5,
  nilaiProyek: 87.5,
  nilaiKuis: 87.5,
  nilaiTugas: 87.5,
  nilaiUTS: 60,
  nilaiUAS: 90,
  tahunAjaran: 2024,
);
```

### 4. Calculate & Check Result
```dart
final result = await calculationHelper.calculateSubCPMKValuesOptimized(
  mahasiswaId: vitaId,
  matakuliahId: 5,
  tahunAjaran: 2024,
);

// Check console for: ✅ [getBobotMatrixForMatakuliah] Loaded bobot from sub_cpmk_komponen_bobot table
print('SUB-CPMK 1 Nilai: ${result[12]}');
// Should show: 76.04 (NOT 83.33) ✅
```

## 🎯 Expected Results

### Before Fix
```
SUB-CPMK 1 Nilai: 83.33  ❌ (simple average)
Database log: Using equal distribution [2.5, 2.5, 2.5, 2.5, 2.5, 2.5]
```

### After Fix
```
SUB-CPMK 1 Nilai: 76.04  ✅ (weighted average)
Database log: ✅ Loaded bobot from sub_cpmk_komponen_bobot table
```

## 📋 Files Created/Modified

| File | Status | Purpose |
|------|--------|---------|
| `lib/services/database_helper.dart` | ✅ Modified | 6 new methods + table |
| `lib/services/obe_calculation_helper.dart` | ✅ No changes | Already calls getBobotMatrixForMatakuliah() |
| `QUICK_TEST_FISIKA_MATEMATIKA_I_BOBOT.md` | ✅ Created | Detailed test guide |
| `FIX_FISIKA_MATEMATIKA_I_BOBOT_KOMPONEN.md` | ✅ Created | Implementation docs |

## 🔧 New Methods Available

```dart
// Save single Sub-CPMK bobot
await dbHelper.saveSubCPMKKomponenBobot(
  matakuliahId: 5,
  subCpmkId: 12,
  komponenBobots: [4, 8, 0, 2, 10, 0],
);

// Load ALL bobot for a matakuliah
final bobot = await dbHelper.getSubCPMKKomponenBobot(5);
// Returns: {12: [4,8,0,2,10,0], 13: [...], ...}

// Load single Sub-CPMK bobot
final single = await dbHelper.getSubCPMKKomponenBobotSingle(
  matakuliahId: 5,
  subCpmkId: 12,
);
// Returns: [4, 8, 0, 2, 10, 0]

// Delete by Sub-CPMK
await dbHelper.deleteSubCPMKKomponenBobot(
  matakuliahId: 5,
  subCpmkId: 12,
);

// Delete all for matakuliah
await dbHelper.deleteSubCPMKKomponenBobotByMatakuliah(5);
```

## ❌ Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Still 83.33 | Bobot not saved | Run `saveSubCPMKKomponenBobot()` again |
| Bobot map empty | Wrong matakuliah_id | Check `getMatakuliahByNama('Fisika Matematika I')` returns correct ID |
| SQL error | Database not v9 | Delete app data + reinstall |
| No console logs | Logs not printing | Check debug output in VS Code console |

## 💾 Optional: Manual SQL Test

If you want to verify bobot is saved without running app:
```sql
-- Check if data saved
SELECT * FROM sub_cpmk_komponen_bobot WHERE matakuliah_id = 5;

-- Expected output:
-- id | matakuliah_id | sub_cpmk_id | komponen_idx | bobot
-- 1  | 5             | 12          | 0           | 4
-- 2  | 5             | 12          | 1           | 8
-- 3  | 5             | 12          | 2           | 0
-- 4  | 5             | 12          | 3           | 2
-- 5  | 5             | 12          | 4           | 10
-- 6  | 5             | 12          | 5           | 0
```

## ✨ Summary

**Implementation**: ✅ COMPLETE  
**Code Quality**: ✅ NO ERRORS  
**Integration**: ✅ AUTOMATIC (already called by calculation logic)  
**Status**: 🚀 **READY TO TEST**

**Next**: Provide Sub-CPMK 2, 3, 4 bobot and run test! 🎯
