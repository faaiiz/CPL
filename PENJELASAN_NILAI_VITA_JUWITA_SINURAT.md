# 📊 Penjelasan Asal Nilai Vita Juwita Sinurat (NIM: 24040120140097)

## 🎯 Ringkasan Nilai yang Ditampilkan di Menu Hitung CPL

| Metrik | Nilai | Penjelasan |
|--------|-------|-----------|
| **Nilai Komponen (Simple Average)** | 83.33 | Rata-rata 6 nilai komponen mentah: (87.5+87.5+87.5+87.5+60+90)/6 |
| **Rata-rata SUB CPMK (Label di UI)** | 83.33 | ❌ SALAH LABEL - ini adalah nilai komponen, bukan Sub-CPMK |
| **Sub-CPMK (Benar)** | [78.33, 78.33, 78.33, 88.61, 88.21, 88.21, 87.92] | Weighted average dari komponen dengan bobot matriks |
| **Rata-rata CPMK (Label di UI)** | 83.33 | ❌ SALAH - seharusnya 83.75 (weighted average dari Sub-CPMK) |
| **CPMK (Benar)** | 83.75 | Weighted average dari 7 Sub-CPMK dengan bobot total dari RPS (15,15,15,9,14,14,18) |
| **CPL** | 0 | ❌ Tidak ada mapping CPMK ke CPL |

---

## 1️⃣ DARI MANA ANGKA 83.33 BERASAL?

### Data Nilai Komponen yang Diimpor:
Ketika Anda melakukan import nilai untuk mahasiswa **Vita Juwita Sinurat**, sistem menerima **6 nilai komponen**:

```
Nilai Komponen: [87.5, 87.5, 87.5, 87.5, 60.0, 90.0]
Komponen:       [Aktivitas, Hasil Proyek, Kuis, Tugas, UTS, UAS]
```

### Perhitungan Rata-rata Sederhana:
```
Rata-rata = (87.5 + 87.5 + 87.5 + 87.5 + 60.0 + 90.0) / 6
         = 500.0 / 6
         = 83.3333... 
         = 83.33 (dibulatkan 2 desimal)
```

✅ **Ini adalah angka 83.33 yang Anda lihat!**

---

## 2️⃣ PERBEDAAN ANTARA NILAI KOMPONEN vs SUB-CPMK vs CPMK

### ⚠️ PENTING: Ada kebingungan dalam tampilan di interface!

Angka **83.33** yang ditampilkan sebagai "Rata-rata SUB CPMK" sebenarnya adalah:
- **Rata-rata nilai komponen mentah** (simple average dari 6 komponen)
- **BUKAN rata-rata Sub-CPMK yang sesungguhnya**
- **BUKAN CPMK yang sesungguhnya**

### Perbandingan:

#### A. Nilai Komponen Mentah (Simple Average)
```
Rata-rata = (87.5 + 87.5 + 87.5 + 87.5 + 60 + 90) / 6
         = 83.33 ← INI YANG DITAMPILKAN SEBAGAI "RATA-RATA SUB CPMK"
```

❌ **Ini SALAH! Ini bukan Sub-CPMK, ini hanya rata-rata komponen mentah.**

#### B. Sub-CPMK yang Sesungguhnya (Weighted Average dengan Bobot Matriks)
Menurut perhitungan OBE yang benar dengan bobot matriks dari RPS:

```
Sub-CPMK 1: (87.5×5 + 87.5×5 + 60×5) / 15 = 1175 / 15 = 78.33
Sub-CPMK 2: (87.5×5 + 87.5×5 + 60×5) / 15 = 1175 / 15 = 78.33
Sub-CPMK 3: (87.5×5 + 87.5×5 + 60×5) / 15 = 1175 / 15 = 78.33
Sub-CPMK 4: (87.5×5 + 90×4) / 9 = 797.5 / 9 = 88.61
Sub-CPMK 5: (87.5×5 + 87.5×5 + 90×4) / 14 = 1235 / 14 = 88.21
Sub-CPMK 6: (87.5×5 + 87.5×5 + 90×4) / 14 = 1235 / 14 = 88.21
Sub-CPMK 7: (87.5×5 + 87.5×5 + 87.5×5 + 90×3) / 18 = 1582.5 / 18 = 87.92

Hasil Sub-CPMK Vita: [78.33, 78.33, 78.33, 88.61, 88.21, 88.21, 87.92]
```

✅ **Ini adalah Sub-CPMK yang benar.**

#### C. CPMK (Weighted Average dari Sub-CPMK dengan Bobot Matriks RPS) 

CPMK dihitung sebagai **weighted average dari 7 Sub-CPMK**, di mana **bobot untuk setiap Sub-CPMK adalah total bobot baris masing-masing Sub-CPMK dari matriks RPS**.

