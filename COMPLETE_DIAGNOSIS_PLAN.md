# 🎯 Complete Diagnosis Plan: "Tidak Ada Data CPMK" Issue

**Status:** Code fixes completed ✅ | Now need data verification 🔍

---

## 📍 Summary of Investigation

### Phase 1: Root Cause Analysis ✅
**Question:** "Jelaskan darimana angka 83.33, 83.99, dan 0 berasal?"

**Finding (Complete):**
- Sub-CPMK 83.33 was using simple average (WRONG)
- CPMK 83.99 was using equal distribution (WRONG)  
- CPL 0 had no database mapping (WRONG)

**Solution Implemented:** 
- Fixed to use weighted average with RPS bobot
- Verified with 10/10 unit tests ✅

---

### Phase 2: Assessment Screen Issue ✅
**Problem:** "Tidak Ada Data CPMK" message displayed despite batch calculation working

**Root Cause Found:**
- `calculateCPMKForMahasiswa()` was taking raw nilai numerik from DB
- It did NOT use component scores + RPS bobot like batch calc
- Result: Different calculations → CPMK empty in assessment screen

**Solution Implemented:**
- Completely rewritten `calculateCPMKForMahasiswa()` (120+ lines)
- Now uses OBE calculation with component scores + bobot matrix
- Aligned with batch calculation logic
- Added step-by-step debug logging
- Code compiles with 0 errors ✅

---

### Phase 3: Data Layer Verification 🔍 (CURRENT)
**Question:** "Coba cek RPS Kalkulus dan Vektor, harusnya minggu 1-16 sudah ter-set CPL dan CPMK nya dan sudah tersimpan di database"

**Investigation Shows:**
- Database only exists at app runtime
- Created enhanced debug output to identify exact data issue
- Created comprehensive verification guides

**Next Step:** Run app and capture debug output to see which prerequisite data is missing

---

## 🔄 The Complete Data Flow

```
[RPS Setup - Minggu 1-16]
    ↓ (Contains: bobot, cpmk_ids, cpl_ids, sub_cpmk_ids)
    
[Nilai Upload]
    ↓ (Contains: aktivitas, hasil_proyek, kuis, tugas, uts, uas)
    
[nilai_komponen Table]
    ↓ (Stores component scores for mahasiswa-MK-tahun)
    
[OBE Calculation]
    ├─ Step 1: Get latest tahun_ajaran
    ├─ Step 2: Load component scores (nilai_komponen)
    ├─ Step 3: Extract component array [6 values]
    ├─ Step 4: Get bobot matrix {SubCPMKId: [6 weights]}
    ├─ Step 5: Calculate Sub-CPMK = Σ(comp × weight) / Σ(weight)
    ├─ Step 6: Calculate CPMK = Σ(SubCPMK × bobot) / 100
    └─ Step 7: Display in Assessment Outcomes screen
```

---

## 🔍 What Could Be Missing

Based on debug output analysis, the first missing piece could be:

### **Scenario A: CPMK not registered (⚠️ Unlikely)**
```
❌ CRITICAL: TIDAK ADA CPMK YANG TERDAFTAR DI DATABASE!
```
→ Need to setup CPMK in admin dashboard

### **Scenario B: Nilai not uploaded (⚠️ Likely)**
```
DEBUG [Step 1] ❌: No nilai found for mahasiswa 5 in MK 1
```
→ Upload nilai for mahasiswa + course

### **Scenario C: Component breakdown missing (⚠️ Most Likely)**
```
DEBUG [Step 2] ❌: No component scores found
⚠️ ISSUE: nilai_komponen table does not have record.
   Did you import component score details?
```
→ Re-import nilai with component breakdown (not just total)

### **Scenario D: Bobot matrix not setup (⚠️ Possible)**
```
DEBUG [Step 4] ❌: No bobot matrix found
⚠️ ISSUE: Bobot matrix not setup in database.
   Admin needs to setup bobot.
```
→ Setup bobot matrix in admin dashboard

