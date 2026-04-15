# 📊 PANDUAN LENGKAP: RPS Input → Database → Perhitungan → Display

## 🎯 Ringkasan Singkat

```
USER INPUT RPS
    ↓
SAVE TO DATABASE (rps_detail, rps_detail_sub_cpmk_bobot)
    ↓
GET DATA FROM DATABASE (dalam Admin Dashboard)
    ↓
CALCULATE CPMK & CPL (menggunakan OBE Calculator)
    ↓
DISPLAY IN TABLE (dengan nilai actual, bukan "-")
```

---

## 📝 FASE 1: INPUT RPS (User Interface)

### Lokasi Screen
**File:** `lib/screens/rps_input_screen.dart`

### Cara Kerja Input

#### 1️⃣ **User memilih Mata Kuliah**
```dart
// User melihat list mata kuliah
// Contoh: Kalkulus & Vektor
```

#### 2️⃣ **User klik "Input RPS" untuk matakuliah**
```dart
// Dialog muncul dengan 16 minggu (week 1-16)
// Untuk setiap minggu, user bisa:
// - Isi topik pembelajaran
// - Pilih metode ajar (Case Based Learning, dll)
// - Input bobot (0-100%)
// - Pilih CPMK (dari database)
// - Pilih Sub-CPMK (dari database)
// - Pilih CPL (dari database)
// - Pilih jenis penilaian (Aktivitas, Proyek, Kuis, Tugas, UTS, UAS)
```

#### 3️⃣ **Untuk UTS/UAS (minggu 8 & 16), user input bobot per Sub-CPMK**
```dart
// Dialog khusus menampilkan tabel:
// ┌─────────────┬──────────┐
// │ Sub-CPMK    │ Bobot    │
// ├─────────────┼──────────┤
// │ SUB-1       │ [input]  │
// │ SUB-2       │ [input]  │
// │ SUB-3       │ [input]  │
// │ ...         │ ...      │
// └─────────────┴──────────┘
// Total harus = 100%
```

#### 4️⃣ **User klik "Simpan"**
```dart
// Data disimpan ke database
// - Jika edit existing → UPDATE rps_detail
// - Jika baru → INSERT rps_detail
// - Jika UTS/UAS & ada bobot per SubCPMK → INSERT ke rps_detail_sub_cpmk_bobot
```

---

## 💾 FASE 2: DATABASE STRUCTURE & STORAGE

### Database Schema

#### **Tabel 1: rps_detail** (Utama)
```sql
CREATE TABLE rps_detail (
  id INTEGER PRIMARY KEY,
  matakuliah_id INTEGER,        -- FK ke mata kuliah
  minggu_ke INTEGER,            -- Minggu 1-16
  topik TEXT,                   -- Topik pembelajaran
  metode_ajar TEXT,             -- Case Based Learning, dll
  jenis_nilai TEXT,             -- Assessment type
  bobot REAL,                   -- 0-100% (total per MK = 100%)
  cpmk_ids TEXT,                -- JSON: [1]  (usually 1 CPMK)
  sub_cpmk_ids TEXT,            -- JSON: [1,2,3,4,5,6,7]
  cpl_ids TEXT,                 -- JSON: [1,2,3,4]
  created_at TEXT,
  updated_at TEXT
);
```

**Contoh Data untuk Kalkulus (16 minggu):**
```
minggu_ke=1:  topik="Bilangan Real", bobot=5, cpmk_ids=[1], sub_cpmk_ids=[1,2], cpl_ids=[1,2]
minggu_ke=2:  topik="Bilangan Kompleks", bobot=5, cpmk_ids=[1], sub_cpmk_ids=[2,3], cpl_ids=[2,3]
...
minggu_ke=8:  topik="UTS", bobot=15, cpmk_ids=[1], sub_cpmk_ids=[1,2,3,4,5,6,7], cpl_ids=[1,2,3,4]
minggu_ke=16: topik="UAS", bobot=15, cpmk_ids=[1], sub_cpmk_ids=[1,2,3,4,5,6,7], cpl_ids=[1,2,3,4]

Total bobot = 5+5+5+5+5+5+5+5+15 + ... = 100%
```

