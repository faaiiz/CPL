# 📊 Academic Calculation System - Implementation Guide

## ✅ Status: IMPLEMENTED

Semua komponen untuk menghitung Sub-CPMK, CPMK, dan CPL telah dibuat dan siap digunakan.

---

## 🏗️ Database Structure

### **1. Table: `sub_cpmk_nilai`**
Track nilai per Sub-CPMK untuk setiap mahasiswa per tahun ajaran.

```sql
CREATE TABLE sub_cpmk_nilai (
  id INTEGER PRIMARY KEY,
  mahasiswa_id INTEGER,
  sub_cpmk_id INTEGER,
  nilai REAL,                    -- Nilai tugas/kuis/proyek
  tahun_ajaran INTEGER,
  catatan TEXT,
  created_at TEXT,
  updated_at TEXT,
  UNIQUE(mahasiswa_id, sub_cpmk_id, tahun_ajaran)
)
```

**Model:** `SubCPMKNilai` (lib/models/sub_cpmk_nilai_model.dart)

**Contoh Data:**
```
Mahasiswa ID 1, Sub-CPMK ID 5, Nilai: 85, Tahun Ajaran: 2024
Mahasiswa ID 1, Sub-CPMK ID 6, Nilai: 92, Tahun Ajaran: 2024
```

---

### **2. Table: `rps_detail_sub_cpmk_bobot`**
Link antara RPS Detail (minggu) dengan Sub-CPMK dan bobotnya dalam minggu tersebut.

```sql
CREATE TABLE rps_detail_sub_cpmk_bobot (
  id INTEGER PRIMARY KEY,
  rps_detail_id INTEGER,         -- Minggu ke-X
  sub_cpmk_id INTEGER,
  bobot REAL,                     -- Bobot dalam minggu ini (%)
  created_at TEXT,
  updated_at TEXT,
  UNIQUE(rps_detail_id, sub_cpmk_id)
)
```

**Model:** `RPSDetailSubCPMKBobot` (lib/models/rps_detail_sub_cpmk_bobot_model.dart)

**Contoh Data:**
```
Minggu 1 (bobot 5%):
├── Sub-CPMK 5: 40% → kontribusi 5% × 40% = 2% ke total
├── Sub-CPMK 6: 60% → kontribusi 5% × 60% = 3% ke total

Minggu 2 (bobot 6%):
├── Sub-CPMK 6: 50% → kontribusi 6% × 50% = 3% ke total
├── Sub-CPMK 7: 50% → kontribusi 6% × 50% = 3% ke total

...dst sampai total 100% dari 16 minggu
```

---

### **3. Table: `sub_cpmk_cpmk_mapping`**
Link antara Sub-CPMK dengan CPMK-nya dan bobot kontribusi.

```sql
CREATE TABLE sub_cpmk_cpmk_mapping (
  id INTEGER PRIMARY KEY,
  sub_cpmk_id INTEGER,
  cpmk_id INTEGER,
  bobot REAL,                     -- Bobot Sub-CPMK ke CPMK (%)
  created_at TEXT,
  updated_at TEXT,
  UNIQUE(sub_cpmk_id, cpmk_id)
)
```

**Model:** `SubCPMKCPMKMapping` (lib/models/sub_cpmk_cpmk_mapping_model.dart)

**Contoh Data:**
```
Sub-CPMK 5 → CPMK 1: 50%
Sub-CPMK 5 → CPMK 2: 50%

Sub-CPMK 6 → CPMK 1: 100%

Sub-CPMK 7 → CPMK 3: 60%
Sub-CPMK 7 → CPMK 4: 40%
```

---

## 📐 Rumus Perhitungan (Final & Locked)

### **1. Nilai Sub-CPMK**
Nilai Sub-CPMK adalah nilai langsung dari tabel `sub_cpmk_nilai`.

$$\text{Nilai\_SubCPMK} = \text{nilai dari table sub\_cpmk\_nilai}$$

**Contoh:**
- Sub-CPMK 5: 85
- Sub-CPMK 6: 92

---

### **2. Nilai CPMK** 
Agregasi dari Sub-CPMK dengan weighted average berdasarkan bobot mapping.