**Bobot distribusi Sub-CPMK ke CPMK** (dari kolom "Total" di matriks RPS):
```
Sub1: 15/100 = 15%  (dari total bobot baris Sub1)
Sub2: 15/100 = 15%
Sub3: 15/100 = 15%
Sub4: 9/100 = 9%
Sub5: 14/100 = 14%
Sub6: 14/100 = 14%
Sub7: 18/100 = 18%
Total: 100%
```

**Formula CPMK:**
```
CPMK = (Σ SubCPMK_i × bobot_i) / 100

CPMK = (78.33×15 + 78.33×15 + 78.33×15 + 88.61×9 + 88.21×14 + 88.21×14 + 87.92×18) / 100
     = (1174.95 + 1174.95 + 1174.95 + 797.49 + 1234.94 + 1234.94 + 1582.56) / 100
     = 8374.78 / 100
     = 83.75
```

**Atau dengan menggunakan nilai exact Sub-CPMK tanpa pembulatan intermediate:**
```
CPMK = (78.3333×15 + 78.3333×15 + 78.3333×15 + 88.6111×9 + 88.2142×14 + 88.2142×14 + 87.9166×18) / 100
     = (1175 + 1175 + 1175 + 797.5 + 1235 + 1235 + 1582.5) / 100
     = 8375 / 100
     = 83.75
```

✅ **Hasil CPMK Vita: 83.75** (dengan perhitungan menggunakan bobot total Sub-CPMK dari matriks RPS)

---

## 3️⃣ DARI MANA DATA NILAI KOMPONEN INI?

### Sumber Data:
Data nilai komponen ini berasal dari **import file CSV** untuk nilai mata kuliah:

**File: `templates_import/nilai_template.csv`**

```csv
nim,nama,matakuliah_kode,aktivitas,hasil_proyek,kuis,tugas,uts,uas
24040120140097,Vita Juwita Sinurat,KALKULUS,87.5,87.5,87.5,87.5,60.0,90.0
24040120140097,Vita Juwita Sinurat,VEKTOR,87.5,87.5,87.5,87.5,70.0,85.0
```

Sistem mengambil nilai dari kolom-kolom ini:
- `aktivitas`: 87.5
- `hasil_proyek`: 87.5
- `kuis`: 87.5
- `tugas`: 87.5
- `uts`: 60.0
- `uas`: 90.0

---

## 4️⃣ MENGAPA CPL = 0?

### Penyebab CPL = 0:

❌ **TIDAK ADA MAPPING CPMK KE CPL**

```
Konfigurasi Sistem:
├── Sub-CPMK (7 item) ← Ada nilai
├── CPMK (Mata Kuliah) ← Ada mapping dari Sub-CPMK
└── CPL (Program) ← ❌ TIDAK ADA MAPPING dari CPMK
```

Ketika UI mencoba menghitung CPL:
```dart
// Di cpmk_cpl_calculation_service.dart
Future<double?> calculateCPLForMahasiswa(int cplId, int mahasiswaId) async {
  final mappings = await _dbHelper.getMappingByCPL(cplId);
  // ❌ mappings adalah KOSONG
  if (mappings.isEmpty) {
    return null; // Kembalikan null/0
  }
}
```

### Solusi:
Anda perlu **membuat mapping dari CPMK ke CPL** di menu:
- **Menu Admin → Kelola CPL → Mapping CPMK ke CPL**
- Atau di **Menu Admin → CPMK-CPL Mapping**

Contoh mapping yang diperlukan:
```
CPL "Matematika Dasar" (ID: 1)
  ├── CPMK Kalkulus (50% bobot)
  └── CPMK Vektor (50% bobot)
```

---

## 5️⃣ ALUR PERHITUNGAN YANG BENAR

### Seharusnya seperti ini:

```
┌─────────────────────────────────────────────────────┐
│ 1. Data Nilai Komponen (Dari Import)                │
│    [87.5, 87.5, 87.5, 87.5, 60, 90]                │
│    Rata-rata = 83.33                                │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 2. Hitung Sub-CPMK (Weighted Average dengan Bobot) │
│    Sub1 = 78.33, Sub2 = 78.33, Sub3 = 78.33       │
│    Sub4 = 88.61, Sub5 = 88.21, Sub6 = 88.21       │
│    Sub7 = 87.92                                     │
│    (Menggunakan Bobot Matriks dari RPS)             │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 3. Hitung CPMK (Dari 7 Sub-CPMK)                    │
│    Bobot: 15%, 15%, 15%, 9%, 14%, 14%, 18%         │
│    CPMK = (Σ Sub-CPMK × Bobot) / 100               │
│    CPMK = 83.75                                     │
│    (Weighted average dari 7 Sub-CPMK)               │
│    (Bobot diambil dari total bobot baris RPS)       │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 4. Hitung CPL (Dari CPMK)                           │
│    CPL = (Σ CPMK × Bobot) / 100                    │
│    ❌ BELUM ADA MAPPING CPMK → CPL                 │
└─────────────────────────────────────────────────────┘
```

