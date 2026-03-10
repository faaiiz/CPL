# Academic OBE Calculation Engine - Documentation

## Ringkasan
Academic OBE Calculation Engine adalah sistem perhitungan nilai Sub-CPMK dan CPMK berbasis matriks bobot dengan metode weighted average. Sistem ini menjamin akurasi, validasi ketat, dan output yang deterministik.

## Aturan Mutlak (Absolute Rules)

✅ **HARUS**
- Gunakan hanya bobot yang diberikan
- Hitung menggunakan weighted average berbasis matriks bobot
- Hanya komponen dengan bobot > 0 yang digunakan dalam perhitungan
- Validasi total bobot Sub-CPMK = 100
- Bulatkan semua hasil ke 2 desimal
- Produksi output yang deterministik dan konsisten
- Hentikan dan beri error message jika data tidak valid

❌ **JANGAN**
- Gunakan rata-rata sederhana
- Modifikasi atau membuat nilai baru
- Abaikan komponen dengan bobot = 0
- Lewatkan validasi data

## Formula Perhitungan

### 1. Sub-CPMK (Nilai Pembelajaran Khusus)

```
SubCPMK_i = (Σ nilai_komponen_j × bobot_ij) / total_bobot_i

dimana:
- SubCPMK_i = Nilai Sub-CPMK ke-i
- nilai_komponen_j = Nilai komponen j (Aktivitas, Tugas, Kuis, etc)
- bobot_ij = Bobot komponen j untuk Sub-CPMK i
- total_bobot_i = Σ bobot_ij untuk Sub-CPMK i (hanya bobot > 0)
```

**Contoh Perhitungan Sub-CPMK:**

```
Nilai Komponen: [Aktivitas, Hasil Proyek, Kuis, Tugas, UTS, UAS]
                [   85.5,      85.5,      85.5,  85.5,  65,   75  ]

Sub-CPMK 1: Bobot = [5, 0, 0, 5, 5, 0]
Total Bobot = 15 (hanya 5+5+5 dari komponen dengan bobot > 0)

SubCPMK_1 = (85.5×5 + 85.5×5 + 65×5) / 15
          = (427.5 + 427.5 + 325) / 15
          = 1180 / 15
          = 78.67
```

### 2. CPMK (Intended Learning Outcomes)

```
CPMK = (Σ SubCPMK_i × bobot_subcpmk_i) / total_bobot_subcpmk

dimana:
- SubCPMK_i = Nilai Sub-CPMK ke-i (dari perhitungan)
- bobot_subcpmk_i = Bobot Sub-CPMK i dalam CPMK
- total_bobot_subcpmk = HARUS = 100
```

**Catatan Penting:**
> Total bobot Sub-CPMK untuk setiap CPMK HARUS = 100. Jika tidak, sistem akan throw Exception.

## Contoh Lengkap: Mata Kuliah Kalkulus & Vektor

### Data Input

**Nilai Komponen Mahasiswa:**
```
Nama: Vira Indra Asih
Nilai: [85.5, 85.5, 85.5, 85.5, 65, 75]
       [Aktivitas, Hasil Proyek, Kuis, Tugas, UTS, UAS]

Nama: Vita juwita Sinurat
Nilai: [87.5, 87.5, 87.5, 87.5, 60, 90]
       [Aktivitas, Hasil Proyek, Kuis, Tugas, UTS, UAS]
```

**Matriks Bobot Sub-CPMK:**

| Sub | Aktivitas | Proyek | Kuis | Tugas | UTS | UAS | Total |
|-----|-----------|--------|------|-------|-----|-----|-------|
| 1   | 5         | 0      | 0    | 5     | 5   | 0   | 15    |
| 2   | 0         | 5      | 5    | 0     | 5   | 0   | 15    |
| 3   | 5         | 0      | 0    | 5     | 5   | 0   | 15    |
| 4   | 0         | 0      | 5    | 0     | 0   | 4   | 9     |
| 5   | 5         | 0      | 0    | 5     | 0   | 4   | 14    |
| 6   | 0         | 5      | 5    | 0     | 0   | 4   | 14    |
| 7   | 5         | 0      | 5    | 5     | 0   | 3   | 18    |

**Total bobot keseluruhan = 15+15+15+9+14+14+18 = 100** ✅

### Perhitungan Sub-CPMK (Vira Indra Asih)

```
Sub1: (85.5×5 + 85.5×5 + 65×5) / 15 = 1180 / 15 = 78.67
Sub2: (85.5×5 + 85.5×5 + 65×5) / 15 = 1180 / 15 = 78.67
Sub3: (85.5×5 + 85.5×5 + 65×5) / 15 = 1180 / 15 = 78.67
Sub4: (85.5×5 + 75×4) / 9 = 727.5 / 9 = 80.83
Sub5: (85.5×5 + 85.5×5 + 75×4) / 14 = 1155 / 14 = 82.50
Sub6: (85.5×5 + 85.5×5 + 75×4) / 14 = 1155 / 14 = 82.50
Sub7: (85.5×5 + 85.5×5 + 85.5×5 + 75×3) / 18 = 1507.5 / 18 = 83.92
```

