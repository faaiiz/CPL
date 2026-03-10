# ⚡ QUICK FIX CHECKLIST - 5 Menit

## 🎯 Tujuan
Tampilkan nilai CPMK untuk VIRA INDRA ASIH (dan mahasiswa lain dengan masalah sama)

## ✅ Langkah-Langkah

### 1️⃣ **Rebuild App** (2 menit)
```bash
cd e:\1. S2 Fisika\5. Tesis\Flutter\chili_app\CPL\cpl
flutter clean
flutter pub get
flutter run
```

### 2️⃣ **Login & Buka Admin Dashboard** (1 menit)
- Login dengan akun admin
- Dashboard akan terbuka

### 3️⃣ **Scroll & Cari "Fix Nilai Komponen"** (30 detik)
- Scroll down di dashboard
- Cari menu card dengan icon **wrench/build**
- Judul: "Fix Nilai Komponen"

### 4️⃣ **Klik "Buka Tool"** (30 detik)
- Screen baru akan terbuka

### 5️⃣ **Select Mahasiswa** (30 detik)
- Dropdown "Pilih Mahasiswa"
- Cari: **VIRA INDRA ASIH**
- Klik untuk select

### 6️⃣ **Klik "Diagnosa"** (1 menit)
- Lihat output di bawah
- Akan show 3 mata kuliah yang hilang nilai_komponen:
  - ❌ Fisika Dasar II
  - ❌ Kalkulus dan Vektor
  - ❌ Mekanika

### 7️⃣ **Klik "Fix All"** (1 menit)
- Dialog akan muncul
- Confirm dengan klik "Lanjutkan"
- Tunggu hingga selesai
- Output akan show: **✅ Fixed: 3**

### 8️⃣ **Verify Hasil** (1 menit)
- Buka **Assessment Outcomes Screen**
- Pilih mahasiswa: **VIRA INDRA ASIH**
- Pilih tahun: **2020**
- ✅ CPMK Score sekarang harus ada nilai (bukan "Tidak Ada Data CPMK")

---

## ✨ Result
✅ **CPMK Sekarang Tertampil!**

---

## 🔔 Jika Ada Error

| Error | Solusi |
|-------|--------|
| "Pilih mahasiswa terlebih dahulu" | Pastikan dropdown sudah selected |
| "Tidak Ada Data" di diagnostic | Mahasiswa belum ada nilai, import dulu |
| Fix berhasil tapi CPMK masih kosong | Restart app, atau check RPS setup |

---

## 📝 Logika yang Terjadi

```
Fix tool akan:
1. Ambil nilai akhir (e.g., 80)
2. Bagi ke 6 komponen dengan proporsi:
   - Aktivitas 15% = 12.0
   - Proyek 15% = 12.0
   - Kuis 15% = 12.0
   - Tugas 15% = 12.0
   - UTS 20% = 16.0
   - UAS 20% = 16.0
3. Insert ke database
4. ✅ CPMK calculation sekarang bisa run
```

---

**Total waktu: ~10 menit**

Need more detail? Baca file:
- `PANDUAN_FIX_NILAI_KOMPONEN.md` (detailed guide)
- `IMPLEMENTASI_FIX_NILAI_KOMPONEN.md` (technical details)