#### **Tabel 2: rps_detail_sub_cpmk_bobot** (Bobot per Minggu/Assessment)
```sql
CREATE TABLE rps_detail_sub_cpmk_bobot (
  id INTEGER PRIMARY KEY,
  rps_detail_id INTEGER,   -- FK ke rps_detail
  sub_cpmk_id INTEGER,     -- Sub-CPMK ID
  bobot REAL,              -- Bobot dalam RPS detail ini (%)
  created_at TEXT,
  updated_at TEXT
);
```

**Contoh Data untuk UTS Minggu 8 (Kalkulus):**
```
rps_detail_id=8, sub_cpmk_id=1, bobot=15  (Sub-CPMK 1 dapat 15% dari minggu 8)
rps_detail_id=8, sub_cpmk_id=2, bobot=15
rps_detail_id=8, sub_cpmk_id=3, bobot=15
rps_detail_id=8, sub_cpmk_id=4, bobot=9
rps_detail_id=8, sub_cpmk_id=5, bobot=14
rps_detail_id=8, sub_cpmk_id=6, bobot=14
rps_detail_id=8, sub_cpmk_id=7, bobot=18
Total = 100%
```

### Data Flow Saat Input

```
┌────────────────────────────────┐
│ User Klik "Simpan"             │
└────────────────────────────────┘
            ↓
┌────────────────────────────────┐
│ Validasi Data:                 │
│ ✓ Topik ada (jika bukan UTS)   │
│ ✓ Bobot 0-100                  │
│ ✓ Total bobot <= 100%          │
└────────────────────────────────┘
            ↓
┌────────────────────────────────┐
│ Simpan ke Database:            │
│ • INSERT/UPDATE rps_detail     │
│ • INSERT rps_detail_sub_cpmk_b │
└────────────────────────────────┘
            ↓
┌────────────────────────────────┐
│ Refresh Cache & UI:            │
│ _rpsCache.remove(mkId)         │
│ setState() → rebuild           │
└────────────────────────────────┘
```

---

## 🧮 FASE 3: PERHITUNGAN CPMK & CPL

### Alur Perhitungan (3 Tingkat)

```
NILAI KOMPONEN (6 values)
  [aktivitas, proyek, kuis, tugas, uts, uas]
        ↓
        └─→ Weighted by: bobot_matrix dari RPS
                ↓
        SUB-CPMK (7 values)
        [sub1, sub2, sub3, sub4, sub5, sub6, sub7]
                ↓
        └─→ Weighted by: bobot per Sub-CPMK = 100%
                ↓
        CPMK (1 value, karena 1 MK = 1 CPMK)
        [cpmk1]
                ↓
        └─→ Distributed by: RPS minggu bobot ke CPL
                ↓
        CPL (N values)
        [cpl1, cpl2, cpl3, cpl4, ...]
```

### Calculation Logic (Ada di OBECalculationHelper)

#### **Step 1: Sub-CPMK = Weighted Avg Nilai Komponen**

```dart
// INPUT:
// nilaiKomponen = [85, 85, 85, 85, 65, 75]  ← nilai student
// bobotMatrix dari RPS:
//   Sub1: [5, 0, 0, 5, 5, 0]  ← bobot dari rps_detail_sub_cpmk_bobot
//   Sub2: [0, 5, 5, 0, 5, 0]
//   ...
//   Sub7: [5, 0, 5, 5, 0, 3]

// ALGORITHM:
Sub1 = (85*5 + 85*0 + 85*0 + 85*5 + 65*5 + 75*0) / (5+0+0+5+5+0)
     = (425 + 0 + 0 + 425 + 325 + 0) / 15
     = 1175 / 15
     = 78.33

Sub2 = (85*0 + 85*5 + 85*5 + 85*0 + 65*5 + 75*0) / (0+5+5+0+5+0)
     = (0 + 425 + 425 + 0 + 325 + 0) / 15
     = 1175 / 15
     = 78.33

... (similarly for Sub3-7)

// OUTPUT:
// subCpmkValues = {1: 78.33, 2: 78.33, 3: 78.33, 4: 88.61, 5: 88.21, 6: 88.21, 7: 87.92}
```