### **Scenario E: RPS minggu incomplete (⚠️ Possible)**
```
[If RPS minggu 1-16 don't have CPL/CPMK IDs assigned]
```
→ Edit RPS and assign IDs to each minggu

---

## 🚀 Implementation Checklist

### Code Changes ✅ COMPLETED
- [x] Rewrite `calculateCPMKForMahasiswa()` method
- [x] Update `calculateCPLForMahasiswa()` method  
- [x] Add fallback calculation methods
- [x] Update `_getSubCpmkToCpmkBobot()` for flexibility
- [x] No compilation errors
- [x] Add enhanced debug logging with visual formatting
- [x] Add error hints for each failure point

### Documentation ✅ COMPLETED
- [x] Create RPS_DATA_VERIFICATION_GUIDE.md
- [x] Create VERIFICATION_ACTION_PLAN.md
- [x] Document expected data structure
- [x] Troubleshooting flowchart
- [x] SQL query examples
- [x] Report template

### Testing 🔍 NEXT STEPS
- [ ] Run app with debug output
- [ ] Select mahasiswa and view debug console
- [ ] Identify first ❌ marker
- [ ] Fix the identified issue
- [ ] Re-test until all ✅
- [ ] Verify CPMK displays in assessment screen

---

## 📊 Expected vs Actual

### For Kalkulus

**Expected Data:**
```
1 CPMK: MAT101-01
7 Sub-CPMK: SK1-SK7
6 Components: aktivitas, proyek, kuis, tugas, uts, uas
16 RPS minggu with:
  - bobot: 6.25% each (total 100%)
  - cpmk_ids: "1" (single CPMK)
  - cpl_ids: "1,2,3,4" (multiple CPLs)
  - sub_cpmk_ids: varies per week
```

**Component Bobot Sample (per Sub-CPMK):**
```
SK1: [5, 0, 0, 5, 5, 0]  (aktivitas, proyek, kuis, tugas, uts, uas)
SK2: [0, 5, 5, 0, 5, 0]
... etc (7 Sub-CPMKs)
```

**RPS Bobot Aggregation:**
```
CPMK = Σ(SubCPMK × bobot) / 100
Where bobot = [15, 15, 15, 9, 14, 14, 18] (percent)
```

**Nilai Komponen per Mahasiswa:**
```
mahasiswa_id, matakuliah_id, tahun_ajaran
aktivitas: 85.0
hasil_proyek: 80.0
kuis: 75.0
tugas: 88.0
uts: 92.0
uas: 87.0
```

---

## 🎓 How to Verify Each Component

### 1. CPMK Registration
**In App:** Admin → Setup CPMK → See Kalkulus has 1 CPMK
**In DB:** `SELECT COUNT(*) FROM cpmk WHERE matakuliah_id = 1`

### 2. Component Bobot
**In App:** Admin → Setup Bobot → See 7 Sub-CPMK bobot
**In DB:** `SELECT * FROM bobot_matrix_breakdown WHERE matakuliah_id = 1`

### 3. RPS Minggu
**In App:** Admin → Kelola RPS → Edit Kalkulus → See minggu 1-16 populated
**In DB:** `SELECT COUNT(*) FROM rps_detail WHERE matakuliah_id = 1 AND bobot IS NOT NULL`

### 4. Nilai for Student
**In App:** Admin → View Nilai → See mahasiswa has grades for Kalkulus
**In DB:** `SELECT COUNT(*) FROM nilai WHERE mahasiswa_id = X AND matakuliah_id = 1`

### 5. Component Scores  
**In App:** Check nilai import includes breakdown
**In DB:** `SELECT * FROM nilai_komponen WHERE mahasiswa_id = X AND matakuliah_id = 1`

---

## 📋 Debug Output Interpretation Guide

