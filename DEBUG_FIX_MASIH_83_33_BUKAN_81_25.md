# 🔧 Debug & Fix: Fisika Matematika I Masih 83.33 (Seharusnya 81.25)

## 📊 Problem Analysis

**Hasil Sekarang**: 83.33 (simple average)  
**Diharapkan**: 81.25 (weighted)

**Penyebab**: Data bobot belum tersimpan di database

---

## 🔍 Step 1: Diagnose - Check Data di Database

Jalankan SQL berikut untuk check:

### A. Check Matakuliah
```sql
SELECT id, nama FROM matakuliah WHERE nama LIKE '%Fisika Matematika%';
-- Expected output: id=?, nama='Fisika Matematika I'
-- Note the matakuliah_id untuk step berikutnya
```

### B. Check Sub-CPMK
```sql
SELECT id, kode_sub_cpmk FROM sub_cpmk WHERE matakuliah_id = ?;
-- Expected: 4 rows (SUB-1, SUB-2, SUB-3, SUB-4)
-- Note the sub_cpmk_id untuk step berikutnya
```

### C. Check Mahasiswa
```sql
SELECT id, nim, nama FROM mahasiswa WHERE nama LIKE '%Vita%';
-- Expected: mahasiswa_id untuk Vita Juwita
```

### D. Check Bobot Komponen (CRITICAL)
```sql
SELECT * FROM sub_cpmk_komponen_bobot WHERE matakuliah_id = ?;
-- Expected: 24 rows (4 Sub-CPMK × 6 komponen)
-- If EMPTY: Bobot belum di-insert! ← THIS IS THE PROBLEM
```

### E. Check Nilai Komponen
```sql
SELECT * FROM nilai_komponen 
WHERE mahasiswa_id = ? AND matakuliah_id = ? AND tahun_ajaran = 2020;
-- Expected: 1 row dengan: nilai_aktivitas=87.5, nilai_proyek=87.5, ...
-- If EMPTY: Nilai komponen belum di-insert!
```

### F. Check RPS Bobot
```sql
SELECT * FROM rps_detail_sub_cpmk_bobot WHERE rps_detail_id IN (
  SELECT id FROM rps_detail WHERE matakuliah_id = ?
);
-- Expected: some rows dengan bobot
-- If EMPTY: RPS bobot belum di-input di UI
```

---

## ✅ Step 2: Insert Missing Data

Jika data kosong dari diagnostic, jalankan INSERT berikut:

### A. Insert Bobot Komponen (Priority 1)
```sql
-- SUB-CPMK 1: [4, 8, 0, 2, 10, 0]
INSERT INTO sub_cpmk_komponen_bobot (matakuliah_id, sub_cpmk_id, komponen_idx, bobot, created_at, updated_at)
VALUES 
  (5, 12, 0, 4, datetime('now'), datetime('now')),      -- Aktivitas
  (5, 12, 1, 8, datetime('now'), datetime('now')),      -- Proyek
  (5, 12, 2, 0, datetime('now'), datetime('now')),      -- Kuis
  (5, 12, 3, 2, datetime('now'), datetime('now')),      -- Tugas
  (5, 12, 4, 10, datetime('now'), datetime('now')),     -- UTS
  (5, 12, 5, 0, datetime('now'), datetime('now'));      -- UAS

-- SUB-CPMK 2: [2, 8, 0, 2, 15, 0]
INSERT INTO sub_cpmk_komponen_bobot (matakuliah_id, sub_cpmk_id, komponen_idx, bobot, created_at, updated_at)
VALUES 
  (5, 13, 0, 2, datetime('now'), datetime('now')),
  (5, 13, 1, 8, datetime('now'), datetime('now')),
  (5, 13, 2, 0, datetime('now'), datetime('now')),
  (5, 13, 3, 2, datetime('now'), datetime('now')),
  (5, 13, 4, 15, datetime('now'), datetime('now')),
  (5, 13, 5, 0, datetime('now'), datetime('now'));

-- SUB-CPMK 3: [2, 6, 0, 2, 0, 5]
INSERT INTO sub_cpmk_komponen_bobot (matakuliah_id, sub_cpmk_id, komponen_idx, bobot, created_at, updated_at)
VALUES 
  (5, 14, 0, 2, datetime('now'), datetime('now')),
  (5, 14, 1, 6, datetime('now'), datetime('now')),
  (5, 14, 2, 0, datetime('now'), datetime('now')),
  (5, 14, 3, 2, datetime('now'), datetime('now')),
  (5, 14, 4, 0, datetime('now'), datetime('now')),
  (5, 14, 5, 5, datetime('now'), datetime('now'));

-- SUB-CPMK 4: [2, 8, 2, 2, 0, 20]
INSERT INTO sub_cpmk_komponen_bobot (matakuliah_id, sub_cpmk_id, komponen_idx, bobot, created_at, updated_at)
VALUES 
  (5, 15, 0, 2, datetime('now'), datetime('now')),
  (5, 15, 1, 8, datetime('now'), datetime('now')),
  (5, 15, 2, 2, datetime('now'), datetime('now')),
  (5, 15, 3, 2, datetime('now'), datetime('now')),
  (5, 15, 4, 0, datetime('now'), datetime('now')),
  (5, 15, 5, 20, datetime('now'), datetime('now'));
```

