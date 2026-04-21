import 'dart:io';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ExcelTemplateService {
  /// Generate and save the Nilai Import Template
  /// Returns the file path where the template was saved
  static Future<String> generateNilaiImportTemplate({
    String? kodeMatakuliah,
    String? namaMatakuliah,
    String? tahunAjaran,
  }) async {
    try {
      // Create Excel workbook
      final excel = excel_lib.Excel.createExcel();
      
      // Get the first sheet
      final sheet = excel.sheets.values.first;

      // Set column widths
      sheet.setColWidth(0, 20); // A
      sheet.setColWidth(1, 30); // B
      sheet.setColWidth(2, 20); // C
      sheet.setColWidth(3, 20); // D
      sheet.setColWidth(4, 20); // E
      sheet.setColWidth(5, 20); // F
      sheet.setColWidth(6, 20); // G
      sheet.setColWidth(7, 20); // H

      // Row 0: Kode Matakuliah
      var cellA0 = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      cellA0.value = 'Kode Matakuliah:';
      
      var cellB0 = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0));
      cellB0.value = kodeMatakuliah ?? '';

      // Row 1: Nama Matakuliah
      var cellA1 = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      cellA1.value = 'Nama Matakuliah:';
      
      var cellB1 = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1));
      cellB1.value = namaMatakuliah ?? '';

      // Row 2: Tahun Ajaran
      var cellA2 = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
      cellA2.value = 'Tahun Ajaran:';
      
      var cellB2 = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2));
      cellB2.value = tahunAjaran ?? '';

      // Row 4: Headers
      final headers = [
        'NIM',
        'Nama Mahasiswa',
        'Aktivitas Partisipasi',
        'Hasil Proyek',
        'Kuis',
        'Tugas',
        'UTS',
        'UAS'
      ];

      for (int col = 0; col < headers.length; col++) {
        var cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 4));
        cell.value = headers[col];
      }

      // Add 10 empty rows for data (rows 5-14)
      for (int row = 5; row < 15; row++) {
        for (int col = 0; col < headers.length; col++) {
          var cell = sheet.cell(
            excel_lib.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
          );
          cell.value = '';
        }
      }

      // Save file
      final fileName =
          'Template_Import_Nilai_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      
      // Get Downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/Downloads');
      
      // Create Downloads directory if it doesn't exist
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);
      
      final excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
      }

      return filePath;
    } catch (e) {
      throw Exception('Gagal membuat template: $e');
    }
  }

  /// Open the file at the given path (platform-specific)
  static Future<void> openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Platform-specific file opening
        if (Platform.isWindows) {
          await Process.run('start', [filePath], runInShell: true);
        } else if (Platform.isMacOS) {
          await Process.run('open', [filePath]);
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [filePath]);
        }
      }
    } catch (e) {
      throw Exception('Gagal membuka file: $e');
    }
  }
}
