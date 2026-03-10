# Dokumentasi Struktur Tampilan CPL - Sebelum vs Sesudah

## 🔄 Perubahan Struktur

### SEBELUMNYA (Tabel Gabung)
```
┌─────────────────────────────────────────────────────────┐
│ Hasil Perhitungan - Mata Kuliah - 2024                  │
│                                             2 mahasiswa   │
├─────────────────────────────────────────────────────────┤
│ No │ NIM  │ Nama    │ Sub-CPMK │ CPMK.IDs │ CPL.IDs    │
├─────────────────────────────────────────────────────────┤
│ 1  │ 001  │ Adi     │ 75.50    │ 76, 77   │ 80, 82     │
│ 2  │ 002  │ Budi    │ 78.25    │ 79, 80   │ 81, 83     │
└─────────────────────────────────────────────────────────┘

❌ KEKURANGAN:
- Satu tabel mencampurkan CPMK dan CPL
- Sulit membaca nilai jika banyak kolom
- Tidak ada ringkasan per kategori
```

### SESUDAHNYA (Dua Tabel Terpisah + Summary)
```
╔═════════════════════════════════════════════════════════╗
║ Hasil Perhitungan - Mata Kuliah - 2024                  ║
║                                         2 mahasiswa     ║
╚═════════════════════════════════════════════════════════╝

┌──────────────────────────┬──────────────────────────┐
│  📊 Rata-rata CPMK       │  🎯 Rata-rata CPL       │
│      75.88               │       81.50              │
└──────────────────────────┴──────────────────────────┘

┌──────────────────────────────────────────────────┐
│ 📚 Nilai CPMK (Capaian Pembelajaran Mata Kuliah)│
├──────────────────────────────────────────────────┤
│ No │ NIM  │ Nama Mahasiswa │ CPMK.1 │ CPMK.2  │
├──────────────────────────────────────────────────┤
│ 1  │ 001  │ Adi Pratama    │ 76.00  │ 77.00   │
│ 2  │ 002  │ Budi Santoso   │ 79.00  │ 80.00   │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│ 🏆 Nilai CPL (Capaian Pembelajaran Lulusan)     │
├──────────────────────────────────────────────────┤
│ No │ NIM  │ Nama Mahasiswa │ CPL.1  │ CPL.2   │
├──────────────────────────────────────────────────┤
│ 1  │ 001  │ Adi Pratama    │ 80.00  │ 82.00   │
│ 2  │ 002  │ Budi Santoso   │ 81.00  │ 83.00   │
└──────────────────────────────────────────────────┘

✅ KEUNGGULAN:
✓ Struktur terpisah dan jelas untuk CPMK dan CPL
✓ Ringkasan rata-rata untuk quick overview
✓ Header deskriptif dengan icon yang jelas
✓ Warna konsisten (hijau untuk CPMK, ungu untuk CPL)
✓ Lebih mudah dibaca dan dipahami
```

## 📊 Breakdown Komponen

### 1. Summary Cards (Baru)
```
┌─────────────────┬─────────────────┐
│  🎓 Rata-rata   │  🏆 Rata-rata   │
│     CPMK        │      CPL        │
│    75.88        │     81.50       │
│   (hijau)       │    (ungu)       │
└─────────────────┴─────────────────┘
```

### 2. CPMK Table
```
Header Color: Hijau (#27AE60)
Icon: Icons.school
Kolom dinamis: CPMK.1, CPMK.2, ... CPMK.N
```

### 3. CPL Table
```
Header Color: Ungu (#8E44AD)
Icon: Icons.flag
Kolom dinamis: CPL.1, CPL.2, ... CPL.N
```

## 🎨 Color Scheme

```
CPMK (Mata Kuliah):
  Header Background: #27AE60 with 0.1 opacity
  Text Color: #27AE60
  Icon: school

CPL (Lulusan):
  Header Background: #8E44AD with 0.1 opacity
  Text Color: #8E44AD
  Icon: flag
```

## 🔧 Dynamic Column Generation

### SEBELUMNYA
Kolom CPMK dan CPL digabung dalam header tunggal

### SESUDAHNYA
```dart
// Setiap CPMK ID mendapat kolom terpisah
CPMK IDs dari data: [1, 3, 5]
Kolom yang dibuat: [CPMK.1, CPMK.3, CPMK.5]

// Setiap CPL ID mendapat kolom terpisah
CPL IDs dari data: [2, 4]
Kolom yang dibuat: [CPL.2, CPL.4]
```

## 📱 Responsive Design

```
┌─ Mobile (scroll horizontal)
│  ┌──────────────────────┐
│  │ NIM │ Nama │ CPMK.1 │ ← scroll
│  │     │      │ CPMK.2 │
│  └──────────────────────┘
│
└─ Desktop (all visible)
   ┌──────────────────────────────┐
   │ NIM │ Nama │ CPMK.1 │ CPMK.2│ ← all visible
   └──────────────────────────────┘
```

## 🚀 Implementasi Methods

### _buildBatchCalculationResults()
- Menghitung rata-rata CPMK dan CPL
- Menampilkan summary cards
- Memanggil `_buildCPMKTable()` dan `_buildCPLTable()`

### _buildCPMKTable()
```dart
Widget _buildCPMKTable(List<OBECalculationResult> results)
  → Extract CPMK IDs dari results
  → Build dynamic columns per CPMK ID
  → Generate DataTable dengan formatting hijau
  → Handle loading/error states
```

### _buildCPLTable()
```dart
Widget _buildCPLTable(List<OBECalculationResult> results)
  → Extract CPL IDs dari results
  → Build dynamic columns per CPL ID
  → Generate DataTable dengan formatting ungu
  → Handle loading/error states
```

## ⚙️ State Management

```
_batchCalculationResults: List<OBECalculationResult>
  ├─ mahasiswaId
  ├─ cpmkValues: Map<int, double>  ← CPMK per ID
  ├─ cplValues: Map<int, double>   ← CPL per ID
  └─ averageSubCPMKNilai: double
```

## 🧪 Testing Checklist

- [x] Compile tanpa error
- [x] Loading states ditampilkan
- [x] Error states ditampilkan
- [x] Summary cards menampilkan nilai dengan benar
- [x] CPMK table dengan kolom dinamis
- [x] CPL table dengan kolom dinamis
- [ ] Test dengan data banyak (>10 mahasiswa)
- [ ] Test scroll horizontal dengan banyak kolom
- [ ] Test animation fade-in saat hasil tampil
