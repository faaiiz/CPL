# 📊 Dokumentasi Perhitungan CPMK dan CPL

## 🎯 Ringkas Overview

Sistem menghitung nilai dengan 3 level:
1. **Sub-CPMK** → Aggregasi dari 6 komponen nilai (aktivitas, proyek, kuis, tugas, UTS, UAS)
2. **CPMK** → Aggregasi dari Sub-CPMK menggunakan bobot matrix
3. **CPL** → Direct mapping 1:1 dari CPMK

---

## 📐 Formula Perhitungan

### 1️⃣ LEVEL 1: Sub-CPMK Calculation

**Formula:**
```
SubCPMK_i = (Σ nilai_komponen × bobot_komponen) / total_bobot_komponen
```

**Contoh untuk Sub-CPMK #1:**
- Nilai Aktivitas = 80, bobot = 5%
- Nilai Proyek = 85, bobot = 15%
- Nilai Kuis = 75, bobot = 10%
- Nilai Tugas = 80, bobot = 15%
- Nilai UTS = 70, bobot = 25%
- Nilai UAS = 85, bobot = 30%

**Perhitungan:**
```
SubCPMK_1 = (80×5 + 85×15 + 75×10 + 80×15 + 70×25 + 85×30) / (5+15+10+15+25+30)
          = (400 + 1275 + 750 + 1200 + 1750 + 2550) / 100
          = 7925 / 100
          = 79.25
```

**Sumber Bobot:** Diambil dari **RPS Details** tabel `rps_detail_sub_cpmk_bobot`

---

### 2️⃣ LEVEL 2: CPMK Calculation

**Formula:**
```
CPMK_j = (Σ SubCPMK_i × bobot_subcpmk_i) / total_bobot_subcpmk
```

Dimana `bobot_subcpmk` adalah bobot total dari bobot matrix (kolom "Total").

**Contoh untuk CPMK #1 dengan 7 Sub-CPMK:**
```
Sub-CPMK Values (di skalakan 0-100):
- SubCPMK_1 = 79.25, bobot = 15
- SubCPMK_2 = 82.50, bobot = 15
- SubCPMK_3 = 78.00, bobot = 15
- SubCPMK_4 = 85.00, bobot = 9
- SubCPMK_5 = 80.50, bobot = 14
- SubCPMK_6 = 83.00, bobot = 14
- SubCPMK_7 = 81.00, bobot = 18

CPMK_1 = (79.25×15 + 82.50×15 + 78.00×15 + 85.00×9 + 80.50×14 + 83.00×14 + 81.00×18) / 100
       = (1188.75 + 1237.50 + 1170.00 + 765.00 + 1127.00 + 1162.00 + 1458.00) / 100
       = 8108.25 / 100
       = 81.08
```

**Sumber Bobot:** Diambil dari **bobot matrix** dalam RPS

---

### 3️⃣ LEVEL 3: CPL Calculation

**Formula:**
```
CPL_k = CPMK_j  (1:1 Direct Mapping)
```

CPL value adalah **direct copy** dari CPMK value berdasarkan RPS mapping.

**Contoh:**
Jika RPS mengatakan:
- CPMK_1 → CPL_1, CPL_2
- CPMK_2 → CPL_3

Maka:
```
CPL_1 = CPMK_1 = 81.08
CPL_2 = CPMK_1 = 81.08
CPL_3 = CPMK_2 = 78.50
```

---

## 🔧 Sumber Bobot (RPS Composition)

### Bobot diserap dari:

| Level | Sumber | Tabel | Contoh |
|-------|--------|-------|--------|
| **Sub-CPMK** | RPS Details | `rps_detail_sub_cpmk_bobot` | Aktivitas 5%, Proyek 15%, Kuis 10%, Tugas 15%, UTS 25%, UAS 30% |
| **CPMK** | Bobot Matrix | `rps_detail` → bobot_matrix | [15, 15, 15, 9, 14, 14, 18] = 100 |
| **CPL** | RPS Mapping | `rps_detail` → cpl_ids | CPMK→CPL mapping dari RPS data |

---

## ⚠️ Kasus: Nilai Sama Meskipun Bobot RPS Berbeda

### Skenario: Mahasiswa Afrida Icha Musaidilla