### B. Insert Nilai Komponen (Priority 2)
```sql
-- Vita Juwita untuk Fisika Matematika I tahun 2020
INSERT INTO nilai_komponen (mahasiswa_id, matakuliah_id, nilai_aktivitas, nilai_proyek, nilai_kuis, nilai_tugas, nilai_uts, nilai_uas, tahun_ajaran, created_at, updated_at)
VALUES (1, 5, 87.5, 87.5, 87.5, 87.5, 60, 90, 2020, datetime('now'), datetime('now'));
-- Change mahasiswa_id=1 to actual Vita's ID from diagnostic step C
```

### C. Insert RPS Bobot (Priority 3)
```sql
-- First, check RPS Detail IDs
SELECT id FROM rps_detail WHERE matakuliah_id = 5;

-- Then insert bobot untuk setiap minggu/Sub-CPMK combination
-- Contoh jika ada 4 minggu, masing-masing ada 1 Sub-CPMK:
INSERT INTO rps_detail_sub_cpmk_bobot (rps_detail_id, sub_cpmk_id, bobot, created_at, updated_at)
VALUES 
  (1, 12, 24, datetime('now'), datetime('now')),  -- Minggu 1, SUB-1, total=24
  (2, 13, 27, datetime('now'), datetime('now')),  -- Minggu 2, SUB-2, total=27
  (3, 14, 15, datetime('now'), datetime('now')),  -- Minggu 3, SUB-3, total=15
  (4, 15, 34, datetime('now'), datetime('now'));  -- Minggu 4, SUB-4, total=34
```

---

## 🔄 Step 3: Recalculate

Setelah insert data:

1. **Delete existing calculation** (untuk force recalculate):
```sql
DELETE FROM cpl_hasil_perhitungan 
WHERE mahasiswa_id = 1 AND matakuliah_id = 5 AND tahun_ajaran = 2020;
```

2. **Di App**: Klik tombol "Hitung" lagi untuk Fisika Matematika I

3. **Check Result**: CPMK seharusnya sekarang = 81.25 ✅

---

## 🐛 Debugging Logs

Setelah klik "Hitung", check console untuk:

### Expected Logs (PATH 1 - Bobot Table):
```
🔍 [_getSubCpmkBobots] Loading Sub-CPMK bobot dari RPS untuk MK=5
   📋 PATH 1: Loading dari tableRPSDetailSubCPMKBobot...
   ✅ RPS bobot data loaded: 4 entries
   📍 RPS minggu untuk MK: 4 minggu
   ✅ PATH 1 SUCCESS: Loaded 4 Sub-CPMK bobot from RPS
      Sub-CPMK 12: total bobot = 24
      Sub-CPMK 13: total bobot = 27
      Sub-CPMK 14: total bobot = 15  ← Note: example might show 22 if components different
      Sub-CPMK 15: total bobot = 34  ← Note: example might show 20 if components different
```

### Expected Logs (Sub-CPMK Calculation):
```
🔍 [calculateSubCPMKValuesOptimized] Mahasiswa=1, MK=5, Tahun=2020
   📦 Nilai Komponen Map: FOUND (6 keys)
   📊 Bobot Matrix: LOADED (4 Sub-CPMK)
   🎯 PATH 1: Using component scores + bobot matrix (WEIGHTED AVERAGE)
   ✅ TRY PATH 1 SUCCESS: Sub-CPMK = {12: 76.04, 13: 72.22, 14: 88.34, 15: 88.98}
```

### Expected Logs (CPMK Calculation):
```
[calculateCPMKValuesOptimized] Loading Sub-CPMK Bobots for weighted calculation
   ✅ Sub-CPMK Bobots loaded: 4 entries
   📌 CPMK IDs for this MK: {1}
   CPMK[1] = 81.25 (weighted) ✅ ← THIS SHOULD APPEAR!
   ✅ TRY PATH 1: Weighted calculation SUCCESS
```

---

## 🎯 If Still 83.33

Jika masih 83.33 setelah insert, berarti:

1. **Sub-CPMK nilai tidak 76.04/72.22/88.34/88.98** → Check nilai komponen
2. **Bobot tidak loaded** → Check console untuk PATH 2 (fallback)
3. **CPMK calculation wrong** → Check database apakah bobot sudah tersimpan

---

## 💾 All ID References

**Important**: Replace dengan actual IDs dari database Anda:
- `matakuliah_id`: dari SELECT matakuliah → id untuk Fisika Matematika I
- `sub_cpmk_id`: dari SELECT sub_cpmk → IDs untuk SUB-1, SUB-2, SUB-3, SUB-4 (misal: 12, 13, 14, 15)
- `mahasiswa_id`: dari SELECT mahasiswa → ID untuk Vita Juwita Sinurat (misal: 1)
- `rps_detail_id`: dari SELECT rps_detail → IDs untuk minggu (misal: 1, 2, 3, 4)
- `tahun_ajaran`: 2020 (dari screenshot)

---

## ✅ Success Criteria

Setelah fix:
- ✅ Console shows "PATH 1 SUCCESS: Loaded X Sub-CPMK bobot"
- ✅ Sub-CPMK nilai = 76.04, 72.22, 88.34, 88.98
- ✅ CPMK nilai = 81.25
- ✅ Screenshot shows CPMK.4 = 81.25 (not 83.33)

---

## 📝 Notes

- `tahun_ajaran = 2020` (dari screenshot)
- `matakuliah_id` likely = 5 (based on previous examples)
- Vita Juwita = `mahasiswa_id` likely = 1
- Sub-CPMK IDs likely = 12, 13, 14, 15
- RPS minggu IDs likely = 1, 2, 3, 4

**Please verify these IDs before running INSERT!**
