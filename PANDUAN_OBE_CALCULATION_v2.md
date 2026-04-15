# Panduan OBE Calculation Helper v2

## 🎯 Ringkasan Perubahan

File `OBE_calculation_helper.dart` telah dirombak ulang dengan fokus pada **kejelasan alur perhitungan OBE** yang sederhana dan transparan:

```
Nilai Komponen → Sub-CPMK → CPMK → CPL
```

### Perubahan Utama:
1. ✅ **Simplifikasi Logic**: Menghapus code legacy dan optimasi yang rumit
2. ✅ **Alur Jelas**: WAJIB melalui Sub-CPMK (bukan shortcut)
3. ✅ **Validasi Ketat**: Pengecekan bobot, nilai, dan data di setiap step
4. ✅ **Response Standard**: Format output yang konsisten sesuai spesifikasi
5. ✅ **Pembulatan 2 Desimal**: Konsisten di semua perhitungan

---

## 📊 Struktur Data Input

### 1. Nilai Komponen
```dart
Map<String, double> nilaiKomponen = {
  "aktivitas": 80.0,
  "proyek": 85.0,
  "kuis": 75.0,
  "tugas": 90.0,
  "uts": 88.0,
  "uas": 92.0
};
```

### 2. Bobot Sub-CPMK
Struktur mapping Sub-CPMK ke komponen dengan bobot masing-masing:

```dart
Map<String, Map<String, double>> subCpmkBobotMap = {
  "sub1": {
    "aktivitas": 10.0,
    "proyek": 15.0,
    "kuis": 10.0,
    "tugas": 15.0,
    "uts": 25.0,
    "uas": 25.0,
  },
  "sub2": {
    "aktivitas": 15.0,
    "proyek": 20.0,
    "kuis": 10.0,
    "tugas": 10.0,
    "uts": 20.0,
    "uas": 25.0,
  },
  "sub3": {
    "aktivitas": 0.0,   // Bobot 0 akan diabaikan
    "proyek": 30.0,
    "kuis": 20.0,
    "tugas": 0.0,
    "uts": 25.0,
    "uas": 25.0,
  },
};
```

### 3. Bobot CPMK (dari Sub-CPMK)
Mapping CPMK ke Sub-CPMK dengan total bobot:

```dart
Map<String, Map<String, double>> cpmkSubCpmkMap = {
  "cpmk1": {
    "sub1": 20.0,  // Porsi Sub-CPMK #1 dalam CPMK #1
    "sub2": 15.0,
    "sub3": 10.0,
    // Total harus > 0
  },
  "cpmk2": {
    "sub2": 25.0,
    "sub3": 20.0,
  },
};
```

### 4. Bobot CPL (dari CPMK) - Optional
Mapping CPL ke daftar CPMK yang berkontribusi:

```dart
Map<String, List<String>> cplCpmkMap = {
  "cpl1": ["cpmk1", "cpmk2"],
  "cpl2": ["cpmk2"],
};
```

---

## 🔢 STEP 1: Hitung Sub-CPMK

### Algoritma
Untuk setiap Sub-CPMK:
1. Ambil bobot komponen yang **> 0**
2. Hitung total bobot aktif
3. Normalisasi bobot: `bobot_normal = bobot / total_bobot`
4. Hitung nilai: `Σ(bobot_normal × nilai_komponen)`

### Contoh Perhitungan (Sub-CPMK #1)
```
Bobot komponen aktif (> 0):
- aktivitas: 10.0
- proyek: 15.0
- kuis: 10.0
- tugas: 15.0
- uts: 25.0
- uas: 25.0

Total bobot = 10 + 15 + 10 + 15 + 25 + 25 = 100

Normalisasi bobot:
- aktivitas: 10/100 = 0.10
- proyek: 15/100 = 0.15
- kuis: 10/100 = 0.10
- tugas: 15/100 = 0.15
- uts: 25/100 = 0.25
- uas: 25/100 = 0.25

Nilai Sub-CPMK #1:
= (0.10 × 80) + (0.15 × 85) + (0.10 × 75) + (0.15 × 90) + (0.25 × 88) + (0.25 × 92)
= 8.0 + 12.75 + 7.5 + 13.5 + 22.0 + 23.0
= 86.75
```

### Implementasi
```dart
final helper = OBECalculationHelper();

final subCpmkValues = helper.calculateSubCPMKValues(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobotMap,
);

// Output: {"sub1": 86.75, "sub2": 85.50, ...}
```

---

## 🔢 STEP 2: Hitung CPMK

### Algoritma
Untuk setiap CPMK:
1. Ambil Sub-CPMK yang **bobot > 0**
2. Hitung total bobot aktif
3. Weighted average: `Σ(nilai_sub × bobot) / total_bobot`

### Contoh Perhitungan (CPMK #1)
```
Sub-CPMK values (dari step 1):
- sub1: 86.75
- sub2: 85.50
- sub3: 84.20

CPMK #1 bobot:
- sub1: 20.0
- sub2: 15.0
- sub3: 10.0

Total bobot = 20 + 15 + 10 = 45

Nilai CPMK #1:
= (86.75 × 20 + 85.50 × 15 + 84.20 × 10) / 45
= (1735.0 + 1282.5 + 842.0) / 45
= 3859.5 / 45
= 85.77
```

### Implementasi
```dart
final cpmkValues = helper.calculateCPMKValues(
  subCpmkValues: subCpmkValues,
  cpmkSubCpmkMap: cpmkSubCpmkMap,
);

// Output: {"cpmk1": 85.77, "cpmk2": 84.65, ...}
```

---

## 🔢 STEP 3: Hitung CPL (Optional)

