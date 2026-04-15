# ✅ UPDATE: Bobot Sub-CPMK Diambil dari RPS (Kolom Total)

## 🎯 Perubahan Penting

Sebelumnya, sistem **MENGHITUNG** bobot Sub-CPMK dari sum bobot komponen:
```
totalBobot = 4 + 8 + 0 + 2 + 10 + 0 = 24  ← Kalkulasi
```

Sekarang, sistem **LOAD** bobot Sub-CPMK dari RPS (seperti yang user input):
```
totalBobot = 24  ← Dari RPS kolom Total (bukan dikalkkulasi)
```

---

## 📊 Data Source

**Dari attachment yang Anda berikan:**

| Sub CPMK | Aktivitas | Proyek | Kuis | Tugas | UTS | UAS | **Total** |
|----------|-----------|--------|------|-------|-----|-----|-----------|
| SUB-CPMK.1 | 4.0 | 8.0 | - | 2.0 | 10.0 | - | **24.0** |
| SUB-CPMK.2 | 2.0 | 8.0 | - | 2.0 | 15.0 | - | **27.0** |
| SUB-CPMK.3 | 2.0 | 6.0 | - | 2.0 | - | 5.0 | **15.0** |
| SUB-CPMK.4 | 2.0 | 8.0 | 2.0 | 2.0 | - | 20.0 | **34.0** |

- **Detail kolom** (Aktivitas, Proyek, Kuis, Tugas, UTS, UAS) = **Bobot Komponen**
- **Total kolom** (24, 27, 15, 34) = **Bobot RPS Sub-CPMK** ← Used untuk CPMK calculation

---

## 🔄 Updated Flow

```
1. RPS Input (User):
   - SUB-1: detail [4,8,0,2,10,0], total=24
   - SUB-2: detail [2,8,0,2,15,0], total=27
   - SUB-3: detail [2,6,0,2,0,5], total=15
   - SUB-4: detail [2,8,2,2,0,20], total=34

2. Database Storage:
   - sub_cpmk_komponen_bobot: detail values
   - rps_detail_sub_cpmk_bobot: total values

3. Calculation (Sub-CPMK):
   Uses detail from sub_cpmk_komponen_bobot
   Result: {1: 76.04, 2: 72.22, 3: 88.34, 4: 88.98}

4. Calculation (CPMK):
   Uses total from rps_detail_sub_cpmk_bobot
   CPMK = (76.04×24 + 72.22×27 + 88.34×15 + 88.98×34) / 100
        = 81.25 ✅
```

---

## 💻 Implementation

**File**: `lib/services/obe_calculation_helper.dart`  
**Method**: `_getSubCpmkBobots()` (UPDATED)

### PATH 1 (PRIORITY): Load from RPS Table
```dart
// Load dari rps_detail_sub_cpmk_bobot table
// Dimana user sudah input bobot di RPS (kolom Total)
final allRpsBobot = await _dbHelper.getAllRPSDetailSubCPMKBobots();

// Aggregate untuk setiap Sub-CPMK across all weeks
for (final bobotRow in allRpsBobot) {
  final subCpmkId = bobotRow['sub_cpmk_id'] as int;
  final bobot = (bobotRow['bobot'] as num).toDouble();
  
  result[subCpmkId] = (result[subCpmkId] ?? 0) + bobot;
}

// Result: {1: 24, 2: 27, 3: 15, 4: 34}
```

### PATH 2 (FALLBACK): Calculate from Komponens
```dart
// Jika RPS bobot kosong, fallback ke sum komponen bobot
final bobotMatrixRaw = await _dbHelper.getBobotMatrixForMatakuliah(...);

for (final entry in bobotMatrixRaw.entries) {
  double totalBobot = 0.0;
  for (final bobot in entry.value) {
    totalBobot += bobot;  // Sum [4,8,0,2,10,0] = 24
  }
  result[entry.key] = totalBobot;
}
```

---

## 📋 Data Flow - Detail

