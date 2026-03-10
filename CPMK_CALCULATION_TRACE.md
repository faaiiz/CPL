# 📊 CPMK Calculation Trace untuk Vita Juwita Sinurat

## ❓ Pertanyaan
Dari mana nilai **Rata-rata CPMK = 83.99** untuk Vita Juwita Sinurat?

## 📈 Jawaban: CPMK adalah Simple Average dari Sub-CPMK

### Formula Aktual (di code):
```
CPMK = Σ(SubCPMK_i × bobot_mapping_i) / 100

dimana bobot_mapping_i diambil dari tabel "sub_cpmk_cpmk_mapping"
```

### Dengan bobot mapping = equal distribution (1/7 per Sub-CPMK):
```
Sub-CPMK values: [78.33, 78.33, 78.33, 88.61, 88.21, 88.21, 87.92]
Bobot mapping:    [100/7, 100/7, 100/7, 100/7, 100/7, 100/7, 100/7]
                = [14.29, 14.29, 14.29, 14.29, 14.29, 14.29, 14.29]

CPMK = (78.33×14.29 + 78.33×14.29 + 78.33×14.29 + 88.61×14.29 + 88.21×14.29 + 88.21×14.29 + 87.92×14.29) / 100
     = (1119.69 + 1119.69 + 1119.69 + 1266.53 + 1260.42 + 1260.42 + 1256.26) / 100
     = 8399.70 / 100
     = 83.99 ✓
```

**ATAU Simple Average:**
```
CPMK = (78.33 + 78.33 + 78.33 + 88.61 + 88.21 + 88.21 + 87.92) / 7
     = 587.94 / 7
     = 83.99 ✓
```

## 🚨 ISSUE: CPMK Menggunakan Equal Distribution, Bukan RPS Bobot!

**Seharusnya** CPMK dihitung dengan **RPS bobot** [15, 15, 15, 9, 14, 14, 18]:
```
CPMK_correct = (78.33×15 + 78.33×15 + 78.33×15 + 88.61×9 + 88.21×14 + 88.21×14 + 87.92×18) / 100
             = 8374.78 / 100
             = 83.75 (sama dengan Sub-CPMK rata-rata)
```

## 📝 Penjelasan

### Mengapa ada 2 tingkatan perhitungan?

1. **Sub-CPMK Calculation** (dari Nilai Komponen):
   - Formula: Weighted average dengan bobot komponen dari RPS
   - Input: [Aktivitas, Proyek, Kuis, Tugas, UTS, UAS] = [87.5, 87.5, 87.5, 87.5, 60, 90]
   - Output: [78.33, 78.33, 78.33, 88.61, 88.21, 88.21, 87.92]
   - ✅ Sudah BENAR setelah fix bobot matrix

2. **CPMK Calculation** (dari Sub-CPMK):
   - Formula: Weighted average dengan bobot dari "sub_cpmk_cpmk_mapping"
   - Input: Sub-CPMK values [78.33, ...]
   - Bobot mapping: Dari database tabel `sub_cpmk_cpmk_mapping`
   - Output: 83.99 (dengan equal distribution)
   - ❌ SALAH! Seharusnya menggunakan RPS bobot [15,15,15,9,14,14,18]

## 💡 Solusi

Ada 2 opsi:

### Opsi 1: Sama-sama gunakan RPS bobot
- Sub-CPMK Calculation: Gunakan RPS bobot komponen ✅
- CPMK Calculation: Gunakan RPS bobot Sub-CPMK (15,15,15,9,14,14,18)
- **Result**: CPMK = 83.75 (equal dengan Sub-CPMK rata-rata)

### Opsi 2: Gunakan sub_cpmk_cpmk_mapping dari database
- Update tabel `sub_cpmk_cpmk_mapping` untuk menggunakan RPS bobot
- Mapping: Sub-CPMK i → CPMK j dengan bobot = RPS total bobot
- **Result**: CPMK = 83.75

## 🔍 Rekomendasi

Menggunakan **Opsi 1** karena:
1. Lebih konsisten - semua 3 tingkatan (Sub-CPMK, CPMK, CPL) gunakan bobot dari RPS
2. Sederhana - saat ada 1 CPMK, maka CPMK = Sub-CPMK rata-rata
3. Testable - bobot bisa dihardcode sama dengan Sub-CPMK bobot

Implementasi:
- Update `getSubCPMKToCPMKBobotMapping` untuk return RPS bobot [15,15,15,9,14,14,18]
- Gunakan bobot ini dalam `calculateCPMKFromSubCPMK`

## 📌 File yang Perlu Update
- `lib/services/database_helper.dart`:
  - Method `getSubCPMKToCPMKBobotMapping` atau buat method baru
  - Return mapping dengan RPS bobot
  
- `lib/services/obe_calculation_helper.dart`:
  - Update `calculateCPMKValuesOptimized` untuk load bobot yang benar
  - Atau use `calculateCPMKFromSubCPMK` dengan bobot matrix

