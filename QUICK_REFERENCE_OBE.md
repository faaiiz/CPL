# Academic OBE Calculation Engine - Quick Reference

## 🎯 Overview

Engine ini menghitung nilai **Sub-CPMK** dan **CPMK** menggunakan **weighted average matrix** dengan validasi ketat dan error handling yang deterministik.

## 📋 Aturan Kritis (MUST READ)

| # | Rule | Status |
|---|------|--------|
| 1 | Gunakan hanya bobot yang diberikan | ✅ |
| 2 | Jangan gunakan rata-rata sederhana | ✅ |
| 3 | Hanya komponen dengan bobot > 0 yang dihitung | ✅ |
| 4 | Total bobot Sub-CPMK per CPMK HARUS = 100 | ✅ |
| 5 | Semua hasil dibulatkan 2 desimal | ✅ |
| 6 | Output harus deterministik & konsisten | ✅ |
| 7 | Stop & error jika data invalid | ✅ |

## 🧮 Formula

### Sub-CPMK

```
SubCPMK_i = (Σ nilai_j × bobot_ij) / (Σ bobot_ij)
            dimana bobot_ij > 0
```

### CPMK

```
CPMK = (Σ SubCPMK_i × bobot_i) / 100
       dengan Σ bobot_i = 100
```

## 💻 Quick API Usage

### Basic: Hitung Sub-CPMK

```dart
final engine = OBECalculationHelper();

const nilaiKomponen = [85.5, 85.5, 85.5, 85.5, 65.0, 75.0];
final bobotMatrix = {
  1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],
  2: [0.0, 5.0, 5.0, 0.0, 5.0, 0.0],
};

final subCpmkValues = engine.calculateSubCPMKWithMatrix(
  nilaiKomponen: nilaiKomponen,
  bobotMatrix: bobotMatrix,
);

// Output: {1: 78.67, 2: 78.67}
```

### Advanced: Hitung CPMK

```dart
final subCpmkBobot = {
  1: {1: 50.0, 2: 50.0}, // Total = 100
};

final cpmkValues = engine.calculateCPMKFromSubCPMK(
  subCpmkValues: subCpmkValues,
  subCpmkBobotToCpmk: subCpmkBobot,
);

// Output: {1: 78.67}
```

### One-Shot: Hitung Langsung ke CPMK

```dart
final cpmkValues = engine.calculateCPMKFull(
  nilaiKomponen: nilaiKomponen,
  bobotMatrix: bobotMatrix,
  subCpmkBobot: subCpmkBobot,
);
```

## 📊 Struktur Data Input

### Nilai Komponen (List<double>)
```dart
// Urutan komponen harus konsisten
[85.5, 85.5, 85.5, 85.5, 65.0, 75.0]
 ↓     ↓     ↓     ↓     ↓    ↓
Aktiv  Proj  Kuis  Tugas UTS  UAS
```

### Bobot Matrix (Map<int, List<double>>)
```dart
{
  1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],  // Sub-CPMK 1
  2: [0.0, 5.0, 5.0, 0.0, 5.0, 0.0],  // Sub-CPMK 2
}
```

### Sub-CPMK Bobot (Map<int, Map<int, double>>)
```dart
{
  1: {  // CPMK 1
    1: 50.0,  // Sub-CPMK 1 weight
    2: 50.0,  // Sub-CPMK 2 weight
    // TOTAL = 100
  }
}
```

## ❌ Error Scenarios

| Scenario | Error Message |
|----------|---------------|
| Jumlah bobot ≠ jumlah nilai | "Jumlah bobot (...) tidak sesuai dengan jumlah komponen nilai (...)" |
| Total bobot = 0 | "Total bobot untuk Sub-CPMK ... = 0. Minimal ada satu komponen dengan bobot > 0" |
| Total bobot ≠ 100 | "Total bobot Sub-CPMK untuk CPMK ... = .... (harus = 100)" |
| Input kosong | "Nilai komponen tidak boleh kosong" atau "Bobot matrix tidak boleh kosong" |

## ✅ Contoh Hasil Benar

**Kasus: Vira Indra Asih**

| Komponen | Nilai |
|----------|-------|
| Aktivitas | 85.5 |
| Hasil Proyek | 85.5 |
| Kuis | 85.5 |
| Tugas | 85.5 |
| UTS | 65.0 |
| UAS | 75.0 |

**Sub-CPMK:** `[78.67, 78.67, 78.67, 80.83, 82.50, 82.50, 83.92]`

**CPMK:** `80.96`

## 🔧 Implementation Details

1. **Rounding**: `(value * 100).round() / 100`
2. **Tolerance**: ±0.01 untuk validasi floating-point
3. **Precision**: Double precision arithmetic
4. **Determinism**: No randomization, pure mathematical calculation

## 📚 Files

| File | Purpose |
|------|---------|
| `obe_calculation_helper.dart` | Main engine implementation |
| `obe_calculation_test.dart` | Comprehensive test suite |
| `obe_calculation_examples.dart` | Usage examples |
| `OBE_CALCULATION_ENGINE.md` | Full documentation |
| `QUICK_REFERENCE.md` (this) | Quick lookup guide |

## 🚀 Testing

```bash
flutter test test/obe_calculation_test.dart
```

Test memverifikasi:
- ✅ Perhitungan akurat vs contoh kasus
- ✅ Validasi bobot
- ✅ Error handling lengkap
- ✅ Rounding precision
- ✅ Deterministic output

## 🔗 Integration Checklist

- [ ] Database schema untuk `nilai_komponen`
- [ ] Database schema untuk `bobot_matrix`
- [ ] Database schema untuk `mapping_subcpmk_cpmk`
- [ ] Fetch data dari database
- [ ] Cache hasil perhitungan
- [ ] Display UI dengan results
- [ ] Error handling UI
- [ ] Batch calculation untuk multiple mahasiswa
- [ ] Export hasil ke PDF/Excel
- [ ] Audit trail logging

## 💡 Tips

1. **Simpan bobot matrix di database** - Jangan hardcode untuk flexibility
2. **Cache hasil perhitungan** - Perhitungan berat, simpan di cache
3. **Validasi input di UI** - Tangkap error sebelum ke engine
4. **Log semua perhitungan** - Untuk audit trail
5. **Batch calculation** - Hitung multiple mahasiswa sekaligus untuk performa

## 📞 Support & Debugging

### Troubleshooting Checklist

1. **Output tidak sesuai?**
   - Check: Urutan komponen nilai sesuai bobot matrix?
   - Check: Semua nilai dalam range 0-100?
   - Check: Total bobot matrix = 100?

2. **Error "bobot mismatch"?**
   - Check: Panjang list bobot = panjang list nilai
   - Check: Tidak ada typo dalam panjang list

3. **Error "total bobot ≠ 100"?**
   - Check: Sum semua bobot Sub-CPMK = 100
   - Gunakan: `sum = bobotList.fold(0.0, (a, b) => a + b)`

4. **Hasil selalu 0?**
   - Check: Semua nilai = 0 atau NaN?
   - Check: Semua bobot = 0?
   - Check: Order of operations correct?

## 📝 Notes

- Engine **tidak** menerima String input - gunakan List<double>
- Engine **tidak** modifikasi nilai - hanya calculate
- Engine **tidak** save ke database - caller harus save
- Floating point tolerance = 0.01
- Pembulatan menggunakan standard rounding rules

---

**Version:** 1.0  
**Status:** Production Ready  
**Last Updated:** 2026-03-02
