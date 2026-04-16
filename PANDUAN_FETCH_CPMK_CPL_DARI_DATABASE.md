# 📊 PANDUAN: Mengambil Nilai CPMK & CPL dari Database

## 🎯 Ringkasan Solusi

Sistem sudah diimplementasikan untuk **mengambil nilai CPMK dan CPL yang tersimpan di database** setelah perhitungan selesai.

### **Alur Lengkap:**

```
┌─────────────────────────────────────────────────────────────┐
│                    ADMIN DASHBOARD                           │
│  User klik "Hitung CPL" untuk Mata Kuliah tertentu         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  1. Admin Dashboard Screen (admin_dashboard_screen.dart)    │
│     - Call: calculateBatchOBEResultsForMatakuliah()         │
│     - Process: Hitung CPMK & CPL untuk semua mahasiswa     │
│     - Save: saveCPLCalculationResults()                      │
│       └─ Simpan ke tabel: 'cpl_hasil_perhitungan'          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  2. Database Storage (cpl_hasil_perhitungan)                │
│     Struktur:                                                │
│     - mahasiswa_id                                           │
│     - matakuliah_id                                          │
│     - tahun_ajaran                                           │
│     - sub_cpmk_values (JSON: "1:78.3|2:82.1")             │
│     - cpmk_values (JSON: "1:83.75")                         │
│     - cpl_values (JSON: "1:35.25|2:42.15|...")            │
│     - average_sub_cpmk_nilai (cached result)                │
│     - average_cpmk_nilai (cached result)                    │
│     - average_cpl_nilai (cached result)                     │
│     - calculated_at (timestamp)                             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  3. Assessment Outcomes Screen (assessment_outcomes_screen) │
│     User memilih mahasiswa dan lihat CPMK/CPL               │
│                                                              │
│  STEP A: TRY FETCH FROM DATABASE (INSTANT)                 │
│     - Call: getCPLCalculationResult(mahasiswaId, mkId)     │
│     - Parse JSON strings ke Map<String, double>             │
│     - Return cached result dalam < 1 detik                  │
│                                                              │
│  STEP B: FALLBACK TO CALCULATION (IF NOT FOUND)            │
│     - Call: calculateBatchOBEResultsForMatakuliah()         │
│     - Calculate fresh values                                │
│     - Save: saveCPLCalculationResults()                     │
│     - Return calculated result                              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  4. UI Display                                               │
│     CPMK & CPL scores ditampilkan dengan data yang fresh   │
│     (dari database atau hasil kalkulasi)                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 File Implementasi

### **1. Admin Dashboard (Batch Calculation & Save)**
**File:** [`lib/screens/admin_dashboard_screen.dart`](lib/screens/admin_dashboard_screen.dart#L1870)

```dart
void _calculateCPLForMatakuliah(Matakuliah matakuliah) async {
  _showCalculatingDialog();

  try {
    // STEP 1: Hitung batch results
    final results = await _obeHelper.calculateBatchOBEResultsForMatakuliah(
      matakuliahId: matakuliahId,
      tahunAjaran: tahunAjaran,
    );

    // STEP 2: SIMPAN HASIL KE DATABASE ✅
    try {
      await _dbHelper.saveCPLCalculationResults(results);
      print('✅ CPL hasil disimpan ke database');
    } catch (saveError) {
      print('⚠️ Warning: Tidak bisa simpan hasil: $saveError');
    }
  }
}
```

### **2. Assessment Outcomes (Fetch & Display)**
**File:** [`lib/screens/assessment_outcomes_screen.dart`](lib/screens/assessment_outcomes_screen.dart#L235)

```dart
void _loadMahasiswaScores(Mahasiswa mahasiswa) async {
  for (final nilaiKomponen in nilaiKomponenList) {
    // STEP 1: TRY FETCH FROM DATABASE FIRST ✅
    final savedResult = await _dbHelper.getCPLCalculationResult(
      mahasiswaId,
      matakuliahId,
      tahunAjaran,
    );
    
    OBECalculationResult? mahasiswaResult;
    
    if (savedResult != null) {
      // ✅ Gunakan hasil yang sudah disimpan (INSTANT)
      print('📦 Memuat hasil CPL dari database untuk MK $matakuliahId');
      
      // Parse JSON strings
      final subCpmkValues = _convertToStringKeyMap(
        _parseJsonMapValue(savedResult['sub_cpmk_values'] ?? '')
      );
      final cpmkValues = _convertToStringKeyMap(
        _parseJsonMapValue(savedResult['cpmk_values'] ?? '')
      );
      final cplValues = _convertToStringKeyMap(
        _parseJsonMapValue(savedResult['cpl_values'] ?? '')
      );
      
      mahasiswaResult = OBECalculationResult(
        mahasiswaId: mahasiswaId,
        matakuliahId: matakuliahId,
        tahunAjaran: tahunAjaran,
        subCpmkValues: subCpmkValues,
        cpmkValues: cpmkValues,
        cplValues: cplValues,
      );
    } else {
      // STEP 2: FALLBACK TO CALCULATION ✅
      print('🔄 Menghitung CPL untuk MK (tidak ada di database)');
      final results = await _obeHelper.calculateBatchOBEResultsForMatakuliah(
        matakuliahId: matakuliahId,
        tahunAjaran: tahunAjaran,
      );
      
      mahasiswaResult = results.firstWhere(
        (r) => r.mahasiswaId == mahasiswaId,
      );
      
      // SAVE untuk next time
      await _dbHelper.saveCPLCalculationResults(results);
    }
  }
}
```

### **3. Database Helper Methods**
**File:** [`lib/services/database_helper.dart`](lib/services/database_helper.dart#L1660)

#### **Simpan Hasil (Batch Insert)**
```dart
Future<void> saveCPLCalculationResults(List<dynamic> results) async {
  // Convert Map ke String format: "1:78.3|2:82.1"
  final subCpmkValuesJson = _mapToJson(result.subCPMKValues);
  final cpmkValuesJson = _mapToJson(result.cpmkValues);
  final cplValuesJson = _mapToJson(result.cplValues);
  
  // Insert dengan REPLACE (update jika sudah ada)
  batch.insert(
    'cpl_hasil_perhitungan',
    {
      'mahasiswa_id': result.mahasiswaId,
      'matakuliah_id': result.matakuliahId,
      'tahun_ajaran': result.tahunAjaran,
      'sub_cpmk_values': subCpmkValuesJson,
      'cpmk_values': cpmkValuesJson,
      'cpl_values': cplValuesJson,
      'average_sub_cpmk_nilai': result.averageSubCPMKNilai,
      'average_cpmk_nilai': result.averageCPMKNilai,
      'average_cpl_nilai': result.averageCPLNilai,
      'calculated_at': DateTime.now().toIso8601String(),
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

#### **Ambil Hasil (Query Database)**
```dart
Future<Map<String, dynamic>?> getCPLCalculationResult(
  int mahasiswaId, 
  int matakuliahId, 
  int tahunAjaran
) async {
  final results = await db.query(
    'cpl_hasil_perhitungan',
    where: 'mahasiswa_id = ? AND matakuliah_id = ? AND tahun_ajaran = ?',
    whereArgs: [mahasiswaId, matakuliahId, tahunAjaran],
  );
  
  return results.isNotEmpty ? results.first : null;
}
```

### **4. Helper Methods (Parse JSON)**
**File:** [`lib/screens/assessment_outcomes_screen.dart`](lib/screens/assessment_outcomes_screen.dart#L1195)

```dart
/// Parse JSON string dari database ke Map<int, double>
/// Format: "1:25.5|2:30.2|3:28.8"
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

/// Convert Map<int, double> ke Map<String, double>
Map<String, double> _convertToStringKeyMap(Map<int, double> intMap) {
  final result = <String, double>{};
  for (final entry in intMap.entries) {
    result[entry.key.toString()] = entry.value;
  }
  return result;
}
```

---

## ✅ Workflow Lengkap

### **Scenario 1: Setelah Batch Calculation (Happy Path)**

```
1. User buka Admin Dashboard
2. Pilih mata kuliah → Klik "Hitung CPL"
3. System menjalankan: calculateBatchOBEResultsForMatakuliah()
4. ✅ Results disimpan ke 'cpl_hasil_perhitungan' table
5. User buka Assessment Outcomes
6. Pilih mahasiswa
7. System query database → getCPLCalculationResult()
8. ✅ INSTANT: Data ditampilkan dari database (< 1 detik)
```

### **Scenario 2: Belum Ada Batch Calculation**

```
1. User langsung buka Assessment Outcomes (tanpa batch calc dulu)
2. Pilih mahasiswa
3. System query database → getCPLCalculationResult()
4. ❌ Tidak ada data (fallback triggered)
5. System calculate → calculateBatchOBEResultsForMatakuliah()
6. ✅ Results disimpan ke database
7. ✅ Data ditampilkan
8. Next time: Langsung fetch dari database (scenario 1)
```

---

## 🐛 Troubleshooting: "Tidak Ada Data CPMK"

### **Issue 1: CPMK Data Kosong di Database**

**Penyebab:** Batch calculation belum dijalankan

**Solusi:**
```
1. Buka Admin Dashboard
2. Pilih mata kuliah yang ingin dihitung
3. Klik tombol "Hitung CPL" (bukan "Lihat")
4. Tunggu hingga selesai (dialog akan tutup)
5. Data sudah tersimpan di database
6. Buka Assessment Outcomes - pilih mahasiswa → lihat data
```

### **Issue 2: Calculation Result Kosong**

**Penyebab:** Nilai komponen tidak lengkap di database

**Solusi:**
```
1. Pastikan nilai komponen sudah diinput:
   - Aktivitas, Proyek, Kuis, Tugas, UTS, UAS
2. Verify data di Edit Nilai Komponen screen
3. Jalankan batch calculation ulang
4. Check Assessment Outcomes
```

### **Issue 3: Database Tidak Tersimpan**

**Penyebab:** Tabel 'cpl_hasil_perhitungan' mungkin corrupt atau tidak ada

**Solusi:**
```dart
// Check di DatabaseHelper if table exists:
final exists = await _dbHelper.checkTableExists('cpl_hasil_perhitungan');

// If tidak ada, recreate:
// 1. Hapus app data (Settings → App → Storage → Clear)
// 2. Restart app (database akan recreate)
// 3. Jalankan batch calculation lagi
```

---

## 📊 Database Table Structure

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PRIMARY KEY | Auto increment |
| mahasiswa_id | INTEGER | Foreign key to mahasiswa |
| matakuliah_id | INTEGER | Foreign key to matakuliah |
| tahun_ajaran | INTEGER | Academic year |
| sub_cpmk_values | TEXT | JSON: "1:78.3\|2:82.1" |
| cpmk_values | TEXT | JSON: "1:83.75" |
| cpl_values | TEXT | JSON: "1:35.25\|2:42.15..." |
| average_sub_cpmk_nilai | REAL | Cached average |
| average_cpmk_nilai | REAL | Cached average |
| average_cpl_nilai | REAL | Cached average |
| sub_cpmk_bobots | TEXT | Bobot reference |
| calculated_at | TEXT | Timestamp |
| updated_at | TEXT | Last update |

**Indexes:**
- `idx_cpl_results_mk`: (matakuliah_id, tahun_ajaran)
- `idx_cpl_results_mhs`: (mahasiswa_id)

---

## 🔍 Verifikasi Implementasi

### **Check 1: Table Exists**
```dart
final result = await db.rawQuery(
  "SELECT name FROM sqlite_master WHERE type='table' AND name='cpl_hasil_perhitungan'"
);
print(result.isNotEmpty ? '✅ Table exists' : '❌ Table missing');
```

### **Check 2: Data Saved**
```dart
final results = await _dbHelper.getCPLCalculationResults(matakuliahId, tahunAjaran);
print('✅ ${results.length} records saved');
```

### **Check 3: Fetch Works**
```dart
final result = await _dbHelper.getCPLCalculationResult(mahasiswaId, matakuliahId, tahunAjaran);
print(result != null ? '✅ Data found' : '❌ Data not found');
```

---

## 🚀 Best Practices

1. **Always run Batch Calculation first** before viewing Assessment Outcomes
2. **Check database** if large dataset (wait a few seconds)
3. **Verify nilai komponen** before batch calculation
4. **Clear app cache** if experiencing persistent issues
5. **Monitor logs** for error messages during calculation

---

## 📝 Summary

| Feature | Status | Location |
|---------|--------|----------|
| Save to DB after calculation | ✅ Implemented | admin_dashboard_screen.dart:1909 |
| Fetch from DB first | ✅ Implemented | assessment_outcomes_screen.dart:280 |
| Fallback to calculation | ✅ Implemented | assessment_outcomes_screen.dart:295 |
| JSON parse/convert | ✅ Implemented | assessment_outcomes_screen.dart:1195 |
| Database schema | ✅ Implemented | database_helper.dart:559 |

**Result:** ✅ **System fully implements "ambil nilai dari database setelah hitung CPL"**

---

**Last Updated:** April 15, 2026  
**Status:** Production Ready ✅