---

## 6️⃣ RINGKASAN MASALAH

### Yang Ditampilkan di UI:
- **"Rata-rata SUB CPMK = 83.33"**
- **"Rata-rata CPMK = 83.33"**

### Yang Seharusnya Ditampilkan:
- ✅ **"Nilai Komponen (Simple Average) = 83.33"** - Untuk informasi saja
- ✅ **"Sub-CPMK:"** - Tampilkan 7 nilai Sub-CPMK terpisah dengan bobot masing-masing:
  - Sub1: 78.33 (bobot 15%), Sub2: 78.33 (bobot 15%), Sub3: 78.33 (bobot 15%)
  - Sub4: 88.61 (bobot 9%), Sub5: 88.21 (bobot 14%), Sub6: 88.21 (bobot 14%), Sub7: 87.92 (bobot 18%)
- ✅ **"CPMK = 83.75"** - Weighted average dari 7 Sub-CPMK dengan bobot dari RPS

### Masalah Utama:
❌ **Label di UI menggunakan "Rata-rata SUB CPMK" untuk nilai komponen mentah (83.33)**
- Nilai 83.33 adalah simple average dari 6 komponen
- BUKAN Sub-CPMK (yang seharusnya 7 nilai berbeda dengan bobot berbeda)
- BUKAN CPMK (yang seharusnya 83.75 = weighted average dari Sub-CPMK)

**Formula yang sebenarnya untuk CPMK:**
```
CPMK = (SubCPMK₁×15 + SubCPMK₂×15 + SubCPMK₃×15 + SubCPMK₄×9 + SubCPMK₅×14 + SubCPMK₆×14 + SubCPMK₇×18) / 100

Bobot diambil dari TOTAL (kolom terakhir) matriks bobot RPS
```

❌ **CPL = 0**
- Penyebab: Tidak ada mapping CPMK ke CPL
- Solusi: Buat mapping di menu Mapping CPMK-CPL

---

## 7️⃣ VERIFIKASI DATA DI DATABASE

### Query untuk memverifikasi:

```sql
-- Nilai komponen Vita Juwita Sinurat untuk Kalkulus
SELECT nim, nama, matakuliah_kode, aktivitas, hasil_proyek, 
       kuis, tugas, uts, uas
FROM nilai
WHERE nim = '24040120140097' 
  AND matakuliah_kode IN ('KALKULUS', 'VEKTOR');

-- Sub-CPMK mapping
SELECT * FROM sub_cpmk_cpmk_mapping 
WHERE cpmk_id IN (
  SELECT id FROM cpmk WHERE matakuliah_id IN (
    SELECT id FROM matakuliah WHERE kode IN ('KALKULUS', 'VEKTOR')
  )
);

-- CPMK ke CPL mapping
SELECT * FROM cpmk_cpl_mapping;
-- ❌ Harusnya ada data, tapi mungkin kosong
```

---

## 8️⃣ DOKUMENTASI REFERENSI

### File Terkait:
- 📄 [OBE_CALCULATION_ENGINE.md](OBE_CALCULATION_ENGINE.md) - Penjelasan lengkap formula OBE
- 📄 [VERIFICATION_OBE.md](VERIFICATION_OBE.md) - Verifikasi perhitungan dengan test case
- 📁 `lib/services/obe_calculation_helper.dart` - Implementasi perhitungan
- 📁 `lib/services/cpmk_cpl_calculation_service.dart` - Service untuk CPMK/CPL calculation
- 📁 `lib/screens/assessment_outcomes_screen.dart` - Screen untuk tampilan hasil
- 📁 `test/obe_calculation_test.dart` - Unit test dengan contoh kasus

---

## ✅ KESIMPULAN

| Pertanyaan | Jawaban |
|---|---|
| **Dari mana 83.33?** | Rata-rata 6 nilai komponen: (87.5+87.5+87.5+87.5+60+90)/6 = 83.33 |
| **Kenapa ditampilkan sebagai "Rata-rata SUB CPMK"?** | ❌ Label salah; ini adalah nilai komponen mentah, bukan Sub-CPMK |
| **Berapa CPMK yang sebenarnya?** | 83.75; dihitung dari weighted average 7 Sub-CPMK dengan bobot distribusi (15,15,15,9,14,14,18) dari RPS |
| **Berapa nilai 7 Sub-CPMK?** | [78.33, 78.33, 78.33, 88.61, 88.21, 88.21, 87.92] - dihitung dengan bobot matriks |
| **Dari mana CPL 0?** | Tidak ada mapping CPMK → CPL; perlu dibuat di menu Mapping CPMK-CPL |
| **Data dari mana?** | Import file `templates_import/nilai_template.csv` saat import nilai mata kuliah |
| **Formula CPMK?** | CPMK = (Σ SubCPMK_i × bobot_i) / 100, di mana bobot_i = total bobot baris Sub-CPMK dari matriks RPS |

