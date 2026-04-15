import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/nilai_model.dart';
import '../models/nilai_komponen_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/matakuliah_model.dart';
import '../models/cpl_master_model.dart';
import '../models/cpmk_model.dart';
import '../models/sub_cpmk_model.dart';
import '../models/rps_detail_model.dart';
import '../models/rps_detail_sub_cpmk_bobot_model.dart';
import '../models/sub_cpmk_cpmk_mapping_model.dart';
import 'database_helper.dart';

class ExcelImportService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Learning methods for validation (untuk batch RPS import)
  // ⚠️ PENULISAN HARUS EXACTLY SAMA (case-sensitive) - tidak ada variasi
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

  // Assessment types for validation (untuk batch RPS import)
  // ⚠️ PENULISAN HARUS EXACTLY SAMA (case-sensitive) - tidak ada variasi
  // Contoh: "Aktifitas Partisipatif" ✓ (bukan "aktivitas partisipatif" ✗)
  static const List<String> _validAssessmentTypes = [
    'Aktifitas Partisipatif',
    'Hasil Proyek',
    'Kuis',
    'Tugas',
  ];

  // Grade mapping dari huruf ke nilai numerik
  static const Map<String, double> _gradeNumerikMap = {
    'A': 4.0,
    'B': 3.0,
    'C': 2.0,
    'D': 1.0,
    'E': 0.0,
  };

  // Import nilai dari file CSV/Excel
  // Format Excel/CSV:
  // Kolom A: NIM
  // Kolom B: Nama Mahasiswa
  // Kolom C: Kode Matakuliah
  // Kolom D: Nama Matakuliah
  // Kolom E: Grade (A-E)
  // Kolom F: Tahun Ajaran
  Future<Map<String, dynamic>> importNilaiFromExcel(String filePath, {Uint8List? fileBytes, String? fileName}) async {
    try {
      late String content;
      
      if (fileBytes != null) {
        // For web, use bytes
        content = String.fromCharCodes(fileBytes);
      } else {
        // For desktop, use file path
        final file = File(filePath);
        content = await file.readAsString();
      }
      
      // Parse CSV
      final rows = const CsvToListConverter().convert(content);
      
      final results = <String, dynamic>{
        'success': true,
        'message': '',
        'imported': 0,
        'failed': 0,
        'errors': <String>[],
      };

      if (rows.isEmpty) {
        results['success'] = false;
        results['message'] = 'File kosong';
        return results;
      }

      final nilaiList = <Nilai>[];
      int rowNumber = 1;

      // Lewati header (baris pertama)
      final dataRows = rows.skip(1).toList();

      for (var row in dataRows) {
        rowNumber++;
        try {
          if (row.isEmpty) continue;

          // Parse kolom
          final nim = row[0]?.toString().trim() ?? '';
          final namaMahasiswa = row[1]?.toString().trim() ?? '';
          final kodeMatakuliah = row[2]?.toString().trim() ?? '';
          final namaMatakuliah = row[3]?.toString().trim() ?? '';
          final gradeStr = row[4]?.toString().toUpperCase().trim() ?? '';
          final tahunAjaranStr = row[5]?.toString().trim() ?? '';

          // Validasi data
          if (nim.isEmpty || namaMahasiswa.isEmpty) {
            results['errors']
                .add('Baris $rowNumber: NIM dan Nama Mahasiswa harus diisi');
            results['failed']++;
            continue;
          }

          if (!_gradeNumerikMap.containsKey(gradeStr)) {
            results['errors'].add(
                'Baris $rowNumber: Grade harus A, B, C, D, atau E');
            results['failed']++;
            continue;
          }

          final tahunAjaran = int.tryParse(tahunAjaranStr);
          if (tahunAjaran == null) {
            results['errors'].add(
                'Baris $rowNumber: Tahun Ajaran harus berupa angka');
            results['failed']++;
            continue;
          }

          // Cek dan tambahkan mahasiswa jika belum ada
          var mahasiswa = await _dbHelper.getMahasiswaByNim(nim);
          if (mahasiswa == null) {
            mahasiswa = Mahasiswa(
              nim: nim,
              nama: namaMahasiswa,
              tahunMasuk: tahunAjaran,
              createdAt: DateTime.now(),
            );
            final mahasiswaId = await _dbHelper.insertMahasiswa(mahasiswa);
            mahasiswa = mahasiswa.copyWith(id: mahasiswaId);
          }

          // Cek dan tambahkan matakuliah jika belum ada
          var matakuliah =
              await _dbHelper.getMatakuliahByKode(kodeMatakuliah);
          if (matakuliah == null) {
            matakuliah = Matakuliah(
              kode: kodeMatakuliah,
              nama: namaMatakuliah,
              sks: 3, // Default SKS
              semester: '1', // Default semester
              jenis: 'wajib', // Default jenis
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
            gradeHuruf: gradeStr,
            nilaiNumerik: _gradeNumerikMap[gradeStr]!,
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

      // Insert semua nilai (skip on web platform)
      if (nilaiList.isNotEmpty && !kIsWeb) {
        await _dbHelper.insertNilaiBatch(nilaiList);
      }

      if (results['failed'] == 0) {
        results['message'] =
            '${results['imported']} nilai berhasil diimport';
      } else {
        results['message'] =
            '${results['imported']} nilai berhasil, ${results['failed']} gagal';
      }

      return results;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'imported': 0,
        'failed': 0,
        'errors': [e.toString()],
      };
    }
  }

  // Import mahasiswa dari file CSV/Excel
  // Format Excel/CSV:
  // Kolom A: NIM
  // Kolom B: Nama
  // Kolom C: Tahun Masuk
  Future<Map<String, dynamic>> importMahasiswaFromExcel(String filePath, {Uint8List? fileBytes, String? fileName}) async {
    try {
      // Use the proper file reading method that handles both CSV and Excel
      final rows = await _readFileData(filePath, fileBytes: fileBytes, fileName: fileName);

      final results = <String, dynamic>{
        'success': true,
        'message': '',
        'imported': 0,
        'failed': 0,
        'errors': <String>[],
      };

      if (rows.isEmpty) {
        results['success'] = false;
        results['message'] = 'File kosong';
        return results;
      }

      final mahasiswaList = <Mahasiswa>[];
      int rowNumber = 1;

      // Lewati header
      final dataRows = rows.skip(1).toList();

      for (var row in dataRows) {
        rowNumber++;
        try {
          if (row.isEmpty) continue;

          final nim = row[0]?.toString().trim() ?? '';
          final nama = row[1]?.toString().trim() ?? '';
          final tahunMasukStr = row[2]?.toString().trim() ?? '';

          if (nim.isEmpty || nama.isEmpty) {
            results['errors']
                .add('Baris $rowNumber: NIM dan Nama harus diisi');
            results['failed']++;
            continue;
          }

          final tahunMasuk = int.tryParse(tahunMasukStr);
          if (tahunMasuk == null) {
            results['errors'].add(
                'Baris $rowNumber: Tahun Masuk harus berupa angka');
            results['failed']++;
            continue;
          }

          // Check apakah mahasiswa sudah ada (skip on web)
          if (!kIsWeb) {
            final existing = await _dbHelper.getMahasiswaByNim(nim);
            if (existing != null) {
              results['errors'].add('Baris $rowNumber: NIM $nim sudah terdaftar');
              results['failed']++;
              continue;
            }
          }

          final mahasiswa = Mahasiswa(
            nim: nim,
            nama: nama,
            tahunMasuk: tahunMasuk,
            createdAt: DateTime.now(),
          );

          mahasiswaList.add(mahasiswa);
          results['imported']++;
        } catch (e) {
          results['errors'].add('Baris $rowNumber: ${e.toString()}');
          results['failed']++;
        }
      }

      // Insert semua mahasiswa (skip on web platform)
      if (mahasiswaList.isNotEmpty && !kIsWeb) {
        await _dbHelper.insertMahasiswaBatch(mahasiswaList);
      }

      if (results['failed'] == 0) {
        results['message'] =
            '${results['imported']} mahasiswa berhasil diimport';
      } else {
        results['message'] =
            '${results['imported']} mahasiswa berhasil, ${results['failed']} gagal';
      }

      return results;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'imported': 0,
        'failed': 0,
        'errors': [e.toString()],
      };
    }
  }

  // Import matakuliah dari file CSV/Excel
  // Format Excel/CSV:
  // Kolom A: Kode Matakuliah
  // Kolom B: Nama Matakuliah
  // Kolom C: Semester
  // Kolom D: Jenis (wajib/pilihan)
  // Kolom E: SKS
  Future<Map<String, dynamic>> importMatakuliahFromExcel(String filePath, {Uint8List? fileBytes, String? fileName}) async {
    try {
      // Use the proper file reading method that handles both CSV and Excel
      final rows = await _readFileData(filePath, fileBytes: fileBytes, fileName: fileName);

      final results = <String, dynamic>{
        'success': true,
        'message': '',
        'imported': 0,
        'failed': 0,
        'errors': <String>[],
      };

      if (rows.isEmpty) {
        results['success'] = false;
        results['message'] = 'File kosong';
        return results;
      }

      final matakuliahList = <Matakuliah>[];
      int rowNumber = 1;

      // Lewati header
      final dataRows = rows.skip(1).toList();

      for (var row in dataRows) {
        rowNumber++;
        try {
          if (row.isEmpty) continue;

          final kode = row[0]?.toString().trim() ?? '';
          final nama = row[1]?.toString().trim() ?? '';
          final semester = row[2]?.toString().trim() ?? '1';
          final jenisStr = row[3]?.toString().trim().toLowerCase() ?? 'wajib';
          final sksStr = row[4]?.toString().trim() ?? '3';

          if (kode.isEmpty || nama.isEmpty) {
            results['errors']
                .add('Baris $rowNumber: Kode dan Nama Matakuliah harus diisi');
            results['failed']++;
            continue;
          }

          // Validasi jenis
          if (jenisStr != 'wajib' && jenisStr != 'pilihan') {
            results['errors'].add(
                'Baris $rowNumber: Jenis harus "wajib" atau "pilihan"');
            results['failed']++;
            continue;
          }

          final sks = int.tryParse(sksStr);
          if (sks == null || sks < 1 || sks > 6) {
            results['errors'].add(
                'Baris $rowNumber: SKS harus angka antara 1-6');
            results['failed']++;
            continue;
          }

          // Check apakah matakuliah sudah ada (skip on web)
          if (!kIsWeb) {
            final existing = await _dbHelper.getMatakuliahByKode(kode);
            if (existing != null) {
              results['errors'].add(
                  'Baris $rowNumber: Kode Matakuliah $kode sudah terdaftar');
              results['failed']++;
              continue;
            }
          }

          final matakuliah = Matakuliah(
            kode: kode,
            nama: nama,
            semester: semester,
            jenis: jenisStr,
            sks: sks,
            createdAt: DateTime.now(),
          );

          matakuliahList.add(matakuliah);
          results['imported']++;
        } catch (e) {
          results['errors'].add('Baris $rowNumber: ${e.toString()}');
          results['failed']++;
        }
      }

      // Insert semua matakuliah (skip on web platform)
      if (matakuliahList.isNotEmpty && !kIsWeb) {
        await _dbHelper.insertMatakuliahBatch(matakuliahList);
      }

      if (results['failed'] == 0) {
        results['message'] =
            '${results['imported']} matakuliah berhasil diimport';
      } else {
        results['message'] =
            '${results['imported']} matakuliah berhasil, ${results['failed']} gagal';
      }

      return results;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'imported': 0,
        'failed': 0,
        'errors': [e.toString()],
      };
    }
  }

  // Konversi nilai numerik ke grade dan nilai BK (Bobot Kredit)
  // A: 85-100 (4.0) | B: 70-84 (3.0) | C: 60-69 (2.0) | D: 50-59 (1.0) | E: <50 (0.0)
  String _nilaiToGrade(double nilai) {
    if (nilai >= 85) return 'A';
    if (nilai >= 70) return 'B';
    if (nilai >= 60) return 'C';
    if (nilai >= 50) return 'D';
    return 'E';
  }

  // Hitung nilai akhir dari komponen
  // Bobot: Aktivitas 10%, Tugas 10%, Hasil Proyek 15%, Kuis 15%, UTS 25%, UAS 25%
  double _calculateNilaiAkhir({
    required double aktivitas,
    required double tugas,
    required double hasilProyek,
    required double kuis,
    required double uts,
    required double uas,
  }) {
    return (aktivitas * 0.10) +
        (tugas * 0.10) +
        (hasilProyek * 0.15) +
        (kuis * 0.15) +
        (uts * 0.25) +
        (uas * 0.25);
  }

  // Helper method untuk membaca file CSV atau Excel
  Future<List<List<dynamic>>> _readFileData(String filePath, {Uint8List? fileBytes, String? fileName}) async {
    // Tentukan nama file untuk mengetahui extension
    String nameToCheck = fileName ?? filePath;
    
    late List<List<dynamic>> rows;
    
    if (nameToCheck.toLowerCase().endsWith('.xlsx') || 
        nameToCheck.toLowerCase().endsWith('.xls')) {
      // Baca Excel file
      late Uint8List bytes;
      if (fileBytes != null) {
        bytes = fileBytes;
      } else {
        final file = File(filePath);
        bytes = file.readAsBytesSync();
      }
      
      var excel = Excel.decodeBytes(bytes);
      
      rows = [];
      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet != null) {
          for (var row in sheet.rows) {
            List<dynamic> rowData = [];
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
      late String content;
      if (fileBytes != null) {
        content = String.fromCharCodes(fileBytes);
      } else {
        final file = File(filePath);
        content = await file.readAsString();
      }
      
      rows = const CsvToListConverter().convert(content);
      return rows;
    }
  }

  // Import nilai dari Excel dengan komponen (Aktivitas, Tugas, Kuis, UTS, UAS)
  // Format Excel/XLSX:
  // Kolom A: NIM
  // Kolom B: Nama
  // Kolom C: Kode Matakuliah
  // Kolom D: Nama Matakuliah
  // Kolom E: Nilai Aktivitas (0-100)
  // Kolom F: Nilai Tugas (0-100)
  // Kolom G: Nilai Kuis (0-100)
  // Kolom H: Nilai UTS (0-100)
  // Kolom I: Nilai UAS (0-100)
  // Kolom J: Tahun Ajaran (contoh: 2024/2025 Ganjil)
  // Kolom K: Semester
  Future<Map<String, dynamic>> importNilaiDetailFromExcel(String filePath, {String? matakuliahFilter, Uint8List? fileBytes, String? fileName}) async {
    try {
      // Baca file (support CSV dan Excel)
      final rows = await _readFileData(filePath, fileBytes: fileBytes, fileName: fileName);

      final results = <String, dynamic>{
        'success': true,
        'message': '',
        'imported': 0,
        'failed': 0,
        'errors': <String>[],
      };

      if (rows.isEmpty) {
        results['success'] = false;
        results['message'] = 'File kosong';
        return results;
      }

      // Cari header row (yang mengandung "NIM")
      int headerRowIndex = 0;
      String? tahunAjaranFromTemplate;
      String? namaMatakuliahFromTemplate;

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.isNotEmpty) {
          final firstCol = row[0]?.toString().trim().toUpperCase() ?? '';
          
          // Ambil info Tahun Ajaran dari row 2
          if (i == 2 && row.length > 1) {
            final firstColText = row[0]?.toString().trim() ?? '';
            if (firstColText.contains('Tahun Ajaran')) {
              // Row format: ['Tahun Ajaran:', 'value']
              tahunAjaranFromTemplate = row[1]?.toString().trim();
              print('DEBUG: Found tahunAjaranFromTemplate at row $i: "$tahunAjaranFromTemplate"');
            }
          }
          
          // Ambil info Nama Matakuliah dari row 1
          if (i == 1 && row.length > 1) {
            final firstColText = row[0]?.toString().trim() ?? '';
            if (firstColText.contains('Nama Matakuliah')) {
              namaMatakuliahFromTemplate = row[1]?.toString().trim();
              print('DEBUG: Found namaMatakuliahFromTemplate at row $i: "$namaMatakuliahFromTemplate"');
            }
          }
          
          // Temukan header row (kolom pertama = "NIM")
          if (firstCol == 'NIM') {
            headerRowIndex = i;
            print('DEBUG: Found header row at index $i');
            break;
          }
        }
      }

      final nilaiList = <Nilai>[];
      final nilaiKomponenList = <NilaiKomponen>[];

      // Lewati header dan baca data rows
      final dataRows = rows.skip(headerRowIndex + 1).toList();

      int rowNumber = headerRowIndex + 1;
      for (var row in dataRows) {
        rowNumber++;
        try {
          if (row.isEmpty) continue;

          // Parse kolom (struktur baru: NIM, Nama, Aktivitas, Hasil Proyek, Tugas, Kuis, UTS, UAS)
          final nim = row[0]?.toString().trim() ?? '';
          final nama = row[1]?.toString().trim() ?? '';
          final aktivitasStr = row[2]?.toString().trim() ?? '';
          final hasilProyekStr = row[3]?.toString().trim() ?? '';
          final tugasStr = row[4]?.toString().trim() ?? '';
          final kuisStr = row[5]?.toString().trim() ?? '';
          final utsStr = row[6]?.toString().trim() ?? '';
          final uasStr = row[7]?.toString().trim() ?? '';

          // Validasi data dasar
          if (nim.isEmpty || nama.isEmpty) {
            results['errors']
                .add('Baris $rowNumber: NIM dan Nama harus diisi');
            results['failed']++;
            continue;
          }

          // Validasi nilai komponen
          final aktivitas = double.tryParse(aktivitasStr);
          final hasilProyek = double.tryParse(hasilProyekStr);
          final tugas = double.tryParse(tugasStr);
          final kuis = double.tryParse(kuisStr);
          final uts = double.tryParse(utsStr);
          final uas = double.tryParse(uasStr);

          if (aktivitas == null ||
              hasilProyek == null ||
              tugas == null ||
              kuis == null ||
              uts == null ||
              uas == null) {
            results['errors'].add(
                'Baris $rowNumber: Semua nilai komponen harus berupa angka (0-100)');
            results['failed']++;
            continue;
          }

          // Validasi range nilai (0-100)
          if (aktivitas < 0 ||
              aktivitas > 100 ||
              hasilProyek < 0 ||
              hasilProyek > 100 ||
              tugas < 0 ||
              tugas > 100 ||
              kuis < 0 ||
              kuis > 100 ||
              uts < 0 ||
              uts > 100 ||
              uas < 0 ||
              uas > 100) {
            results['errors'].add(
                'Baris $rowNumber: Semua nilai harus dalam range 0-100');
            results['failed']++;
            continue;
          }

          // Hitung nilai akhir
          final nilaiAkhir = _calculateNilaiAkhir(
            aktivitas: aktivitas,
            tugas: tugas,
            hasilProyek: hasilProyek,
            kuis: kuis,
            uts: uts,
            uas: uas,
          );

          // Konversi ke grade
          final grade = _nilaiToGrade(nilaiAkhir);

          // ✅ Validasi: Cek apakah mahasiswa ada di database (NIM only)
          var mahasiswa = await _dbHelper.getMahasiswaByNim(nim);
          if (mahasiswa == null) {
            results['errors'].add(
                'Baris $rowNumber: Mahasiswa dengan NIM "$nim" tidak ditemukan di database.');
            results['failed']++;
            continue;
          }

          // Cek dan tambahkan matakuliah jika belum ada
          var matakuliah =
              await _dbHelper.getMatakuliahByKode(matakuliahFilter ?? '');
          if (matakuliah == null) {
            matakuliah = Matakuliah(
              kode: matakuliahFilter ?? '',
              nama: namaMatakuliahFromTemplate ?? 'Matakuliah',
              sks: 3, // Default SKS
              semester: '1', // Default semester kurikulum
              jenis: 'wajib', // Default jenis
              createdAt: DateTime.now(),
            );
            final matakuliahId =
                await _dbHelper.insertMatakuliah(matakuliah);
            matakuliah = matakuliah.copyWith(id: matakuliahId);
          }

          // Extract tahun ajaran sebagai integer dari template atau default
          final tahunAjaranIntForNilai = tahunAjaranFromTemplate != null
              ? int.tryParse(tahunAjaranFromTemplate.substring(0, 4)) ?? 2024
              : 2024;
          
          print('DEBUG: tahunAjaranFromTemplate = "$tahunAjaranFromTemplate", tahunAjaranIntForNilai = $tahunAjaranIntForNilai');

          // Buat nilai
          final nilai = Nilai(
            mahasiswaId: mahasiswa.id!,
            matakuliahId: matakuliah.id!,
            gradeHuruf: grade,
            nilaiNumerik: nilaiAkhir,
            tahunAjaran: tahunAjaranIntForNilai,
            createdAt: DateTime.now(),
          );

          // 📊 Buat nilai komponen (component scores)
          final nilaiKomponen = NilaiKomponen(
            mahasiswaId: mahasiswa.id!,
            matakuliahId: matakuliah.id!,
            nilaiAktivitas: aktivitas,
            nilaiProyek: hasilProyek,
            nilaiKuis: kuis,
            nilaiTugas: tugas,
            nilaiUTS: uts,
            nilaiUAS: uas,
            tahunAjaran: tahunAjaranIntForNilai,
            createdAt: DateTime.now(),
          );

          nilaiList.add(nilai);
          nilaiKomponenList.add(nilaiKomponen);
          results['imported']++;
        } catch (e) {
          results['errors'].add('Baris $rowNumber: ${e.toString()}');
          results['failed']++;
        }
      }

      // Insert semua nilai (skip on web platform)
      if (nilaiList.isNotEmpty && !kIsWeb) {
        await _dbHelper.insertNilaiBatch(nilaiList);
      }

      // 📊 Insert semua nilai komponen (skip on web platform)
      if (nilaiKomponenList.isNotEmpty && !kIsWeb) {
        for (final nk in nilaiKomponenList) {
          await _dbHelper.insertNilaiKomponen(
            mahasiswaId: nk.mahasiswaId,
            matakuliahId: nk.matakuliahId,
            nilaiAktivitas: nk.nilaiAktivitas,
            nilaiProyek: nk.nilaiProyek,
            nilaiKuis: nk.nilaiKuis,
            nilaiTugas: nk.nilaiTugas,
            nilaiUTS: nk.nilaiUTS,
            nilaiUAS: nk.nilaiUAS,
            tahunAjaran: nk.tahunAjaran,
          );
        }
      }

      if (results['failed'] == 0) {
        results['message'] =
            '${results['imported']} nilai berhasil diimport';
      } else {
        results['message'] =
            '${results['imported']} nilai berhasil, ${results['failed']} gagal';
      }

      return results;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'imported': 0,
        'failed': 0,
        'errors': [e.toString()],
      };
    }
  }

  // Import CPL dari file Excel/CSV
  // Format Excel/CSV:
  // Kolom A: Nomor CPL (1-7)
  // Kolom B: Deskripsi CPL
  Future<Map<String, dynamic>> importCPLFromExcel(String filePath, {Uint8List? fileBytes, String? fileName}) async {
    try {
      final rows = await _readFileData(filePath, fileBytes: fileBytes, fileName: fileName);

      final results = <String, dynamic>{
        'success': true,
        'message': '',
        'imported': 0,
        'failed': 0,
        'errors': <String>[],
      };

      if (rows.isEmpty) {
        results['success'] = false;
        results['message'] = 'File kosong';
        return results;
      }

      final cplList = <CPLMaster>[];
      int rowNumber = 1;

      // Lewati header (baris pertama)
      final dataRows = rows.skip(1).toList();

      for (var row in dataRows) {
        rowNumber++;
        try {
          if (row.isEmpty) continue;

          // Parse kolom
          final nomorStr = row[0]?.toString().trim() ?? '';
          final deskripsi = row[1]?.toString().trim() ?? '';

          // Validasi data
          if (nomorStr.isEmpty || deskripsi.isEmpty) {
            results['errors']
                .add('Baris $rowNumber: Nomor CPL dan Deskripsi harus diisi');
            results['failed']++;
            continue;
          }

          // Validasi nomor CPL (1-7)
          final nomorInt = int.tryParse(nomorStr);
          if (nomorInt == null || nomorInt < 1 || nomorInt > 7) {
            results['errors']
                .add('Baris $rowNumber: Nomor CPL harus antara 1-7');
            results['failed']++;
            continue;
          }

          // Buat CPL Master
          final cpl = CPLMaster(
            kodeCPL: 'CPL.$nomorStr',
            deskripsi: deskripsi,
            nomor: nomorStr,
            createdAt: DateTime.now(),
          );

          cplList.add(cpl);
          results['imported']++;
        } catch (e) {
          results['errors'].add('Baris $rowNumber: ${e.toString()}');
          results['failed']++;
        }
      }

      // Insert semua CPL (skip on web platform)
      if (cplList.isNotEmpty && !kIsWeb) {
        for (var cpl in cplList) {
          await _dbHelper.insertCPLMaster(cpl);
        }
      }

      if (results['failed'] == 0) {
        results['message'] =
            '${results['imported']} CPL berhasil diimport';
      } else {
        results['message'] =
            '${results['imported']} CPL berhasil, ${results['failed']} gagal';
      }

      return results;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'imported': 0,
        'failed': 0,
        'errors': [e.toString()],
      };
    }
  }

  // Import CPMK dari file Excel/CSV
  // Format Excel/CSV (sama dengan Sub CPMK Batch):
  // Row 1: Nama Mata Kuliah info
  // Row 2: Kode Mata Kuliah info
  // Row 3: (empty)
  // Row 4: Kolom A: Nomor CPMK, Kolom B: Deskripsi CPMK
  // Row 5+: Data
  Future<Map<String, dynamic>> importCPMKFromExcel(String filePath, {Uint8List? fileBytes, String? fileName}) async {
    try {
      final rows = await _readFileData(filePath, fileBytes: fileBytes, fileName: fileName);

      final results = <String, dynamic>{
        'success': true,
        'message': '',
        'imported': 0,
        'failed': 0,
        'errors': <String>[],
      };

      if (rows.isEmpty) {
        results['success'] = false;
        results['message'] = 'File kosong';
        return results;
      }

      final cpmkList = <CPMK>[];
      int rowNumber = 1;

      // Skip header rows (baris 1-4: info mata kuliah, info kode, empty, dan column headers)
      // Find the column header row by looking for "Nomor CPMK" in the first column
      int dataStartRow = 4; // Default: start dari row 5 (index 4)
      
      for (int i = 0; i < rows.length && i < 10; i++) {
        if (rows[i].isNotEmpty) {
          final firstCol = rows[i][0]?.toString().trim() ?? '';
          if (firstCol == 'Nomor CPMK') {
            dataStartRow = i + 1; // Data starts from next row
            break;
          }
        }
      }

      final dataRows = rows.skip(dataStartRow).toList();

      for (var row in dataRows) {
        rowNumber = dataStartRow + (dataRows.indexOf(row)) + 1;
        try {
          if (row.isEmpty) continue;

          // Parse kolom
          final nomorStr = row[0]?.toString().trim() ?? '';
          final deskripsi = row[1]?.toString().trim() ?? '';

          // Validasi data
          if (nomorStr.isEmpty || deskripsi.isEmpty) {
            results['errors']
                .add('Baris $rowNumber: Nomor CPMK dan Deskripsi harus diisi');
            results['failed']++;
            continue;
          }

          // Validasi nomor CPMK (harus angka)
          final nomorInt = int.tryParse(nomorStr);
          if (nomorInt == null || nomorInt < 1) {
            results['errors']
                .add('Baris $rowNumber: Nomor CPMK harus berupa angka positif');
            results['failed']++;
            continue;
          }

          // Buat CPMK (untuk program studi, matakuliahId = 0)
          final cpmk = CPMK(
            kodeCPMK: 'CPMK.$nomorStr',
            deskripsi: deskripsi,
            matakuliahId: 0, // 0 = CPMK Program Studi
            createdAt: DateTime.now(),
          );

          cpmkList.add(cpmk);
          results['imported']++;
        } catch (e) {
          results['errors'].add('Baris $rowNumber: ${e.toString()}');
          results['failed']++;
        }
      }

      // Insert semua CPMK (skip on web platform) dengan error handling
      if (cpmkList.isNotEmpty && !kIsWeb) {
        int insertedCount = 0;
        for (var cpmk in cpmkList) {
          try {
            await _dbHelper.insertCPMK(cpmk);
            insertedCount++;
          } catch (e) {
            // Handle constraint error
            final errorMsg = e.toString();
            if (errorMsg.contains('UNIQUE constraint failed') || 
                errorMsg.contains('constraint failed')) {
              results['errors'].add('${cpmk.kodeCPMK}: Sudah ada di database (duplikat)');
            } else {
              results['errors'].add('${cpmk.kodeCPMK}: ${e.toString()}');
            }
            results['failed']++;
          }
        }
        results['imported'] = insertedCount;
      }

      if (results['failed'] == 0) {
        results['message'] =
            '${results['imported']} CPMK berhasil diimport';
      } else {
        results['message'] =
            '${results['imported']} CPMK berhasil, ${results['failed']} gagal';
      }

      return results;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'imported': 0,
        'failed': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Import Sub CPMK dari file Excel/CSV
  /// Kolom A: Kode Sub CPMK (format: SUB-CPMK.1, SUB-CPMK.2, dll)
  /// Kolom B: Deskripsi Sub CPMK
  Future<Map<String, dynamic>> importSubCPMKFromExcel(
    String filePath,
    int matakuliahId, {
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final rows = await _readFileData(filePath, fileBytes: fileBytes, fileName: fileName);

      final results = <String, dynamic>{
        'success': true,
        'message': '',
        'imported': 0,
        'failed': 0,
        'errors': <String>[],
      };

      if (rows.isEmpty) {
        results['success'] = false;
        results['message'] = 'File kosong';
        return results;
      }

      final subCpmkList = <SubCPMK>[];
      int rowNumber = 1;

      // Lewati header (baris pertama) dan info (baris kedua jika ada)
      final dataRows = rows.skip(_getFirstDataRowIndex(rows)).toList();

      for (var row in dataRows) {
        rowNumber++;
        try {
          if (row.isEmpty) continue;

          // Parse kolom
          final kodeSubCpmk = row[0]?.toString().trim() ?? '';
          final deskripsi = row[1]?.toString().trim() ?? '';

          // Validasi data
          if (kodeSubCpmk.isEmpty || deskripsi.isEmpty) {
            results['errors']
                .add('Baris $rowNumber: Kode Sub CPMK dan Deskripsi harus diisi');
            results['failed']++;
            continue;
          }

          // Buat Sub CPMK
          final subCpmk = SubCPMK(
            matakuliahId: matakuliahId,
            kodeSubCPMK: kodeSubCpmk,
            deskripsi: deskripsi,
            createdAt: DateTime.now(),
          );

          subCpmkList.add(subCpmk);
          results['imported']++;
        } catch (e) {
          results['errors'].add('Baris $rowNumber: ${e.toString()}');
          results['failed']++;
        }
      }

      // Insert semua Sub CPMK (skip on web platform) dengan error handling
      if (subCpmkList.isNotEmpty && !kIsWeb) {
        int insertedCount = 0;
        for (var subCpmk in subCpmkList) {
          try {
            await _dbHelper.insertSubCPMK(subCpmk);
            insertedCount++;
          } catch (e) {
            // Handle constraint error
            final errorMsg = e.toString();
            if (errorMsg.contains('UNIQUE constraint failed') || 
                errorMsg.contains('constraint failed')) {
              results['errors'].add('${subCpmk.kodeSubCPMK}: Sudah ada di database (duplikat)');
            } else {
              results['errors'].add('${subCpmk.kodeSubCPMK}: ${e.toString()}');
            }
            results['failed']++;
          }
        }
        results['imported'] = insertedCount;
      }

      if (results['failed'] == 0) {
        results['message'] =
            '${results['imported']} Sub CPMK berhasil diimport';
      } else {
        results['message'] =
            '${results['imported']} Sub CPMK berhasil, ${results['failed']} gagal';
      }

      return results;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'imported': 0,
        'failed': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// Import Sub CPMK dari multiple files
  /// Setiap file harus memiliki kode matakuliah di sel B2 (untuk validasi)
  /// Format: Row 1 = Nama Mata Kuliah, Row 2 = Kode Mata Kuliah, Row 4 = Column Headers, Row 5+ = Data
  Future<Map<String, dynamic>> importSubCPMKBatchMultipleFiles(
    List<String> filePaths,
  ) async {
    try {
      final overallResults = <String, dynamic>{
        'success': true,
        'message': '',
        'totalImported': 0,
        'totalFailed': 0,
        'fileResults': <Map<String, dynamic>>[],
        'errors': <String>[],
      };

      // Proses setiap file
      for (final filePath in filePaths) {
        try {
          final rows = await _readFileData(filePath);
          
          if (rows.isEmpty) {
            overallResults['fileResults'].add({
              'fileName': filePath.split('/').last,
              'success': false,
              'message': 'File kosong',
              'matakuliah': null,
              'imported': 0,
            });
            overallResults['totalFailed']++;
            continue;
          }

          // Extract kode matakuliah dari B2 (row 1, column 1) untuk validasi
          String? kodeMatakuliah;
          if (rows.length > 1 && rows[1].length > 1) {
            kodeMatakuliah = rows[1][1]?.toString().trim();
          }

          if (kodeMatakuliah == null || kodeMatakuliah.isEmpty) {
            overallResults['fileResults'].add({
              'fileName': filePath.split('/').last,
              'success': false,
              'message': 'Kode Matakuliah tidak ditemukan di sel B2',
              'matakuliah': null,
              'imported': 0,
            });
            overallResults['totalFailed']++;
            continue;
          }

          // Cari matakuliah berdasarkan KODE (bukan nama)
          final matakuliah = await _dbHelper.getMatakuliahByKode(kodeMatakuliah);
          
          if (matakuliah == null) {
            overallResults['fileResults'].add({
              'fileName': filePath.split('/').last,
              'success': false,
              'message': 'Matakuliah dengan kode "$kodeMatakuliah" tidak ditemukan di database',
              'matakuliah': kodeMatakuliah,
              'imported': 0,
            });
            overallResults['totalFailed']++;
            continue;
          }

          // Import Sub CPMK untuk matakuliah ini
          final subCpmkList = <SubCPMK>[];
          
          // Detect data start row - cari kolom header "Kode Sub CPMK"
          int dataStartRow = 4; // Default
          for (int i = 0; i < rows.length && i < 10; i++) {
            if (rows[i].isNotEmpty) {
              final firstCol = rows[i][0]?.toString().trim() ?? '';
              if (firstCol.toLowerCase().contains('kode') && firstCol.toLowerCase().contains('sub')) {
                dataStartRow = i + 1; // Data starts after header
                break;
              }
            }
          }
          
          for (int i = dataStartRow; i < rows.length; i++) {
            final row = rows[i];
            if (row.isEmpty || row[0] == null) continue;

            try {
              final kodeSubCpmk = row[0]?.toString().trim() ?? '';
              final deskripsi = row[1]?.toString().trim() ?? '';

              // Validasi: kode sub CPMK harus bukan kosong dan harus mengandung "SUB-CPMK"
              if (kodeSubCpmk.isEmpty || deskripsi.isEmpty) {
                continue;
              }
              
              // Skip jika kodeSubCpmk tidak dalam format yang benar (harus mengandung "SUB-CPMK" atau angka)
              if (!kodeSubCpmk.toUpperCase().contains('SUB-CPMK') && 
                  !kodeSubCpmk.toUpperCase().contains('SUB') &&
                  int.tryParse(kodeSubCpmk) != null) {
                // Jika hanya angka, skip (kemungkinan bukan data Sub CPMK)
                continue;
              }

              final subCpmk = SubCPMK(
                matakuliahId: matakuliah.id!,
                kodeSubCPMK: kodeSubCpmk,
                deskripsi: deskripsi,
                createdAt: DateTime.now(),
              );

              subCpmkList.add(subCpmk);
            } catch (e) {
              // Skip row yang error
              continue;
            }
          }

          // Simpan semua Sub CPMK dengan error handling per item
          int successCount = 0;
          List<String> insertErrors = [];
          
          if (subCpmkList.isNotEmpty) {
            for (var subCpmk in subCpmkList) {
              try {
                await _dbHelper.insertSubCPMK(subCpmk);
                successCount++;
              } catch (e) {
                // Handle constraint error - check jika sudah ada data yang sama
                final errorMsg = e.toString();
                if (errorMsg.contains('UNIQUE constraint failed') || 
                    errorMsg.contains('constraint failed')) {
                  insertErrors.add('${subCpmk.kodeSubCPMK}: Sudah ada di database');
                } else {
                  insertErrors.add('${subCpmk.kodeSubCPMK}: ${e.toString()}');
                }
              }
            }
          }

          final errorMsg = insertErrors.isNotEmpty ? '\nError: ${insertErrors.join(', ')}' : '';
          overallResults['fileResults'].add({
            'fileName': filePath.split('/').last,
            'success': successCount > 0,
            'message': '$successCount Sub CPMK berhasil diimport${insertErrors.isNotEmpty ? ' (${insertErrors.length} duplikat/error)$errorMsg' : ''}',
            'matakuliah': kodeMatakuliah,
            'imported': successCount,
          });

          overallResults['totalImported'] += successCount;
        } catch (e) {
          overallResults['fileResults'].add({
            'fileName': filePath.split('/').last,
            'success': false,
            'message': 'Error: ${e.toString()}',
            'matakuliah': null,
            'imported': 0,
          });
          overallResults['totalFailed']++;
        }
      }

      // Set pesan ringkasan
      if (overallResults['totalFailed'] == 0) {
        overallResults['message'] =
            '✓ ${overallResults['totalImported']} Sub CPMK berhasil diimport dari ${filePaths.length} file';
      } else {
        overallResults['message'] =
            '${overallResults['totalImported']} Sub CPMK berhasil, ${overallResults['totalFailed']} file gagal diproses';
        if (overallResults['totalImported'] == 0) {
          overallResults['success'] = false;
        }
      }

      return overallResults;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'totalImported': 0,
        'totalFailed': 0,
        'fileResults': [],
        'errors': [e.toString()],
      };
    }
  }

  /// Import RPS dari multiple files
  /// Setiap file harus memiliki kode matakuliah di sel B2
  /// Format: Row 1 = Header (Nama Mata Kuliah), Row 2 = Kode Matakuliah, Row 4 = Column Headers, Row 5+ = Data
  Future<Map<String, dynamic>> importRPSBatchMultipleFiles(
    List<String> filePaths,
  ) async {
    try {
      final overallResults = <String, dynamic>{
        'success': true,
        'message': '',
        'totalImported': 0,
        'totalFailed': 0,
        'fileResults': <Map<String, dynamic>>[],
        'errors': <String>[],
      };

      // Proses setiap file
      for (final filePath in filePaths) {
        try {
          final rows = await _readFileData(filePath);
          final fileName = filePath.split('/').last;
          
          if (rows.isEmpty) {
            overallResults['fileResults'].add({
              'fileName': fileName,
              'success': false,
              'message': 'File kosong',
              'matakuliah': null,
              'imported': 0,
            });
            overallResults['totalFailed']++;
            continue;
          }

          // Extract kode matakuliah dari B2 (row 1, column 1)
          String? kodeMatakuliah;
          if (rows.length > 1 && rows[1].length > 1) {
            kodeMatakuliah = rows[1][1]?.toString().trim();
          }

          if (kodeMatakuliah == null || kodeMatakuliah.isEmpty) {
            overallResults['fileResults'].add({
              'fileName': fileName,
              'success': false,
              'message': 'Kode Matakuliah tidak ditemukan di sel B2',
              'matakuliah': null,
              'imported': 0,
            });
            overallResults['totalFailed']++;
            continue;
          }

          // Cari matakuliah yang sesuai dari database
          final matakuliah = await _dbHelper.getMatakuliahByKode(kodeMatakuliah);
          
          if (matakuliah == null) {
            overallResults['fileResults'].add({
              'fileName': fileName,
              'success': false,
              'message': 'Matakuliah dengan kode "$kodeMatakuliah" tidak ditemukan di database',
              'matakuliah': kodeMatakuliah,
              'imported': 0,
            });
            overallResults['totalFailed']++;
            continue;
          }

          // Validasi terlebih dahulu sebelum import
          final validationErrors = <String>[];
          final rpsDataList = <RPSDetail>[];

          // Data mulai dari row 4 (index 4) - row 5 di Excel
          final dataStartRow = 4;
          int excelLineNumber = dataStartRow + 1; // Untuk display yang sesuai dengan Excel
          
          for (int i = dataStartRow; i < rows.length; i++) {
            final row = rows[i];
            if (row.isEmpty || row[0] == null) {
              excelLineNumber++;
              continue;
            }

            try {
              // Kolom sesuai header: Kode MK, Nama MK, Minggu Ke, Topik, Metode, Bobot, CPMK, Sub CPMK, CPL, Jenis Penilaian
              final mingguKeStr = row[2]?.toString().trim() ?? '';
              final topik = row[3]?.toString().trim() ?? '';
              final metodeAjar = row[4]?.toString().trim() ?? '';
              final bobotStr = row[5]?.toString().trim() ?? '';
              final kodesCPMK = row[6]?.toString().trim() ?? '';
              final kodesSubCPMK = row[7]?.toString().trim() ?? '';
              final kodesCPL = row[8]?.toString().trim() ?? '';
              final jenisNilaiStr = row[9]?.toString().trim() ?? '';

              if (mingguKeStr.isEmpty || topik.isEmpty) {
                excelLineNumber++;
                continue;
              }

              // Validasi minggu
              final mingguKe = int.tryParse(mingguKeStr);
              if (mingguKe == null || mingguKe < 1 || mingguKe > 16) {
                validationErrors.add(
                    'Baris $excelLineNumber: Minggu Ke harus berupa angka antara 1-16 (nilai: "$mingguKeStr")');
                excelLineNumber++;
                continue;
              }

              // Check if UTS/UAS
              final isUTSorUAS = mingguKe == 8 || mingguKe == 16;

              // Validasi metode ajar - HARUS diisi KECUALI untuk minggu 8 (UTS) dan 16 (UAS)
              if (!isUTSorUAS && (metodeAjar.isEmpty || metodeAjar == '-')) {
                validationErrors.add(
                    'Baris $excelLineNumber (Minggu $mingguKe): Metode pembelajaran HARUS diisi');
                excelLineNumber++;
                continue;
              }

              if (metodeAjar.isNotEmpty && metodeAjar != '-' && !_validLearningMethods.contains(metodeAjar)) {
                validationErrors.add(
                    'Baris $excelLineNumber (Minggu $mingguKe): Metode "$metodeAjar" tidak valid.\n'
                    '✓ Gunakan: ${_validLearningMethods.join(", ")}');
                excelLineNumber++;
                continue;
              }

              // Validasi Jenis Penilaian - HARUS diisi KECUALI untuk minggu 8 (UTS) dan 16 (UAS)
              if (!isUTSorUAS && (jenisNilaiStr.isEmpty || jenisNilaiStr == '-')) {
                validationErrors.add(
                    'Baris $excelLineNumber (Minggu $mingguKe): Jenis Penilaian HARUS diisi');
                excelLineNumber++;
                continue;
              }

              if (jenisNilaiStr.isNotEmpty && jenisNilaiStr != '-' && !_validAssessmentTypes.contains(jenisNilaiStr)) {
                validationErrors.add(
                    'Baris $excelLineNumber (Minggu $mingguKe): Penilaian "$jenisNilaiStr" tidak valid.\n'
                    '✓ Gunakan: ${_validAssessmentTypes.join(", ")}');
                excelLineNumber++;
                continue;
              }

              // Validasi bobot (optional)
              double? bobot;
              if (bobotStr.isNotEmpty) {
                bobot = double.tryParse(bobotStr);
                if (bobot == null || bobot < 0 || bobot > 100) {
                  validationErrors.add(
                      'Baris $excelLineNumber (Minggu $mingguKe): Bobot harus angka 0-100');
                  excelLineNumber++;
                  continue;
                }
              } else {
                bobot = 0;
              }

              // Parse CPMK codes (optional)
              List<int>? cpmkIds;
              if (kodesCPMK.isNotEmpty) {
                cpmkIds = [];
                final cpmkCodes = kodesCPMK.split(';').map((c) => c.trim()).toList();
                for (var code in cpmkCodes) {
                  if (code.isEmpty) continue;
                  var cpmk = await _dbHelper.getCPMKByKode(code);
                  if (cpmk == null) {
                    // Auto-create CPMK if not found
                    cpmk = CPMK(
                      kodeCPMK: code,
                      deskripsi: 'Auto-created dari RPS import: $code',
                      matakuliahId: 0, // program-level CPMK
                      createdAt: DateTime.now(),
                    );
                    final createdId = await _dbHelper.insertCPMK(cpmk);
                    cpmkIds.add(createdId);
                  } else {
                    cpmkIds.add(cpmk.id!);
                  }
                }
                if (cpmkIds.isEmpty) cpmkIds = null;
              }

              // Parse Sub CPMK codes (optional)
              List<int>? subCpmkIds;
              if (kodesSubCPMK.isNotEmpty) {
                subCpmkIds = [];
                final subCpmkCodes = kodesSubCPMK.split(';').map((c) => c.trim()).toList();
                for (var code in subCpmkCodes) {
                  if (code.isEmpty) continue;
                  final allSubCpmks = await _dbHelper.getSubCPMKByMatakuliah(matakuliah.id!);
                  SubCPMK? foundSubCpmk;
                  try {
                    foundSubCpmk = allSubCpmks.firstWhere(
                      (sc) => sc.kodeSubCPMK == code,
                    );
                  } catch (e) {
                    // Auto-create Sub CPMK if not found
                    foundSubCpmk = SubCPMK(
                      matakuliahId: matakuliah.id!,
                      kodeSubCPMK: code,
                      deskripsi: 'Auto-created dari RPS import: $code',
                      createdAt: DateTime.now(),
                    );
                    final createdId = await _dbHelper.insertSubCPMK(foundSubCpmk);
                    foundSubCpmk = foundSubCpmk.copyWith(id: createdId);
                  }
                  subCpmkIds.add(foundSubCpmk.id!);
                }
                if (subCpmkIds.isEmpty) subCpmkIds = null;
              }

              // Parse CPL codes (optional)
              List<int>? cplIds;
              if (kodesCPL.isNotEmpty) {
                cplIds = [];
                try {
                  final codeList = kodesCPL.split(';').map((c) => c.trim()).toList();
                  final allCPLs = await _dbHelper.getAllCPLMaster();
                  for (var code in codeList) {
                    if (code.isEmpty) continue;
                    try {
                      final cpl = allCPLs.firstWhere(
                        (c) => c.kodeCPL == code,
                      );
                      cplIds.add(cpl.id!);
                    } catch (e) {
                      // CPL code not found, skip
                    }
                  }
                  if (cplIds.isEmpty) cplIds = null;
                } catch (e) {
                  // Error parsing CPL codes, skip
                }
              }

              // Prepare RPS data
              final jenisNilai = jenisNilaiStr.isEmpty || jenisNilaiStr == '-' ? null : jenisNilaiStr;
              final finalMetodeAjar = (metodeAjar.isEmpty || metodeAjar == '-') ? '' : metodeAjar;

              final rpsDetail = RPSDetail(
                matakuliahId: matakuliah.id!,
                mingguKe: mingguKe,
                topik: topik,
                metodeAjar: finalMetodeAjar,
                bobot: bobot,
                cpmkIds: cpmkIds,
                subCpmkIds: subCpmkIds,
                cplIds: cplIds,
                jenisNilai: jenisNilai,
                createdAt: DateTime.now(),
              );

              rpsDataList.add(rpsDetail);
            } catch (e) {
              validationErrors.add('Baris $excelLineNumber: Error parsing - ${e.toString()}');
            }
            excelLineNumber++;
          }

          // Jika ada validation errors, jangan import
          if (validationErrors.isNotEmpty) {
            final errorMsg = '${validationErrors.length} baris memiliki error:\n' +
                validationErrors.take(5).join('\n') +
                (validationErrors.length > 5 ? '\n... dan ${validationErrors.length - 5} error lainnya' : '');
            
            overallResults['fileResults'].add({
              'fileName': fileName,
              'success': false,
              'message': 'Import GAGAL: $errorMsg',
              'matakuliah': matakuliah.nama,
              'imported': 0,
              'errors': validationErrors,
            });
            overallResults['totalFailed']++;
            overallResults['errors'].addAll(validationErrors);
            continue;
          }

          // Validasi passed, now import
          // Hapus RPS lama untuk matakuliah ini sebelum import data baru
          await _dbHelper.deleteRPSDetailByMatakuliah(matakuliah.id!);

          int importCount = 0;
          for (var rpsDetail in rpsDataList) {
            try {
              final rpsDetailId = await _dbHelper.insertRPSDetail(rpsDetail);

              // Jika ada Sub CPMK, simpan mapping
              if (rpsDetail.subCpmkIds != null && rpsDetail.subCpmkIds!.isNotEmpty && rpsDetail.bobot != null) {
                for (var subCpmkId in rpsDetail.subCpmkIds!) {
                  try {
                    final rpsBobotSubCpmk = RPSDetailSubCPMKBobot(
                      rpsDetailId: rpsDetailId,
                      subCpmkId: subCpmkId,
                      bobot: rpsDetail.bobot!,
                      createdAt: DateTime.now(),
                    );
                    await _dbHelper.insertRPSDetailSubCPMKBobot(rpsBobotSubCpmk);
                  } catch (e) {
                    // Skip jika gagal insert mapping
                  }
                }
              }

              importCount++;
            } catch (e) {
              // Skip row yang error saat insert
              continue;
            }
          }

          // Auto-create Sub-CPMK → CPMK mapping
          await _createSubCPMKtoCPMKMappings(matakuliah.id!);

          overallResults['fileResults'].add({
            'fileName': fileName,
            'success': true,
            'message': '✓ $importCount RPS berhasil diimport',
            'matakuliah': matakuliah.nama,
            'imported': importCount,
          });

          overallResults['totalImported'] += importCount;
        } catch (e) {
          overallResults['fileResults'].add({
            'fileName': filePath.split('/').last,
            'success': false,
            'message': 'Error: ${e.toString()}',
            'matakuliah': null,
            'imported': 0,
          });
          overallResults['totalFailed']++;
        }
      }

      // Set pesan ringkasan
      if (overallResults['totalFailed'] == 0) {
        overallResults['message'] =
            '✓ ${overallResults['totalImported']} RPS berhasil diimport dari ${filePaths.length} file';
      } else {
        overallResults['message'] =
            '${overallResults['totalImported']} RPS berhasil, ${overallResults['totalFailed']} file gagal diproses';
        if (overallResults['totalImported'] == 0) {
          overallResults['success'] = false;
        }
      }

      return overallResults;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'totalImported': 0,
        'totalFailed': 0,
        'fileResults': [],
        'errors': [e.toString()],
      };
    }
  }

  /// Helper method untuk mencari baris pertama data (skip header dan info)
  int _getFirstDataRowIndex(List<List<dynamic>> rows) {
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isNotEmpty && row[0] != null) {
        final firstCell = row[0].toString().trim().toLowerCase();
        // Skip jika ini header row (contains ':' atau adalah nama kolom tertentu)
        if (firstCell.isNotEmpty && 
            (!firstCell.contains(':') && 
             !firstCell.contains('kode') && 
             !firstCell.contains('nama') &&
             !firstCell.contains('nim'))) {
          return i;
        }
      }
    }
    return 1; // Default skip baris pertama
  }

  // Validasi format file
  List<String> validateExcelFormat(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return ['File tidak ditemukan'];
      }

      // Check file extension
      if (!filePath.endsWith('.csv') && !filePath.endsWith('.xlsx')) {
        return ['File harus berformat .csv atau .xlsx'];
      }

      return [];
    } catch (e) {
      return ['Error validasi: ${e.toString()}'];
    }
  }

  /// Helper method untuk auto-create Sub-CPMK → CPMK mapping
  /// 🔧 IMPROVED: Baca mapping dari RPS data yang sudah di-import, bukan guess berdasarkan nomor
  Future<void> _createSubCPMKtoCPMKMappings(int matakuliahId) async {
    try {
      // Get all RPS details yang sudah di-import (ini punya Sub-CPMK IDs dan CPMK codes)
      final rpsDetails = await _dbHelper.getRPSDetailByMatakuliah(matakuliahId);
      
      if (rpsDetails.isEmpty) {
        print('[RPS Batch Import] No RPS details found for matakuliah $matakuliahId - skipping mapping');
        return;
      }

      // Get all CPMK untuk lookup
      final cpmkList = await _dbHelper.getAllCPMK();
      final cpmkMap = <String, CPMK>{};
      for (final cpmk in cpmkList) {
        cpmkMap[cpmk.kodeCPMK.trim().toUpperCase()] = cpmk;
      }

      print('[RPS Batch Import] Creating Sub-CPMK → CPMK mappings dari RPS data');

      // Build mapping dari RPS data: collect Sub-CPMK ↔ CPMK pairs
      final mappingsToCreate = <({int subCpmkId, int cpmkId})>{};
      
      for (final rps in rpsDetails) {
        // Get CPMK code dari first CPMK dalam RPS (semua minggu biasanya ke CPMK yang sama)
        if (rps.cpmkIds == null || rps.cpmkIds!.isEmpty) {
          print('   ⚠️ RPS minggu ${rps.mingguKe} tidak punya CPMK code');
          continue;
        }

        // Get Sub-CPMK IDs dari RPS
        if (rps.subCpmkIds == null || rps.subCpmkIds!.isEmpty) {
          print('   ⚠️ RPS minggu ${rps.mingguKe} tidak punya Sub-CPMK');
          continue;
        }

        // Use first CPMK ID (assuming one CPMK per course)
        final cpmkId = rps.cpmkIds!.first;
        
        // Create mapping untuk setiap Sub-CPMK di RPS ini
        for (final subCpmkId in rps.subCpmkIds!) {
          mappingsToCreate.add((subCpmkId: subCpmkId, cpmkId: cpmkId));
        }
      }

      if (mappingsToCreate.isEmpty) {
        print('[RPS Batch Import] ⚠️ No Sub-CPMK ↔ CPMK pairs found in RPS data');
        return;
      }

      print('[RPS Batch Import] Found ${mappingsToCreate.length} Sub-CPMK → CPMK mapping(s) to create');

      // Create mappings
      int created = 0;
      int skipped = 0;
      
      for (final pair in mappingsToCreate) {
        try {
          // Check if mapping already exists
          final existingMapping = await _dbHelper.getSubCPMKCPMKMappingSingle(
            pair.subCpmkId,
            pair.cpmkId,
          );

          if (existingMapping == null) {
            final now = DateTime.now();
            final mapping = SubCPMKCPMKMapping(
              subCpmkId: pair.subCpmkId,
              cpmkId: pair.cpmkId,
              bobot: 100.0,
              createdAt: now,
              updatedAt: now,
            );
            
            await _dbHelper.insertSubCPMKCPMKMapping(mapping);
            created++;
            print('[RPS Batch Import]   ✓ Created Sub-CPMK.$pair.subCpmkId → CPMK.$pair.cpmkId');
          } else {
            skipped++;
          }
        } catch (e) {
          print('[RPS Batch Import]   ❌ Error creating mapping Sub-CPMK.${pair.subCpmkId} → CPMK.${pair.cpmkId}: $e');
        }
      }

      print('[RPS Batch Import] Sub-CPMK → CPMK mapping completed: $created created, $skipped already exist');
    } catch (e) {
      print('[RPS Batch Import] Error creating Sub-CPMK → CPMK mappings: $e');
      // Don't rethrow - allow import to continue even if mapping fails
    }
  }
}

