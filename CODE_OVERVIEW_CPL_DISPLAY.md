# Implementasi Lengkap Tampilan CPL - Code Overview

## 📋 Daftar Methods Utama

### 1. **_buildBatchCalculationResults()** (Line ~2260)
**Purpose**: Menampilkan hasil perhitungan CPL dengan summary dan dua tabel

```dart
Widget _buildBatchCalculationResults() {
  ┌─ Hitung rata-rata CPMK & CPL
  ├─ Tampilkan summary cards (rata-rata)
  ├─ Tampilkan tabel CPMK
  └─ Tampilkan tabel CPL
}
```

**Flow**:
1. Kalkulasi `avgCPMK` dan `avgCPL` dari hasil perhitungan
2. Build title dengan nama matakuliah dan tahun ajaran
3. Build dua summary cards (hijau untuk CPMK, ungu untuk CPL)
4. Call `_buildCPMKTable(results)`
5. Call `_buildCPLTable(results)`

**Output**:
```
Judul + Badge jumlah mahasiswa
├─ Summary Cards (2 kolom)
├─ CPMK Table (Card dengan header hijau)
├─ CPL Table (Card dengan header ungu)
```

---

### 2. **_buildCPMKTable()** (Line ~2400)
**Purpose**: Membuat tabel CPMK dengan kolom dinamis berdasarkan CPMK IDs

```dart
Widget _buildCPMKTable(List<OBECalculationResult> results) {
  ┌─ Load mahasiswa data (FutureBuilder)
  ├─ Extract unique CPMK IDs
  ├─ Sort CPMK IDs
  ├─ Build dynamic columns (No, NIM, Nama, CPMK.1, CPMK.2, ...)
  └─ Generate DataTable rows dengan nilai CPMK
}
```

**Struktur Tabel**:
```
┌─────┬─────┬──────────┬─────────┬─────────┐
│ No  │ NIM │ Nama     │ CPMK.1  │ CPMK.2  │
├─────┼─────┼──────────┼─────────┼─────────┤
│ 1   │ 001 │ Adi      │ 76.00   │ 77.00   │
│ 2   │ 002 │ Budi     │ 79.00   │ 80.00   │
└─────┴─────┴──────────┴─────────┴─────────┘
```

