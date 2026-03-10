# Refactoring: Generic OBE Table untuk CPMK dan CPL

## 📋 Ringkasan Perubahan

Telah dilakukan refactoring untuk membuat tampilan CPMK dan CPL **benar-benar identik** dengan menggunakan single generic method yang dapat digunakan oleh keduanya.

---

## ✨ Improvement utama

### SEBELUMNYA (Duplikasi kode)
```dart
_buildCPMKTable()  // ~140 lines, hardcoded untuk CPMK
_buildCPLTable()   // ~140 lines, hardcoded untuk CPL
// Total: ~280 lines dengan logic identik
```

### SESUDAHNYA (DRY Principle)
```dart
_buildCPMKTable()              // ~10 lines, wrapper saja
_buildCPLTable()               // ~10 lines, wrapper saja
_buildGenericOBETable()        // ~160 lines, shared logic
// Total: ~180 lines, code reuse
```

---

## 🏗️ Arsitektur Baru

### Metode Wrapper (Cleaner Interface)

```dart
// CPMK Table - simple wrapper
Widget _buildCPMKTable(List<OBECalculationResult> results) {
  return _buildGenericOBETable(
    results: results,
    valueGetter: (result) => result.cpmkValues,
    headerColor: const Color(0xFF27AE60),
    textColor: const Color(0xFF27AE60),
    labelPrefix: 'CPMK',
    emptyMessage: 'Tidak ada data CPMK untuk ditampilkan',
  );
}

// CPL Table - simple wrapper
Widget _buildCPLTable(List<OBECalculationResult> results) {
  return _buildGenericOBETable(
    results: results,
    valueGetter: (result) => result.cplValues,
    headerColor: const Color(0xFF8E44AD),
    textColor: const Color(0xFF8E44AD),
    labelPrefix: 'CPL',
    emptyMessage: 'Tidak ada data CPL untuk ditampilkan',
  );
}
```

### Main Implementation

```dart
Widget _buildGenericOBETable({
  required List<OBECalculationResult> results,
  required Map<int, double> Function(OBECalculationResult) valueGetter,
  required Color headerColor,
  required Color textColor,
  required String labelPrefix,
  required String emptyMessage,
})
```

---

## 📊 Parameter Explanation

| Parameter | Type | Purpose | CPMK Value | CPL Value |
|-----------|------|---------|-----------|-----------|
| `results` | List | Hasil perhitungan | Same | Same |
| `valueGetter` | Function | Ambil values dari result | `cpmkValues` | `cplValues` |
| `headerColor` | Color | Warna header card | `#27AE60` | `#8E44AD` |
| `textColor` | Color | Warna text nilai | `#27AE60` | `#8E44AD` |
| `labelPrefix` | String | Prefix label kolom | `CPMK` | `CPL` |
| `emptyMessage` | String | Pesan jika kosong | "...CPMK..." | "...CPL..." |

---

## 🔄 Logic Flow

```
_buildCPMKTable(results)
    ↓
_buildGenericOBETable(
    valueGetter: (result) => result.cpmkValues,
    headerColor: #27AE60,
    labelPrefix: 'CPMK',
    ...
)
    ↓
FutureBuilder (Load mahasiswa)
    ↓
Extract unique IDs (1, 3, 5 for CPMK)
    ↓
Build dynamic columns
    ↓
Generate DataTable rows
    ↓
Apply styling (color, font, etc)
    ↓
Return Table Widget
```

---

## ✅ Keuntungan Refactoring

### 1. **Code Reusability** ♻️
```dart
// Satu implementasi digunakan untuk dua tabel
// Mudah untuk menambah tabel OBE lainnya di masa depan
```

### 2. **Maintainability** 🔧
```dart
// Jika ada perubahan logic, hanya perlu edit satu tempat
// Reduceslimbah/duplikasi kode
// Lebih mudah untuk testing
```

### 3. **Consistency** ✨
```dart
// Dijamin kedua tabel identik (same logic, same behavior)
// Hanya perbedaan data dan styling
```

### 4. **Scalability** 📈
```dart
// Mudah untuk menambah outcome types baru (Sub-CPMK, etc)
// Hanya perlu create wrapper baru yang call _buildGenericOBETable()
```

### 5. **Cleaner Code** 📝
```dart
// Wrapper methods lebih readable
// Intent jelas: "build CPMK table" vs "build CPL table"
// Details tersembunyi di generic method
```

---

## 🧪 Verification

### Code Compiles ✅
```
dart analyze: NO ERRORS
Warnings: Only about unused/style issues (expected)
Syntax: VALID
```

### Behavior Identical ✅
```
CPMK Table: Menampilkan CPMK values dengan warna hijau
CPL Table:  Menampilkan CPL values dengan warna ungu
Structure:  100% identical
Logic:      100% identical
```

