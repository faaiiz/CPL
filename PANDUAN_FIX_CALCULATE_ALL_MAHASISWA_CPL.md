# 📚 Panduan Fix: Mengganti calculateAllMahasiswaCPL() yang Deprecated

## ⚠️ Masalah

Method `calculateAllMahasiswaCPL()` sudah di-deprecate dan tidak berfungsi:

```dart
// ❌ DEPRECATED - Jangan gunakan!
final results = await _obeHelper.calculateAllMahasiswaCPL(
  matakuliahId,
  tahunAjaran,
);
```

**Error:**
```
❌ Error dalam _calculateCPLFromTable: 
Unsupported operation: calculateAllMahasiswaCPL() telah di-refactor. 
Gunakan calculateOBEComplete() atau calculate*Values() methods dengan data preparation manual.
```

---

## ✅ Solusi: Gunakan calculateOBEComplete() dengan Data Preparation

### 📋 Overview Alur Perhitungan

```
┌─────────────────────────────────────────────────────────┐
│  1. Get Mahasiswa & Nilai Komponen untuk Mata Kuliah   │
│     (dari nilai_komponen table)                         │
└────────────────┬────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────┐
│  2. For Each Mahasiswa:                                 │
│     - Get nilaiKomponen (aktivitas, proyek, dst)        │
│     - Get subCpmkBobotMap (bobot per komponen)          │
│     - Get cpmkSubCpmkMap (mapping CPMK←SubCPMK)        │
└────────────────┬────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────┐
│  3. Call calculateOBEComplete()                         │
│     → SubCPMK, CPMK, CPL values                         │
└────────────────┬────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────────────────────┐
│  4. Create OBECalculationResult object untuk return     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 Implementasi Step-by-Step

### Fungsi Baru: calculateBatchOBEResultsForMatakuliah()

```dart
/// 🎯 Hitung OBE (Sub-CPMK, CPMK, CPL) untuk semua mahasiswa di satu mata kuliah
///
/// INPUT:
/// - matakuliahId: ID mata kuliah
/// - tahunAjaran: Tahun akademik
///
/// PROCESS:
/// 1. Get semua mahasiswa yang punya nilai_komponen untuk MK ini
/// 2. Untuk tiap mahasiswa:
///    - Ambil nilai_komponen dari database
///    - Ambil bobot matrix dari rps_detail_sub_cpmk_bobot
///    - Ambil CPMK←SubCPMK mapping dari sub_cpmk_cpmk_mapping
///    - Call calculateOBEComplete() dengan data tersebut
///    - Create OBECalculationResult dari hasil perhitungan
/// 3. Return List<OBECalculationResult> untuk semua mahasiswa
///
/// OUTPUT:
/// List<OBECalculationResult> berisi:
/// {
///   mahasiswaId: 123,
///   subCpmkValues: {"sub1": 85.5, "sub2": 82.3, ...},
///   cpmkValues: {"cpmk1": 83.9, ...},
///   cplValues: {"cpl1": 85.2, ...},
///   success: true,
///   ...
/// }
Future<List<OBECalculationResult>> calculateBatchOBEResultsForMatakuliah({
  required int matakuliahId,
  required int tahunAjaran,
}) async {
  try {
    final results = <OBECalculationResult>[];

    // STEP 1️⃣: Get semua mahasiswa yang punya nilai_komponen untuk MK ini
    final nilaiKomponenList = await _dbHelper.getNilaiKomponenByMatakuliah(
      matakuliahId: matakuliahId,
      tahunAjaran: tahunAjaran,
    );

    if (nilaiKomponenList.isEmpty) {
      print('⚠️ Tidak ada nilai_komponen untuk MK $matakuliahId tahun $tahunAjaran');
      return results;
    }

    // STEP 2️⃣: Get bobot matrix (sama untuk semua mahasiswa)
    final subCpmkBobotMap = await _getSubCpmkBobotMapFromDatabase(matakuliahId);
    final cpmkSubCpmkMap = await _getCpmkSubCpmkMapFromDatabase(matakuliahId);

    if (subCpmkBobotMap.isEmpty || cpmkSubCpmkMap.isEmpty) {
      throw Exception(
        'Bobot matrix tidak lengkap untuk MK $matakuliahId. '
        'Pastikan RPS dan mapping sudah di-setup!'
      );
    }

    // STEP 3️⃣: Process tiap mahasiswa
    final processedMahasiswa = <int>{};

    for (final nkRow in nilaiKomponenList) {
      final mahasiswaId = nkRow['mahasiswa_id'] as int;
      
      // Skip jika sudah diproses (jangan double-count)
      if (processedMahasiswa.contains(mahasiswaId)) continue;
      processedMahasiswa.add(mahasiswaId);

      try {
        // STEP 4️⃣: Prepare nilaiKomponen dari row
        final nilaiKomponen = _parseNilaiKomponenRow(nkRow);

        if (nilaiKomponen.isEmpty) {
          print('⚠️ Nilai komponen kosong untuk mahasiswa $mahasiswaId');
          continue;
        }

        // STEP 5️⃣: Call calculateOBEComplete()
        final calculationResult = calculateOBEComplete(
          nilaiKomponen: nilaiKomponen,
          subCpmkBobotMap: subCpmkBobotMap,
          cpmkSubCpmkMap: cpmkSubCpmkMap,
        );

        // STEP 6️⃣: Cek status hasil perhitungan
        if (calculationResult['status'] != 'success') {
          print('⚠️ Perhitungan gagal untuk mahasiswa $mahasiswaId: ${calculationResult['message']}');
          continue;
        }

        // STEP 7️⃣: Create OBECalculationResult object
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
        print('✅ Processed mahasiswa $mahasiswaId');
      } catch (mahasiswaError) {
        print('❌ Error processing mahasiswa $mahasiswaId: $mahasiswaError');
        continue; // Skip mahasiswa ini, continue dengan yang lain
      }
    }

    print('✅ Batch calculation completed: ${results.length} mahasiswa processed');
    return results;
  } catch (e) {
    print('❌ Fatal error in batch calculation: $e');
    rethrow;
  }
}

