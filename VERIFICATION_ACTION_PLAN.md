# 📋 Next Steps untuk Verify RPS Data & Diagnose "Tidak Ada Data CPMK"

## 🎯 Objective
Verify bahwa RPS untuk Kalkulus dan Vektor minggu 1-16 sudah ter-set CPL dan CPMK IDs di database, dan diagnose mengapa "Tidak Ada Data CPMK" muncul di assessment_outcomes_screen.

---

## ✅ Code Changes - Sudah Selesai

### 1. Enhanced Debug Logging
**File:** [lib/services/cpmk_cpl_calculation_service.dart](lib/services/cpmk_cpl_calculation_service.dart)

**Changes Made:**
- ✅ Enhanced `loadCPMKForMahasiswa()` - Shows comprehensive loading steps with visual formatting
- ✅ Enhanced `calculateCPMKForMahasiswa()` - Shows step-by-step OBE calculation with detailed output
- ✅ Added stack trace to error handling for better debugging
- ✅ Added specific error messages for each failure point

**Benefits:**
- Clear indication of where data is missing
- Easy-to-read hierarchical debug output
- Actionable error messages (CRITICAL, ISSUE, WARNING, etc.)

### 2. Verification Guide Created
**File:** [RPS_DATA_VERIFICATION_GUIDE.md](RPS_DATA_VERIFICATION_GUIDE.md)

**Contents:**
- Data structure reference
- 3 verification approaches (visual, debug console, SQL)
- Troubleshooting flowchart
- Expected data for Kalkulus
- Quick fix guide

---

## 🚀 NEXT ACTIONS FOR YOU

### **ACTION 1: Run App & Check Debug Output** (15 minutes)

**Step 1: Start App with Debug**
```bash
# In terminal, go to project folder
flutter run -v
```

**Step 2: Navigate to Assessment Screen**
1. Buka Dashboard → Select "Pengukuran Capaian Pembelajaran"
2. Pilih Angkatan (ex: 2024)
3. Pilih Mahasiswa (any student, preferably one with nilai data)

**Step 3: Watch Console Output**
The console will print something like:
```
================================================================================
🔍 LOADING CPMK DATA FOR MAHASISWA 5
================================================================================
DEBUG [loadCPMKForMahasiswa]: Total MK dalam sistem: 12
  └─ MK ID 1: Kalkulus (Kode: MAT101)
  └─ MK ID 2: Vektor (Kode: MAT102)
  ...

DEBUG: MK ID 1 (Kalkulus) punya 1 CPMK
  ├─ CPMK MAT101-01 (ID: 1, Deskripsi: Mahasiswa menguasai konsep integral)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEBUG: Total UNIQUE CPMK dalam sistem: 2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    Calculating score for CPMK MAT101-01 (ID: 1)...
    DEBUG [OBE]: Calculating CPMK 1 (MAT101-01) for mahasiswa 5 using component scores

DEBUG [Step 1] ✅: Using tahun_ajaran: 2024 (latest from 1 records)
DEBUG [Step 2] ✅: Component scores found: [aktivitas, hasil_proyek, kuis, ...]
DEBUG [Step 3] ✅: Component values: [aktivitas=85.0, proyek=80.0, kuis=75.0, ...]
DEBUG [Step 4] ✅: Bobot matrix found with 7 Sub-CPMK entries
DEBUG [Step 5] ✅: Sub-CPMK values calculated: {1: 82.50, 2: 83.75, ...}
DEBUG [Step 6] ✅: CPMK 1 (MAT101-01) calculated: 83.75 (using component scores & RPS bobot)

    ✅ CPMK MAT101-01 (ID: 1) -> Score: 83.75

================================================================================
📊 SUMMARY: Total CPMK dengan nilai untuk mahasiswa 5: 1
✅ SUCCESS: 1 CPMK values calculated
================================================================================
```

**Step 4: Look for ✅ or ❌ Markers**
- ✅ = Data found and working
- ❌ = Data missing (need to identify which step)
- ⚠️ = Warning (might not break calculation but worth fixing)

---

### **ACTION 2: Identify Which Step is Failing**

Based on the debug output, look for the FIRST ❌ marker:

| First ❌ Found | Problem | Fix |
|---|---|---|
| Step 1: `No nilai found` | Mahasiswa tidak ambil course ini | Upload nilai for this student+course |
| Step 2: `No component scores found` | Nilai impor hanya total, bukan breakdown | Re-import dengan component details (aktivitas, kuis, uts, etc) |
| Step 4: `No bobot matrix found` | Bobot belum di-setup | Go to Admin Dashboard → Setup bobot for this MK |
| Step 5-6: `No valid Sub-CPMK weighted sum` | Sub-CPMK bobot issue | Check _getSubCpmkToCpmkBobot() logic |

**If all ✅:** Then CPMK should display! If still not showing, check UI code.

---

### **ACTION 3: Verify RPS Data** (Optional but Recommended)

Use one of the 3 approaches in [RPS_DATA_VERIFICATION_GUIDE.md](RPS_DATA_VERIFICATION_GUIDE.md):

