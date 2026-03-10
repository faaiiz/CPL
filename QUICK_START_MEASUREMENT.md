# ⚡ QUICK START - AKSES MENU PENGUKURAN CAPAIAN PEMBELAJARAN

## 🎯 Tujuan
Mengakses menu pengukuran dan melihat CPMK/CPL scores yang ter-load dari database dengan ID CPMK dan CPL mahasiswa.

---

## 📝 LANGKAH-LANGKAH (3 Langkah Hanya)

### **Langkah 1: Buka Admin Dashboard**
📍 **Lokasi:** Sidebar Admin
```
Menu pilihan:
- Mahasiswa Management
- Matakuliah Management
- Input RPS
- [Hitung CPL dan CPMK]
- ✨ [Pengukuran CPL dan CPMK] ← KLIK INI
- Import
- Export
```

**Folder structure di screen:**
```
Left Sidebar (15%):          Right Content Area (85%):
├─ Mahasiswa Management
├─ Matakuliah Management
├─ Input RPS
├─ 🧮 Hitung CPL dan CPMK
├─ 📊 Pengukuran CPL... ◄── CLICK HERE
└─ ...

                          ┌─ Content Area akan update
                          │  untuk show measurement options
                          └─ See Card dengan button "Buka Pengukuran"
```

### **Langkah 2: Klik Button "Buka Pengukuran"**
Card content akan show:
```
┌────────────────────────────────────────┐
│ Analisis Capaian Pembelajaran          │
│ per Angkatan                           │
│                                        │
│ 📊 Icon Analytics                      │
│                                        │
│ Lihat tabel mahasiswa per angkatan     │
│ dan detail CPMK/CPL mereka             │
│                                        │
│ [🔗 Buka Pengukuran] ◄── CLICK HERE   │
└────────────────────────────────────────┘
```

**Hasil:** Navigate ke Assessment Outcomes Screen

### **Langkah 3: Select Angkatan & Mahasiswa**

**Screen yang muncul:**
```
═══════════════════════════════════════════════
 Pengukuran Capaian Pembelajaran Mata Kuliah
═══════════════════════════════════════════════

📍 STEP 1: Pilih Angkatan
┌─────────────────────────────┐
│ Dropdown: [2020 ▼]          │← Select tahun angkatan
└─────────────────────────────┘

📍 STEP 2: Pilih Mahasiswa Dari List
┌─────────────────────────────────────────────┐
│ Daftar Mahasiswa Angkatan 2020 (45)         │
├─────────────────────────────────────────────┤
│ NIM          │ Nama                  │ Aksi │
├─────────────────────────────────────────────┤
│ 20401201...  │ VIRA INDRA ASIH       │ ▶️  │◄── Click "Lihat Detail"
│ 20401201...  │ VITA JUWITA SINURAT   │ ▶️  │
│ 20401201...  │ AFRIDA ICHA...        │ ▶️  │
│ ...          │ ...                   │ ... │
└─────────────────────────────────────────────┘

📍 STEP 3: View Hasil
```

**Setelah click "Lihat Detail":**
```
═══════════════════════════════════════════════════════════
 Capaian Pembelajaran Mata Kuliah Mahasiswa
 [20401201140097] VIRA INDRA ASIH | [◄ Kembali]
═══════════════════════════════════════════════════════════

📊 Info Box:
CPMK: 12 | CPL: 7 | CPMK dengan nilai: 8 | CPL dengan nilai: 6

[CPMK] [CPL Prodi] ← Tabs

CPMK Tab (Active):
┌──────────────────────────────────────────────┐
│ Kode CPMK │ Deskripsi │ Nilai │ Status       │
├──────────────────────────────────────────────┤
│ CPMK.1    │ Menjelaskan... │ 78.50 │ ✓ Tercapai │
│ CPMK.2    │ Menganalisis... │ 82.30 │ ✓ Tercapai │
│ CPMK.3    │ Kalkulus... │ 75.00 │ ✓ Tercapai │
│ CPMK.4    │ Mekanika... │ 85.20 │ ✓ Tercapai │
│ ...       │ ...       │ ...   │ ...         │
└──────────────────────────────────────────────┘

CPL Tab:
┌──────────────────────────────────────────────┐
│ Kode CPL │ Deskripsi │ Nilai │ Status       │
├──────────────────────────────────────────────┤
│ CPL.1    │ Mahir dlm... │ 80.15 │ ✓ Tercapai │
│ CPL.2    │ Mampu dlm... │ 78.50 │ ✓ Tercapai │
│ CPL.3    │ Berkomitmen... │ 82.30 │ ✓ Tercapai │
│ ...      │ ...      │ ...   │ ...         │
└──────────────────────────────────────────────┘
```

---

## 🔄 DATA FLOW (Behind The Scenes)

Ketika User klik "Lihat Detail", sistem:

```
1. Get CPMK ID list dari database untuk mahasiswa ini
   └─ SELECT DISTINCT cpmk_id FROM cpmk 
      WHERE matakuliah_id IN (
        SELECT matakuliah_id FROM nilai 
        WHERE mahasiswa_id = 5
      )

2. Untuk setiap CPMK ID, calculate score:
   ├─ Get nilai_komponen[aktivitas, proyek, kuis, tugas, uts, uas]
   ├─ Get bobot matrix dari rps_detail_sub_cpmk_bobot
   ├─ Calculate: (komponen × bobot) = SubCPMK score
   ├─ Calculate: Σ(SubCPMK × bobot) / total = CPMK score
   └─ Return: CPMK ID, kode, deskripsi, score

3. Get CPL ID list dan scores:
   ├─ SELECT * FROM cpl_master (7 CPLs)
   ├─ Get CPMK→CPL mapping dari cpmk_cpl_mapping
   ├─ Calculate: Σ(CPMK_score × bobot) / total = CPL score
   └─ Return: CPL ID, kode, deskripsi, score

4. Display di tab view dengan status:
   ├─ Score ≥ 2.0 → "Tercapai" (green)
   └─ Score < 2.0 → "Tidak Tercapai" (red)
```

---

## ✅ VERIFICATION - PASTIKAN DATA SUDAH LOADED DARI DATABASE

### **Check 1: Database punya data CPMK dan CPL**
```sql
-- Check CPMK data
SELECT COUNT(*) FROM cpmk;
-- Expected: > 0 (jumlah CPMK yang ter-setup)

-- Check CPL data  
SELECT COUNT(*) FROM cpl_master;
-- Expected: 7 (standard CPL count)

-- Check mappings
SELECT COUNT(*) FROM cpmk_cpl_mapping;
-- Expected: > 0 (relationship antara CPMK dan CPL)
```

### **Check 2: Database punya nilai komponen**
```sql
-- Untuk mahasiswa 2020 (VIRA INDRA ASIH)
SELECT COUNT(*) FROM nilai_komponen 
WHERE mahasiswa_id = 5 AND tahun_ajaran = 2020;
-- Expected: > 0 (component scores sudah ter-import/ter-populate)

-- Check sample values
SELECT mahasiswa_id, matakuliah_id, nilai_aktivitas, nilai_uts, nilai_uas
FROM nilai_komponen
WHERE mahasiswa_id = 5
LIMIT 3;
```

### **Check 3: UI Loading Correctly**

**Scenario: Click "Lihat Detail" untuk VIRA INDRA ASIH**

✅ **Success Signs:**
- Loading spinner muncul saat call database
- CPMK Tab shows > 0 records
- CPL Tab shows 7 records (CPL count)
- Scores visible dengan format 0.00
- Status badge shows "Tercapai" atau "Tidak Tercapai"

❌ **Error Signs:**
- Blank tab dengan message "Tidak Ada Data CPMK"
- → Likely: `nilai_komponen` missing → Use fix tool!
- → Fix: Run "Fix Nilai Komponen" tool (see separate doc)

---

## 🔗 SYSTEM INTEGRATION SUMMARY

| Component | Status | Purpose |
|-----------|--------|---------|
| **Admin Dashboard Menu** | ✅ Implemented | Quick access to measurement |
| **Assessment Outcomes Screen** | ✅ Implemented | Main measurement UI |
| **Database Tables** | ✅ Setup | Store CPMK/CPL/mappings/values |
| **Calculation Service** | ✅ Implemented | Load & calculate scores da database |
| **Data Loading** | ✅ Working | Async load via `loadCPMKForMahasiswa()` |
| **Score Display** | ✅ Working | Show calculated scores in tabs |
| **Status Indicators** | ✅ Working | Show Tercapai/Tidak Tercapai |

**Result:** ✅ **All components integrated with database successfully**

---

## 🎯 WHAT HAPPENS WHEN USER MEASURES ACHIEVEMENT

1. **User navigates** via Admin Dashboard → "Pengukuran CPL dan CPMK" → "Buka Pengukuran"

2. **Screen loads mahasiswa list** filtered by selected angkatan (from database)

3. **User selects mahasiswa** → Click "Lihat Detail"

4. **System queries database:**
   - Get all CPMK IDs that this mahasiswa has nilai for
   - Get component scores (nilai_komponen)
   - Get bobot matrices (rps_detail_sub_cpmk_bobot)
   - Get CPL master & mappings

5. **System calculates:**
   - Weighted component → SubCPMK scores
   - SubCPMK scores → CPMK scores
   - CPMK scores → CPL scores

6. **Results displayed in UI:**
   - CPMK Tab: shows all CPMK with scores
   - CPL Tab: shows all CPL with scores
   - Each with status indicator (Tercapai/Tidak Tercapai)

7. **Data persisted:** ✅ (from database, not stored UI-only)

---

## 📞 TROUBLESHOOTING

| Problem | Cause | Solution |
|---------|-------|----------|
| "Tidak Ada Data CPMK" | nilai_komponen missing | Run "Fix Nilai Komponen" tool |
| Screen blank/empty | Mahasiswa not selected | Click "Lihat Detail" button |
| Scores show 0.00 | Calculation error | Check bobot matrix setup |
| Slow loading | Large dataset | Wait or check DB performance |

---

## 📚 RELATED DOCUMENTATION

- **Full Integration Details:** [DOKUMENTASI_INTEGRASI_DATABASE_MEASUREMENT.md](DOKUMENTASI_INTEGRASI_DATABASE_MEASUREMENT.md)
- **Fix Missing Data:** [PANDUAN_FIX_NILAI_KOMPONEN.md](PANDUAN_FIX_NILAI_KOMPONEN.md)
- **Calculation Engine:** [OBE_CALCULATION_ENGINE.md](OBE_CALCULATION_ENGINE.md)

---

**Time to access measurement:** ~30 seconds
**System status:** ✅ Ready to use
**Database integration:** ✅ Complete
