import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/rps_detail_model.dart';
import '../models/matakuliah_model.dart';
import '../models/cpmk_model.dart';
import '../models/sub_cpmk_model.dart';
import '../models/cpl_master_model.dart';
import '../models/sub_cpmk_cpmk_mapping_model.dart';
import 'database_helper.dart';

class RPSExcelService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Learning methods for validation
  static const List<String> _validLearningMethods = [
    'Case Based Learning',
    'Project Based Learning',
    'Small Group Discussion',
    'Discovery Learning',
    'Contextual Learning',
    'Contextual Instruction',
    'Cooperative Learning',
    'Collaborative Learning',
  ];

  // Assessment types for validation
  static const List<String> _validAssessmentTypes = [
    'Aktifitas Partisipatif',
    'Hasil Proyek',
    'Kuis',
    'Tugas',
  ];

  /// Import RPS dari file Excel/XLSX
  /// Format Excel:
  /// Baris 1: Nama Mata Kuliah: {nama}
  /// Baris 2: Kode Matakuliah: {kode}
  /// Baris 3: (kosong)
  /// Baris 4: Header (Kode Matakuliah, Nama Matakuliah, Minggu Ke, Topik Pembelajaran, Metode Ajar, Bobot (%), Kode CPMK, Kode Sub CPMK, Kode CPL, Jenis Penilaian)
  /// Baris ke-5 dst: Data (10 kolom sesuai header)
  Future<Map<String, dynamic>> importRPSFromExcel(
    String filePath,
    Matakuliah matakuliah,
  ) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Try to read as Excel file
      late final List<List<dynamic>> rows;
      bool isExcelFile = false;
      
      try {
        print('[RPS Import] Attempting to parse as Excel file...');
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables.values.first;
        rows = sheet.rows;
        isExcelFile = true;
        print('[RPS Import] Successfully parsed as Excel file');
      } catch (e) {
        print('[RPS Import] Excel parsing failed: $e. Attempting CSV parsing...');
        // Fallback to CSV parsing
        final content = await file.readAsString();
        rows = const CsvToListConverter().convert(content);
        isExcelFile = false;
        print('[RPS Import] Successfully parsed as CSV file');
      }

      print('[RPS Import] File parsed (isExcel: $isExcelFile), total rows: ${rows.length}');
      if (rows.isNotEmpty) {
        print('[RPS Import] First row sample: ${rows.first.length} cols');
        if (rows.first.isNotEmpty) {
          final firstCell = rows.first.first;
          print('[RPS Import] First cell type: ${firstCell.runtimeType}, value: $firstCell');
        }
      }

      final results = <String, dynamic>{
        'success': true,
        'message': '',
        'imported': 0,
        'failed': 0,
        'errors': <String>[],
        'matakuliah': matakuliah,
      };

      if (rows.isEmpty) {
        results['success'] = false;
        results['message'] = 'File kosong';
        return results;
      }

      // Skip header rows (first 4 rows: title, kode, empty, header)
      final dataRows = rows.skip(4).toList();

      if (dataRows.isEmpty) {
        results['success'] = false;
        results['message'] = 'Tidak ada data untuk diimpor (minimal harus ada 1 baris data)';
        return results;
      }

      final rpsList = <RPSDetail>[];
      int rowNumber = 5; // Mulai dari baris ke-5 (setelah header)

      print('[RPS Import] dataRows length: ${dataRows.length}');
      print('[RPS Import] Processing rows starting from row 5...');

      for (var row in dataRows) {
        try {
          print('[RPS Import] Row $rowNumber - Raw row length: ${row.length}');
          
          // Skip baris kosong
          if (row.isEmpty || row.every((cell) => cell == null || cell.toString().isEmpty)) {
            rowNumber++;
            continue;
          }

          // Helper function untuk extract cell value dari Data object (dari excel library)
          // Data object memiliki struktur: Data(value, colIndex, rowIndex, CellStyle, ...)
          // Kita perlu access .value property dari Data object
          String extractCellValueToString(dynamic cell) {
            if (cell == null) return '';
            try {
              // Cek apakah cell punya property 'value' (untuk Data objects dari excel library)
              final value = (cell as dynamic).value;
              if (value != null) {
                return value.toString().trim();
              }
            } catch (e) {
              // property .value tidak ada atau error
            }
            // Fallback: gunakan toString() tapi remove wrapper jika ada
            final cellStr = cell.toString();
            // Jika format Data(...), coba extract value dari dalam
            if (cellStr.startsWith('Data(')) {
              try {
                // Format: Data(value, colIndex, rowIndex, ...)
                // Extract value antara Data( dan comma pertama
                final start = cellStr.indexOf('(') + 1;
                final end = cellStr.indexOf(',', start);
                if (end > start) {
                  return cellStr.substring(start, end).trim();
                }
              } catch (e) {
                print('[RPS Import] Error extracting from Data string: $e');
              }
            }
            return cellStr.trim();
          }

          // Hanya proses jika ada data di kolom pertama (kode matakuliah)
          final kodeMatakuliahStr = extractCellValueToString(row.isNotEmpty ? row[0] : null);
          if (kodeMatakuliahStr.isEmpty) {
            rowNumber++;
            continue;
          }

          // Parse kolom sesuai struktur template Excel (10 kolom dengan 2 header): 
          // 0: Kode Matakuliah, 1: Nama Matakuliah, 2: Minggu Ke, 3: Topik Pembelajaran, 4: Metode Ajar, 5: Bobot (%), 6: Kode CPMK, 7: Kode Sub CPMK, 8: Kode CPL, 9: Jenis Penilaian
          final mingguKeStr = extractCellValueToString(row.length > 2 ? row[2] : null);
          final topik = extractCellValueToString(row.length > 3 ? row[3] : null);
          final metodeAjar = extractCellValueToString(row.length > 4 ? row[4] : null);
          final bobotStr = extractCellValueToString(row.length > 5 ? row[5] : null);
          final kodesCPMK = extractCellValueToString(row.length > 6 ? row[6] : null);
          final kodesSubCPMK = extractCellValueToString(row.length > 7 ? row[7] : null);
          final kodesCPL = extractCellValueToString(row.length > 8 ? row[8] : null);
          final jenisNilaiStr = extractCellValueToString(row.length > 9 ? row[9] : null);
          
          print('[RPS Import] Row $rowNumber - Extracted: mingguKeStr="$mingguKeStr", topik="$topik"');

          // Validasi minggu ke
          final mingguKe = int.tryParse(mingguKeStr);
          if (mingguKe == null || mingguKe < 1 || mingguKe > 16) {
            print('[RPS Import] Row $rowNumber - FAILED: mingguKe=$mingguKe (dari "$mingguKeStr")');
            results['errors'].add(
                'Baris $rowNumber: Minggu Ke harus berupa angka antara 1-16 (nilai: "$mingguKeStr")');
            results['failed']++;
            rowNumber++;
            continue;
          }

          print('[RPS Import] Row $rowNumber - SUCCESS: mingguKe=$mingguKe');

          // Validasi topik
          if (topik.isEmpty) {
            results['errors'].add('Baris $rowNumber: Topik pembelajaran harus diisi');
            results['failed']++;
            rowNumber++;
            continue;
          }

          // Validasi metode ajar - tidak diperlukan untuk UTS dan UAS
          if (metodeAjar.isEmpty && jenisNilaiStr != 'UTS' && jenisNilaiStr != 'UAS') {
            results['errors'].add('Baris $rowNumber: Metode ajar harus diisi');
            results['failed']++;
            rowNumber++;
            continue;
          }

          if (metodeAjar.isNotEmpty && !_validLearningMethods.contains(metodeAjar)) {
            results['errors'].add(
                'Baris $rowNumber: Metode ajar "$metodeAjar" tidak valid. Gunakan salah satu: ${_validLearningMethods.join(", ")}');
            results['failed']++;
            rowNumber++;
            continue;
          }

          // Validasi bobot (optional)
          double? bobot;
          if (bobotStr.isNotEmpty) {
            bobot = double.tryParse(bobotStr);
            if (bobot == null || bobot < 0 || bobot > 100) {
              results['errors'].add(
                  'Baris $rowNumber: Bobot harus berupa angka antara 0-100 (opsional)');
              results['failed']++;
              rowNumber++;
              continue;
            }
          } else {
            bobot = 0; // Default 0 jika tidak diisi
          }

          // Parse CPMK codes dan validasi (optional)
          List<int>? cpmkIds;
          if (kodesCPMK.isNotEmpty) {
            cpmkIds = await _parseAndValidateCodeList(
              kodesCPMK,
              'CPMK',
              rowNumber,
              results,
              0, // matakuliahId = 0 untuk program-level CPMK
            );
            if (cpmkIds == null && kodesCPMK.isNotEmpty) {
              results['failed']++;
              rowNumber++;
              continue;
            }
          }

          // Parse Sub CPMK codes dan validasi (optional)
          List<int>? subCpmkIds;
          if (kodesSubCPMK.isNotEmpty) {
            subCpmkIds = await _parseAndValidateCodeList(
              kodesSubCPMK,
              'Sub CPMK',
              rowNumber,
              results,
              matakuliah.id!,
            );
            if (subCpmkIds == null && kodesSubCPMK.isNotEmpty) {
              results['failed']++;
              rowNumber++;
              continue;
            }
          }

          // Parse CPL codes dan validasi (optional)
          List<int>? cplIds;
          if (kodesCPL.isNotEmpty) {
            cplIds = await _parseAndValidateCPLCodes(
              kodesCPL,
              rowNumber,
              results,
            );
            if (cplIds == null && kodesCPL.isNotEmpty) {
              results['failed']++;
              rowNumber++;
              continue;
            }
          }

          // Parse dan validasi Jenis Penilaian (optional)
          String? jenisNilai;
          if (jenisNilaiStr.isNotEmpty) {
            if (_validAssessmentTypes.contains(jenisNilaiStr)) {
              jenisNilai = jenisNilaiStr;
            } else {
              results['errors'].add(
                  'Baris $rowNumber: Jenis Penilaian "$jenisNilaiStr" tidak valid. Gunakan salah satu: ${_validAssessmentTypes.join(", ")}');
              results['failed']++;
              rowNumber++;
              continue;
            }
          }

          // Buat RPS Detail object
          final rpsDetail = RPSDetail(
            matakuliahId: matakuliah.id!,
            mingguKe: mingguKe,
            topik: topik,
            metodeAjar: metodeAjar,
            bobot: bobot,
            cpmkIds: cpmkIds,
            subCpmkIds: subCpmkIds,
            cplIds: cplIds,
            jenisNilai: jenisNilai,
            createdAt: DateTime.now(),
          );

          rpsList.add(rpsDetail);
        } catch (e) {
          results['errors'].add('Baris $rowNumber: Error parsing - ${e.toString()}');
          results['failed']++;
        }
        rowNumber++;
      }

      // Jika ada error, jangan import
      if (results['failed'] > 0) {
        results['success'] = false;
        results['message'] =
            'Import gagal: ${results['failed']} baris memiliki error';
        return results;
      }

      // Hapus RPS lama untuk matakuliah ini sebelum import data baru
      print('[RPS Import] Deleting old RPS data for matakuliah_id=${matakuliah.id}');
      await _dbHelper.deleteRPSDetailByMatakuliah(matakuliah.id!);
      print('[RPS Import] Old RPS data deleted');

      // Import ke database
      for (var rps in rpsList) {
        await _dbHelper.insertRPSDetail(rps);
      }

      // Auto-create Sub-CPMK → CPMK mapping
      print('[RPS Import] Creating Sub-CPMK → CPMK mappings...');
      await _createSubCPMKtoCPMKMappings(matakuliah.id!);
      print('[RPS Import] Sub-CPMK → CPMK mappings created');

      results['imported'] = rpsList.length;
      results['message'] = '${rpsList.length} data RPS berhasil diimpor + mappings created';
      return results;
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'message': 'Error: ${e.toString()}',
        'imported': 0,
        'failed': 1,
        'errors': [e.toString()],
      };
    }
  }

  /// Helper function untuk parse dan validasi list code CPMK/Sub CPMK
  /// Untuk CPMK: auto-create jika tidak ditemukan di database
  Future<List<int>?> _parseAndValidateCodeList(
    String codes,
    String type,
    int rowNumber,
    Map<String, dynamic> results,
    int matakuliahId,
  ) async {
    try {
      final codeList = codes.split(';').map((c) => c.trim()).toList();
      final idList = <int>[];

      for (var code in codeList) {
        if (code.isEmpty) continue;

        if (type == 'CPMK') {
          var cpmk = await _dbHelper.getCPMKByKode(code);
          if (cpmk == null) {
            // Auto-create CPMK jika tidak ditemukan
            print('[RPS Import] Auto-creating CPMK: $code');
            cpmk = CPMK(
              kodeCPMK: code,
              deskripsi: 'Auto-created dari RPS import: $code',
              matakuliahId: 0, // 0 = program-level CPMK
              createdAt: DateTime.now(),
            );
            final createdId = await _dbHelper.insertCPMK(cpmk);
            print('[RPS Import] CPMK $code berhasil dibuat dengan ID: $createdId');
            idList.add(createdId);
          } else {
            idList.add(cpmk.id!);
          }
        } else if (type == 'Sub CPMK') {
          // Cari Sub CPMK berdasarkan kode dan matakuliahId
          final allSubCpmks = await _dbHelper.getSubCPMKByMatakuliah(matakuliahId);
          SubCPMK? foundSubCpmk;
          
          try {
            foundSubCpmk = allSubCpmks.firstWhere(
              (sc) => sc.kodeSubCPMK == code,
            );
          } catch (e) {
            // Sub CPMK tidak ditemukan - auto-create
            print('[RPS Import] Auto-creating Sub CPMK: $code untuk matakuliah_id=$matakuliahId');
            foundSubCpmk = SubCPMK(
              matakuliahId: matakuliahId,
              kodeSubCPMK: code,
              deskripsi: 'Auto-created dari RPS import: $code',
              createdAt: DateTime.now(),
            );
            final createdId = await _dbHelper.insertSubCPMK(foundSubCpmk);
            print('[RPS Import] Sub CPMK $code berhasil dibuat dengan ID: $createdId');
            foundSubCpmk = foundSubCpmk.copyWith(id: createdId);
          }
          
          if (foundSubCpmk.id == null) {
            results['errors'].add(
                'Baris $rowNumber: Sub CPMK dengan kode "$code" tidak bisa dibuat untuk mata kuliah ini');
            return null;
          }
          idList.add(foundSubCpmk.id!);
        }
      }

      return idList.isNotEmpty ? idList : null;
    } catch (e) {
      results['errors'].add(
          'Baris $rowNumber: Error parsing $type codes - ${e.toString()}');
      return null;
    }
  }

  /// Helper function untuk parse dan validasi list CPL codes
  Future<List<int>?> _parseAndValidateCPLCodes(
    String codes,
    int rowNumber,
    Map<String, dynamic> results,
  ) async {
    try {
      final codeList = codes.split(';').map((c) => c.trim()).toList();
      final idList = <int>[];
      final allCPLs = await _dbHelper.getAllCPLMaster();

      for (var code in codeList) {
        if (code.isEmpty) continue;

        final cpl = allCPLs.firstWhere(
          (c) => c.kodeCPL == code,
          orElse: () => throw 'not found',
        );

        idList.add(cpl.id!);
      }

      return idList.isNotEmpty ? idList : null;
    } catch (e) {
      results['errors']
          .add('Baris $rowNumber: Error parsing CPL codes - ${e.toString()}');
      return null;
    }
  }

  /// Generate XLSX template untuk RPS import
  List<int> generateRPSTemplate(
    Matakuliah matakuliah,
    List<CPMK> cpmkList,
    List<SubCPMK> subCpmkList,
    List<CPLMaster> cplList,
  ) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    int rowIndex = 0;

    // Header dengan instruksi
    sheet.insertRowIterables(['TEMPLATE RPS - ${matakuliah.nama}'], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['Kode Matakuliah: ${matakuliah.kode}'], rowIndex);
    rowIndex++;
    sheet.insertRowIterables([], rowIndex); // Empty row
    rowIndex++;

    // Main header
    sheet.insertRowIterables([
      'Minggu Ke',
      'Topik Pembelajaran',
      'Metode Ajar',
      'Bobot (%)',
      'Kode CPMK',
      'Kode Sub CPMK',
      'Kode CPL',
      'Jenis Penilaian',
    ], rowIndex);
    rowIndex++;

    // Example rows (16 weeks)
    for (int i = 1; i <= 16; i++) {
      sheet.insertRowIterables([
        i,
        'Masukkan topik pembelajaran minggu ke-$i',
        'Masukkan metode ajar (lihat petunjuk di bawah)',
        '', // Bobot dikosongkan - user isi
        '', // CPMK dikosongkan
        '', // Sub CPMK dikosongkan
        '', // CPL dikosongkan
        '', // Jenis Penilaian dikosongkan
      ], rowIndex);
      rowIndex++;
    }

    // Helper text / Petunjuk
    sheet.insertRowIterables([], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['PETUNJUK PENGISIAN:'], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['Jenis Penilaian yang tersedia:'], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['1. Aktivitas Partisipatif'], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['2. Kuis'], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['3. Tugas'], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['4. Hasil Proyek'], rowIndex);
    rowIndex++;

    sheet.insertRowIterables([], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['Metode Ajar yang tersedia:'], rowIndex);
    rowIndex++;
    for (int i = 0; i < _validLearningMethods.length; i++) {
      sheet.insertRowIterables(['${i + 1}. ${_validLearningMethods[i]}'], rowIndex);
      rowIndex++;
    }

    sheet.insertRowIterables([], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['Daftar CPMK yang tersedia untuk mata kuliah ini:'], rowIndex);
    rowIndex++;
    for (var cpmk in cpmkList) {
      sheet.insertRowIterables(['${cpmk.kodeCPMK} - ${cpmk.deskripsi}'], rowIndex);
      rowIndex++;
    }

    sheet.insertRowIterables([], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['Daftar Sub CPMK yang tersedia untuk mata kuliah ini:'], rowIndex);
    rowIndex++;
    for (var subCpmk in subCpmkList) {
      sheet.insertRowIterables(['${subCpmk.kodeSubCPMK} - ${subCpmk.deskripsi}'], rowIndex);
      rowIndex++;
    }

    sheet.insertRowIterables([], rowIndex);
    rowIndex++;
    sheet.insertRowIterables(['Daftar CPL yang tersedia:'], rowIndex);
    rowIndex++;
    for (var cpl in cplList) {
      sheet.insertRowIterables(['${cpl.kodeCPL} - ${cpl.deskripsi}'], rowIndex);
      rowIndex++;
    }

    return excel.encode()!;
  }

  /// Auto-create Sub-CPMK → CPMK mappings
  /// Matches SUB-CPMK.X with CPMK.X where X is the number
  Future<void> _createSubCPMKtoCPMKMappings(int matakuliahId) async {
    try {
      // Get all Sub-CPMK for this matakuliah
      final subCpmkList = await _dbHelper.getSubCPMKByMatakuliah(matakuliahId);
      
      if (subCpmkList.isEmpty) {
        print('[RPS Import] No Sub-CPMK found for matakuliah $matakuliahId');
        return;
      }

      // Get all CPMK (program-level)
      final cpmkList = await _dbHelper.getAllCPMK();
      
      print('[RPS Import] Processing ${subCpmkList.length} Sub-CPMK for mapping');

      // For each Sub-CPMK, find matching CPMK
      for (final subCpmk in subCpmkList) {
        if (subCpmk.id == null) continue;

        // Extract number from SUB-CPMK.X (e.g., "1" from "SUB-CPMK.1")
        String subCpmkCode = subCpmk.kodeSubCPMK.trim();
        String subCpmkNumber = subCpmkCode.replaceFirst(RegExp(r'SUB-CPMK\.'), '');
        
        print('[RPS Import] Sub-CPMK: $subCpmkCode → Looking for CPMK.$subCpmkNumber');

        // Find matching CPMK with same number
        CPMK? matchedCpmk;
        for (final cpmk in cpmkList) {
          String cpmkCode = cpmk.kodeCPMK.trim();
          if (cpmkCode == 'CPMK.$subCpmkNumber') {
            matchedCpmk = cpmk;
            break;
          }
        }

        if (matchedCpmk != null && matchedCpmk.id != null) {
          // Check if mapping already exists
          final existingMapping = await _dbHelper.getSubCPMKCPMKMappingSingle(
            subCpmk.id!,
            matchedCpmk.id!,
          );

          if (existingMapping == null) {
            // Create mapping with 100% bobot
            final now = DateTime.now();
            final mapping = SubCPMKCPMKMapping(
              subCpmkId: subCpmk.id!,
              cpmkId: matchedCpmk.id!,
              bobot: 100.0,
              createdAt: now,
              updatedAt: now,
            );
            
            await _dbHelper.insertSubCPMKCPMKMapping(mapping);

            print('[RPS Import] ✓ Mapped ${subCpmk.kodeSubCPMK} → ${matchedCpmk.kodeCPMK}');
          } else {
            print('[RPS Import] Mapping already exists: ${subCpmk.kodeSubCPMK} → ${matchedCpmk.kodeCPMK}');
          }
        } else {
          print('[RPS Import] ⚠ No matching CPMK.$subCpmkNumber found for ${subCpmk.kodeSubCPMK}');
        }
      }

      print('[RPS Import] Sub-CPMK → CPMK mapping creation completed');
    } catch (e) {
      print('[RPS Import] Error creating Sub-CPMK → CPMK mappings: $e');
      // Don't rethrow - allow import to continue even if mapping fails
    }
  }
}
