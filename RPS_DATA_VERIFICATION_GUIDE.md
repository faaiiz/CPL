# 🔍 RPS Data Verification Guide untuk Kalkulus & Vektor

## Konteks
Anda menanyakan: **"Coba cek RPS Kalkulus dan Vektor, harusnya minggu 1-16 sudah ter-set CPL dan CPMK nya dan sudah tersimpan di database"**

Untuk diagnose mengapa `Tidak Ada Data CPMK` masih muncul di assessment_outcomes_screen, kita perlu verify:
1. ✅ RPS minggu 1-16 sudah populate dengan `cpmk_ids` dan `cpl_ids`?
2. ✅ `nilai_komponen` table ada data component scores untuk mahasiswa?
3. ✅ Calculation path berjalan tanpa error?

---

## 📋 Data Structure Reference

### RPS Detail Table (`rps_detail`)
Setiap minggu harus memiliki:
```
minggu_ke: 1-16 (required)
matakuliah_id: ID dari MK (required)
cpmk_ids: "1" atau "1,2,3" (untuk CPMK terdaftar di minggu itu)
sub_cpmk_ids: "1,2,3" (Sub-CPMK yang diajarkan)
cpl_ids: "1,2,3,4" (CPL yang dicapai)
bobot: 6.25 (untuk 16 minggu, total=100%)
```

### Nilai Komponen Table (`nilai_komponen`)
Untuk setiap mahasiswa-MK-tahun:
```
mahasiswa_id, matakuliah_id, tahun_ajaran (REQUIRED)
aktivitas, hasil_proyek, kuis, tugas, uts, uas (component scores)
```

---

## 🧪 Cara Verify (3 PENDEKATAN)

### **PENDEKATAN 1: Visual Check via RPS Screen** (Paling Mudah)
**Langkah:**
1. Buka app → Dashboard Admin
2. Klik "Kelola RPS Mata Kuliah"
3. Cari "Kalkulus" → Klik "Lihat/Edit"
4. **Check minggu 1-16:**
   - ✅ Setiap minggu punya bobot? (Target: ~6.25% each, total 100%)
   - ✅ Setiap minggu punya CPMK IDs? (Lihat di field "CPMK")
   - ✅ Setiap minggu punya CPL IDs? (Lihat di field "CPL")
5. Ulangi untuk "Vektor"

**Expected Output:**
- Minggu 1: bobot=6.25, cpmk_ids="1", cpl_ids="1,2,3,4"
- Minggu 2: bobot=6.25, cpmk_ids="1", cpl_ids="1,2,3,4"
- ... (semua minggu harus lengkap)

---

### **PENDEKATAN 2: Check Debug Console** (Recommended untuk Technical Details)

#### Step 1: Run App dengan Debug Console
```bash
flutter run -v
```
Atau di VS Code: `Run → Start Debugging (F5)`

#### Step 2: Navigate ke Assessment Outcomes Screen
1. Dashboard → "Pengukuran Capaian Pembelajaran Mata Kuliah"
2. Pilih Angkatan (ex: 2024)
3. Pilih Mahasiswa (ex: any student)

#### Step 3: Watch Debug Console untuk Output
Console akan print detailed info:

```
DEBUG [loadCPMKForMahasiswa]: Total MK dalam sistem: 12
DEBUG: MK ID 1: Kalkulus (Kode: MAT101)
DEBUG: MK ID 1 (Kalkulus) punya 1 CPMK
  - CPMK MAT101-01 (ID: 1, Deskripsi: Mahasiswa menguasai konsep integral)

DEBUG [OBE]: Calculating CPMK 1 for mahasiswa 5 using component scores

DEBUG: Using tahun_ajaran: 2024
DEBUG: Component values: [85.0, 80.0, 75.0, ...]
DEBUG: Sub-CPMK values: {1: 82.5, 2: 81.2, 3: 80.0, ...}
DEBUG: ✅ CPMK 1 calculated: 83.75 (using component scores & RPS bobot)

DEBUG: Total CPMK dengan nilai untuk mahasiswa 5: 1
```

#### Understanding the Output

| Mark | Meaning | Action |
|------|---------|--------|
| ✅ | Data found and calculated | OK |
| ⚠️ | Missing prerequisite data | Need to check that data |
| ❌ | Error in calculation | Bug needs fixing |