#### **Step 2: CPMK = Weighted Avg Sub-CPMK**

```dart
// INPUT:
// subCpmkValues = {1: 78.33, 2: 78.33, 3: 78.33, 4: 88.61, 5: 88.21, 6: 88.21, 7: 87.92}
// bobotPerSubCpmk (dari RPS minggu atau database):
//   CPMK1: {sub1: 15, sub2: 15, sub3: 15, sub4: 9, sub5: 14, sub6: 14, sub7: 18}
//   Total = 100%

// ALGORITHM:
CPMK1 = (78.33*15 + 78.33*15 + 78.33*15 + 88.61*9 + 88.21*14 + 88.21*14 + 87.92*18) / 100
      = (1175 + 1175 + 1175 + 797 + 1235 + 1235 + 1582) / 100
      = 8374 / 100
      = 83.74

// OUTPUT:
// cpmkValues = {1: 83.74}  ← CPMK untuk mata kuliah ini
```

#### **Step 3: CPL = Distributed from CPMK using RPS minggu bobot**

```dart
// INPUT:
// cpmkValues = {1: 83.74}
// RPS minggu data (aggregated):
//   minggu 1-4 (5% each) → CPL 1,2     = 20% total
//   minggu 5-8 (5% each) → CPL 2,3     = 20% total
//   minggu 9-16 (5% each) → CPL 1,3    = 40% total
//   Total CPL bobot: CPL1=60%, CPL2=40%, CPL3=60%
//   Normalized: CPL1=42%, CPL2=28%, CPL3=42%, ...

// ALGORITHM:
CPL1 = 83.74 × (bobot_normalized_cpl1)
CPL2 = 83.74 × (bobot_normalized_cpl2)
CPL3 = 83.74 × (bobot_normalized_cpl3)
...

// OUTPUT:
// cplValues = {1: 35.2, 2: 23.4, 3: 35.2, ...}  ← CPL values
```

### Calculation Flow dalam Kode

```
admin_dashboard_screen.dart (_calculateCPLFromTable)
    ↓
[Step 1] Get all nilai_komponen students
    ↓
[Step 2] Get RPS details & bobot matrix
    ↓
[Step 3] For each student:
    • Parse nilai_komponen row
    • Call calculateSubCPMKValues()     ← Step 1
    • Call calculateCPMKValues()        ← Step 2
    • Call calculateCPLValues()         ← Step 3
    • Store result in OBECalculationResult
    ↓
[Step 4] Return List<OBECalculationResult>
    ↓
[Step 5] Build table from results
```

---

## 📊 FASE 4: DISPLAY IN TABLES

### Admin Dashboard Display Flow

#### **Lokasi Screen**
**File:** `lib/screens/admin_dashboard_screen.dart`

#### **Tabel 1: Tabel Nilai CPMK & CPL** (Main Table)

```
┌────┬──────────────┬────────────────┬────────┬────────┐
│ No │ NIM          │ Nama Mahasiswa │ CPMK.1 │ CPL.1  │
├────┼──────────────┼────────────────┼────────┼────────┤
│ 1  │ 2440012140XX │ VITA JUWITA... │ 83.74  │ 35.25  │
│ 2  │ 2440012140XX │ VIRA INDRA...  │ 80.84  │ 34.02  │
│ 3  │ 2440012140XX │ APRIDA ICH...  │   -    │   -    │
└────┴──────────────┴────────────────┴────────┴────────┘
```

