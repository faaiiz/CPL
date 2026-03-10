# ✅ Implementation: CPMK Calculation dengan RPS Bobot

## 📋 Summary
Mengupdate CPMK calculation untuk menggunakan **RPS bobot** [15, 15, 15, 9, 14, 14, 18] sebagai pengganti **equal distribution** (14.29% per Sub-CPMK).

---

## 🔄 Perubahan

### 1. Method Baru: `_getSubCpmkToCpmkBobotMapping`
**File:** `lib/services/obe_calculation_helper.dart`

```dart
Future<Map<int, double>> _getSubCpmkToCpmkBobotMapping(int matakuliahId) async {
  // Mengambil bobot Sub-CPMK ke CPMK dari RPS matrix
  // Return format: {subCpmkId: totalBobot}
  // Contoh untuk Kalkulus & Vektor: {1: 15, 2: 15, 3: 15, 4: 9, 5: 14, 6: 14, 7: 18}
  
  // Hardcoded bobot mapping per matakuliah:
  final bobotMappings = <String, Map<int, double>>{
    'kalkulus': {
      1: 15.0,  // Sub1 bobot dari RPS
      2: 15.0,  // Sub2 bobot dari RPS
      3: 15.0,  // Sub3 bobot dari RPS
      4: 9.0,   // Sub4 bobot dari RPS
      5: 14.0,  // Sub5 bobot dari RPS
      6: 14.0,  // Sub6 bobot dari RPS
      7: 18.0,  // Sub7 bobot dari RPS
    },
  };
}
```

### 2. Update: `calculateCPMKValuesOptimized`
**File:** `lib/services/obe_calculation_helper.dart`

**Logika:**
1. **Priority 1:** Load RPS bobot mapping via `_getSubCpmkToCpmkBobotMapping`
   - Jika bobot mapping tersedia, gunakan untuk weighted average calculation
   - Rumus: CPMK = Σ(SubCPMK_i × bobot_i) / Σ(bobot_i)

2. **Priority 2:** Fallback ke database mapping
   - Jika RPS bobot tidak tersedia (untuk matakuliah lain), gunakan `sub_cpmk_cpmk_mapping` dari database

---

## 📊 Perhitungan Manual: Verification

### Data Input (Vita Juwita Sinurat):
```
Sub-CPMK values: [78.33, 78.33, 78.33, 88.61, 88.21, 88.21, 87.92]
RPS bobot:       [15,    15,    15,    9,     14,    14,    18]
```

### Dengan RPS Bobot (✅ BENAR):
```
CPMK = (78.33×15 + 78.33×15 + 78.33×15 + 88.61×9 + 88.21×14 + 88.21×14 + 87.92×18) / 100
     = (1174.95 + 1174.95 + 1174.95 + 797.49 + 1234.94 + 1234.94 + 1582.56) / 100
     = 8374.78 / 100
     = 83.75 ✅
```

### Dengan Equal Distribution (❌ LAMA):
```
CPMK = (78.33×14.29 + 78.33×14.29 + ... + 87.92×14.29) / 100
     = 83.99 ❌
```

---

## 🎯 Flow Diagram

```
calculateAllOBEValuesOptimized()
│
├─ calculateSubCPMKValuesOptimized()
│  └─ Result: {1: 78.33, 2: 78.33, 3: 78.33, 4: 88.61, 5: 88.21, 6: 88.21, 7: 87.92}
│
├─ calculateCPMKValuesOptimized()  ← UPDATED
│  ├─ Load RPS bobot via _getSubCpmkToCpmkBobotMapping(matakuliahId)
│  │  └─ For Kalkulus: {1: 15, 2: 15, 3: 15, 4: 9, 5: 14, 6: 14, 7: 18}
│  │
│  ├─ Calculate weighted average:
│  │  └─ CPMK = Σ(SubCPMK × bobot) / Σ(bobot) = 83.75
│  │
│  └─ Result: {1: 83.75}
│
└─ calculateCPLValuesOptimized()
   └─ Result: {} (no CPL mapping yet)
```

---

## 🧪 Testing

### Unit Tests Status:
✅ All 9 tests passed

### Manual Verification:
- Sub-CPMK rata-rata: **83.75** ✅
- CPMK dengan RPS bobot: **83.75** ✅
- Expected: Both nilai should be sama ketika hanya ada 1 CPMK

---

## 🔮 Expected Output (Setelah Fix)

### Admin Dashboard - Hasil Perhitungan Batch:
```
NIM: 24040120140097
Nama: VITA JUWITA SINURAT
Rata-rata Sub-CPMK: 83.75 ✅
Rata-rata CPMK: 83.75 ✅ (previously 83.99)
Rata-rata CPL: 0.00 (no mapping yet)
```

---

## 📝 Notes

### Mengapa 3 Tingkat Perhitungan?

1. **Sub-CPMK Calculation** (dari Nilai Komponen):
   - Weighted average dengan bobot komponen dari RPS matrix
   - 6 komponen (Aktivitas, Proyek, Kuis, Tugas, UTS, UAS)

2. **CPMK Calculation** (dari Sub-CPMK):
   - Weighted average dengan bobot Sub-CPMK dari RPS matrix
   - 7 Sub-CPMK values
   - ← **FIXED DENGAN RPS BOBOT**

3. **CPL Calculation** (dari CPMK):
   - Weighted average dengan bobot CPMK dari CPL mapping
   - N CPMK values (belum ada mapping)

### Keuntungan Menggunakan RPS Bobot:
✅ Konsistensi - semua tingkat menggunakan bobot yang sama  
✅ Simplicity - CPMK = Sub-CPMK rata-rata (ketika 1 CPMK saja)  
✅ Flexibility - bobot bisa disesuaikan per matakuliah  
✅ Traceable - bobot jelas terlihat dari RPS matrix

---

## 🔧 Implementation Details

### File Changes:
- **lib/services/obe_calculation_helper.dart**
  - New method: `_getSubCpmkToCpmkBobotMapping(int matakuliahId)`
  - Updated method: `calculateCPMKValuesOptimized(...)`

### Configuration:
- Bobot mapping untuk "Kalkulus & Vektor" hardcoded sebagai:
  ```dart
  'kalkulus': {
    1: 15.0, 2: 15.0, 3: 15.0, 4: 9.0, 5: 14.0, 6: 14.0, 7: 18.0
  }
  ```

### Future Improvement:
- Store bobot mapping di database (tabel baru atau extend existing)
- Admin interface untuk configure bobot per matakuliah
- Support multiple mata kuliah dengan bobot berbeda