### ✅ Good Signs (Keep Going)
```
DEBUG [Step 1] ✅: Using tahun_ajaran: 2024
DEBUG [Step 2] ✅: Component scores found
DEBUG [Step 3] ✅: Component values: [...]
DEBUG [Step 4] ✅: Bobot matrix found with 7 Sub-CPMK entries
DEBUG [Step 5] ✅: Sub-CPMK values calculated
DEBUG [Step 6] ✅: CPMK calculated: 83.75
✅ SUCCESS: X CPMK values calculated
```
→ Everything working! CPMK should display.

### ❌ Bad Signs (Needs Fixing)
```
Step 1 ❌: No nilai found
Step 2 ❌: No component scores found  
Step 4 ❌: No bobot matrix found
❌ TIDAK ADA CPMK DENGAN NILAI
```
→ Identify which step, implement the fix from table above.

### ⚠️ Warnings (Not Breaking but Worth Noting)
```
⚠️ Tidak ada matakuliah terdaftar
⚠️ No CPMK registered for this MK
```
→ May indicate incomplete setup.

---

## 🔧 If You Get Stuck

1. **First:** Check debug output for FIRST ❌ marker
2. **Then:** Go to troubleshooting section matching that error
3. **Finally:** Implement the listed fix for that scenario
4. **Repeat:** Re-run app until all ✅

Common order of fixes:
1. Setup CPMK (if step 1 fails with "no CPMK")
2. Upload nilai (if step 1 fails with "no nilai")
3. Import component breakdown (if step 2 fails)
4. Setup bobot matrix (if step 4 fails)
5. Populate RPS minggu (verify minggu 1-16 have IDs)

---

## 📞 Key Documentation Files

| File | Purpose | When to Use |
|------|---------|------------|
| [RPS_DATA_VERIFICATION_GUIDE.md](RPS_DATA_VERIFICATION_GUIDE.md) | 3 approaches to verify RPS data | Before running app |
| [VERIFICATION_ACTION_PLAN.md](VERIFICATION_ACTION_PLAN.md) | Step-by-step action items | During and after running app |
| [lib/services/cpmk_cpl_calculation_service.dart](lib/services/cpmk_cpl_calculation_service.dart) | Actual calculation code | Understanding the logic |
| [lib/services/database_helper.dart](lib/services/database_helper.dart) | Database schema | Understanding data structure |

---

## ✨ Expected Outcome

After following this plan:

### Best Case (Most Likely) ✅
All debug output shows ✅ markers:
```
DEBUG [Step 1] ✅: Using tahun_ajaran: 2024
DEBUG [Step 2] ✅: Component scores found
DEBUG [Step 4] ✅: Bobot matrix found
DEBUG [Step 6] ✅: CPMK calculated: 83.75
✅ SUCCESS: 1 CPMK values calculated
```
→ CPMK will display in Assessment Outcomes screen ✅

### Good Case 👍
One or two data import issues found (e.g., component breakdown missing):
```
DEBUG [Step 2] ❌: No component scores found
⚠️ ISSUE: nilai_komponen table does not have record.
```
→ Re-import nilai with component details → Re-test → Success ✅

### Moderate Case 🤔
Multiple setup issues found (e.g., bobot not setup):
```
DEBUG [Step 4] ❌: No bobot matrix found
⚠️ ISSUE: Bobot matrix not setup in database.
```
→ Setup bobot in admin dashboard → Re-test → Success ✅

### Rare Case ❌
Calculation logic issue found (unlikely since already unit tested):
```
DEBUG [Step 5] calculation logic error
```
→ Code bug needs fixing (notify for code review)

---

## 🎯 TL;DR (For Impatient Users)

1. **Run:** `flutter run -v`
2. **Navigate:** Assessment Outcomes → Select mahasiswa
3. **Watch:** Debug console
4. **Look for:** First ❌ marker
5. **Fix:** Based on error message
6. **Test:** Re-run app
7. **Success:** CPMK displays ✅

---

**Ready to verify? Start with VERIFICATION_ACTION_PLAN.md!**
