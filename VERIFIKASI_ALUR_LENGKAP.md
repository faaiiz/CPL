# ✅ VERIFIKASI ALUR LENGKAP CPL SYSTEM

**Tanggal Verifikasi:** 9 Maret 2026  
**Status:** Analisis Menyeluruh Selesai

---

## 📋 RINGKASAN ALUR YANG DIMINTA

User meminta verifikasi 4 langkah alur aplikasi:

1. ✅ User upload nilai melalui import nilai
2. ✅ Matakuliah yang diupload tertampil di menu Hitung CPL  
3. ⚠️ User klik button Hitung CPL, menyimpan nilai di database
4. ✅ Nilai dari database tadi, di load pada menu pengukuran

---

## 🔍 VERIFIKASI DETAIL PER LANGKAH

### **LANGKAH 1: Import Nilai** ✅

**Status:** BERFUNGSI LENGKAP

**Flow:**
```
User Upload File Excel/CSV
  ↓
NilaiBatchImportScreen / NilaiDetailImportScreen
  ├─ File picker
  ├─ Validate format
  └─ Process via ExcelImportService
       ↓
DatabaseHelper.insertNilaiBatch()
  └─ Simpan ke table: nilai & nilai_komponen
```

**Files:**
- [lib/screens/nilai_batch_import_screen.dart](lib/screens/nilai_batch_import_screen.dart) - Batch multiple files
- [lib/screens/nilai_detail_import_screen.dart](lib/screens/nilai_detail_import_screen.dart) - Detail per komponen
- [lib/services/excel_import_service.dart](lib/services/excel_import_service.dart#L100) - Excel parsing
- [lib/services/nilai_batch_import_service.dart](lib/services/nilai_batch_import_service.dart) - Batch processing

**Database:**
- Table `nilai` - Nilai akhir per mahasiswa-matakuliah
- Table `nilai_komponen` - Component scores (aktivitas, proyek, kuis, tugas, UTS, UAS)

**Validasi:** ✅ Semua data tersimpan dengan benar

---

### **LANGKAH 2: Tampil di Menu Hitung CPL** ✅

**Status:** BERFUNGSI LENGKAP

**Flow:**
```
Admin Dashboard → Menu: "Hitung CPL dan CPMK"
  ↓
_EmbeddedHitungCPLContent (StatefulWidget)
  ├─ Initialize lazy loading
  ├─ Call _loadMatakuliahWithNilai()
  │   └─ Load HANYA matakuliah yang punya data nilai
  └─ Render tabel dengan daftar matakuliah
       └─ Setiap baris = matakuliah + tahun ajaran + button hitung
```

**Implementation Details:**
- [lib/screens/admin_dashboard_screen.dart](lib/screens/admin_dashboard_screen.dart#L1800) - Line ~2000-2100
- Method: `_loadMatakuliahWithNilai()`
- Query: `SELECT DISTINCT matakuliah_id, tahun_ajaran FROM nilai`
- Hasil: List dengan format:
  ```dart
  {
    'matakuliah_id': int,
    'matakuliah_nama': String,
    'matakuliah_kode': String,
    'tahun_ajaran': int,
    'has_nilai': true
  }
  ```

**Validasi:** ✅ 
- ✅ Hanya menampilkan MK yang punya nilai
- ✅ Sorted by tahun ajaran (descending) kemudian nama
- ✅ Lazy loaded saat tab diklik pertama kali

---

### **LANGKAH 3: Hitung CPL & Simpan Database** ⚠️ PERLU CLARIFIKASI

**Status:** SEBAGIAN - Ada perbedaan antara ekspektasi & implementasi

#### **Yang TERJADI saat button "Hitung CPL" diklik:**

```
_calculateCPLFromTable(matakuliahId, tahunAjaran)
  ↓
Step 1: Show loading dialog
Step 2: OBECalculationHelper.calculateAllMahasiswaCPL()
        → Calculate CPMK & CPL values dari database
        → Returns: List<OBECalculationResult>
Step 3: DatabaseHelper.recordCPLCalculation()
        → Hanya simpan FLAG (status) ke table 
           cpl_calculation_tracking
        → BUKAN menyimpan nilai CPL hasil hitung
Step 4: Tampilkan hasil perhitungan di UI (cache)
```

#### **Apa yang DISIMPAN ke Database:**

**Table: cpl_calculation_tracking**
- Columns: matakuliah_id, tahun_ajaran, calculated_at
- Fungsi: Track matakuliah mana saja yang sudah dihitung
- Data: HANYA flag/status, BUKAN nilai CPL itu sendiri

**TIDAK ADA table untuk menyimpan nilai CPL hasil perhitungan!**

#### **Ketidaksesuaian:**

| Ekspektasi User | Implementasi Actual |
|---|---|
| Hitung CPL → Simpan nilai ke DB | Hitung CPL → Simpan flag ke DB |
| Nilai CPL disimpan persistent | Nilai CPL hanya disimpan di memory |
| Hasil perhitungan dapat diakses kapan saja | Hasil hanya ada saat session aktif |

#### **Implikasi:**

```
Session 1:
├─ Click "Hitung CPL" untuk Mata Kuliah X
├─ Nilai CPL dihitung & ditampilkan
├─ Close app / refresh
└─ Data hasil perhitungan HILANG ❌

Session 2:
└─ Buka kembali Menu Hitung CPL
   └─ Nilai CPL harus dihitung ulang ❌
```

**Code Reference:**
- [lib/screens/admin_dashboard_screen.dart](lib/screens/admin_dashboard_screen.dart#L1650-1660)
- Line ~1656: `await _dbHelper.recordCPLCalculation(matakuliahId, tahunAjaran);`
- [lib/services/database_helper.dart](lib/services/database_helper.dart#L1786)
- Method: `recordCPLCalculation()` - Hanya insert ke tracking table

---

### **LANGKAH 4: Load di Menu Pengukuran** ✅

**Status:** BERFUNGSI, TAPI BERGANTUNG PADA STEP 3

**Flow:**
```
Admin Dashboard → Menu: "Pengukuran CPL dan CPMK"
  ↓
AssessmentOutcomesScreen
  ├─ Load semua mahasiswa
  ├─ Filter by angkatan/tahun masuk
  ├─ Select mahasiswa
  └─ Load scores:
      ├─ CPMKCPLCalculationService.loadCPMKForMahasiswa()
      └─ CPMKCPLCalculationService.loadCPLForMahasiswa()
           → Calculate dari database tables
           → Bukan dari saved CPL values
```

**Key Points:**
- [lib/screens/assessment_outcomes_screen.dart](lib/screens/assessment_outcomes_screen.dart#L150-200)
- Data source: Tables dasar (nilai_komponen, rps_detail, cpmk, cpl_master, mappings)
- TIDAK ada dependensi pada nilai CPL yang disimpan dari Step 3
- Perhitungan dilakukan on-the-fly setiap kali user view hasil

**Validasi:** ✅ 
- ✅ Load data berhasil
- ✅ Perhitungan on-the-fly akurat
- ⚠️ Tidak memanfaatkan cached results dari Step 3

---

## 🎯 ANALISIS MASALAH

### **Root Cause:**

Sistem saat ini hanya menyimpan **FLAG** bahwa CPL telah dihitung, bukan menyimpan **NILAI hasil perhitungan**.

```
Table: cpl_calculation_tracking (HANYA FLAG)
┌─────────┬──────────────┬────────────────┐
│ mk_id   │ tahun_ajaran │ calculated_at  │
├─────────┼──────────────┼────────────────┤
│ 1       │ 2024         │ 2026-03-09 ... │  ← HANYA status
└─────────┴──────────────┴────────────────┘

TIDAK ADA:
┌──────────┬──────────────┬───────────┬──────┬─────────┐
│ mhs_id   │ tahun_ajaran │ cpmk_id   │ nilai│ ...     │
├──────────┼──────────────┼───────────┼──────┼─────────┤
│ 1        │ 2024         │ 1         │ 78.5 │         │  ← HASIL PERHITUNGAN
└──────────┴──────────────┴───────────┴──────┴─────────┘
```

### **Dampak:**

1. **Tidak persistent** - Hasil perhitungan hilang saat session berakhir
2. **Harus recalculate** - Setiap kali akses menu pengukuran perlu hitung ulang  
3. **Performance issue** - Repeated calculations tanpa caching
4. **Data source confusion** - Ada dua sumber data: cached (Step 3) vs calculated (Step 4)

---

## ✅ REKOMENDASI

### **Opsi 1: Implementasi Persistent Storage** (Rekomendasi)

Buat table untuk menyimpan hasil perhitungan:

```dart
// Table: cpl_hasil_perhitungan
CREATE TABLE cpl_hasil_perhitungan (
  id INTEGER PRIMARY KEY,
  mahasiswa_id INTEGER NOT NULL,
  matakuliah_id INTEGER NOT NULL,
  tahun_ajaran INTEGER NOT NULL,
  cpmk_id INTEGER NOT NULL,
  nilai_cpmk REAL NOT NULL,
  cpl_id INTEGER NOT NULL,
  nilai_cpl REAL NOT NULL,
  calculated_at TEXT NOT NULL,
  FOREIGN KEY (mahasiswa_id) REFERENCES mahasiswa(id),
  FOREIGN KEY (matakuliah_id) REFERENCES matakuliah(id),
  FOREIGN KEY (cpmk_id) REFERENCES cpmk(id),
  FOREIGN KEY (cpl_id) REFERENCES cpl_master(id),
  UNIQUE (mahasiswa_id, matakuliah_id, tahun_ajaran, cpmk_id, cpl_id)
);
```

**Keuntungan:**
- Data persistent & queryable
- Performa lebih cepat
- Audit trail jelas
- Sesuai ekspektasi user

### **Opsi 2: Tetap In-Memory (Current)**

Keep current approach tapi dokumentasikan batasan:

**Keuntungan:**
- Sederhana
- Calculation latest selalu
- Tidak perlu migration

**Kerugian:**
- Tidak persistent
- Harus recalculate setiap session
- Tidak sesuai request user

---

## 📊 SUMMARY CHECKLIST

| Langkah | Feature | Persisten? | Status |
|---|---|---|---|
| 1 | Import Nilai | ✅ Ya | ✅ LENGKAP |
| 2 | Tampil Matakuliah di Menu | - | ✅ LENGKAP |
| 3a | Hitung CPL | ❌ Tidak | ⚠️ PARTIAL |
| 3b | Simpan ke Database | ❌ Hanya flag | ⚠️ PARTIAL |
| 4 | Load Menu Pengukuran | ✅ Calculated on-demand | ✅ LENGKAP |

---

## 🎬 TESTING STEPS

**Test Scenario: Import → Hitung → View**

```
Step 1: Import nilai untuk MK Algoritma, Tahun 2024
  ✅ Verify: nilai tersimpan di table nilai & nilai_komponen
  
Step 2: Buka Menu "Hitung CPL"
  ✅ Verify: MK Algoritma 2024 tampil di tabel
  
Step 3: Klik button "Hitung CPL"
  ✅ Verify: Hasil perhitungan tampil dengan benar
  ✅ Verify: record di cpl_calculation_tracking ada
  ❌ Verify: Tidak ada table hasil perhitungan (sesuai design)
  
Step 4: Close & reopen app → Buka Menu Pengukuran
  ✅ Verify: Perhitungan ulang dilakukan (bukan dari cache)
  ✅ Verify: Hasil sama dengan sebelumnya (calculation logic correct)
```

---

## 📌 CATATAN PENTING

1. **Design Decision**: Sistem dirancang untuk `calculated on-demand`, bukan `persistent cache`
   - Ini adalah design choice yang valid untuk ensuring data consistency
   - Tapi berbeda dari ekspektasi user "simpan hasil perhitungan"

2. **Performance Implication**: 
   - Menu pengukuran = O(n) calculation
   - Untuk 100 mahasiswa & 7 CPL = ~700 calculations per view
   - Sudah ada optimization dengan caching per session

3. **Data Integrity**:
   - Dengan on-demand calculation, selalu pakai data terbaru
   - Tidak ada stale cached data
   - Lebih aman tapi lebih lambat

---

## 🔗 CROSS-REFERENCE

- Import Documentation: [PANDUAN_BATCH_IMPORT_NILAI.md](PANDUAN_BATCH_IMPORT_NILAI.md)
- Measurement Screen: [DOKUMENTASI_INTEGRASI_DATABASE_MEASUREMENT.md](DOKUMENTASI_INTEGRASI_DATABASE_MEASUREMENT.md)
- Calculation Engine: [OBE_CALCULATION_ENGINE.md](OBE_CALCULATION_ENGINE.md)
- Optimization Guide: [OPTIMASI_PERHITUNGAN_CPL.md](OPTIMASI_PERHITUNGAN_CPL.md)

