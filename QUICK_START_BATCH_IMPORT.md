# Quick Start Guide - Batch Import Nilai

## Scenario: Import Nilai Sistem Informasi Semester Ganjil 2024

Anda adalah koordinator akademik dan perlu mengimport nilai 3 mata kuliah untuk tahun ajaran 2024 semester ganjil.

### Persiapan File

#### File 1: algoritma.xlsx (Format Detail)
```
NIM       | Nama Mahasiswa    | Aktivitas | Tugas | Kuis | UTS | UAS
2401001   | Ahmad Hidayat     | 85        | 88    | 80   | 75  | 82
2401002   | Budi Santoso      | 78        | 82    | 75   | 70  | 78
2401003   | Citra Dewi        | 92        | 90    | 88   | 85  | 90
2401004   | Dedy Gunawan      | 65        | 70    | 65   | 60  | 68
2401005   | Eka Putri         | 88        | 85    | 82   | 80  | 85
```

**Header Info (baris 1-2):**
```
Tahun Ajaran: | 2024
Nama Matakuliah: | Algoritma & Pemrograman
```

#### File 2: struktur_data.xlsx (Format Detail)
```
NIM       | Nama Mahasiswa    | Aktivitas | Tugas | Kuis | UTS | UAS
2401001   | Ahmad Hidayat     | 80        | 85    | 78   | 72  | 80
2401002   | Budi Santoso      | 75        | 78    | 72   | 68  | 75
2401003   | Citra Dewi        | 90        | 88    | 85   | 82  | 88
2401004   | Dedy Gunawan      | 60        | 65    | 60   | 55  | 62
2401005   | Eka Putri         | 85        | 82    | 80   | 78  | 82
```

#### File 3: database.xlsx (Format Sederhana)
```
NIM       | Nama Mahasiswa    | Grade
2401001   | Ahmad Hidayat     | A
2401002   | Budi Santoso      | B
2401003   | Citra Dewi        | A
2401004   | Dedy Gunawan      | C
2401005   | Eka Putri         | A
```

### Langkah-Langkah Execution

#### 1. Buka Aplikasi CPL
- Launch aplikasi CPL/Chili App
- Navigate ke menu **Input Nilai**

#### 2. Akses Batch Import
- Klik tombol **Cloud Upload** (☁) di top right of AppBar
- Screen akan menampilkan **Batch Import Nilai**

#### 3. Pilih Tahun Ajaran
```
Dropdown: Tahun Ajaran
Pilih: 2024
```

#### 4. Select Multiple Files
Proses:
1. Klik area upload atau tombol "Klik untuk menambah file"
2. Browse ke folder dengan file:
   - algoritma.xlsx
   - struktur_data.xlsx
   - database.xlsx

Atau:
- Pilih algoritma.xlsx → Klik Open
- Klik area upload lagi → Pilih struktur_data.xlsx
- Klik area upload lagi → Pilih database.xlsx

**Hasil:**
```
File terpilih: 3
- algoritma.xlsx ✕
- struktur_data.xlsx ✕
- database.xlsx ✕

[Hapus Semua] button
```

#### 5. Review File List
- Pastikan 3 file ada dalam daftar
- Setiap file bisa dihapus dengan tombol ✕

#### 6. Mulai Import
- Klik tombol **"Mulai Import Batch"**
- Tunggu hingga selesai

### Expected Output - Success Case

#### Progress Indicator
```
Memproses file 1 dari 3...
Memproses file 2 dari 3...
Memproses file 3 dari 3...
[████████████████████] 100%
```

#### Result Summary (Success)
```
✓ Import berhasil: Diproses: 3 file, Berhasil: 15 nilai, Gagal: 0 nilai

┌──────────────────────────────────────┐
│ File Diproses: 3                     │
│ Nilai Berhasil: 15                   │
│ Nilai Gagal: 0                       │
└──────────────────────────────────────┘

Detail Hasil Per File:

✓ algoritma.xlsx
  Berhasil: 5  Gagal: 0

✓ struktur_data.xlsx
  Berhasil: 5  Gagal: 0

✓ database.xlsx
  Berhasil: 5  Gagal: 0
```

#### Data Tersimpan
Sistem akan otomatis:
1. ✓ Tambah 5 mahasiswa (jika belum ada)
2. ✓ Tambah 3 matakuliah (jika belum ada)
3. ✓ Simpan 15 nilai untuk tahun ajaran 2024

