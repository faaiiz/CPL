import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/nilai_model.dart';
import '../models/nilai_komponen_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/matakuliah_model.dart';
import '../models/cpl_master_model.dart';
import '../models/cpmk_model.dart';
import '../models/sub_cpmk_model.dart';
import 'database_helper.dart';

class ExcelImportService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

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
  Future<Map<String, dynamic>> importNilaiFromExcel(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      
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

      // Insert semua nilai
      if (nilaiList.isNotEmpty) {
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
  Future<Map<String, dynamic>> importMahasiswaFromExcel(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      
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

          // Check apakah mahasiswa sudah ada
          final existing = await _dbHelper.getMahasiswaByNim(nim);
          if (existing != null) {
            results['errors'].add('Baris $rowNumber: NIM $nim sudah terdaftar');
            results['failed']++;
            continue;
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

      // Insert semua mahasiswa
      if (mahasiswaList.isNotEmpty) {
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
  Future<Map<String, dynamic>> importMatakuliahFromExcel(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      
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

          // Check apakah matakuliah sudah ada
          final existing = await _dbHelper.getMatakuliahByKode(kode);
          if (existing != null) {
            results['errors'].add(
                'Baris $rowNumber: Kode Matakuliah $kode sudah terdaftar');
            results['failed']++;
            continue;
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

      // Insert semua matakuliah
      if (matakuliahList.isNotEmpty) {
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
  Future<List<List<dynamic>>> _readFileData(String filePath) async {
    final file = File(filePath);
    
    if (filePath.toLowerCase().endsWith('.xlsx') || 
        filePath.toLowerCase().endsWith('.xls')) {
      // Baca Excel file
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      
      List<List<dynamic>> rows = [];
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
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);
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
  Future<Map<String, dynamic>> importNilaiDetailFromExcel(String filePath, {String? matakuliahFilter}) async {
    try {
      // Baca file (support CSV dan Excel)
      final rows = await _readFileData(filePath);

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

      // Insert semua nilai
      if (nilaiList.isNotEmpty) {
        await _dbHelper.insertNilaiBatch(nilaiList);
      }

      // 📊 Insert semua nilai komponen
      if (nilaiKomponenList.isNotEmpty) {
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
  Future<Map<String, dynamic>> importCPLFromExcel(String filePath) async {
    try {
      final rows = await _readFileData(filePath);

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

      // Insert semua CPL
      if (cplList.isNotEmpty) {
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
  // Format Excel/CSV:
  // Kolom A: Nomor CPMK
  // Kolom B: Deskripsi CPMK
  Future<Map<String, dynamic>> importCPMKFromExcel(String filePath) async {
    try {
      final rows = await _readFileData(filePath);

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

      // Insert semua CPMK
      if (cpmkList.isNotEmpty) {
        for (var cpmk in cpmkList) {
          await _dbHelper.insertCPMK(cpmk);
        }
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
    int matakuliahId,
  ) async {
    try {
      final rows = await _readFileData(filePath);

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

      // Insert semua Sub CPMK
      if (subCpmkList.isNotEmpty) {
        for (var subCpmk in subCpmkList) {
          await _dbHelper.insertSubCPMK(subCpmk);
        }
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
}

