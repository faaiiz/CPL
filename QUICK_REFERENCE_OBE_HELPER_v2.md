# 🚀 QUICK REFERENCE - OBE CALCULATION HELPER v2

**Dokumentasi ringkas untuk penggunaan cepat OBECalculationHelper**

---

## 📥 Import
```dart
import 'package:cpl/services/obe_calculation_helper.dart';
```

---

## 🎯 ONE-LINER USAGE (Paling Umum)

```dart
final helper = OBECalculationHelper();

// INPUT DATA
final nilaiKomponen = {
  'aktivitas': 80.0, 'proyek': 85.0, 'kuis': 75.0,
  'tugas': 90.0, 'uts': 88.0, 'uas': 92.0,
};

final subCpmkBobot = {
  'sub1': {'aktivitas': 10, 'proyek': 15, 'kuis': 10, 'tugas': 15, 'uts': 25, 'uas': 25},
  'sub2': {'aktivitas': 15, 'proyek': 20, 'kuis': 10, 'tugas': 10, 'uts': 20, 'uas': 25},
};

final cpmkBobot = {
  'cpmk1': {'sub1': 20, 'sub2': 15},
};

// HITUNG
final result = helper.calculateOBEComplete(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobot,
  cpmkSubCpmkMap: cpmkBobot,
);

// HASIL
if (result['status'] == 'success') {
  print('Sub-CPMK: ${result['sub_cpmk']}');
  print('CPMK: ${result['cpmk']}');
}
```

---

## 🔢 STEP-BY-STEP MANUAL

### Step 1: Sub-CPMK
```dart
final subCpmkValues = helper.calculateSubCPMKValues(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobot,
);
// Output: {"sub1": 86.75, "sub2": 85.50, ...}
```

### Step 2: CPMK
```dart
final cpmkValues = helper.calculateCPMKValues(
  subCpmkValues: subCpmkValues,
  cpmkSubCpmkMap: cpmkBobot,
);
// Output: {"cpmk1": 85.77, ...}
```

### Step 3: CPL (Optional)
```dart
final cplValues = helper.calculateCPLValues(
  cpmkValues: cpmkValues,
  cplCpmkMap: {'cpl1': ['cpmk1', 'cpmk2']},
);
// Output: {"cpl1": 85.20, ...}
```

---

## 💾 SIMPAN KE DATABASE

### Metode 1: Simpan Sub-CPMK Saja
```dart
await helper.saveSubCPMKNilai(
  mahasiswaId: 123,
  subCpmkId: 1,
  nilai: 86.75,
  tahunAjaran: 2023,
);
```

### Metode 2: Hitung + Simpan Semua
```dart
final success = await helper.calculateAndSaveOBEResults(
  mahasiswaId: 123,
  matakuliahId: 456,
  tahunAjaran: 2023,
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobot,
  cpmkSubCpmkMap: cpmkBobot,
);
```

---

## ⚠️ ERROR HANDLING

```dart
try {
  final result = helper.calculateOBEComplete(...);
  
  if (result['status'] == 'success') {
    // SUCCESS
    final subCpmk = result['sub_cpmk'] as Map<String, double>;
  } else {
    // ERROR
    print('Error: ${result['message']}');
  }
} catch (e) {
  // VALIDATION FAILED
  print('Exception: $e');
}
```

### Common Errors
```
❌ "Nilai komponen tidak boleh kosong"
   → Pastikan nilaiKomponen tidak empty

❌ "Total bobot = 0"
   → Minimal satu bobot per Sub-CPMK harus > 0

❌ "Nilai komponen X tidak ditemukan"
   → Key 'X' tidak ada di nilaiKomponen

❌ "Sub-CPMK Y tidak ditemukan dalam values"
   → Sub-CPMK 'Y' tidak ada di hasil Sub-CPMK calculation
```

---

## 📊 DATA FORMAT