$$\text{Nilai\_CPMK} = \frac{\sum (\text{Nilai\_SubCPMK} \times \text{bobot\_Sub\_ke\_CPMK})}{\sum \text{bobot\_Sub\_ke\_CPMK}}$$

**Contoh Perhitungan:**
```
CPMK 1 memiliki Sub-CPMK: 5 (50%) dan 6 (100%)

Nilai CPMK 1 = (85 × 0.50 + 92 × 1.00) / (0.50 + 1.00)
             = (42.5 + 92) / 1.50
             = 134.5 / 1.50
             = 89.67
```

---

### **3. Nilai Mata Kuliah** (Weighted by RPS Bobot)
Agregasi dari Sub-CPMK dengan bobot dari RPS Detail.

$$\text{Nilai\_MK} = \frac{\sum (\text{Nilai\_SubCPMK} \times \text{bobot\_minggu\_SubCPMK})}{100}$$

**Contoh Perhitungan:**
```
Mata Kuliah "Fisika Dasar" punya:

Minggu 1 (bobot 5%):
├── Sub-CPMK 5: 40% → 85 × 5% × 40% = 1.7
├── Sub-CPMK 6: 60% → 92 × 5% × 60% = 2.76

Minggu 2 (bobot 6%):
├── Sub-CPMK 6: 50% → 92 × 6% × 50% = 2.76
├── Sub-CPMK 7: 50% → 88 × 6% × 50% = 2.64

...dst

Nilai MK = (1.7 + 2.76 + 2.76 + 2.64 + ...) / 100
         = 85.5 / 100
         = 85.5
```

---

### **4. Nilai CPL** (Weighted by SKS)
Agregasi dari CPMK dengan weighted average berdasarkan SKS mata kuliah.

$$\text{Nilai\_CPL} = \frac{\sum (\text{Nilai\_MK} \times \text{SKS\_MK})}{\sum \text{SKS\_MK}}$$

**Contoh Perhitungan:**
```
CPL 1 terdiri dari CPMK dari 3 MK:

Fisika Dasar (3 SKS):
├── CPMK 1: 89.67 (dari MK ini)
├── CPMK 2: 91.2 (dari MK ini)
└── Nilai MK: (89.67 + 91.2) / 2 = 90.44

Matematika Dasar (4 SKS):
├── CPMK 1: 88.5 (dari MK ini)
├── CPMK 3: 89.0 (dari MK ini)
└── Nilai MK: (88.5 + 89.0) / 2 = 88.75

Kimia Dasar (3 SKS):
├── CPMK 1: 87.3 (dari MK ini)
└── Nilai MK: 87.3

Nilai CPL 1 = (90.44 × 3 + 88.75 × 4 + 87.3 × 3) / (3 + 4 + 3)
            = (271.32 + 355 + 261.9) / 10
            = 888.22 / 10
            = 88.82
```

---

## 🔧 Service Class: AcademicCalculationService

File: `lib/services/academic_calculation_service.dart`

### **Methods**

#### **1. calculateSubCPMKValue()**
```dart
Future<double?> calculateSubCPMKValue(
  int mahasiswaId,
  int subCpmkId,
  int tahunAjaran,
)
```
Ambil nilai Sub-CPMK dari database.

---

#### **2. calculateCPMKValue()**
```dart
Future<double?> calculateCPMKValue(
  int mahasiswaId,
  int cpmkId,
  int tahunAjaran,
)
```
Hitung nilai CPMK menggunakan rumus weighted average.

---

#### **3. calculateMatakuliahValue()**
```dart
Future<double?> calculateMatakuliahValue(
  int mahasiswaId,
  int matakuliahId,
  int tahunAjaran,
)
```
Hitung nilai mata kuliah berdasarkan bobot RPS.

---

#### **4. calculateCPLValue()**
```dart
Future<double?> calculateCPLValue(
  int mahasiswaId,
  int cplId,
  int tahunAjaran,
)
```
Hitung nilai CPL menggunakan weighted average SKS.

---

#### **5. generateStudentReport()**
```dart
Future<Map<String, dynamic>> generateStudentReport(
  int mahasiswaId,
  int tahunAjaran,
)
```
Generate laporan lengkap untuk satu mahasiswa dengan:
- Semua nilai Sub-CPMK
- Semua nilai CPMK
- Semua nilai CPL
- Summary average