### Algoritma
CPL dihitung sebagai rata-rata CPMK yang berkontribusi padanya.

### Implementasi
```dart
final cplValues = helper.calculateCPLValues(
  cpmkValues: cpmkValues,
  cplCpmkMap: cplCpmkMap,
);

// Output: {"cpl1": 85.20, "cpl2": 84.65, ...}
```

---

## 🎯 COMPLETE CALCULATION (One-Shot)

Hitung semua dalam satu call tanpa perlu step-by-step:

```dart
final result = helper.calculateOBEComplete(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobotMap,
  cpmkSubCpmkMap: cpmkSubCpmkMap,
  cplCpmkMap: cplCpmkMap, // optional
);

if (result['status'] == 'success') {
  final subCpmkValues = result['sub_cpmk'] as Map<String, double>;
  final cpmkValues = result['cpmk'] as Map<String, double>;
  final cplValues = result['cpl'] as Map<String, double>;
  
  print('Sub-CPMK: $subCpmkValues');
  print('CPMK: $cpmkValues');
  print('CPL: $cplValues');
} else {
  print('Error: ${result['message']}');
}
```

### Response Format
```json
{
  "status": "success",
  "sub_cpmk": {
    "sub1": 86.75,
    "sub2": 85.50,
    "sub3": 84.20
  },
  "cpmk": {
    "cpmk1": 85.77,
    "cpmk2": 84.65
  },
  "cpl": {
    "cpl1": 85.20,
    "cpl2": 84.65
  }
}
```

---

## ⚠️ VALIDASI & ERROR HANDLING

Sistem akan throw Exception jika:

### 1. Nilai Komponen Kosong
```
❌ Nilai komponen tidak boleh kosong
```

### 2. Bobot Map Kosong
```
❌ Sub-CPMK bobot map tidak boleh kosong
```

### 3. Total Bobot Sub-CPMK = 0
```
❌ Sub-CPMK "sub1": Total bobot = 0 (harus > 0)
```

### 4. Nilai Komponen Tidak Ditemukan
```
❌ Sub-CPMK "sub1": Nilai komponen "aktivitas" tidak ditemukan
```

### 5. Sub-CPMK Tidak Ditemukan dalam Values
```
❌ CPMK "cpmk1": Sub-CPMK "sub1" tidak ditemukan dalam values
```

---

## 💾 DATABASE INTEGRATION

### Simpan Hasil Sub-CPMK
```dart
await helper.saveSubCPMKNilai(
  mahasiswaId: 123,
  subCpmkId: 1,
  nilai: 86.75,
  tahunAjaran: 2023,
);
```

### Hitung dan Simpan Semua OBE Results
```dart
final success = await helper.calculateAndSaveOBEResults(
  mahasiswaId: 123,
  matakuliahId: 456,
  tahunAjaran: 2023,
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobotMap,
  cpmkSubCpmkMap: cpmkSubCpmkMap,
);

if (success) {
  print('✅ Semua hasil disimpan ke database');
} else {
  print('❌ Gagal menyimpan hasil');
}
```

---

## 📐 Response Model

### OBECalculationResult
```dart
class OBECalculationResult {
  final bool success;           // Status perhitungan
  final String? errorMessage;   // Pesan error jika ada
  final Map<String, double> subCpmkValues;
  final Map<String, double> cpmkValues;
  final Map<String, double> cplValues;

  // Getter untuk rata-rata
  double get averageSubCPMK { ... }
  double get averageCPMK { ... }
  double get averageCPL { ... }

  // Convert ke JSON
  Map<String, dynamic> toJson() { ... }
}
```

### Factory Constructors
```dart
// Error response
final error = OBECalculationResult.error('Bobot tidak valid');

// Success response
final success = OBECalculationResult.success(
  subCpmkValues: {...},
  cpmkValues: {...},
  cplValues: {...},
);
```

---

## 🔄 Alur Implementasi di Aplikasi

### 1. Load Data dari Database
```dart
final nilaiKomponen = await loadNilaiKomponen(mahasiswaId);
final subCpmkBobotMap = await loadSubCpmkBobot(matakuliahId);
final cpmkSubCpmkMap = await loadCpmkSubCpmkMap();
final cplCpmkMap = await loadCplCpmkMap();
```

### 2. Hitung Menggunakan Helper
```dart
final helper = OBECalculationHelper(dbHelper: _dbHelper);
final result = helper.calculateOBEComplete(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobotMap,
  cpmkSubCpmkMap: cpmkSubCpmkMap,
  cplCpmkMap: cplCpmkMap,
);
```

### 3. Handle Result
```dart
if (result['status'] == 'success') {
  // Simpan ke database jika diperlukan
  // Update UI dengan hasil perhitungan
} else {
  // Tampilkan error ke user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(text: result['message']),
  );
}
```

---

## ✅ Testing Checklist

- [ ] Sub-CPMK calculation dengan validasi bobot
- [ ] CPMK calculation dengan weighted average
- [ ] CPL calculation dengan multiple mappings
- [ ] Error handling untuk missing data
- [ ] Pembulatan 2 desimal di semua hasil
- [ ] Database integration
- [ ] Complete OBE calculation end-to-end

---

## 📝 Notes

- **Pembulatan**: Semua hasil dibulatkan menggunakan formula: `(value * 100).round() / 100`
- **Bobot 0**: Komponen dengan bobot 0 akan diabaikan dari perhitungan
- **Validasi**: Semua input divalidasi sebelum perhitungan dimulai
- **Error Handling**: Gunakan try-catch untuk menangkap Exception dari fungsi perhitungan
- **Performance**: Untuk batch processing, load reference data sekali di awal untuk efisiensi

