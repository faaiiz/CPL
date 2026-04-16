# 🔧 FIX: Sub-CPMK Bobot Aggregation dari RPS

## Masalah
Bobot Sub-CPMK sedang **didistribusikan secara salah**:
- UTS (total 25%) dibagi **rata** ke semua Sub-CPMK (5 Sub-CPMK = 5% per Sub-CPMK ❌)
- UAS (total 25%) dibagi **rata** ke semua Sub-CPMK (5 Sub-CPMK = 5% per Sub-CPMK ❌)

Padahal seharusnya:
- Sub-CPMK 276: UTS bobot 6
- Sub-CPMK 277: UTS bobot 6
- Sub-CPMK 278: UTS bobot 7
- Sub-CPMK 280: UAS bobot 8
- Sub-CPMK 281: UAS bobot 9
- Sub-CPMK 282: UAS bobot 8

## Root Cause
Method `_getSubCpmkBobotMapFromDatabase()` menggunakan **generic bobot** dari RPS:
```dart
final bobot = rpsDetail.bobot ?? 0.0;  // 25% untuk UTS
for (final subCpmkId in subCpmkIds) {  // Loop semua Sub-CPMK
  result[subCpmkId]![komponenName] += bobot;  // Tambah 25% ke semua ❌
}
```

## Solusi
Tabel **`rps_detail_sub_cpmk_bobot`** menyimpan bobot **spesifik per Sub-CPMK**:

| rps_detail_id | sub_cpmk_id | bobot | assessment_type |
|---|---|---|---|
| 1 (UTS minggu X) | 276 | 6.0 | uts |
| 1 (UTS minggu X) | 277 | 6.0 | uts |
| 1 (UTS minggu X) | 278 | 7.0 | uts |
| 2 (UAS minggu Y) | 280 | 8.0 | uas |
| 2 (UAS minggu Y) | 281 | 9.0 | uas |
| 2 (UAS minggu Y) | 282 | 8.0 | uas |

### Fix Implementation
```dart
// ✅ Baca bobot SPESIFIK per Sub-CPMK dari rps_detail_sub_cpmk_bobot
final bobotPerSubCpmk = await _dbHelper.getRPSDetailSubCPMKBobot(rpsDetailId);

for (final bobotRow in bobotPerSubCpmk) {
  final subCpmkId = bobotRow['sub_cpmk_id'];
  final bobot = (bobotRow['bobot'] as num?)?.toDouble() ?? 0.0;
  
  // Gunakan bobot SPESIFIK untuk Sub-CPMK ini
  result[subCpmkIdStr]![komponenName] += bobot;  // ✅ Benar
}
```

## Hasil Setelah Fix

### Before (❌ SALAH)
```
🎯 BOBOT SUB-CPMK (dari RPS):
   Sub-CPMK 276:
      - tugas: 2.50%
      - uts: 25.00%     ← SALAH! Seharusnya 6.0
   Sub-CPMK 277:
      - proyek: 5.00%
      - uts: 25.00%     ← SALAH! Seharusnya 6.0
   ...
```

### After (✅ BENAR)
```
🎯 BOBOT SUB-CPMK (dari RPS):
   Sub-CPMK 276:
      - aktivitas partisipatif: 6.0    ✅
      - tugas: 2.5                     ✅
      - uts: 6.0                       ✅
   Sub-CPMK 277:
      - proyek: 5.0                    ✅
      - uts: 6.0                       ✅
   Sub-CPMK 278:
      - kuis: 7.0                      ✅
      - tugas: 5.0                     ✅
      - uts: 7.0                       ✅
   ...
```

## Fallback Logic
Jika table `rps_detail_sub_cpmk_bobot` **kosong** (data tidak tersimpan), sistem akan:
1. Gunakan generic bobot dari `rpsDetail.bobot`  
2. Bagikan secara **equal** ke semua Sub-CPMK dalam RPS detail tersebut
3. Print warning: `[FALLBACK]`

