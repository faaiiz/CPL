# 📊 DOKUMENTASI - DUALPATH CPL CALCULATION DARI DATABASE

## ⚠️ IMPORTANT: Ada 2 CPL Calculation Paths

Sistem memiliki **2 service calculation yang berbeda**, yang masing-masing menggunakan database dengan cara berbeda:

---

## 🔀 COMPARISON: Dua CPL Calculation Paths

### **Path 1: Traditional CPL (Summary Level)**

**File:** `lib/services/cpl_calculation_service.dart`

**Di-trigger dari:**
- Button "Hitung CPL Semua Mahasiswa" di CPL Calculation Screen
- Route: `/cpl_calculation`

**Calculation Method:**
```
CPL (Final) = Weighted Average of:
├─ IPK (60% bobot) = Σ(nilai_numerik × sks) / Σ(sks)
└─ Rata-rata Nilai (40% bobot) = Σ(nilai_numerik) / count

Example:
├─ Mahasiswa punya nilai untuk 10 matakuliah
├─ IPK = (80×3 + 75×4 + 82×3 + ... ) / total_sks = 78.5
├─ Rata-rata = (80 + 75 + 82 + ...) / 10 = 79.2
├─ CPL = (78.5 × 0.6) + (79.2 × 0.4) = 78.95
└─ Status = "Memenuhi CPL" jika IPK ≥ 2.0, Rata-rata ≥ 2.0, Total SKU ≥ 144
```

**Database Tables Used:**
```
Input:
├─ mahasiswa table
├─ nilai table (nilai_numerik per matakuliah)
└─ matakuliah table (sks per matakuliah)

Output:
└─ cpl table (CPL score & status per mahasiswa)
```

**Result Storage:**
- Disimpan ke `cpl` table
- 1 record per mahasiswa
- Contains: mahasiswa_id, ipk, status, total_sku, rata_nilai, tanggal_hitung

---

### **Path 2: OBE-based CPL Calculation (Detailed Level)**

**File:** `lib/services/cpmk_cpl_calculation_service.dart`

**Di-trigger dari:**
- Assessment Outcomes Screen / Measurement Screen
- Route: `/assessment_outcomes`
- Method: `loadCPLForMahasiswa(mahasiswaId)`

**Calculation Method (6-Step Process):**
```
Step 1: Get component scores untuk setiap CPMK
└─ nilai_komponen [aktivitas, proyek, kuis, tugas, uts, uas]

Step 2: Get bobot matrix untuk SubCPMK
└─ rps_detail_sub_cpmk_bobot

Step 3: Calculate SubCPMK scores
└─ SubCPMK = Σ(komponen × bobot) / Σ(bobot)

Step 4: Calculate CPMK scores
└─ CPMK = Σ(SubCPMK × bobot) / TotalBobot

Step 5: Get CPMK→CPL mappings
└─ cpmk_cpl_mapping dengan bobot

Step 6: Calculate CPL scores
└─ CPL = Σ(CPMK_score × bobot) / TotalBobot

Example:
├─ CPMK.3 (Kalkulus) = 83.75
├─ CPMK.4 (Mekanika) = 93.30
├─ CPMK.5 (Analisis) = 78.45
├─ CPL.4 (linked ke semua CPMK di atas)
├─ CPL.4 = (83.75 × 0.5 + 93.30 × 0.3 + 78.45 × 0.2) / 1.0 = 85.48
└─ Status = "Tercapai" jika CPL ≥ 2.0, "Tidak" jika < 2.0
```

**Database Tables Used:**
```
Input:
├─ cpmk table (CPMK per matakuliah)
├─ cpl_master table (7 CPLs definition)
├─ nilai_komponen table (component scores)
├─ rps_detail_sub_cpmk_bobot table (weekly bobot)
├─ sub_cpmk_cpmk_mapping table (SubCPMK→CPMK bobot)
└─ cpmk_cpl_mapping table (CPMK→CPL bobot)

Output:
└─ Calculated on-the-fly (tidak disimpan ke database)
```

**Result Storage:**
- **NOT persisted** to database
- Calculated real-time saat user query
- Display di Assessment Outcomes Screen

---

## 🎯 KAPAN GUNAKAN MANA?

| Scenario | Path | Service | Screen |
|----------|------|---------|--------|
| Admin ingin hitung CPL summary semua mahasiswa sekaligus | 1 | CPLCalculationService | CPL Calculation Screen |
| Dosen/Admin ingin lihat detail CPMK/CPL per mahasiswa | 2 | CPMKCPLCalculationService | Assessment Outcomes |
| Verifikasi achievement terhadap OBE objectives | 2 | CPMKCPLCalculationService | Assessment Outcomes |
| Generate CPL report dengan IPK & rata-rata nilai | 1 | CPLCalculationService | CPL Report Screen |

