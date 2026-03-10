# 📊 CPL/CPMK Data Structure & Calculation Flow Diagrams

## 1️⃣ COMPLETE DATA HIERARCHY

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PROGRAM LEVEL (CPL)                                │
│                    ┌──────────────────────────┐                            │
│                    │  7 CPL MASTERS (Outcomes)                             │
│                    │  (cpl_master table)                                   │
│                    │                          │                            │
│                    │  CPL.1: Kerjasama        │                            │
│                    │  CPL.2: Kepemimpinan     │                            │
│                    │  CPL.3: Komunikasi       │                            │
│                    │  ... (7 total)           │                            │
│                    └──────────────────────────┘                            │
└────────────────────────────┬─────────────────────────────────────────────────┘
                             │ (cpmk_cpl_mapping table)
                             │ bobot: 0-100% per CPMK
                ┌────────────▼────────────┐
                │ COURSE LEARNING         │
                │ OUTCOMES (CPMK)         │
                │ (cpmk table)            │
                │                         │
                │ One per Matakuliah      │
                │ CPMK.1, CPMK.2, ...     │
                └────────────┬────────────┘
                             │ (sub_cpmk_cpmk_mapping table)
                             │ bobot: 0-100% per Sub-CPMK
                ┌────────────▼────────────────────────┐
                │ WEEKLY LEARNING                     │
                │ OBJECTIVES (SUB-CPMK)               │
                │ (sub_cpmk table)                    │
                │                                     │
                │ Detailed outcomes per week          │
                │ Focus on components:                │
                │ - Aktivitas                         │
                │ - Proyek                            │
                │ - Kuis                              │
                │ - Tugas                             │
                │ - UTS (Midterm)                     │
                │ - UAS (Final Exam)                  │
                └─────────────────────────────────────┘
```

## 2️⃣ STUDENT SCORE DATA FLOW

```
┌──────────────────────────────────────────────────────┐
│ IMPORT COMPONENT SCORES                              │
│ (Excel Template)                                     │
│                                                      │
│ Student | Aktivitas | Proyek | Kuis | Tugas | UTS | UAS │
│ NIM001  |   80      |  75    |  85  |  78   |  82  |  88  │
└──────────────────────┬───────────────────────────────┘
                       │
         ┌─────────────▼──────────────┐
         │ nilai_komponen TABLE        │
         │ (Component Scores)          │
         │ mahasiswa_id | nilai_*      │
         └─────────────┬──────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
 CPMK CALCULATION              SUB-CPMK CALCULATION
        │                             │
        │                    ┌────────▼──────────┐
        │                    │ sub_cpmk_nilai    │
        │                    │ TABLE             │
        │                    │ (SubCPMK Scores)  │
        │                    └────────┬──────────┘
        │                             │
        │         ┌───────────────────┘
        │         │
        └────────┬▼─────────────────────────────┐
                 │ CALCULATE WEIGHTED SCORES    │
                 │ Using RPS Detail Bobot       │
                 │ (rps_detail_sub_cpmk_bobot)  │
                 └────────┬────────────────────┘
                          │
                 ┌────────▼─────────┐
                 │ CPMK SCORE READY │
                 │ (for display)    │
                 └────────┬─────────┘
                          │
                 ┌────────▼─────────────┐
                 │ CPL SCORE READY      │
                 │ (weighted CPMK avg)  │
                 └──────────────────────┘
```

## 3️⃣ CALCULATION FORMULAS

### A. Sub-CPMK Score Calculation

```
Given:
  - Component scores array: [aktivitas, proyek, kuis, tugas, uts, uas]
  - Bobot matrix for Sub-CPMK: [b1, b2, b3, b4, b5, b6]

Formula:
  SubCPMK_Score = Σ(component_value[i] × bobot[i]) / Σ(bobot)

Example:
  Components: [80, 75, 85, 78, 82, 88]
  Bobot:      [10, 15, 15, 10, 25, 25]  (sums to 100)
  
  SubCPMK = (80×10 + 75×15 + 85×15 + 78×10 + 82×25 + 88×25) / 100
         = (800 + 1125 + 1275 + 780 + 2050 + 2200) / 100
         = 8230 / 100
         = 82.30
