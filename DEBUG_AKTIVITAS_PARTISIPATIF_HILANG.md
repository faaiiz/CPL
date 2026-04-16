# 🔍 Debugging: Aktivitas Partisipatif Hilang

## Apa Yang Diubah

Saya perbaiki kode untuk:
1. **Fallback lebih robust** - menghandle case ketika rps_detail_sub_cpmk_bobot kosong
2. **Assessment type parsing lebih fleksibel** - case-insensitive dan trim whitespace
3. **Debug output lebih detail** - menunjukkan DIMANA data aktivitas partisipatif berada

## Cara Menemukan Masalah

Jalankan batch calculation (ini akan otomatis menampilkan debug output):

```dart
final results = await helper.calculateBatchOBEResultsForMatakuliah(
  matakuliahId: 5,  // Fisika Matematika I
  tahunAjaran: 2024,
);
```

## Debug Output Yang Akan Muncul

### Scenario 1: Data DITEMUKAN di rps_detail_sub_cpmk_bobot ✅
```
Minggu 1:
  📊 Data RPS:
     - Topik: ...
     - Jenis Penilaian: Aktivitas Partisipatif
     - Bobot: 25%
     - Sub-CPMK (dari RPS): 1,2,3,4,5,6,7
     - rps_detail_sub_cpmk_bobot: ✅ 2 rows
        └─ Sub-CPMK 276: bobot=6
        └─ Sub-CPMK 282: bobot=4

📊 Aggregating bobot dari RPS Details + rps_detail_sub_cpmk_bobot:
   📌 Minggu 1: "Aktivitas Partisipatif" → komponen "aktivitas"
   ✅ Minggu 1 (Aktivitas Partisipatif): Found 2 rows di rps_detail_sub_cpmk_bobot
   └─ Sub-CPMK 276 += 6.00 untuk aktivitas      ✅
   └─ Sub-CPMK 282 += 4.00 untuk aktivitas      ✅
```

**Result:** Aktivitas partisipatif 6.00 dan 4.00 akan ditampilkan dengan benar!

### Scenario 2: Data TIDAK ditemukan di rps_detail_sub_cpmk_bobot ❌
```
Minggu 1:
  📊 Data RPS:
     - Topik: ...
     - Jenis Penilaian: Aktivitas Partisipatif
     - Bobot: 25%
     - Sub-CPMK (dari RPS): 1,2,3,4,5,6,7
     - rps_detail_sub_cpmk_bobot: ❌ NO DATA (fallback akan digunakan)

📊 Aggregating bobot dari RPS Details + rps_detail_sub_cpmk_bobot:
   📌 Minggu 1: "Aktivitas Partisipatif" → komponen "aktivitas"
   ⚠️  Minggu 1 (Aktivitas Partisipatif, bobot=25.00%): Tidak ada data di rps_detail_sub_cpmk_bobot
   └─ Sub-CPMK 276 += 3.57 untuk aktivitas [FALLBACK - divided by 7]      ❌
   └─ Sub-CPMK 277 += 3.57 untuk aktivitas [FALLBACK - divided by 7]      ❌
   ...
```

**Problem:** Aktivitas partisipatif = 3.57 untuk semua (dibagi 7 Sub-CPMK), bukan 6 dan 4!

### Scenario 3: RPS Detail tidak punya subCpmkIds ⚠️
```
   - Sub-CPMK (dari RPS): ❌ NONE (empty or null)
   - rps_detail_sub_cpmk_bobot: ❌ NO DATA
   
⚠️ subCpmkIds kosong - distribusi ke SEMUA Sub-CPMK
```

## Solusi Berdasarkan Output

### ✅ Jika Scenario 1 (Data Ada)
Aktivitas partisipatif akan bekerja dengan baik. Tidak ada yang perlu diperbaiki.

### ❌ Jika Scenario 2 (Data Hilang dari rps_detail_sub_cpmk_bobot)
Data aktivitas partisipatif bobot spesifik per Sub-CPMK **TIDAK tersimpan** di table `rps_detail_sub_cpmk_bobot`. 

**Penyebab Umum:**
1. RPS belum diimpor dengan benar
2. Table `rps_detail_sub_cpmk_bobot` belum dipopulate saat import
3. Data dihapus atau tidak tersimpan

**Solusi:**
- Verify/re-import RPS dengan benar
- Ensure `rps_detail_sub_cpmk_bobot` tersimpan saat setup RPS

### ⚠️ Jika Scenario 3 (subCpmkIds Kosong)
RPS detail untuk aktivitas partisipatif tidak punya informasi Sub-CPMK mana yang affected.

**Penyebab:**
- Saat setup RPS, Sub-CPMK tidak di-assign
- RPS structure belum complete

**Solusi:**
- Setup RPS dengan assign Sub-CPMK untuk tiap assessment type

## Data Structure Yang Perlu Dicek

### Table: rps_detail
```sql
SELECT 
  id, minggu_ke, jenis_nilai, bobot, sub_cpmk_ids, 
  matakuliah_id
FROM rps_detail
WHERE matakuliah_id = 5
  AND jenis_nilai LIKE '%aktivitas%'
ORDER BY minggu_ke;
```

Expected:
- `jenis_nilai` = "Aktivitas Partisipatif" atau variant
- `bobot` = 25 (atau value tertentu)
- `sub_cpmk_ids` = daftar Sub-CPMK yang affected, atau NULL untuk apply ke semua

### Table: rps_detail_sub_cpmk_bobot
```sql
SELECT d.minggu_ke, d.jenis_nilai, b.sub_cpmk_id, b.bobot
FROM rps_detail d
LEFT JOIN rps_detail_sub_cpmk_bobot b ON d.id = b.rps_detail_id
WHERE d.matakuliah_id = 5
  AND d.jenis_nilai LIKE '%aktivitas%'
ORDER BY d.minggu_ke, b.sub_cpmk_id;
```

Expected untuk aktivitas partisipatif:
```
minggu_ke | jenis_nilai           | sub_cpmk_id | bobot
---------+-----------------------+-------------+-------
    1     | Aktivitas Partisipatif|    276      |  6.0
    1     | Aktivitas Partisipatif|    282      |  4.0
```

Jika hasil kosong atau NULL bobot → ini masalahnya!

## Testing Steps

1. **Run batch calculation:**
   ```dart
   await helper.calculateBatchOBEResultsForMatakuliah(
     matakuliahId: 5,
     tahunAjaran: 2024,
   );
   ```

2. **Check debug output untuk aktivitas partisipatif:**
   - Cari "Aktivitas Partisipatif" di console
   - Lihat apakah: ✅ Found X rows atau ❌ NO DATA

3. **Database verify:**
   - Run query yang di atas
   - Pastikan data activation partisipatif tersimpan dengan bobot spesifik

4. **If data is missing:**
   - Check RPS setup/import
   - Ensure `rps_detail_sub_cpmk_bobot` diisi dengan correct data

## Related Code Changes

- **File**: `lib/services/obe_calculation_helper.dart`
- **Method**: `_getSubCpmkBobotMapFromDatabase()`
- **Changes**:
  - Improved fallback logic
  - Better assessment type parsing
  - Enhanced debug logging

## Next Steps

1. Jalankan code dan share debug output untuk "aktivitas"
2. I'll identify exactly mana yang missing
3. Provide targeted fix based pada output
