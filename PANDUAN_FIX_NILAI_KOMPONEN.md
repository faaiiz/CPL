# 🔧 PANDUAN FIX: Nilai Mata Kuliah Tidak Tertampil di CPMK

## 📋 RINGKASAN MASALAH

**Gejala:**
- Mahasiswa punya nilai untuk 3 mata kuliah (Fisika Dasar II, Kalkulus & Vektor, Mekanika)
- Tapi di Assessment Outcomes screen, muncul "Tidak Ada Data CPMK"
- CPMK Score = 0 (seharusnya ada nilai)

**Penyebab Root:**
Nilai yang ter-import hanya mencakup **nilai akhir saja**, tanpa breakdown detail komponen:
- Aktivitas
- Hasil Proyek
- Kuis
- Tugas
- UTS
- UAS

Sistem CPL memerlukan data komponen ini untuk menghitung CPMK. Jika data komponen tidak ada = CPMK tidak bisa dihitung.

---

## 🔍 ALUR YANG TERJADI

```
┌─ Assessment Outcomes Screen
│  └─ Mau display CPMK untuk mahasiswa
│      └─ Panggil calculateCPMKForMahasiswa()
│          └─ Step 2: Cari nilai_komponen di database
│              │
│              ├─ ✅ ADA: Hitung CPMK, display normalement
│              │
│              └─ ❌ TIDAK ADA:
│                  └─ Return null
│                  └─ CPMK = kosong
│                  └─ Display "Tidak Ada Data CPMK"
```

---

## ✅ SOLUSI

Ada 2 pilihan:

### **OPSI 1: Re-import dengan Komponen Detail (RECOMMENDED)**

**Langkah-langkah:**

1. **Persiapkan Excel/CSV dengan format yang benar:**
   ```
   NIM | Nama | Aktivitas | Hasil Proyek | Tugas | Kuis | UTS | UAS
   ------|------|-----------|-------------|-------|------|-----|-----
   2020-001 | VIRA INDRA ASIH | 80 | 85 | 75 | 78 | 72 | 76
   ```

2. **Buka Admin Dashboard → Import Nilai → Pilih matakuliah**

3. **Upload file Excel/CSV dengan detail komponen**

4. **Sistem akan otomatis:**
   - Validate setiap komponen (0-100)
   - Insert ke `nilai` table (nilai akhir)
   - Insert ke `nilai_komponen` table (component breakdown) ✅

### **OPSI 2: Auto-Fix Existing Data (CEPAT)**

Jika nilai akhir sudah ter-import, gunakan **Fix Nilai Komponen Tool** untuk auto-populate:

**Langkah-langkah:**

1. **Buka Admin Dashboard**
2. **Cari menu "Fix Nilai Komponen"** (icon wrench/build)
3. **Pilih mahasiswa: VIRA INDRA ASIH**
4. **Klik "Diagnosa"** → Lihat data mana saja yang hilang
5. **Klik "Fix All"** → Auto-populate dengan proporsi standard

**Proporsi Standard yang Digunakan:**
- Aktivitas: 15%
- Proyek: 15%
- Kuis: 15%
- Tugas: 15%
- UTS: 20%
- UAS: 20%

**Contoh:**
- Jika nilai akhir = 80
- Maka: Aktivitas=12, Proyek=12, Kuis=12, Tugas=12, UTS=16, UAS=16

---

## 🔧 MENGGUNAKAN FIX NILAI KOMPONEN SCREEN

### **Step 1: Buka Tool**
- Admin Dashboard → "Fix Nilai Komponen" → Klik "Buka Tool"

### **Step 2: Pilih Mahasiswa**
- Dropdown → Cari "VIRA INDRA ASIH"
- Klik untuk select

### **Step 3: Diagnosa Dulu**
- Klik "Diagnosa" button
- Lihat output untuk memastikan masalahnya

**Output akan menunjukkan:**
```
🔍 ===== DIAGNOSTIC HASIL NILAI KOMPONEN =====
Mahasiswa ID: 123

✅ Mahasiswa: VIRA INDRA ASIH (NIM: 2020-001)
📚 Total nilai: 3

❌ MISSING: Fisika Dasar II (Tahun: 2020)
   - Nilai Akhir: 80
   - 🔴 NILAI_KOMPONEN TIDAK ADA DI DATABASE

❌ MISSING: Kalkulus dan Vektor (Tahun: 2020)
   - Nilai Akhir: 75
   - 🔴 NILAI_KOMPONEN TIDAK ADA DI DATABASE

❌ MISSING: Mekanika (Tahun: 2020)
   - Nilai Akhir: 82
   - 🔴 NILAI_KOMPONEN TIDAK ADA DI DATABASE

========================================
```

### **Step 4: Fix Everything**
- Klik "Fix All" button
- Konfirmasi di dialog
- Tunggu hingga selesai