/// 🔧 Helper: Parse nilai_komponen row dari database
Map<String, double> _parseNilaiKomponenRow(Map<String, dynamic> row) {
  return {
    'aktivitas': (row['nilai_aktivitas'] as num?)?.toDouble() ?? 0.0,
    'proyek': (row['nilai_proyek'] as num?)?.toDouble() ?? 0.0,
    'kuis': (row['nilai_kuis'] as num?)?.toDouble() ?? 0.0,
    'tugas': (row['nilai_tugas'] as num?)?.toDouble() ?? 0.0,
    'uts': (row['nilai_uts'] as num?)?.toDouble() ?? 0.0,
    'uas': (row['nilai_uas'] as num?)?.toDouble() ?? 0.0,
  };
}

/// 🔧 Helper: Get Sub-CPMK bobot map dari database
Future<Map<String, Map<String, double>>> _getSubCpmkBobotMapFromDatabase(
  int matakuliahId,
) async {
  try {
    // Get dari tabel rps_detail_sub_cpmk_bobot
    final bobotMatrix = await _dbHelper.getRpsDetailSubCpmkBobot(matakuliahId);
    
    if (bobotMatrix == null || bobotMatrix.isEmpty) {
      throw Exception('Bobot matrix tidak ditemukan untuk MK $matakuliahId');
    }

    // Convert ke format Map<String, Map<String, double>>
    // Format: {"sub1": {"aktivitas": 10, "proyek": 20, ...}, ...}
    final result = <String, Map<String, double>>{};

    for (final entry in bobotMatrix.entries) {
      final subCpmkId = entry.key; // "sub1", "sub2", etc
      final bobots = entry.value; // {"aktivitas": 10, "proyek": 20, ...}

      result[subCpmkId] = bobots.cast<String, double>();
    }

    return result;
  } catch (e) {
    print('❌ Error getting Sub-CPMK bobot map: $e');
    rethrow;
  }
}

/// 🔧 Helper: Get CPMK←SubCPMK mapping dari database
Future<Map<String, Map<String, double>>> _getCpmkSubCpmkMapFromDatabase(
  int matakuliahId,
) async {
  try {
    // Get dari tabel sub_cpmk_cpmk_mapping
    final mappings = await _dbHelper.getSubCpmkCpmkMappings(matakuliahId);
    
    if (mappings == null || mappings.isEmpty) {
      throw Exception('CPMK←SubCPMK mapping tidak ditemukan untuk MK $matakuliahId');
    }

    // Convert ke format Map<String, Map<String, double>>
    // Format: {"cpmk1": {"sub1": 15, "sub2": 15, ...}, ...}
    final result = <String, Map<String, double>>{};

    for (final mapping in mappings) {
      final cpmkId = mapping['cpmk_id'].toString(); // "cpmk1"
      final subCpmkId = mapping['sub_cpmk_id'].toString(); // "sub1"
      final bobot = (mapping['bobot'] as num?)?.toDouble() ?? 0.0;

      if (!result.containsKey(cpmkId)) {
        result[cpmkId] = {};
      }

      result[cpmkId]![subCpmkId] = bobot;
    }

    return result;
  } catch (e) {
    print('❌ Error getting CPMK←SubCPMK mapping: $e');
    rethrow;
  }
}
```

---

## 🔄 Mengubah Kode Lama → Kode Baru

### ❌ SEBELUM (Deprecated):

```dart
// Di admin_dashboard_screen.dart baris 1582
final results = await _obeHelper.calculateAllMahasiswaCPL(
  matakuliahId,
  tahunAjaran,
);
```

### ✅ SESUDAH (New Implementation):

```dart
// Di admin_dashboard_screen.dart baris 1582
final results = await _obeHelper.calculateBatchOBEResultsForMatakuliah(
  matakuliahId: matakuliahId,
  tahunAjaran: tahunAjaran,
);
```

**Itu saja! Signature dan return type tetap sama:**
- Input: `matakuliahId` dan `tahunAjaran`
- Output: `List<OBECalculationResult>`

---

## 📊 Contoh Hasil Perhitungan

### Input Data:

```dart
// nilaiKomponen (dari database)
{
  'aktivitas': 85.0,
  'proyek': 90.0,
  'kuis': 80.0,
  'tugas': 88.0,
  'uts': 75.0,
  'uas': 92.0,
}

