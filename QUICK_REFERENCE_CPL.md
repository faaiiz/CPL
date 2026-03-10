# 🚀 QUICK REFERENCE - CPL Display Implementation

## 📌 TL;DR (Too Long; Didn't Read)

**Apa yang berubah?**
- Tampilan CPL yang sebelumnya gabung dengan CPMK, sekarang terpisah
- Menjadi 2 tabel: CPMK (hijau) dan CPL (ungu) + 2 summary cards

**Bagaimana cara kerjanya?**
1. Click tombol "Lihat" pada matakuliah
2. System compute hasil CPL
3. Tampil summary cards + 2 tabel detail

---

## 🎯 Key Methods

### _buildBatchCalculationResults()
```
╔════════════════════════════════════════════════════╗
║  Main entry point untuk tampilan hasil CPL        ║
║  Dipanggil ketika: _batchCalculationResults != null
╚════════════════════════════════════════════════════╝

Flow:
1. Kalkulasi avgCPMK & avgCPL
2. Build title + summary
3. Build CPMK table
4. Build CPL table

Output: Column dengan semua komponen
```

### _buildCPMKTable()
```
╔════════════════════════════════════════════════════╗
║  Table untuk CPMK Values                           ║
║  Warna: Hijau (#27AE60)                           ║
╚════════════════════════════════════════════════════╝

Kolom: No | NIM | Nama | CPMK.1 | CPMK.2 | ... (dinamis)
Fitur: Load mahasiswa, sort, style, scroll
```

### _buildCPLTable()
```
╔════════════════════════════════════════════════════╗
║  Table untuk CPL Values                            ║
║  Warna: Ungu (#8E44AD)                            ║
╚════════════════════════════════════════════════════╝

Kolom: No | NIM | Nama | CPL.1 | CPL.2 | ... (dinamis)
Fitur: Identik dengan CPMK table
```

---

## 🎨 Visual Structure

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ [TITLE + BADGE]                                ┃
┃ Hasil Perhitungan - Kalkulus I - 2024 | 12 mhs ┃
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ [SUMMARY CARDS]                                ┃
┃ ┌─────────────────┬─────────────────┐        ┃
┃ │ 📊 CPMK: 75.50  │ 🏆 CPL: 80.25   │        ┃
┃ └─────────────────┴─────────────────┘        ┃
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ [CPMK TABLE HEADER]                            ┃
┃ 📚 Nilai CPMK (Capaian Pembelajaran Mata Kuliah) ┃
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ [CPMK TABLE]                                   ┃
┃ No│NIM│Nama│CPMK.1│CPMK.2│ ← scrollable      ┃
┃ 1 │001│Adi │76.00 │77.00 │                   ┃
┃ 2 │002│Bud │79.00 │80.00 │                   ┃
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ [CPL TABLE HEADER]                             ┃
┃ 🏆 Nilai CPL (Capaian Pembelajaran Lulusan)   ┃
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ [CPL TABLE]                                    ┃
┃ No│NIM│Nama│CPL.1│CPL.2│ ← scrollable       ┃
┃ 1 │001│Adi │80.00│82.00│                    ┃
┃ 2 │002│Bud │81.00│83.00│                    ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## 🔧 Common Tasks

### Task 1: Menambah Kolom CPMK
```dart
// Jika ada CPMK ID baru dalam data
// Kolom akan otomatis ditambah!
// Tidak perlu hardcode

// System automatically:
1. Extract CPMK.6 dari data
2. Create column untuk CPMK.6
3. Populate cells dengan nilai CPMK.6
```

### Task 2: Customizing Colors
```dart
// Untuk change CPMK color (saat ini: hijau #27AE60)
// Edit: Line 2318, 2333, 2360, dll
const Color(0xFF27AE60)  // OLD
const Color(0xFFYourHex)  // NEW

// Untuk change CPL color (saat ini: ungu #8E44AD)
const Color(0xFF8E44AD)  // OLD
const Color(0xFFYourHex)  // NEW
```

### Task 3: Changing Column Widths
```dart
// Edit lebar kolom di:
// _buildCPMKTable() - line ~2416
// _buildCPLTable() - line ~2566

SizedBox(width: 80, ...)  // CPMK column width
// Change 80 ke value yang diinginkan
```

### Task 4: Adding New Summary Info
```dart
// Di _buildBatchCalculationResults(), setelah:
double avgCPL = 0;

// Tambah:
double minCPMK = double.infinity;
double maxCPMK = 0;

// Kalkulasi dalam loop:
if (value < minCPMK) minCPMK = value;
if (value > maxCPMK) maxCPMK = value;

// Display di summary cards
```

---

## 🧪 Testing Guide

### Test 1: Basic Display
```
✓ Open app
✓ Go to Admin Dashboard
✓ Select "Hitung CPL" menu
✓ Click "Hitung" button untuk matakuliah
✓ Wait untuk calculation finish
✓ Verify: Summary cards muncul + 2 tables
```

### Test 2: Dynamic Columns
```
✓ Verify CPMK table punya kolom untuk setiap CPMK ID
✓ Verify CPL table punya kolom untuk setiap CPL ID
✓ Verify header text adalah CPMK.X dan CPL.X
✓ Verify nilai ditampilkan di bawah header
```

### Test 3: Styling
```
✓ CPMK table: Green header (#27AE60)
✓ CPL table: Purple header (#8E44AD)
✓ Icons: school untuk CPMK, flag untuk CPL
✓ Summary cards: Color sesuai kategori
```