```

### B. CPMK Score Calculation

```
Given:
  - Multiple Sub-CPMK scores: [SubCPMK1, SubCPMK2, ..., SubCPMKn]
  - Bobot for each Sub-CPMK: [w1, w2, ..., wn]

Formula:
  CPMK_Score = Σ(SubCPMK[i] × bobot[i]) / Σ(bobot)

Example (Kalkulus CPMK from 7 SubCPMKs):
  SubCPMK Scores: [82.30, 78.50, 85.20, 79.10, 81.40, 83.50, 80.20]
  Bobot Matrix:   [15,    15,    15,    9,     14,    14,    18]  (sums to 100)
  
  CPMK = (82.30×15 + 78.50×15 + 85.20×15 + 79.10×9 + 81.40×14 + 83.50×14 + 80.20×18) / 100
       = (1234.50 + 1177.50 + 1278.00 + 711.90 + 1139.60 + 1169.00 + 1443.60) / 100
       = 8154.10 / 100
       = 81.54
```

### C. CPL Score Calculation

```
Given:
  - Multiple CPMK scores that contribute to CPL
  - Bobot for each CPMK: [b1, b2, b3, ..., bn]

Formula:
  CPL_Score = Σ(CPMK[i] × bobot[i]) / Σ(bobot)

Example (CPL.1 from 3 CPMKs):
  CPMK Contributions:
    - Kalkulus (CPMK.1): 81.54 with bobot 40%
    - Vektor (CPMK.2):   79.20 with bobot 35%
    - Diferensial (CPMK.3): 82.10 with bobot 25%
  
  CPL.1 = (81.54×40 + 79.20×35 + 82.10×25) / 100
        = (3261.60 + 2772.00 + 2052.50) / 100
        = 8086.10 / 100
        = 80.86
```

## 4️⃣ DATABASE RELATIONSHIPS DIAGRAM

```
┌─────────────────────────────────┐
│      CPL_MASTER (7 rows)        │
│  id | kode_cpl | deskripsi      │
├─────────────────────────────────┤
│ 1   │ CPL.1    │ Kerjasama...   │
│ 2   │ CPL.2    │ Kepemimpinan.. │
│ ... │ ...      │ ...            │
│ 7   │ CPL.7    │ ...            │
└────┬──────────────────────────────┘
     │ (one-to-many)
     │ Foreign Key: cpl_id
     │
┌────▼──────────────────────────────────┐
│     CPMK_CPL_MAPPING (many rows)      │
│  id | cpmk_id | cpl_id | bobot        │
├────────────────────────────────────────┤
│ 1   │ 1       │ 1      │ 40.0    ← CPMK.1 contributes 40%
│ 2   │ 2       │ 1      │ 35.0    ← CPMK.2 contributes 35%
│ 3   │ 3       │ 1      │ 25.0    ← CPMK.3 contributes 25%
│ 4   │ 1       │ 2      │ 30.0    ← CPMK.1 also contributes to CPL.2
│ ... │ ...     │ ...    │ ...     (many-to-many relationship)
└────┬──────────────────────────────────┘
     │
     │ (one-to-many from CPMK)
     │ Foreign Key: cpmk_id
     │
┌────▼──────────────────────────────────┐
│        CPMK (one per course)           │
│  id | matakuliah_id | kode_cpmk |...  │
├────────────────────────────────────────┤
│ 1   │ 1              │ CPMK.1   │      │
│ 2   │ 1              │ CPMK.2   │      │
│ 3   │ 1              │ CPMK.3   │      │
│ ... │ ...            │ ...      │ ...  │
└────┬──────────────────────────────────┘
     │ (one-to-many)
     │ Foreign Key: cpmk_id
     │
┌────▼──────────────────────────────────────┐
│   SUB_CPMK_CPMK_MAPPING (many rows)      │
│  id | sub_cpmk_id | cpmk_id | bobot      │
├────────────────────────────────────────────┤
│ 1   │ 1           │ 1       │ 15.0       │
│ 2   │ 2           │ 1       │ 15.0       │
│ 3   │ 3           │ 1       │ 15.0       │
│ 4   │ 4           │ 1       │ 9.0        │
│ 5   │ 5           │ 1       │ 14.0       │
│ 6   │ 6           │ 1       │ 14.0       │
│ 7   │ 7           │ 1       │ 18.0       │
│ ... │ ...         │ ...     │ ...        │
└────┬──────────────────────────────────────┘
     │
     │ (one-to-many from SubCPMK)
     │ Foreign Key: sub_cpmk_id
     │
