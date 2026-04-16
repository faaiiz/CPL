# 🔍 DEBUG OUTPUT - CPMK CALCULATION

## Deskripsi

Fitur debug telah ditingkatkan untuk menampilkan detail lengkap perhitungan CPMK, Sub-CPMK, dan bobot-nya. Setiap langkah perhitungan sekarang dapat ditampilkan dengan **formula breakdown** yang detail.

## Informasi Yang Ditampilkan

### 1️⃣ INPUT NILAI KOMPONEN
Menampilkan semua nilai komponen yang diinputkan:
```
📥 INPUT NILAI KOMPONEN:
   aktivitas: 87.5
   proyek: 87.5
   kuis: 87.5
   tugas: 87.5
   uts: 60.0
   uas: 90.0
```

### 2️⃣ BOBOT SUB-CPMK DARI RPS
Menampilkan bobot setiap komponen untuk setiap Sub-CPMK dengan detail breakdown:
```
🎯 BOBOT SUB-CPMK (dari RPS):
   Sub-CPMK 276: (TOTAL = 14.5)
      - aktivitas: 6.0
      - tugas: 2.5
      - uts: 6.0
   Sub-CPMK 277: (TOTAL = 11.0)
      - proyek: 5.0
      - uts: 6.0
   ...
```

**TOTAL KOMPONEN** adalah penjumlahan dari semua bobot komponen dalam setiap Sub-CPMK.

### 3️⃣ CPMK ← SUB-CPMK MAPPING
Menampilkan mapping CPMK ke Sub-CPMK dengan bobot setiap Sub-CPMK:
```
🔗 CPMK ← SUB-CPMK MAPPING:
   CPMK 4: (TOTAL = 100.0)
      - Sub-CPMK 276: 14.5
      - Sub-CPMK 277: 11.0
      - Sub-CPMK 278: 19.0
      ...
```

### 4️⃣ PERHITUNGAN SUB-CPMK (dengan printDebug=true)
Menampilkan **formula breakdown** lengkap untuk setiap Sub-CPMK:
```
📊 HASIL SUB-CPMK:
   276:
      = (87.5×6.0 + 87.5×2.5 + 60.0×6.0) / 14.5
      = 1103.75 / 14.5
      = 76.12
   277:
      = (87.5×5.0 + 60.0×6.0) / 11.0
      = 797.50 / 11.0
      = 72.50
   ...
```

### 5️⃣ PERHITUNGAN CPMK (dengan printDebug=true)
Menampilkan **formula breakdown** lengkap untuk setiap CPMK:
```
📊 HASIL CPMK:
   4:
      = ((76.12×14.5) + (72.50×11.0) + (77.37×19.0) + ... + (89.17×12.0)) / 100.0
      = 8125.08 / 100.0
      = 81.25
```

## Cara Menggunakan Debug Output

### Opsi 1: Batch Calculation dengan Debug Otomatis

Saat menjalankan `calculateBatchOBEResultsForMatakuliah()`, debug output akan **otomatis** ditampilkan untuk mahasiswa pertama:

```dart
final results = await helper.calculateBatchOBEResultsForMatakuliah(
  matakuliahId: 5,
  tahunAjaran: 2024,
);
```

Output akan menunjukkan:
- ✅ Input nilai komponen untuk mahasiswa pertama
- ✅ Bobot Sub-CPMK dari RPS (dengan detail aggregation)
- ✅ Mapping CPMK ← Sub-CPMK
- ✅ Formula breakdown untuk setiap Sub-CPMK
- ✅ Formula breakdown untuk setiap CPMK
- ✅ Hasil akhir untuk semua mahasiswa

### Opsi 2: Direct Calculation dengan printDebug

Gunakan `calculateOBEComplete()` dengan `printDebug: true`:

```dart
final result = helper.calculateOBEComplete(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobotMap,
  cpmkSubCpmkMap: cpmkSubCpmkMap,
  printDebug: true,  // ✅ Enable formula breakdown
);
```

### Opsi 3: Perhitungan Sub-CPMK Saja

Gunakan `calculateSubCPMKValues()` dengan `printDebug: true`:

```dart
final subCpmkValues = helper.calculateSubCPMKValues(
  nilaiKomponen: nilaiKomponen,
  subCpmkBobotMap: subCpmkBobotMap,
  printDebug: true,  // ✅ Show Sub-CPMK formula breakdown
);
```

### Opsi 4: Perhitungan CPMK Saja

Gunakan `calculateCPMKValues()` dengan `printDebug: true`:

```dart
final cpmkValues = helper.calculateCPMKValues(
  subCpmkValues: subCpmkValues,
  cpmkSubCpmkMap: cpmkSubCpmkMap,
  printDebug: true,  // ✅ Show CPMK formula breakdown
);
```

## Format Output Debug

### Sub-CPMK Calculation Formula
```
   Sub-CPMK_ID:
      = (nilai₁×bobot₁ + nilai₂×bobot₂ + ... + nilaiₙ×bobotₙ) / TOTAL_BOBOT
      = TOTAL_NUMERATOR / TOTAL_BOBOT
      = FINAL_VALUE
```

### CPMK Calculation Formula
```
   CPMK_ID:
      = ((subCpmk₁×bobot₁) + (subCpmk₂×bobot₂) + ... + (subCpmkₙ×bobotₙ)) / TOTAL_BOBOT
      = TOTAL_NUMERATOR / TOTAL_BOBOT
      = FINAL_VALUE
```

## Contoh Lengkap Output

Lihat file `test_debug_cpmk_calculation.dart` untuk contoh lengkap dengan:
- Input data dari contoh user
- Formula breakdown untuk setiap Sub-CPMK  
- Formula breakdown untuk CPMK
- Verification dengan expected values

Jalankan dengan:
```bash
dart run test_debug_cpmk_calculation.dart
```

## Fields yang Ditampilkan

| Field | Arti | Sumber |
|-------|------|--------|
| **NILAI KOMPONEN** | Nilai masing-masing komponen dalam skala 0-100 | Input dari user / Database |
| **BOBOT SUB-CPMK** | Bobot setiap komponen untuk setiap Sub-CPMK | Dari RPS Details (aggregated) |
| **TOTAL KOMPONEN** | Jumlah bobot semua komponen dalam satu Sub-CPMK | Sum dari bobot komponen |
| **NILAI SUB-CPMK** | Nilai Sub-CPMK (weighted average) | Calculated: Σ(nilai×bobot)/Σ(bobot) |
| **BOBOT SUB-CPMK (ke CPMK)** | Bobot setiap Sub-CPMK untuk CPMK | Dari RPS Detail mapping |
| **NILAI CPMK** | Nilai CPMK (weighted average dari Sub-CPMK) | Calculated: Σ(subCpmk×bobot)/Σ(bobot) |

## Troubleshooting

### Debug Output Tidak Muncul
- Pastikan menggunakan `printDebug: true` atau menggunakan `calculateBatchOBEResultsForMatakuliah()`
- Check console/logcat untuk output
- Pastikan data bobot tidak kosong

### Nilai Tidak Sesuai Expected
- Verifikasi bobot aggregation dari RPS sudah benar
- Check bahwa TOTAL KOMPONEN untuk setiap Sub-CPMK sudah benar
- Lihat formula breakdown untuk melihat step mana yang bermasalah

### Rumus Breakdown Salah Format
- Pastikan menggunakan `printDebug: true`
- Method harus `calculateOBEComplete()`, `calculateSubCPMKValues()`, atau `calculateCPMKValues()`
- Check bahwa parameter types sudah correct (Map<String, Map<String, double>> bukan Map<int, List<double>>)

## Integration dengan Batch Processing

Debug output akan otomatis ditampilkan untuk mahasiswa pertama saat menggunakan:
```dart
await helper.calculateBatchOBEResultsForMatakuliah(
  matakuliahId: matakuliahId,
  tahunAjaran: tahunAjaran,
  continueOnError: true,  // Batch tetap lanjut jika ada error
);
```

Ini membantu untuk:
- ✅ Verify bobot aggregation dari RPS
- ✅ Verify calculation formula
- ✅ Debug discrepancies antara expected vs actual
- ✅ Trace mahasiswa pertama dengan semua detail

Mahasiswa berikutnya diproses tanpa debug output untuk efficiency.

## Related Files

- **Main Implementation**: `lib/services/obe_calculation_helper.dart`
  - Method: `calculateSubCPMKValues()`
  - Method: `calculateCPMKValues()`
  - Method: `calculateOBEComplete()`
  - Method: `calculateBatchOBEResultsForMatakuliah()`

- **Test File**: `test_debug_cpmk_calculation.dart`
  - Complete example dengan user data
  - Verification logic
  - Expected values

- **Database Integration**: `lib/services/database_helper.dart`
  - Method: `getRPSDetailByMatakuliah()`
  - Method: `getAllNilaiKomponen()`
  - Method: `getAllSubCPMKCPMKMappings()`