**Kode Build Tabel:**
```dart
Widget _buildCombinedCPMKCPLTable(List<OBECalculationResult> results) {
  // 1. Extract unique CPMK IDs
  final cpmkIds = <int>{};
  for (final result in results) {
    cpmkIds.addAll(result.cPMKValues.keys);  // ✅ Use legacy getter
  }
  
  // 2. Extract unique CPL IDs
  final cplIds = <int>{};
  for (final result in results) {
    cplIds.addAll(result.cPLValues.keys);    // ✅ Use legacy getter
  }
  
  // 3. Build rows for each student
  final rows = List.generate(results.length, (index) {
    final result = results[index];
    
    // For each CPMK ID
    for (final cpmkId in cpmkIds) {
      final value = result.cPMKValues[cpmkId];  // ✅ Correct getter
      cells.add(DataCell(
        Text(value != null ? value.toStringAsFixed(2) : '-')
      ));
    }
    
    // For each CPL ID
    for (final cplId in cplIds) {
      final value = result.cPLValues[cplId];    // ✅ Correct getter
      cells.add(DataCell(
        Text(value != null ? value.toStringAsFixed(2) : '-')
      ));
    }
    
    return DataRow(cells: cells);
  });
  
  // 4. Render DataTable
  return DataTable(columns: columns, rows: rows);
}
```

#### **Tabel 2: Ringkasan Nilai** (Summary Cards)

```
┌─────────────────────────────┬─────────────────────────────┐
│ 🎓 Rata-rata CPMK           │ 🚩 Rata-rata CPL            │
│ 82.29 (dari 158 mahasiswa)  │ 35.10 (dari 158 mahasiswa)  │
└─────────────────────────────┴─────────────────────────────┘
```

**Kode:**
```dart
Widget _buildSummaryCard() {
  return Row(
    children: [
      Card(
        child: Text('Rata-rata CPMK: ${_calculationResult.averageCPMK}')
      ),
      Card(
        child: Text('Rata-rata CPL: ${_calculationResult.averageCPL}')
      ),
    ],
  );
}
```

---

