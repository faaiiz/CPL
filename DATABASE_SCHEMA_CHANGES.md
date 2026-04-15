# 📊 DATABASE SCHEMA - OBE CALCULATION ENGINE v3

## 🔧 REQUIRED SCHEMA CHANGES

### NEW TABLE: `sub_cpmk_bobot`

This table stores the weight of each component (aktivitas, proyek, kuis, tugas, uts, uas) for each Sub-CPMK within each mata kuliah.

```sql
CREATE TABLE sub_cpmk_bobot (
  id INT PRIMARY KEY AUTO_INCREMENT,
  matakuliah_id INT NOT NULL,
  sub_cpmk_id INT NOT NULL,
  komponen_type VARCHAR(50) NOT NULL, -- 'aktivitas', 'proyek', 'kuis', 'tugas', 'uts', 'uas'
  bobot DECIMAL(10, 2) NOT NULL DEFAULT 0,  -- Component weight in this Sub-CPMK
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY unique_sub_cpmk_komponen (matakuliah_id, sub_cpmk_id, komponen_type),
  FOREIGN KEY (matakuliah_id) REFERENCES matakuliah(id) ON DELETE CASCADE,
  FOREIGN KEY (sub_cpmk_id) REFERENCES sub_cpmk(id) ON DELETE CASCADE
);
```

**Example Data**:
```
matakuliah_id | sub_cpmk_id | komponen_type | bobot
1             | 10          | aktivitas     | 10.00
1             | 10          | proyek        | 20.00
1             | 10          | kuis          | 15.00
1             | 10          | tugas         | 15.00
1             | 10          | uts           | 20.00
1             | 10          | uas           | 20.00
              |             |               | ----- (Tot: 100.00) ✓
```

---

### ENHANCED TABLE: `sub_cpmk_cpmk` or `cpmk_sub_cpmk`

This table should already exist. Verify it has proper structure:

```sql
CREATE TABLE IF NOT EXISTS cpmk_sub_cpmk (
  id INT PRIMARY KEY AUTO_INCREMENT,
  cpmk_id INT NOT NULL,
  sub_cpmk_id INT NOT NULL,
  bobot DECIMAL(10, 2) NOT NULL,  -- Sub-CPMK weight in this CPMK
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY unique_cpmk_subcpmk (cpmk_id, sub_cpmk_id),
  FOREIGN KEY (cpmk_id) REFERENCES cpmk(id) ON DELETE CASCADE,
  FOREIGN KEY (sub_cpmk_id) REFERENCES sub_cpmk(id) ON DELETE CASCADE
);
```

**Example Data**:
```
cpmk_id | sub_cpmk_id | bobot
1       | 10          | 20.00
1       | 11          | 15.00
1       | 12          | 15.00
1       | 13          | 15.00
1       | 14          | 15.00
1       | 15          | 20.00
        |             | ----- (Tot: 100.00) ✓
```

---

### ENHANCED TABLE: `cpl_cpmk` or `cpmk_cpl`

Add `bobot` column if not exists:

```sql
ALTER TABLE cpl_cpmk ADD COLUMN bobot DECIMAL(10, 2) DEFAULT 1.00;

-- Or create if not exists
CREATE TABLE IF NOT EXISTS cpl_cpmk (
  id INT PRIMARY KEY AUTO_INCREMENT,
  cpl_id INT NOT NULL,
  cpmk_id INT NOT NULL,
  bobot DECIMAL(10, 2) NOT NULL DEFAULT 1.00,  -- CPMK weight in CPL aggregation
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY unique_cpl_cpmk (cpl_id, cpmk_id),
  FOREIGN KEY (cpl_id) REFERENCES cpl(id) ON DELETE CASCADE,
  FOREIGN KEY (cpmk_id) REFERENCES cpmk(id) ON DELETE CASCADE
);
```

**Example Data**:
```
cpl_id | cpmk_id | bobot
1      | 1       | 30.00
1      | 2       | 35.00
1      | 3       | 35.00
       |         | ----- (Tot: 100.00) ✓
```

---

## 🔍 EXISTING TABLES TO VERIFY

### 1. `nilai_komponen` (Component Grades)

Verify this table has all component grades fields:

```sql
DESC nilai_komponen;

-- Should have columns:
-- - mahasiswa_id
-- - matakuliah_id
-- - tahun_ajaran
-- - nilai_aktivitas (0-100)
-- - nilai_proyek (0-100)
-- - nilai_kuis (0-100)
-- - nilai_tugas (0-100)
-- - nilai_uts (0-100)
-- - nilai_uas (0-100)
```

**Constraint**: All `nilai_*` columns should be **NOT NULL** (after data cleanup)