---

## 📈 Metrics

| Metric | Before | After | Improvement |
|--------|--------|-------|------------|
| Lines of Code | ~280 | ~180 | **-100 lines (-36%)** |
| Duplication | High | None | **Eliminated** |
| Methods | 2 | 3* | *1 generic + 2 wrappers |
| Maintenance | Difficult | Easy | **Better** |

---

## 🔮 Future Extensions

Untuk menambah tabel OBE baru (contoh: Sub-CPMK):

```dart
Widget _buildSubCPMKTable(List<OBECalculationResult> results) {
  return _buildGenericOBETable(
    results: results,
    valueGetter: (result) => result.subCpmkValues, // Assumsi ada
    headerColor: const Color(0xFF3498DB),           // Biru
    textColor: const Color(0xFF3498DB),
    labelPrefix: 'SubCPMK',
    emptyMessage: 'Tidak ada data Sub-CPMK untuk ditampilkan',
  );
}
```

**Hanya perlu menambah 10 lines!** 🎉

---

## 🎯 Best Practices Implemented

### 1. DRY (Don't Repeat Yourself)
```dart
✅ Shared logic di generic method
✅ Only differences are parameters
✅ No duplicate code
```

### 2. SOLID Principles
```dart
✅ Single Responsibility: Generic method fokus pada rendering
✅ Open/Closed: Easy to extend untuk type baru
✅ Dependency Inversion: Function parameter untuk flexibility
```

### 3. Functional Programming
```dart
✅ Higher-order function: valueGetter parameter
✅ Function passing: Abstrak how values are extracted
✅ Immutable parameters
```

### 4. Clean Code
```dart
✅ Meaningful names
✅ Single purpose methods
✅ Good documentation
✅ Easy to understand intent
```

---

## 📖 Documentation

### Generic Method Docstring
```dart
/// Membangun tabel OBE (CPMK/CPL) dengan struktur identik
/// 
/// Method generik ini digunakan oleh _buildCPMKTable() dan
/// _buildCPLTable() untuk menampilkan data dengan struktur yang sama.
/// 
/// Parameters:
/// - results: List hasil perhitungan OBE
/// - valueGetter: Function untuk ambil values (cpmkValues atau cplValues)
/// - headerColor: Warna header (hijau untuk CPMK, ungu untuk CPL)
/// - textColor: Warna teks nilai dalam tabel
/// - labelPrefix: Prefix label kolom (CPMK atau CPL)
/// - emptyMessage: Pesan jika tidak ada data untuk ditampilkan
```

---

## 🚀 Implementation Details

### Value Getter Function
```dart
// Example: CPMK
valueGetter: (result) => result.cpmkValues

// This one-liner:
// 1. Takes OBECalculationResult
// 2. Returns the cpmkValues Map
// 3. Much cleaner than if-else logic
```

### Column Building
```dart
// Dynamic generation berdasarkan IDs dalam data
for (final id in sortedIds) {
  columns.add(
    DataColumn(
      label: SizedBox(
        width: 80,
        child: Text('$labelPrefix.$id'), // CPMK.1 atau CPL.1
      ),
    ),
  );
}
```

### Row Data Building
```dart
// Iterate through each result
// Build cells using valueGetter
final values = valueGetter(result);  // Get CPMK atau CPL values
for (final id in sortedIds) {
  final value = values[id];          // Get value untuk ID ini
  // Create cell dengan value
}
```

---

## 📝 Before vs After Code

### BEFORE (Duplikasi)
```dart
// _buildCPMKTable
for (final cpmkId in sortedCpmkIds) {
  final value = result.cpmkValues[cpmkId];
  cells.add(DataCell(...))
}

// _buildCPLTable (IDENTICAL, hanya cplValues)
for (final cplId in sortedCplIds) {
  final value = result.cplValues[cplId];
  cells.add(DataCell(...))
}
```

### AFTER (Shared)
```dart
// _buildGenericOBETable
for (final id in sortedIds) {
  final value = valueGetter(result)[id];
  cells.add(DataCell(...))
}
```

---

## ✅ Checklist

- [x] Generic method created
- [x] CPMK wrapper updated
- [x] CPL wrapper updated
- [x] Code compiles without errors
- [x] All same behavior
- [x] Improved readability
- [x] DRY principle applied
- [x] Documentation complete
- [x] Ready for production

---

## 🎉 Conclusion

Refactoring ini membuat kode lebih maintainable, scalable, dan clean sambil memastikan **CPMK dan CPL display benar-benar identik dalam logic dan struktur**. Hanya parameter yang berbeda, implementasi shared.

**Status**: ✅ **COMPLETE & PRODUCTION READY**

---

**Updated**: March 9, 2026  
**Version**: 2.0.0 (Refactored)  
**Impact**: High (Code quality & maintainability)