## 🔄 COMPLETE WORKFLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER (ADMIN)                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1️⃣ Klik "Input RPS"                                            │
│     ↓                                                           │
│  2️⃣ List 16 minggu                                              │
│     ↓                                                           │
│  3️⃣ Klik minggu → Dialog input                                  │
│     • Topik                                                     │
│     • Metode ajar                                              │
│     • Bobot (0-100%)                                           │
│     • Pilih CPMK/SubCPMK/CPL                                   │
│     • Jenis penilaian                                          │
│     ↓                                                           │
│  4️⃣ Klik "Simpan"                                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                       DATABASE                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  rps_detail:                                                    │
│  ├─ minggu_ke, topik, metode_ajar, bobot, cpmk_ids,           │
│  │  sub_cpmk_ids, cpl_ids, jenis_nilai, created_at           │
│  │  (16 rows per mata kuliah)                                  │
│  │                                                             │
│  rps_detail_sub_cpmk_bobot:                                     │
│  ├─ rps_detail_id, sub_cpmk_id, bobot (untuk UTS/UAS)         │
│  │  (7 rows × 2 assessment = 14 rows per mata kuliah)         │
│  │                                                             │
│  nilai_komponen:                                               │
│  ├─ mahasiswa_id, matakuliah_id, nilai_aktivitas,            │
│  │  nilai_proyek, nilai_kuis, nilai_tugas, nilai_uts,        │
│  │  nilai_uas                                                  │
│  │  (1 row per student per mata kuliah)                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    CALCULATION ENGINE                           │
│                  (OBECalculationHelper)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  For each student:                                              │
│                                                                 │
│  1️⃣ Get nilai_komponen from DB                                 │
│     [aktivitas, proyek, kuis, tugas, uts, uas]                │
│                                                                 │
│  2️⃣ Get bobot_matrix from getBobotMatrixForMatakuliah()        │
│     Sub1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0]                      │
│     Sub2: [0.0, 5.0, 5.0, 0.0, 5.0, 0.0]                      │
│     ...                                                         │
│                                                                 │
│  3️⃣ STEP 1: Hitung Sub-CPMK (weighted avg komponen)           │
│     Sub1 = (nilai × bobot) / total_bobot                       │
│     → {1: 78.33, 2: 78.33, 3: 78.33, ...}                     │
│                                                                 │
│  4️⃣ STEP 2: Hitung CPMK (weighted avg Sub-CPMK)               │
│     CPMK1 = (Sub × bobot) / 100%                               │
│     → {1: 83.74}                                               │
│                                                                 │
│  5️⃣ STEP 3: Hitung CPL (distribute from CPMK)                 │
│     CPL1 = CPMK × (bobot_cpl1 / total)                         │
│     → {1: 35.25, 2: 24.15, 3: 35.25, ...}                     │
│                                                                 │
│  6️⃣ Return OBECalculationResult:                               │
│     {                                                          │
│       subCpmkValues: {1: 78.33, ...},                          │
│       cpmkValues: {1: 83.74},                   ← KEY!         │
│       cplValues: {1: 35.25, ...}                ← KEY!         │
│     }                                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                        DISPLAY TABLE                            │
│                   (Admin Dashboard)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1️⃣ Extract CPMK keys dari semua results                       │
│     cpmkIds = [1] (biasanya hanya 1 per mata kuliah)          │
│                                                                 │
│  2️⃣ Extract CPL keys dari semua results                        │
│     cplIds = [1, 2, 3, 4]                                      │
│                                                                 │
│  3️⃣ For each student result:                                   │
│     • Get CPMK.1 value: result.cPMKValues[1] = 83.74          │
│     • Get CPL.1 value: result.cPLValues[1] = 35.25            │
│     → Add to table row                                         │
│                                                                 │
│  4️⃣ Render DataTable:                                          │
│     ┌────┬───────┬────────┬────────┬────────┐                 │
│     │ No │  NIM  │ Nama   │ CPMK.1 │ CPL.1  │                │
│     ├────┼───────┼────────┼────────┼────────┤                │
│     │ 1  │ 244.. │ Vita   │ 83.74  │ 35.25  │                │
│     │ 2  │ 244.. │ Vira   │ 80.84  │ 33.99  │                │
│     └────┴───────┴────────┴────────┴────────┘                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🐛 DEBUGGING: Kenapa Tabel Menunjukkan "-" ?

### ❌ MASALAH: Tabel Menampilkan Dash ("-") Instead of Values

**Root Cause:** Key type mismatch

```dart
// ❌ WRONG:
cpmkIds = result.cPMKValues.keys  // Returns int keys: [1, 2, 3]
for (final cpmkId in cpmkIds) {   // cpmkId = int (e.g., 1)
  final value = result.cpmkValues[cpmkId];  // ← cpmkValues expects String "1"!
  // Returns null because int 1 ≠ String "1"
}

// ✅ CORRECT:
cpmkIds = result.cPMKValues.keys  // Returns int keys: [1, 2, 3]
for (final cpmkId in cpmkIds) {   // cpmkId = int
  final value = result.cPMKValues[cpmkId];  // ← Use legacy getter which returns Map<int, double>
  // Returns value because Map<int, double>[1] works!
}
```

### 🔧 Fixed Implementation

```dart
Widget _buildCombinedCPMKCPLTable(List<OBECalculationResult> results) {
  // Extract CPMK IDs
  final cpmkIds = <int>{};
  for (final result in results) {
    cpmkIds.addAll(result.cPMKValues.keys);  // ✅ Legacy getter
  }
  
  // Extract CPL IDs
  final cplIds = <int>{};
  for (final result in results) {
    cplIds.addAll(result.cPLValues.keys);    // ✅ Legacy getter
  }
  
  // Build rows
  final rows = List.generate(results.length, (index) {
    final result = results[index];
    final cells = <DataCell>[];
    
    // Add CPMK values
    for (final cpmkId in cpmkIds) {
      final value = result.cPMKValues[cpmkId];  // ✅ Correct getter
      cells.add(DataCell(
        Text(value != null ? value.toStringAsFixed(2) : '-')
      ));
    }
    
    // Add CPL values
    for (final cplId in cplIds) {
      final value = result.cPLValues[cplId];    // ✅ Correct getter
      cells.add(DataCell(
        Text(value != null ? value.toStringAsFixed(2) : '-')
      ));
    }
    
    return DataRow(cells: cells);
  });
  
  return DataTable(columns: columns, rows: rows);
}
```