---

## 📝 CURRENT IMPLEMENTATION STATUS

### **Path 1: Traditional CPL** ✅
- ✅ Service: Fully implemented
- ✅ Calculation logic: Complete
- ✅ Database persistence: Working (saves to `cpl` table)
- ✅ Screen: CPL Calculation Screen
- ✅ Status: Ready to use

### **Path 2: OBE-based CPL** ✅
- ✅ Service: Fully implemented
- ✅ Calculation logic: Complete with 6-step process
- ✅ Database integration: Full (reads from multiple tables)
- ✅ Screen: Assessment Outcomes Screen
- ✅ Real-time calculation: Working
- ✅ Status: Ready to use

---

## 🔄 DATA FLOW COMPARISON

### **Path 1: Traditional CPL Flow**

```
┌─ Admin Dashboard
│  └─ Menu: "Hitung CPL dan CPMK"
│
├─ CPL Calculation Screen
│  └─ Button: "Hitung CPL Semua Mahasiswa"
│
├─ CPLCalculationService.calculateCPLForAllMahasiswa()
│  ├─ 1. Get all mahasiswa from DB
│  ├─ 2. For each mahasiswa:
│  │  ├─ Get nilai list from DB (nilai table)
│  │  ├─ Get matakuliah list from DB (matakuliah table)
│  │  ├─ Calculate: IPK = Σ(nilai × sks) / Σ(sks)
│  │  ├─ Calculate: Rata-rata = Σ(nilai) / count
│  │  ├─ Determine: Status based on threshold
│  │  └─ Store result to DB (cpl table)
│  │
│  └─ 3. Return calculated CPL list
│
├─ UI Display
│  └─ Show success message: "CPL berhasil dihitung untuk X mahasiswa"
│
└─ Database
   └─ cpl table updated with latestCalclua CPL for all students
```

### **Path 2: OBE-based CPL Flow**

```
┌─ Admin Dashboard
│  └─ Menu: "Pengukuran CPL dan CPMK"
│
├─ Assessment Outcomes Screen (/assessment_outcomes)
│  ├─ 1. Load angkatan list from DB
│  ├─ 2. Load mahasiswa list filtered by angkatan from DB
│  ├─ 3. User select mahasiswa
│  │
│  └─ 4. Load Scores:
│     ├─ CPMKCPLCalculationService.loadCPMKForMahasiswa(id)
│     │  ├─ Get CPMK list from cpmk table
│     │  ├─ Get nilai_komponen from DB
│     │  ├─ Get bobot matrix from rps_detail_sub_cpmk_bobot
│     │  ├─ 6-step calculation process
│     │  └─ Return: [{id, kode, score, ...}, ...]
│     │
│     └─ CPMKCPLCalculationService.loadCPLForMahasiswa(id)
│        ├─ Get CPL list from cpl_master table
│        ├─ Get CPMK scores calculated above
│        ├─ Get CPMK→CPL mappings from cpmk_cpl_mapping
│        ├─ Calculate each CPL from CPMK scores
│        └─ Return: [{id, kodeCPL, score, ...}, ...]
│
├─ UI Display
│  ├─ CPMK Tab: Show all CPMK with scores & status
│  └─ CPL Tab: Show all CPL with scores & status
│
└─ NO Persistence
   └─ Scores calculated on-the-fly, not saved to database
```

---

## 💾 DATABASE STATE COMPARISON

### **After Running Path 1 (Traditional CPL)**

```sql
-- cpl table will have records
SELECT * FROM cpl;
┌────┬──────────────┬─────────────────────┬─────┬────────────┬──────────┬────────────┬──────────────┐
│ id │ mahasiswa_id │ nip_mahasiswa       │ ipk │ status     │ total_sku │ rata_nilai │ tanggal_hitung│
├────┼──────────────┼─────────────────────┼─────┼────────────┼──────────┼────────────┼──────────────┤
│ 1  │ 5            │ 20401201140097      │77.5 │ memenuhi.. │ 144      │ 78.30      │ 2026-03-06..│
│ 2  │ 6            │ 20401201140099      │82.1 │ memenuhi.. │ 144      │ 81.20      │ 2026-03-06..│
│ 3  │ 7            │ 20401201140102      │72.4 │ tidak_me.. │ 144      │ 71.80      │ 2026-03-06..│
└────┴──────────────┴─────────────────────┴─────┴────────────┴──────────┴────────────┴──────────────┘
```

### **Path 2 (OBE-based CPL) - NO Persistence**

```
No direct changes to database.
Scores calculated from existing data:
├─ cpmk scores from: nilai_komponen + rps_detail_sub_cpmk_bobot
└─ cpl scores calculated from: cpmk scores + cpmk_cpl_mapping
```

