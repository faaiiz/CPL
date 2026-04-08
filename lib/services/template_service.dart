import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';

class TemplateService {
  // Mahasiswa template content
  static const String mahasiswaTemplate = '''NIM,Nama,Tahun Masuk
2401001,Ahmad Rizki,2024
2401002,Budi Santoso,2024
2401003,Citra Dewi,2024
2401004,Dedi Gunawan,2024
2401005,Eka Putri,2024''';

  // Matakuliah template content
  static const String matakuliahTemplate = '''Kode,Nama,Semester,Jenis,SKS
IFT101,Pemrograman Dasar,1,wajib,3
IFT102,Inovasi Digital,1,wajib,3
IFT201,Struktur Data,2,wajib,4
IFT202,Basis Data,2,pilihan,3
IFT301,Kecerdasan Buatan,3,pilihan,4
IFT302,Keamanan Siber,3,pilihan,3
IFT401,Proyek Akhir,4,wajib,6
IFT402,Seminar,4,wajib,2
IFT403,Magang,4,pilihan,3
IFT404,Penelitian,4,pilihan,3''';

  // Nilai template content
  static const String nilaiTemplate = '''NIM,Nama Mahasiswa,Kode Matakuliah,Nama Matakuliah,Grade,Tahun Ajaran
2401001,Ahmad Rizki,IFT101,Pemrograman Dasar,A,2024/2025
2401002,Budi Santoso,IFT101,Pemrograman Dasar,B,2024/2025
2401003,Citra Dewi,IFT102,Inovasi Digital,A,2024/2025
2401004,Dedi Gunawan,IFT102,Inovasi Digital,C,2024/2025
2401005,Eka Putri,IFT201,Struktur Data,B,2024/2025''';

  // Nilai Detail template - dengan komponen nilai (Aktivitas, Tugas, Hasil Proyek, Kuis, UTS, UAS)
  // Rumus: Nilai Akhir = (Aktivitas×10% + Tugas×10% + Hasil Proyek×15% + Kuis×15% + UTS×25% + UAS×25%)
  static const String nilaiDetailTemplate = '''NIM,Nama,Kode Matakuliah,Nama Matakuliah,Aktivitas,Tugas,Hasil Proyek,Kuis,UTS,UAS,Tahun Ajaran,Semester
2401001,Ahmad Rizki,IFT101,Pemrograman Dasar,85,88,87,90,82,85,2024/2025 Ganjil,1
2401002,Budi Santoso,IFT101,Pemrograman Dasar,78,82,80,80,75,80,2024/2025 Ganjil,1
2401003,Citra Dewi,IFT102,Inovasi Digital,92,90,91,88,90,92,2024/2025 Ganjil,1
2401004,Dedi Gunawan,IFT102,Inovasi Digital,76,74,75,75,70,72,2024/2025 Ganjil,1
2401005,Eka Putri,IFT201,Struktur Data,88,86,87,85,87,86,2024/2025 Ganjil,2''';

  // CPL template content
  static const String cplTemplate = '''Nomor CPL,Deskripsi CPL
1,Menguasai teori dan praktik dalam bidang komputasi
2,Mampu menganalisis dan merancang sistem komputasi
3,Mampu mengimplementasikan solusi komputasi dengan teknologi terkini
4,Memahami etika profesional dan dampak sosial
5,Mampu berkomunikasi dan berkolaborasi secara efektif
6,Mampu belajar mandiri dan terus mengembangkan diri
7,Mampu berinovasi dan mengambil keputusan bisnis''';

  // CPMK template content
  static const String cpmkTemplate = '''Nama Mata Kuliah:,Capaian Program Keahlian
Kode Mata Kuliah:,
,,
Nomor CPMK,Deskripsi CPMK
1,Memahami konsep dasar dan teori fundamental program studi
2,Mampu merancang dan menganalisis solusi kompleks
3,Mampu mengimplementasikan dan menguji solusi
4,Mampu mengkomunikasikan hasil dan dokumentasi
5,Mampu berkontribusi dalam proyek kolaboratif
6,Mampu mengidentifikasi dan menyelesaikan masalah etika
7,Mampu melanjutkan pembelajaran dan pengembangan profesional''';

  // Sub CPMK template content
  static const String subCpmkTemplate = '''Kode Sub CPMK,Deskripsi Sub CPMK
SUB-CPMK.1,Pemahaman konsep fundamental
SUB-CPMK.2,Analisis dan desain sistem
SUB-CPMK.3,Implementasi dan testing
SUB-CPMK.4,Dokumentasi dan komunikasi
SUB-CPMK.5,Kolaborasi dan teamwork
SUB-CPMK.6,Identifikasi dan resolusi masalah
SUB-CPMK.7,Pembelajaran berkelanjutan''';