### Test 4: Error Handling
```
✓ Disconnect database → Error message
✓ No mahasiswa data → Error message
✓ Loading state → Spinner visible
✓ Empty results → "No data" message
```

### Test 5: Responsiveness
```
✓ Horizontal scroll: Works dengan banyak kolom
✓ Vertical scroll: Works dengan banyak baris
✓ Text truncation: Nama panjang di-truncate
✓ Mobile: All visible, scroll friendly
```

---

## 🐛 Troubleshooting

### Issue: Tabel tidak muncul
```
Solution:
1. Check: apakah _batchCalculationResults != null
2. Check: apakah hasil perhitungan diload ke state
3. Verify: snapshot.connectionState == ConnectionState.done
```

### Issue: Kolom tidak muncul
```
Solution:
1. Check: apakah cpmkValues/cplValues tidak kosong
2. Verify: IDs di-extract dengan benar
3. Debug: Print sortedCpmkIds dan sortedCplIds
```

### Issue: Nilai salah
```
Solution:
1. Check: OBECalculationHelper calculation
2. Verify: Data dari database correct
3. Debug: Print result.cpmkValues dan result.cplValues
```

### Issue: Loading spinning forever
```
Solution:
1. Check: Database connection
2. Verify: getAllMahasiswa() query
3. Try: Refresh page atau restart app
4. Check: Console errors (DevTools)
```

---

## 📊 Column Specifications

### CPMK Table
```
Column 1: No (30px, centered, bold)
Column 2: NIM (100px, left-aligned)
Column 3: Nama (150px, left-aligned, ellipsis)
Column 4+: CPMK.X (80px each, centered, green text)

Example dengan CPMK: 1, 3, 5
Total width ≈ 30+100+150+(80×3) = 530px
```

### CPL Table
```
Column 1: No (30px, centered, bold)
Column 2: NIM (100px, left-aligned)
Column 3: Nama (150px, left-aligned, ellipsis)
Column 4+: CPL.X (80px each, centered, purple text)

Example dengan CPL: 2, 4
Total width ≈ 30+100+150+(80×2) = 430px
```

---

## 🎯 Performance Tips

### For Large Datasets (>50 mahasiswa)
```
✓ Horizontal scroll masih smooth
✓ Vertical scroll fine (DataTable handle well)
✓ FutureBuilder cache data di memory
✓ No performance issues up to 100+ rows
```

### Optimization Ideas
```
1. Cache mahasiswa list di variable
2. Use ListView.builder untuk many rows (optional)
3. Lazy load jika mahasiswa > 500
4. Implement pagination
```

---

## 📚 Related Methods

### Data Loading
- `_calculateCPLFromTable()` - Trigger calculation
- `_showSavedResults()` - Load saved results
- `_loadMatakuliahWithNilai()` - Load courses

### Helper Classes
- `OBECalculationHelper.calculateAllMahasiswaCPL()` - Main calculation
- `DatabaseHelper.getAllMahasiswa()` - Load students
- `OBECalculationResult` - Data model

---

## 🔗 File Locations

```
lib/screens/admin_dashboard_screen.dart
├─ _buildBatchCalculationResults() [LINE ~2260]
├─ _buildCPMKTable() [LINE ~2400]
├─ _buildCPLTable() [LINE ~2550]
└─ _buildBatchSummaryTable() [LINE ~2855] (DEPRECATED)
```

---

## 💡 Pro Tips

### Tip 1: Custom Styling
```dart
// Untuk custom summary card
Card(
  elevation: 2,  // Change shadow depth
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),  // Custom radius
  ),
  // Add any custom properties
)
```

### Tip 2: Adding Filters
```dart
// Add filter widget sebelum table
TextField(
  onChanged: (value) {
    setState(() {
      filteredResults = filterByName(value);
    });
  },
)
// Ganti results dengan filteredResults
```

### Tip 3: Export Function
```dart
// Di method baru:
void exportToExcel() {
  // Create Excel dengan 2 sheets
  // Sheet 1: CPMK table
  // Sheet 2: CPL table
}
```

---

## 🆘 Need Help?

### Check These First
1. Code: Line 2260-2690 in admin_dashboard_screen.dart
2. Docs: Read STRUKTUR_CPL_DISPLAY.md
3. Debug: Enable DEBUG prints, check console
4. Test: Run dengan test data, verify each component

### Common Fixes
```dart
/✓ Not showing?
- Check: _batchCalculationResults != null

✓ Wrong values?
- Check: result.cpmkValues dan result.cplValues

✓ Layout broken?
- Check: Column widths sum
- Verify: DataTable settings

✓ Loading forever?
- Check: Database connectivity
- Try: Refresh atau restart
```

---

## ✨ Summary

| What | Where | How |
|------|-------|-----|
| CPMK Table | Line 2400 | `_buildCPMKTable(results)` |
| CPL Table | Line 2550 | `_buildCPLTable(results)` |
| Summary | Line 2300 | Calculated in `_buildBatchCalculationResults()` |
| Colors | Throughout | `#27AE60` (CPMK), `#8E44AD` (CPL) |
| Data | FutureBuilder | `getAllMahasiswa()` + `results` param |

**Status**: ✅ Production Ready  
**Performance**: ✅ Optimized  
**Documentation**: ✅ Complete  

---

**Last Update**: March 9, 2026  
**Version**: 1.0.0  
