# 🎯 QUICK SUMMARY: RPS → Calculation → Display

## 4 Fase Utama

### 📝 FASE 1: INPUT RPS (User Interface)
**File:** `lib/screens/rps_input_screen.dart`

User fills in:
- Topik pembelajaran (learning topic)
- Metode ajar (teaching method)
- Bobot (weight, 0-100%)
- Pilih CPMK, Sub-CPMK, CPL
- Jenis penilaian (assessment type)

**Output:** Data siap disimpan ke database

---

### 💾 FASE 2: SAVE TO DATABASE
**Tables:**
1. **rps_detail** - Main RPS data (16 rows per MK)
   - matakuliah_id, minggu_ke, topik, bobot, cpmk_ids, sub_cpmk_ids, cpl_ids
   
2. **rps_detail_sub_cpmk_bobot** - Bobot per Sub-CPMK per week (14 rows per MK)
   - rps_detail_id, sub_cpmk_id, bobot

3. **nilai_komponen** - Student scores (1 row per student per MK)
   - mahasiswa_id, matakuliah_id, nilai_aktivitas, nilai_proyek, nilai_kuis, nilai_tugas, nilai_uts, nilai_uas

---

### 🧮 FASE 3: CALCULATE CPMK & CPL
**File:** `lib/services/obe_calculation_helper.dart`

```
Nilai Komponen (6 values)
    ↓ × Bobot dari RPS
Sub-CPMK (7 values)
    ↓ × Bobot SubCPMK per MK
CPMK (1 value, karena 1 MK = 1 CPMK)
    ↓ × Aggregated RPS minggu bobot
CPL (N values)
```

**Key Formula:**
```
Sub-CPMK_i = Σ(nilai_j × bobot_j) / Σ(bobot_j)
CPMK = Σ(SubCPMK_i × bobot_i) / 100%
CPL_k = CPMK × (bobot_cpl_k / total_bobot)
```

---

### 📊 FASE 4: DISPLAY IN TABLE
**File:** `lib/screens/admin_dashboard_screen.dart`

```
Tabel: Nilai CPMK & CPL

┌────┬──────────────────┬────────┬────────────────┐
│ No │ Nama Mahasiswa   │ CPMK.1 │ CPL.1          │
├────┼──────────────────┼────────┼────────────────┤
│ 1  │ VITA JUWITA S... │ 83.74  │ 35.25          │
│ 2  │ VIRA INDRA A...  │ 80.84  │ 33.99          │
│ 3  │ APRIDA ICHAS...  │   -    │    -           │
└────┴──────────────────┴────────┴────────────────┘
```

**Key Code:**
```dart
// Extract CPMK/CPL IDs
final cpmkIds = <int>{};
for (final result in results) {
  cpmkIds.addAll(result.cPMKValues.keys);  // ✅ Use legacy getter
}

// Build table rows
for (final cpmkId in cpmkIds) {
  final value = result.cPMKValues[cpmkId];  // ✅ Correct accessor
  cells.add(DataCell(Text(value?.toStringAsFixed(2) ?? '-')));
}
```

---

## 📌 Penting: Key Type Issue

Jangan lupa gunakan **legacy getters** untuk akses CPMK/CPL values:

| ❌ WRONG | ✅ CORRECT |
|---------|-----------|
| `result.cpmkValues[1]` | `result.cPMKValues[1]` |
| `result.cplValues[1]` | `result.cPLValues[1]` |

---

## 📚 File Referensi

Untuk penjelasan detail, lihat:
- **[PANDUAN_WORKFLOW_RPS_LENGKAP.md](PANDUAN_WORKFLOW_RPS_LENGKAP.md)** - Full explanation dengan contoh
- **[DOKUMENTASI_PERHITUNGAN_OBE.md](DOKUMENTASI_PERHITUNGAN_OBE.md)** - OBE calculation details
- **[OBE_CALCULATION_ENGINE.md](OBE_CALCULATION_ENGINE.md)** - Complete API reference

---

## 🚀 Example Data Flow (Vita Juwita Sinurat)

```
INPUT:
├─ Aktivitas: 87.5
├─ Proyek: 87.5
├─ Kuis: 87.5
├─ Tugas: 87.5
├─ UTS: 60.0
└─ UAS: 90.0

RPS BOBOT (dari database):
├─ Sub1: [5%, 0%, 0%, 5%, 5%, 0%]
├─ Sub2: [0%, 5%, 5%, 0%, 5%, 0%]
├─ ... (5 more Sub-CPMK)
└─ Total bobot per Sub = 15% for each

CALCULATION:
├─ Sub1 = (87.5×5 + 87.5×5 + 60×5 + 90×0) / 15 = 78.33
├─ Sub2 = (87.5×5 + 87.5×5 + 60×5 + 90×0) / 15 = 78.33
├─ ... (5 more Sub-CPMK)
├─ CPMK = (78.33×15 + 78.33×15 + ... + 87.92×18) / 100 = 83.74
└─ CPL = CPMK × (bobot_cpl / 100%) = 35.25

DISPLAY:
┌──────┬────────┐
│ CPMK │ CPL    │
├──────┼────────┤
│83.74 │ 35.25  │
└──────┴────────┘
```

---

## ❓ FAQ

**Q: Kenapa nilai menampilkan "-" bukan angka?**
A: Key mismatch. Gunakan legacy getters (`cPMKValues`, `cPLValues`) bukan `cpmkValues`, `cplValues`.

**Q: Berapa bobot yang disimpan di database?**
A: Dua tempat:
1. RPS detail minggu (total 16 minggu = 100%)
2. Bobot per SubCPMK untuk UTS/UAS (untuk dapat 100%)

**Q: Berapa jumlah CPMK per mata kuliah?**
A: Selalu 1 saja. 1 Mata Kuliah = 1 CPMK dengan 7 Sub-CPMK.

**Q: Bagaimana CPL dihitung kalau tidak ada explicit mapping?**
A: CPL dihitung dari aggregated RPS minggu bobot. Setiap minggu mendistribusikan bobot ke CPL IDs yang dipilih.

---

## 📞 Debugging Step

1. Check `rps_detail` table → ada 16 rows untuk setiap MK?
2. Check `rps_detail_sub_cpmk_bobot` → ada bobot untuk UTS/UAS?
3. Check `nilai_komponen` → ada nilai untuk semua komponen?
4. Run calculation → Check console logs dari OBECalculationHelper
5. Check admin dashboard → Gunakan `cPMKValues` & `cPLValues` getters