---

#### **6. checkDataCompleteness()**
```dart
Future<Map<String, dynamic>> checkDataCompleteness(
  int mahasiswaId,
  int tahunAjaran,
)
```
Check apakah semua data lengkap untuk kalkulasi:
- ✓ Mahasiswa ada
- ✓ Nilai Sub-CPMK ada
- ✓ Mapping Sub-CPMK → CPMK ada
- ✓ Mapping CPMK → CPL ada

---

## 💾 Database Operations (CRUD)

### **Sub-CPMK Nilai**
```dart
// Insert
await dbHelper.insertSubCPMKNilai(nilai);

// Query
var nilai = await dbHelper.getSubCPMKNilai(mahasiswaId, subCpmkId, tahunAjaran);
var nilaiList = await dbHelper.getSubCPMKNilaiByMahasiswa(mahasiswaId, tahunAjaran);

// Update
await dbHelper.updateSubCPMKNilai(nilai);

// Delete
await dbHelper.deleteSubCPMKNilai(id);
```

### **RPS Detail Sub-CPMK Bobot**
```dart
// Insert
await dbHelper.insertRPSDetailSubCPMKBobot(bobot);

// Query
var bobotList = await dbHelper.getRPSDetailSubCPMKBobot(rpsDetailId);
var bobot = await dbHelper.getRPSDetailSubCPMKBobotSingle(rpsDetailId, subCpmkId);

// Update
await dbHelper.updateRPSDetailSubCPMKBobot(bobot);

// Delete
await dbHelper.deleteRPSDetailSubCPMKBobot(id);
await dbHelper.deleteRPSDetailSubCPMKBobotByRPSDetail(rpsDetailId);
```

### **Sub-CPMK CPMK Mapping**
```dart
// Insert
await dbHelper.insertSubCPMKCPMKMapping(mapping);

// Query
var mappingList = await dbHelper.getSubCPMKCPMKMapping(subCpmkId);
var mappingList = await dbHelper.getCPMKSubCPMKMapping(cpmkId);
var mapping = await dbHelper.getSubCPMKCPMKMappingSingle(subCpmkId, cpmkId);

// Update
await dbHelper.updateSubCPMKCPMKMapping(mapping);

// Delete
await dbHelper.deleteSubCPMKCPMKMapping(id);
```

---

## 📚 How to Use

### **1. Input Nilai Sub-CPMK**
```dart
final calculation = AcademicCalculationService();

// Mahasiswa 1 input nilai Sub-CPMK 5 = 85 untuk tahun 2024
final nilaiData = SubCPMKNilai(
  mahasiswaId: 1,
  subCpmkId: 5,
  nilai: 85,
  tahunAjaran: 2024,
  createdAt: DateTime.now(),
);
await dbHelper.insertSubCPMKNilai(nilaiData);
```

### **2. Setup Bobot RPS (Per Minggu)**
```dart
// Minggu 1 terdiri dari Sub-CPMK 5 (40%) dan 6 (60%)
final bobot1 = RPSDetailSubCPMKBobot(
  rpsDetailId: 1,  // RPS Detail minggu 1
  subCpmkId: 5,
  bobot: 40,  // 40% dari bobot minggu 1 yang 5%
  createdAt: DateTime.now(),
);
await dbHelper.insertRPSDetailSubCPMKBobot(bobot1);

final bobot2 = RPSDetailSubCPMKBobot(
  rpsDetailId: 1,
  subCpmkId: 6,
  bobot: 60,  // 60% dari bobot minggu 1 yang 5%
  createdAt: DateTime.now(),
);
await dbHelper.insertRPSDetailSubCPMKBobot(bobot2);
```

### **3. Setup Mapping Sub-CPMK → CPMK**
```dart
// Sub-CPMK 5 berkontribusi 50% ke CPMK 1
final mapping1 = SubCPMKCPMKMapping(
  subCpmkId: 5,
  cpmkId: 1,
  bobot: 50,
  createdAt: DateTime.now(),
);
await dbHelper.insertSubCPMKCPMKMapping(mapping1);

// Sub-CPMK 5 berkontribusi 50% ke CPMK 2
final mapping2 = SubCPMKCPMKMapping(
  subCpmkId: 5,
  cpmkId: 2,
  bobot: 50,
  createdAt: DateTime.now(),
);
await dbHelper.insertSubCPMKCPMKMapping(mapping2);
```