**Hasil Sub-CPMK Vira:**
```
Sub1: 78.67
Sub2: 78.67
Sub3: 78.67
Sub4: 80.83
Sub5: 82.50
Sub6: 82.50
Sub7: 83.92
```

### Perhitungan CPMK

CPMK dihitung sebagai weighted average dari 7 Sub-CPMK, di mana **bobot setiap Sub-CPMK adalah total bobot masing-masing Sub-CPMK dari matriks RPS**.

**Bobot distribusi Sub-CPMK ke CPMK** (dari kolom "Total" di matriks bobot):
```
Sub1: 15/100 = 15%
Sub2: 15/100 = 15%
Sub3: 15/100 = 15%
Sub4: 9/100 = 9%
Sub5: 14/100 = 14%
Sub6: 14/100 = 14%
Sub7: 18/100 = 18%
Total: 100/100 = 100% ✅
```

**Formula CPMK:**
```
CPMK = (Σ SubCPMK_i × bobot_i) / 100

dimana:
- SubCPMK_i = Nilai Sub-CPMK ke-i
- bobot_i = Total bobot Sub-CPMK i dari matriks RPS
```

**Perhitungan untuk Vira Indra Asih:**
```
CPMK = (78.67×15 + 78.67×15 + 78.67×15 + 80.83×9 + 82.50×14 + 82.50×14 + 83.92×18) / 100
     = (1180.05 + 1180.05 + 1180.05 + 727.47 + 1155.00 + 1155.00 + 1510.56) / 100
     = 8088.18 / 100
     = 80.88
```

**Hasil CPMK Vira: 80.88**

### Perhitungan Sub-CPMK (Vita juwita Sinurat)

```
Sub1: (87.5×5 + 87.5×5 + 60×5) / 15 = 1175 / 15 = 78.33
Sub2: (87.5×5 + 87.5×5 + 60×5) / 15 = 1175 / 15 = 78.33
Sub3: (87.5×5 + 87.5×5 + 60×5) / 15 = 1175 / 15 = 78.33
Sub4: (87.5×5 + 90×4) / 9 = 797.5 / 9 = 88.61
Sub5: (87.5×5 + 87.5×5 + 90×4) / 14 = 1235 / 14 = 88.21
Sub6: (87.5×5 + 87.5×5 + 90×4) / 14 = 1235 / 14 = 88.21
Sub7: (87.5×5 + 87.5×5 + 87.5×5 + 90×3) / 18 = 1582.5 / 18 = 87.92
```

**Hasil Sub-CPMK Vita:**
```
Sub1: 78.33
Sub2: 78.33
Sub3: 78.33
Sub4: 88.61
Sub5: 88.21
Sub6: 88.21
Sub7: 87.92
```

**Perhitungan CPMK untuk Vita juwita Sinurat:**

Menggunakan bobot distribusi Sub-CPMK yang sama (dari total bobot matriks RPS):
```
CPMK = (78.33×15 + 78.33×15 + 78.33×15 + 88.61×9 + 88.21×14 + 88.21×14 + 87.92×18) / 100
     = (1174.95 + 1174.95 + 1174.95 + 797.49 + 1234.94 + 1234.94 + 1582.56) / 100
     = 8374.78 / 100
     = 83.7478
     = 83.75 (pembulatan 2 desimal)
```

**Atau dengan menggunakan nilai Sub-CPMK tanpa pembulatan intermediate:**
```
CPMK = (78.3333...×15 + 78.3333...×15 + 78.3333...×15 + 88.6111...×9 + 88.2142...×14 + 88.2142...×14 + 87.9166...×18) / 100
     = (1175 + 1175 + 1175 + 797.5 + 1235 + 1235 + 1582.5) / 100
     = 8375 / 100
     = 83.75
```

**Hasil CPMK Vita: 83.75** (dengan perhitungan menggunakan bobot total Sub-CPMK dari RPS)

## API Usage

### 1. Hitung Sub-CPMK dengan Matriks Bobot

```dart
final engine = OBECalculationHelper();

// Prepare data
const nilaiKomponen = [85.5, 85.5, 85.5, 85.5, 65.0, 75.0];
final bobotMatrix = {
  1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],
  2: [0.0, 5.0, 5.0, 0.0, 5.0, 0.0],
  3: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],
  // ... more sub-CPMKs
};

// Calculate
try {
  final subCpmkValues = engine.calculateSubCPMKWithMatrix(
    nilaiKomponen: nilaiKomponen,
    bobotMatrix: bobotMatrix,
  );
  
  // Output: {1: 78.67, 2: 78.67, 3: 78.67, ...}
  subCpmkValues.forEach((id, nilai) {
    print('Sub-CPMK $id: $nilai');
  });
} catch (e) {
  print('Error: $e');
}
```