### Nilai Komponen (0-100 scale)
```dart
Map<String, double> {
  "aktivitas": 80.0,      // Kehadiran & partisipasi
  "proyek": 85.0,         // Hasil proyek kelompok
  "kuis": 75.0,           // Tes singkat
  "tugas": 90.0,          // Tugas individu
  "uts": 88.0,            // Ujian Tengah Semester
  "uas": 92.0,            // Ujian Akhir Semester
}
```

### Sub-CPMK Bobot
```dart
Map<String, Map<String, double>> {
  "sub1": {
    "aktivitas": 10.0,    // Bobot komponen di Sub-CPMK #1
    "proyek": 15.0,
    "kuis": 10.0,
    "tugas": 15.0,
    "uts": 25.0,
    "uas": 25.0,          // Total = 100
  },
}
```

### CPMK Bobot (dari Sub-CPMK)
```dart
Map<String, Map<String, double>> {
  "cpmk1": {
    "sub1": 20.0,         // Bobot Sub-CPMK #1 dalam CPMK #1
    "sub2": 15.0,
    "sub3": 10.0,         // Total tidak harus 100
  },
}
```

### CPL Mapping (dari CPMK)
```dart
Map<String, List<String>> {
  "cpl1": ["cpmk1", "cpmk2"],    // CPMK yang contribute ke CPL #1
  "cpl2": ["cpmk2", "cpmk3"],
}
```

---

## 📈 INTERPRETASI HASIL

```
Sub-CPMK (86.75):
  ├─ Minimum level: 0
  ├─ Maximum level: 100
  ├─ Meaning: Penguasaan Learning Outcome khusus
  └─ Usage: Basis untuk CPMK

CPMK (85.77):
  ├─ Minimum level: 0
  ├─ Maximum level: 100
  ├─ Meaning: Penguasaan Course Learning Outcome
  └─ Usage: Basis untuk CPL atau Grading

CPL (85.20):
  ├─ Minimum level: 0
  ├─ Maximum level: 100
  ├─ Meaning: Penguasaan Program Learning Outcome
  └─ Usage: Akkreditasi & Program Evaluation
```

---

## 🔄 BATCH PROCESSING

```dart
// Loop manual untuk banyak mahasiswa
final students = await db.getStudents();

for (final student in students) {
  // Load data per mahasiswa
  final nilai = await db.getNilaiKomponen(student.id);
  
  // Calculate
  final result = helper.calculateOBEComplete(
    nilaiKomponen: nilai,
    subCpmkBobotMap: subCpmkBobot,
    cpmkSubCpmkMap: cpmkBobot,
  );
  
  // Save jika success
  if (result['status'] == 'success') {
    await db.saveResults(student.id, result);
  }
}
```

---

## ✅ VALIDASI CHECKLIST

Sebelum calculate:
- [ ] Semua nilai komponen tersedia (6 komponen)
- [ ] Minimal satu bobot > 0 per Sub-CPMK
- [ ] Bobot komponen dalam Sub-CPMK > 0
- [ ] Sub-CPMK yang direfer di CPMK ada di nilai
- [ ] Mahasiswa memiliki nilai untuk semua komponen

---

## 🎲 CONTOH REAL-WORLD

### Case 1: Mata Kuliah dengan 3 Sub-CPMK
```dart
// Input
final nilaiKomponen = {
  'aktivitas': 85, 'proyek': 90, 'kuis': 80,
  'tugas': 88, 'uts': 87, 'uas': 91,
};

final subCpmkBobot = {
  'sub1': {'aktivitas': 20, 'proyek': 30, 'kuis': 20, 'tugas': 30, 'uts': 0, 'uas': 0},
  'sub2': {'aktivitas': 10, 'proyek': 20, 'kuis': 0, 'tugas': 0, 'uts': 35, 'uas': 35},
  'sub3': {'aktivitas': 0, 'proyek': 10, 'kuis': 15, 'tugas': 25, 'uts': 25, 'uas': 25},
};

final cpmkBobot = {
  'cpmk_umum': {'sub1': 30, 'sub2': 30, 'sub3': 40},
};

// Calculate
final result = helper.calculateOBEComplete(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobot,
  cpmkSubCpmkMap: cpmkBobot,
);

// Result
// sub1: (0.267×85)+(0.4×90)+(0.267×80)+(0.4×88) = 87.47
// sub2: (0.143×85)+(0.286×90)+(0.5×87)+(0.5×91) = 88.57
// sub3: (0.1×90)+(0.15×80)+(0.25×88)+(0.25×91) = 88.57
// cpmk_umum: (0.3×87.47)+(0.3×88.57)+(0.4×88.57) = 88.28
```