  /// Download Mahasiswa template (EXCEL format)
  static Future<String?> downloadMahasiswaTemplate() async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) return null;

      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Set column widths
      sheetObject.setColWidth(0, 18); // NIM
      sheetObject.setColWidth(1, 25); // Nama
      sheetObject.setColWidth(2, 15); // Tahun Masuk

      // Add headers dengan styling
      var headers = ['NIM', 'Nama', 'Tahun Masuk'];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        
        // Apply header styling: bold, background color
        try {
          CellStyle cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: '#8E44AD', // Purple background
            fontColorHex: '#FFFFFF', // White text
          );
          cell.cellStyle = cellStyle;
        } catch (e) {
          // Could not apply header styling
        }
      }

      // Sample data mahasiswa
      List<List<dynamic>> sampleData = [
        ['2401001', 'Ahmad Rizki', 2024],
        ['2401002', 'Budi Santoso', 2024],
        ['2401003', 'Citra Dewi', 2024],
        ['2401004', 'Dedi Gunawan', 2024],
        ['2401005', 'Eka Putri', 2024],
      ];

      // Masukkan data tabel
      for (int rowIdx = 0; rowIdx < sampleData.length; rowIdx++) {
        for (int colIdx = 0; colIdx < sampleData[rowIdx].length; colIdx++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: colIdx, rowIndex: rowIdx + 1))
              .value = sampleData[rowIdx][colIdx];
        }
      }

      // Add instructions sheet
      try {
        Sheet instructionSheet = excel['Instruksi'];
        instructionSheet.setColWidth(0, 100);
        
        instructionSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
            .value = 'Panduan Import Mahasiswa';
        
        List<String> instructions = [
          '',
          'Kolom yang diperlukan:',
          '1. NIM - Nomor Induk Mahasiswa (format: 7 digit, contoh: 2401001)',
          '2. Nama - Nama lengkap mahasiswa',
          '3. Tahun Masuk - Tahun masuk mahasiswa (format: 4 digit, contoh: 2024)',
          '',
          'Catatan Penting:',
          '- Jangan ubah nama header kolom',
          '- NIM harus unik dan belum terdaftar di sistem',
          '- Nama tidak boleh kosong',
          '- Tahun Masuk harus berupa angka (contoh: 2024, 2023)',
          '- Baris data dapat ditambah sesuai kebutuhan',
          '- Hapus baris contoh sebelum melakukan import',
          '- Jangan mengubah urutan kolom',
        ];
        
        for (int idx = 0; idx < instructions.length; idx++) {
          instructionSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: idx + 1))
              .value = instructions[idx];
        }
      } catch (e) {
        // Could not add instructions sheet
      }

      // Simpan ke file
      final file = File(
          '${downloadDir.path}/TEMPLATE_MAHASISWA_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return file.path;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Download Matakuliah template (EXCEL format)
  static Future<String?> downloadMatakuliahTemplate() async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) return null;

      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Set column widths
      sheetObject.setColWidth(0, 12); // Kode
      sheetObject.setColWidth(1, 25); // Nama
      sheetObject.setColWidth(2, 12); // Semester
      sheetObject.setColWidth(3, 12); // Jenis
      sheetObject.setColWidth(4, 10); // SKS

      // Add headers dengan styling
      var headers = ['Kode', 'Nama', 'Semester', 'Jenis', 'SKS'];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        
        // Apply header styling: bold, background color
        try {
          CellStyle cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: '#27AE60', // Green background
            fontColorHex: '#FFFFFF', // White text
          );
          cell.cellStyle = cellStyle;
        } catch (e) {
          // Could not apply header styling
        }
      }

      // Sample data matakuliah
      List<List<dynamic>> sampleData = [
        ['IFT101', 'Pemrograman Dasar', 1, 'wajib', 3],
        ['IFT102', 'Inovasi Digital', 1, 'wajib', 3],
        ['IFT201', 'Struktur Data', 2, 'wajib', 4],
        ['IFT202', 'Basis Data', 2, 'pilihan', 3],
        ['IFT301', 'Kecerdasan Buatan', 3, 'pilihan', 4],
        ['IFT302', 'Keamanan Siber', 3, 'pilihan', 3],
        ['IFT401', 'Proyek Akhir', 4, 'wajib', 6],
        ['IFT402', 'Seminar', 4, 'wajib', 2],
        ['IFT403', 'Magang', 4, 'pilihan', 3],
        ['IFT404', 'Penelitian', 4, 'pilihan', 3],
      ];

      // Masukkan data tabel
      for (int rowIdx = 0; rowIdx < sampleData.length; rowIdx++) {
        for (int colIdx = 0; colIdx < sampleData[rowIdx].length; colIdx++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: colIdx, rowIndex: rowIdx + 1))
              .value = sampleData[rowIdx][colIdx];
        }
      }

      // Add instructions sheet
      try {
        Sheet instructionSheet = excel['Instruksi'];
        instructionSheet.setColWidth(0, 100);
        
        instructionSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
            .value = 'Panduan Import Matakuliah';
        
        List<String> instructions = [
          '',
          'Kolom yang diperlukan:',
          '1. Kode - Kode matakuliah (format: 6 karakter, contoh: IFT101)',
          '2. Nama - Nama lengkap matakuliah',
          '3. Semester - Semester penawaran (format: angka 1-8, contoh: 1, 2, 3)',
          '4. Jenis - Jenis matakuliah (wajib/pilihan)',
          '5. SKS - Jumlah Satuan Kredit Semester (format: angka 1-6, contoh: 3, 4)',
          '',
          'Catatan Penting:',
          '- Jangan ubah nama header kolom',
          '- Kode matakuliah harus unik dan belum terdaftar di sistem',
          '- Nama tidak boleh kosong',
          '- Semester harus angka 1-8',
          '- Jenis harus "wajib" atau "pilihan" (lowercase)',
          '- SKS harus angka positif (1-6)',
          '- Baris data dapat ditambah sesuai kebutuhan',
          '- Hapus baris contoh sebelum melakukan import',
          '- Jangan mengubah urutan kolom',
        ];
        
        for (int idx = 0; idx < instructions.length; idx++) {
          instructionSheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: idx + 1))
              .value = instructions[idx];
        }
      } catch (e) {
        // Could not add instructions sheet
      }

      // Simpan ke file
      final file = File(
          '${downloadDir.path}/TEMPLATE_MATAKULIAH_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return file.path;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Download Nilai template
  static Future<String?> downloadNilaiTemplate() async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) return null;

      final file = File(
          '${downloadDir.path}/TEMPLATE_NILAI_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(nilaiTemplate);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Download Nilai Detail template (EXCEL format dengan komponen: Aktivitas, Tugas, Kuis, UTS, UAS)
  static Future<String?> downloadNilaiDetailTemplate({
    String? kodeMatakuliah,
    String? namaMatakuliah,
    String? tahunAjaran,
  }) async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) return null;

      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      int currentRow = 0;

      // Informasi header (Kode MK, Nama MK, Tahun Ajaran)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Kode Matakuliah:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = kodeMatakuliah ?? 'IFT101';
      currentRow++;

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Nama Matakuliah:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = namaMatakuliah ?? 'Pemrograman Dasar';
      currentRow++;

      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Tahun Ajaran:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = tahunAjaran ?? '2024/2025 Ganjil';
      currentRow += 2; // Skip satu baris sebelum tabel

      // Header row tabel (tanpa Kode MK dan Nama MK)
      final headers = [
        'NIM',
        'Nama',
        'Aktivitas',
        'Hasil Proyek',
        'Tugas',
        'Kuis',
        'UTS',
        'UAS',
      ];

      // Masukkan header tabel
      for (int i = 0; i < headers.length; i++) {
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
            .value = headers[i];
      }
      currentRow++;

      // Data contoh (tanpa Kode MK dan Nama MK)
      final dataRows = [
        ['2401001', 'Ahmad Rizki', '85', '87', '88', '90', '82', '85'],
        ['2401002', 'Budi Santoso', '78', '80', '82', '80', '75', '80'],
        ['2401003', 'Citra Dewi', '92', '91', '90', '88', '90', '92'],
        ['2401004', 'Dedi Gunawan', '76', '75', '74', '75', '70', '72'],
        ['2401005', 'Eka Putri', '88', '87', '86', '85', '87', '86'],
      ];

      // Masukkan data tabel
      for (final row in dataRows) {
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: colIndex, rowIndex: currentRow))
              .value = row[colIndex];
        }
        currentRow++;
      }

      // Set column widths
      sheetObject.setColWidth(0, 15); // NIM
      sheetObject.setColWidth(1, 20); // Nama
      sheetObject.setColWidth(2, 12); // Aktivitas
      sheetObject.setColWidth(3, 15); // Hasil Proyek
      sheetObject.setColWidth(4, 12); // Tugas
      sheetObject.setColWidth(5, 12); // Kuis
      sheetObject.setColWidth(6, 12); // UTS
      sheetObject.setColWidth(7, 12); // UAS

      // Simpan ke file
      // Struktur folder: Downloads/[Semester] [TahunDenganDash]/
      // Format nama file: [NamaMatakuliah].xlsx
      // Contoh: Downloads/Ganjil 2022-2023/Radiobiologi.xlsx
      
      // Parse tahun ajaran: format input "2024/2025 Genap" -> pisahkan tahun dan semester
      String tahun = '2024/2025';
      String semester = 'Genap';
      
      if (tahunAjaran != null && tahunAjaran.isNotEmpty && tahunAjaran.contains(' ')) {
        final parts = tahunAjaran.split(' ');
        if (parts.length == 2) {
          tahun = parts[0]; // "2024/2025"
          semester = parts[1]; // "Genap" atau "Ganjil"
        }
      }
      
      // Format folder: [Semester] [Tahun dengan dash]
      // Contoh: "Ganjil 2022-2023"
      final tahunDenganDash = tahun.replaceAll('/', '-');
      final folderName = '$semester $tahunDenganDash';
      final folderPath = '${downloadDir.path}/$folderName';
      
      // Format file: [Nama Matakuliah].xlsx saja
      // Contoh: "Radiobiologi.xlsx"
      final matakuliahName = namaMatakuliah ?? 'Matakuliah';
      final fileName = '$matakuliahName.xlsx';
      final filePath = '$folderPath/$fileName';
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        return filePath;
      }

      return null;
    } catch (e) {
      // Error creating Excel template
      return null;
    }
  }

  /// Download Nilai Batch template (EXCEL format)
  /// Template untuk import nilai masal dengan format:
  /// NIM | Nama Mahasiswa | Kode Matakuliah | Nama Matakuliah | Grade | Nilai Numerik | Tahun Ajaran
  static Future<String?> downloadNilaiBatchTemplate() async {
    try {
      // Try to get downloads directory, fallback to app support directory
      Directory? downloadDir = await getDownloadsDirectory();
      
      if (downloadDir == null) {
        // Fallback: gunakan application documents directory
        downloadDir = await getApplicationDocumentsDirectory();
      }



      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Nilai'];

      // Clear default sheet
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      try {
        // Set column widths
        sheetObject.setColWidth(0, 15);  // NIM
        sheetObject.setColWidth(1, 25);  // Nama Mahasiswa
        sheetObject.setColWidth(2, 18);  // Kode Matakuliah
        sheetObject.setColWidth(3, 30);  // Nama Matakuliah
        sheetObject.setColWidth(4, 15);  // Aktivitas Partisipatif
        sheetObject.setColWidth(5, 15);  // Hasil Proyek
        sheetObject.setColWidth(6, 12);  // Kuis
        sheetObject.setColWidth(7, 12);  // Tugas
        sheetObject.setColWidth(8, 12);  // UTS
        sheetObject.setColWidth(9, 12);  // UAS
        sheetObject.setColWidth(10, 18); // Tahun Ajaran
      } catch (e) {
        // Could not set column widths
      }

      // Add headers dengan styling
      var headers = [
        'NIM',
        'Nama Mahasiswa',
        'Kode Matakuliah',
        'Nama Matakuliah',
        'Aktivitas Partisipatif',
        'Hasil Proyek',
        'Kuis',
        'Tugas',
        'UTS',
        'UAS',
        'Tahun Ajaran'
      ];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i];
        
        // Apply header styling: bold, background color
        try {
          CellStyle cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: '#4472C4', // Blue background
            fontColorHex: '#FFFFFF', // White text
          );
          cell.cellStyle = cellStyle;
        } catch (e) {
          // Could not apply header styling
        }
      }

      // Sample data dengan nilai numerik 0-100
      List<List<dynamic>> sampleData = [
        ['22001', 'Ahmad Rizki', 'MAT101', 'Matematika Dasar', 85, 88, 90, 87, 82, 85, '2024/2025'],
        ['22002', 'Budi Santoso', 'MAT101', 'Matematika Dasar', 78, 82, 80, 80, 75, 80, '2024/2025'],
        ['22003', 'Citra Dewi', 'FIS101', 'Fisika Dasar', 92, 90, 88, 91, 90, 92, '2024/2025'],
        ['22004', 'Dedi Gunawan', 'FIS101', 'Fisika Dasar', 76, 74, 75, 75, 70, 72, '2024/2025'],
        ['22005', 'Eka Putri', 'KIM101', 'Kimia Dasar', 88, 86, 85, 87, 87, 86, '2024/2025'],
        ['22001', 'Ahmad Rizki', 'PEM101', 'Pemrograman Dasar', 90, 89, 88, 90, 85, 88, '2024/2025'],
        ['22002', 'Budi Santoso', 'ALG101', 'Algoritma', 80, 82, 79, 81, 78, 80, '2024/2025'],
      ];

      for (int rowIdx = 0; rowIdx < sampleData.length; rowIdx++) {
        for (int colIdx = 0; colIdx < sampleData[rowIdx].length; colIdx++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIdx + 1))
              .value = sampleData[rowIdx][colIdx];
        }
      }

      // Add instructions sheet
      Sheet instructionSheet = excel['Instruksi'];
      
      try {
        instructionSheet.setColWidth(0, 120);
      } catch (e) {
        // Could not set instruction column width
      }

      instructionSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = 'Panduan Import Nilai Batch';

      List<String> instructions = [
        '',
        'Kolom yang diperlukan:',
        '1. NIM - Nomor Induk Mahasiswa (harus terdaftar di sistem)',
        '2. Nama Mahasiswa - Nama lengkap mahasiswa',
        '3. Kode Matakuliah - Kode matakuliah (HARUS sesuai dengan matakuliah yang terdaftar)',
        '4. Nama Matakuliah - Nama lengkap matakuliah (HARUS sesuai dengan matakuliah yang terdaftar)',
        '5. Aktivitas Partisipatif - Nilai numerik 0-100',
        '6. Hasil Proyek - Nilai numerik 0-100',
        '7. Kuis - Nilai numerik 0-100',
        '8. Tugas - Nilai numerik 0-100',
        '9. UTS - Nilai numerik 0-100',
        '10. UAS - Nilai numerik 0-100',
        '11. Tahun Ajaran - Tahun ajaran (format: 2024/2025)',
        '',
        'Catatan Penting:',
        '- Jangan ubah nama header kolom',
        '- NIM harus sudah terdaftar di sistem',
        '- Kode Matakuliah dan Nama Matakuliah HARUS sesuai dengan data matakuliah di sistem',
        '- Semua nilai harus berupa angka numerik (0-100)',
        '- Tahun Ajaran format: tahun/tahunberikutnya (contoh: 2024/2025)',
        '- Satu mahasiswa dapat memiliki beberapa nilai untuk matakuliah berbeda',
        '- Baris data dapat ditambah sesuai kebutuhan',
        '- Hapus baris contoh sebelum melakukan import',
        '- Nilai disimpan di database sebelum diproses lebih lanjut',
      ];

      for (int idx = 0; idx < instructions.length; idx++) {
        instructionSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: idx + 1))
            .value = instructions[idx];
      }

      // Save file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${downloadDir.path}/TEMPLATE_NILAI_BATCH_$timestamp.xlsx';

      // Create directory if not exists
      final file = File(filePath);
      await file.parent.create(recursive: true);

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        
        // Verify file exists
        if (await file.exists()) {
          return filePath;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      // Error creating Nilai Batch template
      return null;
    }
  }

  /// Download Nilai Batch template as CSV (fallback jika Excel gagal)
  static Future<String?> downloadNilaiBatchTemplateAsCSV() async {
    try {
      Directory? downloadDir = await getDownloadsDirectory();
      
      if (downloadDir == null) {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      // CSV content dengan header dan sample data (nilai numerik 0-100)
      final csvContent = '''NIM,Nama Mahasiswa,Kode Matakuliah,Nama Matakuliah,Aktivitas Partisipatif,Hasil Proyek,Kuis,Tugas,UTS,UAS,Tahun Ajaran
22001,Ahmad Rizki,MAT101,Matematika Dasar,85,88,90,87,82,85,2024/2025
22002,Budi Santoso,MAT101,Matematika Dasar,78,82,80,80,75,80,2024/2025
22003,Citra Dewi,FIS101,Fisika Dasar,92,90,88,91,90,92,2024/2025
22004,Dedi Gunawan,FIS101,Fisika Dasar,76,74,75,75,70,72,2024/2025
22005,Eka Putri,KIM101,Kimia Dasar,88,86,85,87,87,86,2024/2025
22001,Ahmad Rizki,PEM101,Pemrograman Dasar,90,89,88,90,85,88,2024/2025
22002,Budi Santoso,ALG101,Algoritma,80,82,79,81,78,80,2024/2025''';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${downloadDir.path}/TEMPLATE_NILAI_BATCH_$timestamp.csv';

      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(csvContent);
      
      // Verify file exists
      if (await file.exists()) {
        return filePath;
      } else {
        return null;
      }
    } catch (e) {
      // Error creating CSV template
      return null;
    }
  }

  /// Download template untuk input nilai single matakuliah (Excel format)
  static Future<String?> downloadNilaiSingleMatakuliahTemplate({
    required String kodeMatakuliah,
    required String namaMatakuliah,
    required String tahunAjaran,
  }) async {
    try {
      Directory? downloadDir;
      
      try {
        downloadDir = await getDownloadsDirectory();
      } catch (e) {
      }
      
      if (downloadDir == null) {
        try {
          downloadDir = await getApplicationDocumentsDirectory();
        } catch (e) {
          return null;
        }
      }

      if (!await downloadDir.exists()) {
        try {
          await downloadDir.create(recursive: true);
        } catch (e) {
          return null;
        }
      }

      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      try {
        // Set column widths
        sheetObject.setColWidth(0, 15);  // NIM
        sheetObject.setColWidth(1, 25);  // Nama Mahasiswa
        sheetObject.setColWidth(2, 18);  // Aktivitas Partisipatif
        sheetObject.setColWidth(3, 15);  // Hasil Proyek
        sheetObject.setColWidth(4, 12);  // Kuis
        sheetObject.setColWidth(5, 12);  // Tugas
        sheetObject.setColWidth(6, 12);  // UTS
        sheetObject.setColWidth(7, 12);  // UAS
      } catch (e) {
        // Could not set column widths
      }

      // Add info section (Kode dan Nama Matakuliah)
      try {
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
            .value = 'Kode Matakuliah:';
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
            .value = kodeMatakuliah;

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
            .value = 'Nama Matakuliah:';
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1))
            .value = namaMatakuliah;

        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
            .value = 'Tahun Ajaran:';
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
            .value = tahunAjaran;
      } catch (e) {
        // Could not add info section
      }

      // Add empty row for spacing
      // Row 3 is empty

      // Add headers at row 4
      var headers = [
        'NIM',
        'Nama Mahasiswa',
        'Aktivitas Partisipatif',
        'Hasil Proyek',
        'Kuis',
        'Tugas',
        'UTS',
        'UAS'
      ];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 4));
        cell.value = headers[i];
        
        // Apply header styling: bold, background color
        try {
          CellStyle cellStyle = CellStyle(
            bold: true,
            backgroundColorHex: '#4472C4', // Blue background
            fontColorHex: '#FFFFFF', // White text
          );
          cell.cellStyle = cellStyle;
        } catch (e) {
          print('Warning: Could not apply header styling: $e');
        }
      }

      // Sample data (starting from row 5)
      List<List<dynamic>> sampleData = [
        ['22001', 'Ahmad Rizki', 85, 88, 90, 87, 82, 85],
        ['22002', 'Budi Santoso', 78, 82, 80, 80, 75, 80],
        ['22003', 'Citra Dewi', 92, 90, 88, 91, 90, 92],
        ['22004', 'Dedi Gunawan', 76, 74, 75, 75, 70, 72],
        ['22005', 'Eka Putri', 88, 86, 85, 87, 87, 86],
      ];

      for (int rowIdx = 0; rowIdx < sampleData.length; rowIdx++) {
        for (int colIdx = 0; colIdx < sampleData[rowIdx].length; colIdx++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIdx + 5))
              .value = sampleData[rowIdx][colIdx];
        }
      }



      // Save file
      final filePath = '${downloadDir.path}/Nilai_${kodeMatakuliah}_${namaMatakuliah}.xlsx';

      print('Attempting to save file to: $filePath');

      final file = File(filePath);
      
      try {
        await file.parent.create(recursive: true);
        print('Parent directory ready');
      } catch (e) {
        // Could not create parent directory
      }

      List<int>? fileBytes;
      try {
        fileBytes = excel.save();
      } catch (e) {
        // Excel save() failed
        return null;
      }
      
      if (fileBytes == null) {
        // Excel save() returned null
        return null;
      }



      try {
        await file.writeAsBytes(fileBytes);

      } catch (e) {
        // Error writing bytes to file
        return null;
      }

      // Verify file exists
      final exists = await file.exists();
      if (exists) {
        return filePath;
      } else {

        return null;
      }
    } catch (e) {
      // Error creating single matakuliah template
      return null;
    }
  }

  /// Download CPL template (EXCEL format)
  static Future<String?> downloadCPLTemplate() async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) return null;

      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Header row
      final headers = ['Nomor CPL', 'Deskripsi CPL'];
      for (int i = 0; i < headers.length; i++) {
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = headers[i];
      }

      // Data contoh
      final dataRows = [
        ['1', 'Menguasai teori dan praktik dalam bidang komputasi'],
        ['2', 'Mampu menganalisis dan merancang sistem komputasi'],
        ['3', 'Mampu mengimplementasikan solusi komputasi dengan teknologi terkini'],
        ['4', 'Memahami etika profesional dan dampak sosial'],
        ['5', 'Mampu berkomunikasi dan berkolaborasi secara efektif'],
        ['6', 'Mampu belajar mandiri dan terus mengembangkan diri'],
        ['7', 'Mampu berinovasi dan mengambil keputusan bisnis'],
      ];

      // Masukkan data
      for (int rowIndex = 0; rowIndex < dataRows.length; rowIndex++) {
        final row = dataRows[rowIndex];
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: colIndex, rowIndex: rowIndex + 1))
              .value = row[colIndex];
        }
      }

      // Set column widths
      sheetObject.setColWidth(0, 15); // Nomor CPL
      sheetObject.setColWidth(1, 60); // Deskripsi CPL

      // Simpan ke file
      final file = File(
          '${downloadDir.path}/TEMPLATE_CPL_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return file.path;
      }

      return null;
    } catch (e) {
      // Error creating Excel CPL template
      return null;
    }
  }

  /// Download CPMK template (EXCEL format)
  /// Format: Sama dengan Sub CPMK Batch
  /// Row 1 = Nama Mata Kuliah, Row 2 = Kode Mata Kuliah, Row 3 = Empty, Row 4 = Column Headers, Row 5+ = Data
  static Future<String?> downloadCPMKTemplate() async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) return null;

      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      int currentRow = 0;

      // Row 1: Nama Mata Kuliah (Label di A, Value di B)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Nama Mata Kuliah:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = 'Capaian Program Keahlian';
      currentRow++;

      // Row 2: Kode Mata Kuliah (Label di A, Value di B)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Kode Mata Kuliah:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = '';
      currentRow++;

      currentRow++; // Skip baris kosong - sekarang row 3

      // Row 4: Header tabel
      final headers = ['Nomor CPMK', 'Deskripsi CPMK'];
      for (int i = 0; i < headers.length; i++) {
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
            .value = headers[i];
      }
      currentRow++;

      // Row 5+: Data contoh
      final dataRows = [
        ['1', 'Memahami konsep dasar dan teori fundamental program studi'],
        ['2', 'Mampu merancang dan menganalisis solusi kompleks'],
        ['3', 'Mampu mengimplementasikan dan menguji solusi'],
        ['4', 'Mampu mengkomunikasikan hasil dan dokumentasi'],
        ['5', 'Mampu berkontribusi dalam proyek kolaboratif'],
        ['6', 'Mampu mengidentifikasi dan menyelesaikan masalah etika'],
        ['7', 'Mampu melanjutkan pembelajaran dan pengembangan profesional'],
      ];

      // Masukkan data tabel
      for (final row in dataRows) {
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: colIndex, rowIndex: currentRow))
              .value = row[colIndex];
        }
        currentRow++;
      }

      // Set column widths
      sheetObject.setColWidth(0, 18); // Nomor CPMK
      sheetObject.setColWidth(1, 150); // Deskripsi CPMK

      // Simpan ke file dengan nama: CPMK_Template_<tahun>.xlsx
      final fileName = 'CPMK_Template_${DateTime.now().year}.xlsx';
      final file = File('${downloadDir.path}/$fileName');
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return file.path;
      }

      return null;
    } catch (e) {
      // Error creating Excel CPMK template
      return null;
    }
  }

  /// Download Sub CPMK template (EXCEL format)
  static Future<String?> downloadSubCPMKTemplate({String? matakuliahNama, String? kodeMatakuliah}) async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) return null;

      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      int currentRow = 0;

      // Informasi header (Nama Mata Kuliah)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Nama Mata Kuliah:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = matakuliahNama ?? 'Pemrograman Dasar';
      currentRow++;

      // Informasi header (Kode Mata Kuliah)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Kode Mata Kuliah:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = kodeMatakuliah ?? '';
      currentRow += 2; // Skip satu baris sebelum tabel

      // Header row tabel
      final headers = ['Kode Sub CPMK', 'Deskripsi Sub CPMK'];
      for (int i = 0; i < headers.length; i++) {
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
            .value = headers[i];
      }
      currentRow++;

      // Data contoh
      final dataRows = [
        ['SUB-CPMK.1', 'Pemahaman konsep fundamental'],
        ['SUB-CPMK.2', 'Analisis dan desain sistem'],
        ['SUB-CPMK.3', 'Implementasi dan testing'],
        ['SUB-CPMK.4', 'Dokumentasi dan komunikasi'],
        ['SUB-CPMK.5', 'Kolaborasi dan teamwork'],
      ];

      // Masukkan data tabel
      for (final row in dataRows) {
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: colIndex, rowIndex: currentRow))
              .value = row[colIndex];
        }
        currentRow++;
      }

      // Set column widths
      sheetObject.setColWidth(0, 20); // Kode Sub CPMK
      sheetObject.setColWidth(1, 50); // Deskripsi Sub CPMK

      // Simpan ke file dengan nama: CPMK_<nama mata kuliah>.xlsx
      final fileName = 'CPMK_${matakuliahNama ?? 'Mata Kuliah'}.xlsx';
      final file = File('${downloadDir.path}/$fileName');
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return file.path;
      }

      return null;
    } catch (e) {
      // Error creating Excel Sub CPMK template
      return null;
    }
  }

  /// Download Sub CPMK Batch template (untuk import batch per matakuliah)
  /// Format: B1 berisi nama matakuliah, mulai data di row 4
  static Future<String?> downloadSubCPMKBatchTemplate({
    String? kodeMatakuliah,
    String? namaMatakuliah,
  }) async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) return null;

      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      int currentRow = 0;

      // Row 1: Nama Mata Kuliah (di kolom B - index 1)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Nama Mata Kuliah:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = namaMatakuliah ?? 'Analisis dan Karakterisasi Material';
      currentRow++; // Row 2

      // Row 2: Kode Mata Kuliah (di kolom B - index 1)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Kode Mata Kuliah:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = kodeMatakuliah ?? '';
      currentRow++; // Row 3

      currentRow++; // Skip baris kosong - sekarang row 4

      // Row 3: Header tabel
      final headers = ['Kode Sub CPMK', 'Deskripsi Sub CPMK'];
      for (int i = 0; i < headers.length; i++) {
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
            .value = headers[i];
      }
      currentRow++; // Row 4

      // Row 4+: Data contoh
      final dataRows = [
        ['SUB-CPMK.1', 'Mahasiswa mampu menjelaskan prinsip-prinsip dasar berbagai metode karakterisasi material, khususnya spektroskopi, serta memahami peran krusialnya dalam pengembangan ilmu pengetahuan dan teknologi material'],
        ['SUB-CPMK.2', 'Mahasiswa mampu memahami dan menerapkan prinsip dasar instrumentasi dan analisis data dari UV-Vis Spektrofotometer untuk mengkarakterisasi sifat optik material dan menginterpretasi hasil pengukurannya'],
        ['SUB-CPMK.3', 'Mahasiswa mampu menerapkan dan menganalisis data dan instrumen ARD dan SEM untuk mengkarakterisasi mikrostruktur material, mengidentifikasi fase kristal, serta mengaitkannya dengan sifat-sifat material yang relevan'],
        ['SUB-CPMK.4', 'Mahasiswa mampu memahami dan menerapkan prinsip dasar dan metode komposisi untuk karakterisasi komposisi unsur material, serta menginterpretasi hasil pengukurannya'],
        ['SUB-CPMK.5', 'Mahasiswa mampu menjelaskan prinsip dasar, menganalisis spektrum FTIR untuk pengidentifikasian gugus fungsi dan ikatan kimia dalam material secara efektif'],
        ['SUB-CPMK.6', 'Mahasiswa mampu menjelaskan prinsip dasar, menginterpretasi data DTA dan TGA, serta menganalisis sifat thermal material, seperti transisi fasa, dekomposisi, dan perubahan massa'],
        ['SUB-CPMK.7', 'Mahasiswa mamahami dan menerapkan prinsip Efek Hall untuk mengukur dan mengkarakterisasi sifat listrik material, seperti menentukan jenis, konsentrasi, dan mobilitas pembawa muatan'],
      ];

      // Masukkan data tabel
      for (final row in dataRows) {
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: colIndex, rowIndex: currentRow))
              .value = row[colIndex];
        }
        currentRow++;
      }

      // Set column widths
      sheetObject.setColWidth(0, 18); // Kode Sub CPMK
      sheetObject.setColWidth(1, 150); // Deskripsi Sub CPMK (lebih lebar)

      // Simpan ke file dengan nama: SUB_CPMK_<nama mata kuliah>_<tahun>.xlsx
      final fileName = 'SUB_CPMK_${kodeMatakuliah ?? 'Mata_Kuliah'}_${DateTime.now().year}.xlsx';
      final file = File('${downloadDir.path}/$fileName');
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return file.path;
      }

      return null;
    } catch (e) {
      // Error creating Excel Sub CPMK batch template
      return null;
    }
  }

  /// Download RPS Batch template (untuk import batch RPS per matakuliah)
  /// Format: B1 = Nama Matakuliah, B2 = Kode Matakuliah
  /// Row 3 = Column Headers, Row 4+ = Data
  static Future<String?> downloadRPSBatchTemplate({
    String? kodeMatakuliah,
    String? namaMatakuliah,
  }) async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) return null;

      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      int currentRow = 0;

      // Row 1: Nama Mata Kuliah (di kolom B)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Nama Mata Kuliah';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = namaMatakuliah ?? 'Kalkulus dan Vektor';
      currentRow++;

      // Row 2: Kode Mata Kuliah (di kolom B)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Kode Matakuliah';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = kodeMatakuliah ?? 'PAFS6313';
      currentRow++;

      currentRow++; // Skip baris kosong - sekarang row 4

      // Row 4: Header tabel (sesuai gambar)
      final headers = [
        'Kode Matakuliah',
        'Nama Matakuliah',
        'Minggu Ke',
        'Topik Pembelajaran',
        'Metode Ajar',
        'Bobot (%)',
        'Kode CPMK',
        'Kode Sub CPMK',
        'Kode CPL',
        'Jenis Penilaian',
      ];
      for (int i = 0; i < headers.length; i++) {
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
            .value = headers[i];
      }
      currentRow++;

      // Row 5+: Data contoh (sesuai gambar)
      final dataRows = [
        [
          'PAFS6313',
          'Kalkulus dan Vektor',
          '1',
          'Kinematika - Pendahuluan',
          'Small Group Discussion',
          '5',
          'CPMK.3',
          'SUB-CPMK.1',
          'CPL.4',
          'Aktifitas Partisipatif'
        ],
        [
          'PAFS6313',
          'Kalkulus dan Vektor',
          '2',
          'Kinematika - Gerak Lurus',
          'Discovery Learning',
          '5',
          'CPMK.3',
          'SUB-CPMK.1',
          'CPL.4',
          'Tugas'
        ],
        [
          'PAFS6313',
          'Kalkulus dan Vektor',
          '3',
          'Dinamika - Hukum Newton',
          'Cooperative Learning',
          '5',
          'CPMK.3',
          'SUB-CPMK.2',
          'CPL.4',
          'Kuis'
        ],
        [
          'PAFS6313',
          'Kalkulus dan Vektor',
          '4',
          'Energi dan Kerja',
          'Project Based Learning',
          '5',
          'CPMK.3',
          'SUB-CPMK.2',
          'CPL.4',
          'Hasil Proyek'
        ],
        [
          'PAFS6313',
          'Kalkulus dan Vektor',
          '5',
          'Momentum dan Impuls',
          'Small Group Discussion',
          '5',
          'CPMK.3',
          'SUB-CPMK.3',
          'CPL.4',
          'Aktifitas Partisipatif'
        ],
        [
          'PAFS6313',
          'Kalkulus dan Vektor',
          '6',
          'Rotasi Benda Tegar',
          'Discovery Learning',
          '5',
          'CPMK.3',
          'SUB-CPMK.4',
          'CPL.4',
          'Tugas'
        ],
        [
          'PAFS6313',
          'Kalkulus dan Vektor',
          '7',
          'Gelatik dan Gelombang',
          'Cooperative Learning',
          '5',
          'CPMK.3',
          'SUB-CPMK.4',
          'CPL.4',
          'Kuis'
        ],
        [
          'PAFS6313',
          'Kalkulus dan Vektor',
          '8',
          'Persiapan UTS',
          'Cooperative Learning',
          '0',
          'CPMK.3',
          '',
          'CPL.4',
          ''
        ],
        [
          'PAFS6313',
          'Kalkulus dan Vektor',
          '9',
          'Termodinamika - Pendahuluan',
          'Small Group Discussion',
          '5',
          'CPMK.3',
          'SUB-CPMK.5',
          'CPL.4',
          'Aktifitas Partisipatif'
        ],
        [
          'PAFS6313',
          'Kalkulus dan Vektor',
          '10',
          'Hukum Termodinamika',
          'Discovery Learning',
          '5',
          'CPMK.3',
          'SUB-CPMK.5',
          'CPL.4',
          'Tugas'
        ],
      ];

      // Masukkan data tabel
      for (final row in dataRows) {
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: colIndex, rowIndex: currentRow))
              .value = row[colIndex];
        }
        currentRow++;
      }

      // Set column widths
      sheetObject.setColWidth(0, 18); // Kode Matakuliah
      sheetObject.setColWidth(1, 25); // Nama Matakuliah
      sheetObject.setColWidth(2, 12); // Minggu Ke
      sheetObject.setColWidth(3, 35); // Topik Pembelajaran
      sheetObject.setColWidth(4, 25); // Metode Ajar
      sheetObject.setColWidth(5, 12); // Bobot (%)
      sheetObject.setColWidth(6, 12); // Kode CPMK
      sheetObject.setColWidth(7, 15); // Kode Sub CPMK
      sheetObject.setColWidth(8, 12); // Kode CPL
      sheetObject.setColWidth(9, 25); // Jenis Penilaian

      // Simpan ke file dengan nama: RPS_<kode_mata_kuliah>_<tahun>.xlsx
      final fileName = 'RPS_${kodeMatakuliah ?? 'Mata_Kuliah'}_${DateTime.now().year}.xlsx';
      final file = File('${downloadDir.path}/$fileName');
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return file.path;
      }

      return null;
    } catch (e) {
      // Error creating Excel RPS batch template
      return null;
    }
  }

  /// Download RPS template (EXCEL format)
  /// Kolom urutan: Minggu ke, Topik Pembelajaran, Metode Ajar, Jenis Penilaian, Bobot, Kode CPL, Kode CPMK, Kode Sub CPMK
  static Future<String?> downloadRPSTemplate({String? matakuliahNama, String? kodeMatkuliah}) async {
    try {

      
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        print('[RPS Template] ERROR: Downloads directory not found');
        return null;
      }
      
      print('[RPS Template] Download directory: ${downloadDir.path}');

      // Buat Excel spreadsheet
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      int currentRow = 0;

      // Informasi header (Nama Mata Kuliah)
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Nama Mata Kuliah:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = matakuliahNama ?? 'Mata Kuliah';
      currentRow++;

      // Kode Matakuliah
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = 'Kode Matakuliah:';
      sheetObject
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = kodeMatkuliah ?? '';
      currentRow += 2; // Skip satu baris sebelum tabel

      // Header row tabel sesuai urutan: Kode Matakuliah, Nama Matakuliah, Minggu Ke, Topik Pembelajaran, Metode Ajar, Bobot, Kode CPMK, Kode Sub CPMK, Kode CPL, Jenis Penilaian
      final headers = [
        'Kode Matakuliah',
        'Nama Matakuliah',
        'Minggu Ke',
        'Topik Pembelajaran',
        'Metode Ajar',
        'Bobot (%)',
        'Kode CPMK',
        'Kode Sub CPMK',
        'Kode CPL',
        'Jenis Penilaian'
      ];
      for (int i = 0; i < headers.length; i++) {
        sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow))
            .value = headers[i];
      }
      currentRow++;

      // Data contoh sesuai urutan kolom baru (10 kolom dengan 2 header)
      final dataRows = [
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 1, 'Kinematika - Pendahuluan', 'Small Group Discussion', 5, 'CPMK.1', 'SUB-CPMK.1', 'CPL.1', 'Aktifitas Partisipatif'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 2, 'Kinematika - Gerak Lurus', 'Discovery Learning', 5, 'CPMK.1', 'SUB-CPMK.1', 'CPL.1', 'Tugas'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 3, 'Dinamika - Hukum Newton', 'Cooperative Learning', 5, 'CPMK.2', 'SUB-CPMK.2', 'CPL.2', 'Kuis'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 4, 'Energi dan Kerja', 'Project Based Learning', 5, 'CPMK.2', 'SUB-CPMK.2', 'CPL.2', 'Hasil Proyek'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 5, 'Momentum dan Impuls', 'Small Group Discussion', 5, 'CPMK.3', 'SUB-CPMK.3', 'CPL.3', 'Aktifitas Partisipatif'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 6, 'Rotasi Benda Tegar', 'Discovery Learning', 5, 'CPMK.3', 'SUB-CPMK.3', 'CPL.3', 'Tugas'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 7, 'Osilasi dan Gelombang', 'Cooperative Learning', 5, 'CPMK.4', 'SUB-CPMK.4', 'CPL.4', 'Kuis'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 8, 'Persiapan UTS', '', 0, '', '', '', ''],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 9, 'Termodinamika - Pendahuluan', 'Small Group Discussion', 5, 'CPMK.5', 'SUB-CPMK.5', 'CPL.4', 'Aktifitas Partisipatif'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 10, 'Hukum Termodinamika', 'Discovery Learning', 5, 'CPMK.5', 'SUB-CPMK.5', 'CPL.5', 'Tugas'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 11, 'Gas Ideal', 'Cooperative Learning', 5, 'CPMK.6', 'SUB-CPMK.6', 'CPL.5', 'Kuis'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 12, 'Elektromagnetik Dasar', 'Project Based Learning', 5, 'CPMK.6', 'SUB-CPMK.6', 'CPL.6', 'Hasil Proyek'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 13, 'Medan Magnet', 'Small Group Discussion', 5, 'CPMK.7', 'SUB-CPMK.7', 'CPL.6', 'Aktifitas Partisipatif'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 14, 'Induksi Elektromagnetik', 'Discovery Learning', 5, 'CPMK.7', 'SUB-CPMK.7', 'CPL.7', 'Tugas'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 15, 'Review dan Latihan Soal', 'Cooperative Learning', 5, 'CPMK.7', 'SUB-CPMK.7', 'CPL.7', 'Kuis'],
        [kodeMatkuliah ?? '', matakuliahNama ?? '', 16, 'Ujian Akhir Semester (UAS)', '', 0, '', '', '', ''],
      ];

      print('[RPS Template] Adding ${dataRows.length} rows of data');

      // Masukkan data tabel
      for (final row in dataRows) {
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: colIndex, rowIndex: currentRow))
              .value = row[colIndex];
        }
        currentRow++;
      }

      // Set column widths
      sheetObject.setColWidth(0, 15);   // Kode Matakuliah
      sheetObject.setColWidth(1, 25);   // Nama Matakuliah
      sheetObject.setColWidth(2, 11);   // Minggu Ke
      sheetObject.setColWidth(3, 30);   // Topik Pembelajaran
      sheetObject.setColWidth(4, 20);   // Metode Ajar
      sheetObject.setColWidth(5, 10);   // Bobot
      sheetObject.setColWidth(6, 12);   // Kode CPMK
      sheetObject.setColWidth(7, 15);   // Kode Sub CPMK
      sheetObject.setColWidth(8, 12);   // Kode CPL
      sheetObject.setColWidth(9, 20);   // Jenis Penilaian

      // Simpan ke file dengan nama yang aman: RPS_<nama_matakuliah>.xlsx
      // Sanitasi nama untuk menghindari karakter khusus
      final sanitizedFileName = (matakuliahNama ?? 'MatKul')
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(' ', '_')
          .toLowerCase();
      final fileName = 'RPS_$sanitizedFileName.xlsx';
      final file = File('${downloadDir.path}/$fileName');
      
      print('[RPS Template] Creating file: $fileName at ${file.path}');
      
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        print('[RPS Template] Excel bytes generated: ${fileBytes.length} bytes');
        await file.writeAsBytes(fileBytes);
        print('[RPS Template] File successfully written to ${file.path}');
        return file.path;
      } else {
        print('[RPS Template] ERROR: Excel.save() returned null');
      }

      return null;
    } catch (e) {
      print('[RPS Template] ERROR: $e');
      print('[RPS Template] Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Download template file (CSV)
  Future<String?> downloadTemplate(String templateFileName) async {
    try {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        throw Exception('Folder Downloads tidak ditemukan');
      }

      // Create output file with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileNameWithoutExt = templateFileName.replaceAll('.csv', '');
      final outputPath = '${downloadDir.path}/${fileNameWithoutExt}_$timestamp.csv';
      final outputFile = File(outputPath);

      // Load CSV template content from assets as text
      final String csvContent = await rootBundle.loadString(
        'templates_import/$templateFileName',
      );

      // Write text file
      await outputFile.writeAsString(csvContent);
      
      // Verify
      if (!await outputFile.exists()) {
        throw Exception('Gagal menyimpan file');
      }

      return outputFile.path;
    } catch (e) {
      throw Exception('Download template gagal: ${e.toString()}');
    }
  }

  /// Get template info
  static Map<String, List<String>> getTemplateInfo(String type) {
    switch (type) {
      case 'mahasiswa':
        return {
          'columns': [
            'Kolom A: NIM',
            'Kolom B: Nama',
            'Kolom C: Tahun Masuk',
          ],
        };
      case 'matakuliah':
        return {
          'columns': [
            'Kolom A: Kode Matakuliah',
            'Kolom B: Nama Matakuliah',
            'Kolom C: Semester',
            'Kolom D: Jenis (wajib/pilihan)',
            'Kolom E: SKS (1-6)',
          ],
        };
      case 'nilai':
        return {
          'columns': [
            'Kolom A: NIM Mahasiswa',
            'Kolom B: Nama Mahasiswa',
            'Kolom C: Kode Matakuliah',
            'Kolom D: Nama Matakuliah',
            'Kolom E: Grade (A/B/C/D/E)',
            'Kolom F: Tahun Ajaran',
          ],
        };
      case 'nilai_detail':
        return {
          'columns': [
            'Header (Otomatis Terisi):',
            '  • Kode Matakuliah',
            '  • Nama Matakuliah',
            '  • Tahun Ajaran',
            '',
            'Kolom Tabel Data:',
            '  A: NIM Mahasiswa',
            '  B: Nama Mahasiswa',
            '  C: Nilai Aktivitas (0-100)',
            '  D: Nilai Hasil Proyek (0-100)',
            '  E: Nilai Tugas (0-100)',
            '  F: Nilai Kuis (0-100)',
            '  G: Nilai UTS (0-100)',
            '  H: Nilai UAS (0-100)',
          ],
          'formula': [
            'Rumus Nilai Akhir:',
            'Nilai = (Aktivitas×10% + Tugas×10% + Hasil Proyek×15% + Kuis×15% + UTS×25% + UAS×25%)',
          ],
        };
      case 'cpl':
        return {
          'columns': [
            'Kolom A: Nomor CPL (1-7)',
            'Kolom B: Deskripsi CPL',
          ],
        };
      case 'cpmk':
        return {
          'columns': [
            'Header (Otomatis Terisi):',
            '  • Nama Mata Kuliah',
            '  • Kode Mata Kuliah',
            '',
            'Kolom Tabel Data:',
            '  A: Nomor CPMK (angka)',
            '  B: Deskripsi CPMK (penjelasan detail capaian pembelajaran)',
          ],
        };
      case 'sub_cpmk':
        return {
          'columns': [
            'Header (Otomatis Terisi):',
            '  • Nama Mata Kuliah',
            '',
            'Kolom Tabel Data:',
            '  A: Kode Sub CPMK (format: SUB-CPMK.1, SUB-CPMK.2, dll)',
            '  B: Deskripsi Sub CPMK (penjelasan detail pembelajaran)',
          ],
        };
      default:
        return {'columns': []};
    }
  }
}