┌────▼──────────────────────────────────┐
│       SUB_CPMK (per course, weekly)    │
│  id | matakuliah_id | kode_sub_cpmk   │
├────────────────────────────────────────┤
│ 1   │ 1              │ SUB-CPMK.1     │
│ 2   │ 1              │ SUB-CPMK.2     │
│ ... │ ...            │ ...             │
│ 7   │ 1              │ SUB-CPMK.7     │
└────┬──────────────────────────────────┘
     │ (linked to RPS Detail)
     │ Foreign Key: sub_cpmk_id
     │
┌────▼────────────────────────────────────┐
│  RPS_DETAIL_SUB_CPMK_BOBOT (weekly)    │
│  id | rps_detail_id | sub_cpmk_id      │
│     | bobot (ARRAY of 6 values)        │
├────────────────────────────────────────┤
│ 1   │ 1              │ 1                │
│     │ [10,15,15,10,25,25]              │
│ 2   │ 1              │ 2                │
│     │ [15,10,20,12,23,20]              │
│ ... │ ...            │ ...              │
└────────────────────────────────────────┘


STUDENT SCORE TABLES:

┌──────────────────────────────────┐
│    NILAI_KOMPONEN (Input)        │
│  mahasiswa_id | matakuliah_id    │
│  nilai_aktivitas (80.0)          │
│  nilai_proyek (75.0)             │
│  nilai_kuis (85.0)               │
│  nilai_tugas (78.0)              │
│  nilai_uts (82.0)                │
│  nilai_uas (88.0)                │
└──────────────────────────────────┘
         │ (input to formula)
         │
         ▼
┌────────────────────────────────────┐
│  SUB_CPMK_NILAI (calculated)       │
│  mahasiswa_id | sub_cpmk_id | nilai│
├────────────────────────────────────┤
│ 1             │ 1            │82.30 │
│ 1             │ 2            │78.50 │
│ 1             │ 3            │85.20 │
│ ... (calculated by OBE engine)     │
└────────────────────────────────────┘
```

## 5️⃣ CALCULATION FLOW - DETAILED SEQUENCE

```
USER ACTION: Select Mahasiswa ID = 1

    │
    ▼
╔═══════════════════════════════════════════╗
║ loadCPMKForMahasiswa(mahasiswaId=1)       ║
╚═══════════════════════════════════════════╝
    │
    ├─ FOR EACH CPMK in system:
    │   │
    │   ▼
    │ ╔═══════════════════════════════════════════════════════════╗
    │ ║ calculateCPMKForMahasiswa(cpmkId, mahasiswaId=1)         ║
    │ ╚═══════════════════════════════════════════════════════════╝
    │   │
    │   ├─ Step 1: Find latest tahun_ajaran for student
    │   │          Query: SELECT * FROM nilai WHERE mahasiswa_id=1
    │   │          Result: tahun_ajaran = 2024
    │   │
    │   ├─ Step 2: Get component scores
    │   │          Query: SELECT * FROM nilai_komponen 
    │   │                 WHERE mahasiswa_id=1 AND matakuliah_id=1
    │   │                       AND tahun_ajaran=2024
    │   │          Result: [aktivitas=80, proyek=75, kuis=85, 
    │   │                   tugas=78, uts=82, uas=88]
    │   │
    │   ├─ Step 3: Extract component array
    │   │          [80.0, 75.0, 85.0, 78.0, 82.0, 88.0]
    │   │
    │   ├─ Step 4: Get bobot matrix
    │   │          Query: SELECT * FROM rps_detail_sub_cpmk_bobot
    │   │                 WHERE rps_detail_id matching course
    │   │          Result: {1: [10,15,15,10,25,25],
    │   │                   2: [15,10,20,12,23,20],
    │   │                   ... }
    │   │
    │   ├─ Step 5: Calculate SubCPMK values
    │   │          For each Sub-CPMK:
    │   │            SubCPMK[i] = Σ(component[j] × bobot[i][j]) / Σ
    │   │          Result: {1: 82.30, 2: 78.50, 3: 85.20, ...}
    │   │
    │   ├─ Step 6: Calculate CPMK
    │   │          Query: SELECT * FROM sub_cpmk_cpmk_mapping
    │   │                 WHERE cpmk_id = current
    │   │          Get weights: {1: 15.0, 2: 15.0, 3: 15.0, ...}
    │   │          CPMK_score = Σ(SubCPMK[i] × weights[i]) / 100
    │   │          Result: 81.54
    │   │
    │   └─ Return: {id: 1, kode: 'CPMK.1', score: 81.54}
    │
    ├─ REPEAT for CPMK.2, CPMK.3, ... (all CPMKs)
    │
    └─ Return: List<Map> with all CPMK scores
         [{id: 1, kode: 'CPMK.1', score: 81.54},
          {id: 2, kode: 'CPMK.2', score: 79.20},
          {id: 3, kode: 'CPMK.3', score: 82.10}]

                │
                ▼