**Approach A: Visual Check (Easiest)**
1. Admin Dashboard → Kelola RPS
2. Select "Kalkulus" → Click "Lihat/Edit"
3. Check minggu 1-16 all have:
   - bobot value (~6.25% each)
   - CPMK IDs assigned
   - CPL IDs assigned

**Approach B: SQL Query (If you have DB viewer)**
```sql
SELECT minggu_ke, bobot, cpmk_ids, cpl_ids, sub_cpmk_ids
FROM rps_detail
WHERE matakuliah_id = (SELECT id FROM matakuliah WHERE nama LIKE '%Kalkulus%')
ORDER BY minggu_ke;
```
Expected: 16 rows, all populated

---

## 📊 Possible Scenarios & Solutions

### **Scenario 1: "TIDAK ADA CPMK YANG TERDAFTAR"**
```
❌ CRITICAL: TIDAK ADA CPMK YANG TERDAFTAR DI DATABASE!
```
**Problem:** No CPMK defined in system
**Fix:** Admin Dashboard → Setup CPMK for courses

---

### **Scenario 2: "No nilai found"**
```
DEBUG [Step 1] ❌: No nilai found for mahasiswa 5 in MK 1
```
**Problem:** Student doesn't have grades enrolled for this course
**Fix:** Upload nilai/grades for this student+course combination

---

### **Scenario 3: "No component scores found"**
```
DEBUG [Step 2] ❌: No component scores found for mahasiswa 5, MK 1, tahun 2024
⚠️ ISSUE: nilai_komponen table does not have record. Did you import component score details?
```
**Problem:** nilai impor hanya nilai_akhir, bukan breakdown (aktivitas, kuis, uts, etc)
**Fix:** 
1. Use component-detailed nilai template
2. Re-import dengan breakdown: aktivitas, hasil_proyek, kuis, tugas, uts, uas

---

### **Scenario 4: "No bobot matrix found"**
```
DEBUG [Step 4] ❌: No bobot matrix found for MK 1
⚠️ ISSUE: Bobot matrix not setup in database. Admin needs to setup bobot.
```
**Problem:** Bobot belum di-setup
**Fix:** Admin Dashboard → Setup Bobot Matrix for each course

---

### **Scenario 5: ✅ Everything Working but CPMK not showing in UI**
```
✅ SUCCESS: 1 CPMK values calculated
[But "Tidak Ada Data CPMK" still shows in assessment screen]
```
**Problem:** Data calculated but UI issue
**Check:**
1. Is `_cpmkScores` map actually populated?
2. Check `_buildCPMKTab()` method - debug why score not displayed
3. May be rendering issue with empty check logic

---

## 📝 Report Template

When you run the app, please provide:

```
MAHASISWA TESTED: [Name, ID]
TAHUN AJARAN: [Year]

KALKULUS:
✅/❌ Total MK dalam sistem > 0
✅/❌ Kalkulus punya CPMK registered
✅/❌ Step 1 (nilai found): ✅ atau error message
✅/❌ Step 2 (component scores): ✅ atau error message
✅/❌ Step 3 (nilai array): ✅ atau error message
✅/❌ Step 4 (bobot matrix): ✅ atau error message
✅/❌ Step 5-6 (calculation): ✅ score or error message

VEKTOR:
[Same as above]

FINAL RESULT:
✅/❌ CPMK showed in assessment screen?
✅/❌ If not, which step failed first?

DEBUG OUTPUT:
[Paste Critical ❌ lines here]
```

---

## 🔧 Quick Reference

### **To Setup RPS:**
1. Admin Dashboard → Kelola RPS
2. Select course
3. For each minggu 1-16:
   - Input bobot (recommend 6.25% each = 100%)
   - Select CPMK IDs
   - Select CPL IDs
   - Input Sub-CPMK IDs

### **To Setup Bobot Matrix:**
1. Admin Dashboard → Setup Bobot
2. Select course
3. For each Sub-CPMK (typically 7):
   - Assign bobot for 6 components: [aktivitas, proyek, kuis, tugas, uts, uas]
4. Save

### **To Import Nilai with Components:**
1. Use nilai template with columns:
   - aktivitas, hasil_proyek, kuis, tugas, uts, uas
2. NOT just nilai_akhir
3. Admin Dashboard → Import Nilai → Upload file
4. System will populate nilai_komponen table

---

## ✅ Verification Checklist

After implementing fixes, verify:

- [ ] Debug output shows "✅ SUCCESS: X CPMK values calculated"
- [ ] No ❌ markers in Step 1-6
- [ ] CPMK values appear in Assessment Outcomes screen
- [ ] RPS minggu 1-16 all populated with bobot + IDs
- [ ] Mahasiswa has nilai for course
- [ ] Component breakdown (aktivitas, kuis, etc) imported
- [ ] Test with multiple students to confirm consistency

---

## 📞 Need Help?

If you're stuck on specific step, check:
1. **Debug output first** - tells you exactly what's missing
2. **Troubleshooting flowchart** in RPS_DATA_VERIFICATION_GUIDE.md
3. **Code comments** in cpmk_cpl_calculation_service.dart
4. **Database schema** in database_helper.dart

---

**🎯 Primary Goal:** Run app, select mahasiswa, capture debug output, identify first ❌, and fix that specific issue.

**Once all ✅, CPMK will display correctly in assessment screen!**