### Input: RPS Sub-CPMK Bobot Table
```
rps_detail_sub_cpmk_bobot table:
┌────────────────┬─────────────┬────────┐
│ rps_detail_id  │ sub_cpmk_id │ bobot  │
├────────────────┼─────────────┼────────┤
│ 1 (minggu 1)   │ 12 (SUB-1)  │ 24     │
│ 2 (minggu 2)   │ 13 (SUB-2)  │ 27     │
│ 3 (minggu 3)   │ 14 (SUB-3)  │ 15     │
│ 4 (minggu 4)   │ 15 (SUB-4)  │ 34     │
└────────────────┴─────────────┴────────┘

Aggregation (if multiple weeks):
If minggu 1 has SUB-1(10) and minggu 2 has SUB-1(14):
  subCpmkBobots[12] = 10 + 14 = 24
```

### Processing in `calculateCPMKValuesOptimized()`
```dart
// Load Sub-CPMK bobot dari RPS
subCpmkBobots = await _getSubCpmkBobots(matakuliahId);
// Result: {12: 24, 13: 27, 14: 15, 15: 34}

// Load Sub-CPMK nilai (dari perhitungan sebelumnya)
subCpmkValues = {12: 76.04, 13: 72.22, 14: 88.34, 15: 88.98}

// Calculate CPMK
totalWeighted = 76.04×24 + 72.22×27 + 88.34×15 + 88.98×34
              = 1824.96 + 1949.94 + 1325.10 + 3025.32
              = 8125.32

totalBobot = 24 + 27 + 15 + 34 = 100

cpmkValue = 8125.32 / 100 = 81.25 ✅
```

---

## ✅ Expected Behavior

### Console Output
```
🔍 [_getSubCpmkBobots] Loading Sub-CPMK bobot dari RPS untuk MK=5
   📋 PATH 1: Loading dari tableRPSDetailSubCPMKBobot...
   ✅ RPS bobot data loaded: 4 entries
   📍 RPS minggu untuk MK: 4 minggu
   ✅ PATH 1 SUCCESS: Loaded 4 Sub-CPMK bobot from RPS
      Sub-CPMK 12: total bobot = 24
      Sub-CPMK 13: total bobot = 27
      Sub-CPMK 14: total bobot = 15
      Sub-CPMK 15: total bobot = 34

[calculateCPMKValuesOptimized] Loading Sub-CPMK Bobots for weighted calculation
   ✅ Sub-CPMK Bobots loaded: 4 entries
   CPMK[1] = 81.25 (weighted)
   ✅ TRY PATH 1: Weighted calculation SUCCESS
```

---

## 🔄 Priority System

```
PRIORITY 1 (PRIMARY):
  Load bobot dari rps_detail_sub_cpmk_bobot table
  (Data dari RPS yang user input)
  
        ↓ If empty/error
  
PRIORITY 2 (FALLBACK):
  Calculate bobot dari sum bobot komponen
  (Data dari sub_cpmk_komponen_bobot table)
```

---

## 📝 Verification Table

| Component | Source | Status |
|-----------|--------|--------|
| **Bobot Komponen** | `sub_cpmk_komponen_bobot` table | ✅ Used untuk Sub-CPMK calc |
| **Bobot RPS Total** | `rps_detail_sub_cpmk_bobot` table | ✅ UPDATED - Used untuk CPMK calc |
| **Sub-CPMK Nilai** | Calculate dari komponen+bobot | ✅ 76.04, 72.22, 88.34, 88.98 |
| **CPMK Nilai** | Calculate dari Sub-CPMK+RPS bobot | ✅ 81.25 |

---

## 🎯 What Changed

| Aspect | Before | After |
|--------|--------|-------|
| Bobot source | Sum komponen bobot | Load dari RPS table |
| Fallback | None | Sum komponen bobot |
| Reliability | Assumes clean math | Respects user RPS input |
| Consistency | Auto-calculated | Matches RPS kolom Total |

---

## ✨ Why This Matters

**Before**: If user input RPS Total = 24 tapi calculation = 24.5 (rounding), maka CPMK calculation wrong!

**After**: System uses exact RPS Total value → CPMK calculation matches RPS! ✅

---

## 🔍 Code Location

**File**: `lib/services/obe_calculation_helper.dart`  
**Lines**: ~460-530  
**Method**: `Future<Map<int, double>> _getSubCpmkBobots(int matakuliahId)`

---

## 🚀 Ready to Test

```
✅ Code updated - no syntax errors
✅ PATH 1 loads from RPS bobot table
✅ PATH 2 fallback to component sum
✅ CPMK calculation uses RPS Total values

Awaiting: Test dengan actual RPS data!
```