╔═══════════════════════════════════════════════════════╗
║ loadCPLForMahasiswa(mahasiswaId=1) [PARALLEL]        ║
╚═══════════════════════════════════════════════════════╝
    │
    ├─ FOR EACH CPL (7 CPLs):
    │   │
    │   ▼
    │ ╔═══════════════════════════════════════════════════╗
    │ ║ calculateCPLForMahasiswa(cplId, mahasiswaId=1)   ║
    │ ╚═══════════════════════════════════════════════════╝
    │   │
    │   ├─ Query: SELECT * FROM cpmk_cpl_mapping
    │   │         WHERE cpl_id = current
    │   │         Result: [(cpmk_id=1, bobot=40),
    │   │                  (cpmk_id=2, bobot=35),
    │   │                  (cpmk_id=3, bobot=25)]
    │   │
    │   ├─ For each mapped CPMK:
    │   │   └─ Use CPMK score from step above: CPMK.1=81.54
    │   │
    │   ├─ Apply weighting:
    │   │   CPL_score = (81.54×40 + 79.20×35 + 82.10×25) / 100
    │   │            = 80.86
    │   │
    │   └─ Return: {id: 1, kodeCPL: 'CPL.1', score: 80.86}
    │
    ├─ REPEAT for CPL.2, CPL.3, ... (all 7 CPLs)
    │
    └─ Return: List<Map> with all CPL scores


                │
                ▼
    ┌─────────────────────────────────┐
    │  Display in Assessment Outcomes │
    │  Screen with 2 tabs             │
    └─────────────────────────────────┘
```

## 6️⃣ TABLE SUMMARY - Which Table is Used When

```
┌────────────────────────────────────────────────────────────────┐
│              DATA FLOW & TABLE USAGE MAPPING                  │
└────────────────────────────────────────────────────────────────┘

READING PHASE (Display):
├─ cpl_master
│  └─ [getAllCPLMaster()] → Load 7 CPL definitions
├─ cpmk
│  └─ [getCPMKByMatakuliah()] → Load all CPMKs
├─ sub_cpmk
│  └─ [getSubCPMKByMatakuliah()] → Load weekly objectives

CALCULATION PHASE (OBE Engine):
├─ nilai_komponen
│  └─ [getNilaiKomponen()] → Get component scores for student
├─ rps_detail_sub_cpmk_bobot
│  └─ [getRPSBobot()] → Get weighting matrix for components
├─ sub_cpmk_cpmk_mapping
│  └─ [getSubCPMKMapping()] → Get weights SubCPMK→CPMK
├─ cpmk_cpl_mapping
│  └─ [getMappingByCPL()] → Get weights CPMK→CPL

STORAGE PHASE (Save Results):
├─ sub_cpmk_nilai
│  └─ [insertSubCPMKNilai()] → Save SubCPMK scores
├─ cpl (if needed)
│  └─ [insertCPL()] → Save CPL summary

DISPLAY PHASE (UI):
├─ Tab 1: Show CPMK with scores
│  └─ Use: cpmk table + calculated scores from memory
├─ Tab 2: Show CPL with scores
│  └─ Use: cpl_master + calculated scores from memory
└─ Optional Tab 3: Show SubCPMK hierarchy
   └─ Use: sub_cpmk + calculated scores
```

---

**Version:** 1.0  
**Last Updated:** March 6, 2026  
**Status:** ✅ Reference Complete