**Output akan menunjukkan:**
```
🔧 BATCH FIX NILAI KOMPONEN =====
Mahasiswa ID: 123

✅ Fixed: MK 5 - {nilaiAkhir: 80, aktivitas: 12.0, ...}
✅ Fixed: MK 6 - {nilaiAkhir: 75, aktivitas: 11.25, ...}
✅ Fixed: MK 7 - {nilaiAkhir: 82, aktivitas: 12.3, ...}

📊 SUMMARY:
  ✅ Fixed: 3
  ⏭️  Skipped: 0
  ❌ Failed: 0
```

### **Step 5: Verify**
- Buka Assessment Outcomes Screen
- Pilih VIRA INDRA ASIH
- Lihat CPMK score sudah muncul ✅

---

## 📊 VERIFIKASI HASIL

Setelah fix, cek database untuk memastikan data tersimpan:

**Query untuk mengecek:**
```sql
SELECT * FROM nilai_komponen 
WHERE mahasiswa_id = (SELECT id FROM mahasiswa WHERE nim = '2020-001')
```

**Output yang diharapkan:**
```
| id | mahasiswa_id | matakuliah_id | nilai_aktivitas | nilai_proyek | nilai_kuis | nilai_tugas | nilai_uts | nilai_uas | tahun_ajaran |
|----|--------------|---------------|-----------------|--------------|-----------|-----------|-----------|-----------|--------------|
| 1  | 5            | 10            | 12.0            | 12.0         | 12.0      | 12.0      | 16.0      | 16.0      | 2020         |
| 2  | 5            | 11            | 11.25           | 11.25        | 11.25     | 11.25     | 15.0      | 15.0      | 2020         |
| 3  | 5            | 12            | 12.3            | 12.3         | 12.3      | 12.3      | 16.4      | 16.4      | 2020         |
```

---

## ⚠️ PENTING!

### **Kapan Menggunakan Opsi 1 vs Opsi 2?**

| Situasi | Opsi 1 (Re-import) | Opsi 2 (Auto-fix) |
|---------|-------------------|------------------|
| Nilai baru diimport | ✅ GUNAKAN | ❌ Tidak perlu |
| Nilai sudah ada, komponen hilang | ✅ BISA JUGA | ✅ PILIH INI (lebih cepat) |
| Ingin kontrol detail komponen | ✅ GUNAKAN | ❌ Proporsi fixed |
| Urgent fix | ❌ Lama | ✅ GUNAKAN |

### **Catatan:**

1. **Auto-fix menggunakan proporsi standard** (15,15,15,15,20,20) - Ini adalah distribusi umum untuk mata kuliah.
   
2. **Jika ingin proporsi berbeda**, gunakan Opsi 1 (re-import) dengan file Excel yang sudah di-customize proporsinya.

3. **Data yang sudah ter-fix tidak bisa di-undo otomatis** - Jika perlu revert, harus manual delete/update di database.

4. **Fix tool akan skip data yang sudah ada komponen-nya** - Aman untuk di-run berkali-kali.

---

## 🚀 QUICK START

### **Untuk fix VIRA INDRA ASIH sekarang:**

1. Buka Admin Dashboard
2. Scroll down, cari menu "Fix Nilai Komponen" (icon wrench)
3. Klik "Buka Tool"
4. Dropdown → Select "VIRA INDRA ASIH"
5. Klik "Diagnosa" untuk lihat detail
6. Klik "Fix All" untuk auto-populate
7. ✅ Selesai! CPMK sekarang akan muncul

---

## 📞 TROUBLESHOOTING

### **Q: "Fix All" masih tidak berhasil?**
A: Mungkin ada masalah lain:
- Cek apakah "CPL" sudah ter-setup di database
- Cek apakah "RPS" sudah complete dengan bobot matrix
- Cek diagnostic output untuk error detail

### **Q: Proporsi standard tidak sesuai?**
A: Edit file `lib/utils/fix_nilai_komponen.dart`, ubah line:
```dart
final aktivitas = nilaiAkhir * 0.15;  // Ubah 0.15 menjadi proporsi lain
final uts = nilaiAkhir * 0.20;        // Dst
```

### **Q: Cara mannually edit nilai_komponen?**
A: Gunakan database tool (e.g., DB Browser for SQLite), open file `cpl_app.db`, edit table `nilai_komponen` langsung.

---

## 📚 RELATED FILES

- **Diagnostic Utility:** `lib/utils/fix_nilai_komponen.dart`
- **UI Screen:** `lib/screens/fix_nilai_komponen_screen.dart`
- **Calculation Engine:** `lib/services/cpmk_cpl_calculation_service.dart` (line 280-286)
- **Database Layer:** `lib/services/database_helper.dart`

---

**Last Updated:** 2026-03-06 | **Status:** ✅ Ready to Use