// subCpmkBobotMap (dari rps_detail_sub_cpmk_bobot)
{
  'sub1': {'aktivitas': 15, 'proyek': 20, 'kuis': 0, 'tugas': 15, 'uts': 25, 'uas': 25},
  'sub2': {'aktivitas': 0, 'proyek': 15, 'kuis': 20, 'tugas': 15, 'uts': 25, 'uas': 25},
  ...
}

// cpmkSubCpmkMap (dari sub_cpmk_cpmk_mapping)
{
  'cpmk1': {'sub1': 15, 'sub2': 15, 'sub3': 15, ...},
}
```

### Process:

```
STEP 1: Hitung Sub-CPMK
- Sub1 = (85×15 + 90×20 + 80×0 + 88×15 + 75×25 + 92×25) / (15+20+0+15+25+25)
       = (1275 + 1800 + 0 + 1320 + 1875 + 2300) / 100
       = 8570 / 100
       = 85.70

STEP 2: Hitung CPMK
- CPMK1 = (85.70×15 + 82.50×15 + 80.00×15 + ...) / (15+15+15+...)
        = ... / total_bobot
        = 83.90

STEP 3: Hitung CPL
- CPL1 = (CPMK1 + CPMK2 + CPMK3) / 3
       = (83.90 + 82.45 + 84.50) / 3
       = 83.62
```

### Output:

```dart
OBECalculationResult(
  mahasiswaId: 123,
  matakuliahId: 5,
  tahunAjaran: 2024,
  subCpmkValues: {
    'sub1': 85.70,
    'sub2': 82.50,
    'sub3': 80.00,
    ...
  },
  cpmkValues: {
    'cpmk1': 83.90,
  },
  cplValues: {
    'cpl1': 83.62,
    'cpl2': 82.45,
    ...
  },
  success: true,
)
```

---

## ⚠️ Error Handling

```dart
try {
  final results = await _obeHelper.calculateBatchOBEResultsForMatakuliah(
    matakuliahId: matakuliahId,
    tahunAjaran: tahunAjaran,
  );

  if (results.isEmpty) {
    // Tidak ada data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚠️ Tidak ada data nilai komponen untuk ditampilkan')),
    );
    return;
  }

  // Success - gunakan results seperti biasa
  setState(() {
    _batchCalculationResults = results;
  });
} catch (e) {
  // Bobot matrix tidak lengkap atau error lain
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('❌ Error perhitungan: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## ✅ Checklist Database

Sebelum menggunakan fungsi ini, pastikan:

- [ ] Table `nilai_komponen` sudah ter-populate dengan component scores
- [ ] Table `rps_detail_sub_cpmk_bobot` sudah ter-populate dengan bobot matrix
- [ ] Table `sub_cpmk_cpmk_mapping` sudah ter-populate dengan mapping CPMK←SubCPMK
- [ ] DatabaseHelper memiliki method:
  - [ ] `getNilaiKomponenByMatakuliah()`
  - [ ] `getRpsDetailSubCpmkBobot()`
  - [ ] `getSubCpmkCpmkMappings()`

Jika belum punya method-method tersebut, tambahkan ke `database_helper.dart`.

---

## 📝 Ringkasan Perubahan

| Aspek | Lama (Deprecated) | Baru (Implemented) |
|-------|-------------------|-------------------|
| **Method** | `calculateAllMahasiswaCPL()` | `calculateBatchOBEResultsForMatakuliah()` |
| **Paradigma** | Async method di OBECalculationHelper (tapi tidak berfungsi) | Kombinasi data preparation + sync `calculateOBEComplete()` |
| **Data Preparation** | Otomatis (internal database query) | Manual (provide data maps) |
| **Flexibility** | Terbatas | Fleksibel - bisa customize rule perhitungan |
| **Error Handling** | Throw exception | Per-mahasiswa error handling |
| **Performance** | Cepat tapi null values | Konsisten tapi rawan missing bobot |

---

## 🎯 Next Steps

1. Tambahkan fungsi `calculateBatchOBEResultsForMatakuliah()` ke OBECalculationHelper
2. Ganti semua `calculateAllMahasiswaCPL()` calls di:
   - `admin_dashboard_screen.dart` baris 1582
   - `admin_dashboard_screen.dart` baris 1883
   - `assessment_outcomes_screen.dart` (jika ada)
3. Verify DatabaseHelper punya semua helper methods untuk fetch bobot data
4. Test dengan data real dari database
5. Hapus/comment method `calculateAllMahasiswaCPL()` lama