Grade yang dihitung untuk File 1 (Detail format):
```
NIM 2401001:
Nilai Akhir = (85×0.10) + (88×0.20) + (80×0.20) + (75×0.25) + (82×0.25)
            = 8.5 + 17.6 + 16 + 18.75 + 20.5
            = 81.35
Grade: B (80 ≤ 81.35 < 85)

NIM 2401003:
Nilai Akhir = (92×0.10) + (90×0.20) + (88×0.20) + (85×0.25) + (90×0.25)
            = 9.2 + 18 + 17.6 + 21.25 + 22.5
            = 88.55
Grade: A (≥ 85)
```

---

## Scenario: Import dengan Error Handling

### Case: File dengan Data Invalid

#### File: invalid_data.xlsx
```
NIM       | Nama Mahasiswa    | Aktivitas | Tugas | Kuis | UTS | UAS
2401001   | Ahmad Hidayat     | 85        | 88    | 80   | 75  | 82
2401002   |                   | 78        | 82    | 75   | 70  | 78    ← Nama kosong
2401003   | INVALID_VALUE     | 150       | 90    | 88   | 85  | 90    ← Nilai > 100
          | Nama Tanpa NIM    | 92        | 90    | 88   | 85  | 90    ← NIM kosong
```

#### Expected Result
```
✗ Import gagal: Diproses: 1 file, Berhasil: 1 nilai, Gagal: 3 nilai

┌──────────────────────────────────────┐
│ File Diproses: 1                     │
│ Nilai Berhasil: 1                    │
│ Nilai Gagal: 3                       │
└──────────────────────────────────────┘

Detail Hasil Per File:

⚠ invalid_data.xlsx
  Berhasil: 1  Gagal: 3

Error Log (Sampel):

invalid_data.xlsx: Baris 3: NIM dan Nama harus diisi
invalid_data.xlsx: Baris 4: Semua nilai harus dalam range 0-100
invalid_data.xlsx: Baris 5: NIM dan Nama harus diisi

Total 3 error (tampil 3)
```

#### Action: Fix & Retry
1. Open invalid_data.xlsx
2. Fix data:
   ```
   2401002 | Budi Santoso      | 78        | 82    | 75   | 70  | 78
   2401003 | Citra Dewi        | 90        | 90    | 88   | 85  | 90
   2401004 | Dedy Gunawan      | 92        | 90    | 88   | 85  | 90
   ```
3. Save file
4. Return to app, add corrected file, import again

Result setelah fix:
```
✓ Import berhasil: Diproses: 1 file, Berhasil: 3 nilai, Gagal: 0 nilai
```

---

## Best Practices

### ✓ Do's
```
1. Prepare data excel format first
   - Use template download if available
   - Validate NIM and names

2. Organize files logically
   - Group by mata kuliah
   - Follow naming convention: mk_tahun_semester.xlsx

3. When in doubt
   - Use Format Detail (safer)
   - Automatic grade calculation
   - Less prone to errors

4. Save correction
   - Keep error log
   - Document fixes
   - Re-verify before next import
```

### ✗ Don'ts
```
1. Don't mix tahun ajaran
   - One batch = one tahun ajaran
   - If need different years, import separately

2. Don't use special characters in NIM
   - Stick to alphanumeric
   - Keep it simple

3. Don't leave required fields empty
   - NIM must exist
   - Nama must exist
   - Setiap row harus complete

4. Don't import corrupted files
   - Check file not in use by another app
   - Validate Excel before import
```

---

## Verification Checklist

Setelah import selesai, verify dengan:

```
□ Jumlah data sesuai harapan
□ Grade benar untuk format detail
□ Tahun ajaran sesuai
□ Matakuliah sudah terinput
□ Error log sudah difiks sebelumnya

Done? ✓
Data ready untuk proses kalkulasi CPL
```

---

## Troubleshooting Quick Ref

| Problem | Solution |
|---------|----------|
| File tidak bisa dipilih | Cek format .xlsx/.csv, tidak corrupted |
| "File kosong" error | Pastikan data ada di Excel sheet |
| "NIM harus diisi" | Add NIM di setiap baris data |
| Nilai invalid | Gunakan 0-100 atau Grade A-E |
| Import lambat | Normal untuk file besar, tunggu saja |
| Data tidak tersimpan | Check error log, fix, retry import |

---

## Support

Jika mengalami masalah:
1. Check error log detail
2. Baca PANDUAN_BATCH_IMPORT_NILAI.md
3. Verify file format
4. Retry dengan corrected data
5. Contact administrator jika masalah berlanjut

Happy Batch Importing! 🚀