Contoh:
```
⚠️  Minggu 1 (UTS): Tidak ada bobot di rps_detail_sub_cpmk_bobot - using fallback
   Minggu 1: Sub-CPMK 276 += 5.00 untuk uts [FALLBACK]
   Minggu 1: Sub-CPMK 277 += 5.00 untuk uts [FALLBACK]  ← Fallback jika data tidak ada
```

## File Yang Diubah
- **[lib/services/obe_calculation_helper.dart](lib/services/obe_calculation_helper.dart)**
  - Method: `_getSubCpmkBobotMapFromDatabase()`
  - Lokasi: Lines 1030-1090 (approx)

## Implementasi Data Source

### 1️⃣ Ensure RPS Data Disimpan Benar
Saat import RPS/setup, pastikan table `rps_detail_sub_cpmk_bobot` terisi dengan bobot spesifik per Sub-CPMK.

**Schema:**
```sql
CREATE TABLE rps_detail_sub_cpmk_bobot (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rps_detail_id INTEGER,
  sub_cpmk_id INTEGER,
  bobot REAL,  -- Bobot spesifik untuk Sub-CPMK ini (e.g., 6.0, 7.0, 8.0, 9.0)
  created_at DATETIME,
  updated_at DATETIME,
  FOREIGN KEY (rps_detail_id) REFERENCES rps_detail(id),
  FOREIGN KEY (sub_cpmk_id) REFERENCES sub_cpmk(id)
);
```

### 2️⃣ Verification Query
Untuk verify data tersimpan benar:
```sql
SELECT 
  rd.minggu_ke,
  rd.jenis_nilai,
  rd.bobot as rps_generic_bobot,
  dsb.sub_cpmk_id,
  dsb.bobot as specific_bobot
FROM rps_detail rd
LEFT JOIN rps_detail_sub_cpmk_bobot dsb ON rd.id = dsb.rps_detail_id
WHERE rd.matakuliah_id = 5
ORDER BY rd.minggu_ke, rd.jenis_nilai, dsb.sub_cpmk_id;
```

Expected output:
```
minggu_ke | jenis_nilai | rps_generic_bobot | sub_cpmk_id | specific_bobot
--------+-------------+------------------+-------------+--------------
   1     | uts         |      25.0        |    276      |      6.0
   1     | uts         |      25.0        |    277      |      6.0
   1     | uts         |      25.0        |    278      |      7.0
  16     | uas         |      25.0        |    280      |      8.0
  16     | uas         |      25.0        |    281      |      9.0
  16     | uas         |      25.0        |    282      |      8.0
```

## Testing
Jalankan:
```bash
dart run lib/services/obe_calculation_helper.dart
# atau
flutter run --release
```

Debug output akan menampilkan:
```
Minggu 1: Sub-CPMK 276 += 6.00 untuk uts
Minggu 1: Sub-CPMK 277 += 6.00 untuk uts
Minggu 1: Sub-CPMK 278 += 7.00 untuk uts
```

Dibandingkan dengan sebelumnya yang menampilkan:
```
Minggu 1: Sub-CPMK 276 += 25.00 untuk uts   ❌ SALAH
Minggu 1: Sub-CPMK 277 += 25.00 untuk uts   ❌ SALAH
Minggu 1: Sub-CPMK 278 += 25.00 untuk uts   ❌ SALAH
```

## Related Methods
- `_dbHelper.getRPSDetailSubCPMKBobot(rpsDetailId)` - Read bobot per Sub-CPMK
- `_dbHelper.getRPSDetailSubCPMKBobotSingle(rpsDetailId, subCpmkId)` - Read single bobot
- `calculateBatchOBEResultsForMatakuliah()` - Now uses corrected aggregation

## Notes
✅ Automatic fallback jika data kosong (tidak error)  
✅ Backward compatible dengan RPS lama  
✅ Debug output menunjukkan source [dari rps_detail_sub_cpmk_bobot vs FALLBACK]  
✅ Per-Sub-CPMK bobot sekarang BENAR sesuai RPS