```sql
ALTER TABLE nilai_komponen MODIFY nilai_aktivitas DECIMAL(5,2) NOT NULL;
ALTER TABLE nilai_komponen MODIFY nilai_proyek DECIMAL(5,2) NOT NULL;
ALTER TABLE nilai_komponen MODIFY nilai_kuis DECIMAL(5,2) NOT NULL;
ALTER TABLE nilai_komponen MODIFY nilai_tugas DECIMAL(5,2) NOT NULL;
ALTER TABLE nilai_komponen MODIFY nilai_uts DECIMAL(5,2) NOT NULL;
ALTER TABLE nilai_komponen MODIFY nilai_uas DECIMAL(5,2) NOT NULL;
```

---

### 2. `rps_detail` (Learning Outcomes by Week)

Verify Sub-CPMK mapping:

```sql
DESC rps_detail;

-- Should have:
-- - rps_id
-- - minggu (week number)
-- - sub_cpmk_ids (JSON or comma-separated string of Sub-CPMK IDs)
```

---

### 3. `sub_cpmk` & `cpmk` & `cpl`

These base reference tables should exist:

```sql
DESC sub_cpmk;
-- id, nama, deskripsi, cpmk_id, created_at, updated_at

DESC cpmk;
-- id, nama, deskripsi, prodi_id, created_at, updated_at

DESC cpl;
-- id, nama, deskripsi, prodi_id, created_at, updated_at
```

---

## 🛠️ MIGRATION SCRIPT (MySQL)

### Step 1: Create sub_cpmk_bobot Table

```sql
CREATE TABLE sub_cpmk_bobot (
  id INT PRIMARY KEY AUTO_INCREMENT,
  matakuliah_id INT NOT NULL,
  sub_cpmk_id INT NOT NULL,
  komponen_type VARCHAR(50) NOT NULL,
  bobot DECIMAL(10, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY unique_sub_cpmk_komponen (matakuliah_id, sub_cpmk_id, komponen_type),
  FOREIGN KEY (matakuliah_id) REFERENCES matakuliah(id) ON DELETE CASCADE,
  FOREIGN KEY (sub_cpmk_id) REFERENCES sub_cpmk(id) ON DELETE CASCADE
);

CREATE INDEX idx_matakuliah_subcpmk ON sub_cpmk_bobot(matakuliah_id, sub_cpmk_id);
```

### Step 2: Make nilai_komponen Stricter

```sql
-- Ensure no NULL values
UPDATE nilai_komponen SET nilai_aktivitas = 0 WHERE nilai_aktivitas IS NULL;
UPDATE nilai_komponen SET nilai_proyek = 0 WHERE nilai_proyek IS NULL;
UPDATE nilai_komponen SET nilai_kuis = 0 WHERE nilai_kuis IS NULL;
UPDATE nilai_komponen SET nilai_tugas = 0 WHERE nilai_tugas IS NULL;
UPDATE nilai_komponen SET nilai_uts = 0 WHERE nilai_uts IS NULL;
UPDATE nilai_komponen SET nilai_uas = 0 WHERE nilai_uas IS NULL;

-- Add NOT NULL constraints
ALTER TABLE nilai_komponen 
  MODIFY nilai_aktivitas DECIMAL(5,2) NOT NULL,
  MODIFY nilai_proyek DECIMAL(5,2) NOT NULL,
  MODIFY nilai_kuis DECIMAL(5,2) NOT NULL,
  MODIFY nilai_tugas DECIMAL(5,2) NOT NULL,
  MODIFY nilai_uts DECIMAL(5,2) NOT NULL,
  MODIFY nilai_uas DECIMAL(5,2) NOT NULL;
```

### Step 3: Add bobot to cpl_cpmk

```sql
-- Check if column exists (if not, add it)
ALTER TABLE cpl_cpmk ADD COLUMN bobot DECIMAL(10, 2) DEFAULT 1.00;

-- Set default equal weight if null
UPDATE cpl_cpmk SET bobot = 1.0 WHERE bobot IS NULL OR bobot = 0;
```

### Step 4: Populate sub_cpmk_bobot (Template)

```sql
-- Insert equal distribution as starting point
-- Replace matakuliah_id and sub_cpmk_ids accordingly

INSERT INTO sub_cpmk_bobot (matakuliah_id, sub_cpmk_id, komponen_type, bobot)
SELECT 
  1 as matakuliah_id,  -- Replace with actual MK ID
  10 as sub_cpmk_id,   -- Replace with actual Sub-CPMK ID
  'aktivitas' as komponen_type,
  16.67 as bobot
UNION ALL SELECT 1, 10, 'proyek', 16.67
UNION ALL SELECT 1, 10, 'kuis', 16.67
UNION ALL SELECT 1, 10, 'tugas', 16.67
UNION ALL SELECT 1, 10, 'uts', 16.67
UNION ALL SELECT 1, 10, 'uas', 16.67;

-- Repeat for each Sub-CPMK in the mata kuliah
```