**Critical Debug Points:**
1. `Total MK dalam sistem: X` → Ada berapa MK terdaftar?
2. `punya Y CPMK` → Apakah Kalkulus punya 1 CPMK terdaftar?
3. `No nilai found` → Apakah nilai sudah diupload untuk MK ini?
4. `No component scores found` → Apakah nilai impor mencakup breakdown component?
5. `No bobot matrix found` → Apakah bobot sudah di-setup di database?

---

### **PENDEKATAN 3: SQL Query Check** (Untuk Verified Diagnostics)

Jika ada database viewer app / SQLite browser:

#### Query 1: Check RPS Minggu untuk Kalkulus
```sql
SELECT 
  m.nama AS matakuliah_name,
  rd.minggu_ke,
  rd.bobot,
  rd.cpmk_ids,
  rd.cpl_ids,
  rd.sub_cpmk_ids
FROM rps_detail rd
JOIN matakuliah m ON rd.matakuliah_id = m.id
WHERE m.nama LIKE '%almulus%' OR m.kode LIKE '%MAT101%'
ORDER BY rd.minggu_ke;
```

**Expected Result:** 16 rows (minggu 1-16), semua dengan bobot dan IDs populated

#### Query 2: Check Nilai Komponen untuk Student
```sql
SELECT 
  nk.mahasiswa_id,
  m.nama AS mahasiswa_name,
  mk.nama AS matakuliah_name,
  nk.aktivitas, nk.hasil_proyek, nk.kuis, nk.tugas, nk.uts, nk.uas
FROM nilai_komponen nk
JOIN mahasiswa m ON nk.mahasiswa_id = m.id
JOIN matakuliah mk ON nk.matakuliah_id = mk.id
WHERE mk.nama LIKE '%Kalkulus%'
LIMIT 5;
```

**Expected Result:** Rows dengan component scores (aktivitas, kuis, uts, etc. bukan 0 atau NULL)

#### Query 3: Check Bobot Matrix
```sql
SELECT 
  sc.id AS sub_cpmk_id,
  sc.kode,
  bmb.component_bobot
FROM bobot_matrix_breakdown bmb
JOIN sub_cpmk sc ON bmb.sub_cpmk_id = sc.id
WHERE bmb.matakuliah_id = (SELECT id FROM matakuliah WHERE nama LIKE '%Kalkulus%')
ORDER BY sc.id;
```

**Expected Result:** 7 rows (untuk 7 Sub-CPMK Kalkulus) dengan bobot per component

---

## 🔁 Troubleshooting Flowchart

```
Buka Assessment Outcomes → Pilih Mahasiswa → Lihat Debug Output

├─ "Total MK dalam sistem: 0"
│  └─ ❌ ERROR: Tidak ada matakuliah di database
│      └─ ACTION: Setup matakuliah dulu

├─ "MK ID X (Kalkulus) punya 0 CPMK"
│  └─ ❌ ERROR: Kalkulus tidak punya CPMK terdaftar
│      └─ ACTION: Setup CPMK untuk Kalkulus

├─ "No nilai found for mahasiswa X in MK Y"
│  └─ ❌ ERROR: Mahasiswa tidak punya nilai untuk MK ini
│      └─ ACTION: Upload nilai untuk mahasiswa dan MK tersebut

├─ "No component scores found for mahasiswa X, MK Y"
│  └─ ❌ ERROR: Nilai komponen (breakdown) tidak ada
│      └─ ACTION: Make sure nilai import includes component details
│                 (aktivitas, hasil_proyek, kuis, tugas, uts, uas)

├─ "No bobot matrix found for MK X"
│  └─ ❌ ERROR: Bobot belum di-setup
│      └─ ACTION: Setup bobot matrix di admin dashboard

├─ "Component values: [0.0, 0.0, 0.0, ...]"
│  └─ ⚠️ WARNING: Semua component nilai 0
│      └─ ACTION: Check if component scores actually imported correctly
│                 OR nilai impor method hanya import nilai_akhir

└─ "✅ CPMK calculated: 83.75"
   └─ ✅ SUCCESS: Semuanya berjalan dengan baik!
      └─ ACTION: Verify display di UI shows correct value
```

---

## 📊 Expected Data for Kalkulus

Based on previous discussions:

### CPMK Setup
- **Kalkulus** should have **1 CPMK**:
  - ID: probably 1
  - Kode: MAT101-01
  - Deskripsi: something about integral

### Sub-CPMK Setup
- **7 Sub-CPMK** untuk Kalkulus:
  - ID: 1-7
  - Nama: SK1-SK7

### Component Bobot
- **6 components**: aktivitas(5), hasil_proyek(0), kuis(0), tugas(5), uts(5), uas(0)
- Per Sub-CPMK, different combinations (check bobot_matrix_breakdown table)

### RPS Minggu Bobot
- **16 minggu × 100% total**
- Bobot per minggu: [15, 15, 15, 9, 14, 14, 18] pattern
  - **Each minggu maps to one or more Sub-CPMK**
  - **Each minggu should have cpl_ids assigned**
  
### Sample Expected RPS Data
```
Minggu 1:  bobot=6.25%, cpmk_ids="1", sub_cpmk_ids="1,2,3", cpl_ids="1,2,3,4"
Minggu 2:  bobot=6.25%, cpmk_ids="1", sub_cpmk_ids="1,2,3", cpl_ids="1,2,3,4"
...
Minggu 16: bobot=6.25%, cpmk_ids="1", sub_cpmk_ids="6,7", cpl_ids="1,3,4"
```

---

## 🎯 Action Items untuk Anda

### Prioritas 1: VISUAL CHECK
- [ ] Buka app dan navigate ke RPS Kalkulus
- [ ] Check apakah minggu 1-16 semua ter-populate dengan bobot, CPMK IDs, CPL IDs
- [ ] Document apa yang Anda lihat (screenshot atau notes)

### Prioritas 2: DEBUG OUTPUT CHECK
- [ ] Run app dengan `flutter run -v`
- [ ] Go to Assessment Outcomes, select mahasiswa
- [ ] Copy debug console output
- [ ] Share dengan me untuk analysis

### Prioritas 3 (If Needed): SQL QUERY
- [ ] Buka SQLite database viewer (Database Browser for SQLite, atau via code)
- [ ] Run the 3 queries above untuk verify actual database state
- [ ] Report findings

---

## 📝 Report Template

Saat Anda sudah check, please report:

```
KALKULUS RPS:
✅/❌ Minggu 1-16 punya bobot values
✅/❌ Minggu 1-16 punya CPMK IDs
✅/❌ Minggu 1-16 punya CPL IDs
✅/❌ Total bobot = 100%

VEKTOR RPS:
✅/❌ Minggu 1-16 punya bobot values
✅/❌ Minggu 1-16 punya CPMK IDs
✅/❌ Minggu 1-16 punya CPL IDs
✅/❌ Total bobot = 100%

DEBUG OUTPUT (Critical Parts):
[Paste relevant debug console output here]

FINDINGS:
[What data is missing or problematic?]

NEXT STEPS:
[What needs to be fixed or imported?]
```

---

## 🔧 Quick Fixes (Based on Common Issues)

### Issue 1: RPS minggu tidak punya CPMK IDs
**Fix:** Edit RPS → For each minggu, assign CPMK ID (usually "1" for single CPMK per course)

### Issue 2: RPS minggu tidak punya CPL IDs
**Fix:** Edit RPS → For each minggu, assign CPL IDs from Program Structure

### Issue 3: RPS minggu tidak punya bobot
**Fix:** Edit RPS → Distribute 100% across all minggu (typically 16×6.25%)

### Issue 4: Mahasiswa tidak punya nilai komponen
**Fix:** Upload nilai template with component breakdown (not just total nilai)

### Issue 5: Bobot matrix tidak ter-setup
**Fix:** Admin Dashboard → Setup bobot untuk each sub-CPMK

---

## 📚 Related Files

- **Calculation Logic**: [lib/services/cpmk_cpl_calculation_service.dart](lib/services/cpmk_cpl_calculation_service.dart) - Lines 245-334
- **Assessment Screen**: [lib/screens/assessment_outcomes_screen.dart](lib/screens/assessment_outcomes_screen.dart)
- **Database Schema**: [lib/services/database_helper.dart](lib/services/database_helper.dart) - Lines 240-260 (rps_detail table definition)
- **RPS Model**: [lib/models/rps_detail_model.dart](lib/models/rps_detail_model.dart)

---

**Next Step:** Please check the RPS data using one of the 3 approaches and share findings!