**Nilai di Database:**
- Fisika Pencitraan 1: nilai_akhir = 80
- Biofisika: nilai_akhir = 83

**Hasil Perhitungan:**
- Fisika Pencitraan 1: CPMK = 80, CPL = 80
- Biofisika: CPMK = 83, CPL = 83

### Mengapa Hasilnya Terlihat Sama?

1. **Fallback Mode**: Jika tidak ada component scores (aktivitas, proyek, kuis, dll), sistem menggunakan nilai akhir mata kuliah.

2. **Bobot Matrix Tidak Berpengaruh**: Saat menggunakan nilai akhir sebagai fallback, bobot matrix RPS diabaikan.

3. **Direct Value Pass-through**: Nilai akhir langsung diskalakan dan digunakan untuk semua Sub-CPMK:
   ```
   Jika nilai_akhir = 80 maka:
   - SubCPMK_1 = 80 × bobot_rps_detail / 100
   - SubCPMK_2 = 80 × bobot_rps_detail / 100
   - ... dst
   
   Average Sub-CPMK ≈ 80
   → CPMK ≈ 80
   → CPL = 80
   ```

### Solusi untuk Menunjukkan Perbedaan Bobot RPS:

#### A. Input Component Scores (Prioritas Utama)
Jika nilai komponen dipisah:
- Fisika Pencitraan 1: Aktivitas=75, Proyek=85, Kuis=78, Tugas=82, UTS=80, UAS=87
- Biofisika: Aktivitas=83, Proyek=80, Kuis=85, Tugas=81, UTS=84, UAS=82

Dengan bobot RPS berbeda, hasil CPMK akan berbeda:
```
Fisika Pencitraan 1 (bobot: Aktivitas 5%, Proyek 20%, Kuis 10%, ...)
CPMK = 80.2

Biofisika (bobot: Aktivitas 15%, Proyek 10%, Kuis 15%, ...)
CPMK = 81.5
```

#### B. Manual Adjustment
Jika diperlukan, edit nilai_akhir di database untuk mencerminkan komposisi yang berbeda.

---

## 🔍 Debug: Cara Verifikasi Perhitungan

### Via Console Logs saat Load Data:
```
📊 Processing nilai_komponen entries...
🎓 Unique Mata Kuliah: 10
🎯 Processed MK ID 1 (CPMK value: 81.08)
🎯 Processed MK ID 2 (CPMK value: 78.50)
🏁 FINAL RESULT: CPMK scores: {1: 81.08, 2: 78.50, ...}
```

### Gunakan Calculation Examples:
File: `lib/services/obe_calculation_examples.dart`
Berisi contoh perhitungan langkah demi langkah untuk validasi manual.

---

## 📌 Kesimpulan

| Aspek | Penjelasan |
|-------|-----------|
| **Mengapa nilai sama?** | Karena fallback ke nilai_akhir mata kuliah, bobot RPS tidak terhitung |
| **Bagaimana menunjukkan perbedaan?** | Input component scores terpisah per mata kuliah |
| **Sumber bobot RPS** | Tabel rps_detail dan rps_detail_sub_cpmk_bobot |
| **Formula CPMK** | Weighted average Sub-CPMK dengan bobot dari bobot matrix |
| **Formula CPL** | Direct 1:1 mapping dari CPMK ke CPL |

---

## 🚀 Next Steps

Untuk mahasiswa Afrida Icha Musaidilla:

1. **Verifikasi component scores di database:**
   ```sql
   SELECT * FROM nilai_komponen 
   WHERE mahasiswa_id = <afrida_id> 
   AND matakuliah_id IN (fisika_pencitraan, biofisika);
   ```

2. **Jika ada component scores:** Harusnya muncul nilai yang berbeda sesuai komposisi RPS

3. **Jika kosong:** Input component scores terpisah untuk menunjukkan pengaruh bobot

4. **Verifikasi RPS bobot:**
   ```sql
   SELECT rps.*, rps_detail.*, rps_detail_sub_cpmk_bobot.*
   FROM rps
   JOIN rps_detail ON rps.id = rps_detail.rps_id
   JOIN rps_detail_sub_cpmk_bobot ON rps_detail.id = rps_detail_sub_cpmk_bobot.rps_detail_id
   WHERE rps.matakuliah_id IN (fisika_pencitraan, biofisika);
   ```