---

## 📋 DATA VALIDATION QUERIES

### Check Weight Sums

```sql
-- Sub-CPMK weights should sum to 100 for each (MK, Sub-CPMK)
SELECT 
  matakuliah_id,
  sub_cpmk_id,
  SUM(bobot) as total_bobot,
  CASE 
    WHEN SUM(bobot) = 100 THEN '✓ OK'
    ELSE '❌ WRONG'
  END as status
FROM sub_cpmk_bobot
GROUP BY matakuliah_id, sub_cpmk_id
HAVING SUM(bobot) != 100;

-- CPMK weights should sum to 100 for each CPMK
SELECT 
  cpmk_id,
  SUM(bobot) as total_bobot,
  CASE 
    WHEN SUM(bobot) = 100 THEN '✓ OK'
    ELSE '❌ WRONG'
  END as status
FROM cpmk_sub_cpmk
GROUP BY cpmk_id
HAVING SUM(bobot) != 100;

-- CPL weights should sum to 100 for each CPL (ideally)
SELECT 
  cpl_id,
  SUM(bobot) as total_bobot,
  CASE 
    WHEN SUM(bobot) = 100 THEN '✓ OK'
    ELSE '⚠️ NOT 100'
  END as status
FROM cpl_cpmk
GROUP BY cpl_id
HAVING SUM(bobot) != 100;
```

### Check for Missing Grades

```sql
-- Find students with NULL or missing component grades
SELECT 
  mahasiswa_id,
  matakuliah_id,
  tahun_ajaran,
  CASE WHEN nilai_aktivitas IS NULL THEN '❌' ELSE '✓' END as aktivitas,
  CASE WHEN nilai_proyek IS NULL THEN '❌' ELSE '✓' END as proyek,
  CASE WHEN nilai_kuis IS NULL THEN '❌' ELSE '✓' END as kuis,
  CASE WHEN nilai_tugas IS NULL THEN '❌' ELSE '✓' END as tugas,
  CASE WHEN nilai_uts IS NULL THEN '❌' ELSE '✓' END as uts,
  CASE WHEN nilai_uas IS NULL THEN '❌' ELSE '✓' END as uas
FROM nilai_komponen
WHERE nilai_aktivitas IS NULL
  OR nilai_proyek IS NULL
  OR nilai_kuis IS NULL
  OR nilai_tugas IS NULL
  OR nilai_uts IS NULL
  OR nilai_uas IS NULL
ORDER BY matakuliah_id, mahasiswa_id;
```

---

## 🔐 REFERENTIAL INTEGRITY

All foreign keys should be properly set up:

```sql
-- Check existing constraints
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'your_database'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```

---

## 💾 BACKUP RECOMMENDATIONS

Before running migrations:

```sql
-- Backup existing data
CREATE TABLE backup_sub_cpmk_bobot AS 
SELECT * FROM sub_cpmk_bobot WHERE 1=0; -- Structure only

-- Or use MySQL command:
-- mysqldump your_database > backup_$(date +%Y%m%d).sql
```

---

## 📌 IMPLEMENTATION ORDER

1. ✅ **Backup database**
2. ✅ **Create new sub_cpmk_bobot table**
3. ✅ **Add bobot column to cpl_cpmk** (if needed)
4. ✅ **Clean up NULL values in nilai_komponen**
5. ✅ **Add NOT NULL constraints**
6. ✅ **Populate sub_cpmk_bobot** with actual weights from RPS
7. ✅ **Validate weight sums** using SQL queries above
8. ✅ **Test OBE calculation** with new schema
9. ✅ **Deploy refactored code** with validation enabled

---

## 🚨 ROLLBACK PLAN

If issues occur:

```sql
-- Drop new table if needed
DROP TABLE IF EXISTS sub_cpmk_bobot;

-- Restore old constraints on nilai_komponen (if removed strictly)
-- Check backup for original schema

-- Revert cpl_cpmk if needed
ALTER TABLE cpl_cpmk DROP COLUMN bobot;
```

---

## ✅ VALIDATION CHECKLIST

Before putting in production:

- [ ] `sub_cpmk_bobot` table created with proper constraints
- [ ] `cpl_cpmk` has `bobot` column
- [ ] All `nilai_komponen` are NOT NULL
- [ ] Weight sums validated ≈ 100 for each (MK, Sub-CPMK) pair
- [ ] No orphaned foreign keys
- [ ] Sample data loaded and tested
- [ ] Calculation results match expected values
- [ ] Error handling tested with invalid data
- [ ] Batch processing tested with multiple students

---

