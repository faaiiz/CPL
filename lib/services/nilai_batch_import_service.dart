import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/nilai_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/matakuliah_model.dart';
import 'database_helper.dart';

/// Service untuk batch import nilai template dalam 1 tahun ajaran yang sama
class NilaiBatchImportService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  static const Map<String, double> _gradeNumerikMap = {
    'A': 4.0,
    'B': 3.0,
    'C': 2.0,
    'D': 1.0,
    'E': 0.0,
  };

  /// Import multiple nilai files dengan tahun ajaran yang sama
  /// 
  /// Params:
  /// - filePaths: List of file paths to be imported
  /// - tahunAjaran: Academic year (e.g., 2024)
  /// - onProgress: Callback untuk progress tracking (fileIndex, totalFiles)
  /// 
  /// Returns: Map dengan statistik import
  Future<Map<String, dynamic>> importNilaiFilesForAcademicYear(
    List<String> filePaths,
    int tahunAjaran, {
    void Function(int, int)? onProgress,
  }) async {
    try {
      final overallResults = <String, dynamic>{
        'success': true,
        'message': '',
        'totalFiles': filePaths.length,
        'processedFiles': 0,
        'totalImported': 0,
        'totalFailed': 0,
        'errors': <String>[],
        'fileResults': <Map<String, dynamic>>[],
      };

      if (filePaths.isEmpty) {
        overallResults['success'] = false;
        overallResults['message'] = 'Tidak ada file yang dipilih';
        return overallResults;
      }

      // Process each file
      for (int i = 0; i < filePaths.length; i++) {
        try {
          final filePath = filePaths[i];
          final fileName = _extractFileName(filePath);

          // Call progress callback
          onProgress?.call(i + 1, filePaths.length);

          // Import file
          final fileResult = await _importSingleNilaiFile(
            filePath,
            tahunAjaran,
          );

          // Add file name to result
          fileResult['fileName'] = fileName;
          overallResults['fileResults'].add(fileResult);

          // Update overall statistics
          overallResults['processedFiles']++;
          overallResults['totalImported'] +=
              (fileResult['imported'] as int?) ?? 0;
          overallResults['totalFailed'] +=
              (fileResult['failed'] as int?) ?? 0;

          // Collect errors
          if (fileResult['errors'] != null) {
            final errors = fileResult['errors'] as List<dynamic>;
            for (var error in errors) {
              overallResults['errors'].add('$fileName: $error');
            }
          }
        } catch (e) {
          overallResults['errors'].add('Error processing file ${i + 1}: $e');
          overallResults['totalFailed']++;
        }
      }

      // Generate final message
      overallResults['message'] =
          'Diproses: ${overallResults['processedFiles']} file, '
          'Berhasil: ${overallResults['totalImported']} nilai, '
          'Gagal: ${overallResults['totalFailed']} nilai';

      if (overallResults['totalFailed'] > 0) {
        overallResults['success'] = false;
      }

      return overallResults;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'totalFiles': filePaths.length,
        'processedFiles': 0,
        'totalImported': 0,
        'totalFailed': 0,
        'errors': [e.toString()],
        'fileResults': <Map<String, dynamic>>[],
      };
    }
  }

  /// Import single nilai file dengan validasi tahun ajaran
  Future<Map<String, dynamic>> _importSingleNilaiFile(
    String filePath,
    int tahunAjaran,
  ) async {
    try {
      // Gunakan ExcelImportService untuk membaca file
      final rows = await _readFileData(filePath);

      final results = <String, dynamic>{
        'success': true,
        'imported': 0,
        'failed': 0,
        'errors': <String>[],
      };

      if (rows.isEmpty) {
        results['success'] = false;
        results['errors'].add('File kosong');
        return results;
      }

      // Cari header row
      int headerRowIndex = 0;
      String? namaMatakuliahFromTemplate;

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isNotEmpty) {
          final firstCol = row[0]?.toString().trim().toUpperCase() ?? '';

          // Ambil info Nama Matakuliah
          if (i == 1 && row.length > 1) {
            final firstColText = row[0]?.toString().trim() ?? '';
            if (firstColText.contains('Nama Matakuliah') ||
                firstColText.contains('Matakuliah')) {
              namaMatakuliahFromTemplate = row[1]?.toString().trim();
            }
          }

          // Temukan header row
          if (firstCol == 'NIM') {
            headerRowIndex = i;
            break;
          }
        }
      }

      final nilaiList = <Nilai>[];
      final dataRows = rows.skip(headerRowIndex + 1).toList();

      int rowNumber = headerRowIndex + 1;
      for (var row in dataRows) {
        rowNumber++;
        try {
          if (row.isEmpty) continue;

          final nim = row[0]?.toString().trim() ?? '';
          final nama = row[1]?.toString().trim() ?? '';

          if (nim.isEmpty || nama.isEmpty) {
            results['errors'].add('Baris $rowNumber: NIM dan Nama harus diisi');
            results['failed']++;
            continue;
          }

          // Parse nilai berdasarkan jumlah kolom
          // Bisa berupa: grade sederhana atau detail (aktivitas, tugas, kuis, uts, uas)
          double nilaiAkhir;
          String gradeHuruf;

          if (row.length >= 7) {
            // Format detail: NIM, Nama, Aktivitas, Tugas, Kuis, UTS, UAS
            final aktivitasStr = row[2]?.toString().trim() ?? '';
            final tugasStr = row[3]?.toString().trim() ?? '';
            final kuisStr = row[4]?.toString().trim() ?? '';
            final utsStr = row[5]?.toString().trim() ?? '';
            final uasStr = row[6]?.toString().trim() ?? '';

            final aktivitas = double.tryParse(aktivitasStr);
            final tugas = double.tryParse(tugasStr);
            final kuis = double.tryParse(kuisStr);
            final uts = double.tryParse(utsStr);
            final uas = double.tryParse(uasStr);

            if (aktivitas == null ||
                tugas == null ||
                kuis == null ||
                uts == null ||
                uas == null) {
              results['errors'].add(
                  'Baris $rowNumber: Semua nilai komponen harus berupa angka');
              results['failed']++;
              continue;
            }

            // Validasi range
            if (aktivitas < 0 ||
                aktivitas > 100 ||
                tugas < 0 ||
                tugas > 100 ||
                kuis < 0 ||
                kuis > 100 ||
                uts < 0 ||
                uts > 100 ||
                uas < 0 ||
                uas > 100) {
              results['errors']
                  .add('Baris $rowNumber: Semua nilai harus dalam range 0-100');
              results['failed']++;
              continue;
            }

            nilaiAkhir = _calculateNilaiAkhir(
              aktivitas: aktivitas,
              tugas: tugas,
              kuis: kuis,
              uts: uts,
              uas: uas,
            );
            gradeHuruf = _nilaiToGrade(nilaiAkhir);
          } else if (row.length >= 3) {
            // Format sederhana: NIM, Nama, Grade/Nilai
            final nilaiStr = row[2]?.toString().trim().toUpperCase() ?? '';

            if (_gradeNumerikMap.containsKey(nilaiStr)) {
              // Grade format (A, B, C, D, E)
              gradeHuruf = nilaiStr;
              nilaiAkhir = _gradeNumerikMap[nilaiStr]!;
            } else {
              // Numeric format
              final nilaiNum = double.tryParse(nilaiStr);
              if (nilaiNum == null || nilaiNum < 0 || nilaiNum > 100) {
                results['errors'].add(
                    'Baris $rowNumber: Nilai harus berupa angka (0-100) atau grade (A-E)');
                results['failed']++;
                continue;
              }
              nilaiAkhir = nilaiNum;
              gradeHuruf = _nilaiToGrade(nilaiAkhir);
            }
          } else {
            results['errors']
                .add('Baris $rowNumber: Kolom tidak lengkap (minimal 3 kolom)');
            results['failed']++;
            continue;
          }

          // Cek dan tambahkan mahasiswa jika belum ada
          var mahasiswa = await _dbHelper.getMahasiswaByNim(nim);
          if (mahasiswa == null) {
            mahasiswa = Mahasiswa(
              nim: nim,
              nama: nama,
              tahunMasuk: tahunAjaran,
              createdAt: DateTime.now(),
            );
            final mahasiswaId = await _dbHelper.insertMahasiswa(mahasiswa);
            mahasiswa = mahasiswa.copyWith(id: mahasiswaId);
          }

          // Tentukan kode dan nama matakuliah
          String kodeMatakuliah = _extractMatakuliahKode(
              namaMatakuliahFromTemplate ?? 'MK_${DateTime.now().millisecondsSinceEpoch}');
          String namaMatakuliah = namaMatakuliahFromTemplate ?? 'Unnamed Course';

          // Cek dan tambahkan matakuliah jika belum ada
          var matakuliah = await _dbHelper.getMatakuliahByKode(kodeMatakuliah);
          if (matakuliah == null) {
            matakuliah = Matakuliah(
              kode: kodeMatakuliah,
              nama: namaMatakuliah,
              sks: 3,
              semester: '1',
              jenis: 'wajib',
              createdAt: DateTime.now(),
            );
            final matakuliahId =
                await _dbHelper.insertMatakuliah(matakuliah);
            matakuliah = matakuliah.copyWith(id: matakuliahId);
          }

          // Buat nilai
          final nilai = Nilai(
            mahasiswaId: mahasiswa.id!,
            matakuliahId: matakuliah.id!,
            gradeHuruf: gradeHuruf,
            nilaiNumerik: nilaiAkhir,
            tahunAjaran: tahunAjaran,
            createdAt: DateTime.now(),
          );

          nilaiList.add(nilai);
          results['imported']++;
        } catch (e) {
          results['errors'].add('Baris $rowNumber: ${e.toString()}');
          results['failed']++;
        }
      }

      // Insert semua nilai
      if (nilaiList.isNotEmpty) {
        await _dbHelper.insertNilaiBatch(nilaiList);
      }

      return results;
    } catch (e) {
      return {
        'success': false,
        'imported': 0,
        'failed': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Baca data dari file Excel/CSV
  Future<List<List<dynamic>>> _readFileData(String filePath) async {
    try {
      final file = File(filePath);

      if (filePath.toLowerCase().endsWith('.xlsx') ||
          filePath.toLowerCase().endsWith('.xls')) {
        // Baca Excel file
        final bytes = file.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);

        final rows = <List<dynamic>>[];
        for (var table in excel.tables.keys) {
          final sheet = excel.tables[table];
          if (sheet != null) {
            for (var row in sheet.rows) {
              final rowData = <dynamic>[];
              for (var cell in row) {
                rowData.add(cell?.value ?? '');
              }
              rows.add(rowData);
            }
          }
        }
        return rows;
      } else {
        // Baca CSV file
        final content = await file.readAsString();
        final rows = const CsvToListConverter().convert(content);
        return rows;
      }
    } catch (e) {
      print('Error reading file: $e');
      rethrow;
    }
  }

  /// Convert nilai numeric to grade (A-E)
  String _nilaiToGrade(double nilai) {
    if (nilai >= 85) return 'A';
    if (nilai >= 70) return 'B';
    if (nilai >= 60) return 'C';
    if (nilai >= 45) return 'D';
    return 'E';
  }

  /// Calculate final nilai from components
  double _calculateNilaiAkhir({
    required double aktivitas,
    required double tugas,
    required double kuis,
    required double uts,
    required double uas,
  }) {
    // Bobot: Aktivitas 10%, Tugas 20%, Kuis 20%, UTS 25%, UAS 25%
    return (aktivitas * 0.10) +
        (tugas * 0.20) +
        (kuis * 0.20) +
        (uts * 0.25) +
        (uas * 0.25);
  }

  /// Extract file name from path
  String _extractFileName(String filePath) {
    return filePath.split('/').last.split('\\').last;
  }

  /// Extract matakuliah kode dari nama file atau default
  String _extractMatakuliahKode(String namaMatakuliah) {
    // Extract first 3-4 characters atau gunakan abbreviation
    final parts = namaMatakuliah.split(' ');
    if (parts.isNotEmpty) {
      final len = parts.first.length;
      final codeLen = len > 4 ? 4 : len;
      return parts.first.substring(0, codeLen);
    }
    return 'MK';
  }
}
