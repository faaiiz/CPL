# Panduan CPMK vs Sub CPMK

## 📊 Perbedaan CPMK dan Sub CPMK

### CPMK (Capaian Pembelajaran Mata Kuliah)
- **Level**: Program Studi / Mata Kuliah
- **Tujuan**: Capaian pembelajaran utama untuk setiap mata kuliah
- **Contoh**: CPMK.1, CPMK.2, CPMK.3 (standar program studi)
- **Dikelola di**: 
  - Langsung dari screen Input RPS (tombol pengaturan ⚙️ di setiap mata kuliah)
  - Atau melalui menu "Kelola CPMK"
- **Digunakan dalam**: Perencanaan RPS minggu demi minggu

### Sub CPMK (Sub Capaian Pembelajaran Mata Kuliah)
- **Level**: Detail / Komponen pembelajaran
- **Tujuan**: Rincian detail dari CPMK (bisa ada beberapa sub-CPMK per CPMK)
- **Contoh**: SUB-CPMK.1, SUB-CPMK.2 (detail spesifik pembelajaran)
- **Dikelola di**: Menu "Kelola Sub CPMK" (per mata kuliah)
- **Digunakan dalam**: Penilaian dan detail pembelajaran yang lebih spesifik

---

## 🎯 Workflow yang Benar

### 1️⃣ Input RPS (Rencana Pembelajaran Semester)

```
📋 Daftar Mata Kuliah
└── Setiap Mata Kuliah memiliki 2 tombol:
    ├── ⚙️ Tombol Kelola CPMK (setting icon)
    │   └── Gunakan untuk menambah/edit CPMK untuk mata kuliah ini
    └── ✏️ Tombol Input (edit icon)
        └── Gunakan untuk mengisi detail RPS per minggu
```

### 2️⃣ Mengelola CPMK untuk Mata Kuliah

**Langkah:**
1. Buka screen "Input RPS"
2. Pilih mata kuliah yang ingin diatur CPMK-nya
3. Klik tombol ⚙️ (Kelola CPMK)
4. Dialog akan terbuka menampilkan daftar CPMK untuk mata kuliah tersebut
5. Gunakan "Tambah CPMK" untuk menambah CPMK baru
   - Kode CPMK: Bisa pilih dari dropdown (Sub CPMK 01-14) atau custom code
   - Deskripsi: Jelaskan capaian pembelajaran ini
6. Setelah CPMK ditambahkan, CPMKs tersebut akan tersedia saat Input RPS

### 3️⃣ Input RPS Mingguan

Setelah CPMK tersedia:
1. Klik tombol ✏️ "Input" untuk mata kuliah
2. Pilih minggu yang ingin diisi
3. Isi detail pembelajaran minggu tersebut
4. **Pilih CPMK** yang relevan untuk minggu itu
5. **Pilih Sub CPMK** jika ada (optional, dari "Kelola Sub CPMK")
6. Simpan

---

## 💡 Tips & Trik

### ✅ DO (Lakukan)
- ✓ Pastikan CPMK sudah ditambahkan SEBELUM input RPS
- ✓ Gunakan tombol ⚙️ di RPS Input untuk mengelola CPMK langsung
- ✓ Gunakan nama CPMK yang konsisten (CPMK.1, CPMK.2, dst)
- ✓ Jelaskan capaian pembelajaran dengan deskripsi yang jelas

### ❌ DON'T (Jangan)
- ✗ Menambah CPMK saat sedang input RPS (bisa hilang)
- ✗ Menggunakan nama CPMK yang sama untuk mata kuliah berbeda tanpa alasan
- ✗ Lupa mengisi CPMK saat input RPS (akan "kosong" di laporan)

---

## 🔍 Troubleshooting

### ❌ Masalah: CPMK tidak muncul saat Input RPS

**Solusi:**
1. Pastikan Anda sudah mengklik tombol ⚙️ "Kelola CPMK" 
2. Pastikan sudah menambahkan minimal 1 CPMK untuk mata kuliah tersebut
3. Refresh/reload aplikasi jika perlu

### ❌ Masalah: CPMK yang ditambahkan tidak tersimpan

**Solusi:**
1. Pastikan internet/database connection stabil
2. Cek di form "Kelola CPMK" apakah CPMK sudah tersimpan atau tidak
3. Jika tidak bisa tersimpan, cek error message di aplikasi

### ❌ Masalah: Bingung mana CPMK, mana Sub CPMK?

**Ingat:**
- CPMK = Capaian Pembelajaran **Mata Kuliah** (Program level)
- Sub CPMK = **SUB** Capaian Pembelajaran (Detail level)
- Sub CPMK adalah DETAIL dari CPMK

---

## 📚 Ringkasan Alur

```
┌─────────────────────────────────────────────────┐
│ Buka Screen "Input RPS"                         │
└───────────────┬─────────────────────────────────┘
                │
                ├─→ Klik ⚙️ "Kelola CPMK"
                │   └─→ Tambah CPMK yang diperlukan
                │       (CPMK.1, CPMK.2, dst)
                │
                └─→ Klik ✏️ "Input" RPS 
                    └─→ Isi detail pembelajaran minggu
                        ├─→ Topik pembelajaran
                        ├─→ Metode ajar
                        ├─→ Bobot
                        └─→ **Pilih CPMK yang relevan**

Hasil: RPS minggu dengan CPMK terdokumentasi ✓
```

---

## 📞 Catatan

Jika masih ada pertanyaan tentang perbedaan CPMK dan Sub CPMK, ingat:
- **CPMK** = hasil pembelajaran minimal yang harus dicapai untuk mata kuliah
- **Sub CPMK** = komponen-komponen detail yang membentuk CPMK
- Bisa ada 1-beberapa Sub CPMK per CPMK

Contoh:
```
CPMK.1: Mahasiswa memahami konsep dasar X
├── Sub CPMK.1.1: Definisi X
├── Sub CPMK.1.2: Karakteristik X  
└── Sub CPMK.1.3: Penerapan X
```