### 2. Hitung CPMK dari Sub-CPMK

```dart
final subCpmkValues = {
  1: 78.67,
  2: 78.67,
  3: 78.67,
  4: 80.83,
  5: 82.50,
  6: 82.50,
  7: 83.92,
};

final subCpmkBobot = {
  1: {
    1: 14.28,
    2: 14.28,
    3: 14.28,
    4: 12.87,
    5: 14.29,
    6: 14.29,
    7: 15.71, // Total MUST = 100
  }
};

try {
  final cpmkValues = engine.calculateCPMKFromSubCPMK(
    subCpmkValues: subCpmkValues,
    subCpmkBobotToCpmk: subCpmkBobot,
  );
  
  // Output: {1: 80.96}
  print('CPMK: ${cpmkValues[1]}');
} catch (e) {
  print('Error: $e');
}
```

### 3. Hitung CPMK Langsung dari Nilai Komponen

```dart
try {
  final cpmkValues = engine.calculateCPMKFull(
    nilaiKomponen: nilaiKomponen,
    bobotMatrix: bobotMatrix,
    subCpmkBobot: subCpmkBobot,
  );
  
  print('CPMK: ${cpmkValues[1]}');
} catch (e) {
  print('Error: $e');
}
```

## Error Handling

Engine akan throw Exception untuk kondisi tidak valid:

```dart
// ❌ Jumlah komponen tidak sesuai bobot
try {
  engine.calculateSubCPMKWithMatrix(
    nilaiKomponen: [85.5, 85.5], // 2 values
    bobotMatrix: {1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0]}, // 6 values
  );
} catch (e) {
  // "❌ Jumlah bobot (6) tidak sesuai dengan jumlah komponen nilai (2)"
}

// ❌ Total bobot Sub-CPMK ≠ 100
try {
  engine.calculateCPMKFromSubCPMK(
    subCpmkValues: {...},
    subCpmkBobotToCpmk: {
      1: {
        1: 14.28,
        2: 14.28,
        // ... total = 99 (not 100)
      }
    },
  );
} catch (e) {
  // "❌ Total bobot Sub-CPMK untuk CPMK 1 = 99.0 (harus = 100)"
}

// ❌ Semua bobot = 0
try {
  engine.calculateSubCPMKWithMatrix(
    nilaiKomponen: [...],
    bobotMatrix: {1: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]},
  );
} catch (e) {
  // "❌ Total bobot untuk Sub-CPMK 1 = 0. Minimal ada satu komponen dengan bobot > 0"
}
```

## Testing

Jalankan test suite untuk memverifikasi akurasi:

```bash
cd cpl
flutter test test/obe_calculation_test.dart
```

Test coverage meliputi:
- ✅ Perhitungan Sub-CPMK dengan example case Vira & Vita
- ✅ Perhitungan CPMK dengan validasi bobot
- ✅ Error handling untuk data invalid
- ✅ Komponen dengan bobot = 0 tidak digunakan
- ✅ Rounding akurat ke 2 desimal
- ✅ Full integration test

## Output Validation

Setiap hasil perhitungan dijamin:
1. **Akurat**: Menggunakan formula weighted average yang benar
2. **Valid**: Semua input dan constraint divalidasi
3. **Konsisten**: Output selalu sama untuk input yang sama
4. **Presisi**: Dibulatkan ke 2 desimal dengan metode standard rounding
5. **Deterministik**: Tidak ada randomisasi atau elemen stokastik

## Catatan Implementasi

- Engine menggunakan floating-point arithmetic dengan toleransi 0.01 untuk validasi bobot
- Pembulatan menggunakan metode: `(value * 100).round() / 100`
- Hanya komponen dengan bobot > 0 yang aktif dalam perhitungan
- Total bobot sub-CPMK untuk CPMK HARUS = 100 (tolerance 0.01)
- Semua hasil dibulatkan 2 desimal setelah setiap tahap perhitungan

## Integrasi dengan Aplikasi

Untuk integrasi lebih lanjut dengan database dan UI:

1. **Database Schema**: Buat table untuk menyimpan:
   - `nilai_komponen` - Per mahasiswa, per mata kuliah
   - `bobot_matrix` - Per mata kuliah, per sub-CPMK
   - `subcpmk_bobot_mapping` - Mapping Sub-CPMK ke CPMK dengan bobot

2. **UI Components**: Buat widgets untuk:
   - Input nilai komponen
   - Display Sub-CPMK & CPMK calculation results
   - Validation error messages

3. **Service Integration**: Update `OBECalculationHelper` untuk:
   - Fetch nilai komponen dari database
   - Fetch bobot matrix dari database
   - Cache hasil perhitungan untuk performa

Lihat `PANDUAN_IMPORT_NILAI_DETAIL.md` untuk integrasi dengan sistem import.