---

## 📚 RINGKASAN FILE PENTING

| File | Fungsi |
|------|--------|
| `rps_input_screen.dart` | UI untuk input RPS (16 minggu) |
| `rps_edit_dialog.dart` | Dialog edit per minggu |
| `database_helper.dart` | Simpan/load dari database |
| `obe_calculation_helper.dart` | Hitung Sub-CPMK → CPMK → CPL |
| `admin_dashboard_screen.dart` | Tampilkan hasil dalam tabel |

---

## 🎓 CONTOH LENGKAP: Vita Juwita Sinurat (Kalkulus & Vektor)

### Input RPS (Minggu 8 & 16 saja, yang penting untuk demo)
```
Minggu 8 (UTS):
├─ Topik: UTS
├─ Bobot: 15%
├─ Jenis Penilaian: UTS
├─ Bobot per Sub-CPMK:
│  ├─ Sub1: 15%
│  ├─ Sub2: 15%
│  ├─ Sub3: 15%
│  ├─ Sub4: 9%
│  ├─ Sub5: 14%
│  ├─ Sub6: 14%
│  └─ Sub7: 18%

Minggu 16 (UAS):
├─ Topik: UAS
├─ Bobot: 15%
├─ Jenis Penilaian: UAS
└─ [Same bobot per Sub-CPMK]
```

### Nilai Komponen (Vita)
```
Aktivitas: 87.5
Proyek:    87.5
Kuis:      87.5
Tugas:     87.5
UTS:       60.0
UAS:       90.0
```

### Calculation Result
```
Sub-CPMK values:
├─ Sub1: 78.33
├─ Sub2: 78.33
├─ Sub3: 78.33
├─ Sub4: 88.61
├─ Sub5: 88.21
├─ Sub6: 88.21
└─ Sub7: 87.92

CPMK values:
└─ CPMK.1: 83.74  ← Weighted avg Sub-CPMK

CPL values (dari RPS minggu aggregation):
├─ CPL.1: 35.17
├─ CPL.2: 23.44
├─ CPL.3: 35.17
└─ CPL.4: 17.60
```

### Display in Table
```
┌────┬───────────────┬──────────────────┬────────┬────────┐
│ No │ NIM           │ Nama              │ CPMK.1 │ CPL.1  │
├────┼───────────────┼──────────────────┼────────┼────────┤
│ 1  │ 2440012140XX  │ VITA JUWITA S.    │ 83.74  │ 35.17  │
│ 2  │ 2440012140XX  │ VIRA INDRA ASIH   │ 80.84  │ 33.95  │
└────┴───────────────┴──────────────────┴────────┴────────┘
```

---

## 🚀 KESIMPULAN

```
INPUT RPS (user fills in UI)
    ↓
SAVE TO DATABASE (rps_detail, rps_detail_sub_cpmk_bobot tables)
    ↓
LOAD FROM DATABASE (when viewing admin dashboard)
    ↓
CALCULATE CPMK & CPL (using OBE calculation engine)
    ↓
DISPLAY IN TABLE (with actual values, not "-")
```

**Key Points:**
1. ✅ RPS input menyimpan bobot per minggu & per Sub-CPMK
2. ✅ Bobot matrix diambil dari database menggunakan `getBobotMatrixForMatakuliah()`
3. ✅ Calculation menggunakan 3-tier weighted average
4. ✅ Display tabel menggunakan `cPMKValues` & `cPLValues` legacy getters (bukan `cpmkValues` & `cplValues`)
5. ✅ Hasilnya CPMK & CPL values ditampilkan dengan benar dibanding "-"