---

## 🛠️ DEBUGGING TIPS

### Debug Sub-CPMK Calculation
```dart
final helper = OBECalculationHelper();

// Test dengan simple data
final test = helper.calculateSubCPMKValues(
  nilaiKomponen: {'aktivitas': 80, 'proyek': 90},
  subCpmkBobotMap: {
    'test': {'aktivitas': 50, 'proyek': 50},
  },
);
// Expected: test = 85 (simple average)

// Test dengan bobot 0
final test2 = helper.calculateSubCPMKValues(
  nilaiKomponen: {'aktivitas': 80, 'proyek': 90, 'kuis': 70},
  subCpmkBobotMap: {
    'test': {'aktivitas': 50, 'proyek': 50, 'kuis': 0},
  },
);
// Expected: test = 85 (kuis ignored)
```

### Print Intermediate Values
```dart
final subCpmk = helper.calculateSubCPMKValues(...);
print('Sub-CPMK: $subCpmk');

final cpmk = helper.calculateCPMKValues(
  subCpmkValues: subCpmk,
  cpmkSubCpmkMap: cpmkBobot,
);
print('CPMK: $cpmk');
```

---

## 📱 UI INTEGRATION EXAMPLE

```dart
// Stateful Widget
class OBECalculationScreen extends StatefulWidget {
  @override
  _OBECalculationScreenState createState() => _OBECalculationScreenState();
}

class _OBECalculationScreenState extends State<OBECalculationScreen> {
  final helper = OBECalculationHelper();
  Map<String, dynamic>? result;
  String? error;

  void _calculateOBE() {
    try {
      final result = helper.calculateOBEComplete(
        nilaiKomponen: getNilaiKomponen(),
        subCpmkBobotMap: getSubCpmkBobot(),
        cpmkSubCpmkMap: getCpmkBobot(),
      );

      setState(() {
        if (result['status'] == 'success') {
          this.result = result;
          this.error = null;
        } else {
          this.error = result['message'];
          this.result = null;
        }
      });
    } catch (e) {
      setState(() {
        this.error = e.toString();
        this.result = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _calculateOBE,
            child: Text('Hitung OBE'),
          ),
          if (error != null) Text('Error: $error'),
          if (result != null) ...[
            Text('Sub-CPMK: ${result!['sub_cpmk']}'),
            Text('CPMK: ${result!['cpmk']}'),
          ],
        ],
      ),
    );
  }
}
```

---

## 📚 DOKUMENTASI LENGKAP

- `PANDUAN_OBE_CALCULATION_v2.md` - Dokumentasi detail
- `obe_calculation_helper_examples.dart` - Contoh kode lengkap
- `PERBANDINGAN_LAMA_VS_BARU.md` - Perbedaan versi old vs new

---

## ⚡ Performance Notes

- **Sync Execution**: Tidak perlu async/await, langsung hasil
- **No Cache**: Tidak ada overhead caching
- **Scalable**: 1 mahasiswa atau 1000 mahasiswa sama performa
- **Memory**: Minimal memory footprint

---

## 🎓 Learning Path

1. **Beginner**: Baca Quick Reference ini
2. **Intermediate**: Pelajari contoh di `obe_calculation_helper_examples.dart`
3. **Advanced**: Baca pemula detail di `PANDUAN_OBE_CALCULATION_v2.md`
4. **Expert**: Explore source code di `obe_calculation_helper.dart`