---

## ✅ INTEGRATION WITH DATABASE - VERIFICATION

### **Path 1 Verification (Traditional CPL)**

```bash
# 1. Check source tables exist
SELECT COUNT(*) FROM nilai;         -- Expected: > 0
SELECT COUNT(*) FROM matakuliah;    -- Expected: > 0

# 2. Run calculation (dari UI)
Admin Dashboard → Hitung CPL dan CPMK → Click "Hitung CPL Semua Mahasiswa"

# 3. Verify results in database
SELECT * FROM cpl WHERE mahasiswa_id = 5;
-- Expected: 1 record with calculated ipk & status

# 4. Check data format
SELECT ipk, status, total_sku FROM cpl LIMIT 5;
-- Expected: IPK in range 0-4.0, Status = memenuhi_cpl|tidak_memenuhi_cpl, SKU >= 144
```

### **Path 2 Verification (OBE-based CPL)**

```bash
# 1. Check source tables exist
SELECT COUNT(*) FROM cpmk;                    -- Expected: > 0
SELECT COUNT(*) FROM cpl_master;              -- Expected: 7
SELECT COUNT(*) FROM cpmk_cpl_mapping;        -- Expected: > 0
SELECT COUNT(*) FROM nilai_komponen;          -- Expected: > 0
SELECT COUNT(*) FROM rps_detail_sub_cpmk_bobot; -- Expected: > 0

# 2. Navigate & view (dari UI)
Admin Dashboard → Pengukuran CPL dan CPMK → Buka Pengukuran
→ Select Angkatan → Select Mahasiswa → Click "Lihat Detail"

# 3. Check data displays in tabs
CPMK Tab: Should show > 0 CPMK with calculated scores
CPL Tab: Should show all 7 CPL with calculated scores

# 4. Verify calculation correctness
Pick one CPMK and verify:
- Get nilai_komponen for that CPMK's matakuliah
- Manually calculate using 6-step process
- Compare with displayed value (should match approximately)
```

---

## ⚙️ OPTIMAL WORKFLOW

### **For Accurate OBE Assessment:**

```
1. Import nilai dengan component breakdown ✅
   └─ Admin Dashboard → Import Nilai
   └─ File format: NIM | Nama | Aktivitas | Proyek | Tugas | Kuis | UTS | UAS

2. Verify nilai_komponen ter-populate di DB ✅
   └─ Query: SELECT COUNT(*) FROM nilai_komponen WHERE tahun_ajaran = ?
   └─ If missing → Use "Fix Nilai Komponen" tool

3. Setup RPS dengan minggu & SubCPMK ✅
   └─ Admin Dashboard → Input RPS
   └─ Setup weeks 1-16 dengan Sub CPMK & bobot matrix

4. Setup CPMK & CPL mappings ✅
   └─ Admin Dashboard → Kelola CPMK & CPL
   └─ Setup bobot untuk CPMK→CPL relationships

5. Run OBE Measurement ✅
   └─ Admin Dashboard → Pengukuran CPL dan CPMK → Buka Pengukuran
   └─ Select mahasiswa & view scores

6. (Optional) Hitung Traditional CPL ✅
   └─ Admin Dashboard → Hitung CPL dan CPMK → Hitung CPL
   └─ For summary IPK & compliance reporting
```

---

## 🎯 SUMMARY TABLE

| Aspect | Path 1 (Traditional) | Path 2 (OBE) |
|--------|----------------------|------|
| **Purpose** | Summary CPL based on IPK & average | Detailed achievement against learning outcomes |
| **Scope** | Institution level | Course & program level |
| **Granularity** | High level (1 CPL per student) | Detailed (7 CPLs + N CPN IKs) |
| **Storage** | Persisted to DB | Calculated on-the-fly |
| **Calculation** | Simple (IPK, average) | Complex (6-step with mappings) |
| **Use Case** | Graduation approval | Learning outcome verification |
| **Screen** | CPL Calculation Screen | Assessment Outcomes Screen |
| **Data Source** | nilai, matakuliah | nilai_komponen, CPMK, CPL, mappings, bobot |
| **Status** | ✅ Working | ✅ Working |

---

## 🔗 Related Implementations

- **Path 1 Screen:** `cpl_calculation_screen.dart`
- **Path 1 Service:** `cpl_calculation_service.dart`
- **Path 2 Screen:** `assessment_outcomes_screen.dart`
- **Path 2 Service:** `cpmk_cpl_calculation_service.dart`
- **Database Layer:** `database_helper.dart`

---

**Status:** ✅ Both paths fully implemented and database-integrated
**Last Updated:** 2026-03-06
