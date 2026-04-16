# 🔧 BUG FIX: Nilai CPMK/CPL Tidak Tersimpan di Database

## 🎯 Ringkasan

**Masalah:** Setelah klik "Hitung CPL", tabel `cpl_hasil_perhitungan` tetap kosong (tidak ada data).

**Penyebab:** Type mismatch di `saveCPLCalculationResults()` method - mengakses `result.cpmkValues` (Map<String, double>) tetapi `_mapToJson()` expects `Map<int, double>`.

**Solusi:** Gunakan legacy getters dengan uppercase names yang otomatis convert String keys → Int keys.

---

## 🐛 Root Cause Analysis

### **File:** [`lib/services/database_helper.dart`](lib/services/database_helper.dart#L1677)

**Kode Sebelum (❌ WRONG):**
```dart
final subCpmkValuesJson = _mapToJson(result.subCPMKValues);  // ✅ OK - Map<int, double>
final cpmkValuesJson = _mapToJson(result.cpmkValues);        // ❌ WRONG - Map<String, double>!
final cplValuesJson = _mapToJson(result.cplValues);          // ❌ WRONG - Map<String, double>!
```

**Problem:**
- `_mapToJson()` signature: `String _mapToJson(Map<int, double> data)`
- `result.cpmkValues` adalah `Map<String, double>` (lowercase 'c')
- `result.cplValues` adalah `Map<String, double>` (lowercase 'c')
- **Type mismatch** → error saat runtime

**Error dibungkus di try-catch** di admin_dashboard_screen.dart [line 1912]:
```dart
try {
  await _dbHelper.saveCPLCalculationResults(results);
} catch (saveError) {
  print('⚠️ Warning: Tidak bisa simpan hasil ke database: $saveError');
  // Error tertelan, tidak detail!
}
```

Akibatnya, **data tidak pernah tersimpan** ke `cpl_hasil_perhitungan`.

---

## ✅ Solusi Implementasi

### **File 1: database_helper.dart**

Gunakan legacy getters (uppercase) yang otomatis convert String keys → int keys:

```dart
// ✅ FIXED
final subCpmkValuesJson = _mapToJson(result.subCPMKValues);  // Getter: Map<int, double>
final cpmkValuesJson = _mapToJson(result.cPMKValues);        // Getter: Map<int, double>
final cplValuesJson = _mapToJson(result.cPLValues);          // Getter: Map<int, double>
```

**Property Mapping:**

| Field (Lowercase) | Legacy Getter (Uppercase) | Type |
|---|---|---|
| `result.subCpmkValues` | `result.subCPMKValues` | Map<String, double> → Map<int, double> |
| `result.cpmkValues` | `result.cPMKValues` | Map<String, double> → Map<int, double> |
| `result.cplValues` | `result.cPLValues` | Map<String, double> → Map<int, double> |

### **File 2: admin_dashboard_screen.dart**

Tambahkan detailed error logging saat save:

```dart
try {
  print('💾 Attempting to save ${results.length} calculation results to database...');
  await _dbHelper.saveCPLCalculationResults(results);
  print('✅ Successfully saved calculation results to cpl_hasil_perhitungan');
} catch (saveError) {
  print('❌ CRITICAL ERROR: Tidak bisa simpan hasil ke database!');
  print('❌ Error detail: $saveError');
  print('❌ Stack trace: ${StackTrace.current}');
  print('⚠️ Hasil perhitungan masih ditampilkan, tapi tidak persisten');
}
```

---

## 🔍 Verification Steps

### **Step 1: Run Batch Calculation**
```
1. Buka Admin Dashboard
2. Pilih mata kuliah
3. Klik "Hitung CPL"
4. LIHAT LOG CONSOLE untuk verify:
   - ✅ "💾 Attempting to save X calculation results..."
   - ✅ "✅ Successfully saved calculation results..."
   
   Jika ada error:
   - ❌ "❌ CRITICAL ERROR: Tidak bisa simpan hasil..."
```

### **Step 2: Check Database**
```
Buka Database Browser dan query:
SELECT COUNT(*) FROM cpl_hasil_perhitungan;

Should return > 0 (data ada, bukan 0/kosong)
```

### **Step 3: Check Data Content**
```
SELECT mahasiswa_id, matakuliah_id, cpmk_values, cpl_values 
FROM cpl_hasil_perhitungan 
LIMIT 1;

Should see:
- mahasiswa_id: [angka]
- matakuliah_id: [angka]
- cpmk_values: "1:78.3" atau "1:78.3|2:82.1" (NOT null/empty)
- cpl_values: "1:35.25|2:42.15..." (NOT null/empty)
```

---

## 📊 Data Flow Setelah Fix

```
┌─────────────────────────────────────────┐
│  User Klik "Hitung CPL" (Admin Dashboard)│
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ calculateBatchOBEResultsForMatakuliah()  │
│ Returns: List<OBECalculationResult>      │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ saveCPLCalculationResults(results)       │
│ 1. For each result in results:           │
│    - Access result.subCPMKValues (getter)│
│    - Access result.cPMKValues (getter)   │ ✅ FIXED
│    - Access result.cPLValues (getter)    │ ✅ FIXED
│    - Convert to JSON: "1:78.3|2:82.1"   │
│    - Insert to cpl_hasil_perhitungan     │
│ 2. batch.commit()                        │
└─────────────────┬───────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│ Database: cpl_hasil_perhitungan          │
│ ✅ Data successfully saved!              │
│ Row count: > 0                           │
└─────────────────────────────────────────┘
```

---

## 🧪 Troubleshooting

### **Issue 1: Still Kosong Setelah Fix**

**Debug Steps:**
```dart
// Print sebelum save
print('DEBUG: Hasil perhitungan yang akan disimpan:');
for (var result in results) {
  print('  - Mahasiswa ID: ${result.mahasiswaId}');
  print('  - CPMK Values: ${result.cPMKValues}');
  print('  - CPL Values: ${result.cPLValues}');
}
```

**Lihat logs untuk:**
- Apakah results ada (length > 0)?
- Apakah cPMKValues/cPLValues kosong atau ada data?
- Apakah ada error message?

### **Issue 2: Error Type Mismatch**

**Jika masih error setelah fix**, possible causes:

1. **Clear app cache & reinstall**
   - Settings → Apps → Hapus data
   - Uninstall app
   - Rebuild & run

2. **Check if all getters exist**
   - Method `cPMKValues`, `cPLValues` harus ada di OBECalculationResult
   - Verify di obe_calculation_helper.dart

---

## 📝 Summary

| Aspek | Sebelum | Sesudah |
|-------|---------|---------|
| Save to DB | ❌ Fail (type mismatch) | ✅ Success |
| DB table status | Empty (0 rows) | Populated (N rows) |
| Error visibility | Hidden (swallowed) | Visible (detailed logs) |
| Assessment Outcomes | Recalculate every time | Fetch from DB (instant) |
| Data persistence | None | Permanent |

---

## 📋 Files Modified

| File | Changes | Reason |
|------|---------|--------|
| `lib/services/database_helper.dart` | Use legacy getters (cPMKValues, cPLValues) | Fix type mismatch |
| `lib/screens/admin_dashboard_screen.dart` | Enhanced error logging | Better debugging |

---

**Status:** ✅ Fixed  
**Test Date:** April 15, 2026  
**Impact:** HIGH - Fixes data persistence issue