### **4. Hitung Nilai CPMK**
```dart
final service = AcademicCalculationService();
final nilaiCPMK = await service.calculateCPMKValue(
  mahasiswaId: 1,
  cpmkId: 1,
  tahunAjaran: 2024,
);
print('Nilai CPMK 1: $nilaiCPMK');  // Output: 89.67
```

### **5. Generate Laporan Mahasiswa**
```dart
final service = AcademicCalculationService();
final report = await service.generateStudentReport(
  mahasiswaId: 1,
  tahunAjaran: 2024,
);

print('Sub-CPMK: ${report['subCPMK']}');  // Daftar nilai Sub-CPMK
print('CPMK: ${report['cpmk']}');          // Daftar nilai CPMK
print('CPL: ${report['cpl']}');            // Daftar nilai CPL
print('Summary: ${report['summary']}');    // Average CPMK & CPL
```

### **6. Check Data Completeness**
```dart
final service = AcademicCalculationService();
final completeness = await service.checkDataCompleteness(
  mahasiswaId: 1,
  tahunAjaran: 2024,
);

if (!completeness['subCPMK']) {
  print('❌ Nilai Sub-CPMK belum ada');
}
if (!completeness['cpmk']) {
  print('❌ Mapping Sub-CPMK ke CPMK belum lengkap');
}
if (!completeness['cpl']) {
  print('❌ Mapping CPMK ke CPL belum lengkap');
}
```

---

## ⚠️ Important Notes

1. **Bobot RPS harus total 100%** dari 16 minggu:
   - Minggu 1-16 memiliki bobot masing-masing
   - Total = 100%
   - Contoh: 5% + 6% + 5% + ... + 4% = 100%

2. **Bobot Sub-CPMK dalam satu minggu harus 100%**:
   - Jika minggu 1 punya Sub-CPMK 5 (40%) dan 6 (60%)
   - Total = 40% + 60% = 100%

3. **Mapping Sub-CPMK → CPMK tidak harus 100%**:
   - Satu Sub-CPMK bisa berkontribusi ke multiple CPMK
   - Contoh: Sub-CPMK 5 → CPMK 1 (50%) + CPMK 2 (50%) = 100%
   - Atau Sub-CPMK 5 → CPMK 1 (100%)

4. **Error Handling**:
   - Service mengembalikan `null` jika data tidak lengkap
   - Check `completeness` sebelum generate report

5. **Performance**:
   - Service menggunakan async/await
   - Tidak lock UI saat perhitungan
   - Cache data untuk mengurangi database queries

---

## 📊 Example Output

### Student Report
```json
{
  "mahasiswa": {
    "id": 1,
    "nim": "123456",
    "nama": "Ahmad Rizki"
  },
  "tahunAjaran": 2024,
  "subCPMK": [
    {"id": 5, "nilai": 85},
    {"id": 6, "nilai": 92},
    {"id": 7, "nilai": 88}
  ],
  "cpmk": [
    {"id": 1, "kode": "CPM.1", "nilai": 89.67},
    {"id": 2, "kode": "CPM.2", "nilai": 91.2},
    {"id": 3, "kode": "CPM.3", "nilai": 87.8}
  ],
  "cpl": [
    {"id": 1, "kode": "CPL.1", "nilai": 88.82},
    {"id": 2, "kode": "CPL.2", "nilai": 89.5}
  ],
  "summary": {
    "averageCPMK": 89.56,
    "averageCPL": 89.16
  }
}
```

---

## 🚀 Status: Ready for Integration

Semua komponen siap untuk:
✅ Integrasi ke screen UI untuk input bobot  
✅ Integrasi ke screen UI untuk view laporan  
✅ Testing dengan data real dari database  
✅ Export hasil perhitungan ke PDF/Excel  

**No breaking changes. All methods follow the locked formulas without modification.**