**Features**:
- `FutureBuilder` untuk load data mahasiswa
- Dynamic columns berdasarkan CPMK IDs dalam data
- Column width: `No: 30px, NIM: 100px, Nama: 150px, CPMK: 80px each`
- Font size: `12px untuk header, 11px untuk data`
- Text color: Hijau (#27AE60)
- Horizontal scroll untuk banyak kolom
- Loading dan error states

**Variables Kunci**:
```dart
sortedCpmkIds     // List ID CPMK yang diurutkan
mahasiswaMap      // Map<int, String> untuk lookup nama
columns           // List<DataColumn> yang di-generate dinamis
```

---

### 3. **_buildCPLTable()** (Line ~2550)
**Purpose**: Membuat tabel CPL dengan struktur identik dengan CPMK

```dart
Widget _buildCPLTable(List<OBECalculationResult> results) {
  ┌─ Load mahasiswa data (FutureBuilder)
  ├─ Extract unique CPL IDs
  ├─ Sort CPL IDs
  ├─ Build dynamic columns (No, NIM, Nama, CPL.1, CPL.2, ...)
  └─ Generate DataTable rows dengan nilai CPL
}
```

**Struktur Tabel**:
```
┌─────┬─────┬──────────┬────────┬────────┐
│ No  │ NIM │ Nama     │ CPL.1  │ CPL.2  │
├─────┼─────┼──────────┼────────┼────────┤
│ 1   │ 001 │ Adi      │ 80.00  │ 82.00  │
│ 2   │ 002 │ Budi     │ 81.00  │ 83.00  │
└─────┴─────┴──────────┴────────┴────────┘
```

**Features**: 
- Identik dengan `_buildCPMKTable()` tapi untuk CPL
- Dynamic columns berdasarkan CPL IDs
- Text color: Ungu (#8E44AD)
- Column width: Sama dengan CPMK table
- Loading dan error states
- Horizontal scroll support

---

## 🔌 Data Flow

### Input Data
```dart
List<OBECalculationResult> results
  └─ Setiap result berisi:
     ├─ mahasiswaId: int
     ├─ cpmkValues: Map<int, double>  // {cpmkId: value}
     ├─ cplValues: Map<int, double>   // {cplId: value}
     └─ averageSubCPMKNilai: double
```

### Processing
```
1. Extract IDs
   results → CPMK IDs (1, 3, 5) & CPL IDs (2, 4)

2. Build Columns
   CPMK IDs (1, 3, 5) → [CPMK.1, CPMK.3, CPMK.5]
   CPL IDs (2, 4) → [CPL.2, CPL.4]

3. Build Rows
   For each result → DataRow dengan nilai per ID
   
4. Render
   DataTable dengan dynamic columns + rows
```

---

## 🎨 Styling Details

### Summary Cards
```dart
Card(
  elevation: 2,
  child: Container(
    decoration: BoxDecoration(
      color: Color(...).withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(8)
    )
  )
)
```

### Table Headers
```dart
Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Color(...).withValues(alpha: 0.1),
    border: Border(bottom: ...)
  ),
  child: Row(
    children: [
      Icon(...),
      Text("Nilai CPMK/CPL (...)")
    ]
  )
)
```

### DataTable Styling
```dart
DataTable(
  columnSpacing: 10,      // Jarak antar kolom
  horizontalMargin: 8,    // Margin kiri-kanan
  columns: [...],         // Dynamic columns
  rows: [...]             // Dynamic rows
)
```

---

## 🚨 Error Handling

### States yang Dihandle

1. **Loading State** (ConnectionState.waiting)
   ```dart
   Center(
     child: CircularProgressIndicator()
   )
   ```

2. **Error State** (snapshot.hasError)
   ```dart
   Container(
     color: Colors.red[50],
     child: Text("Error: ${snapshot.error}")
   )
   ```

3. **Empty Data State** (IDs kosong)
   ```dart
   Text("Tidak ada data CPMK/CPL untuk ditampilkan")
   ```

4. **No Data State** (results kosong)
   ```dart
   // Tabel tidak ditampilkan jika results kosong
   ```

---

## 🔄 Integration Points

### Dipanggil dari:
- `_buildBatchCalculationResults()` 

### Memanggil:
- `_dbHelper.getAllMahasiswa()` - Load data mahasiswa
- `FutureBuilder` - Handle async data loading

### Data Dependencies:
- `_batchCalculationResults` - Results dari perhitungan CPL
- `_currentDisplayedMKKey` - Matakuliah yang sedang ditampilkan
- `_currentMatakuliahNama` - Nama matakuliah
- `_currentTahunAjaran` - Tahun ajaran

---

## 📊 Column Specification

### CPMK Table Columns
| # | Name | Width | Type | Color |
|---|------|-------|------|-------|
| 1 | No | 30px | Text | Black |
| 2 | NIM | 100px | Text | Black |
| 3 | Nama | 150px | Text | Black |
| 4+ | CPMK.X | 80px ea | Text | Green |

### CPL Table Columns
| # | Name | Width | Type | Color |
|---|------|-------|------|-------|
| 1 | No | 30px | Text | Black |
| 2 | NIM | 100px | Text | Black |
| 3 | Nama | 150px | Text | Black |
| 4+ | CPL.X | 80px ea | Text | Purple |

---

## 🧮 Calculation Examples

### Summary Cards
```
Avg CPMK = (76 + 79) / 2 = 77.5
Avg CPL = (80 + 81) / 2 = 80.5

Note: Calculation iterates through all cpmkValues/cplValues
```

### Column Names
```
CPMK: {1: 76, 3: 77} → Columns: CPMK.1, CPMK.3
CPL: {2: 80, 4: 82} → Columns: CPL.2, CPL.4
```

---

## 🧪 Testing Scenarios

### ✅ Happy Path
- Data loading berhasil
- Multiple CPMK dan CPL IDs
- Tabel render dengan sempurna

### ⚠️ Edge Cases
- 0 hasil (tidak menampilkan tabel)
- 1 hasil (1 row tabel)
- Banyak hasil (>50 mahasiswa)
- Missing CPMK/CPL values (tampil "-")
- Single CPMK/CPL ID
- Many CPMK/CPL IDs (horiz scroll)

### ❌ Error Cases
- Database error saat load mahasiswa
- Empty mahasiswa list
- Null values dalam results

---

## 📝 Code References

### Line Numbers (Approximate)
- `_buildBatchCalculationResults()`: ~2260-2380
- `_buildCPMKTable()`: ~2400-2540
- `_buildCPLTable()`: ~2550-2690
- Summary Card Calculation: ~2270-2295
- DataTable Instantiation: ~2450-2480 (CPMK), ~2600-2630 (CPL)

---

## 🎯 Key Takeaways

1. **Modular Design**: Tiga method terpisah untuk flexibility
2. **Dynamic Structure**: Columns di-generate berdasarkan data aktual
3. **Consistent Styling**: CPMK dan CPL menggunakan pattern yang identik
4. **Robust Handling**: Loading, error, dan empty states ditangani
5. **Responsive Design**: Horizontal scroll untuk data banyak
6. **Color Coding**: Hijau untuk CPMK, ungu untuk CPL untuk visual clarity
